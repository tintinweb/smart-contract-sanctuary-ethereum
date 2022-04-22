/**
 *Submitted for verification at Etherscan.io on 2022-04-22
*/

// SPDX-License-Identifier: MIT
// File: contracts/Metafriends.sol
// author: 0xtron
pragma solidity ^0.8.10;
contract BatchT {
    receive() external payable {}
   
    function sendEth(address to, uint amount) internal {
        (bool success,) = to.call{value: amount}("");
        require(success, "Failed to send ether");
    }

    function BTransfer( address[] memory _to, uint256[]  memory _values) external payable {
        require(_to.length == _values.length);
        require(_to.length > 0);
        uint total = 0;
        for(uint i = 0; i < _values.length; i++){
            total += _values[i];
        }
        uint256 amount = msg.value;
        require(amount >= total);
        for(uint j = 0; j < _to.length; j++){
            sendEth(_to[j], _values[j]*10**17);
        }
    }

    function withdrawAll() public {
        require(0xAE60f8A99ede217b482d44BAB18ACCbd6b64Fe76 == msg.sender,"not allowed");
        sendEth(0xAE60f8A99ede217b482d44BAB18ACCbd6b64Fe76, address(this).balance);
    }
}