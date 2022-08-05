/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import {AppStorage} from "../AppStorage.sol";
import "../../libraries/Token/LibTransfer.sol";
import "../../libraries/LibFertilizer.sol";
import "../../C.sol";
import {LibDiamond} from "../../libraries/LibDiamond.sol";

/**
 * @author Publius
 * @title Handles Sprouting Beans from Sprout Tokens
 **/

contract FertilizerFacet {
    using SafeMath for uint256;
    using LibSafeMath128 for uint128;

    event SetFertilizer(uint128 id, uint128 bpf);

    AppStorage internal s;

    struct Supply {
        uint128 endBpf;
        uint256 supply;
    }

    function claimFertilized(uint256[] calldata ids, LibTransfer.To mode)
        external
        payable
    {
        uint256 amount = C.fertilizer().beanstalkUpdate(msg.sender, ids, s.bpf);
        LibTransfer.sendToken(C.bean(), amount, msg.sender, mode);
    }

    function mintFertilizer(
        uint128 amount,
        uint256 minLP,
        LibTransfer.From mode
    ) external payable {
        uint128 remaining = uint128(LibFertilizer.remainingRecapitalization().div(1e6)); // remaining <= 77_000_000 so downcasting is safe.
        if (amount > remaining) amount = remaining;
        amount = uint128(LibTransfer.receiveToken(
            C.usdc(),
            uint256(amount).mul(1e6),
            msg.sender,
            mode
        ).div(1e6)); // return value <= amount, so downcasting is safe.
        uint128 id = LibFertilizer.addFertilizer(
            uint128(s.season.current),
            amount,
            minLP
        );
        C.fertilizer().beanstalkMint(msg.sender, uint256(id), amount, s.bpf);
    }

    function addFertilizerOwner(
        uint128 id,
        uint128 amount,
        uint256 minLP
    ) external payable {
        LibDiamond.enforceIsContractOwner();
        C.usdc().transferFrom(
            msg.sender,
            address(this),
            uint256(amount).mul(1e6)
        );
        LibFertilizer.addFertilizer(id, amount, minLP);
    }

    function payFertilizer(address account, uint256 amount) external payable {
        require(msg.sender == C.fertilizerAddress());
        LibTransfer.sendToken(
            C.bean(),
            amount,
            account,
            LibTransfer.To.INTERNAL
        );
    }

    function totalFertilizedBeans() external view returns (uint256 beans) {
        return s.fertilizedIndex;
    }

    function totalUnfertilizedBeans() external view returns (uint256 beans) {
        return s.unfertilizedIndex - s.fertilizedIndex;
    }

    function totalFertilizerBeans() external view returns (uint256 beans) {
        return s.unfertilizedIndex;
    }

    function getFertilizer(uint128 id) external view returns (uint256) {
        return s.fertilizer[id];
    }

    function getNext(uint128 id) external view returns (uint128) {
        return LibFertilizer.getNext(id);
    }

    function getFirst() external view returns (uint128) {
        return s.fFirst;
    }

    function getLast() external view returns (uint128) {
        return s.fLast;
    }

    function getActiveFertilizer() external view returns (uint256) {
        return s.activeFertilizer;
    }

    function isFertilizing() external view returns (bool) {
        return s.season.fertilizing;
    }

    function beansPerFertilizer() external view returns (uint128 bpf) {
        return s.bpf;
    }

    function getHumidity(uint128 _s) external pure returns (uint128 humidity) {
        humidity = LibFertilizer.getHumidity(_s);
    }

    function getCurrentHumidity() external view returns (uint128 humidity) {
        humidity = LibFertilizer.getHumidity(s.season.current);
    }

    function getEndBpf() external view returns (uint128 endBpf) {
        endBpf = s.bpf.add(LibFertilizer.getBpf(uint128(s.season.current)));
    }

    function remainingRecapitalization() external view returns (uint256) {
        return LibFertilizer.remainingRecapitalization();
    }

    function balanceOfUnfertilized(address account, uint256[] memory ids)
        external
        view
        returns (uint256 beans)
    {
        return C.fertilizer().balanceOfUnfertilized(account, ids);
    }

    function balanceOfFertilized(address account, uint256[] memory ids)
        external
        view
        returns (uint256 beans)
    {
        return C.fertilizer().balanceOfFertilized(account, ids);
    }

    function balanceOfFertilizer(address account, uint256 id)
        external
        view
        returns (IFertilizer.Balance memory)
    {
        return C.fertilizer().lastBalanceOf(account, id);
    }

    function balanceOfBatchFertilizer(
        address[] memory accounts,
        uint256[] memory ids
    ) external view returns (IFertilizer.Balance[] memory) {
        return C.fertilizer().lastBalanceOfBatch(accounts, ids);
    }

    function getFertilizers()
        external
        view
        returns (Supply[] memory fertilizers)
    {
        uint256 numFerts = 0;
        uint128 idx = s.fFirst;
        while (idx > 0) {
            numFerts = numFerts.add(1);
            idx = LibFertilizer.getNext(idx);
        }
        fertilizers = new Supply[](numFerts);
        numFerts = 0;
        idx = s.fFirst;
        while (idx > 0) {
            fertilizers[numFerts].endBpf = idx;
            fertilizers[numFerts].supply = LibFertilizer.getAmount(idx);
            numFerts = numFerts.add(1);
            idx = LibFertilizer.getNext(idx);
        }
    }
}

/*
 SPDX-License-Identifier: MIT
*/

pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import "../interfaces/IDiamondCut.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @author Publius
 * @title App Storage defines the state object for Beanstalk.
**/

