// SPDX-License-Identifier: MIT
//licensing and sharing code easier
pragma solidity 0.8.8; //0.8.12 is the most current version in the video ^= more new version can work as well
// >= 8.9.7 <= 0.9.0 gets a range
// Remix vm (JavaScript Vm) is a fake local blockchain to run trnsactions quickly
// acount section show a bunch of fake accounts with 100 ETH
//Smart Contracts have addresses just like wallets
// section of code is going to define a contract similar to class
contract SimpleStorage {
    //data types to define variables which stores differant types of data
    //boolean, unint, int, address, bytes
    // boolean= true or false, unint= unsigned integer ehich is a whole positive number, 
    //int can be positive or negative, address, wallet address, byte= small number
    //bool hasFavoriteNumber = true;
    //uint is special because you can allicate how many bits you want specifified to number, how  much memory or storage you want to number
    //example of unit bits: uint8 bits or uint 256 dont specofcy uint= default uint256
    //int favoritenumber = 123, int256= 123,
    //uint8 is the lowest you can go because 8 bits - 1 byte
    // uint favoriteNumber =123;
    //  string favoritenumberinText = "123";
    //  int favoriteInt= -5;
    //  address myAddress= 0xb2eE09E32B7b835C3F9FC67e56D2c7cF46F8a799;
    //  //strings are secretly bytes objects but only for text cats gets converted to bytes
    //  bytes32 favoriteBytes= "cat"; //ox132322ddfdfdf random letters and numbers that represent bytes object

// intialized to 0
// set visability to public so you can see transactions

// favoirte number is a global variable because it is within the main contract class curley brackets any function in the contract can access this variable
// this is automatically tasked to be stored as a storgae variable
    uint  favoriteNumber;
// type dictionaery where everysingle name is going to map to a specoicic number
// when a mapping is created, all the values are intialized to null
//string name is being mapped to unit256 favoritenumber
    mapping(string => uint256) public nameToFavoriteNumber;

    // create a new people and assign it to variable person
    //public a getter function
    // parenthesis sigify we are creating a new  person and curly braksets to let solidy know we will be grabbing struc variables
    // People public person=  People({favoriteNumber: 2,  name: "Brian"});
// creste asn object wehich will store variables
// an array is a data structure that holds a list of other types

// People array visability public, call it people
// uint256[] public favoriteNumbersList;
// dynamic array because the size isnt given
People[] public people;


    struct People {
        uint256 favoriteNumber;
        string  name;
    }
// Memorykeyword a tempory place to store data
//call data, memory storage
//call data, memory variable is only going to exist temporyaryily
// stroage exists exist outside just the function executing
// can use call data if you dont end up modfying the name.

// solify knows uint 256 willlive just in meomory here but not sure what a string is going to be
// since strings are array of bites, you need to add memory so solidy knows what to do
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        // people.push will add a new people and grabs favorite number and name
        // People memory newPerson= People({favoriteNumber: _favoriteNumber, name: _name});
        // This way to write isn't as explitcit as the above way
        // People memory newPerson = People(_favoriteNumber, _name);
        // cant reassign name with call data, but you can with memory call data= temp variables that cant be modieid, memory temp variables that can be modified
        // storage permaniant variables that can be modified
// _name= "cat":
        //push newpperson into people array
        // Another way to write it
        people.push(People(_favoriteNumber, _name));

        // at keyname= to favorite number
        nameToFavoriteNumber[_name] = _favoriteNumber;
// people.push(People(_favoriteNumber, _name));
    }
    // functions run a block of code
// change the value of favorote number to new value
                    // number changed to will be passed in store function in parenthesis
                    //function store is going to taske some parametor thast we are goiong to give it and sets favorite number = to new parametor
    function store(uint256 _favoriteNumber) public{
        // what ever variable we passed will be set to new favoritenumber
        favoriteNumber = _favoriteNumber;
        favoriteNumber = favoriteNumber;
        //this will cost gas
        // retrieve();
    }
 // view and pure keywords mean they do not have to spend gas to run they will just read the state cant update the contract with a view function
 //pure functions disallow reading from the blockchain
    function retrieve() public view returns(uint256) {
        return favoriteNumber;
    }

// maybe use math over and over again ,or specific algorythm that doesnt need to read any storage
    // function add() public pure returns(uint256){
    //     return(1+1);
    // }
}
// everytiome you chnage the state of the blockchain, you do it in a transaction
//gas cost will be more then 21,000 eth cost because it is more computationally expensive in a smart contract
// the more code, the more gas it will cost
// smart contract address
//0xd9145CCE52D386f254917e481eB44e9943F39138
// anytime you do somthing on change such as make a new contract, a transaction is created
//if you had numbers to store button you call store function  and execute transaction on fake javascript blockchain to store _favorite number into favorite niumber variable
//  a little gas is spent to call contract
// functions and variables can 1-4 visability specifcifers: public, private,  external and internal
// public is visable externally and internally public keyword creates a getter function that returns the value of the varable
// prvaite means only specific  contract can call specific function
//external means only people outside the contract can call function
// internal only the contract and children contracts can reach the function
// the default visability is internal
// when you create variables, they can only be viewed in the scope where they are
// returns keyword means what this is going to give us after we call it

// mapping is a data structure where a key is "mapped" to a single value