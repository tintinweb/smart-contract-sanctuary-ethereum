// SPDX-License-Identifier: UNLICENSED

// Sources flattened with hardhat v2.9.3 https://hardhat.org

// File @0xsequence/erc-1155/contracts/utils/[email protected]

pragma solidity 0.7.4;


/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {

  /**
   * @dev Multiplies two unsigned integers, reverts on overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath#mul: OVERFLOW");

    return c;
  }

  /**
   * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath#div: DIVISION_BY_ZERO");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath#sub: UNDERFLOW");
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Adds two unsigned integers, reverts on overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath#add: OVERFLOW");

    return c; 
  }

  /**
   * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
   * reverts when dividing by zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath#mod: DIVISION_BY_ZERO");
    return a % b;
  }
}


// File @0xsequence/erc-1155/contracts/interfaces/[email protected]

pragma solidity 0.7.4;

/**
 * @dev ERC-1155 interface for accepting safe transfers.
 */
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
  function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _amount, bytes calldata _data) external returns(bytes4);

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
  function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external returns(bytes4);
}


// File @0xsequence/erc-1155/contracts/interfaces/[email protected]

pragma solidity 0.7.4;


/**
 * @title ERC165
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
 */
interface IERC165 {

    /**
     * @notice Query if a contract implements an interface
     * @dev Interface identification is specified in ERC-165. This function
     * uses less than 30,000 gas
     * @param _interfaceId The interface identifier, as specified in ERC-165
     */
    function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}


// File @0xsequence/erc-1155/contracts/interfaces/[email protected]

pragma solidity 0.7.4;

interface IERC1155 is IERC165 {

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
  event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _amount);

  /**
   * @dev Either TransferSingle or TransferBatch MUST emit when tokens are transferred, including zero amount transfers as well as minting or burning
   *   Operator MUST be msg.sender
   *   When minting/creating tokens, the `_from` field MUST be set to `0x0`
   *   When burning/destroying tokens, the `_to` field MUST be set to `0x0`
   *   The total amount transferred from address 0x0 minus the total amount transferred to 0x0 may be used by clients and exchanges to be added to the "circulating supply" for a given token ID
   *   To broadcast the existence of multiple token IDs with no initial balance, this SHOULD emit the TransferBatch event from `0x0` to `0x0`, with the token creator as `_operator`, and a `_amount` of 0
   */
  event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _amounts);

  /**
   * @dev MUST emit when an approval is updated
   */
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);


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
    * @param _data    Additional data with no specified format, sent in call to `_to`
    */
  function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes calldata _data) external;

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
    * @param _data     Additional data with no specified format, sent in call to `_to`
  */
  function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external;

  /**
   * @notice Get the balance of an account's Tokens
   * @param _owner  The address of the token holder
   * @param _id     ID of the Token
   * @return        The _owner's balance of the Token type requested
   */
  function balanceOf(address _owner, uint256 _id) external view returns (uint256);

  /**
   * @notice Get the balance of multiple account/token pairs
   * @param _owners The addresses of the token holders
   * @param _ids    ID of the Tokens
   * @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
   */
  function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);

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
  function isApprovedForAll(address _owner, address _operator) external view returns (bool isOperator);
}


// File @0xsequence/erc-1155/contracts/utils/[email protected]

pragma solidity 0.7.4;


/**
 * Utility library of inline functions on addresses
 */
library Address {

  // Default hash for EOA accounts returned by extcodehash
  bytes32 constant internal ACCOUNT_HASH = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract.
   * @param _address address of the account to check
   * @return Whether the target address is a contract
   */
  function isContract(address _address) internal view returns (bool) {
    bytes32 codehash;

    // Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address or if it has a non-zero code hash or account hash
    assembly { codehash := extcodehash(_address) }
    return (codehash != 0x0 && codehash != ACCOUNT_HASH);
  }
}


// File @0xsequence/erc-1155/contracts/utils/[email protected]

pragma solidity 0.7.4;

abstract contract ERC165 is IERC165 {
  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceID The interface identifier, as specified in ERC-165
   * @return `true` if the contract implements `_interfaceID`
   */
  function supportsInterface(bytes4 _interfaceID) virtual override public pure returns (bool) {
    return _interfaceID == this.supportsInterface.selector;
  }
}


// File @0xsequence/erc-1155/contracts/tokens/ERC1155/[email protected]

pragma solidity 0.7.4;





