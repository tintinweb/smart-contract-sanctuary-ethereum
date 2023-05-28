// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./GIF89a.sol";
import "./API.sol";
import "./iGUA.sol";

import "@openzeppelin/contracts/utils/Strings.sol";

interface iGUAMetadata {
  function getMetadata(uint256 _tokenId, bytes32 _seed, bytes32 _queryhash, uint256 _timestamp, uint256 _rand, string memory _query, uint8 _colorIndex, bytes2 _bitstream) external pure returns (string memory);
  function fetusMovementGif() external view returns (bytes memory);
  function render(bytes memory _gif, string memory _metadata) external pure returns (string memory);
}

interface iBaGua {
  function cast(bytes32 _input, uint8 _totalColors) external pure returns(uint8[][] memory seed, uint8 colorIndex, bytes2 bitstream);
}

/** @title GUA Contract
  * @author @0xAnimist
  * @notice A collaboration between Cai Guo-Qiang and Kanon
  */
contract GUA is ERC721Enumerable, iGUA {
  address public _artist;
  address public _manager;
  bytes3[] public _colors;
  uint256 private _ww = 3;
  uint256 private _hh = 3;
  address public _GUAMetadataAddress;
  address public _BaGuaAddress;
  bool public _depsFrozen = false;
  bool public _colorsFrozen = false;

  struct Gua {
    bytes32 seed;//hash of query, randomness, & context
    bytes32 queryhash;//hash of query alone
    uint256 timestamp;
    uint256 rand;
    bytes gif;
    string encrypted;
    string query;//blank unless published
    bool queried;//false if gifted
    uint8 colorIndex;
    bytes2 bitstream;
  }

  mapping(uint256 => Gua) public _guas;
  mapping(address => bool) public _readers;//whitelist of contracts that can mint a seed


  modifier onlyAuth(){
    require(msg.sender == _manager || msg.sender == _artist, "a");
    _;
  }

  modifier tokenExists(uint256 _tokenId) {
    require(_exists(_tokenId), "e");
    _;
  }

  /**
    * @dev Constructor, sets caller as _artist and mints token 0 to the caller
    * @param manager_ Address Address of manager
    */
  constructor(address manager_, bytes3[] memory colors_) ERC721("GUA", "GUA"){
    _artist = msg.sender;
    _manager = manager_;
    _colors = colors_;
  }

  function mintFetusMovement() external {
    require(!_exists(0), "f");
    _safeMint(_artist, 0);//mint token #0 to artist
  }

  /**
    * @dev Sets contract manager
    * @param manager_ Address Address of manager
    */
  function setManager(address manager_) external {
    require(msg.sender == _manager, "a");
    _manager = manager_;
  }

  /**
    * @dev Sets address of contract that provides metadata
    * @param GUAMetadataAddress_ Address
    * @param _freeze Blocks any future changes if true
    */
  function setDependencies(address GUAMetadataAddress_, address BaGuaAddress_, bool _freeze) external onlyAuth {
    require(!_depsFrozen, "f");
    _GUAMetadataAddress = GUAMetadataAddress_;
    _BaGuaAddress = BaGuaAddress_;
    _depsFrozen = _freeze;
  }

/*
  function updateColors(bytes3[] memory colors_, bool _freeze) external onlyAuth {
    require(!_colorsFrozen, "f");
    _colors = colors_;
    _colorsFrozen = _freeze;
  }*/
/*
  function getGifs() external view returns(bytes[] memory){
    bytes[] memory gifs = new bytes[](totalSupply()-1);
    for(uint256 i = 1; i < totalSupply(); i++){
      gifs[i-1] = _guas[i].gif;
    }
    return gifs;
  }
*/
  /**
    * @dev Authorizes _reader to mint GUA NFTs
    * @param _reader Address of reader authorized to mint
    */
  function addReader(address _reader) external onlyAuth {
    _readers[_reader] = true;
  }

  /**
    * @dev Mints one GUA NFT
    * @param _owner address to assign ownership of the minted NFT
    * @param _queryhash keccak256 hash of the query
    * @param _rand Random number representing context/intent
    */
  function mint(address _owner, bytes32 _queryhash, uint256 _rand, string memory _encrypted) public returns(uint256 tokenId, bytes32 seed){
    require(_readers[msg.sender], "r");
    tokenId = totalSupply();//start at token #1 bc initialize mints token #0
    _safeMint(_owner, tokenId);

    if(_rand == 0){//not queried
      bytes memory blank;
      _guas[tokenId] = (Gua(seed, _queryhash, block.timestamp, _rand, blank, _encrypted, "", false, 0, 0));
    }else{//queried
      seed = keccak256(abi.encodePacked(_queryhash, block.difficulty));
      seed = keccak256(abi.encodePacked(seed, _rand));

      (bytes memory gif, uint8 colorIndex, bytes2 bitstream) = _response(seed);

      _guas[tokenId] = (Gua(seed, _queryhash, block.timestamp, _rand, gif, _encrypted, "", true, colorIndex, bitstream));
    }
  }

  function redeemFortune(uint256 _tokenId, bytes32 _queryhash, uint256 _rand, string memory _encrypted) external returns(bool success) {
    require(_readers[msg.sender], "r");
    require(ownerOf(_tokenId) == msg.sender, "o");

    bytes32 seed = keccak256(abi.encodePacked(_queryhash, block.difficulty));
    seed = keccak256(abi.encodePacked(seed, _rand));

    (bytes memory gif, uint8 colorIndex, bytes2 bitstream) = _response(seed);

    _guas[_tokenId].seed = seed;
    _guas[_tokenId].queryhash = _queryhash;
    _guas[_tokenId].timestamp = block.timestamp;
    _guas[_tokenId].rand = _rand;
    _guas[_tokenId].gif = gif;
    _guas[_tokenId].queried = true;
    _guas[_tokenId].encrypted = _encrypted;
    _guas[_tokenId].colorIndex = colorIndex;
    _guas[_tokenId].bitstream = bitstream;

    success = true;
  }

  /**
    * @dev Gets GIF and seed raw bytes
    * @param _tokenId the token
    */
  function getData(uint256 _tokenId) external view override tokenExists(_tokenId) returns(bytes memory gif, bytes32 seed, bool queried, string memory encrypted){
    return (_guas[_tokenId].gif, _guas[_tokenId].seed, _guas[_tokenId].queried, _guas[_tokenId].encrypted);
  }

  /**
    * @dev Returns the URI of the token
    * @param _tokenId the token
    */
  function tokenURI(uint256 _tokenId) public view override tokenExists(_tokenId) returns(string memory) {
    bytes memory gif;

    if(_tokenId != 0){
      (gif,,) = _response(_guas[_tokenId].seed);
    }else{
      gif = iGUAMetadata(_GUAMetadataAddress).fetusMovementGif();
    }

    string memory slug = iGUAMetadata(_GUAMetadataAddress).getMetadata(_tokenId, _guas[_tokenId].seed, _guas[_tokenId].queryhash, _guas[_tokenId].timestamp, _guas[_tokenId].rand, _guas[_tokenId].query, _guas[_tokenId].colorIndex, _guas[_tokenId].bitstream);

    return iGUAMetadata(_GUAMetadataAddress).render(gif, slug);
  }

  /**
    * @dev Returns all relevant data for the token in JSON format
    * @param _tokenId the token
    */
  function tokenAPI(uint256 _tokenId) public view returns(string memory api) {
    (bytes memory gif,,) = _response(_guas[_tokenId].seed);

    if(_tokenId != 0){
      return API.guaAPI(
        _tokenId,
        _guas[_tokenId].timestamp,
        _guas[_tokenId].rand,
        _guas[_tokenId].query,
        _guas[_tokenId].queried,
        gif,
        _guas[_tokenId].seed,
        _guas[_tokenId].queryhash
      );
    }
  }

  /**
    * @dev Burns GUA NFT
    * @param tokenId Token to burn
    */
  function burn(uint256 tokenId) public virtual {
      //solhint-disable-next-line max-line-length
      require(_isApprovedOrOwner(_msgSender(), tokenId), "a");
      _burn(tokenId);
  }

  /**
    * @dev Publishes the otherwise private query
    * @param _tokenId the token
    * @param _query the original query, proving knowledge of it
    */
  function publishQuery(uint256 _tokenId, string memory _query) external returns (bool published) {
    require(msg.sender == ownerOf(_tokenId), "o");
    if(keccak256(abi.encodePacked(_query)) == _guas[_tokenId].queryhash){
      _guas[_tokenId].query = _query;
      published = true;
    }
  }

  /**
    * @dev Oracle that provides a GIF in response to a query
    * @param _input the keccak256-encoded contextualized query
    */
  function _response(bytes32 _input) internal view returns(bytes memory gif, uint8 colorIndex, bytes2 bitstream) {
    uint8[][] memory frame;
    (frame, colorIndex, bitstream) = iBaGua(_BaGuaAddress).cast(_input, uint8(_colors.length));

    bytes memory header = hex'47494638396103000300800000ffffff';
    header = abi.encodePacked(header, _colors[colorIndex], hex'21FE154361692047756F2D5169616E672078204B616E6F6E0021f90401000000002c000000000300030000');

    gif = bytes.concat(
      header,
      GIF89a.formatImageLZW(
        frame,
        uint16(2)//only two colors but 2 is the minimum minimum code size for LZW compression
      )
    );

    gif = bytes.concat(gif, hex'3b');
/*
    bytes3[] memory colors = new bytes3[](2);
    colors[0] = 0xFFFFFF;
    colors[1] = 0xF53077;
    //note" hardcoded the header so as to reduce mint gas price, more generic version below
    bytes1 packedLSD = GIF89a.formatLSDPackedField(colors);

    uint16 minCodeSize = uint16(GIF89a.root2(GIF89a.fullColorTableSize(2)));

    return (GIF89a.buildStaticGIF(colors, _ww, _hh, true, 0x00, frame, packedLSD, minCodeSize), colorIndex, bitstream);
*/
  }

}//end

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/** @title GUA Interface
  * @author @0xAnimist
  * @notice A collaboration between Cai Guo-Qiang and Kanon
  */
