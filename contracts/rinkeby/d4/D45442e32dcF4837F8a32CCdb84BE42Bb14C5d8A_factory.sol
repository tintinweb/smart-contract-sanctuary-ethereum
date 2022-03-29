/**
 *Submitted for verification at Etherscan.io on 2022-03-29
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.8.0;
pragma abicoder v2;

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract factory is Ownable {
    IERC20 public rewardToken;
    address stakingContract;
    uint256 waitingPeriod;

    event RewardReceived(
        uint256 _amount,
        address _beneficiary,
        uint256 _timestamp
    );
    event RewardWithdrawn(
        uint256 _amount,
        address _beneficiary,
        uint256 _timestamp
    );

    struct Reward {
        uint amount;
        address beneficiary;
        uint claimTime;
    }
    mapping(address => Reward[]) public userRewards;

    constructor(IERC20 _rewardToken) {
        rewardToken = _rewardToken;
        waitingPeriod = 365 days;
    }

    modifier onlyStakingContract() {
        require(msg.sender == stakingContract);
        _;
    }

    function importRewards(address _user, uint256 _amount)
        external
        onlyStakingContract
    {
        userRewards[_user].push(Reward(_amount, _user, block.timestamp));
        emit RewardReceived(_amount, _user, block.timestamp);
    }

    function withdrawRewards(uint _index) public {
        require(
            userRewards[msg.sender][_index].amount > 0,
            "No rewards to withdraw"
        );
        require(
            block.timestamp >
                (userRewards[msg.sender][_index].claimTime + block.timestamp),
            "funds are locked"
        );
        uint256 length = userRewards[msg.sender].length;
        uint256 amount = userRewards[msg.sender][_index].amount;
        // delete userRewards[msg.sender][_index];
        userRewards[msg.sender][_index] = userRewards[msg.sender][length - 1];
        userRewards[msg.sender].pop();

        IERC20(rewardToken).transfer(msg.sender, amount);
        emit RewardReceived(amount, msg.sender, block.timestamp);
    }

    function withdrawAll() external {
        for (uint8 i = 0; i < userRewards[msg.sender].length; i++) {
            withdrawRewards(i);
            userRewards[msg.sender].pop();
        }
    }

    function allRewards(address _user)
        public
        view
        returns (Reward[] memory rewards)
    {
        return userRewards[_user];
    }

    function setWaitingPeriod(uint _waitingPeriod) external onlyOwner {
        waitingPeriod = _waitingPeriod;
    }

    function setStakingContract(address _stakingContract) external onlyOwner {
        stakingContract = _stakingContract;
    }
}