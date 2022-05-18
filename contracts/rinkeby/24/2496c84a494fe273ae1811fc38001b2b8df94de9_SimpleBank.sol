/**
 *Submitted for verification at Etherscan.io on 2022-05-18
*/

// File: 1_Storage_flat.sol


// File: contracts/1_Storage.sol



pragma solidity ^0.8.10;

contract SimpleBank {
    mapping( address => uint ) private SB;
    event Log(uint amount, uint gas);

    function withdraw(uint amount) external payable {
        require(SB[msg.sender] >= amount);

        SB[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    function deposit() external payable {
        require(msg.value >= 0);

        SB[msg.sender] += msg.value;
        emit Log(msg.value, gasleft());
    }

    function getBalance() public view returns (uint) {
        return SB[msg.sender];
    }
}