interface iGUA {
  function getData(uint256 _tokenId) external view returns(bytes memory, bytes32 seed, bool queried, string memory encrypted);

  //function getGifs() external view returns(bytes[] memory);

  function tokenAPI(uint256 _tokenId) external view returns(string memory);

  function mint(address _owner, bytes32 _queryhash, uint256 _rand, string memory _encrypted) external returns(uint256 tokenId, bytes32 seed);

  function publishQuery(uint256 _tokenId, string memory _query) external returns (bool published);

  function redeemFortune(uint256 _tokenId, bytes32 _queryhash, uint256 _rand, string memory _encrypted) external returns(bool success);
}//end

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./BytesLib.sol";

/** @title GIF89a Contract
  * @author @0xAnimist
  * @notice First Onchain GIF, collaboration between Cai Guo-Qiang and Kanon
  */
library GIF89a {

  bytes1 public constant IMAGE_SEPARATOR = 0x2c;


  function buildStaticGIF(bytes3[] memory _colors, uint256 _ww, uint256 _hh, bool _trans, bytes1 _transIndex, uint8[][] memory _frame, bytes1 _packedLSD, uint16 _minCodeSize) public pure returns (bytes memory gif) {
    gif = formatHeader();
    gif = bytes.concat(gif, formatLSD(_ww, _hh, _packedLSD));
    gif = bytes.concat(gif, formatGCT(_colors));
    gif = bytes.concat(gif, formatGCE(false, 0x00, 0x0000, _trans, _transIndex));

    bytes1 packedImgDesc = 0x00;//no local color tables used
    gif = bytes.concat(gif, formatImageDescriptor(0, 0, _ww, _hh, packedImgDesc));

    gif = bytes.concat(
      gif,
      formatImageLZW(
        _frame,
        _minCodeSize
      )
    );

    gif = bytes.concat(gif, formatTrailer());
  }


  function buildAnimatedGifByPixel(bytes memory _buffer, uint8 _i, uint8 _y, bytes memory _packedHeader, bytes memory _gce, bytes memory _pixel) public pure returns (bytes memory buffer){
    //image descriptor
    bytes memory imgDesc = formatImageDescriptor(_i, _y, 3, 3, 0x0000);

    //pixel-specific metadata
    if(_i == 0){//if first iteration
      buffer = BytesLib.concat(_packedHeader, imgDesc);
    }else{
      buffer = BytesLib.concat(_buffer, BytesLib.concat(_gce, imgDesc));
    }

    //lzw image data
    buffer = BytesLib.concat(buffer, _pixel);
  }



  function assembleGIFStack(bytes[] memory _parts) public pure returns (bytes memory gif) {

    for(uint256 i = 0; i < _parts.length; i++){
      gif = BytesLib.concat(gif, _parts[i]);
    }
  }

  function assembleHeader(bytes3[] memory _colors, uint256 _ww, uint256 _hh) public pure returns (bytes[] memory header) {
    header = new bytes[](3);

    //format Header
    header[0] = formatHeader();

    //format LSD
    bytes1 packedLSD = formatLSDPackedField(_colors);
    header[1] = formatLSD(_ww, _hh, packedLSD);

    //format GCT
    header[2] = formatGCT(_colors);
  }


  function assembleGIF(bytes memory _header, bytes memory _lsd, bytes memory _gct, bytes memory _gce, bytes memory _imgDesc, bytes memory _img, bytes memory _trailer) public pure returns (bytes memory) {
    bytes memory buffer;
    assembly {
      buffer := mload(0x40)//buffer == 0x80

      //total length
      let len := add(mload(_gce),add(mload(_trailer),add(mload(_img),add(mload(_imgDesc),add(mload(_gct),add(mload(_lsd),mload(_header)))))))
      mstore(buffer, len)

      //header
      let pointer := add(buffer,0x20)//store the data after the length word
      let headerData := mload(add(_header,0x20))
      mstore(pointer, headerData)

      //lsd
      pointer := add(pointer,mload(_header))//offset by header length
      let lsdData := mload(add(_lsd,0x20))
      mstore(pointer, lsdData)

      pointer := add(pointer,mload(_lsd))
      let gctData := mload(add(_gct,0x20))
      mstore(pointer, gctData)

      pointer := add(pointer,mload(_gct))
      let gceData := mload(add(_gce,0x20))
      mstore(pointer, gceData)

      pointer := add(pointer,mload(_gce))
      let imgDescData := mload(add(_imgDesc,0x20))
      mstore(pointer, imgDescData)

      pointer := add(pointer,mload(_imgDesc))


      let datawords := div(mload(_img),0x20)//number of 32-byte words of img data

      for { let i := 1 } lt(i, add(datawords,1)) { i := add(i, 1) } {
        mstore(pointer,mload(add(_img,mul(i,0x20))))
        pointer := add(pointer,0x20)
      }

      //store remainder of _img
      let rem := mod(mload(_img),32)//3

      for { let i := 0 } lt(i, rem) { i := add(i, 1) } {
        mstore8(pointer, byte(i,mload(add(_img,mul(add(datawords,1),0x20)))))
        pointer := add(pointer,1)
      }

      let trailerData := mload(add(_trailer,0x20))
      mstore(pointer, trailerData)

      //determine how many 32-byte words are used in total
      let words := div(len,0x20)//total 32-byte words
      if gt(mod(len,32), 0) { words := add(words,1) }

      //update free memory pointer
      let nextmem := add(add(buffer,0x20),mul(words,0x20))
      mstore(0x40, nextmem)
    }
    return buffer;
  }

  //Global Color Table
  function formatGCT(bytes3[] memory _colors) public pure returns (bytes memory) {
    require(_colors.length <= 256, "GIF89a: exceeds max colors");

    uint256 len = fullColorTableSize(_colors.length);
    bytes memory buffer;
    bytes3 empty = 0x000000;

    //fill gct with all colors
    for(uint256 i = 0; i < _colors.length; i++){
      buffer = bytes.concat(buffer, _colors[i]);
    }//end for i

    //pad gct so size is 2^n
    for(uint256 i = _colors.length; i < len; i++){
      buffer = bytes.concat(buffer, empty);
    }

    return buffer;
  }

  //GIF89a
  function formatHeader() public pure returns (bytes memory) {
    bytes memory buffer = new bytes(6);

    buffer[0] = 0x47;//G
    buffer[1] = 0x49;//I
    buffer[2] = 0x46;//F
    buffer[3] = 0x38;//8
    buffer[4] = 0x39;//9
    buffer[5] = 0x61;//a

    return buffer;
  }

  //Logical Screen Display Packed Field
  function formatLSDPackedField(bytes3[] memory _colors) public pure returns(bytes1) {
    bytes memory packedField;

    uint256 gctSize = fullColorTableSize(_colors.length);
    uint8 colorResolution = uint8(root2(gctSize) - 1);

    require(colorResolution >= 0 && colorResolution < 8, "GIF89a: color resolution out of bounds");

    assembly {
      packedField := mload(0x40)
      mstore(packedField, 1)
      let pointer := add(packedField, 0x20)
      mstore8(pointer, or(or(0x80, colorResolution), shl(4,colorResolution)))//0x80 for global color table flag
      mstore(0x40, 0x21)//TODO: should be add(packedField, 0x21) i think!?
    }

    return bytes1(packedField);
  }

  //Logical Screen Display
  function formatLSD(uint256 _ww, uint256 _hh, bytes1 _packedField) public pure returns (bytes memory) {
    bytes memory buffer;// = new bytes(6);

    assembly {
      buffer := mload(0x40)//buffer == 0x80

      mstore(buffer, 0x07)//length == 0x06 == 6

      let dataPointer := add(buffer, 0x20)//store the data after the length word

      //full image width
      mstore8(dataPointer, byte(31,_ww))
      mstore8(add(dataPointer,1), byte(30,_ww))

      //full image height
      mstore8(add(dataPointer,2), byte(31,_hh))
      mstore8(add(dataPointer,3), byte(30,_hh))

      //packed field
      mstore8(add(dataPointer,4), byte(0,_packedField))

      //background color index
      mstore8(add(dataPointer,5), 0x00)

      //pixel aspect ratio (likely not implemented)
      mstore8(add(dataPointer,6), 0x00)

      mstore(0x40, add(buffer, 0x40))//0xc0
    }

    return buffer;
  }

  //Application Extension Block (for infinite loop animation)
  function formatAEB(uint16 _loops) public pure returns (bytes memory) {
    bytes memory buffer = new bytes(19);

    bytes memory loops = abi.encodePacked(_loops);

    buffer[0] = 0x21;//GIF extension code
    buffer[1] = 0xFF;//Application extension label
    buffer[2] = 0x0B;//Length of Application Block
    buffer[3] = 0x4E;//"N"
    buffer[4] = 0x45;//"E"
    buffer[5] = 0x54;//"T"
    buffer[6] = 0x53;//"S"
    buffer[7] = 0x43;//"C"
    buffer[8] = 0x41;//"A"
    buffer[9] = 0x50;//"P"
    buffer[10] = 0x45;//"E"
    buffer[11] = 0x32;//"2"
    buffer[12] = 0x2E;//"."
    buffer[13] = 0x30;//"0"
    buffer[14] = 0x03;//Length of data sub-blocks
    buffer[15] = 0x01;//convention 0x01
    buffer[16] = loops[0];//0x01;//Little endian # of loops: loop only 1x
    buffer[17] = loops[1];//0x00;//^^
    buffer[18] = 0x00;//Data sub-block terminator

    return buffer;
  }


  /**
    * @dev Graphics Control Extension
    * @param _disposal 0x04 if you want to leave the last frame in place after the animation has finished; 0x08 if you want the last frame to be just the background color
    * @param _transIndex numerical gct index of the transparent color in bytes1 format
   */
  function formatGCE(bool _animated, bytes1 _disposal, bytes2 _delay, bool _transparent, bytes1 _transIndex) public pure returns (bytes memory) {
    bytes memory buffer = new bytes(8);

    buffer[0] = 0x21;
    buffer[1] = 0xf9;
    buffer[2] = 0x04;
    buffer[3] = _animated ? _disposal : bytes1(0x00);
    if(_transparent){
      buffer[3] = buffer[3] | bytes1(0x01);
    }
    buffer[4] = _animated ? _delay[0] : bytes1(0x00);
    buffer[5] = _animated ? _delay[1] : bytes1(0x00);
    buffer[6] = _transparent ? _transIndex : bytes1(0x00);
    buffer[7] = 0x00;

    return buffer;
  }

  /**
    * @dev Image Descriptor
    * @param _ll image left
    * [email protected] _tt image top
    */
  function formatImageDescriptor(uint256 _ll, uint256 _tt, uint256 _ww, uint256 _hh, bytes1 _packedField) public pure returns (bytes memory) {
    bytes memory buffer;

    assembly {
      buffer := mload(0x40)//buffer == 0x80

      mstore(buffer, 0x0a)//length == 0xa0 == 10

      let dataPointer := add(buffer, 0x20)//store the data after the length word

      mstore8(dataPointer, 0x2c)//byte(0,IMAGE_SEPARATOR))

      //image left
      mstore8(add(dataPointer,1), byte(31,_ll))
      mstore8(add(dataPointer,2), byte(30,_ll))

      //image top
      mstore8(add(dataPointer,3), byte(31,_tt))
      mstore8(add(dataPointer,4), byte(30,_tt))

      //full image width
      mstore8(add(dataPointer,5), byte(31,_ww))
      mstore8(add(dataPointer,6), byte(30,_ww))

      //full image height
      mstore8(add(dataPointer,7), byte(31,_hh))
      mstore8(add(dataPointer,8), byte(30,_hh))

      //packed field
      mstore8(add(dataPointer,9), byte(0,_packedField))

      mstore(0x40, add(buffer, 0x40))//0xc0
    }

    return buffer;
  }

  //Trailer
  function formatTrailer() public pure returns(bytes memory) {
    bytes memory trailer = new bytes(1);
    trailer[0] = 0x3b;
    return trailer;
  }

  ////////////////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////////////
  /////////////////////////////////// IMAGE //////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Format Image in LZW Compression
   * @param _minimumCodeSize bits/pixel required (thus, size of gct == 2**_minimumCodeSize)
   */
  function formatImageLZW(uint8[][] memory _indexMatrix, uint16 _minimumCodeSize) public pure returns (bytes memory) {
    //convert index matrix (im) to index stream (is)
    uint256 width = _indexMatrix[0].length;
    uint256 totalIndices = _indexMatrix.length * width;// assumes a rectangular index matrix
    bytes memory indexStream = new bytes(totalIndices);//each value is [0,0xff] == [0,255] because |gct| >= 256
    for(uint256 i = 0; i <  _indexMatrix.length; i++){
      for(uint256 j = 0; j < width; j++){
        indexStream[(i*width)+j] =  bytes1(_indexMatrix[i][j]);
      }
    }

    //generate code stream (cs)
    bytes memory cs = encodeImage(indexStream, _minimumCodeSize);

    //break code stream down into chunks <= 0xff in length
    cs = chunkCodeStream(cs);

    //prepend minimum code size
    cs = bytes.concat(bytes1(uint8(_minimumCodeSize)), cs);

    return cs;
  }

  //this function chunks the code stream out into N 0xff-long blocks
  function chunkCodeStream(bytes memory _cs) public pure returns(bytes memory cs) {
    uint256 fullChunks = (_cs.length / 0xff);
    uint8 remainder = uint8(_cs.length % 0xff);
    uint256 chunks = (remainder > 0) ? fullChunks + 1 : fullChunks;

    cs = new bytes(_cs.length + 2*chunks);

    uint256 i = 0;
    uint256 j = 0;
    while(remainder > 0){
      if(fullChunks > 0){
        cs[i++] = 0xff;
        for(uint256 k = j; k < (j+256); k++){
          cs[i++] = _cs[k];
        }
        cs[i++] = 0x00;
        j += 256;
        fullChunks--;
      }else{
        cs[i++] = bytes1(remainder);
        for(uint256 k = j; k < (j + uint256(remainder)); k++){
          cs[i++] = _cs[k];
        }
        cs[i] = 0x00;
        remainder = 0;
      }
    }//end while
  }


  function encodeImage(bytes memory _is, uint16 _minimumCodeSize) public pure returns(bytes memory) {
    uint16 codeSizeInBits = _minimumCodeSize + 1;
    (bytes memory cs, int256 isIndex) = packImage(_is, codeSizeInBits);
    while(isIndex < 0){
      _is = removeFirstNBytes(_is, uint256(isIndex*(-1)));
      (cs, isIndex) = packImage(_is, codeSizeInBits);
    }
    return cs;
  }

  function removeFirstNBytes(bytes memory _is, uint256 _n) public pure returns(bytes memory is_) {
    is_ = new bytes(_is.length - _n);
    for(uint256 j = _n; j < is_.length; j++){
      is_[j-_n] = _is[j];
    }
  }

  /**
   * @param _codeSizeInBits initial code size, one greater than the minimum code size (ie. one bit greater than the amount needed to represent all the indices in the gct)
   */
  function packImage(bytes memory _is, uint16 _codeSizeInBits) public pure returns(bytes memory cs, int isIndex) {
    uint256 csBitLen = 0;
    uint16 cc = uint16(2**(_codeSizeInBits-1));

    bytes[] memory ct;//code table
    (cs, csBitLen) = addToCS(cs, csBitLen, cc, _codeSizeInBits);//send clear code (== total colors == 2**_minimumCodeSize == 2**(_codeSizeInBits-1))

    bytes memory ib = new bytes(1);//index buffer
    ib[0] = _is[uint256(isIndex++)];

    uint256 index;
    uint256 code;
    for(uint256 i = uint256(isIndex); i < _is.length; i++){
      ib = pushToBytes(ib, _is[i]);

      //emit IB(i, ib);
      bool alreadyInCT;
      (alreadyInCT, index) = isInCodeTable(ct, ib, cc+1);

      if(!alreadyInCT){
        if(ib.length == 2){
          (cs, csBitLen) = addToCS(cs, csBitLen, uint256(uint8(ib[0])), _codeSizeInBits);
        }else{
          (cs, csBitLen) = addToCS(cs, csBitLen, code, _codeSizeInBits);
        }

        //add ib to code table, increment codeSizeInBits if appropriate
        (ct, _codeSizeInBits) = addToCT(ct, ib, _codeSizeInBits, (cc+1));

        ib = clearToLen1(ib);
        ib[0] = _is[i];

        //push ib[0] to the code stream if this is the last index
        if(i == (_is.length-1)){
          (cs, csBitLen) = addToCS(cs, csBitLen, uint256(uint8(ib[0])), _codeSizeInBits);
        }

        //must reset color table (ct) if
        if(ct.length == (4095 - cc - 1)){
          isIndex = int(i+1)*(-1);//i has been added to the cs, so start again at i+1
          break;
        }

      }else{
        code = index;
        //push code to the code stream if this is the last index
        if(i == (_is.length-1)){
          (cs, csBitLen) = addToCS(cs, csBitLen, code, _codeSizeInBits);
        }
      }
    }//end for

    //(cs, csBitLen) = addToCS(cs, csBitLen, index, _codeSizeInBits);
    (cs,) = addToCS(cs, csBitLen, cc+1, _codeSizeInBits);//_totalColors + 1 == end of information code
  }


  function invertByteOrder(bytes memory _cs) public pure returns(bytes memory cs) {
    cs = new bytes(_cs.length);
    for(uint256 i = 0; i < _cs.length; i++){
      cs[i] = _cs[_cs.length - 1];
    }
  }

  function addToCS(bytes memory _cs, uint256 _csBitLen, uint256 _code, uint256 _codeSizeInBits) public pure returns(bytes memory cs, uint256 csBitLen) {
    uint256 bitsUsedInLastByte = _csBitLen % 8;//how many used bits in the last byte
    uint256 bitsLeftInLastByte = 8 - bitsUsedInLastByte;
    uint256 bytesToChange = 0;
    uint256 bytesToAdd = 0;

    if(bitsUsedInLastByte == 0){
      bytesToAdd = (_codeSizeInBits > 8) ? 2 : 1;
    }else{
      bytesToChange = 1;
      if(_codeSizeInBits > bitsLeftInLastByte){
        bytesToAdd++;
        if(_codeSizeInBits > (8 + bitsLeftInLastByte)){
          bytesToAdd++;
        }//end if
      }//end if
    }//end ifelse

    if(bytesToChange == 1){
      assembly {
        let lastByteOfCSPointer := add(_cs,add(0x20,sub(mload(_cs),1)))
        let lastByteOfCS := byte(0, mload(lastByteOfCSPointer))
        let oredLastByte := or(lastByteOfCS, byte(31,shl(bitsUsedInLastByte, _code)))//0x0c
        mstore8(lastByteOfCSPointer, oredLastByte)
      }//end assembly
    }//end if

    cs = new bytes(_cs.length + bytesToAdd);
    for(uint256 i = 0; i < _cs.length; i++){
      cs[i] = _cs[i];
    }//end for

    if(bytesToAdd > 0){
      assembly {
        let firstNewByteOfCSPointer := add(cs,add(0x20, mload(_cs)))
        mstore8(firstNewByteOfCSPointer, byte(sub(31,bytesToChange),shl(bitsUsedInLastByte, _code)))

        if eq(bytesToAdd, 2) {
          mstore8(add(firstNewByteOfCSPointer, 1), byte(sub(30,bytesToChange),shl(bitsUsedInLastByte, _code)))
        }//end if
      }//end assembly
    }//end if

    csBitLen = _csBitLen + _codeSizeInBits;
  }

  function clearToLen1(bytes memory _arr) public pure returns(bytes memory) {
    bytes memory arr = new bytes(1);
    for(uint256 i = 0; i < _arr.length-1; i++){
      delete _arr[i];
    }
    _arr = arr;
    return arr;
  }

  function push1DTo(uint256[] memory _pre, uint256[] memory _post) public pure returns(uint256[] memory arr) {
    uint256 len = _pre.length + _post.length;
    arr = new uint256[](len);
    for(uint256 i = 0; i < _pre.length; i++){
      arr[i] = _pre[i];
    }
    for(uint256 j = _pre.length; j < len; j++){
      arr[j] = _post[j-_pre.length];
    }
  }

  function pushTo(uint256[] memory _arr, uint256 _value) public pure returns(uint256[] memory arr) {
    arr = new uint256[](_arr.length+1);
    for(uint256 i = 0; i < _arr.length; i++){
      arr[i] = _arr[i];
    }
    arr[_arr.length] = _value;
  }

  function pushToBytes(bytes memory _arr, bytes1 _value) public pure returns(bytes memory arr) {
    arr = new bytes(_arr.length+1);
    arr = bytes.concat(_arr,_value);
  }

  function popFrom(uint256[] memory _arr) public pure returns(uint256[] memory arr) {
    arr = new uint256[](_arr.length-1);
    for(uint256 i = 0; i < _arr.length-1; i++){
      arr[i] = _arr[i];
    }
  }

  function addToCT(bytes[] memory _ct, bytes memory _arr, uint16 _codeSizeInBits, uint256 _eoi) public pure returns(bytes[] memory ct, uint16 codeSizeInBits) {
    uint256 len = _ct.length+1;
    //increment code size if latest code is == 2**codeSizeInBits - 1
    if((_ct.length + _eoi) >= ((2**_codeSizeInBits) - 1)){
      codeSizeInBits = _codeSizeInBits + 1;
    }else{
      codeSizeInBits = _codeSizeInBits;
    }

    ct = new bytes[](len);
    for(uint256 i = 0; i < len-1; i++){
      ct[i] = _ct[i];
    }

    ct[len-1] = new bytes(_arr.length);
    for(uint256 j = 0; j < _arr.length; j++){
      ct[len-1][j] = _arr[j];
    }
  }

  function isInCodeTable(bytes[] memory _ct, bytes memory _ib, uint256 _eoi) public pure returns(bool contained, uint256 index) {
    //compare ib against every element of _ct
    for(uint256 i = 0; i < _ct.length; i++){
      if(_ct[i].length == _ib.length){
        bool matches = true;
        for(uint256 j = 0; j < _ct[i].length; j++){
          if(_ct[i][j] != _ib[j]){
            matches = false;
            break;
          }
        }

        if(matches){
          return (true, i+_eoi+1);
        }
      }//end if
    }//end for

    return (false,0);
  }

  function root2(uint256 _val) public pure returns(uint256 n) {
    //require(_val%2 == 0, "GIF89a: root2");

    while(_val > 1){
      require(_val%2 == 0, "GIF89a: root2");
      _val = _val/2;
      n++;
    }
  }


  function fullColorTableSize(uint256 _value) public pure returns(uint256 len) {
    len = 1;
    uint256 temp = _value - 1;

    while(temp > 1){
      temp = temp/2;
      len++;
    }

    len = 2**len;
  }

  function getMinimumCodeSize(uint256 _totalColors) public pure returns(uint256 minCodeSize) {
    minCodeSize = root2(fullColorTableSize(_totalColors));
    if(minCodeSize < 2){
      return 2;
    }
  }

}//end GIF89a

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.0 <0.9.0;


