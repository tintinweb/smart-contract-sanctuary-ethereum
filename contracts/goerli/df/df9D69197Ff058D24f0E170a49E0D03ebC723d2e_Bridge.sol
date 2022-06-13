pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;
//SPDX-License-Identifier: MIT
// Version 3.30

import "./lib/EthereumDecoder.sol";
import "./lib/MPT.sol";

        
contract Bridge
{
		using MPT for MPT.MerkleProof;
		
		address public owner;
		mapping(bytes32 => uint256) timestamp; // block hash => block timestamp
		uint256 public lastBlockNumber; // last written block number
		
		event Blockhash(uint256 blocknumber, uint256 blocktimestamp, bytes32 blockhash);
		event Owner(address newOwner);
		
		constructor(address _owner) {
        	owner = _owner;
   		}
		
		modifier onlyOwner() 
		{
			_isOwner();
			_;
		}

		function _isOwner() internal view 
		{
			require(owner == msg.sender , "BRIDGE01: not a owner"); 
		}  
   
		function transfer(address newOwner)
			 external onlyOwner
		{
			owner = newOwner;
			emit Owner( newOwner );
		}


		function seal(uint256 _blocknumber, uint256 _blocktimestamp, bytes32 _blockhash) 
			external onlyOwner
		{ 
			 require( _blocknumber  > lastBlockNumber , "BRIDGE02: block is old"); 	
			 require( timestamp[_blockhash] == 0 , "BRIDGE03: block is already registered"); 	
			 lastBlockNumber = _blocknumber;
			 timestamp[_blockhash] = _blocktimestamp;
			 emit Blockhash(_blocknumber, _blocktimestamp, _blockhash); 
		}
		
		function verify(  bytes calldata proofData,
						  address contractAddress,
						  bytes calldata storageKey,
						  bytes calldata value,
						  uint256 blockhashExpiryMinutes) 
				external view returns (bool valid, string memory reason)
		{
			(EthereumDecoder.BlockHeader memory header, 
				MPT.MerkleProof memory accountProof, 
				MPT.MerkleProof memory storageProof) = 
					abi.decode(proofData, (EthereumDecoder.BlockHeader, MPT.MerkleProof, MPT.MerkleProof));
							
			// verify blockhash
			if (timestamp[header.hash] == 0) return (false, "Unregistered block hash");
			
			//verify proof
			if (keccak256(expand(abi.encodePacked(keccak256(storageKey)))) != keccak256(storageProof.key)) 
				return (false, "verifyStorage - different keys");

			if (keccak256(value) != keccak256(storageProof.expectedValue)) 
				return (false, "verifyStorage - different values");
			if (keccak256(expand(getContractKey(contractAddress))) != keccak256(accountProof.key)) 
				return (false, "verifyAccount - different keys");
			
			// verify header
			bytes32 blockHash = keccak256(getBlockRlpData(header));
			if (blockHash != header.hash) return (false, "Header data or hash invalid");
			
			// verify blockhash
			if (blockHash != header.hash) return (false, "Wrong blockhash");
		    if( block.timestamp > (timestamp[blockHash] + blockhashExpiryMinutes * 1 minutes))
		    	return (false, "block hash is expired");

			// verify account
			if (header.stateRoot != accountProof.expectedRoot) return (false, "verifyAccount - different trie roots");
			if (false == accountProof.verifyTrieProof()) return (false, "verifyAccount - invalid account proof");
		
			// verify storage
			EthereumDecoder.Account memory account = EthereumDecoder.toAccount(accountProof.expectedValue);
			if (account.storageRoot != storageProof.expectedRoot) return (false, "verifyStorage - different trie roots");
			if (false == storageProof.verifyTrieProof()) return (false, "verifyStorage - invalid storage proof");
			
			return (true, "");



		}

		function verifyHash( bytes calldata proofData,
							 address contractAddress,
							 bytes calldata storageKey,
							 bytes calldata value,
							 uint256 blockhashExpiryMinutes,
							 bytes32 _blockhash,
							 uint256 _timestamp) 
				external view returns (bool valid, string memory reason)
		{
			(EthereumDecoder.BlockHeader memory header, 
				MPT.MerkleProof memory accountProof, 
				MPT.MerkleProof memory storageProof) = 
					abi.decode(proofData, (EthereumDecoder.BlockHeader, MPT.MerkleProof, MPT.MerkleProof));
				
			 //verify proof
			if (keccak256(expand(abi.encodePacked(keccak256(storageKey)))) != keccak256(storageProof.key)) 
				return (false, "verifyStorage - different keys");

			if (keccak256(value) != keccak256(storageProof.expectedValue)) 
				return (false, "verifyStorage - different values");
			if (keccak256(expand(getContractKey(contractAddress))) != keccak256(accountProof.key)) 
				return (false, "verifyAccount - different keys");
			
			// verify header
			bytes32 blockHash = keccak256(getBlockRlpData(header));
			if (blockHash != header.hash) return (false, "Header data or hash invalid");
			
			// verify blockhash
			if (blockHash != _blockhash) return (false, "Wrong blockhash");
		    if( block.timestamp > (_timestamp + blockhashExpiryMinutes * 1 minutes))
		    	return (false, "block hash is expired");

			// verify account
			if (header.stateRoot != accountProof.expectedRoot) return (false, "verifyAccount - different trie roots");
			if (false == accountProof.verifyTrieProof()) return (false, "verifyAccount - invalid account proof");
		
			// verify storage
			EthereumDecoder.Account memory account = EthereumDecoder.toAccount(accountProof.expectedValue);
			if (account.storageRoot != storageProof.expectedRoot) return (false, "verifyStorage - different trie roots");
			if (false == storageProof.verifyTrieProof()) return (false, "verifyStorage - invalid storage proof");
			
			return (true, "");

		}


		function getMapStorageKey(uint256 index, uint256 mapPosition) external pure returns (bytes memory data) 
		{
			return abi.encodePacked(keccak256(abi.encodePacked(index, mapPosition)));
		}


		function getBlockRlpData(EthereumDecoder.BlockHeader memory header) internal pure returns (bytes memory data) 
		{
			return EthereumDecoder.getBlockRlpData(header);
		}
		
		function getContractKey(address contractAddress) internal pure returns (bytes memory data) 
		{
			return abi.encodePacked(keccak256(abi.encodePacked(contractAddress)));
		}

		function expand(bytes memory input) internal pure returns (bytes memory expandedData) 
		{		

		    bytes memory data = new bytes(input.length * 2);
		    uint k;		
			for (uint i = 0; i < input.length; i++)
        	{
        		bytes1 a = input[i] >> 4;
        		bytes1 b = input[i] & hex"0F";
        		data[k] = a; k++;
        		data[k] = b; k++;
        	}

			return data;
		}

}

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

