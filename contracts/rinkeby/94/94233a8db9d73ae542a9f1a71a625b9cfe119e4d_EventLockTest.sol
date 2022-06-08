/**
 *Submitted for verification at Etherscan.io on 2022-06-08
*/

pragma solidity ^0.8.0;
contract EventLockTest {
    event Locked(address userAddress, address nftAddress, uint tokenId);
    function lockTokens(address userAddress, address nftAddress, uint tokenId) external {
        emit Locked(userAddress, nftAddress, tokenId);
    }
}