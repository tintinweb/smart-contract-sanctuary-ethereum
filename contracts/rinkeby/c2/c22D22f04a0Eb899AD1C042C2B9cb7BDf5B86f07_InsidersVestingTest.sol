// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct BeneficiaryInit {
    address account;
    uint96 tokenAmount;
}

contract InsidersVestingTest {
    struct BeneficiaryInfo {
        uint64 startTime;
        uint96 tokensLocked;
        uint96 tokensUnlocked;
        uint96 tokensClaimed;
        // amount of tokens unlocked per second
        uint96 tokensPerSec;
        // date of pulling unlocked tokens from locked (transfer, claim)
        uint64 lastVestingUpdate;
    }
    mapping(address => BeneficiaryInfo) private whitelist;
    address public immutable owner;
    bool public initialized;
    uint64 public vestingStart;
    uint64 public lockupEnd;
    uint64 public vestingFinish;

    uint64 public VESTING_LOCKUP_DURATION;
    uint64 public VESTING_DURATION;

    IERC20 public token;

    event TokensClaimed(address indexed from, address indexed to, uint256 amount);
    event TokensTransferred(address indexed from, address indexed to, uint256 amountLocked, uint256 amountUnlocked);

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyFromWhitelist() {
        require(whitelist[msg.sender].lastVestingUpdate > 0, "You are not in whitelist");
        _;
    }

    function initialize(
        address tokenAddress,
        BeneficiaryInit[] memory beneficiaries,
        uint64 _vestingStart,
        uint64 lockupDuration,
        uint64 vestingDuration
    ) external {
        require(msg.sender == owner, "Not allowed to initialize");
        require(!initialized, "Already initialized");
        initialized = true;
        require(beneficiaries.length > 0, "No users");
        token = IERC20(tokenAddress);
        uint96 tokensLimitRemaining = uint96(token.balanceOf(address(this)));
        require(tokensLimitRemaining > 0, "Zero token balance");
        require(_vestingStart > block.timestamp, "Start timestamp is in the past");
        vestingStart = _vestingStart;
        VESTING_LOCKUP_DURATION = lockupDuration;
        VESTING_DURATION = vestingDuration;
        lockupEnd = _vestingStart + VESTING_LOCKUP_DURATION;
        vestingFinish = _vestingStart + VESTING_LOCKUP_DURATION + VESTING_DURATION;

        for (uint96 i = 0; i < beneficiaries.length; i++) {
            BeneficiaryInit memory b = beneficiaries[i];
            require(tokensLimitRemaining >= b.tokenAmount, "Tokens sum is greater than balance");
            tokensLimitRemaining -= b.tokenAmount;
            whitelist[b.account] = BeneficiaryInfo(_vestingStart, b.tokenAmount, 0, 0, b.tokenAmount / VESTING_DURATION, lockupEnd);
        }
        require(tokensLimitRemaining == 0, "Not all tokens are distributed");
    }

    function getBeneficiaryInfo(address beneficiary) public view returns (BeneficiaryInfo memory) {
        if (whitelist[beneficiary].lastVestingUpdate > 0) {
            return whitelist[beneficiary];
        } else {
            revert("Account is not in whitelist");
        }
    }

    function calculateClaim(address beneficiary) external view returns (uint96) {
        BeneficiaryInfo memory info = getBeneficiaryInfo(beneficiary);

        return _calculateClaim(info) + info.tokensUnlocked;
    }

    function _calculateClaim(BeneficiaryInfo memory info) private view returns (uint96) {
        if (block.timestamp < info.lastVestingUpdate) {
            return 0;
        }
        if (block.timestamp < vestingFinish) {
            return (uint64(block.timestamp) - info.lastVestingUpdate) * info.tokensPerSec;
        }
        return info.tokensLocked;
    }

    function claim(address to, uint96 amount) external onlyFromWhitelist {
        require(block.timestamp > lockupEnd, "Cannot claim during 3 months lock-up period");
        address sender = msg.sender;
        calculateClaimAndStage(sender);
        BeneficiaryInfo storage claimer = whitelist[sender];
        require(claimer.tokensUnlocked >= amount, "Requested more than unlocked");

        claimer.tokensUnlocked -= amount;
        claimer.tokensClaimed += amount;
        token.transfer(to, amount);
        emit TokensClaimed(sender, to, amount);
    }

    function transfer(
        address to,
        uint96 tokensLocked,
        uint96 tokensUnlocked
    ) external onlyFromWhitelist {
        BeneficiaryInfo memory sender = calculateClaimAndStage(msg.sender);
        require(sender.tokensLocked >= tokensLocked, "Requested more tokens than locked");
        require(sender.tokensUnlocked >= tokensUnlocked, "Requested more tokens than unlocked");
        _transfer(to, tokensLocked, tokensUnlocked);
    }

    function transferAll(address to) external onlyFromWhitelist {
        BeneficiaryInfo memory sender = calculateClaimAndStage(msg.sender);
        _transfer(to, sender.tokensLocked, sender.tokensUnlocked);
    }

    function _transfer(
        address to,
        uint96 tokensLocked,
        uint96 tokensUnlocked
    ) private {
        require(msg.sender != to, "Cannot transfer to the same address");
        uint64 timestamp = uint64(block.timestamp);
        BeneficiaryInfo storage sender = whitelist[msg.sender];
        BeneficiaryInfo storage recipient = whitelist[to];

        sender.tokensLocked -= tokensLocked;
        uint64 durationLeft;
        uint64 lastVestingUpdate;
        if (timestamp > lockupEnd) {
            // set durationLeft = 1 after vesting finish to avoid division by zero
            durationLeft = vestingFinish > timestamp ? vestingFinish - timestamp : 1;
            lastVestingUpdate = timestamp;
        } else {
            durationLeft = VESTING_DURATION;
            lastVestingUpdate = lockupEnd;
        }
        sender.tokensUnlocked -= tokensUnlocked;
        sender.tokensPerSec = sender.tokensLocked / durationLeft;
        if (recipient.lastVestingUpdate == 0) {
            whitelist[to] = BeneficiaryInfo(timestamp, tokensLocked, tokensUnlocked, 0, tokensLocked / durationLeft, lastVestingUpdate);
        } else {
            calculateClaimAndStage(to);
            recipient.tokensLocked += tokensLocked;
            recipient.tokensUnlocked += tokensUnlocked;
            recipient.tokensPerSec = recipient.tokensLocked / durationLeft;
        }
        emit TokensTransferred(msg.sender, to, tokensLocked, tokensUnlocked);
    }

    // pass only existing beneficiary
    function calculateClaimAndStage(address beneficiary) private returns (BeneficiaryInfo memory) {
        BeneficiaryInfo storage info = whitelist[beneficiary];
        if (block.timestamp > lockupEnd) {
            uint96 unlocked = _calculateClaim(info);
            info.tokensUnlocked += unlocked;
            info.tokensLocked -= unlocked;
            info.lastVestingUpdate = uint64(block.timestamp);
        }
        return info;
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