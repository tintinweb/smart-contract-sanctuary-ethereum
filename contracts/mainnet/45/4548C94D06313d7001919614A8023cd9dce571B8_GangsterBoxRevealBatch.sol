/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface iGasEvo {
    function _trueOwnerOf(uint256 tokenId_) external view returns (address);
    function isTrueOwnerOfAll(address owner, uint256[] calldata tokenIds_) 
    external view returns (bool);
}

contract GangsterBoxRevealBatch {
    
    // Interface with GAS EVO
    iGasEvo public GasEvo = iGasEvo(0xa9BA1A433Ec326bca975aef9a1641B42717197e7);

    // Mapping of packed reveal datas for tokenIds
    mapping(uint256 => bool[32]) public tokenBatchToRevealed;

    //////////////////////////////////////
    //        Internal Functions        //
    //////////////////////////////////////

    function _readTokenBatchData(uint256 batchId_) public view 
    returns (bool[32] memory) {
        return tokenBatchToRevealed[batchId_];
    }
    function _readTokenBatchDatas(uint256[] calldata batchIds_) public view 
    returns (bool[32][] memory) {
        uint256 i;
        uint256 l = batchIds_.length;
        bool[32][] memory _batches = new bool[32][] (l);
        unchecked { do { 
            _batches[i] = _readTokenBatchData(i);
        } while (++i < l); }
        return _batches;
    }

    function _getBatchIdOfTokenId(uint256 tokenId_) public pure returns (uint256) {
        return tokenId_ / 32; 
    }
    function _getSlotIdOfTokenId(uint256 tokenId_) public pure returns (uint256) {
        return tokenId_ % 32; 
    }
    
    function _getBatchesForTokens(uint256[] calldata tokenIds_) public pure
    returns (uint256[] memory) {
        uint256 i;
        uint256 l = tokenIds_.length;
        uint256[] memory _batches = new uint256[] (l);
        unchecked { do {
            _batches[i] = _getBatchIdOfTokenId(tokenIds_[i]);
        } while (++i < l); }
        return _batches;
    }
    function _getSlotsForTokens(uint256[] calldata tokenIds_) public pure
    returns (uint256[] memory) {
        uint256 i;
        uint256 l = tokenIds_.length;
        uint256[] memory _batches = new uint256[] (l);
        unchecked { do {
            _batches[i] = _getSlotIdOfTokenId(tokenIds_[i]);
        } while (++i < l); }
        return _batches;
    }

    //////////////////////////////////////
    //          Write Functions         //
    //////////////////////////////////////

    function revealTokenSingle(uint256 tokenId_) public {
        uint256 _batch = _getBatchIdOfTokenId(tokenId_);
        uint256 _slot = _getSlotIdOfTokenId(tokenId_);
        require(msg.sender == GasEvo._trueOwnerOf(tokenId_), 
            "You are not the owner of this token!");
        tokenBatchToRevealed[_batch][_slot] = true;
    }
    function revealTokenBatch(uint256[] calldata tokenIds_) public {
        uint256 i;
        uint256 l = tokenIds_.length;
        uint256[] memory _batches = _getBatchesForTokens(tokenIds_);
        uint256[] memory _slots = _getSlotsForTokens(tokenIds_);
        
        // Patch 2.1 Implementation
        require(GasEvo.isTrueOwnerOfAll(msg.sender, tokenIds_), 
            "Not owner of tokens!");
        
        unchecked { do { 
            tokenBatchToRevealed[_batches[i]][_slots[i]] = true;
        } while (++i < l); }
    }

    //////////////////////////////////////
    //    Front-End Helper Functions    //
    //////////////////////////////////////

    function tokenIsRevealed(uint256 tokenId_) public view returns (bool) {
        uint256 _batch = _getBatchIdOfTokenId(tokenId_);
        uint256 _slot = _getSlotIdOfTokenId(tokenId_);
        return tokenBatchToRevealed[_batch][_slot];
    }
    function tokensAreRevealed(uint256[] calldata tokenIds_) public view 
    returns (bool[] memory) {
        uint256 i;
        uint256 l = tokenIds_.length;
        bool[] memory _revealeds = new bool[](l);
        unchecked { do { 
            _revealeds[i] = tokenIsRevealed(tokenIds_[i]);
        } while (++i < l); }
        return _revealeds;
    }
}