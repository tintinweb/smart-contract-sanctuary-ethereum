/**
 *Submitted for verification at Etherscan.io on 2022-03-02
*/

pragma solidity 0.8.12;

interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract UniV3Lock  {
    address public uniV3Nft;

    event LpPositionLocked(address owner, uint tokenId, uint unlockTime);
    event LpPositionUnlocked(address owner, uint tokenId);
   
    constructor(address _uniV3Nft) {
        require(_uniV3Nft != address(0), "_uniV3Nft is address zero");
        uniV3Nft = _uniV3Nft;
    }
    
    mapping(uint => address) tokenIdToDepositor;
    mapping(uint => uint) tokenIdToUnlockTime;
    
    function lock(uint _tokenId, uint _unlockTime) external {
        require(_unlockTime > block.timestamp, "unlockTime already passed");
        IERC721(uniV3Nft).transferFrom(msg.sender, address(this), _tokenId);
        tokenIdToDepositor[_tokenId] = msg.sender;
        tokenIdToUnlockTime[_tokenId] = _unlockTime;
        emit LpPositionLocked(msg.sender, _tokenId, _unlockTime);
    }

    function relock(uint _tokenId, uint _unlockTime) external {
        require(tokenIdToDepositor[_tokenId] == msg.sender, "caller is not depositor of token");
        require(_unlockTime > tokenIdToUnlockTime[_tokenId], "new unlockTime not greater than current");
        require(_unlockTime > block.timestamp, "unlockTime already passed");
        tokenIdToUnlockTime[_tokenId] = _unlockTime;
        emit LpPositionLocked(msg.sender, _tokenId, _unlockTime);
    }

    function unlock(uint _tokenId) external {
        require(tokenIdToDepositor[_tokenId] == msg.sender, "caller is not depositor of token");
        require(block.timestamp >= tokenIdToUnlockTime[_tokenId], "lock not yet expired");
        IERC721(uniV3Nft).transferFrom(address(this), msg.sender, _tokenId);
        tokenIdToDepositor[_tokenId] = address(0);
        tokenIdToUnlockTime[_tokenId] = 0;
        emit LpPositionUnlocked(msg.sender, _tokenId);
    } 
}