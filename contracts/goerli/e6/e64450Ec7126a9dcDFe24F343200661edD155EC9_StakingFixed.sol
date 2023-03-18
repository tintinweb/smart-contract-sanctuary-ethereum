/**
 *Submitted for verification at Etherscan.io on 2023-03-18
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: StakingFixed.sol


pragma solidity ^0.8.12;


contract StakingFixed {
    struct Details {
        bool isStaking;
        uint256 startedStakingDate;
        uint256 amount;
    }

    mapping(address => Details) public stakeDetails;
    address public _stakeAddress;
    address public _rewardAddress;
    address public _admin;
    address public _treasuryAddress;
    uint256 public _percentageReturn;

    constructor(address stakeAddress, address rewardAddress, address treasuryAddress, uint256 percentageReturn) {
        _admin = msg.sender;
        _stakeAddress = stakeAddress;
        _rewardAddress = rewardAddress;
        _treasuryAddress = treasuryAddress;
        _percentageReturn = percentageReturn;
    }

    function stake(uint256 amount) public {
        require(amount > 0, "Stake amount can not be less or equals than 0.");
        require(stakeDetails[msg.sender].isStaking == false, "This wallet is already staking.");

        stakeDetails[msg.sender].isStaking = true;
        stakeDetails[msg.sender].amount = amount * 98 / 100;
        stakeDetails[msg.sender].startedStakingDate = block.timestamp;

        IERC20(_stakeAddress).transferFrom(msg.sender, address(this), amount * 98 / 100);
        IERC20(_stakeAddress).transferFrom(msg.sender, _treasuryAddress, amount * 2 / 100);
    }

    function unstake() public {
        require(stakeDetails[msg.sender].isStaking == true, "This wallet is not currently staking.");
      
        uint256 period = block.timestamp - stakeDetails[msg.sender].startedStakingDate;
        uint256 periodRounded = ((period / 60) - (period % 60) / 60);
        uint256 amount = stakeDetails[msg.sender].amount;

        IERC20(_stakeAddress).transfer(msg.sender, amount);
        IERC20(_rewardAddress).transfer(msg.sender, (amount * _percentageReturn / 100) / 365 * periodRounded);

        stakeDetails[msg.sender].isStaking = false;
        stakeDetails[msg.sender].amount = 0;
        stakeDetails[msg.sender].startedStakingDate = 0;
    }

    function setTreasuryAddress(address newAddress) public {
        require(msg.sender == _admin, "Admin only method.");
        _treasuryAddress = newAddress;
    }

    function withdrawalStakeBalalance() public {
        require(msg.sender == _admin, "Admin only method.");

        IERC20(_stakeAddress).transfer(_treasuryAddress, IERC20(_stakeAddress).balanceOf(address(this)));
    }

    function withdrawalRewardBalalance() public {
        require(msg.sender == _admin, "Admin only method.");

        IERC20(_rewardAddress).transfer(_treasuryAddress, IERC20(_rewardAddress).balanceOf(address(this)));
    }

    function balanceOfStakeAddress() public view returns (uint256) {
        return IERC20(_stakeAddress).balanceOf(address(this));
    }

    function balanceOfRewardAddress() public view returns (uint256) {
        return IERC20(_rewardAddress).balanceOf(address(this));
    }
}