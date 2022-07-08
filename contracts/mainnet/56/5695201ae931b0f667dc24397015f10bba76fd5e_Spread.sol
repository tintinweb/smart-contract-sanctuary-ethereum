/**
 *Submitted for verification at Etherscan.io on 2022-07-08
*/

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

contract Spread {

    struct Transfer {
        address receiver;
        uint amount;
    }

    function checkValue(Transfer[] memory _transfers) internal returns(bool) {
        uint transferTotal;
        for (uint x; x < _transfers.length; x++) {
            transferTotal += _transfers[x].amount;
        }

        return transferTotal == msg.value;
    }

    function spreadEther(Transfer[] memory _transfers) external payable {
        require(checkValue(_transfers), "Ether sent must equal total of all transfers");

        for (uint x; x < _transfers.length; x++) {
            payable(address(_transfers[x].receiver)).transfer(_transfers[x].amount);
        }
    }

}