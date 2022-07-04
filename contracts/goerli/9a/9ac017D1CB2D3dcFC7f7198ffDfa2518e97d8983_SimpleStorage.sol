// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract SimpleStorage {
    bool hasFavouriteNumber = true;
    uint256 favouriteNumber = 69; //allocated 256 bits -> multiple of 8
    string favouriteNumberInText = "Five";
    int256 favouriteInt = -5;
    address myAddress = 0xAd991c86C0d760C776F2aD0432B748e6Cd727D9d;
    bytes32 favouriteBytes = "cat"; //how many bytes
    uint256 damiNum;

    //adding virtual makes this overrideable
    function store(uint256 _favNum) public virtual {
        damiNum = _favNum;
    }

    function retrieve() public view returns (uint256) {
        return damiNum;
    }

    struct People {
        uint256 favouriteNumber;
        string name;
    }

    mapping(string => uint256) public nameToFavoriteNumber;
    People public person =
        People({favouriteNumber: 2, name: "Roshan Parajuli"});
    People[] public people;

    function addPerson(string memory _name, uint256 _favNo) external {
        People memory newPerson = People({
            favouriteNumber: _favNo,
            name: _name
        });
        people.push(newPerson);
        nameToFavoriteNumber[_name] = _favNo;
    }
}