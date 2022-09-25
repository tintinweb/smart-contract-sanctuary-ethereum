/**
 *Submitted for verification at Etherscan.io on 2022-09-25
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;
contract Target {
 address public owner;
constructor() {
 owner = msg.sender;
 }
function destroy() public {
 selfdestruct(payable(msg.sender));
 }
 
}
contract CreatorContract {
 event CreatorDeploy (address addr);
 address public _targetaddr;
 function deployTarget() external {
 Target _contract = new Target();
 emit CreatorDeploy(address(_contract));
 _targetaddr = address (_contract);
 }
function destroy() public {
 selfdestruct(payable(msg.sender));
 }
}
contract CreatorFactoryContract {
 event CreatorFactoryDeploy(address addrofc);
 address public _creatorContractaddr;
 function deployCreator(uint _salt) external {
 CreatorContract _creatorcontract = new     CreatorContract{salt:bytes32(_salt)}();
 emit CreatorFactoryDeploy(address(_creatorcontract));
 _creatorContractaddr = address(_creatorcontract); 
 }
}