//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; // to specify the version of compiler.. use ^ before the version number to ensure all later compiler version is permited

//a contract keyworld in solidity is use to create a class
contract SimpleStorage {
    //data types includes
    //by default, variables have internal access modifier
    // the can also be private or public
    bool hasFavouriteNumber = true;
    uint256 public favoriteNumber = 5;
    string favouriteInText = "Five";
    int256 favouriteInt = -5;
    address myWalletAddress = 0xbfC63927FB4070F86E95F2d41975cE705977dDB0;
    bytes32 favouriteBytes = "cat";

    //a public function named store that accept a uint256 as argument
    // a function has access modifier such as public, private, external, internal
    //vitual keyword ensure child of the contract can override it
    function store(uint256 _favouriteNumber) public virtual {
        favoriteNumber = _favouriteNumber;
    }

    //A function mark view or pure does not modify the blockchain hence no gas fee will be burn if run
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    //a struct keyword is use to create an object in solidity
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    //  People public person = People({favoriteNumber: 4, name: "Alli"});

    //An array
    //static array of int256 object that will contain 4 object
    //int256[4] public newArray;
    //dynamic array
    People[] public peopleArray;

    //for array,struct and map where they are stored when they are parameter to a function must be specified
    //memory denote temp storage that can be modified
    //calldata denote temp memory that cannot be modified
    //storage are perm. memory that can be modified
    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        //peopleArray.push(People({favoriteNumber: 2, name: "hush"}));
        peopleArray.push(People(_favouriteNumber, _name));
        nameToFavouriteNumber[_name] = _favouriteNumber;
    }

    mapping(string => uint256) public nameToFavouriteNumber;
}