/*
 * SPDX-License-Identifier: MIT
 */

pragma solidity = 0.8.16;

import "./TokenSilo.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../ReentrancyGuard.sol";

/*
 * @author Publius
 * @title SiloV2Facet handles depositing, withdrawing and claiming whitelisted Silo tokens.
 */
contract SiloV2Facet is TokenSilo {
    event TopcornAllocation(address indexed account, uint256 topcorns);

    struct SeasonClaim {
        address token;
        uint32 season;
    }

    struct SeasonsClaim {
        address token;
        uint32[] seasons;
    }

    struct WithdrawSeason {
        address token;
        uint32 season;
        uint256 amount;
    }

    struct WithdrawSeasons {
        address token;
        uint32[] seasons;
        uint256[] amounts;
    }

    /*
     * Deposit
     */

    function deposit(address token, uint256 amount) external updateSiloNonReentrant {
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        _deposit(token, amount);
    }

    /*
     * Withdraw
     */

    function withdrawTokenBySeason(
        address token,
        uint32 season,
        uint256 amount
    ) external updateSilo {
        _withdrawDeposit(token, season, amount);
        LibSilo.updateBalanceOfRainStalk(msg.sender);
    }

    function withdrawTokenBySeasons(
        address token,
        uint32[] calldata seasons,
        uint256[] calldata amounts
    ) external updateSilo {
        _withdrawDeposits(token, seasons, amounts);
        LibSilo.updateBalanceOfRainStalk(msg.sender);
    }

    function withdrawTokensBySeason(WithdrawSeason[] calldata withdraws) external updateSilo {
        for (uint256 i; i < withdraws.length; i++) {
            _withdrawDeposit(withdraws[i].token, withdraws[i].season, withdraws[i].amount);
        }
        LibSilo.updateBalanceOfRainStalk(msg.sender);
    }

    function withdrawTokensBySeasons(WithdrawSeasons[] calldata withdraws) external updateSilo {
        for (uint256 i; i < withdraws.length; i++) {
            _withdrawDeposits(withdraws[i].token, withdraws[i].seasons, withdraws[i].amounts);
        }
        LibSilo.updateBalanceOfRainStalk(msg.sender);
    }

    /*
     * Claim
     */

    function claimTokenBySeason(address token, uint32 season) external {
        _claimTokenBySeason(token, season);
    }

    function claimTokenBySeasons(address token, uint32[] calldata seasons) external {
        _claimTokenBySeasons(token, seasons);
    }

    function claimTokensBySeason(SeasonClaim[] calldata claims) external {
        for (uint256 i; i < claims.length; i++) {
            _claimTokenBySeason(claims[i].token, claims[i].season);
        }
    }

    function claimTokensBySeasons(SeasonsClaim[] calldata claims) external {
        for (uint256 i; i < claims.length; i++) {
            _claimTokenBySeasons(claims[i].token, claims[i].seasons);
        }
    }

    function _claimTokenBySeasons(address token, uint32[] calldata seasons) private {
        uint256 amount = removeTokenWithdrawals(msg.sender, token, seasons);
        IERC20(token).transfer(msg.sender, amount);
        emit ClaimSeasons(msg.sender, token, seasons, amount);
    }

    function _claimTokenBySeason(address token, uint32 season) private {
        uint256 amount = removeTokenWithdrawal(msg.sender, token, season);
        IERC20(token).transfer(msg.sender, amount);
        emit ClaimSeason(msg.sender, token, season, amount);
    }

    /*
     * Whitelist
     */

    function whitelistToken(
        address token,
        bytes4 selector,
        uint32 stalk,
        uint32 seeds
    ) external {
        require(msg.sender == address(this), "Silo: Only Farmer can whitelist tokens.");
        s.ss[token].selector = selector;
        s.ss[token].stalk = stalk;
        s.ss[token].seeds = seeds;
    }

    function tokenSettings(address token) external view returns (Storage.SiloSettings memory) {
        return s.ss[token];
    }
}

/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity = 0.8.16;

import "../../../libraries/Silo/LibTokenSilo.sol";
import "../../../libraries/Silo/LibSilo.sol";
import "../../../libraries/LibInternal.sol";
import "../../ReentrancyGuard.sol";

/**
 * @author Publius
 * @title Token Silo
 **/
