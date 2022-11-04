/**
 *Submitted for verification at Etherscan.io on 2022-11-04
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Notarization {


    mapping(bytes32 => bytes32) public notarization;
    bytes32[] public notarizationList;
    bool notarized;

    event LogNewNotarization(address sender, bytes32 hash, bytes32 id);
    event LogConfirmed(bool notarized, bytes32 hash, bytes32 id);
    event LogNotNotarized(bool notarized , string);

    function createNotarization(bytes32 hash, bytes32 id) public {
        notarization[hash] = id;
        notarizationList.push(hash);
        emit LogNewNotarization(msg.sender, hash, id);
    }

    function confirmNotarization(bytes32 hash) public{
        if(notarization[hash] != 0){
            emit LogConfirmed(true, hash, notarization[hash]);
        }
        else{
            emit LogNotNotarized(false, "The hash has not been notarized yet");
        }
    }

    /*function getNotarizationDetails(bytes32 hash)public view returns(bytes32, bytes32) {
        if(notarization[hash] != 0){
            return (hash, notarization[hash]);
        }
    }*/
}