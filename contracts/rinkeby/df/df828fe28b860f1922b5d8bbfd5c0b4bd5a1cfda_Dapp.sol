/**
 *Submitted for verification at Etherscan.io on 2022-06-01
*/

/**
 *Submitted for verification at Etherscan.io on 2022-05-23
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Dapp {
    address public owner;

    mapping(string => string) public pictureManage;
    event storeDiploma(string studentId, string url);

    constructor() {
        owner = msg.sender;
    }

    function storePicture(string calldata studentId, string calldata ipfsHash)
        public
    {
        pictureManage[studentId] = string(
            abi.encodePacked("https://ipfs.io/ipfs/", ipfsHash)
        );
        emit storeDiploma(
            studentId,
            string(abi.encodePacked("https://ipfs.io/ipfs/", ipfsHash))
        );
    }
}