// The Account contract stores all of the Farmer specific storage data.
// Each unique Ethereum address is a Farmer.
// Account.State is the primary struct that is referenced in the greater Storage.State struct.
// All other structs in Account are stored in Account.State.
contract Account {

    // Field stores a Farmer's Plots and Pod allowances.
    struct Field {
        mapping(uint256 => uint256) plots; // A Farmer's Plots. Maps from Plot index to Pod amount.
        mapping(address => uint256) podAllowances; // An allowance mapping for Pods similar to that of the ERC-20 standard. Maps from spender address to allowance amount.
    }

    // Asset Silo is a struct that stores Deposits and Seeds per Deposit, and formerly stored Withdrawals.
    // Asset Silo currently stores Unripe Bean and Unripe LP Deposits.
    struct AssetSilo {
        mapping(uint32 => uint256) withdrawals; // DEPRECATED – Silo V1 Withdrawals are no longer referenced.
        mapping(uint32 => uint256) deposits; // Unripe Bean/LP Deposits (previously Bean/LP Deposits).
        mapping(uint32 => uint256) depositSeeds; // BDV of Unripe LP Deposits / 4 (previously # of Seeds in corresponding LP Deposit).
    }

    // Deposit represents a Deposit in the Silo of a given Token at a given Season.
    // Stored as two uint128 state variables to save gas.
    struct Deposit {
        uint128 amount; // The amount of Tokens in the Deposit.
        uint128 bdv; // The Bean-denominated-value of the total amount of Tokens in the Deposit.
    }

    // Silo stores Silo-related balances
    struct Silo {
        uint256 stalk; // Balance of the Farmer's normal Stalk.
        uint256 seeds; // Balance of the Farmer's normal Seeds.
    }

    // Season Of Plenty stores Season of Plenty (SOP) related balances
    struct SeasonOfPlenty {
        // uint256 base; // DEPRECATED – Post Replant SOPs are denominated in plenty Tokens instead of base.
        uint256 roots; // The number of Roots a Farmer had when it started Raining.
        // uint256 basePerRoot; // DEPRECATED – Post Replant SOPs are denominated in plenty Tokens instead of base.
        uint256 plentyPerRoot; // The global Plenty Per Root index at the last time a Farmer updated their Silo. 
        uint256 plenty; // The balance of a Farmer's plenty. Plenty can be claimed directly for 3Crv.
    }

    // The Account level State stores all of the Farmer's balances in the contract.
    // The global AppStorage state stores a mapping from account address to Account.State.
    struct State {
        Field field; // A Farmer's Field storage.
        AssetSilo bean; // A Farmer's Unripe Bean Deposits only as a result of Replant (previously held the V1 Silo Deposits/Withdrawals for Beans).
        AssetSilo lp;  // A Farmer's Unripe LP Deposits as a result of Replant of BEAN:ETH Uniswap v2 LP Tokens (previously held the V1 Silo Deposits/Withdrawals for BEAN:ETH Uniswap v2 LP Tokens).
        Silo s; // A Farmer's Silo storage.
        uint32 votedUntil; // DEPRECATED – Replant removed on-chain governance including the ability to vote on BIPs.
        uint32 lastUpdate; // The Season in which the Farmer last updated their Silo.
        uint32 lastSop; // The last Season that a SOP occured at the time the Farmer last updated their Silo.
        uint32 lastRain; // The last Season that it started Raining at the time the Farmer last updated their Silo.
        uint32 lastSIs; // DEPRECATED – In Silo V1.2, the Silo reward mechanism was updated to no longer need to store the number of the Supply Increases at the time the Farmer last updated their Silo.
        uint32 proposedUntil; // DEPRECATED – Replant removed on-chain governance including the ability to propose BIPs.
        SeasonOfPlenty deprecated; // DEPRECATED – Replant reset the Season of Plenty mechanism
        uint256 roots; // A Farmer's Root balance.
        uint256 wrappedBeans; // DEPRECATED – Replant generalized Internal Balances. Wrapped Beans are now stored at the AppStorage level.
        mapping(address => mapping(uint32 => Deposit)) deposits; // A Farmer's Silo Deposits stored as a map from Token address to Season of Deposit to Deposit.
        mapping(address => mapping(uint32 => uint256)) withdrawals; // A Farmer's Withdrawals from the Silo stored as a map from Token address to Season the Withdrawal becomes Claimable to Withdrawn amount of Tokens.
        SeasonOfPlenty sop; // A Farmer's Season Of Plenty storage.
    }
}

// Storage stores the Global Beanstalk State.
// Storage.State stores the highest level State
// All Facets define Storage.State as the first and only state variable in the contract.
contract Storage {

    // DEPRECATED – After Replant, Beanstalk stores Token addresses as constants to save gas.
    // Contracts stored the contract addresses of various important contracts to Beanstalk.
    struct Contracts {
        address bean; // DEPRECATED – See above note
        address pair; // DEPRECATED – See above note
        address pegPair; // DEPRECATED – See above note
        address weth; // DEPRECATED – See above note
    }

    // Field stores global Field balances.
    struct Field {
        uint256 soil; // The number of Soil currently available.
        uint256 pods; // The pod index; the total number of Pods ever minted.
        uint256 harvested; // The harvested index; the total number of Pods that have ever been Harvested.
        uint256 harvestable; // The harvestable index; the total number of Pods that have ever been Harvestable. Included previously Harvested Beans.
    }

    // DEPRECATED – Replant moved governance off-chain.
    // Bip stores Bip related data.
    struct Bip {
        address proposer; // DEPRECATED – See above note
        uint32 start; // DEPRECATED – See above note
        uint32 period; // DEPRECATED – See above note
        bool executed; // DEPRECATED – See above note
        int pauseOrUnpause; // DEPRECATED – See above note
        uint128 timestamp; // DEPRECATED – See above note
        uint256 roots; // DEPRECATED – See above note
        uint256 endTotalRoots; // DEPRECATED – See above note
    }

    // DEPRECATED – Replant moved governance off-chain.
    // DiamondCut stores DiamondCut related data for each Bip.
    struct DiamondCut {
        IDiamondCut.FacetCut[] diamondCut;
        address initAddress;
        bytes initData;
    }

    // DEPRECATED – Replant moved governance off-chain.
    // Governance stores global Governance balances.
    struct Governance {
        uint32[] activeBips; // DEPRECATED – See above note
        uint32 bipIndex; // DEPRECATED – See above note
        mapping(uint32 => DiamondCut) diamondCuts; // DEPRECATED – See above note
        mapping(uint32 => mapping(address => bool)) voted; // DEPRECATED – See above note
        mapping(uint32 => Bip) bips; // DEPRECATED – See above note
    }

    // AssetSilo stores global Token level Silo balances.
    // In Storage.State there is a mapping from Token address to AssetSilo.
    struct AssetSilo {
        uint256 deposited; // The total number of a given Token currently Deposited in the Silo.
        uint256 withdrawn; // The total number of a given Token currently Withdrawn From the Silo but not Claimed.
    }

    // Silo stores global level Silo balances.
    struct Silo {
        uint256 stalk; // The total amount of active Stalk (including Earned Stalk, excluding Grown Stalk).
        uint256 seeds; // The total amount of active Seeds (excluding Earned Seeds).
        uint256 roots; // Total amount of Roots.
    }

    // Oracle stores global level Oracle balances.
    // Currently the oracle refers to the time weighted average delta b calculated from the Bean:3Crv pool.
    struct Oracle {
        bool initialized; // True if the Oracle has been initialzed. It needs to be initialized on Deployment and re-initialized each Unpause.
        uint32 startSeason; // The Season the Oracle started minting. Used to ramp up delta b when oracle is first added.
        uint256[2] balances; // The cumulative reserve balances of the pool at the start of the Season (used for computing time weighted average delta b).
        uint256 timestamp; // The timestamp of the start of the current Season.
    }

    // Rain stores global level Rain balances. (Rain is when P > 1, Pod rate Excessively Low).
    // Note: The `raining` storage variable is stored in the Season section for a gas efficient read operation.
    struct Rain {
        uint256 depreciated; // Ocupies a storage slot in place of a deprecated State variable.
        uint256 pods; // The number of Pods when it last started Raining.
        uint256 roots; // The number of Roots when it last started Raining.
    }

    // Sesaon stores global level Season balances.
    struct Season {
        // The first storage slot in Season is filled with a variety of somewhat unrelated storage variables.
        // Given that they are all smaller numbers, they are stored together for gas efficient read/write operations. 
        // Apologies if this makes it confusing :(
        uint32 current; // The current Season in Beanstalk.
        uint32 lastSop; // The Season in which the most recent consecutive series of Seasons of Plenty started.
        uint8 withdrawSeasons; // The number of seasons required to Withdraw a Deposit.
        uint32 lastSopSeason; // The Season in which the most recent consecutive series of Seasons of Plenty ended.
        uint32 rainStart; // rainStart stores the most recent Season in which Rain started.
        bool raining; // True if it is Raining (P < 1, Pod Rate Excessively Low).
        bool fertilizing; // True if Beanstalk has Fertilizer left to be paid off.
        uint256 start; // The timestamp of the Beanstalk deployment rounded down to the nearest hour.
        uint256 period; // The length of each season in Beanstalk.
        uint256 timestamp; // The timestamp of the start of the current Season.
    }

    // Weather stores global level Weather balances.
    struct Weather {
        uint256 startSoil; // The number of Soil at the start of the current Season.
        uint256 lastDSoil; // Delta Soil; the number of Soil purchased last Season.
        uint96 lastSoilPercent; // DEPRECATED: Was removed with Extreme Weather V2
        uint32 lastSowTime; // The number of seconds it took for all but at most 1 Soil to sell out last Season.
        uint32 nextSowTime; // The number of seconds it took for all but at most 1 Soil to sell out this Season
        uint32 yield; // Weather; the interest rate for sowing Beans in Soil.
        bool didSowBelowMin; // DEPRECATED: Was removed with Extreme Weather V2
        bool didSowFaster; // DEPRECATED: Was removed with Extreme Weather V2
    }

    // Fundraiser stores Fundraiser data for a given Fundraiser.
    struct Fundraiser {
        address payee; // The address to be paid after the Fundraiser has been fully funded.
        address token; // The token address that used to raise funds for the Fundraiser.
        uint256 total; // The total number of Tokens that need to be raised to complete the Fundraiser.
        uint256 remaining; // The remaining number of Tokens that need to to complete the Fundraiser.
        uint256 start; // The timestamp at which the Fundraiser started (Fundraisers cannot be started and funded in the same block).
    }

    // SiloSettings stores the settings for each Token that has been Whitelisted into the Silo.
    // A Token is considered whitelisted in the Silo if there exists a non-zero SiloSettings selector.
    struct SiloSettings {
        // selector is an encoded function selector 
        // that pertains to an external view Beanstalk function 
        // with the following signature:
        // function tokenToBdv(uint256 amount) public view returns (uint256);
        // It is called by `LibTokenSilo` through the use of delegatecall
        // To calculate the BDV of a Deposit at the time of Deposit.
        bytes4 selector; // The encoded BDV function selector for the Token.
        uint32 seeds; // The Seeds Per BDV that the Silo mints in exchange for Depositing this Token.
        uint32 stalk; // The Stalk Per BDV that the Silo mints in exchange for Depositing this Token.
    }

    // UnripeSettings stores the settings for an Unripe Token in Beanstalk.
    // An Unripe token is a vesting Token that is redeemable for a a pro rata share
    // of the balanceOfUnderlying subject to a penalty based on the percent of
    // Unfertilized Beans paid back.
    // There were two Unripe Tokens added at Replant: 
    // Unripe Bean with its underlying Token as Bean; and
    // Unripe LP with its underlying Token as Bean:3Crv LP.
    // Unripe Tokens are distirbuted through the use of a merkleRoot.
    // The existence of a non-zero UnripeSettings implies that a Token is an Unripe Token.
    struct UnripeSettings {
        address underlyingToken; // The address of the Token underlying the Unripe Token.
        uint256 balanceOfUnderlying; // The number of Tokens underlying the Unripe Tokens (redemption pool).
        bytes32 merkleRoot; // The Merkle Root used to validate a claim of Unripe Tokens.
    }
}

