// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

    error SpinTheWheel__NotOwner();
    error SpinTheWheel__SpinNotOpen();
    error SpinTheWheel__RewardIsNotSetupYet();
    error SpinTheWheel__MinAmountNotReached();
    error SpinTheWheel__UserBalanceIsNotEnough();
    error SpinTheWheel__TransferTokenFailed();
    error SpinTheWheel__TransferUsdtFailed();
    error SpinTheWheel__TransferBnbFailed();
    error SpinTheWheel__RewardTypeError();
    error SpinTheWheel__ContractBalanceIsNotEnough();

contract SpinTheWheel {

    event SpinComplete(Reward reward, address receiver);
    event RandomResult(uint256 data, uint256 rnd, uint result);

    //RewardType
    //1 = TOKEN_POS,
    //2 = TOKEN_NEG,
    //3 = BNB,
    //4 = USDT
    //5 = HOT_WALLET

    struct Reward {
        uint256 ratio;
        uint256 rewardType;
        uint256 value;
    }

    // General constants
    uint32 private constant HUNDRED_PERCENT = 100;

    // Base info
    address public s_owner;
    address public _spinInuAddress;
    address public immutable _usdtAddress;
    uint32 private constant MIN_REWARDS = 1;
    bool public _isPaused;

    // Wheel info
    uint256 public _maxSpinBoolPercentage;
    uint256 public _qualifiedSpinBoolPercentage;
    uint256 public _minSpinAmount;
    Reward[] public _rewards;
    uint256 public _totalWeight;
    uint256 public _randomNo = 0;
    address payable public _hotWallet;
    uint256 public _hotWalletFeeReward;

    //// constructor
    constructor(
        address spinInuAddress,
        address usdtAddress
    ) {
        _spinInuAddress = spinInuAddress;
        _isPaused = true;
        s_owner = msg.sender;
        _usdtAddress = usdtAddress;
        _hotWallet = payable(msg.sender);
    }
    //// receive
    //// fallback
    //// external
    function updateWheelInfo(
        uint256 maxSpinBoolPercentage,
        uint256 qualifiedSpinBoolPercentage,
        uint256 minSpinAmount,
        uint256 hotWalletFeeReward,
        Reward[] memory rewards) external onlyOwner {
        _maxSpinBoolPercentage = maxSpinBoolPercentage;
        _qualifiedSpinBoolPercentage = qualifiedSpinBoolPercentage;
        _minSpinAmount = minSpinAmount;
        _hotWalletFeeReward = hotWalletFeeReward;
        delete _rewards;
        _totalWeight = 0;
        for (uint i = 0; i < rewards.length; i++) {
            _rewards.push(Reward(rewards[i].ratio, rewards[i].rewardType, rewards[i].value));
            _totalWeight += rewards[i].ratio;
        }
    }

    function spin(uint256 amount) external notPaused {
        if (_rewards.length < MIN_REWARDS) {
            revert("SpinTheWheel__RewardIsNotSetupYet");
        }
        if (amount < _minSpinAmount) {
            revert("SpinTheWheel__MinAmountNotReached");
        }
        uint256 maxSpinAmount = getMaxSpinAmount();
        if (amount > maxSpinAmount) {
            amount = maxSpinAmount;
        }
        if (IERC20(_spinInuAddress).balanceOf(msg.sender) < amount) {
            revert("SpinTheWheel__UserBalanceIsNotEnough");
        }
        _randomNo += 1;
        uint256 rewardPos = getRandomReward(_randomNo);
        Reward memory reward = _rewards[rewardPos];
        emit SpinComplete(reward, msg.sender);

        deliveryReward(amount, reward.rewardType, reward.value);
    }

    function depositBnb() external payable {}

    function withdrawBnb() external onlyOwner {
        msg.sender.call{value : address(this).balance}("");
    }

    function depositUsdt(uint256 amount) external {
        IERC20(_usdtAddress).transferFrom(msg.sender, address(this), amount);
    }

    function withdrawUsdt() external onlyOwner {
        uint256 balance = IERC20(_usdtAddress).balanceOf(address(this));
        IERC20(_usdtAddress).transfer(msg.sender, balance);
    }

    function depositToken(uint256 amount) external {
        IERC20(_spinInuAddress).transferFrom(msg.sender, address(this), amount);
    }

    function withdrawToken() external onlyOwner {
        uint256 balance = IERC20(_spinInuAddress).balanceOf(address(this));
        IERC20(_spinInuAddress).transfer(msg.sender, balance);
    }

    function getSpinInuAddress() external view returns (address) {
        return _spinInuAddress;
    }

    function getUsdtAddress() external view returns (address) {
        return _usdtAddress;
    }

    function getMaxSpinBoolPercentage() external view returns (uint256) {
        return _maxSpinBoolPercentage;
    }

    function getQualifiedSpinBoolPercentage() external view returns (uint256) {
        return _qualifiedSpinBoolPercentage;
    }

    function getMinSpinAmount() external view returns (uint256) {
        return _minSpinAmount;
    }

    function getTotalWeight() external view returns (uint256) {
        return _totalWeight;
    }

    function getRewards() external view returns (Reward[] memory) {
        return _rewards;
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getHotWalletAddress() external view returns (address) {
        return _hotWallet;
    }

    function getHotWalletFeeReward() external view returns (uint256) {
        return _hotWalletFeeReward;
    }

    function openSpin() external onlyOwner {
        _isPaused = false;
    }

    function pauseSpin() external onlyOwner {
        _isPaused = true;
    }

    //// public

    function getMaxSpinAmount() public view returns (uint256){
        return (IERC20(_spinInuAddress).balanceOf(address(this)) * _maxSpinBoolPercentage) / 100;
    }

    //// internal
    //// private
    function getRandomReward(uint256 seed) private returns (uint256) {
        uint256 data = uint256(keccak256(abi.encodePacked(block.timestamp + block.difficulty + block.number, msg.sender, seed)));
        uint256 rnd = data % _totalWeight + 1;
        uint256 tmp_rnd = rnd;
        for (uint i = 0; i < _rewards.length; i++) {
            if (rnd > _rewards[i].ratio) {
                rnd -= _rewards[i].ratio;
            } else {
                emit RandomResult(data, tmp_rnd, i);
                return i;
            }
        }
        return 0;
    }

    function deliveryReward(uint256 spinAmount, uint256 rewardType, uint256 rewardValue) private {
        if (rewardType == 1) {
            rewardTokenPositive(spinAmount, rewardValue);
        } else if (rewardType == 2) {
            rewardTokenNegative(spinAmount, rewardValue);
        } else if (rewardType == 3) {
            rewardBnb(rewardValue);
        } else if (rewardType == 4) {
            rewardUsdt(rewardValue);
        } else if (rewardType == 5) {
            rewardHotWallet();
        } else {
            revert("SpinTheWheel__RewardTypeError");
        }
    }

    function rewardTokenNegative(uint256 spinAmount, uint256 percentage) private {
        if (percentage == 0) return;
        uint256 rewardAmount = spinAmount * percentage / HUNDRED_PERCENT;
        if (!IERC20(_spinInuAddress).transferFrom(msg.sender, address(this), rewardAmount)) {
            revert("SpinTheWheel__TransferTokenFailed");
        }
    }

    function rewardTokenPositive(uint256 spinAmount, uint256 percentage) private {
        if (percentage == 0) return;
        uint256 rewardAmount = spinAmount * percentage / HUNDRED_PERCENT;
        uint256 hotWalletAmount = rewardAmount * _hotWalletFeeReward / HUNDRED_PERCENT;
        rewardAmount -= hotWalletAmount;
        if (!IERC20(_spinInuAddress).transfer(_hotWallet, hotWalletAmount)) {
            revert("SpinTheWheel__TransferTokenFailed");
        }
        if (!IERC20(_spinInuAddress).transfer(msg.sender, rewardAmount)) {
            revert("SpinTheWheel__TransferTokenFailed");
        }
    }

    function rewardUsdt(uint256 amount) private {
        if (!IERC20(_usdtAddress).transfer(msg.sender, amount)) {
            revert("SpinTheWheel__TransferUsdtFailed");
        }
    }

    function rewardBnb(uint256 amount) private {
        if (address(this).balance < amount) {
            revert("SpinTheWheel__ContractBalanceIsNotEnough");
        }
        (bool success,) = msg.sender.call{value : amount}("");
        if (!success) {
            revert("SpinTheWheel__TransferBnbFailed");
        }
    }

    function rewardHotWallet() private {
        _hotWallet = payable(msg.sender);
    }

    //// view / pure


    modifier onlyOwner() {
        if (msg.sender != s_owner) {
            revert SpinTheWheel__NotOwner();
        }
        _;
    }

    modifier notPaused {
        if (_isPaused) {
            revert SpinTheWheel__SpinNotOpen();
        }
        _;
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