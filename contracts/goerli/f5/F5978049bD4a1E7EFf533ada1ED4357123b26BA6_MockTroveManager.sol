// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

/* 
 * Mock contract does not coincide with interface of production contract.
 * Used to emit event as found in production contract to simply simulate events that
 * rarely happen, for development.
 */
contract MockTroveManager {
    string public constant NAME = "TroveManager";

    address public stabilityPool;
    address public priceFeed;

    constructor(address _stabilityPool, address _priceFeed) {
        stabilityPool = _stabilityPool;
        priceFeed = _priceFeed;
    }

    event Liquidation(
        uint256 _liquidatedDebt,
        uint256 _liquidatedColl,
        uint256 _collGasCompensation,
        uint256 _LUSDGasCompensation
    );

    function liquidation(
        uint256 _liquidatedDebt,
        uint256 _liquidatedColl,
        uint256 _collGasCompensation,
        uint256 _LUSDGasCompensation
    ) public {
        emit Liquidation(
            _liquidatedDebt,
            _liquidatedColl,
            _collGasCompensation,
            _LUSDGasCompensation
        );
    }
}