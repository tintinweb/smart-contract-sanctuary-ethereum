pragma solidity >=0.4.21 <0.6.0;
pragma experimental ABIEncoderV2;

import "./ReceiptProver.sol";
import "./EventsLibrary.sol";
import "./Transferable.sol";

contract EventsProcessor {
    address owner;

    ReceiptProver public prover;
    Transferable public transferable;
    address public origin;
    bytes32 public transferTopic;
    bytes32 public tokenTopic;
    
    mapping (bytes32 => bool) public processed;
    
    constructor(ReceiptProver _prover, bytes32 _transferTopic, bytes32 _tokenTopic) public {
        owner = msg.sender;
        prover = _prover;
        transferTopic = _transferTopic;
        tokenTopic = _tokenTopic;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Sender is not the owner");
        _;
    }

    function setTransferable(Transferable _transferable) public onlyOwner {
        require(address(transferable) == address(0), "Try to reset transferable");
        transferable = _transferable;
    }

    function setOrigin(address _origin) public onlyOwner {
        require(address(origin) == address(0), "Try to reset origin");
        origin = _origin;
    }
    
    function processReceipt(bytes32 blkhash, bytes memory receipt, bytes[] memory prefixes, bytes[] memory suffixes) public {
        bytes32 hash = keccak256(abi.encodePacked(blkhash, receipt));
        
        // TODO consider require
        if (processed[hash])
            return;
            
        require(prover.receiptIsValid(blkhash, receipt, prefixes, suffixes), "Invalid receipt");

        EventsLibrary.TokenEvent[] memory tkevents = EventsLibrary.getTokenEvents(receipt, origin, tokenTopic);
        uint ntkevents = tkevents.length;
        
        for (uint k = 0; k < ntkevents; k++) {
            EventsLibrary.TokenEvent memory tkevent = tkevents[k];
            
            if (tkevent.token != address(0))
                transferable.processToken(tkevent.token, tkevent.symbol);
        }
        
        EventsLibrary.TransferEvent[] memory tevents = EventsLibrary.getTransferEvents(receipt, origin, transferTopic);
        uint nevents = tevents.length;
        
        for (uint k = 0; k < nevents; k++) {
            EventsLibrary.TransferEvent memory tevent = tevents[k];
            
            if (tevent.amount != 0)
                transferable.acceptTransfer(tevent.token, tevent.receiver, tevent.amount);
        }
        
        processed[hash] = true;
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

contract Transferable {
    function acceptTransfer(address originalTokenAddress, address receiver, uint256 amount) public returns(bool);
    function processToken(address token, string memory symbol) public returns (bool);
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
pragma experimental ABIEncoderV2;

import "./BlockRecorder.sol";
import "./ProofLibrary.sol";

import "./RlpLibrary.sol";

contract ReceiptProver {
    BlockRecorder public blockRecorder;
    
    constructor(BlockRecorder recorder) public {
        blockRecorder = recorder;
    }
    
    function receiptIsValid(bytes32 blkhash, bytes memory receipt, bytes[] memory prefixes, bytes[] memory suffixes) public view returns (bool) {
        require(blockRecorder.getBlockMMRProved(blkhash), "Block has not been recorded yet");
        
        bytes32 receiptRoot = ProofLibrary.calculateRoot(receipt, prefixes, suffixes);
        
        return blockRecorder.getBlockReceiptRoot(blkhash) == receiptRoot;
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

library EventsLibrary {
    struct TransferEvent {
        address token;
        address receiver;
        uint amount;
    }
    
    struct TokenEvent {
        address token;
        string symbol;
    }
    
    function getTokenEvents(bytes memory receipt, address origin, bytes32 topic) internal pure returns(TokenEvent[] memory tevents) {
        RlpLibrary.RlpItem[] memory items = RlpLibrary.getRlpItems(receipt, 0);        
        RlpLibrary.RlpItem[] memory events = RlpLibrary.getRlpItems(receipt, items[2].offset + items[2].length);
    
        uint nevents = events.length;
        
        tevents = new TokenEvent[](nevents);

        uint j = 0;
        
        for (uint k = 0; k < nevents; k++) {
            uint offset = (k == 0) ? items[3].offset : events[k - 1].offset + events[k - 1].length;
            RlpLibrary.RlpItem[] memory evitems = RlpLibrary.getRlpItems(receipt, offset);
            
            if (RlpLibrary.rlpItemToAddress(receipt, evitems[0].offset) != origin)
                continue;
                
            RlpLibrary.RlpItem[] memory evtopics = RlpLibrary.getRlpItems(receipt, evitems[0].offset + evitems[0].length);

            if (RlpLibrary.rlpItemToBytes32(receipt, evtopics[0].offset) != topic)
                continue;
                
            uint symlength = uint256(RlpLibrary.rlpItemToBytes32(receipt, evitems[2].offset + 32));
                
            tevents[j] = TokenEvent(
                RlpLibrary.rlpItemToAddress(receipt, evtopics[1].offset + 12),
                string(RlpLibrary.rlpItemToBytes(receipt, evitems[2].offset + 64, symlength))
            );
            
            j++;
        }
    }
    
    function getTransferEvents(bytes memory receipt, address origin, bytes32 topic) internal pure returns(TransferEvent[] memory tevents) {
        RlpLibrary.RlpItem[] memory items = RlpLibrary.getRlpItems(receipt, 0);        
        RlpLibrary.RlpItem[] memory events = RlpLibrary.getRlpItems(receipt, items[2].offset + items[2].length);
    
        uint nevents = events.length;
        
        tevents = new TransferEvent[](nevents);

        uint j = 0;
        
        for (uint k = 0; k < nevents; k++) {
            uint offset = (k == 0) ? items[3].offset : events[k - 1].offset + events[k - 1].length;
            RlpLibrary.RlpItem[] memory evitems = RlpLibrary.getRlpItems(receipt, offset);
            
            if (RlpLibrary.rlpItemToAddress(receipt, evitems[0].offset) != origin)
                continue;
                
            RlpLibrary.RlpItem[] memory evtopics = RlpLibrary.getRlpItems(receipt, evitems[0].offset + evitems[0].length);
           
            if (RlpLibrary.rlpItemToBytes32(receipt, evtopics[0].offset) != topic)
                continue;
                
            tevents[j] = TransferEvent(
                RlpLibrary.rlpItemToAddress(receipt, evtopics[1].offset + 12),
                RlpLibrary.rlpItemToAddress(receipt, evtopics[2].offset + 12),
                uint256(RlpLibrary.rlpItemToBytes32(receipt, evitems[2].offset))
            );
            
            j++;
        }
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