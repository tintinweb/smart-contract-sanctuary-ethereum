// SPDX-License-Identifier: MIT

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "chainlink-brownie-contracts/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

pragma solidity ^0.8.0;

contract TokenFarm is Ownable {
    // token to user to balance
    mapping(address => mapping(address => uint256)) public stakingBalance;
    // how many unique tokens each address has staked
    mapping(address => uint256) public uniqueTokensStaked;
    address[] internal allowedTokens;
    address[] public stakers;

    IERC20 public dappToken;

    // enable getting value of tokens added later
    mapping(address => address) public tokenPriceFeedMapping;

    constructor(address _dappTokenAddr) payable {
        dappToken = IERC20(_dappTokenAddr);
    }

    function addAllowedToken(address _tokenAddr) external onlyOwner {
        allowedTokens.push(_tokenAddr);
    }

    function stakeTokens(address _tokenAddr, uint256 _amount) public {
        // what tokens can they stake
        // how much they can stake
        require(_amount > 0, "Amount must be greater than 0.");
        require(tokenIsAllowed(_tokenAddr), "Token not allowed.");

        // Assign ABI from interface
        IERC20(_tokenAddr).transferFrom(msg.sender, address(this), _amount);
        // if the user does not have enough balance it should throw (see EIP-20)
        // and i do not care, because it's the users problem

        // add to the stakers list if this is their first staked token (used when issuing DAPP tokens later)
        if (uniqueTokensStaked[msg.sender] == 0) {
            stakers.push(msg.sender);
        }

        updateUniqueTokensStaked(msg.sender, _tokenAddr);
        stakingBalance[_tokenAddr][msg.sender] += _amount;
    }

    function unstakeTokens(address _token) public {
        // Vulnerable to reentrancy attack?
        uint256 balance = stakingBalance[_token][msg.sender];
        require(balance > 0, "Staking balance cannot be 0.");
        IERC20(_token).transfer(msg.sender, balance);
        stakingBalance[_token][msg.sender] = 0;
        uniqueTokensStaked[msg.sender] -= 1;

        // remove the staker from the list of stakers if they
        // no longer have any tokens staked
        // Do not have to do this as the issuing function checks how
        // much tokens should be issued
    }

    function tokenIsAllowed(address _tokenAddr) public view returns (bool) {
        uint256 allowedTokensLen = allowedTokens.length;
        unchecked {
            for (uint256 i; i < allowedTokensLen; ++i) {
                if (allowedTokens[i] == _tokenAddr) {
                    return true;
                }
            }
        }
        return false;
    }

    function updateUniqueTokensStaked(address _user, address _token) internal {
        if (stakingBalance[_token][_user] == 0) {
            uniqueTokensStaked[_user] += 1;
        }
    }

    // 100 ETH staked, 1:1 ratio - for every 1 ETH, I give 1 DAPP
    // 50 ETH and 50 DAI staked, and want to give a reward of 1 DAPP / 1 DAI
    // for the latter, I need to convert ETH to DAI to calculate the amount

    /// @notice Issue tokens to all stakers
    function issueTokens() public onlyOwner {
        uint256 stakersLen = stakers.length;
        unchecked {
            for (uint256 i; i < stakersLen; ++i) {
                address recepient = stakers[i];
                // send them a reward based on
                // their total value locked
                uint256 userTotalValue = getUserTotalValue(recepient);
                dappToken.transfer(recepient, userTotalValue);
            }
        }
    }

    function getUserTotalValue(address _user) public view returns (uint256) {
        //require(uniqueTokensStaked[_user] > 0, "No tokens staked!");
        if (uniqueTokensStaked[_user] == 0) return 0;
        uint256 totalValue;
        uint256 allowedTokensLen = allowedTokens.length;
        for (uint256 i; i < allowedTokensLen; ++i) {
            totalValue += getUserSingleTokenValue(_user, allowedTokens[i]);
        }
        return totalValue;
    }

    function getUserSingleTokenValue(address _user, address _token)
        public
        view
        returns (uint256)
    {
        if (uniqueTokensStaked[_user] == 0) {
            return 0;
        }
        // price of the token * stakingBalance[_tokenAddr][user]
        (uint256 price, uint256 decimals) = getTokenValue(_token);
        return (stakingBalance[_token][_user] * price) / (10**decimals);
    }

    function getTokenValue(address _tokenAddr)
        public
        view
        returns (uint256 adjustedPrice, uint256 decimals)
    {
        address priceFeedAddr = tokenPriceFeedMapping[_tokenAddr];
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAddr);
        (, int256 price, , , ) = priceFeed.latestRoundData();
        adjustedPrice = uint256(price);
        decimals = uint256(priceFeed.decimals());
    }

    function setPriceFeedContract(address _tokenAddr, address _priceFeedAddr)
        public
        onlyOwner
    {
        tokenPriceFeedMapping[_tokenAddr] = _priceFeedAddr;
    }
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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