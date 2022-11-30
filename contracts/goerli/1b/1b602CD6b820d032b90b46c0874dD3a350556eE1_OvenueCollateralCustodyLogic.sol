pragma solidity 0.8.5;

import "../interfaces/IOvenueCollateralCustody.sol";
import "../interfaces/IOvenueExchange.sol";
import "../interfaces/IOvenueConfig.sol";

import "../libraries/OvenueConfigHelper.sol";


library OvenueCollateralCustodyLogic {
    using OvenueConfigHelper for IOvenueConfig;

    error InvalidPoolGovernor();
    error NotExceedsLatenessGracePeriod();

    uint public constant INVERSE_BASIS_POINT = 10000;

    event JuniorPoolDebtRecover(
        address indexed poolAddr,
        uint256 totalOwned,
        uint256 timestamp
    );

    function recoverLossFundsForInvestors(
        IOvenueConfig config,
        IOvenueJuniorPool pool,
        IOvenueExchange exchange,
        IOvenueCollateralCustody.NFTLiquidationOrder memory liquidationOrder,
        IOvenueCollateralCustody.Collateral storage collateral,
        IOvenueCollateralCustody.CollateralStatus storage collateralStatus,
        bool usingFungible
    ) external {
        // if (collateral.governor != msg.sender) {
        //     revert InvalidPoolGovernor();
        // }

        // Check if latesness grace period is passed
        _notExceedsLatenessGracePeriod(pool, config);

        // Get total owned and get the condition of distribute liquidation
        IV2OvenueCreditLine creditLine = pool.creditLine();
        uint loanBalance = creditLine.balance();

        if (loanBalance > 0) {
            pool.assess();
        }

        uint totalOwned = creditLine.interestOwed() + creditLine.principalOwed();

        // check if liquidation amount of pool is still enough for covering debt
        if (!usingFungible) {
            bytes32 orderHash = liquidationOrder.orderHash;
            bool isFullfilled = exchange.cancelledOrFinalized(orderHash);
            
            if (!liquidationOrder.fullfilled && isFullfilled) {
                liquidationOrder.fullfilled = true;
                collateralStatus.fundedNonfungibleAmount = liquidationOrder.price * (INVERSE_BASIS_POINT - liquidationOrder.makerFee) / INVERSE_BASIS_POINT;
            }
            
            collateralStatus.fundedNonfungibleAmount -= totalOwned;
        } else {
            collateralStatus.fundedFungibleAmount -= totalOwned;
        }
        

        // Approve USDC for creditline contract for assessing
        config.getUSDC().approve(
            address(pool),
            totalOwned
        );

        pool.pay(
            totalOwned
        );

        emit JuniorPoolDebtRecover(
            address(pool),
            totalOwned,
            block.timestamp
        );
    }

    function _notExceedsLatenessGracePeriod(IOvenueJuniorPool poolAddr, IOvenueConfig config) internal view {
        IV2OvenueCreditLine creditLine = poolAddr.creditLine();

        if (creditLine.lastFullPaymentTime() + config.getLatenessGracePeriodInDays() > block.timestamp) {
            revert NotExceedsLatenessGracePeriod();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

// import {ImplementationRepository} from "./proxy/ImplementationRepository.sol";
import {OvenueConfigOptions} from "../core/OvenueConfigOptions.sol";

import {IOvenueCollateralCustody} from "../interfaces/IOvenueCollateralCustody.sol";

import {IOvenueConfig} from "../interfaces/IOvenueConfig.sol";
import {IOvenueSeniorLP} from "../interfaces/IOvenueSeniorLP.sol";
import {IOvenueSeniorPool} from "../interfaces/IOvenueSeniorPool.sol";
import {IOvenueSeniorPoolStrategy} from "../interfaces/IOvenueSeniorPoolStrategy.sol";
import {IERC20withDec} from "../interfaces/IERC20withDec.sol";
// import {ICUSDCContract} from "../../interfaces/ICUSDCContract.sol";
import {IOvenueJuniorLP} from "../interfaces/IOvenueJuniorLP.sol";
import {IOvenueJuniorRewards} from "../interfaces/IOvenueJuniorRewards.sol";
import {IOvenueFactory} from "../interfaces/IOvenueFactory.sol";
import {IGo} from "../interfaces/IGo.sol";

import {IOvenueExchange} from "../interfaces/IOvenueExchange.sol";

// import {IStakingRewards} from "../../interfaces/IStakingRewards.sol";
// import {ICurveLP} from "../../interfaces/ICurveLP.sol";

/**
 * @title ConfigHelper
 * @notice A convenience library for getting easy access to other contracts and constants within the
 *  protocol, through the use of the OvenueConfig contract
 * @author Goldfinch
 */

library OvenueConfigHelper {
  function getSeniorPool(IOvenueConfig config) internal view returns (IOvenueSeniorPool) {
    return IOvenueSeniorPool(seniorPoolAddress(config));
  }

  function getSeniorPoolStrategy(IOvenueConfig config) internal view returns (IOvenueSeniorPoolStrategy) {
    return IOvenueSeniorPoolStrategy(seniorPoolStrategyAddress(config));
  }

  function getUSDC(IOvenueConfig config) internal view returns (IERC20withDec) {
    return IERC20withDec(usdcAddress(config));
  }

  function getSeniorLP(IOvenueConfig config) internal view returns (IOvenueSeniorLP) {
    return IOvenueSeniorLP(fiduAddress(config));
  }

//   function getFiduUSDCCurveLP(OvenueConfig config) internal view returns (ICurveLP) {
//     return ICurveLP(fiduUSDCCurveLPAddress(config));
//   }

//   function getCUSDCContract(OvenueConfig config) internal view returns (ICUSDCContract) {
//     return ICUSDCContract(cusdcContractAddress(config));
//   }

  function getJuniorLP(IOvenueConfig config) internal view returns (IOvenueJuniorLP) {
    return IOvenueJuniorLP(juniorLPAddress(config));
  }

  function getJuniorRewards(IOvenueConfig config) internal view returns (IOvenueJuniorRewards) {
    return IOvenueJuniorRewards(juniorRewardsAddress(config));
  }

  function getOvenueFactory(IOvenueConfig config) internal view returns (IOvenueFactory) {
    return IOvenueFactory(ovenueFactoryAddress(config));
  }

  function getOVN(IOvenueConfig config) internal view returns (IERC20withDec) {
    return IERC20withDec(ovenueAddress(config));
  }

  function getGo(IOvenueConfig config) internal view returns (IGo) {
    return IGo(goAddress(config));
  }

  function getCollateralToken(IOvenueConfig config) internal view returns (IERC20withDec) {
    return IERC20withDec(collateralTokenAddress(config));
  }

  function getCollateralCustody(IOvenueConfig config) internal view returns (IOvenueCollateralCustody) {
    return IOvenueCollateralCustody(collateralCustodyAddress(config));
  }

  function getOvenueExchange(IOvenueConfig config) internal view returns (IOvenueExchange) {
    return IOvenueExchange(exchangeAddress(config));
  }

//   function getStakingRewards(OvenueConfig config) internal view returns (IStakingRewards) {
//     return IStakingRewards(stakingRewardsAddress(config));
//   }

  // function getTranchedPoolImplementationRepository(IOvenueConfig config)
  //   internal
  //   view
  //   returns (ImplementationRepository)
  // {
  //   return
  //     ImplementationRepository(
  //       config.getAddress(uint256(OvenueConfigOptions.Addresses.TranchedPoolImplementation))
  //     );
  // }

//   function oneInchAddress(OvenueConfig config) internal view returns (address) {
//     return config.getAddress(uint256(OvenueOvenueConfigOptions.Addresses.OneInch));
//   }

  function creditLineImplementationAddress(IOvenueConfig config) internal view returns (address) {
    return config.getAddress(uint256(OvenueConfigOptions.Addresses.CreditLineImplementation));
  }

//   /// @dev deprecated because we no longer use GSN
//   function trustedForwarderAddress(OvenueConfig config) internal view returns (address) {
//     return config.getAddress(uint256(OvenueOvenueConfigOptions.Addresses.TrustedForwarder));
//   }

function exchangeAddress(IOvenueConfig config) internal view returns (address) {
    return config.getAddress(uint256(OvenueConfigOptions.Addresses.OvenueExchange));
  }

  function collateralCustodyAddress(IOvenueConfig config) internal view returns (address) {
    return config.getAddress(uint256(OvenueConfigOptions.Addresses.CollateralCustody));
  }
  function configAddress(IOvenueConfig config) internal view returns (address) {
    return config.getAddress(uint256(OvenueConfigOptions.Addresses.OvenueConfig));
  }

  function juniorLPAddress(IOvenueConfig config) internal view returns (address) {
    return config.getAddress(uint256(OvenueConfigOptions.Addresses.PoolTokens));
  }

  function juniorRewardsAddress(IOvenueConfig config) internal view returns (address) {
    return config.getAddress(uint256(OvenueConfigOptions.Addresses.JuniorRewards));
  }

  function seniorPoolAddress(IOvenueConfig config) internal view returns (address) {
    return config.getAddress(uint256(OvenueConfigOptions.Addresses.SeniorPool));
  }

  function seniorPoolStrategyAddress(IOvenueConfig config) internal view returns (address) {
    return config.getAddress(uint256(OvenueConfigOptions.Addresses.SeniorPoolStrategy));
  }

  function ovenueFactoryAddress(IOvenueConfig config) internal view returns (address) {
    return config.getAddress(uint256(OvenueConfigOptions.Addresses.OvenueFactory));
  }

  function ovenueAddress(IOvenueConfig config) internal view returns (address) {
    return config.getAddress(uint256(OvenueConfigOptions.Addresses.OVENUE));
  }

  function fiduAddress(IOvenueConfig config) internal view returns (address) {
    return config.getAddress(uint256(OvenueConfigOptions.Addresses.Fidu));
  }

  function collateralTokenAddress(IOvenueConfig config) internal view returns (address) {
    return config.getAddress(uint256(OvenueConfigOptions.Addresses.CollateralToken));
  }

//   function fiduUSDCCurveLPAddress(OvenueConfig config) internal view returns (address) {
//     return config.getAddress(uint256(OvenueConfigOptions.Addresses.FiduUSDCCurveLP));
//   }

//   function cusdcContractAddress(OvenueConfig config) internal view returns (address) {
//     return config.getAddress(uint256(OvenueConfigOptions.Addresses.CUSDCContract));
//   }

  function usdcAddress(IOvenueConfig config) internal view returns (address) {
    return config.getAddress(uint256(OvenueConfigOptions.Addresses.USDC));
  }

  function collateralGovernanceAddress(IOvenueConfig config) internal view returns (address) {
    return config.getAddress(uint256(OvenueConfigOptions.Addresses.CollateralGovernanceImplementation));
  }

  function tranchedPoolAddress(IOvenueConfig config) internal view returns (address) {
    return config.getAddress(uint256(OvenueConfigOptions.Addresses.TranchedPoolImplementation));
  }

  function reserveAddress(IOvenueConfig config) internal view returns (address) {
    return config.getAddress(uint256(OvenueConfigOptions.Addresses.TreasuryReserve));
  }

  function protocolAdminAddress(IOvenueConfig config) internal view returns (address) {
    return config.getAddress(uint256(OvenueConfigOptions.Addresses.ProtocolAdmin));
  }

  function borrowerImplementationAddress(IOvenueConfig config) internal view returns (address) {
    return config.getAddress(uint256(OvenueConfigOptions.Addresses.BorrowerImplementation));
  }

  function goAddress(IOvenueConfig config) internal view returns (address) {
    return config.getAddress(uint256(OvenueConfigOptions.Addresses.Go));
  }

//   function stakingRewardsAddress(OvenueConfig config) internal view returns (address) {
//     return config.getAddress(uint256(OvenueConfigOptions.Addresses.StakingRewards));
//   }

  function getCollateraLockupPeriod(IOvenueConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(OvenueConfigOptions.Numbers.CollateralLockedUpInSeconds));
  }

  function getReserveDenominator(IOvenueConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(OvenueConfigOptions.Numbers.ReserveDenominator));
  }

  function getWithdrawFeeDenominator(IOvenueConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(OvenueConfigOptions.Numbers.WithdrawFeeDenominator));
  }

  function getLatenessGracePeriodInDays(IOvenueConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(OvenueConfigOptions.Numbers.LatenessGracePeriodInDays));
  }

  function getLatenessMaxDays(IOvenueConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(OvenueConfigOptions.Numbers.LatenessMaxDays));
  }

  function getDrawdownPeriodInSeconds(IOvenueConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(OvenueConfigOptions.Numbers.DrawdownPeriodInSeconds));
  }

  function getTransferRestrictionPeriodInDays(IOvenueConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(OvenueConfigOptions.Numbers.TransferRestrictionPeriodInDays));
  }

  function getLeverageRatio(IOvenueConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(OvenueConfigOptions.Numbers.LeverageRatio));
  }

  function getCollateralVotingPeriod(IOvenueConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(OvenueConfigOptions.Numbers.CollateralVotingPeriod));
  }

  function getCollateralVotingDelay(IOvenueConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(OvenueConfigOptions.Numbers.CollateralVotingDelay));
  }

  function getCollateralQuorumNumerator(IOvenueConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(OvenueConfigOptions.Numbers.CollateralVotingQuorumNumerator));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "./IOvenueJuniorPool.sol";

