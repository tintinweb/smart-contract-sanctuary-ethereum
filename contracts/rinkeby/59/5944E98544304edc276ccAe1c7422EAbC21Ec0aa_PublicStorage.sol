//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interface/IPublicStorage.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Contract PublicStorage for storage info number
contract PublicStorage is IPublicStorage, Ownable {

    /// @notice interface DTO (IERC721)
    IERC721 public dto;
    
    /// @notice by token consist of address in different chains
    mapping(uint256 => mapping(uint256 => string)) private addressChain;
    
    /// @notice by token consist of address in different sosial networks
    mapping(uint256 => mapping(uint256 => string)) private userNameSocial;

    /// @notice User Information by token ID 
    mapping(uint256 => UserInfo) private userInfo;
    
    /// @notice Enable BlockChain
    mapping(uint256 => string) private nameBlockchain;
    
    /// @notice Enable BlockChain
    mapping(uint256 => string) private nameSocial;

    /**
     * @notice Construct a new contract
     * @param addressDto address contract DTO 
     */ 
    constructor(address addressDto) {
        dto = IERC721(addressDto);
    }
    
    modifier ownerNft(uint256 tokenId) {
        require(msg.sender == dto.ownerOf(tokenId), "Error: you don`t owner");
        _;
    }

    modifier lengthArray(uint256[] memory idArray) {
        require(idArray.length < 5, "Error: big counter idBLockchain");
        _;
    }

    /** @notice get address in BlockChain by token ID
     *  @param number token ID (PrefixNumberId)
     *  @param idChain id enable Chain
     *  @return address in Chain
    */
    function getAddressChain(uint256 number, uint256 idChain)
        external
        view
        returns (string memory)
    {
        return addressChain[number][idChain];
    }

    /** @notice get username in Social Network by token ID
     *  @param number token ID (PrefixNumberId)
     *  @param idSocial id enable Social Network
     *  @return username in Social Network
    */
    function getUserNameSocial(uint256 number, uint256 idSocial)
        external
        view
        returns (string memory)
    {
        return userNameSocial[number][idSocial];
    }

    /** @notice get Avatar by token ID
     *  @param number token ID (PrefixNumberId)
     *  @return link of Avatar or empty
    */
    function getUserAvatar(uint256 number)
        external
        view
        returns (string memory)
    {
        return userInfo[number].urlAvatar;
    }

    /** @notice get UserPhone by token ID
     *  @param number token ID (PrefixNumberId)
     *  @return real number phone or empty
    */
    function getUserPhone(uint256 number)
        external
        view
        returns (string memory)
    {
        return userInfo[number].numberPhone;
    }

    /** @notice get enable BlockChain
     *  @param idBlockchain id Block Chain
     *  @return name BlockChain or empty
    */
    function getNameBlockchain(uint256 idBlockchain)
        external
        view
        returns (string memory)
    {
        return nameBlockchain[idBlockchain];
    }

    /** @notice get enable Social Network
     *  @param idSocial id Social Network
     *  @return name Social Network or empty
    */
    function getNameSocial(uint256 idSocial)
        external
        view
        returns (string memory)
    {
        return nameSocial[idSocial];
    }

    /** @notice add enable list name BlockChain by id BlockChain 
     *  @param idBlockchain id Block Chain
     *  @param nameBlockchain_ name BlockChain
    */
    function addBlockchainOwner(
        uint256[] memory idBlockchain,
        string[] memory nameBlockchain_
    ) external override onlyOwner {
        for (uint256 i = 0; i < idBlockchain.length; i++) {
            nameBlockchain[idBlockchain[i]] = nameBlockchain_[i];
        }
    }

    /** @notice add list user address Wallet in different by token ID
     *  @param number id Token number
     *  @param idBlockchain id Block Chain
     *  @param addressUser addresses user 
    */
    function addWallet(
        uint256 number,
        uint256[] memory idBlockchain,
        string[] memory addressUser
    ) external override ownerNft(number) lengthArray(idBlockchain) {
        for (uint256 i = 0; i < idBlockchain.length; i++) {
            require(
                bytes(nameBlockchain[idBlockchain[i]]).length > 0,
                "Error: invalide id Blockchain"
            );
            addressChain[number][idBlockchain[i]] = addressUser[i];
        }
    }

    /** @notice add Avatar by token ID
     *  @param number token ID (PrefixNumberId)
     *  @param urlImage link of Avatar
    */
    function addAvatar(uint256 number, string memory urlImage)
        external
        override
        ownerNft(number)
    {
        userInfo[number].urlAvatar = urlImage;
    }

    /** @notice add Avatar by token ID
     *  @param number token ID (PrefixNumberId)
     *  @param phoneNumber real user phone
    */
    function addNumberPhone(uint256 number, string memory phoneNumber)
        external
        override
        ownerNft(number)
    {
        userInfo[number].numberPhone = phoneNumber;
    }

    /** @notice add enable list name Social Network by id Social Network 
     *  @param idSocial id Social Network
     *  @param nameSocial_ name Social Network
    */
    function addSocialOwner(
        uint256[] memory idSocial,
        string[] memory nameSocial_
    ) external override onlyOwner {
        for (uint256 i = 0; i < idSocial.length; i++) {
            nameSocial[idSocial[i]] = nameSocial_[i];
        }
    }

    /** @notice add list user address Wallet in different by token ID
     *  @param number id Token number
     *  @param idSocial id Social Network
     *  @param userName username of Social Network
    */
    function addSocial(
        uint256 number,
        uint256[] memory idSocial,
        string[] memory userName
    ) external override ownerNft(number) lengthArray(idSocial) {
        for (uint256 i = 0; i < idSocial.length; i++) {
            require(
                bytes(nameSocial[idSocial[i]]).length > 0,
                "Error: invalide id Social"
            );
            userNameSocial[number][idSocial[i]] = userName[i];
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IPublicStorage {
    struct UserInfo {
        string urlAvatar;
        string numberPhone;
    }

    /** @notice add enable list name BlockChain by id BlockChain 
     *  @param idBlockchain id Block Chain
     *  @param nameBlockchain_ name BlockChain
    */
    function addBlockchainOwner(
        uint256[] memory idBlockchain,
        string[] memory nameBlockchain_
    ) external;

    /** @notice add list user address Wallet in different by token ID
     *  @param number id Token number
     *  @param idBlockchain id Block Chain
     *  @param addressUser addresses user 
    */
    function addWallet(
        uint256 number,
        uint256[] memory idBlockchain,
        string[] memory addressUser
    ) external;

    /** @notice add Avatar by token ID
     *  @param number token ID (PrefixNumberId)
     *  @param urlImage link of Avatar
    */
    function addAvatar(uint256 number, string memory urlImage) external;

    /** @notice add Avatar by token ID
     *  @param number token ID (PrefixNumberId)
     *  @param phoneNumber real user phone
    */
    function addNumberPhone(uint256 number, string memory phoneNumber) external;

    /** @notice add enable list name Social Network by id Social Network 
     *  @param idSocial id Social Network
     *  @param nameSocial_ name Social Network
    */
    function addSocialOwner(
        uint256[] memory idSocial,
        string[] memory nameSocial_
    ) external;

    /** @notice add list user address Wallet in different by token ID
     *  @param number id Token number
     *  @param idSocial id Social Network
     *  @param userName username of Social Network
    */
    function addSocial(
        uint256 number,
        uint256[] memory idSocial,
        string[] memory userName
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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