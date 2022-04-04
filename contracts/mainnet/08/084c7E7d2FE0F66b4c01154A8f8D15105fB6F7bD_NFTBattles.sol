//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import './NFT/IERC721Full.sol';

/// @title INiftyForge721
/// @author Simon Fremaux (@dievardump)
/// @notice Interface to interact with a NiftyFroge721 on a network
interface INiftyForge721 is IERC721Full {
    struct ModuleInit {
        address module;
        bool enabled;
        bool minter;
    }

    /// @notice this is the constructor of the contract, called at the time of creation
    ///         Although it uses what are called upgradeable contracts, this is only to
    ///         be able to make deployment cheap using a Proxy but NiftyForge contracts
    ///         ARE NOT UPGRADEABLE => the proxy used is not an upgradeable proxy, the implementation is immutable
    /// @param name_ name of the contract (see ERC721)
    /// @param symbol_ symbol of the contract (see ERC721)
    /// @param contractURI_ The contract URI (containing its metadata) - can be empty ""
    /// @param baseURI_ the contract baseURI (if there is)  - can be empty ""
    /// @param owner_ Address to whom transfer ownership
    /// @param modulesInit_ modules to add / enable directly at creation
    /// @param contractRoyaltiesRecipient the recipient, if the contract has "contract wide royalties"
    /// @param contractRoyaltiesValue the value, modules to add / enable directly at creation
    function initialize(
        string memory name_,
        string memory symbol_,
        string memory contractURI_,
        string memory baseURI_,
        address owner_,
        ModuleInit[] memory modulesInit_,
        address contractRoyaltiesRecipient,
        uint256 contractRoyaltiesValue
    ) external;

    /// @notice getter for the version of the implementation
    /// @return the current implementation version following the scheme 0x[erc][type][version]
    /// erc: 00 => ERC721 | 01 => ERC1155
    /// type: 00 => full | 01 => slim
    /// version: 00, 01, 02, 03...
    function version() external view returns (bytes3);

    /// @notice totalSupply access
    function totalSupply() external view returns (uint256);

    /// @notice helper to know if everyone can mint or only minters
    function isMintingOpenToAll() external view returns (bool);

    /// @notice Toggle minting open to all state
    /// @param isOpen if the new state is open or not
    function setMintingOpenToAll(bool isOpen) external;

    /// @notice Allows to set a maximum number of mint possible
    function setMaxSupply(uint256 maxSupply_) external;

    /// @notice Mint next token to `to`
    /// @param to address of recipient
    /// @return tokenId the tokenId
    function mint(address to) external returns (uint256 tokenId);

    /// @notice Mint next token to `to` and then transfers to `transferTo`
    /// @param to address of first recipient
    /// @param transferTo address to transfer token to
    /// @return tokenId the tokenId
    function mint(address to, address transferTo)
        external
        returns (uint256 tokenId);

    /// @notice Mint token to `to` with `uri`
    /// @param to address of recipient
    /// @param uri token metadata uri
    /// @param feeRecipient the recipient of royalties
    /// @param feeAmount the royalties amount. From 0 to 10000
    ///        where 10000 == 100.00%; 1000 == 10.00%; 250 == 2.50%
    /// @param transferTo the address to transfer the NFT to after mint
    ///        this is used when we want to mint the NFT to the creator address
    ///        before transferring it to a recipient
    /// @return tokenId the tokenId
    function mint(
        address to,
        string memory uri,
        address feeRecipient,
        uint256 feeAmount,
        address transferTo
    ) external returns (uint256 tokenId);

    /// @notice Mint batch tokens to `to[i]` with `uri[i]`
    /// @param to array of address of recipients
    /// @param uris array of token metadata uris
    /// @param feeRecipients the recipients of royalties for each id
    /// @param feeAmounts the royalties amounts for each id. From 0 to 10000
    ///        where 10000 == 100.00%; 1000 == 10.00%; 250 == 2.50%
    /// @return startId the first id
    /// @return endId the last id
    function mintBatch(
        address[] memory to,
        string[] memory uris,
        address[] memory feeRecipients,
        uint256[] memory feeAmounts
    ) external returns (uint256 startId, uint256 endId);

