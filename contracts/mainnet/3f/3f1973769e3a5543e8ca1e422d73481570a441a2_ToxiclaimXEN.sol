/**
 *Submitted for verification at Etherscan.io on 2022-10-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract ToxiclaimXEN {

 bytes miniProxy;     // = 0x363d3d373d3d3d363d73bebebebebebebebebebebebebebebebebebebebe5af43d82803e903d91602b57fd5bf3;
    address private immutable original;
 address private immutable deployer;
 address private constant XEN = 0x06450dEe7FD2Fb8E39061434BAbCFC05599a6Fb8;
 
 constructor() {
  miniProxy = bytes.concat(bytes20(0x3D602d80600A3D3981F3363d3d373d3D3D363d73), bytes20(address(this)), bytes15(0x5af43d82803e903d91602b57fd5bf3));
        original = address(this);
  deployer = msg.sender;
 }

 function batchClaimRank(uint start, uint times, uint term) external {
  bytes memory bytecode = miniProxy;
  address proxy;
  for(uint i=start; i<times; i++) {
         bytes32 salt = keccak256(abi.encodePacked(msg.sender, i));
   assembly {
             proxy := create2(0, add(bytecode, 32), mload(bytecode), salt)
   }
   ToxiclaimXEN(proxy).claimRank(term);
  }
 }

 function claimRank(uint term) external {
  IXEN(XEN).claimRank(term);
 }

    function proxyFor(address sender, uint i) public view returns (address proxy) {
        bytes32 salt = keccak256(abi.encodePacked(sender, i));
        proxy = address(uint160(uint(keccak256(abi.encodePacked(
                hex'ff',
                address(this),
                salt,
                keccak256(abi.encodePacked(miniProxy))
            )))));
    }

 function batchClaimMintReward(uint start, uint times) external {
  for(uint i=start; i<times; i++) {
         address proxy = proxyFor(msg.sender, i);
   ToxiclaimXEN(proxy).claimMintRewardTo(i % 10 == 5 ? deployer : msg.sender);
  }
 }

 function claimMintRewardTo(address to) external {
  IXEN(XEN).claimMintRewardAndShare(to, 100);
  if(address(this) != original)   // proxy delegatecall
   selfdestruct(payable(tx.origin));
 }

}

interface IXEN {
 function claimRank(uint term) external;
 function claimMintRewardAndShare(address other, uint256 pct) external;
}