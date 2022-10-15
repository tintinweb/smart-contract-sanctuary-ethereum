pragma solidity ^0.8.9;

contract Stake {
    uint public unlocktime;
    address payable public owner;

    event Withdraw(uint amount,uint when);

    constructor(uint _unlocktime) payable {
        require((block.timestamp < _unlocktime),"Unl");
        unlocktime = _unlocktime;
        owner = payable( msg.sender);
    }

    function withdraw()public{
        require(block.timestamp >= unlocktime,"You can't withdraw yet.");
        require(msg.sender == owner,"You aren't the owner.");

        emit Withdraw(address(this).balance,block.timestamp);

        owner.transfer(address(this).balance);
    }

}