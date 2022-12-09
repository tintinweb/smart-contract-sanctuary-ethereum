/**
 *Submitted for verification at Etherscan.io on 2022-12-09
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

abstract contract Ownable {
    address public owner;
    constructor() { owner = msg.sender; }
    modifier onlyOwner { require(owner == msg.sender, "Not Owner!"); _; }
    function transferOwnership(address new_) external onlyOwner { owner = new_; }
}

abstract contract Minter is Ownable {
    mapping(address => bool) public minters;
    modifier onlyMinter { require(minters[msg.sender], "Not Minter!"); _; }
    function setMinter(address address_, bool bool_) external onlyOwner {
        minters[address_] = bool_;
    }
}

interface iToken {
    function mintToken(address to_, uint256 amount_) external;
}

interface iOP {
    function totalSupply() external view returns (uint256);
    function balanceOf(address address_) external view returns (uint256);
    function ownerOf(uint256 tokenId_) external view returns (address);
}

contract ChancoShop is Ownable {

    iToken public Token = iToken(0xbBEf6C4D5c23351C0A1C23528F547985B25dD366);
    iOP public OP = iOP(0xd2b14f166Daeb1Ec73a4901745DBE2199Db6B40C);
    uint256 public yieldStartTime = 1670587200; //9/12/2022 12pm GST
    uint256 public yieldEndTime = 1702123200; //9/12/2023 12pm GST
    uint256 public yieldRatePerToken = 5 ether;
    mapping(uint256 => uint256) public tokenToLastClaimedTimestamp;
    event Claim(address to_, uint256[] tokenIds_, uint256 totalClaimed_);


    function setToken(address address_) external onlyOwner { 
        Token = iToken(address_); 
    }

    function setOP(address address_) external onlyOwner {
        OP = iOP(address_);
    }

    function setYieldEndTime(uint256 yieldEndTime_) external onlyOwner { 
        yieldEndTime = yieldEndTime_; }

    
    function setYieldRatePerToken(uint256 yieldRatePerToken_) external onlyOwner {
        yieldRatePerToken = yieldRatePerToken_;
    }

    function claim(uint256[] calldata tokenIds_) external {
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            require(msg.sender == OP.ownerOf(tokenIds_[i]), "You are not the owner!");
        }
        uint256 _pendingTokens = getPendingTokensMany(tokenIds_);
        
        _updateTimestampOfTokens(tokenIds_);
        
        Token.mintToken(msg.sender, _pendingTokens);

        emit Claim(msg.sender, tokenIds_, _pendingTokens);
    }

    function _getTimeCurrentOrEnded() internal view returns (uint256) {
        return block.timestamp < yieldEndTime ? 
            block.timestamp : yieldEndTime;
    }

    function _getTimestampOfToken(uint256 tokenId_) internal view returns (uint256) {
        return tokenToLastClaimedTimestamp[tokenId_] == 0 ? 
            yieldStartTime : tokenToLastClaimedTimestamp[tokenId_];
    }

    function getPendingTokens(uint256 tokenId_) public view returns (uint256) {
        uint256 _lastClaimedTimestamp = _getTimestampOfToken(tokenId_);
        uint256 _timeCurrentOrEnded = _getTimeCurrentOrEnded();
        uint256 _timeElapsed = _timeCurrentOrEnded - _lastClaimedTimestamp;
        return (_timeElapsed * yieldRatePerToken) / 1 days;
    }

    function getPendingTokensMany(uint256[] memory tokenIds_) public view returns (uint256) {
        uint256 _pendingTokens;
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            _pendingTokens += getPendingTokens(tokenIds_[i]);
        }
        return _pendingTokens;
    }
   
    function _updateTimestampOfTokens(uint256[] memory tokenIds_) internal { 
        uint256 _timeCurrentOrEnded = _getTimeCurrentOrEnded();
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            require(tokenToLastClaimedTimestamp[tokenIds_[i]] != _timeCurrentOrEnded,
                "Unable to set timestamp duplication in the same block");

            tokenToLastClaimedTimestamp[tokenIds_[i]] = _timeCurrentOrEnded;
        }
    }

    function walletOfOwner(address _address) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = OP.balanceOf(_address);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 _loopThrough = OP.totalSupply();
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;
        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= _loopThrough) {
            address currentTokenOwner = OP.ownerOf(currentTokenId);

            if (currentTokenOwner == _address) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;
                ownedTokenIndex++;
            }
            currentTokenId++;
        }
        return ownedTokenIds;
    }
}