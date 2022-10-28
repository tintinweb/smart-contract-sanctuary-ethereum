// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

// ======================================================================================================
// ===================================== Flip.xyz: LooksRare trades =====================================
// ======================================================================================================

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "./LooksRareTypes.sol";

// Enable interface checking for 721s/1155s.
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// Enable ERC721 transfers back to caller.
interface IERC721 {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

// Enable ERC1155 transfers back to caller.
interface IERC1155 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
}

// Enable rewards claiming.
interface IMultiRewardsDistributor {
    function claim(
        uint8[] calldata treeIds,
        uint256[] calldata amounts,
        bytes32[][] calldata merkleProofs
    ) external;
}

// Enable LOOKS reward transfers to distributor contract.
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);
}

contract FlipLooksRareCheckout is Ownable {
    /// @notice The address of Flip's LOOKS distributor contract; any LOOKS claimed by this contract get forwarded to this.
    address public flipDistributor;

    /// @notice The address of the LOOKS token.
    address constant looksToken = 0xf4d2888d29D722226FafA5d9B24F9164c092421E;

    /// @notice Sets flipDistributor.
    /// @param _flipDistributor Address of Flip's distributor contract.
    constructor(address _flipDistributor) {
        flipDistributor = _flipDistributor;
    }

    /// @notice Executes a batch of ETH for ERC721/ERC1155 trades via LooksRare.
    /// @dev All assets purchased will be forwarded to the 'receiver'.
    /// @dev Will not revert failed trades, but will instead refund the leftover ETH.
    /// @param takerBids Taker orders to match with each maker order.
    /// @param makerAsks Maker orders to match with each taker order.
    /// @param receiver Address to forward the purchased assets to.
    function batchBuy(
        TakerOrder[] calldata takerBids,
        MakerOrder[] calldata makerAsks,
        address receiver
    ) external payable {
        // Make trades
        for (uint256 i = 0; i < takerBids.length; i++) {
            _singleBuy(takerBids[i], makerAsks[i], receiver);
        }

        // Check for leftover ETH
        bool callStatus = true;
        assembly {
            if gt(selfbalance(), 0) {
                callStatus := call(
                    gas(),
                    caller(),
                    selfbalance(),
                    0,
                    0,
                    0,
                    0
                )
            }
        }
        require(callStatus, "batchBuy: ETH refund failed");
    }

    /// @notice Executes a single ETH for ERC721/ERC1155 trade via LooksRare.
    /// @dev All assets purchased will be forwarded to the 'receiver'.
    /// @dev Will not revert failed trades, as batchBuy will refund unspent ETH.
    /// @param takerBid Taker order to match with the maker order.
    /// @param makerAsk Maker order to match with the taker order.
    /// @param receiver Address to forward the purchased asset to.
    function _singleBuy(
        TakerOrder calldata takerBid,
        MakerOrder calldata makerAsk,
        address receiver
    ) internal {
        // Make trade on behalf of caller
        try
            ILooksRareExchange(0x59728544B08AB483533076417FbBB2fD0B17CE3a)
                .matchAskWithTakerBidUsingETHAndWETH{value: takerBid.price}(
                takerBid,
                makerAsk
            )
        {
            if (IERC165(makerAsk.collection).supportsInterface(0x80ac58cd)) {
                IERC721(makerAsk.collection).transferFrom(
                    address(this),
                    receiver,
                    makerAsk.tokenId
                );
            } else if (
                IERC165(makerAsk.collection).supportsInterface(0xd9b67a26)
            ) {
                IERC1155(makerAsk.collection).safeTransferFrom(
                    address(this),
                    receiver,
                    makerAsk.tokenId,
                    makerAsk.amount,
                    "0x"
                );
            } else {
                revert("Purchased asset not ERC721 or ERC1155"); // Will revert the entire transaction so asset does not get stuck
            }
        } catch {} // Do not bubble up failed trade reverts
    }

    /// @notice Claims LOOKS rewards for this contract and forwards them to flipDistributor.
    /// @param treeIds Tree ids to claim for in LooksRare's distributor.
    /// @param amounts Amount to claim from each tree id.
    /// @param merkleProofs Merkle proofs to verify the claims.
    function claimAndSend(
        uint8[] calldata treeIds,
        uint256[] calldata amounts,
        bytes32[][] calldata merkleProofs
    ) external onlyOwner {
        IMultiRewardsDistributor(0x0554f068365eD43dcC98dcd7Fd7A8208a5638C72)
            .claim(treeIds, amounts, merkleProofs);

        uint256 balance = IERC20(looksToken).balanceOf(address(this));
        require(balance > 0, "No rewards claimed");

        IERC20(looksToken).transfer(flipDistributor, balance);
    }

    /// @notice Executes a single ETH for ERC721 trade via LooksRare.
    /// @dev Expects '0x' + 868 bytes of calldata:
    ///         4 byte function selector for LooksRareExchange.matchAskWithTakerBidUsingETHAndWETH
    ///         + 832 bytes order data (TakerOrder and MakerOrder)
    ///         + 32 bytes recipient address
    /// @dev Will revert if msg.value does not equal MakerOrder.price, or if the trade fails.
    fallback() external payable {
        bool success;
        bool success2;
        assembly {
            // 1. Prepare for trade call
            let ptr := mload(0x40)
            // Copy calldata to memory
            calldatacopy(ptr, 0, calldatasize())

            // 2. Make trade
            success := call(
                gas(),
                0x59728544B08AB483533076417FbBB2fD0B17CE3a, // Call LooksRareExchange
                callvalue(), // use msg.value to combat leftover ETH - LooksRareExchange will revert on bad msg.value
                ptr,
                0x344, // Data for making the call is 836 bytes long
                0,
                0
            )

            // 3. Prepare for transfer call
            let ptr2 := mload(0x40)
            // Store transferFrom selector + address(this) + recipient + tokenId
            mstore(
                ptr2,
                0x23b872dd00000000000000000000000000000000000000000000000000000000
            )
            mstore(add(ptr2, 0x04), address())
            mstore(add(ptr2, 0x24), mload(add(ptr, 0x344)))
            mstore(add(ptr2, 0x44), mload(add(ptr, 0xa4)))

            // 4. Transfer NFT to caller
            success2 := call(
                gas(),
                mload(add(ptr, 0x164)), // Call NFT collection
                0,
                ptr2,
                0x64, // Data for call is 100 bytes long (4 + 32 * 3)
                0,
                0
            )
        }

        // Check result
        if (!success || !success2) {
            revert("Trade attempt reverted");
        }
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return 0x150b7a02;
    }

    // For ERC721BasicToken.sol compatability.
    function onERC721Received(
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return 0xf0b9e5ba;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) external virtual returns (bytes4) {
        return this.onERC1155Received.selector; // 0xf23a6e61
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector; // 0xbc197c81
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

// Imports to enable calls to LooksRareExchange

struct MakerOrder {
    bool isOrderAsk; // true --> ask / false --> bid
    address signer; // signer of the maker order
    address collection; // collection address
    uint256 price; // price (used as )
    uint256 tokenId; // id of the token
    uint256 amount; // amount of tokens to sell/purchase (must be 1 for ERC721, 1+ for ERC1155)
    address strategy; // strategy for trade execution (e.g., DutchAuction, StandardSaleForFixedPrice)
    address currency; // currency (e.g., WETH)
    uint256 nonce; // order nonce (must be unique unless new maker order is meant to override existing one e.g., lower ask price)
    uint256 startTime; // startTime in timestamp
    uint256 endTime; // endTime in timestamp
    uint256 minPercentageToAsk; // slippage protection (9000 --> 90% of the final price must return to ask)
    bytes params; // additional parameters
    uint8 v; // v: parameter (27 or 28)
    bytes32 r; // r: parameter
    bytes32 s; // s: parameter
}

struct TakerOrder {
    bool isOrderAsk; // true --> ask / false --> bid
    address taker; // msg.sender
    uint256 price; // final price for the purchase
    uint256 tokenId;
    uint256 minPercentageToAsk; // // slippage protection (9000 --> 90% of the final price must return to ask)
    bytes params; // other params (e.g., tokenId)
}

// Enable LooksRare calls
interface ILooksRareExchange {
    function matchAskWithTakerBidUsingETHAndWETH(
        TakerOrder calldata takerBid,
        MakerOrder calldata makerAsk
    ) external payable;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}