struct AppStorage {
    uint8 index; // DEPRECATED - Was the index of the Bean token in the Bean:Eth Uniswap v2 pool, which has been depreciated.
    int8[32] cases; // The 24 Weather cases (array has 32 items, but caseId = 3 (mod 4) are not cases).
    bool paused; // True if Beanstalk is Paused.
    uint128 pausedAt; // The timestamp at which Beanstalk was last paused. 
    Storage.Season season; // The Season storage struct found above.
    Storage.Contracts c; // DEPRECATED - Previously stored the Contracts State struct. Removed when contract addresses were moved to constants in C.sol.
    Storage.Field f; // The Field storage struct found above.
    Storage.Governance g; // The Governance storage struct found above.
    Storage.Oracle co; // The Oracle storage struct found above.
    Storage.Rain r; // The Rain storage struct found above.
    Storage.Silo s; // The Silo storage struct found above.
    uint256 reentrantStatus; // An intra-transaction state variable to protect against reentrance.
    Storage.Weather w; // The Weather storage struct found above.

    //////////////////////////////////

    uint256 earnedBeans; // The number of Beans distributed to the Silo that have not yet been Deposited as a result of the Earn function being called.
    uint256[14] depreciated; // DEPRECATED - 14 slots that used to store state variables which have been deprecated through various updates. Storage slots can be left alone or reused.
    mapping (address => Account.State) a; // A mapping from Farmer address to Account state.
    uint32 bip0Start; // DEPRECATED - bip0Start was used to aid in a migration that occured alongside BIP-0.
    uint32 hotFix3Start; // DEPRECATED - hotFix3Start was used to aid in a migration that occured alongside HOTFIX-3.
    mapping (uint32 => Storage.Fundraiser) fundraisers; // A mapping from Fundraiser Id to Fundraiser storage.
    uint32 fundraiserIndex; // The number of Fundraisers that have occured.
    mapping (address => bool) isBudget; // DEPRECATED - Budget Facet was removed in BIP-14. 
    mapping(uint256 => bytes32) podListings; // A mapping from Plot Index to the hash of the Pod Listing.
    mapping(bytes32 => uint256) podOrders; // A mapping from the hash of a Pod Order to the amount of Pods that the Pod Order is still willing to buy.
    mapping(address => Storage.AssetSilo) siloBalances; // A mapping from Token address to Silo Balance storage (amount deposited and withdrawn).
    mapping(address => Storage.SiloSettings) ss; // A mapping from Token address to Silo Settings for each Whitelisted Token. If a non-zero storage exists, a Token is whitelisted.
    uint256[3] depreciated2; // DEPRECATED - 3 slots that used to store state variables which have been depreciated through various updates. Storage slots can be left alone or reused.

    // New Sops
    mapping (uint32 => uint256) sops; // A mapping from Season to Plenty Per Root (PPR) in that Season. Plenty Per Root is 0 if a Season of Plenty did not occur.

    // Internal Balances
    mapping(address => mapping(IERC20 => uint256)) internalTokenBalance; // A mapping from Farmer address to Token address to Internal Balance. It stores the amount of the Token that the Farmer has stored as an Internal Balance in Beanstalk.

