// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import {Proxied} from "./vendor/proxy/Proxied.sol";

contract GaugeRegistry is Proxied {
    address[] public gauges;
    mapping(address => address) public gaugeToVault;

    event AddGauge(address gauge, address vault);
    event RemoveGauge(address gauge, address vault);

    constructor() {} // solhint-disable no-empty-blocks

    function addGauge(address newGauge, address vault) external onlyProxyAdmin {
        require(
            gaugeToVault[newGauge] == address(0),
            "GaugeRegistry: gauge already added"
        );
        gauges.push(newGauge);
        gaugeToVault[newGauge] = vault;
        emit AddGauge(newGauge, vault);
    }

    function removeGauge(address gauge) external onlyProxyAdmin {
        _removeFromArray(gauge);
        emit RemoveGauge(gauge, gaugeToVault[gauge]);
        delete gaugeToVault[gauge];
    }

    function _removeFromArray(address target) internal {
        uint256 index = 1 ether;
        address[] memory _gauges = gauges;
        for (uint256 i = 0; i < _gauges.length; i++) {
            if (_gauges[i] == target) {
                index = i;
                break;
            }
        }
        require(index < 1 ether, "GaugeRegistry: element not found");
        gauges[index] = _gauges[_gauges.length - 1];
        gauges.pop();
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

abstract contract Proxied {
    /// @notice to be used by initialisation / postUpgrade function so that only the proxy's admin can execute them
    /// It also allows these functions to be called inside a contructor
    /// even if the contract is meant to be used without proxy
    modifier proxied() {
        address proxyAdminAddress = _proxyAdmin();
        // With hardhat-deploy proxies
        // the proxyAdminAddress is zero only for the implementation contract
        // if the implementation contract want to be used as a standalone/immutable contract
        // it simply has to execute the `proxied` function
        // This ensure the proxyAdminAddress is never zero post deployment
        // And allow you to keep the same code for both proxied contract and immutable contract
        if (proxyAdminAddress == address(0)) {
            // ensure can not be called twice when used outside of proxy : no admin
            // solhint-disable-next-line security/no-inline-assembly
            assembly {
                sstore(
                    0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103,
                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
                )
            }
        } else {
            require(msg.sender == proxyAdminAddress);
        }
        _;
    }

    modifier onlyProxyAdmin() {
        require(msg.sender == _proxyAdmin(), "NOT_AUTHORIZED");
        _;
    }

    function _proxyAdmin() internal view returns (address adminAddress) {
        // solhint-disable-next-line security/no-inline-assembly
        assembly {
            adminAddress := sload(
                0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103
            )
        }
    }
}