//SPDX-License-Identifier:MIT
pragma solidity 0.8.8;

//     int16 num=100;
//     uint64 num1=2882828;
//     string name="faisal";
//     address bamel=0xbD553017559871718A0252bc98119EDC4C3B32E0;
//     bool istrue=true;
//     bytes32 name1="faisal";
//     bytes15 num2="33";       //only stores string.
//     bytes name3="faslal";  // bytes means any size;
//uint num;  // this is same as     uint num=0;

contract simpleStorage {
    //4 types of visibilities    public, private only visible to specific contract, internal visible internally, external,

    uint256 favnum = 0;

    // default visibility is internal
    function store(uint256 fav) public virtual {
        // scope of variabes lies in the carly brackets.
        favnum = fav; //more the stuff in it more gas fee is.
    }

    function retrieve() public view returns (uint256) {
        // view, pure don't cost gass fees.  // view is used to read something out
        return favnum; // if we call our view function inside an other function it cost gass fees.
    }

    // public variables are like view functions

    //car public farari=car({model: "2022 electrical vehcal",cn: 2033});
    //car public mehran=car({model:"fresh attock",cn:20382});

    //structure in solidity
    struct car {
        uint256 cn;
        string model;
    }

    car[] public numbers;

    // Arrays in solidity
    //uint32[] public numbers;
    car[] public pakcars; //dynamical arry its size is not fixed.

    //mapping name to number
    mapping(string => uint256) public nametonumber;

    function add_data(string memory name, uint256 n) public {
        pakcars.push(car(n, name)); //    two ways
        nametonumber[name] = n;

        // car memory Car=car({cn:n,model: name});   same things.
        //car memory Car=car(n,name);

        // pakcars.push(Car);
    }

    // there are 6 ways to save data in the program.
    // 1.calldata,memory,storage
    //memory --> temporary can be modified
    // storage --> permanent can be modified
    // caldata --> temporary can't be modified
    // struct, array, maping need to be given this memory,caldata here  as in the case to string we need it .

    //EVM  etherium virtual machine
    // Avalanche,Fantom,polygon
}