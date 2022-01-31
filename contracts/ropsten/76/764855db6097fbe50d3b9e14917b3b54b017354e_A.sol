/**
 *Submitted for verification at Etherscan.io on 2022-01-31
*/

pragma solidity ^0.8.4;

contract A {
    constructor() payable {
    }

    function sendEther(address _to) public payable {
        (bool sent, bytes memory data) = _to.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}