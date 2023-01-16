/**
 *Submitted for verification at Etherscan.io on 2023-01-16
*/

pragma solidity ^0.6.2;

contract TransferEther {
    mapping(address => uint) public balanceOf;
    address payable public recipient;
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    fallback() external payable {
        require(msg.value > 0);
        balanceOf[msg.sender] = address(msg.sender).balance;
    }

    function transfer(address payable _to, uint _value) public {
        require(msg.sender == owner);
        require(_value <= balanceOf[msg.sender]);
        _to.transfer(_value);
        balanceOf[msg.sender] -= _value;
    }
}