/**
 * @dev Implementation of Multi-Token Standard contract
 */
contract ERC1155 is IERC1155, ERC165 {
  using SafeMath for uint256;
  using Address for address;

  /***********************************|
  |        Variables and Events       |
  |__________________________________*/

  // onReceive function signatures
  bytes4 constant internal ERC1155_RECEIVED_VALUE = 0xf23a6e61;
  bytes4 constant internal ERC1155_BATCH_RECEIVED_VALUE = 0xbc197c81;

  // Objects balances
  mapping (address => mapping(uint256 => uint256)) internal balances;

  // Operator Functions
  mapping (address => mapping(address => bool)) internal operators;


  /***********************************|
  |     Public Transfer Functions     |
  |__________________________________*/

  /**
   * @notice Transfers amount amount of an _id from the _from address to the _to address specified
   * @param _from    Source address
   * @param _to      Target address
   * @param _id      ID of the token type
   * @param _amount  Transfered amount
   * @param _data    Additional data with no specified format, sent in call to `_to`
   */
  function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes memory _data)
    public override
  {
    require((msg.sender == _from) || isApprovedForAll(_from, msg.sender), "ERC1155#safeTransferFrom: INVALID_OPERATOR");
    require(_to != address(0),"ERC1155#safeTransferFrom: INVALID_RECIPIENT");
    // require(_amount <= balances[_from][_id]) is not necessary since checked with safemath operations

    _safeTransferFrom(_from, _to, _id, _amount);
    _callonERC1155Received(_from, _to, _id, _amount, gasleft(), _data);
  }

  /**
   * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
   * @param _from     Source addresses
   * @param _to       Target addresses
   * @param _ids      IDs of each token type
   * @param _amounts  Transfer amounts per token type
   * @param _data     Additional data with no specified format, sent in call to `_to`
   */
  function safeBatchTransferFrom(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data)
    public override
  {
    // Requirements
    require((msg.sender == _from) || isApprovedForAll(_from, msg.sender), "ERC1155#safeBatchTransferFrom: INVALID_OPERATOR");
    require(_to != address(0), "ERC1155#safeBatchTransferFrom: INVALID_RECIPIENT");

    _safeBatchTransferFrom(_from, _to, _ids, _amounts);
    _callonERC1155BatchReceived(_from, _to, _ids, _amounts, gasleft(), _data);
  }


  /***********************************|
  |    Internal Transfer Functions    |
  |__________________________________*/

  /**
   * @notice Transfers amount amount of an _id from the _from address to the _to address specified
   * @param _from    Source address
   * @param _to      Target address
   * @param _id      ID of the token type
   * @param _amount  Transfered amount
   */
  function _safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount)
    internal
  {
    // Update balances
    balances[_from][_id] = balances[_from][_id].sub(_amount); // Subtract amount
    balances[_to][_id] = balances[_to][_id].add(_amount);     // Add amount

    // Emit event
    emit TransferSingle(msg.sender, _from, _to, _id, _amount);
  }

  /**
   * @notice Verifies if receiver is contract and if so, calls (_to).onERC1155Received(...)
   */
  function _callonERC1155Received(address _from, address _to, uint256 _id, uint256 _amount, uint256 _gasLimit, bytes memory _data)
    internal
  {
    // Check if recipient is contract
    if (_to.isContract()) {
      bytes4 retval = IERC1155TokenReceiver(_to).onERC1155Received{gas: _gasLimit}(msg.sender, _from, _id, _amount, _data);
      require(retval == ERC1155_RECEIVED_VALUE, "ERC1155#_callonERC1155Received: INVALID_ON_RECEIVE_MESSAGE");
    }
  }

  /**
   * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
   * @param _from     Source addresses
   * @param _to       Target addresses
   * @param _ids      IDs of each token type
   * @param _amounts  Transfer amounts per token type
   */
  function _safeBatchTransferFrom(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts)
    internal
  {
    require(_ids.length == _amounts.length, "ERC1155#_safeBatchTransferFrom: INVALID_ARRAYS_LENGTH");

    // Number of transfer to execute
    uint256 nTransfer = _ids.length;

    // Executing all transfers
    for (uint256 i = 0; i < nTransfer; i++) {
      // Update storage balance of previous bin
      balances[_from][_ids[i]] = balances[_from][_ids[i]].sub(_amounts[i]);
      balances[_to][_ids[i]] = balances[_to][_ids[i]].add(_amounts[i]);
    }

    // Emit event
    emit TransferBatch(msg.sender, _from, _to, _ids, _amounts);
  }

  /**
   * @notice Verifies if receiver is contract and if so, calls (_to).onERC1155BatchReceived(...)
   */
  function _callonERC1155BatchReceived(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts, uint256 _gasLimit, bytes memory _data)
    internal
  {
    // Pass data if recipient is contract
    if (_to.isContract()) {
      bytes4 retval = IERC1155TokenReceiver(_to).onERC1155BatchReceived{gas: _gasLimit}(msg.sender, _from, _ids, _amounts, _data);
      require(retval == ERC1155_BATCH_RECEIVED_VALUE, "ERC1155#_callonERC1155BatchReceived: INVALID_ON_RECEIVE_MESSAGE");
    }
  }


  /***********************************|
  |         Operator Functions        |
  |__________________________________*/

  /**
   * @notice Enable or disable approval for a third party ("operator") to manage all of caller's tokens
   * @param _operator  Address to add to the set of authorized operators
   * @param _approved  True if the operator is approved, false to revoke approval
   */
  function setApprovalForAll(address _operator, bool _approved)
    external override
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
    public override view returns (bool isOperator)
  {
    return operators[_owner][_operator];
  }


  /***********************************|
  |         Balance Functions         |
  |__________________________________*/

  /**
   * @notice Get the balance of an account's Tokens
   * @param _owner  The address of the token holder
   * @param _id     ID of the Token
   * @return The _owner's balance of the Token type requested
   */
  function balanceOf(address _owner, uint256 _id)
    public override view returns (uint256)
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
    public override view returns (uint256[] memory)
  {
    require(_owners.length == _ids.length, "ERC1155#balanceOfBatch: INVALID_ARRAY_LENGTH");

    // Variables
    uint256[] memory batchBalances = new uint256[](_owners.length);

    // Iterate over each owner and token ID
    for (uint256 i = 0; i < _owners.length; i++) {
      batchBalances[i] = balances[_owners[i]][_ids[i]];
    }

    return batchBalances;
  }


  /***********************************|
  |          ERC165 Functions         |
  |__________________________________*/

  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceID  The interface identifier, as specified in ERC-165
   * @return `true` if the contract implements `_interfaceID` and
   */
  function supportsInterface(bytes4 _interfaceID) public override(ERC165, IERC165) virtual pure returns (bool) {
    if (_interfaceID == type(IERC1155).interfaceId) {
      return true;
    }
    return super.supportsInterface(_interfaceID);
  }
}


