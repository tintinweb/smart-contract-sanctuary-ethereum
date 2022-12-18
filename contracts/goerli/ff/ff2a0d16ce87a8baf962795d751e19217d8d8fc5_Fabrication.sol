/**
 *Submitted for verification at Etherscan.io on 2022-12-17
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 < 0.9.0;
contract Fabrication {
	//storage
	address payable public owner;
	uint256 public units;
    //only the registered people can vote
	mapping (address => bool) public registered; 
	uint256 public lastChangeTimestamp; //unixtime --> provide seconds
    //Choose which extinct animal you would most like to bring back to life
    //you can check the animal's vote by typing its name
    mapping (string => uint256) public animals; 

	modifier isOwner() {
	//only the owner can do this
		require(msg.sender == owner);
		_;//the logic of the modified function
	}

	modifier isAuthorized () {
		require(registered[msg.sender] == true || msg.sender == owner, "You are not registered");
		_;//the logic of the modified function
	}

	modifier isCurrentUser(address newUser) {
		require(msg.sender == newUser, "You can only register for yourself");
		_;//the logic of the modified function
	}
	
	constructor(uint256 initialUnits) {
		//msg.sender by default is address, so we need to transfer it to payable
		owner = payable(msg.sender);
		units = initialUnits;
		lastChangeTimestamp = block.timestamp;
        //initialize some extincted animals
        animals["Ectopistes migratorius"] = 0;
        animals["Nesophontes edithae"] = 0;
        animals["Glaucopsyche xerces"] = 0;
	}

	//only the owner can adjust the unit
	function setUnits(uint256 _units) isOwner public {
		//7days, solidity will help us to change it to second
		//second parameter of require is the message
		require(block.timestamp > lastChangeTimestamp + 7 days, "too early to change units");
		units = _units;
		lastChangeTimestamp = block.timestamp;
	}

    //As long as you pay, you can vote as many times as you want, you can vote for a new animal or animal that is already exist
    function vote(string memory animalName) isAuthorized payable public {
		require(msg.value >= units * 1 ether);
        animals[animalName] = animals[animalName] + 1;
		//every time somebody vote, unit will increment to one, that means, the next people need to pay more to vote
        units = units + 1;
	}
	
	//Everyone can register for themselves
	function registration(address newUser) isCurrentUser(newUser) public{
		registered[newUser] = true;
	}

	//only the owner can delete registered	
	function removeRegistered(address _registered) isOwner public {
		registered[_registered] = false; 
	}

	function balance() private view returns (uint256){
		//use this to reference this smart contract
		return address(this).balance;
	}

	function withdraw() isOwner public {
	//to allow transfer it need be payable 
		owner.transfer(balance());
	}
}