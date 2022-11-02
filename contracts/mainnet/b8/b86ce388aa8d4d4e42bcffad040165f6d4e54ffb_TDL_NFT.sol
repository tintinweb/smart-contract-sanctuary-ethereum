/**
 *Submitted for verification at Etherscan.io on 2022-11-02
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

interface IERC1155TokenReceiver {
    /**
     * @notice Handle the receipt of a single ERC1155 token type
     * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated
     * This function MAY throw to revert and reject the transfer
     * Return of other amount than the magic value MUST result in the transaction being reverted
     * Note: The token contract address is always the message sender
     * @param _operator  The address which called the `safeTransferFrom` function
     * @param _from      The address which previously owned the token
     * @param _id        The id of the token being transferred
     * @param _amount    The amount of tokens being transferred
     * @param _data      Additional data with no specified format
     * @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     */
    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 _amount,
        bytes calldata _data
    ) external returns (bytes4);

    /**
     * @notice Handle the receipt of multiple ERC1155 token types
     * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated
     * This function MAY throw to revert and reject the transfer
     * Return of other amount than the magic value WILL result in the transaction being reverted
     * Note: The token contract address is always the message sender
     * @param _operator  The address which called the `safeBatchTransferFrom` function
     * @param _from      The address which previously owned the token
     * @param _ids       An array containing ids of each token being transferred
     * @param _amounts   An array containing amounts of each token being transferred
     * @param _data      Additional data with no specified format
     * @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     */
    function onERC1155BatchReceived(
        address _operator,
        address _from,
        uint256[] calldata _ids,
        uint256[] calldata _amounts,
        bytes calldata _data
    ) external returns (bytes4);
}

interface IERC1155 {
    /****************************************|
  |                 Events                 |
  |_______________________________________*/

    /**
     * @dev Either TransferSingle or TransferBatch MUST emit when tokens are transferred, including zero amount transfers as well as minting or burning
     *   Operator MUST be msg.sender
     *   When minting/creating tokens, the `_from` field MUST be set to `0x0`
     *   When burning/destroying tokens, the `_to` field MUST be set to `0x0`
     *   The total amount transferred from address 0x0 minus the total amount transferred to 0x0 may be used by clients and exchanges to be added to the "circulating supply" for a given token ID
     *   To broadcast the existence of a token ID with no initial balance, the contract SHOULD emit the TransferSingle event from `0x0` to `0x0`, with the token creator as `_operator`, and a `_amount` of 0
     */
    event TransferSingle(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256 _id,
        uint256 _amount
    );

    /**
     * @dev Either TransferSingle or TransferBatch MUST emit when tokens are transferred, including zero amount transfers as well as minting or burning
     *   Operator MUST be msg.sender
     *   When minting/creating tokens, the `_from` field MUST be set to `0x0`
     *   When burning/destroying tokens, the `_to` field MUST be set to `0x0`
     *   The total amount transferred from address 0x0 minus the total amount transferred to 0x0 may be used by clients and exchanges to be added to the "circulating supply" for a given token ID
     *   To broadcast the existence of multiple token IDs with no initial balance, this SHOULD emit the TransferBatch event from `0x0` to `0x0`, with the token creator as `_operator`, and a `_amount` of 0
     */
    event TransferBatch(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256[] _ids,
        uint256[] _amounts
    );