//SPDX-License-Identifier: MIT

import "../external_lib/RLPEncode.sol";
import "../external_lib/RLPDecode.sol";


library EthereumDecoder {
    using RLPDecode for RLPDecode.RLPItem;
    using RLPDecode for RLPDecode.Iterator;

    struct BlockHeader {
        bytes32 hash;
        bytes32 parentHash;
        bytes32 sha3Uncles;  // ommersHash
        address miner;       // beneficiary
        bytes32 stateRoot;
        bytes32 transactionsRoot;
        bytes32 receiptsRoot;
        bytes logsBloom;
        uint256 difficulty;
        uint256 number;
        uint256 gasLimit;
        uint256 gasUsed;
        uint256 timestamp;
        bytes extraData;
        bytes32 mixHash;
        uint64 nonce;
        uint256 totalDifficulty;
    }

    struct Account {
        uint256 nonce;
        uint256 balance;
        bytes32 storageRoot;
        bytes32 codeHash;
    }

    struct Transaction {
        uint256 nonce;
        uint256 gasPrice;
        uint256 gasLimit;
        address to;
        uint256 value;
        bytes data;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct Log {
        address contractAddress;
        bytes32[] topics;
        bytes data;
    }

    struct TransactionReceipt {
        bytes32 transactionHash;
        uint256 transactionIndex;
        bytes32 blockHash;
        uint256 blockNumber;
        address from;
        address to;
        uint256 gasUsed;
        uint256 cummulativeGasUsed;
        address contractAddress;
        Log[] logs;
        uint256 status;            // root?
        bytes logsBloom;

        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct TransactionReceiptTrie {
        uint8 status;
        uint256 gasUsed;
        bytes logsBloom;
        Log[] logs;
    }

    function getBlockRlpData(BlockHeader memory header) internal pure returns (bytes memory data) {
        bytes[] memory list = new bytes[](15);

        list[0] = RLPEncode.encodeBytes(abi.encodePacked(header.parentHash));
        list[1] = RLPEncode.encodeBytes(abi.encodePacked(header.sha3Uncles));
        list[2] = RLPEncode.encodeAddress(header.miner);
        list[3] = RLPEncode.encodeBytes(abi.encodePacked(header.stateRoot));
        list[4] = RLPEncode.encodeBytes(abi.encodePacked(header.transactionsRoot));
        list[5] = RLPEncode.encodeBytes(abi.encodePacked(header.receiptsRoot));
        list[6] = RLPEncode.encodeBytes(header.logsBloom);
        list[7] = RLPEncode.encodeUint(header.difficulty);
        list[8] = RLPEncode.encodeUint(header.number);
        list[9] = RLPEncode.encodeUint(header.gasLimit);
        list[10] = RLPEncode.encodeUint(header.gasUsed);
        list[11] = RLPEncode.encodeUint(header.timestamp);
        list[12] = RLPEncode.encodeBytes(header.extraData);
        list[13] = RLPEncode.encodeBytes(abi.encodePacked(header.mixHash));
        list[14] = RLPEncode.encodeBytes(abi.encodePacked(header.nonce));

        data = RLPEncode.encodeList(list);
    }

    function toBlockHeader(bytes memory rlpHeader) internal pure returns (BlockHeader memory header) {

        RLPDecode.Iterator memory it = RLPDecode.toRlpItem(rlpHeader).iterator();

        uint idx;
        while(it.hasNext()) {
            if ( idx == 0 )      header.parentHash       = bytes32(it.next().toUint());
            else if ( idx == 1 ) header.sha3Uncles       = bytes32(it.next().toUint());
            else if ( idx == 2 ) header.miner            = it.next().toAddress();
            else if ( idx == 3 ) header.stateRoot        = bytes32(it.next().toUint());
            else if ( idx == 4 ) header.transactionsRoot = bytes32(it.next().toUint());
            else if ( idx == 5 ) header.receiptsRoot     = bytes32(it.next().toUint());
            else if ( idx == 6 ) header.logsBloom        = it.next().toBytes();
            else if ( idx == 7 ) header.difficulty       = it.next().toUint();
            else if ( idx == 8 ) header.number           = it.next().toUint();
            else if ( idx == 9 ) header.gasLimit         = it.next().toUint();
            else if ( idx == 10 ) header.gasUsed         = it.next().toUint();
            else if ( idx == 11 ) header.timestamp       = it.next().toUint();
            else if ( idx == 12 ) header.extraData       = it.next().toBytes();
            else if ( idx == 13 ) header.mixHash         = bytes32(it.next().toUint());
            else if ( idx == 14 ) header.nonce           = uint64(it.next().toUint());
            // else if ( idx == 13 ) header.nonce           = uint64(it.next().toUint());
            else it.next();
            idx++;
        }
        header.hash = keccak256(rlpHeader);
    }

    function getBlockHash(EthereumDecoder.BlockHeader memory header) internal pure returns (bytes32 hash) {
        return keccak256(getBlockRlpData(header));
    }

    function getLog(Log memory log) internal pure returns (bytes memory data) {
        bytes[] memory list = new bytes[](3);
        bytes[] memory topics = new bytes[](log.topics.length);

        for (uint256 i = 0; i < log.topics.length; i++) {
            topics[i] = RLPEncode.encodeBytes(abi.encodePacked(log.topics[i]));
        }

        list[0] = RLPEncode.encodeAddress(log.contractAddress);
        list[1] = RLPEncode.encodeList(topics);
        list[2] = RLPEncode.encodeBytes(log.data);
        data = RLPEncode.encodeList(list);
    }

    function getReceiptRlpData(TransactionReceiptTrie memory receipt) internal pure returns (bytes memory data) {
        bytes[] memory list = new bytes[](4);

        bytes[] memory logs = new bytes[](receipt.logs.length);
        for (uint256 i = 0; i < receipt.logs.length; i++) {
            logs[i] = getLog(receipt.logs[i]);
        }

        list[0] = RLPEncode.encodeUint(receipt.status);
        list[1] = RLPEncode.encodeUint(receipt.gasUsed);
        list[2] = RLPEncode.encodeBytes(receipt.logsBloom);
        list[3] = RLPEncode.encodeList(logs);
        data = RLPEncode.encodeList(list);
    }

    function toReceiptLog(bytes memory data) internal pure returns (Log memory log) {
        RLPDecode.Iterator memory it = RLPDecode.toRlpItem(data).iterator();

        uint idx;
        while(it.hasNext()) {
            if ( idx == 0 ) {
                log.contractAddress = it.next().toAddress();
            }
            else if ( idx == 1 ) {
                RLPDecode.RLPItem[] memory list = it.next().toList();
                log.topics = new bytes32[](list.length);
                for (uint256 i = 0; i < list.length; i++) {
                    bytes32 topic = bytes32(list[i].toUint());
                    log.topics[i] = topic;
                }
            }
            else if ( idx == 2 ) log.data = it.next().toBytes();
            else it.next();
            idx++;
        }
    }

    function toReceipt(bytes memory data) internal pure returns (TransactionReceiptTrie memory receipt) {
        RLPDecode.Iterator memory it = RLPDecode.toRlpItem(data).iterator();

        uint idx;
        while(it.hasNext()) {
            if ( idx == 0 ) receipt.status = uint8(it.next().toUint());
            else if ( idx == 1 ) receipt.gasUsed = it.next().toUint();
            else if ( idx == 2 ) receipt.logsBloom = it.next().toBytes();
            else if ( idx == 3 ) {
                RLPDecode.RLPItem[] memory list = it.next().toList();
                receipt.logs = new Log[](list.length);
                for (uint256 i = 0; i < list.length; i++) {
                    receipt.logs[i] = toReceiptLog(list[i].toRlpBytes());
                }
            }
            else it.next();
            idx++;
        }
    }

    function getTransactionRaw(Transaction memory transaction, uint256 chainId) internal pure returns (bytes memory data) {
        bytes[] memory list = new bytes[](9);

        list[0] = RLPEncode.encodeUint(transaction.nonce);
        list[1] = RLPEncode.encodeUint(transaction.gasPrice);
        list[2] = RLPEncode.encodeUint(transaction.gasLimit);
        list[3] = RLPEncode.encodeAddress(transaction.to);
        list[4] = RLPEncode.encodeUint(transaction.value);
        list[5] = RLPEncode.encodeBytes(transaction.data);
        list[6] = RLPEncode.encodeUint(chainId);
        list[7] = RLPEncode.encodeUint(0);
        list[8] = RLPEncode.encodeUint(0);
        data = RLPEncode.encodeList(list);
    }

    function toTransaction(bytes memory data) internal pure returns (Transaction memory transaction) {
        RLPDecode.Iterator memory it = RLPDecode.toRlpItem(data).iterator();

        uint idx;
        while(it.hasNext()) {
            if ( idx == 0 )      transaction.nonce       = it.next().toUint();
            else if ( idx == 1 ) transaction.gasPrice        = it.next().toUint();
            else if ( idx == 2 ) transaction.gasLimit        = it.next().toUint();
            else if ( idx == 3 ) transaction.to        = it.next().toAddress();
            else if ( idx == 4 ) transaction.value       = it.next().toUint();
            else if ( idx == 5 ) transaction.data       = it.next().toBytes();
            else if ( idx == 6 ) transaction.v       = uint8(it.next().toUint());
            else if ( idx == 7 ) transaction.r       = bytes32(it.next().toUint());
            else if ( idx == 8 ) transaction.s       = bytes32(it.next().toUint());
            else it.next();
            idx++;
        }
    }

    function toAccount(bytes memory data) internal pure returns (Account memory account) {
        RLPDecode.Iterator memory it = RLPDecode.toRlpItem(data).iterator();

        uint idx;
        while(it.hasNext()) {
            if ( idx == 0 )      account.nonce         = it.next().toUint();
            else if ( idx == 1 ) account.balance       = it.next().toUint();
            else if ( idx == 2 ) account.storageRoot   = toBytes32(it.next().toBytes());
            else if ( idx == 3 ) account.codeHash      = toBytes32(it.next().toBytes());
            else it.next();
            idx++;
        }
    }

    function toBytes32(bytes memory data) internal pure returns (bytes32 _data) {
        assembly {
            _data := mload(add(data, 32))
        }
    }
}

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;
//SPDX-License-Identifier: MIT

import "../external_lib/RLPDecode.sol";

/*
    Documentation:
    - https://eth.wiki/en/fundamentals/patricia-tree
    - https://github.com/blockchainsllc/in3/wiki/Ethereum-Verification-and-MerkleProof
    - https://easythereentropy.wordpress.com/2014/06/04/understanding-the-ethereum-trie/
*/
library MPT {
    using RLPDecode for RLPDecode.RLPItem;
    using RLPDecode for RLPDecode.Iterator;

    struct MerkleProof {
        bytes32 expectedRoot;
        bytes key;
        bytes[] proof;
        uint256 keyIndex;
        uint256 proofIndex;
        bytes expectedValue;
    }

    function verifyTrieProof(
        MerkleProof memory data
    ) pure internal returns (bool)
    {
        bytes memory node = data.proof[data.proofIndex];
        RLPDecode.Iterator memory dec = RLPDecode.toRlpItem(node).iterator();

        if (data.keyIndex == 0) {
            require(keccak256(node) == data.expectedRoot, "verifyTrieProof root node hash invalid");
        }
        else if (node.length < 32) {
            bytes32 root = bytes32(dec.next().toUint());
            require(root == data.expectedRoot, "verifyTrieProof < 32");
        }
        else {
            require(keccak256(node) == data.expectedRoot, "verifyTrieProof else");
        }

        uint256 numberItems = RLPDecode.numItems(dec.item);

        // branch
        if (numberItems == 17) {
            return verifyTrieProofBranch(data);
        }
        // leaf / extension
        else if (numberItems == 2) {
            return verifyTrieProofLeafOrExtension(dec, data);
        }

        if (data.expectedValue.length == 0) return true;
        else return false;
    }

    function verifyTrieProofBranch(
        MerkleProof memory data
    ) pure internal returns (bool)
    {
        bytes memory node = data.proof[data.proofIndex];

        if (data.keyIndex >= data.key.length) {
            bytes memory item = RLPDecode.toRlpItem(node).toList()[16].toBytes();
            if (keccak256(item) == keccak256(data.expectedValue)) {
                return true;
            }
        }
        else {
            uint256 index = uint256(uint8(data.key[data.keyIndex]));
            bytes memory _newExpectedRoot = RLPDecode.toRlpItem(node).toList()[index].toBytes();

            if (!(_newExpectedRoot.length == 0)) {
                data.expectedRoot = b2b32(_newExpectedRoot);
                data.keyIndex += 1;
                data.proofIndex += 1;
                return verifyTrieProof(data);
            }
        }

        if (data.expectedValue.length == 0) return true;
        else return false;
    }

    function verifyTrieProofLeafOrExtension(
        RLPDecode.Iterator memory dec,
        MerkleProof memory data
    ) pure internal returns (bool)
    {
        bytes memory nodekey = dec.next().toBytes();
        bytes memory nodevalue = dec.next().toBytes();
        uint256 prefix;
        assembly {
            let first := shr(248, mload(add(nodekey, 32)))
            prefix := shr(4, first)
        }

        if (prefix == 2) {
            // leaf even
            uint256 length = nodekey.length - 1;
            bytes memory actualKey = sliceTransform(nodekey, 33, length, false);
            bytes memory restKey = sliceTransform(data.key, 32 + data.keyIndex, length, false);
            if (keccak256(data.expectedValue) == keccak256(nodevalue)) {
                if (keccak256(actualKey) == keccak256(restKey)) return true;
                if (keccak256(expandKeyEven(actualKey)) == keccak256(restKey)) return true;
            }
        }
        else if (prefix == 3) {
            // leaf odd
            bytes memory actualKey = sliceTransform(nodekey, 32, nodekey.length, true);
            bytes memory restKey = sliceTransform(data.key, 32 + data.keyIndex, data.key.length - data.keyIndex, false);
            if (keccak256(data.expectedValue) == keccak256(nodevalue)) {
                if (keccak256(actualKey) == keccak256(restKey)) return true;
                if (keccak256(expandKeyOdd(actualKey)) == keccak256(restKey)) return true;
            }
        }
        else if (prefix == 0) {
            // extension even
            uint256 extensionLength = nodekey.length - 1;
            bytes memory shared_nibbles = sliceTransform(nodekey, 33, extensionLength, false);
            bytes memory restKey = sliceTransform(data.key, 32 + data.keyIndex, extensionLength, false);
            if (
                keccak256(shared_nibbles) == keccak256(restKey) ||
                keccak256(expandKeyEven(shared_nibbles)) == keccak256(restKey)

            ) {
                data.expectedRoot = b2b32(nodevalue);
                data.keyIndex += extensionLength;
                data.proofIndex += 1;
                return verifyTrieProof(data);
            }
        }
        else if (prefix == 1) {
            // extension odd
            uint256 extensionLength = nodekey.length;
            bytes memory shared_nibbles = sliceTransform(nodekey, 32, extensionLength, true);
            bytes memory restKey = sliceTransform(data.key, 32 + data.keyIndex, extensionLength, false);
            if (
                keccak256(shared_nibbles) == keccak256(restKey) ||
                keccak256(expandKeyEven(shared_nibbles)) == keccak256(restKey)
            ) {
                data.expectedRoot = b2b32(nodevalue);
                data.keyIndex += extensionLength;
                data.proofIndex += 1;
                return verifyTrieProof(data);
            }
        }
        else {
            revert("Invalid proof");
        }
        if (data.expectedValue.length == 0) return true;
        else return false;
    }

    function b2b32(bytes memory data) pure internal returns(bytes32 part) {
        assembly {
            part := mload(add(data, 32))
        }
    }

    function sliceTransform(
        bytes memory data,
        uint256 start,
        uint256 length,
        bool removeFirstNibble
    )
        pure internal returns(bytes memory)
    {
        uint256 slots = length / 32;
        uint256 rest = (length % 32) * 8;
        uint256 pos = 32;
        uint256 si = 0;
        uint256 source;
        bytes memory newdata = new bytes(length);
        assembly {
            source := add(start, data)

            if removeFirstNibble {
                mstore(
                    add(newdata, pos),
                    shr(4, shl(4, mload(add(source, pos))))
                )
                si := 1
                pos := add(pos, 32)
            }

            for {let i := si} lt(i, slots) {i := add(i, 1)} {
                mstore(add(newdata, pos), mload(add(source, pos)))
                pos := add(pos, 32)
            }
            mstore(add(newdata, pos), shl(
                rest,
                shr(rest, mload(add(source, pos)))
            ))
        }
    }

    function getNibbles(bytes1 b) internal pure returns (bytes1 nibble1, bytes1 nibble2) {
        assembly {
                nibble1 := shr(4, b)
                nibble2 := shr(4, shl(4, b))
            }
    }

    function expandKeyEven(bytes memory data) internal pure returns (bytes memory) {
        uint256 length = data.length * 2;
        bytes memory expanded = new bytes(length);

        for (uint256 i = 0 ; i < data.length; i++) {
            (bytes1 nibble1, bytes1 nibble2) = getNibbles(data[i]);
            expanded[i * 2] = nibble1;
            expanded[i * 2 + 1] = nibble2;
        }
        return expanded;
    }

    function expandKeyOdd(bytes memory data) internal pure returns(bytes memory) {
        uint256 length = data.length * 2 - 1;
        bytes memory expanded = new bytes(length);
        expanded[0] = data[0];

        for (uint256 i = 1 ; i < data.length; i++) {
            (bytes1 nibble1, bytes1 nibble2) = getNibbles(data[i]);
            expanded[i * 2 - 1] = nibble1;
            expanded[i * 2] = nibble2;
        }
        return expanded;
    }
}

pragma solidity ^0.7.0;

// slightly modified https://github.com/bakaoh/solidity-rlp-encode/blob/59f7ed4f747bdc7b95b6f9748304b8c8c8967a0f/contracts/RLPEncode.sol

/**
 * @title RLPEncode
 * @dev A simple RLP encoding library.
 * @author Bakaoh
 */
 
//SPDX-License-Identifier: MIT
 
 
library RLPEncode {
    /*
     * Internal functions
     */

    /**
     * @dev RLP encodes a byte string.
     * @param self The byte string to encode.
     * @return The RLP encoded string in bytes.
     */
    function encodeBytes(bytes memory self) internal pure returns (bytes memory) {
        bytes memory encoded;
        if (self.length == 1 && uint8(self[0]) <= 128) {
            encoded = self;
        } else {
            encoded = concat(encodeLength(self.length, 128), self);
        }
        return encoded;
    }

    /**
     * @dev RLP encodes a list of RLP encoded byte byte strings.
     * @param self The list of RLP encoded byte strings.
     * @return The RLP encoded list of items in bytes.
     */
    function encodeList(bytes[] memory self) internal pure returns (bytes memory) {
        bytes memory list = flatten(self);
        return concat(encodeLength(list.length, 192), list);
    }

    /**
     * @dev RLP encodes a string.
     * @param self The string to encode.
     * @return The RLP encoded string in bytes.
     */
    function encodeString(string memory self) internal pure returns (bytes memory) {
        return encodeBytes(bytes(self));
    }

    /**
     * @dev RLP encodes an address.
     * @param self The address to encode.
     * @return The RLP encoded address in bytes.
     */
    function encodeAddress(address self) internal pure returns (bytes memory) {
        bytes memory inputBytes;
        assembly {
            let m := mload(0x40)
            mstore(add(m, 20), xor(0x140000000000000000000000000000000000000000, self))
            mstore(0x40, add(m, 52))
            inputBytes := m
        }
        return encodeBytes(inputBytes);
    }

    /**
     * @dev RLP encodes a uint.
     * @param self The uint to encode.
     * @return The RLP encoded uint in bytes.
     */
    function encodeUint(uint self) internal pure returns (bytes memory) {
        return encodeBytes(toBinary(self));
    }

    /**
     * @dev RLP encodes an int.
     * @param self The int to encode.
     * @return The RLP encoded int in bytes.
     */
    function encodeInt(int self) internal pure returns (bytes memory) {
        return encodeUint(uint(self));
    }

    /**
     * @dev RLP encodes a bool.
     * @param self The bool to encode.
     * @return The RLP encoded bool in bytes.
     */
    function encodeBool(bool self) internal pure returns (bytes memory) {
        bytes memory encoded = new bytes(1);
        encoded[0] = (self ? bytes1(0x01) : bytes1(0x80));
        return encoded;
    }


    /*
     * Private functions
     */

    /**
     * @dev Encode the first byte, followed by the `len` in binary form if `length` is more than 55.
     * @param len The length of the string or the payload.
     * @param offset 128 if item is string, 192 if item is list.
     * @return RLP encoded bytes.
     */
    function encodeLength(uint len, uint offset) private pure returns (bytes memory) {
        bytes memory encoded;
        if (len < 56) {
            encoded = new bytes(1);
            encoded[0] = bytes32(len + offset)[31];
        } else {
            uint lenLen;
            uint i = 1;
            while (len / i != 0) {
                lenLen++;
                i *= 256;
            }

            encoded = new bytes(lenLen + 1);
            encoded[0] = bytes32(lenLen + offset + 55)[31];
            for(i = 1; i <= lenLen; i++) {
                encoded[i] = bytes32((len / (256**(lenLen-i))) % 256)[31];
            }
        }
        return encoded;
    }

    /**
     * @dev Encode integer in big endian binary form with no leading zeroes.
     * @notice TODO: This should be optimized with assembly to save gas costs.
     * @param _x The integer to encode.
     * @return RLP encoded bytes.
     */
    function toBinary(uint _x) private pure returns (bytes memory) {
        bytes memory b = new bytes(32);
        assembly {
            mstore(add(b, 32), _x)
        }
        uint i;
        for (i = 0; i < 32; i++) {
            if (b[i] != 0) {
                break;
            }
        }
        bytes memory res = new bytes(32 - i);
        for (uint j = 0; j < res.length; j++) {
            res[j] = b[i++];
        }
        return res;
    }

    /**
     * @dev Copies a piece of memory to another location.
     * @notice From: https://github.com/Arachnid/solidity-stringutils/blob/master/src/strings.sol.
     * @param _dest Destination location.
     * @param _src Source location.
     * @param _len Length of memory to copy.
     */
    function memcpy(uint _dest, uint _src, uint _len) private pure {
        uint dest = _dest;
        uint src = _src;
        uint len = _len;

        for(; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /**
     * @dev Flattens a list of byte strings into one byte string.
     * @notice From: https://github.com/sammayo/solidity-rlp-encoder/blob/master/RLPEncode.sol.
     * @param _list List of byte strings to flatten.
     * @return The flattened byte string.
     */
    function flatten(bytes[] memory _list) private pure returns (bytes memory) {
        if (_list.length == 0) {
            return new bytes(0);
        }

        uint len;
        uint i;
        for (i = 0; i < _list.length; i++) {
            len += _list[i].length;
        }

        bytes memory flattened = new bytes(len);
        uint flattenedPtr;
        assembly { flattenedPtr := add(flattened, 0x20) }

        for(i = 0; i < _list.length; i++) {
            bytes memory item = _list[i];

            uint listPtr;
            assembly { listPtr := add(item, 0x20)}

            memcpy(flattenedPtr, listPtr, item.length);
            flattenedPtr += _list[i].length;
        }

        return flattened;
    }

    /**
     * @dev Concatenates two bytes.
     * @notice From: https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol.
     * @param _preBytes First byte string.
     * @param _postBytes Second byte string.
     * @return Both byte string combined.
     */
    function concat(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bytes memory) {
        bytes memory tempBytes;

        assembly {
            tempBytes := mload(0x40)

            let length := mload(_preBytes)
            mstore(tempBytes, length)

            let mc := add(tempBytes, 0x20)
            let end := add(mc, length)

            for {
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            mc := end
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31)
            ))
        }

        return tempBytes;
    }
}

// https://github.com/hamdiallam/solidity-rlp
/*
* @author Hamdi Allam [email protected]
* Please reach out with any questions or concerns
*/
pragma solidity ^0.7.0;
//SPDX-License-Identifier: MIT

library RLPDecode {
    uint8 constant STRING_SHORT_START = 0x80;
    uint8 constant STRING_LONG_START  = 0xb8;
    uint8 constant LIST_SHORT_START   = 0xc0;
    uint8 constant LIST_LONG_START    = 0xf8;
    uint8 constant WORD_SIZE = 32;

    struct RLPItem {
        uint len;
        uint memPtr;
    }

    struct Iterator {
        RLPItem item;   // Item that's being iterated over.
        uint nextPtr;   // Position of the next item in the list.
    }

    /*
    * @dev Returns the next element in the iteration. Reverts if it has not next element.
    * @param self The iterator.
    * @return The next element in the iteration.
    */
    function next(Iterator memory self) internal pure returns (RLPItem memory) {
        require(hasNext(self), "RLPDecoder iterator has no next");

        uint ptr = self.nextPtr;
        uint itemLength = _itemLength(ptr);
        self.nextPtr = ptr + itemLength;

        return RLPItem(itemLength, ptr);
    }

    /*
    * @dev Returns true if the iteration has more elements.
    * @param self The iterator.
    * @return true if the iteration has more elements.
    */
    function hasNext(Iterator memory self) internal pure returns (bool) {
        RLPItem memory item = self.item;
        return self.nextPtr < item.memPtr + item.len;
    }

    /*
    * @param item RLP encoded bytes
    */
    function toRlpItem(bytes memory item) internal pure returns (RLPItem memory) {
        uint memPtr;
        assembly {
            memPtr := add(item, 0x20)
        }

        return RLPItem(item.length, memPtr);
    }

    /*
    * @dev Create an iterator. Reverts if item is not a list.
    * @param self The RLP item.
    * @return An 'Iterator' over the item.
    */
    function iterator(RLPItem memory self) internal pure returns (Iterator memory) {
        require(isList(self), "RLPDecoder iterator is not list");

        uint ptr = self.memPtr + _payloadOffset(self.memPtr);
        return Iterator(self, ptr);
    }

    /*
    * @param item RLP encoded bytes
    */
    function rlpLen(RLPItem memory item) internal pure returns (uint) {
        return item.len;
    }

    /*
    * @param item RLP encoded bytes
    */
    function payloadLen(RLPItem memory item) internal pure returns (uint) {
        return item.len - _payloadOffset(item.memPtr);
    }

    /*
    * @param item RLP encoded list in bytes
    */
    function toList(RLPItem memory item) internal pure returns (RLPItem[] memory) {
        require(isList(item), "RLPDecoder iterator is not a list");

        uint items = numItems(item);
        RLPItem[] memory result = new RLPItem[](items);

        uint memPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint dataLen;
        for (uint i = 0; i < items; i++) {
            dataLen = _itemLength(memPtr);
            result[i] = RLPItem(dataLen, memPtr);
            memPtr = memPtr + dataLen;
        }

        return result;
    }

    // @return indicator whether encoded payload is a list. negate this function call for isData.
    function isList(RLPItem memory item) internal pure returns (bool) {
        if (item.len == 0) return false;

        uint8 byte0;
        uint memPtr = item.memPtr;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < LIST_SHORT_START)
            return false;
        return true;
    }

    /** RLPItem conversions into data types **/

    // @returns raw rlp encoding in bytes
    function toRlpBytes(RLPItem memory item) internal pure returns (bytes memory) {
        bytes memory result = new bytes(item.len);
        if (result.length == 0) return result;

        uint ptr;
        assembly {
            ptr := add(0x20, result)
        }

        copy(item.memPtr, ptr, item.len);
        return result;
    }

    // any non-zero byte except "0x80" is considered true
    function toBoolean(RLPItem memory item) internal pure returns (bool) {
        require(item.len == 1, "RLPDecoder toBoolean invalid length");
        uint result;
        uint memPtr = item.memPtr;
        assembly {
            result := byte(0, mload(memPtr))
        }

        // SEE Github Issue #5.
        // Summary: Most commonly used RLP libraries (i.e Geth) will encode
        // "0" as "0x80" instead of as "0". We handle this edge case explicitly
        // here.
        if (result == 0 || result == STRING_SHORT_START) {
            return false;
        } else {
            return true;
        }
    }

    function toAddress(RLPItem memory item) internal pure returns (address) {
        // 1 byte for the length prefix
        require(item.len == 21, "RLPDecoder toAddress invalid length");

        return address(toUint(item));
    }

    function toUint(RLPItem memory item) internal pure returns (uint) {
        require(item.len > 0 && item.len <= 33, "RLPDecoder toUint invalid length");

        uint offset = _payloadOffset(item.memPtr);
        uint len = item.len - offset;

        uint result;
        uint memPtr = item.memPtr + offset;
        assembly {
            result := mload(memPtr)

            // shfit to the correct location if neccesary
            if lt(len, 32) {
                result := div(result, exp(256, sub(32, len)))
            }
        }

        return result;
    }

    // enforces 32 byte length
    function toUintStrict(RLPItem memory item) internal pure returns (uint) {
        // one byte prefix
        require(item.len == 33, "RLPDecoder toUintStrict invalid length");

        uint result;
        uint memPtr = item.memPtr + 1;
        assembly {
            result := mload(memPtr)
        }

        return result;
    }

    function toBytes(RLPItem memory item) internal pure returns (bytes memory) {
        require(item.len > 0, "RLPDecoder toBytes invalid length");

        uint offset = _payloadOffset(item.memPtr);
        uint len = item.len - offset; // data length
        bytes memory result = new bytes(len);

        uint destPtr;
        assembly {
            destPtr := add(0x20, result)
        }

        copy(item.memPtr + offset, destPtr, len);
        return result;
    }

    /*
    * Private Helpers
    */

    // @return number of payload items inside an encoded list.
    function numItems(RLPItem memory item) internal pure returns (uint) {
        if (item.len == 0) return 0;

        uint count = 0;
        uint currPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint endPtr = item.memPtr + item.len;
        while (currPtr < endPtr) {
           currPtr = currPtr + _itemLength(currPtr); // skip over an item
           count++;
        }

        return count;
    }

    // @return entire rlp item byte length
    function _itemLength(uint memPtr) private pure returns (uint) {
        uint itemLen;
        uint byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START)
            itemLen = 1;

        else if (byte0 < STRING_LONG_START)
            itemLen = byte0 - STRING_SHORT_START + 1;

        else if (byte0 < LIST_SHORT_START) {
            assembly {
                let byteLen := sub(byte0, 0xb7) // # of bytes the actual length is
                memPtr := add(memPtr, 1) // skip over the first byte

                /* 32 byte word size */
                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to get the len
                itemLen := add(dataLen, add(byteLen, 1))
            }
        }

        else if (byte0 < LIST_LONG_START) {
            itemLen = byte0 - LIST_SHORT_START + 1;
        }

        else {
            assembly {
                let byteLen := sub(byte0, 0xf7)
                memPtr := add(memPtr, 1)

                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to the correct length
                itemLen := add(dataLen, add(byteLen, 1))
            }
        }

        return itemLen;
    }

    // @return number of bytes until the data
    function _payloadOffset(uint memPtr) private pure returns (uint) {
        uint byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START)
            return 0;
        else if (byte0 < STRING_LONG_START || (byte0 >= LIST_SHORT_START && byte0 < LIST_LONG_START))
            return 1;
        else if (byte0 < LIST_SHORT_START)  // being explicit
            return byte0 - (STRING_LONG_START - 1) + 1;
        else
            return byte0 - (LIST_LONG_START - 1) + 1;
    }

    /*
    * @param src Pointer to source
    * @param dest Pointer to destination
    * @param len Amount of memory to copy from the source
    */
    function copy(uint src, uint dest, uint len) private pure {
        if (len == 0) return;

        // copy as many word sizes as possible
        for (; len >= WORD_SIZE; len -= WORD_SIZE) {
            assembly {
                mstore(dest, mload(src))
            }

            src += WORD_SIZE;
            dest += WORD_SIZE;
        }

        // left over bytes. Mask is used to remove unwanted bytes from the word
        uint mask = 256 ** (WORD_SIZE - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask)) // zero out src
            let destpart := and(mload(dest), mask) // retrieve the bytes
            mstore(dest, or(destpart, srcpart))
        }
    }
}