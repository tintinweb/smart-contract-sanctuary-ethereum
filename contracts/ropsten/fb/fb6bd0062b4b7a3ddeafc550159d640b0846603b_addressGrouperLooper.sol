/**
 *Submitted for verification at Etherscan.io on 2022-03-11
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

//web3 engineer www.twitter.com/SCowboy88


contract addressGrouperLooper{
	uint groupCounter = 1;
	uint addressesPerGroup;
	uint maxGroups;

	mapping (address=>uint) group;
	mapping (uint=>address[]) members;

	constructor(uint _maxGroups, uint _addressesPerGroup){
		addressesPerGroup = _addressesPerGroup;
		maxGroups = _maxGroups;
	}

	//add to group
	function addToGroup(address _address) public {
		bool atMax = true;
		require(group[_address] == 0, "Duplicate address entered");
		uint _lowest = 1;
		for(uint i = 1; i <= maxGroups; i++){
			if(members[i].length == addressesPerGroup){
				continue;
			}else{
				if(members[i].length < members[_lowest].length){
					_lowest = i;	
				}
				atMax = false;
			}
		}
		if(!atMax){
			group[_address] = _lowest;
			members[_lowest].push(_address);
		}else{
			revert("all groups are full");
		}
	}

	function addAddresses(address[] calldata _addresses) external {
		for(uint i = 0; i < _addresses.length; ++i){
			addToGroup(_addresses[i]);
		}
	}

	//remove from group
	function removeFromGroup(address _address) external {
		require(group[_address] != 0, "The address provided is not a token holder");
		for(uint i = 0; i < members[group[_address]].length; ++i){
			if(members[group[_address]][i] == _address){
				members[group[_address]][i] = members[group[_address]][members[group[_address]].length - 1];
				members[group[_address]].pop();
				group[_address] = 0;
				return;
			}
		}
		group[_address] = 0;
		revert("Address was not found");
	}

	function getGroupId(address _address) external view returns(uint){
		require(group[_address] != 0, "The address provided is not a token holder");
		return group[_address];
	}

	function getGroup(uint _groupId) external view returns(address[] memory){
		require(_groupId <= maxGroups, "You have requested a group beyond the maximum groups allowed");
		return members[_groupId];
	}
}