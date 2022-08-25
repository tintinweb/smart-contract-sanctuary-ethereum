// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract SimpleStorage {
    // data types i.e. boolean, uint, int, address, bytes
    uint256 public favoriteNumber;

    //notice that variables are indexed i.e. [0]favoriteNumber [1]first [2]middle [3]last
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    mapping(string => uint256) public nameToFavoriteNumber;
    //Array
    People[] public people;

    //People public person = People({favoriteNumber: 2,first:"First",middle:"Middle",last:"Last"});

    function storeNumber(uint256 _favoriteN) public {
        favoriteNumber = _favoriteN;
        // but calling this no-gas function inside the gas calling function, it will cost gas
        retrieveFave();
    }

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        // People memory person = People({name: _name, favoriteNumber:_favoriteNumber});
        // People memory person = People(_favoriteNumber,_name);
        //people.push(person);
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

    //this function doesn't cost any gas
    function retrieveFave() public view returns (uint256) {
        return favoriteNumber;
    }

    //Contract address: 0xd8b934580fcE35a11B58C6D73aDeE468a2833fa8
    //Contract address: 0x7EF2e0048f5bAeDe046f6BF797943daF4ED8CB47
}