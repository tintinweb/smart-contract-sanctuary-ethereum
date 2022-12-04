/**
 *Submitted for verification at Etherscan.io on 2022-12-04
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract Crowdfunding {
    
    address[] public funders;
    address public immutable owner;

    constructor() {
        owner = msg.sender;
    }

    function fund() external payable {
        uint256 minimumFunding = 1e16; //0.01ETH (1e16 Wei)
        require(msg.value >= minimumFunding, "Not enough ETH");
        funders.push(msg.sender);
    }

    function withdraw() public onlyOwner{
         funders = new address[](0);
         (bool callSuccess, ) = payable(owner).call{value: address(this).balance}("");
         require(callSuccess, "Transfer failed");
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can withdraw");
        _;
    }
}