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
    							  
     function getSeal(bytes memory proof) 
    		external view returns ( uint256 roothash, uint256 timestamp, 
    							  uint256 permalink, uint128 version, uint128 relayId);

}

interface IBridge {

		function verify(  bytes calldata proofData,
						  address contractAddress,
						  bytes calldata storageKey,
						  bytes calldata value,
						  uint256 blockhashExpiryMinutes) 
				external view returns (bool valid, string memory reason);


		function getMapStorageKey(uint256 index, uint256 mapPosition) 
				external pure returns (bytes memory data); 

}


contract Score
{

	mapping(uint256 => uint256) public score; // permalink => Score
	
	event ScoreIncreased(uint256 indexed permalink, uint256 newScore);
	event Check(string checkType, bool valid);
	

    IVerifier public verifier;
    IListHash public listhash;
    IBridge   public bridge;



    constructor(IVerifier _verifier, IListHash _listhash, IBridge _bridge) 
    {
			verifier = _verifier;
			listhash = _listhash;
			bridge = _bridge;
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
	
	function addScoreSeal(bytes memory proof,		  // proof of seal,
						  uint256 maxSealValidityInHours) // seal must be less then maxProofAgeInHours hours old
							external
	{
		 (, uint256 timestamp, uint256 permalink, uint128 version,) = listhash.getSeal(proof);
    	 require( version != 1, "S7 claim is revoked");
    	 require( block.timestamp < (timestamp + maxSealValidityInHours * 1 hours), "S8 seal is too old");
    	 
    	 score[permalink]++;
    	 emit ScoreIncreased( permalink, score[permalink]);
	}
	
	function syncScore( uint256 permalink, 		// permalink
						bytes calldata newScore,	// new score
						bytes calldata proof,   // AWS proof,
						address contractAddress,// AWS Score address
						uint256 blockhashExpiryMinutes) // hash must be less then blockhashExpiryMinutes minutes old
							external
	{
    	 //require( version != 1, "S8 claim is revoked");
    	 bytes memory storageKey = bridge.getMapStorageKey(permalink, 0);

		 (bool valid, string memory reason) = 
		 	bridge.verify(proof, contractAddress, storageKey, newScore, blockhashExpiryMinutes);
		 require( valid, reason);	
    	 
    	 score[permalink] = bytesToUint(newScore);
    	 emit ScoreIncreased( permalink, score[permalink]);
	}

	function bytesToUint(bytes memory b) internal pure returns (uint256)
	{
        uint256 number;
        for(uint i=0;i<b.length;i++){
            number = number + uint(uint8(b[i]))*(2**(8*(b.length-(i+1))));
        }
    	return number;
	}
	
}