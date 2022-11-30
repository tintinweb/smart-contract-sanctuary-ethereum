// SPDX-License-Identifier: MIT
//license for identifying smart contract
pragma solidity ^0.8.7; //^ tells compiler to excecute any version of sol above 0.8.7

//Similar to class
contract SimpleStorage {
    //datatypes
    //boolean,uint(unsigned int)-uint265,int(signed)-int256,address(metamask address),bytes-bytes32

    //this get initialized to 0
    uint256 public favno;

    function store(
        uint256 _favoriteNumber // virtual-to be overridable
    ) public virtual {
        favno = _favoriteNumber;
        // favno++;
        retreive(); //view or pure fun demands gas when it is called in a gas demanding function.
    }

    //view,pure - does not need gas
    //gas is reqiured only when we change the state of blockchain
    function retreive()
        public
        view
        returns (
            uint256 //to return some variables
        )
    {
        return favno;
    }

    function add()
        public
        pure
        returns (
            uint256 //to return some computations without invoving variables
        )
    {
        return (1 + 1);
    }

    //struct
    struct People {
        uint256 favno;
        string name;
    }

    People public p1 = People({favno: 12, name: "Ash"});

    //arrays

    //array from structure - user def datatype
    People[] public peoplearr;
    //array from uint -default type
    uint256[] public peoplearr1;

    //[] dynamic array
    //[5] static array

    function addPeople(string memory _name, uint256 _favno) public {
        peoplearr.push(People(_favno, _name));
    }

    //mapping
    mapping(string => uint256) public nameToFavoriteNumber;

    function addPeople1(string memory _name, uint256 _favno) public {
        peoplearr.push(People(_favno, _name));
        nameToFavoriteNumber[_name] = _favno;
        //By default, it maps every string to value 0
    }

    //EVM- Etherium Virtual Machine
    //EVM Compatable Blockchains-Avalanche, Fantom, Polygon
}

//0xd9145CCE52D386f254917e481eB44e9943F39138-ID of contract