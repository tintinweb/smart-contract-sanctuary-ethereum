//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
contract Metropolis
{
    bytes32[][] public Datastore;
    function Write(bytes32[] calldata Data) external { Datastore.push(Data); }
    function Read(uint Index) external view returns (bytes32[] memory) { return Datastore[Index]; }
    function ReadNumberOfSubmissions() external view returns (uint) { return Datastore.length; }
    function ReadAllIndexes() external view returns (uint[] memory) {
        uint[] memory Indexes = new uint[](Datastore.length);
        for (uint i = 0; i < Datastore.length; i++) { Indexes[i] = i; }
        return Indexes;
    }
}