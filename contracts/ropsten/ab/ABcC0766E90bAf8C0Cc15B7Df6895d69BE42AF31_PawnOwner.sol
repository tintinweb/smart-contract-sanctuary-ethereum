/**
 *	Question 5:
 *  The following smart contract contains a hidden method of overwriting the owner state variable. 
 * 	Can you identify the problem and share a brief of how it will be done?
 */

 /**
  * Answer:
  *
  *
  * Just a note: constructor function don't have to be public in newer Solidity versions since 0.7.0.
  *
  */

pragma solidity ^0.5.0;

contract PawnOwner {
    address public owner;
    uint[] private bonus;
    
    constructor() public {
        bonus = new uint[](0);
        owner = msg.sender;
    }
    
    function PushBonus(uint _c) public {
        bonus.push(_c);
    }
    
    function PopBonus() public {
        require(0 <= bonus.length);
        bonus.length--;
    }
    
    function UpdateBonusAt(uint _idx, uint _c) public {
        require(_idx < bonus.length);
        bonus[_idx] = _c;
    }
}