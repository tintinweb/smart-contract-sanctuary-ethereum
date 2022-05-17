// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract AnonX {
event GotIt(address, uint256);

   receive() external payable {
            // React to receiving ether
        }

        function catchall() external payable {
        emit GotIt(msg.sender, msg.value);


        }
}