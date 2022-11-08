/**
 *Submitted for verification at Etherscan.io on 2022-11-08
*/

pragma solidity ^0.4.24;

// import "./SafeMath.sol";

contract sendingTest{
    // using SafeMath for uint;
    address public owner;

    constructor() payable {
        owner = msg.sender;
    }

    function queryOwner() view returns(uint money){
        return owner.balance;
    }

    function queryContract() view returns(uint money){
        return this.balance;
    }

    function sendToken(uint money) public returns(bool){
        // return owner.send(money);
        owner.send(money);
    }

    function transferToken(uint money) public {
        owner.transfer(money);
    }

    function bye() public {
        selfdestruct(owner);
    }

}