interface IOvenueCollateralCustody {
    struct Collateral {
        address nftAddr;
        address governor;
        uint256 tokenId;
        uint256 fungibleAmount;
    }

    struct CollateralStatus {
        uint256 lockedUntil;
        uint256 fundedFungibleAmount;
        uint256 fundedNonfungibleAmount;
        bool nftLocked;
        bool inLiquidationProcess;
    }

    struct NFTLiquidationOrder {
        bytes32 orderHash;
        uint256 price;
        uint256 makerFee;
        uint64 listAt;
        bool fullfilled;
    }
    
    function isCollateralFullyFunded(IOvenueJuniorPool _poolAddr) external returns(bool);
    function createCollateralStats(
        IOvenueJuniorPool _poolAddr,
        address _nftAddr,
        address _governor,
        uint256 _tokenId,
        uint256 _fungibleAmount
    ) external;
    
    function collectFungibleCollateral(
        IOvenueJuniorPool _poolAddr,
        address _depositor,
        uint256 _amount
    ) external;

    function redeemAllCollateral(
        IOvenueJuniorPool _poolAddr,
        address receiver
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

interface IOvenueConfig {
  function getNumber(uint256 index) external view returns (uint256);

  function getAddress(uint256 index) external view returns (address);

  function setAddress(uint256 index, address newAddress) external returns (address);

  function setNumber(uint256 index, uint256 newNumber) external returns (uint256);

  function goList(address account) external view returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "../libraries/SaleKindInterface.sol";

interface IOvenueExchange {
    enum HowToCall { Call, Delegate }

    function approveOrder_(
        address[6] memory addrs,
        uint[6] memory uints,
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        HowToCall howToCall,
        bytes memory callData,
        bytes memory replacementPattern,
        bool orderbookInclusionDesired
    ) external;
    
    function cancelOrder_(
        address[6] memory addrs,
        uint[6] memory uints,
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        HowToCall howToCall,
        bytes memory callData,
        bytes memory replacementPattern,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function cancelledOrFinalized(
        bytes32 orderHash
    ) external view returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "./IERC20withDec.sol";

interface IOvenueSeniorLP is IERC20withDec {
  function mintTo(address to, uint256 amount) external;

  function burnFrom(address to, uint256 amount) external;

  function renounceRole(bytes32 role, address account) external;

  function delegates(address account) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

/**
 * @title ConfigOptions
 * @notice A central place for enumerating the configurable options of our GoldfinchConfig contract
 * @author Goldfinch
 */

library OvenueConfigOptions {
  // NEVER EVER CHANGE THE ORDER OF THESE!
  // You can rename or append. But NEVER change the order.
  enum Numbers {
    TransactionLimit, // 0
    /// @dev: TotalFundsLimit used to represent a total cap on senior pool deposits
    /// but is now deprecated
    TotalFundsLimit, // 1
    MaxUnderwriterLimit, // 2
    ReserveDenominator, // 3
    WithdrawFeeDenominator, // 4
    LatenessGracePeriodInDays, // 5
    LatenessMaxDays, // 6
    DrawdownPeriodInSeconds, // 7
    TransferRestrictionPeriodInDays, // 8
    LeverageRatio, // 9
    CollateralLockedUpInSeconds, // 10
    CollateralVotingDelay, // 11
    CollateralVotingPeriod, // 12
    CollateralVotingQuorumNumerator // 13,
  }
  /// @dev TrustedForwarder is deprecated because we no longer use GSN. CreditDesk
  ///   and Pool are deprecated because they are no longer used in the protocol.
  enum Addresses {
    CreditLineImplementation, // 0
    OvenueFactory, // 1
    Fidu, // 2
    USDC, // 3
    OVENUE, // 4
    TreasuryReserve, // 5
    ProtocolAdmin, // 6
    // OneInch,
    // CUSDCContract,
    OvenueConfig, // 7
    PoolTokens, // 8
    SeniorPool, // 9
    SeniorPoolStrategy, // 10
    TranchedPoolImplementation, // 11
    BorrowerImplementation, // 12
    // OVENUE, 
    Go, // 13
    JuniorRewards, // 14
    CollateralToken, // 15
    CollateralCustody, // 16
    CollateralGovernanceImplementation, // 17
    OvenueExchange // 18
    // StakingRewards
    // FiduUSDCCurveLP
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "./IOvenueJuniorPool.sol";

abstract contract IOvenueSeniorPool {
  uint256 public sharePrice;
  uint256 public totalLoansOutstanding;
  uint256 public totalWritedowns;

  function deposit(uint256 amount) external virtual returns (uint256 depositShares);

  function depositWithPermit(
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external virtual returns (uint256 depositShares);

  function withdraw(uint256 usdcAmount) external virtual returns (uint256 amount);

  function withdrawInLP(uint256 fiduAmount) external virtual returns (uint256 amount);

//   function sweepToCompound() public virtual;

//   function sweepFromCompound() public virtual;

  function invest(IOvenueJuniorPool pool) public virtual;

  function estimateInvestment(IOvenueJuniorPool pool) public view virtual returns (uint256);

  function redeem(uint256 tokenId) public virtual;

  function writedown(uint256 tokenId) public virtual;

  function calculateWritedown(uint256 tokenId) public view virtual returns (uint256 writedownAmount);

  function assets() public view virtual returns (uint256);

  function getNumShares(uint256 amount) public view virtual returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface IOvenueJuniorLP is IERC721Upgradeable {
    event TokenPrincipalWithdrawn(
        address indexed owner,
        address indexed pool,
        uint256 indexed tokenId,
        uint256 principalWithdrawn,
        uint256 tranche
    );
    event TokenBurned(
        address indexed owner,
        address indexed pool,
        uint256 indexed tokenId
    );
    event TokenMinted(
        address indexed owner,
        address indexed pool,
        uint256 indexed tokenId,
        uint256 amount,
        uint256 tranche
    );

    event TokenRedeemed(
        address indexed owner,
        address indexed pool,
        uint256 indexed tokenId,
        uint256 principalRedeemed,
        uint256 interestRedeemed,
        uint256 tranche
    );

    struct TokenInfo {
        address pool;
        uint256 tranche;
        uint256 principalAmount;
        uint256 principalRedeemed;
        uint256 interestRedeemed;
    }

    struct MintParams {
        uint256 principalAmount;
        uint256 tranche;
    }

    function mint(MintParams calldata params, address to)
        external
        returns (uint256);

    function redeem(
        uint256 tokenId,
        uint256 principalRedeemed,
        uint256 interestRedeemed
    ) external;

    function withdrawPrincipal(uint256 tokenId, uint256 principalAmount)
        external;

    function burn(uint256 tokenId) external;

    function onPoolCreated(address newPool) external;

    function getTokenInfo(uint256 tokenId)
        external
        view
        returns (TokenInfo memory);

    function validPool(address sender) external view returns (bool);

    function isApprovedOrOwner(address spender, uint256 tokenId)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20withDec is IERC20Upgradeable {
  /**
   * @dev Returns the number of decimals used for the token
   */
  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

interface IOvenueFactory {
  function createCreditLine() external returns (address);

  function createBorrower(address owner) external returns (address);

  function createPool(
    address _borrower,
    uint256 _juniorFeePercent,
    uint256 _limit,
    uint256 _interestApr,
    uint256 _paymentPeriodInDays,
    uint256 _termInDays,
    uint256 _lateFeeApr,
    uint256[] calldata _allowedUIDTypes
  ) external returns (address);

  function createMigratedPool(
    address _borrower,
    uint256 _juniorFeePercent,
    uint256 _limit,
    uint256 _interestApr,
    uint256 _paymentPeriodInDays,
    uint256 _termInDays,
    uint256 _lateFeeApr,
    uint256[] calldata _allowedUIDTypes
  ) external returns (address);

  function updateGoldfinchConfig() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

abstract contract IGo {
  uint256 public constant ID_TYPE_0 = 0;
  uint256 public constant ID_TYPE_1 = 1;
  uint256 public constant ID_TYPE_2 = 2;
  uint256 public constant ID_TYPE_3 = 3;
  uint256 public constant ID_TYPE_4 = 4;
  uint256 public constant ID_TYPE_5 = 5;
  uint256 public constant ID_TYPE_6 = 6;
  uint256 public constant ID_TYPE_7 = 7;
  uint256 public constant ID_TYPE_8 = 8;
  uint256 public constant ID_TYPE_9 = 9;
  uint256 public constant ID_TYPE_10 = 10;

  /// @notice Returns the address of the UniqueIdentity contract.
  function uniqueIdentity() external virtual returns (address);

  function go(address account) public view virtual returns (bool);

  function goOnlyIdTypes(address account, uint256[] calldata onlyIdTypes) public view virtual returns (bool);

  function goSeniorPool(address account) public view virtual returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "./IOvenueSeniorPool.sol";
import "./IOvenueJuniorPool.sol";

abstract contract IOvenueSeniorPoolStrategy {
//   function getLeverageRatio(IOvenueJuniorPool pool) public view virtual returns (uint256);
  function getLeverageRatio() public view virtual returns (uint256);

  function invest(IOvenueJuniorPool pool) public view virtual returns (uint256 amount);

  function estimateInvestment(IOvenueJuniorPool pool) public view virtual returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

interface IOvenueJuniorRewards {
  function allocateRewards(uint256 _interestPaymentAmount) external;

  // function onTranchedPoolDrawdown(uint256 sliceIndex) external;

  function setPoolTokenAccRewardsPerPrincipalDollarAtMint(address poolAddress, uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import {IV2OvenueCreditLine} from "./IV2OvenueCreditLine.sol";

abstract contract IOvenueJuniorPool {
    IV2OvenueCreditLine public creditLine;
    uint256 public createdAt;

     struct Collateral {
        address nftAddr;
        uint tokenId;
        uint collateralAmount;
        bool isLocked;
    }

    enum Tranches {
        Reserved,
        Senior,
        Junior
    }

    struct TrancheInfo {
        uint256 id;
        uint256 principalDeposited;
        uint256 principalSharePrice;
        uint256 interestSharePrice;
        uint256 lockedUntil;
    }

    struct PoolSlice {
        TrancheInfo seniorTranche;
        TrancheInfo juniorTranche;
        uint256 totalInterestAccrued;
        uint256 principalDeployed;
        uint256 collateralDeposited;
    }

    function initialize(
        // config - borrower
        address[2] calldata _addresses,
        // junior fee percent - late fee apr, interest apr
        uint256[3] calldata _fees,
        // _paymentPeriodInDays - _termInDays - _principalGracePeriodInDays - _fundableAt
        uint256[4] calldata _days,
        uint256 _limit,
        uint256[] calldata _allowedUIDTypes
    ) external virtual;

    function getTranche(uint256 tranche)
        external
        view
        virtual
        returns (TrancheInfo memory);

    function pay(uint256 amount) external virtual;

    function poolSlices(uint256 index)
        external
        view
        virtual
        returns (PoolSlice memory);

    function cancel() external virtual;

    function setCancelStatus(bool status) external virtual;

    function lockJuniorCapital() external virtual;

    function lockPool() external virtual;

    function initializeNextSlice(uint256 _fundableAt) external virtual;

    function totalJuniorDeposits() external view virtual returns (uint256);

    function drawdown(uint256 amount) external virtual;

    function setFundableAt(uint256 timestamp) external virtual;

    function deposit(uint256 tranche, uint256 amount)
        external
        virtual
        returns (uint256 tokenId);

    function assess() external virtual;

    function depositWithPermit(
        uint256 tranche,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual returns (uint256 tokenId);

    function availableToWithdraw(uint256 tokenId)
        external
        view
        virtual
        returns (uint256 interestRedeemable, uint256 principalRedeemable);

    function withdraw(uint256 tokenId, uint256 amount)
        external
        virtual
        returns (uint256 interestWithdrawn, uint256 principalWithdrawn);

    function withdrawMax(uint256 tokenId)
        external
        virtual
        returns (uint256 interestWithdrawn, uint256 principalWithdrawn);

    function withdrawMultiple(
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external virtual;

    // function claimCollateralNFT() external virtual;

    function numSlices() external view virtual returns (uint256);
    // function isCollateralLocked() external view virtual returns (bool);

    // function getCollateralInfo() external view virtual returns(address, uint, bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "./IOvenueCreditLine.sol";

abstract contract IV2OvenueCreditLine is IOvenueCreditLine {
  function principal() external view virtual returns (uint256);

  function totalInterestAccrued() external view virtual returns (uint256);

  function termStartTime() external view virtual returns (uint256);

  function setLimit(uint256 newAmount) external virtual;

  function setMaxLimit(uint256 newAmount) external virtual;

  function setBalance(uint256 newBalance) external virtual;

  function setPrincipal(uint256 _principal) external virtual;

  function setTotalInterestAccrued(uint256 _interestAccrued) external virtual;

  function drawdown(uint256 amount) external virtual;

  function assess()
    external
    virtual
    returns (
      uint256,
      uint256,
      uint256
    );

  function initialize(
    address _config,
    address owner,
    address _borrower,
    uint256 _limit,
    uint256 _interestApr,
    uint256 _paymentPeriodInDays,
    uint256 _termInDays,
    uint256 _lateFeeApr,
    uint256 _principalGracePeriodInDays
  ) public virtual;

  function setTermEndTime(uint256 newTermEndTime) external virtual;

  function setNextDueTime(uint256 newNextDueTime) external virtual;

  function setInterestOwed(uint256 newInterestOwed) external virtual;

  function setPrincipalOwed(uint256 newPrincipalOwed) external virtual;

  function setInterestAccruedAsOf(uint256 newInterestAccruedAsOf) external virtual;

  function setWritedownAmount(uint256 newWritedownAmount) external virtual;

  function setLastFullPaymentTime(uint256 newLastFullPaymentTime) external virtual;

  function setLateFeeApr(uint256 newLateFeeApr) external virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

interface IOvenueCreditLine {
  function borrower() external view returns (address);

  function limit() external view returns (uint256);

  function maxLimit() external view returns (uint256);

  function interestApr() external view returns (uint256);

  function paymentPeriodInDays() external view returns (uint256);

  function principalGracePeriodInDays() external view returns (uint256);

  function termInDays() external view returns (uint256);

  function lateFeeApr() external view returns (uint256);

  function isLate() external view returns (bool);

  function withinPrincipalGracePeriod() external view returns (bool);

  // Accounting variables
  function balance() external view returns (uint256);

  function interestOwed() external view returns (uint256);

  function principalOwed() external view returns (uint256);

  function termEndTime() external view returns (uint256);

  function nextDueTime() external view returns (uint256);

  function interestAccruedAsOf() external view returns (uint256);

  function lastFullPaymentTime() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.5;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library SaleKindInterface {

    /**
     * Side: buy or sell.
     */
    enum Side { Buy, Sell }

    /**
     * Currently supported kinds of sale: fixed price, Dutch auction.
     * English auctions cannot be supported without stronger escrow guarantees.
     * Future interesting options: Vickrey auction, nonlinear Dutch auctions.
     */
    enum SaleKind { FixedPrice, DutchAuction }

    /**
     * @dev Check whether the parameters of a sale are valid
     * @param saleKind Kind of sale
     * @param expirationTime Order expiration time
     * @return Whether the parameters were valid
     */
    function validateParameters(SaleKind saleKind, uint expirationTime)
    pure
    internal
    returns (bool)
    {
        /* Auctions must have a set expiration date. */
        return (saleKind == SaleKind.FixedPrice || expirationTime > 0);
    }

    /**
     * @dev Return whether or not an order can be settled
     * @dev Precondition: parameters have passed validateParameters
     * @param listingTime Order listing time
     * @param expirationTime Order expiration time
     */
    function canSettleOrder(uint listingTime, uint expirationTime)
    view
    internal
    returns (bool)
    {
        return (listingTime < block.timestamp) && (expirationTime == 0 || block.timestamp < expirationTime);
    }

    /**
     * @dev Calculate the settlement price of an order
     * @dev Precondition: parameters have passed validateParameters.
     * @param side Order side
     * @param saleKind Method of sale
     * @param basePrice Order base price
     * @param extra Order extra price data
     * @param listingTime Order listing time
     * @param expirationTime Order expiration time
     */
    function calculateFinalPrice(Side side, SaleKind saleKind, uint basePrice, uint extra, uint listingTime, uint expirationTime)
    view
    internal
    returns (uint finalPrice)
    {
        if (saleKind == SaleKind.FixedPrice) {
            return basePrice;
        }
        else if (saleKind == SaleKind.DutchAuction) {
            uint diff = SafeMath.div(SafeMath.mul(extra, SafeMath.sub(block.timestamp, listingTime)), SafeMath.sub(expirationTime, listingTime));
            if (side == Side.Sell) {
                /* Sell-side - start price: basePrice. End price: basePrice - extra. */
                return SafeMath.sub(basePrice, diff);
            } else {
                /* Buy-side - start price: basePrice. End price: basePrice + extra. */
                return SafeMath.add(basePrice, diff);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}