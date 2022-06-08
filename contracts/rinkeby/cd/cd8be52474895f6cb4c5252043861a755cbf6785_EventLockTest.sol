/**
 *Submitted for verification at Etherscan.io on 2022-06-08
*/

pragma solidity ^0.8.0;
contract EventLockTest {
    event Locked(address _user, address _nftAddress, uint tokenId);
    function lockTokens(address _userAddress, address _nftAddress, uint tokenId) external {
        emit Locked(_userAddress, _nftAddress, tokenId);
    }
}