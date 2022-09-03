//SPDX-License-Identifier: MIT

pragma solidity 0.8.8; // 0.8.12 is recent on tutorial!

// statement "^0.8.8" meants that version or above
// another example: "pragma solidity >=0.8.7 <0.9.0"

contract SimpleStorage {
    // Data types: boolean, uuint(unregistered number or positive whole number)
    //                            , int ,string, address(or bytes)
    // bool box1 = false ;// or true
    // uint box2 = 123;
    // uint256 box3 = 1234; //storing 256 bits or uint8 is storin 8 bits!
    // int256 box4 = -12;
    // string box5 = "Hiiiiii!" ;
    // address myad = 0x38afCBB64fe3c2D18aCF3047122DFA12286F5939 ;
    // bytes32 boxby = "cat" ; // real bytes actually are : 0x34terge544h4rt...

    uint public boxu; // default is Zero!
    //people public person= people({rnumber:252342, name:"jack" }) ;

    mapping(string => uint256) public name2number;

    struct people {
        uint256 rnumber;
        string name;
    }

    // list declaration
    // uint256[] public boxulist ;
    people[] public people1;

    //people[3] public people1; : a list with people in it!

    function store(uint box100) public virtual {
        boxu = box100;
    }

    // "view" & "pure" doesnt spend gast to get numbers!
    function retrieve() public view returns (uint256) {
        return boxu;
    }

    //EVM can access and store informations in six places: (3 important are below)
    //calldata : is like "memory" but input data cant be modified!
    //memory : is temperary for when the function execures
    //storage : exist even outside the funtion that have been executed!
    //_storage: permenant variable that can be modified!

    function addperson(string memory _name, uint256 _number) public {
        //people1.push(people(_number, _name)); or we can code like this:
        people memory newperson = people({rnumber: _number, name: _name});
        // people memory newperson= people( _number ,  _name); we can also code like this instead of that line.
        people1.push(newperson);
        name2number[_name] = _number;
    }
}
//0xd9145CCE52D386f254917e481eB44e9943F39138
//0xf8e81D47203A594245E36C48e151709F0C19fBe8