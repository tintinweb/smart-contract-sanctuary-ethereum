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
  
  // Contract struct will hold all contract data
  struct Contract {
    address initiator;
    address counterparty;
    string ipfsHash;
    uint256 blockProposed;
    uint256 blockExecuted;
    bool executed;
    bytes initiatorSig;
    bytes counterpartySig;
  }

  // Store contract structs in mapping paired to contract hash
  mapping(bytes32 => Contract) public contracts;

  // Log contract hash, initiator address, counterparty address, ipfsHash/Pointer string, and blockNumber agreement is in
  // counterparty is the only unindexed parameter because EVM only allows for three and I found counterparty to be the least relevant
  event ContractCreated(bytes32 indexed contractHash, address initiator, address counterparty, string indexed ipfsHash, uint256 indexed blockNumber);
  // Log contract hashes on their own as all contrct details in ContractCreated can be obtianed by querying granular contract data mappings (contractParties, ...)
  event ContractHashed(bytes32 indexed contractHash);
  // Log contract signatures, contractHash used in verification, and the signer address to validate against
  event ContractSigned(bytes32 indexed contractHash, address indexed signer, bytes indexed signature);
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

  // Require function call by contract initiator
  modifier onlyInitiator(bytes32 _contractHash) {
    require(contracts[_contractHash].initiator == msg.sender, "Not contract initiator");
    _;
  }

  // Require function call by counterparty, mainly for calling execute contract
  modifier onlyCounterparty(bytes32 _contractHash) {
    require(contracts[_contractHash].counterparty == msg.sender, "Not contract counterparty");
    _;
  }

  // Require contract creation by checking if _party1 is part of a contract with _party2
  modifier validParty(bytes32 _contractHash) {
    require(contracts[_contractHash].initiator == msg.sender || contracts[_contractHash].counterparty == msg.sender, "Not a contract party");
    _;
  }

  modifier notExecuted(bytes32 _contractHash) {
    require(!contracts[_contractHash].executed, "Contract already executed");
    _;
  }

  // Require contract execution has occured by all parties signing
  modifier hasExecuted(bytes32 _contractHash) {
    require(contracts[_contractHash].executed, "Contract hasnt executed");
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
  function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
    return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
  }

  // Split signature into (r, s, v) components so ecrecover() can determine signer
  function splitSignature(bytes memory _signature) public pure returns (bytes32 r, bytes32 s, uint8 v) {
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
  function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) public pure returns (address) {
    (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
    return ecrecover(_ethSignedMessageHash, v, r, s); // Recovers original signer from _ethSignedMessageHash and post-split _signature
  }

  // Verify if signature was for messageHash and that the signer is valid, public because interface might want to use this
  function verifySignature(address _signer, bytes32 _contractHash, bytes memory _signature) public pure returns (bool) {
    bytes32 ethSignedMessageHash = getEthSignedMessageHash(_contractHash);
    return recoverSigner(ethSignedMessageHash, _signature) == _signer;
  }

    // Created to validate both parties have signed with validated signatures
  // Will need to be adapted if multi-party signing is ever implemented
  function verifyAllSignatures(bytes32 _contractHash) public view returns (bool) {
    bool initiatorSigValid = verifySignature(contracts[_contractHash].initiator, _contractHash, contracts[_contractHash].initiatorSig);
    bool counterpartySigValid = verifySignature(contracts[_contractHash].counterparty, _contractHash, contracts[_contractHash].counterpartySig);
    return (initiatorSigValid == counterpartySigValid);
  }

  /* Hash all relevant contract data
     We prevent _counterparty from hashing because switching party address order will change hash 
     The contract hash is what each party needs to sign */
  function hashContract(address _counterparty, string memory _ipfsHash, uint256 _blockNum) internal returns (bytes32) {
    // Generate contract hash
    bytes32 contractHash = getMessageHash(msg.sender, _counterparty, _ipfsHash, _blockNum);

    // Save same contract hash for both parties. Initiator must be only caller as changing the address order changes the hash
    contractHashes[msg.sender][_counterparty][_ipfsHash][_blockNum] = contractHash;
    contractHashes[_counterparty][msg.sender][_ipfsHash][_blockNum] = contractHash;
    emit ContractHashed(contractHash);
    return contractHash;
  }

  // Instantiate two party contract with (msg.sender, counterparty address, IPFS hash of the contract document, current block number) and hash it, return block number of agreement proposal
  function createTwoPartyContract(address _counterparty, string memory _ipfsHash) public returns (bytes32) {
    // Make sure this function isn't called twice in a block
    // Also block counterparty because initiator will set hashes for both address trees in contractHashes mapping
    require(bytes32(contractHashes[msg.sender][_counterparty][_ipfsHash][block.number]) == 0, "Contract already initiated in this block");
    bytes32 contractHash = hashContract(_counterparty, _ipfsHash, block.number);

    // Begin populating Contract data struct
    // Save contract party addresses
    contracts[contractHash].initiator = msg.sender;
    contracts[contractHash].counterparty = _counterparty;
    // Save contract IPFS hash/pointer
    contracts[contractHash].ipfsHash = _ipfsHash;
    // Save block number agreement proposed in
    contracts[contractHash].blockProposed = block.number;

    emit ContractCreated(contractHash, msg.sender, _counterparty, _ipfsHash, block.number);
    return contractHash;
  }

  function executeContract(bytes32 _contractHash) internal onlyCounterparty(_contractHash) returns (bool) {
    // Double check all signatures are valid
    require(verifyAllSignatures(_contractHash));
    contracts[_contractHash].blockExecuted = block.number;
    emit ContractExecuted(_contractHash, block.number);
    return true;
  }

  // Commit signature to blockchain storage after verifying it is correct and that msg.sender hasn't already called signContract()
  // Consider cleaning function by migrating checks into modifiers
  function signContract(bytes32 _contractHash, bytes memory _signature) public validParty(_contractHash) notExecuted(_contractHash) {
    require(verifySignature(msg.sender, _contractHash, _signature), "Signature not valid");

    if (contracts[_contractHash].initiator == msg.sender) { // Save initiator signature
      // Check if already signed
      require(keccak256(contracts[_contractHash].initiatorSig) != keccak256(_signature), "Already signed");
      // Save signature
      contracts[_contractHash].initiatorSig = _signature;
      emit ContractSigned(_contractHash, msg.sender, _signature);
      // If everyone signed, execute
      if (verifyAllSignatures(_contractHash)) {
        contracts[_contractHash].executed = executeContract(_contractHash);
      }

    } else if (contracts[_contractHash].counterparty == msg.sender) { // Save counterparty signature
      // Check if already signed
      require(keccak256(contracts[_contractHash].counterpartySig) != keccak256(_signature), "Already signed");
      // Save signature
      contracts[_contractHash].counterpartySig = _signature;
      emit ContractSigned(_contractHash, msg.sender, _signature);
      // If everyone signed, execute
      if (verifyAllSignatures(_contractHash)) {
        contracts[_contractHash].executed = executeContract(_contractHash);
      }

    } else { // Shouldn't ever be hit but will leave anyways
      revert("Not a contract party");
    }
  }

  // Return all contract data using just the _contractHash, returning struct composition required due to stack limitations
  // Might be useful for frontend
  function getContractData(bytes32 _contractHash) public view returns (Contract memory) {
    return (contracts[_contractHash]);
  }

  // Payment handling functions if we need them, otherwise just accept and allow withdrawal to any owner
  function withdraw() public onlyOwner {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success);
  }
  receive() external payable {}
  fallback() external payable {}
}