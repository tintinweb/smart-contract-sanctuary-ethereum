/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// CSE542 DNS on Ethereum - Lalith Harisha, Tino Thayil

contract BlockDNS {
	struct Record {
		string recordType;
		string key;
		string value;
	}
	struct Domain {
		Record[] records;
		address owner;
		string name;
		uint8 numRecords;
	}
	mapping ( string => Domain) domains;

	function register(string memory name) public {
		if(keccak256(abi.encodePacked(domains[name].name)) != keccak256(abi.encodePacked(""))) return;
		domains[name].owner = msg.sender;
		domains[name].name = name;
		domains[name].numRecords = 0;
	}

	function getDomain(string memory name) public view returns (Domain memory){
		return domains[name];
	}

	function isRegistered(string memory name) public view returns (bool) {
		if(keccak256(abi.encodePacked(domains[name].name)) == keccak256(abi.encodePacked(""))) return false;
		return true;
	}

	function addRecord(string memory name, string memory recordType, string memory key, string memory value) public{
		if(keccak256(abi.encodePacked(domains[name].name)) == keccak256(abi.encodePacked(""))) return;
		Record memory record;
		record.recordType = recordType;
		record.key = key;
		record.value = value;
		domains[name].records.push(record);
		domains[name].numRecords += 1;
	}
	
	function deleteRecord(string memory name, uint8 index) public {
		if(keccak256(abi.encodePacked(domains[name].name)) == keccak256(abi.encodePacked(""))) return;
		domains[name].records[index] = domains[name].records[domains[name].numRecords - 1];
	        delete domains[name].records[domains[name].numRecords - 1];
		domains[name].numRecords -= 1; 
	}

	function getRecords(string memory name, string memory recordType, string memory key) public view returns (Record[] memory) {
		Record[] memory records;
		if(keccak256(abi.encodePacked(domains[name].name)) == keccak256(abi.encodePacked(""))) return records;
		uint8 i = 0;
		uint8 count = 0;
		for( i = 0; i < domains[name].numRecords; i++){
			if ( keccak256(abi.encodePacked(domains[name].records[i].recordType)) == keccak256(abi.encodePacked(recordType)) && keccak256(abi.encodePacked(domains[name].records[i].key)) == keccak256(abi.encodePacked(key))) {
				count ++;
				
			}
		}
		records = new Record[](count);
		count = 0;	
		for( i = 0; i < domains[name].numRecords; i++){
			if ( keccak256(abi.encodePacked(domains[name].records[i].recordType)) == keccak256(abi.encodePacked(recordType)) && keccak256(abi.encodePacked(domains[name].records[i].key)) == keccak256(abi.encodePacked(key))) {
				records[count] = domains[name].records[i];
				count ++;
				
			}
		}
		return records;
	}

}