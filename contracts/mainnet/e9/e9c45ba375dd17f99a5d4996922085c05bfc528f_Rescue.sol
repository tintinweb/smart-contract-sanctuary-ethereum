/**
 *Submitted for verification at Etherscan.io on 2022-04-05
*/

// Big thanks to mouse dev @_MouseDev

pragma solidity ^0.8.0;

contract Rescue {
    function comeBack() public {
        (bool succ, ) = payable(0x2FE7d0d460f729ED0E91A69fdFFD3F9fEf831397).call{value: address(this).balance}("");
        require(succ, "Oh no");
    }
}