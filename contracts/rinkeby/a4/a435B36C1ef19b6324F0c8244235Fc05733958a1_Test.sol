/**
 *Submitted for verification at Etherscan.io on 2022-07-28
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

contract Test{

    event Log(bytes32 val);

    function test(
        uint256 amount,
        uint256 nonce) 
    external{
        // emit Log(v1);
        bytes32 message = prefixed(
            keccak256(abi.encodePacked(msg.sender, amount, nonce, this))
        );
        emit Log(message);
    }

    /// 加入一个前缀，因为在eth_sign签名的时候会加上。
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }
}