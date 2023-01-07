/**
 *Submitted for verification at Etherscan.io on 2023-01-07
*/

/**
 *Submitted for verification at BscScan.com on 2022-03-25
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

contract NftMarket is ERC1155, ERC1155MintBurn, ERC1155Metadata, Ownable {
    using SafeERC20 for IERC20;
    using Strings for string;
    using SafeMath for uint256;

    mapping(address => bool) public isAuthority;
    uint256 public fees = 3000; // 30%
    address public feesDestination;
    IERC20 public feesToken;

    struct CollectionItem {
        uint256 cId;
        string name;
        string symbol;
        uint256 fees;
        bool ignoreCreatorFee;
        bool requiredVerifier;
        uint256 totalSupply;
        uint256 listedNftItems;
    }

    struct NftItem {
        uint256 cId;
        uint256 tokenId;
        uint256 price;
        address creator;
        address owner;
        string tokenURI;
        uint256 amount;
        uint256 creatorFees;
        bool isListed;
    }

    struct BuyOffer {
        uint256 cId;
        uint256 tId;
        uint256 offerId;
        uint256 proposedPrice;
        address authority;
    }

    mapping(uint256 => CollectionItem) public _idToCollection;
    uint256 public _listedCollections = 0;
    mapping(uint256 => mapping(uint256 => uint256)) public _ownedTokenByCollection;

    mapping (uint256 => string) private _tokenURIs;
    mapping(string => bool) private _usedTokenURIs;

    uint256 public totalSupply = 0;
    // uint256 public _listedItems = 0;
    mapping(uint256 => NftItem) public _idToNftItem;

    uint256 public _listedOffers = 0;
    mapping(uint256 => mapping(uint256 => uint256)) private _ownedOfferByCollection;
    mapping(uint256 => BuyOffer) public _idToBuyOffer;

    event NftItemCreated (
      uint256 tokenId,
      uint256 price,
      address creator,
      address owner,
      string tokenURI,
      uint256 amount,
      bool isListed
    );

    constructor(address _feesDestination, IERC20 _feesToken) {
        isAuthority[msg.sender] = true;
        feesDestination = _feesDestination;
        feesToken = _feesToken;
    }

    modifier ownerOnly(uint256 _id) {
      require(balances[msg.sender][_id] > 0, "Ownable: caller is not the owner");
      _;
    }

    function createCollection(string memory name, string memory symbol, uint256 fee, bool ignoreFee) external onlyOwner {
      uint256 cId = getCollectionID();

      _idToCollection[cId] = CollectionItem(
        cId,
        name,
        symbol,
        fee,
        ignoreFee,
        true,
        0,
        0
      );

      incrementCollection();
    }

    function updateCollection(uint256 cId, string memory name, string memory symbol, uint256 fee, bool ignoreFee, bool verifier) external onlyOwner {
      _idToCollection[cId].name = name;
      _idToCollection[cId].symbol = symbol;
      _idToCollection[cId].fees = fee;
      _idToCollection[cId].ignoreCreatorFee = ignoreFee;
      _idToCollection[cId].requiredVerifier = verifier;
    }

    function mintToken(uint256 cId, string memory tokenURI, uint256 price, uint256 creatorFees) public returns (uint256) {
    //   require(!tokenURIExists(tokenURI), "Token URI already exists");
      // require(msg.value == listingPrice, "Price must be equal to listing price");
      
      _idToCollection[cId].totalSupply ++;
      uint256 ctID = _idToCollection[cId].totalSupply;

      uint256 newTokenId = getTokenID();
      _mint(msg.sender, newTokenId, 1);

      _tokenURIs[newTokenId] = tokenURI;
      _createNftItem(cId, newTokenId, price, tokenURI, 1, creatorFees);
      _usedTokenURIs[tokenURI] = true;

      _ownedTokenByCollection[cId][ctID] = newTokenId;
      
      incrementTokens();
      incrementListedItems(cId);

      return newTokenId;
    }

    function _createNftItem(
      uint256 cId,
      uint256 tokenId,
      uint256 price,
      string memory tokenURI,
      uint256 amount,
      uint256 creatorFees
    ) private {
      require(price > 0, "Price must be at least 1 wei");

      _safeTransferFrom(msg.sender, address(this), tokenId, 1);

      _idToNftItem[tokenId] = NftItem(
        cId,
        tokenId,
        price,
        msg.sender,
        msg.sender,
        tokenURI,
        amount,
        creatorFees,
        true
      );

      emit NftItemCreated(tokenId, price, msg.sender, msg.sender, tokenURI, amount, true);
    }

    function createSellOrder(uint256 tokenId, uint256 newPrice) public ownerOnly(tokenId) {
        require(_idToNftItem[tokenId].isListed == false, "Item is already on sale");

        _safeTransferFrom(msg.sender, address(this), tokenId, 1);

        _idToNftItem[tokenId].isListed = true;
        _idToNftItem[tokenId].price = newPrice;

        uint256 cId = _idToNftItem[tokenId].cId;
        incrementListedItems(cId);
    }

    function removeSellOrder(uint256 tokenId) public {
        require(_idToNftItem[tokenId].isListed == true, "Item has already been removed");
        require(_idToNftItem[tokenId].owner == msg.sender, "You are not an Owner of this NFT");

        _safeTransferFrom(address(this), msg.sender, tokenId, 1);
        
        _idToNftItem[tokenId].isListed = false;

        uint256 cId = _idToNftItem[tokenId].cId;
        decrementListedItems(cId);
    }

    function buy(uint256 tokenId) external {

        address buyer = msg.sender;
        uint256 price = _idToNftItem[tokenId].price;
        uint256 userBalance = feesToken.balanceOf(buyer);
        address owner = _idToNftItem[tokenId].owner;

        require(buyer != owner, "You already own this NFT");
        require(userBalance >= price, "Error, not enough your feeToken balance!");

        _idToNftItem[tokenId].isListed = false;
        _idToNftItem[tokenId].owner = buyer;

        uint256 cId = _idToNftItem[tokenId].cId;
        decrementListedItems(cId);

        _safeTransferFrom(address(this), buyer, tokenId, 1);
        _trade(tokenId, owner, buyer, price);
    }

    function createBuyOffer(uint256 cId, uint256 tId, uint256 price) external {
        require(price > 0, "Price must be at least 1 wei");

        uint256 offerId = getOfferID();

        _idToBuyOffer[offerId] = BuyOffer(
            cId,
            tId,
            offerId,
            price,
            msg.sender
        );

        _ownedOfferByCollection[cId][offerId] = offerId;

        // feesToken.safeTransferFrom(msg.sender, address(this), price);
        incrementOffer();
    }

    function removeBuyOffer(uint256 offerId) external {
        require(offerId <= _listedOffers, "This offer does not exist");

        BuyOffer storage buyOffer = _idToBuyOffer[offerId];
        uint256 cId = buyOffer.cId;
        uint256 price = buyOffer.proposedPrice;
        uint256 contractBalance = feesToken.balanceOf(address(this));

        require(buyOffer.authority == msg.sender, "This is not an authority of the offer");
        require(contractBalance >= price, "Error, not enough contract token balance!");

        // feesToken.safeTransfer(msg.sender, price);

        delete _ownedOfferByCollection[cId][offerId];
        delete _idToBuyOffer[offerId];
    }

    // wrong part
    function executeOffer(uint256 offerId) external {
        require(offerId <= _listedOffers, "This offer does not exist");

        BuyOffer storage buyOffer = _idToBuyOffer[offerId];
        uint256 tokenId = buyOffer.tId;
        address buyer = buyOffer.authority;

        require(_idToNftItem[tokenId].owner == msg.sender, "You are not an Owner of this NFT");

        uint256 price = buyOffer.proposedPrice;
        uint256 userBalance = feesToken.balanceOf(buyer);
        address owner = _idToNftItem[tokenId].owner;

        require(buyer != owner, "You already own this NFT");
        require(userBalance >= price, "Error, not enough your feeToken balance!");

        _idToNftItem[tokenId].isListed = false;
        _idToNftItem[tokenId].owner = buyer;

        uint256 cId = _idToNftItem[tokenId].cId;
        decrementListedItems(cId);

        _safeTransferFrom(address(this), buyer, tokenId, 1);
        _trade(tokenId, owner, buyer, price);
        _removeRemainOffers(tokenId);
    }

    function _trade(uint256 tokenId, address _owner, address _buyer, uint256 amount) internal {

      uint256 cId = _idToNftItem[tokenId].cId;
      uint256 creatorFees = _idToNftItem[tokenId].creatorFees;
      address creator = _idToNftItem[tokenId].creator;
      
      bool ignoreCreatorFee = _idToCollection[cId].ignoreCreatorFee;
      
      // 30 % commission cut
      uint256 _commissionValue = amount.mul(fees).div(10000);

      uint256 creatorShare = 0;
      if (!ignoreCreatorFee) {
       creatorShare = amount.mul(creatorFees).div(10000);
      }

      uint256 _sellerValue = amount.sub(_commissionValue).sub(creatorShare);

      if (_sellerValue > 0) {
       feesToken.safeTransferFrom(_buyer, _owner, _sellerValue);
      }

      if (_commissionValue > 0) {
       feesToken.safeTransferFrom(_buyer, feesDestination, _commissionValue);
      }

      if (ignoreCreatorFee && creatorShare > 0) {
       feesToken.safeTransferFrom(_buyer, creator, creatorShare);
      }
    }

    function _removeRemainOffers(uint256 tokenId) internal {
        uint256 allItemsCounts = _listedOffers;
        NftItem storage nftItem = _idToNftItem[tokenId];

        for (uint256 i = 0; i < allItemsCounts; i++) {
           uint256 offerId = i + 1;
           BuyOffer storage offerItem = _idToBuyOffer[offerId];

            if (offerItem.cId == nftItem.cId && offerItem.tId == nftItem.tokenId) {
                delete _ownedOfferByCollection[offerItem.cId][offerId];
                delete _idToBuyOffer[offerId];
            }
        }
    }
    
    function tokenURIExists(string memory tokenURI) public view returns (bool) {
      return _usedTokenURIs[tokenURI] == true;
    }

    function decrementListedItems(uint256 cId) private  {
        _idToCollection[cId].listedNftItems --;
    }

    function incrementListedItems(uint256 cId) private  {
        _idToCollection[cId].listedNftItems ++;
    }

    function getTokenID() private view returns (uint) {
      return totalSupply.add(1);
    }

    function incrementTokens() private  {
      totalSupply++;
    }

    function getCollectionID() private view returns (uint) {
      return _listedCollections.add(1);
    }

    function incrementCollection() private  {
      _listedCollections++;
    }

    function getOfferID() private view returns (uint) {
      return _listedOffers.add(1);
    }

    function incrementOffer() private  {
      _listedOffers++;
    }

    function setAuthority(address _addr, bool _is) external onlyOwner {
        isAuthority[_addr] = _is;
    }

    function setFeesDestination(address _destination) external onlyOwner {
        feesDestination = _destination;
    }

    function setFees(uint256 _fee) external onlyOwner {
        fees = _fee;
    }

    function setFeesToken(IERC20 _tokenAddr) external onlyOwner {
        feesToken = _tokenAddr;
    }

    function getAllCollectionItems() public view returns (CollectionItem[] memory) {
        CollectionItem[] memory items = new CollectionItem[](_listedCollections);

        for (uint256 i = 0; i < _listedCollections; i++) {
            uint256 cId = i + 1;
            CollectionItem storage item = _idToCollection[cId];
            items[i] = item;
        }

        return items;
    }

    function getAllNftsOnSale(uint256 cId) public view returns (NftItem[] memory) {
        uint256 allItemsCounts = _idToCollection[cId].totalSupply;
        uint256 currentIndex = 0;
        NftItem[] memory items = new NftItem[](_idToCollection[cId].listedNftItems);

        for (uint256 i = 0; i < allItemsCounts; i++) {
            uint256 tokenId = _ownedTokenByCollection[cId][i + 1];
            NftItem storage item = _idToNftItem[tokenId];

            if (item.isListed == true) {
                items[currentIndex] = item;
                currentIndex += 1;
            }
        }

        return items;
    }

    function getOwnedNfts() public view returns (NftItem[] memory) {
        uint256 currentIndex = 0;
        uint256 ownedItemsCount = 0;
        
        for (uint256 i = 0; i < totalSupply; i++) {
            uint256 tokenId = i + 1;
            NftItem storage item = _idToNftItem[tokenId];
            
            if (item.owner == msg.sender) {
                ownedItemsCount++;
            }
        }

        NftItem[] memory items = new NftItem[](ownedItemsCount);

        for (uint256 i = 0; i < totalSupply; i++) {
            uint256 tokenId = i + 1;
            NftItem storage item = _idToNftItem[tokenId];

            if (item.owner == msg.sender) {
                items[currentIndex] = item;
                currentIndex += 1;
            }
        }

        return items;
    }

    function getAllOffers(uint256 tId) public view returns (BuyOffer[] memory) {
        uint256 currentIndex = 0;
        uint256 ownedItemsCount = 0;

        uint256 allItemsCounts = _listedOffers;
        NftItem storage nftItem = _idToNftItem[tId];

        for (uint256 i = 0; i < allItemsCounts; i++) {
           uint256 offerId = i + 1;
           BuyOffer storage offerItem = _idToBuyOffer[offerId];

            if (offerItem.cId == nftItem.cId && offerItem.tId == nftItem.tokenId) {
                ownedItemsCount++;
            }
        }

        BuyOffer[] memory items = new BuyOffer[](ownedItemsCount);

        for (uint256 i = 0; i < allItemsCounts; i++) {
           uint256 offerId = i + 1;
           BuyOffer storage offerItem = _idToBuyOffer[offerId];

            if (offerItem.cId == nftItem.cId && offerItem.tId == nftItem.tokenId) {
                items[currentIndex] = offerItem;
                currentIndex += 1;
            }
        }

        return items;
    }

    function getOwnedOffers() public view returns (BuyOffer[] memory) {
        uint256 currentIndex = 0;
        uint256 ownedItemsCount = 0;

        uint256 allItemsCounts = _listedOffers;

        for (uint256 i = 0; i < allItemsCounts; i++) {
           uint256 offerId = i + 1;
           BuyOffer storage offerItem = _idToBuyOffer[offerId];

            if (offerItem.authority == msg.sender) {
                ownedItemsCount++;
            }
        }

        BuyOffer[] memory items = new BuyOffer[](ownedItemsCount);

        for (uint256 i = 0; i < allItemsCounts; i++) {
           uint256 offerId = i + 1;
           BuyOffer storage offerItem = _idToBuyOffer[offerId];

            if (offerItem.authority == msg.sender) {
                items[currentIndex] = offerItem;
                currentIndex += 1;
            }
        }

        return items;
    }

}