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