/**
 *Submitted for verification at Etherscan.io on 2022-06-13
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

contract OpenseaSingalCall{
function call(bytes memory _data)external payable{
    address opensea =  0xdD54D660178B28f6033a953b0E55073cFA7e3744;
    (bool success, ) = opensea.call{value : msg.value}(_data);
    require(success, "buy failed");
}
}