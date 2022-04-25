// Be name Khoda
// Bime Abolfazl
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.13;
pragma abicoder v2;

// =================================================================================================================
//  _|_|_|    _|_|_|_|  _|    _|    _|_|_|      _|_|_|_|  _|                                                       |
//  _|    _|  _|        _|    _|  _|            _|            _|_|_|      _|_|_|  _|_|_|      _|_|_|    _|_|       |
//  _|    _|  _|_|_|    _|    _|    _|_|        _|_|_|    _|  _|    _|  _|    _|  _|    _|  _|        _|_|_|_|     |
//  _|    _|  _|        _|    _|        _|      _|        _|  _|    _|  _|    _|  _|    _|  _|        _|           |
//  _|_|_|    _|_|_|_|    _|_|    _|_|_|        _|        _|  _|    _|    _|_|_|  _|    _|    _|_|_|    _|_|_|     |
// =================================================================================================================
// ============================= DEIPool =============================
// ===================================================================
// DEUS Finance: https://github.com/DeusFinance

// Primary Author(s)
// Vahid: https://github.com/vahid-dev

import "@openzeppelin/contracts/access/AccessControl.sol";
import "../Uniswap/TransferHelper.sol";
import "./interfaces/IPoolLibrary.sol";
import "./interfaces/IPoolV2.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IDEUS.sol";
import "./interfaces/IDEI.sol";

