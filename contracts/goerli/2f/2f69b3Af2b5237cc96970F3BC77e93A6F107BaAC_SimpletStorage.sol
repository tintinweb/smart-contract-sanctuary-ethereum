/**
 *Submitted for verification at Etherscan.io on 2022-11-06
*/

pragma solidity 0.8.17;

contract SimpletStorage{
	uint favoriteNumber;
	struct People {
		uint256 favoriteNumber;
		string name;
	}
	People[] public people;
	mapping(string => uint256) public nameToFavoriteNumber;

	function store(uint _favoriteNumber)public {
		favoriteNumber=_favoriteNumber;
	}

	function retrieve() public view returns(uint256){
      return favoriteNumber;
	}

	function addPerson(string memory _name, uint256 _favoriteNumber) public {
		people.push(People(_favoriteNumber,_name));
		nameToFavoriteNumber[_name]=_favoriteNumber;
	}
}