contract TokenSilo is ReentrancyGuard {
    event Deposit(address indexed account, address indexed token, uint256 season, uint256 amount, uint256 tdv);
    event RemoveSeasons(address indexed account, address indexed token, uint32[] seasons, uint256[] amounts, uint256 amount);
    event RemoveSeason(address indexed account, address indexed token, uint32 season, uint256 amount);

    event Withdraw(address indexed account, address indexed token, uint32 season, uint256 amount);
    event ClaimSeasons(address indexed account, address indexed token, uint32[] seasons, uint256 amount);
    event ClaimSeason(address indexed account, address indexed token, uint32 season, uint256 amount);

    struct AssetsRemoved {
        uint256 tokensRemoved;
        uint256 stalkRemoved;
        uint256 seedsRemoved;
    }

    /**
     * Getters
     **/

    function getDeposit(
        address account,
        address token,
        uint32 season
    ) external view returns (uint256, uint256) {
        return LibTokenSilo.tokenDeposit(account, token, season);
    }

    function getWithdrawal(
        address account,
        address token,
        uint32 season
    ) external view returns (uint256) {
        return LibTokenSilo.tokenWithdrawal(account, token, season);
    }

    function getTotalDeposited(address token) external view returns (uint256) {
        return s.siloBalances[token].deposited;
    }

    function getTotalWithdrawn(address token) external view returns (uint256) {
        return s.siloBalances[token].withdrawn;
    }

    /**
     * Internal
     **/

    function _deposit(address token, uint256 amount) internal {
        LibInternal.updateSilo(msg.sender);
        (uint256 seeds, uint256 stalk) = LibTokenSilo.deposit(msg.sender, token, _season(), amount);
        LibSilo.depositSiloAssets(msg.sender, seeds, stalk);
    }

    function _withdrawDeposits(
        address token,
        uint32[] calldata seasons,
        uint256[] calldata amounts
    ) internal {
        require(seasons.length == amounts.length, "Silo: Crates, amounts are diff lengths.");
        AssetsRemoved memory ar = removeDeposits(token, seasons, amounts);
        uint32 arrivalSeason = _season() + s.season.withdrawSeasons;
        addTokenWithdrawal(msg.sender, token, arrivalSeason, ar.tokensRemoved);
        LibTokenSilo.decrementDepositedToken(token, ar.tokensRemoved);
        LibSilo.withdrawSiloAssets(msg.sender, ar.seedsRemoved, ar.stalkRemoved);
        LibSilo.updateBalanceOfRainStalk(msg.sender);
    }

    function _withdrawDeposit(
        address token,
        uint32 season,
        uint256 amount
    ) internal {
        (uint256 tokensRemoved, uint256 stalkRemoved, uint256 seedsRemoved) = removeDeposit(token, season, amount);
        uint32 arrivalSeason = _season() + s.season.withdrawSeasons;
        addTokenWithdrawal(msg.sender, token, arrivalSeason, tokensRemoved);
        LibTokenSilo.decrementDepositedToken(token, tokensRemoved);
        LibSilo.withdrawSiloAssets(msg.sender, seedsRemoved, stalkRemoved);
    }

    function removeDeposit(
        address token,
        uint32 season,
        uint256 amount
    )
        private
        returns (
            uint256 tokensRemoved,
            uint256 stalkRemoved,
            uint256 seedsRemoved
        )
    {
        uint256 tdv;
        (tokensRemoved, tdv) = LibTokenSilo.removeDeposit(msg.sender, token, season, amount);
        seedsRemoved = tdv * (s.ss[token].seeds);
        stalkRemoved = tdv * (s.ss[token].stalk) + (LibSilo.stalkReward(seedsRemoved, _season() - season));
        emit RemoveSeason(msg.sender, token, season, amount);
    }

    function removeDeposits(
        address token,
        uint32[] calldata seasons,
        uint256[] calldata amounts
    ) private returns (AssetsRemoved memory ar) {
        uint256 tdvRemoved;
        for (uint256 i; i < seasons.length; i++) {
            (uint256 crateTokens, uint256 crateTdv) = LibTokenSilo.removeDeposit(msg.sender, token, seasons[i], amounts[i]);
            tdvRemoved = tdvRemoved + crateTdv;
            ar.tokensRemoved = ar.tokensRemoved + crateTokens;
            ar.stalkRemoved = ar.stalkRemoved + (LibSilo.stalkReward(crateTdv * (s.ss[token].seeds), _season() - seasons[i]));
        }
        ar.seedsRemoved = tdvRemoved * (s.ss[token].seeds);
        ar.stalkRemoved = ar.stalkRemoved + (tdvRemoved * (s.ss[token].stalk));
        emit RemoveSeasons(msg.sender, token, seasons, amounts, ar.tokensRemoved);
    }

    function addTokenWithdrawal(
        address account,
        address token,
        uint32 arrivalSeason,
        uint256 amount
    ) private {
        s.a[account].withdrawals[token][arrivalSeason] = s.a[account].withdrawals[token][arrivalSeason] + amount;
        s.siloBalances[token].withdrawn = s.siloBalances[token].withdrawn + amount;
        emit Withdraw(msg.sender, token, arrivalSeason, amount);
    }

    function removeTokenWithdrawals(
        address account,
        address token,
        uint32[] calldata seasons
    ) internal returns (uint256 amount) {
        for (uint256 i; i < seasons.length; i++) {
            amount = amount + (_removeTokenWithdrawal(account, token, seasons[i]));
        }
        s.siloBalances[token].withdrawn = s.siloBalances[token].withdrawn - amount;
        return amount;
    }

    function removeTokenWithdrawal(
        address account,
        address token,
        uint32 season
    ) internal returns (uint256) {
        uint256 amount = _removeTokenWithdrawal(account, token, season);
        s.siloBalances[token].withdrawn = s.siloBalances[token].withdrawn - amount;
        return amount;
    }

    function _removeTokenWithdrawal(
        address account,
        address token,
        uint32 season
    ) private returns (uint256) {
        require(season <= s.season.current, "Claim: Withdrawal not recievable.");
        uint256 amount = s.a[account].withdrawals[token][season];
        delete s.a[account].withdrawals[token][season];
        return amount;
    }

    function _season() private view returns (uint32) {
        return s.season.current;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

pragma solidity = 0.8.16;

import "../libraries/LibInternal.sol";
import "./AppStorage.sol";

/**
 * @author Farmer Farms
 * @title Variation of Oepn Zeppelins reentrant guard to include Silo Update
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts%2Fsecurity%2FReentrancyGuard.sol
 **/
abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    AppStorage internal s;

    modifier updateSilo() {
        LibInternal.updateSilo(msg.sender);
        _;
    }
    
    modifier updateSiloNonReentrant() {
        require(s.reentrantStatus != _ENTERED, "ReentrancyGuard: reentrant call");
        s.reentrantStatus = _ENTERED;
        LibInternal.updateSilo(msg.sender);
        _;
        s.reentrantStatus = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(s.reentrantStatus != _ENTERED, "ReentrancyGuard: reentrant call");
        s.reentrantStatus = _ENTERED;
        _;
        s.reentrantStatus = _NOT_ENTERED;
    }
}

/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity = 0.8.16;

import "../../interfaces/pancake/IPancakePair.sol";
import "../LibAppStorage.sol";
import "../../C.sol";

/**
 * @author Publius
 * @title Lib Token Silo
 **/
library LibTokenSilo {
    event Deposit(address indexed account, address indexed token, uint256 season, uint256 amount, uint256 tdv);

    /*
     * Deposit
     */

    function deposit(
        address account,
        address token,
        uint32 _s,
        uint256 amount
    ) internal returns (uint256, uint256) {
        uint256 tdv = tokenDenominatedValue(token, amount);
        return depositWithTDV(account, token, _s, amount, tdv);
    }

    function depositWithTDV(
        address account,
        address token,
        uint32 _s,
        uint256 amount,
        uint256 tdv
    ) internal returns (uint256, uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(tdv > 0, "Silo: No Topcorns under Token.");
        incrementDepositedToken(token, amount);
        addDeposit(account, token, _s, amount, tdv);
        return (tdv * (s.ss[token].seeds), tdv * (s.ss[token].stalk));
    }

    function incrementDepositedToken(address token, uint256 amount) private {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.siloBalances[token].deposited = s.siloBalances[token].deposited + amount;
    }

    function addDeposit(
        address account,
        address token,
        uint32 _s,
        uint256 amount,
        uint256 tdv
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.a[account].deposits[token][_s].amount += uint128(amount);
        s.a[account].deposits[token][_s].tdv += uint128(tdv);
        emit Deposit(account, token, _s, amount, tdv);
    }

    function decrementDepositedToken(address token, uint256 amount) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.siloBalances[token].deposited = s.siloBalances[token].deposited - amount;
    }

    /*
     * Remove
     */

    function removeDeposit(
        address account,
        address token,
        uint32 id,
        uint256 amount
    ) internal returns (uint256, uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        (uint256 crateAmount, uint256 crateBase) = tokenDeposit(account, token, id);
        require(crateAmount >= amount, "Silo: Crate balance too low.");
        if (amount < crateAmount) {
            uint256 base = (amount * crateBase) / crateAmount;
            uint256 newBase = uint256(s.a[account].deposits[token][id].tdv) - base;
            uint256 newAmount = uint256(s.a[account].deposits[token][id].amount) - amount;
            require(newBase <= type(uint128).max && newAmount <= type(uint128).max, "Silo: uint128 overflow.");
            s.a[account].deposits[token][id].amount = uint128(newAmount);
            s.a[account].deposits[token][id].tdv = uint128(newBase);
            return (amount, base);
        } else {
            delete s.a[account].deposits[token][id];
            return (crateAmount, crateBase);
        }
    }

    /*
     * Getters
     */

    function tokenDeposit(
        address account,
        address token,
        uint32 id
    ) internal view returns (uint256, uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return (s.a[account].deposits[token][id].amount, s.a[account].deposits[token][id].tdv);
    }

    function tokenDenominatedValue(address token, uint256 amount) private returns (uint256 bdv) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        bytes memory myFunctionCall = abi.encodeWithSelector(s.ss[token].selector, token, amount);
        (bool success, bytes memory data) = address(this).delegatecall(myFunctionCall);
        require(success, "Silo: TopCorn denominated value failed.");
        assembly {
            bdv := mload(add(data, add(0x20, 0)))
        }
    }

    function tokenWithdrawal(
        address account,
        address token,
        uint32 id
    ) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.a[account].withdrawals[token][id];
    }
}

