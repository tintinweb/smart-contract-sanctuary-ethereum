// SPDX-License-Identifier: MIT
pragma solidity 0.8.8; // Setting up solidity version

contract SimpleStorage {
    //public here internally created a getter funtion which gets the stored value.
    // uint256 public favouriteNumber;  //Default value is zero and its internal if we don't add modifier
    uint256 favouriteNumber;
    // People public person = People({favouriteNumber: 2, name: "Balajee "});

    mapping(string => uint256) public nametoFavouriteNumber;

    struct People {
        uint256 favouriteNumber;
        string name;
    }
    //In case of public , it automatically add view funtion
    People[] public people;

    //The more stuff in your function the more gas it costs.
    //use virtual keyword to make any funtion overridable
    function store(uint256 _favouriteNumber) public virtual {
        favouriteNumber = _favouriteNumber;
    }

    //view
    //pure
    //2. View and Pure function when called alone , don’t spend gas.
    function retrieve() public view returns (uint256) {
        return favouriteNumber;
    }

    // Calldata, memory, Storage
    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        // People memory newPerson = People({favouriteNumber: _favouriteNumber, name: _name});
        // people.push(newPerson);
        //Without memory keyword
        people.push(People(_favouriteNumber, _name));
        nametoFavouriteNumber[_name] = _favouriteNumber;
    }
}