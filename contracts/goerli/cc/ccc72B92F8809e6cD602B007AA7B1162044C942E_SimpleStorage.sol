//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8; //solidity version

// pragma solidity >=0.8.0 <0.9.0;

contract SimpleStorage {
    //This initializes favoriteNum to zero!
    //public create a getter function implicitly for storage/state variable
    uint256 favoriteNum;

    //struct:
    struct People {
        uint256 favoriteNum;
        string name;
    }
    //Declare structure
    // People public person = People({
    //     favoriteNum: 7,
    //     name: "Andrew"
    // });

    //Array: collection of other types
    //uint256[] public favoriteNumList;
    People[] public people;

    mapping(string => uint256) public nameToFavNum;

    function store(uint256 _favoriteNum) public virtual {
        favoriteNum = _favoriteNum; //sets favoriteNum Variable
        // retrieve(); //it will cost gas
    }

    // view and pure function don't cost gas
    function retrieve() public view returns (uint256) {
        return favoriteNum;
    }

    //calldata, memory & storage

    //function to add person in people array and mapping
    function addPerson(string memory _name, uint256 _favoriteNum) public {
        people.push(People(_favoriteNum, _name));
        //other way is shown below.....
        // People memory newPerson = People({favoriteNum: _favoriteNum, name: _name});
        // people.push(newPerson);

        //adding to mapping variable
        nameToFavNum[_name] = _favoriteNum;
    }
}