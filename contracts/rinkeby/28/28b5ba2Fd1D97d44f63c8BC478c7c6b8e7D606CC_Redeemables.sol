// contracts/BoosterEnabledToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract Redeemables is  Ownable {
    //variables
    address public parent;
    uint256 totalItems;
    // ERC115
    //modifiers
    modifier onlyParentContact() {
        _;
        require(
            msg.sender == parent || msg.sender == owner(),
            "Only parent contract can call this (Minter.sol)."
        );
    }

    // structs
    struct ValidContractsItemsIn {
        uint256[] validItemsIDs;
        uint256[] validItemTypes;
        uint256[] redeemedItems;
    }

    struct RededeemableItemType {
        uint256 collectionID;
        uint256 amountTimesRedeemed;
        bool enabled;
        string name;
        string uri;
    }

    //mappings.
    //check project contract address, to see if it has any valid NFT's
    mapping(address => ValidContractsItemsIn) projects;
    mapping(uint256 => RededeemableItemType) validItems;

    function isValidItem(uint256 itemID, address contractAddress)
        public
        view
        returns (
            string memory itemName,
            string memory itemURI,
            bool enabled,
            uint256 amountTimesRedeemed
        )
    {
        ValidContractsItemsIn memory validItemsIn = projects[contractAddress];

        if (validItemsIn.validItemsIDs.length == 0) {
            revert("invalid Redeemable item ID");
        }
        for (uint256 i = 0; i < validItemsIn.validItemsIDs.length; i++) {
            if (validItemsIn.validItemsIDs[i] == itemID) {
                RededeemableItemType memory itemType = validItems[
                    validItemsIn.validItemTypes[i]
                ];
                return (
                    itemType.name,
                    itemType.uri,
                    itemType.enabled,
                    itemType.amountTimesRedeemed
                );
            }
        }
    }

    function getRedeemableItem(uint256 itemsID)
        public
        view
        returns (RededeemableItemType memory)
    {
        return validItems[itemsID];
    }

    //insert/invalidates/updates redeemable items
    function editRedeemableItem(
        uint256[] calldata items,
        string[] calldata names,
        string calldata uri,
        bool enabled
    ) public onlyOwner {
        //add to the project
        //add to the token
        for (uint256 index = 0; index < items.length; index++) {
            uint256 itemID = items[index];
            RededeemableItemType storage item = validItems[itemID];
            // validItems[itemID] = RededeemableItemType(
            //     itemID,
            //     0,
            //     enabled,
            //     names[itemID],
            //     uri
            // );
            item.name = names[index];
            item.uri = uri;
            item.enabled = enabled;
            validItems[itemID] = item;
        }
    }

    constructor(address parentAddress)
    {
        parent = parentAddress;
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