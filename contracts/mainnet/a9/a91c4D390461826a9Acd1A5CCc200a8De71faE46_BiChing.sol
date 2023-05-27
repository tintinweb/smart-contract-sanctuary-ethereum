// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;


/** @title BiChing Contract
  * @author @0xAnimist
  * @notice First Onchain GIF, collaboration between Cai Guo-Qiang and Kanon
  */
contract BiChing {

  constructor() { }


  function getBinomialPathsAsStrings(uint8[] memory _fortune, uint8[] memory _fork) public pure returns(string memory fortuneBinomial, string memory forkBinomial){
    (bool[] memory fortunePath, bool[] memory forkPath) = binomialPaths(_fortune, _fork);

    return (binomialPathString(fortunePath, true), binomialPathString(forkPath, false));
  }

  /**
    * @dev Converts _fortune into a binomial path
    * @param _fortune fortune
    */
  function binomialPaths(uint8[] memory _fortune, uint8[] memory _fork) public pure returns(bool[] memory fortunePath, bool[] memory forkPath) {
    fortunePath = new bool[](6);
    forkPath = new bool[](6);

    for(uint8 i = 1; i < 7; i++){
      uint8 j = i-1;

      if(_fortune[i] > _fortune[j]){
        fortunePath[j] = true;
        if(_fork[i] < _fork[j]){
          forkPath[j] = true;
        }
      }else{
        if(_fork[i] > _fork[j]){
          forkPath[j] = true;
        }
      }

      //overwrite above logic with edge cases
      //Note: _fork[x] is zero until a fork happens
      if(_fork[i] == 0){
        forkPath[j] = false;
      }else{//first shift
        if(_fork[j] == 0){
          forkPath[j] = true;
        }
      }
    }
  }

  function forkIndex(uint8[] memory _fortune, uint8[] memory _fork) public pure returns(uint256 index){
    (bool[] memory basePath, bool[] memory forkPath) = binomialPaths(_fortune, _fork);

    for(uint256 i = 0; i < 6; i++){
      if(!forkPath[i]){
        basePath[i] = !basePath[i];
      }
    }

    return _parseDecimal(basePath);
  }

  function binomialPath(uint8[] memory _fortune, bool _invert) public pure returns(bool[] memory path) {
    path = new bool[](6);

    for(uint8 i = 1; i < 7; i++){
      uint8 j = i-1;

      if(_fortune[i] > _fortune[j]){
        path[j] = true;
      }

      if(_invert){
        path[j] = !path[j];
      }
    }
  }

  /**
    * @dev Determines the fortune index from 0-63 of _fortune
    * @param _fortune fortune
    */
  function fortuneIndex(uint8[] memory _fortune) public pure returns(uint256 index) {
    bool[] memory path = binomialPath(_fortune, true);

    return _parseDecimal(path);
  }

  /**
    * @dev Reads array of boolean values as if a binary number and converts to decimal
    * @param _binaryArray array of boolean values
    */
  function _parseDecimal(bool[] memory _binaryArray) internal pure returns (uint dec) {
    for(uint256 i = 0; i < _binaryArray.length; i++){
      if(_binaryArray[_binaryArray.length - 1 - i]){
        dec += 2**i;
      }
    }
  }

  /**
    * @dev Converts binomial _path into a string value
    * @param _path path
    */
  function binomialPathString(bool[] memory _path, bool _invert) public pure returns(string memory pathStr){
    for(uint256 i = 0; i < _path.length; i++){
      if(_path[i]){//note the string is the inverse of the bool path (bc 0 is up on screen)
        if(_invert){
          pathStr = string(abi.encodePacked(pathStr, '0'));
        }else{
          pathStr = string(abi.encodePacked(pathStr, '1'));
        }
      }else{
        if(_invert){
          pathStr = string(abi.encodePacked(pathStr, '1'));
        }else{
          pathStr = string(abi.encodePacked(pathStr, '0'));
        }
      }
    }
  }

  //assume _transIndex == 0
  function cast(bytes memory _input) public pure returns(uint8[] memory fortune, uint8[] memory fork, uint8 forkcount) {
    //require(_input.length >= 18, "insufficient input");

    //initialize return arrays
    fortune = new uint8[](7);
    fork = new uint8[](7);

    fortune[0] = 6;//floor(height/2)
    uint8 f = 6;//floor(height/2)

    bool changed;

    for(uint8 i = 1; i <= 6; i++){
      (fortune[i], f, changed) = compute(fortune[i-1], f, _input[i-1], changed);

      if(changed){
        fork[i] = f;
        forkcount++;
    }
    }//end for
  }//end cast()


  // 1 == tails; 0 == heads
  function compute(uint8 _y, uint8 _f, bytes1 _input, bool _changed) public pure returns(uint8 y, uint8 f, bool changed) {
    _input = _input | 0x1f;
    changed = _changed;

    // heads == 0; tails == 1
    if(_input == 0x1f){// all heads == 6 => changing yin
      f = _f + 1;
      y = _y - 1;
      if(!changed){
        changed = true;
      }
    }else if(_input == 0x3f || _input == 0x5f || _input == 0x9f){// one tails == 7 => yang
      f = _f + 1;
      y = _y + 1;
    }else if(_input == 0x7f || _input == 0xbf || _input == 0xdf){// one heads == 8 => yin
      f = _f - 1;
      y = _y - 1;
    }else{// three tails == 9 => changing yang
      f = _f - 1;
      y = _y + 1;
      if(!changed){
        changed = true;
      }
    }
  }

}//end