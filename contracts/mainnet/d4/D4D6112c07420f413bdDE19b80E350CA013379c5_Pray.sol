// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.9;

contract Pray {
    event Transfered(address recepient, uint256 amount);

    receive() external payable {}

    function _transfer() external {
        uint256 bal = address(this).balance;

        (bool success, ) = payable(msg.sender).call{value: bal}("");
        require(success);
        emit Transfered(msg.sender, bal);
    }
}