// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "ownable.sol";
import "SafeMath.sol";

import "IERC1400.sol";

contract QRFID_gold is IERC1400, Ownable {
    using SafeMath for uint256;

    /*------------------Document Management--------------------*/

    struct KycDocument {
        bytes32 docHash; // Hash of the document
        uint256 lastModified; // Timestamp at which document details was last modified
        string uri; // URI of the document that exist off-chain
    }

    mapping(bytes32 => KycDocument) internal _documents;
    bytes32[] internal _usersKYC;
    mapping(bytes32 => uint256) internal _docIndexes;

    function getDocument(bytes32 _docName)
        public
        view
        override
        returns (string memory, bytes32)
    {
        return (_documents[_docName].uri, _documents[_docName].docHash);
    }

    function setDocument(
        bytes32 _docName,
        string calldata _uri,
        bytes32 _documentHash
    ) public override onlyOwner {
        require(_docName != bytes32(0), "Zero address is not allowed");
        require(bytes(_uri).length > 0, "Should not be a empty uri");

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

    function getKycDocument(address _userAddress)
        external
        view
        returns (string memory, bytes32)
    {
        return (getDocument(addressToBytes32(_userAddress)));
    }

    function setKycDocument(
        address _userAddress,
        string calldata Uri,
        bytes32 _DocumentHash
    ) external onlyOwner {
        setDocument(addressToBytes32(_userAddress), Uri, _DocumentHash);
        setUserKycStatus(_userAddress, true);
    }

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
        string kycUri;
    }
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

    RedeemedTokens[] _redeemedTokensHistory;
    mapping(address => RedeemedTokens[]) _addressToRedeemedTokens;

    function isIssuable() external view override returns (bool) {
        return _isIssuable;
    }

    function tokenSaleHistoryOf(address account)
        external
        view
        returns (TokenSaleData[] memory)
    {
        return addressToTokenSaleHistory[account];
    }

    function getAllTokenSaleHistory()
        external
        view
        returns (TokenSaleData[] memory)
    {
        return tokenSaleHistory;
    }

    function startIssuing() external onlyOwner {
        require(_isIssuable == false, "Already Issuable");
        _isIssuable = true;
    }

    function endIssuing() external onlyOwner {
        require(_isIssuable == true, "Already Not Issuable");
        _isIssuable = false;
    }

    // Distribution function
    function distributeToken(
        address _to,
        uint256 _value,
        uint256 _grams,
        uint256 _timeStamp,
        string calldata _kycUrl
    ) external onlyOwner isTimeStampValid(_timeStamp) {
        transferWithData(_to, _value, bytes(_kycUrl));

        TokenSaleData memory _tokenSaleData = TokenSaleData(
            _timeStamp,
            _to,
            _value,
            _grams,
            _kycUrl
        );

        addressToTokenSaleHistory[_to].push(_tokenSaleData);
        tokenSaleHistory.push(_tokenSaleData);
        incTokenDistributed += _value;
    }

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
        _redeemedTokensHistory.push(_redeemed);
        _addressToRedeemedTokens[msg.sender].push(_redeemed);
        emit Redeemed(msg.sender, msg.sender, _value, _data);
    }

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
        _redeemedTokensHistory.push(_redeemed);
        _addressToRedeemedTokens[_tokenHolder].push(_redeemed);
        emit Redeemed(msg.sender, _tokenHolder, _value, _data);
    }

    // /*------------------Controler Management--------------------*/

    bool _isControllable;
    mapping(address => bool) _isConroller;

    function isController(address account) external view returns (bool) {
        return _isConroller[account];
    }

    function isControllable() external view override returns (bool) {
        return _isControllable;
    }

    function controllerTransfer(
        address _from,
        address _to,
        uint256 _value,
        bytes calldata _data,
        bytes calldata _operatorData
    ) external {}

    function controllerRedeem(
        address _tokenHolder,
        uint256 _value,
        bytes calldata _data,
        bytes calldata _operatorData
    ) external {}

    // /*------------------Operator Management---------------------*/
    mapping(address => mapping(address => bool)) internal _authorizedOperator;

    mapping(address => mapping(bytes32 => mapping(address => bool)))
        internal _authorizedOperatorByPartition;

    function authorizeOperator(address _operator) external override {
        require(_operator != msg.sender);
        _authorizedOperator[_operator][msg.sender] = true;
        emit AuthorizedOperator(_operator, msg.sender);
    }

    function revokeOperator(address _operator) external override {
        require(_operator != msg.sender);
        _authorizedOperator[_operator][msg.sender] = false;
        emit RevokedOperator(_operator, msg.sender);
    }

    function authorizeOperatorByPartition(bytes32 _partition, address _operator)
        external
        override
    {
        _authorizedOperatorByPartition[msg.sender][_partition][
            _operator
        ] = true;
        emit AuthorizedOperatorByPartition(_partition, _operator, msg.sender);
    }

    function revokeOperatorByPartition(bytes32 _partition, address _operator)
        external
        override
    {
        _authorizedOperatorByPartition[msg.sender][_partition][
            _operator
        ] = false;
        emit RevokedOperatorByPartition(_partition, _operator, msg.sender);
    }

    // Operator Information
    function isOperator(address _operator, address _tokenHolder)
        external
        view
        override
        returns (bool)
    {
        return _authorizedOperator[_operator][_tokenHolder];
    }

    function isOperatorForPartition(
        bytes32 _partition,
        address _operator,
        address _tokenHolder
    ) external view override returns (bool) {
        return
            _authorizedOperatorByPartition[_operator][_partition][_tokenHolder];
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

    function balanceOfByPartition(bytes32 _partition, address _tokenHolder)
        external
        view
        override
        returns (uint256)
    {
        return (_balancesByPartition[_partition][_tokenHolder]);
    }

    function partitionsOf(address _tokenHolder)
        external
        view
        override
        returns (bytes32[] memory)
    {
        return _addressToPartitions[_tokenHolder];
    }

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
            partitions[_tokenHolder][index - 1].amount = partitions[
                _tokenHolder
            ][index - 1].amount.add(_value);

            _balancesByPartition[_partition][
                _tokenHolder
            ] = _balancesByPartition[_partition][_tokenHolder].add(_value);
        }

        _balances[_tokenHolder] = _balances[_tokenHolder].add(_value);
        _totalSupply = _totalSupply.add(_value);
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

    function redeemByPartition(
        bytes32 _partition,
        uint256 _value,
        bytes calldata _data
    )
        external
        override
        isUserKyc(msg.sender)
        isUserDataValid(msg.sender, _data)
    {}

    function operatorRedeemByPartition(
        bytes32 _partition,
        address _tokenHolder,
        uint256 _value,
        bytes calldata _operatorData
    ) external override isUserKyc(_tokenHolder) {}

    /*----------------ERC-1400 Transfer Control------------------*/
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

    function operatorTransferByPartition(
        bytes32 _partition,
        address _from,
        address _to,
        uint256 _value,
        bytes calldata _data,
        bytes calldata _operatorData
    )
        external
        override
        isUserBlackListed(_to)
        isUserKyc(_to)
        isUserDataValid(_to, _data)
        returns (bytes32)
    {
        // //TODO: check for operator validity
        // _transferByPartition(_from, _to, _value, _partition);
        // emit TransferByPartition(
        //     _partition,
        //     address(0),
        //     _from,
        //     _to,
        //     _value,
        //     _data,
        //     _operatorData
        // );
        // return _partition;
    }

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

    function canTransferFrom(
        address _from,
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external view returns (bytes1, bytes32) {
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

    function canTransferByPartition(
        address _from,
        address _to,
        bytes32 _partition,
        uint256 _value,
        bytes calldata _data
    )
        external
        view
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

    /// @dev the minted token is added _totalSupply
    /// @param value tokens to be minted
    /// @param _address receiver of minted tokens
    function mint(uint256 value, address _address) external onlyOwner {
        _mint(_address, value);
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external view returns (uint256) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function getAllIssueHistory()
        external
        view
        returns (IssuedTokens[] memory)
    {
        return issueHistory;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function transfer(address to, uint256 amount)
        external
        override
        returns (bool)
    {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        return true;
    }

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

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);

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

    uint256 incTokenDistributed = 0;

    function _incTokenDistributed() external view returns (uint256) {
        return incTokenDistributed;
    }

    function _validateParams(bytes32 _partition, uint256 _value) internal pure {
        require(_value != uint256(0), "ERC1400: Zero value not allowed");
        require(_partition != bytes32(0), "ERC1400: Invalid partition");
    }

    modifier _isIssuingOn() {
        require(_isIssuable, "Sale is off");
        _;
    }

    receive() external payable {
        revert("Invalid transaction");
    }

    function toUint256(bytes memory _bytes)
        internal
        pure
        returns (uint256 value)
    {
        assembly {
            value := mload(add(_bytes, 0x20))
        }
    }

    function toBytes(uint256 x) internal pure returns (bytes memory b) {
        b = new bytes(32);
        for (uint256 i = 0; i < 32; i++) {
            b[i] = bytes1(uint8(x / (2**(8 * (31 - i)))));
        }
        return b;
    }

    function isBytesEqual(bytes memory a, bytes memory b)
        internal
        pure
        returns (bool)
    {
        return (a.length == b.length) && (keccak256(a) == keccak256(b));
    }

    function addressToBytes32(address _address)
        internal
        pure
        returns (bytes32)
    {
        return bytes32(bytes20(_address));
    }

    /*----------------------------------User Checking---------------------------*/

    event UserIsBlackListedByAdmin(address indexed _user);
    event UserKycStatus(address indexed _user, bool _status);
    mapping(address => bool) internal blackListed;
    mapping(address => bool) public userKycStatus;

    function setUserKycStatus(address _address, bool _bool) internal {
        userKycStatus[_address] = _bool;
        emit UserKycStatus(_address, _bool);
    }

    function setBlackList(address _address, bool _bool) external onlyOwner {
        blackListed[_address] = _bool;
        emit UserIsBlackListedByAdmin(_address);
    }

    modifier isUserBlackListed(address _address) {
        require(blackListed[_address] == false, "User Is BlackListed");
        _;
    }

    modifier isUserDataValid(address _userAddress, bytes memory _data) {
        bytes memory userKycUri = bytes(
            _documents[addressToBytes32(_userAddress)].uri
        );
        require(isBytesEqual(_data, userKycUri), "User KYC URI Mismatch");
        _;
    }

    modifier isUserKyc(address _address) {
        require(userKycStatus[_address] == true, "User Kyc Is InCompelet");
        _;
    }

    modifier isTimeStampValid(uint256 timeStamp) {
        require(timeStamp > 0, "Zero Timestamp Provided.");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract Ownable {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    address private _owner;

    constructor() {
        _owner = msg.sender;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "IERC20.sol";

/// @title IERC1400 Security Token Standard
/// @dev See https://github.com/SecurityTokenStandard/EIP-Spec

interface IERC1400 is IERC20 {
    // Document Management
    function getDocument(bytes32 _docName)
        external
        view
        returns (string memory, bytes32);

    function setDocument(
        bytes32 _docName,
        string calldata _uri,
        bytes32 _documentHash
    ) external;

    // Token Information
    function balanceOfByPartition(bytes32 _partition, address _tokenHolder)
        external
        view
        returns (uint256);

    function partitionsOf(address _tokenHolder)
        external
        view
        returns (bytes32[] memory);

    // Transfers
    function transferWithData(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external;

    function transferFromWithData(
        address _from,
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external;

    // Partition Token Transfers
    function transferByPartition(
        bytes32 _partition,
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external returns (bytes32);

    function operatorTransferByPartition(
        bytes32 _partition,
        address _from,
        address _to,
        uint256 _value,
        bytes calldata _data,
        bytes calldata _operatorData
    ) external returns (bytes32);

    // Controller Operation
    function isControllable() external view returns (bool);

    function controllerTransfer(
        address _from,
        address _to,
        uint256 _value,
        bytes calldata _data,
        bytes calldata _operatorData
    ) external;

    function controllerRedeem(
        address _tokenHolder,
        uint256 _value,
        bytes calldata _data,
        bytes calldata _operatorData
    ) external;

    // Operator Management
    function authorizeOperator(address _operator) external;

    function revokeOperator(address _operator) external;

    function authorizeOperatorByPartition(bytes32 _partition, address _operator)
        external;

    function revokeOperatorByPartition(bytes32 _partition, address _operator)
        external;

    // Operator Information
    function isOperator(address _operator, address _tokenHolder)
        external
        view
        returns (bool);

    function isOperatorForPartition(
        bytes32 _partition,
        address _operator,
        address _tokenHolder
    ) external view returns (bool);

    // Token Issuance
    function isIssuable() external view returns (bool);

    function issue(
        address _tokenHolder,
        uint256 _value,
        bytes calldata _data
    ) external;

    function issueByPartition(
        bytes32 _partition,
        address _tokenHolder,
        uint256 _value,
        bytes calldata _data
    ) external;

    // Token Redemption
    function redeem(uint256 _value, bytes calldata _data) external;

    function redeemFrom(
        address _tokenHolder,
        uint256 _value,
        bytes calldata _data
    ) external;

    function redeemByPartition(
        bytes32 _partition,
        uint256 _value,
        bytes calldata _data
    ) external;

    function operatorRedeemByPartition(
        bytes32 _partition,
        address _tokenHolder,
        uint256 _value,
        bytes calldata _operatorData
    ) external;

    // Transfer Validity
    function canTransfer(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external view returns (bytes1, bytes32);

    function canTransferFrom(
        address _from,
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external view returns (bytes1, bytes32);

    function canTransferByPartition(
        address _from,
        address _to,
        bytes32 _partition,
        uint256 _value,
        bytes calldata _data
    )
        external
        view
        returns (
            bytes1,
            bytes32,
            bytes32
        );

    // Controller Events
    event ControllerTransfer(
        address _controller,
        address indexed _from,
        address indexed _to,
        uint256 _value,
        bytes _data,
        bytes _operatorData
    );

    event ControllerRedemption(
        address _controller,
        address indexed _tokenHolder,
        uint256 _value,
        bytes _data,
        bytes _operatorData
    );

    // Document Events
    event Document(bytes32 indexed _name, string _uri, bytes32 _documentHash);

    // Transfer Events
    event TransferByPartition(
        bytes32 indexed _fromPartition,
        address _operator,
        address indexed _from,
        address indexed _to,
        uint256 _value,
        bytes _data,
        bytes _operatorData
    );

    event ChangedPartition(
        bytes32 indexed _fromPartition,
        bytes32 indexed _toPartition,
        uint256 _value
    );

    // Operator Events
    event AuthorizedOperator(
        address indexed _operator,
        address indexed _tokenHolder
    );
    event RevokedOperator(
        address indexed _operator,
        address indexed _tokenHolder
    );
    event AuthorizedOperatorByPartition(
        bytes32 indexed _partition,
        address indexed _operator,
        address indexed _tokenHolder
    );
    event RevokedOperatorByPartition(
        bytes32 indexed _partition,
        address indexed _operator,
        address indexed _tokenHolder
    );

    // Issuance / Redemption Events
    event Issued(
        address indexed _operator,
        address indexed _to,
        uint256 _value,
        bytes _data
    );
    event Redeemed(
        address indexed _operator,
        address indexed _from,
        uint256 _value,
        bytes _data
    );
    event IssuedByPartition(
        bytes32 indexed _partition,
        address indexed _operator,
        address indexed _to,
        uint256 _value,
        bytes _data,
        bytes _operatorData
    );
    event RedeemedByPartition(
        bytes32 indexed _partition,
        address indexed _operator,
        address indexed _from,
        uint256 _value,
        bytes _operatorData
    );
}

/**
 * Reason codes - ERC-1066
 *
 * To improve the token holder experience, canTransfer MUST return a reason byte code
 * on success or failure based on the ERC-1066 application-specific status codes specified below.
 * An implementation can also return arbitrary data as a bytes32 to provide additional
 * information not captured by the reason code.
 *
 * Code	Reason
 * 0x50	transfer failure
 * 0x51	transfer success
 * 0x52	insufficient balance
 * 0x53	insufficient allowance
 * 0x54	transfers halted (contract paused)
 * 0x55	funds locked (lockup period)
 * 0x56	invalid sender
 * 0x57	invalid receiver
 * 0x58	invalid operator (transfer agent)
 * 0x59
 * 0x5a
 * 0x5b
 * 0x5a
 * 0x5b
 * 0x5c
 * 0x5d
 * 0x5e
 * 0x5f	token meta or info
 *
 * These codes are being discussed at: https://ethereum-magicians.org/t/erc-1066-ethereum-status-codes-esc/283/24
 */

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}