// SPDX-License-Identifier: MIT
/**
 *Submitted for verification at BscScan.com on 2022-06-30
 */

pragma solidity 0.8.7;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library Address {
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in construction,
        // since the code is only stored at the end of the constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) - value;
        callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

contract ReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor() {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(
            localCounter == _guardCounter,
            "ReentrancyGuard: reentrant call"
        );
    }
}

interface IStakingRewards {
    function earned(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function stake(uint256 amount) external;

    function stakeFor(uint256 amount, address user) external;

    function getReward() external;

    function withdraw(uint256 amount) external;

    function withdrawAndGetReward(uint256 amount) external;

    function exit() external;
}

contract Ownable {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed from, address indexed to);

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: Caller is not the owner");
        _;
    }

    function transferOwnership(address transferOwner) external onlyOwner {
        require(transferOwner != newOwner);
        newOwner = transferOwner;
    }

    function acceptOwnership() external virtual {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

abstract contract Pausable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

interface IERC20Permit {
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

contract StakingRewardsSameTokenFixedAPY is
    IStakingRewards,
    ReentrancyGuard,
    Ownable,
    Pausable
{
    using SafeERC20 for IERC20;

    IERC20 public immutable token;
    IERC20 public immutable stakingToken; //read only variable for compatibility with other contracts
    uint256 public rewardRate;
    uint256 public constant rewardDuration = 365 days;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    uint256 public rateChangesNonce;
    mapping(address => uint256) public weightedStakeDate;
    mapping(address => mapping(uint256 => StakeNonceInfo))
        public stakeNonceInfos;
    mapping(address => uint256) public stakeNonces;
    mapping(uint256 => APYCheckpoint) APYcheckpoints;

    struct StakeNonceInfo {
        uint256 stakeTime;
        uint256 tokenAmount;
        uint256 rewardRate;
    }

    struct APYCheckpoint {
        uint256 timestamp;
        uint256 rewardRate;
    }

    event RewardUpdated(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event Rescue(address indexed to, uint256 amount);
    event RescueToken(
        address indexed to,
        address indexed token,
        uint256 amount
    );
    event RewardRateUpdated(
        uint256 indexed rateChangesNonce,
        uint256 rewardRate,
        uint256 timestamp
    );

    constructor(address _token, uint256 _rewardRate) {
        token = IERC20(_token);
        stakingToken = IERC20(_token);
        rewardRate = _rewardRate;
        emit RewardRateUpdated(rateChangesNonce, _rewardRate, block.timestamp);
        APYcheckpoints[rateChangesNonce++] = APYCheckpoint(
            block.timestamp,
            rewardRate
        );
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function earnedByNonce(address account, uint256 nonce)
        public
        view
        returns (uint256)
    {
        return
            (stakeNonceInfos[account][nonce].tokenAmount *
                (block.timestamp - stakeNonceInfos[account][nonce].stakeTime) *
                stakeNonceInfos[account][nonce].rewardRate) /
            (100 * rewardDuration);
    }

    function earned(address account)
        public
        view
        override
        returns (uint256 totalEarned)
    {
        for (uint256 i = 0; i < stakeNonces[account]; i++) {
            totalEarned += earnedByNonce(account, i);
        }
    }

    function stakeWithPermit(
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external nonReentrant {
        require(amount > 0, "StakingRewardsSameTokenFixedAPY: Cannot stake 0");
        _totalSupply += amount;
        uint256 previousAmount = _balances[msg.sender];
        uint256 newAmount = previousAmount + amount;
        weightedStakeDate[msg.sender] =
            ((weightedStakeDate[msg.sender] * previousAmount) / newAmount) +
            ((block.timestamp * amount) / newAmount);
        _balances[msg.sender] = newAmount;

        // permit
        IERC20Permit(address(token)).permit(
            msg.sender,
            address(this),
            amount,
            deadline,
            v,
            r,
            s
        );

        token.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function stake(uint256 amount) external override nonReentrant {
        require(amount > 0, "StakingRewardsSameTokenFixedAPY: Cannot stake 0");
        token.safeTransferFrom(msg.sender, address(this), amount);

        _totalSupply += amount;
        _balances[msg.sender] += amount;

        uint256 stakeNonce = stakeNonces[msg.sender]++;
        stakeNonceInfos[msg.sender][stakeNonce].tokenAmount = amount;
        stakeNonceInfos[msg.sender][stakeNonce].stakeTime = block.timestamp;
        stakeNonceInfos[msg.sender][stakeNonce].rewardRate = rewardRate;
        emit Staked(msg.sender, amount);
    }

    function stakeFor(uint256 amount, address user)
        external
        override
        nonReentrant
    {
        require(amount > 0, "StakingRewardsSameTokenFixedAPY: Cannot stake 0");
        require(
            user != address(0),
            "StakingRewardsSameTokenFixedAPY: Cannot stake for zero address"
        );
        _totalSupply += amount;
        uint256 previousAmount = _balances[user];
        uint256 newAmount = previousAmount + amount;
        weightedStakeDate[user] =
            ((weightedStakeDate[user] * previousAmount) / newAmount) +
            ((block.timestamp * amount) / newAmount);
        _balances[user] = newAmount;
        token.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(user, amount);
    }

    //A user can withdraw its staking tokens even if there is no rewards tokens on the contract account

    function withdraw(uint256 nonce)
        public
        override
        nonReentrant
        whenNotPaused
    {
        require(
            stakeNonceInfos[msg.sender][nonce].tokenAmount > 0,
            "StakingRewardsSameTokenFixedAPY: This stake nonce was withdrawn"
        );
        uint256 amount = stakeNonceInfos[msg.sender][nonce].tokenAmount;
        _totalSupply -= amount;
        _balances[msg.sender] -= amount;
        stakeNonceInfos[msg.sender][nonce].tokenAmount = 0;
        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function getReward() public override nonReentrant whenNotPaused {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            for (uint256 i = 0; i < stakeNonces[msg.sender]; i++) {
                stakeNonceInfos[msg.sender][i].stakeTime = block.timestamp;
            }
            token.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function withdrawAndGetReward(uint256 nonce) external override {
        getReward();
        withdraw(nonce);
    }

    function exit() external override {
        getReward();
        for (uint256 i = 0; i < stakeNonces[msg.sender]; i++) {
            if (stakeNonceInfos[msg.sender][i].tokenAmount > 0) {
                withdraw(i);
            }
        }
    }

    function setPaused(bool _paused) external onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    function updateRewardRate(uint256 reward) external onlyOwner {
        rewardRate = reward;
        emit RewardUpdated(reward);
    }

    function rescue(
        address to,
        IERC20 tokenAddress,
        uint256 amount
    ) external onlyOwner {
        require(
            to != address(0),
            "StakingRewardsSameTokenFixedAPY: Cannot rescue to the zero address"
        );
        require(amount > 0, "StakingRewardsSameTokenFixedAPY: Cannot rescue 0");
        require(
            tokenAddress != token,
            "StakingRewardsSameTokenFixedAPY: Cannot rescue staking/reward token"
        );

        tokenAddress.safeTransfer(to, amount);
        emit RescueToken(to, address(tokenAddress), amount);
    }

    function rescue(address payable to, uint256 amount) external onlyOwner {
        require(
            to != address(0),
            "StakingRewardsSameTokenFixedAPY: Cannot rescue to the zero address"
        );
        require(amount > 0, "StakingRewardsSameTokenFixedAPY: Cannot rescue 0");

        to.transfer(amount);
        emit Rescue(to, amount);
    }
}