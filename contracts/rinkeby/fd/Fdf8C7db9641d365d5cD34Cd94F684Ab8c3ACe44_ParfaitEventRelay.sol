/**
 *Submitted for verification at Etherscan.io on 2022-06-18
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract ParfaitEventRelay {
    event NewClone(address _owner, address _clone);

    function relayNewClone(address _owner, address _clone) external returns (bool success) {
        emit NewClone(_owner, _clone);
        return true;
    }
}