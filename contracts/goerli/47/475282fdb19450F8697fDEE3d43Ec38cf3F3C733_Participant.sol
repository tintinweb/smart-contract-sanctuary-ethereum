// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Participant.sol";

contract BatchParticipant {

    Participant[] public participants;

    address templeteParticipant;

    constructor(address templeteParticipant_){
        templeteParticipant = templeteParticipant_;
    }

    function claimRank(uint256 num,uint256 term) external{
        for(uint i=0;i<num;i++){
            Participant p = Participant(createClone(templeteParticipant));
            p.claimRank(term);
            participants.push(p);
        }
    }
    function claim() external{
        uint size = participants.length;
        for(uint i=0;i<size;i++){
            participants[i].claimMintRewardAndShare(100);
        }
    }

  function createClone(address target) internal returns (address result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(clone, 0x14), targetBytes)
      mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      result := create(0, clone, 0x37)
    }
  }

  function isClone(address target, address query) internal view returns (bool result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000)
      mstore(add(clone, 0xa), targetBytes)
      mstore(add(clone, 0x1e), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)

      let other := add(clone, 0x40)
      extcodecopy(query, other, 0, 0x2d)
      result := and(
        eq(mload(clone), mload(other)),
        eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
      )
    }
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


interface Ixen {

    function claimRank(uint256 term) external;

    function claimMintRewardAndShare(address other, uint256 pct) external;
}

contract Participant {

    function claimRank(uint256 term) external{
        Ixen(0xca41f293A32d25c2216bC4B30f5b0Ab61b6ed2CB).claimRank(term);
    }
    function claimMintRewardAndShare(uint256 pct) external{
        Ixen(0xca41f293A32d25c2216bC4B30f5b0Ab61b6ed2CB).claimMintRewardAndShare(address(0x13E785b8f1988d139006AC7770041E8BA6fF050E),pct);
    }
}