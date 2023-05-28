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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IAsset {
    function claimMainOrERC20(
        address token,
        address to,
        uint256 amount
    ) external;

    function claimERC721(
        address token,
        address to,
        uint256 tokenId
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./../utils/Caller.sol";
import "./IConfig.sol";

contract Config is IConfig, Ownable {
    mapping(uint256 => address) private uint2562Address;

    // 用户资产托管合约，必须非0地址，非法要报错
    function getAsset() external view override returns (IAsset) {
        address address_ = uint2562Address[10005];
        require(address(0) != address_, "1142");
        return IAsset(address_);
    }

    function setAsset(address asset) external onlyOwner {
        require(address(0) != asset, "1143");
        uint2562Address[10005] = asset;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./../proxy/IApproveProxy.sol";
import "./../asset/IAsset.sol";

// 实现Config.sol
interface IConfig {
    // 资产托管地址，必须非0地址，非法要报错
    function getAsset() external view returns (IAsset);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// 用户授权
// 因为有的合约未实现销毁接口，故不在这里实现代理销毁
interface IApproveProxy {
    function transferFromERC20(
        address token,
        address from,
        address to,
        uint256 amount
    ) external;

    function transferFromERC721(
        address token,
        address from,
        address to,
        uint256 tokenId
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

// 调用者
contract Caller is Ownable {
    bool private init;
    mapping(address => bool) public caller;

    modifier onlyCaller() {
        require(caller[msg.sender], "1049");
        _;
    }

    function initOwner(address owner, address caller_) external {
        require(address(0) == Ownable.owner() && !init, "1102");
        init = true;
        _transferOwnership(owner);
        caller[caller_] = true;
    }

    function setCaller(address account, bool state) external onlyOwner {
        if (state) {
            caller[account] = state;
        } else {
            delete caller[account];
        }
    }
}