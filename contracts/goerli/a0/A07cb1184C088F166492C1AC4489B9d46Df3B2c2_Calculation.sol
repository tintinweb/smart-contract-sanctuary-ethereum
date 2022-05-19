// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "../interfaces/IMarket.sol";
import "../interfaces/IProtocolConfig.sol";
import "../interfaces/IRiskCalculation.sol";
import "../interfaces/ICalculation.sol";

import "./RiskCalculationV2.sol";
import "./RebalanceCalculation.sol";

/// @title RiskCalculation
/// @notice Calculate current risk using current prices from price oracles, balances from asset pools and capital pools etc.
/// @notice Provides historical data based on time.
contract Calculation is RiskCalculationV2, RebalanceCalculation, ICalculation {

    constructor(
        address _config,
        address _state,
        address _token,
        uint _DIVIDER_ASSET,
        uint _DIVIDER_STABLE
    )
        CalculationBase(
            _config,
            _state,
            _token,
            _DIVIDER_ASSET,
            _DIVIDER_STABLE
        )
    {}

    function validateTakerPos(uint16 risk, uint16 term)
        external
        pure
        virtual
        override
    {
        getTakerRate(risk, term);
    }

    function validateMakerPos(uint16 tier, uint16 term)
        external
        pure
        virtual
        override
    {
        getMakerRate(tier, term);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {IERC20MetadataUpgradeable as IERC20Metadata} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

import "../struct/TakerPosition.sol";
import "../struct/MakerPosition.sol";
import "../struct/UserPositions.sol";
import "../struct/Payout.sol";

import "./IMakerPosition.sol";
import "./ITakerPosition.sol";
import "./IBond.sol";

interface IMarket {
    /// @notice opens a new taker position
    /// @param account initial position owner
    /// @param amount asset amount to protect
    /// @param risk position risk value
    /// @param term position term value
    /// @param bumpAmount bump amount to lock as a bond in the position
    /// @param flags packed position flags
    /// @return id created position id
    /// @dev allowed values of {risk} and {term} are depends of a particular
    /// market and a {Calculation} contract that is uses
    function protect(
        address account,
        uint amount,
        uint16 risk,
        uint16 term,
        uint bumpAmount,
        uint192 flags
    ) external returns (uint id, uint floor);

    /// @notice closes an existing taker position
    /// @notice position can be closed only if position term is over
    /// @param account position owner
    /// @param id taker position id
    /// @param unwrap if market is a wrapped native, this flag is says that asset should be
    /// unwrapped to native or it should be returned as a wrapped native
    /// @param stable stable token address to make payout in
    function close(
        address account,
        uint id,
        bool unwrap,
        address stable
    ) external returns (uint premium, Payout memory payout);

    /// @notice closes an existing taker position and claims stable
    /// @notice position can be closed only if position term is over
    /// @param account position owner
    /// @param id taker position id
    /// @param stable stable token address to make payout in
    function claim(
        address account,
        uint id,
        address stable
    ) external returns (uint premium, Payout memory payout);

    /// @notice cancel existing taker position
    /// @notice position can be canceled even if position term is not over
    /// @param account position owner
    /// @param id taker position id
    /// @param unwrap if market is a wrapped native, this flag is says that asset should be
    /// unwrapped to native or it should be returned as a wrapped native
    /// @param stable stable token address to make payout in
    function cancel(
        address account,
        uint id,
        bool unwrap,
        address stable
    ) external returns (uint premium, Payout memory payout);

    /// @notice opens a new maker position
    /// @param account initial position owner
    /// @param amount asset amount to protect
    /// @param risk position risk value
    /// @param term position term value
    /// @param bumpAmount bump amount to lock as a bond in the position
    /// @param flags packed position flags
    /// @return id created position id
    /// @dev allowed values of {risk} and {term} are depends of a particular
    /// market and a {Calculation} contract that is uses
    function deposit(
        address account,
        uint amount,
        uint16 risk,
        uint16 term,
        uint bumpAmount,
        uint192 flags
    ) external returns (uint id);

    /// @notice closes an existing maker position and claim yield
    /// @notice position can be closed only if position term is over
    /// @param account initial position owner
    /// @param id existing position id
    /// @param stable stable token address to make payout in
    function withdraw(
        address account,
        uint id,
        address stable
    ) external returns (int yield, Payout memory payout);

    /// @notice Allows a Maker to terminate their position before the end of the fixed term.
    /// @notice Comes with forfeiture of positive yield and an early termination penalty.
    /// @param account initial position owner
    /// @param id existing position id
    /// @param stable stable token address to make payout in
    function abandon(
        address account,
        uint id,
        address stable
    ) external returns (int yield, Payout memory payout);

    function setUserProfile(address account, uint profile) external;

    /// @notice Asset token address
    /// @return Asset token
    function ASSET() external pure returns (IERC20);

    /// @notice Stable token address
    /// @return Stable token
    function STABLE() external view returns (IERC20);

    /// @return risk calculation contract address
    function getRiskCalc() external view returns (address);

    /// @return market state contract address
    function getState() external view returns (address);

    /// @notice Get all Taker`s positions
    /// @param taker taker address
    /// @return array of ids of all taker`s positions
    function getTakerPositions(address taker)
        external
        view
        returns (uint[] memory);

    /// @notice Get all Maker`s positions
    /// @param maker maker address
    /// @return array of ids of all maker`s positions
    function getMakerPositions(address maker)
        external
        view
        returns (uint[] memory);

    /// @notice Get Taker position by position id
    /// @param id position id
    /// @return position struct
    function getTakerPosition(uint id)
        external
        view
        returns (TakerPosition memory);

    /// @notice Get Maker position by position id
    /// @param id position id
    /// @return position struct
    function getMakerPosition(uint id)
        external
        view
        returns (MakerPosition memory);

    /// @notice Get locked bond amount for Taker position
    /// @param id position id
    /// @return locked bond amount
    function getTakerPositionBond(uint id) external view returns (uint);

    /// @notice Get locked bond amount for Maker position
    /// @param id position id
    /// @return locked bond amount
    function getMakerPositionBond(uint id) external view returns (uint);

    function getUserProfile(address account) external view returns (uint);

    // function liquidateZeroTakerPosition(address account, uint id) external;
    // function liquidateZeroMakerPosition(address account, uint id) external;
    // calculate premium
    function premiumOnClose(uint id) external view returns (uint);

    function premiumOnClaim(uint id) external view returns (uint);

    function premiumOnCancel(uint id) external view returns (uint);

    // calculate yield
    function yieldOnWithdraw(uint id) external view returns (int);

    function yieldOnAbandon(uint id) external view returns (int);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

/// @notice Interface for accessing protocol configuration parameters
interface IProtocolConfig {
    /// @notice get Global access controller
    function getGAC() external view returns (address);

    /// @notice Version of the protocol
    function getVersion() external view returns (uint16);

    /// @notice Stable coin address
    function getStable() external view returns (address);

    /// @notice Get address of NFT maker for given market
    function getNFTMaker(address token) external view returns (address);

    /// @notice Get address of NFT taker for given market
    function getNFTTaker(address token) external view returns (address);

    /// @notice Get address of B-token for given market
    function getBToken(address token) external view returns (address);

    /// @notice Get market contract address by token address
    function getMarket(address token) external view returns (address);

    /// @notice Get supported assets array 
    function getAssets()
        external
        view
        returns (address[] memory);

    /// @notice Get wrapped native market address
    function getWrappedNativeMarket() external view returns (address);

    /// @notice Get wrapped native token address
    function getWrappedNativeToken() external view returns (address);    

    /// @notice Get rebalancer contract address
    function getRebalancer() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "./IMarket.sol";
import "./ITakerPositionRate.sol";
import "./IMakerPositionRate.sol";
import "./IPAPCalculation.sol";
import "./IYieldCalculation.sol";
import "../struct/BoostingParameters.sol";

interface IRiskCalculation is ITakerPositionRate, IMakerPositionRate, IPAPCalculation, IYieldCalculation {

    function premiumOnClose(uint id) external view returns (uint);

    function premiumOnClaim(uint id) external view returns (uint);

    function premiumOnCancel(uint id) external view returns (uint);

    function yieldOnWithdraw(uint id) external view returns (int);

    function yieldOnAbandon(uint id) external view returns (int);

    function boostParameters() external returns (BoostingParameters memory);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "./IRebalanceCalculation.sol";
import "./IRiskCalculation.sol";

interface ICalculation is IRebalanceCalculation, IRiskCalculation {
    function validateMakerPos(uint16 risk, uint16 term) external pure;

    function validateTakerPos(uint16 risk, uint16 term) external pure;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "../interfaces/IMarket.sol";
import "../interfaces/IProtocolConfig.sol";
import "../interfaces/IRiskCalculation.sol";

import "./CalculationBase.sol";
import "./YieldCalculation.sol";
import "./PAPCalculation.sol";
import "./TakerPositionRate.sol";
import "./MakerPositionRate.sol";
import "./FeeCalculation.sol";
import "./BoostingCalculation.sol";
import "../libraries/OptionFlagsHelper.sol";

import "hardhat/console.sol";

/// @title RiskCalculationV2
/// @notice Calculate current risk using current prices from price oracles, balances from asset pools and capital pools etc.
/// @notice Provides historical data based on time.
abstract contract RiskCalculationV2 is
    CalculationBase,
    TakerPositionRate,
    MakerPositionRate,
    PAPCalculation,
    YieldCalculation,
    FeeCalculation,
    BoostingCalculation,
    IRiskCalculation
{
    using OptionFlagsHelper for uint192;

    function premiumOnClose(uint id) public view override returns (uint) {
        (uint ci, ) = state.calcCI();
        uint premium = commonPremium(id, ci);

        TakerPosition memory pos = market.getTakerPosition(id);

        uint8 terms = pos.flags.getAutorenewTerms();

        if (block.timestamp > pos.start + pos.term * terms * 1 days) {
            uint rate = getTakerRate(pos.risk, pos.term);

            uint extraTime = block.timestamp - (pos.start + pos.term * terms * 1 days);
            
            uint extraPremium = premium * extraTime / (block.timestamp - pos.start);
            premium -= extraPremium;
            extraPremium = extraPremium * (rate + 3 * UDIVIDER) / rate;

            premium += extraPremium;
        }

        // add fee to premium value (fee will be collected later and transfered to the treasury)
        premium += calcTakerPositionFee(pos.assetAmount, pos.start);

        if (pos.assetAmount < premium) premium = pos.assetAmount;

        return premium;
    }

    function premiumOnClaim(uint id) public view override returns (uint) {
        (uint ci, ) = state.calcCI();
        uint premium = commonPremium(id, ci);

        TakerPosition memory pos = market.getTakerPosition(id);

        uint8 terms = pos.flags.getAutorenewTerms();

        if (block.timestamp > pos.start + pos.term * terms * 1 days) {
            uint rate = getTakerRate(pos.risk, pos.term);

            uint extraTime = block.timestamp - (pos.start + pos.term * terms * 1 days);
            
            uint extraPremium = premium * extraTime / (block.timestamp - pos.start);
            premium -= extraPremium;
            extraPremium = extraPremium * (rate + 3 * UDIVIDER) / rate;

            premium += extraPremium;
        }

        // add fee to premium value (fee will be collected later and transfered to the treasury)
        premium += calcTakerPositionFee(pos.assetAmount, pos.start);

        if (pos.assetAmount < premium) premium = pos.assetAmount;

        return premium;
    }

    function premiumOnCancel(uint id) public view override returns (uint) {
        (uint ci, ) = state.calcCI();
        uint premium = commonPremium(id, ci);
        TakerPosition memory pos = market.getTakerPosition(id);
        uint rate = getTakerRate(pos.risk, pos.term);
        
        uint numberDays = (block.timestamp - pos.start) / 1 days;
        uint premiumPerDay = premium / numberDays;

        premium = premium * (rate + 3 * UDIVIDER) / rate;
        uint penalty = premiumPerDay * 5 / rate * 30;

        premium += penalty;

        // add fee to premium value (fee will be collected later and transfered to the treasury)
        premium += calcTakerPositionFee(pos.assetAmount, pos.start);

        if (pos.assetAmount < premium) premium = pos.assetAmount;

        return premium;
    }

    /// @notice Calculate premium for given position
    function commonPremium(uint id, uint ci) public view returns (uint) {
        TakerPosition memory pos = market.getTakerPosition(id);
        uint rate = getTakerRate(pos.risk, pos.term) * pos.flags.getAutorenewTerms();
        uint p = ((ci - pos.ci) * uint((rate * pos.assetAmount) / UDIVIDER)) / UDIVIDER;

        return p;
    }

    function yieldOnWithdraw(uint id) public view override returns (int) {
        int _yield = commonYield(id, 0);

        MakerPosition memory pos = market.getMakerPosition(id);

        uint8 terms = pos.flags.getAutorenewTerms();

        if (block.timestamp > pos.start + pos.term * terms * 1 days) {
            int extraTime = int(block.timestamp - (pos.start + pos.term * terms * 1 days));

            int extraYield = _yield * extraTime / int(block.timestamp - pos.start);
            _yield -= extraYield;

            extraYield = _yield > 0 ? extraYield / 2 : extraYield * 3 / 2;

            _yield += extraYield;
        }

        // add fee to premium value (fee will be collected later and transfered to the treasury)
        _yield -= int(calcMakerPositionFee(pos.stableAmount, pos.start));

        if (int(pos.stableAmount) < -_yield) _yield = -int(pos.stableAmount);

        return _yield;
    }

    function yieldOnAbandon(uint id) public view override returns (int) {
        int _yield = commonYield(id, 0);

        MakerPosition memory pos = market.getMakerPosition(id);

        if(_yield > 0) {
            _yield = - int(pos.stableAmount * 5 / 100);
        }
        else {
            ( , uint negativeRate) = getMakerRate(pos.tier, pos.term);

            _yield = _yield * DIVIDER / int(negativeRate) * 2 - int(pos.stableAmount * 5 / 100);
        }

        // add fee to premium value (fee will be collected later and transfered to the treasury)
        _yield -= int(calcMakerPositionFee(pos.stableAmount, pos.start));

        if (int(pos.stableAmount) < -_yield) _yield = -int(pos.stableAmount);

        return _yield;
    }

    /// @notice calculate yield for given position
    function commonYield(uint id, uint ci) public view returns (int) {
        MakerPosition memory pos = market.getMakerPosition(id);

        MarketState memory s = IState(state).getStateAsStruct();
        int probabilityOfClaim = int(IState(state).probabilityOfClaim());

        (uint positiveRate, uint negativeRate) = getMakerRate(pos.tier, pos.term);

        int marketYield = s.CP - (s.D + probabilityOfClaim * s.L / DIVIDER);

        int part_of_yield = marketYield > 0 
                ? int(pos.stableAmount * positiveRate / IState(state).RWCp())
                : int(pos.stableAmount * negativeRate / IState(state).RWCn());
        
        return part_of_yield * marketYield / DIVIDER;
    }

    function boostParameters() external view override returns (BoostingParameters memory) {
        return _boostParameters();
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "../interfaces/IState.sol";
import "../interfaces/IRebalanceCalculation.sol";

import "./CalculationBase.sol";

import "hardhat/console.sol";

/// @title Implements rebalance calculation
abstract contract RebalanceCalculation is
    CalculationBase,
    IRebalanceCalculation
{

    /// @notice Calculate premium against the asset pool
    function rebalanceAmount()
        public
        view
        override
        returns (RebalanceAmount memory)
    {
        MarketState memory s = IState(state).getStateAsStruct();
        int beta = int(IState(state).probabilityOfClaim());

        int al = AL(beta, s.AR, s.AP, s.B);
        int cl = CL(beta, s.CP, s.CR, s.D, s.L, s.E);

        // Sell Asset
        if (al > 0 && cl < 0) {
            int allowAsset = al / 2;
            if (s.AR > allowAsset) {
                return RebalanceAmount(0, -allowAsset, 0, 0, 0, 0, 0, uint(allowAsset), 0);
            } else if (s.AR + s.AP > allowAsset) {
                return RebalanceAmount(-(s.AP + s.AR - allowAsset), -s.AR, 0, 0, 0, 0, 0, uint(allowAsset), 0);
            } else {
                return RebalanceAmount(-s.AP, -s.AR, 0, 0, 0, 0, 0, uint(s.AP + s.AR), 0);
            }
        }

        // Sell Stable
        if (al < 0 && cl > 0) {
            int allowStable = cl / 2;
            if (s.CP > allowStable) {
                return RebalanceAmount(0, 0, -allowStable, 0, 0, 0, 0, 0, uint(allowStable));
            } else if (s.CR + s.CP > allowStable) {
                return RebalanceAmount(0, 0, -s.CP, -(s.CR + s.CP - allowStable), 0, 0, 0, 0, uint(allowStable));
            } else {
                return RebalanceAmount(0, 0, -s.CP, -s.CR, 0, 0, 0, 0, uint(s.CP + s.CR));
            }
        }

        return RebalanceAmount(0, 0, 0, 0, 0, 0, 0, 0, 0);
    }

    function AL(
        int betta,
        int AR,
        int AP,
        int B
    ) public pure returns (int) {
        int diff = (AP + AR) - B * (PB_U2 - PB_L2 * betta / DIVIDER) / DIVIDER;

        if(diff > B * DB_U2 / DIVIDER) return diff - B * DB_U2 / DIVIDER;

        if(diff < -B * DB_L2 / DIVIDER) return diff + B * DB_L2 / DIVIDER;

        return 0;
    }

    function CL(
        int betta,
        int CP,
        int CR,
        int D,
        int L,
        int E
    ) public pure returns (int) {
        int LDE = L + D + E;
        int diff = (CP + CR) - LDE * (PB_L12 * betta / DIVIDER + PB_U12) / DIVIDER;

        if(diff > LDE * DB_U12 / DIVIDER) return diff - LDE * DB_U12 / DIVIDER;

        if(diff < -LDE * DB_L12 / DIVIDER) return diff + LDE * DB_L12 / DIVIDER;

        return 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// @notice Taker position representation structure
struct TakerPosition {
    address owner; // owner of the position
    uint assetAmount; // amount of tokens
    uint floor; // floor price of the protected tokens
    uint bumpAmount; // locked bump amount for this position
    uint ci; // start position cummulative index
    uint32 start; // timestamp when position was opened
    uint16 risk; // risk in percentage with 100 multiplier (9000 means 90%)
    uint16 term; // term (in days) of protection
    uint192 flags; // option flags
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// @notice Maker position representaion structure
struct MakerPosition {
    address owner; // owner of the position
    uint stableAmount; // amount of stable tokens
    uint bumpAmount; // locked bump amount for this position
    uint ci; // start position cummulative index
    uint32 start; // CI when position was opened
    uint16 term; // term (in days) of protection
    uint16 tier; // tier number (1-5)
    uint192 flags; // option flags
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

struct UserPositions {
    EnumerableSet.UintSet taker;
    EnumerableSet.UintSet maker;
    uint profile;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// @notice Maker position representaion structure
struct Payout {
    //uint bumpAmount;
    uint assetAmount;
    uint stableAmount;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "../struct/MakerPosition.sol";

interface IMakerPosition {
    /// @notice creates a new maker position
    /// @notice takes part of an {amount} to lock as a bond
    /// if deposited bond amount is insufficient
    /// @param amount asset amount to protect
    /// @param tier position tier value
    /// @param term position term value
    /// @param autorenew whether position auto renewing is available
    /// or it`s not
    /// @return id created position id
    /// @dev allowed values of {tier} and {term} are depends of a particular
    /// market and a {Calculation} contract that is uses
    function deposit(
        uint amount,
        uint16 tier,
        uint16 term,
        bool autorenew
    ) external returns (uint id);

    /// @notice protect with bump bond permit only
    /// @notice See more in {deposit}
    function depositWithAutoBondingPermit(
        uint amount,
        uint16 tier,
        uint16 term,
        bool autorenew,
        uint bumpAmount,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint id);

    /// @notice deposit with both stable and bump bond permits
    /// @notice See more in {depositWithPermit}
    /// @param permitStable encoded [deadline, v, r, s] values for stable permit using abi.encode
    /// @param permitBump encoded [deadline, v, r, s] values for bump permit using abi.encode
    function depositWithPermitWithAutoBondingPermit(
        uint amount,
        uint16 tier,
        uint16 term,
        bool autorenew,
        uint bumpAmount,
        bytes memory permitStable,
        bytes memory permitBump
    ) external returns (uint id);

    /// @notice deposit with stable token permit only
    /// @notice See more in {deposit}
    function depositWithPermit(
        uint amount,
        uint16 tier,
        uint16 term,
        bool autorenew,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint id);

    /// @notice closes an existing maker position and claim yield
    /// @notice position can be closed only if position term is over
    /// @param id existing position id
    /// @param withdrawBond says to withdraw deposited bump tokens back to user or not
    function withdraw(uint id, bool withdrawBond) external;

    /// @notice emergency close of an existing maker position
    /// @notice position can be abandoned even if position term is not over
    /// @param id existing position id
    /// @param withdrawBond says to withdraw deposited bump tokens back to user or not
    /// @dev requires {abandonmentPermitted} flag to be true
    function abandon(uint id, bool withdrawBond) external;

    /// @notice toggles an auto renew flag value for existing maker position
    /// @notice can be called only from position owner
    /// @param id existing position id
    function toggleMakerAutorenew(uint id) external;

    /// @param id existing maker position id
    /// @return pos maker position struct
    function getMakerPosition(uint id)
        external
        view
        returns (MakerPosition memory);

    /// @notice emits when new Maker position opens
    /// @param account position owner
    /// @param id created position id
    /// @param amount position asset amount
    /// @param tier position tier value
    /// @param term position term value
    /// @param flags position packed flags
    event Deposit(
        address indexed account,
        uint id,
        uint amount,
        uint16 tier,
        uint16 term,
        uint192 flags,
        uint bumpAmount,
        uint boost,
        uint incentives
    );

    /// @notice emits whenever Taker makes withdraw
    /// @param account position owner
    /// @param id position id
    /// @param reward maker claimed reward
    /// @param assetAmount position claimed asset amount
    /// @param stableAmount position claimed stable amount
    event Withdraw(
        address indexed account,
        uint id,
        int reward,
        uint assetAmount,
        uint stableAmount
    );

    /// @notice emits whenever Taker abandons the position
    /// @param account position owner
    /// @param id position id
    /// @param reward maker claimed reward
    /// @param assetAmount position claimed asset amount
    /// @param stableAmount position claimed stable amount
    event Abandon(
        address indexed account,
        uint id,
        int reward,
        uint assetAmount,
        uint stableAmount
    );        
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "../struct/TakerPosition.sol";

interface ITakerPosition {
    /// @notice opens a new taker position
    /// @notice takes part of an {amount} to lock as a bond
    /// if deposited bond amount is insufficient
    /// @param amount asset amount to protect
    /// @param risk position risk value
    /// @param term position term value
    /// @param autorenew whether position auto renewing is available
    /// or it`s not
    /// @return id created position id
    /// @dev allowed values of {risk} and {term} are depends of a particular
    /// market and a {Calculation} contract that is uses
    function protect(
        uint amount,
        uint16 risk,
        uint16 term,
        bool autorenew
    ) external returns (uint id);

    /// @notice opens a new taker position
    /// @notice takes a part of an position amount to lock as a bond
    /// if deposited bond amount is insufficient
    /// @param risk position risk value
    /// @param term position term value
    /// @param autorenew whether position auto renewing is available
    /// or it`s not
    /// @return id created position id
    /// @dev allowed values of {risk} and {term} are depends of a particular
    /// market and a {Calculation} contract that is uses
    /// @dev position asset amount should be passed to function as msg.value
    function protectNative(
        uint16 risk,
        uint16 term,
        bool autorenew
    ) external payable returns (uint id);

    /// @notice protect with bump bond permit only
    /// @notice See more in {protect}
    function protectWithAutoBondingPermit(
        uint amount,
        uint16 risk,
        uint16 term,
        bool autorenew,
        uint bumpAmount,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint id);

    /// @notice protect with both asset and bump bond permits
    /// @notice See more in {protectWithPermit}
    /// @param permitAsset encoded [deadline, v, r, s] values for asset permit using abi.encode
    /// @param permitBump encoded [deadline, v, r, s] values for bump permit using abi.encode
    function protectWithPermitWithAutoBondingPermit(
        uint amount,
        uint16 risk,
        uint16 term,
        bool autorenew,
        uint bumpAmount,
        bytes memory permitAsset,
        bytes memory permitBump
    ) external returns (uint id);

    /// @notice protect with asset token permit only
    /// @notice See more in {protect}
    function protectWithPermit(
        uint amount,
        uint16 risk,
        uint16 term,    
        bool autorenew,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint id);

    /// @notice closes an existing taker position
    /// @notice position can be closed only if position term is over
    /// @param id taker position id
    /// @param unwrap if market is a wrapped native, this flag is says that asset should be
    /// unwrapped to native or it should be returned as a wrapped native
    /// @param withdrawBond says to withdraw deposited bump tokens back to user or not
    function close(
        uint id,
        bool unwrap,
        bool withdrawBond
    ) external;

    /// @notice closes an existing taker position and claims stable
    /// @notice position can be closed only if position period has passed
    /// @param id taker position id
    /// @param withdrawBond says to withdraw deposited bump tokens back to user or not
    function claim(uint id, bool withdrawBond) external;

    /// @notice cancel taker position
    /// @notice position can be canceled even if position term is not over
    /// @param id taker position id
    /// @param unwrap if market is a wrapped native, this flag is says that asset should be
    /// unwrapped to native or it should be returned as a wrapped native
    /// @param withdrawBond says to withdraw deposited bump tokens back to user or not
    /// @dev requires {cancellationPermitted} flag to be true
    function cancel(
        uint id,
        bool unwrap,
        bool withdrawBond
    ) external;

    /// @notice toggles an auto renew flag value for existing taker position
    /// @notice can be called only from position owner
    /// @param id existing position id
    function toggleTakerAutorenew(uint id) external;

    /// @param id existing maker position id
    /// @return pos taker position struct
    function getTakerPosition(uint id)
        external
        view
        returns (TakerPosition memory);

    /// @notice emits when new Taker position opens
    /// @param account position owner
    /// @param id created position id
    /// @param amount position asset amount
    /// @param floor position asset price floor
    /// @param risk position risk value
    /// @param term position term value
    /// @param flags position packed flags
    event Protect(
        address indexed account,
        uint id,
        uint amount,
        uint floor,
        uint16 risk,
        uint16 term,
        uint192 flags,
        uint bumpAmount,
        uint boost,
        uint incentives
    );

    /// @notice emits whenever Maker makes claim
    /// @param account position owner
    /// @param id position id
    /// @param floor position asset price floor
    /// @param assetAmount position claimed asset amount
    /// @param stableAmount position claimed stable amount
    event Claim(
        address indexed account,
        uint id,
        uint floor,
        uint assetAmount,
        uint stableAmount
    );

    /// @notice emits whenever Maker makes close
    /// @param account position owner
    /// @param id position id
    /// @param premium paid premium
    /// @param assetAmount position claimed asset amount
    /// @param stableAmount position claimed stable amount
    event Close(
        address indexed account,
        uint id,
        uint premium,
        uint assetAmount,
        uint stableAmount
    );

    /// @notice emits whenever Maker cancels a position
    /// @param account position owner
    /// @param id position id
    /// @param premium paid premium
    /// @param assetAmount position claimed asset amount
    /// @param stableAmount position claimed stable amount
    event Cancel(
        address indexed account,
        uint id,
        uint premium,
        uint assetAmount,
        uint stableAmount
    );

}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "../struct/BondConfig.sol";

/// @title IBond
interface IBond {
    /// @return address of token which contract stores
    function BOND_TOKEN_ADDRESS() external view returns (address);

    /// @notice transfers amount from your address to contract
    /// @param depositTo - address on which tokens will be deposited
    /// @param amount - amount of token to store in contract
    function deposit(address depositTo, uint amount) external;

    /// @notice permit version of {deposit} method
    function depositWithPermit(
        address depositTo,
        uint amount,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /// @notice transfers amount from given address to contract
    /// @dev should be called only from authorized accounts
    /// @param amount - amount of token to withdraw from contract
    /// @param amount - amount of token to withdraw from contract
    function withdraw(address withdrawOf, uint amount) external;

    /// @notice transfers amount from your address to contract
    /// @param amount - amount of token to withdraw from contract
    function withdraw(uint amount) external;

    /// @notice unlocks amount of token in contract
    /// @param _owner - owner of the position
    /// @param bondAmount - amount of bond token to unlock
    function unlock(address _owner, uint bondAmount) external;

    /// @notice calculates taker's bond to lock in contract
    /// @param token - token address
    /// @param amount - amount of asset token
    /// @param risk - risk in percentage with 100 multiplier (9000 means 90%)
    /// @param term - term (in days) of protection
    /// @return bondAmount to lock based on taker position
    function takerBond(
        address token,
        uint amount,
        uint16 risk,
        uint16 term
    ) external view returns (uint bondAmount);

    /// @notice calculates maker's bond to lock in contract
    /// @param token - token address
    /// @param amount - amount of stable token to lock
    /// @param risk - risk number (1-5)
    /// @param term - term (in days) of protection
    /// @return bondAmount to lock based on maker position
    function makerBond(
        address token,
        uint amount,
        uint16 risk,
        uint16 term
    ) external view returns (uint bondAmount);

    /// @notice how much of bond amount will be reduced for taker position
    function takerToSwap(address token, uint bondAmount)
        external
        view
        returns (uint amount);

    /// @notice how much of bond amount will be reduced for maker position
    function makerToSwap(address token, uint bondAmount)
        external
        view
        returns (uint amount);

    function autoLockBondTakerPosition(
        address recipient,
        address token,
        uint amount,
        uint16 risk,
        uint16 term,
        uint boostAmount,
        uint incentivesAmount              
    )
        external
        returns (
            uint bondAmount,
            uint toTransfer,
            uint toReduce
        );

    function autoLockBondMakerPosition(
        address recipient,
        address token,
        uint amount,
        uint16 risk,
        uint16 term,
        uint boostAmount,
        uint incentivesAmount              
    )
        external
        returns (
            uint bondAmount,
            uint toTransfer,
            uint toReduce
        );

    /// @notice calculates amount of bond position for taker
    function calcBondSizeForTakerPosition(
        address recipient,
        address token,
        uint amount,
        uint16 risk,
        uint16 term  
    )
        external
        view
        returns (
            uint toLock,
            uint toTransfer,
            uint toReduce
        );

    /// @notice calculates amount of bond position for maker
    function calcBondSizeForMakerPosition(
        address recipient,
        address token,
        uint amount,
        uint16 risk,
        uint16 term     
    )
        external
        view
        returns (
            uint toLock,
            uint toTransfer,
            uint toReduce
        );

    /// @notice locks amount of deposited bond
    function lock(address addr, uint amount) external;

    /// @param addr - address of user
    /// @return amount - locked amount of particular user
    function lockedOf(address addr) external view returns (uint amount);

    /// @param addr - address of user
    /// @return amount - deposited amount of particular user
    function balanceOf(address addr) external view returns (uint amount);

    /// @notice transfer locked bond between accounts
    function transferLocked(
        address from,
        address to,
        uint amount
    ) external;

    /// @notice Calculate Bond multipliers for given token
    function calcBonding(
        address token,
        uint bumpPrice,
        uint assetPrice
    ) external;

    function setBondTheta(
        address token, 
        uint thetaAsset1, 
        uint thetaStable1, 
        uint thetaAsset2, 
        uint thetaStable2 
    ) external;

    /// @notice liquidate user locked bonds (used in liquidation flow)
    function liquidate(address from, uint amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// @title BondConfig
struct BondConfig {
    uint bumpPerAsset; 
    uint bumpPerStable; 
    uint assetPerBump;  
    uint stablePerBump;
    uint thetaAsset1;
    uint thetaAsset2;
    uint thetaStable1;
    uint thetaStable2;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

interface ITakerPositionRate {
    function getTakerRate(uint16 risk, uint16 term)
        external
        pure
        returns (uint);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

interface IMakerPositionRate {
    function getMakerRate(uint16 tier, uint16 term)
        external
        pure
        returns (uint, uint);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "../struct/MarketState.sol";
interface IPAPCalculation {

    /// @notice Calculate premium against the asset pool
    /// @param toCurrentTime - force update to current time
    function calcNewPaps(bool toCurrentTime)
    external
    view
    returns (
        uint papsInAsset,
        uint papsInStable,
        int _lastPrice,
        uint _lastTimestamp,
        uint80 _lastRoundId,
        uint _probabilityOfClaim
    );
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

interface IYieldCalculation {
    function YIELD_EPSILON() external pure returns (uint);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

struct BoostingParameters {
    int w1max;
    int w11max;
    int w1;
    int lrr1;
    int w11;
    int lrr11;
    int pbl1;
    int pbl11;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

struct MarketState {
    int AP; // Asset pool (in tokens with DIVIDER precision)
    int AR; // Asset reserve (in tokens with DIVIDER precision)
    int CP; // Capital pool with DIVIDER precision
    int CR; // Capital reserve with DIVIDER precision
    int B; // Book (in tokens with DIVIDER precision)
    int L; // Liability in ORACLE precision
    int D; // Debt with DIVIDER precision
    int E; // Yield target value with DIVIDER precision (can be negative)
    int RWA; // Risk weighted asset pool
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "../struct/TakerPosition.sol";
import "../struct/MakerPosition.sol";
import "../struct/MarketState.sol";
import "../struct/RebalanceAmount.sol";

/// @notice Rebalance parameters calculation
interface IRebalanceCalculation {
    function rebalanceAmount() external view returns (RebalanceAmount memory);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

struct RebalanceAmount {
    int deltaAP;
    int deltaAR;
    int deltaCP;
    int deltaCR;
    int deltaL;
    int deltaB;
    int deltaE;
    uint sellToken;
    uint sellStable;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "../interfaces/IMarket.sol";
import "../interfaces/IState.sol";
import "../interfaces/IProtocolConfig.sol";

import "./Precisions.sol";
import "./LRBands.sol";

/// @title CalculationBase
/// @notice Base calculation contract with nessesary constants and functions
abstract contract CalculationBase is Precisions, LRBands {

    IProtocolConfig public immutable config;
    IState public immutable state;
    IMarket public immutable market;
    IERC20 public immutable token;
    IERC20 public immutable stable;

    constructor(
        address _config,
        address _state,
        address _token,
        uint _DIVIDER_ASSET,
        uint _DIVIDER_STABLE
    ) Precisions(_DIVIDER_ASSET, _DIVIDER_STABLE) {
        config = IProtocolConfig(_config);
        state = IState(_state);
        market = IMarket(IProtocolConfig(_config).getMarket(_token));
        token = IERC20(_token);
        stable = IERC20(IProtocolConfig(_config).getStable());
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "../interfaces/IYieldCalculation.sol";

/// @notice Liquidity Rations Lambdas
abstract contract YieldCalculation is IYieldCalculation {
    uint constant public override YIELD_EPSILON = 0.000273972602739726 * 10**18;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "../interfaces/IPAPCalculation.sol";
import "./PRFImplementation.sol";
import "./LRFImplementation.sol";
import "./CalculationBase.sol";

/// @notice Liquidity Rations Lower and Upper Bands
abstract contract PAPCalculation is
    CalculationBase,
    PRFImplementation,
    LRFImplementation,
    IPAPCalculation
{

    uint80 constant maxNumberIterations = 10;

    int constant L_PRF = (DIVIDER * 2) / 10;
    int constant L_LRF = (DIVIDER * 8) / 10;
    int constant L_PAP = DIVIDER * 150;

    /// @inheritdoc IPAPCalculation
    function calcNewPaps(bool toCurrentTime)
        public 
        view
        override
        returns (
            uint papsInAsset,
            uint papsInStable,
            int _lastPrice,
            uint _lastTimestamp,
            uint80 _lastRoundId,
            uint _probabilityOfClaim
        )
    {

        (int lastUsedPrice, uint lastUsedTimestamp, uint80 lastUsedRoundId) = state.lastUsedPrice();
        _probabilityOfClaim = state.probabilityOfClaim();
        MarketState memory marketState = state.getStateAsStruct();

        uint80 currentId;
        { // Stack too deep
            int _price;
            uint currentTimestamp;
            (_price, currentTimestamp, currentId) = IState(state).price();

            if (marketState.RWA == 0) return (0, 0, _price, currentTimestamp, currentId, 0);

            if (toCurrentTime && lastUsedRoundId + maxNumberIterations < currentId) {
                revert("RC: can-not-update");
            }
            if(lastUsedRoundId + maxNumberIterations < currentId) {
                currentId = lastUsedRoundId + maxNumberIterations;
            }
        }

        int iPrice;
        uint pInAsset;
        // uint pInStable;
        {
            for (uint80 i = lastUsedRoundId + 1; i <= currentId; i++) {
                uint pap;
                uint iTimestamp;
                (iPrice, iTimestamp) = IState(state).priceAt(i);

                // if we have roundId gap - just skip it
                if(iTimestamp == 0) continue;
        
                if (iTimestamp <= lastUsedTimestamp) continue;

                if(SignedMath.abs(iPrice * DIVIDER / lastUsedPrice - DIVIDER) < UDIVIDER * 1 / 2 / 100) continue;
                
                (pap, _probabilityOfClaim) = _pap(iPrice, lastUsedPrice, iTimestamp, lastUsedTimestamp, marketState);
                // papsInAsset += (iTimestamp - lastUsedTimestamp) * pap / 1 days;
                uint p = (iTimestamp - lastUsedTimestamp) * pap / 1 days;
                pInAsset += p;
                // pInStable += uint(iPrice) * p * DIVIDER_STABLE / DIVIDER_ORACLE;
                lastUsedTimestamp = iTimestamp;
                lastUsedPrice = iPrice;
            }
        }

        if (toCurrentTime){
            uint pap;
            (pap, _probabilityOfClaim) = _pap(iPrice, lastUsedPrice, lastUsedTimestamp, block.timestamp, marketState);
            uint p = (block.timestamp - lastUsedTimestamp) * pap / 1 days;
            // papsInStable = pInStable + uint(iPrice) * p * DIVIDER_STABLE / DIVIDER_ORACLE;
            papsInAsset = pInAsset + p;

            return (papsInAsset, papsInStable, lastUsedPrice, block.timestamp, currentId, _probabilityOfClaim);
        } else {
            // papsInStable = pInStable;
            papsInAsset = pInAsset;

            return (papsInAsset, papsInStable, lastUsedPrice, lastUsedTimestamp, currentId, _probabilityOfClaim);
        }

    }

    function _pap(
        int currentPrice,
        int previousPrice,
        uint currentTimeStamp,
        uint previousTimeStamp,
        MarketState memory marketState
    ) internal pure returns (uint _PAP, uint _probabilityOfClaim) {

        if (marketState.B == 0) return (0, 0);

        currentPrice = (DIVIDER * currentPrice) / int(DIVIDER_ORACLE);
        previousPrice = (DIVIDER * previousPrice) / int(DIVIDER_ORACLE);

        // calculate price risk factor
        int u1 = U1(
            currentPrice,
            previousPrice,
            currentTimeStamp,
            previousTimeStamp
        );
        int _PRF = PRF(u1);

        // calculate probability of claim
        int probabilityOfClaim = pClaim(currentPrice, marketState.B, marketState.L, _PRF);

        // calculate liquidity risk factor
        int _LRF = LRF(
            probabilityOfClaim,
            marketState.AP,
            marketState.AR,
            marketState.CP,
            marketState.CR,
            marketState.B,
            marketState.L,
            marketState.D,
            marketState.E
        );

        // calculate premium against the asset pool
        return (
            uint((((((L_PRF * _PRF + L_LRF * _LRF) / DIVIDER) * marketState.B) / DIVIDER) *
                DIVIDER) / L_PAP),
            uint(probabilityOfClaim)
        );
    }

}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "../interfaces/ITakerPositionRate.sol";

/// @notice NFT token for taker position
abstract contract TakerPositionRate is ITakerPositionRate {

    uint public constant T_150_70 = 1.00 * 10**18;
    uint public constant T_120_70 = 1.15 * 10**18;
    uint public constant T_90_70 = 1.32 * 10**18;
    uint public constant T_60_70 = 1.52 * 10**18;
    uint public constant T_30_70 = 1.75 * 10**18;

    uint public constant T_150_80 = 1.30 * 10**18;
    uint public constant T_120_80 = 1.50 * 10**18;
    uint public constant T_90_80 = 1.72 * 10**18;
    uint public constant T_60_80 = 1.98 * 10**18;
    uint public constant T_30_80 = 2.27 * 10**18;

    uint public constant T_150_85 = 1.69 * 10**18;
    uint public constant T_120_85 = 1.94 * 10**18;
    uint public constant T_90_85 = 2.24 * 10**18;
    uint public constant T_60_85 = 2.57 * 10**18;
    uint public constant T_30_85 = 2.96 * 10**18;

    uint public constant T_150_90 = 2.20 * 10**18;
    uint public constant T_120_90 = 2.53 * 10**18;
    uint public constant T_90_90 = 2.91 * 10**18;
    uint public constant T_60_90 = 3.34 * 10**18;
    uint public constant T_30_90 = 3.84 * 10**18;

    uint public constant T_150_95 = 2.86 * 10**18;
    uint public constant T_120_95 = 3.28 * 10**18;
    uint public constant T_90_95 = 3.78 * 10**18;
    uint public constant T_60_95 = 4.34 * 10**18;
    uint public constant T_30_95 = 5.00 * 10**18;


    function getTakerRate(uint16 risk, uint16 term)
        public
        pure
        override
        returns (uint)
    {
        if (risk == 7000) {
            if (term == 30) return T_30_70;
            if (term == 60) return T_60_70;
            if (term == 90) return T_90_70;
            if (term == 120) return T_120_70;
            if (term == 150) return T_150_70;
        } else if (risk == 8000) {
            if (term == 30) return T_30_80;
            if (term == 60) return T_60_80;
            if (term == 90) return T_90_80;
            if (term == 120) return T_120_80;
            if (term == 150) return T_150_80;
        } else if (risk == 8500) {
            if (term == 30) return T_30_85;
            if (term == 60) return T_60_85;
            if (term == 90) return T_90_85;
            if (term == 120) return T_120_85;
            if (term == 150) return T_150_85;
        } else if (risk == 9000) {
            if (term == 30) return T_30_90;
            if (term == 60) return T_60_90;
            if (term == 90) return T_90_90;
            if (term == 120) return T_120_90;
            if (term == 150) return T_150_90;
        } else if (risk == 9500) {
            if (term == 30) return T_30_95;
            if (term == 60) return T_60_95;
            if (term == 90) return T_90_95;
            if (term == 120) return T_120_95;
            if (term == 150) return T_150_95;
        }

        revert("TPR: wrong-rate");
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "../interfaces/IMakerPositionRate.sol";

/// @notice NFT token for taker position
abstract contract MakerPositionRate is IMakerPositionRate {
    uint public constant M_30_05_POSITIVE = 1.25 * 10**18;
    uint public constant M_60_05_POSITIVE = 1.35 * 10**18;
    uint public constant M_90_05_POSITIVE = 1.45 * 10**18;
    uint public constant M_120_05_POSITIVE = 1.55 * 10**18;
    uint public constant M_150_05_POSITIVE = 1.65 * 10**18;

    uint public constant M_30_04_POSITIVE = 1.15 * 10**18;
    uint public constant M_60_04_POSITIVE = 1.25 * 10**18;
    uint public constant M_90_04_POSITIVE = 1.35 * 10**18;
    uint public constant M_120_04_POSITIVE = 1.45 * 10**18;
    uint public constant M_150_04_POSITIVE = 1.55 * 10**18;

    uint public constant M_30_03_POSITIVE = 1.05 * 10**18;
    uint public constant M_60_03_POSITIVE = 1.15 * 10**18;
    uint public constant M_90_03_POSITIVE = 1.25 * 10**18;
    uint public constant M_120_03_POSITIVE = 1.35 * 10**18;
    uint public constant M_150_03_POSITIVE = 1.45 * 10**18;

    uint public constant M_30_02_POSITIVE = 0.95 * 10**18;
    uint public constant M_60_02_POSITIVE = 1.05 * 10**18;
    uint public constant M_90_02_POSITIVE = 1.15 * 10**18;
    uint public constant M_120_02_POSITIVE = 1.25 * 10**18;
    uint public constant M_150_02_POSITIVE = 1.35 * 10**18;

    uint public constant M_30_01_POSITIVE = 0.85 * 10**18;
    uint public constant M_60_01_POSITIVE = 0.95 * 10**18;
    uint public constant M_90_01_POSITIVE = 1.05 * 10**18;
    uint public constant M_120_01_POSITIVE = 1.15 * 10**18;
    uint public constant M_150_01_POSITIVE = 1.25 * 10**18;

    uint public constant M_30_05_NEGATIVE = 1.75 * 10**18;
    uint public constant M_60_05_NEGATIVE = 1.65 * 10**18;
    uint public constant M_90_05_NEGATIVE = 1.55 * 10**18;
    uint public constant M_120_05_NEGATIVE = 1.45 * 10**18;
    uint public constant M_150_05_NEGATIVE = 1.35 * 10**18;

    uint public constant M_30_04_NEGATIVE = 1.60 * 10**18;
    uint public constant M_60_04_NEGATIVE = 1.50 * 10**18;
    uint public constant M_90_04_NEGATIVE = 1.40 * 10**18;
    uint public constant M_120_04_NEGATIVE = 1.30 * 10**18;
    uint public constant M_150_04_NEGATIVE = 1.20 * 10**18;

    uint public constant M_30_03_NEGATIVE = 1.45 * 10**18;
    uint public constant M_60_03_NEGATIVE = 1.35 * 10**18;
    uint public constant M_90_03_NEGATIVE = 1.25 * 10**18;
    uint public constant M_120_03_NEGATIVE = 1.15 * 10**18;
    uint public constant M_150_03_NEGATIVE = 1.05 * 10**18;

    uint public constant M_30_02_NEGATIVE = 1.30 * 10**18;
    uint public constant M_60_02_NEGATIVE = 1.15 * 10**18;
    uint public constant M_90_02_NEGATIVE = 1.05 * 10**18;
    uint public constant M_120_02_NEGATIVE = 1.00 * 10**18;
    uint public constant M_150_02_NEGATIVE = 0.90 * 10**18;

    uint public constant M_30_01_NEGATIVE = 1.15 * 10**18;
    uint public constant M_60_01_NEGATIVE = 1.05 * 10**18;
    uint public constant M_90_01_NEGATIVE = 0.95 * 10**18;
    uint public constant M_120_01_NEGATIVE = 0.85 * 10**18;
    uint public constant M_150_01_NEGATIVE = 0.75 * 10**18;

    function getMakerRate(uint16 tier, uint16 term)
        public
        pure
        override
        returns (uint, uint)
    {
        if (tier == 5 ) {
            if (term == 30) return (M_30_05_POSITIVE, M_30_05_NEGATIVE);
            if (term == 60) return (M_60_05_POSITIVE, M_60_05_NEGATIVE);
            if (term == 90) return (M_90_05_POSITIVE, M_90_05_NEGATIVE);
        } else if (tier == 4) {
            if (term == 30) return (M_30_04_POSITIVE, M_30_04_NEGATIVE);
            if (term == 60) return (M_60_04_POSITIVE, M_60_04_NEGATIVE);
            if (term == 90) return (M_90_04_POSITIVE, M_90_04_NEGATIVE);
        } else if (tier == 3) {
            if (term == 30) return (M_30_03_POSITIVE, M_30_03_NEGATIVE);
            if (term == 60) return (M_60_03_POSITIVE, M_60_03_NEGATIVE);
            if (term == 90) return (M_90_03_POSITIVE, M_90_03_NEGATIVE);
        } else if (tier == 2) {
            if (term == 30) return (M_30_02_POSITIVE, M_30_02_NEGATIVE);
            if (term == 60) return (M_60_02_POSITIVE, M_60_02_NEGATIVE);
            if (term == 90) return (M_90_02_POSITIVE, M_90_02_NEGATIVE);
        } else if (tier == 1) {
            if (term == 30) return (M_30_01_POSITIVE, M_30_01_NEGATIVE);
            if (term == 60) return (M_60_01_POSITIVE, M_60_01_NEGATIVE);
            if (term == 90) return (M_90_01_POSITIVE, M_90_01_NEGATIVE);
        }

        revert("MPR: wrong-rate");
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "../interfaces/IFeeCalculation.sol";

/// @title Fee Calculation logic
contract FeeCalculation is IFeeCalculation {
    uint private constant TAKER_FEE_PER_DAY = 85;
    uint private constant MAKER_FEE_PER_DAY = 85;
    uint private constant FEE_DIVIDER = 1000000;

    /// @notice calculate fee for maker position
    function calcMakerPositionFee(uint amount, uint32 start)
        public
        view
        override
        returns (uint fee)
    {
        fee =
            (((amount * (block.timestamp - start)) / 1 days) *
                MAKER_FEE_PER_DAY) /
            FEE_DIVIDER;
    }

    /// @notice calculate fee for taker position
    function calcTakerPositionFee(uint amount, uint32 start)
        public
        view
        override
        returns (uint fee)
    {
        fee =
            (((amount * (block.timestamp - start)) / 1 days) *
                TAKER_FEE_PER_DAY) /
            FEE_DIVIDER;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/Math.sol";

import "../interfaces/IMarket.sol";
import "../interfaces/IProtocolConfig.sol";
import "../interfaces/IRebalanceCalculation.sol";

import "./LRFImplementation.sol";
import "./CalculationBase.sol";

import "../struct/BoostingParameters.sol";

import "hardhat/console.sol";

/// @title Implements rebalance calculation
abstract contract BoostingCalculation is CalculationBase, LRFImplementation {
    
    function _boostParameters() internal view returns (BoostingParameters memory) {
        // get market variables
        MarketState memory s = state.getStateAsStruct();

        if (s.B == 0)
            return
                BoostingParameters({
                    w1max: W_MAX1,
                    w11max: W_MAX11,
                    lrr1: 0, //LRR1(pc),
                    lrr11: 0, //LRR11(pc),
                    w1: W_MAX1, //W1(pc, s.AP, s.B ),
                    w11: W_MAX11, //W11(pc, s.CP, s.L, s.D, s.Y ),
                    pbl1: PB_L1,
                    pbl11: PB_L11
                });

        // get probability of claim
        int beta = int(state.probabilityOfClaim());

        return
            BoostingParameters({
                w1max: W_MAX1,
                w11max: W_MAX11,
                lrr1: LRR1(beta),
                lrr11: LRR11(beta),
                w1: W1(beta, s.AP, s.B),
                w11: W11(beta, s.CP, s.L, s.D, s.E),
                pbl1: PB_L1,
                pbl11: PB_L11
            });
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

library OptionFlagsHelper {
    uint192 internal constant EMPTY = 0;

    uint192 private constant AUTORENEW_OFFSET = 0;
    uint192 private constant AUTORENEW_MASK = uint192(1) << AUTORENEW_OFFSET; // size 1

    uint192 private constant AUTORENEW_TERMS_OFFSET = 1;
    uint192 private constant AUTORENEW_TERMS_MASK = uint192(0xFF) << AUTORENEW_TERMS_OFFSET; //size 8

    uint192 private constant FLAG2_OFFSET = 9;
    uint192 private constant FLAG2_MASK = uint192(1) << FLAG2_OFFSET; // size 1

    function getAutorenew(uint192 flags) internal pure returns (bool) {
        return (flags & AUTORENEW_MASK) > 0;
    }

    function setAutorenew(uint192 flags, bool autorenew)
        internal
        pure
        returns (uint192)
    {
        if (autorenew) {
            return flags | AUTORENEW_MASK;
        } else {
            return flags & (~AUTORENEW_MASK);
        }
    }

    function getAutorenewTerms(uint192 flags) internal pure returns (uint8 terms) {
        terms =  uint8((flags & AUTORENEW_TERMS_MASK) >> AUTORENEW_TERMS_OFFSET);
        return terms > 0 ? terms : 1;
    }

    function setAutorenewTerms(uint192 flags, uint8 value)
        internal
        pure
        returns (uint192)
    {        
        return (flags & ~AUTORENEW_TERMS_MASK) | (uint192(value) << AUTORENEW_TERMS_OFFSET);
    }

    function getFlag2(uint192 flags) internal pure returns (bool) {
        return (flags & FLAG2_MASK) > 0;
    }

    function setFlag2(uint192 flags, bool autorenew)
        internal
        pure
        returns (uint192)
    {
        if (autorenew) {
            return flags | FLAG2_MASK;
        } else {
            return flags & (~FLAG2_MASK);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "../struct/TakerPosition.sol";
import "../struct/MakerPosition.sol";
import "../struct/MarketState.sol";
import "../struct/Payout.sol";

interface IState {
    /// @return current asset Pool value
    function AP() external view returns (uint);

    /// @return current asset Reserve value
    function AR() external view returns (uint);

    /// @return current book value
    function B() external view returns (uint);

    /// @return current liability value in price oracle precision
    function L() external view returns (uint);

    /// @return current capital Pool value
    function CP() external view returns (uint);

    /// @return current capital Reserve value
    function CR() external view returns (uint);

    /// @return current debt value
    function D() external view returns (uint);

    /// @return current yield target value
    function E() external view returns (uint);

    /// @return current risk weighted asset pool value
    function RWA() external view returns (uint);

    /// @return current risk weighted liability value
    function RWL() external view returns (uint);

    /// @return current risk weighted capital value with positive rate
    function RWCp() external view returns (uint);

    /// @return current risk weighted capital value with negative rate
    function RWCn() external view returns (uint);

    /// @notice current calculated probability of claim for lastPrice
    function probabilityOfClaim() external view returns (uint);

    /// @notice create new taker position state callback
    /// @param assetAmount amount of asset token
    /// @param risk position risk value
    /// @param term position term value
    /// @param floor position floor value
    function newTakerPosition(
        uint assetAmount,
        uint16 risk,
        uint16 term,
        uint floor
    ) external;

    /// @notice create taker position state callback
    /// @param assetAmount amount of asset token
    /// @param risk position risk value
    /// @param term position term value
    /// @param floor position floor value
    /// @param payout payout stuct value
    function closeTakerPosition(
        uint assetAmount,
        uint16 risk,
        uint16 term,
        uint floor,
        uint premium,
        Payout calldata payout
    ) external;

    /// @notice claim on taker position state callback
    /// @param assetAmount amount of asset token
    /// @param risk position risk value
    /// @param term position term value
    /// @param floor position floor value
    /// @param payout payout stuct value
    function claimTakerPosition(
        uint assetAmount,
        uint16 risk,
        uint16 term,
        uint floor,
        uint premium,
        Payout calldata payout
    ) external;

    /// @notice create new maker position state callback
    /// @param stableAmount amount of stable token
    /// @param tier position tier value
    /// @param term position term value
    function newMakerPosition(
        uint stableAmount,
        uint16 tier,
        uint16 term
    ) external;

    /// @notice close maker position state callback
    /// @param stableAmount amount of stable token
    /// @param tier position tier value
    /// @param term position term value
    /// @param yield position yield value
    /// @param payout payout stuct value
    function closeMakerPosition(
        uint stableAmount,
        uint16 tier,
        uint16 term,
        int yield,
        Payout calldata payout
    ) external;

    /// @notice returns asset information from a price feed
    /// @return _price current asset price
    /// @return _updatedAt price updated at timestamp
    /// @return _roundId latest price update id
    function price()
        external
        view
        returns (
            int _price,
            uint _updatedAt,
            uint80 _roundId
        );

    /// @notice returns last used price information
    /// @return _price last used asset price
    /// @return _updatedAt last used price updated at timestamp
    /// @return _roundId last used price update id
    function lastUsedPrice()
        external
        view
        returns (
            int _price,
            uint _updatedAt,
            uint80 _roundId
        );

    /// @notice returns price info by roundId used price information
    /// @param roundId price update round id
    /// @return _price price by a given round id
    /// @return _updatedAt price updated at by a given round id
    function priceAt(uint80 roundId)
        external
        view
        returns (int _price, uint _updatedAt);

    /// @notice updates state veriable by a given delta values
    /// @param deltaAP delta Asset Pool value
    /// @param deltaAR delta Asset Reserve value
    /// @param deltaCP delta Capital Pool value
    /// @param deltaCR delta Capital Reserve value
    /// @param deltaY delta Yeld target value
    function update(
        int deltaAP,
        int deltaAR,
        int deltaCP,
        int deltaCR,
        int deltaY
    ) external;

    /// @notice updates state variables to current time
    function updateStateToCurrentTime() external;

    /// @notice updates state variables to last price
    function updateStateToLastPrice() external;

    /// @return state variables as a struct
    function getStateAsStruct() external view returns (MarketState memory);

    /// @notice returns state variables by a single function call
    function getState()
        external
        view
        returns (
            uint AP,
            uint AR,
            uint CP,
            uint CR,
            uint B,
            uint L,
            uint D,
            uint Y
        );

    /// @notice set a rebalancer contract address
    /// @param _rebalancer new rebalancer address
    function setRebalancer(address _rebalancer) external;

    /// @notice set a risk calculation contract address
    /// @param _calc new risk calculation address
    function setRiskCalc(address _calc) external;

    /// @notice calculates a cumulative index for taker
    /// @return cia cummulative index (in assets)
    /// @return cis cummulative index (in stables)
    function calcCI()
        external
        view
        returns (
            uint cia,
            uint cis
        );

    function ciTakerAsset() external view returns (uint);

    function ciTakerStable() external view returns (uint);

    function ciMaker() external view returns (uint);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

abstract contract Precisions {
    uint public constant DIVIDER_PRECISION = 18; // DIVIDER that used in all calculation

    uint public constant DIVIDER_ORACLE_PRECISION = 8; // oracle divider

    uint public constant UDIVIDER = (10**DIVIDER_PRECISION);
    int public constant DIVIDER = int(10**DIVIDER_PRECISION);
    uint public constant DIVIDER_ORACLE = (10**DIVIDER_ORACLE_PRECISION);

    uint public immutable DIVIDER_ASSET;
    uint public immutable DIVIDER_STABLE;

    constructor(uint _DIVIDER_ASSET, uint _DIVIDER_STABLE) {
        DIVIDER_STABLE = _DIVIDER_STABLE;
        DIVIDER_ASSET = _DIVIDER_ASSET;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

/// @notice Liquidity Rations Lower and Upper Bands
abstract contract LRBands {

    int public constant PB_L1 =   0.5 * 10**18;
    int public constant PB_U1 =     1 * 10**18;
    int public constant DB_L1 =  -0.1 * 10**18;
    int public constant DB_U1 =   0.1 * 10**18;

    int public constant PB_L2 =   0.8 * 10**18;
    int public constant PB_U2 =   1.3 * 10**18;
    int public constant DB_L2 =  -0.1 * 10**18;
    int public constant DB_U2 =   0.1 * 10**18;

    int public constant PB_L11 =  0.9 * 10**18;
    int public constant PB_U11 =  1.3 * 10**18;
    int public constant DB_L11 = -0.1 * 10**18;
    int public constant DB_U11 =  0.1 * 10**18;

    int public constant PB_L12 =  1.1 * 10**18;
    int public constant PB_U12 =  1.4 * 10**18;
    int public constant DB_L12 = -0.1 * 10**18;
    int public constant DB_U12 =  0.1 * 10**18;

}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "./Precisions.sol";

/// @notice Liquidity Rations Lower and Upper Bands
abstract contract PRFImplementation is Precisions {

    int constant U1_TERM = DIVIDER * 7 days;

    int constant U1_MAX = DIVIDER * 10;

    int constant U1_REF = DIVIDER * (- 1) / 2; // -0.5
    int constant U1_SHIFT = DIVIDER * 2;

    int constant U1_SCALE_P = DIVIDER * 5;
    int constant U1_SCALE_N = DIVIDER * 10;

    int constant PRF_MAX = DIVIDER * 10;

    function U1(
        int currentPrice,
        int previousPrice,
        uint currentTime,
        uint previousTime
    ) public pure returns (int) {
        if (previousPrice == 0 || currentTime <= previousTime) return U1_MAX;

        int alpha = (((currentPrice * DIVIDER) / previousPrice + U1_SHIFT * U1_REF / DIVIDER) *
            U1_TERM) /
            (int(currentTime) - int(previousTime)) /
            DIVIDER;

        int shock = alpha > 0 ? (U1_SCALE_P * alpha) / DIVIDER : (-U1_SCALE_N * alpha) / DIVIDER;

        if (shock > U1_MAX) shock = U1_MAX;

        return shock;
    }

    function PRF(int _u1) public pure returns (int) {
        return (_u1 * DIVIDER) / PRF_MAX;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SignedMath.sol";

import "./CalculationBase.sol";

/// @notice Liquidity Risk Factor calculation
abstract contract LRFImplementation is
    CalculationBase
{

    int constant L_MIN1 = DIVIDER * 0;
    int constant L_SCALE1 = DIVIDER * 1;
    int constant L_SHIFT1 = DIVIDER * 1;

    int constant L_MIN2 = DIVIDER * 0;
    int constant L_SCALE2 = DIVIDER * 1;
    int constant L_SHIFT2 = DIVIDER * 1;

    int constant L_MIN11 = DIVIDER * 0;
    int constant L_SCALE11 = DIVIDER * 1;
    int constant L_SHIFT11 = DIVIDER * 1;

    int constant L_MIN12 = DIVIDER * 0;
    int constant L_SCALE12 = DIVIDER * 1;
    int constant L_SHIFT12 = DIVIDER * 1;

    int constant W_MAX1 = DIVIDER * 1;
    int constant W_MAX2 = DIVIDER * 1;
    int constant W_MAX11 = DIVIDER * 1;
    int constant W_MAX12 = DIVIDER * 1;

    int constant V_MAX = DIVIDER * 1;
    int constant VRF_MAX = DIVIDER * 1;
    int constant PRFVRF_MAX = DIVIDER * 2;
    int constant LRF_MAX = DIVIDER * 8;

    int constant LV_SCALE = DIVIDER * 1;

    function VRF(
        int price,
        int B,
        int L
    ) public pure returns (int) {
        int at = B > 0 && price > 0
            ? (DIVIDER * L) / ((B * price) / DIVIDER)
            : int(0);
        int vt = SignedMath.min(V_MAX, (LV_SCALE * at * at) / DIVIDER / DIVIDER);
        return (DIVIDER * vt) / VRF_MAX;
    }

    function pClaim(
        int price,
        int B,
        int L,
        int _PRF
    ) public pure returns (int) {
        return (VRF(price, B, L) + _PRF) * DIVIDER / PRFVRF_MAX;
    }

    function W1(
        int beta,
        int AP,
        int B
    ) public pure returns (int) {
        if (B == 0) return W_MAX1;
        int a = (DIVIDER * (AP)) / (B);
        int r = LRR1(beta);
        return
            SignedMath.min(
                W_MAX1,
                L_MIN1 +
                    ((L_SCALE1 * (a - L_SHIFT1 * r / DIVIDER)**2 / DIVIDER)) / DIVIDER
            );
    }

    function W2(
        int beta,
        int AP,
        int AR,
        int B
    ) public pure returns (int) {
        if (B == 0) return W_MAX2;
        int a = (DIVIDER * (AP + AR)) / (B);
        int r = LRR2(beta);
        return
            SignedMath.min(
                W_MAX2,
                L_MIN2 +
                    ((L_SCALE2 * (a - L_SHIFT2 * r / DIVIDER)**2 / DIVIDER)) / DIVIDER
            );
    }

    function W11(
        int beta,
        int CP,
        int L,
        int D,
        int E
    ) public pure returns (int) {
        if (L == 0) return W_MAX11;
        int a = (DIVIDER * CP) / (L + D + E);
        int r = LRR11(beta);
        if (a > L_SHIFT11 * r / DIVIDER)
            return SignedMath.min(W_MAX11, L_MIN11 + (L_SCALE11 * DIVIDER) / (a - L_SHIFT11 * r / DIVIDER));
        else return W_MAX11;
    }

    function W12(
        int beta,
        int CP,
        int CR,
        int L,
        int D,
        int E
    ) public pure returns (int) {
        if (L == 0) return W_MAX12;
        int a = (DIVIDER * (CP + CR) / (L + D + E));
        int r = LRR12(beta);
        if (a > L_SHIFT12 * r / DIVIDER)
            return SignedMath.min(W_MAX12, L_MIN12 + (L_SCALE12 * DIVIDER) / (a - L_SHIFT12 * r / DIVIDER));
        else return W_MAX12;
    }

    function LRR1(int beta) public pure returns (int) {
        return (-PB_L1 * beta) / DIVIDER + PB_U1;
    }

    function LRR2(int beta) public pure returns (int) {
        return (-PB_L2 * beta) / DIVIDER + PB_U2;
    }

    function LRR11(int beta) public pure returns (int) {
        return PB_L11 * beta / DIVIDER + PB_U11;
    }

    function LRR12(int beta) public pure returns (int) {
        return PB_L12 * beta / DIVIDER + PB_U12;
    }

    function LRF(
        int beta,
        int AP,
        int AR,
        int CP,
        int CR,
        int B,
        int L,
        int D,
        int E
    ) public pure returns (int) {
        int w1 = W1(beta, AP, B);
        int w2 = W2(beta, AP, AR, B);
        int w11 = W11(beta, CP, L, D, E);
        int w12 = W12(beta, CP, CR, L, D, E);
        int _LRF = (DIVIDER * (w1 + w2 + w11 + w12)) / LRF_MAX;
        return _LRF;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

interface IFeeCalculation {
    function calcMakerPositionFee(uint amount, uint32 start)
        external
        view
        returns (uint);

    function calcTakerPositionFee(uint amount, uint32 start)
        external
        view
        returns (uint);
}