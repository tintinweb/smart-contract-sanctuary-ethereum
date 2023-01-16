//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    //initial favoriteNumber to 0, 如果是public 那么就会默认显示这个variable
    uint256 favoriteNumber = 0;

    //因为是People type所以可以直接引用People type 里面的variable 像这样子
    //People public person = People({favoriteNumber: 2 ,name: "Tom"});

    mapping(string => uint256) public nameToFavoriteNumber;

    //创建一个People type, 就像在使用uint256一样
    struct People {
        uint256 favoriteNumber;
        string name;
    }
    //create a People dinymic array
    People[] public people;

    //让user输入一个数值储存在_favoriteNumber 里面，然后_favoriteNumber 的数值会转移到favoriteNumber
    //这里的 virtual 在作用是， 如果要override 这个function， 那么就要加这个key word
    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    //this returns means that after we call this function. it will return us a  variable - type is uint256
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    //calldata, memory, storage
    //calldata & memory means that variable will only  exist temporarily
    //storage will exist outsidr of this function
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}