//SPDX-License-Identifier: Unlicense
pragma solidity 0.7.0;

import './ProxyContract.sol';
import './GetProofLib.sol';

contract RelayContract {
    event CompareStorageRoots (bytes32 srcAccountHash, bytes32 proxyAccountHash);
    struct ProxyContractInfo {
        // The root of storage trie of the contract.
        bytes32 storageRoot;
        // State of migration if successfull or not
        bool migrationState;
        // block number of the src contract it is currently synched with
        uint blockNumber;
    }

    mapping(address => ProxyContractInfo) proxyStorageInfos;
    mapping(uint => bytes32) srcContractStateRoots;
    uint latestBlockNr;

    constructor() public {
    }

    /**
     * @dev Called by the proxy to update its state, only after migrationState validation
     */
    function updateProxyInfo(bytes32 _newStorage, uint _blockNumber) public {
        require(proxyStorageInfos[msg.sender].blockNumber < _blockNumber);
        proxyStorageInfos[msg.sender].storageRoot = _newStorage;
        proxyStorageInfos[msg.sender].migrationState = true;
        proxyStorageInfos[msg.sender].blockNumber = _blockNumber;
    }

    function addBlock(bytes32 _stateRoot, uint256 _blockNumber) public {
        srcContractStateRoots[_blockNumber] = _stateRoot;
        if (_blockNumber > latestBlockNr) latestBlockNr = _blockNumber;
    }

    /**
    * @dev return state root at the respective blockNumber
    */
    function getStateRoot(uint _blockNumber) public view returns (bytes32) {
        return srcContractStateRoots[_blockNumber];
    }

    /**
    * @dev return the calling contract's storage root (only correct if stored by the contract before only!)
    */
    function getStorageRoot() public view returns (bytes32) {
        return proxyStorageInfos[msg.sender].storageRoot;
    }

    /**
    * @dev return migration state of passed proxy contract
    * @param _contractAddress address of proxy contract 
    */
    function getMigrationState(address _contractAddress) public view returns (bool) {
        return proxyStorageInfos[_contractAddress].migrationState;
    }

    /**
    * @dev return current synched block number of src chain from proxy contract
    * @param _proxyContractAddress address of proxy contract 
    */
    function getCurrentBlockNumber(address _proxyContractAddress) public view returns (uint) {
        return proxyStorageInfos[_proxyContractAddress].blockNumber;
    }

    function getLatestBlockNumber() public view returns (uint) {
        return latestBlockNr;
    }

    /**
    * @dev Used to access the Proxy's abi
    */
    function getProxy(address payable proxyAddress) internal pure returns (ProxyContract) {
        return ProxyContract(proxyAddress);
    }

    /**
    * @dev checks if the migration of the source contract to the proxy contract was successful
    * @param sourceAccountProof contains source contract account information and the merkle patricia proof of the account
    * @param proxyAccountProof contains proxy contract account information and the merkle patricia proof of the account
    * @param proxyChainBlockHeader latest block header of the proxy contract's chain
    * @param proxyAddress address from proxy contract
    * @param proxyChainBlockNumber block number from the proxy chain block header, this is needed because the blockNumber in the header is a hex string
    * @param srcChainBlockNumber block number from the src chain from which we take the stateRoot from the srcContract
    */
    function verifyMigrateContract(bytes memory sourceAccountProof, bytes memory proxyAccountProof, bytes memory proxyChainBlockHeader, address payable proxyAddress, uint proxyChainBlockNumber, uint srcChainBlockNumber) public {
        GetProofLib.BlockHeader memory blockHeader = GetProofLib.parseBlockHeader(proxyChainBlockHeader);

        // compare block header hashes
        bytes32 givenBlockHeaderHash = keccak256(proxyChainBlockHeader);
        bytes32 actualBlockHeaderHash = blockhash(proxyChainBlockNumber);
        require(givenBlockHeaderHash == actualBlockHeaderHash, 'Given proxy chain block header is faulty');

        // verify sourceAccountProof
        // validate that the proof was obtained for the source contract and the account's storage is part of the current state
        ProxyContract proxyContract = getProxy(proxyAddress);
        address sourceAddress = proxyContract.getSourceAddress();
        bytes memory path = GetProofLib.encodedAddress(sourceAddress);
        GetProofLib.GetProof memory getProof = GetProofLib.parseProof(sourceAccountProof);
        require(GetProofLib.verifyProof(getProof.account, getProof.accountProof, path, srcContractStateRoots[srcChainBlockNumber]), "Failed to verify the source account proof");
        GetProofLib.Account memory sourceAccount = GetProofLib.parseAccount(getProof.account);

        // verify proxyAccountProof
        // validate that the proof was obtained for the source contract and the account's storage is part of the current state
        path = GetProofLib.encodedAddress(proxyAddress);
        getProof = GetProofLib.parseProof(proxyAccountProof);
        require(GetProofLib.verifyProof(getProof.account, getProof.accountProof, path, blockHeader.storageRoot), "Failed to verify the proxy account proof");
        GetProofLib.Account memory proxyAccount = GetProofLib.parseAccount(getProof.account);

        emit CompareStorageRoots(sourceAccount.storageHash,proxyAccount.storageHash);

        // compare storageRootHashes
        require(sourceAccount.storageHash == proxyAccount.storageHash, 'storageHashes of the contracts dont match');

        // update proxy info -> complete migration
        proxyStorageInfos[proxyAddress].storageRoot = proxyAccount.storageHash;
        proxyStorageInfos[proxyAddress].migrationState = true;
        proxyStorageInfos[proxyAddress].blockNumber = srcChainBlockNumber;
    }
}