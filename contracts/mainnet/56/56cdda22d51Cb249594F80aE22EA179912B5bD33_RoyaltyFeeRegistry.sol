// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IOwnable} from "../interface/IOwnable.sol";

import {IRoyaltyFeeRegistry} from "./interface/IRoyaltyFeeRegistry.sol";

//  register royalty fee
contract RoyaltyFeeRegistry is IRoyaltyFeeRegistry, Ownable {
    struct FeeInfo {
        address setter;
        address receiver;
        uint256 fee;
    }
       // ERC721 interfaceID
    bytes4 public constant INTERFACE_ID_ERC721 = 0x80ac58cd;

    // ERC1155 interfaceID
    bytes4 public constant INTERFACE_ID_ERC1155 = 0xd9b67a26;

    // ERC2981 interfaceID
    bytes4 public constant INTERFACE_ID_ERC2981 = 0x2a55205a;

    // limit max royalty fee（10,000 = 100%）
    uint256 public royaltyFeeLimit;

    //compile royalty information mapping 
    mapping(address => FeeInfo) private _royaltyFeeInfoCollection;

    event NewRoyaltyFeeLimit(uint256 royaltyFeeLimit);
    event RoyaltyFeeUpdate(address indexed collection, address indexed setter, address indexed receiver, uint256 fee);

    //  initialize royalty fee
    constructor(uint256 _royaltyFeeLimit) {
        // no higher than the upper limit
        require(_royaltyFeeLimit <= 9500, "Royalty fee limit too high");
        royaltyFeeLimit = _royaltyFeeLimit;
    }

    // Update a collection's upper limit of royalty fee
    function updateRoyaltyFeeLimit(uint256 _royaltyFeeLimit) external override onlyOwner {
        // no higher than the upper limit
        require(_royaltyFeeLimit <= 9500, "Royalty fee limit too high");
        royaltyFeeLimit = _royaltyFeeLimit;

        emit NewRoyaltyFeeLimit(_royaltyFeeLimit);
    }

    function updateRoyaltyInfoForCollection(
        address collection,
        address setter,
        address receiver,
        uint256 fee
    ) internal{
        require(fee <= royaltyFeeLimit, "Registry: Royalty fee too high");

        _royaltyFeeInfoCollection[collection] = FeeInfo({setter: setter, receiver: receiver, fee: fee});

        emit RoyaltyFeeUpdate(collection, setter, receiver, fee);
    }

    //
    // function royaltyInfo
    //  @Description: calculate royalty fee
    //  @param address
    //  @param uint256
    //  @return external
    //
    function royaltyInfo(address collection, uint256 amount) external view override returns (address, uint256) {
        return (
        _royaltyFeeInfoCollection[collection].receiver,
        (amount * _royaltyFeeInfoCollection[collection].fee) / 10000
        );
    }
    /*Check collection information*/
    function royaltyFeeInfoCollection(address collection)
    external
    view
    override
    returns (
        address,
        address,
        uint256
    )
    {
        return (
        _royaltyFeeInfoCollection[collection].setter,
        _royaltyFeeInfoCollection[collection].receiver,
        _royaltyFeeInfoCollection[collection].fee
        );
    }


   function updateRoyaltyInfoForCollectionIfSetter(
        address collection,
        address setter,
        address receiver,
        uint256 fee
    ) external {
        address currentSetter = _royaltyFeeInfoCollection[collection].setter;
        require(msg.sender == currentSetter, "Setter: Not the setter");

        updateRoyaltyInfoForCollection(collection, setter, receiver, fee);
    }


        //
    // function checkForCollectionSetter
    //  @Description: Confirm royalty fee seeting information
    //  @param address
    //  @return external Return editor, regarless of admin or owner
    //
    function checkForCollectionSetter(address collection) external view returns (address, uint8) {
        address currentSetter = _royaltyFeeInfoCollection[collection].setter;
        if (currentSetter != address(0)){
            return (currentSetter,0);
        }
        try IERC165(collection).supportsInterface(INTERFACE_ID_ERC2981) returns (bool interfaceSupport) {
            if (interfaceSupport) {
                return (address(0), 1);
            }
        } catch {}

        try IOwnable(collection).owner() returns (address setter) {
            return (setter, 2);
        } catch {
            try IOwnable(collection).admin() returns (address setter) {
                return (setter, 3);
            } catch {
                return (address(0), 4);
            }
        }
    }

    //
    // function updateRoyaltyInfoForCollectionIfAdmin
    //  @Description: Update royalty info if this is the admin of the collection
    //  @param address collection address
    //  @param address  Editor address
    //  @param address  Wallet address receiving royalty fee
    //  @param uint256 royalty fee 500=5%
    //  @return external
    //
    function updateRoyaltyInfoForCollectionIfAdmin(
        address collection,
        address setter,
        address receiver,
        uint256 fee
    ) external {
        //https://eips.ethereum.org/EIPS/eip-2981
        require(!IERC165(collection).supportsInterface(INTERFACE_ID_ERC2981), " Must not be ERC2981");
        require(msg.sender == IOwnable(collection).admin(), " Not the admin");

        _updateRoyaltyInfoForCollectionIfOwnerOrAdmin(collection, setter, receiver, fee);
    }

    //
    // tion updateRoyaltyInfoForCollectionIfOwner
    //  @Description: Update royalty info if this is the owner of the collection
    //  @param address
    //  @param address
    //  @param address
    //  @param uint256
    //  @return external
    //
    function updateRoyaltyInfoForCollectionIfOwner(
        address collection,
        address setter,
        address receiver,
        uint256 fee
    ) external {
        require(!IERC165(collection).supportsInterface(INTERFACE_ID_ERC2981), " Must not be ERC2981");
        require(msg.sender == IOwnable(collection).owner(), " Not the owner");

        _updateRoyaltyInfoForCollectionIfOwnerOrAdmin(collection, setter, receiver, fee);
    }

    //
    // function _updateRoyaltyInfoForCollectionIfOwnerOrAdmin
    //  @Description: Update royalty fee information
    //  @param address
    //  @param address
    //  @param address
    //  @param uint256
    //  @return internal
    //
    function _updateRoyaltyInfoForCollectionIfOwnerOrAdmin(
        address collection,
        address setter,
        address receiver,
        uint256 fee
    ) internal {
        address currentSetter = _royaltyFeeInfoCollection[collection].setter;
        require(currentSetter == address(0), "Already set");

        require(
            (IERC165(collection).supportsInterface(INTERFACE_ID_ERC721) ||
        IERC165(collection).supportsInterface(INTERFACE_ID_ERC1155)),
            " Not Set of ERC721/ERC1155"
        );

        updateRoyaltyInfoForCollection(collection, setter, receiver, fee);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IRoyaltyFeeRegistry {
  
    function updateRoyaltyFeeLimit(uint256 _royaltyFeeLimit) external;

    function royaltyInfo(address collection, uint256 amount) external view returns (address, uint256);

    function royaltyFeeInfoCollection(address collection)
        external
        view
        returns (
            address,
            address,
            uint256
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IOwnable {
    function transferOwnership(address newOwner) external;

    function owner() external view returns (address);

    function admin() external view returns (address);
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