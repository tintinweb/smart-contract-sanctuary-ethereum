/**
 *Submitted for verification at Etherscan.io on 2022-09-17
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;



contract Caller{

    function getProjectBalance(address addr,string memory projectId) public returns(uint256){
        Payment c = Payment(addr);
        return c.getProjectBalance(projectId);
    }

}

interface Payment {
    function getProjectBalance(string memory projectId) external returns(uint256);
}