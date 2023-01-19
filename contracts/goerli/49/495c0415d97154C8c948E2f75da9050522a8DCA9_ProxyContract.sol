//SPDX-License-Identifier: Unlicense
pragma solidity 0.7.0;

import "./RelayContract.sol";
import "./GetProofLib.sol";
import "./RLPWriter.sol";
import "./RLPReader.sol";

contract ProxyContract {
    enum NodeType { BRANCH, EXTENSION, LEAF, DELETED, HASHED }
    struct NodeInfo { 
        uint mtHeight; 
    }
    struct BranchInfo { 
        uint generalChildAmount;
        uint oldValueIndex;
        uint unhashedValues;
        bool[16] unhashedValuePosition; 
    }
    using RLPReader for RLPReader.RLPItem;
    using RLPReader for RLPReader.Iterator;
    using RLPReader for bytes;

    /**
    * @dev address of the deployed relay contract.
    * The address in the file is a placeholder
    */
    address internal constant RELAY_ADDRESS = 0x75b82024F44F5633983B49558Fb66Cd113655ae4;

    /**
    * @dev address of the contract that is being mirrored.
    * The address in the file is a placeholder
    */
    address internal constant SOURCE_ADDRESS = 0x5110B4b4Fea7137895d33B8a0b11330A1B2586E9;

    /**
    * @dev address of the contract that is being mirrored.
    * The address in the file is a placeholder
    */
    address internal constant LOGIC_ADDRESS = 0xBd1BFC1062c9c2266600D23639877f2120701144;

    constructor() public {
    }

    /**
    * @dev Adds values to the storage. Used for initialization.
    * @param keys -> Array of keys for storage
    * @param values -> Array of values corresponding to the array keys.
    */
    function addStorage(bytes32[] memory keys, bytes32[] memory values) public {
        require(keys.length == values.length, 'arrays keys and values do not have the same length');
        require(!(getRelay().getMigrationState(address(this))), 'Migration is already completed');

        bytes32 key;
        bytes32 value;
        for (uint i = 0; i < keys.length; i++) {
            key = keys[i];
            value = values[i];
            assembly {
                sstore(key, value)
            }
        }
    }

    /**
    * @dev Used to access the Relay's abi
    */
    function getRelay() internal pure returns (RelayContract) {
        return RelayContract(RELAY_ADDRESS);
    }

    /**
    * @dev Used to get the relay address
    */
    function getRelayAddress() public pure returns (address) {
        return RELAY_ADDRESS;
    }

    /**
    * @dev Used to get the source address
    */
    function getSourceAddress() public pure returns (address) {
        return SOURCE_ADDRESS;
    }

    /**
    * @dev Used to get the logic address
    */
    function getLogicAddress() public pure returns (address) {
        return LOGIC_ADDRESS;
    }

    /**
  * @dev Sets the contract's storage based on the encoded storage
  * @param rlpStorageKeyProofs the rlp encoded list of storage proofs
  * @param storageHash the hash of the contract's storage
  */
    function updateStorageKeys(bytes memory rlpStorageKeyProofs, bytes32 storageHash) internal {
        RLPReader.Iterator memory it = rlpStorageKeyProofs.toRlpItem().iterator();

        while (it.hasNext()) {
            setStorageKey(it.next(), storageHash);
        }
    }

    /**
    * @dev Update a single storage key after validating against the storage key
    */
    function setStorageKey(RLPReader.RLPItem memory rlpStorageKeyProof, bytes32 storageHash) internal {
        // parse the rlp encoded storage proof
        GetProofLib.StorageProof memory proof = GetProofLib.parseStorageProof(rlpStorageKeyProof.toBytes());

        // get the path in the trie leading to the value
        bytes memory path = GetProofLib.triePath(abi.encodePacked(proof.key));

        // verify the storage proof
        require(MerklePatriciaProof.verify(
                proof.value, path, proof.proof, storageHash
            ), "Failed to verify the storage proof");

        // decode the rlp encoded value
        bytes32 value = bytes32(proof.value.toRlpItem().toUint());

        // store the value in the right slot
        bytes32 slot = proof.key;
        assembly {
            sstore(slot, value)
        }
    }

    function _beforeFallback() internal {
        address addr = address(this);
        bytes4 sig = bytes4(keccak256("emitEvent()"));
        
        bool success; 
        assembly {
            let p := mload(0x40)
            mstore(p,sig)
            success := call(950, addr, 0, p, 0x04, p, 0x00)
            mstore(0x20,add(p,0x04))
            //if eq(success, 1) { revert(0,0) }
        }
        require(!success, "only static calls are permitted");
    }

    function emitEvent() public {
        emit Illegal();
    }

    event Illegal();

    /*
     * The address of the implementation contract
     */
    function _implementation() internal pure returns (address) {
        return LOGIC_ADDRESS;
    }

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal {
        _beforeFallback();
        _delegateLogic();
    }
    
    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable {
        _fallback();
    }

    receive() external payable   {

    }
    /**
    * @dev Delegates the current call to `implementation`.
    *
    * This function does not return to its internal call site, it will return directly to the external caller.
    */
    function _delegateLogic() internal {
        // solhint-disable-next-line no-inline-assembly
        address logic = _implementation();
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), logic, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {revert(0, returndatasize())}
            default {return (0, returndatasize())}
        }
    }

    function restoreOldValueState(RLPReader.RLPItem[] memory leaf) internal view returns (bytes memory, bool) {
        RLPReader.RLPItem[] memory keys = leaf[0].toList();
        uint key = keys[0].toUint();
        bytes32 currValue;
        assembly {
            currValue := sload(key)
        }

        // If the slot was empty before, remove branch to get the old contract state
        if(currValue != 0x0) {
            // update the value and compute the new hash
            // rlp(node) = rlp[rlp(encoded Path), rlp(value)]
            bytes[] memory _list = new bytes[](2);
            _list[0] = leaf[1].toRlpBytes();

            if (uint256(currValue) > 127) {
                _list[1] = RLPWriter.encodeBytes(RLPWriter.encodeUint(uint256(currValue)));
            } else {
                _list[1] = RLPWriter.encodeUint(uint256(currValue));
            }
            
            return (RLPWriter.encodeList(_list), true);
        } else {
            return (RLPWriter.encodeUint(0), false);
        }
    }

    /**
    * @dev see https://eth.wiki/fundamentals/patricia-tree for more details
    * @param leaf the leaf itself with the responding value and key in it. We assume that the value is already loaded from storage.
    * @param nodeInfo contains current mtHeight which is needed to build the encodedPath for the leaf
    */
    // todo make this function create also branches, extensions if they were deleted?
    function restoreLeafAtPos(RLPReader.RLPItem[] memory leaf, NodeInfo memory nodeInfo) private pure returns (bytes memory hashedLeaf) {
        // build the remaining encodedPath for the leaf
        uint8 hp_encoding = 0;
        if ((nodeInfo.mtHeight % 2) == 0) {
            hp_encoding = 2;
        } else {
            hp_encoding = 3;
        }
        RLPReader.RLPItem[] memory keys = leaf[0].toList();
        bytes32 hashedKey = keccak256(keys[0].toBytes());
        bytes memory bytesHashedKey = abi.encodePacked(hashedKey);
        // leaf
        bytes memory res = new bytes(32 - (nodeInfo.mtHeight / 2) + ((nodeInfo.mtHeight + 1) % 2));
        // add hp encoding prefix
        res[0] = bytes1(hp_encoding) << 4;
        uint currPos = nodeInfo.mtHeight;
        if (hp_encoding != 2) {
            res[0] = res[0] | _getNthNibbleOfBytes(currPos, bytesHashedKey);
            currPos++;
        }
        // add the rest
        for (uint k = 1; k < res.length; k++) {
            res[k] = _getNthNibbleOfBytes(currPos, bytesHashedKey) << 4 | _getNthNibbleOfBytes(currPos + 1, bytesHashedKey);
            currPos += 2;
        }
        bytes[] memory _list = new bytes[](2);
        _list[0] = RLPWriter.encodeBytes(res);
        // we assume that the value was already loaded from memory
        _list[1] = leaf[2].toRlpBytes();
        bytes32 listHash = keccak256(RLPWriter.encodeList(_list));
        // we return the hashed leaf
        return RLPWriter.encodeKeccak256Hash(listHash);
    }

    /**
    * @dev Does two things: Recursively updates a single proof node and returns the adjusted hash after modifying all the proof node's values
    * @dev and computes state root from adjusted Merkle Tree
    * @param rlpProofNode proof of form of:
    *        [list of common branches..last common branch,], values[0..16; LeafNode || proof node]
    */
    // todo remove redundant code of computeRoots and computeOldItem
    // todo recalculate new parent hash with given info about nodes. Currently, only root node is rehashed.
    function computeRoots(bytes memory rlpProofNode) public view returns (bytes32, bytes32) {
        // the updated reference hash
        // todo validate the new values of the new proof as well by replacing the values in the proof with the real values
        bytes32 newParentHash;
        bytes32 oldParentHash;
        NodeInfo memory nodeInfo;
        nodeInfo.mtHeight = 1;

        RLPReader.RLPItem[] memory proofNode = rlpProofNode.toRlpItem().toList();

        if (!RLPReader.isList(proofNode[1])) {
            // its only one leaf node in the tree
            (bytes memory oldValueState, bool isValue) = restoreOldValueState(proofNode);
            if (!isValue) {
                // there wasn't a value before
                oldParentHash = 0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421;
            } else {
                oldParentHash = keccak256(oldValueState);
            }
            nodeInfo.mtHeight = 0;
            bytes memory newParentHashBytes = restoreLeafAtPos(proofNode, nodeInfo).toRlpItem().toBytes();
            assembly {
                newParentHash := mload(add(newParentHashBytes, 32))
            }
            return (oldParentHash, newParentHash);
        }

        // root branch with all hashed values in it
        RLPReader.RLPItem[] memory hashedValuesAtRoot = RLPReader.toList(proofNode[0]);
        // and a list of non-hashed values [0..16] for the root branch node
        RLPReader.RLPItem[] memory valuesAtRoot = RLPReader.toList(proofNode[1]);

        bytes32 encodedZero = keccak256(RLPWriter.encodeUint(0));
        if (valuesAtRoot.length == 1) {
            // todo check if there was only leaf at root before
            // its an extension
            // 1. calculate new parent hash
            bytes[] memory _list = new bytes[](2);
            for (uint j = 0; j < 2; j++) {
                _list[j] = hashedValuesAtRoot[j].toRlpBytes();
            }
            // todo use the valuesAtRoot as well
            newParentHash = keccak256(proofNode[0].toRlpBytes());

            // 2. calulate old parent hash
            RLPReader.RLPItem[] memory valueAtRoot = valuesAtRoot[0].toList();
            (bytes memory oldItem, NodeType nodeType) = computeOldItem(valueAtRoot, nodeInfo);
            if (nodeType != NodeType.HASHED) {
                if (nodeType != NodeType.DELETED) {
                    // todo: what if multiple values are not hashed?
                    // todo: set a counter of unhashed values?
                    valuesAtRoot[0] = oldItem.toRlpItem();
                    // todo: hash new node
                } else {
                    // todo: what if everything was deleted
                }
            } else {
                bytes32 oldItemHash = bytes32(oldItem.toRlpItem().toUint());
                _list[1] = RLPWriter.encodeKeccak256Hash(oldItemHash);
                oldParentHash = keccak256(RLPWriter.encodeList(_list));
            }
        } else {
            // its a branch
            bytes[] memory _newList = new bytes[](17);
            bytes[] memory _oldList = new bytes[](17);
            BranchInfo memory branchInfo;
            branchInfo.generalChildAmount = 0;
            branchInfo.oldValueIndex = 17;
            branchInfo.unhashedValues = 0;
            // loop through every value
            for (uint i = 0; i < 17; i++) {
                // get new entry for new parent hash calculation
                _newList[i] = hashedValuesAtRoot[i].toRlpBytes();
                _oldList[i] = hashedValuesAtRoot[i].toRlpBytes();
                bytes32 currEncoded = keccak256(_oldList[i]);
                if (currEncoded != encodedZero) {
                    branchInfo.generalChildAmount++;
                }

                // the value node either holds the [key, value] directly or another proofnode
                RLPReader.RLPItem[] memory valueNode = RLPReader.toList(valuesAtRoot[i]);
                if (valueNode.length == 3) {
                    // get old entry for old parent hash calculation
                    // leaf value, where the is the value of the latest branch node at index i
                    (bytes memory encodedList, bool isOldValue) = restoreOldValueState(valueNode);
                    if (isOldValue) {
                        if (currEncoded == encodedZero) {
                            branchInfo.generalChildAmount++;
                        }
                        branchInfo.oldValueIndex = i; 
                    } else {
                        branchInfo.generalChildAmount--;
                    }
                    if (encodedList.length > 32) {
                        bytes32 listHash = keccak256(encodedList);
                        _oldList[i] = RLPWriter.encodeKeccak256Hash(listHash);
                    } else {
                        _oldList[i] = encodedList;
                    }
                } else if (valueNode.length == 2) {
                    // branch or extension
                    (bytes memory oldItem, NodeType nodeType) = computeOldItem(valueNode, nodeInfo);
                    if (nodeType != NodeType.HASHED) {
                        if (nodeType == NodeType.DELETED) {
                            // node is not existent in old storage. (was just added at src contract)
                            branchInfo.generalChildAmount--;
                            if (branchInfo.oldValueIndex == i) {
                                branchInfo.oldValueIndex = 17;
                            }
                        } else {
                            // underlying node was changed and needs to be rebuild to the old way
                            // todo: what if multiple values are not hashed?
                            // todo: set an array of unhashed indexes?
                            valuesAtRoot[i] = oldItem.toRlpItem();
                        }
                    } else {
                        branchInfo.oldValueIndex = i;
                        if (currEncoded == encodedZero) {
                            branchInfo.generalChildAmount++;
                        }
                        bytes32 oldItemHash;
                        assembly {
                            oldItemHash := mload(add(oldItem, 32))
                        }
                        _oldList[i] = RLPWriter.encodeKeccak256Hash(oldItemHash);
                    }
                }
            }
            newParentHash = keccak256(RLPWriter.encodeList(_newList));
            // todo: hash all values that were not hashed yet
            if (branchInfo.generalChildAmount == 1 && branchInfo.oldValueIndex < 17) {
                // it was just one value before
                // todo: hash one value as root (branch, extension or leaf)
            } else {
                oldParentHash = keccak256(RLPWriter.encodeList(_oldList));
            }
        }

        return (oldParentHash, newParentHash);
    }

    function computeOldItem(RLPReader.RLPItem[] memory proofNode, NodeInfo memory nodeInfo) internal view returns (bytes memory oldNode, NodeType) {
        // the updated reference hash
        bytes32 oldParentHash;
        nodeInfo.mtHeight = nodeInfo.mtHeight + 1;
        // todo also calculate hash for newHash by hashing new values

        // root branch with all hashed values in it
        RLPReader.RLPItem[] memory hashedValuesAtNode = RLPReader.toList(proofNode[0]);
        // and a list of non-hashed values [0..16] for the root branch node
        RLPReader.RLPItem[] memory valuesAtNode = RLPReader.toList(proofNode[1]);

        bytes32 encodedZero = keccak256(RLPWriter.encodeUint(0));
        if (valuesAtNode.length == 1) {
            // its an extension
            bytes[] memory _list = new bytes[](2);
            _list[0] = hashedValuesAtNode[0].toRlpBytes();

            // calulate old parent hash
            RLPReader.RLPItem[] memory valueAtNode = valuesAtNode[0].toList();
            (bytes memory oldItem, NodeType nodeType) = computeOldItem(valueAtNode, nodeInfo);
            if (nodeType != NodeType.HASHED) {
                if (nodeType != NodeType.DELETED) {
                    // todo: what if multiple values are not hashed?
                    // todo: set a counter of unhashed values?
                    valuesAtNode[0] = oldItem.toRlpItem();
                    // todo: hash new node
                } else {
                    // todo: what if everything was deleted
                }
            } else {
                bytes32 oldItemHash;
                assembly {
                    oldItemHash := mload(add(oldItem, 32))
                }
                _list[1] = RLPWriter.encodeKeccak256Hash(oldItemHash);
                oldParentHash = keccak256(RLPWriter.encodeList(_list));
                nodeInfo.mtHeight -= 1;
                return (abi.encodePacked(oldParentHash), NodeType.HASHED);
            }
        } else {
            // its a branch
            bytes[] memory _oldList = new bytes[](17);
            BranchInfo memory branchInfo;
            branchInfo.generalChildAmount = 0;
            branchInfo.oldValueIndex = 17;
            branchInfo.unhashedValues = 0;
            // loop through every value
            for (uint i = 0; i < 17; i++) {
                _oldList[i] = hashedValuesAtNode[i].toRlpBytes();
                bytes32 currEncoded = keccak256(_oldList[i]);
                if (currEncoded != encodedZero) {
                    branchInfo.generalChildAmount++;
                    if (branchInfo.oldValueIndex == 17) {
                        branchInfo.oldValueIndex = i;
                    }
                }

                // get old entry for old parent hash calculation
                // the value node either holds the [key, value]directly or another proofnode
                RLPReader.RLPItem[] memory valueNode = RLPReader.toList(valuesAtNode[i]);
                if (valueNode.length == 3) {
                    // leaf value, where the is the value of the latest branch node at index i
                    (bytes memory encodedList, bool isOldValue) = restoreOldValueState(valueNode);
                    if (isOldValue) {
                        if (currEncoded == encodedZero) {
                            branchInfo.generalChildAmount++;
                        }
                    } else {
                        if (currEncoded != encodedZero) {
                            branchInfo.generalChildAmount--;
                            if (branchInfo.oldValueIndex == i) {
                                branchInfo.oldValueIndex = 17;
                            }
                        }
                    }
                    
                    if (encodedList.length > 32) {
                        bytes32 listHash = keccak256(encodedList);
                        _oldList[i] = RLPWriter.encodeKeccak256Hash(listHash);
                    } else {
                        _oldList[i] = encodedList;
                    }
                } else if (valueNode.length == 2) {
                    // branch or extension
                    (bytes memory oldItem, NodeType nodeType) = computeOldItem(valueNode, nodeInfo);
                    if (nodeType != NodeType.HASHED) {
                        if (nodeType == NodeType.DELETED) {
                            // todo still need to hash 0x0 at the position
                            branchInfo.generalChildAmount--;
                            if (branchInfo.oldValueIndex == i) {
                                branchInfo.oldValueIndex = 17;
                            }
                        } else if (nodeType == NodeType.LEAF) {
                            branchInfo.unhashedValues++;
                            branchInfo.oldValueIndex = i;
                            // todo: what if multiple values are not hashed?
                            // todo: set a counter of unhashed values?
                            // todo: set an array of unhashed indexes?
                            valuesAtNode[i] = oldItem.toRlpItem();
                            branchInfo.unhashedValuePosition[i] = true;
                        } else {
                            branchInfo.unhashedValues++;
                            branchInfo.oldValueIndex = i;
                            valuesAtNode[i] = oldItem.toRlpItem();
                            branchInfo.unhashedValuePosition[i] = true;
                        }
                    } else {
                        branchInfo.oldValueIndex = i;
                        if (currEncoded == encodedZero) {
                            branchInfo.generalChildAmount++;
                        }
                        bytes32 oldItemHash;
                        assembly {
                            oldItemHash := mload(add(oldItem, 32))
                        }
                        _oldList[i] = RLPWriter.encodeKeccak256Hash(oldItemHash);
                    }
                }
            }
            if (branchInfo.generalChildAmount == 1 && branchInfo.oldValueIndex < 17) {
                if (branchInfo.unhashedValues > 0) {
                    // todo check if we got unhashed from lower level
                }
                // its only one value left here.
                // this means we have to return it one level further up to be hashed there
                // it was just one value before
                nodeInfo.mtHeight -= 1;
                return (valuesAtNode[branchInfo.oldValueIndex].toRlpBytes(), NodeType.LEAF);
            } else if (branchInfo.unhashedValues > 0) {
                for (uint8 j = 0; j < 16; j++) {
                    if (branchInfo.unhashedValuePosition[j] == true) {
                        RLPReader.RLPItem[] memory node = RLPReader.toList(valuesAtNode[j]);
                        if (node.length == 2) {
                            // todo its an extension/branch
                        } else {
                            // restoring leaf at the old position
                            _oldList[j] = restoreLeafAtPos(node, nodeInfo);
                        }
                    }
                }
            }
            oldParentHash = keccak256(RLPWriter.encodeList(_oldList));
            nodeInfo.mtHeight -= 1;
            return (abi.encode(oldParentHash), NodeType.HASHED);
        }
    }

    // taken from https://github.com/KyberNetwork/peace-relay/blob/master/contracts/MerklePatriciaProof.sol
    /*
     *This function takes in the bytes string (hp encoded) and the value of N, to return Nth Nibble.
     *@param Value of N
     *@param Bytes String
     *@return ByteString[N]
     */
    function _getNthNibbleOfBytes(uint n, bytes memory str) private pure returns (byte) {
        return byte(n % 2 == 0 ? uint8(str[n / 2]) / 0x10 : uint8(str[n / 2]) % 0x10);
    }

    /**
    * @dev Several steps happen before a storage update takes place:
    * First verify that the provided proof was obtained for the account on the source chain (account proof)
    * Secondly verify that the current value is part of the current storage root (old contract state proof)
    * Third step is verifying the provided storage proofs provided in the `proof` (new contract state proof)
    * @param proof The rlp encoded optimized proof
    * @param blockNumber The block number of the src chain from which to take the stateRoot of the srcContract
    */
    function updateStorage(bytes memory proof, uint blockNumber) public {
        // First verify stateRoot -> account (account proof)
        RelayContract relay = getRelay();
        require(relay.getMigrationState(address(this)), 'migration not completed');
        
        // get the current state root of the source chain
        bytes32 root = relay.getStateRoot(blockNumber);
        // validate that the proof was obtained for the source contract and the account's storage is part of the current state
        bytes memory path = GetProofLib.encodedAddress(SOURCE_ADDRESS);

        GetProofLib.GetProof memory getProof = GetProofLib.parseProof(proof);
        require(GetProofLib.verifyProof(getProof.account, getProof.accountProof, path, root), "Failed to verify the account proof");

        GetProofLib.Account memory account = GetProofLib.parseAccount(getProof.account);

        bytes32 lastValidParentHash = getRelay().getStorageRoot();

        (bytes32 oldParentHash, bytes32 newParentHash) = computeRoots(getProof.storageProofs);

        // Second verify proof would map to current state by replacing values with current values (old contract state proof)
        require(lastValidParentHash == oldParentHash, "Failed to verify old contract state proof");

        // Third verify proof is valid according to current block in relay contract
        require(newParentHash == account.storageHash, "Failed to verify new contract state proof");

        // update the storage or revert on error
        setStorageValues(getProof.storageProofs);

        // update the state in the relay
        relay.updateProxyInfo(account.storageHash, blockNumber);
    }

    function updateStorageValue(RLPReader.RLPItem[] memory valueNode) internal {
        // leaf value, where the is the value of the latest branch node at index i
        uint byte0;
        bytes32 value;
        uint memPtr = valueNode[2].memPtr;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 > 127) {
            // leaf is double encoded when greater than 127
            valueNode[2].memPtr += 1;
            valueNode[2].len -= 1;
            value = bytes32(valueNode[2].toUint());
        } else {
            value = bytes32(byte0);
        }
        RLPReader.RLPItem[] memory keys = valueNode[0].toList();
        bytes32 slot = bytes32(keys[0].toUint());
        assembly {
            sstore(slot, value)
        }
    }

    /**
    * @dev Recursively set contract's storage based on the provided proof nodes
    * @param rlpProofNode the rlp encoded storage proof nodes, starting with the root node
    */
    function setStorageValues(bytes memory rlpProofNode) internal {
        RLPReader.RLPItem[] memory proofNode = rlpProofNode.toRlpItem().toList();

        if (RLPReader.isList(proofNode[1])) {
            RLPReader.RLPItem[] memory valuesAtNode = RLPReader.toList(proofNode[1]);
            if (valuesAtNode.length == 1) {
                // its an extension
                setStorageValues(valuesAtNode[0].toRlpBytes());
            } else {
                // its a branch
                // and a list of values [0..16] for the last branch node
                // loop through every value
                for (uint i = 0; i < 17; i++) {
                    // the value node either holds the [key, value]directly or another proofnode
                    RLPReader.RLPItem[] memory valueNode = RLPReader.toList(valuesAtNode[i]);
                    if (valueNode.length == 3) {
                        updateStorageValue(valueNode);
                    } else if (valueNode.length == 2) {
                        setStorageValues(valuesAtNode[i].toRlpBytes());
                    }
                }
            }
        } else {
            // its only one value
            updateStorageValue(proofNode);
        }
    }
}