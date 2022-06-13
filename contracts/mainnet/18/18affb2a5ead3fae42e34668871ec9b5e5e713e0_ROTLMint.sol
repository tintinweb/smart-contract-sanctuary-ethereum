// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./SafeMath.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";
import "./ROTL.sol";
import "./Pausable.sol";

contract ROTLMint is Ownable, Pausable {
    using SafeMath for uint256;

    struct Round {
        uint256 _price;
        uint256 _maxCount;
        uint256 _onceMaxCount;
        uint256 _addressMaxCount;
        uint256 _startBlock;
        bytes32 _merkleRoot;

        mapping (address => uint256) _minted;
    }

    event SetAddress(address nft);
    event SetRound(uint256 round);
    event SetRoundInfo(
        uint256 round, 
        uint256 price, 
        uint256 maxCount, 
        uint256 onceMaxCount,
        uint256 addressMaxCount,
        uint256 startBlock,
        bytes32 merkleRoot
    );

    ROTL private _nft;

    uint256 private _currentRound;
    mapping (uint256 => Round) private _round;

    function setAddress(address nft) external onlyOwner {
        _nft = ROTL(nft);
        emit SetAddress(nft);
    }

    function setRound(
        uint256 round
    ) external onlyOwner {
        _currentRound = round;
        emit SetRound(round);
    }

    function setRoundInfo(
        uint256 round, 
        uint256 price, 
        uint256 maxCount, 
        uint256 onceMaxCount,
        uint256 addressMaxCount,
        uint256 startBlock,
        bytes32 merkleRoot
    ) external onlyOwner {
        Round storage v = _round[round];
        v._price = price;
        v._maxCount = maxCount;
        v._onceMaxCount = onceMaxCount;
        v._addressMaxCount = addressMaxCount;
        v._startBlock = startBlock;
        v._merkleRoot = merkleRoot;
        
        emit SetRoundInfo(round, price, maxCount, onceMaxCount, addressMaxCount, startBlock, merkleRoot);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function isEnable() external view returns (bool) {
        return __isEnable();
    }

    function __isEnable() internal view returns (bool) {
        return 0 < __getRemainCount() && !paused();
    }

    function getRemainCount() external view returns (uint256) {
        return __getRemainCount();
    }

    function __getRemainCount() internal view returns (uint256) {
        uint256 supply = _nft.totalSupply();
        Round storage info = __getCurrentRoundInfo();
        if (info._maxCount < supply)
            return 0;
        return info._maxCount.sub(supply);
    }

    function getCurrentRoundInfo() external view returns (uint256, uint256, uint256, uint256, uint256) {
        Round storage info = __getCurrentRoundInfo();
        return (info._price, info._maxCount, info._onceMaxCount, info._addressMaxCount, info._startBlock);
    }

    function __getCurrentRoundInfo() internal view returns (Round storage) {
        return _round[_currentRound];
    }

    function getCurrentRound() external view returns (uint256) {
        return _currentRound;
    }

    function getMintedCount(uint256 round, address target) external view returns (uint256) {
        return _round[round]._minted[target];
    }

    function mint(uint256 round, uint256 count, bytes32[] calldata merkleProof) external payable whenNotPaused {
        // check round
        require (_currentRound == round, "require _currentRound == round");
        Round storage info = __getCurrentRoundInfo();
        // check price
        require (msg.value == info._price * count, "require msg.value == price * count");
        // check block
        require (info._startBlock <= block.number, "require info._startBlock <= block.number");
        // check merkle root
        if (info._merkleRoot != "") {
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require (MerkleProof.verify(merkleProof, info._merkleRoot, leaf), "invalid merkle proof");
        }

        // check address max count.
        if (0 < info._addressMaxCount) {
            info._minted[msg.sender] = info._minted[msg.sender].add(count);
            require (info._minted[msg.sender] <= info._addressMaxCount, "over address max count");
        }
        // mint
        __mint(info, count);
    }

    function __mint(Round storage info, uint256 count) internal {
        require (__isEnable() == true, "disable contract");
        require (0 < count, "require 0 < count");
        require (count <= info._onceMaxCount, "require count <= _onceMaxCount");
        require (count <= __getRemainCount(), "require count <= __getRemainCount()");
        _nft.mint(1, msg.sender, count);
    }

    function withdraw(address payable to, uint256 value) external onlyOwner {
        to.transfer(value);
    }
}