// File @0xsequence/erc-1155/contracts/tokens/ERC1155/[email protected]

pragma solidity 0.7.4;

/**
 * @dev Multi-Fungible Tokens with minting and burning methods. These methods assume
 *      a parent contract to be executed as they are `internal` functions
 */
contract ERC1155MintBurn is ERC1155 {
  using SafeMath for uint256;

  /****************************************|
  |            Minting Functions           |
  |_______________________________________*/

  /**
   * @notice Mint _amount of tokens of a given id
   * @param _to      The address to mint tokens to
   * @param _id      Token id to mint
   * @param _amount  The amount to be minted
   * @param _data    Data to pass if receiver is contract
   */
  function _mint(address _to, uint256 _id, uint256 _amount, bytes memory _data)
    internal
  {
    // Add _amount
    balances[_to][_id] = balances[_to][_id].add(_amount);

    // Emit event
    emit TransferSingle(msg.sender, address(0x0), _to, _id, _amount);

    // Calling onReceive method if recipient is contract
    _callonERC1155Received(address(0x0), _to, _id, _amount, gasleft(), _data);
  }

  /**
   * @notice Mint tokens for each ids in _ids
   * @param _to       The address to mint tokens to
   * @param _ids      Array of ids to mint
   * @param _amounts  Array of amount of tokens to mint per id
   * @param _data    Data to pass if receiver is contract
   */
  function _batchMint(address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data)
    internal
  {
    require(_ids.length == _amounts.length, "ERC1155MintBurn#batchMint: INVALID_ARRAYS_LENGTH");

    // Number of mints to execute
    uint256 nMint = _ids.length;

     // Executing all minting
    for (uint256 i = 0; i < nMint; i++) {
      // Update storage balance
      balances[_to][_ids[i]] = balances[_to][_ids[i]].add(_amounts[i]);
    }

    // Emit batch mint event
    emit TransferBatch(msg.sender, address(0x0), _to, _ids, _amounts);

    // Calling onReceive method if recipient is contract
    _callonERC1155BatchReceived(address(0x0), _to, _ids, _amounts, gasleft(), _data);
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
  function _burn(address _from, uint256 _id, uint256 _amount)
    internal
  {
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
  function _batchBurn(address _from, uint256[] memory _ids, uint256[] memory _amounts)
    internal
  {
    // Number of mints to execute
    uint256 nBurn = _ids.length;
    require(nBurn == _amounts.length, "ERC1155MintBurn#batchBurn: INVALID_ARRAYS_LENGTH");

    // Executing all minting
    for (uint256 i = 0; i < nBurn; i++) {
      // Update storage balance
      balances[_from][_ids[i]] = balances[_from][_ids[i]].sub(_amounts[i]);
    }

    // Emit batch mint event
    emit TransferBatch(msg.sender, _from, address(0x0), _ids, _amounts);
  }
}


// File @0xsequence/erc-1155/contracts/utils/[email protected]

pragma solidity 0.7.4;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address private _owner_;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor () {
    _owner_ = msg.sender;
    emit OwnershipTransferred(address(0), _owner_);
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == _owner_, "Ownable#onlyOwner: SENDER_IS_NOT_OWNER");
    _;
  }

  /**
   * @notice Transfers the ownership of the contract to new address
   * @param _newOwner Address of the new owner
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != address(0), "Ownable#transferOwnership: INVALID_ADDRESS");
    emit OwnershipTransferred(_owner_, _newOwner);
    _owner_ = _newOwner;
  }

  /**
   * @notice Returns the address of the owner.
   */
  function owner() public view returns (address) {
    return _owner_;
  }
}


