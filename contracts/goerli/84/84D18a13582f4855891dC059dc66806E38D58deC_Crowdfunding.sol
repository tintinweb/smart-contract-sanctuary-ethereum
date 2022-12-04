/**
 *Submitted for verification at Etherscan.io on 2022-12-03
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

contract Crowdfunding {

    address[] public funders;
    address public immutable owner;

    constructor(){
        owner = msg.sender;
    }


    function found() external payable{
        // accepts funds from funders
        // Only 0.01 ETH or more
        uint256 minimumFunding = 1e16;
        require(msg.value >= minimumFunding, "Not enough ETH");
        funders.push(msg.sender);
    }

    function withdraw() public onlyOwner{
        // transfer all balance to the owner
        funders = new address[](0);

        (bool callSuccess, ) = payable(owner).call{value: address(this).balance}("");
        
        require(callSuccess, "Transfer failed");
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can withdraw");
        _;
    }

}