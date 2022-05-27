// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Strings.sol';
import './SharedStructs.sol';

contract AddressToStakedTokenIterableMap {
	struct Entry {
		uint256 index; // index start 1 to keyList.length
		SharedStructs.StakedToken value;
	}
	mapping(address => Entry) internal map;
	address[] internal keyList;

	function add(address _key, SharedStructs.StakedToken memory _value) public {
		Entry storage entry = map[_key];
		entry.value = _value;
		if (entry.index > 0) {
			// entry exists
			// do nothing
			return;
		} else {
			// new entry
			keyList.push(_key);
			uint256 keyListIndex = keyList.length - 1;
			entry.index = keyListIndex + 1;
		}
	}

	function remove(address _key) public {
		Entry storage entry = map[_key];
		require(entry.index != 0); // entry not exist
		require(entry.index <= keyList.length); // invalid index value

		// Move an last element of array into the vacated key slot.
		uint256 keyListIndex = entry.index - 1;
		uint256 keyListLastIndex = keyList.length - 1;
		map[keyList[keyListLastIndex]].index = keyListIndex + 1;
		keyList[keyListIndex] = keyList[keyListLastIndex];
		delete map[_key];
	}

	function size() public view returns (uint256) {
		return uint256(keyList.length);
	}

	function contains(address _key) public view returns (bool) {
		return map[_key].index > 0;
	}

	function getByKey(address _key)
		public
		view
		returns (SharedStructs.StakedToken memory)
	{
		return map[_key].value;
	}

	function getByIndex(uint256 _index)
		public
		view
		returns (SharedStructs.StakedToken memory, address)
	{
		require(
			_index >= 0,
			string(
				abi.encodePacked(
					'index not greater than or equal to 0: ',
					Strings.toString(_index)
				)
			)
		);
		require(
			_index < keyList.length,
			string(
				abi.encodePacked(
					'index: ',
					Strings.toString(_index),
					' greater than or equal to keylist length: ',
					Strings.toString(keyList.length)
				)
			)
		);
		address a = keyList[_index];
		return (map[a].value, a);
	}

	function getKeys() public view returns (address[] memory) {
		return keyList;
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library SharedStructs {
	struct StakedToken {
		uint256 amount;
		uint256 month;
		uint256 year;
	}
}