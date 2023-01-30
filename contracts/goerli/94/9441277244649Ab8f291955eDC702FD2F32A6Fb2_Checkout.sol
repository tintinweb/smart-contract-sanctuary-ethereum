// SPDX-License-Identifier: MIT
pragma solidity = 0.8.17;
pragma experimental ABIEncoderV2;

// import ownable contract
import "./ownable.sol";

contract Checkout is Ownable {

    string[] private orders;
    string[] private reviews;
    string[] private chanceInfo;
    
    // review[] private reviews;
    

    // events
    event orderEvent(string);
    event reviewEvent(string);
    event chanceEvent(string);

    ////////////review///////////////////////////////////
    function getChanceInfo() view public returns(string[] memory){
        return chanceInfo;
    }

    function setChanceInfo(string memory _chance)public{
        chanceInfo.push(_chance);
        emit chanceEvent(_chance);
    }
    
    function save(string memory _review) public {

        reviews.push(_review);
        emit reviewEvent(_review);   
    }

    // receive amount
    function receive(string memory _order) public payable {
               
         // adding order details
         orders.push(_order);

        // emit event
        emit orderEvent(_order);   
    }

    

    // withdraw amount 
    function  withdraw (address payable _to) public onlyOwner {
      
        _to.transfer(address(this).balance);

        // emit withdrawEvent(_to);

    }

    // get all orders 
    function allOrders() view public onlyOwner returns(string[] memory) {
        return orders;
    }

    function getReview() public view returns (string[] memory){
        return reviews;
    }


    function getBalance() view public onlyOwner returns (uint) {
        return address(this).balance;
    }

}

pragma solidity = 0.8.17;

/**
* @title Ownable
* @dev The Ownable contract has an owner address, and provides basic authorization control
* functions, this simplifies the implementation of "user permissions".
*/
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
  * @dev The Ownable constructor sets the original `owner` of the contract to the sender
  * account.
  */
  constructor() {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
  * @return the address of the owner.
  */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
  * @dev Throws if called by any account other than the owner.
  */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
  * @return true if `msg.sender` is the owner of the contract.
  */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
  * @dev Allows the current owner to relinquish control of the contract.
  * @notice Renouncing to ownership will leave the contract without an owner.
  * It will not be possible to call the functions with the `onlyOwner`
  * modifier anymore.
  */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
  * @dev Allows the current owner to transfer control of the contract to a newOwner.
  * @param newOwner The address to transfer ownership to.
  */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
  * @dev Transfers control of the contract to a newOwner.
  * @param newOwner The address to transfer ownership to.
  */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}