/**
 *Submitted for verification at Etherscan.io on 2022-12-02
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

contract CrowdFunding {

    address[] public funders_list;
    address public owner; 

    function Fund() external payable {
        //acept funds from funders 
        //Only 0.01 ETH accpet 
        //msg.value

        uint256 minimumFunding = 1e16;
        require(msg.value >= minimumFunding, "Not enough ETH" );

            funders_list.push(msg.sender);

    }

    function withdraw() public onlyOwner{
        //transfer all blaance to the owner
        
        funders_list = new address[](0);
        (bool callSuccess, ) = owner.call{value: address(this).balance}("");

        require(callSuccess, "Transfer Failed");
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can withdraw");
        _; 
    }



}