library BytesLib {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                // the next line is the loop condition:
                // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    )
        internal
        view
        returns (bool)
    {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }


    function toHex(bytes memory buffer) public pure returns (string memory) {

        // Fixed buffer size for hexadecimal convertion
        bytes memory converted = new bytes(buffer.length * 2);

        bytes memory _base = "0123456789abcdef";

        for (uint256 i = 0; i < buffer.length; i++) {
            converted[i * 2] = _base[uint8(buffer[i]) / _base.length];
            converted[i * 2 + 1] = _base[uint8(buffer[i]) % _base.length];
        }

        return string(abi.encodePacked("0x", converted));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./iGUA.sol";


/** @title API Contract
  * @author @0xAnimist
  * @notice A collaboration between Cai Guo-Qiang and Kanon
  */
library API {

  function guaAPI(
    uint256 _tokenId,
    uint256 _timestamp,
    uint256 _rand,
    string memory _query,
    bool _queried,
    bytes memory _guaGif,
    bytes32 _seed,
    bytes32 _queryhash
  ) public pure returns(string memory api){
    uint256 queried;
    if(_queried){
      queried = 1;
    }

    api = string(abi.encodePacked(
      '{"tokenId": ',
      Strings.toString(_tokenId),
      ', "timestamp": ',
      Strings.toString(_timestamp),
      ', "rand": ',
      Strings.toString(_rand),
      ', "query": "',
      _query,
      '"'
    ));

    api = string(abi.encodePacked(
      api,
      ', "queried": ',
      Strings.toString(queried),
      ', "guaGif": "',
      bytesToHex(_guaGif),
      '", "seed": "',
      bytesToHex(abi.encodePacked(_seed))
    ));

    api = string(abi.encodePacked(
      api,
      '", "queryhash": "',
      bytesToHex(abi.encodePacked(_queryhash)),
      '"}'
    ));

  }


  //Adapted from BytesLib
  function bytesToHex(bytes memory buffer) public pure returns (string memory) {

      // Fixed buffer size for hexadecimal convertion
      bytes memory converted = new bytes(buffer.length * 2);

      bytes memory _base = "0123456789abcdef";

      for (uint256 i = 0; i < buffer.length; i++) {
          converted[i * 2] = _base[uint8(buffer[i]) / _base.length];
          converted[i * 2 + 1] = _base[uint8(buffer[i]) % _base.length];
      }

      return string(abi.encodePacked(converted));
  }

  //From @goodvibration at https://ethereum.stackexchange.com/questions/90629/converting-bytes32-to-uint256-in-solidity
  function bytes32ToUint256(bytes32 x) public pure returns (uint256) {
    uint256 y;
    for (uint256 i = 0; i < 32; i++) {
        uint256 c = (uint256(x) >> (i * 8)) & 0xff;
        if (48 <= c && c <= 57)
            y += (c - 48) * 10 ** i;
        else
            break;
    }
    return y;
}




}//end API

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);

        if (batchSize > 1) {
            // Will only trigger during construction. Batch transferring (minting) is not available afterwards.
            revert("ERC721Enumerable: consecutive transfers not supported");
        }

        uint256 tokenId = firstTokenId;

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256, /* firstTokenId */
        uint256 batchSize
    ) internal virtual {
        if (batchSize > 1) {
            if (from != address(0)) {
                _balances[from] -= batchSize;
            }
            if (to != address(0)) {
                _balances[to] += batchSize;
            }
        }
    }

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}
}