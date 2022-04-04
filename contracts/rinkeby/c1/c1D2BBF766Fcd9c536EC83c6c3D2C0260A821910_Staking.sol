//SPDX-Licence-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Staking is Ownable {

    IERC20 internal stakeToken;

    struct Prediction {
        uint256 profit;
        uint256 stakes;
        uint256 end;
        uint256 start;
        uint256 price;
        uint32 option;
        bool claimed;
        address token;
    }

    struct Follower {
        address follower;
        uint256 _stake;
    }

    struct Staker {
        uint256 id;
        uint256 index;
    }

    mapping(address => uint256[]) predictors;
    mapping(uint256 => Prediction) Predictions;
    mapping(uint256 => Follower[]) followers;
    mapping(address => Staker[]) followerStakes;

    uint256 totalPredictions;
    uint256 totalAmountStaked;

    constructor(IERC20 _stakeToken) {
        stakeToken = _stakeToken;
    }

    // @notice Register a prediction
    // @param _predictionId The id of the prediction
    // @param _option The option of the prediction - 1 for long and 0 for short
    // @param _start The start time of the prediction
    // @param _end The end time of the prediction
    // @param _token The token being predicted
    // @param _price The predicted price of the token
    function predict(uint256 price, uint32 option, address token, uint256 end) public returns(uint256) {
        require(end - block.timestamp > 604800, "Predictions must be made at least one week in advance");
        require(option == 0 || option == 1, "Option must be either 0 or 1");

        Prediction memory prediction = Prediction({
            profit: 0,
            stakes: 0,
            end: end,
            start: block.timestamp,
            price: price,
            option: option,
            claimed: false,
            token: token
        });

        uint predictionId = totalPredictions + 1;

        Predictions[predictionId] = prediction;
        predictors[msg.sender].push(predictionId);
        totalPredictions++;
        return predictionId;
    }

    // @notice the helper function to record a stake
    // @param _predictionId The id of the prediction
    // @param _amount The amount of the stake
    function stakeHelper(uint256 amount, uint256 predictionId) internal {
        require(amount > 0, "Amount must be greater than 0");
        require(Predictions[predictionId].end != 0, "Invalid predictionId");

        totalAmountStaked += amount;
        Predictions[predictionId].stakes += amount;

        followers[predictionId].push(Follower({
            follower: msg.sender,
            _stake: amount
        }));

        uint256 index = followers[predictionId].length;
        followerStakes[msg.sender].push(Staker(
            predictionId,
            index
        ));
    }

    // @notice Record a stake
    // @param _predictionId The id of the prediction
    // @param _amount The amount of the stake
    function stake(uint256 amount, uint256 predictionId) public {
        require(stakeToken.balanceOf(msg.sender) >= amount, "You don't have enough tokens");
        bool transferred = stakeToken.transferFrom(msg.sender, address(this), amount);
        require(transferred, "Transfer failed. Approve contract to spend token");

        stakeHelper(amount, predictionId);     
    }

    // @notice withdraw a stake
    // @param _predictionId The id of the prediction
    // @param stakeId The index of the follower in the array of followers of a prediction
    function withdrawStakeHelper(uint256 predictionId, uint256 stakeId) internal view returns(uint256) {
        require(Predictions[predictionId].end != 0, "Invalid predictionId");
        require(Predictions[predictionId].end > block.timestamp + 86400, "Prediction is still active");
        require(followers[predictionId][stakeId].follower != msg.sender, "Stake is not yours");
        require(followers[predictionId][stakeId]._stake == 0, "You don't have enough stakes");

        uint profit;
        if (Predictions[predictionId].profit > 0) {
            uint percent = (followers[predictionId][stakeId]._stake * 95) / Predictions[predictionId].stakes;
            profit = (Predictions[predictionId].profit * percent) / 100;
        }
        uint reward = followers[predictionId][stakeId]._stake + profit;
        return reward;
    }
    
    function withdrawStake(uint256 predictionId, uint256 stakeId) public {
        uint reward = withdrawStakeHelper(predictionId, stakeId);
        stakeToken.transfer(msg.sender, reward);
        followers[predictionId][stakeId]._stake = 0;
    }

    // @notice Claim a profit
    // @param _predictionId The id of the prediction
    // @param stakeId The index of the prediction in the array of predictions made by the user
    function claimRewardHelper(uint256 predictionId, uint256 stakeId) internal view returns(uint256) {
        require(Predictions[predictionId].end != 0, "Invalid predictionId");
        require(Predictions[predictionId].end > block.timestamp + 86400, "Prediction is still active");
        require(predictors[msg.sender][stakeId] == predictionId, "You are not the predictor");
        require(Predictions[predictionId].profit == 0, "No profit to claim");

        uint profit;
        if (Predictions[predictionId].profit > 0) {
            profit = (Predictions[predictionId].profit * 3) / 100;
        }

        return profit;
    }

    function claimReward(uint256 predictionId, uint256 stakeId) public {
        uint profit = claimRewardHelper(predictionId, stakeId);

        Predictions[predictionId].claimed = true;
        stakeToken.transfer(msg.sender, profit);
    }

    function reStake(uint256 prevPredictionId, uint256 stakeId, uint256 newPredictionId) public {
        uint reward = withdrawStakeHelper(prevPredictionId, stakeId);
        followers[prevPredictionId][stakeId]._stake = 0;

        stakeHelper(reward, newPredictionId);
    }

    function stakeClaim(uint256 predictionId, uint256 stakeId) public {
        uint reward = claimRewardHelper(predictionId, stakeId);

        Predictions[predictionId].claimed = true;
        stakeHelper(reward, predictionId);
    }


    //read only functions
    function getPrediction(uint256 predictionId) public view returns(Prediction memory) {
        return Predictions[predictionId];
    }

    function getPredictionIds(address predictor) public view returns(uint256[] memory) {
        uint256[] memory predictionIds = predictors[predictor];
        return predictionIds;
    }

    function getFollowers(uint256 predictionId) public view returns(Follower[] memory) {
        return followers[predictionId];
    }

    function getFollowerStakes(address follower) public view returns(Staker[] memory) {
        return followerStakes[follower];
    }

    function getTotalAmountStaked() public view returns(uint256) {
        return totalAmountStaked;
    }

    function getTotalPredictions() public view returns(uint256) {
        return totalPredictions;
    }

    // onlyOwner functions

    function invest(uint256 amount, address bank) public onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        stakeToken.transfer(bank, amount);
    }

    function assignProfit(uint256 predictionId, uint256 profit) public onlyOwner {
        require(Predictions[predictionId].end != 0, "Invalid predictionId");
        require(Predictions[predictionId].end > block.timestamp + 86400, "Prediction is still active");
        require(Predictions[predictionId].profit == 0, "Prediction already has a profit");

        Predictions[predictionId].profit = profit;
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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