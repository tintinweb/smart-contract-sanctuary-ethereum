/**
 *Submitted for verification at Etherscan.io on 2023-05-28
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract SimpleStorage {
    // boolean, unit, int , address, bytes
    // bool hasfavoriteNumber = true;
    // gets initaillay intailaized with zeroo
    uint public favoriteNumber;
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;

    mapping(string => uint256) public nameToFavnum;

    // People public  person =  People({favoriteNumber:2,name:'AWais'});
    // string favStr='Five';
    // int256 favInt=-5;
    // address myadr = 0x505DB390F1825309a327C74F4b163ca7c105f499;
    // bytes32 favBytes = "cat";
    function store(uint256 _fav) public virtual {
        favoriteNumber = _fav;
    }

    // view & pure functions dont use gas
    function retrives() public view returns (uint256) {
        return favoriteNumber;
    }

    // function addPerson (string memory _name,uint256 _favroteNumber) public  {
    //     // People memory newPerson = People({favoriteNumber:_favroteNumber,name:_name});
    //     // people.push(newPerson);
    //     people.push(People(_favroteNumber,_name));
    // }

    // callback, memory, storage
    /* calldate, memory is temporary */
    function addPerson(string memory _name, uint256 _favroteNumber) public {
        people.push(People(_favroteNumber, _name));
        nameToFavnum[_name] = _favroteNumber;
    }

    /* 0xd9145CCE52D386f254917e481eB44e9943F39138 */
}

/* 
contract SimpleStorage {

    uint256 favoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }
    // uint256[] public anArray;
    People[] public people;

    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }
    
    function retrieve() public view returns (uint256){
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
} */