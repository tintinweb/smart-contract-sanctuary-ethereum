// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Efficient library for creating string representations of integers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/LibString.sol)
/// @author Modified from Solady (https://github.com/Vectorized/solady/blob/main/src/utils/LibString.sol)
library LibString {
    function toString(uint256 value) internal pure returns (string memory str) {
        /// @solidity memory-safe-assembly
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but we allocate 160 bytes
            // to keep the free memory pointer word aligned. We'll need 1 word for the length, 1 word for the
            // trailing zeros padding, and 3 other words for a max of 78 digits. In total: 5 * 32 = 160 bytes.
            let newFreeMemoryPointer := add(mload(0x40), 160)

            // Update the free memory pointer to avoid overriding our string.
            mstore(0x40, newFreeMemoryPointer)

            // Assign str to the end of the zone of newly allocated memory.
            str := sub(newFreeMemoryPointer, 32)

            // Clean the last word of memory it may not be overwritten.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                // Move the pointer 1 byte to the left.
                str := sub(str, 1)

                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))

                // Keep dividing temp until zero.
                temp := div(temp, 10)

                 // prettier-ignore
                if iszero(temp) { break }
            }

            // Compute and cache the final total length of the string.
            let length := sub(end, str)

            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 32)

            // Store the string's length at the start of memory allocated for our string.
            mstore(str, length)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "solmate/utils/LibString.sol";
import {StringPad} from "./StringPad.sol";

interface BokkyPooBahsDateTimeContract {
    function getYear(uint256 timestamp) external pure returns (uint256 year);
    function getMonth(uint256 timestamp) external pure returns (uint256 month);
    function getDay(uint256 timestamp) external pure returns (uint256 day);
}

library DateUtils {
    using LibString for uint256;
    using StringPad for string;

    function formatDate(address bpbDateTimeAddress, uint256 timestamp)
        public
        view
        returns (string memory formattedDate)
    {
        if (bpbDateTimeAddress.code.length == 0) {
            return "";
        }

        BokkyPooBahsDateTimeContract bpbDateTime = BokkyPooBahsDateTimeContract(bpbDateTimeAddress);

        try bpbDateTime.getYear(timestamp) returns (uint256 year) {
            formattedDate = year.toString();
        } catch {
            return "";
        }

        try bpbDateTime.getMonth(timestamp) returns (uint256 month) {
            formattedDate = string.concat(formattedDate, ".", month.toString().padStart(2, "0"));
        } catch {
            return "";
        }

        try bpbDateTime.getDay(timestamp) returns (uint256 day) {
            return string.concat(formattedDate, ".", day.toString().padStart(2, "0"));
        } catch {
            return "";
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library StringPad {
    function padStart(string memory value, uint256 targetLength, string memory padString)
        internal
        pure
        returns (string memory paddedValue)
    {
        uint256 diff = targetLength - bytes(value).length;
        if (diff < 1) {
            return value;
        }

        paddedValue = value;
        for (; diff > 0; diff--) {
            paddedValue = string.concat(padString, paddedValue);
        }
        return paddedValue;
    }
}