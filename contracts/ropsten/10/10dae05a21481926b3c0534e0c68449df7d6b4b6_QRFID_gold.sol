// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./Ownable.sol";
import "./IERC1400.sol";

contract QRFID_gold is IERC1400, Ownable {
    /*------------------Document Management--------------------*/

    struct KycDocument {
        bytes32 docHash; // Hash of the document
        uint256 lastModified; // Timestamp at which document details was last modified
        string uri; // URI of the document that exist off-chain
    }

    mapping(bytes32 => KycDocument) internal _documents;
    bytes32[] internal _usersKYC;
    mapping(bytes32 => uint256) internal _docIndexes;

    /**
     * @dev See {IERC1400-getDocument}
     */
    function getDocument(bytes32 _docName)
        public
        view
        override
        returns (string memory, bytes32)
    {
        return (_documents[_docName].uri, _documents[_docName].docHash);
    }

    /**
     * @dev See {IERC1400-setDocument}.
     *
     * Requirements:
     *
     * - `_docName` cannot be the zero {bytes32}.
     * - `_uri` cannot be empty string.
     * - `_documentHash` cannot be the zero {bytes32}.
     */
    function setDocument(
        bytes32 _docName,
        string calldata _uri,
        bytes32 _documentHash
    ) public override onlyOwner {
        require(_docName != bytes32(0), "No Zero Addr");
        require(bytes(_uri).length > 0, "No Empty URL");
        require(_documentHash != bytes32(0), "No Zero hash");

        if (_documents[_docName].lastModified == uint256(0)) {
            _usersKYC.push(_docName);
            _docIndexes[_docName] = _usersKYC.length;
        }

        _documents[_docName] = KycDocument(
            _documentHash,
            block.timestamp,
            _uri
        );

        emit Document(_docName, _uri, _documentHash);
    }

    /**
     * @dev Return a kyc document using `_userAddress`; it converts
     * address to to {bytes32} and queries the document and is used for
     * this contract logic only
     */
    function getKycDocument(address _userAddress)
        external
        view
        returns (string memory, bytes32)
    {
        return (getDocument(addressToBytes32(_userAddress)));
    }

    /**
     * @dev See {setDocument}.
     *
     * note Create kyc document using `_userAddress` by converting it to
     * {bytes32} and is used for this contract logic only
     */
    function setKycDocument(
        address _userAddress,
        string calldata Uri,
        bytes32 _DocumentHash
    ) external onlyOwner {
        setDocument(addressToBytes32(_userAddress), Uri, _DocumentHash);
        setUserKycStatus(_userAddress, true);
    }

    /**
     * @dev Returns all documents
     */
    function getAllKycDocuments() external view returns (bytes32[] memory) {
        return _usersKYC;
    }

    // /*------------------ERC-1594 Implementation--------------------*/

    bool internal _isIssuable;

    struct TokenSaleData {
        uint256 timeStamp;
        address to;
        uint256 tokenValue;
        uint256 grams;
        string goldId;
        string kycUri;
    }

    /**
     * @dev Stores token sale data userwise
     */
    mapping(address => TokenSaleData[]) addressToTokenSaleHistory;

    TokenSaleData[] tokenSaleHistory;

    struct IssuedTokens {
        uint256 timeStamp;
        uint256 tokenValue;
        bytes32 _partition;
        address _address;
    }

    IssuedTokens[] issueHistory;

    struct RedeemedTokens {
        address _operator;
        address _from;
        uint256 _value;
        bytes _data;
    }

    RedeemedTokens[] redeemedTokensHistory;

    /**
     * @dev Stores redeemed tokens userwise
     */
    mapping(address => RedeemedTokens[]) addressToRedeemedTokens;

    /**
     * @dev See {IERC1400-isIssuable}
     */
    function isIssuable() external view override returns (bool) {
        return _isIssuable;
    }

    /**
     * @dev Returns token sale data of `account` from {addressToTokenSaleHistory}
     */
    function tokenSaleHistoryOf(address account)
        external
        view
        returns (TokenSaleData[] memory)
    {
        return addressToTokenSaleHistory[account];
    }

    /**
     * @dev Returns all token sale data from {tokenSaleHistory}
     */
    function getAllTokenSaleHistory()
        external
        view
        returns (TokenSaleData[] memory)
    {
        return tokenSaleHistory;
    }

    /**
     * @dev Returns redeemed tokens data of `account` from {addressToRedeemedTokens}
     */
    function redeemHistoryOf(address account)
        external
        view
        returns (RedeemedTokens[] memory)
    {
        return addressToRedeemedTokens[account];
    }

    /**
     * @dev Returns all redeemed tokens data from {redeemedTokensHistory}
     */
    function getAllRedeemedTokensHistory()
        external
        view
        returns (RedeemedTokens[] memory)
    {
        return redeemedTokensHistory;
    }

    /**
     * @dev Starts and allow issuing tokens
     *
     * note Only owner can call this function
     */
    function startIssuing() external onlyOwner {
        require(_isIssuable == false, "Already Issuable");
        _isIssuable = true;
    }

    /**
     * @dev Stops issuing tokens
     *
     * note Only owner can call this function
     */
    function endIssuing() external onlyOwner {
        require(_isIssuable == true, "Not Issuable");
        _isIssuable = false;
    }

    /**
     * @dev Moves `_value` amount of tokens to `_to`, which is known to contract
     * by its kyc data `_kycUrl` in documents, in exchange of `_grams` grams of
     * gold from `_goldId` gold bar. `_timeStamp` is the date of gold purchase
     *
     * note Stores the token sale data to {tokenSaleHistory}
     */
    function distributeToken(
        address _to,
        uint256 _value,
        uint256 _grams,
        uint256 _timeStamp,
        string calldata _kycUrl,
        string calldata _goldId
    ) external onlyOwner isTimeStampValid(_timeStamp) {
        transferWithData(_to, _value, bytes(_kycUrl));

        TokenSaleData memory _tokenSaleData = TokenSaleData(
            _timeStamp,
            _to,
            _value,
            _grams,
            _goldId,
            _kycUrl
        );

        addressToTokenSaleHistory[_to].push(_tokenSaleData);
        tokenSaleHistory.push(_tokenSaleData);
        incTokenDistributed += _value;
    }

    /**
     * @dev See {IERC1400-issue}
     *
     * Requirements:
     *
     * - issueing is allowed/started
     * - `_tokenHolder` is not in black list
     * - `_tokenHolder` kyc data is present in the contract with a
     * valid data of `_data`
     */
    function issue(
        address _tokenHolder,
        uint256 _value,
        bytes calldata _data
    )
        external
        override
        onlyOwner
        _isIssuingOn
        isUserBlackListed(_tokenHolder)
        isUserKyc(_tokenHolder)
        isUserDataValid(_tokenHolder, _data)
    {
        _mint(_tokenHolder, _value);
        issueHistory.push(
            IssuedTokens(block.timestamp, _value, bytes32(0), _tokenHolder)
        );
        emit Issued(address(0), _tokenHolder, _value, _data);
    }

    /**
     * @dev See {IERC1400-redeem}
     *
     * Requirements:
     *
     * - caller's kyc data is present in the contract with a
     * valid data of `_data`
     *
     * note Stores redeem data in {redeemedTokensHistory}
     */
    function redeem(uint256 _value, bytes calldata _data)
        external
        override
        isUserKyc(msg.sender)
        isUserDataValid(msg.sender, _data)
    {
        _burn(msg.sender, _value);

        RedeemedTokens memory _redeemed = RedeemedTokens(
            msg.sender,
            msg.sender,
            _value,
            _data
        );
        redeemedTokensHistory.push(_redeemed);
        addressToRedeemedTokens[msg.sender].push(_redeemed);
        emit Redeemed(msg.sender, msg.sender, _value, _data);
    }

    /**
     * @dev See {IERC1400-redeemFrom}
     *
     * Requirements:
     *
     * - `_tokenHolder` kyc data is present in the contract with a
     * valid data of `_data`
     *
     * note Stores redeem data in {redeemedTokensHistory}
     */
    function redeemFrom(
        address _tokenHolder,
        uint256 _value,
        bytes calldata _data
    )
        external
        override
        isUserKyc(_tokenHolder)
        isUserDataValid(_tokenHolder, _data)
    {
        _spendAllowance(_tokenHolder, msg.sender, _value);
        _burn(_tokenHolder, _value);

        RedeemedTokens memory _redeemed = RedeemedTokens(
            msg.sender,
            _tokenHolder,
            _value,
            _data
        );
        redeemedTokensHistory.push(_redeemed);
        addressToRedeemedTokens[_tokenHolder].push(_redeemed);
        emit Redeemed(msg.sender, _tokenHolder, _value, _data);
    }

    // /*------------------Partition Management--------------------*/

    struct Partition {
        uint256 amount;
        bytes32 partition;
    }

    mapping(address => Partition[]) partitions;
    mapping(address => mapping(bytes32 => uint256)) partitionToIndex;
    mapping(address => bytes32[]) _addressToPartitions;
    mapping(bytes32 => mapping(address => uint256)) _balancesByPartition;

    /**
     * @dev See {IERC1400-balanceOfByPartition}
     */
    function balanceOfByPartition(bytes32 _partition, address _tokenHolder)
        external
        view
        override
        returns (uint256)
    {
        return (_balancesByPartition[_partition][_tokenHolder]);
    }

    /**
     * @dev See {IERC1400-partitionsOf}
     */
    function partitionsOf(address _tokenHolder)
        external
        view
        override
        returns (bytes32[] memory)
    {
        return _addressToPartitions[_tokenHolder];
    }

    /**
     * @dev See {IERC1400-issueByPartition}
     *
     * Requirements:
     *
     * - issueing is allowed/started
     * - `_tokenHolder` is not a zero address
     * - `_tokenHolder` is not in black list
     * - `_tokenHolder` kyc data is present in the contract with a
     * valid data of `_data`
     *
     * note Stores issue data in {IssuedByPartition}
     */
    function issueByPartition(
        bytes32 _partition,
        address _tokenHolder,
        uint256 _value,
        bytes memory _data
    )
        public
        virtual
        onlyOwner
        _isIssuingOn
        isUserBlackListed(_tokenHolder)
        isUserKyc(_tokenHolder)
        isUserDataValid(_tokenHolder, _data)
    {
        _validateParams(_partition, _value);

        require(_tokenHolder != address(0), "Invalid token receiver");
        uint256 index = partitionToIndex[_tokenHolder][_partition];
        if (index == 0) {
            partitions[_tokenHolder].push(Partition(_value, _partition));
            _addressToPartitions[_tokenHolder].push(_partition);
            partitionToIndex[_tokenHolder][_partition] = partitions[
                _tokenHolder
            ].length;
        } else {
            partitions[_tokenHolder][index - 1].amount =
                partitions[_tokenHolder][index - 1].amount +
                _value;

            _balancesByPartition[_partition][_tokenHolder] =
                _balancesByPartition[_partition][_tokenHolder] +
                _value;
        }

        _balances[_tokenHolder] = _balances[_tokenHolder] + _value;
        _totalSupply = _totalSupply + _value;
        issueHistory.push(
            IssuedTokens(block.timestamp, _value, _partition, _tokenHolder)
        );

        emit IssuedByPartition(
            _partition,
            msg.sender,
            _tokenHolder,
            _value,
            _data,
            bytes(abi.encodePacked(bytes1(0)))
        );
    }

    /*----------------ERC-1400 Transfer Control------------------*/
    /**
     * @dev See {IERC1400-transferWithData}
     *
     * Requirements:
     *
     * - `_to` is not a zero address
     * - `_to` is not in black list
     * - `_to` kyc data is present in the contract with a
     * valid data of `_data`
     */
    function transferWithData(
        address _to,
        uint256 _value,
        bytes calldata _data
    )
        public
        override
        isUserBlackListed(_to)
        isUserKyc(_to)
        isUserDataValid(_to, _data)
    {
        _transfer(msg.sender, _to, _value);
    }

    /**
     * @dev See {IERC1400-transferFromWithData}
     *
     * Requirements:
     *
     * - `_to` & `_from` is not a zero address
     * - `_to` is not in black list
     * - `_to` kyc data is present in the contract with a
     * valid data of `_data`
     */
    function transferFromWithData(
        address _from,
        address _to,
        uint256 _value,
        bytes calldata _data
    )
        external
        override
        isUserBlackListed(_to)
        isUserKyc(_to)
        isUserDataValid(_to, _data)
    {
        _spendAllowance(_from, msg.sender, _value);
        _transfer(_from, _to, _value);
    }

    /**
     * @dev See {IERC1400-transferByPartition}
     *
     * Requirements:
     *
     * - `_to` is not a zero address
     * - `_to` is not in black list
     * - `_to` kyc data is present in the contract with a
     * valid data of `_data`
     */
    function transferByPartition(
        bytes32 _partition,
        address _to,
        uint256 _value,
        bytes calldata _data
    )
        external
        override
        isUserBlackListed(_to)
        isUserKyc(_to)
        isUserDataValid(_to, _data)
        returns (bytes32)
    {
        _transferByPartition(msg.sender, _to, _value, _partition);

        emit TransferByPartition(
            _partition,
            address(0),
            msg.sender,
            _to,
            _value,
            _data,
            abi.encodePacked(bytes1(0))
        );

        return _partition;
    }

    /**
     * @dev See {IERC1400-canTransfer}
     */
    function canTransfer(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external view override returns (bytes1, bytes32) {
        if (!isBytesEqual(abi.encodePacked(bytes1(0)), _data)) {
            bytes memory userKycUri = bytes(
                _documents[addressToBytes32(msg.sender)].uri
            );
            if (!isBytesEqual(userKycUri, _data)) {
                return (0x56, bytes32(bytes("Invalid Sender")));
            }
        }

        if (_to == address(0))
            return (0x57, bytes32(bytes("Invalid Receiver")));

        if (_value > _balances[msg.sender])
            return (0x52, bytes32(bytes("Insufficient Balance")));

        return (0x51, bytes32(bytes("Transfer Success")));
    }

    /**
     * @dev See {IERC1400-canTransferFrom}
     */
    function canTransferFrom(
        address _from,
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external view override returns (bytes1, bytes32) {
        if (!isBytesEqual(abi.encodePacked(bytes1(0)), _data)) {
            bytes memory userKycUri = bytes(
                _documents[addressToBytes32(msg.sender)].uri
            );
            if (!isBytesEqual(userKycUri, _data)) {
                return (0x56, bytes32(bytes("Invalid Sender")));
            }
        }

        if (_from == address(0))
            return (0x56, bytes32(bytes("Invalid Sender")));

        if (_to == address(0))
            return (0x57, bytes32(bytes("Invalid Receiver")));

        if (_value > _balances[msg.sender])
            return (0x52, bytes32(bytes("Insufficient Balance")));

        return (0x51, bytes32(bytes("Transfer Success")));
    }

    /**
     * @dev See {IERC1400-canTransferByPartition}
     */
    function canTransferByPartition(
        address _from,
        address _to,
        bytes32 _partition,
        uint256 _value,
        bytes calldata _data
    )
        external
        view
        override
        returns (
            bytes1,
            bytes32,
            bytes32
        )
    {
        if (!isBytesEqual(abi.encodePacked(bytes1(0)), _data)) {
            bytes memory userKycUri = bytes(
                _documents[addressToBytes32(msg.sender)].uri
            );
            if (!isBytesEqual(userKycUri, _data)) {
                return (0x56, bytes32(bytes("Invalid Sender")), bytes32(0));
            }
        }

        if (_from == address(0))
            return (0x56, bytes32(bytes("Invalid Sender")), bytes32(0));

        if (_to == address(0))
            return (0x57, bytes32(bytes("Invalid Receiver")), bytes32(0));

        if (_value > _balancesByPartition[_partition][msg.sender])
            return (0x52, bytes32(bytes("Insufficient Balance")), bytes32(0));

        if (_partition == bytes32(0))
            return (0x59, bytes32(bytes("Invalid Partition")), bytes32(0));

        return (0x51, bytes32(bytes("Transfer Success")), bytes32(0));
    }

    /*------------------ERC-20 Implementation--------------------*/
    string private _name;
    uint256 _decimals;
    string private _symbol;
    uint256 _totalSupply;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    struct MintToken {
        uint256 Tokens;
        uint256 Date;
        address _address;
    }

    MintToken[] public MintTokenHistory;

    /**
     * @dev Sets the values for {name}, {symbol}, and {owner address}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        address _ownerAddress
    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
        _mint(_ownerAddress, 40000000 * 10**18);
        transferOwnership(_ownerAddress);
    }

    /**
     * @dev the minted token is added _totalSupply
     * @param value tokens to be minted
     * @param _address receiver of minted tokens
     */
    function mint(uint256 value, address _address) external onlyOwner {
        _mint(_address, value);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() external view returns (uint256) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return _balances[account];
    }

    /**
     * @dev Returns all issue history
     */
    function getAllIssueHistory()
        external
        view
        returns (IssuedTokens[] memory)
    {
        return issueHistory;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount)
        external
        override
        returns (bool)
    {
        _transfer(msg.sender, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            allowance(msg.sender, spender) + addedValue
        );
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = allowance(msg.sender, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(msg.sender, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);
    }

    /**
     * @dev Moves `amount` of tokens in the `partition` from the
     * `from` to `to`
     *
     * Requirements:
     *
     * - `from` & `to` cannot be a zero address.
     * - `from` must have a balance of at least `amount` in the `partition`.
     * - `partition` cannot be a zero {bytes32}.
     */
    function _transferByPartition(
        address from,
        address to,
        uint256 amount,
        bytes32 partition
    ) internal {
        require(from != address(0), "ERC1400: transfer from the zero address");
        require(to != address(0), "ERC1400: transfer to the zero address");
        require(
            partition != bytes32(0),
            "ERC1400: transfer withen an invaled partition"
        );

        uint256 fromPartitionBalance = _balancesByPartition[partition][from];
        require(
            fromPartitionBalance >= amount,
            "ERC1400: transfer amount exceeds balance"
        );

        unchecked {
            _balancesByPartition[partition][from] =
                fromPartitionBalance -
                amount;
        }

        _balancesByPartition[partition][to] += amount;
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply + amount;
        _balances[account] = _balances[account] + amount;

        MintTokenHistory.push(MintToken(amount, block.timestamp, msg.sender));
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /*------------------Supporttive Function--------------------*/

    /**
     * @dev Number of tokens that are distributed by {owner}
     */
    uint256 incTokenDistributed = 0;

    /**
     * @dev Returns the amount of tokens that are distributed
     *
     * note it is related to ICO logic
     */
    function _incTokenDistributed() external view returns (uint256) {
        return incTokenDistributed;
    }

    /**
     * @dev Gives error when `_partition` OR `_value` is/are zero
     */
    function _validateParams(bytes32 _partition, uint256 _value) internal pure {
        require(_value != uint256(0), "ERC1400: Zero value not allowed");
        require(_partition != bytes32(0), "ERC1400: Invalid partition");
    }

    /**
     * @dev Gives error when {_isIssuable} is not {true}
     */
    modifier _isIssuingOn() {
        require(_isIssuable, "Sale is off");
        _;
    }

    receive() external payable {
        revert("Invalid transaction");
    }

    /**
     * @dev Converts the `_bytes` of type {bytes} to {uint256}
     */
    function toUint256(bytes memory _bytes)
        internal
        pure
        returns (uint256 value)
    {
        assembly {
            value := mload(add(_bytes, 0x20))
        }
    }

    /**
     * @dev Converts the `x` of type {uint256} to {bytes}
     */
    function toBytes(uint256 x) internal pure returns (bytes memory b) {
        b = new bytes(32);
        for (uint256 i = 0; i < 32; i++) {
            b[i] = bytes1(uint8(x / (2**(8 * (31 - i)))));
        }
        return b;
    }

    /**
     * @dev Compares the bytes `a` with `b` and returns true if they match
     * and false otherwise
     */
    function isBytesEqual(bytes memory a, bytes memory b)
        internal
        pure
        returns (bool)
    {
        return (a.length == b.length) && (keccak256(a) == keccak256(b));
    }

    /**
     * @dev Converts the `_address` of type {address} to {bytes32}
     */
    function addressToBytes32(address _address)
        internal
        pure
        returns (bytes32)
    {
        return bytes32(bytes20(_address));
    }

    /*----------------------------------User Checking---------------------------*/

    event UserIsBlackListedByAdmin(address indexed _user, bool _isBlackListed);
    event UserKycStatus(address indexed _user, bool _status);
    mapping(address => bool) internal blackListed;
    mapping(address => bool) public userKycStatus;

    /**
     * @dev Sets the `_address` with the `_bool` value in {userKycStatus} list
     *
     * Emits {UserKycStatus}
     */
    function setUserKycStatus(address _address, bool _bool) internal {
        userKycStatus[_address] = _bool;
        emit UserKycStatus(_address, _bool);
    }

    /**
     * @dev Sets an `_address` to `_bool` value in the {blackListed} list
     *
     * Emits {UserIsBlackListedByAdmin}
     */
    function setBlackList(address _address, bool _bool) external onlyOwner {
        blackListed[_address] = _bool;
        emit UserIsBlackListedByAdmin(_address, _bool);
    }

    /**
     * @dev Gives error when `_address` exists in the `blackListed`
     * list having {true} value
     */
    modifier isUserBlackListed(address _address) {
        require(blackListed[_address] == false, "User Is BlackListed");
        _;
    }

    /**
     * @dev Gives error when `_data` of `_userAddress` doesn't
     * exist or mismatches in {_documents}
     */
    modifier isUserDataValid(address _userAddress, bytes memory _data) {
        bytes memory userKycUri = bytes(
            _documents[addressToBytes32(_userAddress)].uri
        );
        require(isBytesEqual(_data, userKycUri), "User KYC URI Mismatch");
        _;
    }

    /**
     * @dev Gives error when `_address` is not in the {userKycStatus}
     * list having a true value
     */
    modifier isUserKyc(address _address) {
        require(userKycStatus[_address] == true, "User Kyc Is InComplete");
        _;
    }

    /**
     * @dev Gives error when `timeStamp` is not bigger than zero
     */
    modifier isTimeStampValid(uint256 timeStamp) {
        require(timeStamp > 0, "Zero Timestamp Provided.");
        _;
    }
}