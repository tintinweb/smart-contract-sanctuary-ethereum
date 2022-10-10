/**
 *Submitted for verification at Etherscan.io on 2022-10-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

abstract contract Ownable {
    address public owner; 
    constructor() { owner = msg.sender; }
    modifier onlyOwner { require(owner == msg.sender, "Not Owner!"); _; }
    function transferOwnership(address new_) external onlyOwner { owner = new_; }
}

contract Descriptor is Ownable {

    //has to be one higher than actual num
    uint256 private constant phase1_count = 11;
    uint256 private constant phase2_count = 14;
    uint256 private constant phase3_count = 13;
    uint256 private constant phase4_count = 12;
    uint256 private constant phase5_count = 15;
    uint256 private constant phase6_count = 9;
    uint256 private constant phase7_count = 8;
    uint256 private constant phase8_count = 10;
    uint256 private constant phase9_count = 6;
    uint256 private constant phase10_count = 4;

    
    //string internal constant START = "<svg viewBox='0 0 120 120' xmlns='http://www.w3.org/2000/svg' style='background: black;'><g fill='white' font-size='10px' font-family='Courier New'>";
    string internal constant TXTS = "<text text-anchor='middle' x='60' ";
    string internal constant TXTE = "</text>";
    //string internal constant END = "</g></svg>";

    string[] public phase1;
    string[] public phase2;
    string[] public phase3;
    string[] public phase4;
    string[] public phase5;
    string[] public phase6;
    string[] public phase7;
    string[] public phase8;
    string[] public phase9;
    string[] public phase10;

    string[] public phase1name = 
    ["1","2", "3", "4", "5", "6", "7", "8", "9", "10", "11"];

    string[] public phase2name = 
    ["1","2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14"];

    string[] public phase3name = 
    ["1","2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13"];

    string[] public phase4name = 
    ["1","2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12"];

    string[] public phase5name = 
    ["1","2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15"];

    string[] public phase6name = 
    ["1","2", "3", "4", "5", "6", "7", "8", "9"];

    string[] public phase7name = 
    ["1","2", "3", "4", "5", "6", "7", "8"];

    string[] public phase8name = 
    ["1","2", "3", "4", "5", "6", "7", "8", "9", "10"];

    string[] public phase9name = 
    ["1","2", "3", "4", "5", "6"];

    string[] public phase10name = 
    ["1","2", "3", "4"];

  function _addphase1(string calldata _trait) internal {
    phase1.push(_trait);
  }

  function _addphase2(string calldata _trait) internal {
    phase2.push(_trait);
  }

  function _addphase3(string calldata _trait) internal {
    phase3.push(_trait);
  }

  function _addphase4(string calldata _trait) internal {
    phase4.push(_trait);
  }

  function _addphase5(string calldata _trait) internal {
    phase5.push(_trait);
  }

  function _addphase6(string calldata _trait) internal {
    phase6.push(_trait);
  }

  function _addphase7(string calldata _trait) internal {
    phase7.push(_trait);
  }

  function _addphase8(string calldata _trait) internal {
    phase8.push(_trait);
  }

  function _addphase9(string calldata _trait) internal {
    phase9.push(_trait);
  }

  function _addphase10(string calldata _trait) internal {
    phase10.push(_trait);
  }

  function addManyphase1(string[] calldata _traits) external onlyOwner {
    for (uint256 i = 0; i < _traits.length; i++) {
      _addphase1(_traits[i]);
    }
  }

  function addManyphase2(string[] calldata _traits) external onlyOwner {
    for (uint256 i = 0; i < _traits.length; i++) {
      _addphase2(_traits[i]);
    }
  }

  function addManyphase3(string[] calldata _traits) external onlyOwner {
    for (uint256 i = 0; i < _traits.length; i++) {
      _addphase3(_traits[i]);
    }
  }

  function addManyphase4(string[] calldata _traits) external onlyOwner {
    for (uint256 i = 0; i < _traits.length; i++) {
      _addphase4(_traits[i]);
    }
  }

  function addManyphase5(string[] calldata _traits) external onlyOwner {
    for (uint256 i = 0; i < _traits.length; i++) {
      _addphase5(_traits[i]);
    }
  }

  function addManyphase6(string[] calldata _traits) external onlyOwner {
    for (uint256 i = 0; i < _traits.length; i++) {
      _addphase6(_traits[i]);
    }
  }

  function addManyphase7(string[] calldata _traits) external onlyOwner {
    for (uint256 i = 0; i < _traits.length; i++) {
      _addphase7(_traits[i]);
    }
  }

  function addManyphase8(string[] calldata _traits) external onlyOwner {
    for (uint256 i = 0; i < _traits.length; i++) {
      _addphase8(_traits[i]);
    }
  }

  function addManyphase9(string[] calldata _traits) external onlyOwner {
    for (uint256 i = 0; i < _traits.length; i++) {
      _addphase9(_traits[i]);
    }
  }

  function addManyphase10(string[] calldata _traits) external onlyOwner {
    for (uint256 i = 0; i < _traits.length; i++) {
      _addphase10(_traits[i]);
    }
  }

  function clearphase1() external onlyOwner {
    delete phase1;
  }

  function clearphase2() external onlyOwner {
    delete phase2;
  }

  function clearphase3() external onlyOwner {
    delete phase3;
  }

  function clearphase4() external onlyOwner {
    delete phase4;
  }

  function clearphase5() external onlyOwner {
    delete phase5;
  }

  function clearphase6() external onlyOwner {
    delete phase6;
  }

  function clearphase7() external onlyOwner {
    delete phase7;
  }

  function clearphase8() external onlyOwner {
    delete phase8;
  }

  function clearphase9() external onlyOwner {
    delete phase9;
  }

  function clearphase10() external onlyOwner {
    delete phase10;
  }

  function renderphase1(uint256 _srn) external view returns (string memory) {
      uint256 _trait = _srn % phase1_count;
      return string(abi.encodePacked(TXTS, "y='105'>", phase1[_trait], TXTE));    
  }

  function renderphase2(uint256 _srn) external view returns (string memory) {
      uint256 _trait = _srn % phase2_count;
      return string(abi.encodePacked(TXTS, "y='95'>", phase2[_trait], TXTE));
  }
 
  function renderphase3(uint256 _srn) external view returns (string memory) {
      uint256 _trait = _srn % phase3_count;
      return string(abi.encodePacked(TXTS, "y='85'>", phase3[_trait], TXTE));
  }
 
  function renderphase4(uint256 _srn) external view returns (string memory) {
      uint256 _trait = _srn % phase4_count;
      return string(abi.encodePacked(TXTS, "y='75'>", phase4[_trait], TXTE));
  }
 
  function renderphase5(uint256 _srn) external view returns (string memory) {
      uint256 _trait = _srn % phase5_count;
      return string(abi.encodePacked(TXTS, "y='65'>", phase5[_trait], TXTE));
  }
 
  function renderphase6(uint256 _srn) external view returns (string memory) {
      uint256 _trait = _srn % phase6_count;
      return string(abi.encodePacked(TXTS, "y='55'>", phase6[_trait], TXTE));
  }
 
  function renderphase7(uint256 _srn) external view returns (string memory) {
      uint256 _trait = _srn % phase7_count;
      return string(abi.encodePacked(TXTS, "y='45'>", phase7[_trait], TXTE));
  }
 
  function renderphase8(uint256 _srn) external view returns (string memory) {
      uint256 _trait = _srn % phase8_count;
      return string(abi.encodePacked(TXTS, "y='35'>", phase8[_trait], TXTE));
  }
 
  function renderphase9(uint256 _srn) external view returns (string memory) {
      uint256 _trait = _srn % phase9_count;
      return string(abi.encodePacked(TXTS, "y='25'>", phase9[_trait], TXTE));
  }
 
  function renderphase10(uint256 _srn) external view returns (string memory) {
      uint256 _trait = _srn % phase10_count;
      return string(abi.encodePacked(TXTS, "y='15'>", phase10[_trait], TXTE));
  }

  function rendertrait1(uint256 _srn) external view returns (string memory) {
      uint256 _trait = _srn % phase1_count;
      return string(abi.encodePacked(phase1name[_trait]));    
  }

  function rendertrait2(uint256 _srn) external view returns (string memory) {
      uint256 _trait = _srn % phase2_count;
      return string(abi.encodePacked(phase2name[_trait]));    
  }

  function rendertrait3(uint256 _srn) external view returns (string memory) {
      uint256 _trait = _srn % phase3_count;
      return string(abi.encodePacked(phase3name[_trait]));    
  }

  function rendertrait4(uint256 _srn) external view returns (string memory) {
      uint256 _trait = _srn % phase4_count;
      return string(abi.encodePacked(phase4name[_trait]));    
  }

  function rendertrait5(uint256 _srn) external view returns (string memory) {
      uint256 _trait = _srn % phase5_count;
      return string(abi.encodePacked(phase5name[_trait]));    
  }

  function rendertrait6(uint256 _srn) external view returns (string memory) {
      uint256 _trait = _srn % phase6_count;
      return string(abi.encodePacked(phase6name[_trait]));    
  }

  function rendertrait7(uint256 _srn) external view returns (string memory) {
      uint256 _trait = _srn % phase7_count;
      return string(abi.encodePacked(phase7name[_trait]));    
  }

  function rendertrait8(uint256 _srn) external view returns (string memory) {
      uint256 _trait = _srn % phase8_count;
      return string(abi.encodePacked(phase8name[_trait]));    
  }

  function rendertrait9(uint256 _srn) external view returns (string memory) {
      uint256 _trait = _srn % phase9_count;
      return string(abi.encodePacked(phase9name[_trait]));    
  }

  function rendertrait10(uint256 _srn) external view returns (string memory) {
      uint256 _trait = _srn % phase10_count;
      return string(abi.encodePacked(phase10name[_trait]));    
  }
}