    /**
     * @dev MUST emit when an approval is updated
     */
    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );

    /****************************************|
  |                Functions               |
  |_______________________________________*/

    /**
     * @notice Transfers amount of an _id from the _from address to the _to address specified
     * @dev MUST emit TransferSingle event on success
     * Caller must be approved to manage the _from account's tokens (see isApprovedForAll)
     * MUST throw if `_to` is the zero address
     * MUST throw if balance of sender for token `_id` is lower than the `_amount` sent
     * MUST throw on any other error
     * When transfer is complete, this function MUST check if `_to` is a smart contract (code size > 0). If so, it MUST call `onERC1155Received` on `_to` and revert if the return amount is not `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * @param _from    Source address
     * @param _to      Target address
     * @param _id      ID of the token type
     * @param _amount  Transfered amount
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount
    ) external;

    /**
     * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
     * @dev MUST emit TransferBatch event on success
     * Caller must be approved to manage the _from account's tokens (see isApprovedForAll)
     * MUST throw if `_to` is the zero address
     * MUST throw if length of `_ids` is not the same as length of `_amounts`
     * MUST throw if any of the balance of sender for token `_ids` is lower than the respective `_amounts` sent
     * MUST throw on any other error
     * When transfer is complete, this function MUST check if `_to` is a smart contract (code size > 0). If so, it MUST call `onERC1155BatchReceived` on `_to` and revert if the return amount is not `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * Transfers and events MUST occur in the array order they were submitted (_ids[0] before _ids[1], etc)
     * @param _from     Source addresses
     * @param _to       Target addresses
     * @param _ids      IDs of each token type
     * @param _amounts  Transfer amounts per token type
     */
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _amounts
    ) external;

    /**
     * @notice Get the balance of an account's Tokens
     * @param _owner  The address of the token holder
     * @param _id     ID of the Token
     * @return        The _owner's balance of the Token type requested
     */
    function balanceOf(address _owner, uint256 _id)
        external
        view
        returns (uint256);

    /**
     * @notice Get the balance of multiple account/token pairs
     * @param _owners The addresses of the token holders
     * @param _ids    ID of the Tokens
     * @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @notice Enable or disable approval for a third party ("operator") to manage all of caller's tokens
     * @dev MUST emit the ApprovalForAll event on success
     * @param _operator  Address to add to the set of authorized operators
     * @param _approved  True if the operator is approved, false to revoke approval
     */
    function setApprovalForAll(address _operator, bool _approved) external;

    /**
     * @notice Queries the approval status of an operator for a given owner
     * @param _owner     The owner of the Tokens
     * @param _operator  Address of authorized operator
     * @return isOperator True if the operator is approved, false if not
     */
    function isApprovedForAll(address _owner, address _operator)
        external
        view
        returns (bool isOperator);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

abstract contract ERC165 {
    /**
     * @notice Query if a contract implements an interface
     * @param _interfaceID The interface identifier, as specified in ERC-165
     * @return `true` if the contract implements `_interfaceID`
     */
    function supportsInterface(bytes4 _interfaceID)
        public
        pure
        virtual
        returns (bool)
    {
        return _interfaceID == this.supportsInterface.selector;
    }
}

