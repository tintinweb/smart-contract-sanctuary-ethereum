// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;

contract SolidlyLibraryInterface {
    function getAmountOut(
        uint256 amountIn,
        address tokenIn,
        address tokenOut,
        bool stable
    ) external view returns (uint256) {}

    function getMinimumValue(
        address tokenIn,
        address tokenOut,
        bool stable
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {}

    function getSample(
        address tokenIn,
        address tokenOut,
        bool stable
    ) external view returns (uint256) {}

    function getTradeDiff(
        uint256 amountIn,
        address tokenIn,
        address tokenOut,
        bool stable
    ) external view returns (uint256 a, uint256 b) {}

    function getTradeDiff(
        uint256 amountIn,
        address tokenIn,
        address pair
    ) external view returns (uint256 a, uint256 b) {}

    function governanceAddress()
        external
        view
        returns (address _governanceAddress)
    {}

    function initialize(address _router) external {}

    function router() external view returns (address) {}
}