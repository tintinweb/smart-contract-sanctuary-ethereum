//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; // 也可以这么写 >=0.8.7 <0.9.0

contract SimpleStorage {
    // boolean, uint, int, address, bytes, string
    uint256 public favoriteNumber;

    mapping(string => uint256) public nameToFavoriteNumber;

    People[] public people;

    People public person = People({
        favoriteNumber :4,
        name : "simon"
    });

    struct People{
        uint256 favoriteNumber;
        string name;
    }

    function store(uint _favoriteNumber) public virtual{
        favoriteNumber = _favoriteNumber;
    }
    
    // view:只允许读取合约的状态，但不允许进行修改，因此该标识符的函数不会增加gas的消耗
    // pure:和view一样的同时，连合约内的状态都不能读取。
    function retrieve() public view returns (uint256){
        return favoriteNumber;
    }

    function add() public pure returns(uint256){
        return (1+1);
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        People memory newPerson = People({favoriteNumber: _favoriteNumber, name:_name});
        people.push(newPerson);
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}