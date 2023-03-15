/**
 *Submitted for verification at Etherscan.io on 2023-03-14
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

//EVM ethereum virtual machine
//Avalanche, Fantom, Polygon

contract SimpleStorage {
    // boolean, uint, int, address, bytes

    uint256 favnum; // initialise 0
    mapping(string => uint256) public nametonum;
    struct people {
        uint256 favnum;
        string name;
    }

    //people public person = people({favnum: 2, name: "Diwakar"});
    //eople public person2 = people({favnum: 3, name: "kamal"});
    //or array

    people[] public People; //dynamic array .....people[3]->Fixed Sized Array

    function store(uint256 _favnum) public virtual {
        favnum = _favnum;
        retrieve(); //calling a view function inside gas func cost gas(execution cost goes up)
    }

    // view like pure(doesnt allo reading)

    function retrieve() public view returns (uint256) {
        return favnum;
    }

    // calldata, memory, storage
    //calldata and memory exist inside function and calldata cannot be modified.Storge exist throughout function.

    function addperson(string memory _name, uint256 _favnum) public {
        //people memory newperson = people({favnum: _favnum, name: _name});

        people memory newperson = people(_favnum, _name); //less explicit
        People.push(newperson);
        nametonum[_name] = _favnum;

        //People.push(people(_favnum,_name));
    }
}

//stack memory storage calldata code logs ->store info
//0xd9145CCE52D386f254917e481eB44e9943F39138

//yarn solcjs --bin --abi --include-path node_modules/ --base-path . -o . SimpleStorage.sol