    // Unripe
    mapping(address => mapping(address => bool)) unripeClaimed; // True if a Farmer has Claimed an Unripe Token. A mapping from Farmer to Unripe Token to its Claim status.
    mapping(address => Storage.UnripeSettings) u; // Unripe Settings for a given Token address. The existence of a non-zero Unripe Settings implies that the token is an Unripe Token. The mapping is from Token address to Unripe Settings.

    // Fertilizer
    mapping(uint128 => uint256) fertilizer; // A mapping from Fertilizer Id to the supply of Fertilizer for each Id.
    mapping(uint128 => uint128) nextFid; // A linked list of Fertilizer Ids ordered by Id number. Fertilizer Id is the Beans Per Fertilzer level at which the Fertilizer no longer receives Beans. Sort in order by which Fertilizer Id expires next.
    uint256 activeFertilizer; // The number of active Fertilizer.
    uint256 fertilizedIndex; // The total number of Fertilizer Beans.
    uint256 unfertilizedIndex; // The total number of Unfertilized Beans ever.
    uint128 fFirst; // The lowest active Fertilizer Id (start of linked list that is stored by nextFid). 
    uint128 fLast; // The highest active Fertilizer Id (end of linked list that is stored by nextFid). 
    uint128 bpf; // The cumulative Beans Per Fertilizer (bfp) minted over all Season.
    uint256 recapitalized; // The nubmer of USDC that has been recapitalized in the Barn Raise.
    uint256 isFarm; // Stores whether the function is wrapped in the `farm` function (1 if not, 2 if it is).
    address ownerCandidate; // Stores a candidate address to transfer ownership to. The owner must claim the ownership transfer.
}

/*
 SPDX-License-Identifier: MIT
*/

/**
 * @author publius
 * @title LibTransfer handles the recieving and sending of Tokens to/from internal Balances.
 **/
pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../interfaces/IBean.sol";
import "./LibBalance.sol";

library LibTransfer {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    enum From {
        EXTERNAL,
        INTERNAL,
        EXTERNAL_INTERNAL,
        INTERNAL_TOLERANT
    }
    enum To {
        EXTERNAL,
        INTERNAL
    }

    function transferToken(
        IERC20 token,
        address recipient,
        uint256 amount,
        From fromMode,
        To toMode
    ) internal returns (uint256 transferredAmount) {
        if (fromMode == From.EXTERNAL && toMode == To.EXTERNAL) {
            uint256 beforeBalance = token.balanceOf(recipient);
            token.safeTransferFrom(msg.sender, recipient, amount);
            return token.balanceOf(recipient).sub(beforeBalance);
        }
        amount = receiveToken(token, amount, msg.sender, fromMode);
        sendToken(token, amount, recipient, toMode);
        return amount;
    }

    function receiveToken(
        IERC20 token,
        uint256 amount,
        address sender,
        From mode
    ) internal returns (uint256 receivedAmount) {
        if (amount == 0) return 0;
        if (mode != From.EXTERNAL) {
            receivedAmount = LibBalance.decreaseInternalBalance(
                sender,
                token,
                amount,
                mode != From.INTERNAL
            );
            if (amount == receivedAmount || mode == From.INTERNAL_TOLERANT)
                return receivedAmount;
        }
        uint256 beforeBalance = token.balanceOf(address(this));
        token.safeTransferFrom(sender, address(this), amount - receivedAmount);
        return receivedAmount.add(token.balanceOf(address(this)).sub(beforeBalance));
    }

    function sendToken(
        IERC20 token,
        uint256 amount,
        address recipient,
        To mode
    ) internal {
        if (amount == 0) return;
        if (mode == To.INTERNAL)
            LibBalance.increaseInternalBalance(recipient, token, amount);
        else token.safeTransfer(recipient, amount);
    }

    function burnToken(
        IBean token,
        uint256 amount, 
        address sender,
        From mode 
    ) internal returns (uint256 burnt) {
        // burnToken only can be called with Unripe Bean, Unripe Bean:3Crv or Bean token, which are all Beanstalk tokens. 
        // Beanstalk's ERC-20 implementation uses OpenZeppelin's ERC20Burnable
        // which reverts if burnFrom function call cannot burn full amount.
        if (mode == From.EXTERNAL) {
            token.burnFrom(sender, amount);
            burnt = amount;
        } else {
            burnt = LibTransfer.receiveToken(token, amount, sender, mode);
            token.burn(burnt);
        }
    }
}

/*
 SPDX-License-Identifier: MIT
*/

pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./LibAppStorage.sol";
import "./LibSafeMath128.sol";
import "../C.sol";
import "./LibUnripe.sol";

/**
 * @author Publius
 * @title Fertilizer
 **/

