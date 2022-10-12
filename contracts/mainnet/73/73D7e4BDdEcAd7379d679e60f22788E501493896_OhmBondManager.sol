// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.15;

import {IBondSDA} from "../interfaces/IBondSDA.sol";
import {IBondTeller} from "../interfaces/IBondTeller.sol";
import {IEasyAuction} from "../interfaces/IEasyAuction.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {ITreasury} from "../interfaces/ITreasury.sol";
import {IOlympusAuthority} from "../interfaces/IOlympusAuthority.sol";
import {OlympusAccessControlled} from "../types/OlympusAccessControlled.sol";

contract OhmBondManager is OlympusAccessControlled {
    // ========= DATA STRUCTURES ========= //
    struct BondProtocolParameters {
        uint256 initialPrice;
        uint256 minPrice;
        uint32 debtBuffer;
        uint256 auctionTime;
        uint32 depositInterval;
    }

    struct GnosisAuctionParameters {
        uint256 auctionCancelTime;
        uint256 auctionTime;
        uint96 minRatioSold;
        uint256 minBuyAmount;
        uint256 minFundingThreshold;
    }

    // ========= STATE VARIABLES ========= //

    /// Tokens
    IERC20 public ohm;

    /// Contract Dependencies
    ITreasury public treasury;

    /// Market Creation Systems
    IBondSDA public fixedExpiryAuctioneer;
    IBondTeller public fixedExpiryTeller;
    IEasyAuction public gnosisEasyAuction;

    /// Market parameters
    BondProtocolParameters public bondProtocolParameters;
    GnosisAuctionParameters public gnosisAuctionParameters;

    constructor(
        address ohm_,
        address treasury_,
        address feAuctioneer_,
        address feTeller_,
        address gnosisAuction_,
        address authority_
    ) OlympusAccessControlled(IOlympusAuthority(authority_)) {
        ohm = IERC20(ohm_);
        treasury = ITreasury(treasury_);
        fixedExpiryAuctioneer = IBondSDA(feAuctioneer_);
        fixedExpiryTeller = IBondTeller(feTeller_);
        gnosisEasyAuction = IEasyAuction(gnosisAuction_);
    }

    // ========= MARKET CREATION ========= //
    function createBondProtocolMarket(uint256 capacity_, uint256 bondTerm_) external onlyPolicy returns (uint256) {
        _topUpOhm(capacity_);

        /// Encodes the information needed for creating a bond market on Bond Protocol
        bytes memory createMarketParams = abi.encode(
            ohm, // payoutToken
            ohm, // quoteToken
            address(0), // callbackAddress
            false, // capacityInQuote
            capacity_, // capacity
            bondProtocolParameters.initialPrice, // formattedInitialPrice
            bondProtocolParameters.minPrice, // formattedMinimumPrice
            bondProtocolParameters.debtBuffer, // debtBuffer
            uint48(block.timestamp + bondTerm_), // vesting
            uint48(block.timestamp + bondProtocolParameters.auctionTime), // conclusion
            bondProtocolParameters.depositInterval, // depositInterval
            int8(0) // scaleAdjustment
        );

        ohm.approve(address(fixedExpiryTeller), capacity_);
        uint256 marketId = fixedExpiryAuctioneer.createMarket(createMarketParams);

        return marketId;
    }

    function createGnosisAuction(uint96 capacity_, uint256 bondTerm_) external onlyPolicy returns (uint256) {
        _topUpOhm(capacity_);

        uint48 expiry = uint48(block.timestamp + bondTerm_);

        /// Create bond token
        ohm.approve(address(fixedExpiryTeller), capacity_);
        fixedExpiryTeller.deploy(ohm, expiry);
        (IERC20 bondToken, ) = fixedExpiryTeller.create(ohm, expiry, capacity_);

        /// Launch Gnosis Auction
        bondToken.approve(address(gnosisEasyAuction), capacity_);
        uint256 auctionId = gnosisEasyAuction.initiateAuction(
            bondToken, // auctioningToken
            ohm, // biddingToken
            block.timestamp + gnosisAuctionParameters.auctionCancelTime, // last order cancellation time
            block.timestamp + gnosisAuctionParameters.auctionTime, // auction end time
            capacity_, // auctioned amount
            capacity_ / gnosisAuctionParameters.minRatioSold, // minimum tokens bought for auction to be valid
            gnosisAuctionParameters.minBuyAmount, // minimum purchase size of auctioning token
            gnosisAuctionParameters.minFundingThreshold, // minimum funding threshold
            false, // is atomic closure allowed
            address(0), // access manager contract
            new bytes(0) // access manager contract data
        );

        return auctionId;
    }

    // ========= PARAMETER ADJUSTMENT ========= //
    function setBondProtocolParameters(
        uint256 initialPrice_,
        uint256 minPrice_,
        uint32 debtBuffer_,
        uint256 auctionTime_,
        uint32 depositInterval_
    ) external onlyPolicy {
        bondProtocolParameters = BondProtocolParameters({
            initialPrice: initialPrice_,
            minPrice: minPrice_,
            debtBuffer: debtBuffer_,
            auctionTime: auctionTime_,
            depositInterval: depositInterval_
        });
    }

    function setGnosisAuctionParameters(
        uint256 auctionCancelTime_,
        uint256 auctionTime_,
        uint96 minRatioSold_,
        uint256 minBuyAmount_,
        uint256 minFundingThreshold_
    ) external onlyPolicy {
        gnosisAuctionParameters = GnosisAuctionParameters({
            auctionCancelTime: auctionCancelTime_,
            auctionTime: auctionTime_,
            minRatioSold: minRatioSold_,
            minBuyAmount: minBuyAmount_,
            minFundingThreshold: minFundingThreshold_
        });
    }

    // ========= INTERNAL FUNCTIONS ========= //
    function _topUpOhm(uint256 amountToDeploy_) internal {
        uint256 ohmBalance = ohm.balanceOf(address(this));

        if (amountToDeploy_ > ohmBalance) {
            uint256 amountToMint = amountToDeploy_ - ohmBalance;
            treasury.mint(address(this), amountToMint);
        }
    }

    // ========= EMERGENCY FUNCTIONS ========= //
    function emergencyWithdraw(uint256 amount) external onlyPolicy {
        ohm.transfer(address(treasury), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.15;

import {IERC20} from "./IERC20.sol";

interface IBondSDA {
    /// @notice                 Creates a new bond market
    /// @param params_          Configuration data needed for market creation
    /// @return id              ID of new bond market
    function createMarket(bytes calldata params_) external returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.15;

import {IERC20} from "./IERC20.sol";

interface IBondTeller {
    /// @notice             Instantiates a new fixed expiry bond token
    /// @param payoutToken  Token received upon bonding
    /// @param expiration   Expiry timestamp for the bond
    function deploy(IERC20 payoutToken, uint48 expiration) external;

    /// @notice             Mint bond tokens for a specific expiry
    /// @param expiration   Expiry timestamp for the bond
    /// @param capacity     Amount of bond tokens to mint
    function create(
        IERC20 payoutToken,
        uint48 expiration,
        uint256 capacity
    ) external returns (IERC20, uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.15;

import {IERC20} from "./IERC20.sol";

interface IEasyAuction {
    /// @notice                         Initiates an auction through Gnosis Auctions
    /// @param tokenToSell              The token being sold
    /// @param biddingToken             The token used to bid on the sale token and set its price
    /// @param lastCancellation         The last timestamp a user can cancel their bid at
    /// @param auctionEnd               The timestamp the auction ends at
    /// @param auctionAmount            The number of sale tokens to sell
    /// @param minimumTotalPurchased    The minimum number of sale tokens that need to be sold for the auction to finalize
    /// @param minimumPurchaseAmount    The minimum purchase size in bidding tokens
    /// @param minFundingThreshold      The minimal funding thresholding for finalizing settlement
    /// @param isAtomicClosureAllowed   Can users call settleAuctionAtomically when end date has been reached
    /// @param accessManager            The contract to manage an allowlist
    /// @param accessManagerData        The data for managing an allowlist
    function initiateAuction(
        IERC20 tokenToSell,
        IERC20 biddingToken,
        uint256 lastCancellation,
        uint256 auctionEnd,
        uint96 auctionAmount,
        uint96 minimumTotalPurchased,
        uint256 minimumPurchaseAmount,
        uint256 minFundingThreshold,
        bool isAtomicClosureAllowed,
        address accessManager,
        bytes calldata accessManagerData
    ) external returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface ITreasury {
    function deposit(
        uint256 _amount,
        address _token,
        uint256 _profit
    ) external returns (uint256);

    function withdraw(uint256 _amount, address _token) external;

    function tokenValue(address _token, uint256 _amount) external view returns (uint256 value_);

    function mint(address _recipient, uint256 _amount) external;

    function manage(address _token, uint256 _amount) external;

    function incurDebt(uint256 amount_, address token_) external;

    function repayDebtWithReserve(uint256 amount_, address token_) external;

    function excessReserves() external view returns (uint256);

    function baseSupply() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IOlympusAuthority {
    /* ========== EVENTS ========== */

    event GovernorPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event GuardianPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event PolicyPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event VaultPushed(address indexed from, address indexed to, bool _effectiveImmediately);

    event GovernorPulled(address indexed from, address indexed to);
    event GuardianPulled(address indexed from, address indexed to);
    event PolicyPulled(address indexed from, address indexed to);
    event VaultPulled(address indexed from, address indexed to);

    /* ========== VIEW ========== */

    function governor() external view returns (address);

    function guardian() external view returns (address);

    function policy() external view returns (address);

    function vault() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

import "../interfaces/IOlympusAuthority.sol";

abstract contract OlympusAccessControlled {
    /* ========== EVENTS ========== */

    event AuthorityUpdated(IOlympusAuthority indexed authority);

    string UNAUTHORIZED = "UNAUTHORIZED"; // save gas

    /* ========== STATE VARIABLES ========== */

    IOlympusAuthority public authority;

    /* ========== Constructor ========== */

    constructor(IOlympusAuthority _authority) {
        authority = _authority;
        emit AuthorityUpdated(_authority);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyGovernor() {
        require(msg.sender == authority.governor(), UNAUTHORIZED);
        _;
    }

    modifier onlyGuardian() {
        require(msg.sender == authority.guardian(), UNAUTHORIZED);
        _;
    }

    modifier onlyPolicy() {
        require(msg.sender == authority.policy(), UNAUTHORIZED);
        _;
    }

    modifier onlyVault() {
        require(msg.sender == authority.vault(), UNAUTHORIZED);
        _;
    }

    /* ========== GOV ONLY ========== */

    function setAuthority(IOlympusAuthority _newAuthority) external onlyGovernor {
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }
}