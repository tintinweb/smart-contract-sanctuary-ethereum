// SPDX-License-Identifier: MIT
// ^ means any version at or above this version.
// no modifier means exactly this version
// >=x.x.x < x.x.x means greater than or less than
pragma solidity 0.8.8; // 0.8.7 is known as a stable version.

// think of contract like a class in python
contract SimpleStorage {
    // basic solidity types:
    // - boolean, uint, int, address, bytes, string
    // - (uint is a whole number that isnt positive or negative)
    bool hasFavoriteNumber = true;
    uint256 favoriteNumberUint = 123; // uint is special because we can specify how many bits can be allocated to this. unit8 - uint256. If you dont specify, it defaults to uint256
    int256 favoriteNumberInt = -5;
    string favoriteNumberStr = "Five";
    bytes32 favoriteNumberBytes = "cat"; // 32 is the max for bytes. 8 bits in a byte, so u can do 256 / 8 = 32 for uints.
    // uint256 public favoriteNumber = 123; // uint is special because we can specify how many bits can be allocated to this. unit8 - uint256. If you dont specify, it defaults to uint256

    // Visibility Specifiers:
    // --- public: visible externally and internally (automatically creates a getter function [only if it is a variable?]). I.e., there will be a function w/ name of the variable automatically created.
    // --- private: only visible in the current contract
    // --- external: only visible externally (only for functions)
    // --- internal: only visible internally [ THIS IS THE DEFAULT IF YOU DONT SPECIFY ]

    // actually used in the tutorial:
    uint256 public favoriteNumber; // automatically initializes to 0

    //structs
    // this is a new struct (seems like a hybrid of a list/dict. It is indexed but also has key/value pairs) called people. It accepts a uint256 called favoriteNumber and a string called name.
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    // again, this will create a getter function that can be called ("person")
    People public person = People({favoriteNumber: 2, name: "Patrick"});

    // array is more like a normal list. but have to specify type at beginning.
    People[] public people; // could also give it a size by People[3] to specify max.

    // add a new "People" object, init'd with favoriteNumber and name, to the people array.
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        // People memory newPerson1 = People({favoriteNumber: _favoriteNumber, name: _name});
        // People memory newPerson2 = People(_favoriteNumber, _name); // don't need to be explicit, can just enter the vars in order.
        // people.push(newPerson2);
        people.push(People(_favoriteNumber, _name)); // can avoid using memory keyword if we create the new object inside of the push function
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

    // STORAGE:
    // -- structs, mappings, and arrays (and this includes strings) need to be given a storage keyword. Other variables don't.
    // -- What we won't discuss in this section: "Stack", "Code", "Logs". CANNOT ASSIGN A VARIABLE TO THESE.
    // -- IN THIS SECTION (Can assign a variable to these):
    // ---- Calldata
    //          Variable will only exist temporarily
    // ---- Memory
    //          Variable will only exist temporarily
    //          Can modify the variable (cannot with Calldata)
    // ---- Storage
    //          Variable will continue to exist

    // function is like a method in python
    // we added virtual for the ExtraStorage.sol contract since that contract inherits and overrides this function. Need virtual modifier to be able to be overriden.
    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
        // uint256 testVar = 5;
    }

    // mapping can help us find a persons favorite number without looping thru
    mapping(string => uint256) public nameToFavoriteNumber;

    // nb "view" and "pure" don't require any gas. Cannot modify state.
    // "pure" you also cant even read state. It is for basic math etc.
    // it costs gas IFF you call it from another function that costs gas.
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }
}