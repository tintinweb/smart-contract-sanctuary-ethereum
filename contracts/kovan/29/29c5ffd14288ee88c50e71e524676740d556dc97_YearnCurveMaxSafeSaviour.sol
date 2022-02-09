/**
 *Submitted for verification at Etherscan.io on 2022-02-08
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/saviours/YearnCurveMaxSafeSaviour.sol

pragma solidity >=0.6.7 >=0.6.0 <0.8.0 >=0.6.7 <0.7.0;

////// src/interfaces/CoinJoinLike.sol
/* pragma solidity >=0.6.7; */

abstract contract CoinJoinLike {
    function systemCoin() virtual public view returns (address);
    function safeEngine() virtual public view returns (address);
    function join(address, uint256) virtual external;
}

////// src/interfaces/CollateralJoinLike.sol
/* pragma solidity ^0.6.7; */

abstract contract CollateralJoinLike {
    function safeEngine() virtual public view returns (address);
    function collateralType() virtual public view returns (bytes32);
    function collateral() virtual public view returns (address);
    function decimals() virtual public view returns (uint256);
    function contractEnabled() virtual public view returns (uint256);
    function join(address, uint256) virtual external;
}

////// src/interfaces/CurveV1PoolLike.sol
/* pragma solidity >=0.6.7; */

abstract contract CurveV1PoolLike {
    function coins(uint256 index) public virtual view returns (address);
    function redemption_price_snap() public virtual view returns (address);
    function lp_token() public virtual view returns (address);
    function remove_liquidity(uint256 _amount, uint256[2] memory _min_amounts) public virtual returns (uint256[] memory);
}

////// src/interfaces/ERC20Like.sol
/* pragma solidity ^0.6.7; */

abstract contract ERC20Like {
    function allowance(address, address) virtual public view returns (uint256);
    function approve(address guy, uint wad) virtual public returns (bool);
    function transfer(address dst, uint wad) virtual public returns (bool);
    function balanceOf(address) virtual external view returns (uint256);
    function transferFrom(address src, address dst, uint wad)
        virtual
        public
        returns (bool);
}

////// src/interfaces/GebSafeManagerLike.sol
/* pragma solidity ^0.6.7; */

abstract contract GebSafeManagerLike {
    function safes(uint256) virtual public view returns (address);
    function ownsSAFE(uint256) virtual public view returns (address);
    function safeCan(address,uint256,address) virtual public view returns (uint256);
}

////// src/interfaces/LiquidationEngineLike.sol
/* pragma solidity ^0.6.7; */

abstract contract LiquidationEngineLike_3 {
    function safeSaviours(address) virtual public view returns (uint256);
}

////// src/interfaces/OracleRelayerLike.sol
/* pragma solidity ^0.6.7; */

abstract contract OracleRelayerLike_2 {
    function collateralTypes(bytes32) virtual public view returns (address, uint256, uint256);
    function liquidationCRatio(bytes32) virtual public view returns (uint256);
    function redemptionPrice() virtual public returns (uint256);
}

////// src/interfaces/PriceFeedLike.sol
/* pragma solidity ^0.6.7; */

abstract contract PriceFeedLike {
    function priceSource() virtual public view returns (address);
    function read() virtual public view returns (uint256);
    function getResultWithValidity() virtual external view returns (uint256,bool);
}

////// src/interfaces/SAFEEngineLike.sol
/* pragma solidity ^0.6.7; */

abstract contract SAFEEngineLike_8 {
    function approveSAFEModification(address) virtual external;
    function safeRights(address,address) virtual public view returns (uint256);
    function collateralTypes(bytes32) virtual public view returns (
        uint256 debtAmount,        // [wad]
        uint256 accumulatedRate,   // [ray]
        uint256 safetyPrice,       // [ray]
        uint256 debtCeiling,       // [rad]
        uint256 debtFloor,         // [rad]
        uint256 liquidationPrice   // [ray]
    );
    function safes(bytes32,address) virtual public view returns (
        uint256 lockedCollateral,  // [wad]
        uint256 generatedDebt      // [wad]
    );
    function modifySAFECollateralization(
        bytes32 collateralType,
        address safe,
        address collateralSource,
        address debtDestination,
        int256 deltaCollateral,    // [wad]
        int256 deltaDebt           // [wad]
    ) virtual external;
}

////// src/interfaces/SAFESaviourRegistryLike.sol
/* pragma solidity ^0.6.7; */

abstract contract SAFESaviourRegistryLike {
    function markSave(bytes32 collateralType, address safeHandler) virtual external;
}

////// src/interfaces/TaxCollectorLike.sol
/* pragma solidity >=0.6.7; */

