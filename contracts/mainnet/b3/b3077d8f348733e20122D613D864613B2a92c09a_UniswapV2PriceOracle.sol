// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/libraries/UniswapV2OracleLibrary.sol";

import "./interfaces/IUniswapV2PriceOracle.sol";

/// @title Uniswap V2 price oracle
/// @notice Contains logic for price calculation of asset using Uniswap V2 Pair
/// @dev Oracle works through base asset which is set in initialize function
contract UniswapV2PriceOracle is IUniswapV2PriceOracle, ERC165 {
    using UniswapV2OracleLibrary for address;

    /// @notice Minimum oracle update interval
    /// @dev If min update interval hasn't passed (24h) before update, previously cached value is returned
    uint internal constant MIN_UPDATE_INTERVAL = 24 hours;

    IUniswapV2Pair immutable pair;
    /// @inheritdoc IUniswapV2PriceOracle
    address public immutable override asset0;
    /// @inheritdoc IUniswapV2PriceOracle
    address public immutable override asset1;

    uint32 internal blockTimestampLast;

    uint internal price0CumulativeLast;
    uint internal price1CumulativeLast;
    uint internal price0Average;
    uint internal price1Average;

    constructor(
        address _factory,
        address _assetA,
        address _assetB
    ) {
        IUniswapV2Pair _pair = IUniswapV2Pair(IUniswapV2Factory(_factory).getPair(_assetA, _assetB));
        pair = _pair;
        asset0 = _pair.token0();
        asset1 = _pair.token1();

        uint112 reserve0;
        uint112 reserve1;
        (reserve0, reserve1, blockTimestampLast) = _pair.getReserves();
        require(reserve0 != 0 && reserve1 != 0, "UniswapV2PriceOracle: RESERVES");

        uint _price0CumulativeLast = _pair.price0CumulativeLast();
        uint _price1CumulativeLast = _pair.price1CumulativeLast();
        (uint price0Cml, uint price1Cml, uint32 blockTimestamp) = address(_pair).currentCumulativePrices();
        uint32 timeElapsed = blockTimestamp - blockTimestampLast;
        price0CumulativeLast = _price0CumulativeLast;
        price1CumulativeLast = _price1CumulativeLast;
        price0Average = (price0Cml - _price0CumulativeLast) / timeElapsed;
        price1Average = (price1Cml - _price1CumulativeLast) / timeElapsed;
    }

    /// @inheritdoc IPriceOracle
    /// @dev Updates and returns cumulative price value
    /// @dev If min update interval hasn't passed (24h), previously cached value is returned
    function refreshedAssetPerBaseInUQ(address _asset) external override returns (uint) {
        (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) = address(pair).currentCumulativePrices();
        uint32 timeElapsed = blockTimestamp - blockTimestampLast;

        if (timeElapsed >= MIN_UPDATE_INTERVAL) {
            price0Average = (price0Cumulative - price0CumulativeLast) / timeElapsed;
            price1Average = (price1Cumulative - price1CumulativeLast) / timeElapsed;

            price0CumulativeLast = price0Cumulative;
            price1CumulativeLast = price1Cumulative;
            blockTimestampLast = blockTimestamp;
        }

        return lastAssetPerBaseInUQ(_asset);
    }

    /// @inheritdoc IPriceOracle
    /// @dev Returns cumulative price value cached during last refresh call
    function lastAssetPerBaseInUQ(address _asset) public view override returns (uint) {
        if (_asset == asset0) {
            return price1Average;
        } else {
            require(_asset == asset1, "UniswapV2PriceOracle: UNKNOWN");

            return price0Average;
        }
    }

    /// @inheritdoc ERC165
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return
            _interfaceId == type(IUniswapV2PriceOracle).interfaceId ||
            _interfaceId == type(IPriceOracle).interfaceId ||
            super.supportsInterface(_interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.5.0;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/lib/contracts/libraries/FixedPoint.sol';

// library with helper methods for oracles that are concerned with computing average prices
library UniswapV2OracleLibrary {
    using FixedPoint for *;

    // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2 ** 32);
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices(
        address pair
    ) internal view returns (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) {
        blockTimestamp = currentBlockTimestamp();
        price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(pair).getReserves();
        if (blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;
            // addition overflow is desired
            // counterfactual
            price0Cumulative += uint(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;
            // counterfactual
            price1Cumulative += uint(FixedPoint.fraction(reserve0, reserve1)._x) * timeElapsed;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

import "./IPriceOracle.sol";

/// @title Uniswap price oracle interface
/// @notice Contains logic for price calculation of asset using Uniswap V2 Pair
interface IUniswapV2PriceOracle is IPriceOracle {
    /// @notice Asset0 in the pair
    /// @return Returns address of asset0 in the pair
    function asset0() external view returns (address);

    /// @notice Asset1 in the pair
    /// @return Returns address of asset1 in the pair
    function asset1() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.4.0;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint _x;
    }

    uint8 private constant RESOLUTION = 112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function div(uq112x112 memory self, uint112 x) internal pure returns (uq112x112 memory) {
        require(x != 0, 'FixedPoint: DIV_BY_ZERO');
        return uq112x112(self._x / uint224(x));
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint y) internal pure returns (uq144x112 memory) {
        uint z;
        require(y == 0 || (z = uint(self._x) * y) / y == uint(self._x), "FixedPoint: MULTIPLICATION_OVERFLOW");
        return uq144x112(z);
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // equivalent to encode(numerator).div(denominator)
    function fraction(uint112 numerator, uint112 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112((uint224(numerator) << RESOLUTION) / denominator);
    }

    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

/// @title Price oracle interface
/// @notice Returns price of single asset in relation to base
interface IPriceOracle {
    /// @notice Updates and returns asset per base
    /// @return Asset per base in UQ
    function refreshedAssetPerBaseInUQ(address _asset) external returns (uint);

    /// @notice Returns last asset per base
    /// @return Asset per base in UQ
    function lastAssetPerBaseInUQ(address _asset) external view returns (uint);
}