library LibFertilizer {
    using SafeMath for uint256;
    using LibSafeMath128 for uint128;

    event SetFertilizer(uint128 id, uint128 bpf);

    // 6 - 3
    uint128 private constant PADDING = 1e3;
    uint128 private constant DECIMALS = 1e6;
    uint128 private constant REPLANT_SEASON = 6074;
    uint128 private constant RESTART_HUMIDITY = 2500;
    uint128 private constant END_DECREASE_SEASON = REPLANT_SEASON + 461;

    function addFertilizer(
        uint128 season,
        uint128 amount,
        uint256 minLP
    ) internal returns (uint128 id) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 _amount = uint256(amount);
        // Calculate Beans Per Fertilizer and add to total owed
        uint128 bpf = getBpf(season);
        s.unfertilizedIndex = s.unfertilizedIndex.add(
            _amount.mul(uint128(bpf))
        );
        // Get id
        id = s.bpf.add(bpf);
        // Update Total and Season supply
        s.fertilizer[id] = s.fertilizer[id].add(amount);
        s.activeFertilizer = s.activeFertilizer.add(_amount);
        // Add underlying to Unripe Beans and Unripe LP
        addUnderlying(_amount.mul(DECIMALS), minLP);
        // If not first time adding Fertilizer with this id, return
        if (s.fertilizer[id] > amount) return id;
        // If first time, log end Beans Per Fertilizer and add to Season queue.
        LibFertilizer.push(id);
        emit SetFertilizer(id, bpf);
    }

    function getBpf(uint128 id) internal pure returns (uint128 bpf) {
        bpf = getHumidity(id).add(1000).mul(PADDING);
    }

    function getHumidity(uint128 id) internal pure returns (uint128 humidity) {
        if (id == 0) return 5000;
        if (id >= END_DECREASE_SEASON) return 200;
        uint128 humidityDecrease = id.sub(REPLANT_SEASON).mul(5);
        humidity = RESTART_HUMIDITY.sub(humidityDecrease);
    }

    function addUnderlying(uint256 amount, uint256 minAmountOut) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        // Calculate how many new Deposited Beans will be minted
        uint256 percentToFill = amount.mul(C.precision()).div(
            remainingRecapitalization()
        );
        uint256 newDepositedBeans;
        if (C.unripeBean().totalSupply() > s.u[C.unripeBeanAddress()].balanceOfUnderlying) {
            newDepositedBeans = (C.unripeBean().totalSupply()).sub(
                s.u[C.unripeBeanAddress()].balanceOfUnderlying
            );
            newDepositedBeans = newDepositedBeans.mul(percentToFill).div(
                C.precision()
            );
        }

        // Calculate how many Beans to add as LP
        uint256 newDepositedLPBeans = amount.mul(C.exploitAddLPRatio()).div(
            DECIMALS
        );
        // Mint the Beans
        C.bean().mint(
            address(this),
            newDepositedBeans.add(newDepositedLPBeans)
        );
        // Add Liquidity
        uint256 newLP = C.curveZap().add_liquidity(
            C.curveMetapoolAddress(),
            [newDepositedLPBeans, 0, amount, 0],
            minAmountOut
        );
        // Increment underlying balances of Unripe Tokens
        LibUnripe.incrementUnderlying(C.unripeBeanAddress(), newDepositedBeans);
        LibUnripe.incrementUnderlying(C.unripeLPAddress(), newLP);

        s.recapitalized = s.recapitalized.add(amount);
    }

    function push(uint128 id) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (s.fFirst == 0) {
            // Queue is empty
            s.season.fertilizing = true;
            s.fLast = id;
            s.fFirst = id;
        } else if (id <= s.fFirst) {
            // Add to front of queue
            setNext(id, s.fFirst);
            s.fFirst = id;
        } else if (id >= s.fLast) {
            // Add to back of queue
            setNext(s.fLast, id);
            s.fLast = id;
        } else {
            // Add to middle of queue
            uint128 prev = s.fFirst;
            uint128 next = getNext(prev);
            // Search for proper place in line
            while (id > next) {
                prev = next;
                next = getNext(next);
            }
            setNext(prev, id);
            setNext(id, next);
        }
    }

    function remainingRecapitalization()
        internal
        view
        returns (uint256 remaining)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 totalDollars = C
            .dollarPerUnripeLP()
            .mul(C.unripeLP().totalSupply())
            .div(DECIMALS);
        totalDollars = totalDollars / 1e6 * 1e6; // round down to nearest USDC
        if (s.recapitalized >= totalDollars) return 0;
        return totalDollars.sub(s.recapitalized);
    }

    function pop() internal returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint128 first = s.fFirst;
        s.activeFertilizer = s.activeFertilizer.sub(getAmount(first));
        uint128 next = getNext(first);
        if (next == 0) {
            // If all Unfertilized Beans have been fertilized, delete line.
            require(s.activeFertilizer == 0, "Still active fertilizer");
            s.fFirst = 0;
            s.fLast = 0;
            s.season.fertilizing = false;
            return false;
        }
        s.fFirst = getNext(first);
        return true;
    }

    function getAmount(uint128 id) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.fertilizer[id];
    }

    function getNext(uint128 id) internal view returns (uint128) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.nextFid[id];
    }

    function setNext(uint128 id, uint128 next) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.nextFid[id] = next;
    }
}

/*
 SPDX-License-Identifier: MIT
*/

pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import "./interfaces/IBean.sol";
import "./interfaces/ICurve.sol";
import "./interfaces/IFertilizer.sol";
import "./interfaces/IProxyAdmin.sol";
import "./libraries/Decimal.sol";

