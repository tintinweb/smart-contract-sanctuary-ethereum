/**
 *Submitted for verification at Etherscan.io on 2022-03-11
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

//web3 engineer www.twitter.com/SCowboy88

interface IlandBaronstorage{
	function getGroupId(address _member) external view returns(uint);
	function getGroupMembers(uint _groupId) external view returns(address[] memory);
	function addToGroup(address _member, uint _groupId) external;
	function removeFromGroup(address _member) external;
	function addToMembers(uint _groupId, address _member) external;
	function updateMembers(uint _groupId, address[] calldata _members) external;
}

contract addressGrouperLooper{
	address[] _members; //temporary array
	address[] _reset; //for resetting _members

	address storageContract;
	uint groupCounter = 1;
	uint addressesPerGroup;
	uint maxGroups;


	constructor(uint _maxGroups, uint _addressesPerGroup, address _storageContract){
		storageContract = _storageContract;
		addressesPerGroup = _addressesPerGroup;
		maxGroups = _maxGroups;
	}

	//add to group
	function addToGroup(address _address) public {
		bool atMax = true;
		require(IlandBaronstorage(storageContract).getGroupId(_address) == 0, "Duplicate address entered");
		uint _lowest = 1;
		for(uint i = 1; i <= maxGroups; i++){
			if(IlandBaronstorage(storageContract).getGroupMembers(i).length == addressesPerGroup){
				continue;
			}else{
				if(IlandBaronstorage(storageContract).getGroupMembers(i).length < IlandBaronstorage(storageContract).getGroupMembers(_lowest).length){
					_lowest = i;	
				}
				atMax = false;
			}
		}
		if(!atMax){
			IlandBaronstorage(storageContract).addToGroup(_address, _lowest);
			IlandBaronstorage(storageContract).addToMembers(_lowest, _address);
		}else{
			revert("all groups are full");
		}
	}

	//remove from group
	function removeFromGroup(address _address) external {
		require(IlandBaronstorage(storageContract).getGroupId(_address) != 0, "The address provided is not a token holder");
		_members = IlandBaronstorage(storageContract).getGroupMembers(IlandBaronstorage(storageContract).getGroupId(_address));
		for(uint i = 0; i < _members.length; ++i){
			if(_members[i] == _address){
				_members[i] = _members[_members.length - 1];
				_members.pop();

				IlandBaronstorage(storageContract).updateMembers(IlandBaronstorage(storageContract).getGroupId(_address), _members);
				IlandBaronstorage(storageContract).removeFromGroup(_address);
				_members = _reset;
				return;
			}
		}
		IlandBaronstorage(storageContract).removeFromGroup(_address);
		_members = _reset;
		revert("Address was not found");
	}

	// function getGroupId(address _address) external view returns(uint){
	// 	require(IlandBaronstorage(storageContract).getGroupId(_address) != 0, "The address provided is not a token holder");
	// 	return group[_address];
	// }

	// function getGroup(uint _groupId) external view returns(address[] memory){
	// 	require(_groupId <= maxGroups, "You have requested a group beyond the maximum groups allowed");
	// 	return members[_groupId];
	// }
}