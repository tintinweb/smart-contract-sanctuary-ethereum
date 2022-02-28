//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract Sign{



    function dataHash(uint256 amount,string memory data1 ) public pure returns(bytes32){
       return( keccak256(abi.encodePacked(amount,data1)));

    }
    function signMessageHash(bytes32 hash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)); //here lenght of meesage is not given but but taken as \n32 because keccak always gives output of 32 bytes
}

    function recoverSigner(bytes32 message, bytes memory sig) public pure returns (address){
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }

 function splitSignature(bytes memory sig)
        public
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {

            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))

        }
             return(v,r, s);
    }

    function verify(
        address _signer,
        uint256 _amount,
        string memory _message,
        bytes memory signature
    ) public pure returns (bool) {
        bytes32 messageHash1 = dataHash(_amount, _message);
        bytes32 ethSignedMessageHash = signMessageHash(messageHash1);

        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

        function signerAdd(
        uint256 _amount,
        string memory _message,
        bytes memory signature
    ) public pure returns (address) {
        bytes32 messageHash1 = dataHash(_amount, _message);
        bytes32 ethSignedMessageHash = signMessageHash(messageHash1);
        return recoverSigner(ethSignedMessageHash, signature);
    }

}