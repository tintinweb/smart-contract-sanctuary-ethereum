/**
 *Submitted for verification at Etherscan.io on 2022-05-19
*/

pragma solidity ^0.6.0;

contract PocketMoney {

    address payable public child;
    address public father;

    uint public amount = 0.01 ether;
    uint public period = 1 minutes;
//    uint public period = 4 weeks;
    uint public lastWithDrawal;

    constructor(address payable _child) public {
        child = _child;
        father = msg.sender;

    }

    function withdraw() public {
        //require(msg.sender == child);
        //require(address(this).balance >= amount);
        require(lastWithDrawal + period <= now);

        lastWithDrawal = now;
        child.transfer(amount);

    }

    //fallback
    receive() external payable{

    }

}