/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity = 0.8.16;

import "../../C.sol";
import "../LibAppStorage.sol";

/**
 * @author Publius
 * @title Lib Silo
 **/
library LibSilo {
    using Decimal for Decimal.D256;

    event TopcornDeposit(address indexed account, uint256 season, uint256 topcorns);

    /**
     * Silo
     **/

    function depositSiloAssets(
        address account,
        uint256 seeds,
        uint256 stalk
    ) internal {
        incrementBalanceOfStalk(account, stalk);
        incrementBalanceOfSeeds(account, seeds);
    }

    function withdrawSiloAssets(
        address account,
        uint256 seeds,
        uint256 stalk
    ) internal {
        decrementBalanceOfStalk(account, stalk);
        decrementBalanceOfSeeds(account, seeds);
    }

    function incrementBalanceOfSeeds(address account, uint256 seeds) private {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.s.seeds = s.s.seeds + seeds;
        s.a[account].s.seeds = s.a[account].s.seeds + seeds;
    }

    function incrementBalanceOfStalk(address account, uint256 stalk) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 roots;
        if (s.s.roots == 0) roots = stalk * C.getRootsBase();
        else roots = (s.s.roots * stalk) / s.s.stalk;

        s.s.stalk = s.s.stalk + stalk;
        s.a[account].s.stalk = s.a[account].s.stalk + stalk;

        s.s.roots = s.s.roots + roots;
        s.a[account].roots = s.a[account].roots + roots;
    }

    function decrementBalanceOfSeeds(address account, uint256 seeds) private {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.s.seeds = s.s.seeds - seeds;
        s.a[account].s.seeds = s.a[account].s.seeds - seeds;
    }

    function decrementBalanceOfStalk(address account, uint256 stalk) private {
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (stalk == 0) return;
        uint256 roots = (s.a[account].roots * stalk - 1) / s.a[account].s.stalk + 1;

        s.s.stalk = s.s.stalk - stalk;
        s.a[account].s.stalk = s.a[account].s.stalk - stalk;

        s.s.roots = s.s.roots - roots;
        s.a[account].roots = s.a[account].roots - roots;
    }

    function updateBalanceOfRainStalk(address account) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (!s.r.raining) return;
        if (s.a[account].roots < s.a[account].sop.roots) {
            s.r.roots = s.r.roots - (s.a[account].sop.roots - s.a[account].roots);
            s.a[account].sop.roots = s.a[account].roots;
        }
    }

    function stalkReward(uint256 seeds, uint32 seasons) internal pure returns (uint256) {
        return seeds * seasons;
    }

    function season() internal view returns (uint32) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.season.current;
    }
}

