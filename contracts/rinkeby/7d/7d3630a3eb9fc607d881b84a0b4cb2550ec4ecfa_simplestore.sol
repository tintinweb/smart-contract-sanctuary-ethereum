/**
 *Submitted for verification at Etherscan.io on 2022-08-11
*/

// SPDX-License-Identifier: MIT
pragma solidity  ^0.6.0;


contract simplestore{


	//

	uint256  mynumber;

	struct People{

		uint256 mynumber;
		string name ;

	}

	People[] public people;
	mapping(string=>uint256) public nametonumber;


	


	function store(uint256 _mynumber) public{


mynumber=_mynumber;

	}


	function retrive() public view   returns (uint256){

return mynumber;
	}

	function addPerson(string memory _name, uint256 _number) public{

		people.push(People(_number,_name));

		nametonumber[_name]=_number;


	}





}