    /// @notice Mint `tokenId` to to` with `uri`
    ///         Because not all tokenIds have incremental ids
    ///         be careful with this function, it does not increment lastTokenId
    ///         and expects the minter to actually know what it is doing.
    ///         this also means, this function does not verify _maxTokenId
    /// @param to address of recipient
    /// @param uri token metadata uri
    /// @param tokenId token id wanted
    /// @param feeRecipient the recipient of royalties
    /// @param feeAmount the royalties amount. From 0 to 10000
    ///        where 10000 == 100.00%; 1000 == 10.00%; 250 == 2.50%
    /// @param transferTo the address to transfer the NFT to after mint
    ///        this is used when we want to mint the NFT to the creator address
    ///        before transferring it to a recipient
    /// @return tokenId the tokenId
    function mint(
        address to,
        string memory uri,
        uint256 tokenId_,
        address feeRecipient,
        uint256 feeAmount,
        address transferTo
    ) external returns (uint256 tokenId);

    /// @notice Mint batch tokens to `to[i]` with `uris[i]`
    ///         Because not all tokenIds have incremental ids
    ///         be careful with this function, it does not increment lastTokenId
    ///         and expects the minter to actually know what it's doing.
    ///         this also means, this function does not verify _maxTokenId
    /// @param to array of address of recipients
    /// @param uris array of token metadata uris
    /// @param tokenIds array of token ids wanted
    /// @param feeRecipients the recipients of royalties for each id
    /// @param feeAmounts the royalties amounts for each id. From 0 to 10000
    ///        where 10000 == 100.00%; 1000 == 10.00%; 250 == 2.50%
    function mintBatch(
        address[] memory to,
        string[] memory uris,
        uint256[] memory tokenIds,
        address[] memory feeRecipients,
        uint256[] memory feeAmounts
    ) external;

    /// @notice Attach a module
    /// @param module a module to attach
    /// @param enabled if the module is enabled by default
    /// @param canModuleMint if the module has to be given the minter role
    function attachModule(
        address module,
        bool enabled,
        bool canModuleMint
    ) external;

    /// @dev Allows owner to enable a module
    /// @param module to enable
    /// @param canModuleMint if the module has to be given the minter role
    function enableModule(address module, bool canModuleMint) external;

    /// @dev Allows owner to disable a module
    /// @param module to disable
    function disableModule(address module, bool keepListeners) external;

    /// @notice allows to force the collection to start ids at 0
    function startAtZero() external;

