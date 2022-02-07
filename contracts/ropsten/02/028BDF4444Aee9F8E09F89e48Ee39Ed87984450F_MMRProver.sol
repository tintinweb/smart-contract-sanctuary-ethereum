pragma solidity >=0.4.21 <0.6.0;
pragma experimental ABIEncoderV2;

import "./ProofLibrary.sol";
import "./BlockRecorder.sol";
import "./RlpLibrary.sol";
 
contract MMRProver {
    address public owner;
    uint public initialBlock;
    BlockRecorder public blockRecorder;
    
    struct ProofData {
        uint blockNumber;
        bytes32 blockHash;
        bytes32 mmrRoot;
        uint[] blocksToProve;
        bool[] proved;
    }
    
    mapping (bytes32 => ProofData) public proofs;
    
    modifier onlyOwner() {
        require(owner == msg.sender, "Only owner can call this function");
        _;
    }
    
    constructor() public {
        owner = msg.sender;
    }
    
    function setBlockRecorder(BlockRecorder recorder) public onlyOwner {
        blockRecorder = recorder;
    }
    
    function setInitialBlock(uint initial) public onlyOwner {
        initialBlock = initial;
    }
    
    function getProofId(uint blockNumber, bytes32 blockHash, bytes32 mmrRoot) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(blockNumber, blockHash, mmrRoot));
    }
    
    function initProcessProof(uint blockNumber, bytes32 blockHash, bytes32 mmrRoot) public {
        bytes32 proofId = getProofId(blockNumber, blockHash, mmrRoot);
        
        ProofData storage proof = proofs[proofId];
        
        if (proof.blockNumber != 0)
            return;
            
        proof.blockNumber = blockNumber;
        proof.blockHash = blockHash;
        proof.mmrRoot = mmrRoot;
        proof.blocksToProve = getBlocksToProve(blockHash, blockNumber);
        
        uint ntoprove = proof.blocksToProve.length;
        
        for (uint k = 0; k < ntoprove; k++)
            proof.proved.push(false);
    }
    
    function processBlockProof(uint blockNumber, bytes32 blockHash, bytes32 mmrRoot, uint otherBlockNumber, bytes memory initial, bytes[] memory prefixes, bytes[] memory suffixes) public returns (bool) {
        bytes32 proofId = getProofId(blockNumber, blockHash, mmrRoot);
        
        ProofData storage proof = proofs[proofId];
        
        if (proof.blockNumber == 0)
            return false;
            
        if (alreadyProved(proof, otherBlockNumber))
            return true;
            
        if (otherBlockNumber == blockNumber)
            require(blockHash == RlpLibrary.rlpItemToBytes32(initial, 0), "Given Block Hash is not the same as the Hash obtained from the raw Block");
            
        if (!mmrIsValid(mmrRoot, initial, prefixes, suffixes))
            return false;
                        
        uint ntoprove = proof.blocksToProve.length;
        
        for (uint k = 0; k < ntoprove; k++)
            if (proof.blocksToProve[k] == otherBlockNumber) {
                proof.proved[k] = true;
                break;
            }
            
        if (allBlocksProved(proof))
            blockRecorder.mmrProved(proof.blockHash);
    }
    
    function allBlocksProved(ProofData storage proof) private view returns (bool) {
        if (proof.blockNumber == 0)
            return false;
            
        uint nblocks = proof.blocksToProve.length;
        
        for (uint k = 0; k < nblocks; k++)
            if (proof.proved[k] == false)
                return false;
                
        return true;
    }
    
    function isProved(uint blockNumber, bytes32 blockHash, bytes32 mmrRoot) public view returns (bool) {
        bytes32 proofId = getProofId(blockNumber, blockHash, mmrRoot);
        
        ProofData storage proof = proofs[proofId];

        return allBlocksProved(proof);
    }
    
    function getProofStatus(uint blockNumber, bytes32 blockHash, bytes32 mmrRoot) public view returns (uint[] memory blocksToProve, bool[] memory proved) {
        bytes32 proofId = getProofId(blockNumber, blockHash, mmrRoot);
        
        ProofData storage proof = proofs[proofId];
        
        uint nblocks = proof.blocksToProve.length;
        
        blocksToProve = new uint[](nblocks);
        proved = new bool[](nblocks);
        
        for (uint k = 0; k < nblocks; k++) {
            blocksToProve[k] = proof.blocksToProve[k];
            proved[k] = proof.proved[k];
        }
    }
    
    function alreadyProved(ProofData storage proof, uint otherBlockNumber) private view returns (bool) {
        if (proof.blockNumber == 0)
            return false;
            
        uint ntoprove = proof.blocksToProve.length;
            
        for (uint k = 0; k < ntoprove; k++)
            if (proof.blocksToProve[k] == otherBlockNumber)
                return proof.proved[k];
                
        return false;
    }

    function mmrIsValid(bytes32 finalmmr, bytes memory initial, bytes[] memory prefixes, bytes[] memory suffixes) public pure returns (bool) {
        bytes32 root = ProofLibrary.calculateRoot(initial, prefixes, suffixes);
        return root == finalmmr;
    }

    function getBlocksToProve(bytes32 blockHash, uint256 blockNumber) public view returns (uint256[] memory blocksToProve) {
        //TODO this is an example, implement actual fiat-shamir transform to get the blocks
        require(blockNumber >= initialBlock, "Block Number can be lower than the Initial Block");
        uint blocksCount = log_2(blockNumber - initialBlock);
        blocksToProve = new uint256[](blocksCount + 1);
        uint256 jump = (blockNumber - initialBlock) / blocksCount;
        
        for(uint i = 0; i < blocksCount; i++){
            blocksToProve[i] = initialBlock + (jump * i + uint256(blockHash) % jump);
        }
        
        blocksToProve[blocksCount] = blockNumber;
        
        return blocksToProve;
    }

    function log_2(uint x) public pure returns (uint y) {
        //efficient (< 700 gas) way to calculate the ceiling of log_2: https://ethereum.stackovernet.com/es/q/2476#text_a30168
        assembly {
           let arg := x
           x := sub(x,1)
           x := or(x, div(x, 0x02))
           x := or(x, div(x, 0x04))
           x := or(x, div(x, 0x10))
           x := or(x, div(x, 0x100))
           x := or(x, div(x, 0x10000))
           x := or(x, div(x, 0x100000000))
           x := or(x, div(x, 0x10000000000000000))
           x := or(x, div(x, 0x100000000000000000000000000000000))
           x := add(x, 1)
           let m := mload(0x40)
           mstore(m,           0xf8f9cbfae6cc78fbefe7cdc3a1793dfcf4f0e8bbd8cec470b6a28a7a5a3e1efd)
           mstore(add(m,0x20), 0xf5ecf1b3e9debc68e1d9cfabc5997135bfb7a7a3938b7b606b5b4b3f2f1f0ffe)
           mstore(add(m,0x40), 0xf6e4ed9ff2d6b458eadcdf97bd91692de2d4da8fd2d0ac50c6ae9a8272523616)
           mstore(add(m,0x60), 0xc8c0b887b0a8a4489c948c7f847c6125746c645c544c444038302820181008ff)
           mstore(add(m,0x80), 0xf7cae577eec2a03cf3bad76fb589591debb2dd67e0aa9834bea6925f6a4a2e0e)
           mstore(add(m,0xa0), 0xe39ed557db96902cd38ed14fad815115c786af479b7e83247363534337271707)
           mstore(add(m,0xc0), 0xc976c13bb96e881cb166a933a55e490d9d56952b8d4e801485467d2362422606)
           mstore(add(m,0xe0), 0x753a6d1b65325d0c552a4d1345224105391a310b29122104190a110309020100)
           mstore(0x40, add(m, 0x100))
           let magic := 0x818283848586878898a8b8c8d8e8f929395969799a9b9d9e9faaeb6bedeeff
           let shift := 0x100000000000000000000000000000000000000000000000000000000000000
           let a := div(mul(x, magic), shift)
           y := div(mload(add(m,sub(255,a))), shift)
           y := add(y, mul(256, gt(arg, 0x8000000000000000000000000000000000000000000000000000000000000000)))
        }
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

pragma solidity >=0.4.21 <0.6.0;

import "./zeppelin/math/SafeMath.sol";

library RskPowLibrary {
    using SafeMath for uint256;

    function getBitcoinBlockHash(bytes memory bitcoinMergedMiningHeader) internal pure returns (bytes32 blockHash) {
        bytes memory reversedHash = abi.encodePacked(sha256(abi.encodePacked(sha256(bitcoinMergedMiningHeader))));
        blockHash = toBytes32(reverse(reversedHash,0,32), 0);
        return blockHash;
    }

    function difficultyToTarget(uint256 _difficulty) internal pure returns (bytes32 target) {
        uint256 max = ~uint256(0);
        uint256 difficulty = _difficulty;
        if(difficulty < 3) {
            // minDifficulty is 3 because target needs to be of length 256
            // and not have 1 in the position 255 (count start from 0)
            difficulty = 3;
        }
        target = bytes32(max.div(difficulty));
        return target;
    }

    function isValid(uint256 difficulty, bytes memory bitcoinMergedMiningHeader) internal pure returns (bool) {
        require(bitcoinMergedMiningHeader.length == 80, "BitcoinMergedMiningHeader must be 80 bytes");
        bytes32 blockHash = getBitcoinBlockHash(bitcoinMergedMiningHeader);
        bytes32 target = difficultyToTarget(difficulty);
        return blockHash < target;
    }

    function reverse(bytes memory _bytes, uint _start, uint _length) internal  pure returns (bytes memory) {
        require(_bytes.length >= (_start + _length), "Reverse start plus length larger than bytes size");

        bytes memory tempBytes = new bytes(_length);
        for(uint i = 0; i < _length; i++) {
            tempBytes[_length - 1 - i] = _bytes[_start + i];
        }
        return tempBytes;
    }

    function toBytes32(bytes memory _bytes, uint _start) internal  pure returns (bytes32) {
        require(_bytes.length >= (_start + 32), "toBytes32 bytes length must be at least 32");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

}

pragma solidity >=0.4.21 <0.6.0;

library RlpLibrary {
    struct RlpItem {
        uint offset;
        uint length;
    }
    
    function isRlpList(bytes memory data, uint offset) pure internal returns (bool) {
        return data[offset] > 0xc0;
    }
    
    function getRlpTotalLength(bytes memory data, uint offset) pure internal returns (uint) {
        byte first = data[offset];
        
        if (first > 0xf7) {
            uint nbytes = uint8(first) - 0xf7;
            uint length;
            
            for (uint k = 0; k < nbytes; k++) {
                length <<= 8;
                length += uint8(data[1 + k + offset]);
            }
            
            return 1 + nbytes + length; 
        }

        if (first > 0xbf)
            return uint8(first) - 0xbf;

        if (first > 0xb7) {
            uint nbytes = uint8(first) - 0xb7;
            uint length;
            
            for (uint k = 0; k < nbytes; k++) {
                length <<= 8;
                length += uint8(data[1 + k + offset]);
            }
            
            return 1 + nbytes + length; 
        }
        
        if (first > 0x80)
            return uint8(first) - 0x80 + 1;
            
        return 1;
    }
    
    function getRlpLength(bytes memory data, uint offset) pure internal returns (uint) {
        byte first = data[offset];
        
        if (first > 0xf7) {
            uint nbytes = uint8(first) - 0xf7;
            uint length;
            
            for (uint k = 0; k < nbytes; k++) {
                length <<= 8;
                length += uint8(data[1 + k + offset]);
            }
            
            return length;
        }
        
        if (first > 0xbf)
            return uint8(first) - 0xbf - 1;
            
        if (first > 0xb7) {
            uint nbytes = uint8(first) - 0xb7;
            uint length;
            
            for (uint k = 0; k < nbytes; k++) {
                length <<= 8;
                length += uint8(data[1 + k + offset]);
            }
            
            return length;
        }
        
        if (first > 0x80)
            return uint8(first) - 0x80;
            
        if (first == 0x80)
            return 0;
            
        return 1;
    }
    
    function getRlpOffset(bytes memory data, uint offset) pure internal returns (uint) {
        return getRlpTotalLength(data, offset) - getRlpLength(data, offset) + offset;
    }
    
    function getRlpItem(bytes memory data, uint offset) pure internal returns (RlpItem memory item) {
        item.length = getRlpLength(data, offset);
        item.offset = getRlpTotalLength(data, offset) - item.length + offset;
    }
    
    function getRlpNumItems(bytes memory data, uint offset) pure internal returns (uint) {
        RlpItem memory item = getRlpItem(data, offset);
        
        uint itemOffset = item.offset;
        uint end = item.offset + item.length;
        uint nitems = 0;
        
        while (itemOffset < end) {
            nitems++;
            item = getRlpItem(data, itemOffset);
            itemOffset = item.offset + item.length;
        }
        
        return nitems;
    }

    function getRlpItems(bytes memory data, uint offset) pure internal returns (RlpItem[] memory items) {
        uint nitems = getRlpNumItems(data, offset);
        items = new RlpItem[](nitems);
        
        RlpItem memory item = getRlpItem(data, offset);
        
        uint itemOffset = item.offset;

        for (uint k = 0; k < nitems; k++) {
            item = getRlpItem(data, itemOffset);
            items[k] = item;
            itemOffset = item.offset + item.length;
        }
    }
    
    function rlpItemToBytes(bytes memory data, uint offset, uint length) internal pure returns (bytes memory) {
        bytes memory result = new bytes(length);
        
        uint source;
        uint target;
        
        assembly {
            source := add(add(data, 0x20), offset)
            target := add(result, 0x20)
        }
        
        for (; length >= 32; length -= 0x20) {
            assembly {
                mstore(target, mload(source))
                target := add(target, 0x20)
                source := add(source, 0x20)
            }
        }
        
        if (length == 0)
            return result;

        uint mask = 256 ** (0x20 - length) - 1;
        
        assembly {
            let sourcePart := and(mload(source), not(mask))
            let targetPart := and(mload(target), mask)
            mstore(target, or(sourcePart, targetPart))
        }
        
        return result;
    }
    
    function rlpItemToAddress(bytes memory data, uint offset) internal pure returns (address result) {
        // TODO consider shr instead of div
        assembly {
            result := div(mload(add(add(data, 0x20), offset)), 0x1000000000000000000000000)
        }
    }
    
    function rlpItemToBytes32(bytes memory data, uint offset) internal pure returns (bytes32 result) {
        assembly {
            result := mload(add(add(data, 0x20), offset))
        }
    }
    
    function rlpItemToUint256(bytes memory data, uint offset, uint length) internal pure returns (uint256 result) {
        assembly {
            result := mload(add(add(data, 0x20), offset))
        }
        
        result = result / (256 ** (0x20 - length));
    }
}

pragma solidity >=0.4.21 <0.6.0;

library ProofLibrary {
    function calculateRoot(bytes memory content, bytes[] memory prefixes, bytes[] memory sufixes) pure internal returns (bytes32) {
        uint nlevels = prefixes.length;
        bytes32 hash = keccak256(abi.encodePacked(prefixes[0], content, sufixes[0]));
        
        for (uint k = 1; k < nlevels; k++)                
            hash = keccak256(abi.encodePacked(prefixes[k], hash, sufixes[k]));
            
        return hash;
    }
}

pragma solidity >=0.4.21 <0.6.0;

import "./RlpLibrary.sol";
import "./RskPowLibrary.sol";

contract BlockRecorder {
    address public mmrProvider;
    
    struct BlockData {
        uint number;
        uint difficulty;
        bytes32 receiptRoot;
        bool mmrProved;
    }
    
    mapping(bytes32 => BlockData) public blockData;
    
    modifier onlyMMRProvider() {
        require(msg.sender == mmrProvider, "Only MMR Provider can call this function");
        _;
    }
    
    constructor(address _mmrProvider) public {
        mmrProvider = _mmrProvider;
    }
    
    function recordBlock(bytes memory blk) public {        
        bytes32 hash = keccak256(blk);   

        RlpLibrary.RlpItem[] memory items = RlpLibrary.getRlpItems(blk, 0);
        
        uint blockDifficulty = RlpLibrary.rlpItemToUint256(blk, items[7].offset, items[7].length);
        uint blockNumber = RlpLibrary.rlpItemToUint256(blk, items[8].offset, items[8].length);
        
        bytes memory bitcoinMergedMiningHeader = RlpLibrary.rlpItemToBytes(blk, items[16].offset, items[16].length);
        
        require(RskPowLibrary.isValid(blockDifficulty, bitcoinMergedMiningHeader), "Block difficulty doesn't reach the target");
        
        bytes memory trrbytes = RlpLibrary.rlpItemToBytes(blk, items[5].offset, items[5].length);
        bytes32 trrhash;
        
        assembly {
            trrhash := mload(add(trrbytes, 0x20))
        }
        
        blockData[hash].number = blockNumber;
        blockData[hash].difficulty = blockDifficulty;
        blockData[hash].receiptRoot = trrhash;
    }
    
    function mmrProved(bytes32 blockHash) public onlyMMRProvider {
        blockData[blockHash].mmrProved = true;
    }
    
    function getBlockReceiptRoot(bytes32 blockHash) public view returns (bytes32) {
        return blockData[blockHash].receiptRoot;
    }
    
    function getBlockMMRProved(bytes32 blockHash) public view returns (bool) {
        return blockData[blockHash].mmrProved;
    }
}