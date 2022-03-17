// SPDX-License-Identifier: MIT
// An example of a consumer contract that relies on a subscription for funding.
pragma solidity ^0.8.4;

interface RHOST {
    function requestRandomWords() external;
    function getWords() external view returns (uint, uint);

}

interface LCF {
    function brawl(uint, uint) external returns(uint winner, uint loser);
}

contract BrawlInitiator {
    
  address randomnessHost;
  address lecryptofellows;

  
  constructor(address _randomnessHost, address _lecryptofellows) {
    randomnessHost = _randomnessHost;
    lecryptofellows = _lecryptofellows;
  }
  

  function startBrawl() public {
    (uint rnd1, uint rnd2) = RHOST(randomnessHost).getWords();

    LCF(lecryptofellows).brawl(rnd1, rnd2);
  }

}