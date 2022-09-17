// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173Internal } from './IERC173Internal.sol';

/**
 * @title Contract ownership standard interface
 * @dev see https://eips.ethereum.org/EIPS/eip-173
 */
interface IERC173 is IERC173Internal {
    /**
     * @notice get the ERC173 contract owner
     * @return conrtact owner
     */
    function owner() external view returns (address);

    /**
     * @notice transfer contract ownership to new account
     * @param account address of new owner
     */
    function transferOwnership(address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC173 interface needed by internal functions
 */
interface IERC173Internal {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title ERC165 interface registration interface
 * @dev see https://eips.ethereum.org/EIPS/eip-165
 */
interface IERC165 {
    /**
     * @notice query whether contract has registered support for given interface
     * @param interfaceId interface id
     * @return bool whether interface is supported
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20Internal } from './IERC20Internal.sol';

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 is IERC20Internal {
    /**
     * @notice query the total minted token supply
     * @return token supply
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice query the token balance of given account
     * @param account address to query
     * @return token balance
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @notice query the allowance granted from given holder to given spender
     * @param holder approver of allowance
     * @param spender recipient of allowance
     * @return token allowance
     */
    function allowance(address holder, address spender)
        external
        view
        returns (uint256);

    /**
     * @notice grant approval to spender to spend tokens
     * @dev prefer ERC20Extended functions to avoid transaction-ordering vulnerability (see https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729)
     * @param spender recipient of allowance
     * @param amount quantity of tokens approved for spending
     * @return success status (always true; otherwise function should revert)
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @notice transfer tokens to given recipient
     * @param recipient beneficiary of token transfer
     * @param amount quantity of tokens to transfer
     * @return success status (always true; otherwise function should revert)
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @notice transfer tokens to given recipient on behalf of given holder
     * @param holder holder of tokens prior to transfer
     * @param recipient beneficiary of token transfer
     * @param amount quantity of tokens to transfer
     * @return success status (always true; otherwise function should revert)
     */
    function transferFrom(
        address holder,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC20 interface needed by internal functions
 */
interface IERC20Internal {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165 } from '../../introspection/IERC165.sol';
import { IERC721Internal } from './IERC721Internal.sol';

/**
 * @title ERC721 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721 is IERC721Internal, IERC165 {
    /**
     * @notice query the balance of given address
     * @return balance quantity of tokens held
     */
    function balanceOf(address account) external view returns (uint256 balance);

    /**
     * @notice query the owner of given token
     * @param tokenId token to query
     * @return owner token owner
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @notice transfer token between given addresses, checking for ERC721Receiver implementation if applicable
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId token id
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @notice transfer token between given addresses, checking for ERC721Receiver implementation if applicable
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId token id
     * @param data data payload
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;

    /**
     * @notice transfer token between given addresses, without checking for ERC721Receiver implementation if applicable
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId token id
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @notice grant approval to given account to spend token
     * @param operator address to be approved
     * @param tokenId token to approve
     */
    function approve(address operator, uint256 tokenId) external payable;

    /**
     * @notice get approval status for given token
     * @param tokenId token to query
     * @return operator address approved to spend token
     */
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    /**
     * @notice grant approval to or revoke approval from given account to spend all tokens held by sender
     * @param operator address to be approved
     * @param status approval status
     */
    function setApprovalForAll(address operator, bool status) external;

    /**
     * @notice query approval status of given operator with respect to given address
     * @param account address to query for approval granted
     * @param operator address to query for approval received
     * @return status whether operator is approved to spend tokens held by account
     */
    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool status);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC721 interface needed by internal functions
 */
interface IERC721Internal {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Approval(
        address indexed owner,
        address indexed operator,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC721Base } from './base/IERC721Base.sol';
import { IERC721Enumerable } from './enumerable/IERC721Enumerable.sol';
import { IERC721Metadata } from './metadata/IERC721Metadata.sol';

interface ISolidStateERC721 is
    IERC721Base,
    IERC721Enumerable,
    IERC721Metadata
{}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC721 } from '../IERC721.sol';

/**
 * @title ERC721 base interface
 */
interface IERC721Base is IERC721 {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

interface IERC721Enumerable {
    /**
     * @notice get total token supply
     * @return total supply
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice get token of given owner at given internal storage index
     * @param owner token holder to query
     * @param index position in owner's token list to query
     * @return tokenId id of retrieved token
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 tokenId);

    /**
     * @notice get token at given internal storage index
     * @param index position in global token list to query
     * @return tokenId id of retrieved token
     */
    function tokenByIndex(uint256 index)
        external
        view
        returns (uint256 tokenId);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC721Internal } from '../IERC721Internal.sol';

/**
 * @title ERC721Metadata interface
 */
interface IERC721Metadata is IERC721Internal {
    /**
     * @notice get token name
     * @return token name
     */
    function name() external view returns (string memory);

    /**
     * @notice get token symbol
     * @return token symbol
     */
    function symbol() external view returns (string memory);

    /**
     * @notice get generated URI for given token
     * @return token URI
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { ReentrancyGuardStorage } from './ReentrancyGuardStorage.sol';

/**
 * @title Utility contract for preventing reentrancy attacks
 */
abstract contract ReentrancyGuard {
    modifier nonReentrant() {
        ReentrancyGuardStorage.Layout storage l = ReentrancyGuardStorage
            .layout();
        require(l.status != 2, 'ReentrancyGuard: reentrant call');
        l.status = 2;
        _;
        l.status = 1;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library ReentrancyGuardStorage {
    struct Layout {
        uint256 status;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ReentrancyGuard');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.2
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721AUpgradeable {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
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
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
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
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
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
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
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
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.2
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '../IERC721AUpgradeable.sol';

/**
 * @dev Interface of ERC721AQueryable.
 */
interface IERC721AQueryableUpgradeable is IERC721AUpgradeable {
    /**
     * Invalid query range (`start` >= `stop`).
     */
    error InvalidQueryRange();

    /**
     * @dev Returns the `TokenOwnership` struct at `tokenId` without reverting.
     *
     * If the `tokenId` is out of bounds:
     *
     * - `addr = address(0)`
     * - `startTimestamp = 0`
     * - `burned = false`
     * - `extraData = 0`
     *
     * If the `tokenId` is burned:
     *
     * - `addr = <Address of owner before token was burned>`
     * - `startTimestamp = <Timestamp when token was burned>`
     * - `burned = true`
     * - `extraData = <Extra data when token was burned>`
     *
     * Otherwise:
     *
     * - `addr = <Address of owner>`
     * - `startTimestamp = <Timestamp of start of ownership>`
     * - `burned = false`
     * - `extraData = <Extra data at start of ownership>`
     */
    function explicitOwnershipOf(uint256 tokenId) external view returns (TokenOwnership memory);

    /**
     * @dev Returns an array of `TokenOwnership` structs at `tokenIds` in order.
     * See {ERC721AQueryable-explicitOwnershipOf}
     */
    function explicitOwnershipsOf(uint256[] memory tokenIds) external view returns (TokenOwnership[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`,
     * in the range [`start`, `stop`)
     * (i.e. `start <= tokenId < stop`).
     *
     * This function allows for tokens to be queried if the collection
     * grows too big for a single call of {ERC721AQueryable-tokensOfOwner}.
     *
     * Requirements:
     *
     * - `start < stop`
     */
    function tokensOfOwnerIn(
        address owner,
        uint256 start,
        uint256 stop
    ) external view returns (uint256[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(`totalSupply`) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K collections should be fine).
     */
    function tokensOfOwner(address owner) external view returns (uint256[] memory);
}

//SPDX-License-Identifier: MIT

//     `..        `.  `... `......`.. ..
//  `..   `..    `. ..     `..  `..    `..
// `..          `.  `..    `..   `..
// `..         `..   `..   `..     `..
// `..        `...... `..  `..        `..
//  `..   `..`..       `.. `..  `..    `..
//    `.... `..         `..`..    `.. ..

pragma solidity 0.8.16;
import "@solidstate/contracts/token/ERC721/ISolidStateERC721.sol";
import { IERC173 } from "@solidstate/contracts/access/IERC173.sol";

interface IAnima is ISolidStateERC721, IERC173 {
    function setBaseURI(string calldata baseURI) external;

    function setCatcoinContract(address catcoins) external;

    function mint(address recipient, uint256 tokenId) external;
}

// SPDX-License-Identifier: GPL-3.0

//     `..        `.  `... `......`.. ..
//  `..   `..    `. ..     `..  `..    `..
// `..          `.  `..    `..   `..
// `..         `..   `..   `..     `..
// `..        `...... `..  `..        `..
//  `..   `..`..       `.. `..  `..    `..
//    `.... `..         `..`..    `.. ..
pragma solidity 0.8.16;

import { ICatsAuctionHouse } from "./ICatsAuctionHouse.sol";
import { ICatcoin } from "../catcoin/ICatcoin.sol";
import { CatsAuctionHouseStorage } from "./CatsAuctionHouseStorage.sol";
import { IERC20 } from "@solidstate/contracts/token/ERC20/IERC20.sol";
import { IWETH } from "../weth/IWETH.sol";

library AuctionPaymentLibrary {
    function isBidValid(ICatsAuctionHouse.Auction memory auction, uint256 bidAmount)
        internal
        view
        returns (bool, string memory)
    {
        if (isBelowReservePrice(auction, bidAmount)) return (false, "Bid is below reserve price");
        if (isBelowMinBid(auction, bidAmount)) return (false, "Bid price is below minimum");

        if (auction.isETH) {
            if (msg.value != bidAmount) {
                return (false, "Value sent doesn't match bid");
            }
        } else {
            if (ICatcoin(address(this)).balanceOf(msg.sender) < bidAmount)
                return (false, "Catcoin balance is not enough");
        }
        return (true, "");
    }

    function isBelowMinBid(ICatsAuctionHouse.Auction memory auction, uint256 bidAmount)
        internal
        view
        returns (bool valid)
    {
        if (auction.isETH) {
            valid =
                bidAmount <
                auction.amount + ((auction.amount * CatsAuctionHouseStorage.layout().minBidIncrementPercentage) / 100);
        } else {
            valid = bidAmount < auction.amount + CatsAuctionHouseStorage.layout().minBidIncrementUnit;
        }
    }

    function isBelowReservePrice(ICatsAuctionHouse.Auction memory auction, uint256 bidAmount)
        internal
        view
        returns (bool valid)
    {
        if (auction.isETH) {
            valid = bidAmount < CatsAuctionHouseStorage.layout().reservePriceInETH;
        } else {
            valid = bidAmount < CatsAuctionHouseStorage.layout().reservePriceInCatcoins;
        }
    }

    /**
     * @notice Transfer ETH. If the ETH transfer fails, wrap the ETH and try send it as WETH.
     */
    function withdraw(
        ICatsAuctionHouse.Auction memory auction,
        address to,
        uint256[] calldata tokenIds
    ) internal {
        if (auction.isETH) {
            if (!_safeTransferETH(to, auction.amount)) {
                IWETH(CatsAuctionHouseStorage.layout().weth).deposit{ value: auction.amount }();
                IERC20(CatsAuctionHouseStorage.layout().weth).transfer(to, auction.amount);
            }
        } else {
            require(tokenIds.length == auction.amount, "Withdrawal amount mismatch");
            ICatcoin(address(this)).safeBatchTransferFrom(auction.bidder, to, tokenIds);
        }
    }

    /**
     * @notice Transfer ETH. If the ETH transfer fails, wrap the ETH and try send it as WETH.
     */
    function reverseLastBid(ICatsAuctionHouse.Auction memory auction) internal {
        if (auction.isETH) {
            if (!_safeTransferETH(auction.bidder, auction.amount)) {
                IWETH(CatsAuctionHouseStorage.layout().weth).deposit{ value: auction.amount }();
                IERC20(CatsAuctionHouseStorage.layout().weth).transfer(auction.bidder, auction.amount);
            }
        }
    }

    function _safeTransferETH(address to, uint256 value) internal returns (bool) {
        (bool success, ) = to.call{ value: value, gas: 30_000 }(new bytes(0));
        return success;
    }
}

// SPDX-License-Identifier: GPL-3.0

//     `..        `.  `... `......`.. ..
//  `..   `..    `. ..     `..  `..    `..
// `..          `.  `..    `..   `..
// `..         `..   `..   `..     `..
// `..        `...... `..  `..        `..
//  `..   `..`..       `.. `..  `..    `..
//    `.... `..         `..`..    `.. ..

// LICENSE
// CatsAuctionHouse.sol is a modified version of Zora's AuctionHouse.sol:
// https://github.com/ourzora/auction-house/blob/54a12ec1a6cf562e49f0a4917990474b11350a2d/contracts/AuctionHouse.sol
//
// AuctionHouse.sol source code Copyright Zora licensed under the GPL-3.0 license.
// With modifications by Catders DAO.

pragma solidity 0.8.16;
import { ICatsAuctionHouse } from "./ICatsAuctionHouse.sol";
import { ICats } from "../cats/ICats.sol";
import { IAuctionable } from "../cats/IAuctionable.sol";
import { ICatcoin } from "../catcoin/ICatcoin.sol";
import { ReentrancyGuard } from "@solidstate/contracts/utils/ReentrancyGuard.sol";
import { CatsAuctionHouseStorage } from "./CatsAuctionHouseStorage.sol";
import { AuctionPaymentLibrary } from "./AuctionPaymentLibrary.sol";
import { LibDiamond } from "../diamond/LibDiamond.sol";

contract CatsAuctionHouse is ICatsAuctionHouse, ReentrancyGuard {
    using AuctionPaymentLibrary for ICatsAuctionHouse.Auction;

    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    modifier whenNotPaused() {
        require(
            !CatsAuctionHouseStorage.layout().paused && CatsAuctionHouseStorage.layout().duration != 0,
            "Pausable: paused"
        );
        _;
    }

    modifier whenPaused() {
        require(
            CatsAuctionHouseStorage.layout().paused || CatsAuctionHouseStorage.layout().duration == 0,
            "Pausable: not paused"
        );
        _;
    }

    /**
     * @notice Initialize the auction house and base contracts,
     * populate configuration values, and pause the contract.
     * @dev This function can only be called once.
     */
    function setConfig(
        address treasury_,
        address devs_,
        IAuctionable cats_,
        address weth_,
        uint256 timeBuffer_,
        uint256 reservePriceInETH_,
        uint256 reservePriceInCatcoins_,
        uint8 minBidIncrementPercentage_,
        uint8 minBidIncrementUnit_,
        uint256 duration_
    ) external onlyOwner {
        pause();

        CatsAuctionHouseStorage.layout().treasury = treasury_;
        CatsAuctionHouseStorage.layout().devs = devs_;
        CatsAuctionHouseStorage.layout().cats = cats_;
        CatsAuctionHouseStorage.layout().weth = weth_;
        CatsAuctionHouseStorage.layout().timeBuffer = timeBuffer_;
        CatsAuctionHouseStorage.layout().reservePriceInETH = reservePriceInETH_;
        CatsAuctionHouseStorage.layout().reservePriceInCatcoins = reservePriceInCatcoins_;
        CatsAuctionHouseStorage.layout().minBidIncrementPercentage = minBidIncrementPercentage_;
        CatsAuctionHouseStorage.layout().minBidIncrementUnit = minBidIncrementUnit_;
        CatsAuctionHouseStorage.layout().duration = duration_;
        CatsAuctionHouseStorage.layout().ethAuctions = true;
    }

    /**
     * @notice Settle the current auction, mint a new Cat, and put it up for auction.
     */
    function settleCurrentAndCreateNewAuction(uint256[] calldata tokenIds)
        external
        override
        nonReentrant
        whenNotPaused
    {
        _settleAuction(tokenIds);
        _createAuction();
    }

    /**
     * @notice Settle the current auction.
     * @dev This function can only be called when the contract is paused.
     */
    function settleAuction(uint256[] calldata tokenIds) external override whenPaused nonReentrant {
        _settleAuction(tokenIds);
    }

    /**
     * @notice Create a bid for a Cat, with a given amount.
     * @dev This contract only accepts payment in ETH.
     */
    function createBid(uint256 catId, uint256 amount) external payable override nonReentrant {
        ICatsAuctionHouse.Auction memory _auction = CatsAuctionHouseStorage.layout().auction;

        require(_auction.catId == catId, "Cat not up for auction");
        require(block.timestamp < _auction.endTime, "Auction expired");
        (bool valid, string memory message) = _auction.isBidValid(amount);
        require(valid, message);

        address payable lastBidder = _auction.bidder;

        // Refund the last bidder, if applicableminBidIncrement
        if (lastBidder != address(0)) {
            _auction.reverseLastBid();
        }

        CatsAuctionHouseStorage.layout().auction.bidder = payable(msg.sender);
        CatsAuctionHouseStorage.layout().auction.amount = amount;

        // Extend the auction if the bid was received within `timeBuffer` of the auction end time
        bool extended = _auction.endTime - block.timestamp < CatsAuctionHouseStorage.layout().timeBuffer;
        if (extended) {
            CatsAuctionHouseStorage.layout().auction.endTime = _auction.endTime =
                block.timestamp +
                CatsAuctionHouseStorage.layout().timeBuffer;
        }

        emit AuctionBid(_auction.catId, msg.sender, msg.value, extended);

        if (extended) {
            emit AuctionExtended(_auction.catId, _auction.endTime);
        }
    }

    /**
     * @notice Pause the Cats auction house.
     * @dev This function can only be called by the owner when the
     * contract is unpaused. While no new auctions can be started when paused,
     * anyone can settle an ongoing auction.
     */
    function pause() public onlyOwner {
        CatsAuctionHouseStorage.layout().paused = true;
    }

    /**
     * @notice Unpause the Cats auction house.
     * @dev This function can only be called by the owner when the
     * contract is paused. If required, this function will start a new auction.
     */
    function unpause() external onlyOwner {
        CatsAuctionHouseStorage.layout().paused = false;
        ICatsAuctionHouse.Auction memory _auction = CatsAuctionHouseStorage.layout().auction;
        if (_auction.startTime == 0 || _auction.settled) {
            _createAuction();
        }
    }

    /**
     * @notice Set the auction time buffer.
     * @dev Only callable by the owner.
     */
    function setTimeBuffer(uint256 _timeBuffer) external override onlyOwner {
        CatsAuctionHouseStorage.layout().timeBuffer = _timeBuffer;

        emit AuctionTimeBufferUpdated(_timeBuffer);
    }

    /**
     * @notice Set the auction time buffer.
     * @dev Only callable by the owner.
     */
    function setDuration(uint256 duration_) external override onlyOwner {
        CatsAuctionHouseStorage.layout().duration = duration_;

        emit AuctionDurationUpdated(duration_);
    }

    /**
     * @notice Set the auction reserve price.
     * @dev Only callable by the owner.
     */
    function setReservePriceInETH(uint256 reservePriceInETH_) external override onlyOwner {
        CatsAuctionHouseStorage.layout().reservePriceInETH = reservePriceInETH_;

        emit AuctionReservePriceInETHUpdated(reservePriceInETH_);
    }

    /**
     * @notice Set the auction reserve price.
     * @dev Only callable by the owner.
     */
    function setReservePriceInCatcoins(uint256 reservePriceInCatcoins_) external override onlyOwner {
        CatsAuctionHouseStorage.layout().reservePriceInCatcoins = reservePriceInCatcoins_;

        emit AuctionReservePriceInCatcoinsUpdated(reservePriceInCatcoins_);
    }

    /**
     * @notice Set the auction minimum bid increment percentage (e.g 1 is 1%).
     * @dev Only callable by the owner.
     */
    function setMinBidIncrementPercentage(uint8 _minBidIncrementPercentage) external override onlyOwner {
        CatsAuctionHouseStorage.layout().minBidIncrementPercentage = _minBidIncrementPercentage;

        emit AuctionMinBidIncrementPercentageUpdated(_minBidIncrementPercentage);
    }

    /**
     * @notice Set the auction minimum bid increment in units.
     * @dev Only callable by the owner.
     */
    function setMinBidIncrementUnit(uint8 _minBidIncrementUnit) external override onlyOwner {
        CatsAuctionHouseStorage.layout().minBidIncrementUnit = _minBidIncrementUnit;

        emit AuctionMinBidIncrementUnitUpdated(_minBidIncrementUnit);
    }

    /**
     * @notice Set the auction currency
     * @dev Only callable by the owner.
     */
    function setETHAuctions(bool ethAuctions_) external override onlyOwner {
        CatsAuctionHouseStorage.layout().ethAuctions = ethAuctions_;

        emit ETHAuctionsUpdated(ethAuctions_);
    }

    /**
     * @notice Set the devs address
     * @dev Only callable by the owner.
     */
    function setDevs(address devs_) external override onlyOwner {
        CatsAuctionHouseStorage.layout().devs = devs_;
    }

    /**
     * @notice Set the treasury address
     * @dev Only callable by the owner.
     */
    function setTreasury(address treasury_) external override onlyOwner {
        CatsAuctionHouseStorage.layout().treasury = treasury_;
    }

    /**
     * @notice Create an auction.
     * @dev Store the auction details in minBidIncrementble and emit an AuctionCreated event.
     * If the mint reverts, the minter was updated without pausing this contract first. To remedy this,
     * catch the revert and pause this contract.
     */
    function _createAuction() internal {
        try CatsAuctionHouseStorage.layout().cats.mintOne(address(this)) returns (uint256 catId) {
            if (catId % 10 == 0) {
                ICats(address(CatsAuctionHouseStorage.layout().cats)).transferFrom(
                    address(this),
                    CatsAuctionHouseStorage.layout().devs,
                    catId
                );
                _createAuction();
                return;
            }
            uint256 startTime = block.timestamp;
            uint256 endTime = startTime + CatsAuctionHouseStorage.layout().duration;

            CatsAuctionHouseStorage.layout().auction = Auction({
                catId: catId,
                amount: 0,
                startTime: startTime,
                endTime: endTime,
                bidder: payable(0),
                settled: false,
                isETH: CatsAuctionHouseStorage.layout().ethAuctions
            });

            emit AuctionCreated(catId, startTime, endTime);
        } catch Error(string memory) {
            pause();
        }
    }

    /**
     * @notice Settle an auction, finalizing the bid and paying out to the owner.
     * @dev If there are no bids, the Cat is burned.
     */
    function _settleAuction(uint256[] calldata tokenIds) internal {
        ICatsAuctionHouse.Auction memory _auction = CatsAuctionHouseStorage.layout().auction;

        require(_auction.startTime != 0, "Auction hasn't begun");
        require(!_auction.settled, "Auction has already been settled");
        require(block.timestamp >= _auction.endTime, "Auction hasn't completed");

        CatsAuctionHouseStorage.layout().auction.settled = true;

        if (_auction.amount > 0) {
            _auction.withdraw(CatsAuctionHouseStorage.layout().treasury, tokenIds);
        }

        if (_auction.bidder == address(0)) {
            CatsAuctionHouseStorage.layout().cats.burn(_auction.catId);
        } else {
            ICats(address(CatsAuctionHouseStorage.layout().cats)).transferFrom(
                address(this),
                _auction.bidder,
                _auction.catId
            );
        }

        emit AuctionSettled(_auction.catId, _auction.bidder, _auction.amount);
    }

    function treasury() external view override returns (address) {
        return CatsAuctionHouseStorage.layout().treasury;
    }

    function devs() external view override returns (address) {
        return CatsAuctionHouseStorage.layout().devs;
    }

    function cats() external view override returns (IAuctionable) {
        return CatsAuctionHouseStorage.layout().cats;
    }

    function weth() external view override returns (address) {
        return CatsAuctionHouseStorage.layout().weth;
    }

    function timeBuffer() external view override returns (uint256) {
        return CatsAuctionHouseStorage.layout().timeBuffer;
    }

    function reservePriceInETH() external view override returns (uint256) {
        return CatsAuctionHouseStorage.layout().reservePriceInETH;
    }

    function reservePriceInCatcoins() external view override returns (uint256) {
        return CatsAuctionHouseStorage.layout().reservePriceInCatcoins;
    }

    function minBidIncrementPercentage() external view override returns (uint8) {
        return CatsAuctionHouseStorage.layout().minBidIncrementPercentage;
    }

    function minBidIncrementUnit() external view override returns (uint8) {
        return CatsAuctionHouseStorage.layout().minBidIncrementUnit;
    }

    function duration() external view override returns (uint256) {
        return CatsAuctionHouseStorage.layout().duration;
    }

    function auction() external view override returns (Auction memory) {
        return CatsAuctionHouseStorage.layout().auction;
    }

    function paused() external view override returns (bool) {
        return CatsAuctionHouseStorage.layout().paused;
    }

    function ethAuctions() external view override returns (bool) {
        return CatsAuctionHouseStorage.layout().ethAuctions;
    }
}

// SPDX-License-Identifier: GPL-3.0

//     `..        `.  `... `......`.. ..
//  `..   `..    `. ..     `..  `..    `..
// `..          `.  `..    `..   `..
// `..         `..   `..   `..     `..
// `..        `...... `..  `..        `..
//  `..   `..`..       `.. `..  `..    `..
//    `.... `..         `..`..    `.. ..
pragma solidity 0.8.16;

import { ICatsAuctionHouse } from "./ICatsAuctionHouse.sol";
import { IAuctionable } from "../cats/IAuctionable.sol";
import { ICatcoin } from "../catcoin/ICatcoin.sol";

library CatsAuctionHouseStorage {
    struct Layout {
        // Address of the treasury
        address treasury;
        // Address of the developes
        address devs;
        // The Cats ERC721 token contract
        IAuctionable cats;
        // The address of the WETH contract
        address weth;
        // The minimum amount of time left in an auction after a new bid is created
        uint256 timeBuffer;
        // The minimum price accepted in an auction
        uint256 reservePriceInETH;
        // The minimum price accepted in an auction
        uint256 reservePriceInCatcoins;
        // The minimum percentage difference between the last bid amount and the current bid
        uint8 minBidIncrementPercentage;
        // The minimum unitary difference between the last bid amount and the current bid
        uint8 minBidIncrementUnit;
        // The duration of a single auction
        uint256 duration;
        // The active auction
        ICatsAuctionHouse.Auction auction;
        bool paused;
        bool ethAuctions;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("cats.contracts.storage.auction.house");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

//     `..        `.  `... `......`.. ..
//  `..   `..    `. ..     `..  `..    `..
// `..          `.  `..    `..   `..
// `..         `..   `..   `..     `..
// `..        `...... `..  `..        `..
//  `..   `..`..       `.. `..  `..    `..
//    `.... `..         `..`..    `.. ..

pragma solidity 0.8.16;
import { IAuctionable } from "../cats/IAuctionable.sol";

interface ICatsAuctionHouse {
    struct Auction {
        // ID for the Cats (ERC721 token ID)
        uint256 catId;
        // The current highest bid amount
        uint256 amount;
        // The time that the auction started
        uint256 startTime;
        // The time that the auction is scheduled to end
        uint256 endTime;
        // The address of the current highest bid
        address payable bidder;
        // Whether or not the auction has been settled
        bool settled;
        // Which type of currency is used to settle the auction
        bool isETH;
    }

    event AuctionCreated(uint256 indexed catId, uint256 startTime, uint256 endTime);

    event AuctionBid(uint256 indexed catId, address sender, uint256 value, bool extended);

    event AuctionExtended(uint256 indexed catId, uint256 endTime);

    event AuctionSettled(uint256 indexed catId, address winner, uint256 amount);

    event AuctionTimeBufferUpdated(uint256 timeBuffer);

    event AuctionDurationUpdated(uint256 AuctionDurationUpdated);

    event AuctionReservePriceInETHUpdated(uint256 reservePriceInETH);

    event AuctionReservePriceInCatcoinsUpdated(uint256 reservePriceInCatcoins);

    event AuctionMinBidIncrementPercentageUpdated(uint256 minBidIncrementPercentage);

    event AuctionMinBidIncrementUnitUpdated(uint256 minBidIncrementUnit);

    event ETHAuctionsUpdated(bool ethAuctions);

    function settleAuction(uint256[] calldata tokenIds) external;

    function settleCurrentAndCreateNewAuction(uint256[] calldata tokenIds) external;

    function createBid(uint256 catId, uint256 amount) external payable;

    function pause() external;

    function unpause() external;

    function setConfig(
        address treasury,
        address devs,
        IAuctionable cats,
        address weth,
        uint256 timeBuffer,
        uint256 reservePriceInETH,
        uint256 reservePriceInCatcoins,
        uint8 minBidIncrementPercentage,
        uint8 minBidIncrementUnit,
        uint256 duration
    ) external;

    function setTimeBuffer(uint256 timeBuffer) external;

    function setReservePriceInETH(uint256 reservePriceInETH) external;

    function setReservePriceInCatcoins(uint256 reservePriceInCatcoins) external;

    function setMinBidIncrementPercentage(uint8 minBidIncrementPercentage) external;

    function setMinBidIncrementUnit(uint8 minBidIncrementUnit) external;

    function setETHAuctions(bool ethAuctions) external;

    function setDevs(address devs_) external;

    function setTreasury(address treasury) external;

    function treasury() external view returns (address);

    function devs() external view returns (address);

    function cats() external view returns (IAuctionable);

    function weth() external view returns (address);

    function timeBuffer() external view returns (uint256);

    function setDuration(uint256 duration) external;

    function reservePriceInETH() external view returns (uint256);

    function reservePriceInCatcoins() external view returns (uint256);

    function minBidIncrementPercentage() external view returns (uint8);

    function minBidIncrementUnit() external view returns (uint8);

    function duration() external view returns (uint256);

    function auction() external view returns (Auction memory);

    function paused() external view returns (bool);

    function ethAuctions() external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

//     `..        `.  `... `......`.. ..
//  `..   `..    `. ..     `..  `..    `..
// `..          `.  `..    `..   `..
// `..         `..   `..   `..     `..
// `..        `...... `..  `..        `..
//  `..   `..`..       `.. `..  `..    `..
//    `.... `..         `..`..    `.. ..

pragma solidity 0.8.16;
import { IERC721AUpgradeable } from "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";
import { IERC721AQueryableUpgradeable } from "erc721a-upgradeable/contracts/extensions/IERC721AQueryableUpgradeable.sol";
import { IERC173 } from "@solidstate/contracts/access/IERC173.sol";
import { IAnima } from "../anima/IAnima.sol";

interface ICatcoin is IERC721AUpgradeable, IERC721AQueryableUpgradeable, IERC173 {
    error WrongCatOwner();

    error PledgedQuantityBreached();

    function setBaseURI(string calldata baseURI) external;

    function exchangeCat(uint256 catId) external;

    function daoMint(address recipient, uint256 amount) external;

    function moveCatTo(address recipient, uint256 catId) external;

    function setCatsContract(IERC721AUpgradeable cats) external;

    function setAnimaContract(IAnima anima) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata tokenIds
    ) external;
}

// SPDX-License-Identifier: MIT

//     `..        `.  `... `......`.. ..
//  `..   `..    `. ..     `..  `..    `..
// `..          `.  `..    `..   `..
// `..         `..   `..   `..     `..
// `..        `...... `..  `..        `..
//  `..   `..`..       `.. `..  `..    `..
//    `.... `..         `..`..    `.. ..

pragma solidity 0.8.16;
import { IERC721AUpgradeable } from "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";
import { IERC173 } from "@solidstate/contracts/access/IERC173.sol";

interface IAuctionable is IERC721AUpgradeable, IERC173 {
    function mintOne(address recipient) external returns (uint256);

    function burn(uint256 id) external;
}

// SPDX-License-Identifier: MIT

//     `..        `.  `... `......`.. ..
//  `..   `..    `. ..     `..  `..    `..
// `..          `.  `..    `..   `..
// `..         `..   `..   `..     `..
// `..        `...... `..  `..        `..
//  `..   `..`..       `.. `..  `..    `..
//    `.... `..         `..`..    `.. ..

pragma solidity 0.8.16;
import { IERC721AUpgradeable } from "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";
import { IERC173 } from "@solidstate/contracts/access/IERC173.sol";

interface ICats is IERC721AUpgradeable, IERC173 {
    error MaxTotalSupplyBreached();
    error Unauthorized(address);

    function setBaseURI(string calldata baseURI) external;

    function setContractURI(string calldata contractURI) external;

    function mint(address recipient, uint256 quantity) external;

    function setCatcoinContract(address catcoin) external;

    function contractURI() external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamond Standard: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import "./IDiamondCut.sol";

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint16 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint16 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        // uint16 selectorCount = uint16(diamondStorage().selectors.length);
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint16 selectorPosition = uint16(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
            ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = uint16(ds.facetAddresses.length);
            ds.facetAddresses.push(_facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(selector);
            ds.selectorToFacetAndPosition[selector].facetAddress = _facetAddress;
            ds.selectorToFacetAndPosition[selector].functionSelectorPosition = selectorPosition;
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint16 selectorPosition = uint16(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
            ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = uint16(ds.facetAddresses.length);
            ds.facetAddresses.push(_facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            removeFunction(oldFacetAddress, selector);
            // add function
            ds.selectorToFacetAndPosition[selector].functionSelectorPosition = selectorPosition;
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(selector);
            ds.selectorToFacetAndPosition[selector].facetAddress = _facetAddress;
            selectorPosition++;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(oldFacetAddress, selector);
        }
    }

    function removeFunction(address _facetAddress, bytes4 _selector) internal {
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "LibDiamondCut: Can't remove immutable function");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint16(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = uint16(facetAddressPosition);
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: MIT

//     `..        `.  `... `......`.. ..
//  `..   `..    `. ..     `..  `..    `..
// `..          `.  `..    `..   `..
// `..         `..   `..   `..     `..
// `..        `...... `..  `..        `..
//  `..   `..`..       `.. `..  `..    `..
//    `.... `..         `..`..    `.. ..

pragma solidity 0.8.16;

interface IWETH {
    function deposit() external payable;
}