// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8; 

// contract similar to class
contract SimpleStorage {

    // public implicitly give us a getter function
    // visibilty is by default internal
    uint256 public favoriteNumber;
	
    struct Person {
        uint256 num;
        string name;
    }

	// mapping
	mapping(string => uint256) public stringToName;

    Person[] public peoples;

    Person people = Person({num: 2, name: "Morphx"});

    function store(uint256 _fav)  public {
        // the more math you do the more gas it costs
        favoriteNumber = _fav;
    }

    // pure and view doesn't require gas
    function retrieve() public view returns(uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _num) public {
        peoples.push(Person(_num, _name));
		stringToName[_name] = _num;
    }
}