/**
 *Submitted for verification at Etherscan.io on 2022-11-03
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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// File: contracts/1_Storage.sol


pragma solidity >=0.8.4;



//TODO add minimum stake

contract StableStaker is Ownable {
    event StableStaked(
        address indexed _wallet,
        uint256 _amount,
        uint256 _lockDuration,
        uint256 _reward
    );
    event FundsWithdrawn(address indexed _owner, uint256 _amount);
    event RewardsClaimed(address indexed _wallet, uint256 _amount);

    struct Stake {
        uint256 amount;
        uint256 lockDuration;
        uint256 reward;
        uint256 entryTimeStamp;
    }

    uint256 public minInvestmentAmount;
    address public usdtAddress = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    mapping(address => Stake[]) public stakes;
    mapping(uint256 => uint256) timelockRewards;

    constructor(
        uint256[] memory _lockInDays,
        uint256[] memory _rewardPercentage
    ) {
        for (uint256 i = 0; i < _lockInDays.length; i++)
            timelockRewards[_lockInDays[i]] = _rewardPercentage[i];
    }

    function setMinInvestment(uint256 _amount) external onlyOwner {
        minInvestmentAmount = _amount;
    }

    function stakeTokens(uint256 _amount, uint256 _lockDuration) external {
        require(timelockRewards[_lockDuration] != 0, "Invalid timelock period");
        require(
            _amount >= minInvestmentAmount,
            "Min investment amount not reached"
        );
        require(
            IERC20(usdtAddress).balanceOf(msg.sender) >= _amount,
            "Unsufficient balance"
        );
        require(
            IERC20(usdtAddress).allowance(msg.sender, address(this)) >= _amount,
            "Unsufficient allowance"
        );

        IERC20(usdtAddress).transferFrom(msg.sender, address(this), _amount);

        stakes[msg.sender].push(
            Stake(
                _amount,
                _lockDuration,
                (_amount * (100 + timelockRewards[_lockDuration])) / 100,
                block.timestamp
            )
        );

        emit StableStaked(
            msg.sender,
            _amount,
            _lockDuration,
            (_amount * (1 + timelockRewards[_lockDuration])) / 100
        );
    }

    function withDrawTokens() external onlyOwner {
        uint256 balance = IERC20(usdtAddress).balanceOf(address(this));

        require(balance > 0, "Balance is empty");

        IERC20(usdtAddress).transfer(msg.sender, balance);

        emit FundsWithdrawn(msg.sender, balance);
    }

    function removeStake(uint256 index, address _wallet) public {
        stakes[_wallet][index] = stakes[_wallet][stakes[_wallet].length - 1];
        stakes[_wallet].pop();
    }

    function claimRewards() external {
        Stake[] memory userStakes = stakes[msg.sender];
        require(userStakes.length != 0, "No stake for this address");
        uint256 rewards = 0;

        for (uint256 i = 0; i < userStakes.length; i++) {
            if (
                userStakes[i].entryTimeStamp +
                    userStakes[i].lockDuration *
                    60 *
                    60 *
                    24 <=
                block.timestamp &&
                userStakes[i].reward != 0
            ) {
                rewards += userStakes[i].reward;
                delete stakes[msg.sender][i];
            }
        }

        require(rewards != 0, "Staking locked");

        IERC20(usdtAddress).transfer(msg.sender, rewards);

        emit RewardsClaimed(msg.sender, rewards);
    }

    function setStableReward(address _newUsdtAddress) external onlyOwner {
        usdtAddress = _newUsdtAddress;
    }

    function getStakes(address _wallet) external view returns (Stake[] memory) {
        return stakes[_wallet];
    }
}