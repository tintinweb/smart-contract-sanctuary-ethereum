// SPDX-License-Identifier: UNLICENSED
pragma solidity^0.8.0;
import './verifier_MerkleTree.sol';
import './verifier_zkSNARK.sol';

contract eVote {
    verifierMerkleTree vMerkleProof;
    verifierZKSNARK vzkSNARK;

    address public admin;
    mapping(address=> uint[2]) public publicKeys;
    mapping(address=> uint[2]) public encryptedVotes;
    mapping(address=> bool) public refunded;
    address[] public voters;
    uint public constant nVoters = 3;
    bytes32 public usersMerkleTreeRoot;
    uint public finishRegistartionBlockNumber;
    uint public finishVotingBlockNumber;
    uint public finishTallyBlockNumber;
    uint public constant DEPOSIT = 0.001 ether;
    uint public voteResult;
    uint[] public encryptedVotesXsign = [0];
    uint public constant pm1d2 = 10944121435919637611123202872628637544274182200208017171849102093287904247808;
    
    constructor(
            address _verifierMerkleTreeAddress, 
            address _verifierZKSNARKAddress, 
            bytes32 _usersMerkleTreeRoot, 
            uint _registrationBlockInterval, 
            uint _votingBlockInterval, 
            uint _tallyBlockInterval
        ) payable {
        require(msg.value==DEPOSIT,"Invalid deposit value");
        vMerkleProof = verifierMerkleTree(_verifierMerkleTreeAddress);
        vzkSNARK = verifierZKSNARK(_verifierZKSNARKAddress);
        admin = msg.sender;
        usersMerkleTreeRoot = _usersMerkleTreeRoot;
        finishRegistartionBlockNumber = block.number+_registrationBlockInterval;
        finishVotingBlockNumber = finishRegistartionBlockNumber + _votingBlockInterval;
        finishTallyBlockNumber = finishVotingBlockNumber+_tallyBlockInterval;
    }

    function register(
            uint[] memory _pubKey, 
            uint[2] memory proof_a, 
            uint[2][2] memory proof_b, 
            uint[2] memory proof_c, 
            bytes32[] memory _merkleProof
        ) public payable{
        require(msg.value==DEPOSIT,"Invalid deposit value");
        require(voters.length + 1 <= nVoters, "Max number of voters is reached");
        require(block.number<finishRegistartionBlockNumber,"Registration phase is already closed");
        require(vMerkleProof.verifyProof(_merkleProof, usersMerkleTreeRoot, keccak256(abi.encodePacked(msg.sender))), "Invalid Merkle proof");
        require(vzkSNARK.verifyProof(proof_a, proof_b, proof_c, _pubKey, 0),"Invalid DL proof");
        voters.push(msg.sender);
        publicKeys[msg.sender] = [_pubKey[0], _pubKey[1]];
    }
    function castVote(
            uint[2] memory _encryptedVote, 
            uint _Idx, 
            uint[2] memory proof_a, 
            uint[2][2] memory proof_b, 
            uint[2] memory proof_c
        ) public {
        require(block.number >= finishRegistartionBlockNumber, "Voting phase is not yet started");
        require(block.number < finishVotingBlockNumber, "Voting phase is already closed");
        require( msg.sender == voters[_Idx], "Unregistered voter");
        uint[] memory _publicSignals = new uint[](nVoters + 3);
        _publicSignals[0] = _encryptedVote[0];
        _publicSignals[1] = _encryptedVote[1];
        for(uint i=0; i<voters.length; i++){
            _publicSignals[i + 2] = publicKeys[voters[i]][1];
        }
        if (voters.length < nVoters){
            for(uint i=voters.length; i<nVoters; i++){
                _publicSignals[i + 2] = 1;
            }
        }
        _publicSignals[_publicSignals.length-1] = _Idx;
        
        require(vzkSNARK.verifyProof(proof_a, proof_b, proof_c, _publicSignals, 1),"Invalid encrypted vote");

        encryptedVotes[msg.sender] = _encryptedVote;

        if (_encryptedVote[0] >= pm1d2){
            encryptedVotesXsign[_Idx/253] ^= 1<<(_Idx%253);
        }
    }
    function setTally(
            uint _result, 
            uint[2] memory proof_a, 
            uint[2][2] memory proof_b, 
            uint[2] memory proof_c
        ) public {
        require(msg.sender==admin,"Only admin can set the tally result");
        require(block.number >= finishVotingBlockNumber, "Tallying phase is not yet started");
        require(block.number < finishTallyBlockNumber, "Tallying phase is already closed");
        
        uint[] memory _publicSignals = new uint[](nVoters + encryptedVotesXsign.length + 1);
        _publicSignals[0] = _result;
        uint offset = 1;
        for(uint i=0; i<encryptedVotesXsign.length;i++){
            _publicSignals[i + offset] = encryptedVotesXsign[i];
        }
        offset += encryptedVotesXsign.length;
        for(uint i=0; i<voters.length; i++){
            _publicSignals[i + offset] = encryptedVotes[voters[i]][1];
        }
        if (voters.length < nVoters){
            for(uint i=voters.length; i<nVoters; i++){
                _publicSignals[i + offset] = 1;
            }
        }        
        require(vzkSNARK.verifyProof(proof_a, proof_b, proof_c, _publicSignals, 2),"Invalid Tallying Result");
        voteResult = _result;
    }
    function refund() public{
        require(block.number >= finishTallyBlockNumber, "Invalid reclaim deposit phase");
        require(refunded[msg.sender] == false && (encryptedVotes[msg.sender][0] != 0 || msg.sender == admin),"Illegal reclaim");
        refunded[msg.sender] = true;
        payable(msg.sender).transfer(DEPOSIT);
    }
    
}