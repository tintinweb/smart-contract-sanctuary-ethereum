// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.7;
pragma experimental ABIEncoderV2;

// settings for core deployments
abstract contract Config {
    // external addresses
    address internal constant ETH_FROM = 0xe75B8A5Ba47ca7458Cbc4dB1dD52df5E2ebC42Cf;
    address internal constant GEB_MULTISIG = 0x336281cB29D22914242edFC4467E1f458FB378c7;
    address internal constant MULTICALL = address(0);
    address internal constant PROXY_ACTIONS = 0x8fEB9Cd2f09c8Bb7be283EECa2EA48b9706F13cc;
    address internal constant PROXY_ACTIONS_INCENTIVES = 0x4D3c1634Cd241B90EbE60107c16842E5d30716f5;
    address internal constant WETH = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
    address internal constant UNIV3_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address internal constant BUNNI_FACTORY = 0xb5087F95643A9a4069471A28d32C569D9bd57fE4;

    // testnet - will deploy tokens for collaterals if true. Owner of tokens will remain the EOA used to create them (will not be transferred to pause.proxy())
    bool internal constant IS_TESTNET = true;

    // pause
    uint256 internal constant PAUSE_DELAY = 0;

    // protocol token
    string internal constant PROTOCOL_TOKEN_NAME = "RATE governance token";
    string internal constant PROTOCOL_TOKEN_SYMBOL = "RATE";
    uint internal constant PROTOCOL_TOKEN_SUPPLY = 1000000 ether;

    // coin
    string internal constant SYSTEM_COIN_NAME = "TAI reflex index";
    string internal constant SYSTEM_COIN_SYMBOL = "TAI";
    uint internal constant INITIAL_COIN_PRICE = 1 ether;

    // DSR
    bool internal constant DEPLOY_DSR = false;

    // Safe engine
    uint internal constant GLOBAL_DEBT_CEILING = uint(-1);
    // debt rewards
    uint internal constant DEBT_REWARDS = 50000 ether;
    uint internal constant DEBT_REWARD_PER_BLOCK = 1 ether;

    // Accounting Engine
    uint internal constant SURPLUS_AUCTION_AMOUNT_TO_SELL = 23539750823574720783752937941325000000000000000000;
    uint internal constant SURPLUS_BUFFER = 500000000000000000000000000000000000000000000000000;

    // SF treasury
    uint internal constant TREASURY_CAPACITY = 50000 *10**45;

    // Auction houses
    bytes32 internal constant SURPLUS_AUCTION_HOUSE_TYPE = "mixed";
    address internal constant SURPLUS_AUCTION_RECEIVER = address(0x1); // receives proceeds from surplus auctions on recycling and mixedStrat

    // ESM
    uint internal constant ESM_THRESHOLD = 20000 ether;
    uint internal constant ESM_MIN_AMOUNT_TO_BURN = 10000 ether;
    uint internal constant ESM_SUPPLY_PERCENTAGE_TO_BURN = 100; // 10%

    // Controller
    bytes32 internal constant CONTROLLER_TYPE = "new"; // raw, scaled, or new. PI always used
    int256 internal constant CONTROLLER_KP = 0;
    int256 internal constant CONTROLLER_KI = 0;
    int256 internal constant CONTROLLER_BIAS = 0;
    uint256 internal constant CONTROLLER_PSCL = 1000000000000000000000000000;
    uint256 internal constant CONTROLLER_IPS = 3600;
    uint256 internal constant CONTROLLER_NB = 1000000000000000000;
    uint256 internal constant CONTROLLER_FOUB = 1000000000000000000000000000000000000000000000;
    int256 internal constant CONTROLLER_FOLB = -999999999999999999999999999;
    int256[] internal CONTROLLER_IMPORTED_STATE = new int256[](5); // clean state

    // Controller setter
    uint256 internal constant CONTROLLER_SETTER_UPDATE_DELAY = 3600;
    uint256 internal constant CONTROLLER_SETTER_BASE_UPDATE_CALLER_REWARD = 100;
    uint256 internal constant CONTROLLER_SETTER_MAX_UPDATE_CALLER_REWARD = 200;
    uint256 internal constant CONTROLLER_SETTER_PER_SECOND_REWARD_INCREASE = 1000000000000000000000000000; // no increase
    uint256 internal constant CONTROLLER_SETTER_RELAY_DELAY = 3600;
    uint256 internal constant CONTROLLER_SETTER_RELAYER_MAX_REWARD_INCREASE_DELAY = 6 hours;

    // Collateral  oracle reward params
    uint256 internal constant ORACLE_BASE_CALLER_REWARD = 100;
    uint256 internal constant ORACLE_MAX_CALLER_REWARD = 200;
    uint256 internal constant ORACLE_PERIOD_SIZE = 2600;
    uint256 internal constant ORACLE_REWARD_INCREASE = 1000000000000000000000000000;
    uint256 internal constant ORACLE_REWARD_INCREASE_TIMELINE = 3600;
    uint256 internal constant ORACLE_MAX_REWARD_INCREASE_DELAY = 6 hours;

    // Debt Popper Rewards
    uint256 internal immutable POPPER_REWARDS_REWARD_PERIOD_START;
    uint256 internal constant POPPER_REWARDS_INTER_PERIOD_DELAY = 1209600;
    uint256 internal constant POPPER_REWARDS_REWARD_TIMELINE = 4838400;
    uint256 internal constant POPPER_REWARDS_FIXED_REWARD = 8068940976438182549;
    uint256 internal constant POPPER_REWARDS_MAX_PER_PERIOD_POPS = 50;
    uint256 internal constant POPPER_REWARDS_REWARD_START_TIME = 1620766800;

    // Liqiudity Incentives
    uint24  internal constant UNI_V3_FEE = 3000;
    int24   internal constant BUNNI_POSITION_TICK_LOWER = int24(0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2761a);
    int24   internal constant BUNNI_POSITION_TICK_UPPER = int24(0x00000000000000000000000000000000000000000000000000000000000d89e6);
    uint    internal constant LIQUIDITY_REWARDS = 50000 ether;
    uint    internal constant LIQUIDITY_REWARD_PER_BLOCK = 1 ether;    


    constructor() public {
        // setting deploy time vars here
        POPPER_REWARDS_REWARD_PERIOD_START = block.timestamp + 10 days;
    }
}

// // SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.7;

import "./Config.sol";
import "./Utils.sol";

abstract contract AuctionHouseLike {
    function AUCTION_TYPE() external virtual returns (bytes32);
}

abstract contract Setter {
    function updateResult(uint256) external virtual;

    function addAuthorization(address) external virtual;

    function removeAuthorization(address) external virtual;

    function removeAuthority(address) external virtual;

    function setAuthority(address) external virtual;

    function setOwner(address) external virtual;

    function setDelay(uint256) external virtual;

    function modifyParameters(bytes32, address) external virtual;

    function modifyParameters(
        bytes32,
        bytes32,
        address
    ) external virtual;

    function modifyParameters(bytes32, uint256) external virtual;

    function modifyParameters(
        bytes32,
        bytes32,
        uint256
    ) external virtual;

    function setPerBlockAllowance(address, uint256) external virtual;

    function setTotalAllowance(address, uint256) external virtual;

    function initializeCollateralType(bytes32) external virtual;

    function updateCollateralPrice(bytes32) external virtual;

    function updateRate(address) external virtual;
}

contract Setup is Config {
    Setter internal immutable coin;
    Setter internal immutable coinJoin;
    Setter internal immutable coinOracle;
    Setter internal immutable oracleRelayer;
    Setter internal immutable safeEngine;
    Setter internal immutable taxCollector;
    Setter internal immutable coinSavingsAccount;
    Setter internal immutable surplusAuctionHouse;
    Setter internal immutable debtAuctionHouse;
    Setter internal immutable accountingEngine;
    Setter internal immutable liquidationEngine;
    Setter internal immutable stabilityFeeTreasury;
    Setter internal immutable globalSettlement;
    Setter internal immutable esm;
    Setter internal immutable rateCalculator;
    Setter internal immutable rateSetter;
    Setter internal immutable rateSetterRelayer;
    Setter internal immutable pause;
    Setter internal immutable protocolTokenAuthority;
    Setter internal immutable prot;
    Setter internal immutable debtPopperRewards;
    Setter internal immutable debtRewards;
    Setter internal immutable debtRewardsDripper;
    Setter internal immutable liquidityRewards;
    Setter internal immutable liquidityRewardsDripper;

    constructor(address[] memory addresses) public {
        coin = Setter(addresses[0]);
        coinJoin = Setter(addresses[1]);
        coinOracle = Setter(addresses[2]);
        oracleRelayer = Setter(addresses[3]);
        safeEngine = Setter(addresses[4]);
        taxCollector = Setter(addresses[5]);
        coinSavingsAccount = Setter(addresses[6]);
        surplusAuctionHouse = Setter(addresses[7]);
        debtAuctionHouse = Setter(addresses[8]);
        accountingEngine = Setter(addresses[9]);
        liquidationEngine = Setter(addresses[10]);
        stabilityFeeTreasury = Setter(addresses[11]);
        globalSettlement = Setter(addresses[12]);
        esm = Setter(addresses[13]);
        rateCalculator = Setter(addresses[14]);
        rateSetter = Setter(addresses[15]);
        rateSetterRelayer = Setter(addresses[16]);
        pause = Setter(addresses[17]);
        protocolTokenAuthority = Setter(addresses[18]);
        prot = Setter(addresses[19]);
        debtPopperRewards = Setter(addresses[20]);
        debtRewards = Setter(addresses[21]);
        debtRewardsDripper = Setter(addresses[22]);
        liquidityRewards = Setter(addresses[23]);
        liquidityRewardsDripper = Setter(addresses[24]);
    }

    function setup() external {
        // prot
        prot.setAuthority(address(protocolTokenAuthority));

        protocolTokenAuthority.addAuthorization(address(debtAuctionHouse));
        protocolTokenAuthority.addAuthorization(address(surplusAuctionHouse));

        // coin oracle
        coinOracle.updateResult(INITIAL_COIN_PRICE);

        // safeEngine
        safeEngine.modifyParameters("globalDebtCeiling", GLOBAL_DEBT_CEILING);

        if (DEBT_REWARDS > 0) {
            safeEngine.modifyParameters("rewards", address(debtRewards));
            debtRewardsDripper.modifyParameters(
                "requestor",
                address(debtRewards)
            );
        }

        oracleRelayer.modifyParameters(
            "redemptionPrice",
            INITIAL_COIN_PRICE * 10**9
        );

        // coin
        coin.addAuthorization(address(coinJoin));

        // taxation
        safeEngine.addAuthorization(address(taxCollector));
        taxCollector.modifyParameters(
            "primaryTaxReceiver",
            address(stabilityFeeTreasury)
        ); // stability fee treasury will accumulate, anything over treasury capacity is sent to accounting engine (surplus buffer)
        stabilityFeeTreasury.modifyParameters(
            "treasuryCapacity",
            TREASURY_CAPACITY
        );

        // dsr
        if (DEPLOY_DSR) {
            safeEngine.addAuthorization(address(coinSavingsAccount));
        }

        // auction setup
        if (
            (SURPLUS_AUCTION_HOUSE_TYPE == "recycling" ||
                SURPLUS_AUCTION_HOUSE_TYPE == "mixed") &&
            SURPLUS_AUCTION_RECEIVER != address(0)
        ) {
            surplusAuctionHouse.modifyParameters(
                "protocolTokenBidReceiver",
                SURPLUS_AUCTION_RECEIVER
            );
        }

        safeEngine.addAuthorization(address(debtAuctionHouse));

        // accounting engine
        debtAuctionHouse.modifyParameters(
            "accountingEngine",
            address(accountingEngine)
        );
        surplusAuctionHouse.addAuthorization(address(accountingEngine));
        debtAuctionHouse.addAuthorization(address(accountingEngine));

        accountingEngine.modifyParameters(
            "protocolTokenAuthority",
            address(protocolTokenAuthority)
        );
        accountingEngine.modifyParameters(
            "surplusAuctionAmountToSell",
            SURPLUS_AUCTION_AMOUNT_TO_SELL
        );
        accountingEngine.modifyParameters("surplusBuffer", SURPLUS_BUFFER);

        // liquidation engine
        liquidationEngine.modifyParameters(
            "accountingEngine",
            address(accountingEngine)
        );
        safeEngine.addAuthorization(address(liquidationEngine));
        accountingEngine.addAuthorization(address(liquidationEngine));

        // global settlement
        globalSettlement.modifyParameters("safeEngine", address(safeEngine));
        globalSettlement.modifyParameters(
            "liquidationEngine",
            address(liquidationEngine)
        );
        globalSettlement.modifyParameters(
            "accountingEngine",
            address(accountingEngine)
        );
        globalSettlement.modifyParameters(
            "oracleRelayer",
            address(oracleRelayer)
        );
        if (address(coinSavingsAccount) != address(0)) {
            globalSettlement.modifyParameters(
                "coinSavingsAccount",
                address(coinSavingsAccount)
            );
        }
        if (address(stabilityFeeTreasury) != address(0)) {
            globalSettlement.modifyParameters(
                "stabilityFeeTreasury",
                address(stabilityFeeTreasury)
            );
        }

        safeEngine.addAuthorization(address(globalSettlement));
        liquidationEngine.addAuthorization(address(globalSettlement));
        accountingEngine.addAuthorization(address(globalSettlement));
        oracleRelayer.addAuthorization(address(globalSettlement));
        if (address(coinSavingsAccount) != address(0)) {
            coinSavingsAccount.addAuthorization(address(globalSettlement));
        }
        if (address(stabilityFeeTreasury) != address(0)) {
            stabilityFeeTreasury.addAuthorization(address(globalSettlement));
        }

        // ESM
        globalSettlement.addAuthorization(address(esm));

        // Controller
        rateSetterRelayer.modifyParameters("setter", address(rateSetter));
        if (CONTROLLER_TYPE != "new") {
            rateCalculator.modifyParameters("allReaderToggle", 1);
        }
        rateCalculator.modifyParameters("seedProposer", address(rateSetter));
        rateSetter.updateRate(address(accountingEngine));
        oracleRelayer.addAuthorization(address(rateSetterRelayer));
        stabilityFeeTreasury.setPerBlockAllowance(
            address(rateSetterRelayer),
            CONTROLLER_SETTER_MAX_UPDATE_CALLER_REWARD
        );
        stabilityFeeTreasury.setTotalAllowance(
            address(rateSetterRelayer),
            uint256(-1)
        );
        rateSetterRelayer.modifyParameters(
            "maxRewardIncreaseDelay",
            CONTROLLER_SETTER_RELAYER_MAX_REWARD_INCREASE_DELAY
        );

        // DebtPopperRewards
        stabilityFeeTreasury.setPerBlockAllowance(
            address(debtPopperRewards),
            POPPER_REWARDS_FIXED_REWARD
        );
        stabilityFeeTreasury.setTotalAllowance(
            address(debtPopperRewards),
            uint256(-1)
        );

        // Liquidity incentives
        if (LIQUIDITY_REWARDS > 0)
            liquidityRewardsDripper.modifyParameters(
                "requestor",
                address(liquidityRewards)
            );

        // deauth deployer from all contracts
        coin.removeAuthorization(ETH_FROM);
        coinJoin.removeAuthorization(ETH_FROM);
        oracleRelayer.removeAuthorization(ETH_FROM);
        safeEngine.removeAuthorization(ETH_FROM);
        taxCollector.removeAuthorization(ETH_FROM);
        if (address(coinSavingsAccount) != address(0))
            coinSavingsAccount.removeAuthorization(ETH_FROM);
        surplusAuctionHouse.removeAuthorization(ETH_FROM);
        debtAuctionHouse.removeAuthorization(ETH_FROM);
        accountingEngine.removeAuthorization(ETH_FROM);
        liquidationEngine.removeAuthorization(ETH_FROM);
        stabilityFeeTreasury.removeAuthorization(ETH_FROM);
        globalSettlement.removeAuthorization(ETH_FROM);
        esm.removeAuthorization(ETH_FROM);
        rateCalculator.removeAuthority(ETH_FROM);
        rateSetter.removeAuthorization(ETH_FROM);
        rateSetterRelayer.removeAuthorization(ETH_FROM);
        debtPopperRewards.removeAuthorization(ETH_FROM);
        debtRewardsDripper.removeAuthorization(ETH_FROM);
        liquidityRewardsDripper.removeAuthorization(ETH_FROM);
        liquidityRewards.removeAuthorization(ETH_FROM);


        // pause setup
        pause.setDelay(PAUSE_DELAY);
        pause.setOwner(GEB_MULTISIG);
    }

    function setupCollateral(
        bytes32 collateralType,
        address auctionHouse,
        address adapter,
        address collateralFSM,
        uint256 debtCeiling,
        uint256 debtFloor,
        uint256 cRatio,
        uint256 stabilityFee,
        uint256 liquidationPenalty,
        uint256 liquidationQuantity
    ) public {
        safeEngine.addAuthorization(address(oracleRelayer));
        safeEngine.addAuthorization(adapter);

        liquidationEngine.modifyParameters(
            collateralType,
            "collateralAuctionHouse",
            auctionHouse
        );
        liquidationEngine.modifyParameters(
            collateralType,
            "liquidationPenalty",
            liquidationPenalty
        );
        liquidationEngine.modifyParameters(
            collateralType,
            "liquidationQuantity",
            liquidationQuantity
        );
        liquidationEngine.addAuthorization(auctionHouse);
        // Internal auth
        Setter(auctionHouse).addAuthorization(address(liquidationEngine));
        Setter(auctionHouse).addAuthorization(address(globalSettlement));

        oracleRelayer.modifyParameters(
            collateralType,
            "orcl",
            address(collateralFSM)
        );

        // Internal references set up
        safeEngine.initializeCollateralType(collateralType);
        taxCollector.initializeCollateralType(collateralType);
        taxCollector.modifyParameters(
            collateralType,
            "stabilityFee",
            stabilityFee
        );

        // Set bid restrictions
        bytes32 auctionHouseType = AuctionHouseLike(auctionHouse)
            .AUCTION_TYPE();
        if (auctionHouseType != "ENGLISH") {
            Setter(auctionHouse).modifyParameters(
                "oracleRelayer",
                address(oracleRelayer)
            );
            Setter(auctionHouse).modifyParameters(
                "collateralFSM",
                address(collateralFSM)
            );
        }

        safeEngine.modifyParameters(collateralType, "debtCeiling", debtCeiling);
        safeEngine.modifyParameters(collateralType, "debtFloor", debtFloor);
        oracleRelayer.modifyParameters(collateralType, "safetyCRatio", cRatio);
        oracleRelayer.modifyParameters(
            collateralType,
            "liquidationCRatio",
            cRatio
        );

        // remove auth
        Setter(auctionHouse).removeAuthorization(ETH_FROM);
        Setter(adapter).removeAuthorization(ETH_FROM);
        Setter(collateralFSM).removeAuthorization(ETH_FROM);

        // update collateral price
        oracleRelayer.updateCollateralPrice(collateralType);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.7;
pragma experimental ABIEncoderV2;

abstract contract AuthLike {
    function addAuthorization(address) external virtual;
    function setOwner(address) external virtual;
}

abstract contract PauseLike {
    function scheduleTransaction(address, bytes32, bytes calldata, uint256) external virtual;
    function executeTransaction(address, bytes32, bytes calldata, uint256) external virtual;
    function  proxy() external virtual returns (address);
}

contract Utils {
    mapping (string => address) public addr;
    string[] public addressList;
    event log_named_address(string key, address val);

    function addressListLength() public view returns (uint256) {return addressList.length;}

    function addAddress(string memory name, address val) internal {
        emit log_named_address(name, val);
        addressList.push(name);
        addr[name] = val;
    }

    function addAddress(string memory name, address val, address auth) internal {
        AuthLike(val).addAuthorization(auth);
        addAddress(name, val);
    }

    function getExtCodeHash(address usr)
        internal view
        returns (bytes32 codeHash)
    {
        assembly { codeHash := extcodehash(usr) }
    }

    function getChainID() internal view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }
}