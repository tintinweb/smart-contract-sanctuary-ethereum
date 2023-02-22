/**
 *Submitted for verification at Etherscan.io on 2023-02-22
*/

pragma solidity 0.8.17;

contract SigVerify {
    function getHash(
        address _wallet,
        uint256 _value,
        bytes memory _data,
        uint256 chainid,
        uint256 _nonce
    ) external pure returns(bytes32) {
        return keccak256(abi.encodePacked(
                    bytes1(0x19),
                    bytes1(0),
                    _wallet,
                    _value,
                    _data,
                    chainid,
                    _nonce
                ));
    }

    function getHash2(
        address _from,
        uint256 _value,
        bytes memory _data,
        uint256 chainid,
        uint256 _nonce
    ) external pure returns(bytes32) {
        return keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(
                    bytes1(0x19),
                    bytes1(0),
                    _from,
                    _value,
                    _data,
                    chainid,
                    _nonce
                ))
            )
        );
    }


    function getChainId() external view returns(uint) {
        return block.chainid;
    }



    function recoverSigner(bytes32 _signedHash, bytes memory _signatures, uint _index) external pure returns (address) {
        uint8 v;
        bytes32 r;
        bytes32 s;
        // we jump 32 (0x20) as the first slot of bytes contains the length
        // we jump 65 (0x41) per signature
        // for v we load 32 bytes ending with v (the first 31 come from s) then apply a mask
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(_signatures, add(0x20,mul(0x41,_index))))
            s := mload(add(_signatures, add(0x40,mul(0x41,_index))))
            v := and(mload(add(_signatures, add(0x41,mul(0x41,_index)))), 0xff)
        }
        require(v == 27 || v == 28, "Utils: bad v value in signature");

        address recoveredAddress = ecrecover(_signedHash, v, r, s);
        require(recoveredAddress != address(0), "Utils: ecrecover returned 0");
        return recoveredAddress;
    }

    function uint256ToBytes32(uint256 num) external pure returns(bytes32) {
        return bytes32(num);
    }

    function recoverSigner2(uint8 v, bytes32 r, bytes32 s, bytes32 _signedHash) external pure returns(address) {
        // require(v == 27 || v == 28, "Utils: bad v value in signature");

        address recoveredAddress = ecrecover(_signedHash, v, r, s);
        require(recoveredAddress != address(0), "Utils: ecrecover returned 0");
        return recoveredAddress;
    }
}