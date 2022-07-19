// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ownable.sol";
import "IERC20.sol";
import "AggregatorV3Interface.sol";


contract TokenFarm is Ownable {
    // token address -> staker address -> amount
    mapping(address => mapping(address => uint256)) public stakingBalance;
    // staker address -> unique tokens staked
    mapping(address => uint256) public uniqueTokensStaked;
    // token address -> token price feed address
    mapping(address => address) public tokenPriceFeedMapping;
    // array of stakers
    address[] public stakers;
    // array of the allowed tokens
    address[] public allowedTokens;
    // Storing the GWIN token as a global variable, IERC20 imported above, address passed into constructor
    IERC20 public gwinToken;


    // stakeTokens - DONE!
    // unStakeTokens - DONE! 
    // issueTokens - DONE!
    // addAllowedTokens - DONE!
    // getEthValue - DONE!

    // **  Staking Rewards  **
    // 1:1 ETH per GWIN
    // If 50 ETH and 50 DAI, and we want to reward 1 GWIN / 1 DAI

    // Right when we deploy this contract, we need to know the address of GWIN token
    constructor(address _gwinTokenAddress) public {
        // we pass in the address from the GwinToken.sol contract
        gwinToken = IERC20(_gwinTokenAddress);
    }

    function setPriceFeedContract(address _token, address _priceFeed) public onlyOwner {
        // sets the mapping for the token to its corresponding price feed contract
        tokenPriceFeedMapping[_token] = _priceFeed;
    }

    // Issue tokens to all stakers
    function issueTokens() public onlyOwner {
        // loops through the global array, stakers[], for length of stakers[]
        for (
            uint256 stakersIndex = 0; 
            stakersIndex < stakers.length; 
            stakersIndex++
        ) {
            // the recipient is the index of array stakers[]
            address recipient = stakers[stakersIndex];
            // userTotalValue is fetched through getUserTotalValue()
            uint256 userTotalValue = getUserTotalValue(recipient);
            // Send them a token reward based on their total value locked
            gwinToken.transfer(recipient, userTotalValue);
        }
    }

    // Gets the user's value
    function getUserTotalValue(address _user) public view returns (uint256) {
        // Initialize totalValue at 0
        uint256 totalValue = 0;
        // require that user has some tokens staked
        require(uniqueTokensStaked[_user] > 0, "No tokens staked!");
        // loop through the array of allowed tokens
        for (
            uint256 allowedTokensIndex = 0;
            allowedTokensIndex < allowedTokens.length;
            allowedTokensIndex++
        ){
            // loops through each single token, calls function to get the staked token's value for payout
            totalValue = totalValue + getUserSingleTokenValue(_user, allowedTokens[allowedTokensIndex]);
        }
        // returns the total value to pay out stake
        return totalValue;
    }

    // Gets the staking value to pay out for a single token
    function getUserSingleTokenValue(address _user, address _token) public view returns (uint256) {
        // if there is no tokens staked, return 0
        if (uniqueTokensStaked[_user] <= 0) {
            return 0;
        }
        // passes getTokenValue() the _token address to get current price and decimals
        (uint256 price, uint256 decimals) = getTokenValue(_token);
        // returns the staking value to pay out
        return (
            // 10,000000000000000000 ETH
            // ETH/USD --> 100,00000000 USD/ 1 ETH
            // 10 * 100 = 1,000

            // Mapped staking balance * price / decimals
            stakingBalance[_token][_user] * price / (10**decimals)
        );
    }

    function getTokenValue(address _token) public view returns (uint256, uint256) {
        // priceFeedAddress is pulled from the mapping
        address priceFeedAddress = tokenPriceFeedMapping[_token];
        // priceFeedAddress is fed into the AggregatorV3Interface
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAddress);
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        // set number of decimals for token value
        uint256 decimals = priceFeed.decimals();
        // return token price and decimals
        return (uint256(price), decimals);
    }

    function stakeTokens(uint256 _amount, address _token) public {
        // Make sure that the amount to stake is more than 0
        require(_amount > 0, "Amount must be more than 0");
        // Check whether token is allowed by passing it to tokenIsAllowed()
        require(tokenIsAllowed(_token), "Token is not currently allowed.");
        
        // NOTES: transferFrom  --  ERC20s have transfer and transfer from. 
        // Transfer only works if you call it from the wallet that owns the token

        // Transfer _amount of _token to the contract address
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        // Set the _token as one of the unique tokens staked by the staker
        updateUniqueTokensStaked(msg.sender, _token);
        // Update the staking balance for the staker
        stakingBalance[_token][msg.sender] = stakingBalance[_token][msg.sender] + _amount;
        // If after this, the staker has just 1 token staked, then add the staker to stakers[] array
        if (uniqueTokensStaked[msg.sender] == 1){
            stakers.push(msg.sender);
        }
    }

    // NOTES: Vulnerable to Reentrancy attacks? Yeah. Probably.

    // allows staker to unstake tokens
    function unstakeTokens(address _token) public {
        // set current balance by checking the stakingBalance mapping
        uint256 balance = stakingBalance[_token][msg.sender];
        // current balance must be more than 0
        require(balance > 0, "Staking balance cannot be less than 0");
        // transfer the entire current balance to the staker
        IERC20(_token).transfer(msg.sender, balance);
        // update the mapping of the stakingBalance to 0
        stakingBalance[_token][msg.sender] = 0;
        // reduce the unique tokens staked mapping by 1
        uniqueTokensStaked[msg.sender] = uniqueTokensStaked[msg.sender] - 1;
        // we could also remove the staker entirely... later?
    }

    // updates the mapping of user to tokens staked, could be called INCREMENT
    function updateUniqueTokensStaked(address _user, address _token) internal {
        
        // NOTES: I feel like it should be '>=' below instead
        
        // If the staking balance of the staker is less that or equal to 0 then...
        if (stakingBalance[_token][_user] <= 0) {
            // add 1 to the number of unique tokens staked
            uniqueTokensStaked[_user] = uniqueTokensStaked[_user] + 1;
        }
    }

    // add a token address to allowed tokens for staking, only owner can call
    function addAllowedTokens(address _token) public onlyOwner {
        // add token address to allowedTokens[] array
        allowedTokens.push(_token);
    }

    // returns whether token is allowed
    function tokenIsAllowed(address _token) public view returns (bool) {
        // Loops through the array of allowedTokens[] for length of array
        for(uint256 allowedTokensIndex=0; allowedTokensIndex < allowedTokens.length; allowedTokensIndex++){
            // If token at index matched the passed in token, return true
            if(allowedTokens[allowedTokensIndex] == _token){
                return true;
            }
        }
        return false;
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