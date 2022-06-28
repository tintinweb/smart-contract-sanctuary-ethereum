//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; //0.8.12 most current langauge

//^ tells the compiler that anything above the speicifed version would work
//could also use >= to specify lower bound or < to specify upper bound
//first thing you need is the version of solidity you need to use

//this defines a contract, think of it as a class
contract SimpleStorage {
    //solidity has types , boolean, uint, int, address, bytes , string
    //unit256 where 256 means the number of bits
    //address can be the meta mask address we have

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    //an array of ppl
    People[] public people; //we did not give the size of array --> dynamic sized array

    uint256 favoriteNumber; //defaults to zero
    //if we do not give a visiblity , it is automatic internal

    mapping(string => uint256) public nameToFavNumber;

    //where string is the key, unit246 is the value
    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    //0xd9145CCE52D386f254917e481eB44e9943F39138
    //notice that function tagged as view or pure spend no gas --> that is why

    /* 
        function retrieve() public view returns(unit256) {
                return favoriteNumber;
                //notice that varibales are just functions 
                //view function disallow modifications 
                 but calling view and pure functions inside a 
                function that modifies blockchain has gas 
        }


*/

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        /* three big storage space are calldata, memory, and storage
            calldata and memory means that it only exists temp, memeory is temp var that can be modified, but calldata can not be modified
            storage exists even outside of function

            we dont need memory tag for number because solidity knows where it is, but strings are complicated 
            string is bascially an array(we need tags for array struct and mappings)





        */
        //we can also add it to the mapping
        nameToFavNumber[_name] = _favoriteNumber;
    }
}