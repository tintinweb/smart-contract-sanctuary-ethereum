/**
 *Submitted for verification at Etherscan.io on 2023-03-16
*/

pragma solidity ^0.4.23;

contract NewImplementation {
    address public owner;

    // Remove the constructor

    function setOwner(address _newOwner) public {
        require(msg.sender == owner, "Only the owner can change the owner");
        owner = _newOwner;
    }

    function withdraw(uint256 amount) public {
        require(msg.sender == owner, "Only the owner can withdraw");
        owner.transfer(amount);
    }

    function () external payable {
    }
}