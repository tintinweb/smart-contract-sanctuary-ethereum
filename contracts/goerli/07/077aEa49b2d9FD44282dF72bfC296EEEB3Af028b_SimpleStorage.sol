//SPDX-License-Identifier: MIT
// In starting of the code a comment with mentioning license is must, no other comment to be added after mentioning license
pragma solidity ^0.8.7; // ^0.8.17 means any version from 0.8.17 and above

// we can write like this >=0.8.17 <0.9.0, means any version greater than or equal to 0.8.17 and less than 0.9.0 will work.
// with ; we tell it is end of the line

// Next thing we are gonna do define our contract, this 'contract' keyword tells the code that next thing in code will be a contract, contract is similar to a class
contract SimpleStorage {
    // every thing between this curly braces is 'content of the contract'.

    //bool hasFavouriteNumber = true;
    //int256 firstFavouriteNumber = -123;         // could be positive/negetive
    //uint256 secondFavouriteNumber = 456;        // unsigned, only positive
    //string myName = "Abinash";
    //address myAddress = 0xC81d6a1c5e539313927e1E0d3e1177379CeE8DE9;
    //bytes32 myNameInByte = "Abinash";                                   // https://blog.logrocket.com/ultimate-guide-data-types-solidity/#bytes

    //uint256 favouriteNumber = 100;

    // 1. VARIABLE
    uint256 public favouriteNumber; // here type is uint256 and variable name is favouriteNumber, if we dont hold any value in variable it holds some default value, here by dafault is 0.
    // when we add this public variable to this favourite number, we secretly adding a function that just returns the favourite number, in other word this function is created in backend.

    // MAPPING
    mapping(string => uint256) public nameToFavouriteNumber; // string == key, uint256 == value

    // 2. STRUCT

    struct People {
        uint256 favouriteNumber;
        string name;
    }

    //People public person = People({favouriteNumber:10, name:"Abinash"});      // person == function, People == structure

    // 3. Array
    People[] public people;

    function addPeople(string memory _name, uint256 _favouriteNumber) public {
        people.push(People(_favouriteNumber, _name)); // people == array name, People == struct name
        nameToFavouriteNumber[_name] = _favouriteNumber;
    }

    // 3. Let's create function, keyword is function

    function store(uint256 _favouriteNumber) public virtual {
        // we are passing a variable as parameter in function
        // we used virtual keyword to make this function overrideable so that we can use this function in any other file in same directory
        favouriteNumber = _favouriteNumber;
        //retrieve();
        // favouriteNumber = favouriteNumber + 1;        // more stuff we are gonna do more expensive it will be
    }

    // COMPILE --> DEPLOY

    //0xd9145CCE52D386f254917e481eB44e9943F39138      THE CONTRACT WE JUST DEPLOYED IS LOCATED IN THIS ADDRESS

    // When we deploy a contract is actually same sending a transaction, anytime we do anything on the bloclchain, we modify any value, WE ARE SENDING A
    // TRANSACTION. So deploying a contract is MODIFYING THE BLOCKCHAIN TO HAVE THIS CONTRACT, it is modifying state of blockchain.
    // We only spend GAS, we only make transaction when we modify the blockchain state.

    // view/pure
    function retrieve() public view returns (uint256) {
        // view function means we are going to read state from this contract,
        return favouriteNumber;
        //test();                      // view function disallows modification
    } // we cant update blockchain with view function

    // function test() public pure returns(uint256){
    //     return 1000000;
    // }
} // pure function also disallow any modification of state, disallow reading from blockchain

// There are actually two keyword in solidity that notate a function that doesn't actually have to spend GAS to run, those keywords are view and
// pure, for VIEW we can read state, see upward for PURE, we use pure when we want to use any specific algorithm which does not need to read any
// storage, now important thing is when we call view or pure function we dont spend any GAS. Clicking the blue button does not make any transaction.
// Calling a view/pure function doesn't cost GAS, but if we call any function that holds view/pure function from such function which costs GAS then
// it will cost GAS.

// MEMORY/CALLDATA/STORAGE

// EVM can access and store information in six place,
// 1. Stack
// 2. memeory
// 3. storage
// 4. calldata
// 5. code
// 6. logs

// if 'memory' is mentioned then the variable is going to exist temporarily during the transaction, so in this case
// People[] public people;
//     function addPeople(string memory _name, uint256 _favouriteNumber) public {
//         people.push(People(_favouriteNumber, _name));                            // people == array name, People == struct name
//     }

// _name variable will exist temporarily during the transaction means when addPeople is called.

// calldata is temporary variable that cant be modified.
// memory is temporary variable that can be modified.
// storage is permanent variable that can be modified.
// Data location can only be specified for array, struct or mapping types. Otherwise it will give error. we can not use memory location with
// for example uint256.
// Summury of all this is struct, array and mapping should be given this memory/calldata/storage keyword when passing as an parameter.

// view / pure function doesn't modify the state of blockchain.

// smart contracts are COMPOSABLE because they can interact with each other.