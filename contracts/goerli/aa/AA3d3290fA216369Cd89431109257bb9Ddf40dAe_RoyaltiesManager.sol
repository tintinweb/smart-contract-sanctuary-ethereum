// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "openzeppelin-solidity/contracts/access/Ownable.sol";

interface IERC2981 {
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (
        address receiver,
        uint256 royaltyAmount
    );
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

contract RoyaltiesManager is Ownable {
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    bool public ERC2981Support = true;

    struct Royalty {
        address receiver;
        uint256 feesPercentage;
    }

    mapping(address => Royalty) private royalties;
    mapping(address => bool) private blacklist;

    // RoyaltiesAddressSet event is emitted whenever `setRoyaltiesAddress` is executed succesfully.
    event RoyaltiesAddressSet(address collectionAddress, address receiver, uint256 feesPercentage);

    /// @dev Changes the 2918 support
    function toggleERC2981Support() external onlyOwner {
        ERC2981Support = !ERC2981Support;
    }

    /// @dev sets the collection's royalties address
    function setRoyaltiesAddress(
        address collectionAddress,
        address receiver,
        uint256 feesPercentage
    ) external onlyOwner {
        royalties[collectionAddress] = Royalty(
            receiver,
            feesPercentage
        );
        emit RoyaltiesAddressSet(collectionAddress, receiver, feesPercentage);
    }

    /// @dev gets the collection's royalties address abd fees
    /// @return receiver the address to transfer the fees to
    /// @return royaltyAmount the amount of fees to transfer
    function getRoyalties(address collectionAddress, uint256 tokenId, uint256 salePrice)
        external
        view
        returns (
            address receiver,
            uint256 royaltyAmount
        )
    {
        if (blacklist[collectionAddress]) {
            return (address(0), 0);
        }
        if (ERC2981Support) {
            bool success = IERC2981(collectionAddress).supportsInterface(_INTERFACE_ID_ERC2981);
            if (success) {
                return IERC2981(collectionAddress).royaltyInfo(tokenId, salePrice);
            }
        }
        Royalty memory royalty = royalties[collectionAddress];
        uint256 _royaltyAmount;
        if (royalty.receiver != address(0)) {
            _royaltyAmount = royalty.feesPercentage * salePrice / 100;
        }
        return (royalty.receiver, _royaltyAmount);
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