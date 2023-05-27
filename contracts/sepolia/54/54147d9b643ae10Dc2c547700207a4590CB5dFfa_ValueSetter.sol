// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

abstract contract AuthorizedValue {
    uint256 private value;

    address private messageOwner = 0x5A902DB2775515E98ff5127EFEa53D1CC9EE1912;

    function setValueRaw(
        uint256 value_,
        bytes32 messageHash,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) public {
        address signer = ecrecover(messageHash, v, r, s);

        require(signer == messageOwner, "Invalid signature.");

        value = value_;
    }

    function setValue(uint256 value_, bytes memory signature) external virtual;

    function getValue() external view returns (uint256) {
        return value;
    }

    function getMessageOwner() external view returns (address) {
        return messageOwner;
    }
}

contract ValueSetter is AuthorizedValue {
    function splitSignature(bytes memory _signature) public pure returns(bytes32 r, bytes32 s, uint8 v) {
        require(_signature.length == 65, "Invalid Signature Length!");

        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }
    }

    function setValue(uint256 value_, bytes memory signature) external override {
        // TODO
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);
        bytes32 messageHash = keccak256(abi.encode(value_, block.chainid, "ValueSetter"));
        bytes32 ethSignedMessageHash= keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
        setValueRaw(value_, ethSignedMessageHash, r, s, v);
    }
}