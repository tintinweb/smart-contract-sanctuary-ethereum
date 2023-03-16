// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ICrossDomainMessenger} from "@eth-optimism/contracts/libraries/bridge/ICrossDomainMessenger.sol";

import "../L2/interface/IL2TokenClaimBridge.sol";
import "./interface/IL1EventLogger.sol";
import "./interface/IL1TokenClaimBridge.sol";
import "../lib/storage/L1TokenClaimBridgeStorage.sol";
import "../lib/crosschain/CrosschainOrigin.sol";
import "./interface/ICreatorRegistry.sol";

contract L1TokenClaimBridge is IL1TokenClaimBridge {
    modifier onlyNftCreator(address canonicalNft_, uint256 tokenId_) {
        require(
            ICreatorRegistry(L1TokenClaimBridgeStorage.get().creatorRegistry)
                .getCreatorOf(canonicalNft_, tokenId_) == msg.sender,
            "Message sender did not create NFT"
        );
        _;
    }

    modifier onlyNftsCreator(
        address[] calldata canonicalNfts_,
        uint256[] calldata tokenIds_
    ) {
        require(
            canonicalNfts_.length > 0 &&
                tokenIds_.length > 0 &&
                canonicalNfts_.length == tokenIds_.length,
            "NFT inputs are malformed"
        );

        for (uint8 i = 0; i < canonicalNfts_.length; i++) {
            require(
                ICreatorRegistry(
                    L1TokenClaimBridgeStorage.get().creatorRegistry
                ).getCreatorOf(canonicalNfts_[i], tokenIds_[i]) == msg.sender,
                "Message sender did not create at least one given NFT"
            );
        }
        _;
    }

    constructor(
        address l1EventLogger_,
        address l2TokenClaimBridge_,
        address creatorRegistry_
    ) {
        L1TokenClaimBridgeStorage.get().l1EventLogger = l1EventLogger_;
        L1TokenClaimBridgeStorage
            .get()
            .l2TokenClaimBridge = l2TokenClaimBridge_;
        L1TokenClaimBridgeStorage.get().creatorRegistry = creatorRegistry_;
    }

    function claimEtherForMultipleNfts(
        address[] calldata canonicalNfts_,
        uint256[] calldata tokenIds_,
        address payable beneficiary_,
        uint256[] calldata amounts_
    ) external override onlyNftsCreator(canonicalNfts_, tokenIds_) {
        require(
            amounts_.length == canonicalNfts_.length,
            "canonicalNfts_, tokenIds_, and amounts_ must be same length"
        );

        bytes memory message = abi.encodeCall(
            IL2TokenClaimBridge(address(0)).claimEtherForMultipleNfts,
            (canonicalNfts_, tokenIds_, beneficiary_, amounts_)
        );

        ICrossDomainMessenger(CrosschainOrigin.crossDomainMessenger())
            .sendMessage(
                L1TokenClaimBridgeStorage.get().l2TokenClaimBridge,
                message,
                1920000
            );

        IL1EventLogger(L1TokenClaimBridgeStorage.get().l1EventLogger)
            .emitClaimEtherForMultipleNftsMessageSent(
                keccak256(abi.encodePacked(canonicalNfts_)),
                keccak256(abi.encodePacked(tokenIds_)),
                beneficiary_
            );
    }

    function markReplicasAsAuthentic(address canonicalNft_, uint256 tokenId_)
        external
        override
        onlyNftCreator(canonicalNft_, tokenId_)
    {
        bytes memory message = abi.encodeCall(
            IL2TokenClaimBridge(address(0)).markReplicasAsAuthentic,
            (canonicalNft_, tokenId_)
        );

        ICrossDomainMessenger(CrosschainOrigin.crossDomainMessenger())
            .sendMessage(
                L1TokenClaimBridgeStorage.get().l2TokenClaimBridge,
                message,
                1000000
            );

        IL1EventLogger(L1TokenClaimBridgeStorage.get().l1EventLogger)
            .emitMarkReplicasAsAuthenticMessageSent(canonicalNft_, tokenId_);
    }

    function l2TokenClaimBridge() external view override returns (address) {
        return L1TokenClaimBridgeStorage.get().l2TokenClaimBridge;
    }

    function l1EventLogger() external view override returns (address) {
        return L1TokenClaimBridgeStorage.get().l1EventLogger;
    }

    function creatorRegistry() external view override returns (address) {
        return L1TokenClaimBridgeStorage.get().creatorRegistry;
    }
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
pragma solidity >0.5.0 <0.9.0;

/**
 * @title ICrossDomainMessenger
 */
interface ICrossDomainMessenger {
    /**********
     * Events *
     **********/

    event SentMessage(
        address indexed target,
        address sender,
        bytes message,
        uint256 messageNonce,
        uint256 gasLimit
    );
    event RelayedMessage(bytes32 indexed msgHash);
    event FailedRelayedMessage(bytes32 indexed msgHash);

    /*************
     * Variables *
     *************/

    function xDomainMessageSender() external view returns (address);

    /********************
     * Public Functions *
     ********************/

    /**
     * Sends a cross domain message to the target messenger.
     * @param _target Target contract address.
     * @param _message Message to send to the target.
     * @param _gasLimit Gas limit for the provided message.
     */
    function sendMessage(
        address _target,
        bytes calldata _message,
        uint32 _gasLimit
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./IHomageProtocolConfigView.sol";

interface IL2TokenClaimBridge is IHomageProtocolConfigView {
    function initialize(address homageProtocolConfig_) external;

    function claimEtherForMultipleNfts(
        address[] calldata canonicalNfts_,
        uint256[] calldata tokenIds_,
        address payable beneficiary_,
        uint256[] calldata claimAmounts_
    ) external returns (uint256);

    function markReplicasAsAuthentic(address canonicalNft_, uint256 tokenId_)
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "../../shared/interface/IEventLogger.sol";

interface IL1EventLogger is IEventLogger {
    function emitClaimEtherForMultipleNftsMessageSent(
        bytes32 canonicalNftsHash_,
        bytes32 tokenIdsHash_,
        address beneficiary_
    ) external;

    function emitMarkReplicasAsAuthenticMessageSent(
        address canonicalNft_,
        uint256 tokenId_
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IL1TokenClaimBridge {
    function claimEtherForMultipleNfts(
        address[] calldata canonicalNfts_,
        uint256[] calldata tokenIds_,
        address payable beneficiary_,
        uint256[] calldata amounts_
    ) external;

    function markReplicasAsAuthentic(address canonicalNft_, uint256 tokenId_)
        external;

    function l2TokenClaimBridge() external view returns (address);

    function l1EventLogger() external view returns (address);

    function creatorRegistry() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

library L1TokenClaimBridgeStorage {
    bytes32 constant STORAGE_POSITION = keccak256("homage.l1TokenClaimBridge");

    struct Struct {
        address l1EventLogger;
        address l2TokenClaimBridge;
        address creatorRegistry;
    }

    function get() internal pure returns (Struct storage storageStruct) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            storageStruct.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

// Reference: https://github.com/ethereum-optimism/optimism-tutorial/blob/main/cross-dom-comm/contracts/Greeter.sol

import {ICrossDomainMessenger} from "@eth-optimism/contracts/libraries/bridge/ICrossDomainMessenger.sol";

library CrosschainOrigin {
    function crossDomainMessenger() internal view returns (address cdmAddr) {
        // Get the cross domain messenger's address each time.
        // This is less resource intensive than writing to storage.

        if (block.chainid == 1)
            cdmAddr = 0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1;

        // Goerli
        if (block.chainid == 5)
            cdmAddr = 0x5086d1eEF304eb5284A0f6720f79403b4e9bE294;

        // Kovan
        if (block.chainid == 42)
            cdmAddr = 0x4361d0F75A0186C05f971c566dC6bEa5957483fD;

        // L2
        if (block.chainid == 10 || block.chainid == 420 || block.chainid == 69)
            cdmAddr = 0x4200000000000000000000000000000000000007;

        // Local L1 (pre-Bedrock)
        if (block.chainid == 31337) {
            cdmAddr = 0x8A791620dd6260079BF849Dc5567aDC3F2FdC318;
        }

        // Local L1 (Bedrock)
        if (block.chainid == 900) {
            cdmAddr = 0x6900000000000000000000000000000000000002;
        }

        // Local L2 (pre-Bedrock)
        if (block.chainid == 987) {
            cdmAddr = 0x4200000000000000000000000000000000000007;
        }

        // Local L2 (Bedrock)
        if (block.chainid == 901) {
            cdmAddr = 0x4200000000000000000000000000000000000007;
        }
    }

    function getCrosschainMessageSender() internal view returns (address) {
        // Get the cross domain messenger's address each time.
        // This is less resource intensive than writing to storage.
        address cdmAddr = crossDomainMessenger();

        // If this isn't a cross domain message
        if (msg.sender != cdmAddr) {
            revert("Not crosschain call");
        }

        // If it is a cross domain message, find out where it is from
        return ICrossDomainMessenger(cdmAddr).xDomainMessageSender();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface ICreatorRegistry {
    function getCreatorOf(address nftContract_, uint256 tokenId_)
        external
        view
        returns (address);
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
pragma solidity ^0.8.12;

interface IHomageProtocolConfigView {
    function homageProtocolConfig() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IEventLogger {
    function emitReplicaDeployed(address replica_) external;

    function emitReplicaTransferred(
        uint256 canonicalTokenId_,
        uint256 replicaTokenId_
    ) external;

    function emitReplicaRegistered(
        address canonicalNftContract_,
        uint256 canonicalTokenId_,
        address replica_
    ) external;
}