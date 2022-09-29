//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8; //selects version of solidity to work with

contract SimpleStorage {
    //boolean-true or false
    //uint-unsigned integer, neither positive or negative
    //int-positive or negative whole number
    //address-used to store addresses
    //bytes
    //bool hasFavouriteNumber = true;
    //uint256 favouriteNumber = 5;
    //string favouriteNumberInText = "Five";
    //int256 favouriteInt = -5;
    //address myAddress = 0x422F699FC043E8d2279b3Cd8847BCcc9B0554F3B;
    //byte32 favouriteBytes = "cats"; //0x123hjsdghjfdslgj gets converted to bytes

    uint256 favouriteNumber; //public means anyone can see what is stored in this variable
    People public person = People({favouriteNumber: 2, name: "Jon"}); //calling of struct from below

    //mappings-a data structure where a key is mapped to a single value
    // e.g. basically a dictionary.
    mapping(string => uint256) public nameToFavouriteNumber;
    //uses person's name to find their favouritenumber
    //uses associated string to find the related uint256 variable

    struct People {
        //Solidity's version of objects
        uint256 favouriteNumber;
        string name;
    }

    People[] public people; //dynamic array

    //private means that something is only visible in the current contract
    function store(uint256 _favouriteNumber) public virtual {
        //to ensure a function can be overridden need to specify 'virtual'
        favouriteNumber = _favouriteNumber; //refer to ExtraStorage.sol to see override in use.
        favouriteNumber = favouriteNumber;
    } //note that the more stuff that is being done within a contract the

    //more gas is used(gas being the currency of work for the network)
    //hence larger contract=more expensive

    function retrieve() public view returns (uint256) {
        //view and pure function disallow modification of state
        return favouriteNumber;
    }

    function add() public pure returns (uint256) {
        return (1 + 1);
    }

    //Note that pure and view do not use gas as they only look at content of blockchain
    //Gas is only used to modify(do work on) the blockchain
    //So if a gas calling function then calls a view or pure function
    //only then will it being using gas

    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        //function gets a person's name and favouritenumber
        People memory newPerson = People({
            favouriteNumber: _favouriteNumber,
            name: _name
        }); //creates the element for the array defined above.
        people.push(newPerson);
        nameToFavouriteNumber[_name] = _favouriteNumber; //pushes the values entered to an element of the array above person.
        //initially all values associated with names in an array are set to zero, but when this function is
        //used, the number attached to that person's name will be linked so we can find the
        //person's favourite number through the nameToFavourite icon on the contract.
    }

    //ethereum virtual machine can store data in 6 places:
    //1) Stack, 2)Memory, 3)Storage, 4)Calldata, 5) Code, 6)Logs
    //callback and memory will only exist whilst the programming is running, temporary in nature
    //storage variables exist outisde the transactions.
    //in the example above, _name is a memory variable as we can throw it away once the function is done
    //on the other hand, uint256 favouriteNumber is a storage variable as we will be needing it for more than one task
}