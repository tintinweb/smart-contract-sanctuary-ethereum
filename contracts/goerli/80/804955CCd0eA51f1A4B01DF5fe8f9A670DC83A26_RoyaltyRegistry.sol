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
pragma solidity >0.8.0;

// import "./IERC165.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

///
/// @dev Interface for the NFT Royalty Standard
///
interface IERC2981 is IERC165 {
    /// ERC165 bytes to add to interface array - set in parent contract
    /// implementing this standard
    ///
    /// bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
    /// bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    /// _registerInterface(_INTERFACE_ID_ERC2981);

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _salePrice
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity >0.8.0;

struct Royalties {
    address payable recepient;
    uint96 royalty;
}

interface IRoyaltyProvider {
    function getRoyalties(address token, uint256 tokenId)
        external
        returns (Royalties[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../interfaces/IRoyaltyProvider.sol";
import "../interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error RoyaltyRecepientIsZero();
error RoyaltyAmountIsZero();
error RoyaltyAbove100Percent();
error GetRoyaltiesError();
error UnauthorizedCall();

contract RoyaltyRegistry is Ownable, IRoyaltyProvider {
    uint256 constant _WEIGHT_VALUE = 1000000;
    // type of royalty providers:
    // 0 = provider is unset
    // 1 = internalProvider
    // 2 = EIP-2981
    // 3 = external provider
    struct Royalty {
        bool initialized;
        uint8 providerType;
        address provider;
        Royalties[] royalty;
    }

    mapping(address => Royalty) public royaltyByToken; /// type of provider, address of token => Royalty

    event RoyaltiesSet(Royalties[] royalty, address token);

    constructor() Ownable() {}

    function setRoyaltyProvider(address token, address provider) external {
        checkOwner(token);
        royaltyByToken[token].provider = provider;
        royaltyByToken[token].providerType = 3;
    }

    function setRoyaltyType(address token, uint8 providerType) external {
        checkOwner(token);
        royaltyByToken[token].providerType = providerType;
    }

    function setRoyalty(Royalties[] memory royalties, address token) external {
        checkOwner(token);
        uint256 sumRoyalties;
        if (royalties.length > 0) {
            for (uint256 i = 0; i < royalties.length; i++) {
                if (royalties[i].recepient == address(0x0)) {
                    revert RoyaltyRecepientIsZero();
                }
                if (royalties[i].royalty == 0) {
                    revert RoyaltyAmountIsZero();
                }
                royaltyByToken[token].royalty.push(royalties[i]);
                sumRoyalties += royalties[i].royalty;
            }
        }

        if (sumRoyalties > 10000) revert RoyaltyAbove100Percent();

        royaltyByToken[token].initialized = true;
        emit RoyaltiesSet(royalties, token);
    }

    function getProviderType(address token) internal view returns (uint8) {
        if (royaltyByToken[token].providerType != 0)
            return royaltyByToken[token].providerType;

        try
            IERC165(token).supportsInterface(type(IERC2981).interfaceId)
        returns (bool result) {
            if (result) return 2;
        } catch {}

        if (royaltyByToken[token].provider != address(0)) {
            return 3;
        }

        if (royaltyByToken[token].initialized) return 1;

        return 0;
    }

    function getRoyalties(address token, uint256 tokenId)
        external
        override
        returns (Royalties[] memory)
    {
        Royalty storage royalty = royaltyByToken[token];
        if (royalty.providerType == 0) {
            royalty.providerType = getProviderType(token);
        }

        uint256 providerType = royalty.providerType;
        if (providerType == 1) return royalty.royalty;

        if (providerType == 2) {
            return getRoyaltiesEIP2981(token, tokenId);
        }
        if (providerType == 3)
            return providerExtractor(token, tokenId, royalty.provider);

        return new Royalties[](0);
    }

    function getRoyaltiesEIP2981(address token, uint256 tokenId)
        internal
        view
        returns (Royalties[] memory)
    {
        try IERC2981(token).royaltyInfo(tokenId, _WEIGHT_VALUE) returns (
            address receiver,
            uint256 royaltyAmount
        ) {
            Royalties[] memory result;
            if (royaltyAmount == 0) {
                return result;
            }
            uint256 percent = (royaltyAmount * 10000) / _WEIGHT_VALUE;

            if (percent > 10000) revert RoyaltyAbove100Percent();

            result = new Royalties[](1);
            result[0].recepient = payable(receiver);
            result[0].royalty = uint96(percent);
            return result;
        } catch {
            return new Royalties[](0);
        }
    }

    function providerExtractor(
        address token,
        uint256 tokenId,
        address providerAddress
    ) internal returns (Royalties[] memory) {
        try
            IRoyaltyProvider(providerAddress).getRoyalties(token, tokenId)
        returns (Royalties[] memory result) {
            return result;
        } catch {
            return new Royalties[](0);
        }
    }

    function checkOwner(address token) internal view {
        if ((msg.sender != owner()) && (msg.sender != Ownable(token).owner())) {
            revert UnauthorizedCall();
        }
    }
}