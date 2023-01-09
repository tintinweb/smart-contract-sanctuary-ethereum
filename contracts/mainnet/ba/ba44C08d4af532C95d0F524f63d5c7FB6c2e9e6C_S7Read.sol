import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IQuoter.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/INonfungiblePositionManagerStrategy.sol";
import "./interfaces/IS7.sol";
import "./interfaces/IS4.sol";
import "./interfaces/IS4Calc.sol";
import "./interfaces/IAavePriceOracle.sol";
import "./interfaces/IProtocolDataProvider.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV3Factory.sol";

import "./interfaces/ILendingPool.sol";

pragma solidity ^0.8.17;

// SPDX-License-Identifier: MIT

contract S7Read is Ownable {
    address wethAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address protocolDataProvider=0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d;

    uint24[] feeTiers;

    //aave addresses
    ILendingPool lendingPool =
        ILendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
    IAavePriceOracle aavePriceOracle =
        IAavePriceOracle(0xA50ba011c48153De246E5192C8f9258A2ba79Ca9);

    IQuoter uniswapQuoter = IQuoter(0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6);

    IUniswapV3Factory uniV3Factory =
        IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);

    IS4 s4;
    IS4Calc s4Calc;

    constructor(
        address s4_,
        address s4Calc_,
        uint24[] memory feeTiers_
    ) {
        s4 = IS4(s4_);
        s4Calc = IS4Calc(s4Calc_);
        feeTiers = feeTiers_;
    }

    //getter for v3 position NFTs
    function getV3PositionNft(
        address strategy,
        address user,
        address token0,
        address token1,
        uint24 poolFee
    )
        public
        view
        returns (
            address,
            address,
            uint256
        )
    {
        return IS7(strategy).getV3PositionNft(user, token0, token1, poolFee);
    }

    //getter for v3 position
    function getV3Position(uint256 nftId)
        public
        view
        returns (
            //0: nonce
            uint96,
            //1: operator
            address,
            //2: token0
            address,
            //3: token1
            address,
            //4: fee
            uint24,
            //5:tickLower
            int24,
            //6:tickUpper
            int24,
            //7:liquidity (@dev current deposit)
            uint128,
            //8:feeGrowthInside0LastX128
            uint256,
            //9:feeGrowthInside1LastX128
            uint256,
            //10:tokensOwed0 (@dev avaliable to claim)
            uint128,
            //11:tokensOwed1 (@dev avaliable to claim)
            uint128
        )
    {
        return s4.getV3Position(nftId);
    }

    //getter for v3 pool data given poolAddress
    function getV3PoolData(address poolAddress)
        public
        view
        returns (
            address,
            address,
            uint24
        )
    {
        return s4.getV3PoolData(poolAddress);
    }

    //getter for v3 PoolAddress give tokens and fees
    function getV3PoolAddress(
        address token0,
        address token1,
        uint24 fee
    ) public view returns (address) {
        return s4.getV3PoolAddress(token0, token1, fee);
    }

    //@dev use staticcall for this function
    function getV3TokenAmounts(uint256 nftId)
        public
        returns (uint256 token0Amt, uint256 token1Amt)
    {
        return s4Calc.getV3TokenAmounts(nftId); 
    }

    //getter for v2 pools
    function getV2PoolData(address poolAddress)
        public
        view
        returns (address, address)
    {
        return s4.getV2PoolData(poolAddress);
    }

    function getV2PoolAddress(address token0, address token1)
        public
        view
        returns (address)
    {
        return s4.getV2PoolAddress(token0, token1);
    }

    function getV2TokenAmounts(address user, address pool)
        public
        view
        returns (uint256 token0Amt, uint256 token1Amt)
    {
        return s4Calc.getV2TokenAmounts(user, pool);
    }

    //@dev use staticcall for this function
    //@dev pass nftId 0 for v2Pool
    function getUserData(
        address strategy,
        address user,
        address poolAddress,
        uint256 nftId
    )
        public
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        address token0;
        address token1;
        uint256 stakedEth;
        uint256 token0Eth;
        uint256 token1Eth;
        uint token0Amt;
        uint token1Amt;
        address proxy = IS7(strategy).userPoolProxy(user, poolAddress);

        //get the supply and borrow amounts
        (uint256 supplyEth, uint256 borrowEth, , , , uint256 healthFactor) = lendingPool
            .getUserAccountData(proxy);
        //get the token0 and token1 address
        token0 = IUniswapV2Pair(poolAddress).token0();
        token1 = IUniswapV2Pair(poolAddress).token1();
        if(nftId>0){
            (token0Amt, token1Amt) = getV3TokenAmounts(nftId);
        }else{
            (token0Amt, token1Amt) = getV2TokenAmounts(proxy, poolAddress);
        }
        //get amount of token0 in eth
        token0Eth = getv3Quote(wethAddress, token0);

        //get amount of token1 in eth
        token1Eth = getv3Quote(wethAddress, token1);
        stakedEth = (token0Amt * token0Eth) + (token1Amt * token1Eth);
        return (supplyEth, borrowEth, stakedEth, healthFactor);
    }

    //@dev use staticcall for this function
    //Quotes amount of tokenB for 1 unit of tokenA
    function getv3Quote(address tokenA, address tokenB)
        public
        returns (uint256)
    {
        if (tokenA == wethAddress || tokenB == wethAddress) {
            //Attempt to fetch price from AAVE to resolve USDT issue
            uint256 aavePrice = aavePriceOracle.getAssetPrice(tokenB);
            if (aavePrice > 0) {
                return
                    tokenB == wethAddress
                        ? aavePrice
                        : 10**(18 + IERC20(tokenB).decimals()) / aavePrice;
            }
        } else {
            for (uint256 i = 0; i < feeTiers.length; i++) {
                try
                    uniswapQuoter.quoteExactInputSingle(
                        tokenA,
                        tokenB,
                        feeTiers[i],
                        1 * 10**IERC20(tokenA).decimals(),
                        0
                    )
                returns (uint256 price) {
                    return price;
                } catch {}
            }
        }
        return 0;
    }

    function getAaveData(address asset) public view returns(address, address, uint){
        (, , , , , , , address aToken, , address debtToken, , ) = ILendingPool(lendingPool)
            .getReserveData(asset);
        (, uint256 ltv, , , , , , , , ) = IProtocolDataProvider(
            protocolDataProvider
        ).getReserveConfigurationData(asset);

        return(aToken, debtToken, ltv);
    }

    function addFeeTier(uint24 feeTier) external onlyOwner {
        feeTiers.push(feeTier);
    }

}

