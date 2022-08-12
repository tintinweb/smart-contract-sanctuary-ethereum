//SPDX-License-Identifier: MIT

//must add solidity version
// ad ^ to solidity version to allow any solidity above 0.8.2
// as >= if we want a randge of solidity version
pragma solidity 0.8.9;

//EVM, Ethereum Virtual Machine
// Avalanche, Fantom, Polygon

//define contranct (Similar to a class)
contract SimpleStorage {
    //base solidty types boolean, uint, int, adderss, bytes
    //uint unsigned interger that cant be negative
    // string favoriteNumberInText = "Five";
    // int256 favoriteInt = -5;
    // address myAddress =  0x5908e024c553Eb035d9fe9B12b314e942978b6c3;
    // bytes32 favoriteBytes = "cat";
    // bool hasFavoriteNumber = true;

    //can specifiy amount fo bytes will hold number defaults to 256 bytes
    //by adding public it now how a getter for anyone to read it,
    // defaults to internal which only this contract can interact with
    uint public favoriteNumber; //defaults to 0 if not initialized to zero

    // //add {} let soldity know wer will be grabbing from these struct values
    // People public person = People({favoriteNumber: 2, name: "Spencer"});

    //array
    //dynamic array cz we didnt give it a size
    //to give it a size add a numer withing [3]
    People[] public people;

    //dictionay
    mapping(string => uint256) public nameToFavoriteNumber;

    //when u have a list of variables inside of an object they automatically get indexed
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    //in order for a function to be override we need to add virtual keyword
    // adding more to functon will increase its gas prices
    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
        //if we call retrieve in this function gas price will go up
    }

    //Memory
    //Six Places to store data: Stack ,Code, Logs, Memory, Storage, CallData
    //Memory - variable will only exist temporarily within this function being called and can be modified
    //CallData - variable will only exist temporarily within this function being called and cannot be modified
    //Storage - variables exist outside function example is favorite Number or People above
    //You only have to specify what type of storage variable will be when its a struct, array, or mapping
    //String is secretly an array of charcters
    //adds new person to array
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        //two ways of init
        // People memory newPerson = People({favoriteNumber : _favoriteNumber, name: _name});
        // People memory newPerson = People(_favoriteNumber, _name);
        //dont need memory key word if init inline
        people.push(People(_favoriteNumber, _name));

        //adding to dictionary for easier access to find number
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

    //by adding public to favorite number it basically creates this function
    //By adding View tells contract that we dont need to create a transaction aka spend gas money
    // we are only reading value. Cannnot manipulate value in anyway
    //The two keywords are View and pure (disallow modification of state)
    //the only time it will cost gas is if a function within contract is calling the view function
    // function retreive() public view returns(uint256){
    //     return favoriteNumber;
    // }

    // //pure functions cannot read from blockchain either
    // function add() public pure returns(uint256){
    //     return(1 + 1);
    // }
}
//0xd9145CCE52D386f254917e481eB44e9943F39138 contract address