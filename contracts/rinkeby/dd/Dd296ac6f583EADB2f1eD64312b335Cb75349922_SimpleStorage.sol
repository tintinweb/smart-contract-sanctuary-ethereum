// SPDX-License-Identifier: MIT
// solidity version
pragma solidity ^0.8.8;

// pragma solidity ^0.8.7 any version above this is ok
//  >= .... < between version

contract SimpleStorage {
    //  boolean , uint , int , address , bytes
    uint256 public favNumber;
    //   People public person = People({favN : 5 , name : "BHumi"});
    uint256[] public pep;
    People[] public people;

    mapping(string => uint256) public nameTofavN;

    struct People {
        uint256 favN;
        string name;
    }

    function store(uint256 favN) public virtual {
        favNumber = favN;
    }

    function retrieve() public view returns (uint256) {
        return favNumber;
    }

    function add() public pure returns (uint256) {
        return (13 + 11);
    }

    // memory -> tempo existence can be modified
    // calldata -> tempo dont be modified
    // storage -> permenant data can be modified
    function addPeople(string memory _name, uint256 _favN) public {
        // People memory newPer = People({favN : _favN , name : _name});
        People memory newPer = People(_favN, _name);

        people.push(newPer);
        nameTofavN[_name] = _favN;
    }
}

// 0xd9145CCE52D386f254917e481eB44e9943F39138
// everytime we change blockchain its a transaction