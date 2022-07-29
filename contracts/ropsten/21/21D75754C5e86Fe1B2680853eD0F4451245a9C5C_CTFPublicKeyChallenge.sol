/**
 *Submitted for verification at Etherscan.io on 2022-07-29
*/

pragma solidity ^0.4.21;

contract CTFPublicKeyChallenge {
    address public publicAddress;
    bytes32 public sHash;
    bytes32 public sR;
    bytes32 public sS;
    uint8   public sV;

    function doRecover(bytes32 _hash, bytes32 _r, bytes32 _s, uint8 _v) public pure returns(address){
        address calcAddr = ecrecover(_hash, _v, _r, _s);
        return calcAddr;
    }

    function doRecoverByAdd(bytes32 _hash, bytes32 _r, bytes32 _s, byte _v) public pure returns(address){
        uint8 newV = uint8(_v);

        address calcAddr = ecrecover(_hash, newV, _r, _s);
        return calcAddr;
    }

    function doRecoverByString(string _hash, string _r, string _s, byte _v) public returns(address){
        uint8 newV = uint8(_v);
        bytes32 newR = stringToBytes32(_r);
        bytes32 newS = stringToBytes32(_s);
        bytes32 newHash = stringToBytes32(_hash);
        sHash = newHash;
        sR = newR;
        sS = newS;
        sV = newV;
        address calcAddr = ecrecover(newHash, newV, newR, newS);
        return calcAddr;
    }

    function stringToBytes32(string memory source) public pure returns(bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }
}