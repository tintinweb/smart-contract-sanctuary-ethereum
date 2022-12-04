//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Module that enables calling multiple methods of the system in a single transaction.
 */
interface IMulticallModule {
    /**
     * @notice Executes multiple transaction payloads in a single transaction.
     * @dev Each transaction is executed using `delegatecall`, and targets the system address.
     */
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../interfaces/IMulticallModule.sol";

/**
 * @title Module that enables calling multiple methods of the system in a single transaction.
 * @dev See IMulticallModule.
 * @dev Implementation adapted from https://github.com/Uniswap/v3-periphery/blob/main/contracts/base/Multicall.sol
 */
contract MulticallModule is IMulticallModule {
    /**
     * @inheritdoc IMulticallModule
     */
    function multicall(bytes[] calldata data) public payable override returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

            if (!success) {
                // Next 6 lines from https://ethereum.stackexchange.com/a/83577
                // solhint-disable-next-line reason-string
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }

            results[i] = result;
        }
    }
}