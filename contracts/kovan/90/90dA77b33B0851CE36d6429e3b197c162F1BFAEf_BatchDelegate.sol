/**
 *Submitted for verification at Etherscan.io on 2022-05-11
*/

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

interface dCult {
  function delegateBySig(
    address delegatee,
    uint nonce,
    uint expiry,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;
}

contract BatchDelegate {
  struct Sig {
    address delegatee;
    uint nonce;
    uint expiry;
    uint8 v;
    bytes32 r;
    bytes32 s;
  }

  Sig[] sigg;

  function setTuple(address[] memory _delegatee,
    uint[] memory _nonce,
    uint[] memory _expiry,
    uint8[] memory _v,
    bytes32[] memory _r,
    bytes32[] memory _s) public {
      for(uint i=0; i<_delegatee.length; i++){
          Sig memory sig = Sig(_delegatee[i], _nonce[i], _expiry[i], _v[i], _r[i], _s[i]);
          sigg.push(sig);
      }
  }

  function viewTuple(uint256 _tupleId) public view returns(Sig memory) {     
      return sigg[_tupleId];
  }

  function delegateBySigs() public {
    dCult dcult = dCult(0xD54B1434c1E7b0513Bc70D39e9ba9452085d4A4B);

    for (uint i = 0; i < sigg.length; i++) {
      Sig memory sig = sigg[i];
      dcult.delegateBySig(sig.delegatee, sig.nonce, sig.expiry, sig.v, sig.r, sig.s);
    }
  }
}