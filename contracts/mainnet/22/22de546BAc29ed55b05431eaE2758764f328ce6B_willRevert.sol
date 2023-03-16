/**
 *Submitted for verification at Etherscan.io on 2023-03-15
*/

pragma solidity ^0.8.18;

error thisIsACustomError();

contract willRevert {
    function doRevert() external {
        revert thisIsACustomError();
    }
}