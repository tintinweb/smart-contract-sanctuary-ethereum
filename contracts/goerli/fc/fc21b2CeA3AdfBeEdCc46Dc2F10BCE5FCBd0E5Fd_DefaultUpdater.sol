// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title IProxyUpdater
 * @notice Interface that must be inherited by each adapter.
 */
interface IProxyUpdater {
    /**
     * @notice Modifies some storage slot within the proxy contract. Gives us a lot of power to
     *         perform upgrades in a more transparent way.
     *
     * @param _key   Storage key to modify.
     * @param _value New value for the storage key.
     */
    function setStorage(bytes32 _key, bytes32 _value) external;

    receive() external payable;

    fallback() external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { IProxyUpdater } from "../interfaces/IProxyUpdater.sol";

/**
 * @title DefaultUpdater
 * @notice Proxy Updater for an OpenZeppelin Transparent Upgradeable proxy. This is the proxy
 *         updater used by default proxies in the ChugSplash system. To learn more about the
 *         transparent proxy pattern, see:
 *         https://docs.openzeppelin.com/contracts/4.x/api/proxy#transparent_proxy
 */
contract DefaultUpdater is IProxyUpdater {
    /**
     * @notice The storage slot that holds the address of the owner.
     *         bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1)
     */
    bytes32 internal constant OWNER_KEY =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @notice Queries the owner of the proxy contract.
     *
     * @return Owner address.
     */
    function _getAdmin() internal view returns (address) {
        address owner;
        assembly {
            owner := sload(OWNER_KEY)
        }
        return owner;
    }

    /**
     * @notice A modifier that reverts if not called by the owner or by address(0) to allow
     *         eth_call to interact with this proxy without needing to use low-level storage
     *         inspection. We assume that nobody is able to trigger calls from address(0) during
     *         normal EVM execution.
     */
    modifier ifAdmin() {
        if (msg.sender == _getAdmin() || msg.sender == address(0)) {
            _;
        } else {
            revert("DefaultUpdater: caller is not admin");
        }
    }

    /**
     * @notice Modifies some storage slot within the proxy contract. Gives us a lot of power to
     *         perform upgrades in a more transparent way.
     *
     * @param _key   Storage key to modify.
     * @param _value New value for the storage key.
     */
    function setStorage(bytes32 _key, bytes32 _value) external ifAdmin {
        assembly {
            sstore(_key, _value)
        }
    }

    receive() external payable {
        revert("DefaultUpdater: caller is not an admin");
    }

    fallback() external payable {
        revert("DefaultUpdater: cannot call implementation functions while update is in progress");
    }
}