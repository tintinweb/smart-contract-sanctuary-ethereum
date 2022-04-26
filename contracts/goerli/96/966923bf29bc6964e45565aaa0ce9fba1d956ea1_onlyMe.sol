/**
 *Submitted for verification at Etherscan.io on 2022-04-26
*/

pragma solidity ^0.8.10;

contract onlyMe {
    address public owner;

    constructor(address _owner) payable {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}