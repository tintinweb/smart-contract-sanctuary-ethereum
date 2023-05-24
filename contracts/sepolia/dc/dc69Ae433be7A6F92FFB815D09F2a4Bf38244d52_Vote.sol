// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IZKSBT {
    /**
     * @dev Validates if the _soul is associated with the valid data in the corresponding address.
     * By checking if the `_soulData` given in parameter is the same as the data in the struct of mapping.
     *
     * This uses the Verification.sol contract to verify the data.
     * @param _soul is the address of the soul
     * @param verifierAddress is the address deployed for the Verifier.sol contract
     *
     * @return true if the proof is valid, false otherwise
     */
    function validateAttribute(
        address _soul, 
        address verifierAddress, 
        uint256[1] memory input
    ) external view returns (bool);
} 

contract Vote {

  mapping (bytes32 => uint256) private votesReceived; // 用來記錄候選人獲得的票數
  mapping (bytes32 => bool) public candidateList;
  mapping (address => bool) private voters;

  /* constructor input example:
    // John, Alice, Bob after keccak256  
    [0x0bfa36c40b8771f59912a8b06e3ba9cd68504e69345a0ebcb952c3c6100ec88e,0x6070f87e7650727769f301b1e264c58d77a49792dc17c13fe3cb44a9bb1f7b44, 0x780641b8ceca510c40f5f0178d126444811cc3e3edf7fa86f3656f77615dcc5c], 
  */
  constructor(bytes32[] memory _candidateNames) {
    for (uint8 i = 0; i < _candidateNames.length; i++) { // 候選人名單
      candidateList[_candidateNames[i]] = true;
    } 
  }

  modifier validVoter (
      address _soul, 
      address _verifierAddress, 
      address _zkSBTAddress, 
      uint256 [1] memory input 
    ) {
        IZKSBT zksbt = IZKSBT(_zkSBTAddress);
        require (zksbt.validateAttribute(_soul, _verifierAddress, input), "You are invalid to vote");
        _;
  }

  function voteForCandidate(
        bytes32 candidate,
        address _soul, 
        address _verifierAddress, 
        address _zkSBTAddress, 
        uint256 [1] memory input
    ) public 
    validVoter( 
        _soul, _verifierAddress, _zkSBTAddress, input
    ) { 
    require (candidateList[candidate], "input is not a candidate");
    require (!voters[_soul], "This sbt has voted");
    votesReceived[candidate] += 1;
    voters[_soul] = true;
  }
}