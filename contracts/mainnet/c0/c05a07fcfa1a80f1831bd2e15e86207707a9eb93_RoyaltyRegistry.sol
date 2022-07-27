/**
 *Submitted for verification at Etherscan.io on 2022-07-27
*/

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol

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

// File: @openzeppelin/contracts/interfaces/IERC2981.sol


// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: contracts/RoyaltyRegistry.sol


pragma solidity ^0.8.9;






interface IOwnable {
    function owner() external view returns (address);
    function admin() external view returns (address);
}
contract RoyaltyRegistry is Ownable, ReentrancyGuard {
    bytes4 public constant ERC2981_INTERFACE_ID = type(IERC2981).interfaceId;
    
    uint256 public royaltyFeeLimit;
    mapping(address => RoyaltyFee) private _collectionToRoyaltyFee;

    struct RoyaltyFee {
        address setter;
        address receiver;
        uint256 fee; // Stored in basis points. e.g. - 7.5% will be 7500 in basis points
    }

    event RoyaltyFeeChanged (address nftAddress, uint256 fee);
    event FeeLimitChanged ( uint256 newLimit );

    function updateRoyaltyFeeForCollection(
        address nftAddress,
        address setter,
        address receiver,
        uint256 fee
    ) external onlyOwner {
        require(!IERC165(nftAddress).supportsInterface(ERC2981_INTERFACE_ID), "NFT contract must not support ERC2981");
        require(fee <= royaltyFeeLimit, "Royalty fee is higher than the limit");
        _collectionToRoyaltyFee[nftAddress] = RoyaltyFee({setter: setter, receiver: receiver, fee: fee});

        emit RoyaltyFeeChanged(
            nftAddress,
            fee
        );
    }

    function updateRoyaltyFeeForCollectionIfOwner(
        address nftAddress,
        address owner,
        address receiver,
        uint256 fee
    ) external {
        require(!IERC165(nftAddress).supportsInterface(ERC2981_INTERFACE_ID), "NFT contract must not support ERC2981");
        require(msg.sender == IOwnable(nftAddress).owner(), "Not the NFT collection owner");
        require(fee <= royaltyFeeLimit, "Royalty fee is higher than the limit");
        _collectionToRoyaltyFee[nftAddress] = RoyaltyFee({setter: owner, receiver: receiver, fee: fee});

        emit RoyaltyFeeChanged(
            nftAddress,
            fee
        );
    }

    function updateRoyaltyFeeForCollectionIfAdmin(
        address nftAddress,
        address admin,
        address receiver,
        uint256 fee
    ) external {
        require(!IERC165(nftAddress).supportsInterface(ERC2981_INTERFACE_ID), "NFT contract must not support ERC2981");
        require(msg.sender == IOwnable(nftAddress).admin(), "Not the NFT collection admin");
        require(fee <= royaltyFeeLimit, "Royalty fee is higher than the limit");
        _collectionToRoyaltyFee[nftAddress] = RoyaltyFee({setter: admin, receiver: receiver, fee: fee});

        emit RoyaltyFeeChanged(
            nftAddress,
            fee
        );
    }

    function updateRoyaltyFeeForCollectionIfSetter(
        address nftAddress,
        address setter,
        address receiver,
        uint256 fee
    ) external {
        require(!IERC165(nftAddress).supportsInterface(ERC2981_INTERFACE_ID), "NFT contract must not support ERC2981");
        require(msg.sender == _collectionToRoyaltyFee[nftAddress].setter, "Not the NFT collection admin");
        require(fee <= royaltyFeeLimit, "Royalty fee is higher than the limit");
        _collectionToRoyaltyFee[nftAddress] = RoyaltyFee({setter: setter, receiver: receiver, fee: fee});

        emit RoyaltyFeeChanged(
            nftAddress,
            fee
        );
    }

    function updateFeeLimit(uint256 newFeeLimit) external onlyOwner {
        require(newFeeLimit <= 10000, "New royalty fee limit is too high");
        royaltyFeeLimit = newFeeLimit;

        emit FeeLimitChanged(newFeeLimit);
    }

    function getRoyaltyInfo(
        address nftAddress,
        uint256 amount
    ) external view returns (address, uint256) 
    {
        return (
            _collectionToRoyaltyFee[nftAddress].receiver,
            (amount * _collectionToRoyaltyFee[nftAddress].fee) / 10000
        );
    }

    function getRoyaltyFeeForCollection(address nftAddress)
        external view returns (address, address, uint256) 
    {
        return (
            _collectionToRoyaltyFee[nftAddress].setter,
            _collectionToRoyaltyFee[nftAddress].receiver,
            _collectionToRoyaltyFee[nftAddress].fee
        );
    }

    function calculateRoyaltyFee(address nftAddress, uint256 tokenId, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        address owner;
        uint256 royaltyFee;

        if(IERC165(nftAddress).supportsInterface(ERC2981_INTERFACE_ID)) {
            (receiver, royaltyAmount) = IERC2981(nftAddress).royaltyInfo(tokenId, salePrice);
        }
        else {
            (owner, receiver, royaltyFee) = this.getRoyaltyFeeForCollection(nftAddress);
            royaltyAmount = ((royaltyFee*salePrice)/1000);
        }

        return (receiver, royaltyAmount);
    }
}