/**
 *Submitted for verification at Etherscan.io on 2022-05-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Contract26May
{
    address ownerAddress;

    constructor ()
    {
        ownerAddress = msg.sender;
    }

    modifier ownerOnly()
    {
        require (msg.sender == ownerAddress, "Only owner can invoke this method.");
        _;
    }


    // Step 1 - type conversion
    function TypeConversionDemo() external pure
    {
        // //Implicit
        // uint8 a = 10;
        // uint80 b = a;

        // int8 c = 11;
        // uint16 d = c;

        // uint8 e = 22;
        // int256 f = e;

        // //Explicit
        // uint256 first = 257;
        // uint8 second = uint8(first);

        // bytes memory nameBytes = "Blockchain";
        // string memory name = string(nameBytes);
    }

    // Step 2 - Global variables and function
    function GetBlockHash(uint blockNumber) external view returns(bytes32)
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

    function DestroyContract() external ownerOnly()
    {
        selfdestruct(payable(ownerAddress));
    }

    function ReceiveFunds() external payable
    {}

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