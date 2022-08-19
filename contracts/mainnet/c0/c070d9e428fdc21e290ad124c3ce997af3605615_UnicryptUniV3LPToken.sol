// SPDX-License-Identifier: UNLICENSED
// ALL RIGHTS RESERVED
// Unicrypt by SDDTech reserves all rights on this code. You may NOT copy these contracts.

pragma solidity 0.8.3;

import "./ERC20.sol";
import "./Ownable.sol";

import "./TransferHelper.sol";
import "./FullMath.sol";

import "./IUniswapV3MintCallback.sol";
import "./IUniswapV3Pool.sol";
import "./IWETH9.sol";
import "./IUnicryptUniV3LPFactory.sol";
import "./IFeeHelper.sol";

/// @title Uniswap V3 LP Token on Unicrypt
/// @notice The Uniswap V3 LP Token facilitates creates and manages Unicrypt LP tokens and 
///  interactions with the pool

contract UnicryptUniV3LPToken is ERC20, Ownable, IUniswapV3MintCallback {

    uint256 constant public CONTRACT_VERSION = 1;

    address public token0;
    address public token1;
    address public pool;
    uint24 public fee;
    /// @dev stores tick data, used by the V3 pool to calculate the range of concentrated liquidity
    int24 public tickUpper;
    int24 public tickLower;

    /// @dev stores position data from the V3 pool, used to calculate rewards from fees
    /// updated after each call to the V3 pool
    struct Position {
        uint256 liquidity;
        uint256 feeGrowthInside0LastX128;
        uint256 feeGrowthInside1LastX128;
        uint128 tokensOwed0;
        uint128 tokensOwed1;
    }

    Position public positionState;

    /// @dev pool cannot be initiallized twice
    bool public initialized = false;

    address public WETH9;

    /// @dev used to create a unique pool key similar to what V3 uses
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    /// @dev data format needed to decode the mintcallback data from the pool
    struct MintCallbackData {
        PoolKey poolKey;
        address payer;
    }
    
    PoolKey private poolKey;

    event Mint(address sender, int24 tickLower, int24 tickUpper, uint128 liquidity, uint256 amount0, uint256 amount1);
    event Burn(address sender, int24 tickLower, int24 tickUpper, uint128 liquidity, uint256 _desiredLiquidity, uint256 amount0, uint256 amount1);
    event Collect(address pool, uint128 amount0Collect, uint128 amount1Collect);
    event Fee(address token, address sender, address recipient, uint256 fee);
    event SetTicks(int24 tickUpper, int24 tickLower);
    event InitializePool(uint160 sqrtPriceX96);

    constructor(string memory name, string memory symbol, address _token0, address _token1, uint24 _fee, address _pool, address _WETH9) ERC20(name, symbol) {
        require(_token0 != address(0));
        require(_token1 != address(0));
        require(_pool != address(0));
        require(_WETH9 != address(0));

        token0 = _token0;
        token1 = _token1;
        fee = _fee;
        pool = _pool;
        WETH9 = _WETH9;
        poolKey = PoolKey(token0, token1, fee);
    }

    /// @notice Sets the ticks on the LP Token
    /// @dev Must call this from the factory before doing any liquidity operations
    /// @param _tickUpper The higher tick
    /// @param _tickLower The lower tick
    function setTicks(int24 _tickUpper, int24 _tickLower) external onlyOwner{
        tickUpper = _tickUpper;
        tickLower = _tickLower;
        emit SetTicks(_tickUpper, _tickLower);
    }

    /// @dev helper to handle different types of payments depending on transactions.
    function pay(address token, address payer, address recipient, uint256 value) internal {
        if (token == WETH9 && address(this).balance >= value) {
            // pay with WETH9
            IWETH9(WETH9).deposit{value: value}(); // wrap only what is needed to pay
            bool res = IWETH9(WETH9).transfer(recipient, value);
            require(res);
        } else if (payer == address(this)) {
            // pay with tokens already in the contract (for the exact input multihop case)
            TransferHelper.safeTransfer(token, recipient, value);
        } else {
            // pull payment
            TransferHelper.safeTransferFrom(token, payer, recipient, value);
        }
    }

    /// @notice Called to `msg.sender` after minting liquidity to a position from IUniswapV3Pool#mint.
    /// @dev In the implementation you must pay the pool tokens owed for the minted liquidity.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// @param amount0Owed The amount of token0 due to the pool for the minted liquidity
    /// @param amount1Owed The amount of token1 due to the pool for the minted liquidity
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#mint call
    function uniswapV3MintCallback(uint256 amount0Owed, uint256 amount1Owed, bytes calldata data) external override {
        require(msg.sender == pool);
        MintCallbackData memory decoded = abi.decode(data, (MintCallbackData));

        if (amount0Owed > 0) {
            pay(decoded.poolKey.token0, decoded.payer, msg.sender, amount0Owed);
        } 

        if (amount1Owed > 0) {
            pay(decoded.poolKey.token1, decoded.payer, msg.sender, amount1Owed);
        }
    }

    /// @notice Mints liquidity to the Uniswap V3 Pool, and adds to the total supply
    /// of the LP Token. A fee is taken from each token before minting liquidity
    /// @param amount0Desired The desired amount of token0 added to the liquidity pool
    /// @param amount1Desired The desired amount of token1 added to the liquidity pool
    /// @return amount0 and amount1 - the amount eof each token used to provide liquidity
    function addLiquidity(uint256 amount0Desired, uint256 amount1Desired) external returns (uint256 amount0 , uint256 amount1) {
        uint128 liquidity;
        IFeeHelper feeHelper = IFeeHelper(IUnicryptUniV3LPFactory(owner()).getFeeHelperAddress());

        uint256 amount0Fee = FullMath.mulDiv(amount0Desired, feeHelper.getFee(), feeHelper.getFeeDenominator());
        uint256 amount1Fee = FullMath.mulDiv(amount1Desired, feeHelper.getFee(), feeHelper.getFeeDenominator());
        uint256 amount0AfterFees = amount0Desired - amount0Fee;
        uint256 amount1AfterFees = amount1Desired - amount1Fee;

        
        address lpTokenHelper = IUnicryptUniV3LPFactory(owner()).getLPTokenHelperAddress();

        (bool success0, bytes memory result0) = lpTokenHelper.delegatecall(abi.encodeWithSignature("handleLiquidity(uint256,uint256,uint256,uint256)", amount0Desired, amount1Desired, amount0AfterFees, amount1AfterFees));

        if (!success0) {
            // Next 5 lines from https://ethereum.stackexchange.com/a/83577
            if (result0.length < 68) revert();
            revert(abi.decode(result0, (string)));
        }
        (liquidity) = abi.decode(result0, (uint128));


        IUniswapV3Pool poolContract = IUniswapV3Pool(pool);
        (amount0, amount1) = poolContract.mint(address(this), tickLower, tickUpper, liquidity, abi.encode(MintCallbackData({poolKey: poolKey, payer: msg.sender})));
        require(amount0 + amount0Fee <= amount0Desired);
        require(amount1 + amount1Fee <= amount1Desired);
        (bool success1, bytes memory result1) = lpTokenHelper.delegatecall(abi.encodeWithSignature("finalizeLiquidity(uint128,uint256,uint256,uint256,uint256)", liquidity, amount0, amount1, amount0Fee, amount1Fee));
        if (!success1) {
            // Next 5 lines from https://ethereum.stackexchange.com/a/83577
            if (result1.length < 68) revert();
            revert(abi.decode(result1, (string)));
        }
    }

    /// @notice Removes liquidity from the Uniswap V3 Pool, and burns the total supply
    /// of the LP Token, sends the owed tokens to the msg.sender
    /// @param _desiredLiquidity The desired amount of liquidity to remove
    /// @return amount0 and amount1 - the amount eof each token removed
    function removeLiquidity(uint256 _desiredLiquidity) external payable returns (uint256 amount0 , uint256 amount1) {
        IUnicryptUniV3LPFactory factory = IUnicryptUniV3LPFactory(owner());
        address lpTokenHelper = factory.getLPTokenHelperAddress();
        (bool success, bytes memory result) = lpTokenHelper.delegatecall(abi.encodeWithSignature("getActualLiquidity(uint256)", _desiredLiquidity));
        if (!success) {
            // Next 5 lines from https://ethereum.stackexchange.com/a/83577
            if (result.length < 68) revert();
            revert(abi.decode(result, (string)));
        }
        (uint128 actualLiquidity) = abi.decode(result, (uint128));
        IUniswapV3Pool poolContract = IUniswapV3Pool(pool);
        (amount0, amount1) = poolContract.burn(tickLower, tickUpper, actualLiquidity);
        (bool success2, bytes memory result2) = lpTokenHelper.delegatecall(abi.encodeWithSignature("removeLiquidity(uint256,uint128,uint256,uint256)", _desiredLiquidity, actualLiquidity, amount0, amount1));
        if (!success2) {
            // Next 5 lines from https://ethereum.stackexchange.com/a/83577
            if (result2.length < 68) revert();
            revert(abi.decode(result2, (string)));
        }
    }
    /// @notice Collects tokens owed from the liquidity pool and sends back to the LP Token
    /// @dev the LP Token receives the fees, then mints them back into the pool. 
    /// @param amount0Max The maximum amount of token0 to collect from the liquidity pool
    /// @param amount1Max The maximum amount of token1 to collect from the liquidity pool
    /// @return amount0 and amount1 - the amount of each token collected
    function collect(uint128 amount0Max, uint128 amount1Max) external returns (uint256 amount0, uint256 amount1) {
        IUnicryptUniV3LPFactory factory = IUnicryptUniV3LPFactory(owner());
        address lpTokenHelper = factory.getLPTokenHelperAddress();
        (bool success, bytes memory result) = lpTokenHelper.delegatecall(abi.encodeWithSignature("collect(uint128,uint128)", amount0Max, amount1Max));
        if (!success) {
            // Next 5 lines from https://ethereum.stackexchange.com/a/83577
            if (result.length < 68) revert();

            revert(abi.decode(result, (string)));
        }
        uint128 liquidity;
        (amount0, amount1, liquidity) = abi.decode(result, (uint256, uint256, uint128));
        if(liquidity != 0) {
            IUniswapV3Pool poolContract = IUniswapV3Pool(pool);
            (uint256 amount0Added, uint256 amount1Added) = poolContract.mint(address(this), tickLower, tickUpper, liquidity, abi.encode(MintCallbackData({poolKey: poolKey, payer: address(this)})));
            (bool success2, bytes memory result2) = lpTokenHelper.delegatecall(abi.encodeWithSignature("mintCollected(uint128)", liquidity));
            if (!success2) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                if (result2.length < 68) revert();

                revert(abi.decode(result2, (string)));
            }
            emit Mint(address(this), tickLower, tickUpper, liquidity, amount0Added, amount1Added);  
        }
    }

    /// @notice Sets the initial price for the pool. Can only be called once.
    /// @param _sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initializePool(uint160 _sqrtPriceX96) external {
        IUnicryptUniV3LPFactory factory = IUnicryptUniV3LPFactory(owner());
        address lpTokenHelper = factory.getLPTokenHelperAddress();
        (bool success, bytes memory result) = lpTokenHelper.delegatecall(abi.encodeWithSignature("initializePool(uint160)", _sqrtPriceX96));
        if (!success) {
            // Next 5 lines from https://ethereum.stackexchange.com/a/83577
            if (result.length < 68) revert();
            assembly {
                result := add(result, 0x04)
            }
            revert(abi.decode(result, (string)));
        }
    }

    // @notice Multicall to mint and collect
    /// @param _amount0Desired The desired amount of token0 added to the liquidity pool
    /// @param _amount1Desired The desired amount of token1 added to the liquidity pool
    /// @param _amount0Max The maximum amount of token0 to collect from the liquidity pool
    /// @param _amount1Max The maximum amount of token1 to collect from the liquidity pool
    /// @return results
    function addMulticall(uint256 _amount0Desired, uint256 _amount1Desired, uint128 _amount0Max, uint128 _amount1Max) external payable returns (bytes[] memory results){
        results = new bytes[](2);
        (bool successAdd, bytes memory resultAdd) = address(this).delegatecall(abi.encodeWithSignature("addLiquidity(uint256,uint256)", _amount0Desired, _amount1Desired));
        (bool successCollect, bytes memory resultCollect) = address(this).delegatecall(abi.encodeWithSignature("collect(uint128,uint128)", _amount0Max, _amount1Max));
        if (!successAdd) {
            // Next 5 lines from https://ethereum.stackexchange.com/a/83577
            if (resultAdd.length < 68) revert();
            assembly {
                resultAdd := add(resultAdd, 0x04)
            }
            revert(abi.decode(resultAdd, (string)));
        }
        if (!successCollect) {
            // Next 5 lines from https://ethereum.stackexchange.com/a/83577
            if (resultCollect.length < 68) revert();
            assembly {
                resultCollect := add(resultCollect, 0x04)
            }
            revert(abi.decode(resultCollect, (string)));
        }
        results[0] = resultAdd;
        results[1] = resultCollect;
    }

    // @notice Multicall to remove and collect
    /// @param _desiredLiquidity The desired amount of liquidity to remove
    /// @param _amount0Max The maximum amount of token0 to collect from the liquidity pool
    /// @param _amount1Max The maximum amount of token1 to collect from the liquidity pool
    /// @return results
    function removeMulticall(uint256 _desiredLiquidity, uint128 _amount0Max, uint128 _amount1Max) external payable returns (bytes[] memory results){
        results = new bytes[](2);
        (bool successCollect, bytes memory resultCollect) = address(this).delegatecall(abi.encodeWithSignature("collect(uint128,uint128)", _amount0Max, _amount1Max));
        (bool successRemove, bytes memory resultRemove) = address(this).delegatecall(abi.encodeWithSignature("removeLiquidity(uint256)", _desiredLiquidity));
        if (!successRemove) {
            // Next 5 lines from https://ethereum.stackexchange.com/a/83577
            if (resultRemove.length < 68) revert();
            assembly {
                resultRemove := add(resultRemove, 0x04)
            }
            revert(abi.decode(resultRemove, (string)));
        }
        if (!successCollect) {
            // Next 5 lines from https://ethereum.stackexchange.com/a/83577
            if (resultCollect.length < 68) revert();
            assembly {
                resultCollect := add(resultCollect, 0x04)
            }
            revert(abi.decode(resultCollect, (string)));
        }
        results[0] = resultRemove;
        results[1] = resultCollect;
    }
}