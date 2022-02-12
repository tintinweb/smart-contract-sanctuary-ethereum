// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

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
        auctionCopy.initialize(floorPrice, auctionEndBlock, address(0));
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
            whitelistedCollection
        );
        return copy;
    }

    /// Admin

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

// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

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
pragma solidity =0.8.11;

interface IAuction {
    error AlreadyInitialized();
    error AuctionIsActive();
    error AuctionNotActive();
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
    /// @notice Emitted when lost bid was refunded
    /// @param bidder Address of the bidder that lost the auction
    /// @param refundAmount Amount the bidder is refunded
    event RefundBid(address indexed bidder, uint256 indexed refundAmount);

    /// @notice This function should be ran first thing after deploy.
    /// It initializes the state of the contract
    /// @param initFloorPrice Auction floor price
    /// @param initAuctionEndBlock Auction end block number
    /// @param initWhitelistedCollection Collection that is whitelisted to
    /// participate in the auction
    function initialize(
        uint256 initFloorPrice,
        uint256 initAuctionEndBlock,
        address initWhitelistedCollection
    ) external;

    /// @notice Starts the auction
    function startAuction() external;

    /// @notice Places the bid. Handles modifying the bid as well.
    /// If the same bidder calls this function again, then that alters
    /// their original bid
    function placeBid() external payable;

    /// @notice Refunds all the lost bids. Makes an assumption that
    /// the contract keeps track of all of the bids.
    /// @param losingThreshold Refund all the bids below this price
    /// @param fromIx Loop through all of the bidders starting at this index
    /// @param toIx Loop through all of the bidders ending at this index
    function refundBidders(
        uint256 losingThreshold,
        uint256 fromIx,
        uint256 toIx
    ) external;
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
pragma solidity =0.8.11;

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