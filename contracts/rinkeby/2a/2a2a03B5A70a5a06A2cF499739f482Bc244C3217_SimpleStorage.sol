// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract SimpleStorage{
    // bool hasFavoruteNumber = true;
    uint256 public favotiteNumber;
    // string favoruteNumberInText = "Five";
    // int32 favoriteInt = -5;
    // address myAddress = 0x1BCFF18E3B53bEA469085bFA865dC63Ce44cbd96;
    // bytes32 favoriteBytes = "cat";

    // People public person = People({favotiteNumber: 7, name: "Rohit"});

    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favotiteNumber;
        string name;
    }

    // uint256[] public favotiteNumberList;
    People[] public people;
    

    function store(uint256 _favotiteNumber) public virtual {
        favotiteNumber = _favotiteNumber;
        retrive();
    }

    // view, pure don't spend gad
    function retrive() public view returns(uint256){
        return favotiteNumber;
    }

    function add() public pure returns(uint256){
        return 1 + 1;
    }

    function addPerson(string memory _name, uint256 _favotiteNumber) public {
        People memory newPerson = People({favotiteNumber: _favotiteNumber, name: _name});
        people.push(newPerson);
        nameToFavoriteNumber[_name] = _favotiteNumber;
    }

}