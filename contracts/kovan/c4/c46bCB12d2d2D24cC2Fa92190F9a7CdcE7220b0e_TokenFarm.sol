// want to be able to stake tokens
// unstake tokens
// issue tokens (issuing token rewards to those who stake); and issue based on the amount they've contributed
// add allowed tokens to add more tokens to the tokens that can be staked onto our contract
// and want ability to get the value of eth/usd

// SPDX-License-Identifier: MIT

import "Ownable.sol";
import "IERC20.sol";
import "AggregatorV3Interface.sol";

pragma solidity ^0.8.0;

contract TokenFarm is Ownable {
    // create a mapping to keep track of how much tokens has been send to us by who
    // mapping will make the token address -> staker address -> amount (how much of each token each staker has staked)
    mapping(address => mapping(address => uint256)) public stakingBalance;
    mapping(address => uint256) public uniqueTokensStaked;
    mapping(address => address) public tokenPriceFeedMapping;
    // make a list of all stakers
    address[] public stakers;
    address[] public allowedTokens;
    // store the dapptoken as a global variable
    IERC20 public dappToken;

    // if someone gives 100 ETH, we want to reward at a 1:1 ratio and give them 1 DappToken per ETH given
    // if someone gives 50 ETH and 50 DAI, and we want to give a reward of 1 DappToken per 1 Dai, we would have to also convert the ETH to DAI to determine the reward
    // we will do this with the function called issueTokens

    // create a constructor to know the address of the reward token (DappToken) right as we deploy the contract
    constructor(address _dappTokenAddress) public {
        dappToken = IERC20(_dappTokenAddress);
    }

    // function to set the price feed associated with the token
    function setPriceFeedContract(address _token, address _priceFeed)
        public
        onlyOwner
    {
        tokenPriceFeedMapping[_token] = _priceFeed;
    }

    function issueTokens() public onlyOwner {
        // Issue tokens to all stakers
        // need a list of all stakers; make this above
        for (
            uint256 stakersIndex = 0;
            stakersIndex < stakers.length;
            stakersIndex++
        ) {
            address recipient = stakers[stakersIndex];
            // then send these recipients a token reward based on their token value locked; need a function (getUserTotalValue) to get their total value locked
            uint256 userTotalValue = getUserTotalValue(recipient);
            // since dappToken is now a global variable with its associated address, can now call functions on it
            // can call transfer instead of transferFrom because this contract will hold all of the DappTokens
            // dappToken.transfer(recipient, ?amount?)
            dappToken.transfer(recipient, userTotalValue);
        }
    }

    // using this function to find out how much of each token someone has across all tokens
    function getUserTotalValue(address _user) public view returns (uint256) {
        uint256 totalValue = 0;
        require(uniqueTokensStaked[_user] > 0, "No tokens staked!");
        for (
            uint256 allowedTokensIndex = 0;
            allowedTokensIndex < allowedTokens.length;
            allowedTokensIndex++
        ) {
            // need to find how much someone has in one token for all tokens
            totalValue =
                totalValue +
                getUserSingleTokenValue(
                    _user,
                    allowedTokens[allowedTokensIndex]
                );
        }
        return totalValue;
    }

    // want to get value of how much this person staked of this single token
    function getUserSingleTokenValue(address _user, address _token)
        public
        view
        returns (uint256)
    {
        // if they staked 1 ETH and 1 ETH = $2000USD, this should return 2000
        // if they staked 200 DAI and 200 DAI = $200USD, this should return 200
        if (uniqueTokensStaked[_user] <= 0) {
            return 0;
        }
        // need to get the price of the token and then multiply it by the staking balance of the token from the user: need to create new function called getTokenValue
        (uint256 price, uint256 decimals) = getTokenValue(_token);
        return // example: user stakes 10 ETH, price feed contract gives us ETH/USD, suppose price is 100 (ETH/USD = 100)
        // so first bit is 10ETH * 100 => 1000
        // then divide by decimals (decimals is 10**decimals because the ETH has 18 decimals whereas the price feed contract which returns the decimals value only returns in 8 decimals)
        ((stakingBalance[_token][_user] * price) / (10**decimals));
    }

    function getTokenValue(address _token)
        public
        view
        returns (uint256, uint256)
    {
        // use the chainlink price feeds here
        // first thing we need is a priceFeedAddress and need to map each token to its price feed
        address priceFeedAddress = tokenPriceFeedMapping[_token];
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            priceFeedAddress
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 decimals = uint256(priceFeed.decimals());
        return (uint256(price), decimals);
    }

    // stake token function; want an amount of token to stake and stake a certain address of the token
    // so basically just some amount of some token
    function stakeTokens(uint256 _amount, address _token) public {
        // things to keep in mind: what tokens can they stake? How much can they stake?
        // we're just gonna say you can stake any amount above zero
        // notice that because we are using solidity ^0.8.0 we do not have to worry about safemath
        require(_amount > 0, "Amount must be more than zero!");
        // need to choose the specific kinds of tokens to have staked; so we'll make a function for that called tokenIsAllowed, and require it below
        require(tokenIsAllowed(_token), "Token is currently not allowed!");
        // now we have to call the transferFrom function from the ERC20 to move the ERC20 tokens around - we need the abi, so grab the interface from openzeppelin
        // wrap the _token in the IERC20 to get the abi via the interface (IERC20) and the address, then call transferFrom from the msg.sender and send it to this contract, and send the _amount
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        // saying that staking balance of this token, from the msg.sender is equal whatever balance they had before plus the amount they just staked
        updateUniqueTokensStaked(msg.sender, _token);
        stakingBalance[_token][msg.sender] =
            stakingBalance[_token][msg.sender] +
            _amount;
        // add stakers to the list; only add if they're not already there; to do this, should know how many unique tokens the user actually has. So make function called updateUniqueTokensStaked
        if (uniqueTokensStaked[msg.sender] == 1) {
            stakers.push(msg.sender);
        }
    }

    function unStakeTokens(address _token) public {
        // first thing we want to do is see how much of the token does the user have
        uint256 balance = stakingBalance[_token][msg.sender];
        require(balance > 0, "Staking balance cannot be zero!");
        // transfer the token
        IERC20(_token).transfer(msg.sender, balance);
        // after transfer happens, update the balance of the token to 0
        stakingBalance[_token][msg.sender] = 0;
        uniqueTokensStaked[msg.sender] = uniqueTokensStaked[msg.sender] - 1;
        // update the stakers list array to remove this person if they no longer have anything staked
    }

    function withdraw(address _token) public onlyOwner {
        IERC20(_token).transfer(msg.sender, address(this).balance);
    }

    // making this function internal so only this contract can call it
    function updateUniqueTokensStaked(address _user, address _token) internal {
        if (stakingBalance[_token][_user] <= 0) {
            uniqueTokensStaked[_user] = uniqueTokensStaked[_user] + 1;
        }
    }

    // create a function to add allowed tokens take only you, the contract owner, can call
    function addAllowedTokens(address _token) public onlyOwner {
        allowedTokens.push(_token);
    }

    function tokenIsAllowed(address _token) public view returns (bool) {
        // make a list of the tokens that are allowed above as an address array
        // going to want to loop to the address array so this function can see which tokens are allowed; thus use a for loop
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