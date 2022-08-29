// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract TypeEmitter {

    uint256[] public uints = [1, 2, 3, 4];

    address[] public addresses = [
            0x3E22bb8B2f6e60e6fC432000B6187af34bDD4800, 
            0x5c68c7651A84719dA49a8Ab75d9f3fbe70f88c1f,
            0x9C945bCB80a7FAE9493abb98ec3e5f093144B449,
            0xb32c48A486C2300bE7a4Ca2E710d11087D7Fa17f,
            0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45,
            0xE44cff9843da14F400425d4689527980c7075089
        ];
    
    string[] public strings = [
        "foo",
        "bar",
        "baz"
    ];

    bool[] public booleans = [true, false, false, true, true];

    struct TheStruct {
        string title;
        string author;
        uint book_id;
        address addr;
        TheStruct2 meta;
    }

    struct TheStruct2 {
        string subtitle;
        uint pages;
    }

    TheStruct public theStruct = TheStruct("The Title", "The Author", 666, 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45, TheStruct2("The Subtitle", 999));

    event UintArrayReturned(uint256[] array);
    event AddressArrayReturned(address[] array);
    event StringArrayReturned(string[] array);
    event BoolArrayReturned(bool[]);
    event StringReturned(string);
    event UintReturned(uint256);
    event StructReturned(TheStruct);
    event BoolReturned(bool);
    event StructArrayReturned(TheStruct[3]);
    event AllReturned(uint256[] myUints, address[] myAddresses, string[] myStrings, string myString, uint256 myUint, bool myBool, TheStruct myStruct, TheStruct[3] myStructs);

    function emitUints() public {
        emit UintArrayReturned(uints);
    }

    function emitAddresses() public {
        emit AddressArrayReturned(addresses);
    }

    function emitStrings() public {
        emit StringArrayReturned(strings);
    }

    function emitBools() public {
        emit BoolArrayReturned(booleans);
    }

    function emitString() public {
        emit StringReturned("foo");
    }

    function emitUint() public {
        emit UintReturned(666);
    }

    function emitStruct() public {
        emit StructReturned(theStruct);
    }

    function emitBool() public {
        emit BoolReturned(true);
    }

    function emitArrayOfStructs() public {
        TheStruct memory theStruct1 = TheStruct("Foo", "Foo2", 1, 0x3E22bb8B2f6e60e6fC432000B6187af34bDD4800, TheStruct2("The Subtitle", 999));
        TheStruct memory theStruct2 = TheStruct("Bar", "Bar2", 2, 0x5c68c7651A84719dA49a8Ab75d9f3fbe70f88c1f, TheStruct2("The Subtitle", 999));
        TheStruct memory theStruct3 = TheStruct("Baz", "Baz2", 2, 0x9C945bCB80a7FAE9493abb98ec3e5f093144B449, TheStruct2("The Subtitle", 999));
        TheStruct[3] memory structs = [theStruct1, theStruct2, theStruct3];
        emit StructArrayReturned(structs);
    }

    function emitAll() public {
        TheStruct memory theStruct1 = TheStruct("Foo", "Foo2", 1, 0x3E22bb8B2f6e60e6fC432000B6187af34bDD4800, TheStruct2("The Subtitle", 999));
        TheStruct memory theStruct2 = TheStruct("Bar", "Bar2", 2, 0x5c68c7651A84719dA49a8Ab75d9f3fbe70f88c1f, TheStruct2("The Subtitle", 999));
        TheStruct memory theStruct3 = TheStruct("Baz", "Baz2", 2, 0x9C945bCB80a7FAE9493abb98ec3e5f093144B449, TheStruct2("The Subtitle", 999));
        TheStruct[3] memory structs = [theStruct1, theStruct2, theStruct3];

        emit AllReturned(uints, addresses, strings, "foo", 666, true, theStruct, structs);
    }
}