// File interfaces/IOperators.sol

pragma solidity ^0.7.4;

/**
 * IOperatorRegistry contract.
 * @author Yoel Zerbib
 * Date created: 4.6.22.
 * Github
**/

interface IOperatorRegistry {
    function isOperator(address _address) external view returns (bool);
}


// File contracts/TicketrustMiddleware.sol

pragma solidity ^0.7.4;

/**
 * Ticketrust Middleware contract.
 * @author Yoel Zerbib
 * Date created: 4.6.22.
 * Github
**/

contract TicketrustMiddleware {

    IOperatorRegistry public operatorsRegistry;
    address public committee;

    // Only operator modifier
    modifier onlyOperator {
        require(operatorsRegistry.isOperator(msg.sender), "Restricted only to operator");
        _;
    }

    // Only committee modifier
    modifier onlyCommittee {
        require(msg.sender == committee, "Restricted only to committee");
        _;
    }

    function setCommitteeAndOperators(address _committee, address _operatorsRegistry) internal {
        committee = _committee;
        operatorsRegistry = IOperatorRegistry(_operatorsRegistry);
    }

    function setOperatorsRegistry(address _operatorsRegistry) public onlyCommittee {
        operatorsRegistry = IOperatorRegistry(_operatorsRegistry);
    }

}


// File contracts/PaymentHandler.sol

pragma solidity ^0.7.4;

contract PaymentHandler {

    event AmountReceived(address sender, uint value);

    mapping(address => mapping(uint => mapping(address => uint))) public shares;
    mapping(address => mapping(uint => mapping(address => bool))) public isPayee;
    mapping(address => mapping(uint => mapping(address => uint))) public released;
    
    mapping(address => mapping(uint => address[])) public payees;
    mapping(address => mapping(uint => uint)) public eventRevenue;
    
    mapping(address => mapping(uint => uint)) public totalShare;
    
    modifier onlyCreator(address _creator) {
        require(msg.sender == _creator, "Caller is not the creator");
        _;
    }

    function addPayee(address _creator, uint _id, address _payee, uint _share) public onlyCreator(_creator) {
        require(!isPayee[_creator][_id][_payee], "Payee already exist");
        require(totalShare[_creator][_id] + _share <= 100, "Share must not exeed 100%");

        isPayee[_creator][_id][_payee] = true;
        shares[_creator][_id][_payee] = _share;
        payees[_creator][_id].push(_payee);
        totalShare[_creator][_id] += _share;
    }

    function releasable(address _creator, uint _id, address _payee) public view returns(uint) {
        require(isPayee[_creator][_id][_payee], "Address is not payee");
        
        uint payeeRevenue = eventRevenue[_creator][_id] * shares[_creator][_id][_payee] / 100;
        uint payeeReleased = released[_creator][_id][_payee];
        
        return payeeRevenue - payeeReleased;
    }

    function release(address _creator, uint _id, address _payee) public {
        require(isPayee[_creator][_id][msg.sender] || msg.sender == _creator, "You are not a payee nor the owner of the event");
        require(released[_creator][_id][_payee] < releasable(_creator, _id, _payee), "No funds to withdraw");

        uint amount = releasable(_creator, _id, _payee) - released[_creator][_id][_payee];
        (bool sent, ) = (_payee).call{value: amount}("");
        require(sent, "Oops, widthdrawal failed !");

        released[_creator][_id][_payee] += amount;
    }

    // fallback() external payable {
    //     if(msg.value > 0) {
    //         emit AmountReceived(msg.sender, msg.value);
    //     }
    // }
}


