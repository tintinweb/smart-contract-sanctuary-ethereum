// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./MemberRegistry.sol";

// import "hardhat/console.sol";

//*********************************************************************//
// --------------------------- custom errors ------------------------- //
//*********************************************************************//
error INVALID_ACCOUNT();

// DAO member registry
//  - keeps track of members
//  - keeps track of member part/full time activity (activity multiplier)
//  - keeps track of member start date
//  - keeps track of member total seconds active

contract ChampionRegistry is MemberRegistry, Ownable {

    // REGISTERY MODIFIERS

    // add member to registry
    function setNewMember(
        address _member,
        uint32 _activityMultiplier,
        uint32 _startDate
    ) external onlyOwner {
        _setNewMember(_member, _activityMultiplier, _startDate);
    }

    // update member activity multiplier
    function updateMember(address _member, uint32 _activityMultiplier)
        external
        onlyOwner
    {
        _updateMember(_member, _activityMultiplier);
    }

    // BATCH OPERATIONS

    function batchNewMember(
        address[] memory _members,
        uint32[] memory _activityMultipliers,
        uint32[] memory _startDates
    ) external onlyOwner {
        for (uint256 i = 0; i < _members.length; i++) {
            _setNewMember(_members[i], _activityMultipliers[i], _startDates[i]);
        }
    }

    function batchUpdateMember(
        address[] memory _members,
        uint32[] memory _activityMultipliers
    ) external onlyOwner {
        for (uint256 i = 0; i < _members.length; i++) {
            _updateMember(_members[i], _activityMultipliers[i]);
        }
    }

    // MEMBER ACTIONS

    function zeroOutActivityMultiplier() external {
        uint256 idx = memberIdxs[msg.sender];
        if(msg.sender != members[idx - 1].account) revert INVALID_ACCOUNT();
        _zeroOutActivityMultiplier(msg.sender);
    }

    // UPDATE ACTIONS

    // update member total seconds and seconds in last period
    function updateSecondsActive() public {
        _updateSecondsActive();
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

// import "hardhat/console.sol";

//*********************************************************************//
// --------------------------- custom errors ------------------------- //
//*********************************************************************//
error ALREADY_REGISTERED();
error NOT_REGISTERED();
error START_DATE_IN_FUTURE();
error INVALID_ACTIVITY_MULTIPLIER();

abstract contract MemberRegistry {
    struct Member {
        address account;
        uint32 secondsActive;
        uint32 activityMultiplier;
        uint32 startDate;
    }

    // store when a update happens
    uint32 public lastUpdate;
    // iterable
    Member[] public members;
    uint256 public count = 1;
    mapping(address => uint256) public memberIdxs;

    // EVENTS
    event SetMember(Member member, uint32 startDate);
    event UpdateMemberSeconds(Member member, uint32 newSeconds);
    event UpdateMember(Member member);
    event Update(uint32 date);

    // REGISTERY MODIFIERS

    // add member to registry
    // if member already exists, update their activity multiplier
    // if member does not exist, add them to the registry
    function _setNewMember(
        address _member,
        uint32 _activityMultiplier,
        uint32 _startDate
    ) internal {
        if(memberIdxs[_member] != 0) revert ALREADY_REGISTERED();
        if(_startDate > uint32(block.timestamp)) revert START_DATE_IN_FUTURE();
        if(_activityMultiplier > 100) revert INVALID_ACTIVITY_MULTIPLIER();

        // set to 0, will be updated in next update
        uint32 secsActive = 0;
        members.push(
            Member(_member, secsActive, _activityMultiplier, _startDate)
        );
        memberIdxs[_member] = count;
        emit SetMember(members[count - 1], uint32(block.timestamp)); // index is minus 1 for 0 index array
        count += 1;
    }

    function _updateMember(
        address _member,
        uint32 _activityMultiplier // 0-100 %
    ) internal {
        if(!memberExists(_member)) revert NOT_REGISTERED();
        if(_activityMultiplier > 100) revert INVALID_ACTIVITY_MULTIPLIER();

        members[memberIdxs[_member] - 1]
            .activityMultiplier = _activityMultiplier;
        emit UpdateMember(members[memberIdxs[_member] - 1]);
    }

    // add seconds active to member from last update
    // for brand new members it will be an update from their start date
    // todo: this could be more generic, use a controller contract to update
    function _updateSecondsActive() internal virtual {
        uint32 currentUpdate = uint32(block.timestamp);
        // update struct with total seconds active and seconds in last claim
        for (uint256 i = 0; i < members.length; i++) {
            Member storage _member = members[i];

            uint32 newSeconds = 0;
            if (_member.secondsActive == 0) {
                // new member will be 0 and should get seconds from start date
                newSeconds = (currentUpdate - _member.startDate);
            } else {
                newSeconds = (currentUpdate - lastUpdate);
            }
            // multiple by modifier and divide by 100 to get modifier % of seconds
            uint32 newSecondsActive = (newSeconds *
                _member.activityMultiplier) / 100;
            _member.secondsActive += newSecondsActive;
            emit UpdateMemberSeconds(_member, newSecondsActive);
        }
        lastUpdate = currentUpdate;
        emit Update(currentUpdate);
    }

    function _zeroOutActivityMultiplier(address _account) internal virtual {
        uint256 idx = memberIdxs[_account];
        if(!memberExists(_account)) revert NOT_REGISTERED();
        members[idx - 1].activityMultiplier = 0;
    }

    // GETTERS

    function getMembers() public view returns (Member[] memory) {
        return members;
    }

    function memberExists(address _account) public view returns (bool) {
        return memberIdxs[_account] != 0;
    }

    function getMember(address _account) public view returns (Member memory) {
        uint256 idx = memberIdxs[_account];
        return idx > 0 ? members[idx - 1] : Member(address(0), 0, 0, 0);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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