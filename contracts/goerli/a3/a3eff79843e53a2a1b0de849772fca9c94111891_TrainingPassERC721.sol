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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {IERC721} from "openzeppelin-contracts/token/ERC721/IERC721.sol";
import {IERC165} from "openzeppelin-contracts/utils/introspection/IERC165.sol";
import {ERC165} from "openzeppelin-contracts/utils/introspection/ERC165.sol";

/// @title  A custom ERC-721 implementation for soulbound tokens
/// @author RaceDev
/// @notice An ERC-721 token that cannot be transferred, or sold
/// @dev    Heavily inspired by Solmate's ERC721 and Party DAO's CrowdfundNFT
abstract contract SoulBoundERC721 is ERC165, IERC721 {
    string public name;

    string public symbol;

    mapping(uint256 => address) internal _owners;

    /*//////////////////////////////////////////////
                        E R R O R S
    //////////////////////////////////////////////*/

    error SoulBound();

    error AlreadyBurnedError(address owner, uint256 tokenId);

    error InvalidTokenError(uint256 tokenId);

    error AlreadyMintedError(address owner, uint256 tokenId);

    /*//////////////////////////////////////////////
                    M O D I F I E R S
    //////////////////////////////////////////////*/

    modifier soulBound() {
        revert SoulBound();
        _; // Compiler requires this.
    }

    /*//////////////////////////////////////////////
                C O N S T R U C T O R
    //////////////////////////////////////////////*/
    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////
                        E R C 7 2 1
    //////////////////////////////////////////////*/

    /// @notice Returns a URI to render the NFT.
    function tokenURI(uint256 tokenId) public view virtual returns (string memory);

    function balanceOf(address owner) external view returns (uint256 numTokens) {
        return _doesTokenExistFor(owner) ? 1 : 0;
    }

    /// @notice Returns the owner of a given ID
    function ownerOf(uint256 tokenId) public view returns (address owner) {
        owner = _owners[tokenId];
        if (owner == address(0)) {
            revert InvalidTokenError(tokenId);
        }
    }

    /*//////////////////////////////////////////////
                   S O U L   B O N D I N G
    //////////////////////////////////////////////*/

    /// @notice NB: Don't call. Token is Soulbound - this will fail.
    function transferFrom(
        address,
        address,
        uint256
    ) external soulBound {}

    /// @notice NB: Don't call. Token is Soulbound - this will fail.
    function safeTransferFrom(
        address,
        address,
        uint256
    ) external soulBound {}

    /// @notice NB: Don't call. Token is Soulbound - this will fail.
    function safeTransferFrom(
        address,
        address,
        uint256,
        bytes calldata
    ) external soulBound {}

    /// @notice NB: Don't call. Token is Soulbound - this will fail.
    function approve(address, uint256) external soulBound {}

    /// @notice NB: Don't call. Token is Soulbound - this will fail.
    function setApprovalForAll(address, bool) external soulBound {}

    /// @notice NB: Don't call. Token is Soulbound - this will fail.
    function getApproved(uint256) external pure returns (address) {
        return address(0);
    }

    /// @notice This is a soulbound NFT and cannot be transferred.
    ///         Attempting to call this function will always return false.
    function isApprovedForAll(address, address) external pure returns (bool) {
        return false;
    }

    /*//////////////////////////////////////////////
                    C O M P L I A N C E
    //////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId || super.supportsInterface(interfaceId);
    }

    /*//////////////////////////////////////////////
                    I N T E R N A L
    //////////////////////////////////////////////*/

    /// @dev    No need to increment a tokenId, as each owner address
    ///         will generate a unique tokenId.
    function _mint(address owner) internal returns (uint256 tokenId) {
        tokenId = _addressToTokenId(owner);

        // TODO: not 100% about this logic, could the owners Id ever contain
        // a different address?
        if (_owners[tokenId] != owner) {
            _owners[tokenId] = owner;
            emit Transfer(address(0), owner, tokenId);
        } else {
            revert AlreadyMintedError(owner, tokenId);
        }
    }

    function _burn(address owner) internal {
        uint256 tokenId = _addressToTokenId(owner);
        if (_owners[tokenId] == owner) {
            delete _owners[tokenId];
            emit Transfer(owner, address(0), tokenId);
            return;
        }
        revert AlreadyBurnedError(owner, tokenId);
    }

    /*//////////////////////////////////////////////
                        U T I L S
    //////////////////////////////////////////////*/

    function _doesTokenExistFor(address owner) internal view returns (bool) {
        return _owners[_addressToTokenId(owner)] != address(0);
    }

    function _addressToTokenId(address user) internal pure returns (uint256 tokenId) {
        tokenId = uint256(uint160(user));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {SoulBoundERC721} from "./SoulboundERC721.sol";

/// @title  A Soulbound Training Pass ERC721 for the EXR ecosystem
/// @author RacerDev
/// @notice The Training Pass is a utility NFT and can only be airdropped to someone
///         who holds at least one Pilot, one Racecraft, and one Booster
/// @dev    Users cannot mint for themselves - passes can only be airdropped by an authorized user
/// @dev    Tokens cannot be sold or transferred, but can be burned by the user
/// @dev    All tokens in this contract share the `sharedUri` as the `tokenURI`
/// @dev    Token IDs are not sequential and are derived from each user's address, therefore unique

contract TrainingPassERC721 is SoulBoundERC721 {
    // the metadata uri shared by every token
    string private sharedUri;

    // the contract owner, ie. super admin
    address private immutable owner;

    // stores authorized users (capable of airdropping/minting)
    mapping(address => bool) private _authorized;

    // keeps track of which tokens (by user) have been burned
    mapping(address => bool) private _burned;

    /*//////////////////////////////////////////////
                        E R R O R S
    //////////////////////////////////////////////*/

    error NotAuthorized();

    error OnlyOwner();

    error NotTokenOwner();

    error TokenAlreadyBurned();

    /*//////////////////////////////////////////////
                    M O D I F I E R S
    //////////////////////////////////////////////*/

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert OnlyOwner();
        }
        _;
    }

    modifier onlyAuthorized() {
        if (!_authorized[msg.sender]) revert NotAuthorized();
        _;
    }

    /*//////////////////////////////////////////////
                C O N S T R U C T O R
    //////////////////////////////////////////////*/

    constructor(
        string memory name_,
        string memory symbol_,
        string memory uri_
    ) SoulBoundERC721(name_, symbol_) {
        owner = msg.sender;
        sharedUri = uri_;
    }

    /*//////////////////////////////////////////////
                C O N V E N I E N C E
    //////////////////////////////////////////////*/

    /// @notice convenience function to check if an address is an authorized user
    function isAuthorizedUser(address user) external view returns (bool) {
        return _authorized[user];
    }

    function hasUserBurnedToken(address user) external view returns (bool) {
        return _burned[user];
    }

    /*//////////////////////////////////////////////
                    M E T A D A T A
    //////////////////////////////////////////////*/

    /// @notice Returns the metadata URI for a given token ID
    /// @dev    All tokens return the same `sharedUri`
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (_owners[tokenId] == address(0)) {
            revert InvalidTokenError(tokenId);
        }
        return sharedUri;
    }

    /*//////////////////////////////////////////////
                U S E R   F U N C T I O N S
    //////////////////////////////////////////////*/

    /// @notice Burns the soulbound token. Cannot be reclaimed once burned.
    /// @dev    Marks the token as burned in `_burned` so it cannot be reminted.
    function burn() external {
        uint256 id = _addressToTokenId(msg.sender);
        if (msg.sender != _owners[id]) revert NotTokenOwner();
        _burned[msg.sender] = true;
        _burn(msg.sender);
    }

    /*//////////////////////////////////////////////
                    A U T H O R I Z E D
    //////////////////////////////////////////////*/

    /// @notice Airdrops a token to a user.
    /// @dev    Can only be minted/airdroped by an authorized user.
    function airdrop(address user) external onlyAuthorized returns (uint256 tokenId) {
        if (_burned[user]) {
            revert TokenAlreadyBurned();
        }
        tokenId = _mint(user);
    }

    /*//////////////////////////////////////////////
                        O W N E R
    //////////////////////////////////////////////*/

    /// @notice Adds an authorized user to the contract.
    /// @dev    Only authorized users can mint/airdrop tokens.
    function addAuthorizedUser(address user) external onlyOwner {
        _authorized[user] = true;
    }

    /// @notice Removes an authorized user from the contract.
    function removeAuthorizedUser(address user) external onlyOwner {
        _authorized[user] = false;
    }

    /// @notice Updates the metadata URI
    function updateURI(string memory newUri_) external onlyOwner {
        sharedUri = newUri_;
    }
}