// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;


                                                                

// ======================================================================
// |     ____  ____  ___   _  __    _______                             | 
// |    / __ )/ __ \/   | | |/ /   / ____(____  ____ _____  ________    | 
// |   / __  / /_/ / /| | |   /   / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / /_/ / _, _/ ___ |/   |   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_____/_/ |_/_/  |_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                    |
// ======================================================================
// ============================ BraxPoolV3 ==============================
// ======================================================================
// Allows multiple btc sythns (fixed amount at initialization) as collateral
// wBTC, ibBTC and renBTC to start
// For this pool, the goal is to accept decentralized assets as collateral to limit
// government / regulatory risk (e.g. wBTC blacklisting until holders KYC)

// Brax Finance: https://github.com/BraxFinance

// Primary Author(s)
// Travis Moore: https://github.com/FortisFortuna

// Reviewer(s) / Contributor(s)
// Jason Huan: https://github.com/jasonhuan
// Sam Kazemian: https://github.com/samkazemian
// Dennis: github.com/denett
// Hameed
// Andrew Mitchell: https://github.com/mitche50

import "../../Math/SafeMath.sol";
import '../../Uniswap/TransferHelper.sol';
import "../../Staking/Owned.sol";
import "../../BXS/IBxs.sol";
import "../../Brax/IBrax.sol";
import "../../Oracle/AggregatorV3Interface.sol";
import "../../Brax/IBraxAMOMinter.sol";
import "../../ERC20/ERC20.sol";