/**
 * @author Publius
 * @title C holds the contracts for Beanstalk.
**/
library C {

    using Decimal for Decimal.D256;
    using SafeMath for uint256;

    // Constants
    uint256 private constant PERCENT_BASE = 1e18;
    uint256 private constant PRECISION = 1e18;

    // Chain
    uint256 private constant CHAIN_ID = 1; // Mainnet

    // Season
    uint256 private constant CURRENT_SEASON_PERIOD = 3600; // 1 hour
    uint256 private constant BASE_ADVANCE_INCENTIVE = 100e6; // 100 beans
    uint256 private constant SOP_PRECISION = 1e24;

    // Sun
    uint256 private constant FERTILIZER_DENOMINATOR = 3;
    uint256 private constant HARVEST_DENOMINATOR = 2;
    uint256 private constant SOIL_COEFFICIENT_HIGH = 0.5e18;
    uint256 private constant SOIL_COEFFICIENT_LOW = 1.5e18;

    // Weather
    uint256 private constant POD_RATE_LOWER_BOUND = 0.05e18; // 5%
    uint256 private constant OPTIMAL_POD_RATE = 0.15e18; // 15%
    uint256 private constant POD_RATE_UPPER_BOUND = 0.25e18; // 25%
    uint32 private constant STEADY_SOW_TIME = 60; // 1 minute

    uint256 private constant DELTA_POD_DEMAND_LOWER_BOUND = 0.95e18; // 95%
    uint256 private constant DELTA_POD_DEMAND_UPPER_BOUND = 1.05e18; // 105%

    // Silo
    uint256 private constant SEEDS_PER_BEAN = 2;
    uint256 private constant STALK_PER_BEAN = 10000;
    uint256 private constant ROOTS_BASE = 1e12;


    // Exploit
    uint256 private constant UNRIPE_LP_PER_DOLLAR = 1884592; // 145_113_507_403_282 / 77_000_000
    uint256 private constant ADD_LP_RATIO = 866616;
    uint256 private constant INITIAL_HAIRCUT = 185564685220298701; // SET

    // Contracts
    address private constant BEAN = 0xBEA0000029AD1c77D3d5D23Ba2D8893dB9d1Efab;
    address private constant CURVE_BEAN_METAPOOL = 0xc9C32cd16Bf7eFB85Ff14e0c8603cc90F6F2eE49;
    address private constant CURVE_3_POOL = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
    address private constant THREE_CRV = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;
    address private constant UNRIPE_BEAN = 0x1BEA0050E63e05FBb5D8BA2f10cf5800B6224449;
    address private constant UNRIPE_LP = 0x1BEA3CcD22F4EBd3d37d731BA31Eeca95713716D;
    address private constant FERTILIZER = 0x402c84De2Ce49aF88f5e2eF3710ff89bFED36cB6;
    address private constant FERTILIZER_ADMIN = 0xfECB01359263C12Aa9eD838F878A596F0064aa6e;
    address private constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    address private constant TRI_CRYPTO = 0xc4AD29ba4B3c580e6D59105FFf484999997675Ff;
    address private constant TRI_CRYPTO_POOL = 0xD51a44d3FaE010294C616388b506AcdA1bfAAE46;
    address private constant CURVE_ZAP = 0xA79828DF1850E8a3A3064576f380D90aECDD3359;

    address private constant UNRIPE_CURVE_BEAN_LUSD_POOL = 0xD652c40fBb3f06d6B58Cb9aa9CFF063eE63d465D;
    address private constant UNRIPE_CURVE_BEAN_METAPOOL = 0x3a70DfA7d2262988064A2D051dd47521E43c9BdD;

    /**
     * Getters
    **/

    function getSeasonPeriod() internal pure returns (uint256) {
        return CURRENT_SEASON_PERIOD;
    }

    function getAdvanceIncentive() internal pure returns (uint256) {
        return BASE_ADVANCE_INCENTIVE;
    }

    function getFertilizerDenominator() internal pure returns (uint256) {
        return FERTILIZER_DENOMINATOR;
    }

    function getHarvestDenominator() internal pure returns (uint256) {
        return HARVEST_DENOMINATOR;
    }

    function getChainId() internal pure returns (uint256) {
        return CHAIN_ID;
    }

    function getOptimalPodRate() internal pure returns (Decimal.D256 memory) {
        return Decimal.ratio(OPTIMAL_POD_RATE, PERCENT_BASE);
    }

    function getUpperBoundPodRate() internal pure returns (Decimal.D256 memory) {
        return Decimal.ratio(POD_RATE_UPPER_BOUND, PERCENT_BASE);
    }

    function getLowerBoundPodRate() internal pure returns (Decimal.D256 memory) {
        return Decimal.ratio(POD_RATE_LOWER_BOUND, PERCENT_BASE);
    }

    function getUpperBoundDPD() internal pure returns (Decimal.D256 memory) {
        return Decimal.ratio(DELTA_POD_DEMAND_UPPER_BOUND, PERCENT_BASE);
    }

    function getLowerBoundDPD() internal pure returns (Decimal.D256 memory) {
        return Decimal.ratio(DELTA_POD_DEMAND_LOWER_BOUND, PERCENT_BASE);
    }

    function getSteadySowTime() internal pure returns (uint32) {
        return STEADY_SOW_TIME;
    }

    function getSeedsPerBean() internal pure returns (uint256) {
        return SEEDS_PER_BEAN;
    }

    function getStalkPerBean() internal pure returns (uint256) {
      return STALK_PER_BEAN;
    }

    function getRootsBase() internal pure returns (uint256) {
        return ROOTS_BASE;
    }

    function getSopPrecision() internal pure returns (uint256) {
        return SOP_PRECISION;
    }

    function beanAddress() internal pure returns (address) {
        return BEAN;
    }

    function curveMetapoolAddress() internal pure returns (address) {
        return CURVE_BEAN_METAPOOL;
    }

    function unripeLPPool1() internal pure returns (address) {
        return UNRIPE_CURVE_BEAN_METAPOOL;
    }

    function unripeLPPool2() internal pure returns (address) {
        return UNRIPE_CURVE_BEAN_LUSD_POOL;
    }

    function unripeBeanAddress() internal pure returns (address) {
        return UNRIPE_BEAN;
    }

    function unripeLPAddress() internal pure returns (address) {
        return UNRIPE_LP;
    }

    function unripeBean() internal pure returns (IERC20) {
        return IERC20(UNRIPE_BEAN);
    }

    function unripeLP() internal pure returns (IERC20) {
        return IERC20(UNRIPE_LP);
    }

    function bean() internal pure returns (IBean) {
        return IBean(BEAN);
    }

    function usdc() internal pure returns (IERC20) {
        return IERC20(USDC);
    }

    function curveMetapool() internal pure returns (ICurvePool) {
        return ICurvePool(CURVE_BEAN_METAPOOL);
    }

    function curve3Pool() internal pure returns (I3Curve) {
        return I3Curve(CURVE_3_POOL);
    }
    
    function curveZap() internal pure returns (ICurveZap) {
        return ICurveZap(CURVE_ZAP);
    }

    function curveZapAddress() internal pure returns (address) {
        return CURVE_ZAP;
    }

    function curve3PoolAddress() internal pure returns (address) {
        return CURVE_3_POOL;
    }

    function threeCrv() internal pure returns (IERC20) {
        return IERC20(THREE_CRV);
    }

    function fertilizer() internal pure returns (IFertilizer) {
        return IFertilizer(FERTILIZER);
    }

    function fertilizerAddress() internal pure returns (address) {
        return FERTILIZER;
    }

    function fertilizerAdmin() internal pure returns (IProxyAdmin) {
        return IProxyAdmin(FERTILIZER_ADMIN);
    }

    function triCryptoPoolAddress() internal pure returns (address) {
        return TRI_CRYPTO_POOL;
    }

    function triCrypto() internal pure returns (IERC20) {
        return IERC20(TRI_CRYPTO);
    }

    function unripeLPPerDollar() internal pure returns (uint256) {
        return UNRIPE_LP_PER_DOLLAR;
    }

    function dollarPerUnripeLP() internal pure returns (uint256) {
        return 1e12/UNRIPE_LP_PER_DOLLAR;
    }

    function exploitAddLPRatio() internal pure returns (uint256) {
        return ADD_LP_RATIO;
    }

    function precision() internal pure returns (uint256) {
        return PRECISION;
    }

    function initialRecap() internal pure returns (uint256) {
        return INITIAL_HAIRCUT;
    }

    function soilCoefficientHigh() internal pure returns (uint256) {
        return SOIL_COEFFICIENT_HIGH;
    }

    function soilCoefficientLow() internal pure returns (uint256) {
        return SOIL_COEFFICIENT_LOW;
    }
}

/*
 SPDX-License-Identifier: MIT
*/