pragma solidity ^0.8.17;

// SPDX-License-Identifier: MIT

interface IQuoter {
    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);

    function quoteExactInput(bytes memory path, uint256 amountIn)
        external
        returns (uint256 amountOut);
}

pragma solidity 0.8.17;
// SPDX-License-Identifier: MIT

interface IERC20 {
    function balanceOf(address _owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external;

    function transfer(address recipient, uint256 amount) external;

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external;

    function decimals() external view returns (uint256);
}

pragma solidity >=0.8.17;
// SPDX-License-Identifier: GPL-2.0-or-later

interface INonfungiblePositionManagerStrategy{
    function ownerOf(uint tokenId) external view returns(address);
    function safeTransferFrom(address from, address to, uint tokenId) external;
    function safeTransferFrom(address from, address to, uint tokenId, bytes memory data) external;
       
    /// @notice Returns the position information associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the position
    /// @return nonce The nonce for permits
    /// @return operator The address that is approved for spending
    /// @return token0 The address of the token0 for a specific pool
    /// @return token1 The address of the token1 for a specific pool
    /// @return fee The fee associated with the pool
    /// @return tickLower The lower end of the tick range for the position
    /// @return tickUpper The higher end of the tick range for the position
    /// @return liquidity The liquidity of the position
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );
}

