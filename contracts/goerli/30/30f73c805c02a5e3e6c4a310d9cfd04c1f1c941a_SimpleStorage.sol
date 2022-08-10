/**
 *Submitted for verification at Etherscan.io on 2022-08-10
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.8; // greater than 0.8.7 (^0.8.7) -  or a range (>=0.8.8 <0.9.0)

// EVM, Ethereum Virtual Machine
// Avalanche, Fantom, Polygon

contract SimpleStorage {
    //Variable type
    //boolean, uint, int, address, bytes
    //bool hasFavoriteNumber = false;
    //uint favoriteNumber = 123;
    //uint256 favoriteNumber2 = 256;
    //int favoriteNumber3 = 789;
    //string favoriteNumberInText = "Five";
    //int256 favoriteInt = -5;
    //address myAddress = 0x4EE070b2808DE04EF095e58D80401448643f571B;
    //bytes32 favoriteBytes32 = "cat";
    //bytes favoriteBytes = "cat";
    uint256 favoriteNumber; //will default initate = 0 -- without public you can't see it, add public to see it
    People public person = People(
        {favoriteNumber: 2, name: "JC"}
    );

    //array
    People[] public personList;

    struct People{
        uint256 favoriteNumber;
        string name;
    }

    //mapping key is case sensitive, JC <> Jc
    mapping(string => uint256) public nameToFavoriteNumber;

    //public: visible externally and internally (create a getter function for storage/state variables)
    //private: only visible in the current contract
    //external: only visible externally (only for functions) - i.e. can only be message-called (via this.func)
    //internal: only visible internally; default as internal if not declare

    function store(uint256 _favoriteNumber) public {
        favoriteNumber =  _favoriteNumber;
        retrieve(); //this will cost more gas even retrieve function is public view
    }

    //view, pure: will not cost gas - no hash, only can get the state in contract, can't update
    //calling the function idenpendenty will not cost gas; however if call the function inside another function then will cost gas
    function retrieve() public view returns(uint256) {
        return favoriteNumber;
    }

    function add() public pure returns(uint256) {
        return(1+1);
    }

    function addPeople(string memory _name, uint256 _favoriteNumber) public {
        People memory newPerson = People({favoriteNumber: _favoriteNumber, name: _name});
        personList.push(newPerson);
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
    

    //study about calldata, memory, storage; stack, logs and code will be learned later
    
    //calldata: temporary variable that can't be modify
    //e.g. of wrong using calldata
    //function wrongcalldata(string calldata _name, uint256 _favoriteNumber) public {
    //    _name = "cat";
    //    People memory newPerson = People({favoriteNumber: _favoriteNumber, name: _name});
    //}

    //memory: temporary variable that allow to modify in the function
    //memory only needs to be added for array/string, struct and mapping types, uint256 cant define as memory
    //storage: permanent variable that can be modified
}

//0xd9145CCE52D386f254917e481eB44e9943F39138