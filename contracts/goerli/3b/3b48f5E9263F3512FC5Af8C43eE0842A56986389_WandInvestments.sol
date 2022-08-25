// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./w-IERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./mathFunclib.sol";

//TODO: Change back to WandInvestments
contract WandInvestments is ReentrancyGuard, Ownable {
    //TODO: update
    uint256 public constant SEED_AMOUNT_1 = 9411764706 * 10**12;
    uint256 public constant SEED_AMOUNT_2 = 4470588235 * 10**13;
    uint256 public constant SEED_AMOUNT_3 = 4705882353 * 10**13;
    uint256 public constant SEED_AMOUNT = SEED_AMOUNT_1 + SEED_AMOUNT_2 + SEED_AMOUNT_3;

    uint256 constant DECIMALS = 10**18;
    uint256 constant SECONDS_IN_A_DAY = 60 * 60 * 24;

    // The contract attempts to transfer the stable coins from the SCEPTER_TREASURY_ADDR
    // and the BATON_TREASURY_ADDR address. Therefore, these addresses need to approve
    // this contract spending those coins. Call the `approve` function on the stable
    // coins and supply them with the address of this contract as the `spender` and
    // 115792089237316195423570985008687907853269984665640564039457584007913129639935
    // as the `amount`.
    //TODO: update to correct addresses
    address public constant SCEPTER_TREASURY_ADDR = 0xE9E36a2524b7ea4BE96bB3e11e458704a36d070e;
    address public constant BATON_TREASURY_ADDR = 0xb32e3D54f7b60C719537b2A32736eADf382Cc47f;
    address public constant DEV_WALLET_ADDR = 0x5D8c972231BbA705Bd2148b67C86e7E126B16C74;

    // This contract needs to be allowed to mint and burn the Scepter, Wand, and Baton tokens
    // to and from any address.
    //TODO: update
    IERC20 public constant SPTR = IERC20(0xfEC840Bb3A9aBdF68480d3EEF7f5320379c4C70A);
    IERC20 public constant WAND = IERC20(0x311349046Ba0a7b27F53B5EE2C0cD9dfD4C48074);
    IERC20 public constant BTON = IERC20(0x9401F9f739E0b9Fe67466FeBDeA8D22F0DBfa2d8);

    address public adminDelegator;

    bool public tradingEnabled = false;

    struct WLData {
        uint256 buyLimit;
        uint256 SPTRBought;
    }
    mapping(address => WLData) public whiteListees;

    uint256 public timeLaunched = 0;
    uint256 public daysInCalculation;

    struct ScepterData {
        uint256 sptrGrowthFactor;
        uint256 sptrSellFactor;
        uint256 sptrBackingPrice;
        uint256 sptrSellPrice;
        uint256 sptrBuyPrice;
        uint256 sptrTreasuryBal;
    }
    ScepterData public scepterData;

    struct BatonData {
        uint256 btonBackingPrice;
        uint256 btonRedeemingPrice;
        uint256 btonTreasuryBal;
    }
    BatonData public batonData;

    mapping(uint256 => uint256) public tokensBoughtXDays;
    mapping(uint256 => uint256) public tokensSoldXDays;
    mapping(uint256 => uint256) public circulatingSupplyXDays;
    mapping(uint256 => bool) private setCircSupplyToPreviousDay;

    struct stableTokensParams {
        address contractAddress;
        uint256 tokenDecimals;
    }
    mapping (string => stableTokensParams) public stableERC20Info;

    struct lockedamounts {
        uint256 timeUnlocked;
        uint256 amounts;
    }
    mapping(address => lockedamounts) public withheldWithdrawals;

    mapping(address => uint256) public initialTimeHeld;
    mapping(address => uint256) public timeSold;

    struct btonsLocked {
        uint256 timeInit;
        uint256 amounts;
    }
    mapping(address => btonsLocked) public btonHoldings;

    event sceptersBought(address indexed _from, uint256 _amount);
    event sceptersSold(address indexed _from, uint256 _amount);

    constructor() {
        // Multisig address is the contract owner.
        //TODO: update owner and adminDelegator
        _transferOwnership(0x00719601bD4d4755B04992a02bc2809bF2D11F8a);
        adminDelegator = 0x1f174b307FB42B221454328EDE7bcA7De841a991; 

        //TODO: update BUSD contract address to 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56
        stableERC20Info["BUSD"].contractAddress = 0xA7132A1CA713c51454aAbfA948070e1aC33BBd42;
        stableERC20Info["BUSD"].tokenDecimals = 18;

        //TODO: update USDC contract address to 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d
        stableERC20Info["USDC"].contractAddress = 0x233406c3e4dc19B2F08341A1e77485b9e4B3936d;
        stableERC20Info["USDC"].tokenDecimals = 18;

        stableERC20Info["DAI"].contractAddress = 0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3;
        stableERC20Info["DAI"].tokenDecimals = 18;

        stableERC20Info["FRAX"].contractAddress = 0x90C97F71E18723b0Cf0dfa30ee176Ab653E89F40;
        stableERC20Info["FRAX"].tokenDecimals = 18;
    }

    function setCirculatingSupplyXDaysToPrevious(uint256 dInArray) private returns (uint256) {
        if (setCircSupplyToPreviousDay[dInArray]) {
            return circulatingSupplyXDays[dInArray];
        }
        setCircSupplyToPreviousDay[dInArray] = true;
        circulatingSupplyXDays[dInArray] = setCirculatingSupplyXDaysToPrevious(dInArray - 1);
        return circulatingSupplyXDays[dInArray];
    }

    function cashOutScepter(
        uint256 amountSPTRtoSell,
        uint256 daysChosenLocked,
        string calldata stableChosen
    )
        external nonReentrant
    {
        require(tradingEnabled, "Disabled");
        require(SPTR.balanceOf(msg.sender) >= amountSPTRtoSell, "You dont have that amount!");
        require(daysChosenLocked < 10, "You can only lock for a max of 9 days");

        uint256 usdAmt = mathFuncs.decMul18(
            mathFuncs.decMul18(scepterData.sptrSellPrice, amountSPTRtoSell),
            mathFuncs.decDiv18((daysChosenLocked + 1) * 10, 100)
        );

        require(usdAmt > 0, "Not enough tokens swapped");

        uint256 dInArray = (block.timestamp - timeLaunched) / SECONDS_IN_A_DAY;
        tokensSoldXDays[dInArray] += amountSPTRtoSell;
        setCirculatingSupplyXDaysToPrevious(dInArray);
        circulatingSupplyXDays[dInArray] -= amountSPTRtoSell;

        WAND.burn(SCEPTER_TREASURY_ADDR, amountSPTRtoSell);
        SPTR.burn(msg.sender, amountSPTRtoSell);

        if (daysChosenLocked == 0) {
            require(stableERC20Info[stableChosen].contractAddress != address(0), "Unsupported stable coin");
            IERC20 tokenStable = IERC20(stableERC20Info[stableChosen].contractAddress);

            uint256 usdAmtTrf = usdAmt / 10**(18 - stableERC20Info[stableChosen].tokenDecimals);
            uint256 usdAmtToUser = mathFuncs.decMul18(usdAmtTrf, mathFuncs.decDiv18(95, 100));

            require(usdAmtToUser > 0, "Not enough tokens swapped");

            scepterData.sptrTreasuryBal -= usdAmt;

            _safeTransferFrom(tokenStable, SCEPTER_TREASURY_ADDR, msg.sender, usdAmtToUser);
            _safeTransferFrom(tokenStable, SCEPTER_TREASURY_ADDR, DEV_WALLET_ADDR, usdAmtTrf - usdAmtToUser);
        } else {
            if (withheldWithdrawals[msg.sender].timeUnlocked == 0) {
                withheldWithdrawals[msg.sender].amounts = usdAmt;
                withheldWithdrawals[msg.sender].timeUnlocked =
                    block.timestamp + (daysChosenLocked * SECONDS_IN_A_DAY);
            } else {
                withheldWithdrawals[msg.sender].amounts += usdAmt;
                if (block.timestamp < withheldWithdrawals[msg.sender].timeUnlocked) {
                    withheldWithdrawals[msg.sender].timeUnlocked += (daysChosenLocked * SECONDS_IN_A_DAY);
                } else {
                    withheldWithdrawals[msg.sender].timeUnlocked =
                        block.timestamp + (daysChosenLocked * SECONDS_IN_A_DAY);
                }
            }
        }

        calcSPTRData();

        timeSold[msg.sender] = block.timestamp;
        if (SPTR.balanceOf(msg.sender) == 0 && BTON.balanceOf(msg.sender) == 0) {
            initialTimeHeld[msg.sender] = 0;
        }

        emit sceptersSold(msg.sender, amountSPTRtoSell);
    }

    function cashOutBaton(uint256 amountBTONtoSell, string calldata stableChosen) external nonReentrant {
        require(tradingEnabled, "Disabled");
        require(BTON.balanceOf(msg.sender) >= amountBTONtoSell, "You dont have that amount!");
        require(stableERC20Info[stableChosen].contractAddress != address(0), "Unsupported stable coin");

        IERC20 tokenStable = IERC20(stableERC20Info[stableChosen].contractAddress);
        uint256 usdAmt = mathFuncs.decMul18(batonData.btonRedeemingPrice, amountBTONtoSell);
        uint256 usdAmtTrf = usdAmt / 10**(18 - stableERC20Info[stableChosen].tokenDecimals);

        require(usdAmtTrf > 0, "Not enough tokens swapped");

        batonData.btonTreasuryBal -= usdAmt;

        btonHoldings[msg.sender].timeInit = block.timestamp;
        btonHoldings[msg.sender].amounts -= amountBTONtoSell;

        BTON.burn(msg.sender, amountBTONtoSell);
        _safeTransferFrom(tokenStable, BATON_TREASURY_ADDR, msg.sender, usdAmtTrf);

        calcBTONData();

        timeSold[msg.sender] = block.timestamp;
        if (SPTR.balanceOf(msg.sender) == 0 && BTON.balanceOf(msg.sender) == 0) {
            initialTimeHeld[msg.sender] = 0;
        }
    }

    function transformScepterToBaton(uint256 amountSPTRtoSwap, string calldata stableChosen) external nonReentrant {
        require(tradingEnabled, "Disabled");
        require(SPTR.balanceOf(msg.sender) >= amountSPTRtoSwap, "You dont have that amount!");
        require(stableERC20Info[stableChosen].contractAddress != address(0), "Unsupported stable coin");

        uint256 btonTreaAmtTrf = mathFuncs.decMul18(
            mathFuncs.decMul18(scepterData.sptrBackingPrice, amountSPTRtoSwap),
            mathFuncs.decDiv18(9, 10)
        );

        uint256 toTrf = btonTreaAmtTrf / 10**(18 - stableERC20Info[stableChosen].tokenDecimals);

        require(toTrf > 0, "Not enough tokens swapped");

        IERC20 tokenStable = IERC20(stableERC20Info[stableChosen].contractAddress);

        uint256 dInArray = (block.timestamp - timeLaunched) / SECONDS_IN_A_DAY;
        tokensSoldXDays[dInArray] += amountSPTRtoSwap;
        setCirculatingSupplyXDaysToPrevious(dInArray);
        circulatingSupplyXDays[dInArray] -= amountSPTRtoSwap;

        scepterData.sptrTreasuryBal -= btonTreaAmtTrf;

        batonData.btonTreasuryBal += btonTreaAmtTrf;

        btonHoldings[msg.sender].timeInit = block.timestamp;
        btonHoldings[msg.sender].amounts += amountSPTRtoSwap;

        WAND.burn(SCEPTER_TREASURY_ADDR, amountSPTRtoSwap);
        SPTR.burn(msg.sender, amountSPTRtoSwap);
        BTON.mint(msg.sender, amountSPTRtoSwap);
        calcSPTRData();
        calcBTONData();
        _safeTransferFrom(tokenStable, SCEPTER_TREASURY_ADDR, BATON_TREASURY_ADDR, toTrf);
    }

    function buyScepter(uint256 amountSPTRtoBuy, string calldata stableChosen) external nonReentrant {
        require(tradingEnabled, "Disabled");
        require(timeLaunched != 0 && block.timestamp > timeLaunched + 172800, "Not launched for public.");
        require(amountSPTRtoBuy <= 250000 * DECIMALS , "Per transaction limit");
        require(stableERC20Info[stableChosen].contractAddress != address(0), "Unsupported stable coin");

        IERC20 tokenStable = IERC20(stableERC20Info[stableChosen].contractAddress);

        uint256 usdAmt = mathFuncs.decMul18(amountSPTRtoBuy, scepterData.sptrBuyPrice);
        uint256 usdAmtToPay = usdAmt / 10**(18 - stableERC20Info[stableChosen].tokenDecimals);

        require(tokenStable.balanceOf(msg.sender) >= usdAmtToPay, "You dont have that amount!");

        uint256 dInArray = (block.timestamp - timeLaunched) / SECONDS_IN_A_DAY;
        tokensBoughtXDays[dInArray] += amountSPTRtoBuy;
        setCirculatingSupplyXDaysToPrevious(dInArray);
        circulatingSupplyXDays[dInArray] += amountSPTRtoBuy;

        scepterData.sptrTreasuryBal += mathFuncs.decMul18(usdAmt, mathFuncs.decDiv18(95, 100));

        uint256 usdAmtToTreasury = mathFuncs.decMul18(usdAmtToPay, mathFuncs.decDiv18(95, 100));

        require(usdAmtToTreasury > 0, "Not enough tokens swapped");

        _safeTransferFrom(tokenStable, msg.sender, SCEPTER_TREASURY_ADDR, usdAmtToTreasury);
        _safeTransferFrom(tokenStable, msg.sender, DEV_WALLET_ADDR, usdAmtToPay - usdAmtToTreasury);

        SPTR.mint(msg.sender, amountSPTRtoBuy);
        WAND.mint(SCEPTER_TREASURY_ADDR, amountSPTRtoBuy);
        calcSPTRData();

        if (initialTimeHeld[msg.sender] == 0) {
            initialTimeHeld[msg.sender] = block.timestamp;
        }

        emit sceptersBought(msg.sender, amountSPTRtoBuy);
    }

    function wlBuyScepter(uint256 amountSPTRtoBuy, string calldata stableChosen) external nonReentrant {
        require(tradingEnabled, "Disabled");
        require(block.timestamp <= timeLaunched + 172800, "WL Sale closed");
        require(whiteListees[msg.sender].SPTRBought + amountSPTRtoBuy <= whiteListees[msg.sender].buyLimit, "Hit Limit");
        require(stableERC20Info[stableChosen].contractAddress != address(0), "Unsupported stable coin");

        IERC20 tokenStable = IERC20(stableERC20Info[stableChosen].contractAddress);

        uint256 usdAmt = amountSPTRtoBuy;
        uint256 usdAmtToPay = usdAmt / 10**(18 - stableERC20Info[stableChosen].tokenDecimals);
        require(tokenStable.balanceOf(msg.sender) >= usdAmtToPay, "You dont have that amount!");

        uint256 dInArray = (block.timestamp - timeLaunched) / SECONDS_IN_A_DAY;
        tokensBoughtXDays[dInArray] += amountSPTRtoBuy;
        setCirculatingSupplyXDaysToPrevious(dInArray);
        circulatingSupplyXDays[dInArray] += amountSPTRtoBuy;

        scepterData.sptrTreasuryBal += mathFuncs.decMul18(usdAmt, mathFuncs.decDiv18(95, 100));

        uint256 usdAmtToTreasury = mathFuncs.decMul18(usdAmtToPay, mathFuncs.decDiv18(95, 100));

        require(usdAmtToTreasury > 0, "Not enough tokens swapped");

        //_safeTransferFrom(tokenStable, msg.sender, SCEPTER_TREASURY_ADDR, usdAmtToTreasury);
        //_safeTransferFrom(tokenStable, msg.sender, DEV_WALLET_ADDR, usdAmtToPay - usdAmtToTreasury);

        whiteListees[msg.sender].SPTRBought += amountSPTRtoBuy;

        SPTR.mint(msg.sender, amountSPTRtoBuy);
        WAND.mint(SCEPTER_TREASURY_ADDR, amountSPTRtoBuy);
        calcSPTRData();

        if (initialTimeHeld[msg.sender] == 0) {
            initialTimeHeld[msg.sender] = block.timestamp;
        }

        emit sceptersBought(msg.sender, amountSPTRtoBuy);
    }

    function claimLockedUSD(string calldata stableChosen) external nonReentrant {
        require(tradingEnabled, "Disabled");
        require(withheldWithdrawals[msg.sender].timeUnlocked != 0, "No locked funds to claim");
        require(block.timestamp >= withheldWithdrawals[msg.sender].timeUnlocked, "Not unlocked");
        require(stableERC20Info[stableChosen].contractAddress != address(0), "Unsupported stable coin");

        IERC20 tokenStable = IERC20(stableERC20Info[stableChosen].contractAddress);

        uint256 claimAmts =
            withheldWithdrawals[msg.sender].amounts /
            10**(18 - stableERC20Info[stableChosen].tokenDecimals);
        uint256 amtToUser = mathFuncs.decMul18(claimAmts, mathFuncs.decDiv18(95, 100));

        scepterData.sptrTreasuryBal -= withheldWithdrawals[msg.sender].amounts;
        calcSPTRData();

        delete withheldWithdrawals[msg.sender];
        _safeTransferFrom(tokenStable, SCEPTER_TREASURY_ADDR, msg.sender, amtToUser);
        _safeTransferFrom(tokenStable, SCEPTER_TREASURY_ADDR, DEV_WALLET_ADDR, claimAmts - amtToUser);
    }

    function getCircSupplyXDays() public view returns (uint256) {
        if (timeLaunched == 0) return SEED_AMOUNT;
        uint256 daySinceLaunched = (block.timestamp - timeLaunched) / SECONDS_IN_A_DAY;
        uint256 numdays = daysInCalculation / SECONDS_IN_A_DAY;
        if (daySinceLaunched < numdays) {
            return SEED_AMOUNT;
        }
        for (uint d = daySinceLaunched - numdays; d > 0; d--) {
            if (setCircSupplyToPreviousDay[d]) {
                return circulatingSupplyXDays[d];
            }
        }
        return circulatingSupplyXDays[0];
    }

    function calcBTONData() private {
        // Total supply will be guaranteed to not fall to 0 by sending Baton tokens
        // to a dead address. Initially before any Baton tokens are minted, the values
        // produced by this function are irrelevant.
        if (BTON.totalSupply() == 0) { 
            batonData.btonBackingPrice = DECIMALS;
        } else {
            batonData.btonBackingPrice = mathFuncs.decDiv18(batonData.btonTreasuryBal, BTON.totalSupply());
        }
        uint256 btonPrice = mathFuncs.decMul18(batonData.btonBackingPrice, mathFuncs.decDiv18(30, 100));
        uint256 sptrPriceHalf = scepterData.sptrBackingPrice / 2;
        if (btonPrice > sptrPriceHalf) {
            batonData.btonRedeemingPrice = sptrPriceHalf;
        } else {
            batonData.btonRedeemingPrice = btonPrice;
        }
    }

    function calcSPTRData() private {
        if (getCircSupplyXDays() == 0) {
            scepterData.sptrGrowthFactor = 3 * 10**17;
        } else {
            scepterData.sptrGrowthFactor =
                2 * (mathFuncs.decDiv18(getTokensBoughtXDays(), getCircSupplyXDays()));
        }
        if (scepterData.sptrGrowthFactor > 3 * 10**17) {
            scepterData.sptrGrowthFactor = 3 * 10**17;
        }

        if (getCircSupplyXDays() == 0) {
            scepterData.sptrSellFactor = 3 * 10**17;
        } else {
            scepterData.sptrSellFactor =
                2 * (mathFuncs.decDiv18(getTokensSoldXDays(), getCircSupplyXDays()));
        }
        if (scepterData.sptrSellFactor > 3 * 10**17) {
           scepterData.sptrSellFactor = 3 * 10**17;
        }

        // Total supply will be guaranteed to not fall to 0 by sending Scepter tokens
        // to a dead address.
        if (SPTR.totalSupply() == 0) {
            scepterData.sptrBackingPrice = DECIMALS;
        } else {
            scepterData.sptrBackingPrice =
                mathFuncs.decDiv18(scepterData.sptrTreasuryBal, SPTR.totalSupply());
        }

        scepterData.sptrBuyPrice = mathFuncs.decMul18(
            scepterData.sptrBackingPrice,
            12 * 10**17 + scepterData.sptrGrowthFactor
        );
        scepterData.sptrSellPrice = mathFuncs.decMul18(
            scepterData.sptrBackingPrice,
            9 * 10**17 - scepterData.sptrSellFactor
        );
    }

    function getTokensBoughtXDays() public view returns (uint256) {
        if (timeLaunched == 0) return tokensBoughtXDays[0];

        uint256 boughtCount = 0;
        uint d = 0;
        uint256 numdays = daysInCalculation / SECONDS_IN_A_DAY;
        uint256 daySinceLaunched = (block.timestamp - timeLaunched) / SECONDS_IN_A_DAY;

        if (daySinceLaunched > numdays) {
            d = daySinceLaunched - numdays;
        }
        for (; d <= daySinceLaunched; d++) {
            boughtCount += tokensBoughtXDays[d];
        }
        return boughtCount;
    }

    function getTokensSoldXDays() public view returns (uint256) {
        if (timeLaunched == 0) return tokensSoldXDays[0];

        uint256 soldCount = 0;
        uint256 d;
        uint256 numdays = daysInCalculation / SECONDS_IN_A_DAY;
        uint256 daySinceLaunched = (block.timestamp - timeLaunched) / SECONDS_IN_A_DAY;

        if (daySinceLaunched > numdays) {
            d = daySinceLaunched - numdays;
        }
        for (; d <= daySinceLaunched; d++) {  
            soldCount += tokensSoldXDays[d];
        }
        return soldCount;
    }

    function turnOnOffTrading(bool value) external onlyOwner {
        tradingEnabled = value;
    }

    function updateSPTRTreasuryBal(uint256 totalAmt) external {
        require(msg.sender == adminDelegator, "Not Delegated to call."); 
        scepterData.sptrTreasuryBal = totalAmt * DECIMALS;
        calcSPTRData();
    }

    function updateDelegator(address newAddress) external onlyOwner {
        adminDelegator = newAddress;
    }

    function addOrSubFromSPTRTreasuryBal(int256 amount) external onlyOwner {
        if (amount < 0) {
            scepterData.sptrTreasuryBal -= uint256(-amount) * DECIMALS;
        } else {
            scepterData.sptrTreasuryBal += uint256(amount) * DECIMALS;
        }
        calcSPTRData();
    }

    function updateBTONTreasuryBal(uint256 totalAmt) external {
        require(msg.sender == adminDelegator, "Not Delegated to call."); 
        batonData.btonTreasuryBal = totalAmt * DECIMALS;
        calcBTONData();
    }

    function Launch() external onlyOwner {
        require(timeLaunched == 0, "Already Launched");
        timeLaunched = block.timestamp;
        daysInCalculation = 5 days;
        //TODO: update
        SPTR.mint(0xEF4503dD3768CB4CE1Be12F56b3ee4c7E6a5E3ec, SEED_AMOUNT_1); //seed 1
        SPTR.mint(0x90C66d0401d75A6d3b4f46cbA5F4230EE00D7f71, SEED_AMOUNT_2); //seed 2
        SPTR.mint(0xac80056C1A76736111706496F4E4634726Eebb89, SEED_AMOUNT_3); //seed 3

        WAND.mint(SCEPTER_TREASURY_ADDR, SEED_AMOUNT);

        tokensBoughtXDays[0] = SEED_AMOUNT;
        circulatingSupplyXDays[0] = SEED_AMOUNT;
        setCircSupplyToPreviousDay[0] = true;
        scepterData.sptrTreasuryBal = 86000 * DECIMALS; //TODO: update
        batonData.btonTreasuryBal = 0;
        calcSPTRData();
        tradingEnabled = true;

    }

    function setDaysUsedInFactors(uint256 numDays) external onlyOwner {
        daysInCalculation = numDays * SECONDS_IN_A_DAY;
    }

    function addWhitelistee(uint listNum, address[] memory addr) external {
        require(msg.sender == adminDelegator, "Not Delegated to call.");
        require(listNum >= 1 && listNum <= 3, "listNum has to be 1, 2, or 3.");
        if (listNum == 1) {
            listNum = 2000 * DECIMALS;
        } else if (listNum == 2) {
            listNum = 1500 * DECIMALS;
        } else {
            listNum = 1000 * DECIMALS;
        }
        for (uint256 i = 0; i < addr.length; i++) {
            whiteListees[addr[i]].buyLimit = listNum;
            whiteListees[addr[i]].SPTRBought = 0;
        }
    }

    function addStable(string calldata ticker, address addr, uint256 dec) external onlyOwner {
        stableERC20Info[ticker].contractAddress = addr;
        stableERC20Info[ticker].tokenDecimals = dec;
    }

    function _safeTransferFrom(
        IERC20 token,
        address sender,
        address recipient,
        uint256 amount
    )
        private
    {
        require(token.transferFrom(sender, recipient, amount), "Token transfer failed");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /*
    *Customised 
    */
    function mint(address addrTo, uint256 amount) external;
    function burn(address addrFrom, uint256 amount) external;
    //function scepterTotalSupply() public view virtual returns (uint256);
    //function transferFrom(address addrTo, uint256 amount) external ;
    /*
    *End Customised 
    */

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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

    constructor() {
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
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

library mathFuncs {
    uint constant DECIMALS = 10**18; 

    function decMul18(uint x, uint y) internal pure returns (uint decProd) {
        decProd = x * y / DECIMALS;
    }

    function decDiv18(uint x, uint y) internal pure returns (uint decQuotient) {
        require(y != 0, "Division by zero");
        decQuotient = x * DECIMALS / y;
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