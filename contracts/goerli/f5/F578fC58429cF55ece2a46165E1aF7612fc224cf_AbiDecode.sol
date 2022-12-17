// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract AbiDecode {
    struct dataStruct {
        bytes32 gameId;
        uint256 startTime;
        string homeTeam;
        string awayTeam;
    }

    function encode(
        dataStruct calldata myStruct
    ) external pure returns (bytes memory) {
        return abi.encode(myStruct);
    }

    function decode(bytes calldata data)
        external
        pure
        returns (
            dataStruct memory myStruct
        )
    {
        (myStruct) = abi.decode(data, (dataStruct));
    }
}