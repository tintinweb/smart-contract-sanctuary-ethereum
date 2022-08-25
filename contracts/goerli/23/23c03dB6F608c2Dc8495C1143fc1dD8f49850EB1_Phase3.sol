// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IPhase3.sol";
import "../base/Ownable.sol";
import "../base/ReentrancyGuard.sol";

contract Phase3 is IPhase3, ReentrancyGuard, Ownable {
    event Claim(address indexed account, uint256 amount);

    /// @dev DEPOSIT_END < DURATION
    uint256 private constant DURATION = 5 days;
    uint256 private constant DEPOSIT_END = 4 days;
    /// @dev WITHDRAW_1_END < WITHDRAW_2_END < DURATION
    uint256 private constant WITHDRAW_1_END = 3 days;
    uint256 private constant WITHDRAW_2_END = 4 days;
    uint256 private constant WITHDRAW_3_DURATION = DURATION - WITHDRAW_2_END;

    uint256 public constant Halo_ALLOCATION = 5_000_000 ether;

    /// @dev Index of the current time
    uint256 public immutable startTime;
    uint256 public immutable endTime;

    /// @dev Supported token addresses
    IERC20 public immutable halo;
    IERC20 public immutable usdc;

    address public immutable teamTreasury;

    uint256 public usdcCollected;

    /// @dev user address to deposit data
    mapping(address => Deposit) public deposits;

    constructor(
        IERC20 _halo,
        IERC20 _usdc,
        address _teamTreasury
    ) {
        require(
            address(_halo) != address(0) &&
                address(_usdc) != address(0) &&
                _teamTreasury != address(0),
            "Invalid arguments"
        );

        halo = _halo;
        usdc = _usdc;
        teamTreasury = _teamTreasury;

        startTime = block.timestamp;
        endTime = block.timestamp + DURATION;
    }

    /// Privileged Functionality

    function evaluatePhase() external onlyOwner {
        require(block.timestamp > endTime, "Not available");

        uint256 balance = usdc.balanceOf(address(this));
        usdcCollected = balance;
        usdc.transfer(teamTreasury, balance);
    }

    /// Non-Privileged Functionality

    /// @dev Deposit USDC to the Halo sale phase
    /// @param amount The amount in USDC that the user wants to deposit into the sale
    /// @custom:require The system is in part 1 of the sale
    function deposit(uint256 amount) external lock {
        require(amount != 0, "Zero amount");
        require(block.timestamp <= startTime + DEPOSIT_END, "Not available");

        deposits[msg.sender].amount += amount;
        deposits[msg.sender].half = deposits[msg.sender].amount / 2;

        usdc.transferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) external lock {
        require(amount != 0, "Invalid amount provided");
        require(block.timestamp < endTime, "Withdraw duration is expired");

        Deposit storage _deposit = deposits[msg.sender];
        require(_deposit.amount != 0, "No amount available for withdrawal");

        if (block.timestamp <= startTime + WITHDRAW_1_END) {
            _deposit.amount -= amount;
            _deposit.half = _deposit.amount / 2;
        } else if (block.timestamp <= startTime + WITHDRAW_2_END) {
            require(
                _deposit.withdrawnOn4thDay + amount <= _deposit.half,
                "withdrawn amount exceeds the limit on 4th day"
            );

            _deposit.amount -= amount;
            _deposit.withdrawnOn4thDay += amount;
        } else {
            uint256 half = _deposit.half;
            uint256 withdrawnTillOn5thDay = _deposit.withdrawnTillOn5thDay;

            uint256 lastClaimedTill = withdrawnTillOn5thDay > block.timestamp
                ? withdrawnTillOn5thDay
                : block.timestamp;
            uint256 amountWithdrawable = ((half * (endTime - lastClaimedTill)) /
                WITHDRAW_3_DURATION);
            require(
                amount <= amountWithdrawable,
                "Amount exceeds withdrawable"
            );

            _deposit.amount -= amount;
            _deposit.withdrawnTillOn5thDay =
                lastClaimedTill +
                ((amount * WITHDRAW_3_DURATION) / half);
        }

        usdc.transfer(msg.sender, amount);
    }

    /// @dev Claim function for users to claim the tokens after the sale
    /// @notice This function can only be called after owner calls end sale function
    /// @return amount The amount of tokens that the user has claimed
    function claim() external lock returns (uint256) {
        require(usdcCollected != 0, "Cannot claim");

        Deposit storage _deposit = deposits[msg.sender];
        require(_deposit.amount != 0, "Not available");

        uint256 toClaim = (_deposit.amount * Halo_ALLOCATION) / usdcCollected;

        delete deposits[msg.sender];

        halo.transfer(msg.sender, toClaim);

        emit Claim(msg.sender, toClaim);

        return toClaim;
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
pragma solidity 0.8.13;

interface IPhase3 {
    /// @dev Represents a deposit a phase 3
    struct Deposit {
        uint256 amount;
        uint256 withdrawnOn4thDay;
        uint256 withdrawnTillOn5thDay;
        uint256 half;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../interfaces/IOwnable.sol";

contract Ownable is IOwnable {
    event NewOwner(address owner);

    address public owner;
    address public pendingOwner;

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function setOwner(address _newOwner) external onlyOwner {
        require(_newOwner != msg.sender, "new owner = current owner");
        pendingOwner = _newOwner;
    }

    function acceptOwner() external {
        require(msg.sender == pendingOwner, "not pending owner");
        owner = msg.sender;
        pendingOwner = address(0);
        emit NewOwner(msg.sender);
    }

    function deleteOwner() external onlyOwner {
        require(pendingOwner == address(0), "pending owner != 0 address");
        owner = address(0);
        emit NewOwner(address(0));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

abstract contract ReentrancyGuard {
    // simple re-entrancy check
    uint256 private _unlocked = 1;

    modifier lock() {
        // solhint-disable-next-line
        require(_unlocked == 1, "reentrant");
        _unlocked = 2;
        _;
        _unlocked = 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IOwnable {
    function owner() external view returns (address);

    function setOwner(address _newOwner) external;

    function acceptOwner() external;

    function deleteOwner() external;
}