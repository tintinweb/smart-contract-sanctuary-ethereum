// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

contract TwoPartyContract {
  mapping(address => bool) public owners; // Contract owners, all addresses initialize as false

  /* "multidimensional" mapping allows for one party to sign different contracts (even each contract multiple times but only once per block) with different people
     Can only sign one iteration of a specific contract between two parties once per block as we use block.number as nonce
     Originator/Initiator + Counterparty + IPFS Hash + Block Number Contract Proposed In = Contract Hash */
  mapping(address => 
    mapping(address => 
      mapping(string => 
        mapping(uint256 => bytes32)))) public contractHashes;
  
  // When the contract hash is generated, we then populate a set of arrays with contract info that can be queried with the contract hash later
  mapping(bytes32 => address[]) public contractParties; // Contract Hash => Party Addresses
  mapping(bytes32 => string) public contractIpfsHash; // Contract Hash => IPFS Pointer
  mapping(bytes32 => uint256) public contractBlock; // Contract Hash => Block Number in which agreement was proposed
  mapping(bytes32 => bool) public contractExecuted; // Contract Hash => True/False, contract automatically executes when both parties sign
  mapping(bytes32 => bytes[]) public contractSignatures; // Contract Hash => Signatures

  // Contract struct required for getContractData() function as Solidity can't handle returning 7 variables. Returning a struct is technically only one
  struct Contract {
    address initiator;
    address counterParty;
    string ipfsHash;
    uint256 blockNumber;
    bool executed;
    bytes firstSignature;
    bytes secondSignature;
  }

  // Log contract initiator address, counterParty address, ipfsHash/Pointer string, and blockNumber agreement is in
  // counterParty is the only unindexed parameter because EVM only allows for three and I found counterParty to be the least relevant
  event ContractCreated(address initiator, address counterParty, string indexed ipfsHash, uint256 indexed blockNumber, bytes32 indexed contractHash);
  // Log contract hashes on their own as all contrct details in ContractCreated can be obtianed by querying granular contract data mappings (contractParties, ...)
  event ContractHashed(bytes32 indexed contractHash);
  // Log contract signatures, contractHash used in verification, and the signer address to validate against
  event ContractSigned(address indexed signer, bytes32 indexed contractHash, bytes indexed signature);
  // Log contract execution using hash and the block it executed in
  event ContractExecuted(bytes32 indexed contractHash, uint256 indexed blockNumber);

  // what should we do on deploy?
  constructor() {
    owners[payable(msg.sender)] = true;
  }

  // Require msg.sender to be an owner of contract to call modified function
  modifier onlyOwner() {
    require(owners[msg.sender], "Not a contract owner");
    _;
  }

  // Require initiator hash initialization before proceeding with modified function
  modifier onlyInitiator(address _counterParty, string memory _ipfsHash, uint256 _blockNum) {
    require(bytes32(contractHashes[msg.sender][_counterParty][_ipfsHash][_blockNum]) > 0, "Initiator hash not initialized");
    _;
  }

  // Require contract creation by checking if _party1 is part of a contract with _party2
  modifier validParty(bytes32 _contractHash) {
    require(contractParties[_contractHash][0] == msg.sender || contractParties[_contractHash][1] == msg.sender);
    _;
  }

  modifier notExecuted(bytes32 _contractHash) {
    require(!contractExecuted[_contractHash], "Contract already executed");
    _;
  }

  // Require contract execution has occured by all parties signing
  modifier hasExecuted(bytes32 _contractHash) {
    require(contractExecuted[_contractHash], "Contract hasn't executed");
    _;
  }

  // Add additional owners to contract
  function addOwner(address _owner) public onlyOwner {
    owners[payable(_owner)] = true;
  }

  // Hash of: Party1 Address + Party2 Address + IPFS Hash + Block Number Agreement Proposed In
  function getMessageHash(address _party1, address _party2, string memory _ipfsHash, uint256 _blockNum) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_party1, _party2, _ipfsHash, _blockNum));
  }

  // Ethereum signed message has following format:
  // "\x19Ethereum Signed Message\n" + len(msg) + msg
  function getEthSignedMessageHash(bytes32 _messageHash) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
  }

  // Split signature into (r, s, v) components so ecrecover() can determine signer
  function splitSignature(bytes memory _signature) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
    require(_signature.length == 65, "Invalid signture length");
    assembly {
      // mload(p) loads next 32 bytes starting at memory address p into memory
      // First 32 bytes of signature stores the length of the signature and can be ignored
      r := mload(add(_signature, 32)) // r stores first 32 bytes after the length prefix (0-31)
      s := mload(add(_signature, 64)) // s stores the next 32 bytes after r
      v := byte(0, mload(add(_signature, 96))) // v stores the final byte (as signatures are 65 bytes total)
    }
    // assembly implicitly returns (r, s, v)
  }

  // Recover signer address for split signature
  function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) internal pure returns (address) {
    (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
    return ecrecover(_ethSignedMessageHash, v, r, s); // Recovers original signer from _ethSignedMessageHash and post-split _signature
  }

  // Verify if signature was for messageHash and that the signer is valid, public because interface might want to use this
  function verifySignature(address _signer, bytes32 _contractHash, bytes memory _signature) public pure returns (bool) {
    bytes32 ethSignedMessageHash = getEthSignedMessageHash(_contractHash);
    return recoverSigner(ethSignedMessageHash, _signature) == _signer;
  }

  /* Hash all relevant contract data
     Use of onlyInitiator requires contract to be created by initiator before being signable
     We prevent _counterParty from hashing because switching party address order will change hash 
     The contract hash is what each party needs to sign */
  function hashContract(address _counterParty, string memory _ipfsHash, uint256 _blockNum) internal onlyInitiator(_counterParty, _ipfsHash, _blockNum) returns (bytes32) {
    bytes32 contractHash = getMessageHash(msg.sender, _counterParty, _ipfsHash, _blockNum);
    // Save same contract hash for both parties. Initiator must be only caller as changing the address order changes the hash
    contractHashes[msg.sender][_counterParty][_ipfsHash][_blockNum] = contractHash;
    contractHashes[_counterParty][msg.sender][_ipfsHash][_blockNum] = contractHash;
    // Save contract party addresses
    contractParties[contractHash].push(msg.sender);
    contractParties[contractHash].push(_counterParty);
    // Save contract IPFS hash/pointer
    contractIpfsHash[contractHash] = _ipfsHash;
    // Save block number agreement proposed in
    contractBlock[contractHash] = _blockNum;
    emit ContractHashed(contractHash);
    return contractHash;
  }

  // Instantiate two party contract with (msg.sender, counterparty address, IPFS hash of the contract document, current block number) and hash it, return block number of agreement proposal
  function createTwoPartyContract(address _counterParty, string memory _ipfsHash) public returns (bytes32) {
    require(bytes32(contractHashes[msg.sender][_counterParty][_ipfsHash][block.number]) == 0, "Contract already initiated in this block");
    // Need to instantiate hash field for each party to pass onlyInitiator check in hashContract()
    contractHashes[msg.sender][_counterParty][_ipfsHash][block.number] = bytes32("1");
    bytes32 contractHash = hashContract(_counterParty, _ipfsHash, block.number);
    emit ContractCreated(msg.sender, _counterParty, _ipfsHash, block.number, contractHash);
    return contractHash;
  }

  // Commit signature to blockchain storage after verifying it is correct and that msg.sender hasn't already called signContract()
  // Consider cleaning function by migrating checks into modifiers
  function signContract(bytes32 _contractHash, bytes memory _signature) public validParty(_contractHash) notExecuted(_contractHash) {
    require(verifySignature(msg.sender, _contractHash, _signature), "Signature not valid");
    if (contractSignatures[_contractHash].length == 0) { // Push signature if no other signatures are stored
      contractSignatures[_contractHash].push(_signature);
      emit ContractSigned(msg.sender, _contractHash, _signature);
    } else if (contractSignatures[_contractHash].length == 1) { // Push signature if other party has signed and isn't trying to sign again
      require(recoverSigner(getEthSignedMessageHash(_contractHash), contractSignatures[_contractHash][0]) != msg.sender, "Already signed");
      contractSignatures[_contractHash].push(_signature);
      emit ContractSigned(msg.sender, _contractHash, _signature);
      contractExecuted[_contractHash] = true;
      emit ContractExecuted(_contractHash, block.number);
    } else { // Shouldn't ever be hit but will leave anyways
      revert("Two signatures already collected");
    }
  }

  // Created to validate both parties have signed with validated signatures
  // Will need to be adapted if multi-party signing is ever implemented
  function verifyExecution(bytes32 _contractHash) public view hasExecuted(_contractHash) returns (bool) {
    bool party1;
    bool party2;
    // Validate signatures against both addresses one at a time
    for (uint i = 0; i < contractSignatures[_contractHash].length; i++) {
      if (verifySignature(contractParties[_contractHash][0], _contractHash, contractSignatures[_contractHash][i])) {
        party1 = true;
      }
      if (verifySignature(contractParties[_contractHash][1], _contractHash, contractSignatures[_contractHash][i])) {
        party2 = true;
      }
    }
    return (party1 == party2);
  }

  // Return all contract data using just the _contractHash, returning struct composition required due to stack limitations
  // Might be useful for frontend
  function getContractData(bytes32 _contractHash) public view returns (Contract memory) {
    Contract memory contractData;
    contractData.initiator = contractParties[_contractHash][0];
    contractData.counterParty = contractParties[_contractHash][1];
    contractData.ipfsHash = contractIpfsHash[_contractHash];
    contractData.blockNumber = contractBlock[_contractHash];
    contractData.executed = contractExecuted[_contractHash];
    contractData.firstSignature = contractSignatures[_contractHash][0];
    contractData.secondSignature = contractSignatures[_contractHash][1];
    return (contractData);
  }

  // Payment handling functions if we need them, otherwise just accept and allow withdrawal to any owner
  function withdraw() public onlyOwner {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success);
  }
  receive() external payable {}
  fallback() external payable {}
}