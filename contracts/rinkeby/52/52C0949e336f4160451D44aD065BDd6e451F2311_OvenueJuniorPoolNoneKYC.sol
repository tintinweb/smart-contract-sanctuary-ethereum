// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../libraries/Math.sol";

import {IOvenueJuniorPool} from "../interfaces/IOvenueJuniorPool.sol";
import {IRequiresUID} from "../interfaces/IRequiresUID.sol";
import {IERC20withDec} from "../interfaces/IERC20withDec.sol";
import {IV2OvenueCreditLine} from "../interfaces/IV2OvenueCreditLine.sol";
import {IOvenueJuniorLP} from "../interfaces/IOvenueJuniorLP.sol";
import {IOvenueConfig} from "../interfaces/IOvenueConfig.sol";
import {BaseUpgradeablePausable} from "../upgradeable/BaseUpgradeablePausable.sol";
import {OvenueConfigHelper} from "../libraries/OvenueConfigHelper.sol";
import {OvenueTranchingLogic} from "../libraries/OvenueTranchingLogic.sol";
import {OvenueJuniorPoolLogic} from "../libraries/OvenueJuniorPoolLogic.sol";

contract OvenueJuniorPoolNoneKYC is
    BaseUpgradeablePausable,
    IRequiresUID,
    IOvenueJuniorPool
{
    error NFTCollateralNotLocked();
    error CreditLineBalanceExisted(uint256 balance);
    error AddressZeroInitialization();
    error JuniorTranchAlreadyLocked();
    error PoolNotOpened();
    error InvalidDepositAmount(uint256 amount);
    error AllowedUIDNotGranted(address sender);
    error DrawnDownPaused();
    error UnauthorizedCaller();
    error UnmatchedArraysLength();
    error PoolBalanceNotEmpty();
    error NotFullyCollateral();

    IOvenueConfig public config;
    using OvenueConfigHelper for IOvenueConfig;

    // // Events ////////////////////////////////////////////////////////////////////

    event DrawdownsToggled(address indexed pool, bool isAllowed);
    // event TrancheLocked(
    //     address indexed pool,
    //     uint256 trancheId,
    //     uint256 lockedUntil
    // );

    bytes32 public constant LOCKER_ROLE = keccak256("LOCKER_ROLE");
    bytes32 public constant SENIOR_ROLE = keccak256("SENIOR_ROLE");
    // uint8 internal constant MAJOR_VERSION = 0;
    // uint8 internal constant MINOR_VERSION = 1;
    // uint8 internal constant PATCH_VERSION = 0;

    bool public drawdownsPaused;

    uint256 public juniorFeePercent;
    uint256 public totalDeployed;
    uint256 public fundableAt;
    uint256 public override numSlices;

    uint256[] public allowedUIDTypes;

    mapping(uint256 => PoolSlice) internal _poolSlices;

    function initialize(
        // config - borrower
        address[2] calldata _addresses,
        // junior fee percent - late fee apr, interest apr
        uint256[3] calldata _fees,
        // _paymentPeriodInDays - _termInDays - _principalGracePeriodInDays - _fundableAt
        uint256[4] calldata _days,
        uint256 _limit,
        uint256[] calldata _allowedUIDTypes
    ) external override initializer {
        if (
            !(address(_addresses[0]) != address(0) &&
                address(_addresses[1]) != address(0))
        ) {
            revert AddressZeroInitialization();
        }

     
        config = IOvenueConfig(_addresses[0]);

        address owner = config.protocolAdminAddress();
        __BaseUpgradeablePausable__init(owner);
        

        (numSlices, creditLine) = OvenueJuniorPoolLogic.initialize(
            _poolSlices,
            numSlices,
            config,
            _addresses[1],
            _fees,
            _days,
            _limit
        );

        if (_allowedUIDTypes.length == 0) {
            uint256[1] memory defaultAllowedUIDTypes = [
                config.getGo().ID_TYPE_0()
            ];
            allowedUIDTypes = defaultAllowedUIDTypes;
        } else {
            allowedUIDTypes = _allowedUIDTypes;
        }

        createdAt = block.timestamp;
        fundableAt = _days[3];
        juniorFeePercent = _fees[0];

        _setupRole(LOCKER_ROLE, _addresses[1]);
        _setupRole(LOCKER_ROLE, owner);
        _setRoleAdmin(LOCKER_ROLE, OWNER_ROLE);
        _setRoleAdmin(SENIOR_ROLE, OWNER_ROLE);

        // Give the senior pool the ability to deposit into the senior pool
        _setupRole(SENIOR_ROLE, address(config.getSeniorPool()));

        // Unlock self for infinite amount
        require(config.getUSDC().approve(address(this), type(uint256).max));
    }

    function setAllowedUIDTypes(uint256[] calldata ids) external onlyLocker {
        if (
            !(_poolSlices[0].juniorTranche.principalDeposited == 0 &&
                _poolSlices[0].seniorTranche.principalDeposited == 0)
        ) {
            revert PoolBalanceNotEmpty();
        }

        allowedUIDTypes = ids;
    }

    function getAllowedUIDTypes() external view returns (uint256[] memory) {
        return allowedUIDTypes;
    }

    /**
     * @notice Deposit a USDC amount into the pool for a tranche. Mints an NFT to the caller representing the position
     * @param tranche The number representing the tranche to deposit into
     * @param amount The USDC amount to tranfer from the caller to the pool
     * @return tokenId The tokenId of the NFT
     */
    function deposit(uint256 tranche, uint256 amount)
        public
        override
        nonReentrant
        whenNotPaused
        returns (uint256)
    {
        TrancheInfo storage trancheInfo = OvenueJuniorPoolLogic._getTrancheInfo(
            _poolSlices,
            numSlices,
            tranche
        );

        // /// @dev TL: Collateral locked
        if (!config.getCollateralCustody().isCollateralFullyFunded(IOvenueJuniorPool(address(this)))) {
            revert NotFullyCollateral();
        }

        /// @dev TL: tranche locked
        if (trancheInfo.lockedUntil != 0) {
            revert JuniorTranchAlreadyLocked();
        }

        /// @dev TL: Pool not opened
        if (block.timestamp < fundableAt) {
            revert PoolNotOpened();
        }

        /// @dev IA: invalid amount
        if (amount <= 0) {
            revert InvalidDepositAmount(amount);
        }

        // senior tranche ids are always odd numbered
        if (OvenueTranchingLogic.isSeniorTrancheId(trancheInfo.id)) {
            if (!hasRole(SENIOR_ROLE, _msgSender())) {
                revert UnauthorizedCaller();
            }
        }

        return OvenueJuniorPoolLogic.deposit(trancheInfo, config, amount);
    }

    function depositWithPermit(
        uint256 tranche,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override returns (uint256 tokenId) {
        IERC20Permit(config.usdcAddress()).permit(
            msg.sender,
            address(this),
            amount,
            deadline,
            v,
            r,
            s
        );
        return deposit(tranche, amount);
    }

    /**
     * @notice Withdraw an already deposited amount if the funds are available
     * @param tokenId The NFT representing the position
     * @param amount The amount to withdraw (must be <= interest+principal currently available to withdraw)
     * @return interestWithdrawn The interest amount that was withdrawn
     * @return principalWithdrawn The principal amount that was withdrawn
     */
    function withdraw(uint256 tokenId, uint256 amount)
        public
        override
        nonReentrant
        whenNotPaused
        returns (uint256, uint256)
    {
        /// @dev NA: not authorized
        if (
            !(config.getJuniorLP().isApprovedOrOwner(msg.sender, tokenId) &&
                hasAllowedUID(msg.sender))
        ) {
            revert UnauthorizedCaller();
        }
        return
            OvenueJuniorPoolLogic.withdraw(
                _poolSlices,
                numSlices,
                tokenId,
                amount,
                config
            );
    }

    /**
     * @notice Withdraw from many tokens (that the sender owns) in a single transaction
     * @param tokenIds An array of tokens ids representing the position
     * @param amounts An array of amounts to withdraw from the corresponding tokenIds
     */
    function withdrawMultiple(
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) public override {
        if (tokenIds.length != amounts.length) {
            revert UnmatchedArraysLength();
        }

        uint256 i;

        while (i < amounts.length) {
            withdraw(tokenIds[i], amounts[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Similar to withdraw but will withdraw all available funds
     * @param tokenId The NFT representing the position
     * @return interestWithdrawn The interest amount that was withdrawn
     * @return principalWithdrawn The principal amount that was withdrawn
     */
    function withdrawMax(uint256 tokenId)
        external
        override
        nonReentrant
        whenNotPaused
        returns (uint256 interestWithdrawn, uint256 principalWithdrawn)
    {
        return
            OvenueJuniorPoolLogic.withdrawMax(
                _poolSlices,
                numSlices,
                tokenId,
                config
            );
    }

    /**
     * @notice Draws down the funds (and locks the pool) to the borrower address. Can only be called by the borrower
     * @param amount The amount to drawdown from the creditline (must be < limit)
     */
    function drawdown(uint256 amount)
        external
        override
        onlyLocker
        whenNotPaused
    {
        /// @dev DP: drawdowns paused
        if (drawdownsPaused) {
            revert DrawnDownPaused();
        }

        totalDeployed = OvenueJuniorPoolLogic.drawdown(
            _poolSlices,
            creditLine,
            config,
            numSlices,
            amount,
            totalDeployed
        );
    }

    function NUM_TRANCHES_PER_SLICE() external pure returns (uint256) {
        return OvenueTranchingLogic.NUM_TRANCHES_PER_SLICE;
    }

    /**
     * @notice Locks the junior tranche, preventing more junior deposits. Gives time for the senior to determine how
     * much to invest (ensure leverage ratio cannot change for the period)
     */
    function lockJuniorCapital() external override onlyLocker whenNotPaused {
        _lockJuniorCapital(numSlices - 1);
    }

    /**
     * @notice Locks the pool (locks both senior and junior tranches and starts the drawdown period). Beyond the drawdown
     * period, any unused capital is available to withdraw by all depositors
     */
    function lockPool() external override onlyLocker whenNotPaused {
        OvenueJuniorPoolLogic.lockPool(
            _poolSlices,
            creditLine,
            config,
            numSlices
        );
    }

    function setFundableAt(uint256 newFundableAt) external override onlyLocker {
        fundableAt = newFundableAt;
    }

    function initializeNextSlice(uint256 _fundableAt)
        external
        override
        onlyLocker
        whenNotPaused
    {
        fundableAt = _fundableAt;
        numSlices = OvenueJuniorPoolLogic.initializeAnotherNextSlice(
            _poolSlices,
            creditLine,
            numSlices
        );
    }

    /**
     * @notice Triggers an assessment of the creditline and the applies the payments according the tranche waterfall
     */
    function assess() external override whenNotPaused {
        totalDeployed = OvenueJuniorPoolLogic.assess(
            _poolSlices,
            [address(creditLine), address(config)],
            [numSlices, totalDeployed, juniorFeePercent]
        );
    }

    // function claimCollateralNFT() external virtual override onlyLocker {
    //     uint256 creditBalance = IV2OvenueCreditLine(creditLine).balance();
    //     if (creditBalance != 0) {
    //         revert CreditLineBalanceExisted(creditBalance);
    //     }

    //     IERC721(collateral.nftAddr).safeTransferFrom(
    //         address(this),
    //         msg.sender,
    //         collateral.tokenId,
    //         ""
    //     );
    //     collateral.isLocked = false;

    //     emit NFTCollateralClaimed(
    //         msg.sender,
    //         collateral.nftAddr,
    //         collateral.tokenId
    //     );
    // }

    /**
     * @notice Allows repaying the creditline. Collects the USDC amount from the sender and triggers an assess
     * @param amount The amount to repay
     */
    function pay(uint256 amount) external override whenNotPaused {
        totalDeployed = OvenueJuniorPoolLogic.pay(
            _poolSlices,
            [address(creditLine), address(config)],
            [numSlices, totalDeployed, juniorFeePercent, amount]
        );
    }

    /**
     * @notice Pauses the pool and sweeps any remaining funds to the treasury reserve.
     */
    function emergencyShutdown() public onlyAdmin {
        if (!paused()) {
            _pause();
        }

        OvenueJuniorPoolLogic.emergencyShutdown(config, creditLine);
    }

    /**
     * @notice Toggles all drawdowns (but not deposits/withdraws)
     */
    function toggleDrawdowns() public onlyAdmin {
        drawdownsPaused = drawdownsPaused ? false : true;
        emit DrawdownsToggled(address(this), drawdownsPaused);
    }

    // CreditLine proxy method
    function setLimit(uint256 newAmount) external onlyAdmin {
        return creditLine.setLimit(newAmount);
    }

    function setMaxLimit(uint256 newAmount) external onlyAdmin {
        return creditLine.setMaxLimit(newAmount);
    }

    function getTranche(uint256 tranche)
        public
        view
        override
        returns (TrancheInfo memory)
    {
        return
            OvenueJuniorPoolLogic._getTrancheInfo(
                _poolSlices,
                numSlices,
                tranche
            );
    }

    function poolSlices(uint256 index)
        external
        view
        override
        returns (PoolSlice memory)
    {
        return _poolSlices[index];
    }

    /**
     * @notice Returns the total junior capital deposited
     * @return The total USDC amount deposited into all junior tranches
     */
    function totalJuniorDeposits() external view override returns (uint256) {
        uint256 total;
        for (uint256 i = 0; i < numSlices; i++) {
            total = total + _poolSlices[i].juniorTranche.principalDeposited;
        }
        return total;
    }

    // /**
    //  * @notice Returns boolean to check if nft is locked
    //  * @return Check whether nft is locked as collateral
    //  */
    // function isCollateralLocked() external view override returns (bool) {
    //     return collateral.isLocked;
    // }

    // function getCollateralInfo()
    //     external
    //     view
    //     virtual
    //     override
    //     returns (
    //         address,
    //         uint256,
    //         bool
    //     )
    // {
    //     return (
    //         collateral.nftAddr,
    //         collateral.tokenId,
    //         collateral.isLocked
    //     );
    // }

    /**
     * @notice Determines the amount of interest and principal redeemable by a particular tokenId
     * @param tokenId The token representing the position
     * @return interestRedeemable The interest available to redeem
     * @return principalRedeemable The principal available to redeem
     */
    function availableToWithdraw(uint256 tokenId)
        public
        view
        override
        returns (uint256, uint256)
    {
        return
            OvenueJuniorPoolLogic.availableToWithdraw(
                _poolSlices,
                numSlices,
                config,
                tokenId
            );
    }

    function hasAllowedUID(address sender) public view override returns (bool) {
        return config.getGo().goOnlyIdTypes(sender, allowedUIDTypes);
    }

    function _lockJuniorCapital(uint256 sliceId) internal {
        OvenueJuniorPoolLogic.lockJuniorCapital(
            _poolSlices,
            numSlices,
            config,
            sliceId
        );
    }

    // // // Modifiers /////////////////////////////////////////////////////////////////

    modifier onlyLocker() {
        /// @dev NA: not authorized. not locker
        if (!hasRole(LOCKER_ROLE, msg.sender)) {
            revert UnauthorizedCaller();
        }
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)
pragma solidity ^0.8.5;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
   
    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }
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

interface IRequiresUID {
  function hasAllowedUID(address sender) external view returns (bool);
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
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

interface IOvenueConfig {
  function getNumber(uint256 index) external view returns (uint256);

  function getAddress(uint256 index) external view returns (address);

  function setAddress(uint256 index, address newAddress) external returns (address);

  function setNumber(uint256 index, uint256 newNumber) external returns (uint256);
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

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

/**
 * @title BaseUpgradeablePausable contract
 * @notice This is our Base contract that most other contracts inherit from. It includes many standard
 *  useful abilities like upgradeability, pausability, access control, and re-entrancy guards.
 * @author Goldfinch
 */

contract BaseUpgradeablePausable is
    AccessControlUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    // Pre-reserving a few slots in the base contract in case we need to add things in the future.
    // This does not actually take up gas cost or storage cost, but it does reserve the storage slots.
    // See OpenZeppelin's use of this pattern here:
    // https://github.com/OpenZeppelin/openzeppelin-contracts-ethereum-package/blob/master/contracts/GSN/Context.sol#L37
    uint256[50] private __gap1;
    uint256[50] private __gap2;
    uint256[50] private __gap3;
    uint256[50] private __gap4;

    // solhint-disable-next-line func-name-mixedcase
    function __BaseUpgradeablePausable__init(address owner) public onlyInitializing {
        require(owner != address(0), "Owner cannot be the zero address");
        __AccessControl_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        _setupRole(OWNER_ROLE, owner);
        _setupRole(PAUSER_ROLE, owner);

        _setRoleAdmin(PAUSER_ROLE, OWNER_ROLE);
        _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
    }

    function isAdmin() public view returns (bool) {
        return hasRole(OWNER_ROLE, _msgSender());
    }

    modifier onlyAdmin() {
        require(isAdmin(), "Must have admin role to perform this action");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "./Math.sol";
import "./WadRayMath.sol";
import {IV2OvenueCreditLine} from "../interfaces/IV2OvenueCreditLine.sol";
import {IOvenueJuniorPool} from "../interfaces/IOvenueJuniorPool.sol";
import {IOvenueJuniorLP} from "../interfaces/IOvenueJuniorLP.sol";
import {IOvenueConfig} from "../interfaces/IOvenueConfig.sol";
import {OvenueConfigHelper} from "./OvenueConfigHelper.sol";

/**
 * @title OvenueTranchingLogic
 * @notice Library for handling the payments waterfall
 * @author Goldfinch
 */

library OvenueTranchingLogic {
    // event TranchedPoolAssessed(address indexed pool);
    event PaymentApplied(
        address indexed payer,
        address indexed pool,
        uint256 interestAmount,
        uint256 principalAmount,
        uint256 remainingAmount,
        uint256 reserveAmount
    );

    using WadRayMath for uint256;

    using OvenueConfigHelper for IOvenueConfig;

    struct SliceInfo {
        uint256 reserveFeePercent;
        uint256 interestAccrued;
        uint256 principalAccrued;
    }

    struct ApplyResult {
        uint256 interestRemaining;
        uint256 principalRemaining;
        uint256 reserveDeduction;
        uint256 oldInterestSharePrice;
        uint256 oldPrincipalSharePrice;
    }

    uint256 internal constant FP_SCALING_FACTOR = 1e18;
    uint256 public constant NUM_TRANCHES_PER_SLICE = 2;

    function usdcToSharePrice(uint256 amount, uint256 totalShares)
        public
        pure
        returns (uint256)
    {
        return
            totalShares == 0
                ? 0
                : amount.wadDiv(totalShares);
    }

    function sharePriceToUsdc(uint256 sharePrice, uint256 totalShares)
        public
        pure
        returns (uint256)
    {
        return sharePrice * totalShares / WadRayMath.WAD;
    }

    function lockTranche(
        IOvenueJuniorPool.TrancheInfo storage tranche,
        IOvenueConfig config
    ) external {
        tranche.lockedUntil = block.timestamp + (
            config.getDrawdownPeriodInSeconds()
        );
        emit TrancheLocked(address(this), tranche.id, tranche.lockedUntil);
    }

    function redeemableInterestAndPrincipal(
        IOvenueJuniorPool.TrancheInfo storage trancheInfo,
        IOvenueJuniorLP.TokenInfo memory tokenInfo
    ) public view returns (uint256, uint256) {
        // This supports withdrawing before or after locking because principal share price starts at 1
        // and is set to 0 on lock. Interest share price is always 0 until interest payments come back, when it increases
        uint256 maxPrincipalRedeemable = sharePriceToUsdc(
            trancheInfo.principalSharePrice,
            tokenInfo.principalAmount
        );
        // The principalAmount is used as the totalShares because we want the interestSharePrice to be expressed as a
        // percent of total loan value e.g. if the interest is 10% APR, the interestSharePrice should approach a max of 0.1.
        uint256 maxInterestRedeemable = sharePriceToUsdc(
            trancheInfo.interestSharePrice,
            tokenInfo.principalAmount
        );

        uint256 interestRedeemable = maxInterestRedeemable - (
            tokenInfo.interestRedeemed
        );
        uint256 principalRedeemable = maxPrincipalRedeemable - (
            tokenInfo.principalRedeemed
        );

        return (interestRedeemable, principalRedeemable);
    }

    function calculateExpectedSharePrice(
        IOvenueJuniorPool.TrancheInfo memory tranche,
        uint256 amount,
        IOvenueJuniorPool.PoolSlice memory slice
    ) public pure returns (uint256) {
        uint256 sharePrice = usdcToSharePrice(
            amount,
            tranche.principalDeposited
        );
        return _scaleByPercentOwnership(tranche, sharePrice, slice);
    }

    function scaleForSlice(
        IOvenueJuniorPool.PoolSlice memory slice,
        uint256 amount,
        uint256 totalDeployed
    ) public pure returns (uint256) {
        return scaleByFraction(amount, slice.principalDeployed, totalDeployed);
    }

    // We need to create this struct so we don't run into a stack too deep error due to too many variables
    function getSliceInfo(
        IOvenueJuniorPool.PoolSlice memory slice,
        IV2OvenueCreditLine creditLine,
        uint256 totalDeployed,
        uint256 reserveFeePercent
    ) public view returns (SliceInfo memory) {
        (
            uint256 interestAccrued,
            uint256 principalAccrued
        ) = getTotalInterestAndPrincipal(slice, creditLine, totalDeployed);
        return
            SliceInfo({
                reserveFeePercent: reserveFeePercent,
                interestAccrued: interestAccrued,
                principalAccrued: principalAccrued
            });
    }

    function getTotalInterestAndPrincipal(
        IOvenueJuniorPool.PoolSlice memory slice,
        IV2OvenueCreditLine creditLine,
        uint256 totalDeployed
    ) public view returns (uint256, uint256) {
        uint256 principalAccrued = creditLine.principalOwed();
        // In addition to principal actually owed, we need to account for early principal payments
        // If the borrower pays back 5K early on a 10K loan, the actual principal accrued should be
        // 5K (balance- deployed) + 0 (principal owed)
        principalAccrued = totalDeployed - creditLine.balance() + principalAccrued;
        // Now we need to scale that correctly for the slice we're interested in
        principalAccrued = scaleForSlice(
            slice,
            principalAccrued,
            totalDeployed
        );
        // Finally, we need to account for partial drawdowns. e.g. If 20K was deposited, and only 10K was drawn down,
        // Then principal accrued should start at 10K (total deposited - principal deployed), not 0. This is because
        // share price starts at 1, and is decremented by what was drawn down.
        uint256 totalDeposited = slice.seniorTranche.principalDeposited + (
            slice.juniorTranche.principalDeposited
        );
        principalAccrued = totalDeposited - slice.principalDeployed + principalAccrued;
        return (slice.totalInterestAccrued, principalAccrued);
    }

    function scaleByFraction(
        uint256 amount,
        uint256 fraction,
        uint256 total
    ) public pure returns (uint256) {
        // uint256 totalAsFixedPoint = FixedPoint
        //     .fromUnscaledUint(total);
        // uint256 memory fractionAsFixedPoint = FixedPoint
        //     .fromUnscaledUint(fraction);
        // return
        //     fractionAsFixedPoint
        //         .div(totalAsFixedPoint)
        //         .mul(amount)
        //         .div(FP_SCALING_FACTOR)
        //         .rawValue;

        return fraction.wadDiv(total).wadMul(amount);
    }

    /// @notice apply a payment to all slices
    /// @param poolSlices slices to apply to
    /// @param numSlices number of slices
    /// @param interest amount of interest to apply
    /// @param principal amount of principal to apply
    /// @param reserveFeePercent percentage that protocol will take for reserves
    /// @param totalDeployed total amount of principal deployed
    /// @param creditLine creditline to account for
    /// @param juniorFeePercent percentage the junior tranche will take
    /// @return total amount that will be sent to reserves
    function applyToAllSlices(
        mapping(uint256 => IOvenueJuniorPool.PoolSlice) storage poolSlices,
        uint256 numSlices,
        uint256 interest,
        uint256 principal,
        uint256 reserveFeePercent,
        uint256 totalDeployed,
        IV2OvenueCreditLine creditLine,
        uint256 juniorFeePercent
    ) external returns (uint256) {
        ApplyResult memory result = OvenueTranchingLogic.applyToAllSeniorTranches(
            poolSlices,
            numSlices,
            interest,
            principal,
            reserveFeePercent,
            totalDeployed,
            creditLine,
            juniorFeePercent
        );

        return
            result.reserveDeduction + (
                OvenueTranchingLogic.applyToAllJuniorTranches(
                    poolSlices,
                    numSlices,
                    result.interestRemaining,
                    result.principalRemaining,
                    reserveFeePercent,
                    totalDeployed,
                    creditLine
                )
            );
    }

    function applyToAllSeniorTranches(
        mapping(uint256 => IOvenueJuniorPool.PoolSlice) storage poolSlices,
        uint256 numSlices,
        uint256 interest,
        uint256 principal,
        uint256 reserveFeePercent,
        uint256 totalDeployed,
        IV2OvenueCreditLine creditLine,
        uint256 juniorFeePercent
    ) internal returns (ApplyResult memory) {
        ApplyResult memory seniorApplyResult;
        for (uint256 i = 0; i < numSlices; i++) {
            IOvenueJuniorPool.PoolSlice storage slice = poolSlices[i];

            SliceInfo memory sliceInfo = getSliceInfo(
                slice,
                creditLine,
                totalDeployed,
                reserveFeePercent
            );

            // Since slices cannot be created when the loan is late, all interest collected can be assumed to split
            // pro-rata across the slices. So we scale the interest and principal to the slice
            ApplyResult memory applyResult = applyToSeniorTranche(
                slice,
                scaleForSlice(slice, interest, totalDeployed),
                scaleForSlice(slice, principal, totalDeployed),
                juniorFeePercent,
                sliceInfo
            );
            emitSharePriceUpdatedEvent(slice.seniorTranche, applyResult);
            seniorApplyResult.interestRemaining = seniorApplyResult
                .interestRemaining
                 + (applyResult.interestRemaining);
            seniorApplyResult.principalRemaining = seniorApplyResult
                .principalRemaining
                 + (applyResult.principalRemaining);
            seniorApplyResult.reserveDeduction = seniorApplyResult
                .reserveDeduction
                 + (applyResult.reserveDeduction);
        }
        return seniorApplyResult;
    }

    function applyToAllJuniorTranches(
        mapping(uint256 => IOvenueJuniorPool.PoolSlice) storage poolSlices,
        uint256 numSlices,
        uint256 interest,
        uint256 principal,
        uint256 reserveFeePercent,
        uint256 totalDeployed,
        IV2OvenueCreditLine creditLine
    ) internal returns (uint256 totalReserveAmount) {
        for (uint256 i = 0; i < numSlices; i++) {
            SliceInfo memory sliceInfo = getSliceInfo(
                poolSlices[i],
                creditLine,
                totalDeployed,
                reserveFeePercent
            );
            // Any remaining interest and principal is then shared pro-rata with the junior slices
            ApplyResult memory applyResult = applyToJuniorTranche(
                poolSlices[i],
                scaleForSlice(poolSlices[i], interest, totalDeployed),
                scaleForSlice(poolSlices[i], principal, totalDeployed),
                sliceInfo
            );
            emitSharePriceUpdatedEvent(
                poolSlices[i].juniorTranche,
                applyResult
            );
            totalReserveAmount = totalReserveAmount + applyResult.reserveDeduction;
        }
        return totalReserveAmount;
    }

    function emitSharePriceUpdatedEvent(
        IOvenueJuniorPool.TrancheInfo memory tranche,
        ApplyResult memory applyResult
    ) internal {
        emit SharePriceUpdated(
            address(this),
            tranche.id,
            tranche.principalSharePrice,
            int256(
                tranche.principalSharePrice - applyResult.oldPrincipalSharePrice
            ),
            tranche.interestSharePrice,
            int256(
                tranche.interestSharePrice - applyResult.oldInterestSharePrice
            )
        );
    }

    function applyToSeniorTranche(
        IOvenueJuniorPool.PoolSlice storage slice,
        uint256 interestRemaining,
        uint256 principalRemaining,
        uint256 juniorFeePercent,
        SliceInfo memory sliceInfo
    ) internal returns (ApplyResult memory) {
        // First determine the expected share price for the senior tranche. This is the gross amount the senior
        // tranche should receive.
        uint256 expectedInterestSharePrice = calculateExpectedSharePrice(
            slice.seniorTranche,
            sliceInfo.interestAccrued,
            slice
        );
        uint256 expectedPrincipalSharePrice = calculateExpectedSharePrice(
            slice.seniorTranche,
            sliceInfo.principalAccrued,
            slice
        );

        // Deduct the junior fee and the protocol reserve
        uint256 desiredNetInterestSharePrice = scaleByFraction(
            expectedInterestSharePrice,
            uint256(100) - (juniorFeePercent + (sliceInfo.reserveFeePercent)),
            uint256(100)
        );
        // Collect protocol fee interest received (we've subtracted this from the senior portion above)
        uint256 reserveDeduction = scaleByFraction(
            interestRemaining,
            sliceInfo.reserveFeePercent,
            uint256(100)
        );
        interestRemaining = interestRemaining - reserveDeduction;
        uint256 oldInterestSharePrice = slice.seniorTranche.interestSharePrice;
        uint256 oldPrincipalSharePrice = slice
            .seniorTranche
            .principalSharePrice;
        // Apply the interest remaining so we get up to the netInterestSharePrice
        (interestRemaining, principalRemaining) = _applyBySharePrice(
            slice.seniorTranche,
            interestRemaining,
            principalRemaining,
            desiredNetInterestSharePrice,
            expectedPrincipalSharePrice
        );
        return
            ApplyResult({
                interestRemaining: interestRemaining,
                principalRemaining: principalRemaining,
                reserveDeduction: reserveDeduction,
                oldInterestSharePrice: oldInterestSharePrice,
                oldPrincipalSharePrice: oldPrincipalSharePrice
            });
    }

    function applyToJuniorTranche(
        IOvenueJuniorPool.PoolSlice storage slice,
        uint256 interestRemaining,
        uint256 principalRemaining,
        SliceInfo memory sliceInfo
    ) public returns (ApplyResult memory) {
        // Then fill up the junior tranche with all the interest remaining, upto the principal share price
        uint256 expectedInterestSharePrice = slice
            .juniorTranche
            .interestSharePrice
            + (
                usdcToSharePrice(
                    interestRemaining,
                    slice.juniorTranche.principalDeposited
                )
            );
        uint256 expectedPrincipalSharePrice = calculateExpectedSharePrice(
            slice.juniorTranche,
            sliceInfo.principalAccrued,
            slice
        );
        uint256 oldInterestSharePrice = slice.juniorTranche.interestSharePrice;
        uint256 oldPrincipalSharePrice = slice
            .juniorTranche
            .principalSharePrice;
        (interestRemaining, principalRemaining) = _applyBySharePrice(
            slice.juniorTranche,
            interestRemaining,
            principalRemaining,
            expectedInterestSharePrice,
            expectedPrincipalSharePrice
        );

        // All remaining interest and principal is applied towards the junior tranche as interest
        interestRemaining = interestRemaining + principalRemaining;
        // Since any principal remaining is treated as interest (there is "extra" interest to be distributed)
        // we need to make sure to collect the protocol fee on the additional interest (we only deducted the
        // fee on the original interest portion)
        uint256 reserveDeduction = scaleByFraction(
            principalRemaining,
            sliceInfo.reserveFeePercent,
            uint256(100)
        );
        interestRemaining = interestRemaining - reserveDeduction;
        principalRemaining = 0;

        (interestRemaining, principalRemaining) = _applyByAmount(
            slice.juniorTranche,
            interestRemaining + principalRemaining,
            0,
            interestRemaining + principalRemaining,
            0
        );
        return
            ApplyResult({
                interestRemaining: interestRemaining,
                principalRemaining: principalRemaining,
                reserveDeduction: reserveDeduction,
                oldInterestSharePrice: oldInterestSharePrice,
                oldPrincipalSharePrice: oldPrincipalSharePrice
            });
    }

    function migrateAccountingVariables(
        IV2OvenueCreditLine originalCl,
        IV2OvenueCreditLine newCl
    ) external {
        // Copy over all accounting variables
        newCl.setBalance(originalCl.balance());
        newCl.setLimit(originalCl.limit());
        newCl.setInterestOwed(originalCl.interestOwed());
        newCl.setPrincipalOwed(originalCl.principalOwed());
        newCl.setTermEndTime(originalCl.termEndTime());
        newCl.setNextDueTime(originalCl.nextDueTime());
        newCl.setInterestAccruedAsOf(originalCl.interestAccruedAsOf());
        newCl.setLastFullPaymentTime(originalCl.lastFullPaymentTime());
        newCl.setTotalInterestAccrued(originalCl.totalInterestAccrued());
    }

    function closeCreditLine(IV2OvenueCreditLine cl) external {
        // Close out old CL
        cl.setBalance(0);
        cl.setLimit(0);
        cl.setMaxLimit(0);
    }

    function trancheIdToSliceIndex(uint256 trancheId)
        external
        pure
        returns (uint256)
    {
        return (trancheId - 1) / NUM_TRANCHES_PER_SLICE;
    }

    function initializeNextSlice(
        mapping(uint256 => IOvenueJuniorPool.PoolSlice) storage poolSlices,
        uint256 sliceIndex
    ) external {
        poolSlices[sliceIndex] = IOvenueJuniorPool.PoolSlice({
            seniorTranche: IOvenueJuniorPool.TrancheInfo({
                id: sliceIndexToSeniorTrancheId(sliceIndex),
                principalSharePrice: usdcToSharePrice(1, 1),
                interestSharePrice: 0,
                principalDeposited: 0,
                lockedUntil: 0
            }),
            juniorTranche: IOvenueJuniorPool.TrancheInfo({
                id: sliceIndexToJuniorTrancheId(sliceIndex),
                principalSharePrice: usdcToSharePrice(1, 1),
                interestSharePrice: 0,
                principalDeposited: 0,
                lockedUntil: 0
            }),
            totalInterestAccrued: 0,
            principalDeployed: 0,
            collateralDeposited: 0
        });
    }

    function sliceIndexToJuniorTrancheId(uint256 sliceIndex)
        public
        pure
        returns (uint256)
    {
        // 0 -> 2
        // 1 -> 4
        return sliceIndex* NUM_TRANCHES_PER_SLICE + 2;
    }

    function sliceIndexToSeniorTrancheId(uint256 sliceIndex)
        public
        pure
        returns (uint256)
    {
        // 0 -> 1
        // 1 -> 3
        return sliceIndex * NUM_TRANCHES_PER_SLICE + 1;
    }

    function isSeniorTrancheId(uint256 trancheId) external pure returns (bool) {
        uint seniorTrancheId;
        uint numberOfTranchesPerSlice = OvenueTranchingLogic.NUM_TRANCHES_PER_SLICE;
        
        assembly {
            seniorTrancheId := mod(trancheId, numberOfTranchesPerSlice)
        }

        return seniorTrancheId == 1;
    }

    function isJuniorTrancheId(uint256 trancheId) external pure returns (bool) {
        uint juniorTrancheId;
        uint numberOfTranchesPerSlice = OvenueTranchingLogic.NUM_TRANCHES_PER_SLICE;

        assembly {
            juniorTrancheId := mod(trancheId, numberOfTranchesPerSlice)
        }

        return trancheId != 0 && juniorTrancheId == 0;
    }

    // // INTERNAL //////////////////////////////////////////////////////////////////

    function _applyToSharePrice(
        uint256 amountRemaining,
        uint256 currentSharePrice,
        uint256 desiredAmount,
        uint256 totalShares
    ) internal pure returns (uint256, uint256) {
        // If no money left to apply, or don't need any changes, return the original amounts
        if (amountRemaining == 0 || desiredAmount == 0) {
            return (amountRemaining, currentSharePrice);
        }
        if (amountRemaining < desiredAmount) {
            // We don't have enough money to adjust share price to the desired level. So just use whatever amount is left
            desiredAmount = amountRemaining;
        }
        uint256 sharePriceDifference = usdcToSharePrice(
            desiredAmount,
            totalShares
        );
        return (
            amountRemaining - desiredAmount,
            currentSharePrice + sharePriceDifference
        );
    }

    function _scaleByPercentOwnership(
        IOvenueJuniorPool.TrancheInfo memory tranche,
        uint256 amount,
        IOvenueJuniorPool.PoolSlice memory slice
    ) internal pure returns (uint256) {
        uint256 totalDeposited = slice.juniorTranche.principalDeposited + (
            slice.seniorTranche.principalDeposited
        );
        return
            scaleByFraction(amount, tranche.principalDeposited, totalDeposited);
    }

    function _desiredAmountFromSharePrice(
        uint256 desiredSharePrice,
        uint256 actualSharePrice,
        uint256 totalShares
    ) internal pure returns (uint256) {
        // If the desired share price is lower, then ignore it, and leave it unchanged
        if (desiredSharePrice < actualSharePrice) {
            desiredSharePrice = actualSharePrice;
        }
        uint256 sharePriceDifference = desiredSharePrice - actualSharePrice;
        return sharePriceToUsdc(sharePriceDifference, totalShares);
    }

    function _applyByAmount(
        IOvenueJuniorPool.TrancheInfo storage tranche,
        uint256 interestRemaining,
        uint256 principalRemaining,
        uint256 desiredInterestAmount,
        uint256 desiredPrincipalAmount
    ) internal returns (uint256, uint256) {
        uint256 totalShares = tranche.principalDeposited;
        uint256 newSharePrice;

        (interestRemaining, newSharePrice) = _applyToSharePrice(
            interestRemaining,
            tranche.interestSharePrice,
            desiredInterestAmount,
            totalShares
        );
        tranche.interestSharePrice = newSharePrice;

        (principalRemaining, newSharePrice) = _applyToSharePrice(
            principalRemaining,
            tranche.principalSharePrice,
            desiredPrincipalAmount,
            totalShares
        );
        tranche.principalSharePrice = newSharePrice;
        return (interestRemaining, principalRemaining);
    }

    function _applyBySharePrice(
        IOvenueJuniorPool.TrancheInfo storage tranche,
        uint256 interestRemaining,
        uint256 principalRemaining,
        uint256 desiredInterestSharePrice,
        uint256 desiredPrincipalSharePrice
    ) internal returns (uint256, uint256) {
        uint256 desiredInterestAmount = _desiredAmountFromSharePrice(
            desiredInterestSharePrice,
            tranche.interestSharePrice,
            tranche.principalDeposited
        );
        uint256 desiredPrincipalAmount = _desiredAmountFromSharePrice(
            desiredPrincipalSharePrice,
            tranche.principalSharePrice,
            tranche.principalDeposited
        );
        return
            _applyByAmount(
                tranche,
                interestRemaining,
                principalRemaining,
                desiredInterestAmount,
                desiredPrincipalAmount
            );
    }

    // // Events /////////////////////////////////////////////////////////////////////

    // NOTE: this needs to match the event in TranchedPool
    event TrancheLocked(
        address indexed pool,
        uint256 trancheId,
        uint256 lockedUntil
    );

    event SharePriceUpdated(
        address indexed pool,
        uint256 indexed tranche,
        uint256 principalSharePrice,
        int256 principalDelta,
        uint256 interestSharePrice,
        int256 interestDelta
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import {IOvenueJuniorRewards} from "../interfaces/IOvenueJuniorRewards.sol";
import {IOvenueJuniorPool} from "../interfaces/IOvenueJuniorPool.sol";
import {IOvenueJuniorLP} from "../interfaces/IOvenueJuniorLP.sol";
import {IOvenueConfig} from "../interfaces/IOvenueConfig.sol";
import {IERC20withDec} from "../interfaces/IERC20withDec.sol";
import {OvenueTranchingLogic} from "./OvenueTranchingLogic.sol";
import {OvenueConfigHelper} from "./OvenueConfigHelper.sol";
import {IV2OvenueCreditLine} from "../interfaces/IV2OvenueCreditLine.sol";
import {IGo} from "../interfaces/IGo.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./Math.sol";


library OvenueJuniorPoolLogic {
    using OvenueTranchingLogic for IOvenueJuniorPool.PoolSlice;
    using OvenueTranchingLogic for IOvenueJuniorPool.TrancheInfo;
    using OvenueConfigHelper for IOvenueConfig;
    using SafeERC20Upgradeable for IERC20withDec;

    event ReserveFundsCollected(address indexed from, uint256 amount);

    event PaymentApplied(
        address indexed payer,
        address indexed pool,
        uint256 interestAmount,
        uint256 principalAmount,
        uint256 remainingAmount,
        uint256 reserveAmount
    );

    event DepositMade(
        address indexed owner,
        uint256 indexed tranche,
        uint256 indexed tokenId,
        uint256 amount
    );

    event WithdrawalMade(
        address indexed owner,
        uint256 indexed tranche,
        uint256 indexed tokenId,
        uint256 interestWithdrawn,
        uint256 principalWithdrawn
    );

    event SharePriceUpdated(
        address indexed pool,
        uint256 indexed tranche,
        uint256 principalSharePrice,
        int256 principalDelta,
        uint256 interestSharePrice,
        int256 interestDelta
    );

    event DrawdownMade(address indexed borrower, uint256 amount);
    event EmergencyShutdown(address indexed pool);
    event SliceCreated(address indexed pool, uint256 sliceId);

    function pay(
         mapping(uint256 => IOvenueJuniorPool.PoolSlice) storage _poolSlices,
        // IV2OvenueCreditLine creditLine,
        // IOvenueConfig config,
        // creditline - config
        address[2] calldata addresses,
        // numSlices - totalDeployed - juniorFeePercent - amount
        uint256[4] memory uints
    ) external returns(uint) {
        uint paymentAmount = uints[3];
        /// @dev  IA: cannot pay 0
        require(paymentAmount > 0, "IA");
        IOvenueConfig(addresses[1]).getUSDC().safeTransferFrom(msg.sender, addresses[0], paymentAmount);
        return assess(
            _poolSlices,
            addresses,
            [uints[0], uints[1], uints[2]]
        );
    }

    function deposit(
        IOvenueJuniorPool.TrancheInfo storage trancheInfo,
        IOvenueConfig config,
        uint256 amount
    ) external returns (uint256) {
        trancheInfo.principalDeposited =
            trancheInfo.principalDeposited +
            amount;

        uint256 tokenId = config.getJuniorLP().mint(
            IOvenueJuniorLP.MintParams({
                tranche: trancheInfo.id,
                principalAmount: amount
            }),
            msg.sender
        );

        config.getUSDC().safeTransferFrom(msg.sender, address(this), amount);
        emit DepositMade(msg.sender, trancheInfo.id, tokenId, amount);
        return tokenId;
    }

    function withdraw(
        mapping(uint256 => IOvenueJuniorPool.PoolSlice) storage _poolSlices,
        uint256 numSlices,
        uint256 tokenId,
        uint256 amount,
        IOvenueConfig config
    ) public returns (uint256, uint256) {
        IOvenueJuniorLP.TokenInfo memory tokenInfo = config
            .getJuniorLP()
            .getTokenInfo(tokenId);
        IOvenueJuniorPool.TrancheInfo storage trancheInfo = _getTrancheInfo(
            _poolSlices,
            numSlices,
            tokenInfo.tranche
        );

        /// @dev IA: invalid amount. Cannot withdraw 0
        require(amount > 0, "IA");
        (
            uint256 interestRedeemable,
            uint256 principalRedeemable
        ) = OvenueTranchingLogic.redeemableInterestAndPrincipal(
                trancheInfo,
                tokenInfo
            );
        uint256 netRedeemable = interestRedeemable + principalRedeemable;
        /// @dev IA: invalid amount. User does not have enough available to redeem
        require(amount <= netRedeemable, "IA");
        /// @dev TL: Tranched Locked
        require(block.timestamp > trancheInfo.lockedUntil, "TL");

        uint256 interestToRedeem = 0;
        uint256 principalToRedeem = 0;

        // If the tranche has not been locked, ensure the deposited amount is correct
        if (trancheInfo.lockedUntil == 0) {
            trancheInfo.principalDeposited =
                trancheInfo.principalDeposited -
                amount;

            principalToRedeem = amount;

            config.getJuniorLP().withdrawPrincipal(tokenId, principalToRedeem);
        } else {
            interestToRedeem = Math.min(interestRedeemable, amount);
            principalToRedeem = Math.min(
                principalRedeemable,
                amount - interestToRedeem
            );

            config.getJuniorLP().redeem(
                tokenId,
                principalToRedeem,
                interestToRedeem
            );
        }

        config.getUSDC().safeTransferFrom(
            address(this),
            msg.sender,
            principalToRedeem + interestToRedeem
        );

        emit WithdrawalMade(
            msg.sender,
            tokenInfo.tranche,
            tokenId,
            interestToRedeem,
            principalToRedeem
        );

        return (interestToRedeem, principalToRedeem);
    }

    function withdrawMax(
        mapping(uint256 => IOvenueJuniorPool.PoolSlice) storage _poolSlices,
        uint256 numSlices,
        uint256 tokenId,
        IOvenueConfig config
    ) external returns (uint256, uint256) {
        IOvenueJuniorLP.TokenInfo memory tokenInfo = config
            .getJuniorLP()
            .getTokenInfo(tokenId);
        IOvenueJuniorPool.TrancheInfo storage trancheInfo = _getTrancheInfo(
            _poolSlices,
            numSlices,
            tokenInfo.tranche
        );

        (
            uint256 interestRedeemable,
            uint256 principalRedeemable
        ) = OvenueTranchingLogic.redeemableInterestAndPrincipal(
                trancheInfo,
                tokenInfo
            );

        uint256 amount = interestRedeemable + principalRedeemable;

        return withdraw(_poolSlices, numSlices, tokenId, amount, config);
    }

    function drawdown(
        mapping(uint256 => IOvenueJuniorPool.PoolSlice) storage _poolSlices,
        IV2OvenueCreditLine creditLine,
        IOvenueConfig config,
        uint256 numSlices,
        uint256 amount,
        uint256 totalDeployed
    ) external returns (uint256) {
        if (!_locked(_poolSlices, numSlices)) {
            // Assumes the senior pool has invested already (saves the borrower a separate transaction to lock the pool)
            _lockPool(_poolSlices, creditLine, config, numSlices);
        }
        // Drawdown only draws down from the current slice for simplicity. It's harder to account for how much
        // money is available from previous slices since depositors can redeem after unlock.
        IOvenueJuniorPool.PoolSlice storage currentSlice = _poolSlices[
            numSlices - 1
        ];
        uint256 amountAvailable = OvenueTranchingLogic.sharePriceToUsdc(
            currentSlice.juniorTranche.principalSharePrice,
            currentSlice.juniorTranche.principalDeposited
        );
        amountAvailable =
            amountAvailable +
            (
                OvenueTranchingLogic.sharePriceToUsdc(
                    currentSlice.seniorTranche.principalSharePrice,
                    currentSlice.seniorTranche.principalDeposited
                )
            );

        // @dev IF: insufficient funds
        require(amount <= amountAvailable, "IF");

        creditLine.drawdown(amount);
        // Update the share price to reflect the amount remaining in the pool
        uint256 amountRemaining = amountAvailable - amount;
        uint256 oldJuniorPrincipalSharePrice = currentSlice
            .juniorTranche
            .principalSharePrice;
        uint256 oldSeniorPrincipalSharePrice = currentSlice
            .seniorTranche
            .principalSharePrice;
        currentSlice.juniorTranche.principalSharePrice = currentSlice
            .juniorTranche
            .calculateExpectedSharePrice(amountRemaining, currentSlice);
        currentSlice.seniorTranche.principalSharePrice = currentSlice
            .seniorTranche
            .calculateExpectedSharePrice(amountRemaining, currentSlice);
        currentSlice.principalDeployed =
            currentSlice.principalDeployed +
            amount;
        totalDeployed = totalDeployed + amount;

        address borrower = creditLine.borrower();

        // _calcJuniorRewards(config, numSlices);
        config.getUSDC().safeTransferFrom(address(this), borrower, amount);

        emit DrawdownMade(borrower, amount);
        emit SharePriceUpdated(
            address(this),
            currentSlice.juniorTranche.id,
            currentSlice.juniorTranche.principalSharePrice,
            int256(
                oldJuniorPrincipalSharePrice -
                    currentSlice.juniorTranche.principalSharePrice
            ) * -1,
            currentSlice.juniorTranche.interestSharePrice,
            0
        );
        emit SharePriceUpdated(
            address(this),
            currentSlice.seniorTranche.id,
            currentSlice.seniorTranche.principalSharePrice,
            int256(
                oldSeniorPrincipalSharePrice -
                    currentSlice.seniorTranche.principalSharePrice
            ) * -1,
            currentSlice.seniorTranche.interestSharePrice,
            0
        );

        return totalDeployed;
    }

    // function _calcJuniorRewards(IOvenueConfig config, uint256 numSlices)
    //     internal
    // {
    //     IOvenueJuniorRewards juniorRewards = IOvenueJuniorRewards(
    //         config.juniorRewardsAddress()
    //     );
    //     juniorRewards.onTranchedPoolDrawdown(numSlices - 1);
    // }

    function _lockPool(
        mapping(uint256 => IOvenueJuniorPool.PoolSlice) storage _poolSlices,
        IV2OvenueCreditLine creditLine,
        IOvenueConfig config,
        uint256 numSlices
    ) internal {
        IOvenueJuniorPool.PoolSlice storage slice = _poolSlices[numSlices - 1];
        /// @dev NL: Not locked
        require(slice.juniorTranche.lockedUntil > 0, "NL");
        // Allow locking the pool only once; do not allow extending the lock of an
        // already-locked pool. Otherwise the locker could keep the pool locked
        // indefinitely, preventing withdrawals.
        /// @dev TL: tranche locked. The senior pool has already been locked.
        require(slice.seniorTranche.lockedUntil == 0, "TL");

        uint256 currentTotal = slice.juniorTranche.principalDeposited +
            slice.seniorTranche.principalDeposited;
        creditLine.setLimit(
            Math.min(creditLine.limit() + currentTotal, creditLine.maxLimit())
        );

        // We start the drawdown period, so backers can withdraw unused capital after borrower draws down
        OvenueTranchingLogic.lockTranche(slice.juniorTranche, config);
        OvenueTranchingLogic.lockTranche(slice.seniorTranche, config);
    }

    function _locked(
        mapping(uint256 => IOvenueJuniorPool.PoolSlice) storage _poolSlices,
        uint256 numSlices
    ) internal view returns (bool) {
        return
            numSlices == 0 ||
            _poolSlices[numSlices - 1].seniorTranche.lockedUntil > 0;
    }

    // function locked(
    //     mapping(uint256 => IOvenueJuniorPool.PoolSlice) storage _poolSlices,
    //     uint256 numSlices
    // ) internal view returns (bool) {
    //     return _locked(_poolSlices, numSlices);
    // }

    function lockPool(
        mapping(uint256 => IOvenueJuniorPool.PoolSlice) storage _poolSlices,
        IV2OvenueCreditLine creditLine,
        IOvenueConfig config,
        uint256 numSlices
    ) external {
        _lockPool(_poolSlices, creditLine, config, numSlices);
    }

    function availableToWithdraw(
        mapping(uint256 => IOvenueJuniorPool.PoolSlice) storage _poolSlices,
        uint256 numSlices,
        IOvenueConfig config,
        uint256 tokenId
    ) external view returns (uint256, uint256) {
        IOvenueJuniorLP.TokenInfo memory tokenInfo = config
            .getJuniorLP()
            .getTokenInfo(tokenId);

        IOvenueJuniorPool.TrancheInfo
            storage trancheInfo = OvenueJuniorPoolLogic._getTrancheInfo(
                _poolSlices,
                numSlices,
                tokenInfo.tranche
            );

        if (block.timestamp > trancheInfo.lockedUntil) {
            return
                OvenueTranchingLogic.redeemableInterestAndPrincipal(
                    trancheInfo,
                    tokenInfo
                );
        } else {
            return (0, 0);
        }
    }

    function emergencyShutdown(
        IOvenueConfig config,
        IV2OvenueCreditLine creditLine
    ) external {
        IERC20withDec usdc = config.getUSDC();
        address reserveAddress = config.reserveAddress();
        // // Sweep any funds to community reserve
        uint256 poolBalance = usdc.balanceOf(address(this));
        if (poolBalance > 0) {
            config.getUSDC().safeTransfer(reserveAddress, poolBalance);
        }

        uint256 clBalance = usdc.balanceOf(address(creditLine));
        if (clBalance > 0) {
            usdc.safeTransferFrom(
                address(creditLine),
                reserveAddress,
                clBalance
            );
        }
        emit EmergencyShutdown(address(this));
    }

    function assess(
        mapping(uint256 => IOvenueJuniorPool.PoolSlice) storage _poolSlices,
        // creditline - config
        address[2] calldata addresses,
        // numSlices - totalDeployed - juniorFeePercent
        uint256[3] memory uints
    )
        public
        returns (
            // total deployed
            uint256
        )
    {
        require(_locked(_poolSlices, uints[0]), "NL");

        uint256 interestAccrued = IV2OvenueCreditLine(addresses[0])
            .totalInterestAccrued();
        (
            uint256 paymentRemaining,
            uint256 interestPayment,
            uint256 principalPayment
        ) = IV2OvenueCreditLine(addresses[0]).assess();
        interestAccrued =
            IV2OvenueCreditLine(addresses[0]).totalInterestAccrued() -
            interestAccrued;

        uint256[] memory principalPaymentsPerSlice = _calcInterest(
            _poolSlices,
            interestAccrued,
            principalPayment,
            uints[1],
            uints[0]
        );

        if (interestPayment > 0 || principalPayment > 0) {
            // uint256[] memory uintParams = new uint256[](5);
            uint256 reserveAmount = _applyToAllSlices(
                _poolSlices,
                [
                    uints[0],
                    interestPayment,
                    principalPayment + paymentRemaining,
                    uints[1],
                    uints[2]
                ],
                addresses
            );

            IOvenueConfig(addresses[1]).getUSDC().safeTransferFrom(
                addresses[0],
                address(this),
                principalPayment + paymentRemaining
            );
            IOvenueConfig(addresses[1]).getUSDC().safeTransferFrom(
                address(this),
                IOvenueConfig(addresses[1]).reserveAddress(),
                reserveAmount
            );

            emit ReserveFundsCollected(address(this), reserveAmount);

            // i < numSlices
            for (uint256 i = 0; i < uints[0]; i++) {
                _poolSlices[i].principalDeployed =
                    _poolSlices[i].principalDeployed -
                    principalPaymentsPerSlice[i];
                // totalDeployed = totalDeployed - principalPaymentsPerSlice[i];
                uints[1] = uints[1] - principalPaymentsPerSlice[i];
            }

            IOvenueConfig(addresses[1]).getJuniorRewards().allocateRewards(
                interestPayment
            );

            emit PaymentApplied(
                IV2OvenueCreditLine(addresses[0]).borrower(),
                address(this),
                interestPayment,
                principalPayment,
                paymentRemaining,
                reserveAmount
            );
        }

        // totaldeployed - uints[1]
        return uints[1];
    }

    function _applyToAllSlices(
        mapping(uint256 => IOvenueJuniorPool.PoolSlice) storage _poolSlices,
        // numSlices - interest - principal - totalDeployed  - JuniorFeePercent
        uint256[5] memory uints,
        // creditline - config
        address[2] calldata addresses
    )
        internal
        returns (
            // IV2OvenueCreditLine creditLine
            uint256
        )
    {
        return
            OvenueTranchingLogic.applyToAllSlices(
                _poolSlices,
                uints[0],
                uints[1],
                uints[2],
                uint256(100) / (IOvenueConfig(addresses[1]).getReserveDenominator()), // Convert the denonminator to percent
                uints[3],
                IV2OvenueCreditLine(addresses[0]),
                uints[4]
            );
    }

    function _calcInterest(
        mapping(uint256 => IOvenueJuniorPool.PoolSlice) storage _poolSlices,
        uint256 interestAccrued,
        uint256 principalPayment,
        uint256 totalDeployed,
        uint256 numSlices
    ) internal returns (uint256[] memory principalPaymentsPerSlice) {
        principalPaymentsPerSlice = new uint256[](numSlices);

        for (uint256 i = 0; i < numSlices; i++) {
            uint256 interestForSlice = OvenueTranchingLogic.scaleByFraction(
                interestAccrued,
                _poolSlices[i].principalDeployed,
                totalDeployed
            );
            principalPaymentsPerSlice[i] = OvenueTranchingLogic.scaleByFraction(
                principalPayment,
                _poolSlices[i].principalDeployed,
                totalDeployed
            );
            _poolSlices[i].totalInterestAccrued =
                _poolSlices[i].totalInterestAccrued +
                interestForSlice;
        }
    }

    function _getTrancheInfo(
        mapping(uint256 => IOvenueJuniorPool.PoolSlice) storage _poolSlices,
        uint256 numSlices,
        uint256 trancheId
    ) internal view returns (IOvenueJuniorPool.TrancheInfo storage) {
        require(
            trancheId > 0 &&
                trancheId <= numSlices * OvenueTranchingLogic.NUM_TRANCHES_PER_SLICE,
            "invalid tranche"
        );
        uint256 sliceId = OvenueTranchingLogic.trancheIdToSliceIndex(trancheId);
        IOvenueJuniorPool.PoolSlice storage slice = _poolSlices[sliceId];
        IOvenueJuniorPool.TrancheInfo storage trancheInfo = OvenueTranchingLogic
            .isSeniorTrancheId(trancheId)
            ? slice.seniorTranche
            : slice.juniorTranche;
        return trancheInfo;
    }

    function getTrancheInfo(
        mapping(uint256 => IOvenueJuniorPool.PoolSlice) storage _poolSlices,
        uint256 numSlices,
        uint256 trancheId
    ) external view returns (IOvenueJuniorPool.TrancheInfo storage) {
        return _getTrancheInfo(_poolSlices, numSlices, trancheId);
    }

    function initializeNextSlice(
        mapping(uint256 => IOvenueJuniorPool.PoolSlice) storage _poolSlices,
        uint256 numSlices
    ) public returns (uint256) {
        /// @dev SL: slice limit
        require(numSlices < 2, "SL");
        // OvenueTranchingLogic.initializeNextSlice(_poolSlices, numSlices);
        // numSlices = numSlices + 1;

        return numSlices;
    }

    function initializeAnotherNextSlice(
        mapping(uint256 => IOvenueJuniorPool.PoolSlice) storage _poolSlices,
        IV2OvenueCreditLine creditLine,
        uint256 numSlices
    ) external returns (uint256) {
        /// @dev NL: not locked
        require(_locked(_poolSlices, numSlices), "NL");
        /// @dev LP: late payment
        require(!creditLine.isLate(), "LP");
        /// @dev GP: beyond principal grace period
        require(creditLine.withinPrincipalGracePeriod(), "GP");
        emit SliceCreated(address(this), numSlices - 1);
        return initializeNextSlice(_poolSlices, numSlices);
    }

    function initialize(
        mapping(uint256 => IOvenueJuniorPool.PoolSlice) storage _poolSlices,
        uint256 numSlices,
        IOvenueConfig config,
        address _borrower,
        // junior fee percent - late fee apr, interest apr
        uint256[3] calldata _fees,
        // _paymentPeriodInDays - _termInDays - _principalGracePeriodInDays - _fundableAt
        uint256[4] calldata _days,
        uint256 _limit
    )
        external
        returns (
            uint256,
            IV2OvenueCreditLine
        )
    {
        uint256 adjustedNumSlices = initializeNextSlice(
            _poolSlices,
            numSlices
        );

        IV2OvenueCreditLine creditLine = creditLineInitialize(
            config,
            _borrower,
            _fees,
            _days,
            _limit
        );

        return (adjustedNumSlices, creditLine);
    }

    function creditLineInitialize(
        IOvenueConfig config,
        address _borrower,
        // junior fee percent - late fee apr, interest apr
        uint256[3] calldata _fees,
        // _paymentPeriodInDays - _termInDays - _principalGracePeriodInDays - _fundableAt
        uint256[4] calldata _days,
        uint256 _maxLimit
    ) internal returns (IV2OvenueCreditLine) {
        IV2OvenueCreditLine creditLine = IV2OvenueCreditLine(
            config.getOvenueFactory().createCreditLine()
        );

        creditLine.initialize(
            address(config),
            address(this), // Set self as the owner
            _borrower,
            _maxLimit,
            _fees[2],
            _days[0],
            _days[1],
            _fees[1],
            _days[2]
        );

        return creditLine;
    }

    function lockJuniorCapital(
        mapping(uint256 => IOvenueJuniorPool.PoolSlice) storage _poolSlices,
        uint256 numSlices,
        IOvenueConfig config,
        uint256 sliceId
    ) external {
        /// @dev TL: tranch locked
        require(
            !_locked(_poolSlices, numSlices) &&
                _poolSlices[sliceId].juniorTranche.lockedUntil == 0,
            "TL"
        );

        OvenueTranchingLogic.lockTranche(_poolSlices[sliceId].juniorTranche, config);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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
    CollateralLockedUpInSeconds // 10
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
    CollateralCustody // 16
    // StakingRewards
    // FiduUSDCCurveLP
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "./IOvenueJuniorPool.sol";

interface IOvenueCollateralCustody {
    function isCollateralFullyFunded(IOvenueJuniorPool _poolAddr) external virtual returns(bool);
    function createCollateralStats(
        IOvenueJuniorPool _poolAddr,
        address _nftAddr,
        uint256 _tokenId,
        uint256 _fungibleAmount
    ) external virtual;
    
    function collectFungibleCollateral(
        IOvenueJuniorPool _poolAddr,
        address _depositor,
        uint256 _amount
    ) external virtual;

    function redeemAllCollateral(
        IOvenueJuniorPool _poolAddr,
        address receiver
    ) external virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "./IERC20withDec.sol";

interface IOvenueSeniorLP is IERC20withDec {
  function mintTo(address to, uint256 amount) external;

  function burnFrom(address to, uint256 amount) external;

  function renounceRole(bytes32 role, address account) external;
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

interface IOvenueJuniorRewards {
  function allocateRewards(uint256 _interestPaymentAmount) external;

  // function onTranchedPoolDrawdown(uint256 sliceIndex) external;

  function setPoolTokenAccRewardsPerPrincipalDollarAtMint(address poolAddress, uint256 tokenId) external;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
                /// @solidity memory-safe-assembly
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.5;

/**
 * @title WadRayMath library
 * @author Aave
 * @notice Provides functions to perform calculations with Wad and Ray units
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits of precision) and rays (decimal numbers
 * with 27 digits of precision)
 * @dev Operations are rounded. If a value is >=.5, will be rounded up, otherwise rounded down.
 **/
library WadRayMath {
  // HALF_WAD and HALF_RAY expressed with extended notation as constant with operations are not supported in Yul assembly
  uint256 internal constant WAD = 1e18;
  uint256 internal constant HALF_WAD = 0.5e18;

  uint256 internal constant RAY = 1e27;
  uint256 internal constant HALF_RAY = 0.5e27;

  uint256 internal constant WAD_RAY_RATIO = 1e9;

  /**
   * @dev Multiplies two wad, rounding half up to the nearest wad
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Wad
   * @param b Wad
   * @return c = a*b, in wad
   **/
  function wadMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // to avoid overflow, a <= (type(uint256).max - HALF_WAD) / b
    assembly {
      if iszero(or(iszero(b), iszero(gt(a, div(sub(not(0), HALF_WAD), b))))) {
        revert(0, 0)
      }

      c := div(add(mul(a, b), HALF_WAD), WAD)
    }
  }

  /**
   * @dev Divides two wad, rounding half up to the nearest wad
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Wad
   * @param b Wad
   * @return c = a/b, in wad
   **/
  function wadDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // to avoid overflow, a <= (type(uint256).max - halfB) / WAD
    assembly {
      if or(iszero(b), iszero(iszero(gt(a, div(sub(not(0), div(b, 2)), WAD))))) {
        revert(0, 0)
      }

      c := div(add(mul(a, WAD), div(b, 2)), b)
    }
  }

  /**
   * @notice Multiplies two ray, rounding half up to the nearest ray
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Ray
   * @param b Ray
   * @return c = a raymul b
   **/
  function rayMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // to avoid overflow, a <= (type(uint256).max - HALF_RAY) / b
    assembly {
      if iszero(or(iszero(b), iszero(gt(a, div(sub(not(0), HALF_RAY), b))))) {
        revert(0, 0)
      }

      c := div(add(mul(a, b), HALF_RAY), RAY)
    }
  }

  /**
   * @notice Divides two ray, rounding half up to the nearest ray
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Ray
   * @param b Ray
   * @return c = a raydiv b
   **/
  function rayDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // to avoid overflow, a <= (type(uint256).max - halfB) / RAY
    assembly {
      if or(iszero(b), iszero(iszero(gt(a, div(sub(not(0), div(b, 2)), RAY))))) {
        revert(0, 0)
      }

      c := div(add(mul(a, RAY), div(b, 2)), b)
    }
  }

  /**
   * @dev Casts ray down to wad
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Ray
   * @return b = a converted to wad, rounded half up to the nearest wad
   **/
  function rayToWad(uint256 a) internal pure returns (uint256 b) {
    assembly {
      b := div(a, WAD_RAY_RATIO)
      let remainder := mod(a, WAD_RAY_RATIO)
      if iszero(lt(remainder, div(WAD_RAY_RATIO, 2))) {
        b := add(b, 1)
      }
    }
  }

  /**
   * @dev Converts wad up to ray
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Wad
   * @return b = a converted in ray
   **/
  function wadToRay(uint256 a) internal pure returns (uint256 b) {
    // to avoid overflow, b/WAD_RAY_RATIO == a
    assembly {
      b := mul(a, WAD_RAY_RATIO)

      if iszero(eq(div(b, WAD_RAY_RATIO), a)) {
        revert(0, 0)
      }
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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