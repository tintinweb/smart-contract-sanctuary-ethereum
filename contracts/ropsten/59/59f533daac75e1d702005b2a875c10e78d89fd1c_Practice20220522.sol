/**
 *Submitted for verification at Etherscan.io on 2022-05-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Practice20220522
{
    // #1 - Type conversion
    function TypeConversionDemo() external pure
    {
        // // Implicit
        // uint8 a = 100;
        // uint80 b = a;
        // //uint40 c = b; // Error

        // int8 d = 50;
        // //uint16 e = d; // Error

        // uint8 f = 23;
        // //int16 g = f; // Error

        // // Explicit
        // uint16 h = 256;
        // uint8 i = uint8(h);

        // bytes memory nameBytes = "Blockchain";
        // string memory name = string(nameBytes);
        // // return (nameBytes, name);
    }

    // #2 - Global variables and functions
    function GetBlockHash(uint blockNumber) external view returns (bytes32)
    {
        return blockhash(blockNumber);
    }

    function GetChainId() external view returns (uint)
    {
        return block.chainid;
    }

    function GetBlockNumber() external view returns (uint)
    {
        return block.number;
    }

    function GetMinerAddress() external view returns (address)
    {
        return block.coinbase;
    }

    function GetSenderAddresses() external view returns (address latestCaller, address firstCaller)
    {
        latestCaller = msg.sender;
        firstCaller = tx.origin;
    }

    function GetContractAddress() external view returns (address)
    {
        return address(this);
    }

    address ownerAddress = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    function DestroyContract() external
    {
        selfdestruct(payable(ownerAddress));
    }

    function ReceiveFunds() external payable
    {
    }

    function GetContractBalance() external view returns (uint)
    {
        return address(this).balance;
    }

    // #3 - Cryptographic Hash Functions
    function HashFunctionsDemo(uint num, string memory str) external pure returns (bytes32, bytes32, bytes20)
    {
        bytes32 s = sha256(abi.encode("Ahmed", num, str));
        bytes32 k = keccak256(abi.encode("Ahmed", num, str));
        bytes20 r = ripemd160(abi.encode("Ahmed", num, str));

        return (s, k, r);
    }
}