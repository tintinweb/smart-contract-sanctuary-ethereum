pragma solidity 0.4.24;

// Taken from https://github.com/HarryR/solcrypto/blob/master/contracts/HackyAOSRing.sol and slightly modified by us
contract HackyAOSRing{
	  
    function sbmul_add_smul(uint256 a, uint256 x, uint256 y, uint256 c)
        internal pure returns(address)
    {
        uint256 Q = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;

        a = mulmod((Q - a) % Q, x, Q);

        return ecrecover(
        	bytes32(a),						// 'msghash'
        	y % 2 != 0 ? 28 : 27,		// v
        	bytes32(x),					// r
        	bytes32(mulmod(c, x, Q)));	// s
    }


	function HackySchnorrCalc( uint256 x, uint256 y, uint256 message, uint256 t, uint256 s )
		internal pure returns(uint256)
	{
		address hashed_point = sbmul_add_smul(t, x, y, s);

		bytes memory ring_link = abi.encodePacked(x, y, uint256(hashed_point), message);

		return uint256(keccak256(ring_link));
	}


	/**
	* @notice verify a ring signature
	* @param pubkeys the addresses of the ring (addresses = [key1-x, key1-y, key2-x, key2-y, ..., keyN-x, keyN-y])
	* @param tees the tees of the ring (tees = [tee1, tee2, ..., teeN])
	* @param seed the seed of the ring
	* @param message the message to verify
	*/
	function Verify( uint256[] pubkeys, uint256[] tees, uint256 seed, uint256 message )
		public pure returns (bool)
	{
		require( pubkeys.length % 2 == 0 );
		require( pubkeys.length > 0 );

		uint256 c = seed;
		uint256 nkeys = pubkeys.length / 2;
		uint256 j = 0;

		for( uint256 i = 0; i < nkeys; i++ )
		{
			c = HackySchnorrCalc(pubkeys[j], pubkeys[j+1], message, tees[i], c);
			j += 2;
		}

		return c == seed;
	}
}