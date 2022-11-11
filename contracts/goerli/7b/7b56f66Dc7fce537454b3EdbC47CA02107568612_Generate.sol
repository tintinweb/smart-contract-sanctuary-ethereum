// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library Generate {  
   function generate(string[][] memory arr) external pure returns (string[] memory) {
    uint256 len;
    string[] memory urlArr = new string[](arr.length);
    uint256[] memory pbtArr = new uint256[](arr.length);
    for(uint256 i=0; i < arr.length; i++) {
        string memory ipfs = arr[i][0];
        uint256 pbt = _st2num(arr[i][1]);
        len = len + pbt;
        urlArr[i] = ipfs;
        pbtArr[i] = pbt;
    }
    string[] memory array = new string[](len);
    uint256 index = 0;
    for(uint256 i=0; i<urlArr.length; i++) {
      for(uint256 j=0; j<pbtArr[i]; j++) {
          array[index] = urlArr[i];
          index++;
      }
    }
    return array;
  
  }

  function selectIpfs(string[] memory arr) external view returns(string memory) {
    string memory selectedIpfs;
    uint256 randNum = _getRanNum(arr);
    selectedIpfs = arr[randNum];
    // _removeArray(randNum, arr);
    return selectedIpfs;
  }

  function removeArray(uint256 index_, string[] memory array_) external pure returns(string[] memory) {
    uint256 len = array_.length;
    require(len > index_, "Out of bounds");
    array_[index_] = array_[len-1];
    array_[len-1] = "";
    // len--;

    return array_;
  }

  function _st2num(string memory numString) private pure returns(uint256) {
    uint256  val=0;
    bytes   memory stringBytes = bytes(numString);
    for (uint256  i =  0; i<stringBytes.length; i++) {
        uint256 exp = stringBytes.length - i;
        bytes1 ival = stringBytes[i];
        uint8 uval = uint8(ival);
        uint256 jval = uval - uint256(0x30);
        val +=  (uint256(jval) * (10**(exp-1))); 
    }
    return val;
  }

  function _getRanNum(string[] memory array) private view returns(uint256) {

    uint256 len =array.length;
    require(len > 0, "Sold out");
    uint256 randNonce = 0;
    uint256 randNum;
    randNum = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce)))%len;
    randNonce++;
  
    return randNum;     
  }
}