/**
 *Submitted for verification at Etherscan.io on 2023-03-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract SimpleStorage {
    // bool hasFavNo = true;
    uint public favNo;

    // int256 x =5;
    // string s = "Amit Kumar"
    // address myAddress = 0xD0A13235f2D299Db3567f8d3BfaaE2225f6C5979
    // bytes32 favBytes = "cat"

    function store(uint _favNo) public virtual {
        favNo = _favNo;
    }

    // 0xd9145CCE52D386f254917e481eB44e9943F39138

    // • public: visible externally and internally (creates a getter function for storage/state variables)
    // • private: only visible in the current contract
    // • external: only visible externally (only for functions) - i.e. can only be message-called (via this.func
    // • internal: only visible internally

    // view can only read
    function retrieve() public view returns (uint256) {
        return favNo;
    }

    // pure cannot even read
    function add() public pure returns (uint256) {
        return (1 + 1);
    }

    struct People {
        uint favNo;
        string name;
    }

    // People public people = People({favNo:2, name:"Amit"});

    People[] public people;

    function addPerson(string memory _name, uint256 _favNo) public {
        people.push(People(_favNo, _name));
        nameToFavNo[_name] = _favNo;
    }

    mapping(string => uint256) public nameToFavNo;
}