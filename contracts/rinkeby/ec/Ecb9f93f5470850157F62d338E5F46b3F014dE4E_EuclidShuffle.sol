// SPDX-License-Identifier: MIT
//
//  ********  **     **    ******   **        **  *******  
// /**/////  /**    /**   **////** /**       /** /**////** 
// /**       /**    /**  **    //  /**       /** /**    /**
// /*******  /**    /** /**        /**       /** /**    /**
// /**////   /**    /** /**        /**       /** /**    /**
// /**       /**    /** //**    ** /**       /** /**    ** 
// /******** //*******   //******  /******** /** /*******  
// ////////   ///////     //////   ////////  //  ///////   
//
// by collect-code 2022
// https://collect-code.com/
//
pragma solidity ^0.8.2;
import "./IEuclidRandomizer.sol";

library EuclidShuffle {

	struct ShuffleState {
		mapping(uint32 => uint32) ids;
		uint32 size;
		uint32 pos;
	}

	//----------------------------------
	// Token Id Randomizer
	// (storage version)
	//
	// - based on Fisher–Yates shuffle
	// - it does not store the randomizer state, just generated Ids
	// - each call to getNextShuffleId() must contain a new seed
	// - use EuclidRandomizer.makeSeed() or make your own
	//
	// Initializes Shuffle storage
	// size is the total number of Ids to be suffled
	// allows getNextShuffleId() to be called <size> times
	function initialize(ShuffleState storage self, uint32 size) public {
		self.size = size;
		self.pos = 0;
	}
	// Return new shuffled id from storage
	// Ids keys and values range from 1..size
	// Returns 0 when all ids have been used
	function getNextShuffleId(IEuclidRandomizer randomizer, ShuffleState storage self, uint128 seed) public returns (uint32) {
		if(self.pos == self.size) return 0; // no more ids available
		self.pos += 1;
		if(self.pos == self.size) return self.ids[self.pos]; // last
		// choose a random remaining cell
		IEuclidRandomizer.RandomizerState memory rnd = randomizer.initialize(seed);
		rnd = randomizer.getIntRange(rnd, self.pos, self.size);
		// swap for current position
		uint32 swapPos = rnd.value + 1;
		uint32 newId = self.ids[swapPos] > 0 ? self.ids[swapPos] : swapPos;
		self.ids[swapPos] = self.ids[self.pos] > 0 ? self.ids[self.pos] : self.pos;
		self.ids[self.pos] = newId;
		return newId;
	}
}

// SPDX-License-Identifier: MIT
//
//  ********  **     **    ******   **        **  *******  
// /**/////  /**    /**   **////** /**       /** /**////** 
// /**       /**    /**  **    //  /**       /** /**    /**
// /*******  /**    /** /**        /**       /** /**    /**
// /**////   /**    /** /**        /**       /** /**    /**
// /**       /**    /** //**    ** /**       /** /**    ** 
// /******** //*******   //******  /******** /** /*******  
// ////////   ///////     //////   ////////  //  ///////   
//
// by collect-code 2022
// https://collect-code.com/
//
pragma solidity ^0.8.2;

interface IEuclidRandomizer {

	struct RandomizerState {
		uint32[4] state;
		uint32 value;
	}

	function makeSeed(address contractAddress, address senderAddress, uint blockNumber, uint256 tokenNumber) external view returns (uint128) ;
	function initialize(uint128 seed) external pure returns (RandomizerState memory);
	function initialize(bytes16 seed) external pure returns (RandomizerState memory);
	function getNextValue(RandomizerState memory self) external pure returns (RandomizerState memory);
	function getInt(RandomizerState memory self, uint32 maxExclusive) external pure returns (RandomizerState memory);
	function getIntRange(RandomizerState memory self, uint32 minInclusive, uint32 maxExclusive) external pure returns (RandomizerState memory);
}