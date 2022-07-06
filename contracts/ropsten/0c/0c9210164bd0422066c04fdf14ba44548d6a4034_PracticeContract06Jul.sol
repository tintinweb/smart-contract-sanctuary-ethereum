/**
 *Submitted for verification at Etherscan.io on 2022-07-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PracticeContract06Jul
{
    // Step 1 - Type conversion 

    //Implicit vs Explicit

    // uint8 a = 100;
    // uint16 b = a;

    // uint16 c = 355;
    // uint8 d = uint8(c);


    // Step 2 - Global variables and functions
    function GetBlockHash(uint blockNumber) external view returns(bytes32)
    {
        return blockhash(blockNumber);
    }

    function GetChainId() external view returns(uint chainId)
    {
        chainId = block.chainid;
    }

    function GetBlockNumber() external view returns(uint)
    {
        return block.number;
    }

    function GetMinerAddress() external view returns(address)
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
    {}

    function GetContractBalance() external view returns (uint)
    {
        return address(this).balance;
    }


    // Step 3 - Cryptographic hash functions
    function HashFunctionsDemo(uint num, string memory str) external pure returns (bytes32, bytes32, bytes20)
    {
        bytes32 s = sha256(abi.encode("Ahmed", num, str));
        bytes32 k = keccak256(abi.encode("Ahmed", num, str));
        bytes20 r = ripemd160(abi.encode("Ahmed", num, str));

        return (s, k, r);
    }
}