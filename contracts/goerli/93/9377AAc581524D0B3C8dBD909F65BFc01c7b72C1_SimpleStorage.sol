/**
 *Submitted for verification at Etherscan.io on 2022-09-09
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7; // comment, ^: it s ok for above versions, >=, < for ranges

contract SimpleStorage {
    // solidity types: boolean, unit: unsigned int -> 8uint, 256uint: max bit for uint, int, address, bytes
    bool hasFavouriteNumber = true; // 'false' instead;
    uint256 public favouriteNumber = 0; // visibility changed, deafult as 'internal'
    int favouriteNumberInt = 5;
    string words = "hi";
    address myAddress = 0x8a22CF44a968Fa3f099235bACd14ec0640d79c39;
    bytes32 something = "hello";
    uint256 number; // default initalized to 0

    mapping(string => uint256) public nameToFavouriteNumber;

    People public person = People({favouriteNumber: 2, name: "Andrea"});
    People[] public people; // array

    struct People {
        uint256 favouriteNumber;
        string name;
    }

    function store(uint256 _favouriteNumber) public virtual {
        // function declaration
        favouriteNumber = _favouriteNumber;
        // favouriteNumber = favouriteNumber+1; gas increases
    }

    // view: read state from contract -> no gas fees
    // pure: others -> pay gas only if blockchain state modified
    function retrieve() public view returns (uint256) {
        // gas because it reads from pure function
        return favouriteNumber;
    }

    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        People memory newPerson = People(_favouriteNumber, _name);
        people.push(newPerson);
        nameToFavouriteNumber[_name] = _favouriteNumber;
    }
}