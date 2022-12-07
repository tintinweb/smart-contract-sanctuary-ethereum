// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;
pragma experimental ABIEncoderV2;

contract BaseV2PairInterface {
    struct Observation {
        uint256 timestamp;
        uint256 reserve0Cumulative;
        uint256 reserve1Cumulative;
    }

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Claim(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1
    );
    event Fees(address indexed sender, uint256 amount0, uint256 amount1);
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint256 reserve0, uint256 reserve1);
    event Transfer(address indexed from, address indexed to, uint256 amount);

    function allowance(address, address) external view returns (uint256) {}

    function approve(address spender, uint256 amount) external returns (bool) {}

    function balanceOf(address) external view returns (uint256) {}

    function blockTimestampLast() external view returns (uint256) {}

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1)
    {}

    function claimFees()
        external
        returns (uint256 claimed0, uint256 claimed1)
    {}

    function current(address tokenIn, uint256 amountIn)
        external
        view
        returns (uint256 amountOut)
    {}

    function currentCumulativePrices()
        external
        view
        returns (
            uint256 reserve0Cumulative,
            uint256 reserve1Cumulative,
            uint256 blockTimestamp
        )
    {}

    function decimals() external view returns (uint8) {}

    function factoryAddress() external view returns (address _factory) {}

    function feeRatio() external view returns (uint256) {}

    function fees() external view returns (address) {}

    function getAmountOut(uint256 amountIn, address tokenIn)
        external
        view
        returns (uint256)
    {}

    function getReserves()
        external
        view
        returns (
            uint256 _reserve0,
            uint256 _reserve1,
            uint256 _blockTimestampLast
        )
    {}

    function governanceAddress()
        external
        view
        returns (address _governanceAddress)
    {}

    function initialize(
        address _token0,
        address _token1,
        bool _stable
    ) external {}

    function lastObservation() external view returns (Observation memory) {}

    function metadata()
        external
        view
        returns (
            uint256 dec0,
            uint256 dec1,
            uint256 r0,
            uint256 r1,
            bool st,
            address t0,
            address t1,
            uint256 _feeRatio
        )
    {}

    function mint(address to) external returns (uint256 liquidity) {}

    function name() external view returns (string memory) {}

    function nonces(address) external view returns (uint256) {}

    function observationLength() external view returns (uint256) {}

    function observations(uint256)
        external
        view
        returns (
            uint256 timestamp,
            uint256 reserve0Cumulative,
            uint256 reserve1Cumulative
        )
    {}

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {}

    function prices(
        address tokenIn,
        uint256 amountIn,
        uint256 points
    ) external view returns (uint256[] memory) {}

    function quote(
        address tokenIn,
        uint256 amountIn,
        uint256 granularity
    ) external view returns (uint256 amountOut) {}

    function reserve0() external view returns (uint256) {}

    function reserve0CumulativeLast() external view returns (uint256) {}

    function reserve1() external view returns (uint256) {}

    function reserve1CumulativeLast() external view returns (uint256) {}

    function sample(
        address tokenIn,
        uint256 amountIn,
        uint256 points,
        uint256 window
    ) external view returns (uint256[] memory) {}

    function skim(address to) external {}

    function stable() external view returns (bool) {}

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes memory data
    ) external {}

    function symbol() external view returns (string memory) {}

    function sync() external {}

    function syncFees() external {}

    function token0() external view returns (address) {}

    function token1() external view returns (address) {}

    function tokens() external view returns (address, address) {}

    function totalSupply() external view returns (uint256) {}

    function transfer(address dst, uint256 amount) external returns (bool) {}

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool) {}
}