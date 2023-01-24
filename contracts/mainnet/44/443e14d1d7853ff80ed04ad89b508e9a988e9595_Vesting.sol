// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.13;

import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IVesting} from "src/interfaces/IVesting.sol";
import {IVestingFactory} from "src/interfaces/IVestingFactory.sol";

/*//////////////////////////////////////////////////////////////
                        CUSTOM ERROR
//////////////////////////////////////////////////////////////*/

error NotInitialised();
error Initialised();
error NoAccess();
error ZeroAddress();
error NoVestingData();
error StartLessThanNow();
error ZeroAmount();
error ZeroClaimAmount();
error AlreadyClaimed();
error AlreadyCancelled();
error Uncancellable();
error SameRecipient();

/*//////////////////////////////////////////////////////////////
                          CONTRACT
//////////////////////////////////////////////////////////////*/

/// @title Vesting Contract
contract Vesting is IVesting {
    // The recipient of the tokens
    address public recipient;

    uint40 public start;
    uint40 public duration;
    uint256 public amount;

    // Total amount of tokens which are claimed
    uint256 public totalClaimedAmount;

    // Flag for whether the vesting is cancellable or not
    bool public isCancellable;
    // Flag for whether the vesting is cancelled or not
    bool public cancelled;
    // Flag to check if its initialised
    bool private initialised;

    IVestingFactory public factory;

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    function initialise(address _recipient, uint40 _start, uint40 _duration, uint256 _amount, bool _isCancellable)
        external
        override
    {
        if (initialised) revert Initialised();
        initialised = true;

        recipient = _recipient;
        start = _start;
        duration = _duration;
        amount = _amount;
        isCancellable = _isCancellable;
        factory = IVestingFactory(msg.sender);
    }

    /*//////////////////////////////////////////////////////////////
                            MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyTreasury() {
        if (msg.sender != factory.treasury()) revert NoAccess();
        _;
    }

    modifier onlyOwner() {
        bool isOwner;
        if (isCancellable == false) {
            // If the vest is uncancellable, only the recipient can call the function
            isOwner = (msg.sender == recipient);
        } else {
            // If the vest is cancellable, only the treasury or the recipient can call the function
            isOwner = (msg.sender == recipient) || (msg.sender == factory.treasury());
        }
        if (!isOwner) revert NoAccess();
        _;
    }

    modifier onlyInit() {
        if (!initialised) revert NotInitialised();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Calculates the amount of tokens which have been accrued to date.
    /// @notice This does not take into account the amount which has been claimed already.
    /// @return uint256 The amount of tokens which have been accrued to date.
    function getAccruedTokens() public view returns (uint256) {
        if (block.timestamp >= start + duration) {
            return amount;
        } else if (block.timestamp < start) {
            // Allows us to set up vests in advance
            return 0;
        } else {
            return (block.timestamp - start) * (amount / duration);
        }
    }

    /// @notice Calculates the amount of tokens which can be claimed.
    /// @return uint256 The amount of tokens which can be claimed.
    function getClaimableTokens() public view returns (uint256) {
        if (cancelled) {
            return 0;
        }

        uint256 accruedTokens = getAccruedTokens();

        // Calculate the amount of tokens which can be claimed
        uint256 tokensToClaim = accruedTokens - totalClaimedAmount;

        return tokensToClaim;
    }

    /// @notice Gets the vesting details of the contract.
    function getVestingDetails() public view returns (uint40, uint40, uint256, uint256, bool) {
        return (start, duration, amount, totalClaimedAmount, isCancellable);
    }

    /*//////////////////////////////////////////////////////////////
                          EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Changes the recipient of vested tokens.
    /// @notice The old recipient will not be able to claim the tokens, the new recipient will be able to claim all unclaimed tokens accrued to date.
    /// @dev Can be called by the treasury or the recipient depending on whether the vest is cancellable or not.
    /// @param _newRecipient Address of the new recipient recieving the vested tokens.
    function changeRecipient(address _newRecipient) external onlyOwner onlyInit {
        if (_newRecipient == address(0)) revert ZeroAddress();
        if (_newRecipient == recipient) revert SameRecipient();
        if (start == 0) revert NoVestingData();
        if (cancelled) revert AlreadyCancelled();
        factory.changeRecipient(recipient, _newRecipient);
        recipient = _newRecipient;
    }

    /// @notice Cancels the vest and transfers the accrued amount to the recipient.
    /// @dev Can only be called by the treasury.
    function cancelVest() external onlyTreasury onlyInit {
        if (start < 1) revert NoVestingData();
        if (isCancellable == false) revert Uncancellable();
        if (cancelled) revert AlreadyCancelled();

        uint256 claimAmount = getClaimableTokens();

        if (claimAmount > 0) {
            totalClaimedAmount += claimAmount;
            factory.token().transfer(recipient, claimAmount);
        }

        cancelled = true;

        // Transfer the remainder of the tokens to the treasury
        factory.token().transfer(factory.treasury(), amount - totalClaimedAmount);
    }

    /// @notice A function allowing the recipient to claim the vested tokens.
    /// @notice The function returns unclaimed tokens to the treasury.
    /// @dev This function can be called by anyone.
    function claim() public override onlyInit {
        if (totalClaimedAmount >= amount) revert AlreadyClaimed();
        if (cancelled) revert AlreadyCancelled();

        uint256 claimAmount = getClaimableTokens();
        if (claimAmount < 1) revert ZeroClaimAmount();

        totalClaimedAmount += claimAmount;
        factory.token().transfer(recipient, claimAmount);
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

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.0;

interface IVesting {
    function cancelled() external returns (bool);

    function totalClaimedAmount() external returns (uint256);
    
    function amount() external returns (uint256);

    function initialise(address _recipient, uint40 _start, uint40 _duration, uint256 _amount, bool _isCancellable)
        external;

    function claim() external;
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.0;

import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IVestingFactory {
    function treasury() external returns (address);

    function token() external returns (IERC20);

    function changeRecipient(address _oldRecipient, address _newRecipient) external;
}