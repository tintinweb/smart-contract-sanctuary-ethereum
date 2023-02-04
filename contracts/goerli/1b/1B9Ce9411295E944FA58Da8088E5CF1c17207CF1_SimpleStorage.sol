/**
 *Submitted for verification at Etherscan.io on 2023-02-04
*/

// SPDX-License-Identifier:MIT
pragma solidity ^0.8.6;    // ^  ---> this specifies greater than or equal to this version   <= --->Less than

// specify the version at top of your code.

// contract <contractName> {} creates a contract


contract SimpleStorage {
    // boolean uint int address bytes string
    // unit<Size> size = {8,16,32,64,128,256} unit stores only positive integers
    // address stores the address of your account {public key}
    // bytes<Size> Size = {,32,}
    // string ---> a type of bytes that stores only texts
    // type(X).min and type(X).max to access the maximum as well as the minimum value of a type
    // ~int256(0) == int256(-1)
    // default value of int and uint is 0
    // -x  <==>  (T(0) - x) where T is a variable of x type
    // address: Holds a 20 byte value (size of an Ethereum address).

    // address payable: Same as address, but with the additional members transfer and send.

    // The idea behind this distinction is that address payable is an address you can send Ether to, while you are not supposed to send Ether to a plain address, for example because it might be a smart contract that was not built to accept Ether.

    // function <functionName> (<parameters>) public { code }  <--- use this to create a function in solidity similar like javascript maybe java

    // don't forget the public keyword

    // anything you need or want to change your contract , it can be only implemented using transcation in blockchain or decentralized world
      
    // store section in the deploy section is for the uncalled function parameters value

    // use public keyword to chow your functions or variables value to public 
    // It's like make the visibility of your certain parts of your contract to the public. 

    // 
    /* Visibility Specifiers :
            public : make the part visible or mutable internal contrats as well as public contracts;
            private : makes the part only acessceble internally ie not visible in derived contracts;
            internal : can be accessed only within the current contract or deeriving contracts;
            external : can be called by other contracts by message key or via transcation;
            Making something private or internal only prevents other contracts from reading or modifying the information, but it will still be visible to the whole world outside of the blockchain.

            default is internal
     */

    // more code to compile in your contract more heavy is the transcation(more gas)


    uint256 public number;
    bool ch = false;
    
    // virtual tells that this is modifyable by the inherited child contract
    function store(uint256 _transactionNumber_ ) public virtual {
        number = _transactionNumber_;
              
    }

    // view --> makes the function read only and pure --> restricts read as well write from chain 
    // view and pure disallows modifications of state and these don't costs gas
    // if a gas calling function calls the view or pure function then only its costs the gas

    function retrive() public view returns(uint256) {
        return(number);
    }


    // To store multiple data as a list we use the struct
    // like a constructer

    struct Person {
        uint256 personNumber ;
        string name; 
    }

    // like a object calling

    // Person public p = Person({
    //     personNumber: 2,
    //     name: "Akash"
    // });

    // in a specific function or a specific contract local variables are stored as in the form of list only;
    // like above at line 49 and 50 we have a list that stores the first variable 'number' which is stored at 0th index with default value 0;
    // and changed at 1st index with the value specified

    // To create an array in solidity it is different from other languages
    // Here the [] is put with the data types like
    // <type>[] <visibility> <arrayName>;   --------> the type in here can be a list also

    Person[] public persons;   // EMPTY ARRAY DYNAMIC ARRAY
    string[] public names;     // EMPTY ARRAY DYNAMIC ARRAY
    string[3] memes;   // Not a dynamic array      

    // The below code appends the data into the persons array as well as the names array

    //EVM can store into 6 different types 
    //calldata, stack, memory, logs, storage, code
    /*
        memory(temproray variables) stores that value only inside that function or local space.The value can be altered inside. It can't be accessed outside the function;
        calldata(temproray variables) does the same as memory and instead it restricts the value of that parameter/variable to change;
        storage stores the data globally. Gobal variables uses this concept. It is permanent and can be modified;
    */
    
    // Solidity provides a mapping data type
    //      mapping(<keyDataType> => <valueDataType>) <visibility> <mappingName>;
    // we can now access a value using its key like :
    //      <mapName>[<key>] = <value>;
    // by default the value of the <valueDataType> is default value of the respetive Data type;


    mapping(string => uint256) public person;

    function addPerson(string memory _name, uint256 _personNumer) public {
        Person memory newPerson = Person({personNumber: _personNumer, name:_name});
        persons.push(newPerson);
        names.push(_name);
        person[_name] = _personNumer;

        // Notice that memory is used only once and only with string.
        //all this storage types are applicable only for struct, maps and arrays;
        // And string is an array of characters;

        /*
               Person memory newPerson = Person({personNumber: _personNumer, name:_name});
               persons.push(newPerson);
        
        the above can be replaced with 
        
               persons.push(Person(_personNumer, _name));   ------> Order of the parameter has to be maintained
        
        */
    }

}

// 0xd9145CCE52D386f254917e481eB44e9943F39138