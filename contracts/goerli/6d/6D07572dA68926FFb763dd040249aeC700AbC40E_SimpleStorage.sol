//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17; // You can use other version See Slides for more info

contract SimpleStorage {
    uint256 favriteNumber1; //uint256 public favriteNumber1;
    //int256 favriteNumber2=5;
    //bool favriteNumber3=true;
    //bytes32 favriteNumberbyte="cat";
    //address Vaddress=0xD87A8CdD92f19437fAd7895529e69d97D97427A7;
    //People public person = People({favriteNumber: 2, name: "patric"});

    mapping(string => uint256) public nameToFavriteNumber;

    struct People {
        uint256 favriteNumber;
        string name;
    }

    // uint256[] public favritelist;
    People[] public people;

    function store(uint256 _favNumber) public virtual {
        favriteNumber1 = _favNumber;
        retrieve();
    }

    function retrieve() public view returns (uint256) {
        return favriteNumber1;
    }

    function add() public pure returns (uint256) {
        return (1 + 1);
    }

    function addPerson(string memory _name, uint256 _favriteNumber) public {
        people.push(People(_favriteNumber, _name));
        nameToFavriteNumber[_name] = _favriteNumber;
        //People memory newperson= People({favriteNumber: _favriteNumber, name:_name});
        //people.push(newperson);
    }
}

//0xd9145CCE52D386f254917e481eB44e9943F39138