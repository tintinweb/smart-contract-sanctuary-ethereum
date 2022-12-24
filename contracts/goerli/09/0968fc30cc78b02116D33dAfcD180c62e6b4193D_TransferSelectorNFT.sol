// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "../../openzeppelin/contracts/Ownable.sol";
import {IERC165} from "../../openzeppelin/contracts/IERC165.sol";

import {ITransferSelectorNFT} from "./interfaces/ITransferSelectorNFT.sol";

/**
 * @title TransferSelectorNFT
 * @notice It selects the NFT transfer manager based on a collection address.
 */
contract TransferSelectorNFT is ITransferSelectorNFT, Ownable {
    // ERC721 interfaceID
    bytes4 public constant INTERFACE_ID_ERC721 = 0x80ac58cd;
    // ERC1155 interfaceID
    bytes4 public constant INTERFACE_ID_ERC1155 = 0xd9b67a26;

    // Address of the transfer manager contract for ERC721 tokens
    address public immutable TRANSFER_MANAGER_ERC721;

    // Address of the transfer manager contract for ERC1155 tokens
    address public immutable TRANSFER_MANAGER_ERC1155;

    // Map collection address to transfer manager address
    mapping(address => address) public transferManagerSelectorForCollection;

    event CollectionTransferManagerAdded(address indexed collection, address indexed transferManager);
    event CollectionTransferManagerRemoved(address indexed collection);

    /**
     * @notice Constructor
     * @param _transferManagerERC721 address of the ERC721 transfer manager
     * @param _transferManagerERC1155 address of the ERC1155 transfer manager
     */
    constructor(address _transferManagerERC721, address _transferManagerERC1155) {
        TRANSFER_MANAGER_ERC721 = _transferManagerERC721;
        TRANSFER_MANAGER_ERC1155 = _transferManagerERC1155;
    }

    /**
     * @notice Add a transfer manager for a collection
     * @param collection collection address to add specific transfer rule
     * @dev It is meant to be used for exceptions only (e.g., CryptoKitties)
     */
    function addCollectionTransferManager(address collection, address transferManager) external onlyOwner {
        require(collection != address(0), "Owner: Collection cannot be null address");
        require(transferManager != address(0), "Owner: TransferManager cannot be null address");

        transferManagerSelectorForCollection[collection] = transferManager;

        emit CollectionTransferManagerAdded(collection, transferManager);
    }

    /**
     * @notice Remove a transfer manager for a collection
     * @param collection collection address to remove exception
     */
    function removeCollectionTransferManager(address collection) external onlyOwner {
        require(
            transferManagerSelectorForCollection[collection] != address(0),
            "Owner: Collection has no transfer manager"
        );

        // Set it to the address(0)
        transferManagerSelectorForCollection[collection] = address(0);

        emit CollectionTransferManagerRemoved(collection);
    }

    /**
     * @notice Check the transfer manager for a token
     * @param collection collection address
     * @dev Support for ERC165 interface is checked AFTER custom implementation
     */
    function checkTransferManagerForToken(address collection) external view override returns (address transferManager) {
        // Assign transfer manager (if any)
        transferManager = transferManagerSelectorForCollection[collection];

        if (transferManager == address(0)) {
            if (IERC165(collection).supportsInterface(INTERFACE_ID_ERC721)) {
                transferManager = TRANSFER_MANAGER_ERC721;
            } else if (IERC165(collection).supportsInterface(INTERFACE_ID_ERC1155)) {
                transferManager = TRANSFER_MANAGER_ERC1155;
            }
        }

        return transferManager;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./Context.sol";

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

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

interface ITransferSelectorNFT {
    function checkTransferManagerForToken(address collection) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}