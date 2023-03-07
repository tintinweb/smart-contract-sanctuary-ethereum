// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

contract Multisend {
    function multisend(address[] calldata tos, bytes[] calldata datas)
        external
        returns (bytes[] memory results)
    {
        results = new bytes[](datas.length);
        for (uint256 i = 0; i < datas.length; i++) {
            (bool success, bytes memory returndata) = tos[i].call(datas[i]);

            if (!success) {
                // Look for revert reason and bubble it up if present
                if (returndata.length > 0) {
                    // The easiest way to bubble the revert reason is using memory via assembly
                    /// @solidity memory-safe-assembly
                    assembly {
                        let returndata_size := mload(returndata)
                        revert(add(32, returndata), returndata_size)
                    }
                } else {
                    revert();
                }
            }

            results[i] = returndata;
        }
    }
}