contract BraxPoolV3 is Owned {
    using SafeMath for uint256;
    // SafeMath automatically included in Solidity >= 8.0.0

    /* ========== STATE VARIABLES ========== */

    // Core
    address public timelockAddress;
    address public custodianAddress; // Custodian is an EOA (or msig) with pausing privileges only, in case of an emergency

    IBrax private BRAX;
    IBxs private BXS;

    mapping(address => bool) public amoMinterAddresses; // minter address -> is it enabled
    // TODO: Get aggregator
    // IMPORTANT - set to random chainlink contract for testing
    AggregatorV3Interface public priceFeedBRAXBTC = AggregatorV3Interface(0xfdFD9C85aD200c506Cf9e21F1FD8dd01932FBB23);
    // TODO: Get aggregator
    // IMPORTANT - set to random chainlink contract for testing
    AggregatorV3Interface public priceFeedBXSBTC = AggregatorV3Interface(0xfdFD9C85aD200c506Cf9e21F1FD8dd01932FBB23);
    uint256 private chainlinkBraxBtcDecimals;
    uint256 private chainlinkBxsBtcDecimals;

    // Collateral
    address[] public collateralAddresses;
    string[] public collateralSymbols;
    uint256[] public missingDecimals; // Number of decimals needed to get to E18. collateral index -> missingDecimals
    uint256[] public poolCeilings; // Total across all collaterals. Accounts for missingDecimals
    uint256[] public collateralPrices; // Stores price of the collateral, if price is paused.  Currently hardcoded at 1:1 BTC. CONSIDER ORACLES EVENTUALLY!!!
    mapping(address => uint256) public collateralAddrToIdx; // collateral addr -> collateral index
    mapping(address => bool) public enabledCollaterals; // collateral address -> is it enabled
    
    // Redeem related
    mapping (address => uint256) public redeemBXSBalances;
    mapping (address => mapping(uint256 => uint256)) public redeemCollateralBalances; // Address -> collateral index -> balance
    uint256[] public unclaimedPoolCollateral; // collateral index -> balance
    uint256 public unclaimedPoolBXS;
    mapping (address => uint256) public lastRedeemed; // Collateral independent
    uint256 public redemptionDelay = 2; // Number of blocks to wait before being able to collectRedemption()
    uint256 public redeemPriceThreshold = 99000000; // 0.99 BTC
    uint256 public mintPriceThreshold = 101000000; // 1.01 BTC
    
    // Buyback related
    mapping(uint256 => uint256) public bbkHourlyCum; // Epoch hour ->  Collat out in that hour (E18)
    uint256 public bbkMaxColE18OutPerHour = 1e18;

    // Recollat related
    mapping(uint256 => uint256) public rctHourlyCum; // Epoch hour ->  BXS out in that hour
    uint256 public rctMaxBxsOutPerHour = 1000e18;

    // Fees and rates
    // getters are in collateralInformation()
    uint256[] private mintingFee;
    uint256[] private redemptionFee;
    uint256[] private buybackFee;
    uint256[] private recollatFee;
    uint256 public bonusRate; // Bonus rate on BXS minted during recollateralize(); 6 decimals of precision, set to 0.75% on genesis
    
    // Constants for various precisions
    uint256 private constant PRICE_PRECISION = 1e8;

    // Pause variables
    // getters are in collateralInformation()
    bool[] private mintPaused; // Collateral-specific
    bool[] private redeemPaused; // Collateral-specific
    bool[] private recollateralizePaused; // Collateral-specific
    bool[] private buyBackPaused; // Collateral-specific
    bool[] private borrowingPaused; // Collateral-specific

    /* ========== MODIFIERS ========== */

    modifier onlyByOwnGov() {
        require(msg.sender == timelockAddress || msg.sender == owner, "Not owner or timelock");
        _;
    }

    modifier onlyByOwnGovCust() {
        require(msg.sender == timelockAddress || msg.sender == owner || msg.sender == custodianAddress, "Not owner, tlck, or custd");
        _;
    }

    modifier onlyAMOMinters() {
        require(amoMinterAddresses[msg.sender], "Not an AMO Minter");
        _;
    }

    modifier collateralEnabled(uint256 colIdx) {
        require(enabledCollaterals[collateralAddresses[colIdx]], "Collateral disabled");
        _;
    }

    modifier validCollateral(uint256 colIdx) {
        require(collateralAddresses[colIdx] != address(0), "Invalid collateral");
        _;
    }
 
    /* ========== CONSTRUCTOR ========== */
    
    constructor (
        address poolManagerAddress,
        address newCustodianAddress,
        address newTimelockAddress,
        address[] memory newCollateralAddresses,
        uint256[] memory newPoolCeilings,
        uint256[] memory initialFees,
        address braxAddress,
        address bxsAddress
    ) Owned(poolManagerAddress){
        // Core
        timelockAddress = newTimelockAddress;
        custodianAddress = newCustodianAddress;

        // BRAX and BXS
        BRAX = IBrax(braxAddress);
        BXS = IBxs(bxsAddress);

        // Fill collateral info
        collateralAddresses = newCollateralAddresses;
        for (uint256 i = 0; i < newCollateralAddresses.length; i++){ 
            // For fast collateral address -> collateral idx lookups later
            collateralAddrToIdx[newCollateralAddresses[i]] = i;

            // Set all of the collaterals initially to disabled
            enabledCollaterals[newCollateralAddresses[i]] = false;

            // Add in the missing decimals
            missingDecimals.push(uint256(18).sub(ERC20(newCollateralAddresses[i]).decimals()));

            // Add in the collateral symbols
            collateralSymbols.push(ERC20(newCollateralAddresses[i]).symbol());

            // Initialize unclaimed pool collateral
            unclaimedPoolCollateral.push(0);

            // Initialize paused prices to 1 BTC as a backup
            collateralPrices.push(PRICE_PRECISION);

            // Handle the fees
            mintingFee.push(initialFees[0]);
            redemptionFee.push(initialFees[1]);
            buybackFee.push(initialFees[2]);
            recollatFee.push(initialFees[3]);

            // Handle the pauses
            mintPaused.push(false);
            redeemPaused.push(false);
            recollateralizePaused.push(false);
            buyBackPaused.push(false);
            borrowingPaused.push(false);
        }

        // Pool ceiling
        poolCeilings = newPoolCeilings;

        // Set the decimals
        // chainlinkBraxBtcDecimals = priceFeedBRAXBTC.decimals();
        // chainlinkBxsBtcDecimals = priceFeedBXSBTC.decimals();
        chainlinkBraxBtcDecimals = 18;
        chainlinkBxsBtcDecimals = 18;
    }

    /* ========== STRUCTS ========== */
    
    struct CollateralInformation {
        uint256 index;
        string symbol;
        address colAddr;
        bool isEnabled;
        uint256 missingDecs;
        uint256 price;
        uint256 poolCeiling;
        bool mintPaused;
        bool redeemPaused;
        bool recollatPaused;
        bool buybackPaused;
        bool borrowingPaused;
        uint256 mintingFee;
        uint256 redemptionFee;
        uint256 buybackFee;
        uint256 recollatFee;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
     * @notice Compute the threshold for buyback and recollateralization to throttle
     * @notice both in times of high volatility
     * @dev helper function to help limit volatility in calculations
     * @param cur Current amount already consumed in the current hour
     * @param max Maximum allowable in the current hour
     * @param theo Amount to theoretically distribute, used to check against available amounts
     * @return amount Amount allowable to distribute
     */
    function comboCalcBbkRct(uint256 cur, uint256 max, uint256 theo) internal pure returns (uint256 amount) {
        if (cur >= max) {
            // If the hourly limit has already been reached, return 0;
            return 0;
        }
        else {
            // Get the available amount
            uint256 available = max.sub(cur);

            if (theo >= available) {
                // If the the theoretical is more than the available, return the available
                return available;
            }
            else {
                // Otherwise, return the theoretical amount
                return theo;
            }
        }
    }

    /* ========== VIEWS ========== */

    /**
     * @notice Return the collateral information for a provided address
     * @param collatAddress address of a type of collateral, e.g. wBTC or renBTC
     * @return returnData struct containing all data regarding the provided collateral address
     */
    function collateralInformation(address collatAddress) external view returns (CollateralInformation memory returnData){
        require(enabledCollaterals[collatAddress], "Invalid collateral");

        // Get the index
        uint256 idx = collateralAddrToIdx[collatAddress];
        
        returnData = CollateralInformation(
            idx, // [0]
            collateralSymbols[idx], // [1]
            collatAddress, // [2]
            enabledCollaterals[collatAddress], // [3]
            missingDecimals[idx], // [4]
            collateralPrices[idx], // [5]
            poolCeilings[idx], // [6]
            mintPaused[idx], // [7]
            redeemPaused[idx], // [8]
            recollateralizePaused[idx], // [9]
            buyBackPaused[idx], // [10]
            borrowingPaused[idx], // [11]
            mintingFee[idx], // [12]
            redemptionFee[idx], // [13]
            buybackFee[idx], // [14]
            recollatFee[idx] // [15]
        );
    }

    /**
     * @notice Returns a list of all collateral addresses
     * @return addresses list of all collateral addresses
     */
    function allCollaterals() external view returns (address[] memory addresses) {
        return collateralAddresses;
    }

    /**
     * @notice Return current price from chainlink feed for BRAX
     * @return braxPrice Current price of BRAX chainlink feed
     */
    function getBRAXPrice() public view returns (uint256 braxPrice) {
        (uint80 roundID, int price, , uint256 updatedAt, uint80 answeredInRound) = priceFeedBRAXBTC.latestRoundData();
        require(price >= 0 && updatedAt!= 0 && answeredInRound >= roundID, "Invalid chainlink price");

        return uint256(price).mul(PRICE_PRECISION).div(10 ** chainlinkBraxBtcDecimals);
    }

    /**
     * @notice Return current price from chainlink feed for BXS
     * @return bxsPrice Current price of BXS chainlink feed
     */
    function getBXSPrice() public view returns (uint256 bxsPrice) {
        (uint80 roundID, int price, , uint256 updatedAt, uint80 answeredInRound) = priceFeedBXSBTC.latestRoundData();
        require(price >= 0 && updatedAt!= 0 && answeredInRound >= roundID, "Invalid chainlink price");

        return uint256(price).mul(PRICE_PRECISION).div(10 ** chainlinkBxsBtcDecimals);
    }

    /**
     * @notice Return price of BRAX in the provided collateral token
     * @dev Note: pricing is returned in collateral precision.  For example,
     * @dev getting price for wBTC would be in 8 decimals
     * @param colIdx index of collateral token (e.g. 0 for wBTC, 1 for renBTC)
     * @param braxAmount amount of BRAX to get the equivalent price for
     * @return braxPrice price of BRAX in collateral (decimals are equivalent to collateral, not BRAX)
     */
    function getBRAXInCollateral(uint256 colIdx, uint256 braxAmount) public view returns (uint256 braxPrice) {
        require(collateralPrices[colIdx] > 0, "Price missing from collateral");

        return braxAmount.mul(PRICE_PRECISION).div(10 ** missingDecimals[colIdx]).div(collateralPrices[colIdx]);
    }

    /**
     * @notice Return amount of collateral balance not waiting to be redeemed
     * @param colIdx index of collateral token (e.g. 0 for wBTC, 1 for renBTC)
     * @return collatAmount amount of collateral not waiting to be redeemed (E18)
     */
    function freeCollatBalance(uint256 colIdx) public view validCollateral(colIdx) returns (uint256 collatAmount) {
        return ERC20(collateralAddresses[colIdx]).balanceOf(address(this)).sub(unclaimedPoolCollateral[colIdx]);
    }

    /**
     * @notice Returns BTC value of collateral held in this Brax pool, in E18
     * @return balanceTally total BTC value in pool (E18)
     */
    function collatBtcBalance() external view returns (uint256 balanceTally) {
        balanceTally = 0;

        for (uint256 i = 0; i < collateralAddresses.length; i++){
            // It's possible collateral has been removed, so skip any address(0) collateral
            if(collateralAddresses[i] == address(0)) {
                continue;
            }
            balanceTally += freeCollatBalance(i).mul(10 ** missingDecimals[i]).mul(collateralPrices[i]).div(PRICE_PRECISION);
        }
    }

    /**
     * @notice Returns the value of excess collateral (E18) held globally, compared to what is needed to maintain the global collateral ratio
     * @dev comboCalcBbkRct() is used to throttle buybacks to avoid dumps during periods of large volatility
     * @return total excess collateral in the system (E18)
     */
    function buybackAvailableCollat() public view returns (uint256) {
        uint256 totalSupply = BRAX.totalSupply();
        uint256 globalCollateralRatio = BRAX.globalCollateralRatio();
        uint256 globalCollatValue = BRAX.globalCollateralValue();

        if (globalCollateralRatio > PRICE_PRECISION) globalCollateralRatio = PRICE_PRECISION; // Handles an overcollateralized contract with CR > 1
        uint256 requiredCollatBTCValueD18 = (totalSupply.mul(globalCollateralRatio)).div(PRICE_PRECISION); // Calculates collateral needed to back each 1 BRAX with 1 BTC of collateral at current collat ratio
        
        if (globalCollatValue > requiredCollatBTCValueD18) {
            // Get the theoretical buyback amount
            uint256 theoreticalBbkAmt = globalCollatValue.sub(requiredCollatBTCValueD18);

            // See how much has collateral has been issued this hour
            uint256 currentHrBbk = bbkHourlyCum[curEpochHr()];

            // Account for the throttling
            return comboCalcBbkRct(currentHrBbk, bbkMaxColE18OutPerHour, theoreticalBbkAmt);
        }
        else return 0;
    }

    /**
     * @notice Returns the missing amount of collateral (in E18) needed to maintain the collateral ratio
     * @return balanceTally total BTC missing to maintain collateral ratio
     */
    function recollatTheoColAvailableE18() public view returns (uint256 balanceTally) {
        uint256 braxTotalSupply = BRAX.totalSupply();
        uint256 effectiveCollateralRatio = BRAX.globalCollateralValue().mul(PRICE_PRECISION).div(braxTotalSupply); // Returns it in 1e8
        
        uint256 desiredCollatE24 = (BRAX.globalCollateralRatio()).mul(braxTotalSupply);
        uint256 effectiveCollatE24 = effectiveCollateralRatio.mul(braxTotalSupply);

        // Return 0 if already overcollateralized
        // Otherwise, return the deficiency
        if (effectiveCollatE24 >= desiredCollatE24) return 0;
        else {
            return (desiredCollatE24.sub(effectiveCollatE24)).div(PRICE_PRECISION);
        }
    }

    /**
     * @notice Returns the value of BXS available to be used for recollats
     * @dev utilizes comboCalcBbkRct to throttle for periods of high volatility
     * @return total value of BXS available for recollateralization
     */
    function recollatAvailableBxs() public view returns (uint256) {
        uint256 bxsPrice = getBXSPrice();

        // Get the amount of collateral theoretically available
        uint256 recollatTheoAvailableE18 = recollatTheoColAvailableE18();

        // Return 0 if already overcollateralized
        if (recollatTheoAvailableE18 <= 0) return 0;

        // Get the amount of BXS theoretically outputtable
        uint256 bxsTheoOut = recollatTheoAvailableE18.mul(PRICE_PRECISION).div(bxsPrice);

        // See how much BXS has been issued this hour
        uint256 currentHrRct = rctHourlyCum[curEpochHr()];

        // Account for the throttling
        return comboCalcBbkRct(currentHrRct, rctMaxBxsOutPerHour, bxsTheoOut);
    }

    /// @return hour current epoch hour
    function curEpochHr() public view returns (uint256) {
        return (block.timestamp / 3600); // Truncation desired
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    /**
     * @notice Mint BRAX via collateral / BXS combination
     * @param colIdx integer value of the collateral index
     * @param braxAmt Amount of BRAX to mint
     * @param braxOutMin Minimum amount of BRAX to accept
     * @param maxCollatIn Maximum amount of collateral to use for minting
     * @param maxBxsIn Maximum amount of BXS to use for minting
     * @param oneToOneOverride Boolean flag to indicate using 1:1 BRAX:Collateral for 
     *   minting, ignoring current global collateral ratio of BRAX
     * @return totalBraxMint Amount of BRAX minted
     * @return collatNeeded Amount of collateral used
     * @return bxsNeeded Amount of BXS used
     */
     function mintBrax(
        uint256 colIdx, 
        uint256 braxAmt,
        uint256 braxOutMin,
        uint256 maxCollatIn,
        uint256 maxBxsIn,
        bool oneToOneOverride
    ) external collateralEnabled(colIdx) returns (
        uint256 totalBraxMint, 
        uint256 collatNeeded, 
        uint256 bxsNeeded
    ) {
        require(mintPaused[colIdx] == false, "Minting is paused");

        // Prevent unneccessary mints
        require(getBRAXPrice() >= mintPriceThreshold, "Brax price too low");

        uint256 globalCollateralRatio = BRAX.globalCollateralRatio();

        if (oneToOneOverride || globalCollateralRatio >= PRICE_PRECISION) { 
            // 1-to-1, overcollateralized, or user selects override
            collatNeeded = getBRAXInCollateral(colIdx, braxAmt);
            bxsNeeded = 0;
        } else if (globalCollateralRatio == 0) { 
            // Algorithmic
            collatNeeded = 0;
            bxsNeeded = braxAmt.mul(PRICE_PRECISION).div(getBXSPrice());
        } else { 
            // Fractional
            uint256 braxForCollat = braxAmt.mul(globalCollateralRatio).div(PRICE_PRECISION);
            uint256 braxForBxs = braxAmt.sub(braxForCollat);
            collatNeeded = getBRAXInCollateral(colIdx, braxForCollat);
            bxsNeeded = braxForBxs.mul(PRICE_PRECISION).div(getBXSPrice());
        }

        // Subtract the minting fee
        totalBraxMint = (braxAmt.mul(PRICE_PRECISION.sub(mintingFee[colIdx]))).div(PRICE_PRECISION);

        // Check slippages
        require((totalBraxMint >= braxOutMin), "BRAX slippage");
        require((collatNeeded <= maxCollatIn), "Collat slippage");
        require((bxsNeeded <= maxBxsIn), "BXS slippage");

        // Check the pool ceiling
        require(freeCollatBalance(colIdx).add(collatNeeded) <= poolCeilings[colIdx], "Pool ceiling");

        if(bxsNeeded > 0) {
            // Take the BXS and collateral first
            BXS.poolBurnFrom(msg.sender, bxsNeeded);
        }
        TransferHelper.safeTransferFrom(collateralAddresses[colIdx], msg.sender, address(this), collatNeeded);

        // Mint the BRAX
        BRAX.poolMint(msg.sender, totalBraxMint);
    }

    /**
     * @notice Redeem BRAX for BXS / Collateral combination
     * @param colIdx integer value of the collateral index
     * @param braxAmount Amount of BRAX to redeem
     * @param bxsOutMin Minimum amount of BXS to redeem for
     * @param colOutMin Minimum amount of collateral to redeem for
     * @return collatOut Amount of collateral redeemed
     * @return bxsOut Amount of BXS redeemed
     */
    function redeemBrax(
        uint256 colIdx, 
        uint256 braxAmount, 
        uint256 bxsOutMin, 
        uint256 colOutMin
    ) external collateralEnabled(colIdx) returns (
        uint256 collatOut, 
        uint256 bxsOut
    ) {
        require(redeemPaused[colIdx] == false, "Redeeming is paused");

        // Prevent unnecessary redemptions that could adversely affect the BXS price
        require(getBRAXPrice() <= redeemPriceThreshold, "Brax price too high");

        uint256 globalCollateralRatio = BRAX.globalCollateralRatio();
        uint256 braxAfterFee = (braxAmount.mul(PRICE_PRECISION.sub(redemptionFee[colIdx]))).div(PRICE_PRECISION);

        // Assumes 1 BTC BRAX in all cases
        if(globalCollateralRatio >= PRICE_PRECISION) { 
            // 1-to-1 or overcollateralized
            collatOut = getBRAXInCollateral(colIdx, braxAfterFee);
            bxsOut = 0;
        } else if (globalCollateralRatio == 0) { 
            // Algorithmic
            bxsOut = braxAfterFee
                            .mul(PRICE_PRECISION)
                            .div(getBXSPrice());
            collatOut = 0;
        } else { 
            // Fractional
            collatOut = getBRAXInCollateral(colIdx, braxAfterFee)
                            .mul(globalCollateralRatio)
                            .div(PRICE_PRECISION);
            bxsOut = braxAfterFee
                            .mul(PRICE_PRECISION.sub(globalCollateralRatio))
                            .div(getBXSPrice()); // PRICE_PRECISIONS CANCEL OUT
        }

        // Checks
        require(collatOut <= (ERC20(collateralAddresses[colIdx])).balanceOf(address(this)).sub(unclaimedPoolCollateral[colIdx]), "Insufficient pool collateral");
        require(collatOut >= colOutMin, "Collateral slippage");
        require(bxsOut >= bxsOutMin, "BXS slippage");

        // Account for the redeem delay
        redeemCollateralBalances[msg.sender][colIdx] = redeemCollateralBalances[msg.sender][colIdx].add(collatOut);
        unclaimedPoolCollateral[colIdx] = unclaimedPoolCollateral[colIdx].add(collatOut);

        redeemBXSBalances[msg.sender] = redeemBXSBalances[msg.sender].add(bxsOut);
        unclaimedPoolBXS = unclaimedPoolBXS.add(bxsOut);

        lastRedeemed[msg.sender] = block.number;
        
        BRAX.poolBurnFrom(msg.sender, braxAmount);
        if (bxsOut > 0) {
            BXS.poolMint(address(this), bxsOut);
        }
    }


    /**
     * @notice Collect collateral and BXS from redemption pool
     * @dev Redemption is split into two functions to prevent flash loans removing 
     * @dev BXS/collateral from the system, use an AMM to trade new price and then mint back
     * @param colIdx integer value of the collateral index
     * @return bxsAmount Amount of BXS redeemed
     * @return collateralAmount Amount of collateral redeemed
     */ 
    function collectRedemption(uint256 colIdx) external returns (uint256 bxsAmount, uint256 collateralAmount) {
        require(redeemPaused[colIdx] == false, "Redeeming is paused");
        require((lastRedeemed[msg.sender].add(redemptionDelay)) <= block.number, "Too soon");
        bool sendBXS = false;
        bool sendCollateral = false;

        // Use Checks-Effects-Interactions pattern
        if(redeemBXSBalances[msg.sender] > 0){
            bxsAmount = redeemBXSBalances[msg.sender];
            redeemBXSBalances[msg.sender] = 0;
            unclaimedPoolBXS = unclaimedPoolBXS.sub(bxsAmount);
            sendBXS = true;
        }
        
        if(redeemCollateralBalances[msg.sender][colIdx] > 0){
            collateralAmount = redeemCollateralBalances[msg.sender][colIdx];
            redeemCollateralBalances[msg.sender][colIdx] = 0;
            unclaimedPoolCollateral[colIdx] = unclaimedPoolCollateral[colIdx].sub(collateralAmount);
            sendCollateral = true;
        }

        // Send out the tokens
        if(sendBXS){
            TransferHelper.safeTransfer(address(BXS), msg.sender, bxsAmount);
        }
        if(sendCollateral){
            TransferHelper.safeTransfer(collateralAddresses[colIdx], msg.sender, collateralAmount);
        }
    }

    /**
     * @notice Trigger buy back of BXS with excess collateral from a desired collateral pool
     * @notice when the current collateralization rate > global collateral ratio
     * @param colIdx Index of the collateral to buy back with
     * @param bxsAmount Amount of BXS to buy back
     * @param colOutMin Minimum amount of collateral to use to buyback
     * @return colOut Amount of collateral used to purchase BXS
     */
    function buyBackBxs(uint256 colIdx, uint256 bxsAmount, uint256 colOutMin) external collateralEnabled(colIdx) returns (uint256 colOut) {
        require(buyBackPaused[colIdx] == false, "Buyback is paused");
        uint256 bxsPrice = getBXSPrice();
        uint256 availableExcessCollatDv = buybackAvailableCollat();

        // If the total collateral value is higher than the amount required at the current collateral ratio then buy back up to the possible BXS with the desired collateral
        require(availableExcessCollatDv > 0, "No Collat Avail For BBK");

        // Make sure not to take more than is available
        uint256 bxsBTCValueD18 = bxsAmount.mul(bxsPrice).div(PRICE_PRECISION);
        require(bxsBTCValueD18 <= availableExcessCollatDv, "Insuf Collat Avail For BBK");

        // Get the equivalent amount of collateral based on the market value of BXS provided 
        uint256 collateralEquivalentD18 = bxsBTCValueD18.mul(PRICE_PRECISION).div(collateralPrices[colIdx]);
        colOut = collateralEquivalentD18.div(10 ** missingDecimals[colIdx]); // In its natural decimals()

        // Subtract the buyback fee
        colOut = (colOut.mul(PRICE_PRECISION.sub(buybackFee[colIdx]))).div(PRICE_PRECISION);

        // Check for slippage
        require(colOut >= colOutMin, "Collateral slippage");

        // Take in and burn the BXS, then send out the collateral
        BXS.poolBurnFrom(msg.sender, bxsAmount);
        TransferHelper.safeTransfer(collateralAddresses[colIdx], msg.sender, colOut);

        // Increment the outbound collateral, in E18, for that hour
        // Used for buyback throttling
        bbkHourlyCum[curEpochHr()] += collateralEquivalentD18;
    }

    /**
     * @notice Reward users who send collateral to a pool with the same amount of BXS + set bonus rate
     * @notice Anyone can call this function to recollateralize the pool and get extra BXS
     * @param colIdx Index of the collateral to recollateralize
     * @param collateralAmount Amount of collateral being deposited
     * @param bxsOutMin Minimum amount of BXS to accept
     * @return bxsOut Amount of BXS distributed
     */
    function recollateralize(uint256 colIdx, uint256 collateralAmount, uint256 bxsOutMin) external collateralEnabled(colIdx) returns (uint256 bxsOut) {
        require(recollateralizePaused[colIdx] == false, "Recollat is paused");
        uint256 collateralAmountD18 = collateralAmount * (10 ** missingDecimals[colIdx]);
        uint256 bxsPrice = getBXSPrice();

        // Get the amount of BXS actually available (accounts for throttling)
        uint256 bxsActuallyAvailable = recollatAvailableBxs();

        // Calculated the attempted amount of BXS
        bxsOut = collateralAmountD18.mul(PRICE_PRECISION.add(bonusRate).sub(recollatFee[colIdx])).div(bxsPrice);

        // Make sure there is BXS available
        require(bxsOut <= bxsActuallyAvailable, "Insuf BXS Avail For RCT");

        // Check slippage
        require(bxsOut >= bxsOutMin, "BXS slippage");

        // Don't take in more collateral than the pool ceiling for this token allows
        require(freeCollatBalance(colIdx).add(collateralAmount) <= poolCeilings[colIdx], "Pool ceiling");

        // Take in the collateral and pay out the BXS
        TransferHelper.safeTransferFrom(collateralAddresses[colIdx], msg.sender, address(this), collateralAmount);
        BXS.poolMint(msg.sender, bxsOut);

        // Increment the outbound BXS, in E18
        // Used for recollat throttling
        rctHourlyCum[curEpochHr()] += bxsOut;
    }

    /* ========== RESTRICTED FUNCTIONS, MINTER ONLY ========== */

    /**
     * @notice Allow AMO Minters to borrow without gas intensive mint->redeem cycle
     * @param collateralAmount Amount of collateral the AMO minter will borrow
     */
    function amoMinterBorrow(uint256 collateralAmount) external onlyAMOMinters {
        // Checks the colIdx of the minter as an additional safety check
        uint256 minterColIdx = IBraxAMOMinter(msg.sender).colIdx();

        // Checks to see if borrowing is paused
        require(borrowingPaused[minterColIdx] == false, "Borrowing is paused");

        // Ensure collateral is enabled
        require(enabledCollaterals[collateralAddresses[minterColIdx]], "Collateral disabled");

        // Transfer
        TransferHelper.safeTransfer(collateralAddresses[minterColIdx], msg.sender, collateralAmount);
    }

    /* ========== RESTRICTED FUNCTIONS, CUSTODIAN CAN CALL TOO ========== */

    /**
     * @notice Toggles the pause status for different functions within the pool
     * @param colIdx Collateral to toggle data for
     * @param togIdx Specific value to toggle
     * @dev togIdx, 0 = mint, 1 = redeem, 2 = buyback, 3 = recollateralize, 4 = borrowing
     */
    function toggleMRBR(uint256 colIdx, uint8 togIdx) external onlyByOwnGovCust {
        require(togIdx <= 4, "Invalid togIdx");
        require(colIdx < collateralAddresses.length, "Invalid collateral");

        if (togIdx == 0) mintPaused[colIdx] = !mintPaused[colIdx];
        else if (togIdx == 1) redeemPaused[colIdx] = !redeemPaused[colIdx];
        else if (togIdx == 2) buyBackPaused[colIdx] = !buyBackPaused[colIdx];
        else if (togIdx == 3) recollateralizePaused[colIdx] = !recollateralizePaused[colIdx];
        else if (togIdx == 4) borrowingPaused[colIdx] = !borrowingPaused[colIdx];

        emit MRBRToggled(colIdx, togIdx);
    }

    /* ========== RESTRICTED FUNCTIONS, GOVERNANCE ONLY ========== */

    /// @notice Add an AMO Minter Address
    /// @param amoMinterAddr Address of the new AMO minter
    function addAMOMinter(address amoMinterAddr) external onlyByOwnGov {
        require(amoMinterAddr != address(0), "Zero address detected");

        // Make sure the AMO Minter has collatBtcBalance()
        uint256 collatValE18 = IBraxAMOMinter(amoMinterAddr).collatBtcBalance();
        require(collatValE18 >= 0, "Invalid AMO");

        amoMinterAddresses[amoMinterAddr] = true;

        emit AMOMinterAdded(amoMinterAddr);
    }

    /// @notice Remove an AMO Minter Address
    /// @param amoMinterAddr Address of the AMO minter to remove
    function removeAMOMinter(address amoMinterAddr) external onlyByOwnGov {
        require(amoMinterAddresses[amoMinterAddr] == true, "Minter not active");

        amoMinterAddresses[amoMinterAddr] = false;
        
        emit AMOMinterRemoved(amoMinterAddr);
    }

    /** 
     * @notice Set the collateral price for a specific collateral
     * @param colIdx Index of the collateral
     * @param newPrice New price of the collateral
     */
    function setCollateralPrice(uint256 colIdx, uint256 newPrice) external onlyByOwnGov validCollateral(colIdx) {
        require(collateralPrices[colIdx] != newPrice, "Same pricing");

        // Only to be used for collateral without chainlink price feed
        // Immediate priorty to get a price feed in place
        collateralPrices[colIdx] = newPrice;

        emit CollateralPriceSet(colIdx, newPrice);
    }

    /**
     * @notice Toggles collateral for use in the pool
     * @param colIdx Index of the collateral to be enabled
     */
    function toggleCollateral(uint256 colIdx) external onlyByOwnGov validCollateral(colIdx) {
        address colAddress = collateralAddresses[colIdx];
        enabledCollaterals[colAddress] = !enabledCollaterals[colAddress];

        emit CollateralToggled(colIdx, enabledCollaterals[colAddress]);
    }

    /**
     * @notice Set the ceiling of collateral allowed for minting
     * @param colIdx Index of the collateral to be modified
     * @param newCeiling New ceiling amount of collateral
     */
    function setPoolCeiling(uint256 colIdx, uint256 newCeiling) external onlyByOwnGov validCollateral(colIdx) {
        require(poolCeilings[colIdx] != newCeiling, "Same ceiling");
        poolCeilings[colIdx] = newCeiling;

        emit PoolCeilingSet(colIdx, newCeiling);
    }

    /**
     * @notice Set the fees of collateral allowed for minting
     * @param colIdx Index of the collateral to be modified
     * @param newMintFee New mint fee for collateral
     * @param newRedeemFee New redemption fee for collateral
     * @param newBuybackFee New buyback fee for collateral
     * @param newRecollatFee New recollateralization fee for collateral
     */
    function setFees(uint256 colIdx, uint256 newMintFee, uint256 newRedeemFee, uint256 newBuybackFee, uint256 newRecollatFee) external onlyByOwnGov validCollateral(colIdx) {
        mintingFee[colIdx] = newMintFee;
        redemptionFee[colIdx] = newRedeemFee;
        buybackFee[colIdx] = newBuybackFee;
        recollatFee[colIdx] = newRecollatFee;

        emit FeesSet(colIdx, newMintFee, newRedeemFee, newBuybackFee, newRecollatFee);
    }

    /**
     * @notice Set the parameters of the pool
     * @param newBonusRate Index of the collateral to be modified
     * @param newRedemptionDelay Number of blocks to wait before being able to collectRedemption()
     */
    function setPoolParameters(uint256 newBonusRate, uint256 newRedemptionDelay) external onlyByOwnGov {
        bonusRate = newBonusRate;
        redemptionDelay = newRedemptionDelay;
        emit PoolParametersSet(newBonusRate, newRedemptionDelay);
    }

    /**
     * @notice Set the price thresholds of the pool, preventing minting or redeeming when trading would be more effective
     * @param newMintPriceThreshold Price at which minting is allowed
     * @param newRedeemPriceThreshold Price at which redemptions are allowed
     */
    function setPriceThresholds(uint256 newMintPriceThreshold, uint256 newRedeemPriceThreshold) external onlyByOwnGov {
        mintPriceThreshold = newMintPriceThreshold;
        redeemPriceThreshold = newRedeemPriceThreshold;
        emit PriceThresholdsSet(newMintPriceThreshold, newRedeemPriceThreshold);
    }

    /**
     * @notice Set the buyback and recollateralization maximum amounts for the pool
     * @param newBbkMaxColE18OutPerHour Maximum amount of collateral per hour to be used for buyback
     * @param newBrctMaxBxsOutPerHour Maximum amount of BXS per hour allowed to be given for recollateralization
     */
    function setBbkRctPerHour(uint256 newBbkMaxColE18OutPerHour, uint256 newBrctMaxBxsOutPerHour) external onlyByOwnGov {
        bbkMaxColE18OutPerHour = newBbkMaxColE18OutPerHour;
        rctMaxBxsOutPerHour = newBrctMaxBxsOutPerHour;
        emit BbkRctPerHourSet(newBbkMaxColE18OutPerHour, newBrctMaxBxsOutPerHour);
    }

    /**
     * @notice Set the chainlink oracles for the pool
     * @param braxBtcChainlinkAddr BRAX / BTC chainlink oracle
     * @param bxsBtcChainlinkAddr BXS / BTC chainlink oracle
     */
    function setOracles(address braxBtcChainlinkAddr, address bxsBtcChainlinkAddr) external onlyByOwnGov {
        // Set the instances
        priceFeedBRAXBTC = AggregatorV3Interface(braxBtcChainlinkAddr);
        priceFeedBXSBTC = AggregatorV3Interface(bxsBtcChainlinkAddr);

        // Set the decimals
        chainlinkBraxBtcDecimals = priceFeedBRAXBTC.decimals();
        require(chainlinkBraxBtcDecimals > 0, "Invalid BRAX Oracle");
        chainlinkBxsBtcDecimals = priceFeedBXSBTC.decimals();
        require(chainlinkBxsBtcDecimals > 0, "Invalid BXS Oracle");
        
        emit OraclesSet(braxBtcChainlinkAddr, bxsBtcChainlinkAddr);
    }

    /**
     * @notice Set the custodian address for the pool
     * @param newCustodian New custodian address
     */
    function setCustodian(address newCustodian) external onlyByOwnGov {
        require(newCustodian != address(0), "Custodian zero address");
        custodianAddress = newCustodian;

        emit CustodianSet(newCustodian);
    }

    /**
     * @notice Set the timelock address for the pool
     * @param newTimelock New timelock address
     */
    function setTimelock(address newTimelock) external onlyByOwnGov {
        require(newTimelock != address(0), "Timelock zero address");
        timelockAddress = newTimelock;

        emit TimelockSet(newTimelock);
    }

    /* ========== EVENTS ========== */
    event CollateralToggled(uint256 colIdx, bool newState);
    event PoolCeilingSet(uint256 colIdx, uint256 newCeiling);
    event FeesSet(uint256 colIdx, uint256 newMintFee, uint256 newRedeemFee, uint256 newBuybackFee, uint256 newRecollatFee);
    event PoolParametersSet(uint256 newBonusRate, uint256 newRedemptionDelay);
    event PriceThresholdsSet(uint256 newBonusRate, uint256 newRedemptionDelay);
    event BbkRctPerHourSet(uint256 bbkMaxColE18OutPerHour, uint256 rctMaxBxsOutPerHour);
    event AMOMinterAdded(address amoMinterAddr);
    event AMOMinterRemoved(address amoMinterAddr);
    event OraclesSet(address braxBtcChainlinkAddr, address bxsBtcChainlinkAddr);
    event CustodianSet(address newCustodian);
    event TimelockSet(address newTimelock);
    event MRBRToggled(uint256 colIdx, uint8 togIdx);
    event CollateralPriceSet(uint256 colIdx, uint256 newPrice);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

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
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.11;

// https://docs.synthetix.io/contracts/Owned
contract Owned {
    address public owner;
    address public nominatedOwner;

    constructor (address _owner) public {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only the contract owner may perform this action");
        _;
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.11;

interface IBxs {
  function DEFAULT_ADMIN_ROLE() external view returns(bytes32);
  function BRAXBtcSynthAdd() external view returns(address);
  function BXS_DAO_MIN() external view returns(uint256);
  function allowance(address owner, address spender) external view returns(uint256);
  function approve(address spender, uint256 amount) external returns(bool);
  function balanceOf(address account) external view returns(uint256);
  function burn(uint256 amount) external;
  function burnFrom(address account, uint256 amount) external;
  function checkpoints(address, uint32) external view returns(uint32 fromBlock, uint96 votes);
  function decimals() external view returns(uint8);
  function decreaseAllowance(address spender, uint256 subtractedValue) external returns(bool);
  function genesisSupply() external view returns(uint256);
  function getCurrentVotes(address account) external view returns(uint96);
  function getPriorVotes(address account, uint256 blockNumber) external view returns(uint96);
  function getRoleAdmin(bytes32 role) external view returns(bytes32);
  function getRoleMember(bytes32 role, uint256 index) external view returns(address);
  function getRoleMemberCount(bytes32 role) external view returns(uint256);
  function grantRole(bytes32 role, address account) external;
  function hasRole(bytes32 role, address account) external view returns(bool);
  function increaseAllowance(address spender, uint256 addedValue) external returns(bool);
  function mint(address to, uint256 amount) external;
  function name() external view returns(string memory);
  function numCheckpoints(address) external view returns(uint32);
  function oracleAddress() external view returns(address);
  function ownerAddress() external view returns(address);
  function poolBurnFrom(address bAddress, uint256 bAmount) external;
  function poolMint(address mAddress, uint256 mAmount) external;
  function renounceRole(bytes32 role, address account) external;
  function revokeRole(bytes32 role, address account) external;
  function setBRAXAddress(address braxContractAddress) external;
  function setBXSMinDAO(uint256 minBXS) external;
  function setOracle(address newOracle) external;
  function setOwner(address _ownerAddress) external;
  function setTimelock(address newTimelock) external;
  function symbol() external view returns(string memory);
  function timelockAddress() external view returns(address);
  function toggleVotes() external;
  function totalSupply() external view returns(uint256);
  function trackingVotes() external view returns(bool);
  function transfer(address recipient, uint256 amount) external returns(bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.11;

interface IBrax {
  function COLLATERAL_RATIO_PAUSER() external view returns (bytes32);
  function DEFAULT_ADMIN_ADDRESS() external view returns (address);
  function DEFAULT_ADMIN_ROLE() external view returns (bytes32);
  function addPool(address poolAddress ) external;
  function allowance(address owner, address spender ) external view returns (uint256);
  function approve(address spender, uint256 amount ) external returns (bool);
  function balanceOf(address account ) external view returns (uint256);
  function burn(uint256 amount ) external;
  function burnFrom(address account, uint256 amount ) external;
  function collateralRatioPaused() external view returns (bool);
  function controllerAddress() external view returns (address);
  function creatorAddress() external view returns (address);
  function decimals() external view returns (uint8);
  function decreaseAllowance(address spender, uint256 subtractedValue ) external returns (bool);
  function wbtcBtcConsumerAddress() external view returns (address);
  function braxWbtcOracleAddress() external view returns (address);
  function braxInfo() external view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256);
  function braxPools(address ) external view returns (bool);
  function braxPoolsArray(uint256 ) external view returns (address);
  function braxPrice() external view returns (uint256);
  function braxStep() external view returns (uint256);
  function bxsAddress() external view returns (address);
  function bxsWbtcOracleAddress() external view returns (address);
  function bxsPrice() external view returns (uint256);
  function genesisSupply() external view returns (uint256);
  function getRoleAdmin(bytes32 role ) external view returns (bytes32);
  function getRoleMember(bytes32 role, uint256 index ) external view returns (address);
  function getRoleMemberCount(bytes32 role ) external view returns (uint256);
  function globalCollateralValue() external view returns (uint256);
  function globalCollateralRatio() external view returns (uint256);
  function grantRole(bytes32 role, address account ) external;
  function hasRole(bytes32 role, address account ) external view returns (bool);
  function increaseAllowance(address spender, uint256 addedValue ) external returns (bool);
  function lastCallTime() external view returns (uint256);
  function mintingFee() external view returns (uint256);
  function name() external view returns (string memory);
  function ownerAddress() external view returns (address);
  function poolBurnFrom(address bAddress, uint256 bAmount ) external;
  function poolMint(address mAddress, uint256 mAmount ) external;
  function priceBand() external view returns (uint256);
  function priceTarget() external view returns (uint256);
  function redemptionFee() external view returns (uint256);
  function refreshCollateralRatio() external;
  function refreshCooldown() external view returns (uint256);
  function removePool(address poolAddress ) external;
  function renounceRole(bytes32 role, address account ) external;
  function revokeRole(bytes32 role, address account ) external;
  function setController(address _controllerAddress ) external;
  function setWBTCBTCOracle(address _wbtcBtcConsumerAddress ) external;
  function setBRAXWBtcOracle(address _brax_oracle_addr, address _wbtcAddress ) external;
  function setBXSAddress(address _bxs_address ) external;
  function setBXSBtcOracle(address _bxsOracleAddr, address _wbtcAddress ) external;
  function setBraxStep(uint256 _newStep ) external;
  function setMintingFee(uint256 minFee ) external;
  function setOwner(address _ownerAddress ) external;
  function setPriceBand(uint256 _priceBand ) external;
  function setPriceTarget(uint256 _newPriceTarget ) external;
  function setRedemptionFee(uint256 redFee ) external;
  function setRefreshCooldown(uint256 _newCooldown ) external;
  function setTimelock(address newTimelock ) external;
  function symbol() external view returns (string memory);
  function timelock_address() external view returns (address);
  function toggleCollateralRatio() external;
  function totalSupply() external view returns (uint256);
  function transfer(address recipient, uint256 amount ) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount ) external returns (bool);
  function wbtcAddress() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.11;

// MAY need to be updated
interface IBraxAMOMinter {
  function BRAX() external view returns(address);
  function BXS() external view returns(address);
  function acceptOwnership() external;
  function addAMO(address amo_address, bool sync_too) external;
  function allAMOAddresses() external view returns(address[] memory);
  function allAMOsLength() external view returns(uint256);
  function amos(address) external view returns(bool);
  function amosArray(uint256) external view returns(address);
  function burnBraxFromAMO(uint256 brax_amount) external;
  function burnBxsFromAMO(uint256 bxs_amount) external;
  function colIdx() external view returns(uint256);
  function collatBtcBalance() external view returns(uint256);
  function collatBtcBalanceStored() external view returns(uint256);
  function collatBorrowCap() external view returns(int256);
  function collatBorrowedBalances(address) external view returns(int256);
  function collatBorrowedSum() external view returns(int256);
  function collateralAddress() external view returns(address);
  function collateralToken() external view returns(address);
  function correctionOffsetsAmos(address, uint256) external view returns(int256);
  function custodianAddress() external view returns(address);
  function btcBalances() external view returns(uint256 brax_val_e18, uint256 collat_val_e18);
  // function execute(address _to, uint256 _value, bytes _data) external returns(bool, bytes);
  function braxBtcBalanceStored() external view returns(uint256);
  function braxTrackedAMO(address amo_address) external view returns(int256);
  function braxTrackedGlobal() external view returns(int256);
  function braxMintBalances(address) external view returns(int256);
  function braxMintCap() external view returns(int256);
  function braxMintSum() external view returns(int256);
  function bxsMintBalances(address) external view returns(int256);
  function bxsMintCap() external view returns(int256);
  function bxsMintSum() external view returns(int256);
  function giveCollatToAMO(address destination_amo, uint256 collat_amount) external;
  function minCr() external view returns(uint256);
  function mintBraxForAMO(address destination_amo, uint256 brax_amount) external;
  function mintBxsForAMO(address destination_amo, uint256 bxs_amount) external;
  function missingDecimals() external view returns(uint256);
  function nominateNewOwner(address _owner) external;
  function nominatedOwner() external view returns(address);
  function oldPoolCollectAndGive(address destination_amo) external;
  function oldPoolRedeem(uint256 brax_amount) external;
  function oldPool() external view returns(address);
  function owner() external view returns(address);
  function pool() external view returns(address);
  function receiveCollatFromAMO(uint256 usdc_amount) external;
  function recoverERC20(address tokenAddress, uint256 tokenAmount) external;
  function removeAMO(address amo_address, bool sync_too) external;
  function setAMOCorrectionOffsets(address amo_address, int256 brax_e18_correction, int256 collat_e18_correction) external;
  function setCollatBorrowCap(uint256 _collat_borrow_cap) external;
  function setCustodian(address _custodian_address) external;
  function setBraxMintCap(uint256 _brax_mint_cap) external;
  function setBraxPool(address _pool_address) external;
  function setBxsMintCap(uint256 _bxs_mint_cap) external;
  function setMinimumCollateralRatio(uint256 _min_cr) external;
  function setTimelock(address new_timelock) external;
  function syncBtcBalances() external;
  function timelockAddress() external view returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

import "../Common/Context.sol";
import "./IERC20.sol";
import "../Math/SafeMath.sol";
import "../Utils/Address.sol";


/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
 
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    
    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory __name, string memory __symbol) public {
        _name = __name;
        _symbol = __symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.approve(address spender, uint256 amount)
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for `accounts`'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }


    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal virtual {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of `from`'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of `from`'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:using-hooks.adoc[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

import "../Common/Context.sol";
import "../Math/SafeMath.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
pragma solidity >=0.6.11 <0.9.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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