// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.11;

// Pool manager implementation with no restrictions where every function is a no-op. Refer to "PoolManager.sol"
// for an exemplar of a normal Pool Manager.
contract NoopPoolManager {
    function deployPool(
        string calldata name,
        uint256 closeFactor,
        uint256 liqIncentive,
        address fallbackOracle
    ) external returns (uint256 _poolIndex, address _comptroller) {}

    function addTarget(address target, address adapter) external returns (address cTarget) {}

    function queueSeries(
        address adapter,
        uint256 maturity,
        address pool
    ) external {}

    function addSeries(address adapter, uint256 maturity) external returns (address, address) {}
}