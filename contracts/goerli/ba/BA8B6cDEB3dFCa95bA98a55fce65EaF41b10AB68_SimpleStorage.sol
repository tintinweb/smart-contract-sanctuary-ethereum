// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; //^0.8 or e.g. >0.8.7 <0.9.0

//data type: boolean, uint, int, address, bytes
contract SimpleStorage {
    // public, private,
    // extrenal - call by other only
    // internal - (default) current and children object access
    struct People {
        uint256 some_v1;
        string some_v2;
    }

    bool some_var123 = true;
    uint256 public param_1 = 123;
    People public person = People({some_v1: 2, some_v2: "aa"});

    //mapping
    mapping(string => uint256) public nameToNum;
    //array
    People[] public people;

    // uint256 is memory default
    function addPerson(string memory _name, uint256 _num) public {
        /* Notes: 
        Stack - not for code
        Memory - temporary
        Storage - non-temporary
        Calldata - temporary 
        Code - not for code
        Logs - not for code
        */
        //TypeError: Data location must be "storage", "memory" or "calldata" for variable, but none was given.
        //--> contracts/SimpleStorage.sol:16:9:
        People memory new_person = People(_num, _name);
        people.push(new_person);
        nameToNum[_name] = _num;
    }

    function store(uint256 input_param) public virtual {
        param_1 = input_param;
        retrieve(); // this is not free, part of Gas consumption
    }

    //view = read only (no update blockchain)
    function retrieve() public view returns (uint256) {
        return param_1;
    }

    //pure = read only (no update blockchain)
    function add() public pure returns (uint256) {
        return (1 + 1);
    }
}

//Contract address
//0xd9145CCE52D386f254917e481eB44e9943F39138
//0xd8b934580fcE35a11B58C6D73aDeE468a2833fa8
//0xD7ACd2a9FD159E69Bb102A1ca21C9a3e3A5F771B