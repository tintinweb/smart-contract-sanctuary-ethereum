// SPDX-License-Identifier: GPL-3.0

/// @title Interface for SVGRenderer

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

interface ISVGRenderer {
    struct Part {
        bytes image;
        bytes palette;
    }

    struct SVGParams {
        Part[] parts;
        string background;
    }

    function generateSVG(SVGParams memory params) external view returns (string memory svg);

    function generateSVGPart(Part memory part) external view returns (string memory partialSVG);

    function generateSVGParts(Part[] memory parts) external view returns (string memory partialSVG);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
pragma solidity 0.8.13;

/// @dev Interface for NounletProposal contract
interface INounletProposal {
    function cancel(uint256 _proposalId) external;

    function castVote(uint256 _proposalId, uint8 _support) external;

    function castVoteWithReason(
        uint256 _proposalId,
        uint8 _support,
        string calldata _reason
    ) external;

    function propose(
        address[] calldata _targets,
        uint256[] calldata _values,
        string[] calldata _signatures,
        bytes[] calldata _calldatas,
        string calldata _description
    ) external;
}

// SPDX-License-Identifier: GPL-3.0

/// @title Common interface for NounsDescriptor versions, as used by NounsToken and NounsSeeder.

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.13;

import {INounsSeeder} from "./INounsSeeder.sol";
import {ISVGRenderer} from "nouns-contracts/contracts/interfaces/ISVGRenderer.sol";

interface INounsDescriptor {
    function tokenURI(uint256 tokenId, INounsSeeder.Seed memory seed)
        external
        view
        returns (string memory);

    function dataURI(uint256 tokenId, INounsSeeder.Seed memory seed)
        external
        view
        returns (string memory);

    function backgroundCount() external view returns (uint256);

    function bodyCount() external view returns (uint256);

    function accessoryCount() external view returns (uint256);

    function headCount() external view returns (uint256);

    function glassesCount() external view returns (uint256);

    function genericDataURI(
        string calldata name,
        string calldata description,
        INounsSeeder.Seed memory seed
    ) external view returns (string memory);

    function renderer() external view returns (address);

    function art() external view returns (address);

    function getPartsForSeed(INounsSeeder.Seed memory seed)
        external
        view
        returns (ISVGRenderer.Part[] memory);
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for NounsSeeder

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.13;

import {INounsDescriptor} from "./INounsDescriptor.sol";

interface INounsSeeder {
    struct Seed {
        uint48 background;
        uint48 body;
        uint48 accessory;
        uint48 head;
        uint48 glasses;
    }

    function generateSeed(uint256 nounId, INounsDescriptor descriptor)
        external
        view
        returns (Seed memory);
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for NounsToken

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.13;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {INounsDescriptor} from "./INounsDescriptor.sol";
import {INounsSeeder} from "./INounsSeeder.sol";

interface INounsToken is IERC721 {
    event DescriptorLocked();

    event DescriptorUpdated(INounsDescriptor descriptor);

    event NounBurned(uint256 indexed tokenId);

    event NounCreated(uint256 indexed tokenId, INounsSeeder.Seed seed);

    event NoundersDAOUpdated(address noundersDAO);

    event MinterLocked();

    event MinterUpdated(address minter);

    event SeederLocked();

    event SeederUpdated(INounsSeeder seeder);

    function burn(uint256 tokenId) external;

    function dataURI(uint256 tokenId) external returns (string memory);

    function delegate(address delegatee) external;

    function descriptor() external returns (INounsDescriptor);

    function lockDescriptor() external;

    function lockMinter() external;

    function lockSeeder() external;

    function mint() external returns (uint256);

    function minter() external returns (address);

    function seeds(uint256) external view returns (INounsSeeder.Seed memory);

    function setDescriptor(INounsDescriptor descriptor) external;

    function setMinter(address minter) external;

    function setNoundersDAO(address noundersDAO) external;

    function setSeeder(INounsSeeder seeder) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {INounletProposal as IProposal} from "../interfaces/INounletProposal.sol";
import {INounsToken as INouns} from "../interfaces/INounsToken.sol";

/// @title NounletProposal
/// @author Tessera
/// @notice Target contract for executing proposal actions
contract NounletProposal is IProposal {
    /// @notice Address of NounsDAOProxy contract
    address public immutable nounsDAO;
    /// @notice Address of NounsToken contract
    address public immutable nounsToken;

    /// @dev Initializes address of NounsDAOProxy and NounsToken contracts
    constructor(address _nounsDAO, address _nounsToken) {
        nounsDAO = _nounsDAO;
        nounsToken = _nounsToken;
    }

    /// @notice Cancels a given proposal
    /// @param _proposalId ID of the proposal
    function cancel(uint256 _proposalId) external {
        IProposal(nounsDAO).cancel(_proposalId);
    }

    /// @notice Casts a vote on a given proposal
    /// @param _proposalId ID of the proposal
    /// @param _support Decision value for the vote (0=against, 1=for, 2=abstain)
    function castVote(uint256 _proposalId, uint8 _support) external {
        IProposal(nounsDAO).castVote(_proposalId, _support);
    }

    /// @notice Casts a vote on a given proposal with reason
    /// @param _proposalId ID of the proposal
    /// @param _support Decision value for the vote (0=against, 1=for, 2=abstain)
    /// @param _reason Reason given for voting decision
    function castVoteWithReason(
        uint256 _proposalId,
        uint8 _support,
        string calldata _reason
    ) external {
        IProposal(nounsDAO).castVoteWithReason(_proposalId, _support, _reason);
    }

    /// @notice Delegates voting power to a given address
    /// @param _delegatee Address of the delegatee
    function delegate(address _delegatee) external {
        INouns(nounsToken).delegate(_delegatee);
    }

    /// @notice Creates a new proposal
    /// @param _targets Target addresses for proposal calls
    /// @param _values Eth values for proposal calls
    /// @param _signatures Function signatures for proposal calls
    /// @param _calldatas Calldatas for proposal calls
    /// @param _description String description of the proposal
    function propose(
        address[] calldata _targets,
        uint256[] calldata _values,
        string[] calldata _signatures,
        bytes[] calldata _calldatas,
        string calldata _description
    ) external {
        IProposal(nounsDAO).propose(_targets, _values, _signatures, _calldatas, _description);
    }
}