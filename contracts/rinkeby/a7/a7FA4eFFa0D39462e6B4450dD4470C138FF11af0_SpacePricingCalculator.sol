// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./interfaces/IPricingCalculator.sol";
import "./interfaces/IERC1543.sol";
import "./interfaces/IERC20Metadata.sol";
import "./interfaces/IUniswapV2Pair.sol";

import "./libraries/FixedPoint.sol";

contract SpacePricingCalculator is IPricingCalculator {
    
	IERC1543 internal immutable _factory;

    constructor(address factory_) {
        require(factory_ != address(0), "Zero address: ALP Factory");
        _factory = IERC1543(factory_);
    }

    function getKValue(address _pair) public view returns (uint256 k_) {
        uint256 token0 = IERC20Metadata(IUniswapV2Pair(_pair).token0()).decimals();
        uint256 token1 = IERC20Metadata(IUniswapV2Pair(_pair).token1()).decimals();
        uint256 decimals = token0 + token1 - IERC20Metadata(_pair).decimals();

        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(_pair).getReserves();
        k_ = reserve0 * reserve1 / (10**decimals);
    }

    function getTotalValue(address _pair) public view returns (uint256 _value) {
        _value = FixedPoint.sqrrt(getKValue(_pair)) * 2;
    }

    function valuation(address _pair, uint256 amount_) external view override returns (uint256 _value) {
        uint256 totalValue = getTotalValue(_pair);
        uint256 totalSupply = IUniswapV2Pair(_pair).totalSupply();
		
		_value = totalValue * FixedPoint.fraction(amount_, totalSupply) / 1e18;
    }

    function markdown(address _pair, uint256 tokenId) external view override returns (uint256) {
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(_pair).getReserves();
		address alpAddress = _factory.assetPair(tokenId).tokenAddress;

        uint256 reserve;
        if (IUniswapV2Pair(_pair).token0() == alpAddress) {
            reserve = reserve1;
        } else {
            require(IUniswapV2Pair(_pair).token1() == alpAddress, "Invalid pair");
            reserve = reserve0;
        }
        return reserve * (2 * (10**IERC20Metadata(alpAddress).decimals())) / getTotalValue(_pair);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

library FullMath {
	function mulDiv(
		uint256 a,
		uint256 b,
		uint256 denominator
	) internal pure returns (uint256 result) {
		// 512-bit multiply [prod1 prod0] = a * b
		// Compute the product mod 2**256 and mod 2**256 - 1
		// then use the Chinese Remainder Theorem to reconstruct
		// the 512 bit result. The result is stored in two 256
		// variables such that product = prod1 * 2**256 + prod0
		uint256 prod0; // Least significant 256 bits of the product
		uint256 prod1; // Most significant 256 bits of the product
		assembly {
			let mm := mulmod(a, b, not(0))
			prod0 := mul(a, b)
			prod1 := sub(sub(mm, prod0), lt(mm, prod0))
		}

		// Handle non-overflow cases, 256 by 256 division
		if (prod1 == 0) {
			require(denominator > 0);
			assembly {
				result := div(prod0, denominator)
			}
			return result;
		}

		// Make sure the result is less than 2**256.
		// Also prevents denominator == 0
		require(denominator > prod1);

		///////////////////////////////////////////////
		// 512 by 256 division.
		///////////////////////////////////////////////

		// Make division exact by subtracting the remainder from [prod1 prod0]
		// Compute remainder using mulmod
		uint256 remainder;
		assembly {
			remainder := mulmod(a, b, denominator)
		}
		// Subtract 256 bit number from 512 bit number
		assembly {
			prod1 := sub(prod1, gt(remainder, prod0))
			prod0 := sub(prod0, remainder)
		}

		// Factor powers of two out of denominator
		// Compute largest power of two divisor of denominator.
		// Always >= 1.
		unchecked {
			uint256 twos = (type(uint256).max - denominator + 1) & denominator;
			// Divide denominator by power of two
			assembly {
				denominator := div(denominator, twos)
			}

			// Divide [prod1 prod0] by the factors of two
			assembly {
				prod0 := div(prod0, twos)
			}
			// Shift in bits from prod1 into prod0. For this we need
			// to flip `twos` such that it is 2**256 / twos.
			// If twos is zero, then it becomes one
			assembly {
				twos := add(div(sub(0, twos), twos), 1)
			}
			prod0 |= prod1 * twos;

			// Invert denominator mod 2**256
			// Now that denominator is an odd number, it has an inverse
			// modulo 2**256 such that denominator * inv = 1 mod 2**256.
			// Compute the inverse by starting with a seed that is correct
			// correct for four bits. That is, denominator * inv = 1 mod 2**4
			uint256 inv = (3 * denominator) ^ 2;
			// Now use Newton-Raphson iteration to improve the precision.
			// Thanks to Hensel's lifting lemma, this also works in modular
			// arithmetic, doubling the correct bits in each step.
			inv *= 2 - denominator * inv; // inverse mod 2**8
			inv *= 2 - denominator * inv; // inverse mod 2**16
			inv *= 2 - denominator * inv; // inverse mod 2**32
			inv *= 2 - denominator * inv; // inverse mod 2**64
			inv *= 2 - denominator * inv; // inverse mod 2**128
			inv *= 2 - denominator * inv; // inverse mod 2**256

			// Because the division is now exact we can divide by multiplying
			// with the modular inverse of denominator. This will give us the
			// correct result modulo 2**256. Since the precoditions guarantee
			// that the outcome is less than 2**256, this is the final result.
			// We don't need to compute the high bits of the result and prod1
			// is no longer required.
			result = prod0 * inv;
			return result;
		}
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./FullMath.sol";

library Babylonian {
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;

        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }
}

library BitMath {
    function mostSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0, "BitMath::mostSignificantBit: zero");

        if (x >= 0x100000000000000000000000000000000) {
            x >>= 128;
            r += 128;
        }
        if (x >= 0x10000000000000000) {
            x >>= 64;
            r += 64;
        }
        if (x >= 0x100000000) {
            x >>= 32;
            r += 32;
        }
        if (x >= 0x10000) {
            x >>= 16;
            r += 16;
        }
        if (x >= 0x100) {
            x >>= 8;
            r += 8;
        }
        if (x >= 0x10) {
            x >>= 4;
            r += 4;
        }
        if (x >= 0x4) {
            x >>= 2;
            r += 2;
        }
        if (x >= 0x2) r += 1;
    }
}

library FixedPoint {
    struct uq112x112 {
        uint224 _x;
    }

    struct uq144x112 {
        uint256 _x;
    }

    uint8 private constant RESOLUTION = 112;
    uint256 private constant Q112 = 0x10000000000000000000000000000;
    uint256 private constant Q224 = 0x100000000000000000000000000000000000000000000000000000000;
    uint256 private constant LOWER_MASK = 0xffffffffffffffffffffffffffff; // decimal of UQ*x112 (lower 112 bits)

    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    function decode112with18(uq112x112 memory self) internal pure returns (uint256) {
        return uint256(self._x) / 5192296858534827;
    }

    function fraction(uint256 numerator, uint256 denominator) internal pure returns (uint256) {
        require(denominator > 0, "FixedPoint::fraction: division by zero");
        if (numerator == 0) return 0;

        if (numerator <= type(uint144).max) {
            uint256 result = (numerator << RESOLUTION) / denominator;
            require(result <= type(uint224).max, "FixedPoint::fraction: overflow");
            return result / 5192296858534827;
        } else {
            uint256 result = FullMath.mulDiv(numerator, Q112, denominator);
            require(result <= type(uint224).max, "FixedPoint::fraction: overflow");
            return result / 5192296858534827;
        }
    }

	function sqrrt(uint256 a) internal pure returns (uint256 c) {
        if (a > 3) {
            c = a;
            uint256 b = (a / 2) + 1;
            while (b < c) {
                c = b;
                b = ((a / b) + b ) / 2;
            }
        } else if (a != 0) {
            c = 1;
        }
    }
}

// SPDX-License-Identifier: MIT
  
pragma solidity 0.8.7;

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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface IPricingCalculator {
	// liquidity price
    function markdown(address _LP, uint256 tokenId) external view returns (uint256);
    function valuation(address pair_, uint256 amount_) external view returns (uint256 _value);

	// internal price
}

// SPDX-License-Identifier: MIT
  
pragma solidity 0.8.7;

interface IERC20Metadata {
	function decimals() external view returns (uint8);
	function name() external view returns (string memory);
	function symbol() external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface IERC1543 {
	struct AssetPair {
        bool initialized;
        uint256 epoch;
        address tokenAddress;
        bool checked;
		uint256 debt;
		uint256 paymentAmount;
		uint256 paymentTime;
		uint256 paymentDelay;
    }
	
	event PairCreated(uint256 indexed tokenId, address indexed alp);
	event DebtChanged(uint256 indexed tokenId, uint256 indexed amount, bool add);
	event AssetChanged(
		uint256 indexed tokenId, 
		address indexed owner, 
		uint256 delay, 
		uint256 amount
	);

	function allPairsLength() external view returns (uint256);
	function checkedPairsLength() external view returns (uint256);
	function assetPair(uint256 tokenId) external view returns (AssetPair memory);

	function createPair(
		address to,
		uint256 paymentDelay,
		string memory name, 
		string memory symbol,
		string memory metadataURI
	) external returns (uint256);
	
	function changeDebt(
		address owner,
		uint256 amount,
		uint256 tokenId,
		bool add
	) external;

	function changeAssetInfo(
		uint256 tokenId,
		uint256 delay,
		uint256 amount,
		address owner
	) external;

	function checkAssetPair(uint256 tokenId) external;
	function rebase(uint256 tokenId, int256 supplyDelta) external;
	function burnAsset(uint256 tokenId, address owner) external;
}