/*
 SPDX-License-Identifier: MIT
*/

pragma solidity = 0.8.16;

/**
 * @author Publius
 * @title Internal Library handles gas efficient function calls between facets.
 **/

interface ISiloUpdate {
    function updateSilo(address account) external payable;
}

library LibInternal {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint16 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint16 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        address[] facetAddresses;
        mapping(bytes4 => bool) supportedInterfaces;
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function updateSilo(address account) internal {
        DiamondStorage storage ds = diamondStorage();
        address facet = ds.selectorToFacetAndPosition[ISiloUpdate.updateSilo.selector].facetAddress;
        bytes memory myFunctionCall = abi.encodeWithSelector(ISiloUpdate.updateSilo.selector, account);
        (bool success, ) = address(facet).delegatecall(myFunctionCall);
        require(success, "Silo: updateSilo failed.");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;

/**
 * @author Stanislav
 * @title Pancake Pair Interface
 **/
interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

/*
 SPDX-License-Identifier: MIT
*/

pragma solidity = 0.8.16;

import "../farm/AppStorage.sol";

/**
 * @author Publius
 * @title App Storage Library allows libaries to access Farmer's state.
 **/
library LibAppStorage {
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }
}

/*
 SPDX-License-Identifier: MIT
*/

pragma solidity = 0.8.16;

import "./interfaces/pancake/IPancakePair.sol";
import "./interfaces/ITopcorn.sol";
import "./libraries/Decimal.sol";

/**
 * @author Publius
 * @title C holds the contracts for Farmer.
 **/
library C {
    using Decimal for Decimal.D256;

    // Constants
    uint256 private constant PERCENT_BASE = 1e18; // BSC

    // Chain
    uint256 private constant CHAIN_ID = 56; // BSC

    // Season
    uint256 private constant CURRENT_SEASON_PERIOD = 3600; // 1 hour
    uint256 private constant REWARD_MULTIPLIER = 1;
    uint256 private constant MAX_TIME_MULTIPLIER = 300; // seconds

    // Sun
    uint256 private constant HARVESET_PERCENTAGE = 0.5e18; // 50%

    // Weather
    uint256 private constant POD_RATE_LOWER_BOUND = 0.05e18; // 5%
    uint256 private constant OPTIMAL_POD_RATE = 0.15e18; // 15%
    uint256 private constant POD_RATE_UPPER_BOUND = 0.25e18; // 25%

    uint256 private constant DELTA_POD_DEMAND_LOWER_BOUND = 0.95e18; // 95%
    uint256 private constant DELTA_POD_DEMAND_UPPER_BOUND = 1.05e18; // 105%

    uint32 private constant STEADY_SOW_TIME = 60; // 1 minute
    uint256 private constant RAIN_TIME = 24; // 24 seasons = 1 day

    // Silo
    uint256 private constant BASE_ADVANCE_INCENTIVE = 100e18; // 100 topcorn
    uint32 private constant WITHDRAW_TIME = 25; // 24 + 1 seasons
    uint256 private constant SEEDS_PER_TOPCORN = 2;
    uint256 private constant SEEDS_PER_LP_TOPCORN = 4;
    uint256 private constant STALK_PER_TOPCORN = 10000;
    uint256 private constant ROOTS_BASE = 1e12;

    // Bsc contracts
    address private constant FACTORY = address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    address private constant ROUTER = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address private constant PEG_PAIR = address(0x8CAd25b511cEeFF2F20FeA5825A6993113Aa8211);
    address private constant BUSD_TOKEN = address(0xf76D4a441E4ba86A923ce32B89AFF89dBccAA075);  // comp

    /**
     * Getters
     **/

    function getSeasonPeriod() internal pure returns (uint256) {
        return CURRENT_SEASON_PERIOD;
    }

    function getAdvanceIncentive() internal pure returns (uint256) {
        return BASE_ADVANCE_INCENTIVE;
    }

    function getSiloWithdrawSeasons() internal pure returns (uint32) {
        return WITHDRAW_TIME;
    }

    function getHarvestPercentage() internal pure returns (uint256) {
        return HARVESET_PERCENTAGE;
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

    function getRainTime() internal pure returns (uint256) {
        return RAIN_TIME;
    }

    function getSeedsPerTopcorn() internal pure returns (uint256) {
        return SEEDS_PER_TOPCORN;
    }

    function getSeedsPerLP() internal pure returns (uint256) {
        return SEEDS_PER_LP_TOPCORN;
    }

    function getStalkPerTopcorn() internal pure returns (uint256) {
        return STALK_PER_TOPCORN;
    }

    function getStalkPerLPSeed() internal pure returns (uint256) {
        return STALK_PER_TOPCORN / SEEDS_PER_LP_TOPCORN;
    }

    function getRootsBase() internal pure returns (uint256) {
        return ROOTS_BASE;
    }

    function getFactory() internal pure returns (address) {
        return FACTORY;
    }

    function getRouter() internal pure returns (address) {
        return ROUTER;
    }

    function getPegPair() internal pure returns (address) {
        return PEG_PAIR;
    }

    function getRewardMultiplier() internal pure returns (uint256) {
        return REWARD_MULTIPLIER;
    }

    function getMaxTimeMultiplier() internal pure returns (uint256) {
        return MAX_TIME_MULTIPLIER;
    }

    function getBUSD() internal pure returns (address) {
        return BUSD_TOKEN;
    }
}

/*
 SPDX-License-Identifier: MIT
*/

pragma solidity = 0.8.16;

import "../interfaces/IDiamondCut.sol";

/**
 * @author Publius
 * @title App Storage defines the state object for Farmer.
 **/
contract Account {
    // Field stores a Farmer's Plots and Pod allowances.
    struct Field {
        mapping(uint256 => uint256) plots; // A Farmer's Plots. Maps from Plot index to Pod amount.
        mapping(address => uint256) podAllowances; // An allowance mapping for Pods similar to that of the ERC-20 standard. Maps from spender address to allowance amount.
    }

    // Asset Silo is a struct that stores Deposits and Seeds per Deposit, and stored Withdrawals.
    struct AssetSilo {
        mapping(uint32 => uint256) withdrawals;
        mapping(uint32 => uint256) deposits;
        mapping(uint32 => uint256) depositSeeds;
    }

    // Deposit represents a Deposit in the Silo of a given Token at a given Season.
    // Stored as two uint128 state variables to save gas.
    struct Deposit {
        uint128 amount;
        uint128 tdv;
    }

    // Silo stores Silo-related balances
    struct Silo {
        uint256 stalk; // Balance of the Farmer's normal Stalk.
        uint256 seeds; // Balance of the Farmer's normal Seeds.
    }

    // Season Of Plenty stores Season of Plenty (SOP) related balances
    struct SeasonOfPlenty {
        uint256 base;
        uint256 roots; // The number of Roots a Farmer had when it started Raining.
        uint256 basePerRoot;
    }

    // The Account level State stores all of the Farmer's balances in the contract.
    struct State {
        Field field; // A Farmer's Field storage.
        AssetSilo topcorn;
        AssetSilo lp;
        Silo s; // A Farmer's Silo storage. 
        uint32 lastUpdate; // The Season in which the Farmer last updated their Silo.
        uint32 lastSop; // The last Season that a SOP occured at the time the Farmer last updated their Silo.
        uint32 lastRain; // The last Season that it started Raining at the time the Farmer last updated their Silo.
        SeasonOfPlenty sop; // A Farmer's Season Of Plenty storage.
        uint256 roots; // A Farmer's Root balance.
        uint256 wrappedTopcorns;
        mapping(address => mapping(uint32 => Deposit)) deposits;  // A Farmer's Silo Deposits stored as a map from Token address to Season of Deposit to Deposit.
        mapping(address => mapping(uint32 => uint256)) withdrawals;  // A Farmer's Withdrawals from the Silo stored as a map from Token address to Season the Withdrawal becomes Claimable to Withdrawn amount of Tokens.
    }
}

contract Storage {
    // Contracts stored the contract addresses of various important contracts to Farm.
    struct Contracts {
        address topcorn;
        address pair;
        address pegPair;
        address wbnb;
    }

    // Field stores global Field balances.
    struct Field {
        uint256 soil; // The number of Soil currently available.
        uint256 pods; // The pod index; the total number of Pods ever minted.
        uint256 harvested; // The harvested index; the total number of Pods that have ever been Harvested.
        uint256 harvestable; // The harvestable index; the total number of Pods that have ever been Harvestable. Included previously Harvested Topcorns.
    }

    // Silo
    struct AssetSilo {
        uint256 deposited; // The total number of a given Token currently Deposited in the Silo.
        uint256 withdrawn; // The total number of a given Token currently Withdrawn From the Silo but not Claimed.
    }

    struct SeasonOfPlenty {
        uint256 wbnb;
        uint256 base;
        uint32 last;
    }

    struct Silo {
        uint256 stalk;
        uint256 seeds;
        uint256 roots;
        uint256 topcorns;
    }

    // Oracle stores global level Oracle balances.
    // Currently the oracle refers to the time weighted average price calculated from the Topcorn:BNB - usd:BNB.
    struct Oracle {
        bool initialized;  // True if the Oracle has been initialzed. It needs to be initialized on Deployment and re-initialized each Unpause.
        uint256 cumulative;
        uint256 pegCumulative;
        uint32 timestamp;  // The timestamp of the start of the current Season.
        uint32 pegTimestamp;
    }

    // Rain stores global level Rain balances. (Rain is when P > 1, Pod rate Excessively Low).
    struct Rain {
        uint32 start;
        bool raining;
        uint256 pods; // The number of Pods when it last started Raining.
        uint256 roots; // The number of Roots when it last started Raining.
    }

    // Sesaon stores global level Season balances.
    struct Season {
        // The first storage slot in Season is filled with a variety of somewhat unrelated storage variables.
        // Given that they are all smaller numbers, they are stored together for gas efficient read/write operations. 
        // Apologies if this makes it confusing :(
        uint32 current; // The current Season in Farm.
        uint8 withdrawSeasons; // The number of seasons required to Withdraw a Deposit.
        uint256 start; // The timestamp of the Farm deployment rounded down to the nearest hour.
        uint256 period; // The length of each season in Farm.
        uint256 timestamp; // The timestamp of the start of the current Season.
        uint256 rewardMultiplier; // Multiplier for incentivize 
        uint256 maxTimeMultiplier; // Multiplier for incentivize 
        uint256 costSunrice; // For Incentivize, gas limit per function call sunrise()
    }

    // Weather stores global level Weather balances.
    struct Weather {
        uint256 startSoil; // The number of Soil at the start of the current Season.
        uint256 lastDSoil; // Delta Soil; the number of Soil purchased last Season.
        uint32 lastSowTime; // The number of seconds it took for all but at most 1 Soil to sell out last Season.
        uint32 nextSowTime; // The number of seconds it took for all but at most 1 Soil to sell out this Season
        uint32 yield; // Weather; the interest rate for sowing Topcorns in Soil.
    }

    // SiloSettings stores the settings for each Token that has been Whitelisted into the Silo.
    // A Token is considered whitelisted in the Silo if there exists a non-zero SiloSettings selector.
    struct SiloSettings {
        bytes4 selector; // The encoded TDV function selector for the Token.
        uint32 seeds; // The Seeds Per TDV that the Silo mints in exchange for Depositing this Token.
        uint32 stalk; // The Stalk Per TDV that the Silo mints in exchange for Depositing this Token.
    }
}

struct AppStorage {
    uint8 index; // The index of the Topcorn token in the Topcorn:BNB Pancakeswap v2 pool
    int8[32] cases; // The 24 Weather cases (array has 32 items, but caseId = 3 (mod 4) are not cases).
    bool paused; // True if Farm is Paused.
    uint128 pausedAt; // The timestamp at which Farm was last paused. 
    Storage.Season season; // The Season storage struct found above.
    Storage.Contracts c;
    Storage.Field f; // The Field storage struct found above.
    Storage.Oracle o; // The Oracle storage struct found above.
    Storage.Rain r; // The Rain storage struct found above.
    Storage.Silo s; // The Silo storage struct found above.
    uint256 reentrantStatus; // An intra-transaction state variable to protect against reentrance
    Storage.Weather w; // The Weather storage struct found above.
    Storage.AssetSilo topcorn;
    Storage.AssetSilo lp;
    Storage.SeasonOfPlenty sop;
    mapping(uint32 => uint256) sops; // A mapping from Season to Plenty Per Root (PPR) in that Season. Plenty Per Root is 0 if a Season of Plenty did not occur.
    mapping(address => Account.State) a; // A mapping from Farmer address to Account state.
    mapping(uint256 => bytes32) podListings; // A mapping from Plot Index to the hash of the Pod Listing.
    mapping(bytes32 => uint256) podOrders; // A mapping from the hash of a Pod Order to the amount of Pods that the Pod Order is still willing to buy.
    mapping(address => Storage.AssetSilo) siloBalances; // A mapping from Token address to Silo Balance storage (amount deposited and withdrawn).
    mapping(address => Storage.SiloSettings) ss;  // A mapping from Token address to Silo Settings for each Whitelisted Token. If a non-zero storage exists, a Token is whitelisted.
    // These refund variables are intra-transaction state varables use to store refund amounts
    uint256 refundStatus;
    uint256 topcornRefundAmount;
    uint256 bnbRefundAmount;
    uint8 pegIndex; // The index of the BUSD token in the BUSD:BNB PancakeSwap v2 pool
}

// SPDX-License-Identifier: MIT
pragma solidity = 0.8.16;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }

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

/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity = 0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @author Publius
 * @title TopCorn Interface
 **/
abstract contract ITopcorn is IERC20 {
    function burn(uint256 amount) public virtual;

    function burnFrom(address account, uint256 amount) public virtual;

    function mint(address account, uint256 amount) public virtual returns (bool);
}

/*
 SPDX-License-Identifier: MIT
*/

pragma solidity = 0.8.16;

/**
 * @title Decimal
 * @author dYdX
 *
 * Library that defines a fixed-point number with 18 decimal places.
 */
library Decimal {
    // ============ Constants ============

    uint256 constant BASE = 10**18;

    // ============ Structs ============

    struct D256 {
        uint256 value;
    }

    // ============ Static Functions ============

    function zero() internal pure returns (D256 memory) {
        return D256({value: 0});
    }

    function one() internal pure returns (D256 memory) {
        return D256({value: BASE});
    }

    function from(uint256 a) internal pure returns (D256 memory) {
        return D256({value: a * (BASE)});
    }

    function ratio(uint256 a, uint256 b) internal pure returns (D256 memory) {
        return D256({value: getPartial(a, BASE, b)});
    }

    // ============ Self Functions ============

    function add(D256 memory self, uint256 b) internal pure returns (D256 memory) {
        return D256({value: self.value + (b * (BASE))});
    }

    function sub(D256 memory self, uint256 b) internal pure returns (D256 memory) {
        return D256({value: self.value - (b * (BASE))});
    }

    function sub(
        D256 memory self,
        uint256 b,
        string memory reason
    ) internal pure returns (D256 memory) {
        require(self.value >= b * BASE, reason);
        return D256({value: self.value - (b * (BASE))});
    }

    function mul(D256 memory self, uint256 b) internal pure returns (D256 memory) {
        return D256({value: self.value * (b)});
    }

    function div(D256 memory self, uint256 b) internal pure returns (D256 memory) {
        return D256({value: self.value / (b)});
    }

    function pow(D256 memory self, uint256 b) internal pure returns (D256 memory) {
        if (b == 0) {
            return one();
        }

        D256 memory temp = D256({value: self.value});
        for (uint256 i = 1; i < b; i++) {
            temp = mul(temp, self);
        }

        return temp;
    }

    function add(D256 memory self, D256 memory b) internal pure returns (D256 memory) {
        return D256({value: self.value + (b.value)});
    }

    function sub(D256 memory self, D256 memory b) internal pure returns (D256 memory) {
        return D256({value: self.value - (b.value)});
    }

    function sub(
        D256 memory self,
        D256 memory b,
        string memory reason
    ) internal pure returns (D256 memory) {
        require(self.value >= b.value, reason);
        return D256({value: self.value - (b.value)});
    }

    function mul(D256 memory self, D256 memory b) internal pure returns (D256 memory) {
        return D256({value: getPartial(self.value, b.value, BASE)});
    }

    function div(D256 memory self, D256 memory b) internal pure returns (D256 memory) {
        return D256({value: getPartial(self.value, BASE, b.value)});
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
        return self.value / (BASE);
    }

    // ============ Core Methods ============

    function getPartial(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    ) private pure returns (uint256) {
        return (target * (numerator)) / (denominator);
    }

    function compareTo(D256 memory a, D256 memory b) private pure returns (uint256) {
        if (a.value == b.value) {
            return 1;
        }
        return a.value > b.value ? 2 : 0;
    }
}