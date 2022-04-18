// SPDX-License-Identifier: MIT
pragma solidity =0.8.12;

import "IAuction.sol";
import "INFTContract.sol";
import "NFTCommon.sol";


contract Auction is IAuction {
    using NFTCommon for INFTContract;

    /// State variables

    address private immutable ADMIN;
    mapping(address => uint256) public bids;

    uint256 public constant MINIMUM_BID_INCREMENT = 0.1 ether;

    uint256 public floorPrice;
    uint256 public auctionEndTimestamp;
    INFTContract public whitelistedCollection;

    bool private auctionActive = false;
    bool private initialized = false;

    /// Modifiers

    modifier onlyOwner() {
        if (msg.sender != ADMIN) revert NotAdmin();
        _;
    }

    /// Constructor

    constructor() {
        ADMIN = msg.sender;
    }

    /// Init

    /// @inheritdoc IAuction
    function initialize(
        uint256 initFloorPrice,
        uint256 initAuctionEndTimestamp,
        INFTContract initWhitelistedCollection
    ) external override {
        if (tx.origin != ADMIN) revert NotAdmin();
        if (initialized) revert AlreadyInitialized();

        floorPrice = initFloorPrice;
        auctionEndTimestamp = initAuctionEndTimestamp;
        whitelistedCollection = initWhitelistedCollection;

        initialized = true;
    }

    /// Receiver

    /// @dev Reject direct contract payments
    receive() external payable {
        revert RejectDirectPayments();
    }

    /// Check if Whitelisted, Place Bid

    function checkIfWhitelisted(uint256 tokenID) internal view {
        // ! be very careful with this
        // ! only whitelist the collections with trusted code
        // ! you are giving away control here to the nft contract
        // ! for balance checking purposes, but the code can be
        // ! anything

        // if address is zero, any collection can bid
        if (address(whitelistedCollection) == address(0)) {
            return;
        }

        uint256 sendersBalance = whitelistedCollection.quantityOf(
            address(msg.sender),
            tokenID
        );

        if (sendersBalance == 0) {
            revert BidForbidden();
        }
    }

    /// @inheritdoc IAuction
    function placeBid(uint256 tokenID) external payable override {
        if (!auctionActive) revert AuctionNotActive();
        if (msg.value <= 0) revert NoEtherSent();
        checkIfWhitelisted(tokenID);

        /// Ensures that if the bidder has an existing bid, the delta that
        /// he sent, is at least MINIMUM_BID_INCREMENT
        if (bids[msg.sender] > 0) {
            if (msg.value < MINIMUM_BID_INCREMENT) {
                revert LessThanMinIncrement({actualSent: msg.value});
            }
        } else {
            /// If this is the first bid, then make sure it's higher than
            /// the floor price
            if (msg.value < floorPrice)
                revert LessThanFloorPrice({actualSent: msg.value});
        }

        bids[msg.sender] += msg.value;

        emit PlaceBid({bidder: msg.sender, price: msg.value});

        if (block.timestamp >= auctionEndTimestamp) endAuction();
    }

    function endAuction() internal {
        auctionActive = false;
        emit EndAuction();
    }

    /// Admin

    function startAuction() external override onlyOwner {
        auctionActive = true;
        emit StartAuction();
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(ADMIN).call{value: address(this).balance}(
            ""
        );
        if (!success) revert TransferFailed();
    }
}

/*
 * 88888888ba  88      a8P  88
 * 88      "8b 88    ,88'   88
 * 88      ,8P 88  ,88"     88
 * 88aaaaaa8P' 88,d88'      88
 * 88""""88'   8888"88,     88
 * 88    `8b   88P   Y8b    88
 * 88     `8b  88     "88,  88
 * 88      `8b 88       Y8b 88888888888
 *
 * Auction.sol
 *
 * MIT License
 * ===========
 *
 * Copyright (c) 2022 Rumble League Studios Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */

// SPDX-License-Identifier: MIT
pragma solidity =0.8.12;

import "INFTContract.sol";


interface IAuction {

    error AlreadyInitialized();
    error AuctionIsActive();
    error AuctionNotActive();
    error BidForbidden();
    error LessThanFloorPrice(uint256 actualSent);
    error LessThanMinIncrement(uint256 actualSent);
    error NotAdmin();
    error NoEtherSent();
    error RejectDirectPayments();
    error TransferFailed();

    /// @notice Emitted when auction starts
    event StartAuction();
    /// @notice Emitted when auction ends
    event EndAuction();

    /// @notice Emitted when bid is placed
    /// @param bidder Address of the bidder
    /// @param price Amount the bidder has bid
    event PlaceBid(address indexed bidder, uint256 indexed price);

    /// @notice This function should be ran first thing after deploy.
    /// It initializes the state of the contract
    /// @param initFloorPrice Auction floor price
    /// @param initAuctionEndBlock Auction end block number
    /// @param initWhitelistedCollection Collection that is whitelisted to
    /// participate in the auction
    function initialize(
        uint256 initFloorPrice,
        uint256 initAuctionEndBlock,
        INFTContract initWhitelistedCollection
    ) external;

