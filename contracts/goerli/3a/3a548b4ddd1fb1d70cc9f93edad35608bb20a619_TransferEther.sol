/**
 *Submitted for verification at Etherscan.io on 2023-01-16
*/

pragma solidity ^0.6.2;

contract TransferEther {
    address payable public recipient;
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    fallback() external payable {
        require(msg.value > 0);
        recipient = msg.sender;
    }

    function transfer(address payable _to, uint _value) public {
        require(msg.sender == owner);
        _to.transfer(_value);
    }
    
    function changeOwner(address payable newOwner) public {
        require(msg.sender == owner);
        owner = newOwner;
    }
}