    /// @notice function that returns a string that can be used to render the current token
    /// @param tokenId tokenId
    /// @return the URI to render token
    function renderTokenURI(uint256 tokenId)
        external
        view
        returns (string memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';

interface INFModule is IERC165 {
    /// @notice Called by a Token Registry whenever the module is Attached
    /// @return if the attach worked
    function onAttach() external returns (bool);

    /// @notice Called by a Token Registry whenever the module is Enabled
    /// @return if the enabling worked
    function onEnable() external returns (bool);

    /// @notice Called by a Token Registry whenever the module is Disabled
    function onDisable() external;

    /// @notice returns an URI with information about the module
    /// @return the URI where to find information about the module
    function contractURI() external view returns (string memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface INFModuleTokenURI {
    function tokenURI(address registry, uint256 tokenId)
        external
        view
        returns (string memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface INFModuleWithRoyalties {
    /// @notice Return royalties (recipient, basisPoint) for tokenId
    /// @dev Contrary to EIP2981, modules are expected to return basisPoint for second parameters
    ///      This in order to allow right royalties on marketplaces not supporting 2981 (like Rarible)
    /// @param registry registry to check id of
    /// @param tokenId token to check
    /// @return recipient and basisPoint for this tokenId
    function royaltyInfo(address registry, uint256 tokenId)
        external
        view
        returns (address recipient, uint256 basisPoint);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import './INFModule.sol';

/// @title NFBaseModule
/// @author Simon Fremaux (@dievardump)
contract NFBaseModule is INFModule, ERC165 {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet internal _attached;

    event NewContractURI(string contractURI);

    string private _contractURI;

    modifier onlyAttached(address registry) {
        require(_attached.contains(registry), '!NOT_ATTACHED!');
        _;
    }

    constructor(string memory contractURI_) {
        _setContractURI(contractURI_);
    }

    /// @inheritdoc	INFModule
    function contractURI()
        external
        view
        virtual
        override
        returns (string memory)
    {
        return _contractURI;
    }

    /// @inheritdoc	INFModule
    function onAttach() external virtual override returns (bool) {
        if (_attached.add(msg.sender)) {
            return true;
        }

        revert('!ALREADY_ATTACHED!');
    }

    /// @notice this contract doesn't really care if it's enabled or not
    ///         since trying to mint on a contract where it's not enabled will fail
    /// @inheritdoc	INFModule
    function onEnable() external virtual override returns (bool) {
        return true;
    }

    /// @inheritdoc	INFModule
    function onDisable() external virtual override {}

    function _setContractURI(string memory contractURI_) internal {
        _contractURI = contractURI_;
        emit NewContractURI(contractURI_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @dev This is the interface for NFT extension mutableURI
/// @author Simon Fremaux (@dievardump)
interface IERC721WithMutableURI {
    function mutableURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '../Royalties/ERC2981/IERC2981Royalties.sol';
import '../Royalties/RaribleSecondarySales/IRaribleSecondarySales.sol';
import '../Royalties/FoundationSecondarySales/IFoundationSecondarySales.sol';

/// @dev This is a contract used for royalties on various platforms
/// @author Simon Fremaux (@dievardump)
interface IERC721WithRoyalties is
    IERC2981Royalties,
    IRaribleSecondarySales,
    IFoundationSecondarySales
{

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol';

import './ERC721/IERC721WithRoyalties.sol';
import './ERC721/IERC721WithMutableURI.sol';

/// @title ERC721Full
/// @dev This contains all the different overrides needed on
///      ERC721 / URIStorage / Royalties
///      This contract does not use ERC721enumerable because Enumerable adds quite some
///      gas to minting costs and I am trying to make this cheap for creators.
///      Also, since all NiftyForge contracts will be fully indexed in TheGraph it will easily
///      Be possible to get tokenIds of an owner off-chain, before passing them to a contract
///      which can verify ownership at the processing time
/// @author Simon Fremaux (@dievardump)
interface IERC721Full is
    IERC721Upgradeable,
    IERC721WithRoyalties,
    IERC721WithMutableURI
{
    function baseURI() external view returns (string memory);

    function contractURI() external view returns (string memory);

    /// @notice This is a generic function that allows this contract's owner to withdraw
    ///         any balance / ERC20 / ERC721 / ERC1155 it can have
    ///         this contract has no payable nor receive function so it should not get any nativ token
    ///         but this could save some ERC20, 721 or 1155
    /// @param token the token to withdraw from. address(0) means native chain token
    /// @param amount the amount to withdraw if native token, erc20 or erc1155 - must be 0 for ERC721
    /// @param tokenId the tokenId to withdraw for ERC1155 and ERC721
    function withdraw(
        address token,
        uint256 amount,
        uint256 tokenId
    ) external;

    /// @notice Helper to know if an address can do the action an Editor can
    /// @param account the address to check
    function canEdit(address account) external view returns (bool);

    /// @notice Helper to know if an address can do the action a Minter can
    /// @param account the address to check
    function canMint(address account) external view returns (bool);

    /// @notice Helper to know if an address is editor
    /// @param account the address to check
    function isEditor(address account) external view returns (bool);

    /// @notice Helper to know if an address is minter
    /// @param account the address to check
    function isMinter(address account) external view returns (bool);

    /// @notice Allows to get approved using a permit and transfer in the same call
    /// @dev this supposes that the permit is for msg.sender
    /// @param from current owner
    /// @param to recipient
    /// @param tokenId the token id
    /// @param _data optional data to add
    /// @param deadline the deadline for the permit to be used
    /// @param signature of permit
    function safeTransferFromWithPermit(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data,
        uint256 deadline,
        bytes memory signature
    ) external;

    /// @notice Set the base token URI
    /// @dev only an editor can do that (account or module)
    /// @param baseURI_ the new base token uri used in tokenURI()
    function setBaseURI(string memory baseURI_) external;

    /// @notice Set the base mutable meta URI for tokens
    /// @param baseMutableURI_ the new base for mutable meta uri used in mutableURI()
    function setBaseMutableURI(string memory baseMutableURI_) external;

    /// @notice Set the mutable URI for a token
    /// @dev    Mutable URI work like tokenURI
    ///         -> if there is a baseMutableURI and a mutableURI, concat baseMutableURI + mutableURI
    ///         -> else if there is only mutableURI, return mutableURI
    //.         -> else if there is only baseMutableURI, concat baseMutableURI + tokenId
    /// @dev only an editor (account or module) can call this
    /// @param tokenId the token to set the mutable URI for
    /// @param mutableURI_ the mutable URI
    function setMutableURI(uint256 tokenId, string memory mutableURI_) external;

    /// @notice Helper for the owner to add new editors
    /// @dev needs to be owner
    /// @param users list of new editors
    function addEditors(address[] memory users) external;

    /// @notice Helper for the owner to remove editors
    /// @dev needs to be owner
    /// @param users list of removed editors
    function removeEditors(address[] memory users) external;

    /// @notice Helper for an editor to add new minter
    /// @dev needs to be owner
    /// @param users list of new minters
    function addMinters(address[] memory users) external;

    /// @notice Helper for an editor to remove minters
    /// @dev needs to be owner
    /// @param users list of removed minters
    function removeMinters(address[] memory users) external;

    /// @notice Allows to change the default royalties recipient
    /// @dev an editor can call this
    /// @param recipient new default royalties recipient
    function setDefaultRoyaltiesRecipient(address recipient) external;

    /// @notice Allows a royalty recipient of a token to change their recipient address
    /// @dev only the current token royalty recipient can change the address
    /// @param tokenId the token to change the recipient for
    /// @param recipient new default royalties recipient
    function setTokenRoyaltiesRecipient(uint256 tokenId, address recipient)
        external;

    /// @notice Helper for the owner of the contract to set the new contract URI
    /// @dev needs to be owner
    /// @param contractURI_ new contract URI
    function setContractURI(string memory contractURI_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title IERC2981Royalties
/// @dev Interface for the ERC2981 - Token Royalty standard
interface IERC2981Royalties {
    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _value - the sale price of the NFT asset specified by _tokenId
    /// @return _receiver - address of who should be sent the royalty payment
    /// @return _royaltyAmount - the royalty payment amount for value sale price
    function royaltyInfo(uint256 _tokenId, uint256 _value)
        external
        view
        returns (address _receiver, uint256 _royaltyAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IFoundationSecondarySales {
    /// @notice returns a list of royalties recipients and the amount
    /// @param tokenId the token Id to check for
    /// @return all the recipients and their basis points, for tokenId
    function getFees(uint256 tokenId)
        external
        view
        returns (address payable[] memory, uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IRaribleSecondarySales {
    /// @notice returns a list of royalties recipients
    /// @param tokenId the token Id to check for
    /// @return all the recipients for tokenId
    function getFeeRecipients(uint256 tokenId)
        external
        view
        returns (address payable[] memory);

    /// @notice returns a list of royalties amounts
    /// @param tokenId the token Id to check for
    /// @return all the amounts for tokenId
    function getFeeBps(uint256 tokenId)
        external
        view
        returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GroupedURIs {
    event TokenToGroup(uint256 tokenId, uint256 groupId);

    /// @notice current group of tokenIds
    uint256 public currentGroupId;

    /// @notice the NFTs will first have centralized tokenURIs until the artist provide all files
    mapping(uint256 => string) public groupBaseURI;

    /// @notice mapping tokenId to group
    mapping(uint256 => uint256) public tokenGroup;

    function _incrementGroup(
        string memory previousGroupBaseURI,
        string memory newGroupBaseURI
    ) internal {
        if (bytes(previousGroupBaseURI).length != 0) {
            _setGroupURI(currentGroupId, previousGroupBaseURI);
        }
        _setGroupURI(++currentGroupId, newGroupBaseURI);
    }

    function _setGroupURI(uint256 group, string memory baseURI) internal {
        groupBaseURI[group] = baseURI;
    }

    function _setTokenGroup(uint256 tokenId, uint256 groupId) internal {
        tokenGroup[tokenId] = groupId;
        emit TokenToGroup(tokenId, groupId);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {INiftyForge721} from "@0xdievardump/niftyforge/contracts/INiftyForge721.sol";
import {NFBaseModule} from "@0xdievardump/niftyforge/contracts/Modules/NFBaseModule.sol";
import {INFModuleTokenURI} from "@0xdievardump/niftyforge/contracts/Modules/INFModuleTokenURI.sol";
import {INFModuleWithRoyalties} from "@0xdievardump/niftyforge/contracts/Modules/INFModuleWithRoyalties.sol";

import {GroupedURIs} from "./GroupedURIs.sol";

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function transfer(address to, uint256 value) external returns (bool);
}

contract NFTBattles is
    Ownable,
    ReentrancyGuard,
    GroupedURIs,
    NFBaseModule,
    INFModuleTokenURI,
    INFModuleWithRoyalties
{
    using Strings for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    error WETHNotSet();
    error BattleInactive();
    error WrongContender();
    error NoSelfOutbid();
    error WrongBidValue();
    error NotEnoughContenders();
    error AlreadySettled();
    error UnknownBattle();
    error BattleNotEnded();

    event BattleCreated(uint256 battleId, address[] contenders);

    event BidCreated(
        uint256 battleId,
        uint256 contender,
        address bidder,
        uint256 bid
    );

    event BattleStartChanged(uint256 battleId, uint256 newEnd);

    event BattleEndChanged(uint256 battleId, uint256 newEnd);

    event BattleSettled(uint256 battleId, uint256 bidsSum);

    event BattleContenderResult(
        uint256 battleId,
        uint256 index,
        uint256 tokenId,
        address randomBidder
    );

    event BattleCanceled(uint256 battleId);

    struct Battle {
        uint256 startsAt;
        uint256 endsAt;
        uint256 contenders;
        bool settled;
    }

    struct BattleContender {
        address artist;
        address highestBidder;
        uint256 highestBid;
        EnumerableSet.AddressSet bidders;
    }

    /// @notice the contract holding the NFTs
    address public nftContract;

    /// @notice minimal bid
    uint256 public minimalBid = 0.001 ether;

    /// @notice minimal bid increase when bidding (5% initially)
    uint256 public minimalBidIncrease = 5;

    /// @notice time to add to the battle auction end when late bids
    uint256 public timeBuffer = 5 minutes;

    /// @notice contains last known battle id
    uint256 public lastBattleId;

    /// @notice the target address getting the eth when settling a Battle
    address public withdrawTarget;

    /// @notice all battles
    mapping(uint256 => Battle) public battles;

    /// @notice all contenders
    mapping(uint256 => mapping(uint256 => BattleContender))
        internal _battleContenders;

    /// @notice weth contract address to refund users if transfer fails
    address public immutable wethContract;

    /// @notice mapping tokenId => creator
    mapping(uint256 => address) public tokenCreator;

    constructor(
        string memory contractURI_,
        string memory baseURI,
        address wethContract_,
        address owner_
    ) NFBaseModule(contractURI_) {
        _incrementGroup("", baseURI);

        uint256 chainId = block.chainid;
        if (chainId == 4) {
            wethContract_ = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
        } else if (chainId == 1) {
            wethContract_ = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        } else {
            if (wethContract_ == address(0)) {
                revert WETHNotSet();
            }
        }

        // immutable can not be initialized in an if statement.
        wethContract = wethContract_;

        if (owner_ != address(0)) {
            transferOwnership(owner_);
        }
    }

    ////////////////////////////////////////////
    // getters                                //
    ////////////////////////////////////////////

    /// @notice returns current bids for a battle
    /// @param battleId the battle id
    /// @return bidders an array of bidders
    /// @return bids an array of bids
    function getBattleBids(uint256 battleId)
        external
        view
        returns (address[] memory bidders, uint256[] memory bids)
    {
        Battle memory battle = battles[battleId];

        bidders = new address[](battle.contenders);
        bids = new uint256[](battle.contenders);

        for (uint256 i; i < battle.contenders; i++) {
            bidders[i] = _battleContenders[battleId][i].highestBidder;
            bids[i] = _battleContenders[battleId][i].highestBid;
        }
    }

    ////////////////////////////////////////////////////
    ///// Module                                      //
    ////////////////////////////////////////////////////

    function onAttach() external virtual override returns (bool) {
        if (nftContract != address(0)) {
            revert();
        }

        nftContract = msg.sender;
        return true;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(INFModuleTokenURI).interfaceId ||
            interfaceId == type(INFModuleWithRoyalties).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @inheritdoc	INFModuleWithRoyalties
    function royaltyInfo(address, uint256 tokenId)
        public
        view
        override
        returns (address recipient, uint256 basisPoint)
    {
        // 7.5% to tokenCreator
        recipient = tokenCreator[tokenId];
        basisPoint = 750;
    }

    /// @inheritdoc	INFModuleTokenURI
    function tokenURI(address registry, uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        string memory baseURI = groupBaseURI[tokenGroup[tokenId]];
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    ////////////////////////////////////////////
    // Publics                                //
    ////////////////////////////////////////////

    /// @notice Allows to bid on `contender` for a Battle
    /// @param battleId the battle id to bid on
    /// @param contender the contender to bid on
    function bid(uint256 battleId, uint256 contender)
        public
        payable
        nonReentrant
    {
        if (battleId > lastBattleId) {
            revert UnknownBattle();
        }

        Battle storage battle = battles[battleId];

        if (battle.settled) {
            revert AlreadySettled();
        }

        // time check
        uint256 timestamp = block.timestamp;
        if (!(timestamp >= battle.startsAt && timestamp < battle.endsAt)) {
            revert BattleInactive();
        }

        // input check
        BattleContender storage auction = _battleContenders[battleId][
            contender
        ];
        if (auction.artist == address(0)) {
            revert WrongContender();
        }

        address sender = msg.sender;

        // can't outbid yourself.
        // why? someone could be watching the pool, and outbid themselves in order to make incoming bid invalid
        // and not have to outbid an higher bid
        if (auction.highestBidder == sender) {
            revert NoSelfOutbid();
        }

        // value check
        uint256 currentBid = msg.value;
        if (
            currentBid <
            ((auction.highestBid * (100 + minimalBidIncrease)) / 100) ||
            currentBid < minimalBid
        ) {
            revert WrongBidValue();
        }

        // add to bidders
        auction.bidders.add(sender);

        // refund previous highest bidder
        if (auction.highestBid != 0) {
            _sendETHSafe(auction.highestBidder, auction.highestBid);
        }

        auction.highestBidder = sender;
        auction.highestBid = currentBid;

        emit BidCreated(battleId, contender, sender, currentBid);

        uint256 timeBuffer_ = timeBuffer;
        if (timestamp > battle.endsAt - timeBuffer_) {
            battle.endsAt = timestamp + timeBuffer_;
            emit BattleEndChanged(battleId, battle.endsAt);
        }
    }

    ////////////////////////////////////////////
    // Owner / Admin                          //
    ////////////////////////////////////////////

    /// @notice Allows owner to create a battle
    /// @param contenders the contenders for this battle
    /// @param startsAt when the battle starts
    /// @param duration the duration of the battle
    function createBattle(
        address[] calldata contenders,
        uint256 startsAt,
        uint256 duration
    ) external onlyOwner {
        uint256 length = contenders.length;
        if (length < 2) {
            revert NotEnoughContenders();
        }

        uint256 battleId = ++lastBattleId;

        Battle storage battle = battles[battleId];

        battle.startsAt = startsAt;
        battle.endsAt = startsAt + duration;
        battle.contenders = length;

        for (uint256 i; i < length; i++) {
            if (contenders[i] == address(0)) {
                revert WrongContender();
            }

            _battleContenders[battleId][i].artist = contenders[i];
        }

        emit BattleCreated(battleId, contenders);
    }

    /// @notice allows owner to cancel a battle
    /// @param battleId the battle id
    function cancelBattle(uint256 battleId) external onlyOwner {
        if (battleId > lastBattleId) {
            revert UnknownBattle();
        }

        Battle storage battle = battles[battleId];
        battle.settled = true;

        uint256 length = battle.contenders;
        BattleContender storage contender;

        for (uint256 i; i < length; i++) {
            contender = _battleContenders[battleId][i];
            // refund highest bidder for each contender
            if (contender.highestBid != 0) {
                _sendETHSafe(contender.highestBidder, contender.highestBid);
            }
        }

        emit BattleCanceled(battleId);
    }

    /// @notice allows owner to settle a battle
    /// @param battleId the battle id
    function settleBattle(uint256 battleId) external onlyOwner {
        if (battleId > lastBattleId) {
            revert UnknownBattle();
        }

        Battle storage battle = battles[battleId];

        if (battle.settled) {
            revert AlreadySettled();
        }

        uint256 timestamp = block.timestamp;
        if (timestamp < battle.endsAt) {
            revert BattleNotEnded();
        }

        // settle the battle here, this will lock any Reentrancy
        battle.settled = true;

        bytes32 seed = keccak256(
            abi.encode(
                block.timestamp,
                msg.sender,
                block.difficulty,
                blockhash(block.number - 1)
            )
        );

        uint256 cumul;
        uint256 temp;
        uint256 length = battle.contenders;

        uint256 currentGroupId_ = currentGroupId;
        address nftContract_ = nftContract;
        BattleContender storage contender;

        for (uint256 i; i < length; i++) {
            contender = _battleContenders[battleId][i];
            cumul += contender.highestBid;

            if (contender.highestBid > 0) {
                // if there is a bid
                // mint the NFT to artist and transfer to highestBidder
                temp = INiftyForge721(nftContract_).mint(
                    contender.artist,
                    contender.highestBidder
                );

                // select a random bidder in the list of bidders
                seed = keccak256(abi.encode(seed));

                emit BattleContenderResult(
                    battleId,
                    i, // index
                    temp, // tokenId
                    //  random bidder
                    contender.bidders.at(
                        uint256(seed) % contender.bidders.length()
                    )
                );
            } else {
                // else mint the NFT to artist
                temp = INiftyForge721(nftContract_).mint(contender.artist);
            }

            _setTokenGroup(temp, currentGroupId_);
            tokenCreator[temp] = contender.artist;
        }

        _sendETHSafe(
            withdrawTarget != address(0) ? withdrawTarget : msg.sender,
            cumul
        );

        emit BattleSettled(battleId, cumul);
    }

    /// @notice allows owner to change the time of a battle
    /// @param battleId the battle id
    /// @param startsAt the start time
    /// @param duration the battle duration
    function setBattleStarts(
        uint256 battleId,
        uint256 startsAt,
        uint256 duration
    ) external onlyOwner {
        if (battleId > lastBattleId) {
            revert UnknownBattle();
        }

        Battle storage battle = battles[battleId];

        if (battle.settled) {
            revert AlreadySettled();
        }

        battle.startsAt = startsAt;
        battle.endsAt = startsAt + duration;
        emit BattleStartChanged(battleId, startsAt);
        emit BattleEndChanged(battleId, startsAt + duration);
    }

    /// @notice allows owner to pass to the next
    /// @param previousGroupBaseURI current group baseURI
    /// @param newGroupBaseURI next group baseURI
    function incrementGroup(
        string calldata previousGroupBaseURI,
        string calldata newGroupBaseURI
    ) external onlyOwner {
        _incrementGroup(previousGroupBaseURI, newGroupBaseURI);
    }

    /// @notice allows owner to set a group URI
    /// @param groupId the group id
    /// @param baseURI group baseURI
    function setGroupURI(uint256 groupId, string calldata baseURI)
        external
        onlyOwner
    {
        _setGroupURI(groupId, baseURI);
    }

    /// @notice allows owner to set one URI for several groups
    /// @param groupIds the groups ids
    /// @param baseURI group baseURI
    function setGroupsURI(uint256[] calldata groupIds, string calldata baseURI)
        external
        onlyOwner
    {
        for (uint256 i; i < groupIds.length; i++) {
            _setGroupURI(groupIds[i], baseURI);
        }
    }

    /// @notice allows owner to associate a token to a specific group
    /// @param tokenId the token id
    /// @param groupId the group id
    function setTokenGroup(uint256 tokenId, uint256 groupId)
        external
        onlyOwner
    {
        _setTokenGroup(tokenId, groupId);
    }

    /// @notice allows owner to associate tokenIds to a specific group
    /// @param tokenIds the token ids
    /// @param groupId the group id
    function setTokensGroup(uint256[] calldata tokenIds, uint256 groupId)
        external
        onlyOwner
    {
        for (uint256 i; i < tokenIds.length; i++) {
            _setTokenGroup(tokenIds[i], groupId);
        }
    }

    /// @notice allows owner to set the withdraw address
    /// @param newWithdrawTarget the new address to withdraw to
    function setWithdrawTarget(address newWithdrawTarget) external onlyOwner {
        withdrawTarget = newWithdrawTarget;
    }

    /// @notice allows owner to change minimalBidIncreace and minimalBid
    /// @param newMinimalBid the new minimal bid, in wei
    /// @param newMinimalBidIncrease the new minimalBidIncrease, in percent, no decimals
    function setMinimals(uint256 newMinimalBid, uint256 newMinimalBidIncrease)
        external
        onlyOwner
    {
        minimalBid = newMinimalBid;
        minimalBidIncrease = newMinimalBidIncrease;
    }

    ////////////////////////////////////////////
    // Internals                              //
    ////////////////////////////////////////////

    /// @dev This function tries to send eth to an address; if the transfer doesn't work
    ///      it will be done using WETH
    /// @param recipient the recipient to refund
    /// @param value the value to refund
    function _sendETHSafe(address recipient, uint256 value) internal {
        if (value == 0) {
            return;
        }

        // limit to 30k gas, to ensure noone uses a contract
        // to make outbidding/canceling overly expensive or impossible.
        (bool success, ) = recipient.call{value: value, gas: 30000}("");

        // if the refund didn't work, transform the ethereum into WETH and send it
        // to recipient
        if (!success) {
            IWETH(wethContract).deposit{value: value}();
            IWETH(wethContract).transfer(recipient, value);
        }
    }
}