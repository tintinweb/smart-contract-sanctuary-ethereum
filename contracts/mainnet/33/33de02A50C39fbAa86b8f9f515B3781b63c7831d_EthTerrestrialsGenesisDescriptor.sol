//	SPDX-License-Identifier: MIT

/// @title  ETHTerrestrials by Kye descriptor (v1). An on-chain migration of assets from the OpenSea shared storefront token.
/// @notice Image and traits stored on-chain (non-generative)

pragma solidity ^0.8.0;

import "./InflateLib.sol";
import "./Strings.sol";
import "./Base64.sol";
import "@0xsequence/sstore2/contracts/SSTORE2.sol";

contract EthTerrestrialsGenesisDescriptor {
   using Strings for uint8;
   using Strings for uint256;
   using InflateLib for bytes;

   /// @notice Storage entry for a token
   struct Token {
      address imageStore; //SSTORE2 storage location for a base64 encoded PNG, compressed using DEFLATE (python zlib). Header (first 2 bytes) and checksum (last 4 bytes) truncated.
      uint96 imagelen; //The length of the uncomressed image data (required for decompression).
      uint8[] buildCode; //Each token's traits.
   }
   mapping(uint256 => Token) public tokenData;

   /// @notice Storage of the two types of traits
   mapping(uint256 => string) public skincolor;
   mapping(uint256 => string) public accesories;

   /// @notice Storage entry for an animated frame
   struct Frame {
      address imageStore; //SSTORE2 storage location for a base64 encoded PNG, compressed using DEFLATE (python zlib). Header (first 2 bytes) and checksum (last 4 bytes) truncated.
      uint96 imagelen; //The length of the uncomressed image data (required for decompression).
   }

   /// @notice A mapping of frame components for animated tokens in the format animationFrames[tokenId][frame number].
   /// @dev each frame is a base64 encoded PNG. In order to save storage space, each frame PNG only contains pixels that differ from frame 0
   mapping(uint256 => mapping(uint256 => Frame)) public animationFrames;

   /// @notice Permanently seals the metadata in the contract from being modified by deployer.
   bool public contractsealed;

   address private deployer;

   constructor() public {
      deployer = msg.sender;
   }

   modifier onlyDeployerWhileUnsealed() {
      require(!contractsealed && msg.sender == deployer, "Not authorized or locked");
      _;
   }

   string imageTagOpen =
      '<image x="0" y="0" width="24" height="24" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,';

   /*
.___  ___.  _______ .___________.    ___       _______       ___   .___________.    ___      
|   \/   | |   ____||           |   /   \     |       \     /   \  |           |   /   \     
|  \  /  | |  |__   `---|  |----`  /  ^  \    |  .--.  |   /  ^  \ `---|  |----`  /  ^  \    
|  |\/|  | |   __|      |  |      /  /_\  \   |  |  |  |  /  /_\  \    |  |      /  /_\  \   
|  |  |  | |  |____     |  |     /  _____  \  |  '--'  | /  _____  \   |  |     /  _____  \  
|__|  |__| |_______|    |__|    /__/     \__\ |_______/ /__/     \__\  |__|    /__/     \__\ 
*/

   /// @notice Generates a list of traits
   /// @param tokenId, the desired tokenId
   /// @return traits, a string array
   function viewTraits(uint256 tokenId) public view returns (string[] memory) {
      uint256 length = tokenData[tokenId].buildCode.length;
      string[] memory traits = new string[](length);

      for (uint256 i; i < length; i++) {
         uint8 thisTrait = tokenData[tokenId].buildCode[i];
         if (i == 0) {
            traits[i] = skincolor[thisTrait];
         } else {
            traits[i] = accesories[thisTrait];
         }
      }
      return traits;
   }

   /// @notice Generates an ERC721 standard metadata JSON string
   /// @param tokenId, the desired tokenId
   /// @return json, a JSON metadata string
   function viewTraitsJSON(uint256 tokenId) public view returns (string memory) {
      uint256 length = tokenData[tokenId].buildCode.length;
      string[] memory traits = new string[](length);
      traits = viewTraits(tokenId);

      traits[0] = string(abi.encodePacked('[{"trait_type":"Genesis Skin Color","value":"', traits[0], '"}'));

      for (uint256 i = 1; i < length; i++) {
         traits[i] = string(abi.encodePacked(',{"trait_type":"Genesis Accessory","value":"', traits[i], '"}'));
      }

      string memory json = traits[0];
      for (uint256 i = 1; i < length; i++) {
         json = string(abi.encodePacked(json, traits[i]));
      }

      json = string(abi.encodePacked(json, ',{"trait_type":"Life Form","value":"Genesis"}]'));
      return json;
   }

   /// @notice Returns an ERC721 standard tokenURI
   /// @param tokenId, the desired tokenId to display
   /// @return output, a base64 encoded JSON string containing the tokenURI (metadata and image)
   function generateTokenURI(uint256 tokenId) external view returns (string memory) {
      string memory name = string(abi.encodePacked("Genesis EtherTerrestrial #", tokenId.toString()));
      string
         memory description = "EtherTerrestrials are inter-dimensional Extra-Terrestrials who came to Earth's internet to infuse consciousness into all other pixelated Lifeforms. They can be encountered in the form of on-chain characters as interpreted by the existential explorer Kye.";
      string memory traits = viewTraitsJSON(tokenId);
      string memory svg = getSvg(tokenId);

      string memory json = Base64.encode(
         bytes(
            string(
               abi.encodePacked(
                  '{"name": "',
                  name,
                  '", "description": "',
                  description,
                  '", "attributes":',
                  traits,
                  ',"image": "data:image/svg+xml;base64,',
                  Base64.encode(bytes(svg)),
                  '"}'
               )
            )
         )
      );

      string memory output = string(abi.encodePacked("data:application/json;base64,", json));
      return output;
   }

   /// @notice Generates an unencoded SVG image for a given token
   /// @param tokenId, the desired tokenId to display
   /// @dev PNG images are added into an SVG for easy scaling
   /// @return an SVG string
   function getSvg(uint256 tokenId) public view returns (string memory) {
      string
         memory SVG = '<svg id="ETHT" width="100%" height="100%" version="1.1" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">';
      string memory base64encodedPNG = decompress(SSTORE2.read(tokenData[tokenId].imageStore), tokenData[tokenId].imagelen);
      SVG = string(
         abi.encodePacked(
            SVG,
            imageTagOpen,
            base64encodedPNG,
            '"/>',
            tokenId <= 3 ? addAnimations(tokenId) : "",
            "<style>#ETHT{shape-rendering: crispedges; image-rendering: -webkit-crisp-edges; image-rendering: -moz-crisp-edges; image-rendering: crisp-edges; image-rendering: pixelated; -ms-interpolation-mode: nearest-neighbor;}</style></svg>"
         )
      );
      return SVG;
   }

   /// @notice Builds animation layers for certain tokens
   /// @param tokenId, the desired tokenId
   /// @return allAnimatedFrames, a string of SVG components
   function addAnimations(uint256 tokenId) internal view returns (string memory) {
      uint8 numAnimatedFrames;
      string memory duration;
      if (tokenId == 1) {
         numAnimatedFrames = 18;
         duration = "1.33";
      } else if (tokenId == 2) {
         numAnimatedFrames = 32;
         duration = "2.31";
      } else if (tokenId == 3) {
         numAnimatedFrames = 35;
         duration = "2.52";
      }
      string[36] memory frames;
      frames[0] = string(
         abi.encodePacked(
            '<rect><animate  id="b" begin="0;f',
            (numAnimatedFrames - 1).toString(),
            '.end" dur="',
            duration,
            's" attributeName="visibility" from="hide" to="hide"/></rect>'
         )
      );

      for (uint8 i; i < numAnimatedFrames; i++) {
         string memory begin;
         if (i == 0) begin = "b.begin+0.07s";
         else begin = string(abi.encodePacked("f", (i - 1).toString(), ".end"));

         string memory frame = string(
            abi.encodePacked(
               '<g opacity="0">',
               imageTagOpen,
               decompress(SSTORE2.read(animationFrames[tokenId][i].imageStore), animationFrames[tokenId][i].imagelen),
               '"/>',
               '<animate attributeName="opacity" id ="f',
               i.toString(),
               '" begin="',
               begin,
               '" values="1" dur="0.07"  calcMode="discrete"/></g>'
            )
         );
         frames[i + 1] = frame;
      }

      string memory allAnimatedFrames;

      for (uint8 i; i < numAnimatedFrames + 1; i++) {
         allAnimatedFrames = string(abi.encodePacked(allAnimatedFrames, frames[i]));
      }

      return allAnimatedFrames;
   }

   function decompress(bytes memory input, uint256 len) public pure returns (string memory) {
      (, bytes memory decompressed) = InflateLib.puff(input, len);
      return string(decompressed);
   }

   /*
 _______   _______ .______    __        ______   ____    ____  _______ .______      
|       \ |   ____||   _  \  |  |      /  __  \  \   \  /   / |   ____||   _  \     
|  .--.  ||  |__   |  |_)  | |  |     |  |  |  |  \   \/   /  |  |__   |  |_)  |    
|  |  |  ||   __|  |   ___/  |  |     |  |  |  |   \_    _/   |   __|  |      /     
|  '--'  ||  |____ |  |      |  `----.|  `--'  |     |  |     |  |____ |  |\  \----.
|_______/ |_______|| _|      |_______| \______/      |__|     |_______|| _| `._____|
                                                                                                                                                
*/

   /// @notice Establishes the list of accessory traits
   function setSkins(string[] memory _skins, uint256[] memory traitNumber) external onlyDeployerWhileUnsealed {
      require(_skins.length == traitNumber.length);

      for (uint8 i; i < _skins.length; i++) skincolor[traitNumber[i]] = _skins[i];
   }

   /// @notice Establishes the list of accessory traits
   function setAccessories(string[] memory _accesories, uint256[] memory traitNumber) external onlyDeployerWhileUnsealed {
      require(_accesories.length == traitNumber.length);
      for (uint8 i; i < _accesories.length; i++) accesories[traitNumber[i]] = _accesories[i];
   }

   /// @notice Establishes the tokenData for a list of tokens (image and trait build code)
   function setTokenData(
      uint8[] memory _newTokenIds,
      Token[] memory _tokenData,
      bytes[] memory _imageData
   ) external onlyDeployerWhileUnsealed {
      require(_newTokenIds.length == _tokenData.length && _imageData.length == _tokenData.length);
      for (uint8 i; i < _newTokenIds.length; i++) {
         _tokenData[i].imageStore = SSTORE2.write(_imageData[i]);
         tokenData[_newTokenIds[i]] = _tokenData[i];
      }
   }

   /// @notice Establishes the animated frames for a given tokenId
   function setAnimationFrames(
      uint256 _tokenId,
      Frame[] memory _animationFrames,
      uint256[] memory frameNumber,
      bytes[] memory _imageData
   ) external onlyDeployerWhileUnsealed {
      require(_tokenId <= 3);
      require(_animationFrames.length == frameNumber.length && _imageData.length == frameNumber.length);
      for (uint256 i; i < _animationFrames.length; i++) {
         _animationFrames[i].imageStore = SSTORE2.write(_imageData[i]);
         animationFrames[_tokenId][frameNumber[i]] = _animationFrames[i];
      }
   }

   /// @notice IRREVERSIBLY SEALS THE CONTRACT FROM BEING MODIFIED
   function sealContract() external onlyDeployerWhileUnsealed {
      contractsealed = true;
   }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0 <0.9.0;

/// https://github.com/adlerjohn/inflate-sol
/// @notice Based on https://github.com/madler/zlib/blob/master/contrib/puff
library InflateLib {
   // Maximum bits in a code
   uint256 constant MAXBITS = 15;
   // Maximum number of literal/length codes
   uint256 constant MAXLCODES = 286;
   // Maximum number of distance codes
   uint256 constant MAXDCODES = 30;
   // Maximum codes lengths to read
   uint256 constant MAXCODES = (MAXLCODES + MAXDCODES);
   // Number of fixed literal/length codes
   uint256 constant FIXLCODES = 288;

   // Error codes
   enum ErrorCode {
      ERR_NONE, // 0 successful inflate
      ERR_NOT_TERMINATED, // 1 available inflate data did not terminate
      ERR_OUTPUT_EXHAUSTED, // 2 output space exhausted before completing inflate
      ERR_INVALID_BLOCK_TYPE, // 3 invalid block type (type == 3)
      ERR_STORED_LENGTH_NO_MATCH, // 4 stored block length did not match one's complement
      ERR_TOO_MANY_LENGTH_OR_DISTANCE_CODES, // 5 dynamic block code description: too many length or distance codes
      ERR_CODE_LENGTHS_CODES_INCOMPLETE, // 6 dynamic block code description: code lengths codes incomplete
      ERR_REPEAT_NO_FIRST_LENGTH, // 7 dynamic block code description: repeat lengths with no first length
      ERR_REPEAT_MORE, // 8 dynamic block code description: repeat more than specified lengths
      ERR_INVALID_LITERAL_LENGTH_CODE_LENGTHS, // 9 dynamic block code description: invalid literal/length code lengths
      ERR_INVALID_DISTANCE_CODE_LENGTHS, // 10 dynamic block code description: invalid distance code lengths
      ERR_MISSING_END_OF_BLOCK, // 11 dynamic block code description: missing end-of-block code
      ERR_INVALID_LENGTH_OR_DISTANCE_CODE, // 12 invalid literal/length or distance code in fixed or dynamic block
      ERR_DISTANCE_TOO_FAR, // 13 distance is too far back in fixed or dynamic block
      ERR_CONSTRUCT // 14 internal: error in construct()
   }

   // Input and output state
   struct State {
      //////////////////
      // Output state //
      //////////////////
      // Output buffer
      bytes output;
      // Bytes written to out so far
      uint256 outcnt;
      /////////////////
      // Input state //
      /////////////////
      // Input buffer
      bytes input;
      // Bytes read so far
      uint256 incnt;
      ////////////////
      // Temp state //
      ////////////////
      // Bit buffer
      uint256 bitbuf;
      // Number of bits in bit buffer
      uint256 bitcnt;
      //////////////////////////
      // Static Huffman codes //
      //////////////////////////
      Huffman lencode;
      Huffman distcode;
   }

   // Huffman code decoding tables
   struct Huffman {
      uint256[] counts;
      uint256[] symbols;
   }

   function bits(State memory s, uint256 need) private pure returns (ErrorCode, uint256) {
      // Bit accumulator (can use up to 20 bits)
      uint256 val;

      // Load at least need bits into val
      val = s.bitbuf;
      while (s.bitcnt < need) {
         if (s.incnt == s.input.length) {
            // Out of input
            return (ErrorCode.ERR_NOT_TERMINATED, 0);
         }

         // Load eight bits
         val |= uint256(uint8(s.input[s.incnt++])) << s.bitcnt;
         s.bitcnt += 8;
      }

      // Drop need bits and update buffer, always zero to seven bits left
      s.bitbuf = val >> need;
      s.bitcnt -= need;

      // Return need bits, zeroing the bits above that
      uint256 ret = (val & ((1 << need) - 1));
      return (ErrorCode.ERR_NONE, ret);
   }

   function _stored(State memory s) private pure returns (ErrorCode) {
      // Length of stored block
      uint256 len;

      // Discard leftover bits from current byte (assumes s.bitcnt < 8)
      s.bitbuf = 0;
      s.bitcnt = 0;

      // Get length and check against its one's complement
      if (s.incnt + 4 > s.input.length) {
         // Not enough input
         return ErrorCode.ERR_NOT_TERMINATED;
      }
      len = uint256(uint8(s.input[s.incnt++]));
      len |= uint256(uint8(s.input[s.incnt++])) << 8;

      if (uint8(s.input[s.incnt++]) != (~len & 0xFF) || uint8(s.input[s.incnt++]) != ((~len >> 8) & 0xFF)) {
         // Didn't match complement!
         return ErrorCode.ERR_STORED_LENGTH_NO_MATCH;
      }

      // Copy len bytes from in to out
      if (s.incnt + len > s.input.length) {
         // Not enough input
         return ErrorCode.ERR_NOT_TERMINATED;
      }
      if (s.outcnt + len > s.output.length) {
         // Not enough output space
         return ErrorCode.ERR_OUTPUT_EXHAUSTED;
      }
      while (len != 0) {
         // Note: Solidity reverts on underflow, so we decrement here
         len -= 1;
         s.output[s.outcnt++] = s.input[s.incnt++];
      }

      // Done with a valid stored block
      return ErrorCode.ERR_NONE;
   }

   function _decode(State memory s, Huffman memory h) private pure returns (ErrorCode, uint256) {
      // Current number of bits in code
      uint256 len;
      // Len bits being decoded
      uint256 code = 0;
      // First code of length len
      uint256 first = 0;
      // Number of codes of length len
      uint256 count;
      // Index of first code of length len in symbol table
      uint256 index = 0;
      // Error code
      ErrorCode err;

      for (len = 1; len <= MAXBITS; len++) {
         // Get next bit
         uint256 tempCode;
         (err, tempCode) = bits(s, 1);
         if (err != ErrorCode.ERR_NONE) {
            return (err, 0);
         }
         code |= tempCode;
         count = h.counts[len];

         // If length len, return symbol
         if (code < first + count) {
            return (ErrorCode.ERR_NONE, h.symbols[index + (code - first)]);
         }
         // Else update for next length
         index += count;
         first += count;
         first <<= 1;
         code <<= 1;
      }

      // Ran out of codes
      return (ErrorCode.ERR_INVALID_LENGTH_OR_DISTANCE_CODE, 0);
   }

   function _construct(
      Huffman memory h,
      uint256[] memory lengths,
      uint256 n,
      uint256 start
   ) private pure returns (ErrorCode) {
      // Current symbol when stepping through lengths[]
      uint256 symbol;
      // Current length when stepping through h.counts[]
      uint256 len;
      // Number of possible codes left of current length
      uint256 left;
      // Offsets in symbol table for each length
      uint256[MAXBITS + 1] memory offs;

      // Count number of codes of each length
      for (len = 0; len <= MAXBITS; len++) {
         h.counts[len] = 0;
      }
      for (symbol = 0; symbol < n; symbol++) {
         // Assumes lengths are within bounds
         h.counts[lengths[start + symbol]]++;
      }
      // No codes!
      if (h.counts[0] == n) {
         // Complete, but decode() will fail
         return (ErrorCode.ERR_NONE);
      }

      // Check for an over-subscribed or incomplete set of lengths

      // One possible code of zero length
      left = 1;

      for (len = 1; len <= MAXBITS; len++) {
         // One more bit, double codes left
         left <<= 1;
         if (left < h.counts[len]) {
            // Over-subscribed--return error
            return ErrorCode.ERR_CONSTRUCT;
         }
         // Deduct count from possible codes

         left -= h.counts[len];
      }

      // Generate offsets into symbol table for each length for sorting
      offs[1] = 0;
      for (len = 1; len < MAXBITS; len++) {
         offs[len + 1] = offs[len] + h.counts[len];
      }

      // Put symbols in table sorted by length, by symbol order within each length
      for (symbol = 0; symbol < n; symbol++) {
         if (lengths[start + symbol] != 0) {
            h.symbols[offs[lengths[start + symbol]]++] = symbol;
         }
      }

      // Left > 0 means incomplete
      return left > 0 ? ErrorCode.ERR_CONSTRUCT : ErrorCode.ERR_NONE;
   }

   function _codes(
      State memory s,
      Huffman memory lencode,
      Huffman memory distcode
   ) private pure returns (ErrorCode) {
      // Decoded symbol
      uint256 symbol;
      // Length for copy
      uint256 len;
      // Distance for copy
      uint256 dist;
      // TODO Solidity doesn't support constant arrays, but these are fixed at compile-time
      // Size base for length codes 257..285
      uint16[29] memory lens = [
         3,
         4,
         5,
         6,
         7,
         8,
         9,
         10,
         11,
         13,
         15,
         17,
         19,
         23,
         27,
         31,
         35,
         43,
         51,
         59,
         67,
         83,
         99,
         115,
         131,
         163,
         195,
         227,
         258
      ];
      // Extra bits for length codes 257..285
      uint8[29] memory lext = [0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 0];
      // Offset base for distance codes 0..29
      uint16[30] memory dists = [
         1,
         2,
         3,
         4,
         5,
         7,
         9,
         13,
         17,
         25,
         33,
         49,
         65,
         97,
         129,
         193,
         257,
         385,
         513,
         769,
         1025,
         1537,
         2049,
         3073,
         4097,
         6145,
         8193,
         12289,
         16385,
         24577
      ];
      // Extra bits for distance codes 0..29
      uint8[30] memory dext = [0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13];
      // Error code
      ErrorCode err;

      // Decode literals and length/distance pairs
      while (symbol != 256) {
         (err, symbol) = _decode(s, lencode);
         if (err != ErrorCode.ERR_NONE) {
            // Invalid symbol
            return err;
         }

         if (symbol < 256) {
            // Literal: symbol is the byte
            // Write out the literal
            if (s.outcnt == s.output.length) {
               return ErrorCode.ERR_OUTPUT_EXHAUSTED;
            }
            s.output[s.outcnt] = bytes1(uint8(symbol));
            s.outcnt++;
         } else if (symbol > 256) {
            uint256 tempBits;
            // Length
            // Get and compute length
            symbol -= 257;
            if (symbol >= 29) {
               // Invalid fixed code
               return ErrorCode.ERR_INVALID_LENGTH_OR_DISTANCE_CODE;
            }

            (err, tempBits) = bits(s, lext[symbol]);
            if (err != ErrorCode.ERR_NONE) {
               return err;
            }
            len = lens[symbol] + tempBits;

            // Get and check distance
            (err, symbol) = _decode(s, distcode);
            if (err != ErrorCode.ERR_NONE) {
               // Invalid symbol
               return err;
            }
            (err, tempBits) = bits(s, dext[symbol]);
            if (err != ErrorCode.ERR_NONE) {
               return err;
            }
            dist = dists[symbol] + tempBits;
            if (dist > s.outcnt) {
               // Distance too far back
               return ErrorCode.ERR_DISTANCE_TOO_FAR;
            }

            // Copy length bytes from distance bytes back
            if (s.outcnt + len > s.output.length) {
               return ErrorCode.ERR_OUTPUT_EXHAUSTED;
            }
            while (len != 0) {
               // Note: Solidity reverts on underflow, so we decrement here
               len -= 1;
               s.output[s.outcnt] = s.output[s.outcnt - dist];
               s.outcnt++;
            }
         } else {
            s.outcnt += len;
         }
      }

      // Done with a valid fixed or dynamic block
      return ErrorCode.ERR_NONE;
   }

   function _build_fixed(State memory s) private pure returns (ErrorCode) {
      // Build fixed Huffman tables
      // TODO this is all a compile-time constant
      uint256 symbol;
      uint256[] memory lengths = new uint256[](FIXLCODES);

      // Literal/length table
      for (symbol = 0; symbol < 144; symbol++) {
         lengths[symbol] = 8;
      }
      for (; symbol < 256; symbol++) {
         lengths[symbol] = 9;
      }
      for (; symbol < 280; symbol++) {
         lengths[symbol] = 7;
      }
      for (; symbol < FIXLCODES; symbol++) {
         lengths[symbol] = 8;
      }

      _construct(s.lencode, lengths, FIXLCODES, 0);

      // Distance table
      for (symbol = 0; symbol < MAXDCODES; symbol++) {
         lengths[symbol] = 5;
      }

      _construct(s.distcode, lengths, MAXDCODES, 0);

      return ErrorCode.ERR_NONE;
   }

   function _fixed(State memory s) private pure returns (ErrorCode) {
      // Decode data until end-of-block code
      return _codes(s, s.lencode, s.distcode);
   }

   function _build_dynamic_lengths(State memory s) private pure returns (ErrorCode, uint256[] memory) {
      uint256 ncode;
      // Index of lengths[]
      uint256 index;
      // Descriptor code lengths
      uint256[] memory lengths = new uint256[](MAXCODES);
      // Error code
      ErrorCode err;
      // Permutation of code length codes
      uint8[19] memory order = [16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15];

      (err, ncode) = bits(s, 4);
      if (err != ErrorCode.ERR_NONE) {
         return (err, lengths);
      }
      ncode += 4;

      // Read code length code lengths (really), missing lengths are zero
      for (index = 0; index < ncode; index++) {
         (err, lengths[order[index]]) = bits(s, 3);
         if (err != ErrorCode.ERR_NONE) {
            return (err, lengths);
         }
      }
      for (; index < 19; index++) {
         lengths[order[index]] = 0;
      }

      return (ErrorCode.ERR_NONE, lengths);
   }

   function _build_dynamic(State memory s)
      private
      pure
      returns (
         ErrorCode,
         Huffman memory,
         Huffman memory
      )
   {
      // Number of lengths in descriptor
      uint256 nlen;
      uint256 ndist;
      // Index of lengths[]
      uint256 index;
      // Error code
      ErrorCode err;
      // Descriptor code lengths
      uint256[] memory lengths = new uint256[](MAXCODES);
      // Length and distance codes
      Huffman memory lencode = Huffman(new uint256[](MAXBITS + 1), new uint256[](MAXLCODES));
      Huffman memory distcode = Huffman(new uint256[](MAXBITS + 1), new uint256[](MAXDCODES));
      uint256 tempBits;

      // Get number of lengths in each table, check lengths
      (err, nlen) = bits(s, 5);
      if (err != ErrorCode.ERR_NONE) {
         return (err, lencode, distcode);
      }
      nlen += 257;
      (err, ndist) = bits(s, 5);
      if (err != ErrorCode.ERR_NONE) {
         return (err, lencode, distcode);
      }
      ndist += 1;

      if (nlen > MAXLCODES || ndist > MAXDCODES) {
         // Bad counts
         return (ErrorCode.ERR_TOO_MANY_LENGTH_OR_DISTANCE_CODES, lencode, distcode);
      }

      (err, lengths) = _build_dynamic_lengths(s);
      if (err != ErrorCode.ERR_NONE) {
         return (err, lencode, distcode);
      }

      // Build huffman table for code lengths codes (use lencode temporarily)
      err = _construct(lencode, lengths, 19, 0);
      if (err != ErrorCode.ERR_NONE) {
         // Require complete code set here
         return (ErrorCode.ERR_CODE_LENGTHS_CODES_INCOMPLETE, lencode, distcode);
      }

      // Read length/literal and distance code length tables
      index = 0;
      while (index < nlen + ndist) {
         // Decoded value
         uint256 symbol;
         // Last length to repeat
         uint256 len;

         (err, symbol) = _decode(s, lencode);
         if (err != ErrorCode.ERR_NONE) {
            // Invalid symbol
            return (err, lencode, distcode);
         }

         if (symbol < 16) {
            // Length in 0..15
            lengths[index++] = symbol;
         } else {
            // Repeat instruction
            // Assume repeating zeros
            len = 0;
            if (symbol == 16) {
               // Repeat last length 3..6 times
               if (index == 0) {
                  // No last length!
                  return (ErrorCode.ERR_REPEAT_NO_FIRST_LENGTH, lencode, distcode);
               }
               // Last length
               len = lengths[index - 1];
               (err, tempBits) = bits(s, 2);
               if (err != ErrorCode.ERR_NONE) {
                  return (err, lencode, distcode);
               }
               symbol = 3 + tempBits;
            } else if (symbol == 17) {
               // Repeat zero 3..10 times
               (err, tempBits) = bits(s, 3);
               if (err != ErrorCode.ERR_NONE) {
                  return (err, lencode, distcode);
               }
               symbol = 3 + tempBits;
            } else {
               // == 18, repeat zero 11..138 times
               (err, tempBits) = bits(s, 7);
               if (err != ErrorCode.ERR_NONE) {
                  return (err, lencode, distcode);
               }
               symbol = 11 + tempBits;
            }

            if (index + symbol > nlen + ndist) {
               // Too many lengths!
               return (ErrorCode.ERR_REPEAT_MORE, lencode, distcode);
            }
            while (symbol != 0) {
               // Note: Solidity reverts on underflow, so we decrement here
               symbol -= 1;

               // Repeat last or zero symbol times
               lengths[index++] = len;
            }
         }
      }

      // Check for end-of-block code -- there better be one!
      if (lengths[256] == 0) {
         return (ErrorCode.ERR_MISSING_END_OF_BLOCK, lencode, distcode);
      }

      // Build huffman table for literal/length codes
      err = _construct(lencode, lengths, nlen, 0);
      if (
         err != ErrorCode.ERR_NONE &&
         (err == ErrorCode.ERR_NOT_TERMINATED || err == ErrorCode.ERR_OUTPUT_EXHAUSTED || nlen != lencode.counts[0] + lencode.counts[1])
      ) {
         // Incomplete code ok only for single length 1 code
         return (ErrorCode.ERR_INVALID_LITERAL_LENGTH_CODE_LENGTHS, lencode, distcode);
      }

      // Build huffman table for distance codes
      err = _construct(distcode, lengths, ndist, nlen);
      if (
         err != ErrorCode.ERR_NONE &&
         (err == ErrorCode.ERR_NOT_TERMINATED || err == ErrorCode.ERR_OUTPUT_EXHAUSTED || ndist != distcode.counts[0] + distcode.counts[1])
      ) {
         // Incomplete code ok only for single length 1 code
         return (ErrorCode.ERR_INVALID_DISTANCE_CODE_LENGTHS, lencode, distcode);
      }

      return (ErrorCode.ERR_NONE, lencode, distcode);
   }

   function _dynamic(State memory s) private pure returns (ErrorCode) {
      // Length and distance codes
      Huffman memory lencode;
      Huffman memory distcode;
      // Error code
      ErrorCode err;

      (err, lencode, distcode) = _build_dynamic(s);
      if (err != ErrorCode.ERR_NONE) {
         return err;
      }

      // Decode data until end-of-block code
      return _codes(s, lencode, distcode);
   }

   function puff(bytes memory source, uint256 destlen) internal pure returns (ErrorCode, bytes memory) {
      // Input/output state
      State memory s = State(
         new bytes(destlen),
         0,
         source,
         0,
         0,
         0,
         Huffman(new uint256[](MAXBITS + 1), new uint256[](FIXLCODES)),
         Huffman(new uint256[](MAXBITS + 1), new uint256[](MAXDCODES))
      );
      // Temp: last bit
      uint256 last;
      // Temp: block type bit
      uint256 t;
      // Error code
      ErrorCode err;

      // Build fixed Huffman tables
      err = _build_fixed(s);
      if (err != ErrorCode.ERR_NONE) {
         return (err, s.output);
      }

      // Process blocks until last block or error
      while (last == 0) {
         // One if last block
         (err, last) = bits(s, 1);
         if (err != ErrorCode.ERR_NONE) {
            return (err, s.output);
         }

         // Block type 0..3
         (err, t) = bits(s, 2);
         if (err != ErrorCode.ERR_NONE) {
            return (err, s.output);
         }

         err = (t == 0 ? _stored(s) : (t == 1 ? _fixed(s) : (t == 2 ? _dynamic(s) : ErrorCode.ERR_INVALID_BLOCK_TYPE)));
         // type == 3, invalid

         if (err != ErrorCode.ERR_NONE) {
            // Return with error
            break;
         }
      }

      return (err, s.output);
   }
}

library Strings {
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
}

// SPDX-License-Identifier: MIT
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>

library Base64 {
   string internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

   function encode(bytes memory data) internal pure returns (string memory) {
      if (data.length == 0) return "";

      // load the table into memory
      string memory table = TABLE;

      // multiply by 4/3 rounded up
      uint256 encodedLen = 4 * ((data.length + 2) / 3);

      // add some extra buffer at the end required for the writing
      string memory result = new string(encodedLen + 32);

      assembly {
         // set the actual output length
         mstore(result, encodedLen)

         // prepare the lookup table
         let tablePtr := add(table, 1)

         // input ptr
         let dataPtr := data
         let endPtr := add(dataPtr, mload(data))

         // result ptr, jump over length
         let resultPtr := add(result, 32)

         // run over the input, 3 bytes at a time
         for {

         } lt(dataPtr, endPtr) {

         } {
            dataPtr := add(dataPtr, 3)

            // read 3 bytes
            let input := mload(dataPtr)

            // write 4 characters
            mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
            resultPtr := add(resultPtr, 1)
            mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
            resultPtr := add(resultPtr, 1)
            mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F)))))
            resultPtr := add(resultPtr, 1)
            mstore(resultPtr, shl(248, mload(add(tablePtr, and(input, 0x3F)))))
            resultPtr := add(resultPtr, 1)
         }

         // padding with '='
         switch mod(mload(data), 3)
         case 1 {
            mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
         }
         case 2 {
            mstore(sub(resultPtr, 1), shl(248, 0x3d))
         }
      }

      return result;
   }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./utils/Bytecode.sol";

