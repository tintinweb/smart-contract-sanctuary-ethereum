// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IAnonymiceBadgesData.sol";

contract AnonymiceBadgesData is Ownable {
    mapping(uint256 => IAnonymiceBadgesData.Badge) public badges;
    mapping(uint256 => string) public boardImages;
    string public badgePlaceholder;
    string public fontSource;

    function getBoardImage(uint256 boardId) external view returns (string memory) {
        return boardImages[boardId];
    }

    function getBadge(uint256 badgeId) external view returns (IAnonymiceBadgesData.Badge memory) {
        return badges[badgeId];
    }

    function getBadgeRaw(uint256 badgeId)
        external
        view
        returns (
            string memory,
            string memory,
            string memory
        )
    {
        IAnonymiceBadgesData.Badge memory badge = badges[badgeId];
        return (badge.image, badge.nameLine1, badge.nameLine2);
    }

    function getBadgePlaceholder() external view returns (string memory) {
        return badgePlaceholder;
    }

    function getFontSource() external view returns (string memory) {
        return fontSource;
    }

    function setBadgePlaceholder(string memory image) external onlyOwner {
        badgePlaceholder = image;
    }

    function setBoardImage(uint256 boardId, string memory image) external onlyOwner {
        boardImages[boardId] = image;
    }

    function setFontSource(string memory _fontSoruce) external onlyOwner {
        fontSource = _fontSoruce;
    }

    function setBadgeImage(
        uint256 badgeId,
        string memory image,
        string memory nameLine1,
        string memory nameLine2
    ) external onlyOwner {
        badges[badgeId] = IAnonymiceBadgesData.Badge({image: image, nameLine1: nameLine1, nameLine2: nameLine2});
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

pragma solidity ^0.8.7;

interface IAnonymiceBadgesData {
    struct Badge {
        string image;
        string nameLine1;
        string nameLine2;
    }

    function getBadgePlaceholder() external view returns (string memory);

    function getFontSource() external view returns (string memory);

    function getBoardImage(uint256 badgeId) external view returns (string memory);

    function getBadge(uint256 badgeId) external view returns (Badge memory);

    function getBadgeRaw(uint256 badgeId)
        external
        view
        returns (
            string memory,
            string memory,
            string memory
        );
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