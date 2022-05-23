/**
 *Submitted for verification at Etherscan.io on 2022-05-22
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.14;

interface RocketNodeStakingInterface {
  function getNodeRPLStake(address _nodeAddress) external view returns (uint256);
  function getNodeEffectiveRPLStake(address _nodeAddress) external view returns (uint256);
}

interface ERC20 {
  function balanceOf(address _owner) external view returns (uint256 balance);
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
    require(nodeToDelegate[delegateAddress] == address(0), "Cannot vote with node address once delegated");
    address nodeAddress = delegateToNode[delegateAddress];
    if (nodeAddress == address(0)) {
      nodeAddress = delegateAddress;
    }
    return nodeAddress; 
  }

  function getNodeRPLStake(address _rocketNodeStakingAddress, address _address) public view returns (uint256) {
    RocketNodeStakingInterface rocketNodeStaking = RocketNodeStakingInterface(_rocketNodeStakingAddress);
    return rocketNodeStaking.getNodeRPLStake(getNodeAddressForDelegate(_address));
  }

  function getNodeRPLStakeQuadratic(address _rocketNodeStakingAddress, address _address) public view returns (uint256) {
    return sqrt(getNodeRPLStake(_rocketNodeStakingAddress, _address));
  }

  function getNodeEffectiveRPLStake(address _rocketNodeStakingAddress, address _address) public view returns (uint256) {
    RocketNodeStakingInterface rocketNodeStaking = RocketNodeStakingInterface(_rocketNodeStakingAddress);
    return rocketNodeStaking.getNodeEffectiveRPLStake(getNodeAddressForDelegate(_address));
  }

  function getNodeEffectiveRPLStakeQuadratic(address _rocketNodeStakingAddress, address _address) public view returns (uint256) {
    return sqrt(getNodeEffectiveRPLStake(_rocketNodeStakingAddress, _address));
  }

  function getNodeRPLBalance(address _rplAddress, address _address) public view returns (uint256) {
    ERC20 rpl = ERC20(_rplAddress);
    return rpl.balanceOf(getNodeAddressForDelegate(_address));
  }

  function getNodeRPLBalanceQuadratic(address _rplAddress, address _address) public view returns (uint256) {
    return sqrt(getNodeRPLBalance(_rplAddress, _address));
  }

  // https://github.com/Uniswap/v2-core/blob/v1.0.1/contracts/libraries/Math.sol
  function sqrt(uint y) internal pure returns (uint z) {
    if (y > 3) {
      z = y;
      uint x = y / 2 + 1;
      while (x < z) {
        z = x;
        x = (y / x + x) / 2;
      }
    } else if (y != 0) {
      z = 1;
    }
  }
}