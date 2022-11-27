/**
 *Submitted for verification at Etherscan.io on 2022-11-27
*/

pragma solidity ^0.4.18;

contract Election {
    /* Constructor */
    address public signerAddress;
	mapping(uint16 => uint) public votesReceived;
	mapping(address => uint8) public madeVote;
	mapping(address => bytes32) public thisAddressVoteFor;
	uint public totalCandidates;
	uint public totalVotesReceived;
	uint public totalVotedPerson;
	uint8 public noOfRightToVote;

	event Vote(address vote_from, uint16 to_candidate_no);
    
    function Election (
		uint _totalCandidates,
		uint8 _noOfRightToVote
	) public {
		signerAddress = msg.sender;
		totalCandidates = _totalCandidates;
		noOfRightToVote = _noOfRightToVote;
    }
    
    function sliceAddress(bytes b, uint offset) internal pure returns (address) {
        bytes32 out;
        for (uint i = 0; i < 20; i++) {
            out |= bytes32(b[offset + i] & 0xFF) >> ((i+12) * 8);
        }
        return address(uint(out));
    }
	
    function slice32(bytes b, uint offset) internal pure returns (bytes32) {
        bytes32 out;
        for (uint i = 0; i < 32; i++) {
            out |= bytes32(b[offset + i] & 0xFF) >> (i * 8);
        }
        return out;
    }

    function slice20(bytes b, uint offset) internal pure returns (bytes20) {
        bytes20 out;
        for (uint i = 0; i < 20; i++) {
            out |= bytes20(b[offset + i] & 0xFF) >> (i * 8);
        }
        return out;
    }	
    
    function slice2(bytes b, uint offset) internal pure returns (bytes2) {
        bytes2 out;
        for (uint i = 0; i < 2; i++) {
            out |= bytes2(b[offset + i] & 0xFF) >> (i * 8);
        }
        return out;
    }

    function slice1(bytes b, uint offset) internal pure returns (bytes1) {
        bytes1 out;
        for (uint i = 0; i < 1; i++) {
            out |= bytes1(b[offset + i] & 0xFF) >> (i * 8);
        }
        return out;
    }
    
    function getSignedData(bytes dataframe, uint offset) internal pure returns(bytes32 r, bytes32 s, uint v) {
		bytes32 _r = slice32(dataframe, 0+offset);
		bytes32 _s = slice32(dataframe, 32+offset);
		uint _v = uint(slice1(dataframe, 64+offset));
        return (_r, _s, _v);
    }
    
    function getElectionData(bytes dataframe, uint offset) internal pure returns(bytes20 d1, bytes32 d2, address voterAddress) {
		bytes20 _d1 = slice20(dataframe, 65+offset);
		bytes32 _d2 = slice32(dataframe, 85+offset);
		address _voterAddress = sliceAddress(dataframe, 65+offset);
        return (_d1, _d2, _voterAddress);
    }

    function vote(bytes data, uint _offset) public returns(bool) {
        bytes32 r;
        bytes32 s;
        uint v;
        bytes20 d1;
        bytes32 d2;
        address voterAddress;
        (r, s, v) = getSignedData(data, _offset);
        (d1, d2, voterAddress) = getElectionData(data, _offset);
		if(madeVote[voterAddress]==0){
            bytes memory prefix = "\x19Ethereum Signed Message:\n32";
            bytes32 prefixedHash = keccak256(prefix, keccak256(d1, d2));
            address signer = ecrecover(prefixedHash, uint8(v), r, s);
    		require(signer==signerAddress);
    		thisAddressVoteFor[voterAddress] = d2;
    		for(uint i = 0; i < uint(noOfRightToVote); i++) {
    			uint16 candidateNo = uint16(slice2(data, 85+_offset+(i*2)));
    			if (candidateNo>0) {
        			votesReceived[candidateNo] += 1;
        		    totalVotesReceived += 1;
        		    Vote(voterAddress, candidateNo);
    			}
    		}
    		madeVote[voterAddress] += 1;
    		totalVotedPerson += 1;
		}
		return true;
    }
	
    function batchvote(bytes dataframe) public returns(bool) {
		bool check;
		uint batchsize = uint(slice1(dataframe, 0));
		for(uint j = 0; j < batchsize; j++) {
			check = vote(dataframe, 1+(117*j));
		}
		return check;
    }	
}