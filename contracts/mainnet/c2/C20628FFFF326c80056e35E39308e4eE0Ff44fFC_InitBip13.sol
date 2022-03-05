/*
 SPDX-License-Identifier: MIT
*/

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import {AppStorage} from "../AppStorage.sol";

/**
 * @author Publius
 * @title InitBip13 initializes the weather change for BIP-13.
**/
contract InitBip13 {

    AppStorage internal s;

    function init() external {
        s.cases = [
        // Dsc, Sdy, Inc, nul
       int8(3),   1,   0,   0,  // Exs Low: P < 1
            -1,  -3,  -3,   0,  //          P > 1
             3,   1,   0,   0,  // Rea Low: P < 1
            -1,  -3,  -3,   0,  //          P > 1
             3,   3,   1,   0,  // Rea Hgh: P < 1
             0,  -1,  -3,   0,  //          P > 1
             3,   3,   1,   0,  // Exs Hgh: P < 1
             0,  -1,  -3,   0   //          P > 1
        ];
    }
}

/*
 SPDX-License-Identifier: MIT
*/

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "../interfaces/IDiamondCut.sol";

/**
 * @author Publius
 * @title App Storage defines the state object for Beanstalk.
**/
contract Account {

    struct Field {
        mapping(uint256 => uint256) plots;
        mapping(address => uint256) podAllowances;
    }

    struct AssetSilo {
        mapping(uint32 => uint256) withdrawals;
        mapping(uint32 => uint256) deposits;
        mapping(uint32 => uint256) depositSeeds;
    }

    struct Deposit {
        uint128 amount;
        uint128 bdv;
    }

    struct Silo {
        uint256 stalk;
        uint256 seeds;
    }

    struct SeasonOfPlenty {
        uint256 base;
        uint256 roots;
        uint256 basePerRoot;
    }

    struct State {
        Field field;
        AssetSilo bean;
        AssetSilo lp;
        Silo s;
        uint32 votedUntil;
        uint32 lastUpdate;
        uint32 lastSop;
        uint32 lastRain;
        uint32 lastSIs;
        uint32 proposedUntil;
        SeasonOfPlenty sop;
        uint256 roots;
        uint256 wrappedBeans;
        mapping(address => mapping(uint32 => Deposit)) deposits;
        mapping(address => mapping(uint32 => uint256)) withdrawals;
    }
}

contract Storage {
    struct Contracts {
        address bean;
        address pair;
        address pegPair;
        address weth;
    }

    // Field

    struct Field {
        uint256 soil;
        uint256 pods;
        uint256 harvested;
        uint256 harvestable;
    }

    // Governance

    struct Bip {
        address proposer;
        uint32 start;
        uint32 period;
        bool executed;
        int pauseOrUnpause;
        uint128 timestamp;
        uint256 roots;
        uint256 endTotalRoots;
    }

    struct DiamondCut {
        IDiamondCut.FacetCut[] diamondCut;
        address initAddress;
        bytes initData;
    }

    struct Governance {
        uint32[] activeBips;
        uint32 bipIndex;
        mapping(uint32 => DiamondCut) diamondCuts;
        mapping(uint32 => mapping(address => bool)) voted;
        mapping(uint32 => Bip) bips;
    }

    // Silo

    struct AssetSilo {
        uint256 deposited;
        uint256 withdrawn;
    }

    struct IncreaseSilo {
        uint256 beans;
        uint256 stalk;
    }

    struct V1IncreaseSilo {
        uint256 beans;
        uint256 stalk;
        uint256 roots;
    }

    struct SeasonOfPlenty {
        uint256 weth;
        uint256 base;
        uint32 last;
    }

    struct Silo {
        uint256 stalk;
        uint256 seeds;
        uint256 roots;
    }

    // Season

    struct Oracle {
        bool initialized;
        uint256 cumulative;
        uint256 pegCumulative;
        uint32 timestamp;
        uint32 pegTimestamp;
    }

    struct Rain {
        uint32 start;
        bool raining;
        uint256 pods;
        uint256 roots;
    }

    struct Season {
        uint32 current;
        uint32 sis;
        uint8 withdrawSeasons;
        uint256 start;
        uint256 period;
        uint256 timestamp;
    }

    struct Weather {
        uint256 startSoil;
        uint256 lastDSoil;
        uint96 lastSoilPercent;
        uint32 lastSowTime;
        uint32 nextSowTime;
        uint32 yield;
        bool didSowBelowMin;
        bool didSowFaster;
    }

    struct Fundraiser {
        address payee;
        address token;
        uint256 total;
        uint256 remaining;
    }

    struct SiloSettings {
        bytes4 selector;
        uint32 seeds;
        uint32 stalk;
    }
}

struct AppStorage {
    uint8 index;
    int8[32] cases;
    bool paused;
    uint128 pausedAt;
    Storage.Season season;
    Storage.Contracts c;
    Storage.Field f;
    Storage.Governance g;
    Storage.Oracle o;
    Storage.Rain r;
    Storage.Silo s;
    uint256 depreciated1;
    Storage.Weather w;
    Storage.AssetSilo bean;
    Storage.AssetSilo lp;
    Storage.IncreaseSilo si;
    Storage.SeasonOfPlenty sop;
    Storage.V1IncreaseSilo v1SI;
    uint256 unclaimedRoots;
    uint256 v2SIBeans;
    mapping (uint32 => uint256) sops;
    mapping (address => Account.State) a;
    uint32 bip0Start;
    uint32 hotFix3Start;
    mapping (uint32 => Storage.Fundraiser) fundraisers;
    uint32 fundraiserIndex;
    mapping (address => bool) isBudget;
    mapping(uint256 => bytes32) podListings;
    mapping(bytes32 => uint256) podOrders;
    mapping(address => Storage.AssetSilo) siloBalances;
    mapping(address => Storage.SiloSettings) ss;
}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.7.6;
/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}