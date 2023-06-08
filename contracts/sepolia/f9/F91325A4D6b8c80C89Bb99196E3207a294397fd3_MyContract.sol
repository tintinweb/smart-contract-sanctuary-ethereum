pragma solidity ^0.8.0;

contract MyContract {
    struct StructData {
        uint256 value;
        address owner;
    }

    StructData[] public structs;

    function setStructArray(StructData[] calldata data) public {
        for (uint i = 0; i < data.length; i++) {
            structs.push(data[i]);
        }
    }
}