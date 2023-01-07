/**
 *Submitted for verification at Etherscan.io on 2023-01-07
*/

pragma solidity ^0.8.9;

contract Winner {
    function callAttempt() public returns (bytes memory) {
        address payable contractAddress = payable(0xcF469d3BEB3Fc24cEe979eFf83BE33ed50988502);
        // call attempt() function of the contract
        (bool success, bytes memory data) = contractAddress.call(abi.encodeWithSignature("attempt()"));
        if (success) {
            return data;
        } else {
            return "Failed";
        }
    }
}