// File contracts/Billeterie.sol

pragma solidity ^0.7.4;

/**
 * Ticketrust main contract.
 * @author Yoel Zerbib
 * Date created: 24.5.22.
 * Github
**/




contract Billeterie is ERC1155MintBurn, TicketrustMiddleware, PaymentHandler {
    // Global variables
    uint public totalEvents;
    uint public baseOptionFees;

    // Mappings
    // Creator address to event offchain data
    mapping(address => mapping(uint => string)) eventOffchainData;
    // Creator address to event supply
    mapping(address => mapping(uint => uint32)) eventSupply;
    // Creator address to event price
    mapping(address => mapping(uint => uint)) eventPrice;
    // Creator address to event date
    mapping(address => mapping(uint => uint)) eventDate;

    // Creator address to event option fees
    mapping(address => mapping(uint => uint)) eventOptionFees;
    // Creator address to event total option count
    mapping(address => mapping(uint => uint)) eventOptionCount;

    // Creator address to event option count for specific buyer
    mapping(address => mapping(uint => mapping(address => uint))) public eventOptionAmount;
    // Creator address to event option duration for specific buyer
    mapping(address => mapping(uint => mapping(address => uint))) public eventOptionTime;
    // Creator address to event address that is authorize to perform tx on this option
    mapping(address => mapping(uint => mapping(address => address))) public eventOptionAllowance;
    
    // Creator to his total revenue
    // mapping(address => uint) public ownerRevenue;
    
    // Creator to his total events
    mapping(address => uint) public totalCreatorEvents;

    // Events
    // Emitted when new event is created
    event EventCreated(
        uint id, 
        address indexed owner,
        uint price,
        uint initialSupply
    );
    // Emitted when new ticket is minted
    event TicketMinted(
        uint indexed eventId, 
        address indexed owner, 
        uint32 amount
    );
    // Emitted when new option is added to an event
    event OptionAdded(
        address indexed creator, 
        address indexed optionOwner,
        uint indexed eventId,
        uint amount,
        uint duration
    );
    // Emitted when new option is removed from an event
    event OptionRemoved(
        address indexed creator, 
        address indexed optionOwner,
        uint indexed eventId,
        uint amount
    );


    function initialize(address _committee, address _operatorsRegistry) public {
        baseOptionFees = 4;
        setCommitteeAndOperators(_committee, _operatorsRegistry);
    }


    function createTicketing(
        uint32 _initialSupply, 
        uint _eventPrice, 
        uint _eventDate, 
        uint _optionFees, 
        bool _customOptionFees,
        address[] calldata _payees,
        uint[] calldata _shares
    ) 
    public
    {
        require(_payees.length == _shares.length, "Error: Array size mismatched");

        uint newEvent = totalCreatorEvents[msg.sender];

        // Update event data
        eventPrice[msg.sender][newEvent] = _eventPrice;
        eventDate[msg.sender][newEvent] = _eventDate;
        eventOptionFees[msg.sender][newEvent] = _optionFees;
        eventSupply[msg.sender][newEvent] = _initialSupply;

        // If there is no custom fees, put base option fees
        if (_customOptionFees == false) {
            eventOptionFees[msg.sender][newEvent] = baseOptionFees;
        }

        totalCreatorEvents[msg.sender] += 1;
        totalEvents += 1;

        for(uint i; i < _payees.length; i++) {
            addPayee(msg.sender, newEvent, _payees[i], _shares[i]);
        }

        emit EventCreated(newEvent, msg.sender, _eventPrice, _initialSupply);
    }


    function saveOffchainData(uint _id, string memory _offchainData) public {
        require(totalCreatorEvents[msg.sender] >= _id, "Event doesn't exist");
        
        // Update IPFS data for this event
        eventOffchainData[msg.sender][_id] = _offchainData;
    }


    function mint(address _to, address _creator, uint _id, uint32 _amount, bytes memory _data) public payable {        
        require(totalCreatorEvents[_creator] >= _id, "Event doesn't exist");
        require(eventSupply[_creator][_id] >= _amount, "No supply for event");
        require(block.timestamp <= eventDate[_creator][_id], "Event date is passed");
        require(msg.value == (eventPrice[_creator][_id] * _amount), "Incorrect ETH amount");

        // Mint a new ticket for this event
        _mint(_to, _id, _amount, _data);

        // Update general event data
        eventSupply[_creator][_id] -= _amount;
        
        // Update PaymentHandler
        eventRevenue[_creator][_id] += msg.value;

    }


    function optionTicket(address _creator, uint _id, uint32 _amount, uint _optionDuration) public payable {   
        require(totalCreatorEvents[_creator] >= _id, "Event doesn't exist");

        // Timestamp for the option from the moment the user call the function
        uint optionTimestamp = block.timestamp + (60 * 60 * _optionDuration);
        require(optionTimestamp <= eventDate[_creator][_id], "Event date is passed");

        // Get option fee price for this event
        uint optionFees = eventOptionFees[_creator][_id];
        uint optionPrice = (eventPrice[_creator][_id] * optionFees * _optionDuration * _amount) / 100;
        
        require(msg.value >= optionPrice, "Not enough ETH");
        require(eventSupply[_creator][_id] >= _amount, "Amount would exceed ticket supply !");
        
        // Update option data for this event
        eventOptionAmount[_creator][_id][msg.sender] += _amount;
        eventOptionAllowance[_creator][_id][msg.sender] = msg.sender;
        eventOptionTime[_creator][_id][msg.sender] = optionTimestamp;
        eventOptionCount[_creator][_id] += _amount;
        
        // Update general event data
        eventSupply[_creator][_id] -= _amount;
        // ownerRevenue[_creator] += msg.value;

        emit OptionAdded(_creator, msg.sender, _id, _amount, optionTimestamp);
    }
    

    function removeOption(address _creator, uint _id, address _to, uint32 _amount) public {
        require(totalCreatorEvents[_creator] >= _id, "Event doesn't exist");
        require(eventOptionAllowance[_creator][_id][_to] == msg.sender || operatorsRegistry.isOperator(msg.sender), "Not allowed");
        require(eventOptionAmount[_creator][_id][_to] >= _amount, "No option to remove");
        require(block.timestamp < eventOptionTime[_creator][_id][_to], "Too late to remove the option");
        
        eventSupply[_creator][_id] += _amount;
        eventOptionAmount[_creator][_id][_to] -= _amount;
        eventOptionCount[_creator][_id] -= _amount;

        emit OptionRemoved(_creator, _to, _id, _amount);
    }


    function eventInfo(address _creator, uint _id) public view returns(address _eventCreator, uint _eventDate, uint _eventPrice, uint _optionFees, uint32 _currentSupply, string memory _offchainData) {
        require(totalCreatorEvents[_creator] >= _id, "Event doesn't exist");
        
        return (_creator, 
                eventDate[_creator][_id], 
                eventPrice[_creator][_id], 
                eventOptionFees[_creator][_id], 
                eventSupply[_creator][_id], 
                eventOffchainData[_creator][_id]
        );
    }
    

    function ownerRevenue(address _creator) public view returns (uint) {
        require(totalCreatorEvents[_creator] > 0, "No event for this address");

        uint totalRevenue = 0;
        uint _totalCreatorEvents = totalCreatorEvents[_creator];
        
        for (uint i; i < _totalCreatorEvents; i++) {
            uint revenue = eventRevenue[_creator][i];
            totalRevenue += revenue;
        }

        return totalRevenue;
    }


    // function withdraw(uint _amount) public payable {
    //    require(ownerRevenue[msg.sender] >= _amount, "Not enough ETH in your balance");

    //    (bool sent, ) = (msg.sender).call{value: _amount}("");
    //    require(sent, "Oops, widthdrawal failed !");

    //    ownerRevenue[msg.sender] -= _amount;
    // }

}