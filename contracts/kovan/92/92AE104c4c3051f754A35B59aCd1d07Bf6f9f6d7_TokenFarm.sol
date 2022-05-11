// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IERC20.sol";
import "Ownable.sol";
import "AggregatorV3Interface.sol";

contract TokenFarm is Ownable {
    string public name = "SZATK Token Farm";
    IERC20 public szatkToken;

    //should be dynamicaly updated
    mapping(address => address) public tokenPriceFeedMapping;
    mapping(address => uint256) public userUniqueTokenStakedMapping;
    mapping(address => mapping(address => uint256)) public stakedBalance;

    //check before stake?
    address[] public allovedTokens;
    address[] public stakers;

    // stakeTokens +
    // unStakeTokens -
    // issueTokens +
    // addAllowedTokens +
    // getValue +
    // 100 ETH 1:1 for every 1 ETH, we give 1 DappToken
    // 50 ETH and 50 DAI staked, and we want to give a reward of 1 DAPP / 1 DAI

    constructor(address _szatk) public {
        szatkToken = IERC20(_szatk);
    }

    function addAllovedTokens(address _token) public onlyOwner {
        allovedTokens.push(_token);
    }

    function setPriceFeedAddress(address _token, address _price_feed)
        public
        onlyOwner
    {
        tokenPriceFeedMapping[_token] = _price_feed;
    }

    // iterate over stakers+
    // get user tokens total value
    // send rewards+
    function sendRewards() public onlyOwner {
        for (uint256 i = 0; i < stakers.length; i++) {
            address reciever = stakers[i];
            uint256 value = getUserTotalValue(reciever);
            szatkToken.transfer(reciever, value);
        }
    }

    // get users total value in usd
    // get value in token
    // convert to usd
    // sumup and return
    function getUserTotalValue(address _reciever)
        internal
        view
        returns (uint256)
    {
        // check if user staked anything
        uint256 totalValue = 0;
        for (uint256 i = 0; i < allovedTokens.length; i++) {
            totalValue =
                totalValue +
                getTotalTokenValue(allovedTokens[i], _reciever);
        }
        return totalValue;
    }

    // get token, user, amount
    // convert to usd
    // return
    function getTotalTokenValue(address _token, address _reciever)
        internal
        view
        returns (uint256)
    {
        if (userUniqueTokenStakedMapping[_reciever] <= 0) {
            return 0;
        }
        (uint256 price, uint256 decimals) = getTokenPriceData(_token);
        // 10000000000000000000 ETH
        // ETH/USD -> 10000000000
        // 10 * 100 = 1,000
        return ((stakedBalance[_token][_reciever] * price) / (10**decimals));
    }

    function getTokenPriceData(address _token)
        public
        view
        returns (uint256, uint256)
    {
        AggregatorV3Interface price_feed = AggregatorV3Interface(
            tokenPriceFeedMapping[_token]
        );
        (, int256 price, , , ) = price_feed.latestRoundData();
        uint256 priceDecimals = price_feed.decimals();

        return (uint256(price), uint256(priceDecimals));
    }

    function stake(uint256 _amount, address _token) public {
        require(_amount > 0, "Amount can't be 0.");
        require(tokenIsAlloved(_token), "Token isn't alloved by admin.");

        increseUniqueStakedTokens(_token);
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        stakedBalance[_token][msg.sender] =
            stakedBalance[_token][msg.sender] +
            _amount;
        updateStakersList();
    }

    function unstake(address _token) public {
        uint256 balance = stakedBalance[_token][msg.sender];
        require(balance > 0, "Your staked balance isn't enough.");

        IERC20(_token).transfer(msg.sender, balance);

        decrementUserUniqueTokenStakedMapping(_token);
        stakedBalance[_token][msg.sender] = 0;
        checkStakers();
    }

    function checkStakers() internal {
        if (userUniqueTokenStakedMapping[msg.sender] == 0) {
            for (
                uint256 stakersIndex = 0;
                stakersIndex < stakers.length;
                stakersIndex++
            ) {
                if (stakers[stakersIndex] == msg.sender) {
                    stakers[stakersIndex] = stakers[stakers.length - 1];
                    stakers.pop();
                }
            }
        }
    }

    function decrementUserUniqueTokenStakedMapping(address _token) internal {
        if (stakedBalance[_token][msg.sender] == 0) {
            userUniqueTokenStakedMapping[msg.sender] =
                userUniqueTokenStakedMapping[msg.sender] -
                1;
        }
    }

    function updateStakersList() internal {
        if (userUniqueTokenStakedMapping[msg.sender] > 0) {
            stakers.push(msg.sender);
        }
    }

    function increseUniqueStakedTokens(address _token) internal {
        if (stakedBalance[_token][msg.sender] <= 0) {
            userUniqueTokenStakedMapping[msg.sender] =
                userUniqueTokenStakedMapping[msg.sender] +
                1;
        }
    }

    function tokenIsAlloved(address _token) public view returns (bool) {
        for (uint256 i = 0; i < allovedTokens.length; i++) {
            if (allovedTokens[i] == _token) {
                return true;
            }
        }
        return false;
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

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