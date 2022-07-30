// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Market {

   event OrdersMatched(
        bytes32 buyHash,
        bytes32 sellHash,
        address indexed maker,
        address indexed taker,
        address indexed collection,
        address paymentToken,
        uint256 price
    );
    function atomicMatch( 
                        bytes32 buyHash,
                        bytes32 sellHash,
                        address buy,
                        address sell,
                        address target,
                        address paymentToken,
                        uint256 price
                        ) public {

            emit OrdersMatched(
            buyHash,
            sellHash,
            buy,
            sell,
            target,
            paymentToken,
            price
        );
    }
}