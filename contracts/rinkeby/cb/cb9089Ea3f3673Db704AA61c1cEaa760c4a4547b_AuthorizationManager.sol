// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IAuthorizationManager, IAuthenticatedProxy} from "../interfaces/IAuthorizationManager.sol";

import {AuthenticatedProxy} from "./AuthenticatedProxy.sol";

contract AuthorizationManager is Ownable, IAuthorizationManager {
    mapping(address => address) public override proxies;
    address public immutable override authorizedAddress;
    address public immutable WETH;
    bool public override revoked;

    event Revoked();

    constructor(address _WETH, address _authorizedAddress) {
        WETH = _WETH;
        authorizedAddress = _authorizedAddress;
    }

    function revoke() external override onlyOwner {
        revoked = true;
        emit Revoked();
    }

    /**
     * Register a proxy contract with this registry
     *
     * @dev Must be called by the user which the proxy is for, creates a new AuthenticatedProxy
     * @return proxy New AuthenticatedProxy contract
     */
    function registerProxy() external override returns (address) {
        return _registerProxyFor(msg.sender);
    }

    function _registerProxyFor(address user) internal returns (address) {
        require(address(proxies[user]) == address(0), "Authorization: user already has a proxy");
        address proxy = address(new AuthenticatedProxy(user, address(this), WETH));
        proxies[user] = proxy;
        return proxy;
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
pragma solidity 0.8.9;

import {IAuthenticatedProxy} from "./IAuthenticatedProxy.sol";

interface IAuthorizationManager {
    function revoked() external returns (bool);

    function authorizedAddress() external returns (address);

    function proxies(address owner) external returns (address);

    function revoke() external;

    function registerProxy() external returns (address);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import {IAuthenticatedProxy} from "../interfaces/IAuthenticatedProxy.sol";
import {IAuthorizationManager} from "../interfaces/IAuthorizationManager.sol";
import {IWETH} from "../interfaces/IWETH.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AuthenticatedProxy is IAuthenticatedProxy {
    address public immutable owner;
    IAuthorizationManager public immutable authorizationManager;
    address public immutable WETH;
    bool public revoked;

    event Revoked(bool revoked);

    modifier onlyOwnerOrAuthed() {
        require(
            msg.sender == owner ||
                (!revoked && !authorizationManager.revoked() && msg.sender == authorizationManager.authorizedAddress()),
            "Proxy: permission denied"
        );
        _;
    }

    constructor(
        address _owner,
        address _authorizationManager,
        address _WETH
    ) {
        owner = _owner;
        authorizationManager = IAuthorizationManager(_authorizationManager);
        WETH = _WETH;
    }

    function setRevoke(bool revoke) external override {
        require(msg.sender == owner, "Proxy: permission denied");
        revoked = revoke;
        emit Revoked(revoke);
    }

    function safeTransfer(
        address token,
        address to,
        uint256 amount
    ) external override onlyOwnerOrAuthed {
        require(IERC20(token).transferFrom(owner, to, amount), "Proxy: transfer failed");
    }

    function withdrawETH() external override onlyOwnerOrAuthed {
        uint256 amount = IWETH(WETH).balanceOf(address(this));
        IWETH(WETH).withdraw(amount);
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Proxy: withdraw ETH failed");
    }

    function withdrawToken(address token) external override onlyOwnerOrAuthed {
        uint256 amount = IERC20(token).balanceOf(address(this));
        require(IERC20(token).transfer(owner, amount), "Proxy: withdraw token failed");
    }

    function delegatecall(address dest, bytes memory data)
        external
        override
        onlyOwnerOrAuthed
        returns (bool success, bytes memory returndata)
    {
        (success, returndata) = dest.delegatecall(data);
    }

    receive() external payable {
        require(msg.sender == address(WETH), "Receive not allowed");
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
pragma solidity 0.8.9;

interface IAuthenticatedProxy {
    function setRevoke(bool revoke) external;

    function safeTransfer(
        address token,
        address to,
        uint256 amount
    ) external;

    function withdrawETH() external;

    function withdrawToken(address token) external;

    function delegatecall(address dest, bytes memory data) external returns (bool, bytes memory);
}

// SPDX-License-Identifier: GNU
pragma solidity 0.8.9;

interface IWETH {
    function balanceOf(address) external view returns (uint256);

    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
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