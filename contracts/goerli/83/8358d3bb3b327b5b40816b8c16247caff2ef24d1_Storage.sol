/**
 *Submitted for verification at Etherscan.io on 2023-01-13
*/

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

// File: contracts/1_Storage.sol



pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts

 
 */


contract Storage {

    uint256 number;

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) public {
        number = num;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }

    struct Booster {
        IERC721 collectionBooster;
        uint256 tokenId;
    }

     struct VaultPayload {
        uint256 poolId;
        address user;
        uint256 nonce;
        uint256[] tokenIdForPrimary;
        Booster[] booster;
        uint256 amountUmadValueOrNftValue;
        uint256 topUpUmadValue;
        uint256 APR;
        bytes _signature;
    }


    function getSignerForPayload(
        bytes32 domain,
       VaultPayload memory payload
    ) public pure returns ( bytes32) {
        // merge booster
        bytes32[] memory mergedBooster = new bytes32[](payload.booster.length);

        for (uint256 i = 0; i < payload.booster.length; ) {
            mergedBooster[i] = keccak256(
                abi.encodePacked(
                    payload.booster[i].collectionBooster,
                    payload.booster[i].tokenId
                )
            );
            unchecked {
                i++;
            }
        }
        bytes32 hashMessage = keccak256(
            abi.encodePacked(
                domain,
                payload.poolId,
                payload.user,
                payload.nonce,
                payload.tokenIdForPrimary,
                mergedBooster,
                payload.amountUmadValueOrNftValue,
                payload.topUpUmadValue,
                payload.APR
            )
        );
        return 
            hashMessage
        ;
    }

     enum UnStakeType {
        NFT,
        UMADVALUE,
        TOPUP
    }

       struct UnStakeCardPayload {
        UnStakeType unstakeType;
        uint256 vaultIndex;
        uint256 poolId;
        address user;
        uint256 nonce;
        uint256[] tokenIdForPrimary;
        uint256[] indexForPrimary;
        Booster[] booster;
        uint256[] indexForBooster;
        uint256 amountUmadValueUnStakeOrNftValueUnStake;
        uint256 topUpUmadValue;
        uint256 APR;
        bytes _signature;
    }

    function getSignerForUnstakePayload(
        bytes32 domain,
        UnStakeCardPayload memory payload
    ) public pure returns ( bytes32) {
        bytes32 hashMessage;
        if (payload.unstakeType == UnStakeType.NFT) {
            bytes32[] memory mergedBooster = new bytes32[](
                payload.booster.length
            );

            for (uint256 i = 0; i < payload.booster.length; ) {
                mergedBooster[i] = keccak256(
                    abi.encodePacked(
                        payload.booster[i].collectionBooster,
                        payload.booster[i].tokenId
                    )
                );
                unchecked {
                    i++;
                }
            }
            hashMessage = keccak256(
                abi.encodePacked(
                    domain,
                    payload.unstakeType,
                    payload.vaultIndex,
                    payload.poolId,
                    payload.user,
                    payload.nonce,
                    payload.tokenIdForPrimary,
                    mergedBooster,
                    payload.APR,
                    payload.amountUmadValueUnStakeOrNftValueUnStake
                )
            );
        } else if (
            payload.unstakeType == UnStakeType.UMADVALUE
        ) {
            hashMessage = keccak256(
                abi.encodePacked(
                    domain,
                    payload.unstakeType,
                    payload.vaultIndex,
                    payload.poolId,
                    payload.user,
                    payload.nonce,
                    payload.amountUmadValueUnStakeOrNftValueUnStake,
                    payload.APR
                )
            );
        } else if (payload.unstakeType == UnStakeType.TOPUP) {
            hashMessage = keccak256(
                abi.encodePacked(
                    domain,
                    payload.unstakeType,
                    payload.vaultIndex,
                    payload.poolId,
                    payload.user,
                    payload.nonce,
                    payload.topUpUmadValue,
                    payload.APR,
                    payload.amountUmadValueUnStakeOrNftValueUnStake
                )
            );
        }
        return 
           
            hashMessage
        ;
    }

  

    
}