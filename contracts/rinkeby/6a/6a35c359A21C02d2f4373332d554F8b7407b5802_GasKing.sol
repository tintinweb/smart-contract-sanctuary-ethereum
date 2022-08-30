// SPDX-Licence-Identifier: MIT
pragma solidity ^0.8.0;

contract GasKing {
    address payable public externalKing =
        payable(0x1B098a508B531FC2e587814aF444711cA6165255);

    function sending() external payable {
        externalKing.call{value: msg.value, gas: 100000}("");
    }
}