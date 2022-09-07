// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Define contract
contract SimpleStorage {
    // boolean, uint, int, address, bytes, string
    // Data Types
    /*
    bool hasFavoriteNumber = true;
    uint256 favoriteNumber = 5;
    string favoriteNumberInText = "Five";
    int favoriteInt = -5;
    address myAddress = 0x5C1d25e1f3933f79896f4947c6e78704B36bBD5d;
    bytes32 animal = cat;
    */

    // This gets initialized to zero!
    // <- This means that this section is a comment!
    // initializing a variable
    // public variable implicitly get assigned a function that returns its value!

    uint256 favoriteNumber;
    // People public person = People({favoriteNumber: 2, name: "Yeb" });

    // Struct can be used to create personal variables
    //Q3. Creating Object and Arrays

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    //Q4. Data Structure (Array)
    // uint256[] public favoriteNumber;
    // Dynamic Arrays
    People[] public people;

    // Q7. Basic Soldity Mappings
    /*
     * A mapping is a data strucutre where a key is "mapped" to a single
     * value. An easy way is to thingk of it as a dictionary
     */
    mapping(string => uint256) public nameToFavoriteNumber;

    // Q5. Basic Solidity Errors and Warnings
    /*
     * Warnings won't stop your code from working but it's usualyy a
     * good ide to check them out.

    */

    // Q6. Basic Solidity Memory, Storage, & Calldata (intro)
    /*
     * EVM can access and store information in six (6) places:
     * 1. Stack
     * 2. Memory
     * 3. Storage
     * 4. Calldata
     * 5. Code
     * 6. Logs
     
     * 3 Main EVM Storage: calldata, memory, storage
     * Calldata : Are temporary variable that cannot be modified
     * Memory: Are temporary variables that can be modified
     * Storage: Are permanent variables that can be accessed and modified. 
     *
     * By Default all variables are assinged storage privillege
    */

    /*
     * "Functions" or "Methods" execute a subset of code when called
     */
    function store(uint256 _favoriteNumber) public {
        /*
         * Store:  Name of functions
         * uint256: Type of variable the function will hold
         * _favoriteNumber:  Name of variable
         * publc : make the function accessible to everyone
         */
        favoriteNumber = _favoriteNumber;
    }

    //view, pure
    /*
     * View and pure functions, when called alone, don't spend gas
     * View functions diallows any modification of state
     8 Pure function additionally disallow you to read from blockchain state
    */
    function retrieve() public view returns (uint256) {
        /*
         * retrieval: Name of function
         * public: Visibility
         * view: State
         * returns: Return data from blockchain
         */
        return favoriteNumber;
    }

    // Creating functions for the Array - People
    // calldata, memory, storage
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        // People memory newPerson = People({
        //     favoriteNumber: _favoriteNumber,
        //     name: _name
        // });
        people.push(People(_favoriteNumber, _name));
        // Add mapping to function
        nameToFavoriteNumber[_name] = _favoriteNumber;
        // Or people.push(People(_favoriteNumber, _name));
    }
}