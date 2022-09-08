// SPDX-License-Identifier: MIT

/**
 ______  ___  ____  _   _  ___  __  __
 | || | // \\ || \\ \\ // // \\ ||\ ||
   ||   ||=|| ||_//  )X(  ||=|| ||\\||
   ||   || || || \\ // \\ || || || \||
                                      
*/

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./ERC721.sol";
import "./IERC1155.sol";
import "./ReentrancyGuard.sol";

/**
 * @title Multiswap Contract
 * @author Pineapple Workshop (https://twitter.com/poweredby_pw)
 * @notice This contract enables two parties to perform an atomic swap of multiple assets 
   with a batched metatransaction, and enforces the agreement of the swap.
 */

contract Multiswap is ReentrancyGuard {

    constructor() {}

    struct Side {
        address user;
        bytes signedRequiredOutput;
        ERC20Component[] erc20s;
        ERC721Component[] erc721s;
        ERC1155Component[] erc1155s;
    }

    struct ERC20Component {
        uint256 amount;
        address underlying;

        // A signed approval transaction giving `amount` transfer rights
        // of token `underlying` to address(this).
        // bytes signedApproval;
    }

    struct ERC721Component {
        uint256 tokenId;
        address collection;

        // A signed approval transaction giving `tokenId` tranfer rights
        // of token `collection` to address(this).
        // bytes signedApproval;
    }

    struct ERC1155Component {
        uint256 tokenId;
        uint256 amount;
        address collection;

        // A signed approval transaction giving `tokenId` tranfer rights
        // of token `collection` to address(this).
        // bytes signedApproval;
    }

    struct Order {
        Side side0;
        Side side1;
        uint256 expiry;
        bytes32 hashlock;
        bytes32 preimage;
        bool completed;
    }

    event OrderCreated(address indexed user, bytes32 orderId);

    uint256 public totalOrders;
    mapping(bytes32 => Order) public orders;

    function createSwapOrder(
        Side calldata side0,
        bytes32 hashlock,
        uint256 timelock
    ) public {
        // Validate that the hashlock is not empty.
        require(hashlock != bytes32(0), "Hashlock must not be empty");
        // Validate that the timelock is in the future.
        require(
            timelock > block.timestamp + 15 minutes,
            "Timelock time must be at least 15 minutes in the future"
        );
        // Validate that the user is not empty.
        require(side0.user != address(0), "User must not be empty");
        // Create the order.
        bytes32 orderId = keccak256(
            abi.encodePacked(
                side0.user,
                hashlock,
                timelock,
                block.timestamp,
                totalOrders
            )
        );
        Order storage order = orders[orderId];

        // Copying side0
        order.side0 = side0;

        // Copying side1
        order.side1.user = address(0);
        order.side1.signedRequiredOutput = "";

        // Copying expiry, hashlock, preimage, completed
        order.expiry = timelock;
        order.hashlock = hashlock;
        order.preimage = bytes32(0);
        order.completed = false;

        totalOrders += 1;
        emit OrderCreated(side0.user, orderId);
    }

    function fulfillOrder(
        Side calldata side1,
        bytes32 preimage,
        bytes32 orderId
    ) public {
        // Validate that the order exists.
        require(orders[orderId].expiry != 0, "Order does not exist");
        // Validate that the order has not expired.
        require(orders[orderId].expiry > block.timestamp, "Order has expired");
        // Validate that the order has not been completed.
        require(orders[orderId].completed == false, "Order has been completed");
        // Validate that the user is not empty.
        require(side1.user != address(0), "User must not be empty");
        // Validate that the preimage is valid.
        require(
            sha256(abi.encodePacked(preimage)) == orders[orderId].hashlock,
            "Preimage is invalid"
        );

        // Fulfill the order.
        orders[orderId].side1 = side1;
        orders[orderId].preimage = preimage;

        // Execute the swap.
        multiswap(orders[orderId].side0, orders[orderId].side1);
        orders[orderId].completed = true;
    }

    function multiswap(Side storage side0, Side storage side1) internal {
        // Validate that each side's signed expected output matches the input of the counterparty.
        {
            (uint8 v, bytes32 r, bytes32 s) = vrs(side0.signedRequiredOutput);
            require(
                getSigner(encodeNetInput(side1), v, r, s) == side0.user,
                "Invalid signature 0"
            );
        }
        {
            (uint8 v, bytes32 r, bytes32 s) = vrs(side1.signedRequiredOutput);
            require(
                getSigner(encodeNetInput(side0), v, r, s) == side1.user,
                "Invalid signature 1"
            );
        }
        /* Execute each side's transfer.
        Message signature validation for transfer calls can be delegated to the ERC contracts.
        Multiswap's role is to *forward* signed metatransactions, not execute them on internal structures.
        ie, Multiswap does not need to validate the message signatures itself.
        If we forward a "forged" message to an ERC20/721/1155, that contract will fail and revert our atomic swap.
        If we forward a `transfer` signed call to an ERC20 and the user does not have sufficient balance,
          the erc20 contract will revert our atomic swap.
        If we forward a `transfer` signed call to an ERC721/1155 and the user does not possess the non fungible token,
          the erc721/erc1155 will revert our atomic swap. */
        _executeSide(side0, side1.user);
        _executeSide(side1, side0.user);
    }

    function _executeSide(Side storage side, address recipient) internal {
        for (uint256 i; i < side.erc20s.length; i++) {
            ERC20Component storage c = side.erc20s[i];
            // NOTE: Gasless metatransactions will not work with approval calls.
            // When the ERC standards are extended to include `permit`, this is back on the table.
            // call(c.signedApproval, c.underlying, gasleft(), 0);
            bool ret = IERC20(c.underlying).transferFrom(
                side.user,
                recipient,
                c.amount
            );
            require(ret == true, "ERC20 transfer failed");
        }
        for (uint256 i; i < side.erc721s.length; i++) {
            ERC721Component storage c = side.erc721s[i];
            // NOTE: Gasless metatransactions will not work with approval calls.
            // call(c.signedApproval, c.collection, gasleft(), 0);
            IERC721(c.collection).safeTransferFrom(
                side.user,
                recipient,
                c.tokenId
            );
        }
        for (uint256 i; i < side.erc1155s.length; i++) {
            ERC1155Component storage c = side.erc1155s[i];
            // NOTE: Gasless metatransactions will not work with approval calls.
            // call(c.signedApproval, c.collection, gasleft(), 0);
            IERC1155(c.collection).safeTransferFrom(
                side.user,
                recipient,
                c.tokenId,
                c.amount,
                ""
            );
        }
    }

    function encodeNetInput(Side memory side) public pure returns (bytes32) {
        // return the hash of the net output, where the net output is the total combination of
        // - (uint amount, address underyling) for each erc20
        // - (uint tokenId, address collection) for each 721 and 1155
        // all organized into a layout of two arrays in a deterministic way:

        uint256 n = side.erc20s.length +
            side.erc721s.length +
            side.erc1155s.length;
        uint256[] memory tokens = new uint256[](n);
        address[] memory addrs = new address[](n);

        for (uint256 i; i < side.erc20s.length; i++) {
            uint256 offset = 0;
            tokens[i + offset] = side.erc20s[i].amount;
            addrs[i + offset] = side.erc20s[i].underlying;
        }

        for (uint256 i; i < side.erc721s.length; i++) {
            uint256 offset = side.erc20s.length;
            tokens[i + offset] = side.erc721s[i].tokenId;
            addrs[i + offset] = side.erc721s[i].collection;
        }

        for (uint256 i; i < side.erc1155s.length; i++) {
            uint256 offset = side.erc20s.length + side.erc721s.length;
            tokens[i + offset] = side.erc1155s[i].tokenId;
            addrs[i + offset] = side.erc1155s[i].collection;
        }

        return keccak256(abi.encodePacked(tokens, addrs));
    }

    function vrs(bytes memory sig)
        public
        pure
        returns (
            uint8,
            bytes32,
            bytes32
        )
    {
        require(sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := and(mload(add(sig, 65)), 255)
        }
        if (v < 27) v += 27;

        return (v, r, s);
    }

    function getSigner(
        bytes32 unsignedMessage,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public pure returns (address) {
        return ecrecover(prefixed(unsignedMessage), v, r, s);
    }

    // Builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }
}