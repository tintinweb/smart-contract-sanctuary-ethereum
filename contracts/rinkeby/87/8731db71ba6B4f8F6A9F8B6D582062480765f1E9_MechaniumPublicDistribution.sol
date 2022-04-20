// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./MechaniumVesting.sol";
import "../MechaniumStaking/IStakingPool.sol";

/**
 * @title MechaniumPublicDistribution - Public distribution smart contract
 * @author EthernalHorizons - <https://ethernalhorizons.com/>
 * @custom:project-website  https://mechachain.io/
 * @custom:security-contact [email protected]
 */
contract MechaniumPublicDistribution is MechaniumVesting {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /**
     * ========================
     *          Events
     * ========================
     */

    /**
     * @notice Event emitted when the `vestingStartingTime` has changed
     */
    event VestingStartingTimeChanged(uint256 vestingStartingTime);

    /**
     * @notice Event emitted when `amount` tokens has been transferred to the play to earn pool
     */
    event TransferUnsoldToPTEPool(uint256 amount);

    /**
     * @notice Event emitted when `account` has transferred `amount` tokens to the staking pool
     */
    event TransferToStakingPool(
        address indexed account,
        uint256 amount,
        uint256 stakingTime
    );

    /**
     * ========================
     *  Constants & Immutables
     * ========================
     */

    /// Max vesting starting time
    uint256 private immutable _maxVestingStartingTime;

    /**
     * ========================
     *         Storage
     * ========================
     */

    /// Mapping of address/amount of allocated toknes
    mapping(address => uint256) private _allocatedTokens;

    /// Starting time of the vesting schedule
    uint256 private _vestingStartingTime;

    /// Staking pool address & interface
    address internal _stakingPoolAddress;
    IStakingPool internal _stakingPool;

    /// Time to transfer tokens to staking pool
    uint256 private _stakingTransferTimeLimit;

    /// Minimum staking time
    uint256 private _minimumStakingTime;

    /**
     * ========================
     *         Modifiers
     * ========================
     */

    /**
     * @dev Check if the vesting has started
     */
    modifier vestingStarted() {
        require(
            hasVestingStarted(),
            "The vesting schedule has not started yet"
        );
        _;
    }

    /**
     * @dev Check if the vesting has not started
     */
    modifier vestingNotStarted() {
        require(
            !hasVestingStarted(),
            "The vesting schedule has already started"
        );
        _;
    }

    /**
     * ========================
     *     Public Functions
     * ========================
     */

    /**
     * @dev Contract constructor
     * @param token_ address of the ERC20 token contract, this address cannot be changed later
     */
    constructor(IERC20 token_)
        MechaniumVesting(
            token_,
            25, // once the schedule has started, unlock 20%
            30 days // and repeat every month
        )
    {
        _vestingStartingTime = block.timestamp.add(180 days);
        _maxVestingStartingTime = block.timestamp.add(180 days);
        _stakingTransferTimeLimit = 90 days;
        _minimumStakingTime = 180 days;
    }

    /**
     * @notice Allocate `amount` token `to` address
     * @param to Address of the beneficiary
     * @param amount Total token to be allocated
     */
    function allocateTokens(address to, uint256 amount)
        public
        override
        onlyRole(ALLOCATOR_ROLE)
        tokensAvailable(amount)
        returns (bool)
    {
        require(amount > 0, "Amount must be superior to 0");
        require(to != address(0), "Address must not be address(0)");
        require(to != address(this), "Address must not be contract address");

        if (_allocatedTokens[to] == 0) {
            /// first allocation
            _beneficiaryList.push(to);
        }

        _allocatedTokens[to] = _allocatedTokens[to].add(amount);
        _totalAllocatedTokens = _totalAllocatedTokens.add(amount);

        emit Allocated(to, amount);
        if (isSoldOut()) {
            emit SoldOut(totalAllocatedTokens());
        }
        return true;
    }
    
    function allocateMultipleTokens(address[] calldata addresses, uint256[] calldata amounts) 
      public
      onlyRole(ALLOCATOR_ROLE)
      returns (bool)
    {
        require(addresses.length == amounts.length, "arrays length mismatch");
        
        for(uint256 i = 0; i < addresses.length; i++) {
          allocateTokens(addresses[i],amounts[i]);
        }
        
        return true;
    }

    /**
     * @notice Start the vesting immediately
     */
    function startVesting()
        public
        vestingNotStarted
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (bool)
    {
        _vestingStartingTime = block.timestamp;

        emit VestingStartingTimeChanged(_vestingStartingTime);
        return true;
    }

    /**
     * @notice Set the vesting start time
     * @param startTime vesting start time
     */
    function startVesting(uint256 startTime)
        public
        vestingNotStarted
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (bool)
    {
        require(
            startTime <= _maxVestingStartingTime,
            "Vesting start time must not be more than 6 months"
        );
        require(
            startTime >= block.timestamp,
            "Vesting start time cannot be in the past"
        );

        _vestingStartingTime = startTime;

        emit VestingStartingTimeChanged(_vestingStartingTime);
        return true;
    }

    /**
     * @notice Set staking pool address
     * @param stakingPoolAddress The staking pool address
     */
    function setStakingPool(address stakingPoolAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (bool)
    {
        _stakingPoolAddress = stakingPoolAddress;
        _stakingPool = IStakingPool(stakingPoolAddress);
        return true;
    }

    /**
     * @notice Set staking transfer time limit
     * @param stakingTransferTimeLimit The staking transfer time limit
     */
    function setStakingTransferTimeLimit(uint256 stakingTransferTimeLimit)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (bool)
    {
        _stakingTransferTimeLimit = stakingTransferTimeLimit;
        return true;
    }

    /**
     * @notice Set minimum staking time
     * @param minimumStakingTime The minimum staking time
     */
    function setMinimumStakingTime(uint256 minimumStakingTime)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (bool)
    {
        _minimumStakingTime = minimumStakingTime;
        return true;
    }

    /**
     * @notice Transfer tokens balance ( allocated but not claimed ) to the staking pool
     */
    function transferToStakingPool(uint256 amount, uint256 stakingTime)
        public
        returns (bool)
    {
        require(
            _stakingPoolAddress != address(0),
            "Staking pool address is not set"
        );

        require(
            block.timestamp <=
                _vestingStartingTime.add(_stakingTransferTimeLimit),
            "Staking is not possible after staking time limit passed"
        );

        require(
            stakingTime >= _minimumStakingTime,
            "Staking time must be superior to minimum staking time"
        );

        require(amount > 0, "Amount must be superior to zero");

        address account = msg.sender;
        uint256 userBalance = balanceOf(account);
        require(amount <= userBalance, "Insufficient balance");

        _token.safeIncreaseAllowance(_stakingPoolAddress, amount);
        _stakingPool.depositFor(account, amount, stakingTime);
        _allocatedTokens[account] = allocatedTokensOf(account).sub(amount);

        emit TransferToStakingPool(account, amount, stakingTime);
        return true;
    }

    /**
     * ========================
     *          Views
     * ========================
     */

    /**
     * @dev Return the amount of allocated tokens for `account` from the beginning
     */
    function allocatedTokensOf(address account)
        public
        view
        override
        returns (uint256)
    {
        return _allocatedTokens[account];
    }

    /**
     * @dev Return the amount of tokens that the `account` can unlock in real time
     */
    function pendingTokensOf(address account)
        public
        view
        override
        returns (uint256)
    {
        return
            _pendingTokensCalc(_vestingStartingTime, _allocatedTokens[account])
                .sub(releasedTokensOf(account));
    }

    /**
     * @dev Return the amount of tokens that the `account` can unlock per month
     */
    function unlockableTokens(address account)
        public
        view
        override
        returns (uint256)
    {
        return
            _unlockTokensCalc(_vestingStartingTime, _allocatedTokens[account])
                .sub(releasedTokensOf(account));
    }

    /**
     * @dev Return true if the vesting schedule has started
     */
    function hasVestingStarted() public view returns (bool) {
        return block.timestamp >= _vestingStartingTime;
    }

    /**
     * @dev Return the starting time of the vesting schedule
     */
    function vestingStartingTime() public view returns (uint256) {
        return _vestingStartingTime;
    }

    /**
     * @dev Return the unchangeable maximum vesting starting time
     */
    function maxVestingStartingTime() public view returns (uint256) {
        return _maxVestingStartingTime;
    }

    /**
     * @dev Return the staking pool address
     */
    function getStakingPoolAddress() public view returns (address) {
        return _stakingPoolAddress;
    }

    /**
     * @dev Return the staking transfer time limit
     */
    function getStrakingTransferTimeLimit() public view returns (uint256) {
        return _stakingTransferTimeLimit;
    }

    /**
     * @dev Return the minimum staking time
     */
    function getMinimumStakingTime() public view returns (uint256) {
        return _minimumStakingTime;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./IMechaniumVesting.sol";
import "../MechaniumUtils/MechaniumCanReleaseUnintented.sol";

/**
 * @title MechaniumVesting - Abstract class for vesting and distribution smart contract
 * @author EthernalHorizons - <https://ethernalhorizons.com/>
 * @custom:project-website  https://mechachain.io/
 * @custom:security-contact [email protected]
 */
abstract contract MechaniumVesting is
    AccessControl,
    IMechaniumVesting,
    MechaniumCanReleaseUnintented
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /**
     * ========================
     *          Events
     * ========================
     */

    /**
     * @notice Event emitted when `amount` tokens have been allocated for `to` address
     */
    event Allocated(address indexed to, uint256 amount);

    /**
     * @notice Event emitted when `caller` claimed `amount` tokens for `to` address
     */
    event ClaimedTokens(
        address indexed caller,
        address indexed to,
        uint256 amount
    );

    /**
     * @notice Event emitted when `caller` claimed the tokens for all beneficiary address
     */
    event ClaimedTokensToAll(
        address indexed caller,
        uint256 beneficiariesNb,
        uint256 tokensUnlockNb
    );

    /**
     * @notice Event emitted when all tokens have been allocated
     */
    event SoldOut(uint256 totalAllocated);

    /**
     * @notice Event emitted when the last tokens have been claimed
     */
    event ReleasedLastTokens(uint256 totalReleased);

    /**
     * ========================
     *  Constants & Immutables
     * ========================
     */

    /// Role who can call allocate function
    bytes32 public constant ALLOCATOR_ROLE = keccak256("ALLOCATOR_ROLE");

    /// ERC20 basic token contract being held
    IERC20 internal immutable _token;

    /// Percentage of unlocked tokens per _vestingClockTime once the vesting schedule has started
    uint256 internal immutable _vestingPerClock;

    /// Number of seconds between two _vestingPerClock
    uint256 internal immutable _vestingClockTime;

    /**
     * ========================
     *         Storage
     * ========================
     */

    /// Mapping of address/amount of transfered tokens
    mapping(address => uint256) internal _releasedTokens;

    /// List of all the addresses that have allocations
    address[] internal _beneficiaryList;

    /// Total allocated tokens for all the addresses
    uint256 internal _totalAllocatedTokens = 0;

    /// Total transfered tokens for all the addresses
    uint256 internal _totalReleasedTokens = 0;

    /**
     * ========================
     *         Modifiers
     * ========================
     */

    /**
     * @dev Check if the contract has the amount of tokens to allocate
     * @param amount The amount of tokens to allocate
     */
    modifier tokensAvailable(uint256 amount) {
        require(
            _totalAllocatedTokens.add(amount) <= totalSupply(),
            "The contract does not have enough available token to allocate"
        );
        _;
    }

    /**
     * ========================
     *     Public Functions
     * ========================
     */

    /**
     * @dev Contract constructor sets the configuration of the vesting schedule
     * @param token_ Address of the ERC20 token contract, this address cannot be changed later
     * @param vestingPerClock_ Percentage of unlocked tokens per _vestingClockTime once the vesting schedule has started
     * @param vestingClockTime_ Number of seconds between two _vestingPerClock
     */
    constructor(
        IERC20 token_,
        uint256 vestingPerClock_,
        uint256 vestingClockTime_
    ) {
        require(vestingPerClock_ <= 100, "Vesting can be greater than 100%");
        _token = token_;
        _vestingPerClock = vestingPerClock_;
        _vestingClockTime = vestingClockTime_;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ALLOCATOR_ROLE, msg.sender);

        _addLockedToken(address(token_));
    }

    /**
     * @notice Allocate `amount` token `to` address
     * @param to Address of the beneficiary
     * @param amount Total token to be allocated
     */
    function allocateTokens(address to, uint256 amount)
        public
        virtual
        override
        returns (bool);

    /**
     * @notice Claim the account's token
     * @param account the account to claim tokens
     */
    function claimTokens(address account) public override returns (bool) {
        uint256 pendingTokens = unlockableTokens(account);
        require(pendingTokens > 0, "No token can be unlocked for this account");

        _releaseTokens(account, pendingTokens);

        emit ClaimedTokens(msg.sender, account, pendingTokens);
        return true;
    }

    /**
     * @notice Claim the account's token
     */
    function claimTokens() public override returns (bool) {
        return claimTokens(msg.sender);
    }

    /**
     * @notice Claim all the accounts tokens (Only by DEFAULT_ADMIN_ROLE)
     */
    function claimTokensForAll()
        public
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (bool)
    {
        uint256 beneficiariesNb = 0;
        uint256 tokensUnlockNb = 0;
        for (uint256 i = 0; i < _beneficiaryList.length; i++) {
            address beneficiary = _beneficiaryList[i];
            uint256 pendingTokens = unlockableTokens(beneficiary);
            if (pendingTokens > 0) {
                _releaseTokens(beneficiary, pendingTokens);
                beneficiariesNb = beneficiariesNb.add(1);
                tokensUnlockNb = tokensUnlockNb.add(pendingTokens);
            }
        }
        require(tokensUnlockNb > 0, "No token can be unlocked");
        emit ClaimedTokensToAll(msg.sender, beneficiariesNb, tokensUnlockNb);
        return true;
    }

    /**
     * ========================
     *    Internal functions
     * ========================
     */

    /**
     * @notice Send `amount` token `to` address
     * @dev `amount` must imperatively be less or equal to the number of allocated tokens, throw an assert (loss of transaction fees)
     * @param to Address of the beneficiary
     * @param amount Total token to send
     */
    function _releaseTokens(address to, uint256 amount) internal {
        assert(releasedTokensOf(to).add(amount) <= allocatedTokensOf(to));

        _token.safeTransfer(to, amount);

        _releasedTokens[to] = releasedTokensOf(to).add(amount);
        _totalReleasedTokens = _totalReleasedTokens.add(amount);

        if (tokenBalance() == 0) {
            emit ReleasedLastTokens(totalReleasedTokens());
        }
    }

    /**
     * ========================
     *          Views
     * ========================
     */

    /**
     * @dev Return the number of tokens that can be unlock since startTime
     */
    function _unlockTokensCalc(uint256 startTime, uint256 allocation)
        internal
        view
        returns (uint256)
    {
        if (startTime > block.timestamp) {
            return 0;
        }
        uint256 diff = block.timestamp.sub(startTime); // number of seconds since vesting has started
        uint256 clockNumber = diff.div(_vestingClockTime).add(1); // number of clock since vesting has started + 1
        uint256 percentage = clockNumber.mul(_vestingPerClock); // percentage
        if (percentage > 100) {
            // percentage has to be <= to 100%
            percentage = 100;
        }
        return allocation.mul(percentage).div(100);
    }

    /**
     * @dev Return the number of tokens that can be unlock in real time since startTime
     */
    function _pendingTokensCalc(uint256 startTime, uint256 allocation)
        internal
        view
        returns (uint256)
    {
        if (startTime > block.timestamp) {
            return 0;
        }
        uint256 decimals = 18; // decimals to add to the percentage calc
        uint256 diff = block.timestamp.sub(startTime).mul(10**decimals); // number of seconds since vesting has started ** decimals
        uint256 clockNumber = diff.div(_vestingClockTime); // number of clock since vesting has started ** decimals
        uint256 percentage = clockNumber.mul(_vestingPerClock).add(
            _vestingPerClock.mul(10**decimals) // + vesting of the clock 0
        ); // percentage
        if (percentage > 10**(decimals + 2)) {
            // percentage has to be <= to 100%
            percentage = 10**(decimals + 2);
        }
        return allocation.mul(percentage).div(10**(decimals + 2));
    }

    /**
     * @dev Return the amount of tokens locked for `account`
     */
    function balanceOf(address account) public view override returns (uint256) {
        return allocatedTokensOf(account).sub(releasedTokensOf(account));
    }

    /**
     * @dev Return the amount of allocated tokens for `account` from the beginning
     */
    function allocatedTokensOf(address account)
        public
        view
        virtual
        override
        returns (uint256);

    /**
     * @dev Return the amount of tokens that the `account` can unlock in real time
     */
    function pendingTokensOf(address account)
        public
        view
        virtual
        override
        returns (uint256);

    /**
     * @dev Return the amount of tokens that the `account` can unlock per month
     */
    function unlockableTokens(address account)
        public
        view
        virtual
        override
        returns (uint256);

    /**
     * @dev Get released tokens of an address
     */
    function releasedTokensOf(address account)
        public
        view
        override
        returns (uint256)
    {
        return _releasedTokens[account];
    }

    /**
     * @dev Return the token IERC20
     */
    function token() public view override returns (address) {
        return address(_token);
    }

    /**
     * @dev Return the total token hold by the contract
     */
    function tokenBalance() public view override returns (uint256) {
        return _token.balanceOf(address(this));
    }

    /**
     * @dev Return the total supply of tokens
     */
    function totalSupply() public view override returns (uint256) {
        return tokenBalance().add(_totalReleasedTokens);
    }

    /**
     * @dev Return the total token unallocated by the contract
     */
    function totalUnallocatedTokens() public view override returns (uint256) {
        return totalSupply().sub(_totalAllocatedTokens);
    }

    /**
     * @dev Return the total allocated tokens for all the addresses
     */
    function totalAllocatedTokens() public view override returns (uint256) {
        return _totalAllocatedTokens;
    }

    /**
     * @dev Return the total tokens that have been transferred among all the addresses
     */
    function totalReleasedTokens() public view override returns (uint256) {
        return _totalReleasedTokens;
    }

    /**
     * @dev Return the percentage of unlocked tokens per `vestingClockTime()` once the vesting schedule has started
     */
    function vestingPerClock() public view override returns (uint256) {
        return _vestingPerClock;
    }

    /**
     * @dev Return the number of seconds between two `vestingPerClock()`
     */
    function vestingClockTime() public view override returns (uint256) {
        return _vestingClockTime;
    }

    /**
     * @dev Return true if all tokens have been allocated
     */
    function isSoldOut() public view override returns (bool) {
        return totalSupply() == totalAllocatedTokens();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/**
 * @dev Mechanim distribution smart contract interface
 * @author EthernalHorizons - <https://ethernalhorizons.com/>
 * @custom:project-website  https://mechachain.io/
 * @custom:security-contact [email protected]
 */
interface IMechaniumVesting {
    /**
     * @dev Allocate an amount of tokens to an address ( only allocator role )
     */
    function allocateTokens(address to, uint256 amount) external returns (bool);

    /**
     * @dev Transfers the allocated tokens to an address ( once the distribution has started )
     */
    function claimTokens(address account) external returns (bool);

    /**
     * @dev Transfers the allocated tokens to the sender ( once the distribution has started )
     */
    function claimTokens() external returns (bool);

    /**
     * @dev Transfers the all the allocated tokens to the respective addresses ( once the distribution has started and only by DEFAULT_ADMIN_ROLE)
     */
    function claimTokensForAll() external returns (bool);

    /**
     * @dev Get balance of allocated tokens of an address
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Return the amount of allocated tokens for `account` from the beginning
     */
    function allocatedTokensOf(address account) external view returns (uint256);

    /**
     * @dev Get pending tokens of an account ( amont / time )
     */
    function pendingTokensOf(address account) external view returns (uint256);

    /**
     * @dev Get unlockable tokens of an address
     */
    function unlockableTokens(address account) external view returns (uint256);

    /**
     * @dev Get released tokens of an address
     */
    function releasedTokensOf(address account) external view returns (uint256);

    /**
     * @dev Return the token IERC20
     */
    function token() external view returns (address);

    /**
     * @dev Return the total token hold by the contract
     */
    function tokenBalance() external view returns (uint256);

    /**
     * @dev Get total tokens supply
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Get total unallocated tokens
     */
    function totalUnallocatedTokens() external view returns (uint256);

    /**
     * @dev Return the total allocated tokens for all the addresses
     */
    function totalAllocatedTokens() external view returns (uint256);

    /**
     * @dev Return the total tokens that have been transferred among all the addresses
     */
    function totalReleasedTokens() external view returns (uint256);

    /**
     * @dev Return the percentage of unlocked tokens per `vestingClockTime()` once the vesting schedule has started
     */
    function vestingPerClock() external view returns (uint256);

    /**
     * @dev Return the number of seconds between two `vestingPerClock()`
     */
    function vestingClockTime() external view returns (uint256);

    /**
     * @dev Return true if all tokens have been allocated
     */
    function isSoldOut() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./IMechaniumCanReleaseUnintented.sol";

/**
 * @title MechaniumCanReleaseUnintented - Abstract class for util can release unintented tokens smart contract
 * @author EthernalHorizons - <https://ethernalhorizons.com/>
 * @custom:project-website  https://mechachain.io/
 * @custom:security-contact [email protected]
 */
abstract contract MechaniumCanReleaseUnintented is
    AccessControl,
    IMechaniumCanReleaseUnintented
{
    using SafeERC20 for IERC20;

    /**
     * @notice Event emitted when release unintented `amount` of `token` for `account` address
     */
    event ReleaseUintentedTokens(
        address indexed token,
        address indexed account,
        uint256 amount
    );

    /// Locked tokens that can't be released for contract
    mapping(address => bool) private _lockedTokens;

    /// fallback payable function ( used to receive ETH in tests )
    fallback() external payable {}

    /// receive payable function ( used to receive ETH in tests )
    receive() external payable {}

    /**
     * @notice Add a locked `token_` ( can't be released )
     */
    function _addLockedToken(address token_) internal {
        _lockedTokens[token_] = true;
    }

    /**
     * @notice Release an `amount` of `token` to an `account`
     * This function is used to prevent unintented tokens that got sent to be stuck on the contract
     * @param token The address of the token contract (zero address for claiming native coins).
     * @param account The address of the tokens/coins receiver.
     * @param amount Amount to claim.
     */
    function releaseUnintented(
        address token,
        address account,
        uint256 amount
    ) public override onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        require(amount > 0, "Amount must be superior to zero");
        require(
            account != address(0) && account != address(this),
            "Amount must be superior to zero"
        );
        require(!_lockedTokens[token], "Token can't be released");

        if (token == address(0)) {
            require(
                address(this).balance >= amount,
                "Address: insufficient balance"
            );
            (bool success, ) = account.call{value: amount}("");
            require(
                success,
                "Address: unable to send value, recipient may have reverted"
            );
        } else {
            IERC20 customToken = IERC20(token);
            require(
                customToken.balanceOf(address(this)) >= amount,
                "Address: insufficient balance"
            );
            customToken.safeTransfer(account, amount);
        }

        emit ReleaseUintentedTokens(token, account, amount);

        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/**
 * @dev Mechanim can release unintented smart contract interface
 * @author EthernalHorizons - <https://ethernalhorizons.com/>
 * @custom:project-website  https://mechachain.io/
 * @custom:security-contact [email protected]
 */
interface IMechaniumCanReleaseUnintented {
    /**
     * @dev Release unintented tokens sent to smart contract ( only admin role )
     * This function is used to prevent unintented tokens that got sent to be stuck on the contract
     * @param token The address of the token contract (zero address for claiming native coins).
     * @param account The address of the tokens/coins receiver.
     * @param amount Amount to claim.
     */
    function releaseUnintented(
        address token,
        address account,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/**
 * @dev Staking pool smart contract interface
 * @author EthernalHorizons - <https://ethernalhorizons.com/>
 * @custom:project-website  https://mechachain.io/
 * @custom:security-contact [email protected]
 */
interface IStakingPool {
    /**
     * @dev Stake tokens
     */
    function depositFor(
        address account,
        uint256 amount,
        uint256 lockPeriod
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}