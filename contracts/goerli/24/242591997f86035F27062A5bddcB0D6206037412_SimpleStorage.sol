// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract SimpleStorage {
    // declaring variables, public function to change the state of blokchain (change variable value)
    // and a public view function which acts as a getter function for the variable
    uint256 num = 0;

    // this function will cost us gas as it changing the state of the blockchain
    // "virtual" keyword is necessary for the child contract to be able to override this function
    function store(uint256 _num) public virtual {
        num = _num;
    }

    // this function won't cause us any gas as it is a "view" function which only returns a value
    function retrieve() public view returns (uint256) {
        return num;
    }

    // -----------------------------------------------------------------------------------------------

    // working with structs, mapping and arrays for storing the objects

    // struct works almost like JS constructor
    struct People {
        uint256 num; // num is a key and
        string name; // name is another key
    }

    People[] public people; // declaring an array of type "People"

    // string is the key, uint256 is the value
    // if duplicate keys are inserted, the latest value is saved in the mapping
    mapping(string => uint256) public nameToNumber;

    // if we use a array/structs, we need to specify the access location along with it
    // we can either use callback, memory, or storage as access location
    // but as we are using the array(string in this case), inside a parameter, we can only use memory/calldata
    // using memory, the variable data can be changed inside the function, but using calldata, it can't be changed
    function addPerson(string memory _name, uint256 _favNum) public {
        // adding the new person to the "people" list
        people.push(People(_favNum, _name));
        // but we also want to search directly by a name to get corresponding favorite number
        // thats why we also need to add the new person in the mapping type
        nameToNumber[_name] = _favNum;
    }
}