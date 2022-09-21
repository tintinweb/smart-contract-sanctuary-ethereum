/**
 *Submitted for verification at Etherscan.io on 2022-09-21
*/

pragma solidity ^0.8.7;

contract EtherWallet {
    address payable public owner;

    constructor() {
        owner = payable(msg.sender);
    }

     modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        // Underscore is a special character only used inside a function modifier and it tells Solidity to execute the rest of the code.
        _;
    }

    receive() external payable {}

    function withdraw(uint _amount) external onlyOwner {
        
        payable(msg.sender).transfer(_amount);
    }

    function getBalance() external view returns (uint) {
        return address(this).balance;
    }
}