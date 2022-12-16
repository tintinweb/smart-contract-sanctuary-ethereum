// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7; // We must declare the version of solidty that we are using before we can start writing

// code in the IDE. The ^ sign shows that all versions of solidity from 0.8.8 and above can use this code.

contract simpleStorage {
    // There are five major units in solidity. They are
    // bool: True and False.
    // Uint: Unsigned integers.  Integers without positive or negative.
    // int: signed integer
    // address: The address from your ethereum wallet on meta mask or any other wallet.
    // bytes: This can be any convertible data type, like strings or even numbers

    // The uint variable gets initialized to zero if you don't place a value
    uint public favouriteNumber;

    // The 'public' makes the information in the contract visible to everyone and anyone.
    // It ceates a 'getter' functionn for the variable favouriteNumber
    // If you don't specify the visibility function of the function, it automatically gets deployed as internal.
    // The more stuff you do inside of a contract, the more expensive that contract will be to deploy
    // That basically means it will cost more gas.
    function store(uint256 _favouriteNumber) public virtual {
        favouriteNumber = _favouriteNumber;
    }

    // View and pure functions cannot allow modification of states so they are only used to view already stated variables. They do not cost any gas to run.
    // But calling view functions inside of a non-view function will cost gas.
    function retrieve() public view returns (uint256) {
        return favouriteNumber;
    }

    // You can use the 'struct' call syntax below to create a new function.
    struct People {
        uint256 favouriteNumber;
        string name;
    }
    // The mapping variable allows you to link one variable to another one.
    mapping(string => uint256) public nameToFavouriteNumber;

    // The [] tag allows you to name the following variable as an array.
    People[] public person;

    // calldata: Temporary variables that can't be modified.
    // Memory: Temporary variables that can be modified.
    // Storage: Permanent variables that can be modified. This is basically every global scope variable.
    // Data location can only be signified for array, struct or mapping types
    function addPerson(string memory _name, uint _favouriteNumber) public {
        People memory newPerson = People({
            favouriteNumber: _favouriteNumber,
            name: _name
        });
        person.push(newPerson);
        nameToFavouriteNumber[_name] = _favouriteNumber;
    }
}