/**
  @title A key-value storage with auto-generated keys for storing chunks of data with a lower write & read cost.
  @author Agustin Aguilar <[email protected]>

  Readme: https://github.com/0xsequence/sstore2#readme
*/
library SSTORE2 {
  error WriteError();

  /**
    @notice Stores `_data` and returns `pointer` as key for later retrieval
    @dev The pointer is a contract address with `_data` as code
    @param _data to be written
    @return pointer Pointer to the written `_data`
  */
  function write(bytes memory _data) internal returns (address pointer) {
    // Append 00 to _data so contract can't be called
    // Build init code
    bytes memory code = Bytecode.creationCodeFor(
      abi.encodePacked(
        hex'00',
        _data
      )
    );

    // Deploy contract using create
    assembly { pointer := create(0, add(code, 32), mload(code)) }

    // Address MUST be non-zero
    if (pointer == address(0)) revert WriteError();
  }

  /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @return data read from `_pointer` contract
  */
  function read(address _pointer) internal view returns (bytes memory) {
    return Bytecode.codeAt(_pointer, 1, type(uint256).max);
  }

  /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @param _start number of bytes to skip
    @return data read from `_pointer` contract
  */
  function read(address _pointer, uint256 _start) internal view returns (bytes memory) {
    return Bytecode.codeAt(_pointer, _start + 1, type(uint256).max);
  }

  /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @param _start number of bytes to skip
    @param _end index before which to end extraction
    @return data read from `_pointer` contract
  */
  function read(address _pointer, uint256 _start, uint256 _end) internal view returns (bytes memory) {
    return Bytecode.codeAt(_pointer, _start + 1, _end + 1);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


library Bytecode {
  error InvalidCodeAtRange(uint256 _size, uint256 _start, uint256 _end);

  /**
    @notice Generate a creation code that results on a contract with `_code` as bytecode
    @param _code The returning value of the resulting `creationCode`
    @return creationCode (constructor) for new contract
  */
  function creationCodeFor(bytes memory _code) internal pure returns (bytes memory) {
    /*
      0x00    0x63         0x63XXXXXX  PUSH4 _code.length  size
      0x01    0x80         0x80        DUP1                size size
      0x02    0x60         0x600e      PUSH1 14            14 size size
      0x03    0x60         0x6000      PUSH1 00            0 14 size size
      0x04    0x39         0x39        CODECOPY            size
      0x05    0x60         0x6000      PUSH1 00            0 size
      0x06    0xf3         0xf3        RETURN
      <CODE>
    */

    return abi.encodePacked(
      hex"63",
      uint32(_code.length),
      hex"80_60_0E_60_00_39_60_00_F3",
      _code
    );
  }

  /**
    @notice Returns the size of the code on a given address
    @param _addr Address that may or may not contain code
    @return size of the code on the given `_addr`
  */
  function codeSize(address _addr) internal view returns (uint256 size) {
    assembly { size := extcodesize(_addr) }
  }

  /**
    @notice Returns the code of a given address
    @dev It will fail if `_end < _start`
    @param _addr Address that may or may not contain code
    @param _start number of bytes of code to skip on read
    @param _end index before which to end extraction
    @return oCode read from `_addr` deployed bytecode

    Forked from: https://gist.github.com/KardanovIR/fe98661df9338c842b4a30306d507fbd
  */
  function codeAt(address _addr, uint256 _start, uint256 _end) internal view returns (bytes memory oCode) {
    uint256 csize = codeSize(_addr);
    if (csize == 0) return bytes("");

    if (_start > csize) return bytes("");
    if (_end < _start) revert InvalidCodeAtRange(csize, _start, _end); 

    unchecked {
      uint256 reqSize = _end - _start;
      uint256 maxSize = csize - _start;

      uint256 size = maxSize < reqSize ? maxSize : reqSize;

      assembly {
        // allocate output byte array - this could also be done without assembly
        // by using o_code = new bytes(size)
        oCode := mload(0x40)
        // new "memory end" including padding
        mstore(0x40, add(oCode, and(add(add(size, 0x20), 0x1f), not(0x1f))))
        // store length in memory
        mstore(oCode, size)
        // actually retrieve the code, this needs assembly
        extcodecopy(_addr, add(oCode, 0x20), _start, size)
      }
    }
  }
}