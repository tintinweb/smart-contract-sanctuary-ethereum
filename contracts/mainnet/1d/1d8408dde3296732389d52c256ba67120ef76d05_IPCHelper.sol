/**
 *Submitted for verification at Etherscan.io on 2022-07-10
*/

pragma solidity ^0.8.0;

// ----------------------------------------------------------------------------
// IPCHelpver 0.9.0-alpha
//
// https://github.com/bokkypoobah/TokenToolz
//
// Deployed to Mainnet 0x1d8408DdE3296732389d52C256bA67120ef76d05
//
// SPDX-License-Identifier: MIT
//
// Enjoy.
//
// (c) BokkyPooBah / Bok Consulting Pty Ltd 2022. The MIT Licence.
// ----------------------------------------------------------------------------

interface IPC {
    function getIpc(uint256 _ipcId) external view returns (string memory name, bytes32 attributeSeed, bytes32 dna, uint128 experience, uint128 timeOfBirth);
}

contract IPCHelper {

    address public constant IPCADDRESS = 0x011C77fa577c500dEeDaD364b8af9e8540b808C0;

    function getBulkIpc(uint from, uint to) external view returns(string[] memory names, bytes32[] memory attributeSeeds, bytes32[] memory dnas, uint128[] memory experiences, uint128[] memory timeOfBirths) {
        require(from < to);
        names = new string[](to - from);
        attributeSeeds = new bytes32[](to - from);
        dnas = new bytes32[](to - from);
        experiences = new uint128[](to - from);
        timeOfBirths = new uint128[](to - from);
        uint i = 0;
        for (uint index = from; index < to; index++) {
            try IPC(IPCADDRESS).getIpc(index) returns (string memory name, bytes32 attributeSeed, bytes32 dna, uint128 experience, uint128 timeOfBirth) {
                names[i] = name;
                attributeSeeds[i] = attributeSeed;
                dnas[i] = dna;
                experiences[i] = experience;
                timeOfBirths[i] = timeOfBirth;
            } catch {
            }
            i++;
        }
    }

}