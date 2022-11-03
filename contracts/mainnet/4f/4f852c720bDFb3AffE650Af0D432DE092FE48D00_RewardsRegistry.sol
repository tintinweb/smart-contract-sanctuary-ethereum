/**
 *Submitted for verification at Etherscan.io on 2022-11-03
*/

/**
 *Submitted for verification at Etherscan.io on 2021-11-21
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.0 <0.8.0;

contract RewardsRegistry {
    
    address public owner;
    address[] public registry;
    mapping(address=>uint256) public registryMap;
    int256 public counter;
    
    event RewardsAdded(address rewards, uint256 index);
    event RewardsRemoved(address rewards, uint256 index);
    
    constructor() {
        owner = msg.sender;    
    }
    
    function add(address rewards) external {
        require(msg.sender == owner,"only owner");
        require(registryMap[rewards]==0, "exists");
        registry.push(rewards);
        registryMap[rewards] = registry.length;
        counter++;
        emit RewardsAdded(rewards, registry.length-1);
    }
    
    function addMany(address[] memory rewardss) external {
        require(msg.sender == owner,"only owner");
        for(uint256 i=0; i<rewardss.length; i++) {
            if(registryMap[rewardss[i]]!=0) continue;
            registry.push(rewardss[i]);
            registryMap[rewardss[i]] = registry.length;
            counter++;
            emit RewardsAdded(rewardss[i], registry.length-1);
        }
    }

    function remove(address rewards) external {
        require(msg.sender == owner,"only owner");
        require(registryMap[rewards]!=0, "not exists");
        emit RewardsRemoved(rewards, registryMap[rewards]-1);
        registryMap[rewards] = 0;
        counter--;
    }
    
    function rewardsByIndex(uint256 index) external view returns (address, uint256){
        return (registry[index], registryMap[registry[index]]);
    }
    
    function transferOwnership(address newOwner) external {
        require(msg.sender == owner, "only owner");
        owner = newOwner;
    }

}