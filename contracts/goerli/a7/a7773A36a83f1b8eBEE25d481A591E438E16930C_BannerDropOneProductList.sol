// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// NFTC Prerelease Contracts
import './IFlavorInfoV2.sol';

/**
 * @title IFlavorInfoProviderV2
 * @author @NFTCulture
 * @dev Interface for Providing a product list definition.
 *
 * Note: This definition is compatible with the V2 version of Flavor Infos.
 */
interface IFlavorInfoProviderV2 is IFlavorInfoV2 {
    function provideFlavorInfos() external view returns (FlavorInfoV2[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/**
 * @title IFlavorInfoV2
 * @author NFT Culture
 * @dev Interface for FlavorInfoV2 objects.
 *
 *  Bits Layout:
 *    256 bit slot #1
 *    - [0..63]    `flavorId`
 *    - [64..127]  `maxSupply`
 *    - [128..191] `totalMinted`
 *    - [192..255] `aux`
 *
 *    256 bit slot #2
 *    - [0..159]   `externalValidator`
 *    - [160..255] `price`
 *
 *    256 bit slot #3
 *    - [0..255] `uriFragment`
 *
 *  NOTE: Splitting out uriFragment and ipfsHash allows for the more gas efficient bytes32 uriFragment
 *  to be used if ipfsHash is included as part of Base URI.
 *
 *  URI should be built like: `${baseURI}${ipfsHash}${uriFragment}
 *    - Care should be taken to properly include '/' chars. Typically baseURI will have a trailing slash.
 *    - If ipfsHash is used, uriFragment should contain a leading '/'.
 *    - If ipfsHash is not used, uriFragment should not contain a leading '/'.
 */
interface IFlavorInfoV2 {
    struct FlavorInfoV2 {
        uint64 flavorId;
        uint64 maxSupply;
        uint64 totalMinted;
        uint64 aux; // Extra storage space that can be used however needed by the caller.
        address externalValidator; // Address of an external validator, for use cases such as making purchase of the product dependent on some other NFT project.
        uint96 price; // Price needs to be 96 bit. 64bit for value sets a cap at about 9.2 ETH (9.2e18 wei)
        bytes32 uriFragment; // Fragment to append to URI
        string ipfsHash; // IPFS Hash to append to URI
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// NFTC Prerelease Contracts
import './IFlavorInfoV2.sol';

/**
 * @title IFlavorInfoValidatorV2
 * @author @NFTCulture
 * @dev Interface for validating attempts to mint a Flavor token.
 *
 * Note: This definition is compatible with the V2 version of Flavor Infos.
 */
interface IFlavorInfoValidatorV2 is IFlavorInfoV2 {
    /**
     * @notice Determine validity of a Mint operation.
     *
     * @param caller The account that is executing the mint.
     * @param holder a cold wallet, if a delegation scheme is being used.
     * @param count the number of tokens requested.
     * @param flavorInfo the type of token requested.
     * @param validationData extra information needed to pass validation (if applicable).
     */
    function validateMint(
        address caller,
        address holder,
        uint256 count,
        FlavorInfoV2 memory flavorInfo,
        uint256 validationData
    ) external returns (bool, string memory);
}

// SPDX-License-Identifier: MIT
// Lifted from: https://github.com/delegatecash/delegation-registry/blob/main/src/IDelegationRegistry.sol
pragma solidity ^0.8.11;

/**
 * @title An immutable registry contract to be deployed as a standalone primitive
 * @dev See EIP-5639, new project launches can read previous cold wallet -> hot wallet delegations
 * from here and integrate those permissions into their flow
 */
interface IDelegationRegistry {
    /// @notice Delegation type
    enum DelegationType {
        NONE,
        ALL,
        CONTRACT,
        TOKEN
    }

    /// @notice Info about a single delegation, used for onchain enumeration
    struct DelegationInfo {
        DelegationType type_;
        address vault;
        address delegate;
        address contract_;
        uint256 tokenId;
    }

    /// @notice Info about a single contract-level delegation
    struct ContractDelegation {
        address contract_;
        address delegate;
    }

    /// @notice Info about a single token-level delegation
    struct TokenDelegation {
        address contract_;
        uint256 tokenId;
        address delegate;
    }

    /// @notice Emitted when a user delegates their entire wallet
    event DelegateForAll(address vault, address delegate, bool value);

    /// @notice Emitted when a user delegates a specific contract
    event DelegateForContract(address vault, address delegate, address contract_, bool value);

    /// @notice Emitted when a user delegates a specific token
    event DelegateForToken(address vault, address delegate, address contract_, uint256 tokenId, bool value);

    /// @notice Emitted when a user revokes all delegations
    event RevokeAllDelegates(address vault);

    /// @notice Emitted when a user revoes all delegations for a given delegate
    event RevokeDelegate(address vault, address delegate);

    /**
     * -----------  WRITE -----------
     */

    /**
     * @notice Allow the delegate to act on your behalf for all contracts
     * @param delegate The hotwallet to act on your behalf
     * @param value Whether to enable or disable delegation for this address, true for setting and false for revoking
     */
    function delegateForAll(address delegate, bool value) external;

    /**
     * @notice Allow the delegate to act on your behalf for a specific contract
     * @param delegate The hotwallet to act on your behalf
     * @param contract_ The address for the contract you're delegating
     * @param value Whether to enable or disable delegation for this address, true for setting and false for revoking
     */
    function delegateForContract(address delegate, address contract_, bool value) external;

    /**
     * @notice Allow the delegate to act on your behalf for a specific token
     * @param delegate The hotwallet to act on your behalf
     * @param contract_ The address for the contract you're delegating
     * @param tokenId The token id for the token you're delegating
     * @param value Whether to enable or disable delegation for this address, true for setting and false for revoking
     */
    function delegateForToken(address delegate, address contract_, uint256 tokenId, bool value) external;

    /**
     * @notice Revoke all delegates
     */
    function revokeAllDelegates() external;

    /**
     * @notice Revoke a specific delegate for all their permissions
     * @param delegate The hotwallet to revoke
     */
    function revokeDelegate(address delegate) external;

    /**
     * @notice Remove yourself as a delegate for a specific vault
     * @param vault The vault which delegated to the msg.sender, and should be removed
     */
    function revokeSelf(address vault) external;

    /**
     * -----------  READ -----------
     */

    /**
     * @notice Returns all active delegations a given delegate is able to claim on behalf of
     * @param delegate The delegate that you would like to retrieve delegations for
     * @return info Array of DelegationInfo structs
     */
    function getDelegationsByDelegate(address delegate) external view returns (DelegationInfo[] memory);

    /**
     * @notice Returns an array of wallet-level delegates for a given vault
     * @param vault The cold wallet who issued the delegation
     * @return addresses Array of wallet-level delegates for a given vault
     */
    function getDelegatesForAll(address vault) external view returns (address[] memory);

    /**
     * @notice Returns an array of contract-level delegates for a given vault and contract
     * @param vault The cold wallet who issued the delegation
     * @param contract_ The address for the contract you're delegating
     * @return addresses Array of contract-level delegates for a given vault and contract
     */
    function getDelegatesForContract(address vault, address contract_) external view returns (address[] memory);

    /**
     * @notice Returns an array of contract-level delegates for a given vault's token
     * @param vault The cold wallet who issued the delegation
     * @param contract_ The address for the contract holding the token
     * @param tokenId The token id for the token you're delegating
     * @return addresses Array of contract-level delegates for a given vault's token
     */
    function getDelegatesForToken(address vault, address contract_, uint256 tokenId)
        external
        view
        returns (address[] memory);

    /**
     * @notice Returns all contract-level delegations for a given vault
     * @param vault The cold wallet who issued the delegations
     * @return delegations Array of ContractDelegation structs
     */
    function getContractLevelDelegations(address vault)
        external
        view
        returns (ContractDelegation[] memory delegations);

    /**
     * @notice Returns all token-level delegations for a given vault
     * @param vault The cold wallet who issued the delegations
     * @return delegations Array of TokenDelegation structs
     */
    function getTokenLevelDelegations(address vault) external view returns (TokenDelegation[] memory delegations);

    /**
     * @notice Returns true if the address is delegated to act on the entire vault
     * @param delegate The hotwallet to act on your behalf
     * @param vault The cold wallet who issued the delegation
     */
    function checkDelegateForAll(address delegate, address vault) external view returns (bool);

    /**
     * @notice Returns true if the address is delegated to act on your behalf for a token contract or an entire vault
     * @param delegate The hotwallet to act on your behalf
     * @param contract_ The address for the contract you're delegating
     * @param vault The cold wallet who issued the delegation
     */
    function checkDelegateForContract(address delegate, address vault, address contract_)
        external
        view
        returns (bool);

    /**
     * @notice Returns true if the address is delegated to act on your behalf for a specific token, the token's contract or an entire vault
     * @param delegate The hotwallet to act on your behalf
     * @param contract_ The address for the contract you're delegating
     * @param tokenId The token id for the token you're delegating
     * @param vault The cold wallet who issued the delegation
     */
    function checkDelegateForToken(address delegate, address vault, address contract_, uint256 tokenId)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import '../interfaces/IDelegationRegistry.sol';

error NotAuthorizedForDelegation();

/**
 * @title NFTCDelegateEnforcer
 * @author @NFTCulture
 * @dev Enforce requirements for Delegate wallets.
 *
 * NFTC's opinionated approach to enforcing delegation via Delegate.Cash.
 *
 * @notice Delegate.cash has some quirks, execute transactions using this
 * service at your own risk.
 */
abstract contract NFTCDelegateEnforcer {
    // See: https://github.com/delegatecash/delegation-registry
    IDelegationRegistry public constant DELEGATION_REGISTRY =
        IDelegationRegistry(0x00000000000076A84feF008CDAbe6409d2FE638B);

    function _getOperatorFromDelegation(
        address caller,
        address coldWallet,
        address targetContract,
        uint256 theToken
    ) internal view returns (address) {
        if (coldWallet == address(0)) {
            // Cold wallet was not provided, so caller is only authorized to act as its own operator.
            return caller;
        }

        if (!DELEGATION_REGISTRY.checkDelegateForToken(caller, coldWallet, targetContract, theToken))
            revert NotAuthorizedForDelegation();

        // Caller is authorized to operate on behalf of coldWallet.
        return coldWallet;
    }
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
pragma solidity 0.8.17;

// NFTC Open Source Contracts See: https://github.com/NFTCulture/nftc-contracts
import '@nftculture/nftc-contracts/contracts/security/NFTCDelegateEnforcer.sol';

// NFTC Prerelease Contracts
import '@nftculture/nftc-contracts-private/contracts/token/IFlavorInfoProviderV2.sol';
import '@nftculture/nftc-contracts-private/contracts/token/IFlavorInfoValidatorV2.sol';

// OZ Libraries
import '@openzeppelin/contracts/interfaces/IERC721.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

/**
 * @title BannerDropOneProductList
 * @author @NFTCulture
 * @dev Reference implementation of a product list contract.
 */
contract BannerDropOneProductList is IFlavorInfoProviderV2, IFlavorInfoValidatorV2, NFTCDelegateEnforcer, Ownable {
    address private constant APE_ADDRESS = 0xA0C512e4522956EA1B7812eFC82d9B7f42Ac2d2C;
    address private constant CAT_ADDRESS = 0xe73e61C93F86071D942fb586Ca4e6Dc90bf285D5;

    mapping(address => mapping(uint256 => bool)) public minters;

    bool private immutable tokenValidatorsInitialized;

    IERC721 private exclusiveNft200001;
    IERC721 private exclusiveNft200002;

    constructor() {
        exclusiveNft200001 = IERC721(APE_ADDRESS);
        exclusiveNft200002 = IERC721(CAT_ADDRESS);

        tokenValidatorsInitialized = true;
    }

    /**
     * A sample flavor provider function. This one extends the default flavor list with an additional 13 flavors.
     */
    function provideFlavorInfos() external view override returns (FlavorInfoV2[] memory) {
        FlavorInfoV2[] memory initialFlavors = new FlavorInfoV2[](13);

        // General Banners.
        initialFlavors[0] = FlavorInfoV2(100001, 2000, 0, 0, address(0), .1 ether, 0, '');
        initialFlavors[1] = FlavorInfoV2(100002, 2000, 0, 0, address(0), .1 ether, 0, '');

        // Exclusive Banners for Apes
        initialFlavors[2] = FlavorInfoV2(200001, 1000, 0, 0, address(this), .2 ether, 0, '');

        // Exclusive Banner for Cats
        initialFlavors[3] = FlavorInfoV2(200002, 1000, 0, 0, address(this), .2 ether, 0, '');

        // Exclusive Banner for Apes and Cats
        initialFlavors[4] = FlavorInfoV2(200003, 100, 0, 0, address(this), .5 ether, 0, '');

        return initialFlavors;
    }

    /**
     * A sample mint validation function. This one will restrict to one mint
     * per wallet, and each wallet is capped to a max of two tokens purchased.
     *
     * @param caller The account that is executing the mint.
     * @param holder a cold wallet, if a delegation scheme is being used.
     * @param count - the amount of tokens being purchased
     * @param tokenFlavor - information about the token being purchased
     * @param validationData - placeholder for validationData if it is needed
     * @return - bool corresponding to the success or failure of the validation
     * @return - message to revert with if the validation fails.
     */
    function validateMint(
        address caller,
        address holder,
        uint256 count,
        FlavorInfoV2 memory tokenFlavor,
        uint256 validationData
    ) external override returns (bool, string memory) {
        /**
         * IMPORTANT: this will not currently work for crossmint. We need to add a special exception for the crossmint address.
         */
        if (minters[caller][tokenFlavor.flavorId]) return (false, 'Flavor already minted');
        if (count > 2) return (false, 'Count too large');

        (bool success, string memory message) = _approvedToMint(caller, holder, tokenFlavor.flavorId, validationData);

        if (success) {
            minters[caller][tokenFlavor.flavorId] = true;
        }

        return (success, message);
    }

    function eligibleForMint(
        address caller,
        address holder,
        uint256 flavorId,
        uint256 tokenId
    ) external view returns (bool, string memory) {
        return _approvedToMint(caller, holder, flavorId, tokenId);
    }

    function _approvedToMint(
        address caller,
        address holder,
        uint256 flavorId,
        uint256 tokenId
    ) internal view returns (bool, string memory) {
        address left;
        address right;

        if (tokenValidatorsInitialized) {
            if (flavorId == 200001) {
                left = _getOperatorFromDelegation(caller, holder, APE_ADDRESS, tokenId);
                right = exclusiveNft200001.ownerOf(tokenId);
                return (left == right, 'Operator not owner');
            }
            if (flavorId == 200002) {
                left = _getOperatorFromDelegation(caller, holder, CAT_ADDRESS, tokenId);
                right = exclusiveNft200002.ownerOf(tokenId);
                return (left == right, 'Operator not owner');
            }
            if (flavorId == 200003) {
                // Both contracts have to be delegated, or else this won't work.
                left = _getOperatorFromDelegation(caller, holder, APE_ADDRESS, tokenId);
                right = _getOperatorFromDelegation(caller, holder, CAT_ADDRESS, tokenId);

                return (
                    exclusiveNft200001.balanceOf(left) > 0 && exclusiveNft200002.balanceOf(right) > 0,
                    'Operator not owner'
                );
            }
        }

        return (true, '');
    }
}