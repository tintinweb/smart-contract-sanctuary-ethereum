//SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import { IKeyValuePairs } from "./interfaces/IKeyValuePairs.sol";

/**
 * Implementation of [IKeyValuePairs](./interfaces/IKeyValuePairs.md), a utility 
 * contract to log key / value pair events for the calling address.
 */
contract KeyValuePairs is IKeyValuePairs {

    event ValueUpdated(address indexed theAddress, string key, string value);

    error IncorrectValueCount();

    /** @inheritdoc IKeyValuePairs*/
    function updateValues(string[] memory _keys, string[] memory _values) external {

        uint256 keyCount = _keys.length;

        if (keyCount != _values.length)
            revert IncorrectValueCount();

        for (uint256 i; i < keyCount; ) {
            emit ValueUpdated(msg.sender, _keys[i], _values[i]);
            unchecked {
                ++i;
            }
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

/**
 * A utility contract to log key / value pair events for the calling address.
 */
interface IKeyValuePairs {

    /**
     * Logs the given key / value pairs, along with the caller's address.
     *
     * @param _keys the keys
     * @param _values the values
     */
    function updateValues(string[] memory _keys, string[] memory _values) external;
}