//            //-----------\\
//          //       | |   | \\
//        //  \__   /   \ /  | \\
//       ||       \|     |  / __||
//       ||         \    | |_/  ||
//       ||\     __  |   |/ __  ||
//       ||  \__/   \|   |_/  \_||
//       ||  _    ___|  /  \_   ||
//       ||_/ \__/   |/_     \_/||
//       ||          o  \      _||
//       ||\       / |    \___/ ||
//       ||  \___/   |     \   /||
//       ||     |   / \_    )-<_||
//       ||    /  /     \  /    ||
//        \\ /   |      _><    //
//        //\\   |     /   \ //\\
//       ||   \\-----------//   ||
//       ||                     ||
//      /||\                   /||\
//     /____\                 /____\

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface ICabinet is IERC1155 {
    function create(
        address initialOwner,
        uint256 totalTokenSupply,
        string calldata tokenUri,
        bytes calldata data
    ) external returns (uint256);
}

contract EnchantedMirror {
    event VictimTrapped(
        uint256 victimId,
        address victimAddress,
        uint256 culprit,
        address culpritAddress
    );
    event VictimSaved(
        uint256 victim,
        address victimAddress,
        uint256 savior,
        address saviorAddress
    );
    event MirrorBroken(uint256 breakerId, address breakerAddress);
    event ShardFound(
        string code,
        uint256 finderId,
        address finderAddress,
        uint256 indexed counter,
        address owner
    );

    struct Epoch {
        mapping(string => bool) codesUsed;
        address[] pastOwners;
        uint256 allShardsFoundTimestamp;
        bool mirrorBroken;
    }

    /**
     * Keeps track of number of breaking - repairing epochs
     */
    uint256 public counter = 0;
    uint256 private constant MAX_INT = 2**256 - 1;
    uint256 public victimId = MAX_INT;

    uint256 public claimPrice = 0.013 ether;

    uint256 public TOTAL_SHARDS;

    uint256 public shardId = MAX_INT;

    address public victimAddress;

    address wizardsAddress;
    address poniesAddress;
    address soulsAddress;
    address warriorsAddress;
    address cabinetAddress;
    address managerAddress;

    bytes32 public merkleRoot;

    uint16 public shardsFound;
    uint8 public constant LORB_ID = 0;
    uint8 public constant MIRROR_ID = 1;

    mapping(uint256 => Epoch) public epochs;

    constructor(
        address _cabinetAddress,
        address _wizardsAddress,
        address _soulsAddress,
        address _warriorsAddress,
        address _poniesAddress,
        uint256 _totalShards
    ) {
        cabinetAddress = _cabinetAddress;
        wizardsAddress = _wizardsAddress;
        soulsAddress = _soulsAddress;
        warriorsAddress = _warriorsAddress;
        poniesAddress = _poniesAddress;
        TOTAL_SHARDS = _totalShards;
    }

    /**
     * The manager is the owner of the Mirror token, making the game
     * contract a tradable asset.
     */
    modifier onlyManager() {
        require(
            IERC1155(cabinetAddress).balanceOf(msg.sender, MIRROR_ID) == 1,
            "You are not the owner of the Enchanted Mirror"
        );
        if (managerAddress != msg.sender) {
            managerAddress = msg.sender;
        }
        _;
    }

    /**
     * breaking the mirror starts the game, by issuing the shards. Can only break
     * a non-broken mirror, a wizard has to be trapped inside, and only a wizard,
     * warrior, soul or pony can break the mirror.
     */
    function breakMirror(uint256 breakerId, address breakerAddress) external {
        require(!epochs[counter].mirrorBroken, "mirror is already broken");
        require(
            victimId != MAX_INT,
            "The mirror without a victim trapped is just an illusion"
        );
        string memory breakerAssetType = _getAssetType(breakerAddress);
        require(
            keccak256(abi.encodePacked(breakerAssetType)) !=
                keccak256(abi.encodePacked("invalid")) &&
                IERC721(breakerAddress).ownerOf(breakerId) == msg.sender,
            "Only creatures of the Runiverse can break the mirror"
        );
        epochs[counter].mirrorBroken = true;

        shardId = ICabinet(cabinetAddress).create(
            address(this),
            TOTAL_SHARDS,
            "ipfs://Qmbphxjagw1YDg3VWvhSZq2Uo3AErF1qC6HsVm48ncH914",
            ""
        );

        emit MirrorBroken(breakerId, breakerAddress);
    }

    function updatePastOwners(address account) external {
        require(
            msg.sender == cabinetAddress,
            "unauthorized to update past owners"
        );
        epochs[counter].pastOwners.push(account);
    }

    function getPastOwners(uint256 epoch)
        external
        view
        returns (address[] memory)
    {
        return epochs[epoch].pastOwners;
    }

    /**
     * A broken mirror can only be repaired by a wizard or a soul.
     * The repairer with the most shards can repair the mirror.
     * Repairing the mirror frees the trapped victim, and the caller
     * becomes its owner, and the owner of the mirror.
     */
    function repairMirror(uint256 repairerId, address repairerAddress) public {
        require(epochs[counter].mirrorBroken, "The mirror is not broken");
        require(shardsFound == TOTAL_SHARDS, "Not all shards were found");
        address _wizardsAddress = wizardsAddress;
        bool isWizardOrSoul = repairerAddress == _wizardsAddress ||
            repairerAddress == soulsAddress;
        require(
            isWizardOrSoul &&
                IERC721(repairerAddress).ownerOf(repairerId) == msg.sender,
            "Only magicians can fix the mirror"
        );

        bool isRepairerBiggestHolder = true;
        uint256[] memory ids = new uint256[](epochs[counter].pastOwners.length);
        for (uint256 i = 0; i < ids.length; ++i) {
            ids[i] = shardId;
        }
        uint256[] memory shardBalance = IERC1155(cabinetAddress).balanceOfBatch(
            epochs[counter].pastOwners,
            ids
        );
        uint256 repairerBalance = IERC1155(cabinetAddress).balanceOf(
            msg.sender,
            shardId
        );
        for (uint256 i = 0; i < epochs[counter].pastOwners.length; ++i) {
            if (shardBalance[i] > repairerBalance) {
                isRepairerBiggestHolder = false;
                break;
            }
        }

        require(isRepairerBiggestHolder, "Repairer has to own the most shards");
        require(
            block.timestamp > epochs[counter].allShardsFoundTimestamp + 2 days,
            "two days has to pass after finding all shards"
        );

        // if any funds are left, transfer to the current manager
        payable(managerAddress).call{value: address(this).balance}("");

        // the mirror goes to the wizard who repaired it
        IERC1155(cabinetAddress).safeTransferFrom(
            managerAddress,
            msg.sender,
            MIRROR_ID,
            1,
            ""
        );
        IERC721(_wizardsAddress).safeTransferFrom(
            address(this),
            msg.sender,
            victimId
        );

        emit VictimSaved(victimId, victimAddress, repairerId, repairerAddress);
        epochs[counter].mirrorBroken = false;
        victimId = MAX_INT;
        victimAddress = address(0);
        shardsFound = 0;
        counter++;
    }

    /**
     * Claim shards by finding the codes which scattered across
     * the runiverse. Only broken mirrors have shards, and each
     * code can be used once.
     */
    function claimShard(
        string calldata code,
        bytes32[] calldata proof,
        address finderAddress,
        uint256 finderId
    ) external payable {
        require(epochs[counter].mirrorBroken, "The mirror is not broken");
        require(
            _verify(_leaf(code), proof),
            "Don't try to temper with magic you don't fully understand"
        );
        string memory finderAssetType = _getAssetType(finderAddress);
        require(
            keccak256(abi.encodePacked(finderAssetType)) !=
                keccak256(abi.encodePacked("invalid")) &&
                IERC721(finderAddress).ownerOf(finderId) == msg.sender,
            "Only creatures of the Runiverse can find the shards"
        );
        Epoch storage epoch = epochs[counter];
        require(
            epoch.codesUsed[code] == false,
            "This shard of the mirror has been already found"
        );
        require(msg.value >= claimPrice, "Ether value sent is not sufficient");
        epoch.codesUsed[code] = true;
        IERC1155(cabinetAddress).safeTransferFrom(
            address(this),
            msg.sender,
            shardId,
            1,
            ""
        );

        shardsFound++;

        if (shardsFound == TOTAL_SHARDS) {
            epoch.allShardsFoundTimestamp = block.timestamp;
        }

        emit ShardFound(code, finderId, finderAddress, counter, msg.sender);
    }

    /**
     * A wizard or a soul can use the mirror to trap a victim, which can be a wizard
     * or a warrior. The mirror may be broken, in which case all shards have to be
     * found to repair it and free the trapped victim.
     */
    function trap(
        uint256 _victimId,
        address _victimAddress,
        uint256 _culpritId,
        address _culpritAddress
    ) external onlyManager {
        address _wizardsAddress = wizardsAddress;

        bool _isVictimWizard = _victimAddress == _wizardsAddress;
        bool _isCulpritWizard = _culpritAddress == _wizardsAddress;

        require(
            (_isVictimWizard || _victimAddress == warriorsAddress) &&
                IERC721(_victimAddress).ownerOf(_victimId) == msg.sender,
            "Can only trap a wizard or a warrior"
        );
        require(
            (_isCulpritWizard || _culpritAddress == soulsAddress) &&
                IERC721(_culpritAddress).ownerOf(_culpritId) == msg.sender,
            "Only a wizard or a soul can use the mirror"
        );

        require(victimId == MAX_INT, "There's a victim already trapped");

        IERC721(wizardsAddress).transferFrom(
            msg.sender,
            address(this),
            _victimId
        );

        victimAddress = _victimAddress;
        victimId = _victimId;
        emit VictimTrapped(
            _victimId,
            _victimAddress,
            _culpritId,
            _culpritAddress
        );
    }

    function _getAssetType(address contractAddress)
        internal
        view
        returns (string memory)
    {
        return
            contractAddress == wizardsAddress
                ? "wizard"
                : contractAddress == warriorsAddress
                ? "warrior"
                : contractAddress == soulsAddress
                ? "soul"
                : contractAddress == poniesAddress
                ? "pony"
                : "invalid";
    }

    function _leaf(string calldata code) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(code));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof)
        internal
        view
        returns (bool)
    {
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyManager {
        merkleRoot = _merkleRoot;
    }

    function setClaimPrice(uint256 _claimPrice) external onlyManager {
        require(
            !epochs[counter].mirrorBroken,
            "Cannot set price when mirror is broken"
        );
        claimPrice = _claimPrice;
    }

    function withdraw() external onlyManager {
        (bool sent, ) = payable(msg.sender).call{value: address(this).balance}(
            ""
        );
        require(sent, "Failure, ETH not sent");
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
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