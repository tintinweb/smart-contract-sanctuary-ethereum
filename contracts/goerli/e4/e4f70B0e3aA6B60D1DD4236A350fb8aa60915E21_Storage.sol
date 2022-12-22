// SPDX-License-Identifier: MIT
pragma solidity 0.8.17; // ila zedna '^' kate3ni ay version kbira mn dik la version li mentione raha accepted

contract Storage {
    // types in solidity: boolean, uint, int , address, bytes, string
    // solidity is statically-typed language = the type of each variable needs to be specified
    bool hasFavoriteNumber = false;
    uint256 favoriteNumber = 10; //256 bits
    string favoriteNumberText = "ten";
    address myAddress = 0x613D035C32737aA1A93F2eE8cF03FD4d1eE58000;

    // ila declarina xi variable sans valeur donc radi tkon fiha default valeur li khassa b dik type
    // example:
    // uint256 numberOfAddress; donc numberOfAddress ratkon fiha 0 hia default value dial uint256

    uint256 randomNumber; // randomNumber daba ra fiha 0

    // a special data type called structure , it is used by using the keyword "struct"
    // had struct b7al ila ka definilek wahed new type (b7al uint, string...)
    struct people {
        string name;
        uint256 age;
    }
    Storage.people[] public users;
    //hna syebna wahd empty array of objects
    // had objects li raykono f users array radi ytb3o dik struct li definina (struct people)

    mapping(string => uint256) public userAge;

    function addUsers(string memory _name, uint256 _age) public {
        users.push(people(_name, _age));
        userAge[_name] = _age;
    }

    function getUserByIndex(
        string memory _userName
    ) public view returns (uint256) {
        return userAge[_userName];
    }

    // storing data :
    // calldata :for temporary variables that cannot be modified
    // memory : for temporary variables that can be modified
    // storage : for permanent variables that can be modified

    //remarque importante: ila zedna keyword "public" before any variable name dik sa3a n9dro nchofoh
    // after the function call
    // ila mazednach had keyword donc varibale kayb9a private w mat9derch tchofo

    /*function changeNumber (uint256 number ) public {
        randomNumber = number;
    } */

    // view, pure
    // view and pure functions do not modifies the state of blockchain
    //they just return or retrieve the value of something
    // so these functions are gasless
    // we only pay gas ila kena anbdlo state of blockchain

    /*function retrieve() public view returns (uint256) {
       return randomNumber;
    } */
}