abstract contract TaxCollectorLike {
    function taxSingle(bytes32) public virtual returns (uint256);
}

////// src/utils/ReentrancyGuard.sol

/* pragma solidity >=0.6.0 <0.8.0; */

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

////// src/interfaces/SafeSaviourLike.sol
// Copyright (C) 2020 Reflexer Labs, INC

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

/* pragma solidity ^0.6.7; */

/* import "./CollateralJoinLike.sol"; */
/* import "./CoinJoinLike.sol"; */
/* import "./OracleRelayerLike.sol"; */
/* import "./SAFEEngineLike.sol"; */
/* import "./LiquidationEngineLike.sol"; */
/* import "./PriceFeedLike.sol"; */
/* import "./ERC20Like.sol"; */
/* import "./GebSafeManagerLike.sol"; */
/* import "./TaxCollectorLike.sol"; */
/* import "./SAFESaviourRegistryLike.sol"; */

/* import "../utils/ReentrancyGuard.sol"; */

abstract contract SafeSaviourLike is ReentrancyGuard {
    // Checks whether a saviour contract has been approved by governance in the LiquidationEngine
    modifier liquidationEngineApproved(address saviour) {
        require(liquidationEngine.safeSaviours(saviour) == 1, "SafeSaviour/not-approved-in-liquidation-engine");
        _;
    }
    // Checks whether someone controls a safe handler inside the GebSafeManager
    modifier controlsSAFE(address owner, uint256 safeID) {
        require(owner != address(0), "SafeSaviour/null-owner");
        require(either(owner == safeManager.ownsSAFE(safeID), safeManager.safeCan(safeManager.ownsSAFE(safeID), safeID, owner) == 1), "SafeSaviour/not-owning-safe");

        _;
    }

    // --- Variables ---
    LiquidationEngineLike_3   public liquidationEngine;
    TaxCollectorLike        public taxCollector;
    OracleRelayerLike_2       public oracleRelayer;
    GebSafeManagerLike      public safeManager;
    SAFEEngineLike_8          public safeEngine;
    SAFESaviourRegistryLike public saviourRegistry;

    // The amount of tokens the keeper gets in exchange for the gas spent to save a SAFE
    uint256 public keeperPayout;          // [wad]
    // The minimum fiat value that the keeper must get in exchange for saving a SAFE
    uint256 public minKeeperPayoutValue;  // [wad]
    /*
      The proportion between the keeperPayout (if it's in collateral) and the amount of collateral or debt that's in a SAFE to be saved.
      Alternatively, it can be the proportion between the fiat value of keeperPayout and the fiat value of the profit that a keeper
      could make if a SAFE is liquidated right now. It ensures there's no incentive to intentionally put a SAFE underwater and then
      save it just to make a profit that's greater than the one from participating in collateral auctions
    */
    uint256 public payoutToSAFESize;

    // --- Constants ---
    uint256 public constant ONE               = 1;
    uint256 public constant HUNDRED           = 100;
    uint256 public constant THOUSAND          = 1000;
    uint256 public constant WAD_COMPLEMENT    = 10**9;
    uint256 public constant WAD               = 10**18;
    uint256 public constant RAY               = 10**27;
    uint256 public constant MAX_UINT          = uint(-1);

    // --- Boolean Logic ---
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := and(x, y) }
    }
    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }

    // --- Events ---
    event SaveSAFE(address indexed keeper, bytes32 indexed collateralType, address indexed safeHandler, uint256 collateralAddedOrDebtRepaid);

    // --- Functions to Implement ---
    function saveSAFE(address,bytes32,address) virtual external returns (bool,uint256,uint256);
    function getKeeperPayoutValue() virtual public returns (uint256);
    function keeperPayoutExceedsMinValue() virtual public returns (bool);
    function canSave(bytes32,address) virtual external returns (bool);
    function tokenAmountUsedToSave(bytes32,address) virtual public returns (uint256);
}

////// src/interfaces/SaviourCRatioSetterLike.sol
/* pragma solidity >=0.6.7; */

/* import "./OracleRelayerLike.sol"; */
/* import "./GebSafeManagerLike.sol"; */

/* import "../utils/ReentrancyGuard.sol"; */

