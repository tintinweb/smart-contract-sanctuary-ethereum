/**
 *Submitted for verification at Etherscan.io on 2022-11-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

contract SimpleStorage {
    //boolean, uint, int, address, bytes
    //  bool hasFavouriteNumber=true;
    //  uint256 favouriteNumber =5;
    //  int256 favouriteInt=-5;
    //  string favouriteNumberInText="Five";
    //  address myAddress= 0x3746343473483483;
    //  bytes32 animal="cat"

    //  this get initialize to zero.
    uint256 favouriteNumber;

    struct People {
        uint256 favouriteNumber;
        string name;
    }

    People public person = People({favouriteNumber: 2, name: "haseeb"});

    //In solidity there is static and dynamic arrays
    // uint256[] public favouriteNumber;
    People[] public people;

    //mapping
    mapping(string => uint256) public nameToFavouriteNumber;

    function store(uint256 _favouriteNumber) public virtual {
        favouriteNumber = _favouriteNumber;

        //but here the view function costs gas because we are calling it inside a state changing function
        retrive();
    }

    // view and pure functions cant cost any gas because we are not updating blockchain state in them.

    //view function cant update the state but we can only read data from blockchain
    function retrive() public view returns (uint256) {
        return favouriteNumber;
    }

    //pure functions cant only update state but we cant read blockchain from them ,like
    function add() public pure returns (uint256) {
        return (1 + 1);
    }

    //calldata, memory, storage
    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        people.push(People(_favouriteNumber, _name));

        //  or

        //   People memory newPerson=People({favouriteNumber:_favouriteNumber,name:_name});
        //     people.push(newPerson);

        //   or

        //  People memory newPerson=People(_favouriteNumber,_name);
        //  people.push(newPerson);

        nameToFavouriteNumber[_name] = _favouriteNumber;
    }
}