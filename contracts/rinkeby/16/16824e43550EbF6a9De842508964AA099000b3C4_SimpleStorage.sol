// I'm a comment!
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; //0.8.12; immer schreinb eine Version von Solidity am Anfang des Files

///^ any version 0.8.7(8-...)
////>=0.8.7 < 0.9.0 alles was in der mitte liegt und 0.8.7, 0.9.0 würde nicht funktionieren

contract SimpleStorage {
    ///boolean,uint 8-->256,int,address,bytes -->32
    // bool hasFavoriteNumber = false;
    uint256 public favNumber; //automatically initialized to 0 automatically is internal and visible only for this contract

    // int256 favMumber = -5;
    // string favNumberNAme = "Five";
    // address myAddress = 0x05E527ADd77Ae53d1186dBe2328E9cB321c81Cc2;
    // bytes32 favBytes = "cat";
    //0x123njn13123n2432Dq5261

    function store(uint _favN) public virtual {
        favNumber = _favN;
        // retrieve();
        // favNumber = favNumber + 1;
    }

    /// view, pure doesnt require gas

    //view --> only read not change
    //pure --> no read no change
    function retrieve() public view returns (uint256) {
        return favNumber;
    }

    function matOpp() public pure returns (uint256) {
        return 1 + 1;
    }

    Person public ich = Person({favouriteNum: 100, myName: "Ann"});
    /////////////////////////------------->ARRAYS AND STRUCTS <----------////////////////////////
    struct Person {
        uint256 favouriteNum;
        string myName;
    }
    ////following array. is dinamyc, since we didnt determinate in [] how many elements will be in it
    Person[] public myGroup;

    function addPerson(string memory persName, uint favPersNum) public {
        // Person  memory newPerson = Person({
        //     favouriteNum:favPersNum,
        //     myName:persName
        // });

        Person memory newPerson = Person(favPersNum, persName);
        ////same with what was written before but shorter, the variables
        ////should be put in the reiefolge wie in struct

        myGroup.push(newPerson);
        listDictionary[persName] = favPersNum;
    }

    ///////// --------> CALLDATA, MEMORY, STORAGE<----------////////////////////

    //////storage wariables still are saved after the execution of function
    /////calldata and memory exist only in short period of time when they are needed
    /////calldata can`t be reasigned aber memory can be changed

    ////we need to add such specifications only to arrays structs or string (array)

    //////////////////------------>MAPPING THROUGH ARRAY<-----------/////////

    mapping(string => uint256) public listDictionary;
    ///   listDictionary[persName]=favPersNum;

    //////////////////------------>DEPLOY MY FIRST CONTRACT<-----------/////////
    //////////////////------------>EVM ETHERUM VIRTUAL MACHINE<-----------/////////

    ///AvalancHhe, Polygon, Fantom Blockchains
}

//0xd9145CCE52D386f254917e481eB44e9943F39138

///command p how to quickly get to files
//command a highlight alll text in your file