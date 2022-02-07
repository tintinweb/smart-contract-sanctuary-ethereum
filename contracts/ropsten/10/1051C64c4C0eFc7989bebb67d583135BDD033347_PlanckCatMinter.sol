// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "ERC721Holder.sol";
import "IPlanckCat.sol";

contract PlanckCatMinter is ERC721Holder {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // planck cat NFT contract
    address public immutable pcd;

    // whether id is claimable by address
    mapping(uint256 => mapping(address => bool)) public claimable;
    // ids that have been escrowed
    mapping(address => uint256[]) public escrowed;
    // number remaining to be claimed
    mapping(address => uint256) public count;

    // events
    event Mint(address indexed to, uint256 id);
    event Claim(address indexed by, uint256 id);

    constructor(address _pcd) {
        pcd = _pcd;
    }

    modifier onlyMinter() {
        require(IPlanckCat(pcd).hasRole(MINTER_ROLE, msg.sender), "!minter");
        _;
    }

    /// @notice bulk mint new planck cats for claiming
    /// @dev mints to this planck cat minter contract first to avoid security
    /// @dev issues with ERC721 call back. After all are minted,
    /// @dev users can call claim() function. Technically the callback
    /// @dev shouldn't affect us given the onlyMinter modifier, but still.
    function mintBatch(uint256 currentId, address[] memory tos) external onlyMinter {
        require(isCurrentId(currentId), "!currentId");

        // loop through and safe mint to this address. track who
        // can claim which minted NFT thru claimable
        address _pcd = pcd;
        for (uint256 i = 0; i < tos.length; i++) {
            address to = tos[i];

            // mark as claimable and record escrowed id
            claimable[currentId][to] = true;
            escrowed[to].push(currentId);
            count[to]++;

            // emit mint event
            emit Mint(to, currentId);

            // increment current id counter
            currentId++;

            // mint to this address
            IPlanckCat(_pcd).safeMint(address(this));
        }
    }

    /// @notice bulk mint new custom planck cats for claiming
    /// @dev mints to this planck cat minter contract first to avoid security
    /// @dev issues with ERC721 call back. After all are minted,
    /// @dev users can call claim() function. Technically the callback
    /// @dev shouldn't affect us given the onlyMinter modifier, but still.
    function mintCustomBatch(
        uint256 currentId,
        address[] memory tos,
        string[] memory uris
    ) external onlyMinter {
        require(tos.length == uris.length, "tos != uris");
        require(isCurrentId(currentId), "!currentId");

        // loop through and safe mint to this address. track who
        // can claim which minted NFT thru claimable
        address _pcd = pcd;
        for (uint256 i = 0; i < tos.length; i++) {
            address to = tos[i];
            string memory uri = uris[i];

            // mark as claimable and record escrowed id
            claimable[currentId][to] = true;
            escrowed[to].push(currentId);
            count[to]++;

            // emit mint event
            emit Mint(to, currentId);

            // increment current id counter
            currentId++;

            // mint to this address
            IPlanckCat(_pcd).safeMintCustom(address(this), uri);
        }
    }

    /// @notice claim planck cat by ID
    function claim(uint256 id) external {
        address _pcd = pcd;

        // check can actually claim id
        require(claimable[id][msg.sender], "!claimable");

        // mark escrowed as claimed
        claimable[id][msg.sender] = false;
        count[msg.sender]--;

        // emit claim event
        emit Claim(msg.sender, id);

        // transfer escrowed to msg.sender
        IPlanckCat(_pcd).safeTransferFrom(address(this), msg.sender, id, "");
    }

    /// @notice check whether currentId is the ID of the next cat to be minted
    /// @dev IPlanckCat(_pcd)_tokenIdCounter.current() == currentId
    function isCurrentId(uint256 currentId) public view returns (bool) {
        address _pcd = pcd;

        // Gameplan: tokenURI(currentId) should revert on call to PCD BUT
        // tokenURI(currentId-1) should not IF isCurrentId(currentId) == true
        string memory nonexistentReason = "ERC721Metadata: URI query for nonexistent token";
        try IPlanckCat(_pcd).tokenURI(currentId) returns (string memory) {
            // if URI already exists, then not the current id
            return false;
        } catch Error(string memory reason) {
            if (currentId == 0) {
                return true;
            } else if (keccak256(bytes(reason)) == keccak256(bytes(nonexistentReason))) {
                // currentId hasn't been minted yet. Now check that
                // currentId - 1 has been minted, so we know currentId is the
                // next ID
                try IPlanckCat(_pcd).tokenURI(currentId - 1) returns (string memory) {
                    // last minted ID was currentId-1, so currentId is actually the current id
                    return true;
                } catch {}
            }
        }
        return false;
    }

    /// @notice returns IDs that can still be claimed for by
    function canClaim(address by) external view returns (uint256[] memory can_) {
        uint256[] memory ids = escrowed[by];
        can_ = new uint256[](count[by]);

        uint256 idx;
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            if (claimable[id][by]) {
                can_[idx] = id;
                idx++;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "IERC721.sol";
import "IAccessControl.sol";

interface IPlanckCat is IERC721, IAccessControl {
    function safeMint(address to) external;

    function safeMintCustom(address to, string memory _customURI) external;

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}