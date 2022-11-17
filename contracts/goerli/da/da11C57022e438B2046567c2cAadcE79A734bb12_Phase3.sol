/**
 *Submitted for verification at Etherscan.io on 2022-11-17
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IPhase3 {}

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

interface IOwnable {
    function owner() external view returns (address);

    function setOwner(address _newOwner) external;

    function acceptOwner() external;

    function deleteOwner() external;
}

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

contract Phase3 is IPhase3, ReentrancyGuard, Ownable {
    struct Position {
        uint256 amount;
        uint256 half;
        // Total amount withdrawn on and after 4th day
        uint256 withdrawn;
    }

    event Deposit(address indexed account, uint256 amount);
    event Withdraw(address indexed account, uint256 amount);
    event Claim(address indexed account, uint256 amount);

    /// @dev DEPOSIT_END < DURATION
    uint256 private constant DURATION = 5 weeks;
    uint256 private constant DEPOSIT_END = 4 weeks;
    /// @dev WITHDRAW_1_END < WITHDRAW_2_END < DURATION
    uint256 private constant WITHDRAW_1_END = 3 weeks;
    uint256 private constant WITHDRAW_2_END = 4 weeks;
    uint256 private constant WITHDRAW_3_DURATION = DURATION - WITHDRAW_2_END;

    uint256 private constant HALO_ALLOCATION = 5_000_000 * 1e18;

    uint256 public block_timestamp = block.timestamp;

    function setBlockTimestamp(uint256 t) external {
        block_timestamp = t;
    }

    /// @dev Index of the current time
    uint256 public immutable startTime;
    uint256 public immutable endTime;

    /// @dev Supported token addresses
    IERC20 public immutable halo;
    IERC20 public immutable usdc;

    address public immutable teamTreasury;

    uint256 public usdcCollected;

    /// @dev user address to position data
    mapping(address => Position) public positions;

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

        startTime = block_timestamp;
        endTime = block_timestamp + DURATION;
    }

    /// Privileged Functionality

    function evaluatePhase() external onlyOwner {
        require(block_timestamp > endTime, "Not ended");

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
        require(block_timestamp < startTime + DEPOSIT_END, "Not available");

        positions[msg.sender].amount += amount;
        positions[msg.sender].half = positions[msg.sender].amount / 2;

        usdc.transferFrom(msg.sender, address(this), amount);

        emit Deposit(msg.sender, amount);
    }

    function calculateMaxWithdrawAmount(address account)
        external
        view
        returns (uint256)
    {
        return _calculateMaxWithdrawAmount(positions[account]);
    }

    function _calculateMaxWithdrawAmount(Position memory position)
        private
        view
        returns (uint256)
    {
        if (block_timestamp < startTime + WITHDRAW_1_END) {
            return position.amount;
        }
        if (block_timestamp < startTime + WITHDRAW_2_END) {
            uint256 half = position.half;
            uint256 withdrawn = position.withdrawn;
            if (half > withdrawn) {
                return half - withdrawn;
            }
            return 0;
        }
        if (block_timestamp < endTime) {
            uint256 withdrawn = position.withdrawn;
            uint256 max = (position.half * (endTime - block_timestamp)) /
                WITHDRAW_3_DURATION;

            if (max > withdrawn) {
                return max - withdrawn;
            }
            return 0;
        }
        return 0;
    }

    function withdraw(uint256 amount) external lock {
        require(amount != 0, "Zero amount");
        require(block_timestamp < endTime, "Withdraw duration is expired");

        Position storage position = positions[msg.sender];
        require(position.amount != 0, "No amount available for withdrawal");

        uint256 max = _calculateMaxWithdrawAmount(position);
        require(amount <= max, "Withdraw amount exceeds limit");

        if (block_timestamp < startTime + WITHDRAW_1_END) {
            position.amount -= amount;
            position.half = position.amount / 2;
        } else {
            position.amount -= amount;
            position.withdrawn += amount;
        }

        usdc.transfer(msg.sender, amount);

        emit Withdraw(msg.sender, amount);
    }

    function _quoteHalo(Position memory position)
        private
        view
        returns (uint256)
    {
        if (position.amount == 0) {
            return 0;
        }

        return (HALO_ALLOCATION * position.amount) / usdcCollected;
    }

    function quoteHalo(address account) external view returns (uint256) {
        return _quoteHalo(positions[account]);
    }

    /// @dev Claim function for users to claim the tokens after the sale
    /// @notice This function can only be called after owner calls end sale function
    /// @return amount The amount of tokens that the user has claimed
    function claim() external lock returns (uint256) {
        require(usdcCollected != 0, "Cannot claim");

        Position storage position = positions[msg.sender];
        require(position.amount != 0, "Not available");

        uint256 toClaim = _quoteHalo(position);

        delete positions[msg.sender];

        halo.transfer(msg.sender, toClaim);

        emit Claim(msg.sender, toClaim);

        return toClaim;
    }
}