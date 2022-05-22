/**
 *Submitted for verification at Etherscan.io on 2022-05-22
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface RocketNodeStakingInterface {
  function getNodeEffectiveRPLStake(address _nodeAddress) external view returns (uint256);
}

contract RocketNodeDelegateVote {
  event Registration(address delegateAddress, address nodeAddress, uint256 index);
  event Confirmation(address delegateAddress, address nodeAddress);

  mapping(uint256 => address) unconfirmedDelegateAddress;
  mapping(uint256 => address) unconfirmedNodeAddress;
  uint256 unconfirmedIndex;

  mapping(address => address) delegateToNode;
  mapping(address => address) nodeToDelegate;

  function registerDelegateAddress(address nodeAddress) public returns (uint256) {
    address delegateAddress = msg.sender;
    unconfirmedIndex += 1;
    unconfirmedDelegateAddress[unconfirmedIndex] = delegateAddress;
    unconfirmedNodeAddress[unconfirmedIndex] = nodeAddress;
    emit Registration(delegateAddress, nodeAddress, unconfirmedIndex);
    return unconfirmedIndex;
  }

  receive() external payable {
    uint256 index = msg.value;
    address nodeAddress = unconfirmedNodeAddress[index];
    address delegateAddress = unconfirmedDelegateAddress[index];
    require(delegateAddress != address(0), "Registration invalid");
    require(nodeAddress != address(0), "Node address is invalid");
    require(nodeAddress == msg.sender, "Registration is for another node address");
    require(nodeAddress != delegateAddress, "Node address and delegate address are the same");
    require(delegateToNode[delegateAddress] == address(0), "Delegate address already used");
    delegateToNode[delegateAddress] = nodeAddress;
    nodeToDelegate[nodeAddress] = delegateAddress;
    emit Confirmation(delegateAddress, nodeAddress);
  }

  function undelegate() public {
    address nodeAddress = msg.sender;
    address delegateAddress = nodeToDelegate[nodeAddress];
    delegateToNode[delegateAddress] = address(0);
    nodeToDelegate[nodeAddress] = address(0);
  }

  function getNodeAddressForDelegate(address delegateAddress) public view returns (address) {
    address nodeAddress = delegateToNode[delegateAddress];
    if (nodeAddress == address(0)) {
      nodeAddress = delegateAddress;
    }
    return nodeAddress; 
  }

  function getNodeEffectiveRPLStake(address _rocketNodeStakingAddress, address _address) public view returns (uint256) {
    RocketNodeStakingInterface rocketNodeStaking = RocketNodeStakingInterface(_rocketNodeStakingAddress);
    return rocketNodeStaking.getNodeEffectiveRPLStake(getNodeAddressForDelegate(_address));
  }
}