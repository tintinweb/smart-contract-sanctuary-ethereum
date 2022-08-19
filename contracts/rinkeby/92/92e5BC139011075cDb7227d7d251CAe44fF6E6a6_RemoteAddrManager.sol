// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import {IRemoteAddrManager} from "../interfaces/IRemoteAddrManager.sol";

/**
 * @title TransferSelectorNFT
 * @notice It selects the NFT transfer manager based on a collection address.
 */
contract RemoteAddrManager is IRemoteAddrManager, Ownable {
    // Map (remoteAddr => remoteChainId => srcAddr) : srcAddr/srcChain <=> remoteAddr/currentChain
    mapping(address => mapping(uint16 => address)) public remoteAddresses;

    event RemoteAddressAdded(address indexed remoteAddr, uint16 indexed remoteChainId, address srcAddr);
    event RemoteAddressRemoved(address indexed remoteAddr, uint16 indexed remoteChainid);

    function addRemoteAddress(address remoteAddr, uint16 remoteChainId, address srcAddr) external onlyOwner {
        require(srcAddr != address(0), "Owner: source cannot be null address");
        require(remoteAddr != address(0), "Owner: remote cannot be null address");

        remoteAddresses[remoteAddr][remoteChainId] = srcAddr;

        emit RemoteAddressAdded(remoteAddr, remoteChainId, srcAddr);
    }

    function removeRemoteAddress(address remoteAddr, uint16 remoteChainId) external onlyOwner {
        require(remoteAddresses[remoteAddr][remoteChainId] != address(0), "Owner: no remote address");

        remoteAddresses[remoteAddr][remoteChainId] = address(0);

        emit RemoteAddressRemoved(remoteAddr, remoteChainId);
    }

    /**
     * @notice Check if remoteAddress was added
     * @param remoteAddress remote contract address
     * @param remoteAddress remote chain id
     */
    function checkRemoteAddress(address remoteAddress, uint16 remoteChainId) external view override returns (address) {
        if (remoteChainId == uint16(block.chainid)) {
            return remoteAddress;
        }

        address srcAddr = remoteAddresses[remoteAddress][remoteChainId];
        if (srcAddr == address(0)) {
            return remoteAddress;
        }

        return srcAddr;
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
pragma solidity ^0.8.0;

interface IRemoteAddrManager {
    function checkRemoteAddress(address remoteAddress, uint16 remoteChainId) external view returns (address);
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