// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract SimpleStorage {
    // JS TS 32h course

    // boolean, uint, int, string,  address, bytes
    //bool true/false
    bool hasFavoriteNumber = true;

    // uint cant be negative
    // to be able to see the stored favorite number we need to change the visibility of the variable storing it to public
    uint public favoriteNumber = 0;

    //mappings like a dictionnary a set of keys mapped to a value.
    // ie if we know a name of a person from the array we could search it using its name using a mapping
    mapping(string => uint256) public nameToFavoriteNumber;

    // can use a key / value pair to store let say a name to its corresponding number.
    // this is a struct. which will create a new type called people in this case
    People public person = People({favoriteNumber: 2, name: "patrick"});
    // using the line above require to add as much line as their is people to store their key value pair
    struct People {
        uint256 favoriteNumber;
        string name;
    }
    //the right way for storing a lot of values is an array, both down are dynamic array
    People[] public people;
    //can be done for numbers too
    uint256[] public favoriteNumberList;
    // an array of size 3
    uint256[3] public fixArray;

    // can specify bytes for uint
    uint256 favoriteNumberTwo = 0;
    //work the same for int

    //string object are actually a byte object but only for a text
    string favoritePhrase = "dream";
    //int can be negative
    int negativeNumber = -5;

    address MyAdress = 0xe071EeD2EB7CA3514e40d81533046aa90D12f768;

    bytes32 favoriteBytes = "cat";

    // the Null value is 0 in solidity
    // so initializing a number
    uint256 testInt;

    // is the same as
    //uint256 testInt = 0;

    //functions
    // function called store
    //taking some parameter as input
    // with an public access to it.
    // in which our favoriteNumber variable will be equal to the inputed parameter
    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
        // the more the computation is necessary the more gas will augment
        //so let say we add or just do +1 to the variable. gas price for interaction wont be the same as without the surplus
        favoriteNumber = favoriteNumber + 1;
        //require to pay more gas, details after pure function
        retrieve();
    }

    // view disallow just state change of the blockchain. not the reading from it
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // pure disallow reading AND state change from the blockchain so can read favoriteNumber value
    // so if we doesnt need to reed from the blockchain the right use is like this
    function add() public pure returns (uint256) {
        return (1 + 1);
    }

    // if a function costing gas is calling a pure or view function it will cost additional gas
    // otherwise both doesnt cost any gas, they are free unless they are called inside another function
    // which need to pay for computational events so let say like putting retrieve() inside store()

    //function to push into an array
    function addPeople(string memory _name, uint256 _favoriteNumber) public {
        // lower case p = array, capital p = struct
        // take the people array and push into it a new People object, aka a new person, containing a number and a name
        // that way it avoid to use again the memory storage
        //people.push(People(_favoriteNumber, _name));

        //can also be done like this
        //People memory newPerson = People({favoriteNumber: _favoriteNumber, name: _name});
        // or like this which is exactly the same as the previous line
        People memory newPerson = People(_favoriteNumber, _name);
        people.push(newPerson);
        // add the person to the mapping too
        // string to uint, at the key _name it will be returning the value og its favoritenumber
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
    //function to push into an fixed array
    //  function addNumber(uint256 _fixArray) public {
    //       fixArray.push(uint256 _fixArray);
    //   }
}