abstract contract SaviourCRatioSetterLike is ReentrancyGuard {
    // --- Auth ---
    mapping (address => uint256) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "SaviourCRatioSetter/account-not-authorized");
        _;
    }

    // Checks whether someone controls a safe handler inside the GebSafeManager
    modifier controlsSAFE(address owner, uint256 safeID) {
        require(owner != address(0), "SaviourCRatioSetter/null-owner");
        require(either(owner == safeManager.ownsSAFE(safeID), safeManager.safeCan(safeManager.ownsSAFE(safeID), safeID, owner) == 1), "SaviourCRatioSetter/not-owning-safe");

        _;
    }

    // --- Variables ---
    OracleRelayerLike_2  public oracleRelayer;
    GebSafeManagerLike public safeManager;

    // Default desired cratio for each individual collateral type
    mapping(bytes32 => uint256)                     public defaultDesiredCollateralizationRatios;
    // Minimum bound for the desired cratio for each collateral type
    mapping(bytes32 => uint256)                     public minDesiredCollateralizationRatios;
    // Desired CRatios for each SAFE after they're saved
    mapping(bytes32 => mapping(address => uint256)) public desiredCollateralizationRatios;

    // --- Constants ---
    uint256 public constant MAX_CRATIO        = 1000;
    uint256 public constant CRATIO_SCALE_DOWN = 10**25;

    // --- Boolean Logic ---
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := and(x, y) }
    }
    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event ModifyParameters(bytes32 indexed parameter, address data);
    event SetDefaultCRatio(bytes32 indexed collateralType, uint256 cRatio);
    event SetMinDesiredCollateralizationRatio(
      bytes32 indexed collateralType,
      uint256 cRatio
    );
    event SetDesiredCollateralizationRatio(
      address indexed caller,
      bytes32 indexed collateralType,
      uint256 safeID,
      address indexed safeHandler,
      uint256 cRatio
    );

    // --- Functions ---
    function setDefaultCRatio(bytes32, uint256) virtual external;
    function setMinDesiredCollateralizationRatio(bytes32 collateralType, uint256 cRatio) virtual external;
    function setDesiredCollateralizationRatio(bytes32 collateralType, uint256 safeID, uint256 cRatio) virtual external;
}

////// src/interfaces/YVault3Like.sol
/* pragma solidity >=0.6.7; */

/* import "./ERC20Like.sol"; */


abstract contract YVault3Like {
    function deposit(uint256, address) virtual external returns (uint256);
    function withdraw(uint256, address, uint256) virtual external returns (uint256);
    function pricePerShare() virtual external returns (uint256);
    function token() virtual external returns (address);
}

////// src/math/SafeMath.sol

/* pragma solidity >=0.6.0 <0.8.0; */

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
contract SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

////// src/saviours/YearnCurveMaxSafeSaviour.sol
// Copyright (C) 2021 James Connolly, Reflexer Labs, INC

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

/* pragma solidity >=0.6.7; */

/* import "../interfaces/YVault3Like.sol"; */
/* import "../interfaces/SaviourCRatioSetterLike.sol"; */
/* import "../interfaces/SafeSaviourLike.sol"; */
/* import "../interfaces/CurveV1PoolLike.sol"; */
/* import "../math/SafeMath.sol"; */

