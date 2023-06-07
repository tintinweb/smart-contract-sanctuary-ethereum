//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "../../interfaces/IMulticallModule.sol";

import "../../storage/Config.sol";

/**
 * @title Module that enables calling multiple methods of the system in a single transaction.
 * @dev See IMulticallModule.
 * @dev Implementation adapted from https://github.com/Uniswap/v3-periphery/blob/main/contracts/base/Multicall.sol
 */
contract MulticallModule is IMulticallModule {
    bytes32 internal constant _CONFIG_MESSAGE_SENDER = "_messageSender";

    error RecursiveMulticall(address);

    /**
     * @inheritdoc IMulticallModule
     */
    function multicall(
        bytes[] calldata data
    ) public payable override returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

            if (!success) {
                uint len = result.length;
                assembly {
                    revert(add(result, 0x20), len)
                }
            }

            results[i] = result;
        }
    }

    // uncomment this when governance approves `multicallThrough` functionality (didnt want to put this in a separate PR for now)
    /*function multicallThrough(
        address[] calldata to,
        bytes[] calldata data
    ) public payable override returns (bytes[] memory results) {
        if (Config.read(_CONFIG_MESSAGE_SENDER, 0) != 0) {
            revert RecursiveMulticall(msg.sender);
        }

        Config.put(_CONFIG_MESSAGE_SENDER, bytes32(uint256(uint160(msg.sender))));

        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            bool success;
            bytes memory result;
            if (to[i] == address(this)) {
                (success, result) = address(this).delegatecall(data[i]);
            } else {
                (success, result) = address(to[i]).call(data[i]);
            }

            if (!success) {
                uint len = result.length;
                assembly {
                    revert(add(result, 0x20), len)
                }
            }

            results[i] = result;
        }

        Config.put(_CONFIG_MESSAGE_SENDER, 0);
    }

    function getMessageSender() external view override returns (address) {
        return Config.readAddress(_CONFIG_MESSAGE_SENDER, address(0));
    }*/
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Module that enables calling multiple methods of the system in a single transaction.
 */
interface IMulticallModule {
    /**
     * @notice Executes multiple transaction payloads in a single transaction.
     * @dev Each transaction is executed using `delegatecall`, and targets the system address.
     * @param data Array of calldata objects, one for each function that is to be called in the system.
     * @return results Array of each `delegatecall`'s response corresponding to the incoming calldata array.
     */
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);

    /**
     * @notice Similar to `multicall`, but allows for transactions to be executed
     * @dev If the address specified in `to` iteration is not the core system, it will call the contract with a regular "call". If it is the core system, it will be delegatecall.
     * @dev Target `to` contracts will need to support calling the below `getMessageSender` rather than regular `msg.sender` in order to allow for usage of permissioned calls with this function
     * @dev It is not possible to call this function recursively.
     * @dev Fails immediately on revert of any call.
     * @return results Array of each call's response corresponding
     */
    /*function multicallThrough(
        address[] calldata to,
        bytes[] calldata data
    ) external payable returns (bytes[] memory results);

    function getMessageSender() external view returns (address);*/
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title System wide configuration for anything
 */
library Config {
    struct Data {
        uint256 __unused;
    }

    /**
     * @dev Returns a config value
     */
    function read(bytes32 k, bytes32 zeroValue) internal view returns (bytes32 v) {
        bytes32 s = keccak256(abi.encode("Config", k));
        assembly {
            v := sload(s)
        }

        if (v == bytes32(0)) {
            v = zeroValue;
        }
    }

    function readUint(bytes32 k, uint256 zeroValue) internal view returns (uint256 v) {
        // solhint-disable-next-line numcast/safe-cast
        return uint(read(k, bytes32(zeroValue)));
    }

    function readAddress(bytes32 k, address zeroValue) internal view returns (address v) {
        // solhint-disable-next-line numcast/safe-cast
        return address(uint160(readUint(k, uint160(zeroValue))));
    }

    function put(bytes32 k, bytes32 v) internal {
        bytes32 s = keccak256(abi.encode("Config", k));
        assembly {
            sstore(s, v)
        }
    }
}