/// @title Minter Pool Contract V2
/// @author DEUS Finance
/// @notice Minter pool of DEI stablecoin
/// @dev Uses twap and vwap for DEUS price in DEI redemption by using muon oracles
///      Usable for stablecoins as collateral
contract DEIPool is IDEIPool, AccessControl {
    /* ========== STATE VARIABLES ========== */
    address public collateral;
    address private dei;
    address private deus;

    uint256 public mintingFee;
    uint256 public redemptionFee = 10000;
    uint256 public buybackFee = 5000;
    uint256 public recollatFee = 5000;

    mapping(address => uint256) public redeemCollateralBalances;
    uint256 public unclaimedPoolCollateral;
    mapping(address => uint256) public lastCollateralRedeemed;

    // position data
    mapping(address => IDEIPool.RedeemPosition[]) public redeemPositions;
    mapping(address => uint256) public nextRedeemId;

    uint256 public collateralRedemptionDelay;
    uint256 public deusRedemptionDelay;

    // Constants for various precisions
    uint256 private constant PRICE_PRECISION = 1e6;
    uint256 private constant COLLATERAL_RATIO_PRECISION = 1e6;
    uint256 private constant COLLATERAL_RATIO_MAX = 1e6;
    uint256 private constant COLLATERAL_PRICE = 1e6;
    uint256 private constant SCALE = 1e6;

    // Number of decimals needed to get to 18
    uint256 private immutable missingDecimals;

    // Pool_ceiling is the total units of collateral that a pool contract can hold
    uint256 public poolCeiling;

    // Bonus rate on DEUS minted during RecollateralizeDei(); 6 decimals of precision, set to 0.75% on genesis
    uint256 public bonusRate = 7500;

    uint256 public daoShare = 0; // fees goes to daoWallet

    address public poolLibrary; // Pool library contract

    address public muon;
    uint32 public appId;
    uint256 minimumRequiredSignatures;

    // AccessControl Roles
    bytes32 public constant PARAMETER_SETTER_ROLE =
        keccak256("PARAMETER_SETTER_ROLE");
    bytes32 public constant DAO_SHARE_COLLECTOR =
        keccak256("DAO_SHARE_COLLECTOR");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant TRUSTY_ROLE = keccak256("TRUSTY_ROLE");

    // AccessControl state variables
    bool public mintPaused = false;
    bool public redeemPaused = false;
    bool public recollateralizePaused = false;
    bool public buyBackPaused = false;

    /* ========== MODIFIERS ========== */
    modifier notRedeemPaused() {
        require(redeemPaused == false, "DEIPool: REDEEM_PAUSED");
        _;
    }

    modifier notMintPaused() {
        require(mintPaused == false, "DEIPool: MINTING_PAUSED");
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address dei_,
        address deus_,
        address collateral_,
        address muon_,
        address library_,
        address admin,
        uint256 minimumRequiredSignatures_,
        uint256 collateralRedemptionDelay_,
        uint256 deusRedemptionDelay_,
        uint256 poolCeiling_,
        uint32 appId_
    ) {
        require(
            (dei_ != address(0)) &&
                (deus_ != address(0)) &&
                (collateral_ != address(0)) &&
                (library_ != address(0)) &&
                (admin != address(0)),
            "DEIPool: ZERO_ADDRESS_DETECTED"
        );
        dei = dei_;
        deus = deus_;
        collateral = collateral_;
        muon = muon_;
        appId = appId_;
        minimumRequiredSignatures = minimumRequiredSignatures_;
        collateralRedemptionDelay = collateralRedemptionDelay_;
        deusRedemptionDelay = deusRedemptionDelay_;
        poolCeiling = poolCeiling_;
        poolLibrary = library_;
        missingDecimals = uint256(18) - IERC20(collateral).decimals();

        _setupRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /* ========== VIEWS ========== */

    // Returns dollar value of collateral held in this DEI pool
    function collatDollarBalance(uint256 collateralPrice)
        public
        view
        returns (uint256 balance)
    {
        balance =
            ((IERC20(collateral).balanceOf(address(this)) -
                unclaimedPoolCollateral) *
                (10**missingDecimals) *
                collateralPrice) /
            (PRICE_PRECISION);
    }

    // Returns the value of excess collateral held in this DEI pool, compared to what is needed to maintain the global collateral ratio
    function availableExcessCollatDV(uint256[] memory collateralPrice)
        public
        view
        returns (uint256)
    {
        uint256 totalSupply = IDEI(dei).totalSupply();
        uint256 globalCollateralRatio = IDEI(dei).global_collateral_ratio();
        uint256 globalCollateralValue = IDEI(dei).globalCollateralValue(
            collateralPrice
        );

        if (globalCollateralRatio > COLLATERAL_RATIO_PRECISION)
            globalCollateralRatio = COLLATERAL_RATIO_PRECISION; // Handles an overcollateralized contract with CR > 1
        uint256 requiredCollateralDollarValued18 = (totalSupply *
            globalCollateralRatio) / (COLLATERAL_RATIO_PRECISION); // Calculates collateral needed to back each 1 DEI with $1 of collateral at current collat ratio
        if (globalCollateralValue > requiredCollateralDollarValued18)
            return globalCollateralValue - requiredCollateralDollarValued18;
        else return 0;
    }

    function positionsLength(address user)
        external
        view
        returns (uint256 length)
    {
        length = redeemPositions[user].length;
    }

    function getAllPositions(address user)
        external
        view
        returns (RedeemPosition[] memory positions)
    {
        positions = redeemPositions[user];
    }

    function getUnRedeemedPositions(address user)
        external
        view
        returns (RedeemPosition[] memory)
    {
        uint256 totalRedeemPositions = redeemPositions[user].length;
        uint256 redeemId = nextRedeemId[user];

        RedeemPosition[] memory positions = new RedeemPosition[](
            totalRedeemPositions - redeemId + 1
        );
        uint256 index = 0;
        for (uint256 i = redeemId; i < totalRedeemPositions; i++) {
            positions[index] = redeemPositions[user][i];
            index++;
        }

        return positions;
    }

    function _getChainId() internal view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    // We separate out the 1t1, fractional and algorithmic minting functions for gas efficiency
    function mint1t1DEI(uint256 collateralAmount)
        external
        notMintPaused
        returns (uint256 deiAmount)
    {
        require(
            IDEI(dei).global_collateral_ratio() >= COLLATERAL_RATIO_MAX,
            "DEIPool: INVALID_COLLATERAL_RATIO"
        );
        require(
            IERC20(collateral).balanceOf(address(this)) -
                unclaimedPoolCollateral +
                collateralAmount <=
                poolCeiling,
            "DEIPool: CEILING_REACHED"
        );

        uint256 collateralAmountD18 = collateralAmount * (10**missingDecimals);
        deiAmount = IPoolLibrary(poolLibrary).calcMint1t1DEI(
            COLLATERAL_PRICE,
            collateralAmountD18
        ); //1 DEI for each $1 worth of collateral

        deiAmount = (deiAmount * (SCALE - mintingFee)) / SCALE; //remove precision at the end

        TransferHelper.safeTransferFrom(
            collateral,
            msg.sender,
            address(this),
            collateralAmount
        );

        daoShare += (deiAmount * mintingFee) / SCALE;
        IDEI(dei).pool_mint(msg.sender, deiAmount);
    }

    // 0% collateral-backed
    function mintAlgorithmicDEI(
        uint256 deusAmount,
        uint256 deusPrice,
        uint256 expireBlock,
        bytes[] calldata sigs
    ) external notMintPaused returns (uint256 deiAmount) {
        require(
            IDEI(dei).global_collateral_ratio() == 0,
            "DEIPool: INVALID_COLLATERAL_RATIO"
        );
        require(expireBlock >= block.number, "DEIPool: EXPIRED_SIGNATURE");
        bytes32 sighash = keccak256(
            abi.encodePacked(deus, deusPrice, expireBlock, _getChainId())
        );
        require(
            IDEI(dei).verify_price(sighash, sigs),
            "DEIPool: UNVERIFIED_SIGNATURE"
        );

        deiAmount = IPoolLibrary(poolLibrary).calcMintAlgorithmicDEI(
            deusPrice, // X DEUS / 1 USD
            deusAmount
        );

        deiAmount = (deiAmount * (SCALE - (mintingFee))) / SCALE;
        daoShare += (deiAmount * mintingFee) / SCALE;

        IDEUS(deus).pool_burn_from(msg.sender, deusAmount);
        IDEI(dei).pool_mint(msg.sender, deiAmount);
    }

    // Will fail if fully collateralized or fully algorithmic
    // > 0% and < 100% collateral-backed
    function mintFractionalDEI(
        uint256 collateralAmount,
        uint256 deusAmount,
        uint256 deusPrice,
        uint256 expireBlock,
        bytes[] calldata sigs
    ) external notMintPaused returns (uint256 mintAmount) {
        uint256 globalCollateralRatio = IDEI(dei).global_collateral_ratio();
        require(
            globalCollateralRatio < COLLATERAL_RATIO_MAX &&
                globalCollateralRatio > 0,
            "DEIPool: INVALID_COLLATERAL_RATIO"
        );
        require(
            IERC20(collateral).balanceOf(address(this)) -
                unclaimedPoolCollateral +
                collateralAmount <=
                poolCeiling,
            "DEIPool: CEILING_REACHED"
        );

        require(expireBlock >= block.number, "DEIPool: EXPIRED_SIGNATURE");
        bytes32 sighash = keccak256(
            abi.encodePacked(deus, deusPrice, expireBlock, _getChainId())
        );
        require(
            IDEI(dei).verify_price(sighash, sigs),
            "DEIPool: UNVERIFIED_SIGNATURE"
        );

        IPoolLibrary.MintFractionalDeiParams memory inputParams;

        // Blocking is just for solving stack depth problem
        {
            uint256 collateralAmountD18 = collateralAmount *
                (10**missingDecimals);
            inputParams = IPoolLibrary.MintFractionalDeiParams(
                deusPrice,
                COLLATERAL_PRICE,
                collateralAmountD18,
                globalCollateralRatio
            );
        }

        uint256 deusNeeded;
        (mintAmount, deusNeeded) = IPoolLibrary(poolLibrary)
            .calcMintFractionalDEI(inputParams);
        require(deusNeeded <= deusAmount, "INSUFFICIENT_DEUS_INPUTTED");

        mintAmount = (mintAmount * (SCALE - mintingFee)) / SCALE;

        IDEUS(deus).pool_burn_from(msg.sender, deusNeeded);

        TransferHelper.safeTransferFrom(
            collateral,
            msg.sender,
            address(this),
            collateralAmount
        );

        daoShare += (mintAmount * mintingFee) / SCALE;
        IDEI(dei).pool_mint(msg.sender, mintAmount);
    }

    // Redeem collateral. 100% collateral-backed
    function redeem1t1DEI(uint256 deiAmount) external notRedeemPaused {
        require(
            IDEI(dei).global_collateral_ratio() == COLLATERAL_RATIO_MAX,
            "DEIPool: INVALID_COLLATERAL_RATIO"
        );

        // Need to adjust for decimals of collateral
        uint256 deiAmountPrecision = deiAmount / (10**missingDecimals);
        uint256 collateralNeeded = IPoolLibrary(poolLibrary).calcRedeem1t1DEI(
            COLLATERAL_PRICE,
            deiAmountPrecision
        );

        collateralNeeded = (collateralNeeded * (SCALE - redemptionFee)) / SCALE;
        require(
            collateralNeeded <=
                IERC20(collateral).balanceOf(address(this)) -
                    unclaimedPoolCollateral,
            "DEIPool: INSUFFICIENT_COLLATERAL_BALANCE"
        );

        redeemCollateralBalances[msg.sender] =
            redeemCollateralBalances[msg.sender] +
            collateralNeeded;
        unclaimedPoolCollateral = unclaimedPoolCollateral + collateralNeeded;
        lastCollateralRedeemed[msg.sender] = block.number;

        daoShare += (deiAmount * redemptionFee) / SCALE;
        // Move all external functions to the end
        IDEI(dei).pool_burn_from(msg.sender, deiAmount);
    }

    // Will fail if fully collateralized or algorithmic
    // Redeem DEI for collateral and DEUS. > 0% and < 100% collateral-backed
    function redeemFractionalDEI(uint256 deiAmount) external notRedeemPaused {
        uint256 globalCollateralRatio = IDEI(dei).global_collateral_ratio();
        require(
            globalCollateralRatio < COLLATERAL_RATIO_MAX &&
                globalCollateralRatio > 0,
            "DEIPool: INVALID_COLLATERAL_RATIO"
        );

        // Blocking is just for solving stack depth problem
        uint256 collateralAmount;
        {
            uint256 deiAmountPostFee = (deiAmount * (SCALE - redemptionFee)) /
                (PRICE_PRECISION);
            uint256 deiAmountPrecision = deiAmountPostFee /
                (10**missingDecimals);
            collateralAmount =
                (deiAmountPrecision * globalCollateralRatio) /
                PRICE_PRECISION;
        }
        require(
            collateralAmount <=
                IERC20(collateral).balanceOf(address(this)) -
                    unclaimedPoolCollateral,
            "DEIPool: NOT_ENOUGH_COLLATERAL"
        );

        redeemCollateralBalances[msg.sender] += collateralAmount;
        lastCollateralRedeemed[msg.sender] = block.timestamp;
        unclaimedPoolCollateral = unclaimedPoolCollateral + collateralAmount;

        {
            uint256 deiAmountPostFee = (deiAmount * (SCALE - redemptionFee)) /
                SCALE;
            uint256 deusDollarAmount = (deiAmountPostFee *
                (SCALE - globalCollateralRatio)) / SCALE;

            redeemPositions[msg.sender].push(
                RedeemPosition({
                    amount: deusDollarAmount,
                    timestamp: block.timestamp
                })
            );
        }

        daoShare += (deiAmount * redemptionFee) / SCALE;

        IDEI(dei).pool_burn_from(msg.sender, deiAmount);
    }

    // Redeem DEI for DEUS. 0% collateral-backed
    function redeemAlgorithmicDEI(uint256 deiAmount) external notRedeemPaused {
        require(
            IDEI(dei).global_collateral_ratio() == 0,
            "DEIPool: INVALID_COLLATERAL_RATIO"
        );

        uint256 deusDollarAmount = (deiAmount * (SCALE - redemptionFee)) /
            (PRICE_PRECISION);
        redeemPositions[msg.sender].push(
            RedeemPosition({
                amount: deusDollarAmount,
                timestamp: block.timestamp
            })
        );
        daoShare += (deiAmount * redemptionFee) / SCALE;
        IDEI(dei).pool_burn_from(msg.sender, deiAmount);
    }

    function collectCollateral() external {
        require(
            (lastCollateralRedeemed[msg.sender] + collateralRedemptionDelay) <=
                block.timestamp,
            "DEIPool: COLLATERAL_REDEMPTION_DELAY"
        );

        if (redeemCollateralBalances[msg.sender] > 0) {
            uint256 collateralAmount = redeemCollateralBalances[msg.sender];
            redeemCollateralBalances[msg.sender] = 0;
            TransferHelper.safeTransfer(
                collateral,
                msg.sender,
                collateralAmount
            );
            unclaimedPoolCollateral =
                unclaimedPoolCollateral -
                collateralAmount;
        }
    }

    function collectDeus(
        uint256 price,
        bytes calldata _reqId,
        SchnorrSign[] calldata sigs
    ) external {
        require(
            sigs.length >= minimumRequiredSignatures,
            "DEIPool: INSUFFICIENT_SIGNATURES"
        );

        uint256 redeemId = nextRedeemId[msg.sender]++;

        require(
            redeemPositions[msg.sender][redeemId].timestamp +
                deusRedemptionDelay <=
                block.timestamp,
            "DEIPool: DEUS_REDEMPTION_DELAY"
        );

        {
            bytes32 hash = keccak256(
                abi.encodePacked(
                    appId,
                    msg.sender,
                    redeemId,
                    price,
                    _getChainId()
                )
            );
            require(
                IMuonV02(muon).verify(_reqId, uint256(hash), sigs),
                "DEIPool: UNVERIFIED_SIGNATURES"
            );
        }

        uint256 deusAmount = (redeemPositions[msg.sender][redeemId].amount *
            1e18) / price;

        IDEUS(deus).pool_mint(msg.sender, deusAmount);
    }

    // When the protocol is recollateralizing, we need to give a discount of DEUS to hit the new CR target
    // Thus, if the target collateral ratio is higher than the actual value of collateral, minters get DEUS for adding collateral
    // This function simply rewards anyone that sends collateral to a pool with the same amount of DEUS + the bonus rate
    // Anyone can call this function to recollateralize the protocol and take the extra DEUS value from the bonus rate as an arb opportunity
    function RecollateralizeDei(RecollateralizeDeiParams memory inputs)
        external
    {
        require(
            recollateralizePaused == false,
            "DEIPool: RECOLLATERALIZE_PAUSED"
        );

        require(
            inputs.expireBlock >= block.number,
            "DEIPool: EXPIRE_SIGNATURE"
        );
        bytes32 sighash = keccak256(
            abi.encodePacked(
                deus,
                inputs.deusPrice,
                inputs.expireBlock,
                _getChainId()
            )
        );
        require(
            IDEI(dei).verify_price(sighash, inputs.sigs),
            "DEIPool: UNVERIFIED_SIGNATURES"
        );

        uint256 collateralAmountD18 = inputs.collateralAmount *
            (10**missingDecimals);

        uint256 deiTotalSupply = IDEI(dei).totalSupply();
        uint256 globalCollateralRatio = IDEI(dei).global_collateral_ratio();
        uint256 globalCollateralValue = IDEI(dei).globalCollateralValue(
            inputs.collateralPrice
        );

        (uint256 collateralUnits, uint256 amountToRecollat) = IPoolLibrary(
            poolLibrary
        ).calcRecollateralizeDEIInner(
                collateralAmountD18,
                inputs.collateralPrice[inputs.collateralPrice.length - 1], // pool collateral price exist in last index
                globalCollateralValue,
                deiTotalSupply,
                globalCollateralRatio
            );

        uint256 collateralUnitsPrecision = collateralUnits /
            (10**missingDecimals);

        uint256 deusPaidBack = (amountToRecollat *
            (SCALE + bonusRate - recollatFee)) / inputs.deusPrice;

        TransferHelper.safeTransferFrom(
            collateral,
            msg.sender,
            address(this),
            collateralUnitsPrecision
        );
        IDEUS(deus).pool_mint(msg.sender, deusPaidBack);
    }

    // Function can be called by an DEUS holder to have the protocol buy back DEUS with excess collateral value from a desired collateral pool
    // This can also happen if the collateral ratio > 1
    function buyBackDeus(
        uint256 deusAmount,
        uint256[] memory collateralPrice,
        uint256 deusPrice,
        uint256 expireBlock,
        bytes[] calldata sigs
    ) external {
        require(buyBackPaused == false, "DEIPool: BUYBACK_PAUSED");
        require(expireBlock >= block.number, "DEIPool: EXPIRED_SIGNATURE");
        bytes32 sighash = keccak256(
            abi.encodePacked(
                collateral,
                collateralPrice,
                deus,
                deusPrice,
                expireBlock,
                _getChainId()
            )
        );
        require(
            IDEI(dei).verify_price(sighash, sigs),
            "DEIPool: UNVERIFIED_SIGNATURE"
        );

        IPoolLibrary.BuybackDeusParams memory inputParams = IPoolLibrary
            .BuybackDeusParams(
                availableExcessCollatDV(collateralPrice),
                deusPrice,
                collateralPrice[collateralPrice.length - 1], // pool collateral price exist in last index
                deusAmount
            );

        uint256 collateralEquivalentD18 = (IPoolLibrary(poolLibrary)
            .calcBuyBackDEUS(inputParams) * (SCALE - buybackFee)) / SCALE;
        uint256 collateralPrecision = collateralEquivalentD18 /
            (10**missingDecimals);

        // Give the sender their desired collateral and burn the DEUS
        IDEUS(deus).pool_burn_from(msg.sender, deusAmount);
        TransferHelper.safeTransfer(
            collateral,
            msg.sender,
            collateralPrecision
        );
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function collectDaoShare(uint256 amount, address to)
        external
        onlyRole(DAO_SHARE_COLLECTOR)
    {
        require(amount <= daoShare, "DEIPool: INVALID_AMOUNT");

        IDEI(dei).pool_mint(to, amount);
        daoShare -= amount;

        emit daoShareCollected(amount, to);
    }

    function emergencyWithdrawERC20(
        address token,
        uint256 amount,
        address to
    ) external onlyRole(TRUSTY_ROLE) {
        IERC20(token).transfer(to, amount);
    }

    function toggleMinting() external onlyRole(PAUSER_ROLE) {
        mintPaused = !mintPaused;
        emit MintingToggled(mintPaused);
    }

    function toggleRedeeming() external onlyRole(PAUSER_ROLE) {
        redeemPaused = !redeemPaused;
        emit RedeemingToggled(redeemPaused);
    }

    function toggleRecollateralize() external onlyRole(PAUSER_ROLE) {
        recollateralizePaused = !recollateralizePaused;
        emit RecollateralizeToggled(recollateralizePaused);
    }

    function toggleBuyBack() external onlyRole(PAUSER_ROLE) {
        buyBackPaused = !buyBackPaused;
        emit BuybackToggled(buyBackPaused);
    }

    // Combined into one function due to 24KiB contract memory limit
    function setPoolParameters(
        uint256 poolCeiling_,
        uint256 bonusRate_,
        uint256 collateralRedemptionDelay_,
        uint256 deusRedemptionDelay_,
        uint256 mintingFee_,
        uint256 redemptionFee_,
        uint256 buybackFee_,
        uint256 recollatFee_,
        address muon_,
        uint32 appId_,
        uint256 minimumRequiredSignatures_
    ) external onlyRole(PARAMETER_SETTER_ROLE) {
        poolCeiling = poolCeiling_;
        bonusRate = bonusRate_;
        collateralRedemptionDelay = collateralRedemptionDelay_;
        deusRedemptionDelay = deusRedemptionDelay_;
        mintingFee = mintingFee_;
        redemptionFee = redemptionFee_;
        buybackFee = buybackFee_;
        recollatFee = recollatFee_;
        muon = muon_;
        appId = appId_;
        minimumRequiredSignatures = minimumRequiredSignatures_;

        emit PoolParametersSet(
            poolCeiling_,
            bonusRate_,
            collateralRedemptionDelay_,
            deusRedemptionDelay_,
            mintingFee_,
            redemptionFee_,
            buybackFee_,
            recollatFee_,
            muon_,
            appId_,
            minimumRequiredSignatures_
        );
    }
}

//Dar panah khoda

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
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
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
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
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
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
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

interface IPoolLibrary {
     struct MintFractionalDeiParams {
        uint256 deusPrice;
        uint256 collateralPrice;
        uint256 collateralAmount;
        uint256 collateralRatio;
    }

    struct BuybackDeusParams {
        uint256 excessCollateralValueD18;
        uint256 deusPrice;
        uint256 collateralPrice;
        uint256 deusAmount;
    }

    function calcMint1t1DEI(uint256 col_price, uint256 collateral_amount_d18)
        external
        pure
        returns (uint256);

    function calcMintAlgorithmicDEI(
        uint256 deus_price_usd,
        uint256 deus_amount_d18
    ) external pure returns (uint256);

    function calcMintFractionalDEI(MintFractionalDeiParams memory params)
        external
        pure
        returns (uint256, uint256);

    function calcRedeem1t1DEI(uint256 col_price_usd, uint256 DEI_amount)
        external
        pure
        returns (uint256);

    function calcBuyBackDEUS(BuybackDeusParams memory params)
        external
        pure
        returns (uint256);

    function recollateralizeAmount(
        uint256 total_supply,
        uint256 global_collateral_ratio,
        uint256 global_collat_value
    ) external pure returns (uint256);

    function calcRecollateralizeDEIInner(
        uint256 collateral_amount,
        uint256 col_price,
        uint256 global_collat_value,
        uint256 dei_total_supply,
        uint256 global_collateral_ratio
    ) external pure returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT

// =================================================================================================================
//  _|_|_|    _|_|_|_|  _|    _|    _|_|_|      _|_|_|_|  _|                                                       |
//  _|    _|  _|        _|    _|  _|            _|            _|_|_|      _|_|_|  _|_|_|      _|_|_|    _|_|       |
//  _|    _|  _|_|_|    _|    _|    _|_|        _|_|_|    _|  _|    _|  _|    _|  _|    _|  _|        _|_|_|_|     |
//  _|    _|  _|        _|    _|        _|      _|        _|  _|    _|  _|    _|  _|    _|  _|        _|           |
//  _|_|_|    _|_|_|_|    _|_|    _|_|_|        _|        _|  _|    _|    _|_|_|  _|    _|    _|_|_|    _|_|_|     |
// =================================================================================================================
// ============================= Oracle =============================
// ==================================================================
// DEUS Finance: https://github.com/DeusFinance

// Primary Author(s)
// Sina: https://github.com/spsina
// Vahid: https://github.com/vahid-dev

import "./IMuonV02.sol";

interface IDEIPool {
    struct RecollateralizeDeiParams {
        uint256 collateralAmount;
        uint256 poolCollateralPrice;
        uint256[] collateralPrice;
        uint256 deusPrice;
        uint256 expireBlock;
        bytes[] sigs;
    }

    struct RedeemPosition {
        uint256 amount;
        uint256 timestamp;
    }

    /* ========== PUBLIC VIEWS ========== */

    function collatDollarBalance(uint256 collateralPrice)
        external
        view
        returns (uint256 balance);

    function positionsLength(address user)
        external
        view
        returns (uint256 length);

    function getAllPositions(address user)
        external
        view
        returns (RedeemPosition[] memory positinos);

    function getUnRedeemedPositions(address user)
        external
        view
        returns (RedeemPosition[] memory positions);

    function mint1t1DEI(uint256 collateralAmount)
        external
        returns (uint256 deiAmount);

    function mintAlgorithmicDEI(
        uint256 deusAmount,
        uint256 deusPrice,
        uint256 expireBlock,
        bytes[] calldata sigs
    ) external returns (uint256 deiAmount);

    function mintFractionalDEI(
        uint256 collateralAmount,
        uint256 deusAmount,
        uint256 deusPrice,
        uint256 expireBlock,
        bytes[] calldata sigs
    ) external returns (uint256 mintAmount);

    function redeem1t1DEI(uint256 deiAmount) external;

    function redeemFractionalDEI(uint256 deiAmount) external;

    function redeemAlgorithmicDEI(uint256 deiAmount) external;

    function collectCollateral() external;

    function collectDeus(
        uint256 price,
        bytes calldata _reqId,
        SchnorrSign[] calldata sigs
    ) external;

    function RecollateralizeDei(RecollateralizeDeiParams memory inputs)
        external;

    function buyBackDeus(
        uint256 deusAmount,
        uint256[] memory collateralPrice,
        uint256 deusPrice,
        uint256 expireBlock,
        bytes[] calldata sigs
    ) external;

    /* ========== RESTRICTED FUNCTIONS ========== */
    function collectDaoShare(uint256 amount, address to) external;

    function emergencyWithdrawERC20(
        address token,
        uint256 amount,
        address to
    ) external;

    function toggleMinting() external;

    function toggleRedeeming() external;

    function toggleRecollateralize() external;

    function toggleBuyBack() external;

    function setPoolParameters(
        uint256 poolCeiling_,
        uint256 bonusRate_,
        uint256 collateralRedemptionDelay_,
        uint256 deusRedemptionDelay_,
        uint256 mintingFee_,
        uint256 redemptionFee_,
        uint256 buybackFee_,
        uint256 recollatFee_,
        address muon_,
        uint32 appId_,
        uint256 minimumRequiredSignatures_
    ) external;

    /* ========== EVENTS ========== */

    event PoolParametersSet(
        uint256 poolCeiling,
        uint256 bonusRate,
        uint256 collateralRedemptionDelay,
        uint256 deusRedemptionDelay,
        uint256 mintingFee,
        uint256 redemptionFee,
        uint256 buybackFee,
        uint256 recollatFee,
        address muon,
        uint32 appId,
        uint256 minimumRequiredSignatures
    );
    event daoShareCollected(uint256 daoShare, address to);
    event MintingToggled(bool toggled);
    event RedeemingToggled(bool toggled);
    event RecollateralizeToggled(bool toggled);
    event BuybackToggled(bool toggled);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function decimals() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later

interface IDEUS {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function pool_burn_from(address b_address, uint256 b_amount) external;
    function pool_mint(address m_address, uint256 m_amount) external;
    function mint(address to, uint256 amount) external;
    function setDEIAddress(address dei_contract_address) external;
    function setNameAndSymbol(string memory _name, string memory _symbol) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

interface IDEI {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function global_collateral_ratio() external view returns (uint256);
    function dei_pools(address _address) external view returns (bool);
    function dei_pools_array() external view returns (address[] memory);
    function verify_price(bytes32 sighash, bytes[] calldata sigs) external view returns (bool);
    function dei_info(uint256[] memory collat_usd_price) external view returns (uint256, uint256, uint256);
    function getChainID() external view returns (uint256);
    function globalCollateralValue(uint256[] memory collat_usd_price) external view returns (uint256);
    function refreshCollateralRatio(uint deus_price, uint dei_price, uint256 expire_block, bytes[] calldata sigs) external;
    function useGrowthRatio(bool _use_growth_ratio) external;
    function setGrowthRatioBands(uint256 _GR_top_band, uint256 _GR_bottom_band) external;
    function setPriceBands(uint256 _top_band, uint256 _bottom_band) external;
    function activateDIP(bool _activate) external;
    function pool_burn_from(address b_address, uint256 b_amount) external;
    function pool_mint(address m_address, uint256 m_amount) external;
    function addPool(address pool_address) external;
    function removePool(address pool_address) external;
    function setNameAndSymbol(string memory _name, string memory _symbol) external;
    function setOracle(address _oracle) external;
    function setDEIStep(uint256 _new_step) external;
    function setReserveTracker(address _reserve_tracker_address) external;
    function setRefreshCooldown(uint256 _new_cooldown) external;
    function setDEUSAddress(address _deus_address) external;
    function toggleCollateralRatio() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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

// SPDX-License-Identifier: GPL-3.0

struct SchnorrSign {
    uint256 signature;
    address owner;
    address nonce;
}

interface IMuonV02 {
    function verify(
        bytes calldata reqId,
        uint256 hash,
        SchnorrSign[] calldata _sigs
    ) external returns (bool);
}