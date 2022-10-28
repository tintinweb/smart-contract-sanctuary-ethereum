// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    // booleanm uint, int, address, bytes

    mapping(string => uint256) public nameToFavNumber;

    struct People {
        uint256 favNumber;
        string name;
    }
    People[] public peoples; //dynamic
    People[4] public peoples2; //static

    uint256 public favNumber = 5; //8 and multiples o f8 //internal is default scope
    string favNumberText = "five";

    // function favNumberReturn(uint256 _favNum) public virtual {
    //     favNumber = _favNum;
    // }

    //view, pure do not create new transactions as they cnanot be used to change state of blockchain
    //view is used to view blockchain state
    //pure you cannot even retrieve state
    function retrieve() public view returns (uint256) {
        return favNumber;
    }

    //some kinda math maybe or some algo which does not need blockchain state
    // function retrivePure() public pure returns(uint256){
    //     return (1+1);
    // }

    function store(uint256 _favoriteNumber) public virtual {
        favNumber = _favoriteNumber;
    }

    //different places where data can be stored
    /** 
    calldata - temp variable which cannot be modified
    memory - only exists temporarily, can be modified
    storage - stays in memory on contract, can be modified

    string needs to be given memory keyword because string treated as array in sol, array structs and something are treated as memory
    **/
    function addPerson(string memory _name, uint256 _favNum) public {
        peoples.push(People({favNumber: _favNum, name: _name}));
        nameToFavNumber[_name] = _favNum;
    }
}