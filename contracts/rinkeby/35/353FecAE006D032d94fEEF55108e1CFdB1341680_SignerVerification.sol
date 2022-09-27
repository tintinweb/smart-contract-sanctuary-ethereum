//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/Strings.sol';

library SignerVerification {
    function isMessageVerified(
        address signer,
        bytes calldata signature,
        string calldata concatenatedParams
    ) external pure returns (bool) {
        return recoverSigner(getPrefixedHashMessage(concatenatedParams), signature) == signer;
    }

    function getSigner(bytes calldata signature, string calldata concatenatedParams) external pure returns (address) {
        return recoverSigner(getPrefixedHashMessage(concatenatedParams), signature);
    }

    function getPrefixedHashMessage(string calldata concatenatedParams) internal pure returns (bytes32) {
        uint256 messageLength = bytes(concatenatedParams).length;
        bytes memory prefix = abi.encodePacked('\x19Ethereum Signed Message:\n', Strings.toString(messageLength));
        return keccak256(abi.encodePacked(prefix, concatenatedParams));
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) internal pure returns (address) {
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
        require(sig.length == 65, 'invalid signature length');

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function concatParams(
		uint256 _quizId,
		address _userAddress,
		uint256 _quizStatus
	) external returns (string memory) {
		return
			string(
				abi.encodePacked(
					Strings.toString(_quizId),
					_addressToString(_userAddress),
					Strings.toString(_quizStatus)
				)
			);
	}

	function _addressToString(address _addr) public pure returns (string memory) {
		bytes memory addressBytes = abi.encodePacked(_addr);

		bytes memory stringBytes = new bytes(42);

		stringBytes[0] = "0";
		stringBytes[1] = "x";

		for (uint256 i = 0; i < 20; i++) {
			uint8 leftValue = uint8(addressBytes[i]) / 16;
			uint8 rightValue = uint8(addressBytes[i]) - 16 * leftValue;

			bytes1 leftChar = leftValue < 10 ? bytes1(leftValue + 48) : bytes1(leftValue + 87);
			bytes1 rightChar = rightValue < 10 ? bytes1(rightValue + 48) : bytes1(rightValue + 87);

			stringBytes[2 * i + 3] = rightChar;
			stringBytes[2 * i + 2] = leftChar;
		}

		return string(stringBytes);
	}

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}