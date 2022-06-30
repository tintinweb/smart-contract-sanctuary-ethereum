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
import "@openzeppelin/contracts/utils/Strings.sol";
import "./IEuclidRandomizer.sol";
import "./IEuclidFormula.sol";

contract EuclidFormula is IEuclidFormula {
	using Strings for uint32;

	IEuclidRandomizer randomizer;

	constructor(address randomizer_) {
		randomizer = IEuclidRandomizer(randomizer_);
	}

	function generateFormula(uint128 hash, uint256 tokenId) public view override returns (string memory) {
		IEuclidRandomizer.RandomizerState memory rnd = randomizer.initialize(hash);
		uint8[6] memory supplyData = supplyDataFromTokenId(tokenId);
		bytes memory formula;
		// palette
		rnd = randomizer.getInt(rnd, supplyData[0]);
		uint32 pa = rnd.value;
		formula = abi.encodePacked(formula, 'pa', pa.toString());
		// shape count
		rnd = randomizer.getIntRange(rnd, supplyData[2], supplyData[3]+1);
		uint32 shapeCount = rnd.value;
		// attribute draw
		uint32 drawCount = 9 + 3 * shapeCount;
		uint32[] memory indices = new uint32[](drawCount);
		uint32[] memory draw = new uint32[](supplyData[5]);
		for (uint32 i = 0; i < indices.length ; i++) indices[i] = i;
		for (uint32 i = 0; i < draw.length ; i++) {
			rnd = randomizer.getIntRange(rnd, i, uint32(indices.length));
			draw[i] = indices[rnd.value];
			indices[rnd.value] = i;
		}
		uint8 drawing;
		bytes1 propValue;
		// prop: bg
		(rnd, propValue) = drawProp(rnd, drawing++, draw, bytes(pa==0?'01234568A':pa==1?'0123678A':pa==2?'02459':pa==3?'499999':pa==4?'02345A':pa==5?'01345A':pa==6?'0123457A':pa==7?'012367A':pa==8?'045':'012345678A'));
		formula = abi.encodePacked(formula, '.bg', propValue);
		// prop: ma
		(rnd, propValue) = drawProp(rnd, drawing++, draw, bytes(pa==3?'0000112':'00001123'));
		formula = abi.encodePacked(formula, '.ma', propValue);
		// prop: tr
		(rnd, propValue) = drawProp(rnd, drawing++, draw, bytes(pa==1?'022233':pa==3?'01122233':'011222334566'));
		formula = abi.encodePacked(formula, '.tr', propValue);
		(rnd, propValue) = drawProp(rnd, drawing++, draw, bytes(pa==0?'01111':pa==3?'01111':pa==6?'02223':pa==7?'02223':'011113'));
		formula = abi.encodePacked(formula, propValue);
		(rnd, propValue) = drawProp(rnd, drawing++, draw, bytes(pa==3?'00':'0000003333334'));
		formula = abi.encodePacked(formula, propValue);
		(rnd, propValue) = drawProp(rnd, drawing++, draw, bytes(pa==3?'00':'0000001111'));
		formula = abi.encodePacked(formula, propValue);
		(rnd, propValue) = drawProp(rnd, drawing++, draw, '0000000123');
		formula = abi.encodePacked(formula, propValue);
		// prop: fx
		(rnd, propValue) = drawProp(rnd, drawing++, draw, bytes(pa==3?'0111111244445555':pa==6?'0111111244445555':pa==8?'5155544':'01111112344445555'));
		formula = abi.encodePacked(formula, '.fx', propValue);
		(rnd, propValue) = drawProp(rnd, drawing++, draw, bytes(pa==1?'02':pa==2?'02':pa==3?'02':pa==6?'013':'012'));
		formula = abi.encodePacked(formula, propValue);
		// prop: rn
		(rnd, propValue) = randomizeProp(rnd, 0, '0123456789ABCDEF');
		formula = abi.encodePacked(formula, '.rn', propValue);
		(rnd, propValue) = randomizeProp(rnd, 0, '0123456789ABCDEF');
		formula = abi.encodePacked(formula, propValue);
		// randomize shapes
		for (uint32 i = 0; i < shapeCount ; i++) {
			// shape type
			bytes1 baseShape;
			if (i == 0) {
				baseShape = bytes('CTQP')[tokenId % supplyData[1]];
			} else {
				rnd = randomizer.getInt(rnd, supplyData[1]);
				baseShape = bytes('CTQP')[rnd.value];
			}
			rnd = randomizer.getInt(rnd, supplyData[4]);
			bytes1 shapeVariant = bytes(baseShape=='T'?'04261537':baseShape=='Q'?'00112200':baseShape=='P'?'56678865':'00000000')[rnd.value];
			formula = abi.encodePacked(formula, '.sh', baseShape, shapeVariant);
			if (i > 0) {
				// prop: fr
				(rnd, propValue) = randomizeProp(rnd, 0, 'FFCCMMMMMMMIIAAA');
				formula = abi.encodePacked(formula, 'fr', propValue);
				(rnd, propValue) = randomizeProp(rnd, 0, '0123456789ABCDEF');
				formula = abi.encodePacked(formula, propValue);
				(rnd, propValue) = randomizeProp(rnd, 0, '0123456789ABCDEF');
				formula = abi.encodePacked(formula, propValue);
				(rnd, propValue) = randomizeProp(rnd, 0, '0123456789ABCDEF');
				formula = abi.encodePacked(formula, propValue);
			}
			// prop: in
			(rnd, propValue) = randomizeProp(rnd, 0, 'SDDT');
			formula = abi.encodePacked(formula, 'in', propValue);
			(rnd, propValue) = randomizeProp(rnd, 0, '0123456789ABCDEF');
			formula = abi.encodePacked(formula, propValue);
			(rnd, propValue) = randomizeProp(rnd, 0, '0123456789ABCDEF');
			formula = abi.encodePacked(formula, propValue);
			// prop: st
			(rnd, propValue) = drawProp(rnd, drawing++, draw, '012');
			formula = abi.encodePacked(formula, 'st', propValue);
			(rnd, propValue) = drawProp(rnd, drawing++, draw, '0123');
			formula = abi.encodePacked(formula, propValue);
			(rnd, propValue) = drawProp(rnd, drawing++, draw, '011223');
			formula = abi.encodePacked(formula, propValue);
			// prop: rn
			(rnd, propValue) = randomizeProp(rnd, 0, '0123456789ABCDEF');
			formula = abi.encodePacked(formula, 'rn', propValue);
			(rnd, propValue) = randomizeProp(rnd, 0, '0123456789ABCDEF');
			formula = abi.encodePacked(formula, propValue);
		}
		// done!
		return string(formula);
	}
	
	function supplyDataFromTokenId(uint256 tokenId) public pure returns (uint8[6] memory) {
		if (tokenId > 714) return [9, 4, 2, 5, 8, 12];
		if (tokenId > 273) return [7, 4, 1, 4, 8, 11];
		if (tokenId > 104) return [5, 4, 1, 3, 8, 10];
		if (tokenId > 40) return [4, 4, 1, 2, 4, 9];
		if (tokenId > 15) return [3, 4, 1, 2, 2, 8];
		if (tokenId > 6) return [2, 3, 1, 1, 1, 7];
		if (tokenId > 2) return [1, 3, 1, 1, 1, 6];
		return [1, 3, 1, 1, 1, 5];
	}
	
	function drawProp(IEuclidRandomizer.RandomizerState memory rnd, uint8 drawing, uint32[] memory draw, bytes memory values) internal view returns(IEuclidRandomizer.RandomizerState memory, bytes1) {
		uint8 i = 0;
		for (; i < draw.length; i++) if (drawing == draw[i]) break;
		if (i == draw.length) return (rnd, values[0]);
		return randomizeProp(rnd, 1, values);
	}
	
	function randomizeProp(IEuclidRandomizer.RandomizerState memory rnd, uint32 startIndex, bytes memory values) internal view returns(IEuclidRandomizer.RandomizerState memory, bytes1) {
		rnd = randomizer.getIntRange(rnd, startIndex, uint32(values.length));
		return (rnd, values[rnd.value]);
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
import "@openzeppelin/contracts/utils/Strings.sol";
import "./IEuclidRandomizer.sol";

interface IEuclidFormula {
	function generateFormula(uint128 hash, uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}