// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./library/ExponentMath.sol";
import "./BaseBondDepository.sol";

import "./interfaces/IStabilizingBondDepository.sol";
import "./interfaces/IMintableBurnableERC20.sol";
import "./interfaces/IPriceFeedOracle.sol";
import "./interfaces/IStablecoinEngine.sol";
import "./interfaces/ITwapOracle.sol";
import "./interfaces/ITreasury.sol";

import "./external/IUniswapV2Pair.sol";
import "./external/UniswapV2Library.sol";

/// @title StabilizingBondDepository
/// @author Bluejay Core Team
/// @notice StabilizingBondDepository performs open market operations to peg stablecoin prices.
/// It does so by selling bonds to the user to size the swap, at a discount rate.
/// The discount rate is proportional to the difference between the oracle price and spot price on AMM.
contract StabilizingBondDepository is
  Ownable,
  BaseBondDepository,
  IStabilizingBondDepository
{
  using SafeERC20 for IERC20;
  using SafeERC20 for IMintableBurnableERC20;

  uint256 private constant WAD = 10**18;
  uint256 private constant RAY = 10**27;
  uint256 private constant RAD = 10**45;

  /// @notice Contract address of the BLU Token
  IERC20 public immutable BLU;

  /// @notice Contract address of the asset used to pay for the bonds
  IERC20 public immutable override reserve;

  /// @notice Contract address of the Stablecoin token
  IMintableBurnableERC20 public immutable stablecoin;

  /// @notice Contract address of the Treasury where the reserve assets are sent and BLU minted
  ITreasury public immutable treasury;

  /// @notice Contract address of the StablecoinEngine to mint additional stablecoin
  IStablecoinEngine public immutable stablecoinEngine;

  /// @notice Vesting period of bonds, in seconds
  uint256 public immutable vestingPeriod;

  /// @notice Contract address of UniswapV2 Pool with the stablecoin token and reserve token
  IUniswapV2Pair public immutable pool;

  /// @notice Caching if the reserve token on the UniswapV2 pool is token 0
  bool public immutable reserveIsToken0;

  /// @notice Contract address of TWAP Oracle of the BLU/<reserve> UniswapV2 pool
  ITwapOracle public bluTwapOracle;

  /// @notice Contract address of TWAP Oracle of the Stablecoin/<reserve> UniswapV2 pool
  ITwapOracle public stablecoinTwapOracle;

  /// @notice Contract address of external price oracle of the Stablecoin against <reserve>
  /// @dev Price is quoted as stablecoins per reserve token, in WAD
  IPriceFeedOracle public stablecoinOracle;

  /// @notice Price deviation tolerance where bonds will not be sold, in WAD
  uint256 public tolerance;

  /// @notice Maximum amount of reward for the bond purchase, in WAD
  uint256 public maxRewardFactor;

  /// @notice Control variable to control discount rate of bonds, in WEI
  uint256 public controlVariable;

  /// @notice Flag to pause purchase of bonds
  bool public isPurchasePaused;

  /// @notice Flag to pause redemption of bonds
  bool public isRedeemPaused;

  /// @notice Constructor to initialize the contract
  /// @param _blu Address of the BLU token
  /// @param _reserve Address of the asset accepted for payment of the bonds
  /// @param _stablecoin Address of target stablecoin
  /// @param _treasury Address of the Treasury for minting BLU tokens and storing proceeds
  /// @param _stablecoinEngine Address of stablecoin engine to mint additional stablecoin
  /// @param _bluTwapOracle Address of TWAP Oracle of the BLU/<reserve> UniswapV2 pool
  /// @param _stablecoinTwapOracle Address of TWAP Oracle of the Stablecoin/<reserve> UniswapV2 pool
  /// @param _stablecoinOracle Address of external price oracle of the Stablecoin against <reserve>
  /// @param _pool Address of UniswapV2 Pool with the stablecoin token and reserve token
  /// @param _vestingPeriod Vesting period of bonds, in seconds
  constructor(
    address _blu,
    address _reserve,
    address _stablecoin,
    address _treasury,
    address _stablecoinEngine,
    address _bluTwapOracle,
    address _stablecoinTwapOracle,
    address _stablecoinOracle,
    address _pool,
    uint256 _vestingPeriod
  ) {
    BLU = IERC20(_blu);
    reserve = IERC20(_reserve);
    stablecoin = IMintableBurnableERC20(_stablecoin);

    treasury = ITreasury(_treasury);
    stablecoinEngine = IStablecoinEngine(_stablecoinEngine);
    bluTwapOracle = ITwapOracle(_bluTwapOracle);
    stablecoinTwapOracle = ITwapOracle(_stablecoinTwapOracle);
    stablecoinOracle = IPriceFeedOracle(_stablecoinOracle);
    pool = IUniswapV2Pair(_pool);

    vestingPeriod = _vestingPeriod;

    (address token0, ) = UniswapV2Library.sortTokens(_stablecoin, _reserve);
    reserveIsToken0 = _reserve == token0;

    isPurchasePaused = true;
  }

  // =============================== PUBLIC FUNCTIONS =================================
  /// @notice Convenience function to update both TWAP oracles if possible
  function updateOracles() public override {
    stablecoinTwapOracle.tryUpdate();
    bluTwapOracle.tryUpdate();
  }

  /// @notice Purchase treasury bond paid with reserve assets
  /// @dev Approval of reserve asset to this address is required
  /// @param amount Amount of reserve asset to spend, in WAD
  /// @param maxPrice Maximum price to pay for the bond to prevent slippages, in WAD
  /// @param minOutput Minumum output of the underlying swap to prevent excessive slippages, in WAD
  /// @param recipient Address to issue the bond to
  /// @return bondId ID of bond that was issued
  function purchase(
    uint256 amount,
    uint256 maxPrice,
    uint256 minOutput,
    address recipient
  ) public override returns (uint256 bondId) {
    require(!isPurchasePaused, "Paused");

    // Update oracle
    updateOracles();

    // Check that stabilizing bond is available
    uint256 externalPrice = stablecoinOracle.getPrice();
    (uint256 degree, bool isExpansionary, ) = getTwapDeviationFromPrice(
      externalPrice
    );
    require(degree > tolerance, "Not available");

    // Collect payments
    reserve.safeTransferFrom(msg.sender, address(this), amount);

    // Perform corrective actions
    if (isExpansionary) {
      // If expansionary:
      // - send reserve to treasury
      // - mint stablecoin at reference rate (stablecoinTwapOracle) to pool
      // - swap stablecoin for reserve
      reserve.safeTransfer(address(treasury), amount);
      uint256 stablecoinToMint = (amount * externalPrice) / WAD;
      stablecoinEngine.mint(
        address(stablecoin),
        address(pool),
        stablecoinToMint
      );
      (uint256 reserve0, uint256 reserve1, ) = pool.getReserves();

      uint256 amountOut = UniswapV2Library.getAmountOut(
        stablecoinToMint,
        reserveIsToken0 ? reserve1 : reserve0, // reserveIn
        reserveIsToken0 ? reserve0 : reserve1 // reserveOut
      );

      require(amountOut >= minOutput, "Insufficient output");

      pool.swap(
        reserveIsToken0 ? amountOut : 0, // amount0Out
        reserveIsToken0 ? 0 : amountOut, // amount1Out
        address(treasury),
        new bytes(0)
      );
    } else {
      // If contractionary:
      // - send reserve to pool
      // - swap reserve for stablecoin
      // - burn stablecoin
      reserve.safeTransfer(address(pool), amount);
      (uint256 reserve0, uint256 reserve1, ) = pool.getReserves();
      uint256 amountOut = UniswapV2Library.getAmountOut(
        amount,
        reserveIsToken0 ? reserve0 : reserve1, // reserveIn
        reserveIsToken0 ? reserve1 : reserve0 // reserveOut
      );

      require(amountOut >= minOutput, "Insufficient output");

      pool.swap(
        reserveIsToken0 ? 0 : amountOut, // amount0Out
        reserveIsToken0 ? amountOut : 0, // amount1Out
        address(this),
        new bytes(0)
      );
      stablecoin.burn(amountOut);
    }

    {
      // Check for overcorrection
      (, bool isExpansionaryFinal, ) = getSpotDeviationFromPrice(externalPrice);
      require(isExpansionary == isExpansionaryFinal, "Overcorrection");
    }

    // Check if user is overpaying
    uint256 price = bondPriceFromDeviation(degree);
    require(price < maxPrice, "Slippage");

    // Finally issue bonds
    uint256 payout = (amount * WAD) / price;
    treasury.mint(address(this), payout);
    bondId = _mint(recipient, payout, vestingPeriod);

    emit BondPurchased(bondId, recipient, amount, payout, price);
  }

  /// @notice Redeem BLU tokens from previously purchased bond.
  /// BLU is linearly vested over the vesting period and user can redeem vested tokens at any time.
  /// @dev Bond will be deleted after the bond is fully vested and redeemed
  /// @param bondId ID of bond to redeem, caller must the bond owner
  /// @param recipient Address to send vested BLU tokens to
  /// @return payout Amount of BLU tokens sent to recipient, in WAD
  /// @return principal Amount of BLU tokens left to be vested on the bond, in WAD
  function redeem(uint256 bondId, address recipient)
    public
    override
    returns (uint256 payout, uint256 principal)
  {
    require(!isRedeemPaused, "Paused");
    require(bondOwners[bondId] == msg.sender, "Not owner");
    Bond memory bond = bonds[bondId];
    bool fullyRedeemed = false;
    if (bond.lastRedeemed + bond.vestingPeriod <= block.timestamp) {
      _burn(bondId);
      fullyRedeemed = true;
      payout = bond.principal;
      BLU.safeTransfer(recipient, payout);
    } else {
      payout =
        (bond.principal * (block.timestamp - bond.lastRedeemed)) /
        bond.vestingPeriod;
      principal = bond.principal - payout;
      bonds[bondId] = Bond({
        principal: principal,
        vestingPeriod: bond.vestingPeriod -
          (block.timestamp - bond.lastRedeemed),
        purchased: bond.purchased,
        lastRedeemed: block.timestamp
      });
      BLU.safeTransfer(recipient, payout);
    }
    emit BondRedeemed(bondId, recipient, fullyRedeemed, payout, principal);
  }

  // =============================== ADMIN FUNCTIONS =================================

  /// @notice Set the tolerance level where bonds are not sold
  /// @param  _tolerance Tolerance level, in WAD
  function setTolerance(uint256 _tolerance) public override onlyOwner {
    tolerance = _tolerance;
    emit UpdatedTolerance(_tolerance);
  }

  /// @notice Set the max reward factor
  /// @param  _maxRewardFactor Max reward factor, in WAD
  function setMaxRewardFactor(uint256 _maxRewardFactor)
    public
    override
    onlyOwner
  {
    maxRewardFactor = _maxRewardFactor;
    emit UpdatedMaxRewardFactor(_maxRewardFactor);
  }

  /// @notice Set the control variable
  /// @param  _controlVariable Control variable, in WAD
  function setControlVariable(uint256 _controlVariable)
    public
    override
    onlyOwner
  {
    controlVariable = _controlVariable;
    emit UpdatedControlVariable(_controlVariable);
  }

  /// @notice Set address of TWAP Oracle of the BLU/<reserve> UniswapV2 pool
  /// @param  _bluTwapOracle Address of TWAP Oracle
  function setBluTwapOracle(address _bluTwapOracle) public override onlyOwner {
    bluTwapOracle = ITwapOracle(_bluTwapOracle);
    emit UpdatedBluTwapOracle(_bluTwapOracle);
  }

  /// @notice Set address of TWAP Oracle of the stablecoin/<reserve> UniswapV2 pool
  /// @param  _stablecoinTwapOracle Address of TWAP Oracle
  function setStablecoinTwapOracle(address _stablecoinTwapOracle)
    public
    override
    onlyOwner
  {
    stablecoinTwapOracle = ITwapOracle(_stablecoinTwapOracle);
    emit UpdatedStablecoinTwapOracle(_stablecoinTwapOracle);
  }

  /// @notice Pause or unpause redemption of bonds
  /// @param pause True to pause redemption, false to unpause redemption
  function setIsRedeemPaused(bool pause) public override onlyOwner {
    isRedeemPaused = pause;
    emit RedeemPaused(pause);
  }

  /// @notice Pause or unpause purchase of bonds
  /// @param pause True to pause purchase, false to unpause purchase
  function setIsPurchasePaused(bool pause) public override onlyOwner {
    isPurchasePaused = pause;
    emit PurchasePaused(pause);
  }

  /// @notice Set address of external price oracle of the Stablecoin against <reserve>
  /// @param  _stablecoinOracle Address of the PriceFeedOracle
  function setStablecoinOracle(address _stablecoinOracle)
    public
    override
    onlyOwner
  {
    stablecoinOracle = IPriceFeedOracle(_stablecoinOracle);
    emit UpdatedStablecoinOracle(_stablecoinOracle);
  }

  // =============================== VIEW FUNCTIONS =================================

  /// @notice Calculate the reward base on the degree of price deviation
  /// @param degree Degree of price deviation, in WAD
  /// @return rewardFactor Reward factor, in WAD
  function getReward(uint256 degree)
    public
    view
    override
    returns (uint256 rewardFactor)
  {
    if (degree <= tolerance) return WAD;

    uint256 factor = (WAD + degree);
    rewardFactor = ExponentMath.rpow(factor, controlVariable, WAD);

    if (rewardFactor > maxRewardFactor) {
      return maxRewardFactor;
    }
    return rewardFactor;
  }

  /// @notice Get current reward factor
  /// @return rewardFactor Reward factor, in WAD
  function getCurrentReward()
    public
    view
    override
    returns (uint256 rewardFactor)
  {
    (uint256 degree, , ) = getTwapDeviation();
    rewardFactor = getReward(degree);
  }

  /// @notice Calculate deviation between oracle price and average price of the stablecoins on the pool
  /// @dev The calculation is based on swapping one WAD of stablecoin to reserve using the oracle price
  /// and then swapping back to stablecoin using the average pool price.
  /// @param oraclePrice Price of stablecoin from oracle, in WAD
  /// @return degree Degree of price deviation, in WAD
  /// @return isExpansionary True if stablecoin is more expensive on the pool than on the oracle price
  /// @return stablecoinOut Amount of stablecoins after the swap sequence
  function getTwapDeviationFromPrice(uint256 oraclePrice)
    public
    view
    override
    returns (
      uint256 degree,
      bool isExpansionary,
      uint256 stablecoinOut
    )
  {
    uint256 stablecoinIn = WAD;
    uint256 reserveOut = (stablecoinIn * WAD) / oraclePrice;
    stablecoinOut = stablecoinTwapOracle.consult(address(reserve), reserveOut);
    if (stablecoinOut >= stablecoinIn) {
      degree = stablecoinOut - stablecoinIn;
      isExpansionary = false;
    } else {
      degree = stablecoinIn - stablecoinOut;
      isExpansionary = true;
    }
  }

  /// @notice Get current deviation between oracle price and average price of the stablecoins on the pool
  /// @return degree Degree of price deviation, in WAD
  /// @return isExpansionary True if stablecoin is more expensive on the pool than on the oracle price
  /// @return stablecoinOut Amount of stablecoins after the swap sequence
  function getTwapDeviation()
    public
    view
    override
    returns (
      uint256 degree,
      bool isExpansionary,
      uint256 stablecoinOut
    )
  {
    (degree, isExpansionary, stablecoinOut) = getTwapDeviationFromPrice(
      stablecoinOracle.getPrice()
    );
  }

  /// @notice Calculate deviation between oracle price and spot price of the stablecoins on the pool
  /// @dev The calculation is based on swapping one WAD of stablecoin to reserve using the oracle price
  /// and then swapping back to stablecoin using the current pool parameters.
  /// @return degree Degree of price deviation, in WAD
  /// @return isExpansionary True if stablecoin is more expensive on the pool than on the oracle price
  /// @return stablecoinOut Amount of stablecoins after the swap sequence
  function getSpotDeviationFromPrice(uint256 oraclePrice)
    public
    view
    override
    returns (
      uint256 degree,
      bool isExpansionary,
      uint256 stablecoinOut
    )
  {
    uint256 stablecoinIn = WAD;
    uint256 reserveOut = (stablecoinIn * WAD) / oraclePrice;
    (uint256 reserve0, uint256 reserve1, ) = pool.getReserves();
    stablecoinOut = UniswapV2Library.getAmountOut(
      reserveOut,
      reserveIsToken0 ? reserve0 : reserve1, // reserveIn
      reserveIsToken0 ? reserve1 : reserve0 // reserveOut
    );
    if (stablecoinOut >= stablecoinIn) {
      degree = stablecoinOut - stablecoinIn;
      isExpansionary = false;
    } else {
      degree = stablecoinIn - stablecoinOut;
      isExpansionary = true;
    }
  }

  /// @notice Get current deviation between oracle price and spot price of the stablecoins on the pool
  /// @return degree Degree of price deviation, in WAD
  /// @return isExpansionary True if stablecoin is more expensive on the pool than on the oracle price
  /// @return stablecoinOut Amount of stablecoins after the swap sequence
  function getSpotDeviation()
    public
    view
    override
    returns (
      uint256 degree,
      bool isExpansionary,
      uint256 stablecoinOut
    )
  {
    (degree, isExpansionary, stablecoinOut) = getSpotDeviationFromPrice(
      stablecoinOracle.getPrice()
    );
  }

  /// @notice Calculate the discounted bond price from the average bond price
  /// @dev The reward factor is based on the control variable and price deviation
  /// between average pool price and oracle price
  /// @param deviation Percentage deviation in the average pool price and oracle price, in WAD
  /// @return price Discounted bond price, in WAD
  function bondPriceFromDeviation(uint256 deviation)
    public
    view
    override
    returns (uint256 price)
  {
    uint256 rewardFactor = getReward(deviation);
    uint256 marketPrice = bluTwapOracle.consult(address(BLU), WAD);
    price = (marketPrice * WAD) / rewardFactor;
  }

  /// @notice Get current bond price based on current deviation between average pool price and oracle price
  /// @return price Discounted bond price, in WAD
  function bondPrice() public view override returns (uint256 price) {
    (uint256 degree, , ) = getTwapDeviation();
    price = bondPriceFromDeviation(degree);
  }

  // =============================== STATIC CALL QUERY FUNCTIONS =================================

  /// @notice Query for the updated bond price after the oracle states have been updated
  /// @dev Use static call to perform the query
  /// @return price Discounted bond price, in WAD
  function updatedBondPrice() public override returns (uint256 price) {
    updateOracles();
    price = bondPrice();
  }

  /// @notice Query for the updated reward factor after the oracle states have been updated
  /// @dev Use static call to perform the query
  /// @return reward Reward factor, in WAD
  function updatedReward() public override returns (uint256 reward) {
    updateOracles();
    reward = getCurrentReward();
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
// https://github.com/makerdao/dss/blob/master/src/abaci.sol
pragma solidity ^0.8.4;

library ExponentMath {
  function rpow(
    uint256 x,
    uint256 n,
    uint256 b
  ) internal pure returns (uint256 z) {
    assembly {
      switch n
      case 0 {
        z := b
      }
      default {
        switch x
        case 0 {
          z := 0
        }
        default {
          switch mod(n, 2)
          case 0 {
            z := b
          }
          default {
            z := x
          }
          let half := div(b, 2) // for rounding.
          for {
            n := div(n, 2)
          } n {
            n := div(n, 2)
          } {
            let xx := mul(x, x)
            if shr(128, x) {
              revert(0, 0)
            }
            let xxRound := add(xx, half)
            if lt(xxRound, xx) {
              revert(0, 0)
            }
            x := div(xxRound, b)
            if mod(n, 2) {
              let zx := mul(z, x)
              if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) {
                revert(0, 0)
              }
              let zxRound := add(zx, half)
              if lt(zxRound, zx) {
                revert(0, 0)
              }
              z := div(zxRound, b)
            }
          }
        }
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/IBaseBondDepository.sol";

/// @title BaseBondDepository
/// @author Bluejay Core Team
/// @notice BaseBondDepository provides logic for minting, burning and storing bond info.
/// The contract is to be inherited by treasury bond depository and stabilizing bond depository.
abstract contract BaseBondDepository is IBaseBondDepository {
  /// @notice Number of bonds minted, monotonic increasing from 0
  uint256 public bondsCount;

  /// @notice Map of bond ID to the bond information
  mapping(uint256 => Bond) public override bonds;

  /// @notice Map of bond ID to the address of the bond owner
  mapping(uint256 => address) public bondOwners;

  /// @notice Map of bond owner address to array of bonds owned
  mapping(address => uint256[]) public ownedBonds;

  /// @notice Map of bond owner and bond ID to the index location of `ownedBonds`
  mapping(address => mapping(uint256 => uint256)) public ownedBondsIndex;

  // =============================== INTERNAL FUNCTIONS =================================

  /// @notice Internal function for child contract to mint a bond with fixed vesting period to an address
  /// @param to Address to mint the bond to
  /// @param payout Amount of assets to payout across the entire vesting period
  /// @param vestingPeriod Vesting period of the bond
  function _mint(
    address to,
    uint256 payout,
    uint256 vestingPeriod
  ) internal returns (uint256 bondId) {
    bondId = ++bondsCount;
    bonds[bondId] = Bond({
      principal: payout,
      vestingPeriod: vestingPeriod,
      purchased: block.timestamp,
      lastRedeemed: block.timestamp
    });
    bondOwners[bondId] = to;
    uint256[] storage userBonds = ownedBonds[to];
    ownedBondsIndex[to][bondId] = userBonds.length;
    userBonds.push(bondId);
  }

  /// @notice Internal function for child contract to burn a bond, usually after it fully vest
  /// This recover gas as well as delete the bond from the view functions
  /// @param bondId Bond ID of the bond to burn
  /// @dev Perform required sanity check on the bond before burning it
  function _burn(uint256 bondId) internal {
    address bondOwner = bondOwners[bondId];
    require(bondOwner != address(0), "Invalid bond");
    uint256[] storage userBonds = ownedBonds[bondOwner];
    mapping(uint256 => uint256) storage userBondIndices = ownedBondsIndex[
      bondOwner
    ];
    uint256 lastBondIndex = userBonds.length - 1;
    uint256 bondIndex = userBondIndices[bondId];
    if (bondIndex != lastBondIndex) {
      uint256 lastBondId = userBonds[lastBondIndex];
      userBonds[bondIndex] = lastBondId;
      userBondIndices[lastBondId] = bondIndex;
    }
    userBonds.pop();
    delete userBondIndices[bondId];
    delete bonds[bondId];
    delete bondOwners[bondId];
  }

  // =============================== INTERNAL FUNCTIONS =================================

  /// @notice List all bond IDs owned by an address
  /// @param owner Address of the owner of the bonds
  /// @return bondIds List of bond IDs owned by the address
  function listBondIds(address owner)
    public
    view
    override
    returns (uint256[] memory bondIds)
  {
    bondIds = ownedBonds[owner];
  }

  /// @notice List all bond info owned by an address
  /// @param owner Address of the owner of the bonds
  /// @return Bond List of bond info owned by the address
  function listBonds(address owner)
    public
    view
    override
    returns (Bond[] memory)
  {
    uint256[] memory bondIds = ownedBonds[owner];
    Bond[] memory bondsOwned = new Bond[](bondIds.length);
    for (uint256 i = 0; i < bondIds.length; i++) {
      bondsOwned[i] = bonds[bondIds[i]];
    }
    return bondsOwned;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IBondDepositoryCommon.sol";

interface IStabilizingBondDepository is IBondDepositoryCommon {
  function purchase(
    uint256 amount,
    uint256 maxPrice,
    uint256 minOutput,
    address recipient
  ) external returns (uint256 bondId);

  function updateOracles() external;

  function updatedBondPrice() external returns (uint256 price);

  function updatedReward() external returns (uint256 reward);

  function getReward(uint256 degree) external view returns (uint256 reward);

  function getCurrentReward() external view returns (uint256);

  function getTwapDeviationFromPrice(uint256 oraclePrice)
    external
    view
    returns (
      uint256 degree,
      bool isExpansionary,
      uint256 stablecoinOut
    );

  function getTwapDeviation()
    external
    view
    returns (
      uint256 degree,
      bool isExpansionary,
      uint256 stablecoinOut
    );

  function getSpotDeviationFromPrice(uint256 oraclePrice)
    external
    view
    returns (
      uint256 degree,
      bool isExpansionary,
      uint256 stablecoinOut
    );

  function getSpotDeviation()
    external
    view
    returns (
      uint256 degree,
      bool isExpansionary,
      uint256 stablecoinOut
    );

  function bondPriceFromDeviation(uint256 deviation)
    external
    view
    returns (uint256 price);

  function setTolerance(uint256 _tolerance) external;

  function setMaxRewardFactor(uint256 _maxRewardFactor) external;

  function setControlVariable(uint256 _controlVariable) external;

  function setBluTwapOracle(address _bluTwapOracle) external;

  function setStablecoinTwapOracle(address _stablecoinTwapOracle) external;

  function setStablecoinOracle(address _stablecoinOracle) external;

  event UpdatedTolerance(uint256 _tolerance);
  event UpdatedMaxRewardFactor(uint256 _maxRewardFactor);
  event UpdatedControlVariable(uint256 _controlVariable);
  event UpdatedBluTwapOracle(address indexed _oracle);
  event UpdatedStablecoinTwapOracle(address indexed _oracle);
  event UpdatedStablecoinOracle(address indexed _oracle);
  event RedeemPaused(bool indexed _paused);
  event PurchasePaused(bool indexed _paused);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IMintableBurnableERC20 is IERC20 {
  function mint(address _to, uint256 _amount) external;

  function burn(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../external/AggregatorV3Interface.sol";

interface IPriceFeedOracle {
  struct Feed {
    AggregatorV3Interface aggregator;
    uint8 decimals;
    bool invert;
  }

  function getPrice() external view returns (uint256 price);
  
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IStablecoinEngine {
  struct StablecoinPoolInfo {
    address reserve;
    address stablecoin;
    address pool;
    bool stablecoinIsToken0;
  }

  function pools(address reserve, address stablecoin)
    external
    view
    returns (address pool);

  function poolsInfo(address _pool)
    external
    view
    returns (
      address reserve,
      address stablecoin,
      address pool,
      bool stablecoinIsToken0
    );

  function initializeStablecoin(
    address reserve,
    address stablecoin,
    uint256 initialReserveAmount,
    uint256 initialStablecoinAmount
  ) external returns (address poolAddress);

  function addLiquidity(
    address pool,
    uint256 reserveAmountDesired,
    uint256 stablecoinAmountDesired,
    uint256 reserveAmountMin,
    uint256 stablecoinAmountMin
  ) external returns (uint256 liquidity);

  function removeLiquidity(
    address pool,
    uint256 liquidity,
    uint256 minimumReserveAmount,
    uint256 minimumStablecoinAmount
  ) external returns (uint256 reserveAmount, uint256 stablecoinAmount);

  function swap(
    address poolAddr,
    uint256 amountIn,
    uint256 minAmountOut,
    bool stablecoinForReserve
  ) external returns (uint256 amountOut);

  function mint(
    address stablecoin,
    address to,
    uint256 amount
  ) external;

  function calculateAmounts(
    address poolAddr,
    uint256 reserveAmountDesired,
    uint256 stablecoinAmountDesired,
    uint256 reserveAmountMin,
    uint256 stablecoinAmountMin
  ) external view returns (uint256 reserveAmount, uint256 stablecoinAmount);

  function getReserves(address poolAddr)
    external
    view
    returns (uint256 stablecoinReserve, uint256 reserveReserve);

  event PoolAdded(
    address indexed reserve,
    address indexed stablecoin,
    address indexed pool
  );
  event LiquidityAdded(
    address indexed pool,
    uint256 liquidity,
    uint256 reserve,
    uint256 stablecoin
  );
  event LiquidityRemoved(
    address indexed pool,
    uint256 liquidity,
    uint256 reserve,
    uint256 stablecoin
  );
  event Swap(
    address indexed pool,
    uint256 amountIn,
    uint256 amountOut,
    bool stablecoinForReserve
  );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ITwapOracle {
  function update() external;

  function tryUpdate() external;

  function consult(address token, uint256 amountIn)
    external
    view
    returns (uint256 amountOut);

  function updateAndConsult(address token, uint256 amountIn)
    external
    returns (uint256 amountOut);

  event UpdatedPrice(
    uint256 price0Average,
    uint256 price1Average,
    uint256 price0CumulativeLast,
    uint256 price1CumulativeLast
  );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ITreasury {
  function mint(address to, uint256 amount) external;

  function withdraw(
    address token,
    address to,
    uint256 amount
  ) external;

  function increaseMintLimit(address minter, uint256 amount) external;

  function decreaseMintLimit(address minter, uint256 amount) external;

  function increaseWithdrawalLimit(
    address asset,
    address spender,
    uint256 amount
  ) external;

  function decreaseWithdrawalLimit(
    address asset,
    address spender,
    uint256 amount
  ) external;

  event Mint(address indexed to, uint256 amount);
  event Withdraw(address indexed token, address indexed to, uint256 amount);
  event MintLimitUpdate(address indexed minter, uint256 amount);
  event WithdrawLimitUpdate(
    address indexed token,
    address indexed minter,
    uint256 amount
  );
}

// SPDX-License-Identifier: GPL-3.0-or-later
// https://github.com/Uniswap/v2-core/blob/master/contracts/UniswapV2Pair.sol
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IUniswapV2Pair is IERC20 {
  function name() external pure returns (string memory);

  function symbol() external pure returns (string memory);

  function decimals() external pure returns (uint8);

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

  function burn(address to) external returns (uint256 amount0, uint256 amount1);

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

// SPDX-License-Identifier: GPL-3.0-or-later
// https://github.com/Uniswap/v2-periphery/blob/master/contracts/libraries/UniswapV2Library.sol
pragma solidity ^0.8.4;

import "./IUniswapV2Pair.sol";

library UniswapV2Library {
  // returns sorted token addresses, used to handle return values from pairs sorted in this order
  function sortTokens(address tokenA, address tokenB)
    internal
    pure
    returns (address token0, address token1)
  {
    require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
    (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
  }

  // calculates the CREATE2 address for a pair without making any external calls
  function pairFor(
    address factory,
    address tokenA,
    address tokenB
  ) internal pure returns (address pair) {
    (address token0, address token1) = sortTokens(tokenA, tokenB);
    pair = address(
      uint160(
        uint256(
          keccak256(
            abi.encodePacked(
              hex"ff",
              factory,
              keccak256(abi.encodePacked(token0, token1)),
              hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash
            )
          )
        )
      )
    );
  }

  // fetches and sorts the reserves for a pair
  function getReserves(
    address factory,
    address tokenA,
    address tokenB
  ) internal view returns (uint256 reserveA, uint256 reserveB) {
    (address token0, ) = sortTokens(tokenA, tokenB);
    (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(
      pairFor(factory, tokenA, tokenB)
    ).getReserves();
    (reserveA, reserveB) = tokenA == token0
      ? (reserve0, reserve1)
      : (reserve1, reserve0);
  }

  // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
  function quote(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  ) internal pure returns (uint256 amountB) {
    require(amountA > 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
    require(
      reserveA > 0 && reserveB > 0,
      "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
    );
    amountB = (amountA * reserveB) / reserveA;
  }

  // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) internal pure returns (uint256 amountOut) {
    require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
    require(
      reserveIn > 0 && reserveOut > 0,
      "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
    );
    uint256 amountInWithFee = amountIn * 997;
    uint256 numerator = amountInWithFee * reserveOut;
    uint256 denominator = (reserveIn * 1000) + amountInWithFee;
    amountOut = numerator / denominator;
  }

  // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut
  ) internal pure returns (uint256 amountIn) {
    require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
    require(
      reserveIn > 0 && reserveOut > 0,
      "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
    );
    uint256 numerator = reserveIn * amountOut * 1000;
    uint256 denominator = (reserveOut - amountOut) * 997;
    amountIn = (numerator / denominator) + 1;
  }

  // performs chained getAmountOut calculations on any number of pairs
  function getAmountsOut(
    address factory,
    uint256 amountIn,
    address[] memory path
  ) internal view returns (uint256[] memory amounts) {
    require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
    amounts = new uint256[](path.length);
    amounts[0] = amountIn;
    for (uint256 i; i < path.length - 1; i++) {
      (uint256 reserveIn, uint256 reserveOut) = getReserves(
        factory,
        path[i],
        path[i + 1]
      );
      amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
    }
  }

  // performs chained getAmountIn calculations on any number of pairs
  function getAmountsIn(
    address factory,
    uint256 amountOut,
    address[] memory path
  ) internal view returns (uint256[] memory amounts) {
    require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
    amounts = new uint256[](path.length);
    amounts[amounts.length - 1] = amountOut;
    for (uint256 i = path.length - 1; i > 0; i--) {
      (uint256 reserveIn, uint256 reserveOut) = getReserves(
        factory,
        path[i - 1],
        path[i]
      );
      amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IBaseBondDepository {
  struct Bond {
    uint256 principal; // [wad]
    uint256 vestingPeriod; // [seconds]
    uint256 purchased; // [unix timestamp]
    uint256 lastRedeemed; // [unix timestamp]
  }

  function bonds(uint256 _id)
    external
    view
    returns (
      uint256 principal,
      uint256 vestingPeriod,
      uint256 purchased,
      uint256 lastRedeemed
    );

  function listBondIds(address owner)
    external
    view
    returns (uint256[] memory bondIds);

  function listBonds(address owner) external view returns (Bond[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./IBaseBondDepository.sol";

interface IBondDepositoryCommon is IBaseBondDepository {
  function reserve() external view returns (IERC20);

  function bondPrice() external view returns (uint256 price);

  function redeem(uint256 bondId, address recipient)
    external
    returns (uint256 payout, uint256 principal);

  function setIsRedeemPaused(bool pause) external;

  function setIsPurchasePaused(bool pause) external;

  event BondPurchased(
    uint256 indexed bondId,
    address indexed recipient,
    uint256 amount,
    uint256 principal,
    uint256 price
  );
  event BondRedeemed(
    uint256 indexed bondId,
    address indexed recipient,
    bool indexed fullyRedeemed,
    uint256 payout,
    uint256 principal
  );
}

// SPDX-License-Identifier: MIT
// https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}