contract ERC1155 is IERC1155, ERC165 {
    using SafeMath for uint256;
    using Address for address;

    /***********************************|
  |        Variables and Events       |
  |__________________________________*/

    // onReceive function signatures
    bytes4 internal constant ERC1155_RECEIVED_VALUE = 0xf23a6e61;
    bytes4 internal constant ERC1155_BATCH_RECEIVED_VALUE = 0xbc197c81;

    // Objects balances
    mapping(address => mapping(uint256 => uint256)) internal balances;

    // Operator Functions
    mapping(address => mapping(address => bool)) internal operators;

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount
    ) public override {
        require(
            (msg.sender == _from) || isApprovedForAll(_from, msg.sender),
            "ERC1155#safeTransferFrom: INVALID_OPERATOR"
        );
        require(
            _to != address(0),
            "ERC1155#safeTransferFrom: INVALID_RECIPIENT"
        );
        // require(_amount <= balances[_from][_id]) is not necessary since checked with safemath operations

        _safeTransferFrom(_from, _to, _id, _amount);
    }

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) public override {
        // Requirements
        require(
            (msg.sender == _from) || isApprovedForAll(_from, msg.sender),
            "ERC1155#safeBatchTransferFrom: INVALID_OPERATOR"
        );
        require(
            _to != address(0),
            "ERC1155#safeBatchTransferFrom: INVALID_RECIPIENT"
        );

        _safeBatchTransferFrom(_from, _to, _ids, _amounts);
    }

    function _safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount
    ) internal {
        // Update balances
        balances[_from][_id] = balances[_from][_id].sub(_amount); // Subtract amount
        balances[_to][_id] = balances[_to][_id].add(_amount); // Add amount

        // Emit event
        emit TransferSingle(msg.sender, _from, _to, _id, _amount);
    }

    function _safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) internal {
        require(
            _ids.length == _amounts.length,
            "ERC1155#_safeBatchTransferFrom: INVALID_ARRAYS_LENGTH"
        );

        // Number of transfer to execute
        uint256 nTransfer = _ids.length;

        // Executing all transfers
        for (uint256 i = 0; i < nTransfer; i++) {
            // Update storage balance of previous bin
            balances[_from][_ids[i]] = balances[_from][_ids[i]].sub(
                _amounts[i]
            );
            balances[_to][_ids[i]] = balances[_to][_ids[i]].add(_amounts[i]);
        }

        // Emit event
        emit TransferBatch(msg.sender, _from, _to, _ids, _amounts);
    }

    function setApprovalForAll(address _operator, bool _approved)
        external
        override
    {
        // Update operator status
        operators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /**
     * @notice Queries the approval status of an operator for a given owner
     * @param _owner     The owner of the Tokens
     * @param _operator  Address of authorized operator
     * @return isOperator True if the operator is approved, false if not
     */
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        virtual
        override
        returns (bool isOperator)
    {
        return operators[_owner][_operator];
    }

    function balanceOf(address _owner, uint256 _id)
        public
        view
        override
        returns (uint256)
    {
        return balances[_owner][_id];
    }

    /**
     * @notice Get the balance of multiple account/token pairs
     * @param _owners The addresses of the token holders
     * @param _ids    ID of the Tokens
     * @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(address[] memory _owners, uint256[] memory _ids)
        public
        view
        override
        returns (uint256[] memory)
    {
        require(
            _owners.length == _ids.length,
            "ERC1155#balanceOfBatch: INVALID_ARRAY_LENGTH"
        );

        // Variables
        uint256[] memory batchBalances = new uint256[](_owners.length);

        // Iterate over each owner and token ID
        for (uint256 i = 0; i < _owners.length; i++) {
            batchBalances[i] = balances[_owners[i]][_ids[i]];
        }

        return batchBalances;
    }
}

interface IERC1155Metadata {
    event URI(string _uri, uint256 indexed _id);

    function uri(uint256 _id) external view returns (string memory);
}

contract ERC1155Metadata is IERC1155Metadata, ERC165 {
    // URI's default URI prefix
    string internal baseMetadataURI;

    /***********************************|
  |     Metadata Public Function s    |
  |__________________________________*/

    /**
     * @notice A distinct Uniform Resource Identifier (URI) for a given token.
     * @dev URIs are defined in RFC 3986.
     *      URIs are assumed to be deterministically generated based on token ID
     * @return URI string
     */
    function uri(uint256 _id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return
            string(abi.encodePacked(baseMetadataURI, _uint2str(_id), ".json"));
    }

    /***********************************|
  |    Metadata Internal Functions    |
  |__________________________________*/

    /**
     * @notice Will emit default URI log event for corresponding token _id
     * @param _tokenIDs Array of IDs of tokens to log default URI
     */
    function _logURIs(uint256[] memory _tokenIDs) internal {
        string memory baseURL = baseMetadataURI;
        string memory tokenURI;

        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            tokenURI = string(
                abi.encodePacked(baseURL, _uint2str(_tokenIDs[i]), ".json")
            );
            emit URI(tokenURI, _tokenIDs[i]);
        }
    }

    /**
     * @notice Will update the base URL of token's URI
     * @param _newBaseMetadataURI New base URL of token's URI
     */
    function _setBaseMetadataURI(string memory _newBaseMetadataURI) internal {
        baseMetadataURI = _newBaseMetadataURI;
    }

    /***********************************|
  |    Utility Internal Functions     |
  |__________________________________*/

    /**
     * @notice Convert uint256 to string
     * @param _i Unsigned integer to convert to string
     */
    function _uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }

        uint256 j = _i;
        uint256 ii = _i;
        uint256 len;

        // Get number of bytes
        while (j != 0) {
            len++;
            j /= 10;
        }

        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;

        // Get each individual ASCII
        while (ii != 0) {
            bstr[k--] = bytes1(uint8(48 + (ii % 10)));
            ii /= 10;
        }

        // Convert to string
        return string(bstr);
    }
}

