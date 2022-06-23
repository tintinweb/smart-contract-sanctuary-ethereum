// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract VerifySignature {
    function getMessageHash(
        string memory _objectId,
        address _seller,
        uint256 _askingPrice,
        address _contractAddress,
        uint256 _tokenId,
        uint256 _amount,
        address _saleToken,
        string memory _ercType,
        uint256 _nonce
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _objectId,
                    _seller,
                    _askingPrice,
                    _contractAddress,
                    _tokenId,
                    _amount,
                    _saleToken,
                    _ercType,
                    _nonce
                )
            );
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function verify(
        address _signer,
        string memory _objectId,
        address _seller,
        uint256 _askingPrice,
        address _contractAddress,
        uint256 _tokenId,
        uint256 _amount,
        address _saleToken,
        string memory _ercType,
        uint256 _nonce,
        bytes memory signature
    ) public pure returns (bool) {
        bytes32 messageHash = getMessageHash(
            _objectId,
            _seller,
            _askingPrice,
            _contractAddress,
            _tokenId,
            _amount,
            _saleToken,
            _ercType,
            _nonce
        );
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            r := mload(add(sig, 32))

            s := mload(add(sig, 64))

            v := byte(0, mload(add(sig, 96)))
        }
    }
}