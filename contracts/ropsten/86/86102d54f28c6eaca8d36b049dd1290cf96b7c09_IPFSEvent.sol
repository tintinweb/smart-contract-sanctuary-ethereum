/**
 *Submitted for verification at Etherscan.io on 2022-08-22
*/

pragma solidity ^0.8.0;


contract IPFSEvent {

    event CID(string cid);

    function sendIPFSHash(string memory cid) external {
        emit CID(cid);
    }

}