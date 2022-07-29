// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Market {

    event OrdersMatched(
                        bytes32 buyHash,
                        bytes32 sellHash,
                        address indexed maker,
                        address indexed taker,
                        address target,
                        address token,
                        uint256 price,
                        bytes32 indexed metadata
                        );
    function atomicMatch( bytes32 buyHash,
                        bytes32 sellHash,
                        address buy,
                        address sell,
                        address target,
                        address token,
                        uint256 price,
                        bytes32 metadata) public {

             emit OrdersMatched(
                buyHash,
                sellHash,
                buy,
                sell,
                target,
                token,
                price,
                metadata
                );
    }
}