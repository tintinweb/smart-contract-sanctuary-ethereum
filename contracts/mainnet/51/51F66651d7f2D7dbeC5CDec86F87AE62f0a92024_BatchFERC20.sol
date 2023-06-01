/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface FERC20 {
    function mint(address v) external ;
}
interface ROBOT{
    function balanceOf(address owner) external view returns (uint256 balance);
}
contract BatchFERC20 {
    address constant robot=0x81Ca1F6608747285c9c001ba4f5ff6ff2b5f36F8;
    mapping (address=>bool) public wls;
    function go(address contractAddress,uint batchCount) external {
        require(ROBOT(robot).balanceOf(msg.sender)>0||wls[msg.sender]);
        for (uint i = 0; i < batchCount; i++) {
            FERC20(contractAddress).mint(msg.sender);
        }
    }
    function wl(address user,bool state)external 
    {
        require(ROBOT(robot).balanceOf(msg.sender)>0);
        wls[user]=state;
    }
}