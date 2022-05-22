// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IERC20.sol";
import "Ownable.sol";
import "AggregatorV3Interface.sol";

contract FarmToTheMoon is Ownable {
    struct StakerStruct {
        uint256 index;
        uint256 uniqueStakedTokenCound;
        mapping(address => uint256) stakedBalance;
    }

    string public name = "Improved MOON Farm";
    IERC20 public szatkToken;

    mapping(address => address) public tokenPriceFeedMapping;
    address[] public allovedTokens;

    mapping(address => StakerStruct) public stakerStruct; //privat
    address[] public stakerIndex; //privat

    event LogNewStaker(
        address indexed stakerAddress,
        uint256 index,
        uint256 uniqueTokenCount
    );
    event LogUpdateStaker(
        address indexed stakerAddress,
        uint256 index,
        uint256 uniqueTokenCount
    );
    event LogDeleteStaker(address indexed stakerAddress, uint256 index);

    constructor(address _szatk) public {
        szatkToken = IERC20(_szatk);
    }

    function isUser(address stakerAddress) public view returns (bool isIndeed) {
        if (stakerIndex.length == 0) return false;
        return (stakerIndex[stakerStruct[stakerAddress].index] ==
            stakerAddress);
    }

    function stake(uint256 _amount, address _token)
        public
        returns (uint256 index)
    {
        require(_amount > 0, "Amount can't be 0.");
        require(tokenIsAlloved(_token), "Token isn't alloved by admin.");

        if (stakerStruct[msg.sender].stakedBalance[_token] == 0) {
            stakerStruct[msg.sender].uniqueStakedTokenCound =
                stakerStruct[msg.sender].uniqueStakedTokenCound +
                1;
        }
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        stakerStruct[msg.sender].stakedBalance[_token] =
            stakerStruct[msg.sender].stakedBalance[_token] +
            _amount;

        if (!isUser(msg.sender)) {
            stakerIndex.push(msg.sender);
            stakerStruct[msg.sender].index = stakerIndex.length - 1;
        }

        emit LogNewStaker(
            msg.sender,
            stakerStruct[msg.sender].index,
            stakerStruct[msg.sender].uniqueStakedTokenCound
        );

        return stakerIndex.length - 1;
    }

    function unstake2(address _token) public {
        uint256 balance = stakerStruct[msg.sender].stakedBalance[_token];
        require(balance > 0, "Your staked balance isn't enough.");

        IERC20(_token).transfer(msg.sender, balance);
        stakerStruct[msg.sender].stakedBalance[_token] = 0;
        stakerStruct[msg.sender].uniqueStakedTokenCound =
            stakerStruct[msg.sender].uniqueStakedTokenCound -
            1;

        if (stakerStruct[msg.sender].uniqueStakedTokenCound == 0) {
            deleteStaker(msg.sender);
        }
    }

    function unstake(address _token) public {
        uint256 balance = stakerStruct[msg.sender].stakedBalance[_token];
        require(balance > 0, "Your staked balance isn't enough.");

        IERC20(_token).transfer(msg.sender, balance);
        stakerStruct[msg.sender].stakedBalance[_token] = 0;
        stakerStruct[msg.sender].uniqueStakedTokenCound =
            stakerStruct[msg.sender].uniqueStakedTokenCound -
            1;

        if (stakerStruct[msg.sender].uniqueStakedTokenCound == 0) {
            deleteStaker(msg.sender);
        }
    }

    function deleteStaker(address stakerAddress)
        private
        returns (uint256 index)
    {
        require(!isUser(stakerAddress), "Staker doesn't exist.");

        uint256 rowToDelete = stakerStruct[stakerAddress].index;
        address keyToMove = stakerIndex[stakerIndex.length - 1];

        stakerIndex[rowToDelete] = keyToMove;
        stakerStruct[keyToMove].index = rowToDelete;
        delete stakerIndex[rowToDelete];
        emit LogDeleteStaker(stakerAddress, rowToDelete);
        emit LogUpdateStaker(
            keyToMove,
            rowToDelete,
            stakerStruct[keyToMove].uniqueStakedTokenCound
        );
        return rowToDelete;
    }

    function getStaker(address staker)
        public
        view
        returns (uint256 index, uint256 uniqueStakedTokenCound)
    {
        // require(!isUser(staker), "Staker doesn't exist.");
        return (
            stakerStruct[staker].index,
            stakerStruct[staker].uniqueStakedTokenCound
        );
    }

    function getStakerTokens(address staker, address _token)
        public
        view
        returns (address token, uint256 balance)
    {
        // require(!isUser(staker), "Staker doesn't exist.");
        return (_token, stakerStruct[staker].stakedBalance[_token]);
    }

    function getStakerCount() public view returns (uint256 count) {
        return stakerIndex.length;
    }

    function getUserAtIndex(uint256 index)
        public
        view
        returns (address userAddress)
    {
        return stakerIndex[index];
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