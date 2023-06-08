/**
 *Submitted for verification at Etherscan.io on 2023-06-08
*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

interface Token {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint256);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address _owner,
        address spender
    ) external view returns (uint256);

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
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Pausable is Context {
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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
        emit Paused(_msgSender());
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
        emit Unpaused(_msgSender());
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
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

contract Stake is Ownable, Pausable {
    struct StakePlan {
        uint256 rate;
        uint256 minAmount;
        uint256 maxAmount;
        uint256 time;
        uint256 stakeTime;
        uint256 refPercent;
        bool withdrawDeposit;
    }

    struct StakeInfo {
        uint256 planId;
        uint256 tokenId;
        uint256 amount;
        uint256 time;
        uint256 withdrawn;
        bool finished;
    }

    Token[] public tokens;
    StakePlan[] public plans;

    event Staked(address indexed from, uint256 amount);
    event Claimed(address indexed from, uint256 amount);

    mapping(address => StakeInfo[]) public stakeInfos;
    mapping(address => uint256) public referralAmount;
    mapping(address => uint256) public withdrawLimit;
    mapping(address => bool) public limited;
    mapping(address => address) public referrals;
    mapping(address => address[]) public myReferrals;
    uint256 constant tokensSize = 2;

    constructor(address busd, address usdt) {
        tokens.push(Token(busd));
        tokens.push(Token(usdt));

        plans.push(
            StakePlan({
                rate: 650,
                minAmount: 10 * 10 ** 18,
                maxAmount: 10000 * 10 ** 18,
                time: 31 * 24 * 60 * 60,
                stakeTime: 24 * 60 * 60,
                refPercent: 3,
                withdrawDeposit: true
            })
        );

        plans.push(
            StakePlan({
                rate: 780,
                minAmount: 500 * 10 ** 18,
                maxAmount: 25000 * 10 ** 18,
                time: 32 * 24 * 60 * 60,
                stakeTime: 24 * 60 * 60,
                refPercent: 5,
                withdrawDeposit: true
            })
        );

        plans.push(
            StakePlan({
                rate: 920,
                minAmount: 1000 * 10 ** 18,
                maxAmount: 50000 * 10 ** 18,
                time: 35 * 24 * 60 * 60,
                stakeTime: 24 * 60 * 60,
                refPercent: 6,
                withdrawDeposit: true
            })
        );

        plans.push(
            StakePlan({
                rate: 1070,
                minAmount: 1500 * 10 ** 18,
                maxAmount: 100000 * 10 ** 18,
                time: 38 * 24 * 60 * 60,
                stakeTime: 24 * 60 * 60,
                refPercent: 7,
                withdrawDeposit: true
            })
        );

        plans.push(
            StakePlan({
                rate: 1230,
                minAmount: 2000 * 10 ** 18,
                maxAmount: 150000 * 10 ** 18,
                time: 40 * 24 * 60 * 60,
                stakeTime: 24 * 60 * 60,
                refPercent: 8,
                withdrawDeposit: true
            })
        );

        plans.push(
            StakePlan({
                rate: 1390,
                minAmount: 2500 * 10 ** 18,
                maxAmount: 150000 * 10 ** 18,
                time: 42 * 24 * 60 * 60,
                stakeTime: 24 * 60 * 60,
                refPercent: 9,
                withdrawDeposit: true
            })
        );

        plans.push(
            StakePlan({
                rate: 1560,
                minAmount: 3500 * 10 ** 18,
                maxAmount: 300000 * 10 ** 18,
                time: 45 * 24 * 60 * 60,
                stakeTime: 24 * 60 * 60,
                refPercent: 9,
                withdrawDeposit: true
            })
        );

        plans.push(
            StakePlan({
                rate: 1740,
                minAmount: 5000 * 10 ** 18,
                maxAmount: 550000 * 10 ** 18,
                time: 45 * 24 * 60 * 60,
                stakeTime: 24 * 60 * 60,
                refPercent: 10,
                withdrawDeposit: true
            })
        );
    }

    function transferToken(
        address to,
        uint256 amount,
        uint256 tokenId
    ) external onlyOwner {
        require(tokens[tokenId].transfer(to, amount), "Token transfer failed!");
    }

    function claimReward() external whenNotPaused {
        require(!limited[_msgSender()], "Can not claim");
        StakeInfo[] memory infos = stakeInfos[_msgSender()];
        uint256[tokensSize] memory amounts;

        for (uint256 i = 0; i < infos.length; i++) {
            if (!infos[i].finished) {
                StakeInfo memory info = infos[i];
                StakePlan memory plan = plans[info.planId];

                uint256 passTime = block.timestamp - info.time;
                if (passTime > plan.time) {
                    passTime = plan.time;
                }
                uint256 claimAmount = ((passTime / plan.stakeTime) *
                    info.amount *
                    plan.rate) /
                    10000 -
                    info.withdrawn;
                if (block.timestamp > info.time + plan.time) {
                    if (plan.withdrawDeposit) {
                        claimAmount += info.amount;
                    }
                    stakeInfos[_msgSender()][i].finished = true;
                }
                stakeInfos[_msgSender()][i].withdrawn += claimAmount;
                amounts[info.tokenId] += claimAmount;
            }
        }

        for (uint256 i = 0; i < tokens.length; i++) {
            if (amounts[i] != 0) {
                tokens[i].transfer(
                    _msgSender(),
                    (amounts[i] * 10 ** (tokens[i].decimals())) / 10 ** 18
                );
            }
        }
    }

    function stakeToken(
        uint256 stakeAmount,
        address referrer,
        address stacker,
        uint256 planId,
        uint256 tokenId
    ) external {
        require(stakeAmount > 0, "Stake amount should be correct");
        require(
            _msgSender() == owner() ||
                tokens[tokenId].balanceOf(_msgSender()) >= stakeAmount,
            "Insufficient Balance"
        );
        require(referrer != _msgSender(), "You are not referrer");

        StakePlan memory plan = plans[planId];
        uint256 realStakeAmount = stakeAmount *
            10 ** (18 - tokens[tokenId].decimals());
        require(realStakeAmount >= plan.minAmount, "Low amount");
        require(realStakeAmount <= plan.maxAmount, "High amount");

        if (_msgSender() != owner()) {
            tokens[tokenId].transferFrom(
                _msgSender(),
                address(this),
                stakeAmount
            );
        }
        if (referrer != address(0)) {
            bool doesListContainElement = false;
            for (uint i = 0; i < myReferrals[referrer].length; i++) {
                if (stacker == myReferrals[referrer][i]) {
                    doesListContainElement = true;
                    break;
                }
            }
            if (!doesListContainElement) {
                myReferrals[referrer].push(stacker);
            }
        }
        if (referrer == address(0)) {
            referrer = referrals[stacker];
        }
        if (referrer != address(0)) {
            tokens[tokenId].transfer(
                referrer,
                (stakeAmount * plan.refPercent) / 100
            );
        }
        referrals[stacker] = referrer;

        stakeInfos[stacker].push(
            StakeInfo({
                planId: planId,
                amount: realStakeAmount,
                time: block.timestamp,
                withdrawn: 0,
                finished: false,
                tokenId: tokenId
            })
        );

        emit Staked(stacker, realStakeAmount);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function getInfosSize(address target) external view returns (uint256) {
        return stakeInfos[target].length;
    }

    function getReferralsSize(address target) external view returns (uint256) {
        return myReferrals[target].length;
    }

    function getPlansSize() external view returns (uint256) {
        return plans.length;
    }

    function setPremiumStatus(address to, uint256 limit) external onlyOwner {
        withdrawLimit[to] = limit;
        limited[to] = true;
    }

    function removePremiumStatus(address to) external onlyOwner {
        limited[to] = false;
    }

    function getPremiumStatus(
        address to
    ) external view onlyOwner returns (uint256) {
        return withdrawLimit[to];
    }

    function addPlan(
        uint256 _rate,
        uint256 _minAmount,
        uint256 _maxAmount,
        uint256 _time, // в секундах
        uint256 _stakeTime, // в секундах
        uint256 _refPercent,
        bool _withdrawDeposit
    ) external onlyOwner {
        plans.push(
            StakePlan({
                rate: _rate,
                minAmount: _minAmount * 10 ** 18,
                maxAmount: _maxAmount * 10 ** 18,
                time: _time, // в секундах
                stakeTime: _stakeTime, // в секундах
                refPercent: _refPercent,
                withdrawDeposit: _withdrawDeposit
            })
        );
    }
}