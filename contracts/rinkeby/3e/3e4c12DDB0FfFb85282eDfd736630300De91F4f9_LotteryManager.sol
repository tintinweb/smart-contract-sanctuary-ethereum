// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./Lottery.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LotteryManager is Ownable {
  
    address[] public arrayLotteries;
 
    constructor()
    {

    }
   
    function createLottery(string memory _nameLottery,uint _endDate, uint  _priceOfEntrance, uint  _maxNumberOfEntries) public onlyOwner{
      
      require(bytes(_nameLottery).length != 0,"The lottery must have a name!");
      require(_endDate > block.timestamp,"End date should be in the future!");
      require(_priceOfEntrance > 0,"The price of entrance should be not 0!");
      require(_maxNumberOfEntries > 0,"The user should be entrance at least once!");
    
      address lottery = address (new Lottery(msg.sender,_nameLottery,_endDate,_priceOfEntrance,_maxNumberOfEntries));
      arrayLotteries.push(lottery);
    

    }

    function getLotteries()public view returns(address[] memory)
    {
        return arrayLotteries;
    }

  
  
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Lottery{

    struct participant{
        
        uint numberOfEntries;
    }

    string public nameLottery;
    address  public owner;
    address payable[] public arrayParticipants;
    mapping (address => participant) public mapParticipants;
    uint public startDate ;
    uint public endDate;
    uint public pickedDate;
    uint public priceOfEntrance;
    bool public hasEnded = false;
    bool public ownerWithdrawedCommision = false;
    uint public indexFirstPrize;
    uint public indexSecondPrize;
    uint public maxNumberOfEntries;

   constructor (address _owner,string memory _nameLottery,uint _endDate, uint  _priceOfEntrace, uint  _maxNumberOfEntries) {
        nameLottery = _nameLottery;
        maxNumberOfEntries = _maxNumberOfEntries;
        owner = _owner;
        endDate = _endDate;
        startDate = block.timestamp;
        priceOfEntrance = _priceOfEntrace * 1 wei;
     
    
    }


   
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
    


    function enter() public payable {
        require(msg.value >= priceOfEntrance, "Incorrect amount!"); 
        require (msg.value < priceOfEntrance + 3000000 wei, "Incorrect amount!");
        require(mapParticipants[msg.sender].numberOfEntries < maxNumberOfEntries,"To many entries");

        if(mapParticipants[msg.sender].numberOfEntries == 0)
        {
          
            mapParticipants[msg.sender] = participant(1);
            
        }
        else
        {
            mapParticipants[msg.sender].numberOfEntries += 1;
            
        }
        arrayParticipants.push(payable(msg.sender));

    }

    function getRandomNumber(uint number) public view returns (uint) {
        return uint(keccak256(abi.encodePacked(owner, block.timestamp, block.number, block.difficulty,number)));
    }
    
  
    function pickWinner() public onlyowner{
        
        require(address(this).balance > 0, "Balance is 0");
        require(hasEnded == false);
        
        indexFirstPrize = getRandomNumber(1) % arrayParticipants.length;
        indexSecondPrize = getRandomNumber(2) % arrayParticipants.length;
        
       
        arrayParticipants[indexFirstPrize].transfer(address(this).balance / 100 * 70);
        arrayParticipants[indexSecondPrize].transfer(address(this).balance / 100 * 83);
        

        hasEnded = true;

        pickedDate = block.timestamp;
        
    }
     function withdrawCommision() public onlyowner()
     {
        require(hasEnded == true, "Please pick the winner first!");
        require(ownerWithdrawedCommision == false, "You receive the commsision");
        address payable copy;
        copy = payable(owner);
        copy.transfer(address(this).balance);
        ownerWithdrawedCommision = true;
     }
    

    function getWinner1() public view returns(address)
    {
        require(hasEnded == true);
        return arrayParticipants[indexFirstPrize];
    }

    function getWinner2() public view returns(address)
    {
        require(hasEnded == true);
        return arrayParticipants[indexSecondPrize];
    }

    function getPlayers() public view returns(address payable[] memory)
    {
        return arrayParticipants;
    }
    
    function  getNumberOfEntriesForUser(address player) public view returns(uint){
        return mapParticipants[player].numberOfEntries;
    }

    modifier onlyowner() {
        require(msg.sender == owner);
      _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
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