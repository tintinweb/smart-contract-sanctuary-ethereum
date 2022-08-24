/**
 *Submitted for verification at Etherscan.io on 2022-08-24
*/

/**
 *Submitted for verification at Etherscan.io on 2022-07-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


contract TestMeta {

    event score(address playerAddress, uint256 score);

    mapping (address => uint256) public replayNonce;

    function scored(bytes memory signature, address scorer, uint256 _score, uint256 nonce) public returns (bool) {
        bytes32 metaHash = metaScoreHash(scorer, _score, nonce);
        address signer = getSigner(metaHash, signature);
        require(signer!=address(0), "Address cannot be 0");
        require(nonce == replayNonce[signer], "replay nonce is not equal to the sent nonce");
        replayNonce[signer]++;
        emit score( scorer, _score);
        return true;
    }

    function metaScoreHash(address scorer, uint256 _score, uint256 nonce) public view returns(bytes32){
        return keccak256(abi.encodePacked(address(this),"scored", scorer, _score, nonce));
    }

    function getSigner(bytes32 _hash, bytes memory _signature) internal pure returns (address){
        bytes32 r;
        bytes32 s;
        uint8 v;
        if (_signature.length != 65) {
            return address(0);
        }
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }
        if (v < 27) {
         v += 27;
        }
        if (v != 27 && v != 28) {
            return address(0);
        } else {
            return ecrecover(keccak256(
             abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)
            ), v, r, s);
        }
    }

}