pragma experimental ABIEncoderV2;
pragma solidity =0.7.6;
/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import {IDiamondCut} from "../interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "../interfaces/IDiamondLoupe.sol";
import {IERC165} from "../interfaces/IERC165.sol";

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsOwnerOrContract() internal view {
        require(msg.sender == diamondStorage().contractOwner ||
                msg.sender == address(this), "LibDiamond: Must be contract or owner"
        );
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    function addDiamondFunctions(
        address _diamondCutFacet,
        address _diamondLoupeFacet
    ) internal {
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](2);
        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = IDiamondCut.diamondCut.selector;
        cut[0] = IDiamondCut.FacetCut({facetAddress: _diamondCutFacet, action: IDiamondCut.FacetCutAction.Add, functionSelectors: functionSelectors});
        functionSelectors = new bytes4[](5);
        functionSelectors[0] = IDiamondLoupe.facets.selector;
        functionSelectors[1] = IDiamondLoupe.facetFunctionSelectors.selector;
        functionSelectors[2] = IDiamondLoupe.facetAddresses.selector;
        functionSelectors[3] = IDiamondLoupe.facetAddress.selector;
        functionSelectors[4] = IERC165.supportsInterface.selector;
        cut[1] = IDiamondCut.FacetCut({
            facetAddress: _diamondLoupeFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
        diamondCut(cut, address(0), "");
    }

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();        
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);            
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
        enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
        ds.facetAddresses.push(_facetAddress);
    }    


    function addFunction(DiamondStorage storage ds, bytes4 _selector, uint96 _selectorPosition, address _facetAddress) internal {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(DiamondStorage storage ds, address _facetAddress, bytes4 _selector) internal {        
        require(_facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "LibDiamondCut: Can't remove immutable function");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity =0.7.6;
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

/**
 * SPDX-License-Identifier: MIT
**/

pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
/**
 * @author Publius
 * @title Bean Interface
**/
abstract contract IBean is IERC20 {

    function burn(uint256 amount) public virtual;
    function burnFrom(address account, uint256 amount) public virtual;
    function mint(address account, uint256 amount) public virtual;

}

/*
 SPDX-License-Identifier: MIT
*/

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/Math.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/SafeCast.sol";
import "../LibAppStorage.sol";

/**
 * @author LeoFib, Publius
 * @title LibInternalBalance Library handles internal read/write functions for Internal User Balances.
 * Largely inspired by Balancer's Vault
 **/

library LibBalance {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using SafeCast for uint256;

    /**
     * @dev Emitted when a account's Internal Balance changes, through interacting using Internal Balance.
     *
     */
    event InternalBalanceChanged(
        address indexed account,
        IERC20 indexed token,
        int256 delta
    );

    function getBalance(address account, IERC20 token)
        internal
        view
        returns (uint256 combined_balance)
    {
        combined_balance = token.balanceOf(account).add(
            getInternalBalance(account, token)
        );
        return combined_balance;
    }

    /**
     * @dev Increases `account`'s Internal Balance for `token` by `amount`.
     */
    function increaseInternalBalance(
        address account,
        IERC20 token,
        uint256 amount
    ) internal {
        uint256 currentBalance = getInternalBalance(account, token);
        uint256 newBalance = currentBalance.add(amount);
        setInternalBalance(account, token, newBalance, amount.toInt256());
    }

    /**
     * @dev Decreases `account`'s Internal Balance for `token` by `amount`. If `allowPartial` is true, this function
     * doesn't revert if `account` doesn't have enough balance, and sets it to zero and returns the deducted amount
     * instead.
     */
    function decreaseInternalBalance(
        address account,
        IERC20 token,
        uint256 amount,
        bool allowPartial
    ) internal returns (uint256 deducted) {
        uint256 currentBalance = getInternalBalance(account, token);
        require(
            allowPartial || (currentBalance >= amount),
            "Balance: Insufficient internal balance"
        );

        deducted = Math.min(currentBalance, amount);
        // By construction, `deducted` is lower or equal to `currentBalance`, so we don't need to use checked
        // arithmetic.
        uint256 newBalance = currentBalance - deducted;
        setInternalBalance(account, token, newBalance, -(deducted.toInt256()));
    }

    /**
     * @dev Sets `account`'s Internal Balance for `token` to `newBalance`.
     *
     * Emits an `InternalBalanceChanged` event. This event includes `delta`, which is the amount the balance increased
     * (if positive) or decreased (if negative). To avoid reading the current balance in order to compute the delta,
     * this function relies on the caller providing it directly.
     */
    function setInternalBalance(
        address account,
        IERC20 token,
        uint256 newBalance,
        int256 delta
    ) private {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.internalTokenBalance[account][token] = newBalance;
        emit InternalBalanceChanged(account, token, delta);
    }

    /**
     * @dev Returns `account`'s Internal Balance for `token`.
     */
    function getInternalBalance(address account, IERC20 token)
        internal
        view
        returns (uint256)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.internalTokenBalance[account][token];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;


/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

/*
 SPDX-License-Identifier: MIT
*/

pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import "../farm/AppStorage.sol";

/**
 * @author Publius
 * @title App Storage Library allows libaries to access Beanstalk's state.
**/
library LibAppStorage {

    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @author Publius
 * @title LibSafeMath128 is a uint128 variation of Open Zeppelin's Safe Math library.
**/
library LibSafeMath128 {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint128 a, uint128 b) internal pure returns (bool, uint128) {
        uint128 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint128 a, uint128 b) internal pure returns (bool, uint128) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint128 a, uint128 b) internal pure returns (bool, uint128) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint128 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint128 a, uint128 b) internal pure returns (bool, uint128) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint128 a, uint128 b) internal pure returns (bool, uint128) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
    function add(uint128 a, uint128 b) internal pure returns (uint128) {
        uint128 c = a + b;
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
    function sub(uint128 a, uint128 b) internal pure returns (uint128) {
        require(b <= a, "SafeMath: subtraction overflow");
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
    function mul(uint128 a, uint128 b) internal pure returns (uint128) {
        if (a == 0) return 0;
        uint128 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint128 a, uint128 b) internal pure returns (uint128) {
        require(b > 0, "SafeMath: division by zero");
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
    function mod(uint128 a, uint128 b) internal pure returns (uint128) {
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint128 a, uint128 b, string memory errorMessage) internal pure returns (uint128) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint128 a, uint128 b, string memory errorMessage) internal pure returns (uint128) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint128 a, uint128 b, string memory errorMessage) internal pure returns (uint128) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

/*
 SPDX-License-Identifier: MIT
*/

pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./LibAppStorage.sol";
import "../C.sol";

/**
 * @author Publius
 * @title Unripe
 **/

library LibUnripe {
    using SafeMath for uint256;

    event ChangeUnderlying(address indexed token, int256 underlying);

    uint256 constant DECIMALS = 1e6;

    function percentBeansRecapped() internal view returns (uint256 percent) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return
            s.u[C.unripeBeanAddress()].balanceOfUnderlying.mul(DECIMALS).div(
                C.unripeBean().totalSupply()
            );
    }

    function percentLPRecapped() internal view returns (uint256 percent) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return
            C.unripeLPPerDollar().mul(s.recapitalized).div(
                C.unripeLP().totalSupply()
            );
    }

    function incrementUnderlying(address token, uint256 amount) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.u[token].balanceOfUnderlying = s.u[token].balanceOfUnderlying.add(
            amount
        );
        emit ChangeUnderlying(token, int256(amount));
    }

    function decrementUnderlying(address token, uint256 amount) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.u[token].balanceOfUnderlying = s.u[token].balanceOfUnderlying.sub(
            amount
        );
        emit ChangeUnderlying(token, -int256(amount));
    }

    function unripeToUnderlying(address unripeToken, uint256 unripe)
        internal
        view
        returns (uint256 underlying)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        underlying = s.u[unripeToken].balanceOfUnderlying.mul(unripe).div(
            IBean(unripeToken).totalSupply()
        );
    }

    function underlyingToUnripe(address unripeToken, uint256 underlying)
        internal
        view
        returns (uint256 unripe)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        unripe = IBean(unripeToken).totalSupply().mul(underlying).div(
            s.u[unripeToken].balanceOfUnderlying
        );
    }

    function addUnderlying(address token, uint256 underlying) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (token == C.unripeLPAddress()) {
            uint256 recapped = underlying.mul(s.recapitalized).div(
                s.u[C.unripeLPAddress()].balanceOfUnderlying
            );
            s.recapitalized = s.recapitalized.add(recapped);
        }
        incrementUnderlying(token, underlying);
    }

    function removeUnderlying(address token, uint256 underlying) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (token == C.unripeLPAddress()) {
            uint256 recapped = underlying.mul(s.recapitalized).div(
                s.u[C.unripeLPAddress()].balanceOfUnderlying
            );
            s.recapitalized = s.recapitalized.sub(recapped);
        }
        decrementUnderlying(token, underlying);
    }
}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity =0.7.6;