contract ERC1155MintBurn is ERC1155 {
    using SafeMath for uint256;

    /**
     * @notice Mint _amount of tokens of a given id
     * @param _to      The address to mint tokens to
     * @param _id      Token id to mint
     * @param _amount  The amount to be minted
     */
    function _mint(
        address _to,
        uint256 _id,
        uint256 _amount
    ) internal {
        // Add _amount
        balances[_to][_id] = balances[_to][_id].add(_amount);

        // Emit event
        emit TransferSingle(msg.sender, address(0x0), _to, _id, _amount);
    }

    /**
     * @notice Mint tokens for each ids in _ids
     * @param _to       The address to mint tokens to
     * @param _ids      Array of ids to mint
     * @param _amounts  Array of amount of tokens to mint per id
     */
    function _batchMint(
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) internal {
        require(
            _ids.length == _amounts.length,
            "ERC1155MintBurn#batchMint: INVALID_ARRAYS_LENGTH"
        );

        // Number of mints to execute
        uint256 nMint = _ids.length;

        // Executing all minting
        for (uint256 i = 0; i < nMint; i++) {
            // Update storage balance
            balances[_to][_ids[i]] = balances[_to][_ids[i]].add(_amounts[i]);
        }

        // Emit batch mint event
        emit TransferBatch(msg.sender, address(0x0), _to, _ids, _amounts);
    }

    /****************************************|
  |            Burning Functions           |
  |_______________________________________*/

    /**
     * @notice Burn _amount of tokens of a given token id
     * @param _from    The address to burn tokens from
     * @param _id      Token id to burn
     * @param _amount  The amount to be burned
     */
    function _burn(
        address _from,
        uint256 _id,
        uint256 _amount
    ) internal {
        //Substract _amount
        balances[_from][_id] = balances[_from][_id].sub(_amount);

        // Emit event
        emit TransferSingle(msg.sender, _from, address(0x0), _id, _amount);
    }

    /**
     * @notice Burn tokens of given token id for each (_ids[i], _amounts[i]) pair
     * @param _from     The address to burn tokens from
     * @param _ids      Array of token ids to burn
     * @param _amounts  Array of the amount to be burned
     */
    function _batchBurn(
        address _from,
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) internal {
        // Number of mints to execute
        uint256 nBurn = _ids.length;
        require(
            nBurn == _amounts.length,
            "ERC1155MintBurn#batchBurn: INVALID_ARRAYS_LENGTH"
        );

        // Executing all minting
        for (uint256 i = 0; i < nBurn; i++) {
            // Update storage balance
            balances[_from][_ids[i]] = balances[_from][_ids[i]].sub(
                _amounts[i]
            );
        }

        // Emit batch mint event
        emit TransferBatch(msg.sender, _from, address(0x0), _ids, _amounts);
    }
}

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

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

library Strings {
    // via https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol
    function strConcat(
        string memory _a,
        string memory _b,
        string memory _c,
        string memory _d,
        string memory _e
    ) internal pure returns (string memory) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(
            _ba.length + _bb.length + _bc.length + _bd.length + _be.length
        );
        bytes memory babcde = bytes(abcde);
        uint256 k = 0;
        for (uint256 i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (uint256 i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        for (uint256 i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
        for (uint256 i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
        for (uint256 i = 0; i < _be.length; i++) babcde[k++] = _be[i];
        return string(babcde);
    }

    function strConcat(
        string memory _a,
        string memory _b,
        string memory _c,
        string memory _d
    ) internal pure returns (string memory) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(
        string memory _a,
        string memory _b,
        string memory _c
    ) internal pure returns (string memory) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string memory _a, string memory _b)
        internal
        pure
        returns (string memory)
    {
        return strConcat(_a, _b, "", "", "");
    }

    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + (_i % 10)));
            _i /= 10;
        }
        return string(bstr);
    }
}

/**
 * @title ERC1155Tradable
 * ERC1155Tradable - ERC1155 contract that whitelists an operator address, has create and mint functionality, and supports useful standards from OpenZeppelin,
  like _exists(), name(), symbol(), and totalSupply()
 */
