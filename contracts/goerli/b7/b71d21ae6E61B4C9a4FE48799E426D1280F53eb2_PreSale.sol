// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "contracts/ERC20/interfaces/IERC20.sol";
import "contracts/utils/SafeTransfer.sol";

contract PreSale is Ownable, Pausable, ReentrancyGuard, SafeTransfer{
    struct PreSaleInfo {
        uint256 start;
        uint256 end;
        address tokenSale;
        uint256 totalTokenSale;
        uint256 totalTokenSold;
        uint256 rate;
        address tokenCommit;
    }

    struct UserInfo {
        uint256 amountCommitted;
        uint256 amountReceive;
        bool claimed;
    }
    bool private initialized;

    PreSaleInfo public presaleInfo;
    mapping(address => UserInfo) public userInfo;
    address public admin;

    event Committed(address sender, uint256 amount,uint256 amountReceive);
    event Claimed(address sender, uint256 amountReceive);

    modifier onlyAdmin() {
		require(msg.sender == admin, "PS: only admin");
		_;
	}

    function pause() public onlyAdmin {
		_pause();
	}

	function unpause() public onlyAdmin {
		_unpause();
	}

    function initPreSale(
        address _admin, 
        address _tokenSale,
        address _tokenCommit,
        uint256 _totalTokenSale,
        uint256 _start,
        uint256 _end,
        uint256 _rate
    ) public {
        require(!initialized,"PS: initialized");

        presaleInfo.start = _start;
        presaleInfo.end = _end;
        presaleInfo.tokenSale = _tokenSale;
        presaleInfo.totalTokenSale = _totalTokenSale;
        presaleInfo.rate = _rate;
        presaleInfo.tokenCommit = _tokenCommit;

        admin = _admin;
        initialized = true;
        _safeTransferFrom(_tokenSale, msg.sender, address(this), _totalTokenSale);
    }

    function changeAdmin(address newAdmin) public onlyAdmin {
        admin = newAdmin;
    }

    function committed(uint256 _amountCommit) public payable nonReentrant whenNotPaused {
        require(presaleOngoing(),"PS: presale not ongoing");

        uint256 amountReceive;
        uint256 tokenRemaining = presaleInfo.totalTokenSale - presaleInfo.totalTokenSold;
       
        if(presaleInfo.tokenCommit == ETH_ADDRESS)
        {
            require(msg.value > 0,'PS: insufficient ETH');
            amountReceive = calculateAmountReceive(msg.value);
            require(amountReceive <= tokenRemaining,"PS: insufficient token sale");
            presaleInfo.totalTokenSold += amountReceive; 

            userInfo[msg.sender].amountCommitted += msg.value;
            userInfo[msg.sender].amountReceive += amountReceive;
        }
        else {
            require(_amountCommit > 0,'PS: insufficient token');
            amountReceive = calculateAmountReceive(_amountCommit);
            require(amountReceive <= tokenRemaining,"PS: insufficient token sale");
            _safeTransferFrom(presaleInfo.tokenCommit, msg.sender,address(this), _amountCommit);
            presaleInfo.totalTokenSold += amountReceive; 

            userInfo[msg.sender].amountCommitted += _amountCommit;
            userInfo[msg.sender].amountReceive += amountReceive;
        }

        emit Committed(msg.sender, presaleInfo.tokenSale == ETH_ADDRESS ? msg.value : _amountCommit,amountReceive);
    }

    function claim() public nonReentrant whenNotPaused{
        require(!userInfo[msg.sender].claimed,"PS: sender claimed");
        require(userInfo[msg.sender].amountReceive > 0,"PS: sender not join");
        require(!presaleOngoing(),"PS: presale ongoing");

        _safeTransfer(presaleInfo.tokenSale,msg.sender,userInfo[msg.sender].amountReceive);
        userInfo[msg.sender].claimed = true;

        emit Claimed(msg.sender, userInfo[msg.sender].amountReceive);
    }

    function withdraw(address receiver,address token, uint256 amount) public onlyAdmin {
        safeTokenTransfer(token, payable(receiver), amount);
    }

    function calculateAmountReceive(uint256 _amount) public view returns(uint256 _amountReceive) {
        uint256 decimal = IERC20(presaleInfo.tokenSale).decimals();
        _amountReceive = (_amount * 10**decimal) / presaleInfo.rate;
    }

    function presaleOngoing() public view returns(bool) {
        return (
            (block.timestamp >= presaleInfo.start) &&
            (block.timestamp < presaleInfo.end)
        );
    } 

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SafeTransfer {
  address internal constant ETH_ADDRESS = 0x0000000000000000000000000000000000000000;

  function safeTokenTransfer(address _token, address payable _to, uint256 _amount) internal {
    if (address(_token) == ETH_ADDRESS) {
      _safeTransferETH(_to, _amount);
    } else {
      _safeTransfer(_token, _to, _amount);
    }
  }

  function tokenTransfer(address _token, address payable _to, uint256 _amount) internal {
    if (address(_token) == ETH_ADDRESS) {
      _to.transfer(_amount);
    } else {
      _safeTransfer(_token, _to, _amount);
    }
  }

  function safeApprove(address token, address to, uint256 amount) internal {
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, amount));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "ST: approve failed");
  }

  function _safeTransfer(address token, address to, uint256 amount) internal {
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, amount));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "ST: transfer failed");
  }

  function _safeTransferFrom(address token, address from, uint256 amount) internal {
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, address(this), amount));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "ST: transfer from failed");
  }

  function _safeTransferFrom(address token, address from, address to, uint256 amount) internal {
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, amount));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "ST: transfer from failed");
  }

  function _safeTransferETH(address to, uint256 value) internal {
    (bool success,) = to.call{value: value}("");
    require(success, "ST: eth transfer failed"); 
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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