contract YearnCurveMaxSafeSaviour is SafeMath, SafeSaviourLike {
    // --- Auth ---
    mapping (address => uint256) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "YearnCurveMaxSafeSaviour/account-not-authorized");
        _;
    }

    mapping (address => uint256) public allowedUsers;
    /**
     * @notice Allow a user to deposit assets
     * @param usr User to whitelist
     */
    function allowUser(address usr) external isAuthorized {
        allowedUsers[usr] = 1;
        emit AllowUser(usr);
    }
    /**
     * @notice Disallow a user from depositing assets
     * @param usr User to disallow
     */
    function disallowUser(address usr) external isAuthorized {
        allowedUsers[usr] = 0;
        emit DisallowUser(usr);
    }
    /**
    * @notice Checks whether an address is an allowed user
    **/
    modifier isAllowed {
        require(
          either(restrictUsage == 0, both(restrictUsage == 1, allowedUsers[msg.sender] == 1)),
          "YearnCurveMaxSafeSaviour/account-not-allowed"
        );
        _;
    }

    // --- Variables ---
    // Flag that tells whether usage of the contract is restricted to allowed users
    uint256                     public restrictUsage;
    // Default max loss used when saving a Safe
    uint256                     public defaultMaxLoss = 1; // 0.01%
    // Array used to store amounts of tokens removed from Curve when a SAFE is saved
    uint256[]                                       public removedCurveCoinLiquidity;
    // Array of tokens in the Curve pool
    address[2]                                       public curvePoolTokens;
    // Default array of min tokens to withdraw
    uint256[2]                                       public defaultMinTokensToWithdraw;
    // Amount of collateral deposited to cover each SAFE
    mapping(bytes32 => mapping(address => uint256)) public yvTokenCover;
    // Amount of tokens that weren't used to save SAFEs and Safe owners can now get back
    mapping(address => mapping(address => uint256)) public underlyingReserves;

    // The yVault address
    YVault3Like                 public yVault;
    // Curve pool address
    CurveV1PoolLike             public curvePool;
    // Curve LP token
    ERC20Like                   public curveLpToken;
    // The ERC20 system coin
    ERC20Like                   public systemCoin;
    // The system coin join contract
    CoinJoinLike                public coinJoin;
    // Oracle providing the system coin price feed
    PriceFeedLike               public systemCoinOrcl;

    uint256                     public constant MAX_LOSS = 10_000; // 10k basis points

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event AllowUser(address usr);
    event DisallowUser(address usr);
    event ModifyParameters(bytes32 indexed parameter, uint256 val);
    event ModifyParameters(bytes32 indexed parameter, address data);
    event Deposit(
      address indexed caller,
      bytes32 collateralType,
      address indexed safeHandler,
      uint256 systemCoinAmount,
      uint256 yvTokenAmount
    );
    event Withdraw(
      address indexed caller,
      bytes32 collateralType,
      address indexed safeHandler,
      address dst,
      uint256 systemCoinAmount,
      uint256 yvTokenAmount
    );
    event GetReserves(
      address indexed caller,
      address indexed safeHandler,
      address token,
      uint256 tokenAmount,
      address dst
    );

    constructor(
      address coinJoin_,
      address systemCoinOrcl_,
      address liquidationEngine_,
      address taxCollector_,
      address oracleRelayer_,
      address safeManager_,
      address saviourRegistry_,
      address yVault_,
      address curvePool_,
      uint256 minKeeperPayoutValue_
    ) public {
        require(coinJoin_ != address(0), "YearnCurveMaxSafeSaviour/null-coin-join");
        require(systemCoinOrcl_ != address(0), "YearnCurveMaxSafeSaviour/null-system-coin-oracle");
        require(oracleRelayer_ != address(0), "YearnCurveMaxSafeSaviour/null-oracle-relayer");
        require(liquidationEngine_ != address(0), "YearnCurveMaxSafeSaviour/null-liquidation-engine");
        require(taxCollector_ != address(0), "YearnCurveMaxSafeSaviour/null-tax-collector");
        require(safeManager_ != address(0), "YearnCurveMaxSafeSaviour/null-safe-manager");
        require(saviourRegistry_ != address(0), "YearnCurveMaxSafeSaviour/null-saviour-registry");
        require(yVault_ != address(0), "YearnCurveMaxSafeSaviour/null-y-vault");
        require(curvePool_ != address(0), "YearnCurveMaxSafeSaviour/null-curve-pool");
        require(minKeeperPayoutValue_ > 0, "YearnCurveMaxSafeSaviour/invalid-min-payout-value");


        authorizedAccounts[msg.sender] = 1;

        minKeeperPayoutValue = minKeeperPayoutValue_;

        coinJoin             = CoinJoinLike(coinJoin_);
        liquidationEngine    = LiquidationEngineLike_3(liquidationEngine_);
        taxCollector         = TaxCollectorLike(taxCollector_);

        oracleRelayer        = OracleRelayerLike_2(oracleRelayer_);
        systemCoinOrcl       = PriceFeedLike(systemCoinOrcl_);
        systemCoin           = ERC20Like(coinJoin.systemCoin());
        safeEngine           = SAFEEngineLike_8(coinJoin.safeEngine());
        safeManager          = GebSafeManagerLike(safeManager_);
        saviourRegistry      = SAFESaviourRegistryLike(saviourRegistry_);
        yVault               = YVault3Like(yVault_);
        curveLpToken         = ERC20Like(yVault.token());
        curvePool            = CurveV1PoolLike(curvePool_); 

        require(address(curveLpToken) != address(0), "YearnCurveMaxSafeSaviour/null-curve-lp");
        require(curvePool.lp_token() == address(curveLpToken), "YearnCurveMaxSafeSaviour/curve-pool-not-matching");
        require(address(safeEngine) != address(0), "YearnCurveMaxSafeSaviour/null-safe-engine");
        require(address(systemCoin) != address(0), "YearnCurveMaxSafeSaviour/null-sys-coin");

        systemCoinOrcl.read();
        systemCoinOrcl.getResultWithValidity();
        oracleRelayer.redemptionPrice();

        address coin0 = curvePool.coins(0);
        address coin1 = curvePool.coins(1);

        require(both(coin0 != address(0), coin1 != address(0)));

        curvePoolTokens = [coin0, coin1];
        defaultMinTokensToWithdraw = [0, 0];

        emit AddAuthorization(msg.sender);
        emit ModifyParameters("minKeeperPayoutValue", minKeeperPayoutValue);
        emit ModifyParameters("liquidationEngine", liquidationEngine_);
        emit ModifyParameters("taxCollector", taxCollector_);
        emit ModifyParameters("oracleRelayer", oracleRelayer_);
        emit ModifyParameters("systemCoinOrcl", systemCoinOrcl_);
    }

    // --- Math ---
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = (x <= y) ? x : y;
    }

    // --- Administration ---
    /**
     * @notice Modify an uint256 param
     * @param parameter The name of the parameter
     * @param val New value for the parameter
     */
    function modifyParameters(bytes32 parameter, uint256 val) external isAuthorized {
        if (parameter == "minKeeperPayoutValue") {
            require(val > 0, "YearnCurveMaxSafeSaviour/null-min-payout");
            minKeeperPayoutValue = val;
        }
        else if (parameter == "restrictUsage") {
            require(val <= 1, "YearnCurveMaxSafeSaviour/invalid-restriction");
            restrictUsage = val;
        }
        else if (parameter == "defaultMaxLoss") {
            require(val <= MAX_LOSS, "YearnCurveMaxSafeSaviour/exceeds-max-loss");
            defaultMaxLoss = val;
        }
        else revert("YearnCurveMaxSafeSaviour/modify-unrecognized-param");
        emit ModifyParameters(parameter, val);
    }
    /**
     * @notice Modify an address param
     * @param parameter The name of the parameter
     * @param data New address for the parameter
     */
    function modifyParameters(bytes32 parameter, address data) external isAuthorized {
        require(data != address(0), "YearnCurveMaxSafeSaviour/null-data");

        if (parameter == "systemCoinOrcl") {
            systemCoinOrcl = PriceFeedLike(data);
            systemCoinOrcl.read();
            systemCoinOrcl.getResultWithValidity();
        }
        else if (parameter == "oracleRelayer") {
            oracleRelayer = OracleRelayerLike_2(data);
            oracleRelayer.redemptionPrice();
        }
        else if (parameter == "liquidationEngine") {
            liquidationEngine = LiquidationEngineLike_3(data);
        }
        else if (parameter == "taxCollector") {
            taxCollector = TaxCollectorLike(data);
        }
        else revert("YearnCurveMaxSafeSaviour/modify-unrecognized-param");
        emit ModifyParameters(parameter, data);
    }


    // --- Transferring Reserves ---
    /*
    * @notice Get back multiple tokens that were withdrawn from Curve and not used to save a specific SAFE
    * @param safeID The ID of the safe that was previously saved and has leftover funds that can be withdrawn
    * @param tokens The addresses of the tokens being transferred
    * @param dst The address that will receive the reserve system coins
    */
    function getReserves(uint256 safeID, address[] calldata tokens, address dst)
      external controlsSAFE(msg.sender, safeID) nonReentrant {
        require(tokens.length > 0, "CurveV1MaxSafeSaviour/no-tokens");
        address safeHandler = safeManager.safes(safeID);

        uint256 reserve;
        for (uint i = 0; i < tokens.length; i++) {
          reserve = underlyingReserves[safeHandler][tokens[i]];
          if (reserve == 0) continue;

          delete(underlyingReserves[safeHandler][tokens[i]]);
          ERC20Like(tokens[i]).transfer(dst, reserve);

          emit GetReserves(msg.sender, safeHandler, tokens[i], reserve, dst);
        }
    }
    /*
    * @notify Get back tokens that were withdrawn from Curve and not used to save a specific SAFE
    * @param safeID The ID of the safe that was previously saved and has leftover funds that can be withdrawn
    * @param token The address of the token being transferred
    * @param dst The address that will receive the reserve system coins
    */
    function getReserves(uint256 safeID, address token, address dst) external controlsSAFE(msg.sender, safeID) nonReentrant {
        address safeHandler = safeManager.safes(safeID);
        uint256 reserve     = underlyingReserves[safeHandler][token];

        require(reserve > 0, "CurveV1MaxSafeSaviour/no-reserves");
        delete(underlyingReserves[safeHandler][token]);

        ERC20Like(token).transfer(dst, reserve);

        emit GetReserves(msg.sender, safeHandler, token, reserve, dst);
    }

    // --- Adding/Withdrawing Cover ---
    /*
    * @notice Deposit systemCoin in the contract and lend in the Yearn vault in order to provide cover for a
    *         specific SAFE controlled by the SAFE Manager
    * @param collateralType The collateral type used in the SAFE
    * @param safeID The ID of the SAFE to protect. This ID should be registered inside GebSafeManager
    * @param systemCoinAmount The amount of systemCoin to deposit
    */
    function deposit(bytes32 collateralType, uint256 safeID, uint256 lpTokenAmount)
      external isAllowed() liquidationEngineApproved(address(this)) nonReentrant {
        require(lpTokenAmount > 0, "YearnCurveMaxSafeSaviour/null-lp-token-amount");

        // Check that the SAFE exists inside GebSafeManager
        address safeHandler = safeManager.safes(safeID);
        require(safeHandler != address(0), "YearnCurveMaxSafeSaviour/null-handler");

        // Check that the SAFE has debt
        (, uint256 safeDebt) = safeEngine.safes(collateralType, safeHandler);
        require(safeDebt > 0, "YearnCurveMaxSafeSaviour/safe-does-not-have-debt");

        // Deposit into Yearn
        curveLpToken.transferFrom(msg.sender, address(this), lpTokenAmount);
        curveLpToken.approve(address(yVault), lpTokenAmount);
        uint256 yvTokens = yVault.deposit(lpTokenAmount, address(this)); // use return value to save on math operations
        require(yvTokens > 0, "YearnCurveMaxSafeSaviour/no-vault-tokens-returned");

        // Update the yvToken balance used to cover the SAFE
        yvTokenCover[collateralType][safeHandler] = add(yvTokenCover[collateralType][safeHandler], yvTokens);

        emit Deposit(msg.sender, collateralType, safeHandler, lpTokenAmount, yvTokens);
    }
    /*
    * @notice Withdraw system coins from the contract and provide less cover for a SAFE
    * @dev Only an address that controls the SAFE inside GebSafeManager can call this
    * @param safeID The ID of the SAFE to remove cover from. This ID should be registered inside GebSafeManager
    * @param yvTokenAmount The amount of yvTokens to burn
    * @param maxLoss The maximum acceptable loss to sustain on withdrawal.
    *                If a loss is specified, up to that amount of shares may be burnt to cover losses on withdrawal.
    * @param dst The address that will receive the withdrawn system coins
    */
    function withdraw(bytes32 collateralType, uint256 safeID, uint256 yvTokenAmount, address dst)
      external controlsSAFE(msg.sender, safeID) nonReentrant {
        require(yvTokenAmount > 0, "YearnCurveMaxSafeSaviour/null-yvToken-amount");
        require(dst != address(0), "YearnCurveMaxSafeSaviour/null-dst");

        // Fetch the handler from the SAFE manager
        address safeHandler = safeManager.safes(safeID);
        require(yvTokenCover[collateralType][safeHandler] >= yvTokenAmount, "YearnCurveMaxSafeSaviour/withdraw-request-higher-than-balance");

        // Redeem system coins from Yearn and transfer them to the caller
        yvTokenCover[collateralType][safeHandler] = sub(yvTokenCover[collateralType][safeHandler], yvTokenAmount);

        uint256 withdrawnCurveLp = yVault.withdraw(yvTokenAmount, dst, defaultMaxLoss); // use return value to save on math operations
        require(withdrawnCurveLp > 0, "YearnCurveMaxSafeSaviour/no-coins-withdrawn");

        emit Withdraw(
          msg.sender,
          collateralType,
          safeHandler,
          dst,
          withdrawnCurveLp,
          yvTokenAmount
        );
    }

    // --- Saving Logic ---
    /*
    * @notice Saves a SAFE by repaying some of its debt
    * @dev Only the LiquidationEngine can call this
    * @param keeper The keeper that called LiquidationEngine.liquidateSAFE and that should be rewarded for
    *               spending gas to save a SAFE
    * @param collateralType The collateral type backing the SAFE that's being liquidated
    * @param safeHandler The handler of the SAFE that's being liquidated
    * @return Whether the SAFE has been saved, the amount of system coin debt repaid as well as the amount of
    *         system coins sent to the keeper as their payment
    */
    function saveSAFE(address keeper, bytes32 collateralType, address safeHandler) override
      external returns (bool, uint256, uint256) {
        require(address(liquidationEngine) == msg.sender, "YearnCurveMaxSafeSaviour/caller-not-liquidation-engine");
        require(keeper != address(0), "YearnCurveMaxSafeSaviour/null-keeper-address");

        if (both(both(collateralType == "", safeHandler == address(0)), keeper == address(liquidationEngine))) {
            return (true, uint(-1), uint(-1));
        }

        // Tax the collateral
        taxCollector.taxSingle(collateralType);

        // Mark the SAFE in the registry as just having been saved
        saviourRegistry.markSave(collateralType, safeHandler);

        // Get and update the current cover
        uint256 currentCover = yvTokenCover[collateralType][safeHandler];
        require(currentCover > 0, "YearnCurveMaxSafeSaviour/null-cover");
        yvTokenCover[collateralType][safeHandler] = 0;

        // Get curve LP from yearn vault
        yVault.withdraw(currentCover, address(this), defaultMaxLoss);


        // Withdraw curve LP
        removeCurveLiquidity(collateralType, safeHandler);

        // Record tokens that are not system coins and put them in reserves
        uint256 sysCoinBalance = underlyingReserves[safeHandler][address(systemCoin)];

        for (uint i = 0; i < removedCurveCoinLiquidity.length; i++) {
          if (both(curvePoolTokens[i] != address(systemCoin), removedCurveCoinLiquidity[i] > 0)) {
            underlyingReserves[safeHandler][curvePoolTokens[i]] = add(
              underlyingReserves[safeHandler][curvePoolTokens[i]], removedCurveCoinLiquidity[i]
            );
          } else {
            sysCoinBalance = add(sysCoinBalance, removedCurveCoinLiquidity[i]);
          }
        }

        // Get the amounts of tokens sent to the keeper as payment
        uint256 keeperSysCoins =
          getKeeperPayoutTokens(
            safeHandler,
            sysCoinBalance
          );

        // There must be tokens that go to the keeper
        require(keeperSysCoins > 0, "CurveV1MaxSafeSaviour/cannot-pay-keeper");

        // Get the amount of tokens used to top up the SAFE
        uint256 safeDebtRepaid =
          getTokensForSaving(
            collateralType,
            safeHandler,
            sub(sysCoinBalance, keeperSysCoins)
          );

        // There must be tokens used to save the SAVE
        require(safeDebtRepaid > 0, "CurveV1MaxSafeSaviour/cannot-save-safe");

        // Compute remaining balances of tokens that will go into reserves
        sysCoinBalance = sub(sysCoinBalance, add(safeDebtRepaid, keeperSysCoins));

        // Update system coin reserves
        underlyingReserves[safeHandler][address(systemCoin)] = sysCoinBalance;

        // Save the SAFE
        {
          // Approve the coin join contract to take system coins and repay debt
          systemCoin.approve(address(coinJoin), safeDebtRepaid);
          // Calculate the non adjusted system coin amount
          (uint256 accumulatedRate, ) = getAccumulatedRateAndLiquidationPrice(collateralType);
          uint256 nonAdjustedSystemCoinsToRepay = div(mul(safeDebtRepaid, RAY), accumulatedRate);

          // Join system coins in the system and repay the SAFE's debt
          coinJoin.join(address(this), safeDebtRepaid);
          safeEngine.modifySAFECollateralization(
            collateralType,
            safeHandler,
            address(0),
            address(this),
            int256(0),
            -int256(nonAdjustedSystemCoinsToRepay)
          );
        }

        // Check the SAFE is saved
        require(safeIsAfloat(collateralType, safeHandler), "CurveV1MaxSafeSaviour/safe-not-saved");

        // Pay keeper
        systemCoin.transfer(keeper, keeperSysCoins);

        // Emit an event
        emit SaveSAFE(keeper, collateralType, safeHandler, currentCover);

        return (true, currentCover, 0);
    }
    
    // --- Internal Logic ---

    event dbg();
    /**
     * @notice Remove all Curve liquidity protecting a specific SAFE and return the amounts of all returned tokens
     * @param collateralType The collateral type of the SAFE whose cover is now used
     * @param safeHandler The handler of the SAFE for which we withdraw Curve liquidity
     */
    function removeCurveLiquidity(bytes32 collateralType, address safeHandler) internal {
        
        // Wipe storage
        delete(removedCurveCoinLiquidity);
        require(removedCurveCoinLiquidity.length == 0, "CurveV1MaxSafeSaviour/cannot-wipe-storage");
        for (uint i = 0; i < curvePoolTokens.length; i++) {
          removedCurveCoinLiquidity.push(ERC20Like(curvePoolTokens[i]).balanceOf(address(this)));
        }

        uint256 lpBalance = curveLpToken.balanceOf(address(this));

        if (lpBalance == 0) return;

        curveLpToken.approve(address(curvePool), lpBalance);
        curvePool.remove_liquidity(lpBalance, defaultMinTokensToWithdraw);

        for (uint i = 0; i < curvePoolTokens.length; i++) {
          removedCurveCoinLiquidity[i] = sub(ERC20Like(curvePoolTokens[i]).balanceOf(address(this)), removedCurveCoinLiquidity[i]);
        }
    }

    // --- Getters ---
    /*
    * @notify Must be implemented according to the interface although it always returns false
    */
    function keeperPayoutExceedsMinValue() override public returns (bool) {
        return false;
    }
    /*
    * @notify Must be implemented according to the interface although it always returns 0
    */
    function getKeeperPayoutValue() override public returns (uint256) {
        return 0;
    }
    /*
    * @notify Returns whether a SAFE can be currently saved; in this implementation it always returns false
    */
    function canSave(bytes32, address) override external returns (bool) {
        return false;
    }
    /*
    * @notice Return the amount of system coins used to pay a keeper
    * @param safeHandler The handler/address of the targeted SAFE
    * @param sysCoinsFromLP System coins withdrawn from Uniswap
    */
    function getKeeperPayoutTokens(
      address safeHandler,
      uint256 sysCoinsFromLP
    ) public view returns (uint256) {
        if (sysCoinsFromLP == 0) return 0;

        // Get the system coin market price
        uint256 sysCoinMarketPrice = getSystemCoinMarketPrice();
        if (sysCoinMarketPrice == 0) {
            return 0;
        }

        // Check if the keeper can be paid only with system coins, otherwise return zero
        uint256 payoutInSystemCoins = div(mul(minKeeperPayoutValue, WAD), sysCoinMarketPrice);

        if (payoutInSystemCoins <= sysCoinsFromLP) {
          return payoutInSystemCoins;
        }

        return 0;
    }
    /*
    * @notice Calculate the amount of system coins used to save a SAFE. This implementation always returns 0
    */
    function tokenAmountUsedToSave(bytes32, address) override public returns (uint256) {
        return 0;
    }
        /*
    * @notice Return the amount of system coins used to save a SAFE
    * @param collateralType The SAFE collateral type
    * @param safeHandler The handler/address of the targeted SAFE
    * @param coinsLeft System coins left to save the SAFE after paying the liquidation keeper
    */
    function getTokensForSaving(
      bytes32 collateralType,
      address safeHandler,
      uint256 coinsLeft
    ) public view returns (uint256) {
        if (coinsLeft == 0) {
            return 0;
        }

        // Get the default CRatio for the SAFE
        (uint256 depositedCollateralToken, uint256 safeDebt) =
          SAFEEngineLike_8(address(safeEngine)).safes(collateralType, safeHandler);
        if (safeDebt == 0) {
            return 0;
        }

        // See how many system coins can be used to save the SAFE
        uint256 usedSystemCoins;
        (, , , , uint256 debtFloor, ) = safeEngine.collateralTypes(collateralType);
        (uint256 accumulatedRate, uint256 liquidationPrice) =
          getAccumulatedRateAndLiquidationPrice(collateralType);

        if (coinsLeft >= safeDebt) usedSystemCoins = safeDebt;
        else if (debtFloor < mul(safeDebt, accumulatedRate)) {
          usedSystemCoins = min(sub(mul(safeDebt, accumulatedRate), debtFloor) / RAY, coinsLeft);
        }

        if (usedSystemCoins == 0) return 0;

        // See if the SAFE can be saved
        bool safeSaved = (
          mul(depositedCollateralToken, liquidationPrice) >
          mul(sub(safeDebt, usedSystemCoins), accumulatedRate)
        );

        if (safeSaved) return usedSystemCoins;
        return 0;
    }
    /*
    * @notify Fetch the system coin's market price
    */
    function getSystemCoinMarketPrice() public view returns (uint256) {
        (uint256 priceFeedValue, bool hasValidValue) = systemCoinOrcl.getResultWithValidity();
        if (!hasValidValue) return 0;

        return priceFeedValue;
    }
    /*
    * @notify Returns whether a target debt amount is below the debt floor of a specific collateral type
    * @param collateralType The collateral type whose floor we compare against
    * @param targetDebtAmount The target debt amount for a SAFE that has collateralType collateral in it
    */
    function debtBelowFloor(bytes32 collateralType, uint256 targetDebtAmount) public view returns (bool) {
        (, , , , uint256 debtFloor, ) = safeEngine.collateralTypes(collateralType);
        return (mul(targetDebtAmount, RAY) < debtFloor);
    }
    /*
    * @notify Returns whether a SAFE is afloat
    * @param safeHandler The handler of the SAFE to verify
    */
    function safeIsAfloat(bytes32 collateralType, address safeHandler) public view returns (bool) {
        (, uint256 accumulatedRate, , , , uint256 liquidationPrice) = safeEngine.collateralTypes(collateralType);
        (uint256 safeCollateral, uint256 safeDebt) = safeEngine.safes(collateralType, safeHandler);

        return (
          mul(safeCollateral, liquidationPrice) > mul(safeDebt, accumulatedRate)
        );
    }
    /*
    * @notify Get the accumulated interest rate for a specific collateral type as well as its current liquidation price
    * @param The collateral type for which to retrieve the rate and the price
    */
    function getAccumulatedRateAndLiquidationPrice(bytes32 collateralType)
      public view returns (uint256 accumulatedRate, uint256 liquidationPrice) {
        (, accumulatedRate, , , , liquidationPrice) = safeEngine.collateralTypes(collateralType);
    }
}