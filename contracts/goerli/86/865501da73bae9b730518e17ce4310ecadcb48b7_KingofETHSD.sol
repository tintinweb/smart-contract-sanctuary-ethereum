/**
 *Submitted for verification at Etherscan.io on 2023-01-21
*/

// File: kingofethsd.sol


pragma solidity ^0.8.17;

contract KingofETHSD {
    uint public targetAmount = 1 ether;
    address public king;

    function deposit() public payable {
        require(msg.value >= 0.1 ether, "You need to send at least 0.1 ether");
        king = address(msg.sender);

        uint _balance = address(this).balance;

        if (_balance >= targetAmount) {
            address payable addr = payable(address(msg.sender));
            selfdestruct(addr);
        }
    }

    function balance() public view returns (uint) {
        return address(this).balance;
    }
}