pragma solidity ^0.8.17;

// SPDX-License-Identifier: MIT

interface IS7{
    function userPoolProxy(address user, address poolAddress) external view returns(address proxy);
    function getV3PositionNft(address user, address token0, address token1, uint24 poolFee) external view returns(address _token0, address _token1, uint _nftId);
}

pragma solidity ^0.8.17;

// SPDX-License-Identifier: MIT

interface IS4Calc {
    function getV2TokenAmounts(address user, address pool) external view returns(uint token0Amt, uint token1Amt);
    function getV3TokenAmounts(uint256 nftId) external returns(uint token0Amt, uint token1Amt);
}

pragma solidity ^0.8.17;

// SPDX-License-Identifier: MIT

interface IAavePriceOracle{
    function getAssetPrice(address _asset) external view returns(uint256 price);
}

pragma solidity ^0.8.17;

// SPDX-License-Identifier: MIT

interface IS4{
    function depositors(address user) external view returns (address proxy);
        function getV3Position(uint256 nftId) external view returns(
            //0: nonce
            uint96 nonce,
            //1: operator
            address operator,
            //2: token0
            address token0,
            //3: token1
            address token1,
            //4: fee
            uint24 fee,
            //5:tickLower
            int24 tickLower,
            //6:tickUpper
            int24 tickUpper,
            //7:liquidity (@dev current deposit)
            uint128 liquidity,
            //8:feeGrowthInside0LastX128
            uint256 feeGrowthInside0LastX128,
            //9:feeGrowthInside1LastX128
            uint256 feeGrowthInside1LastX128,
            //10:tokensOwed0 (@dev avaliable to claim)
            uint128 tokensOwed0,
            //11:tokensOwed1 (@dev avaliable to claim)
            uint128 tokensOwed1
            );
    function getV3PoolData(address poolAddress)
        external
        view
        returns (
            address token0,
            address token1,
            uint24 poolFee
        );

    //getter for v3 PoolAddress give tokens and fees
    function getV3PoolAddress(
        address token0,
        address token1,
        uint24 fee
    ) external view returns (address poolAddress);

    function getV2PoolData(address poolAddress)
        external
        view
        returns (address token0, address token1);

    function getV2PoolAddress(address token0, address token1)
        external
        view
        returns (address poolAddress);    
}

pragma solidity ^0.8.17;

// SPDX-License-Identifier: MIT

interface IProtocolDataProvider {
    function getReserveConfigurationData(address asset)
        external
        view
        returns (
            uint256 decimals,
            uint256 ltv,
            uint256 liquidationThreshold,
            uint256 liquidationBonus,
            uint256 reserveFactor,
            bool usageAsCollateralEnabled,
            bool borrowingEnabled,
            bool stableBorrowRateEnabled,
            bool isActive,
            bool isFrozen
        );
}

pragma solidity >=0.5.0;
// SPDX-License-Identifier: MIT
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

pragma solidity >=0.5.0;
// SPDX-License-Identifier: GPL-2.0-or-later

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
   
    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

}

pragma solidity ^0.8.17;

// SPDX-License-Identifier: MIT

interface ILendingPool {
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external;

    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    function repay(
        address asset,
        uint256 amount,
        uint256 rateMode,
        address onBehalfOf
    ) external;

    function getReserveData(address asset)
        external
        view
        returns (
            uint256 configuration,
            uint128 liquidityIndex,
            uint128 variableBorrowIndex,
            uint128 currentLiquidityRate,
            uint128 currentVariableBorrowRate,
            uint128 currentStableBorrowRate,
            uint40 lastUpdateTimestamp,
            address aTokenAddress,
            address stableDebtTokenAddress,
            address variableDebtTokenAddress,
            address interestRateStrategyAddress,
            uint8 id
        );

    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );

    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata modes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}