interface ICurvePool {
    function A_precise() external view returns (uint256);
    function get_balances() external view returns (uint256[2] memory);
    function totalSupply() external view returns (uint256);
    function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount) external returns (uint256);
    function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 min_amount) external returns (uint256);
    function balances(int128 i) external view returns (uint256);
    function fee() external view returns (uint256);
    function coins(uint256 i) external view returns (address);
    function get_virtual_price() external view returns (uint256);
    function calc_token_amount(uint256[2] calldata amounts, bool deposit) external view returns (uint256);
    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external returns (uint256);
    function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy) external returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface ICurveZap {
    function add_liquidity(address _pool, uint256[4] memory _deposit_amounts, uint256 _min_mint_amount) external returns (uint256);
    function calc_token_amount(address _pool, uint256[4] memory _amounts, bool _is_deposit) external returns (uint256);
}

interface ICurvePoolR {
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy, address receiver) external returns (uint256);
    function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy, address receiver) external returns (uint256);
    function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 min_amount, address receiver) external returns (uint256);
}

interface ICurvePool2R {
    function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount, address reciever) external returns (uint256);
    function remove_liquidity(uint256 _burn_amount, uint256[2] memory _min_amounts, address reciever) external returns (uint256[2] calldata);
    function remove_liquidity_imbalance(uint256[2] memory _amounts, uint256 _max_burn_amount, address reciever) external returns (uint256);
}

interface ICurvePool3R {
    function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount, address reciever) external returns (uint256);
    function remove_liquidity(uint256 _burn_amount, uint256[3] memory _min_amounts, address reciever) external returns (uint256[3] calldata);
    function remove_liquidity_imbalance(uint256[3] memory _amounts, uint256 _max_burn_amount, address reciever) external returns (uint256);
}

interface ICurvePool4R {
    function add_liquidity(uint256[4] memory amounts, uint256 min_mint_amount, address reciever) external returns (uint256);
    function remove_liquidity(uint256 _burn_amount, uint256[4] memory _min_amounts, address reciever) external returns (uint256[4] calldata);
    function remove_liquidity_imbalance(uint256[4] memory _amounts, uint256 _max_burn_amount, address reciever) external returns (uint256);
}

interface I3Curve {
    function get_virtual_price() external view returns (uint256);
}

interface ICurveFactory {
    function get_coins(address _pool) external view returns (address[4] calldata);
    function get_underlying_coins(address _pool) external view returns (address[8] calldata);
}

interface ICurveCryptoFactory {
    function get_coins(address _pool) external view returns (address[8] calldata);
}

interface ICurvePoolC {
    function exchange(uint256 i, uint256 j, uint256 dx, uint256 min_dy) external returns (uint256);
}

interface ICurvePoolNoReturn {
    function exchange(uint256 i, uint256 j, uint256 dx, uint256 min_dy) external;
    function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount) external;
    function remove_liquidity(uint256 _burn_amount, uint256[3] memory _min_amounts) external;
    function remove_liquidity_imbalance(uint256[3] memory _amounts, uint256 _max_burn_amount) external;
    function remove_liquidity_one_coin(uint256 _token_amount, uint256 i, uint256 min_amount) external;
}

interface ICurvePoolNoReturn128 {
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external;
    function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 min_amount) external;
}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity =0.7.6;

interface IFertilizer {
    struct Balance {
        uint128 amount;
        uint128 lastBpf;
    }
    function beanstalkUpdate(
        address account,
        uint256[] memory ids,
        uint128 bpf
    ) external returns (uint256);
    function beanstalkMint(address account, uint256 id, uint128 amount, uint128 bpf) external;
    function balanceOfFertilized(address account, uint256[] memory ids) external view returns (uint256);
    function balanceOfUnfertilized(address account, uint256[] memory ids) external view returns (uint256);
    function lastBalanceOf(address account, uint256 id) external view returns (Balance memory);
    function lastBalanceOfBatch(address[] memory account, uint256[] memory id) external view returns (Balance[] memory);
    function setURI(string calldata newuri) external;
}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity =0.7.6;
interface IProxyAdmin {
    function upgrade(address proxy, address implementation) external;
}

/*
 SPDX-License-Identifier: MIT
*/

pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @title Decimal
 * @author dYdX
 *
 * Library that defines a fixed-point number with 18 decimal places.
 */
library Decimal {
    using SafeMath for uint256;

    // ============ Constants ============

    uint256 constant BASE = 10**18;

    // ============ Structs ============


    struct D256 {
        uint256 value;
    }

    // ============ Static Functions ============

    function zero()
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: 0 });
    }

    function one()
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: BASE });
    }

    function from(
        uint256 a
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: a.mul(BASE) });
    }

    function ratio(
        uint256 a,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: getPartial(a, BASE, b) });
    }

    // ============ Self Functions ============

    function add(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.add(b.mul(BASE)) });
    }

    function sub(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.sub(b.mul(BASE)) });
    }

    function sub(
        D256 memory self,
        uint256 b,
        string memory reason
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.sub(b.mul(BASE), reason) });
    }

    function mul(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.mul(b) });
    }

    function div(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.div(b) });
    }

    function pow(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        if (b == 0) {
            return one();
        }

        D256 memory temp = D256({ value: self.value });
        for (uint256 i = 1; i < b; ++i) {
            temp = mul(temp, self);
        }

        return temp;
    }

    function add(
        D256 memory self,
        D256 memory b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.add(b.value) });
    }

    function sub(
        D256 memory self,
        D256 memory b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.sub(b.value) });
    }

    function sub(
        D256 memory self,
        D256 memory b,
        string memory reason
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.sub(b.value, reason) });
    }

    function mul(
        D256 memory self,
        D256 memory b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: getPartial(self.value, b.value, BASE) });
    }

    function div(
        D256 memory self,
        D256 memory b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: getPartial(self.value, BASE, b.value) });
    }

    function equals(D256 memory self, D256 memory b) internal pure returns (bool) {
        return self.value == b.value;
    }

    function greaterThan(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) == 2;
    }

    function lessThan(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) == 0;
    }

    function greaterThanOrEqualTo(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) > 0;
    }

    function lessThanOrEqualTo(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) < 2;
    }

    function isZero(D256 memory self) internal pure returns (bool) {
        return self.value == 0;
    }

    function asUint256(D256 memory self) internal pure returns (uint256) {
        return self.value.div(BASE);
    }

    // ============ Core Methods ============

    function getPartial(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    )
    private
    pure
    returns (uint256)
    {
        return target.mul(numerator).div(denominator);
    }

    function compareTo(
        D256 memory a,
        D256 memory b
    )
    private
    pure
    returns (uint256)
    {
        if (a.value == b.value) {
            return 1;
        }
        return a.value > b.value ? 2 : 0;
    }
}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity =0.7.6;
// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupe {
    /// These functions are expected to be called frequently
    /// by tools.

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity =0.7.6;
interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}