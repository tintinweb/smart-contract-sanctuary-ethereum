// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "../Structs/structs.sol";

/**
 * the Vault is a contract that can lock a batch of nfts and transfer them together
 */
contract Vault {
    using Counters for Counters.Counter;

    Counters.Counter private _VaultCounter;

    mapping(uint256 => VaultInfo) public Vaults;

    /// @dev lock NFTs and create a new Vault for these nfts
    /// @notice only support erc721 nfts for now
    /// @notice need nft token approve first
    /// @param from nft's owner address
    /// @param tokens nft contract addresses
    /// @param tokenIDs nft tokenIds
    function lockNFTsAndCreateVaultFrom(
        address from,
        address[] memory tokens,
        uint256[] memory tokenIDs
    ) public returns (uint256) {
        _VaultCounter.increment();
        uint256 VaultId = _VaultCounter.current();
        Vaults[VaultId].VaultId = VaultId;
        Vaults[VaultId].owner = msg.sender;
        lockNFTs(from, tokens, tokenIDs, VaultId);
        return VaultId;
    }

    function lockNFTsAndCreateVault(
        address[] memory tokens,
        uint256[] memory tokenIDs
    ) public {
        uint256 VaultId = lockNFTsAndCreateVaultFrom(
            msg.sender,
            tokens,
            tokenIDs
        );
        Vaults[VaultId].owner = msg.sender;
    }

    /**
     * do real lock actions
     */
    function lockNFTs(
        address owner,
        address[] memory tokens,
        uint256[] memory tokenIDs,
        uint256 VaultId
    ) private {
        require(tokens.length == tokenIDs.length, "args not fit");
        for (uint8 i = 0; i < tokens.length; i++) {
            require(
                ERC165(tokens[i]).supportsInterface(type(IERC721).interfaceId),
                "must support the ERC721 interface"
            );
            require(
                IERC721(tokens[i]).getApproved(tokenIDs[i]) == address(this) ||
                    IERC721(tokens[i]).isApprovedForAll(owner, address(this)),
                "need token approve"
            );
        }

        for (uint8 i = 0; i < tokens.length; i++) {
            IERC721(tokens[i]).safeTransferFrom(
                owner,
                address(this),
                tokenIDs[i]
            );
            Vaults[VaultId].inVaultNFTs[i] = inVaultNFTInfo(
                VaultId,
                i,
                tokens[i],
                tokenIDs[i],
                false
            );
        }
        Vaults[VaultId].inVaultNum = uint8(tokens.length);
    }

    /**
     * get the number of nfts inside the Vault
     */
    function getInVaultNum(uint256 VaultId) public view returns (uint8) {
        return Vaults[VaultId].inVaultNum;
    }

    /**
     * get the owner of a Vault
     */
    function getOwner(uint256 VaultId) public view returns (address) {
        return Vaults[VaultId].owner;
    }

    /**
     * get the latest generated Vault's id
     */
    function getCurrentVaultId() public view returns (uint256) {
        return _VaultCounter.current();
    }

    /**
     * transfer the Vault's owner to a new address
     */
    function transferVaultOwner(uint256 VaultId, address newOwner)
        public
        onlyOwner(VaultId)
    {
        Vaults[VaultId].owner = newOwner;
    }

    /**
     * unlock the nft inside a Vault to some address by the Vault owner only
     */
    function unlockNFT(
        address to,
        uint256 VaultId,
        uint8 nftIndex
    ) public onlyOwner(VaultId) {
        IERC721(Vaults[VaultId].inVaultNFTs[nftIndex].contractAddress)
            .safeTransferFrom(
                address(this),
                to,
                Vaults[VaultId].inVaultNFTs[nftIndex].tokenId
            );
        Vaults[VaultId].inVaultNFTs[nftIndex].redeemed = true;
    }

    function onERC721Received(
        address operator,
        address,
        uint256,
        bytes calldata
    ) external view returns (bytes4) {
        require(
            operator == address(this),
            "can only lock tokens via lockNFT method"
        );
        return type(IERC721Receiver).interfaceId;
    }

    modifier onlyOwner(uint256 VaultId) {
        require(
            msg.sender == Vaults[VaultId].owner,
            "you dot have the permission"
        );
        _;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

struct PTokenInfo {
    uint256 VaultId;
    uint8 inVaultNum;
    address creator;
    address verifiedOwner;
    address PTokenContract;
}

struct proptoEventCustomIdGroup {
    address proptoEventContract;
    uint256 customId;
    uint256[] tokenIds;
    uint256[] insuranceAmounts;
    address[] beneficiaries;
    uint256[] reverseTokenIds;
    uint256[] reverseInsuranceAmounts;
    address[] reverseBeneficiaries;
}

struct incomingReservesDetail {
    uint256 amount;
    bool collected;
}

struct outgoingIPTokenDetail {
    uint256 amount;
    bool collected;
}

struct insurancePay {
    address proptoEventContract;
    uint256 tokenId;
    uint256 customId;
    uint256 insuranceAmount;
    address beneficiary;
    bool direction;
    uint8 collected;
}

struct RoundLockRangeUnit {
    uint256 rangeStart;
    uint256 rangeAmount;
}

struct RoundLockReservesBatchInfo {
    uint256 batchRangeTotal;
    uint256 batchLockedAmount;
    uint256 batchLockedMaximum;
    uint256 batchRangesUnitNum;
    uint256 dataIndex;
}

struct RoundLockReservesBatchData {
    mapping(uint256 => RoundLockRangeUnit) RoundLockRangeUnits;
}

struct RoundLockReserves {
    uint256 totalLockedAmount;
    mapping(uint256 => RoundLockReservesBatchInfo) batchInfos;
    mapping(uint256 => RoundLockReservesBatchData) batchDatas;
    uint256 batchesNum;
}

struct keyVerifications {
    uint256 pendingVerificationKeyNumbers;
    uint256 startRange;
    uint256[] tokenIds;
    uint256[] keys;
}

struct customIdVerification {
    uint256 VRFMachineIndex;
    uint256 VRFIndex;
}

struct inVaultNFTInfo {
    uint256 VaultId;
    uint8 nftIndex;
    address contractAddress;
    uint256 tokenId;
    bool redeemed;
}

struct VaultInfo {
    uint256 VaultId;
    uint8 inVaultNum;
    address owner;
    address creator;
    bool locked;
    mapping(uint8 => inVaultNFTInfo) inVaultNFTs;
}

struct Goods {
    address owner;
    uint256 price;
    uint256 initialAmount;
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