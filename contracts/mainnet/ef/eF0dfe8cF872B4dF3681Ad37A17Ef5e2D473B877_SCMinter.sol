// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ownable.sol";
import "IERC20.sol";

import "StableSwapGuard.sol";
import "GeminonInfrastructure.sol";
import "VariableFees.sol";

import "IGeminonOracle.sol";
import "IGenesisLiquidityPool.sol";

import "IERC20Indexed.sol";
import "TradePausable.sol";


/**
* @title SCMinter
* @author Geminon Protocol
* @notice Allows users to mint and redeem stablecoins using GEX tokens and swap stablecoins.
*/
contract SCMinter is Ownable, TradePausable, GeminonInfrastructure, StableSwapGuard, VariableFees {
    
    address public immutable USDI;
    
    uint32 public baseMintFee;
    uint32 public baseRedeemFee;
    
    address[] public stablecoins;
    
    mapping(address => bool) public validTokens;
    mapping(address => bool) public mintedTokens;
    mapping(address => uint32) public baseSwapFees;
    

    /// @dev Checks if token is a valid mintable token
    modifier onlyValidTokens(address token) {
        require(validTokens[token], 'Invalid token');
        _;
    }

    /// @dev Checks if token is a valid redeemable token
    modifier onlyMintedTokens(address token) {
        require(mintedTokens[token], 'Token not minted');
        _;
    }


    constructor(address gex, address usdi, address oracle) {
        GEX = gex;
        USDI = usdi;
        
        oracleGeminon = oracle;
        oracleAge = uint64(block.timestamp);

        baseMintFee = 1000;
        baseRedeemFee = 2000;
        
        stablecoins.push(usdi);
        validTokens[usdi] = true;
        mintedTokens[usdi] = true;
        baseSwapFees[usdi] = 3000;
    }
    
    
    
    /// @dev Adds stablecoin to the list of valid tokens
    function addStablecoin(address token, uint32 swapFee) external onlyOwner {
        require(token != address(0)); // dev: Address 0
        stablecoins.push(token);
        validTokens[token] = true;
        mintedTokens[token] = true;
        setSwapFee(token, swapFee);
    }

    /// @dev Removes stablecoin from the list of valid tokens
    /// @notice Stablecoins can't be removed from the list of minted tokens
    /// to protect users: they can always be redeem once created.
    function removeStablecoin(address token) external onlyOwner onlyValidTokens(token) {
        require(token != USDI); // dev: Cant remove USDI
        validTokens[token] = false;
    }



    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // +                       PARAMETERS CHANGES                           +
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    /// @dev Changes the value of the base mint fee
    /// Max allowed value is 0.5% 
    function setMintFee(uint32 value) external onlyOwner {
        require(value <= 5000); // dev: Max mint fee
        baseMintFee = value;
    }

    /// @dev Changes the value of the base redeem fee
    /// Max allowed value is 0.6%
    function setRedeemFee(uint32 value) external onlyOwner {
        require(value <= 6000); // dev: Max redeem fee
        baseRedeemFee = value;
    }

    /// @dev Changes the value of the base swap fee of the stablecoin
    /// Max allowed value is 1.2%
    function setSwapFee(address stable, uint32 value) public onlyOwner onlyValidTokens(stable) {
        require(value <= 12000); // dev: Max swap fee
        require(value >= baseMintFee + baseRedeemFee); // dev: Low swap fee
        baseSwapFees[stable] = value;
    }
    
    
    
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // +                          USER FUNCTIONS                            +
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    /// @notice Mints a stablecoin from the list of valid tokens using GEX as payment
    function mintStablecoin(address stablecoin, uint256 amountInGEX) 
        external 
        whenMintNotPaused 
        onlyValidTokens(stablecoin) 
        returns(uint256)
    {    
        uint256 amountOutStablecoin;

        uint256 usdPrice = IERC20Indexed(stablecoin).getOrUpdatePegValue();

        if (stablecoin == USDI || usdPrice == 1e18) {
            uint256 amountFeeGEX_ = amountFeeGEX(amountInGEX, baseMintFee);
            amountOutStablecoin = amountMint(stablecoin, amountInGEX - amountFeeGEX_);
        } else {
            amountOutStablecoin = amountMint(stablecoin, amountInGEX);
            _updatePriceRecord(stablecoin, usdPrice, amountOutStablecoin, true);
            amountOutStablecoin -= amountFeeMint(stablecoin, amountOutStablecoin, usdPrice);
        }
        
        if (amountOutStablecoin > IERC20Indexed(stablecoin).balanceOf(address(this)) / 10)
            _addReserves(amountOutStablecoin, stablecoin);

        _balanceFees += (amountInGEX * baseMintFee) / 1e6;
        
        IERC20(GEX).transferFrom(msg.sender, address(this), amountInGEX);
        IERC20(stablecoin).transfer(msg.sender, amountOutStablecoin);

        return amountOutStablecoin;
    }

    
    /// @notice Redeems a stablecoin from the list of minted tokens receiving GEX in exchange
    function redeemStablecoin(address stablecoin, uint256 amountInStablecoin) 
        external 
        onlyMintedTokens(stablecoin) 
        returns(uint256) 
    {
        uint256 amountFeeGEX_;
        
        uint256 usdPrice = IERC20Indexed(stablecoin).getOrUpdatePegValue();
        
        uint256 amountOutGEX = amountRedeem(stablecoin, amountInStablecoin);
        if (stablecoin == USDI || usdPrice == 1e18) {
            amountFeeGEX_ = amountFeeGEX(amountOutGEX, baseRedeemFee);
        } else {
            _updatePriceRecord(stablecoin, usdPrice, amountInStablecoin, false);
            uint256 amountFeeStablecoin = amountFeeRedeem(stablecoin, amountInStablecoin, usdPrice);
            amountFeeGEX_ = amountRedeem(stablecoin, amountFeeStablecoin);
        }

        uint256 balanceGEX = IERC20(GEX).balanceOf(address(this)) - _balanceFees;
        if(amountOutGEX > balanceGEX) 
            _requestBailoutFromPool();
        require(amountOutGEX <= balanceGEX, "Amount too high");
        
        _balanceFees += (amountOutGEX * baseRedeemFee) / 1e6;
        
        amountOutGEX -= amountFeeGEX_;
        IERC20(stablecoin).transferFrom(msg.sender, address(this), amountInStablecoin);
        IERC20(GEX).transfer(msg.sender, amountOutGEX);

        return amountOutGEX;
    }


    /// @notice Swaps any pair of stablecoins without slippage. The fees generated go
    /// to the GEX holders.
    function stableSwap(address stableIn, address stableOut, uint256 amountIn) 
        external 
        whenMintNotPaused 
        onlyMintedTokens(stableIn) 
        onlyValidTokens(stableOut) 
        returns(uint256) 
    {
        uint256 usdPriceIn = IERC20Indexed(stableIn).getOrUpdatePegValue();
        uint256 usdPriceOut = IERC20Indexed(stableOut).getOrUpdatePegValue();

        uint256 amountOutStable = (amountIn * usdPriceIn) / usdPriceOut;

        if (stableIn != USDI && usdPriceIn != 1e18) 
            _updatePriceRecord(stableIn, usdPriceIn, amountIn, false);
        if (stableOut != USDI && usdPriceOut != 1e18) 
            _updatePriceRecord(stableOut, usdPriceOut, amountOutStable, true);

        amountOutStable -= amountFeeSwap(
            stableIn, 
            stableOut, 
            usdPriceIn, 
            usdPriceOut, 
            amountOutStable
        );
        
        if (amountOutStable > IERC20Indexed(stableOut).balanceOf(address(this)) / 10)
            _addReserves(amountOutStable, stableOut);
        
        IERC20(stableIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(stableOut).transfer(msg.sender, amountOutStable);

        return amountOutStable;
    }



    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // +                        PROTOCOL FUNCTIONS                          +
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    /// @dev Pauses stablecoins mint. Redeems can not be paused.
    function pauseMint() external onlyOwner whenMintNotPaused {
        _pauseMint();
    }

    /// @dev Unpauses stablecoins mint. Can not unpause if migration has 
    /// been requested as those actions pause the minter as security measure.
    function unpauseMint() external onlyOwner whenMintPaused {
        require(!isMigrationRequested); // dev: migration requested
        _unpauseMint();
    }

    
    /// @dev Mints new supply of GEX to this contract
    function addReservesGEX(uint256 amount) external onlyOwner {
        IERC20Indexed(GEX).mint(address(this), amount);
    }

    /// @dev Mints stablecoins to this contract
    function addReserves(uint256 amount, address stablecoin) external onlyOwner onlyValidTokens(stablecoin) {
        _addReserves(amount, stablecoin);
    }

    /// @dev Burns stablecoins from this contract
    function burnReserves(uint256 amount, address stablecoin) external onlyOwner onlyMintedTokens(stablecoin) {
        IERC20Indexed(stablecoin).burn(address(this), amount);
    }


    /// @notice Transfer GEX tokens from a Genesis Liquidity Pool
    function requestBailoutFromPool() external onlyOwner returns(uint256) {
        return _requestBailoutFromPool();
    }

    

    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // +                     INFORMATIVE FUNCTIONS                          +
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    /// @notice Gets the GEX balance
    function getBalanceGEX() external view returns(uint256) {
        return IERC20(GEX).balanceOf(address(this)) - _balanceFees;
    }

    /// @notice Calculates the Total Value Circulating of the Geminon stablecoins in this blockchain
    function getTVC() external view returns(uint256) {
        uint256 value = 0;
        for (uint16 i=0; i<stablecoins.length; i++) {
            address sc = stablecoins[i];
            uint256 circulating = IERC20(sc).totalSupply() - IERC20(sc).balanceOf(address(this));
            value += (circulating * IERC20Indexed(sc).getPegValue()) / 1e18;
        }
        return value;
    }


    /// @notice Calculates the amount of the mint/redeem fee given the amount of GEX
    function amountFeeGEX(uint256 amountGEX, uint256 baseFee) public view returns(uint256 fee) {
        return (amountGEX * feeGEX(amountGEX, baseFee)) / 1e6;
    }

    /// @notice Calculates the amount of the mint fee for a given stablecoin amount
    function amountFeeMint(address stable, uint256 amountStable, uint256 usdPrice) public view returns(uint256) {
        return (amountStable * _feeStablecoin(stable, amountStable, usdPrice, baseMintFee, true)) / 1e6;
    }

    /// @notice Calculates the amount of the redeem fee for a given stablecoin amount
    function amountFeeRedeem(address stable, uint256 amountStable, uint256 usdPrice) public view returns(uint256) {
        return (amountStable * _feeStablecoin(stable, amountStable, usdPrice, baseRedeemFee, false)) / 1e6;
    }

    /// @notice Calculates the amount of the stableswap fee
    function amountFeeSwap(
        address stableIn, 
        address stableOut, 
        uint256 usdPriceIn, 
        uint256 usdPriceOut, 
        uint256 amountOut
    ) public view returns(uint256) {
        return (amountOut * feeSwap(stableIn, stableOut, usdPriceIn, usdPriceOut, amountOut)) / 1e6;
    }
    
    
    /// @notice Calculate the percentage of the fee to mint a stablecoin given the amount of stablecoin
    function feeStablecoinMint(address stable, uint256 amountStable) public view returns(uint256) {
        uint256 amountEqUSDI = amountUSDI(stable, amountStable);
        uint256 usdPrice = IERC20Indexed(stable).getPegValue();
        return _feeStablecoin(stable, amountEqUSDI, usdPrice, baseMintFee, true);
    }

    /// @notice Calculate the percentage of the fee to redeem a stablecoin given the amount of stablecoin
    function feeStablecoinRedeem(address stable, uint256 amountStable) public view returns(uint256) {
        uint256 amountEqUSDI = amountUSDI(stable, amountStable);
        uint256 usdPrice = IERC20Indexed(stable).getPegValue();
        return _feeStablecoin(stable, amountEqUSDI, usdPrice, baseRedeemFee, false);
    }

    /// @notice Returns the equivalent amount of USDI of a given stablecoin amount
    function amountUSDI(address stablecoin, uint256 amount) public view returns(uint256) {
        return (amount * IERC20Indexed(stablecoin).getPegValue()) / IERC20Indexed(USDI).getPegValue();
    }

    /// @notice Gives all mintStablecoin info at once. Reduces front-end RPC calls.
    /// All return values have 18 decimals except fee that has 6.
    function getMintInfo(uint256 inGEXAmount, address stablecoin) public view returns(
        uint256 gexPriceUSD,
        uint256 stablecoinPriceUSD, 
        uint256 fee,
        uint256 feeAmount,
        uint256 outStablecoinAmount
    ) {
        gexPriceUSD = IGeminonOracle(oracleGeminon).getSafePrice();
        stablecoinPriceUSD = IERC20Indexed(stablecoin).getPegValue();
        fee = feeGEX(inGEXAmount, baseMintFee);
        feeAmount = (inGEXAmount * fee) / 1e6;
        outStablecoinAmount = amountMint(stablecoin, inGEXAmount - feeAmount);
    }

    /// @notice Gives all redeemStablecoin info at once. Reduces front-end RPC calls.
    /// All return values have 18 decimals except fee that has 6.
    function getRedeemInfo(uint256 inStablecoinAmount, address stablecoin) public view returns(
        uint256 stablecoinPriceUSD, 
        uint256 gexPriceUSD,
        uint256 fee,
        uint256 feeAmount,
        uint256 outGEXAmount
    ) {
        stablecoinPriceUSD = IERC20Indexed(stablecoin).getPegValue();
        gexPriceUSD = IGeminonOracle(oracleGeminon).getSafePrice();
        fee = feeStablecoinRedeem(stablecoin, inStablecoinAmount);
        feeAmount = (inStablecoinAmount * fee) / 1e6;
        outGEXAmount = amountRedeem(stablecoin, inStablecoinAmount - feeAmount);
    }

    /// @notice Gives all stableSwap info at once. Reduces front-end RPC calls.
    /// All return values have 18 decimals except fee that has 6.
    function getStableSwapInfo(uint256 inAmount, address stableIn, address stableOut) public view returns(
        uint256 inStablecoinPriceUSD,
        uint256 outStablecoinPriceUSD, 
        uint256 quoteS2S1,
        uint256 fee,
        uint256 feeAmount,
        uint256 outStablecoinAmount
    ) {
        inStablecoinPriceUSD = IERC20Indexed(stableIn).getPegValue();
        outStablecoinPriceUSD = IERC20Indexed(stableOut).getPegValue();
        quoteS2S1 = (outStablecoinPriceUSD * 1e18) / inStablecoinPriceUSD;
        outStablecoinAmount = (inAmount * inStablecoinPriceUSD) / outStablecoinPriceUSD;
        fee = feeSwap(stableIn, stableOut, inStablecoinPriceUSD, outStablecoinPriceUSD, outStablecoinAmount);
        feeAmount = (outStablecoinAmount * fee) / 1e6;
        outStablecoinAmount -= feeAmount;
    }



    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // +                         CORE FUNCTIONS                             +
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    /// @dev Calculates the amount ot stablecoin minted given a GEX amount
    function amountMint(address stablecoin, uint256 amountGEX) public view returns(uint256) {
        return (amountGEX * getSafeMintRatio(stablecoin)) / 1e18;
    }

    /// @dev Calculates the amount of GEX to redeem a given stablecoin and amount
    function amountRedeem(address stablecoin, uint256 amountStablecoin) public view returns(uint256) {
        return (amountStablecoin * getSafeRedeemRatio(stablecoin)) / 1e18;
    }
    
    /// @dev Calculates the quote of the GEX token on the given stablecoin
    function getSafeMintRatio(address stablecoin) public view returns(uint256) {
        uint256 priceGEX = IGeminonOracle(oracleGeminon).getSafePrice();
        uint256 priceIndex = IERC20Indexed(stablecoin).getPegValue();
        return (priceGEX * 1e18) / priceIndex;
    }

    /// @dev Calculates the quote of the given stablecoin on GEX tokens
    function getSafeRedeemRatio(address stablecoin) public view returns(uint256) {
        uint256 priceGEX = IGeminonOracle(oracleGeminon).getSafePrice();
        uint256 priceIndex = IERC20Indexed(stablecoin).getPegValue();
        return (priceIndex * 1e18) / priceGEX;
    }

    
    /// @dev Calculate the percentage of the fee given a GEX amount with 6 decimals. 
    function feeGEX(uint256 amountGEX, uint256 baseFee) public view returns(uint256 fee) {
        if (msg.sender == arbitrageur && arbitrageur != address(0)) return 0;
        uint256 usdiAmount = (amountGEX * getSafeMintRatio(USDI)) / 1e18;
        return _variableFee(usdiAmount, baseFee);
    }

    /// @dev Calculates the percentage of the stableswap fee with 6 decimals. 
    function feeSwap(
        address stableIn, 
        address stableOut, 
        uint256 usdPriceIn, 
        uint256 usdPriceOut, 
        uint256 amountOut
    ) public view returns(uint256) {
        uint256 amountEqUSDI = amountUSDI(stableOut, amountOut);
        uint256 feeStableIn = _feeStablecoin(stableIn, amountEqUSDI, usdPriceIn, baseSwapFees[stableIn], false);
        uint256 feeStableOut = _feeStablecoin(stableOut, amountEqUSDI, usdPriceOut, baseSwapFees[stableOut], true);
        return feeStableIn > feeStableOut ? feeStableIn : feeStableOut;
    }


    /// @dev Mints new supply of the stablecoin to this contract
    function _addReserves(uint256 amount, address stablecoin) private {
        IERC20Indexed(stablecoin).mint(address(this), amount);
    }

    /// @dev Transfers GEX tokens from a Genesis Liquidity Pool to this contract
    function _requestBailoutFromPool() private returns(uint256) {
        address pool = _biggestPool();
        uint256 bailoutAmount = IGenesisLiquidityPool(pool).bailoutMinter();
        IERC20(GEX).transferFrom(pool, address(this), bailoutAmount);
        return bailoutAmount;
    }
    

    /// @dev Calculates the safety fee of the stablecoin with 6 decimals. 
    function _feeStablecoin(
        address stable, 
        uint256 amountEqUSDI, 
        uint256 usdPrice, 
        uint256 baseFee, 
        bool isOpLong
    ) private view returns(uint256) {     
        if (msg.sender == arbitrageur && arbitrageur != address(0)) return 0;

        if (stable != USDI && usdPrice != 1e18) {
            uint256 safetyFee = _safetyFeeStablecoin(stable, usdPrice, isOpLong);
            baseFee = safetyFee > baseFee ? safetyFee : baseFee;
        }
        return _variableFee(amountEqUSDI, baseFee);
    }

    /// @dev Returns the address of the GLP with the higher balance of GEX
    function _biggestPool() private view returns(address) {
        return IGeminonOracle(oracleGeminon).getHighestGEXPool();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/**
* @title StableSwapGuard
* @author Geminon Protocol
* @notice Calculates safety fees to make oracle front-running exploit unprofitable.
*/
contract StableSwapGuard {

    struct priceRecord {
        uint64 lastTimestamp;
        uint32 weightedPrice;
        uint256 volume;
    }

    mapping(address => priceRecord) public priceRecordsLongs;
    mapping(address => priceRecord) public priceRecordsShorts;
    
    
    /// @dev Updates the price record of the stablecoin for the given trade direction
    function _updatePriceRecord(address stable, uint256 usdPrice, uint256 amount, bool isOpLong) internal {
        if (isOpLong) {
            priceRecord memory record = priceRecordsLongs[stable];
            priceRecordsLongs[stable] = _modifyRecord(record, usdPrice, amount);
        } else {
            priceRecord memory record = priceRecordsShorts[stable];
            priceRecordsShorts[stable] = _modifyRecord(record, usdPrice, amount);
        }
    }

    /// @dev Calculates the minimum fee rate to avoid front-running exploits for a pair of stablecoins (6 decimals)
    function _safetyFeeStablecoins(
        address stableIn, 
        address stableOut, 
        uint256 usdPriceIn, 
        uint256 usdPriceOut
    ) internal view returns(uint256) {
        uint256 fee1 = _safetyFeeStablecoin(stableIn, usdPriceIn, false);
        uint256 fee2 = _safetyFeeStablecoin(stableOut, usdPriceOut, true);
        return fee1 > fee2 ? fee1 : fee2;
    }
    
    /// @dev Calculates the minimum fee rate to avoid front-running exploits for a single stablecoin (6 decimals)
    function _safetyFeeStablecoin(address stable, uint256 usdPrice, bool isOpLong) internal view returns(uint256) {
        return _volatility(stable, usdPrice, isOpLong) / 1e12;
    }

    
    /// @dev Calculates a weighted mean of the price for the last 5 minutes
    function _modifyRecord(
        priceRecord memory record, 
        uint256 usdPrice, 
        uint256 amount
    ) private view returns(priceRecord memory) {
        uint64 timestamp;
        uint32 weightedPrice;
        uint256 volume;

        if (block.timestamp - record.lastTimestamp > 300) {
            weightedPrice = uint32(usdPrice/1e12);
            volume = amount;
        } else {
            uint256 w = (amount * 1e6) / (amount + record.volume);
            weightedPrice = uint32((w*usdPrice/1e12 + (1e6-w)*record.weightedPrice) / 1e6);
            volume = record.volume + amount;
        }
        timestamp = uint64(block.timestamp);

        return priceRecord(timestamp, weightedPrice, volume);
    }


    /// @dev Calculates the price variation of the stablecoin for a given trade direction (18 decimals)
    function _volatility(address stable, uint256 usdPrice, bool isOpLong) private view returns(uint256) {
        uint32 weightedPrice;
        
        if (isOpLong)
            weightedPrice = priceRecordsLongs[stable].weightedPrice;
        else
            weightedPrice = priceRecordsShorts[stable].weightedPrice;
        
        return _absRet(usdPrice, uint256(weightedPrice)*1e12);
    }

    /// @dev Calculates the absolute return of two prices
    function _absRet(uint256 price, uint256 basePrice) private pure returns(uint256) {
        if (basePrice == 0) 
            return 0;
            
        if (price >= basePrice)
            return ((price - basePrice) * 1e18) / basePrice;
        else
            return ((basePrice - price) * 1e18) / basePrice;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ownable.sol";

import "SCMinterMigration.sol";
import "IGeminonOracle.sol";
import "TimeLocks.sol";



contract GeminonInfrastructure is Ownable, TimeLocks, SCMinterMigration {
    
    address public arbitrageur;


    /// @dev Set the address of the arbitrage operator.
    function setArbitrageur(address arbitrageur_) external onlyOwner {
        arbitrageur = arbitrageur_;
    }


    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // +             SMART CONTRACTS INFRASTRUCTURE CHANGES                 +
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    
    /// @dev Apply the change in the GEX oracle address proposed using
    /// the requestAddressChange() function. This function can only be called
    /// 30 days after the request of the change.
    function applyOracleChange() external onlyOwner {
        require(!isMigrationRequested); // dev: migration requested
        require(changeRequests[oracleGeminon].changeRequested); // dev: Not requested
        require(block.timestamp - changeRequests[oracleGeminon].timestampRequest > 30 days); // dev: Time elapsed
        require(changeRequests[oracleGeminon].newAddressRequested != address(0)); // dev: Address zero

        changeRequests[oracleGeminon].changeRequested = false;
        oracleGeminon = changeRequests[oracleGeminon].newAddressRequested;
        oracleAge = uint64(block.timestamp);
    }
    

    /// @notice Cancels any pending request for changes in the smart contract
    function cancelChangeRequests() external onlyOwner {
        
        if (changeRequests[address(0)].changeRequested)
            changeRequests[address(0)].changeRequested = false;
        
        if (changeRequests[oracleGeminon].changeRequested)
            changeRequests[oracleGeminon].changeRequested = false;
        
        if (isMigrationRequested) {
            isMigrationRequested = false;
            IGeminonOracle(oracleGeminon).cancelMigration();
        }        
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ownable.sol";
import "IERC20.sol";

import "CollectibleFees.sol";
import "ISCMinter.sol";
import "IGeminonOracle.sol";

import "TimeLocks.sol";
import "TradePausable.sol";


contract SCMinterMigration is Ownable, TradePausable, TimeLocks, CollectibleFees {
    
    uint64 public oracleAge;

    bool public isMigrationRequested;
    uint64 public timestampMigrationRequest;
    address public migrationMinter;



    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // +                         MINTER MIGRATION                           +
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    /// @dev Register a request to migrate the minter.
    /// Begins a timelock of 7 days before enabling the migration.
    /// requestAddressChange() had to be made in this contract and in the
    /// oracle contract 7 days before this request.
    function requestMigration(address newMinter) external onlyOwner {
        require(changeRequests[address(this)].changeRequested); // dev: Not requested
        require(block.timestamp - changeRequests[address(this)].timestampRequest > 7 days); // dev: Time elapsed
        require(changeRequests[address(this)].newAddressRequested == newMinter); // dev: Address not zero
        require(oracleGeminon != address(0)); // dev: oracle is not set

        changeRequests[address(this)].changeRequested = false;
        changeRequests[address(this)].newAddressRequested = address(this);
        changeRequests[address(this)].timestampRequest = type(uint64).max;
        
        isMigrationRequested = true;
        migrationMinter = newMinter;
        timestampMigrationRequest = uint64(block.timestamp);

        IGeminonOracle(oracleGeminon).requestMigrateMinter(newMinter);
        _pauseMint();
    }

    /// @dev Transfer all GEX in the minter to the new minter.
    /// Removes the minter from the Geminon Oracle.
    function migrateMinter() external onlyOwner whenMintPaused {
        require(isMigrationRequested); // dev: migration not requested
        require(oracleGeminon != address(0)); // dev: oracle is not set
        require(IGeminonOracle(oracleGeminon).isMigratingMinter()); // dev: migration not requested
        require(block.timestamp - timestampMigrationRequest > 15 days); // dev: timelock
        
        uint256 amountGEX = IERC20(GEX).balanceOf(address(this)) - _balanceFees;
        
        isMigrationRequested = false;

        IERC20(GEX).approve(migrationMinter, amountGEX);

        ISCMinter(migrationMinter).receiveMigration(amountGEX);
        
        IGeminonOracle(oracleGeminon).setMinterMigrationDone();
    }

    /// @dev Receive the funds of the previous minter that is migrating.
    function receiveMigration(uint256 amountGEX) external {
        require(oracleGeminon != address(0)); // dev: oracle is not set
        require(IGeminonOracle(oracleGeminon).scMinter() == msg.sender); // dev: sender is not pool
        require(IGeminonOracle(oracleGeminon).isMigratingMinter()); // dev: migration not requested

        require(IERC20(GEX).transferFrom(msg.sender, address(this), amountGEX));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IERC20.sol";
import "Ownable.sol";

import "Geminon.sol";


/**
* @title CollectibleFees
* @author Geminon Protocol
* @notice Allows owner of the contract to collect fees in GEX tokens
*/
contract CollectibleFees is Ownable, Geminon {
    
    address private _feesCollector;
    uint256 internal _balanceFees;
    
    
    /// @dev Set the address of the fees collector.
    function setCollector(address feesCollector) external onlyOwner {
        _feesCollector = feesCollector;
    }

    /// @dev Collects the fees generated by this contract
    function collectFees() external returns(uint256) {
        require(_feesCollector != address(0)); // dev: collector not set
        require(msg.sender == _feesCollector); // dev: invalid caller address
        require(_balanceFees > 0); // dev: Nothing to collect
        
        uint256 feesCollected = _balanceFees;
        _balanceFees = 0;
        
        require(IERC20(GEX).transfer(_feesCollector, feesCollected));
        return feesCollected;
    }  
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract Geminon {
    address public GEX;
    address public oracleGeminon;
    uint256 internal _balanceGEX;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IGeminon.sol";
import "ICollectibleFees.sol";
import "IGeminonInfrastructure.sol";
import "ISCMinterMigration.sol";


interface ISCMinter is 
    IGeminon, 
    ICollectibleFees, 
    ISCMinterMigration, 
    IGeminonInfrastructure 
{

    // +++++++++++++++++++  PUBLIC STATE VARIABLES  +++++++++++++++++++++++++
    function USDI() external view returns(address);  
    function baseMintFee() external view returns(uint32);
    function baseRedeemFee() external view returns(uint32);
    function stablecoins(uint) external view returns(address);
    function validTokens(address) external view returns(bool);
    function mintedTokens(address) external view returns(bool);
    function baseSwapFees(address) external view returns(uint32);
    
    
    // ++++++++++++++++++++++++  INITIALIZATION  ++++++++++++++++++++++++++++
    function addStablecoin(address token, uint32 swapFee) external;
    function removeStablecoin(address token) external;

    // ++++++++++++++++++++++++++  PARAMETERS  +++++++++++++++++++++++++++++
    function setMintFee(uint32 value) external;
    function setRedeemFee(uint32 value) external;
    function setSwapFee(address stable, uint32 value) external;


    // ++++++++++++++++++++++++  USER FUNCTIONS  ++++++++++++++++++++++++++++
    function mintStablecoin(address stablecoin, uint256 inAmountGEX) external returns(uint256);
    function redeemStablecoin(address stablecoin, uint256 inAmountStablecoin) external returns(uint256);
    function stableSwap(address stableIn, address stableOut, uint256 amountIn) external returns(uint256);
    

    // ++++++++++++++++++++++  PROTOCOL FUNCTIONS  ++++++++++++++++++++++++++
    function pauseMint() external;
    function unpauseMint() external;    
    function addReservesGEX(uint256 amount) external;
    function addReserves(uint256 amount, address stablecoin) external;
    function burnReserves(uint256 amount, address stablecoin) external;
    function requestBailoutFromPool() external returns(uint256);
    
    
    // +++++++++++++++++++++  INFORMATIVE FUNCTIONS  ++++++++++++++++++++++++

    function getBalanceGEX() external view returns(uint256);
    function getTVC() external view returns(uint256);

    function amountFeeGEX(uint256 amountGEX, uint256 baseFee) external view returns(uint256 fee);
    function amountFeeMint(address stable, uint256 amountStable, uint256 usdPrice) external view returns(uint256);
    function amountFeeRedeem(address stable, uint256 amountStable, uint256 usdPrice) external view returns(uint256);
    function amountFeeSwap(
        address stableIn, 
        address stableOut, 
        uint256 usdPriceIn, 
        uint256 usdPriceOut, 
        uint256 amountOut
    ) external view returns(uint256);
    
    function feeStablecoinMint(address stable, uint256 amountStable) external view returns(uint256);
    function feeStablecoinRedeem(address stable, uint256 amountStable) external view returns(uint256);

    function amountUSDI(address stablecoin, uint256 amount) external view returns(uint256);
    function getMintInfo(uint256 inGEXAmount, address stablecoin) external view returns(
        uint256 gexPriceUSD,
        uint256 stablecoinPriceUSD, 
        uint256 fee,
        uint256 feeAmount,
        uint256 outStablecoinAmount
    );
    function getRedeemInfo(uint256 inStablecoinAmount, address stablecoin) external view returns(
        uint256 stablecoinPriceUSD, 
        uint256 gexPriceUSD,
        uint256 fee,
        uint256 feeAmount,
        uint256 outGEXAmount
    );
    function getStableSwapInfo(uint256 inAmount, address stableIn, address stableOut) external view returns(
        uint256 inStablecoinPriceUSD,
        uint256 outStablecoinPriceUSD, 
        uint256 quoteS2S1,
        uint256 fee,
        uint256 feeAmount,
        uint256 outStablecoinAmount
    );

    function amountMint(address stablecoin, uint256 amountGEX) external view returns(uint256);
    function amountRedeem(address stablecoin, uint256 amountStablecoin) external view returns(uint256);

    function getSafeMintRatio(address stablecoin) external view returns(uint256);
    function getSafeRedeemRatio(address stablecoin) external view returns(uint256);
    
    function feeGEX(uint256 amountGEX, uint256 baseFee) external view returns(uint256 fee);
    function feeSwap(
        address stableIn, 
        address stableOut, 
        uint256 usdPriceIn, 
        uint256 usdPriceOut, 
        uint256 amountOut
    ) external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IGeminon {
    function GEX() external view returns(address);
    function oracleGeminon() external view returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/**
* @title ICollectibleFees
* @author Geminon Protocol
* @notice Interface for smart contracts whose fees have
* to be collected by the FeeCollector contract.
*/
interface ICollectibleFees {
    function setCollector(address feesCollector) external;
    function collectFees() external returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IGeminonInfrastructure {
    function arbitrageur() external view returns(address);
    function setArbitrageur(address arbitrageur_) external;
    function applyOracleChange() external;
    function cancelChangeRequests() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/**
* @title ISCMinterMigration
* @author Geminon Protocol
* @notice Interface for SCMinter migration
*/
interface ISCMinterMigration {
    
    function oracleAge() external view returns(uint64);
    function isMigrationRequested() external view returns(bool);
    function timestampMigrationRequest() external view returns(uint64);
    function migrationMinter() external view returns(address);

    function requestMigration(address newMinter) external;
    function migrateMinter() external;
    function receiveMigration(uint256 amountGEX) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IGeminonOracle {

    // +++++++++++++++++++  PUBLIC STATE VARIABLES  +++++++++++++++++++++++++

    function isAnyPoolMigrating() external view returns(bool);
    function isAnyPoolRemoving() external view returns(bool);
    
    function scMinter() external view returns(address);
    function bridge() external view returns(address);
    function treasuryLender() external view returns(address);
    function feesCollector() external view returns(address);
    function pools(uint) external view returns(address);

    function ageSCMinter() external view returns(uint64);
    function ageBridge() external view returns(uint64);
    function ageTreasuryLender() external view returns(uint64);
    function ageFeesCollector() external view returns(uint64);
    
    function isMigratingMinter() external view returns(bool);
    function newMinter() external view returns(address);

    function isPool(address) external view returns(bool);
    function isMigratingPool(address) external view returns(bool);
    function isRemovingPool(address) external view returns(bool);
    function poolAge(address) external view returns(uint64);


    // ++++++++++++++++++++++++  INITIALIZATION  ++++++++++++++++++++++++++++

    function setSCMinter(address scMinter_) external;
    function setBridge(address bridge_) external;
    function setTreasuryLender(address lender) external;
    function setCollector(address feesCollector_) external;

    
    // ++++++++++++++++++++++++++  MIGRATIONS  ++++++++++++++++++++++++++++++

    function addPool(address newPool) external;
    function removePool(address pool) external;

    function requestMigratePool(address newPool) external;
    function setMigrationDone() external;
    function cancelMigration() external;

    function requestRemovePool() external;
    function setRemoveDone() external;
    function cancelRemove() external;
    
    function requestMigrateMinter(address newMinter) external;
    function setMinterMigrationDone() external;
    function cancelMinterMigration() external;


    // ++++++++++++++++++++  INFORMATIVE FUNCTIONS  +++++++++++++++++++++++++

    function getTotalCollatValue() external view returns(uint256);
    function getPoolCollatWeight(address pool) external view returns(uint256);
    
    function getSafePrice() external view returns(uint256);
    function getLastPrice() external view returns(uint256);
    
    function getMeanVolume() external view returns(uint256);
    function getLastVolume() external view returns(uint256);

    function getTotalMintedGEX() external view returns(uint256);
    function getExternalMintedGEX() external view returns(uint256);
    function getLockedAmountGEX() external view returns(uint256);
    function getHighestGEXPool() external view returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ownable.sol";


/**
* @title TimeLocks
* @author Geminon Protocol
* @dev Utility to protect smart contracts against instant changes
* on critical infrastructure. Sets a two step procedure to change
* the address of a smart contract that is used by another contract.
*/
contract TimeLocks is Ownable {

    struct ContractChangeRequest {
        bool changeRequested;
        uint64 timestampRequest;
        address newAddressRequested;
    }

    mapping(address => ContractChangeRequest) public changeRequests;

    
    /// @dev Creates a request to change the address of a smart contract.
    function requestAddressChange(address actualContract, address newContract) 
        external 
        onlyOwner 
    {
        require(newContract != address(0)); // dev: address 0
        
        ContractChangeRequest memory changeRequest = 
            ContractChangeRequest({
                changeRequested: true, 
                timestampRequest: uint64(block.timestamp), 
                newAddressRequested: newContract
            });
        
        changeRequests[actualContract] = changeRequest;
    }

    /// @dev Creates a request to add a new address of a smart contract.
    function requestAddAddress(address newContract) external onlyOwner {
        require(newContract != address(0)); // dev: address 0

        ContractChangeRequest memory changeRequest = 
            ContractChangeRequest({
                changeRequested: true, 
                timestampRequest: uint64(block.timestamp), 
                newAddressRequested: newContract
            });
        
        changeRequests[address(0)] = changeRequest;
    }

    /// @dev Creates a request to remove the address of a smart contract.
    function requestRemoveAddress(address oldContract) external onlyOwner {
        require(oldContract != address(0)); // dev: address zero
        
        ContractChangeRequest memory changeRequest = 
            ContractChangeRequest({
                changeRequested: true, 
                timestampRequest: uint64(block.timestamp), 
                newAddressRequested: address(0)
            });
        
        changeRequests[oldContract] = changeRequest;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenMintNotPaused`, `whenMintPaused`, `whenRedeemNotPaused` 
 * and `whenRedeemPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract TradePausable {

    bool private _mintPaused;
    bool private _redeemPaused;


    /// @dev Emitted when the mint pause is triggered by `account`.
    event MintPaused(address account);

    /// @dev Emitted when the redeem pause is triggered by `account`.
    event RedeemPaused(address account);

    /// @dev Emitted when the mint pause is lifted by `account`.
    event MintUnpaused(address account);

    /// @dev Emitted when the redeem pause is lifted by `account`.
    event RedeemUnpaused(address account);


    /// @dev Modifier to make a function callable only when the contract is not paused.
    modifier whenMintNotPaused() {
        _requireMintNotPaused();
        _;
    }

    /// @dev Modifier to make a function callable only when the contract is paused.
    modifier whenMintPaused() {
        _requireMintPaused();
        _;
    }

    /// @dev Modifier to make a function callable only when the contract is not paused.
    modifier whenRedeemNotPaused() {
        _requireRedeemNotPaused();
        _;
    }

    /// @dev Modifier to make a function callable only when the contract is paused.
    modifier whenRedeemPaused() {
        _requireRedeemPaused();
        _;
    }


    /// @dev Initializes the contract in unpaused state.
    constructor() {
        _mintPaused= false;
        _redeemPaused= false;
    }

    
    function isMintPaused() public view returns(bool) {
        return _mintPaused;
    }

    function isRedeemPaused() public view returns(bool) {
        return _redeemPaused;
    }


    /// @dev Throws if the contract is paused.
    function _requireMintNotPaused() internal view virtual {
        require(!_mintPaused, "Mint paused");
    }

    /// @dev Throws if the contract is not paused.
    function _requireMintPaused() internal view virtual {
        require(_mintPaused); // TradePausable: mint not paused
    }

    /// @dev Throws if the contract is paused.
    function _requireRedeemNotPaused() internal view virtual {
        require(!_redeemPaused); // TradePausable: redeem paused
    }

    /// @dev Throws if the contract is not paused.
    function _requireRedeemPaused() internal view virtual {
        require(_redeemPaused); // TradePausable: redeem not paused
    }

    /// @dev Triggers stopped state for mint
    function _pauseMint() internal virtual {
        _mintPaused = true;
        emit MintPaused(msg.sender);
    }

    /// @dev Returns to normal state.
    function _unpauseMint() internal virtual {
        _mintPaused = false;
        emit MintUnpaused(msg.sender);
    }

    /// @dev Triggers stopped state for redeem 
    function _pauseRedeem() internal virtual {
        _redeemPaused = true;
        emit RedeemPaused(msg.sender);
    }

    /// @dev Returns to normal state.
    function _unpauseRedeem() internal virtual {
        _redeemPaused = false;
        emit RedeemUnpaused(msg.sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract VariableFees {

    /// @dev Fee rate over USD amount with 6 decimals
    function _variableFee(uint256 usdAmount, uint256 baseFee) internal pure returns(uint256 fee) {
        if (usdAmount < 1000*1e18) 
            fee = baseFee;
        
        else if (usdAmount < 10000*1e18) 
            fee = baseFee + 500 * (usdAmount - 1000*1e18) / 9000 / 1e18;
        
        else if (usdAmount < 100000*1e18) 
            fee = baseFee + 500 + 500 * (usdAmount - 10000*1e18) / 90000 / 1e18;
        
        else if (usdAmount < 1000000*1e18) 
            fee = baseFee + 1000 + 1000 * (usdAmount - 100000*1e18) / 900000 / 1e18;
        
        else 
            fee = baseFee + 2000;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ICollectible.sol";


interface IGenesisLiquidityPool is ICollectible {

    // +++++++++++++++++++  PUBLIC STATE VARIABLES  +++++++++++++++++++++++++

    function initMintedAmount() external view returns(uint256);

    function poolWeight() external view returns(uint16);
    
    function mintedGEX() external view returns(int256);

    function balanceCollateral() external view returns(uint256);

    function balanceGEX() external view returns(uint256);
    
    function blockTimestampLast() external view returns(uint64);
    
    function lastCollatPrice() external view returns(uint256);
    
    function meanPrice() external view returns(uint256);
    
    function lastPrice() external view returns(uint256);
    
    function meanVolume() external view returns(uint256);
    
    function lastVolume() external view returns(uint256);

    function isMigrationRequested() external view returns(bool);
    
    function isRemoveRequested() external view returns(bool);    
    

    // ++++++++++++++++++++++++++  MIGRATION  +++++++++++++++++++++++++++++++

    function receiveMigration(uint256 amountGEX, uint256 amountCollateral, uint256 initMintedAmount) external;

    function bailoutMinter() external returns(uint256);

    function lendCollateral(uint256 amount) external returns(uint256);

    function repayCollateral(uint256 amount) external returns(uint256);

    
    // ++++++++++++++++++++++++  USER FUNCTIONS  ++++++++++++++++++++++++++++
    
    function mintSwap(uint256 inCollatAmount, uint256 minOutGEXAmount) external;

    function redeemSwap(uint256 inGEXAmount, uint256 minOutCollatAmount) external;
    
    
    // ++++++++++++++++++++  INFORMATIVE FUNCTIONS  +++++++++++++++++++++++++

    function collateralPrice() external view returns(uint256);

    function collateralQuote() external view returns(uint256);

    function getCollateralValue() external view returns(uint256);

    function GEXPrice() external view returns(uint256);

    function GEXQuote() external view returns(uint256);

    function amountFeeMint(uint256 amountGEX) external view returns(uint256);

    function amountFeeRedeem(uint256 amountGEX) external view returns(uint256);

    function getMintInfo(uint256 inCollatAmount) external view returns(
        uint256 collateralPriceUSD, 
        uint256 gexPriceUSD,
        uint256 collatQuote,
        uint256 gexQuote,
        uint256 fee,
        uint256 feeAmount,
        uint256 outGEXAmount,
        uint256 finalGEXPriceUSD,
        uint256 priceImpact
    );

    function getRedeemInfo(uint256 inGEXAmount) external view returns(
        uint256 collateralPriceUSD, 
        uint256 gexPriceUSD,
        uint256 collatQuote,
        uint256 gexQuote,
        uint256 fee,
        uint256 feeAmount,
        uint256 outCollatAmount,
        uint256 finalGEXPriceUSD,
        uint256 priceImpact
    );

    function amountOutGEX(uint256 inCollatAmount) external view returns(uint256);

    function amountOutCollateral(uint256 inGEXAmount) external view returns(uint256);

    function amountMint(uint256 outGEXAmount) external view returns(uint256);

    function amountBurn(uint256 inGEXAmount) external view returns(uint256);

    function variableFee(uint256 amountGEX, uint256 baseFee) external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/**
* @title ICollectible
* @author Geminon Protocol
* @notice Interface for smart contracts whose fees have
* to be collected by the FeeCollector contract.
*/
interface ICollectible {
    function collectFees() external returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IERC20ElasticSupply.sol";


/**
* @title IERC20Indexed
* @author Geminon Protocol
* @dev Interface for the ERC20Indexed contract
*/
interface IERC20Indexed is IERC20ElasticSupply {
    
    function setIndexBeacon(address beacon) external;
    function requestMaxVariationChange(uint16 newValue) external;
    function applyMaxVariationChange() external;

    function updateTarget() external;
    
    function getOrUpdatePegValue() external returns(uint256);
    function getPegValue() external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IERC20.sol";


/**
* @title IERC20ElasticSupply
* @author Geminon Protocol
* @dev Interface for the ERC20ElasticSupply contract
*/
interface IERC20ElasticSupply is IERC20 {

    function addMinter(address newMinter) external;
    function removeMinter(address minter) external;
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
    function maxAmountMintable() external view returns(uint256);
}