/**
 *Submitted for verification at Etherscan.io on 2022-10-30
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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

// File: contracts/1_Storage.sol


pragma solidity >=0.8.0 <0.9.0;


contract SmartChange is Ownable {
  bool internal isEntry = false; // boolean for reentrency security

  struct Exchange {
    uint id;
    uint userId;
    uint date;
    uint crypto;
    uint fiat;
    address creator;
    address responder;
    string location;
    Status status;
    Cash currency;
    Type exchangeType;
  }

  enum Type {SELL, BUY} // Sell or buy eth 
  enum Cash {USD, EUR, BYN, RUB, UAH, GBP, KZT}
  enum Status {DEFAULT, OPEN, PENDING, COMPLETED, CLOSE}
  
  mapping (address => mapping(uint => Exchange)) userExchanges;
  mapping (address => uint) usersExhangeIds;
  
  uint globalID;
  address[] userAddresses;

  // for reentrency security
  modifier noReentrant(){
    require(isEntry == false, "This function is already running!");
    isEntry = true;
    _;
    isEntry = false;
  }

  function openChange(
    string memory _location,
    uint _date, 
    uint _fiat,
    Cash _currency, 
    Type _type
  ) public payable {
    if (_type == Type.SELL) {
      require(msg.value > 0, "You can't change 0 ETH!");
    } else {
      require(_fiat > 0, "You can't change 0 fiat!");
    }

    Exchange memory newExchange = Exchange({
      id: globalID,
      userId: usersExhangeIds[msg.sender],
      date: _date,
      crypto: msg.value,
      fiat: _fiat,
      creator: msg.sender,
      responder: address(0),
      location: _location,
      currency: _currency,
      status: Status.OPEN,
      exchangeType: _type
    });

    userExchanges[msg.sender][usersExhangeIds[msg.sender]] = newExchange;

    if(usersExhangeIds[msg.sender] == 0){
      userAddresses.push(msg.sender);
    }

    usersExhangeIds[msg.sender]++;
    globalID++;
  }

  function respondChange(address _creator, uint _exchangeId, uint _fiat) public payable{
    Type exchangeType = userExchanges[_creator][_exchangeId].exchangeType;
    if (exchangeType == Type.BUY) {
      require(msg.value > 0, "You can't change 0 ETH!");
      userExchanges[_creator][_exchangeId].crypto = msg.value;
    } else {
      require(_fiat > 0, "You can't change 0 fiat!");
      userExchanges[_creator][_exchangeId].fiat = _fiat;
    }

    userExchanges[_creator][_exchangeId].responder = msg.sender;
    userExchanges[_creator][_exchangeId].status = Status.PENDING;
  }

  function doneChange(address _creator, uint _exchangeId) public noReentrant onlyOwner{
    Type exchangeType = userExchanges[_creator][_exchangeId].exchangeType;
    if (exchangeType == Type.BUY) {
      bool isSend = payable(userExchanges[_creator][_exchangeId].creator).send(userExchanges[_creator][_exchangeId].crypto);
      require(isSend, "Error to done buy funds to user!");
    } else {
      bool isSend = payable(userExchanges[_creator][_exchangeId].responder).send(userExchanges[_creator][_exchangeId].crypto);
      require(isSend, "Error to done sell funds to user!");
    }
    
    userExchanges[_creator][_exchangeId].status = Status.COMPLETED;
  }

  function cancelChange(address _creator, uint _exchangeId) public noReentrant{
    Status status = userExchanges[_creator][_exchangeId].status;
    Type exchangeType = userExchanges[_creator][_exchangeId].exchangeType;
    require(status != Status.CLOSE && status != Status.COMPLETED, "Exchange not active anymore!");
    address responder = userExchanges[_creator][_exchangeId].responder;
    if(exchangeType == Type.SELL) {
      bool isSend = payable(userExchanges[_creator][_exchangeId].creator).send(userExchanges[_creator][_exchangeId].crypto);
      require(isSend, "Error to cancel sell funds to user!");
    } else if(responder != address(0)){
      bool isSend = payable(userExchanges[_creator][_exchangeId].creator).send(userExchanges[_creator][_exchangeId].crypto);
      require(isSend, "Error to cancel buy funds to user!");
    }

    userExchanges[_creator][_exchangeId].status = Status.CLOSE;
  }

  function getExchange(address _owner, uint _exchangeId) public view returns(Exchange memory){
    return userExchanges[_owner][_exchangeId];
  }

  function getExchangeArray(address _owner) public view returns(Exchange[] memory){
    Exchange[] memory array = new Exchange[](usersExhangeIds[_owner]);
    for(uint i = 0; i < usersExhangeIds[_owner]; i++){
      array[i] = userExchanges[_owner][i];
    }
    return array;
  }

  function getAllExhanges() public view returns(Exchange[] memory){
    uint arraySize = 0;
    for(uint i = 0; i < userAddresses.length; i++){
      arraySize += usersExhangeIds[userAddresses[i]];
    }
    Exchange[] memory array = new Exchange[](arraySize);
    for(uint j = 0; j < userAddresses.length; j++){
      for(uint i = 0; i < usersExhangeIds[userAddresses[j]]; i++){
        array[i] = userExchanges[userAddresses[j]][i];
      }
    }
    return array;
  }
}