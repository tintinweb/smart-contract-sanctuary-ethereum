pragma solidity 0.8.9;
//SPDX-License-Identifier: MIT
// Version 3.00

interface IVerifier {

    function verifyProof(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[4] memory input
        ) external view returns (bool r);
} 

interface IListHash {

   	 function getVersion(bytes memory proof) 
    		external view returns ( uint256 roothash, uint256 timestamp, 
    							  uint256 permalink, uint128 version, uint128 relayId);
}


contract Score
{
	mapping(uint256 => uint256) public score; // permalink => Score
	
	event ScoreIncreased(uint256 indexed permalink, uint256 newScore);
	

    IVerifier public verifier;
    IListHash public listhash;


    constructor(IVerifier _verifier, IListHash _listhash) {
			verifier = _verifier;
			listhash = _listhash;
    }

	
	function addScore(uint256 permalink, 	// permalink on our records
					  uint128 version,		// version on our records
					  uint128 relayId,		// relay on our records
					  bytes memory proof, 	// proof of roothash of relay
					  uint[2] memory a,		// proof of exclusion/inclusion
					  uint[2][2] memory b,
					  uint[2] memory c,
					  uint[4] memory input) external // roothash, permalink, version, isExclusion
	{
		 (uint256 roothash, , , , uint128 _relayId) = listhash.getVersion(proof);
    	 require( verifier.verifyProof(a, b, c, input) == true, "S1 wrong proof");
    	 require( permalink == input[1], "S2 wrong permalink");	
    	 require( roothash == input[0], "S3 wrong roothash");	
    	 require( (input[2] * input[3] == 0), "S4 wrong exclusion or inclusion flag");	
    	 require( version == input[2], "S5 wrong version");
    	 require( _relayId == relayId, "S6 wrong relay");
    	 
    	 score[permalink]++;
    	 emit ScoreIncreased( permalink, score[permalink]);
	}
}