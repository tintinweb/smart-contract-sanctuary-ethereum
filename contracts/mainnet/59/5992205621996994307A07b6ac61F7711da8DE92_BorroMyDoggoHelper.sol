// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "./lib/IBAYCSewerPassClaim.sol";
import "./lib/IDelegationRegistry.sol";

contract BorroMyDoggoHelper {
    address constant public SEWER_PASS_CLAIM = 0xBA5a9E9CBCE12c70224446C24C111132BECf9F1d;
    address constant public BAYC = 0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D;
    address constant public MAYC = 0x60E4d786628Fea6478F785A6d7e704777c86a7c6;
    address constant public BAKC = 0xba30E5F9Bb24caa003E9f2f0497Ad287FDF95623;
    address constant public BORRO_MY_DOGGO = 0x56B61e063f0f662588655F27B1175F4aAEBD7251;
    IDelegationRegistry delegateCash = IDelegationRegistry(0x00000000000076A84feF008CDAbe6409d2FE638B);

    struct TokenStatus {
        uint16 tokenId;
        bool delegated;
        bool claimed;
    }

    function baycTokens(address operator) external view returns(TokenStatus[] memory tokens) {
        TokenStatus[] memory tmpTokens = new TokenStatus[](512);
        uint256 statusIndex = 0;
        uint256 tmpTokenId;
        uint256[] memory checked = new uint256[](40);
        uint256 balance = IERC721(BAYC).balanceOf(operator);
        for(uint256 tokenIndex = 0;tokenIndex < balance;tokenIndex++) {
            TokenStatus memory ts = getTokenStatus(operator, BAYC, IERC721Enumerable(BAYC).tokenOfOwnerByIndex(operator, tokenIndex));
            checked[(ts.tokenId>>8)] |= (1 << (ts.tokenId & 0xff));
            tmpTokens[statusIndex] = ts;
            statusIndex++;
        }
        IDelegationRegistry.DelegationInfo[] memory di = delegateCash.getDelegationsByDelegate(operator);
        for(uint256 i = 0;i < di.length;i++) {
            if(di[i].type_ == IDelegationRegistry.DelegationType.ALL || (di[i].type_ == IDelegationRegistry.DelegationType.CONTRACT && di[i].contract_ == BAYC)) {
                balance = IERC721(BAYC).balanceOf(di[i].vault);
                for(uint256 tokenIndex = 0;tokenIndex < balance;tokenIndex++) {
                    tmpTokenId = IERC721Enumerable(BAYC).tokenOfOwnerByIndex(di[i].vault, tokenIndex);
                    if((checked[(tmpTokenId>>8)] & (1 << (tmpTokenId & 0xff))) == 0) {
                        TokenStatus memory ts = getTokenStatus(di[i].vault, BAYC, tmpTokenId);
                        checked[(ts.tokenId>>8)] |= (1 << (ts.tokenId & 0xff));
                        tmpTokens[statusIndex] = ts;
                        statusIndex++;
                    }
                }
            } else if(di[i].type_ == IDelegationRegistry.DelegationType.TOKEN && di[i].contract_ == BAYC) {
                tmpTokenId = di[i].tokenId;
                if((checked[(tmpTokenId>>8)] & (1 << (tmpTokenId & 0xff))) == 0) {
                    TokenStatus memory ts = getTokenStatus(di[i].vault, BAYC, tmpTokenId);
                    checked[(ts.tokenId>>8)] |= (1 << (ts.tokenId & 0xff));
                    tmpTokens[statusIndex] = ts;
                    statusIndex++;
                }
            }
        }
        tokens = new TokenStatus[](statusIndex);
        for(uint256 i = 0;i < tokens.length;i++) {
            tokens[i] = tmpTokens[i];
        }
    }

    function maycTokens(address operator) external view returns(TokenStatus[] memory tokens) {
        TokenStatus[] memory tmpTokens = new TokenStatus[](512);
        uint256 statusIndex = 0;
        uint256 tmpTokenId;
        uint256[] memory checked = new uint256[](160);
        uint256 balance = IERC721(MAYC).balanceOf(operator);
        for(uint256 tokenIndex = 0;tokenIndex < balance;tokenIndex++) {
            TokenStatus memory ts = getTokenStatus(operator, MAYC, IERC721Enumerable(MAYC).tokenOfOwnerByIndex(operator, tokenIndex));
            checked[(ts.tokenId>>8)] |= (1 << (ts.tokenId & 0xff));
            tmpTokens[statusIndex] = ts;
            statusIndex++;
        }
        IDelegationRegistry.DelegationInfo[] memory di = delegateCash.getDelegationsByDelegate(operator);
        for(uint256 i = 0;i < di.length;i++) {
            if(di[i].type_ == IDelegationRegistry.DelegationType.ALL || (di[i].type_ == IDelegationRegistry.DelegationType.CONTRACT && di[i].contract_ == MAYC)) {
                balance = IERC721(MAYC).balanceOf(di[i].vault);
                for(uint256 tokenIndex = 0;tokenIndex < balance;tokenIndex++) {
                    tmpTokenId = IERC721Enumerable(MAYC).tokenOfOwnerByIndex(di[i].vault, tokenIndex);
                    if((checked[(tmpTokenId>>8)] & (1 << (tmpTokenId & 0xff))) == 0) {
                        TokenStatus memory ts = getTokenStatus(di[i].vault, MAYC, tmpTokenId);
                        checked[(ts.tokenId>>8)] |= (1 << (ts.tokenId & 0xff));
                        tmpTokens[statusIndex] = ts;
                        statusIndex++;
                    }
                }
            } else if(di[i].type_ == IDelegationRegistry.DelegationType.TOKEN && di[i].contract_ == MAYC) {
                tmpTokenId = di[i].tokenId;
                if((checked[(tmpTokenId>>8)] & (1 << (tmpTokenId & 0xff))) == 0) {
                    TokenStatus memory ts = getTokenStatus(di[i].vault, MAYC, tmpTokenId);
                    checked[(ts.tokenId>>8)] |= (1 << (ts.tokenId & 0xff));
                    tmpTokens[statusIndex] = ts;
                    statusIndex++;
                }
            }
        }
        tokens = new TokenStatus[](statusIndex);
        for(uint256 i = 0;i < tokens.length;i++) {
            tokens[i] = tmpTokens[i];
        }
    }

    function bakcTokens(address operator) external view returns(TokenStatus[] memory tokens) {
        TokenStatus[] memory tmpTokens = new TokenStatus[](512);
        uint256 statusIndex = 0;
        uint256 tmpTokenId;
        uint256[] memory checked = new uint256[](80);
        uint256 balance = IERC721(BAKC).balanceOf(operator);
        for(uint256 tokenIndex = 0;tokenIndex < balance;tokenIndex++) {
            TokenStatus memory ts = getTokenStatus(operator, BAKC, IERC721Enumerable(BAKC).tokenOfOwnerByIndex(operator, tokenIndex));
            checked[(ts.tokenId>>8)] |= (1 << (ts.tokenId & 0xff));
            tmpTokens[statusIndex] = ts;
            statusIndex++;
        }
        IDelegationRegistry.DelegationInfo[] memory di = delegateCash.getDelegationsByDelegate(operator);
        for(uint256 i = 0;i < di.length;i++) {
            if(di[i].type_ == IDelegationRegistry.DelegationType.ALL || (di[i].type_ == IDelegationRegistry.DelegationType.CONTRACT && di[i].contract_ == BAKC)) {
                balance = IERC721(BAKC).balanceOf(di[i].vault);
                for(uint256 tokenIndex = 0;tokenIndex < balance;tokenIndex++) {
                    tmpTokenId = IERC721Enumerable(BAKC).tokenOfOwnerByIndex(di[i].vault, tokenIndex);
                    if((checked[(tmpTokenId>>8)] & (1 << (tmpTokenId & 0xff))) == 0) {
                        TokenStatus memory ts = getTokenStatus(di[i].vault, BAKC, tmpTokenId);
                        checked[(ts.tokenId>>8)] |= (1 << (ts.tokenId & 0xff));
                        tmpTokens[statusIndex] = ts;
                        statusIndex++;
                    }
                }
            } else if(di[i].type_ == IDelegationRegistry.DelegationType.TOKEN && di[i].contract_ == BAKC) {
                tmpTokenId = di[i].tokenId;
                if((checked[(tmpTokenId>>8)] & (1 << (tmpTokenId & 0xff))) == 0) {
                    TokenStatus memory ts = getTokenStatus(di[i].vault, BAKC, tmpTokenId);
                    checked[(ts.tokenId>>8)] |= (1 << (ts.tokenId & 0xff));
                    tmpTokens[statusIndex] = ts;
                    statusIndex++;
                }
            }
        }
        tokens = new TokenStatus[](statusIndex);
        for(uint256 i = 0;i < tokens.length;i++) {
            tokens[i] = tmpTokens[i];
        }
    }

    function getTokenStatus(address vault, address contract_, uint256 tokenId) internal view returns(TokenStatus memory ts) {
        ts.tokenId = uint16(tokenId);
        ts.delegated = delegateCash.checkDelegateForToken(BORRO_MY_DOGGO, vault, contract_, ts.tokenId);
        ts.claimed = IBAYCSewerPassClaim(SEWER_PASS_CLAIM).checkClaimed((contract_ == BAYC ? 0 : contract_ == MAYC ? 1 : 2), ts.tokenId);
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.17;

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
pragma solidity ^0.8.17;

interface IBAYCSewerPassClaim {
    function claimBaycBakc(uint256 baycTokenId, uint256 bakcTokenId) external;
    function claimBayc(uint256 baycTokenId) external;
    function claimMaycBakc(uint256 maycTokenId, uint256 bakcTokenId) external;
    function claimMayc(uint256 maycTokenId) external;
    function checkClaimed(uint8 collectionId, uint256 tokenId) external view returns (bool);
    function bakcClaimed(uint256 doggoId) external view returns (bool);
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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