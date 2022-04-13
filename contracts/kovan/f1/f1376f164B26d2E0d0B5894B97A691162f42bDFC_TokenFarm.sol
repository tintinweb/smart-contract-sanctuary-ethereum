/**
 *Submitted for verification at Etherscan.io on 2022-04-13
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;



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

// Part: smartcontractkit/[email protected]/AggregatorV3Interface

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

// File: token_farm.sol

contract TokenFarm is Ownable {
    address[] public allowedToken;
    mapping(address => mapping(address => uint256)) public stakingBalance;
    address[] public stakers;
    mapping(address => uint256) public uniquetokenstake;
    mapping(address => address) public tokenToPricefeed;

    IERC20 public dapp_token;

    constructor(address dapp_token_address) public {
        dapp_token = IERC20(dapp_token_address);
    }

    function setPriceFeedcontract(address token, address priceFeed)
        public
        onlyOwner
    {
        tokenToPricefeed[token] = priceFeed;
    }

    function StakeToken(uint256 amount, address token) public {
        //what token is allowed to stake
        //how much to stake
        require(amount > 0, "Amount must be more than 0");
        //require(tokenIsAllowed(token), "Token is currently no allowed");
        //transferFrom -- anyone can call vs transfer -- only works if the wallet that calls this token owns the token for ERC20
        //needs abi
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        //see how many unique token the staker has
        updateUniqueTokens(msg.sender, token);
        stakingBalance[token][msg.sender] =
            stakingBalance[token][msg.sender] +
            amount;
        if (uniquetokenstake[msg.sender] == 1) {
            stakers.push(msg.sender);
        }
    }

    function unstakeToken(address token) public {
        uint256 balance = stakingBalance[token][msg.sender];
        require(balance > 0, "Staking balance cannot be 0");
        IERC20(token).transfer(msg.sender, balance);
        stakingBalance[token][msg.sender] = 0;
        uniquetokenstake[msg.sender] = uniquetokenstake[msg.sender] - 1;
        if (uniquetokenstake[msg.sender] == 0) {
            remove(msg.sender);
        }
    }

    function remove(address user) public {
        for (uint256 i = 0; i < stakers.length; i++) {
            if (user == stakers[i]) {
                stakers[i] = stakers[stakers.length - 1];
                stakers.pop();
            }
        }
    }

    function updateUniqueTokens(address user, address token) internal {
        if (stakingBalance[token][user] <= 0) {
            //see how many unique token type the user has staked
            uniquetokenstake[user] = uniquetokenstake[user] + 1;
        }
    }

    function issueToken() public onlyOwner {
        //reward for users that use our platform
        //this is based off the value that they have staked eg for every 1 eth they get 1dapp as a reward
        for (
            uint256 stakerIndex = 0;
            stakerIndex < stakers.length;
            stakerIndex++
        ) {
            address recipient = stakers[stakerIndex];
            //send them DAPP amount based on their total value of assets staked
            uint256 userTotalValue = getTotalValue(recipient);
            //transfer the absolute usd in dapp;  userTotalValue is derived in USD (eg. USD2000 is rewarded, so 2000 dapp is rewarded)
            dapp_token.transfer(recipient, userTotalValue);
        }
    }

    function getTotalValue(address user) public view returns (uint256) {
        require(uniquetokenstake[user] > 0, "No staked tokens");
        uint256 total_value = 0;
        for (
            uint256 allowedTokenIndex = 0;
            allowedTokenIndex < allowedToken.length;
            allowedTokenIndex++
        ) {
            address token_address = allowedToken[allowedTokenIndex];
            total_value =
                total_value +
                getSingleTokenValue(token_address, user);
        }
        return total_value;
    }

    function getSingleTokenValue(address token, address user)
        public
        view
        returns (uint256)
    {
        //get the usd equivelant of their total asset
        if (uniquetokenstake[user] <= 0) {
            return 0;
        } else {
            //price of token, and mulitple the staking balnce of user
            (uint256 price, uint256 decimals) = getTokenValue(token);
            return ((stakingBalance[token][user] * price) / (10**decimals));
        }
    }

    function getTokenValue(address token)
        public
        view
        returns (uint256, uint256)
    {
        //priceFeed address mapping
        address pricefeedaddress = tokenToPricefeed[token];
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            pricefeedaddress
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        //decimals() returns a uint8
        uint256 decimals = uint256(priceFeed.decimals());
        return (uint256(price), decimals);
    }

    function addAllowedtoken(address token) public onlyOwner {
        allowedToken.push(token);
    }

    function tokenIsAllowed(address token) public returns (bool) {
        for (
            uint256 allowedTokenIndex = 0;
            allowedTokenIndex < allowedToken.length;
            allowedTokenIndex++
        ) {
            if (allowedToken[allowedTokenIndex] == token) {
                return true;
            }
            return false;
        }
    }
}