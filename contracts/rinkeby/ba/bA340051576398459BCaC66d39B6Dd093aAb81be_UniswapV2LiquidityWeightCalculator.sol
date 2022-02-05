pragma solidity >=0.8.10;

import "../interfaces/ILiquidityWeightCalculator.sol";
import "../interfaces/IUniswapV2Pair.sol";

error ZeroAddressNativeToken();
error InvalidLiquidity();

/**
 * @title UniswapV2LiquidityWeightCalculator
 * @dev UniswapV2LiquidityWeightCalculator contract
 * @author Federico Luzzi - <[email protected]>
 * SPDX-License-Identifier: GPL-3.0
 */
contract UniswapV2LiquidityWeightCalculator is ILiquidityWeightCalculator {
    address nativeToken;

    constructor(address _nativeToken) {
        if (_nativeToken == address(0)) revert ZeroAddressNativeToken();
        nativeToken = _nativeToken;
    }

    function calculate(address _liquidity, uint256 _amount)
        external
        view
        returns (uint256)
    {
        uint256 _reserve = 0;
        (uint256 _reserve0, uint256 _reserve1, ) = IUniswapV2Pair(_liquidity)
            .getReserves();
        if (IUniswapV2Pair(_liquidity).token0() == nativeToken)
            _reserve = _reserve0;
        else if (IUniswapV2Pair(_liquidity).token1() == nativeToken)
            _reserve = _reserve1;
        else revert InvalidLiquidity();
        return
            ((_reserve * _amount) / IUniswapV2Pair(_liquidity).totalSupply()) *
            2;
    }
}

pragma solidity >=0.8.10;

/**
 * @title ILiquidityWeightCalculator
 * @dev ILiquidityWeightCalculator contract
 * @author Federico Luzzi - <[email protected]>
 * SPDX-License-Identifier: GPL-3.0
 */
interface ILiquidityWeightCalculator {
    function calculate(address _liquidity, uint256 _amount)
        external
        view
        returns (uint256);
}

pragma solidity >=0.8.10;

/**
 * @title IUniswapV2Pair
 * @dev IUniswapV2Pair contract
 * @author Federico Luzzi - <[email protected]>
 * SPDX-License-Identifier: GPL-3.0
 */
interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}