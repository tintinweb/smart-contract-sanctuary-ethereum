// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

contract SimpleStorage {
    uint public favoriteNumber;

    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint favoriteNumber;
        string name;
    }

    People public person = People({favoriteNumber: 2, name: "Pesho"});

    People[] public people;

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

	function blockStamp () public view returns(uint256) {
		return block.timestamp;
	}

	function blockDiff () public view returns(uint256) {
		return block.difficulty;
	}

	function getKeccak() public view returns(uint256) {
		return uint256(keccak256(abi.encodePacked(address(this),block.difficulty,block.timestamp))) % 1000000;
	}

}