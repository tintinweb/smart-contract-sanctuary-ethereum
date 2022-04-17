/**
 *Submitted for verification at Etherscan.io on 2022-04-17
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;



// Part: OpenZeppelin/[email protected]/Context

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

// Part: OpenZeppelin/[email protected]/IERC20

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

// Part: smartcontractkit/[email protected]/AggregatorV3Interface

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// Part: OpenZeppelin/[email protected]/Ownable

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

// File: SavvyFinanceStaking.sol

contract SavvyFinanceStaking is Ownable {
    IERC20 public rewardToken;
    mapping(address => mapping(address => uint256)) public stakingData;
    mapping(address => uint256) public stakersToUniqueTokensStaked;
    mapping(address => uint256) public stakersToRewards;
    mapping(address => address) public tokensToPriceFeeds;
    address[] public stakers;
    address[] public allowedTokens;

    constructor(address _reward_token) {
        rewardToken = IERC20(_reward_token);
    }

    function stakeToken(address _token, uint256 _amount) public {
        require(tokenIsAllowed(_token), "You can't stake this token.");
        require(_amount > 0, "Amount must be greater than zero.");
        require(
            IERC20(_token).balanceOf(msg.sender) >= _amount,
            "Insufficient balance."
        );
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        updateStakersData(msg.sender, _token, "stake");
        stakingData[_token][msg.sender] += _amount;
    }

    function unstakeToken(address _token, uint256 _amount) public {
        require(_amount > 0, "Amount must be greater than zero.");
        require(
            stakingData[_token][msg.sender] >= _amount,
            "Amount is greater than staking balance."
        );
        IERC20(_token).transfer(msg.sender, _amount);
        stakingData[_token][msg.sender] -= _amount;
        updateStakersData(msg.sender, _token, "unstake");
    }

    function updateStakersData(
        address _staker,
        address _token,
        string memory _action
    ) internal {
        if (stakingData[_token][_staker] <= 0) {
            if (
                keccak256(abi.encodePacked(_action)) ==
                keccak256(abi.encodePacked("stake"))
            ) {
                stakersToUniqueTokensStaked[_staker]++;

                if (stakersToUniqueTokensStaked[_staker] == 1) {
                    stakers.push(msg.sender);
                }
            }

            if (
                keccak256(abi.encodePacked(_action)) ==
                keccak256(abi.encodePacked("unstake"))
            ) {
                stakersToUniqueTokensStaked[_staker]--;

                if (stakersToUniqueTokensStaked[_staker] == 0) {
                    removeFrom(stakers, _staker);
                }
            }
        }
    }

    function tokenIsAllowed(address _token) public view returns (bool) {
        for (
            uint256 allowedTokensIndex = 0;
            allowedTokensIndex < allowedTokens.length;
            allowedTokensIndex++
        ) {
            if (allowedTokens[allowedTokensIndex] == _token) {
                return true;
            }
        }
        return false;
    }

    function addAllowedToken(address _token) public onlyOwner {
        allowedTokens.push(_token);
    }

    function removeAllowedToken(address _token) public onlyOwner {
        removeFrom(allowedTokens, _token);
    }

    function removeFrom(address[] storage _array, address _value) internal {
        for (uint256 arrayIndex = 0; arrayIndex < _array.length; arrayIndex++) {
            if (_array[arrayIndex] == _value) {
                // move to last index
                _array[arrayIndex] = _array[_array.length - 1];
                // delete last index
                _array.pop();
            }
        }
    }

    function rewardStakers() public onlyOwner {
        for (
            uint256 stakersIndex = 0;
            stakersIndex < stakers.length;
            stakersIndex++
        ) {
            uint256 rewardAmount = getStakerTotalValue(
                stakers[stakersIndex],
                allowedTokens
            ) / 100;
            rewardToken.transfer(stakers[stakersIndex], rewardAmount);
        }
    }

    function getStakerTotalValue(address _staker, address[] memory _tokens)
        public
        view
        returns (uint256)
    {
        if (stakersToUniqueTokensStaked[_staker] <= 0) return 0;
        uint256 stakerTotalValue = 0;
        for (
            uint256 tokensIndex = 0;
            tokensIndex < _tokens.length;
            tokensIndex++
        ) {
            stakerTotalValue += getStakerTokenValue(
                _staker,
                _tokens[tokensIndex]
            );
        }
        return stakerTotalValue;
    }

    function getStakerTokenValue(address _staker, address _token)
        public
        view
        returns (uint256)
    {
        if (stakersToUniqueTokensStaked[_staker] <= 0) return 0;
        if (stakingData[_token][_staker] <= 0) return 0;
        (uint256 price, uint256 decimals) = getTokenPrice(_token);
        return ((stakingData[_token][_staker] * price) / (10**decimals));
    }

    function getTokenPrice(address _token)
        public
        view
        returns (uint256, uint256)
    {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            tokensToPriceFeeds[_token]
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return (uint256(price), uint256(priceFeed.decimals()));
    }

    function setTokenPriceFeed(address _token, address _price_feed)
        public
        onlyOwner
    {
        tokensToPriceFeeds[_token] = _price_feed;
    }
}