// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library Utils {
    /**
     * @notice Recover signer address from signature.
     */
    function recoverSigner(bytes32 signedHash, bytes memory signature) internal pure returns (address) {
        uint8 v;
        bytes32 r;
        bytes32 s;
        // we jump 32 (0x20) as the first slot of bytes contains the length
        // we jump 65 (0x41) per signature
        // for v we load 32 bytes ending with v (the first 31 come from s) then apply a mask
        assembly {
            r := mload(add(signature, add(0x20, mul(0x41, 0))))
            s := mload(add(signature, add(0x40, mul(0x41, 0))))
            v := and(mload(add(signature, add(0x41, mul(0x41, 0)))), 0xff)
        }
        require(v == 27 || v == 28, "Utils: bad v value in signature");

        address recoveredAddress = ecrecover(signedHash, v, r, s);
        require(recoveredAddress != address(0), "Utils: ecrecover returned 0");
        return recoveredAddress;
    }

    /**
     * @notice Helper method to parse the function selector from data.
     */
    function parseFunctionSelector(bytes memory data) public pure returns (bytes4 result) {
        assembly {
            result := mload(add(data, 0x20))
        }
    }

    /**
     * @notice Parse address from given data.
     * The method returns address at given position
     * @param data Any data to be parsed, mostly calldata of transaction.
     * @param location Position of address.
     */
    function getAddressAt(bytes memory data, uint8 location) public pure returns (address result) {
        assembly {
            result := mload(add(data, location))
        }
    }

    /**
     * @notice Parse uint256 from given data.
     * The method returns uint256 at given position
     * @param data Any data to be parsed, mostly calldata of transaction.
     * @param location Position of uint256.
     */
    function getUint256At(bytes memory data, uint8 location) public pure returns (uint256 result) {
        assembly {
            result := mload(add(data, location))
        }
    }
}