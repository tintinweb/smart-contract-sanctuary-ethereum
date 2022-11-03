// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

library Errors {
    error DataEmpty(); // data empty
    error AssetAdded(); // asset added
    error VaultPaused(); // vault paused
    error InvalidAsset(); // invalid asset
    error InvalidAmount(); // invalid amount
    error InvalidCaller(); // invalid caller
    error WithdrawFailed(); // withdraw failed
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "../interfaces/IVault.sol";
import "../interfaces/IWToken.sol";
import {Errors} from "./Errors.sol";
import "openzeppelin/access/Ownable.sol";
import "../interfaces/IWTokenGateway.sol";

contract WTokenGateway is Ownable, IWTokenGateway {
    IVault internal immutable VAULT;
    IWToken internal immutable WTOKEN;

    constructor(address wtoken, address vault) {
        VAULT = IVault(vault);
        WTOKEN = IWToken(wtoken);

        // approve wtoken
        IWToken(wtoken).approve(vault, type(uint256).max);
    }

    /**
     * @dev deposit native token
     */
    function depositWToken(address pool) external payable override {
        WTOKEN.deposit{value: msg.value}();
        VAULT.deposit(pool, true, address(WTOKEN), msg.value);
    }

    /**
     * @dev withdraw naive token
     */
    function withdrawWToken(uint256 amount, address to) external override onlyOwner {
        VAULT.withdraw(address(WTOKEN), true, amount, address(this));
        WTOKEN.withdraw(amount);

        // (bool success,) = to.call{value: amount}(new bytes(0));
        // if (!success) {
        //     revert Errors.WithdrawFailed();
        // }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IVault {
    /**
     * @dev Emitted on deposit()
     */
    event Deposit(address indexed pool, address indexed asset, address indexed user, uint256 amount);

    /**
     * @dev Emitted on withdraw()
     */
    event Withdraw(address indexed asset, address indexed user, uint256 amount);

    /**
     * @dev Emitted when paused
     */
    event Paused();

    /**
     * @dev Emitted when unpaused
     */
    event UnPaused();

    /**
     * @dev
     */
    function deposit(address pool, bool wrap, address asset, uint256 amount) external;

    /**
     * @dev
     */
    function withdraw(address asset, bool wrap, uint256 amount, address to) external;

    /**
     * @dev
     */
    function addAsset(address asset) external;

    /**
     * @dev
     */
    function addAssets(address[] memory assets) external;

    function setPause(bool val) external;

    function paused() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IWToken {
    function deposit() external payable;

    function withdraw(uint256) external;

    function approve(address guy, uint256 wad) external returns (bool);

    function transferFrom(address src, address dst, uint256 wad) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IWTokenGateway {
    function depositWToken(address pool) external payable;

    function withdrawWToken(uint256 amount, address to) external;
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