contract TDL_NFT is ERC1155, ERC1155MintBurn, ERC1155Metadata, Ownable {
    using SafeERC20 for IERC20;
    using Strings for string;
    using SafeMath for uint256;

    address public feeRecipient;
    uint256 public purchaseFee = 0;
    uint256 public auctionFee = 0;
    uint256 public totalSupply = 0;
    uint256 public idLength = 16;
    uint256 public auctionCount;
    uint256 public listCount;

    struct ListMap {
        address owner;
        uint256 price;
        uint256 token;
        uint256 amount;
    }

    struct nftInfo {
        uint256 id;
        uint256 supply;
        uint256 price;
        string uri;
    }

    struct auctionData {
        address owner;
        address lastBidder;
        uint256 bid;
        uint256 expiry;
        uint256 token;
        uint256 amount;
    }

    mapping(uint256 => uint256) public tokenSupply;
    mapping(uint256 => uint256) public defaultPrice;
    mapping(uint256 => uint256) private _price;
    mapping(uint256 => uint256) private _maxSupply;
    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => ListMap) public nftLists;
    mapping(uint256 => auctionData) public auctionList;

    uint256[] public nfts;

    // Contract name
    string public name = "Two Double Lucky";
    // Contract symbol
    string public symbol = "TDL";

    constructor(address _feerecipient) {
        feeRecipient = _feerecipient;
    }

    event AddList(uint256 id, uint256 price, uint256 amount);
    event AuctionStart(
        address creator,
        uint256 token,
        uint256 startingBid,
        uint256 auctionIndex,
        uint256 expiry
    );
    event AuctionEnd(
        uint256 token,
        uint256 finalBid,
        address owner,
        address newOwner,
        uint256 auctionIndex
    );
    event AuctionReset(
        uint256 auctionIndex,
        uint256 newExpiry,
        uint256 newPrice
    );
    event Bid(
        address bidder,
        uint256 token,
        uint256 auctionIndex,
        uint256 amount
    );
    event Buy(address newOwner, uint256 token, uint256 amount, uint256 price);

    modifier ownersOnly(uint256 _id, uint256 _amount) {
        require(
            balances[msg.sender][_id] >= _amount,
            "ERC1155Tradable#ownersOnly: ONLY_OWNERS_ALLOWED"
        );
        _;
    }

    function uri(uint256 _id) public view override returns (string memory) {
        return Strings.strConcat(baseMetadataURI, _tokenURIs[_id]);
    }

    /**
     * @dev Will update the base URL of token's URI
     * @param _newBaseMetadataURI New base URL of token's URI
     */
    function setBaseMetadataURI(string memory _newBaseMetadataURI)
        public
        onlyOwner
    {
        _setBaseMetadataURI(_newBaseMetadataURI);
    }

    function mint(
        address _to,
        uint256 _id,
        uint256 _supply,
        string calldata _uri
    ) public payable {
        require(_supply > 0, "supply is zero!");

        uint256 max = _maxSupply[_id];
        if (max == 0) max = 1;
        require(max >= tokenSupply[_id].add(_supply), "overflow max supply!");

        if (owner() != msg.sender) {
            uint256 __price = _price[_id];
            uint256 _type = getTypeFromId(_id);
            if (__price == 0) __price = defaultPrice[_type];

            require(
                msg.value >= __price.mul(_supply),
                "payment is not enough!"
            );
            payable(feeRecipient).transfer(msg.value);
        }

        if (bytes(_uri).length > 0) {
            _tokenURIs[_id] = _uri;
        }

        _mint(_to, _id, _supply);

        if (tokenSupply[_id] == 0) {
            nfts.push(_id);
            totalSupply++;
        }

        tokenSupply[_id] += _supply;
    }

    function burn(uint256 _id, uint256 _quantity) public {
        require(
            balances[msg.sender][_id] >= _quantity,
            "balance is not enough"
        );
        _burn(msg.sender, _id, _quantity);
        tokenSupply[_id] = tokenSupply[_id].sub(_quantity);
    }

    function getTypeFromId(uint256 id) public view returns (uint256) {
        return id.div(10**idLength);
    }

    function batchMint(
        address _to,
        uint256[] memory _ids,
        uint256[] memory _quantities
    ) public payable {
        uint256 prices;

        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 _id = _ids[i];
            uint256 quantity = _quantities[i];

            require(quantity > 0, "supply is zero!");
            uint256 max = _maxSupply[_id];
            if (max == 0) max = 1;
            require(
                max >= tokenSupply[_id].add(quantity),
                "overflow max supply!"
            );

            if (_price[_id] != 0) {
                prices += _price[_id].mul(quantity);
            } else {
                uint256 _type = getTypeFromId(_id);
                prices += defaultPrice[_type].mul(quantity);
            }

            if (tokenSupply[_id] == 0) {
                nfts.push(_id);
                totalSupply++;
            }
            tokenSupply[_id] += quantity;
        }

        if (owner() != msg.sender) {
            require(msg.value >= prices, "payment is not enough!");
            payable(feeRecipient).transfer(msg.value);
        }

        _batchMint(_to, _ids, _quantities);
    }

    function addList(
        uint256 _token,
        uint256 _amount,
        uint256 price_
    ) public ownersOnly(_token, _amount) {
        require(price_ > 0, "Price Cannot Be 0");
        require(_amount > 0, "Amount Cannot Be 0");

        _safeTransferFrom(msg.sender, address(this), _token, _amount);
        nftLists[listCount] = ListMap(msg.sender, price_, _token, _amount);
        listCount++;
        emit AddList(_token, price_, _amount);
    }

    function buy(uint256 _index) external payable {
        ListMap storage list = nftLists[_index];
        require(list.price != 0, "Already sold");
        require(
            msg.value >= list.price.mul(list.amount),
            "Value is not enough!"
        );

        uint256 feeAmount = msg.value.mul(purchaseFee).div(100);
        if (feeAmount > 0) payable(feeRecipient).transfer(feeAmount);
        payable(list.owner).transfer(msg.value.sub(feeAmount));
        _safeTransferFrom(address(this), msg.sender, list.token, list.amount);

        list.price = 0;
        emit Buy(msg.sender, list.token, list.amount, msg.value);
    }

    function concludeList(uint256 _index) external {
        ListMap storage list = nftLists[_index];
        require(list.price != 0, "Already conclude");
        require(list.owner == msg.sender, "Owner can Conclude");
        
        _safeTransferFrom(address(this), list.owner, list.token, list.amount);

        list.price = 0;
    }

    function bid(uint256 _index) public payable {
        require(auctionList[_index].expiry > block.timestamp);
        require(
            auctionList[_index].bid + 10000000000000000 <=
                msg.value.div(auctionList[_index].amount)
        );
        require(msg.sender != auctionList[_index].owner);
        require(msg.sender != auctionList[_index].lastBidder);
        if (auctionList[_index].lastBidder != address(0)) {
            payable(auctionList[_index].lastBidder).transfer(
                auctionList[_index].bid.mul(auctionList[_index].amount)
            );
        }
        auctionList[_index].bid = msg.value.div(auctionList[_index].amount);
        auctionList[_index].lastBidder = msg.sender;
        emit Bid(msg.sender, auctionList[_index].token, _index, msg.value);
    }

    function createAuctionAdmin(
        uint256[] memory _token,
        uint256 _expiry,
        uint256[] memory _amount,
        uint256[] memory price_
    ) public onlyOwner {
        require(_token.length == _amount.length && _amount.length == price_.length, "length not match!");
        
        batchMint(msg.sender, _token, _amount);
        for(uint256 i = 0; i < _token.length; i ++) {
            createAuction(price_[i], _expiry, _token[i], _amount[i]);
        }
    }

    function createAuction(
        uint256 price_,
        uint256 _expiry,
        uint256 _token,
        uint256 _amount
    ) public ownersOnly(_token, _amount) {
        require(block.timestamp < _expiry, "Auction Date Passed");
        require(price_ > 0, "Auction Price Cannot Be 0");
        _safeTransferFrom(msg.sender, address(this), _token, _amount);
        auctionList[auctionCount] = auctionData(
            msg.sender,
            address(0),
            price_,
            _expiry,
            _token,
            _amount
        );
        emit AuctionStart(msg.sender, _token, price_, auctionCount, _expiry);
        auctionCount++;
    }

    function resetAuction(
        uint256 _index,
        uint256 _expiry,
        uint256 price_,
        uint256 _amount
    ) public {
        require(
            msg.sender == auctionList[_index].owner,
            "You Dont Own This Auction!"
        );
        require(
            _amount >= auctionList[_index].amount,
            "Amount is small than before!"
        );
        require(
            address(0) == auctionList[_index].lastBidder,
            "Someone Won This Auction!"
        );
        require(
            auctionList[_index].expiry < block.timestamp,
            "Auction Is Still Running"
        );
        require(_expiry > block.timestamp, "Auction Date Passed");
        auctionList[_index].expiry = _expiry;
        auctionList[_index].bid = price_;

        if (_amount > auctionList[_index].amount) {
            require(
                balances[msg.sender][auctionList[_index].token] >=
                    _amount.sub(auctionList[_index].amount),
                "ERC1155Tradable#ownersOnly: ONLY_OWNERS_ALLOWED"
            );
            auctionList[_index].amount = _amount;
            _safeTransferFrom(
                msg.sender,
                address(this),
                auctionList[_index].token,
                _amount.sub(auctionList[_index].amount)
            );
        }
        emit AuctionReset(_index, _expiry, price_);
    }

    function concludeAuction(uint256 _index) public {
        require(
            auctionList[_index].expiry < block.timestamp,
            "Auction Not Expired"
        );
        require(auctionList[_index].bid != 0, "Auction Concluded");
        require(auctionList[_index].owner == msg.sender, "Owner can Conclude");

        if (auctionList[_index].lastBidder != address(0)) {
            _safeTransferFrom(
                address(this),
                auctionList[_index].lastBidder,
                auctionList[_index].token,
                auctionList[_index].amount
            );
            uint256 fee = auctionList[_index].bid.mul(auctionFee).div(100);
            if(fee > 0) payable(feeRecipient).transfer(fee);
            payable(auctionList[_index].owner).transfer(
                auctionList[_index].bid.sub(fee)
            );
            emit AuctionEnd(
                auctionList[_index].token,
                auctionList[_index].bid,
                auctionList[_index].owner,
                auctionList[_index].lastBidder,
                _index
            );
        } else {
            _safeTransferFrom(
                address(this),
                auctionList[_index].owner,
                auctionList[_index].token,
                auctionList[_index].amount
            );
            emit AuctionEnd(
                auctionList[_index].token,
                0,
                auctionList[_index].owner,
                auctionList[_index].owner,
                _index
            );
        }
        auctionList[_index].lastBidder = address(0);
        auctionList[_index].bid = 0;
    }

    function setPrice(uint256[] memory ids, uint256[] memory prices)
        external
        onlyOwner
    {
        require(ids.length == prices.length, "length is not match!");

        for (uint256 i = 0; i < ids.length; i++) {
            _price[ids[i]] = prices[i];
        }
    }

    function setMaxSupply(uint256[] memory ids, uint256[] memory supply)
        external
        onlyOwner
    {
        require(ids.length == supply.length, "length is not match!");

        for (uint256 i = 0; i < ids.length; i++) {
            _maxSupply[ids[i]] = supply[i];
        }
    }

    function getAllNfts() public view returns (nftInfo[] memory allNft) {
        allNft = new nftInfo[](nfts.length);
        for (uint256 i = 0; i < nfts.length; i++) {
            uint256 id = nfts[i];
            uint256 _type = getTypeFromId(id);
            allNft[i] = nftInfo(
                id,
                tokenSupply[id],
                _price[id] != 0 ? _price[id] : defaultPrice[_type],
                uri(id)
            );
        }
    }
    
    function getAllAuctions() public view returns (auctionData[] memory allNft) {
        allNft = new auctionData[](auctionCount);
      
        for (uint256 i = 0; i < auctionCount; i++) {
            auctionData memory auction = auctionList[i];
            allNft[i] = auction;
        }
    }
    
    function getAllLists() public view returns (ListMap[] memory allNft) {
        allNft = new ListMap[](auctionCount);
      
        for (uint256 i = 0; i < auctionCount; i++) {
            ListMap memory list = nftLists[i];
            allNft[i] = list;
        }
    }

    function price(uint256 id) public view returns (uint256) {
        uint256 _type = getTypeFromId(id);
        return _price[id] != 0 ? _price[id] : defaultPrice[_type];
    }

    function maxSupply(uint256 id) public view returns (uint256) {
        return _maxSupply[id] != 0 ? _maxSupply[id] : 1;
    }

    function setFeeRecipient(address _recipient) external onlyOwner {
        feeRecipient = _recipient;
    }

    function setDefaultPrice(uint256 __price, uint256 _type)
        external
        onlyOwner
    {
        defaultPrice[_type] = __price;
    }

    function setAuctionFee(uint256 _newFee) public onlyOwner {
        require(_newFee < 100, "Fee Too High!");
        auctionFee = _newFee;
    }

    function setPurchaseFee(uint256 _fee) external onlyOwner {
        purchaseFee = _fee;
    }
}