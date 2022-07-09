// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./LaunchPadLib.sol";
import "./AuxLibrary.sol";

interface ILocker {
    function unlockCycles() view external returns(uint);
    function unlockSchedule(uint cycle) view external returns(AuxLibrary.UnlockScheduleInternal memory);
    function lockerInfo() view external returns(AuxLibrary.LockerInfo memory);
}

interface IPresale {
    function tokenInfo() view external returns(LaunchPadLib.TokenInfo memory);
    function presaleTimes() view external returns(LaunchPadLib.PresaleTimes memory);
    function finalizingTime() view external returns(uint);
    function temaVestingCycles() view external returns(uint);
    function teamVestingRecord(uint cycle) view external returns(AuxLibrary.TeamVestingRecordInternal memory);
    function teamVesting() view external returns(LaunchPadLib.TeamVesting memory);

    function participant(address _address) view external returns(AuxLibrary.Participant memory);
    function contributorVestingRecord(uint cycle) view external returns(AuxLibrary.ContributorsVestingRecordInternal memory);
    function contributorCycles() view external returns(uint);
    function getContributorReleaseStatus(uint _time, address _address) view external returns(uint8);
}

contract Auxilliary {

    function getLockerSchedule(ILocker locker) public view returns(AuxLibrary.UnlockSchedule[] memory)  {
        uint tokensLocked = locker.lockerInfo().numOfTokensLocked;
        uint cycles = locker.unlockCycles();
        AuxLibrary.UnlockSchedule[] memory unlockSchedule = new AuxLibrary.UnlockSchedule[](cycles+1);

        for(uint i=0; i <= cycles; i++){
            AuxLibrary.UnlockScheduleInternal memory schedule = locker.unlockSchedule(i);
            unlockSchedule[i].cycle = schedule.cycle;
            unlockSchedule[i].releaseTime = schedule.releaseTime;
            unlockSchedule[i].tokens = tokensLocked * schedule.percentageToRelease * schedule.tokensPC / 10000;
            unlockSchedule[i].releaseStatus = schedule.releaseStatus;
        }

        return unlockSchedule;
    }

    function getTeamVestingSchedule(IPresale presale) public view returns(AuxLibrary.TeamVestingRecord[] memory)  {
        uint decimals = presale.tokenInfo().decimals;
        uint tokensLocked = presale.teamVesting().vestingTokens;
        uint finalizingTime = presale.finalizingTime();
        uint expiredAt = presale.presaleTimes().expiredAt;

        if (finalizingTime == 0) {
            finalizingTime = expiredAt;
        }

        uint cycles = presale.temaVestingCycles();
        AuxLibrary.TeamVestingRecord[] memory unlockSchedule = new AuxLibrary.TeamVestingRecord[](cycles+1);

        for(uint i=0; i <= cycles; i++){
            AuxLibrary.TeamVestingRecordInternal memory schedule = presale.teamVestingRecord(i);
            unlockSchedule[i].cycle = schedule.cycle;
            unlockSchedule[i].releaseTime = finalizingTime + schedule.releaseTime;
            unlockSchedule[i].tokens = (tokensLocked * schedule.percentageToRelease * schedule.tokensPC * (10**decimals)) / 10000;
            unlockSchedule[i].releaseStatus = schedule.releaseStatus;
        }

        return unlockSchedule;

    }

    function getContributorVestingSchedule(IPresale presale, address _address) public view returns(AuxLibrary.ContributorsVestingRecord[] memory)  {
        uint tokens = presale.participant(_address).tokens;
        uint finalizingTime = presale.finalizingTime();
        uint expiredAt = presale.presaleTimes().expiredAt;

        if (finalizingTime == 0) {
            finalizingTime = expiredAt;
        }

        uint cycles = presale.contributorCycles();
        AuxLibrary.ContributorsVestingRecord[] memory unlockSchedule = new AuxLibrary.ContributorsVestingRecord[](cycles+1);

        for (uint i=0; i <= cycles; i++){
            AuxLibrary.ContributorsVestingRecordInternal memory schedule = presale.contributorVestingRecord(i);
            uint8 releaseStatus = presale.getContributorReleaseStatus(finalizingTime + schedule.releaseTime, _address);
            unlockSchedule[i].cycle = schedule.cycle;
            unlockSchedule[i].releaseTime = finalizingTime + schedule.releaseTime;
            unlockSchedule[i].tokens = (tokens * schedule.percentageToRelease * schedule.tokensPC ) / 10000;
            unlockSchedule[i].releaseStatus = releaseStatus;
        }

        return unlockSchedule;

    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
pragma solidity 0.8.7;


library LaunchPadLib {

    enum PresaleType {PUBLIC, WHITELISTED, TOKENHOLDERS}
    enum PreSaleStatus {PENDING, INPROGRESS, SUCCEED, FAILED, CANCELED}
    enum RefundType {BURN, WITHDRAW}

    struct PresaleInfo {
        uint id;
        address presaleOwner;
        PreSaleStatus preSaleStatus;
    }

    struct TokenInfo {
        address tokenAddress;
        uint8 decimals;
    }

    struct ParticipationCriteria {
        PresaleType presaleType;
        address criteriaToken;
        uint256 minCriteriaTokens;
        uint256 presaleRate;
        uint8 liquidity;
        uint256 hardCap;
        uint256 softCap;
        uint256 minContribution;
        uint256 maxContribution;
        RefundType refundType;
    }

    struct PresaleTimes {
        uint256 startedAt;
        uint256 expiredAt;
        uint256 lpLockupDuration;
    }

    struct PresalectCounts {
        uint256 accumulatedBalance;
        uint256 contributors;
        uint256 claimsCount;
    }

    struct ContributorsVesting {
        bool isEnabled;
        uint firstReleasePC;
        uint eachCycleDuration;
        uint8 eachCyclePC;
    }

    struct TeamVesting {
        bool isEnabled;
        uint vestingTokens;
        uint firstReleaseDelay;
        uint firstReleasePC;
        uint eachCycleDuration;
        uint8 eachCyclePC;
    }

    struct GeneralInfo {
        string logoURL;
        string websiteURL;
        string twitterURL;
        string telegramURL;
        string discordURL;
        string description;
    }
    

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library AuxLibrary {

    struct UnlockScheduleInternal {
        uint cycle;
        uint percentageToRelease;
        uint releaseTime;
        uint tokensPC;
        uint releaseStatus;
    }
    struct UnlockSchedule {
        uint cycle;
        uint releaseTime;
        uint tokens;
        uint releaseStatus;
    }

    struct LockerInfo {
        uint id;
        address owner;
        IERC20 token;
        uint numOfTokensLocked;
        uint numOfTokensClaimed;
    }

    struct TeamVestingRecordInternal {
        uint cycle;
        uint releaseTime;
        uint tokensPC;
        uint percentageToRelease;
        uint releaseStatus;
    }

    struct TeamVestingRecord {
        uint cycle;
        uint releaseTime;
        uint tokens;
        uint releaseStatus;
    }

    struct Participant {
        uint256 value;
        uint256 tokens;
        uint256 unclaimed;
    }
    struct ContributorsVestingRecordInternal {
        uint cycle;
        uint releaseTime;
        uint tokensPC;
        uint percentageToRelease;
    }

    struct ContributorsVestingRecord {
        uint cycle;
        uint releaseTime;
        uint tokens;
        uint releaseStatus;
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