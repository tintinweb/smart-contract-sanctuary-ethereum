// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

contract NativeTokenTransfer {
    /// @notice Transfers native tokens in batch
    function batchTransfer(
        address[] calldata addressList,
        uint256[] calldata valueList
    ) external payable {
        require(addressList.length == valueList.length, "length mismatch");

        uint256 len = addressList.length;
        unchecked {
            uint256 total = 0;
            for (uint256 i = 0; i < len; i++) {
                total += valueList[i];
            }

            require(total == msg.value, "incorrect value");

            for (uint256 i = 0; i < len; i++) {
                // slither-disable-next-line low-level-calls,arbitrary-send-eth,calls-loop
                (bool success, ) = addressList[i].call{value: valueList[i]}("");

                require(success, "transfer failed");
            }
        }
    }

    /// @notice Returns native token balances in batch
    function balances(address[] calldata addressList)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory balanceList = new uint256[](addressList.length);

        unchecked {
            for (uint256 i = 0; i < addressList.length; i++) {
                // slither-disable-next-line low-level-calls,arbitrary-send-eth
                balanceList[i] = addressList[i].balance;
            }
        }

        return balanceList;
    }
}