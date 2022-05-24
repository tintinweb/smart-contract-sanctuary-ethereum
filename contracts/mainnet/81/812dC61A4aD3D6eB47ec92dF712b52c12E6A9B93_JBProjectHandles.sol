// SPDX-License-Identifier: MIT

/// @title JBProjectHandles
/// @author peri
/// @notice Manages reverse records that point from JB project IDs to ENS nodes. If the reverse record of a project ID is pointed to an ENS node with a TXT record matching the ID of that project, then the ENS node will be considered the "handle" for that project.

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "./interfaces/IJBProjectHandles.sol";
import "./interfaces/ITextResolver.sol";

contract JBProjectHandles is IJBProjectHandles {
    /* -------------------------------------------------------------------------- */
    /* ------------------------------- MODIFIERS -------------------------------- */
    /* -------------------------------------------------------------------------- */

    /// @notice Require that caller owns this Juicebox project
    /// @param projectId id of Juicebox project
    modifier onlyProjectOwner(uint256 projectId) {
        require(
            msg.sender == IERC721(jbProjects).ownerOf(projectId),
            "Not Juicebox project owner"
        );
        _;
    }

    /* -------------------------------------------------------------------------- */
    /* ------------------------------ CONSTRUCTOR ------------------------------- */
    /* -------------------------------------------------------------------------- */

    constructor(address _jbProjects, address _ensTextResolver) {
        jbProjects = _jbProjects;
        ensTextResolver = _ensTextResolver;
    }

    /* -------------------------------------------------------------------------- */
    /* ------------------------------- VARIABLES -------------------------------- */
    /* -------------------------------------------------------------------------- */

    string constant KEY = "JUICEBOX";

    /// JB Projects contract address
    address immutable jbProjects;

    /// ENS text resolver contract address
    address immutable ensTextResolver;

    /// Point from project ID to ENS node
    mapping(uint256 => bytes32) reverseRecords;

    /* -------------------------------------------------------------------------- */
    /* --------------------------- EXTERNAL FUNCTIONS --------------------------- */
    /* -------------------------------------------------------------------------- */

    /// @notice Set reverse record for Juicebox project
    /// @dev Requires sender to own Juicebox project
    /// @param projectId id of Juicebox project
    /// @param record new reverse record for Juicebox project
    function setReverseRecord(uint256 projectId, bytes32 record)
        external
        onlyProjectOwner(projectId)
    {
        reverseRecords[projectId] = record;

        emit SetReverseRecord(projectId, record);
    }

    /// @notice Returns reverse record of Juicebox project
    /// @param projectId id of Juicebox project
    function reverseRecordOf(uint256 projectId)
        public
        view
        returns (bytes32 reverseRecord)
    {
        reverseRecord = reverseRecords[projectId];
    }

    /// @notice Returns handle for Juicebox project
    /// @dev Requires ENS TXT record to match projectId
    /// @param projectId id of Juicebox project
    function handleOf(uint256 projectId) public view returns (bytes32) {
        bytes32 reverseRecord = reverseRecordOf(projectId);

        require(reverseRecord != bytes32(0), "No reverse record");

        string memory id = ITextResolver(ensTextResolver).text(
            reverseRecord,
            KEY
        );

        require(stringToUint(id) == projectId, "Invalid TXT record");

        return reverseRecord;
    }

    /* -------------------------------------------------------------------------- */
    /* --------------------------- INTERNAL FUNCTIONS --------------------------- */
    /* -------------------------------------------------------------------------- */

    /// @notice Converts string to uint256
    /// @param str string to be converted
    function stringToUint(string memory str)
        internal
        pure
        returns (uint256 _result)
    {
        bytes memory _data = bytes(str);
        uint256 count = 0;
        for (uint256 i = _data.length; i > 0; i--) {
            _result |= uint256(uint8(_data[i - 1])) << ((count++) * 8);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT

/// @title Interface for JBProjectHandles

pragma solidity ^0.8.0;

interface IJBProjectHandles {
    event SetReverseRecord(uint256 indexed projectId, bytes32 indexed record);

    function setReverseRecord(uint256 projectId, bytes32 record) external;

    function reverseRecordOf(uint256 projectId)
        external
        view
        returns (bytes32 reverseRecord);

    function handleOf(uint256 projectId) external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

// https://github.com/ensdomains/ens-contracts/blob/master/contracts/resolvers/profiles/ITextResolver.sol

interface ITextResolver {
    event TextChanged(
        bytes32 indexed node,
        string indexed indexedKey,
        string key
    );

    /**
     * Returns the text data associated with an ENS node and key.
     * @param node The ENS node to query.
     * @param key The text data key to query.
     * @return The associated text data.
     */
    function text(bytes32 node, string calldata key)
        external
        view
        returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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