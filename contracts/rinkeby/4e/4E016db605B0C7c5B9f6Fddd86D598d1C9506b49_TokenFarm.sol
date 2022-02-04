// stakeTokens
// unStakeTokens
// issueTokens
// addAllowed Tokens
// getEthValue

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "Ownable.sol";
import "IERC20.sol";
import "AggregatorV3Interface.sol";



contract TokenFarm is Ownable {
        //"How much of each token each staker has staked. :  mapping token address -> staker addr -> amount
    mapping(address => mapping(address => uint256)) public stakingBalance;
    mapping(address => uint256) public uniqTokensStaked;
    mapping(address => address) public tokentoPricefeed;

    address[] public stakers;
    address[] public allowedTokens;
    IERC20 public dappToken;

// 100 ETH 1:1 FOR EVERY 1 ETH, we give 1 DappToken
// 50 ETH and 50 DAI staked, and we want to give a reward of 1 DAPP per 1 DAI

    constructor(address _dappTokenAddr) {
        dappToken = IERC20(_dappTokenAddr);
    }

    function setPricefeedContract(address _token, address _pricefeed ) public onlyOwner {
        tokentoPricefeed[_token] = _pricefeed;
    }

    function issueTokens() public onlyOwner{
        //Issue tokens to allowedTokens stakers
        for ( uint256 stakersIndex = 0; stakersIndex < stakers.length; stakersIndex++ ){
            address recipient = stakers[stakersIndex];
            uint256 userTotalValu = getUserTotalValu(recipient);
            // send them a token reward based on their total value locked
            dappToken.transfer(recipient, userTotalValu);

        }


    }


    function getUserTotalValu(address _user) public view returns (uint256){
        require(uniqTokensStaked[_user] > 0, "No tokens staked!");
        uint256 totalValue = 0;
        for (  uint256 allowedTokensIndex = 0; allowedTokensIndex < allowedTokens.length; allowedTokensIndex++ ){
            totalValue += getUserSingleTokenValu(_user, allowedTokens[allowedTokensIndex]);
        }
        return totalValue;
    }

    // if 1 ETH == $2000 then 2000
    // if 200 DAI == $200 then 200
    function getUserSingleTokenValu(address _user, address _token) public view returns(uint256) {
        if (uniqTokensStaked[_user] <= 0 ){ return 0;}
        // price of the token * stakingBalance[_token][_user]
        (uint256 price, uint256 decimals) =  getTokenValu(_token);
        return ( stakingBalance[_token][_user] * price / (10**decimals));

    }

    function getTokenValu(address _token) public view returns (uint256, uint256) {
        //priceFeedAddr
        address pricefeedAddr = tokentoPricefeed[_token];
        AggregatorV3Interface pricefeed = AggregatorV3Interface(pricefeedAddr);
        (, int256 price,,,) = pricefeed.latestRoundData();
        uint256 decimals = pricefeed.decimals();
        return(uint256(price), decimals);

    }

    function stakeTokens(uint256 _amount, address _token) public {
            //how much can they stake?
        require(_amount > 0, "Amount must be > 0");
            //what tokens can they stake?
        require(tokenIsAllowed(_token), "Token is not currently allowed");

        IERC20(_token).transferFrom(
            {sender : msg.sender,
             recipient : address (this),
             amount: _amount}
        );

        updateUniqTokensStaked(msg.sender, _token);
        stakingBalance[_token][msg.sender] += _amount;

        if (uniqTokensStaked[msg.sender] == 1 ){
            stakers.push(msg.sender);
        }

    }

    function unStakeTokens(address _token) public {
        uint256 balance = stakingBalance[_token][msg.sender];
        require(balance > 0, "Staking balance must be > 0!");
        IERC20(_token).transfer(msg.sender, balance );
        stakingBalance[_token][msg.sender] = 0 ;
        uniqTokensStaked[msg.sender]-- ;


    }

    function updateUniqTokensStaked(address _user, address _token) internal {
        if (stakingBalance[_token][_user] <= 0) {
            uniqTokensStaked[_user]++;
        }

    }

    function addAllowedTokens(address token) public onlyOwner {
        allowedTokens.push(token);
    }


    function tokenIsAllowed(address _token) public returns (bool){
        for (uint256 allowedTokensIndex=0; allowedTokensIndex < allowedTokens.length; allowedTokensIndex++)
            if (allowedTokens[allowedTokensIndex] == _token) { return true;}

            return false;


    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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