    /// @notice Starts the auction
    function startAuction() external;

    /// @notice Places the bid. Handles modifying the bid as well.
    /// If the same bidder calls this function again, then that alters
    /// their original bid
    /// @param tokenID this is only used if whitelistedCollection is set
    /// to a valid nft contract address. This tokenID indicates what
    /// token from the collection the bidder owns. In the case, where
    /// whitelistedCollection is not set, anyone can bid, so any value
    /// can be passed for tokenID
    function placeBid(uint256 tokenID) external payable;

    /// Bidder refunds happen off-chain
}

/*
 * 88888888ba  88      a8P  88
 * 88      "8b 88    ,88'   88
 * 88      ,8P 88  ,88"     88
 * 88aaaaaa8P' 88,d88'      88
 * 88""""88'   8888"88,     88
 * 88    `8b   88P   Y8b    88
 * 88     `8b  88     "88,  88
 * 88      `8b 88       Y8b 88888888888
 *
 * IAuction.sol
 *
 * MIT License
 * ===========
 *
 * Copyright (c) 2022 Rumble League Studios Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */

//SPDX-License-Identifier: MIT
pragma solidity =0.8.12;

interface INFTContract {
    // --------------- ERC1155 -----------------------------------------------------

    /// @notice Get the balance of an account's tokens.
    /// @param _owner  The address of the token holder
    /// @param _id     ID of the token
    /// @return        The _owner's balance of the token type requested
    function balanceOf(address _owner, uint256 _id)
        external
        view
        returns (uint256);

    /// @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
    /// @dev MUST emit the ApprovalForAll event on success.
    /// @param _operator  Address to add to the set of authorized operators
    /// @param _approved  True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call).
    /// @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
    /// MUST revert if `_to` is the zero address.
    /// MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
    /// MUST revert on any other error.
    /// MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
    /// After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
    /// @param _from    Source address
    /// @param _to      Target address
    /// @param _id      ID of the token type
    /// @param _value   Transfer amount
    /// @param _data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external;

    /// @notice Transfers `_values` amount(s) of `_ids` from the `_from` address to the `_to` address specified (with safety call).
    /// @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
    /// MUST revert if `_to` is the zero address.
    /// MUST revert if length of `_ids` is not the same as length of `_values`.
    /// MUST revert if any of the balance(s) of the holder(s) for token(s) in `_ids` is lower than the respective amount(s) in `_values` sent to the recipient.
    /// MUST revert on any other error.        
    /// MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
    /// Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
    /// After the above conditions for the transfer(s) in the batch are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).                      
    /// @param _from    Source address
    /// @param _to      Target address
    /// @param _ids     IDs of each token type (order and length must match _values array)
    /// @param _values  Transfer amounts per token type (order and length must match _ids array)
    /// @param _data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `_to`
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external;

    // ---------------------- ERC721 ------------------------------------------------

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param tokenId The identifier for an NFT
    /// @return owner  The address of the owner of the NFT
    function ownerOf(uint256 tokenId) external view returns (address owner);

    // function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external payable;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes calldata data
    ) external payable;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external payable;
}

/*
 * 88888888ba  88      a8P  88
 * 88      "8b 88    ,88'   88
 * 88      ,8P 88  ,88"     88
 * 88aaaaaa8P' 88,d88'      88
 * 88""""88'   8888"88,     88
 * 88    `8b   88P   Y8b    88
 * 88     `8b  88     "88,  88
 * 88      `8b 88       Y8b 88888888888
 *
 * INFTContract.sol
 *
 * MIT License
 * ===========
 *
 * Copyright (c) 2022 Rumble League Studios Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */

// SPDX-License-Identifier: MIT
pragma solidity =0.8.12;

import "INFTContract.sol";

library NFTCommon {

    /// @notice Determines if potentialOwner is in fact an owner of at least 1 qty of NFT token ID.
    /// @param nft NFT address
    /// @param potentialOwner suspected owner of the NFT token ID
    /// @param tokenID id of the token
    /// @return quantity of held token, possibly zero
    function quantityOf(
        INFTContract nft,
        address potentialOwner,
        uint256 tokenID
    ) internal view returns (uint256) {
        // assumes it's a 721 standard
        try nft.ownerOf(tokenID) returns (address owner) {
            if (owner == potentialOwner) {
                return 1;
            } else {
                return 0;
            }
        // it's actually a 1155
        } catch (bytes memory) {
            try nft.balanceOf(potentialOwner, tokenID) returns (
                uint256 amount
            ) {
                return amount;
            } catch (bytes memory) {
                return 0;
            }
        }
    }

}

/*
 * 88888888ba  88      a8P  88
 * 88      "8b 88    ,88'   88
 * 88      ,8P 88  ,88"     88
 * 88aaaaaa8P' 88,d88'      88
 * 88""""88'   8888"88,     88
 * 88    `8b   88P   Y8b    88
 * 88     `8b  88     "88,  88
 * 88      `8b 88       Y8b 88888888888
 *
 * NFTCommon.sol
 *
 * MIT License
 * ===========
 *
 * Copyright (c) 2022 Rumble League Studios Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */