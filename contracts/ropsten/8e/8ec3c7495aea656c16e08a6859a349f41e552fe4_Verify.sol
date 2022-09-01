/**
 *Submitted for verification at Etherscan.io on 2022-08-31
*/

// SPDX-License-Identifier: MIT
// Tells the Solidity compiler to compile only from v0.8.13 to v0.9.0
pragma solidity ^0.8.13;

contract Verify {

    /**********************   一个结构体的domainSeparator是固定不变的，可以提前在构造函数里面构造好   *****************/ 
    bytes32 DOMAIN_SEPARATOR_PERMIT;

    constructor (uint256 chainId_){
        DOMAIN_SEPARATOR_PERMIT = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes("PERMIT VERIFY")),
            keccak256(bytes("1")),
            chainId_,
            address(this)
        ));
    }

    /**********************   eth_sign   *****************/    
    function ethSignVerify(bytes32  digest, address sourceAddress, bytes memory signMsg) external pure returns (bool) {
        (uint8 v, bytes32 r, bytes32 s) = convertSign(signMsg); 

        require(sourceAddress == ecrecover(digest, v, r, s), "verify failed!");

        return true;
    }


    /**********************   personal_sign   *****************/
    function personalSignVerify(string memory message, address sourceAddress, bytes memory signMsg) external pure returns (bool) {
        string memory prefix = "\x19Ethereum Signed Message:\n";
        uint256 length = bytes(message).length;
        string memory lenStr = toString(length);
        string memory finalPrefix = strConcat(prefix, lenStr);

        bytes32 digest = keccak256(bytes(strConcat(finalPrefix, message)));

        (uint8 v, bytes32 r, bytes32 s) = convertSign(signMsg);
        require(sourceAddress == ecrecover(digest, v, r, s), "verify failed!");

        return true;
    }


     /**********************   eth_signTyedData_V3 DAI Permit 方法签名  *****************/
    // bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address holder,address spender,uint256 nonce,uint256 expiry,bool allowed)"); 
    bytes32 PERMIT_TYPEHASH = 0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb;

    function permitStructVerify(address holder, address spender, uint256 nonce, uint256 expiry, bool allowed, bytes memory signMsg) external view returns (bool) {
        bytes32 digest =
            keccak256(abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR_PERMIT,
                keccak256(abi.encode(PERMIT_TYPEHASH,
                                     holder,
                                     spender,
                                     nonce,
                                     expiry,
                                     allowed))
        ));
        (uint8 v, bytes32 r, bytes32 s) = convertSign(signMsg);
        require(holder == ecrecover(digest, v, r, s), "verify failed!");
        return true;
    }


 /**********************  以下是Util相关方法      *****************/

    /********   将签名后数据转换成r  s  v    ********/
    function convertSign(bytes memory message) internal pure returns (uint8, bytes32, bytes32) {
        bytes memory r = new bytes(32);
        bytes memory s = new bytes(32);
        bytes memory v = new bytes(1);
        for(uint i=0; i<message.length; i++) {
            if(i < 32) {
                r[i] = message[i];
            } else if (i < 64) {
                s[i-32] = message[i]; 
            } else if (i == 64) {
                v[0] = message[i];
            }
        }
        return (uint8(bytes1(v)), bytes32(r), bytes32(s));
    }

    /******  拼接字符串 ********/
    function strConcat(string memory _a, string memory _b) internal pure returns (string memory){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory bret = new bytes(_ba.length + _bb.length);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) {
            bret[k++] = _ba[i];
        }
        for (uint i = 0; i < _bb.length; i++) {
            bret[k++] = _bb[i];
        }
        return string(bret);
   } 

    /******  uint 转换成字符串 ********/
    function toString(uint256 value) internal pure returns (string memory) {

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}