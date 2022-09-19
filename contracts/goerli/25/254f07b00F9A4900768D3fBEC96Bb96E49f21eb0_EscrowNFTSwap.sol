// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

contract EscrowNFTSwap is ReentrancyGuard,ERC721Holder {
    struct ListedToken {
        address owner;
        address contractAddr;
        uint tokenId;
        string description;
    }

    ListedToken[] public listedTokens;

    mapping (address => uint[]) public ownerTokens;

    // For convenience
    mapping (address => mapping (uint256 => uint)) public tokenIndexInOwnerTokens;

    struct Offer {
        address offerer;
        uint requestedIndex;
        uint offeredIndex;
        int exchangeValue;
        uint expires;
    }

    Offer[] public offers;

    event TokenListed(uint indexed listedId,address indexed owner,address indexed contractAddr, uint256 tokenId, string description);
    event TokenUnlisted(uint indexed listedId,address indexed contractAddr, uint256 indexed tokenId);
    event OfferMade(uint indexed offerId,uint256 indexed requestedListedId,uint256 indexed offeredListedId, int exchangeValue, uint expires);
    event OfferTaken(uint indexed offerId,address takenContractAddr, uint256 takenTokenId, address givenContractAddr, uint256 givenTokenId, int exchangeValue);
    event OfferCancelled(uint indexed offerId,address requestedContractAddr, uint256 requestedTokenId, address offeredContractAddr, uint256 offeredTokenId, int exchangeValue, uint expires);

    constructor () {
        listedTokens.push(ListedToken({
            owner: address(0),
            contractAddr: address(0),
            tokenId: 0,
            description: ""
        }));
    }
    

    function escrowToken(address _contractAddr, uint256 _tokenId, string memory _description) external nonReentrant{

        uint listedTokenIndex = listedTokens.length;
        listedTokens.push(ListedToken({
            owner: msg.sender,
            contractAddr: _contractAddr,
            tokenId: _tokenId,
            description: _description
        }));

        // push returns the new length of the array, so listed token is at index-1
        uint ownerTokenIndex = ownerTokens[msg.sender].length;
        ownerTokens[msg.sender].push(listedTokenIndex);
        tokenIndexInOwnerTokens[_contractAddr][_tokenId] = ownerTokenIndex;

        // This requires the token to be approved which should be handled by the UI
        IERC721(_contractAddr).safeTransferFrom(msg.sender, address(this), _tokenId);

        emit TokenListed((listedTokenIndex),msg.sender,_contractAddr, _tokenId, _description);
    }

    function withdrawToken(uint _listedTokenIndex) external nonReentrant {
        ListedToken storage withdrawnListedToken = listedTokens[_listedTokenIndex];
        require(withdrawnListedToken.owner == msg.sender);

        if (tokenIndexInOwnerTokens[withdrawnListedToken.contractAddr][withdrawnListedToken.tokenId] != ownerTokens[msg.sender].length - 1) {
            uint movedListedTokenIndex = ownerTokens[msg.sender][ownerTokens[msg.sender].length - 1];

            ownerTokens[msg.sender][tokenIndexInOwnerTokens[withdrawnListedToken.contractAddr][withdrawnListedToken.tokenId]] = movedListedTokenIndex;

            // Update moved token's index in owner tokens
            ListedToken storage movedListedToken = listedTokens[movedListedTokenIndex];
            tokenIndexInOwnerTokens[movedListedToken.contractAddr][movedListedToken.tokenId]
                = tokenIndexInOwnerTokens[withdrawnListedToken.contractAddr][withdrawnListedToken.tokenId];
        }

        ownerTokens[msg.sender].pop;
        delete tokenIndexInOwnerTokens[withdrawnListedToken.contractAddr][withdrawnListedToken.tokenId];

        IERC721(withdrawnListedToken.contractAddr).safeTransferFrom(address(this),msg.sender, withdrawnListedToken.tokenId);

        emit TokenUnlisted(_listedTokenIndex,withdrawnListedToken.contractAddr, withdrawnListedToken.tokenId);

        delete listedTokens[_listedTokenIndex];
    }

    // Makes an offer for the token listed at _requestedIndex for the token listed at _offeredIndex
    function makeOffer(uint _requestedIndex, uint _offeredIndex, int _exchangeValue, uint _expiresIn) external nonReentrant payable returns (uint) {
        // exchangeValue is the amount of funds which is offered part of the deal. Can be positive or negative.
        // If it's positive, the exact amount must have been send with this transaction
        require(_exchangeValue <= 0 || msg.value == uint(_exchangeValue));

        require(_exchangeValue >= 0 || msg.value == 0);

        require(_expiresIn > 0);

        ListedToken storage requestedToken = listedTokens[_requestedIndex];

        // Can not make offers to non-listed token
        require(requestedToken.owner != address(0));

        ListedToken storage offeredToken = listedTokens[_offeredIndex];

        require(offeredToken.owner == msg.sender);

        uint index = offers.length;
        offers.push(Offer({
            offerer: msg.sender,
            requestedIndex: _requestedIndex,
            offeredIndex: _offeredIndex,
            exchangeValue: _exchangeValue,
            expires: block.number + _expiresIn
        }));

        emit OfferMade((index),_requestedIndex, _offeredIndex, _exchangeValue, block.number + _expiresIn);

        return index;
    }

    // Makes an offer for the token listed at _requestedIndex with the sent funds (without offering a token in return)
    function makeOfferWithFunds(uint _requestedIndex, uint _expiresIn) external nonReentrant payable returns (uint) {
        require(_expiresIn > 0);

        ListedToken storage requestedToken = listedTokens[_requestedIndex];

        // Can not make offers to delisted token
        require(requestedToken.owner != address(0));

        uint index = offers.length;
        offers.push(Offer({
            offerer: msg.sender,
            requestedIndex: _requestedIndex,
            offeredIndex: 0,                 // 0 means no token is offered (listed token id's start from 1, see constructor)
            exchangeValue: int(msg.value),   // Exchange value is equal to the amount sent
            expires: block.number + _expiresIn
        }));

        emit OfferMade((index),_requestedIndex, 0, int(msg.value), block.number + _expiresIn);

        return index;
    }

    function takeOffer(uint _offerId) external nonReentrant payable {
        Offer storage offer = offers[_offerId];
        require(offer.expires > block.number);

        // Negative exchangeValue means offerer wants to receive funds in part of the deal
        // In that case the exact amount of funds must have been send
        require(offer.exchangeValue >= 0 || msg.value == uint(-offer.exchangeValue));

        // If exchangeValue is greater than or equal to 0, no funds accepted
        require(offer.exchangeValue < 0 || msg.value == 0);

        ListedToken storage givenToken = listedTokens[offer.requestedIndex];
        require(givenToken.owner == msg.sender);

        givenToken.owner = offer.offerer;

        uint givenTokenIndex = tokenIndexInOwnerTokens[givenToken.contractAddr][givenToken.tokenId];

        ListedToken storage takenToken = listedTokens[offer.offeredIndex];

        // If this is a "cash-only" offer
        if (takenToken.owner == address(0)) {  // We are actually checking if null
            uint toBeMovedTokenIndex = ownerTokens[msg.sender].length - 1;

            if (givenTokenIndex != toBeMovedTokenIndex) {
                ownerTokens[msg.sender][givenTokenIndex] = ownerTokens[msg.sender][toBeMovedTokenIndex];

                ListedToken storage toBeMovedToken = listedTokens[ownerTokens[msg.sender][toBeMovedTokenIndex]];
                tokenIndexInOwnerTokens[toBeMovedToken.contractAddr][toBeMovedToken.tokenId] = givenTokenIndex;
            }

            ownerTokens[msg.sender].pop;

            uint newIndex = ownerTokens[offer.offerer].length;
            ownerTokens[offer.offerer].push(offer.requestedIndex);
            tokenIndexInOwnerTokens[givenToken.contractAddr][givenToken.tokenId] = newIndex;

            payable(msg.sender).transfer(uint(offer.exchangeValue));

            emit OfferTaken(_offerId,address(0), 0, givenToken.contractAddr, givenToken.tokenId, offer.exchangeValue);
        } else { // Cash only offer
            takenToken.owner = msg.sender;

            uint takenTokenIndex = tokenIndexInOwnerTokens[takenToken.contractAddr][takenToken.tokenId];

            uint temp = ownerTokens[msg.sender][givenTokenIndex];
            ownerTokens[msg.sender][givenTokenIndex] = ownerTokens[offer.offerer][takenTokenIndex];
            ownerTokens[offer.offerer][takenTokenIndex] = temp;

            temp = tokenIndexInOwnerTokens[givenToken.contractAddr][givenToken.tokenId];
            tokenIndexInOwnerTokens[givenToken.contractAddr][givenToken.tokenId] =
                tokenIndexInOwnerTokens[takenToken.contractAddr][takenToken.tokenId];
            tokenIndexInOwnerTokens[takenToken.contractAddr][takenToken.tokenId] = temp;

            // Transfer exchange value if required. If the value is 0, no funds are transferred
            if (offer.exchangeValue > 0) {
                // We have positive value, meaning offerer pays
                payable(msg.sender).transfer(uint(offer.exchangeValue));
            } else if (offer.exchangeValue < 0) {
                // We have negative value, meaning offerer receives
                payable(offer.offerer).transfer(uint(-offer.exchangeValue));
            }

            emit OfferTaken(_offerId,takenToken.contractAddr, takenToken.tokenId, givenToken.contractAddr, givenToken.tokenId, offer.exchangeValue);
        }

        // Remove offer since it's taken
        delete offers[_offerId];
    }

    // This does not remove the approval of the token
    function cancelOffer(uint _offerId) external nonReentrant {
        Offer storage offer = offers[_offerId];
        require(offer.offerer == msg.sender);

        // Refund to offerer if exchangeValue is greater than 0, which means offerer sent it when making the offer
        if (offer.exchangeValue > 0) {
            payable(offer.offerer).transfer(uint(offer.exchangeValue));
        }

        ListedToken storage requestedToken = listedTokens[offer.requestedIndex];
        ListedToken storage offeredToken = listedTokens[offer.offeredIndex];

        emit OfferCancelled(_offerId,requestedToken.contractAddr, requestedToken.tokenId, offeredToken.contractAddr, offeredToken.tokenId, offer.exchangeValue, offer.expires);

        delete offers[_offerId];
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

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