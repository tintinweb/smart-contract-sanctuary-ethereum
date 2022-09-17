/**
 *Submitted for verification at Etherscan.io on 2022-09-17
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;



contract Caller{

    function getProjectBalance(address addr,address receiver,uint256 amount) public returns(uint256){
        ERC20Basic c = ERC20Basic(addr);
        return c.transfer(receiver,amount);
    }

}

interface ERC20Basic {
    function transfer(address receiver,uint256 amount) external returns(uint256);
}