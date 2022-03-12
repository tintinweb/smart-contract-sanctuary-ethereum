// SPDX-License-Identifier: MIT
pragma solidity =0.8.12;

import "INFTContract.sol";
import "IAuctionFactory.sol";
import "IAuction.sol";
import "Clones.sol";

contract AuctionFactory is IAuctionFactory {
    /// Uses https://blog.openzeppelin.com/deep-dive-into-the-minimal-proxy-contract/ pattern

    address public immutable admin;
    /// @dev Clones will be made off of this deployment
    IAuction auctionAddress;

    /// Modifiers

    modifier onlyOwner() {
        if (msg.sender != admin) revert NotAdmin();
        _;
    }

    /// Constructor

    constructor() {
        admin = msg.sender;
    }

    /// @inheritdoc IAuctionFactory
    function createAuction(
        uint256 floorPrice,
        uint256 auctionEndBlock,
        bytes32 salt
    ) external override onlyOwner returns (address) {
        address copy = Clones.cloneDeterministic(address(auctionAddress), salt);
        IAuction auctionCopy = IAuction(copy);
        auctionCopy.initialize(floorPrice, auctionEndBlock, INFTContract(address(0)));
        return copy;
    }

    /// @inheritdoc IAuctionFactory
    function createWhitelistedAuction(
        uint256 floorPrice,
        uint256 auctionEndBlock,
        address whitelistedCollection,
        bytes32 salt
    ) external override onlyOwner returns (address) {
        address copy = Clones.cloneDeterministic(address(auctionAddress), salt);
        IAuction auctionCopy = IAuction(copy);
        auctionCopy.initialize(
            floorPrice,
            auctionEndBlock,
            INFTContract(whitelistedCollection)
        );
        return copy;
    }

    /// Admin

    /// @notice If there is ever a need, new club auctions can be cloned
    /// by setting this to a different address.
    /// @param initAuctionAddress make clones off this contract
    function setAuctionAddress(address initAuctionAddress) external onlyOwner {
        auctionAddress = IAuction(initAuctionAddress);
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
 * AuctionFactory.sol
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

interface IAuctionFactory {
    error NotAdmin();

    /// @notice Creates minimal proxy contract for auction
    /// @param floorPrice Floor bid price. Bids can't be places that are
    /// lower than this price
    /// @param auctionEndBlock Ethereum block index at which the auction
    /// ends
    /// @param salt Used for deterministic clone deploy
    function createAuction(
        uint256 floorPrice,
        uint256 auctionEndBlock,
        bytes32 salt
    ) external returns (address);

    /// @notice Creates minimal proxy contract for whitelisted auction.
    /// This is where only holders of a certain NFT collection are
    /// allowed to participate
    /// @param floorPrice Floor bid price. Bids can't be places that are
    /// lower than this price
    /// @param auctionEndBlock Ethereum block index at which the auction
    /// ends
    /// @param whitelistedCollection Ethereum address of the NFT collection
    /// that is whitelisted to participate in the auction
    /// @param salt Used for deterministic clone deploy
    function createWhitelistedAuction(
        uint256 floorPrice,
        uint256 auctionEndBlock,
        address whitelistedCollection,
        bytes32 salt
    ) external returns (address);
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
 * IAuctionFactory.sol
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)
pragma solidity =0.8.12;

/// @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
/// deploying minimal proxy contracts, also known as "clones".
///
/// > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
/// > a minimal bytecode implementation that delegates all calls to a known, fixed address.
///
/// The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
/// (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
/// deterministic method.
///
/// _Available since v3.4._
library Clones {
    /// @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
    ///
    /// This function uses the create2 opcode and a `salt` to deterministically deploy
    /// the clone. Using the same `implementation` and `salt` multiple time will revert, since
    /// the clones cannot be deployed twice at the same address.
    function cloneDeterministic(address implementation, bytes32 salt)
        internal
        returns (address instance)
    {
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(
                add(ptr, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /// @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) external pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(
                add(ptr, 0x28),
                0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000
            )
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }
}