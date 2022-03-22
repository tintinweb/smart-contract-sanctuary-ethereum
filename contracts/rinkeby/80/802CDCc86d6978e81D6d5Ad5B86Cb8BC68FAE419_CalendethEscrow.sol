// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.9;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC2771Context} from "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import {IMeTokenRegistryFacet} from "./interfaces/IMeTokenRegistryFacet.sol";

/* solhint-disable not-rely-on-time */

contract CalendethEscrow is ERC2771Context {
    event SetScheduleFee(uint256 _perMinuteFee);
    event ScheduleMeeting(
        address _meHolder,
        uint256 _meetingIndex,
        uint256 _minutes,
        uint256 _totalFee
    );
    event Claim(uint256 _meetingId, bool invitee);

    /// @dev meeting details
    struct Meeting {
        address _meHolder; // invitee
        address _inviter; // inviter
        bool _claim; // true if invitee or inviter has claimed
        uint256 _totalFee; // meeting schedule fee
        uint256 _timestamp; // meeting start timestamp
    }

    /// @dev fee of scheduling meeting for 1 minute
    mapping(address => uint256) public scheduleFee;

    /// @dev meeting id to meeting details
    mapping(uint256 => Meeting) public meetings;

    /// @dev metoken diamond's MeTokenRegistryFacet instance
    IMeTokenRegistryFacet public meTokenRegistry;

    /// @dev meeting id counter
    uint256 public meetingCounter;

    /// @dev waiting period for invite
    uint256 public inviterClaimWaiting;

    modifier mustBeMeHolder(address _meHolder) {
        require(meTokenRegistry.isOwner(_meHolder), "not a metoken owner");
        _;
    }

    constructor(
        address _metokenDiamond,
        uint256 _inviterClaimWaiting,
        address _trustedForwarder
    ) ERC2771Context(_trustedForwarder) {
        meTokenRegistry = IMeTokenRegistryFacet(_metokenDiamond);
        inviterClaimWaiting = _inviterClaimWaiting;
    }

    function setScheduleFee(uint256 _perMinuteFee)
        external
        mustBeMeHolder(_msgSender())
    {
        scheduleFee[_msgSender()] = _perMinuteFee;
        emit SetScheduleFee(_perMinuteFee);
    }

    function scheduleMeeting(
        address _meHolder,
        uint256 _minutes,
        uint256 _timestamp
    ) external mustBeMeHolder(_meHolder) {
        address sender = _msgSender();
        uint256 _totalFee = 0;
        if (scheduleFee[_meHolder] > 0) {
            _totalFee = scheduleFee[_meHolder] * _minutes;
            IERC20(meTokenRegistry.getOwnerMeToken(_meHolder)).transferFrom(
                sender,
                address(this),
                _totalFee
            );
        }

        Meeting storage _meeting = meetings[++meetingCounter];
        _meeting._meHolder = _meHolder;
        _meeting._inviter = sender;
        _meeting._totalFee = _totalFee;
        _meeting._timestamp = _timestamp;

        emit ScheduleMeeting(_meHolder, meetingCounter, _minutes, _totalFee);
    }

    function noShowClaim(uint256 _meetingId) external {
        _claim(_meetingId, true);
    }

    function inviterClaim(uint256 _meetingId) external {
        _claim(_meetingId, false);
    }

    function _claim(uint256 _meetingId, bool _invitee) internal {
        address sender = _msgSender();
        Meeting storage _meeting = meetings[_meetingId];
        require(!_meeting._claim, "already claimed"); // invitee or inviter claim

        if (_invitee) {
            require(_meeting._meHolder == sender, "only invitee");
        } else {
            require(_meeting._inviter == sender, "only inviter");
            require(
                block.timestamp > _meeting._timestamp + inviterClaimWaiting,
                "too soon"
            );
        }
        _meeting._claim = true; // invitee or inviter claim
        emit Claim(_meetingId, _invitee);
        IERC20(sender).transfer(sender, _meeting._totalFee);
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
// OpenZeppelin Contracts (last updated v4.5.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "../utils/Context.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

interface IMeTokenRegistryFacet {
    /// @notice View to return if an address owns a meToken or not
    /// @param owner    Address to query
    /// @return         True if owns a meToken, else false
    function isOwner(address owner) external view returns (bool);

    /// @notice View to return Address of meToken owned by owner
    /// @param owner    Address of meToken owner
    /// @return         Address of meToken
    function getOwnerMeToken(address owner) external view returns (address);
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