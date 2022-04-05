// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./openzeppelin/contracts/token/ERC20/IERC20.sol";

contract InsidersVestingTest {
    struct VestingInfo {
        uint96 tokensLocked;
        uint96 tokensClaimed;
        uint64 pausedTime;
        uint96 stagedProfit;
        uint96 tokensPerSec;
        uint64 lastChange;
    }
    mapping(address => VestingInfo) private whitelist;
    uint96 public whitelistReserveTokensLimit;
    uint96 public whitelistReserveTokensUsed;
    address public immutable owner;
    bool public initialized;

    uint64 public constant VESTING_LOCKUP_END = 1649164800;
    uint64 public constant VESTING_FINISH = 1649167200;
    uint64 public constant VESTING_DURATION = VESTING_FINISH - VESTING_LOCKUP_END;

    IERC20 public token;

    event TokensClaimed(address indexed to, uint256 amount);

    constructor(address _owner) {
        owner = _owner;
    }

    modifier afterInitialize() {
        require(initialized, "Vesting has not started yet");
        _;
    }

    function initialize(
        address tokenAddress,
        address[] memory accounts,
        uint96[] memory tokenAmounts,
        uint96 mainAllocation,
        uint96 reserveAllocation
    ) external {
        require(msg.sender == owner, "Not allowed to initialize");
        require(!initialized, "Already initialized");
        initialized = true;
        require(accounts.length == tokenAmounts.length, "Users and tokenAmounts length mismatch");
        require(accounts.length > 0, "No users");
        token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) >= mainAllocation + reserveAllocation, "Insufficient token balance");

        whitelistReserveTokensLimit = reserveAllocation;
        uint96 whitelistTokensSum;

        for (uint96 i = 0; i < accounts.length; i++) {
            address account = accounts[i];
            uint96 tokenAmount = tokenAmounts[i];
            require(account != address(0), "Address is zero");
            whitelistTokensSum += tokenAmount;
            require(whitelistTokensSum <= mainAllocation, "Exceeded tokens limit");
            whitelist[account] = VestingInfo(tokenAmount, 0, 0, 0, tokenAmount / VESTING_DURATION, VESTING_LOCKUP_END);
        }
    }

    function addBeneficiary(address beneficiary, uint96 tokenAmount) external afterInitialize {
        require(msg.sender == owner, "Not allowed to add beneficiary");
        require(beneficiary != address(0), "Address is zero");
        require(whitelist[beneficiary].lastChange == 0, "Beneficiary is already in whitelist");
        whitelistReserveTokensUsed += tokenAmount;
        require(whitelistReserveTokensUsed <= whitelistReserveTokensLimit, "Exceeded tokens limit");
        whitelist[beneficiary] = VestingInfo(tokenAmount, 0, 0, 0, tokenAmount / VESTING_DURATION, VESTING_LOCKUP_END);
    }

    function getBeneficiaryInfo(address beneficiary) public view returns (VestingInfo memory) {
        if (whitelist[beneficiary].lastChange > 0) {
            return whitelist[beneficiary];
        } else {
            revert("Account is not in whitelist");
        }
    }

    function calculateClaim(address beneficiary) external view returns (uint96) {
        VestingInfo memory vesting = getBeneficiaryInfo(beneficiary);

        return _calculateClaim(vesting) + vesting.stagedProfit;
    }

    function _calculateClaim(VestingInfo memory vesting) private view returns (uint96) {
        if (vesting.pausedTime > 0 || block.timestamp < vesting.lastChange) {
            return 0;
        }
        if (block.timestamp < VESTING_FINISH) {
            return (uint64(block.timestamp) - vesting.lastChange) * vesting.tokensPerSec;
        }
        return vesting.tokensLocked;
    }

    function claim(address to, uint96 amount) external {
        require(block.timestamp > VESTING_LOCKUP_END, "Cannot claim during 3 months lock-up period");
        address sender = msg.sender;
        require(whitelist[sender].lastChange > 0, "Claimer is not in whitelist");
        VestingInfo memory vesting = calculateProfitAndStage(sender);
        require(vesting.stagedProfit >= amount, "Requested more than unlocked");

        whitelist[sender].stagedProfit -= amount;
        whitelist[sender].tokensClaimed += amount;
        token.transfer(to, amount);
        emit TokensClaimed(to, amount);
    }

    function sellShare(address to, uint96 amount) external afterInitialize {
        address sender = msg.sender;
        require(sender != to, "Cannot sell to the same address");
        require(whitelist[sender].lastChange > 0, "Sender is not in whitelist");

        uint64 timestamp = uint64(block.timestamp);
        VestingInfo storage buyer = whitelist[to];
        if (timestamp > VESTING_LOCKUP_END) {
            VestingInfo memory seller = calculateProfitAndStage(sender);
            require(seller.tokensLocked >= amount, "Requested more tokens than locked");

            whitelist[sender].tokensLocked -= amount;
            whitelist[sender].tokensPerSec = whitelist[sender].tokensLocked / (VESTING_FINISH - timestamp);

            if (buyer.lastChange == 0) {
                whitelist[to] = VestingInfo(amount, 0, 0, 0, amount / (VESTING_FINISH - timestamp), timestamp);
            } else {
                buyer.tokensLocked += amount;
                if (buyer.pausedTime == 0) {
                    calculateProfitAndStage(to);
                    buyer.tokensPerSec = buyer.tokensLocked / (VESTING_FINISH - timestamp);
                }
            }
        } else {
            if (buyer.lastChange == 0) {
                whitelist[to] = VestingInfo(amount, 0, 0, 0, amount / VESTING_DURATION, VESTING_LOCKUP_END);
            } else {
                buyer.tokensLocked += amount;
                buyer.tokensPerSec = buyer.tokensLocked / VESTING_DURATION;
            }
            whitelist[sender].tokensLocked -= amount;
            whitelist[sender].tokensPerSec = whitelist[sender].tokensLocked / VESTING_DURATION;
        }
    }

    function setPaused(bool paused) external {
        VestingInfo storage vesting = whitelist[msg.sender];
        require(vesting.lastChange > 0, "Account is not in whitelist");
        uint64 timestamp = uint64(block.timestamp);
        require(timestamp > VESTING_LOCKUP_END, "Cannot pause during 3 months lock-up period");
        if (paused) {
            require(vesting.pausedTime == 0, "Already on pause");
            calculateProfitAndStage(msg.sender);
            vesting.pausedTime = timestamp;
            vesting.tokensPerSec = 0;
        } else {
            require(vesting.pausedTime > 0, "Already unpaused");
            vesting.pausedTime = 0;
            vesting.lastChange = timestamp;
            vesting.tokensPerSec = timestamp < VESTING_FINISH ? vesting.tokensLocked / (VESTING_FINISH - timestamp) : 0;
        }
    }

    // pass only existing beneficiary
    function calculateProfitAndStage(address beneficiary) private returns (VestingInfo memory) {
        VestingInfo storage vesting = whitelist[beneficiary];
        uint96 unlocked = _calculateClaim(vesting);
        vesting.stagedProfit += unlocked;
        vesting.tokensLocked -= unlocked;
        vesting.lastChange = uint64(block.timestamp);
        return vesting;
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