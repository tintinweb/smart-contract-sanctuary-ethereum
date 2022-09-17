/**
 *Submitted for verification at Etherscan.io on 2022-09-17
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;



contract Caller{

    function fundingUsingCaller(address addr,string memory projectId) public payable returns(uint256){
        Payment c = Payment(addr);
        return c.funding(projectId);
    }

}

interface Payment {
    function funding(string memory projectId) external payable returns(uint256);
}