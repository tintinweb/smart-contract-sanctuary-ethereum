// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {ITradingEngine, Position} from "../../interfaces/ITradingEngine.sol";

contract Lens {
    ITradingEngine public tradingEngine;

    constructor(address _tradingEngine) {
        tradingEngine = ITradingEngine(_tradingEngine);
    }

    function getPositions(
        address account,
        address[] memory _indexTokens,
        address[] memory _collateralTokens
    ) external view returns (Position[] memory positions) {
        require(_indexTokens.length == _collateralTokens.length, "Lens: array length mismatch");
        positions = new Position[](_indexTokens.length * 2); // 2 is for both long and short

        for (uint256 i = 0; i < _indexTokens.length; i++) {
            Position memory longPosition = tradingEngine.getPosition(
                account,
                _indexTokens[i],
                _collateralTokens[i],
                true
            );

            positions[i] = longPosition;

            Position memory shortPosition = tradingEngine.getPosition(
                account,
                _indexTokens[i],
                _collateralTokens[i],
                false
            );

            positions[i + 1] = shortPosition;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

struct Position {
    /// @dev side of the position, long or short
    bool isLong;
    /// @dev contract size is evaluated in dollar
    uint256 size;
    /// @dev collateral value in dollar
    uint256 collateralValue;
    /// @dev contract size in indexToken
    uint256 collateralAmount;
    uint256 reserveAmount;
    /// @dev average entry price
    uint256 entryPrice;
    /// @dev last cumulative interest rate
    uint256 entryFundingRate;
    address collateralModule;
    bytes32 collateralPositionKey;
}

interface ITradingEngine {
    struct ExternalCollateralArgs {
        address collateralModule;
        bytes32 collateralPositionKey;
        uint256 collateralAmount;
    }

    function increasePosition(
        address _account,
        address _indexToken,
        address _collateralToken,
        uint256 _sizeDelta,
        bool _isLong
    ) external;

    function decreasePosition(
        address _account,
        address _indexToken,
        address _collateralToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong
    ) external;

    function increasePositionExternalCollateral(
        address _account,
        address _indexToken,
        address _collateralToken,
        uint256 _sizeDelta,
        bool _isLong,
        ExternalCollateralArgs calldata _args
    ) external;

    function liquidatePositionExternalCollateral(
        address _account,
        address _indexToken,
        address _collateralToken,
        bool _isLong,
        address _collateralModule,
        bytes32 _collateralPositionKey
    ) external;

    function whitelistedTokenCount() external view returns (uint256);

    function totalTokenWeights() external view returns (uint256);

    function tokenWeights(address _token) external view returns (uint256);

    function getTargetVlpAmount(address _token) external view returns (uint256);

    function getNormalizedIncome(address _token) external view returns (int256);

    function updateVaultBalance(address _token, uint256 _delta, bool _isIncrease) external;

    function getVault(address _token) external returns (address);

    function addVault(address _token, address _vault) external;

    function getPosition(
        address _account,
        address _indexToken,
        address _collateralToken,
        bool _isLong
    ) external view returns (Position memory);
}