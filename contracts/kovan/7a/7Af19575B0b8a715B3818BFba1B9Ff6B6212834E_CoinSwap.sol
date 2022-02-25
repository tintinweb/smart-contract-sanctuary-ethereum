// SPDX-License-Identifier: MIT

// Stake, 
// Unstake, 
// issue rewards, 
// add allowed tokens, 
// get eth value

pragma solidity ^0.8.0;

import "Ownable.sol";
import "IERC20.sol";
import "AggregatorV3Interface.sol";

contract CoinSwap is Ownable {

    // token address -> staker's address -> amount he staked
    mapping(address => mapping(address => uint256)) public stakeBalance;
    // staker -> how many types of token he staked
    mapping(address => uint256) public uniqueTokensStaked;
    // map tokens to their priceFeed
    mapping(address => address) public tokenPriceFeed;

    address[] public stakers;
    address[] public allowedTokens;
    IERC20 public mangoToken;


    constructor(address _mangoTokenAddress) public {
        mangoToken = IERC20(_mangoTokenAddress);
    }

    // Set the Chainlink's price feed address -> to the token
    function setPriceFeedContract(address _token, address _priceFeed) public onlyOwner {
        tokenPriceFeed[_token] = _priceFeed;
    }

    // Reward the users with MGO tokens 
    // ( 1 ETH = $2000 USD == 2000 MGOs )
    function issueTokens() public onlyOwner {
        // Iterate through the stakers list
        for (uint256 stakersInx = 0; stakersInx < stakers.length; stakersInx++) {

            address recipient = stakers[stakersInx];
            // Get the Value of the recipient's amount present in stake (in USD)
            uint256 userHoldingAmount = getStakedValueOfUser(recipient);
            // Send reward 
            mangoToken.transfer(recipient, userHoldingAmount);
        }
    }

    // Get How much the User has been staked in total (returns in USD)
    function getStakedValueOfUser(address _user) public view returns (uint256) {
        uint256 totalValue = 0;
        // The user has to be staked atleast a min amount.
        require(uniqueTokensStaked[_user] > 0, "No Tokens Staked");
        for (uint256 allowedTokensInx = 0; allowedTokensInx < allowedTokens.length; allowedTokensInx++) {
            totalValue = totalValue + getUserSingleTokenValue(_user, allowedTokens[allowedTokensInx]);
        }
        return totalValue;
    }

    // Get How much the User has been staked on one token (returns in USD)
    function getUserSingleTokenValue(address _user, address _token) public view returns(uint256) {
        if(uniqueTokensStaked[_user] <= 0) {
            return 0;
        }  
        // Price of the token (eg. ETH) * staking balance of the user (eg. 5 ETH)   
        (uint256 price, uint256 decimals) = getTokenValue(_token);

        // stakingBal * price x 10 ^-decimals
        return (stakeBalance[_token][_user] * price/(10**decimals));
    }

    // Get the token's value using chainlink AggregatorV3 (in USD)
    function getTokenValue(address _token) public view returns(uint256, uint256) {
        // PriceFeedAddress
        address priceFeedAddress = tokenPriceFeed[_token];
        AggregatorV3Interface _pricefeed = AggregatorV3Interface(priceFeedAddress);
        (, int256 price, , ,) = _pricefeed.latestRoundData();
        uint256 decimals = uint256(_pricefeed.decimals());
        return (uint256(price), decimals);
    }

    // Stake Tokens
    function stakeTokens(uint256 _amount, address _token) public {
        // The conditions are
        // The amount must be greater than zero
        require(_amount > 0, "Amount must be more than 0");
        // Only valid tokens are allowed to stake
        require(tokenIsAlowed(_token), "Oops! This token is currently not allowed to stake.");
        
        // Get the amount from the user
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);

        // Update how many different tokens does a user hold.
        updateUniqueTokenStaked(msg.sender, _token);
        stakeBalance[_token][msg.sender] = stakeBalance[_token][msg.sender] + _amount; 
        if (uniqueTokensStaked[msg.sender] == 1) {
            stakers.push(msg.sender);
        }
    }

    // Update how many different tokens does a user hold.
    function updateUniqueTokenStaked(address _user, address _token) internal {
        if (stakeBalance[_token][_user] <=0 ) {
            uniqueTokensStaked[_user] = uniqueTokensStaked[_user] + 1;
        }
    }

    // Add allowed tokens 
    function addAllowedTokens(address _token) public onlyOwner {
        allowedTokens.push(_token);
    }

    // Check whether the token is allowed or not.
    function tokenIsAlowed(address _token) public returns (bool) {
        for(uint256 allowedTokensInx=0; allowedTokensInx < allowedTokens.length; allowedTokensInx++) {
            if (allowedTokens[allowedTokensInx] == _token)
                return true;
        }
        return false;
    }

    // Unstake Tokens
    function unstakeTokens(address _token) public {
        uint256 balance = stakeBalance[_token][msg.sender];
        require(balance > 0, "You need to have a balance to stake!");
        IERC20(_token).transfer(msg.sender, balance);
        stakeBalance[_token][msg.sender] = 0;
        uniqueTokensStaked[msg.sender] = uniqueTokensStaked[msg.sender] - 1;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Context.sol";

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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