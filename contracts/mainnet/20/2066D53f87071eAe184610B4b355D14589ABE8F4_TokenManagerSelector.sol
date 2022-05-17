// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./interfaces/ITokenManagerSelector.sol";

contract TokenManagerSelector is ITokenManagerSelector, Ownable {
    bytes4 public constant INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 public constant INTERFACE_ID_ERC1155 = 0xd9b67a26;

    address public immutable TOKEN_MANAGER_ERC721;
    address public immutable TOKEN_MANAGER_ERC1155;

    mapping(address => address) public tokenManagerSelectorForTokenAddress;

    event TokenManagerSet(address indexed tokenAddress, address indexed tokenManager);
    event TokenManagerRemoved(address indexed tokenAddress);

    constructor(address tokenManagerERC721, address tokenManagerERC1155) {
        TOKEN_MANAGER_ERC721 = tokenManagerERC721;
        TOKEN_MANAGER_ERC1155 = tokenManagerERC1155;
    }

    function setTokenManager(address tokenAddress, address tokenManager) external onlyOwner {
        require(tokenAddress != address(0), "TokenManagerSelector: tokenAddress cannot be null address");
        require(tokenManager != address(0), "TokenManagerSelector: tokenManager cannot be null address");

        tokenManagerSelectorForTokenAddress[tokenAddress] = tokenManager;

        emit TokenManagerSet(tokenAddress, tokenManager);
    }

    function removeTokenManager(address tokenAddress) external onlyOwner {
        require(
            tokenManagerSelectorForTokenAddress[tokenAddress] != address(0),
            "TokenManagerSelector: tokenAddress has no token manager"
        );

        tokenManagerSelectorForTokenAddress[tokenAddress] = address(0);

        emit TokenManagerRemoved(tokenAddress);
    }

    function getManagerAddress(address tokenAddress) external view returns (address) {
        address transferManager = tokenManagerSelectorForTokenAddress[tokenAddress];

        if (transferManager == address(0)) {
            if (IERC165(tokenAddress).supportsInterface(INTERFACE_ID_ERC721)) {
                transferManager = TOKEN_MANAGER_ERC721;
            } else if (IERC165(tokenAddress).supportsInterface(INTERFACE_ID_ERC1155)) {
                transferManager = TOKEN_MANAGER_ERC1155;
            }
        }

        return transferManager;
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface ITokenManagerSelector {
    function getManagerAddress(address tokenAddress) external view returns (address);
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