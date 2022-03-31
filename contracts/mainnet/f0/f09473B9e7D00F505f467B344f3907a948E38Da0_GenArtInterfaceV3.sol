// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./GenArtAccess.sol";
import "./IGenArtMembership.sol";
import "./IGenArtERC721V2.sol";
import "./IGenArtInterfaceV3.sol";

/**
 * Interface to the GEN.ART Membership and Governance Token Contracts
 */

contract GenArtInterfaceV3 is GenArtAccess, IGenArtInterfaceV3 {
    IGenArtMembership private _genArtMembership;

    constructor(address genArtMembershipAddress_) {
        _genArtMembership = IGenArtMembership(genArtMembershipAddress_);
    }

    function isGoldToken(uint256 _membershipId)
        public
        view
        override
        returns (bool)
    {
        return _genArtMembership.isGoldToken(_membershipId);
    }

    function getMembershipsOf(address account)
        public
        view
        override
        returns (uint256[] memory)
    {
        return _genArtMembership.getTokensByOwner(account);
    }

    function ownerOfMembership(uint256 _membershipId)
        public
        view
        override
        returns (address)
    {
        return _genArtMembership.ownerOf(_membershipId);
    }

    /**
     *@dev Get available mints for an account
     */
    function getAvailableMintsForAccount(address collection, address account)
        public
        view
        override
        returns (uint256)
    {
        uint256[] memory memberships = getMembershipsOf(account);
        uint256 availableMints;
        for (uint256 i; i < memberships.length; i++) {
            availableMints += IGenArtERC721V2(collection)
                .getAvailableMintsForMembership(memberships[i]);
        }
        return availableMints;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev This implements access control for owner and admins
 */
abstract contract GenArtAccess is Ownable {
    mapping(address => bool) public admins;
    address public genartAdmin;

    constructor() Ownable() {
        genartAdmin = _msgSender();
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyAdmin() {
        address sender = _msgSender();
        require(
            owner() == sender || admins[sender],
            "GenArtAccess: caller is not the owner nor admin"
        );
        _;
    }

    /**
     * @dev Throws if called by any account other than the GEN.ART admin.
     */
    modifier onlyGenArtAdmin() {
        address sender = _msgSender();
        require(
            genartAdmin == sender,
            "GenArtAccess: caller is not genart admin"
        );
        _;
    }

    function setGenArtAdmin(address admin) public onlyGenArtAdmin {
        genartAdmin = admin;
    }

    function setAdminAccess(address admin, bool access) public onlyGenArtAdmin {
        admins[admin] = access;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGenArtMembership {
    function getTokensByOwner(address owner)
        external
        view
        returns (uint256[] memory);

    function ownerOf(uint256 tokenId) external view returns (address);

    function isGoldToken(uint256 _tokenId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGenArtERC721V2 {
    function getAvailableMintsForMembership(uint256 membershipId)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGenArtInterfaceV3 {
    function isGoldToken(uint256 _membershipId) external view returns (bool);

    function getAvailableMintsForAccount(address collection, address account)
        external
        view
        returns (uint256);

    function getMembershipsOf(address account)
        external
        view
        returns (uint256[] memory);

    function ownerOfMembership(uint256 _membershipId) external view returns (address);
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