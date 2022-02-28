/**
 *Submitted for verification at Etherscan.io on 2022-02-28
*/

pragma solidity ^0.5.8;

contract MiMC {
  uint constant FIELD_SIZE = 21888242871839275222246405745257275088548364400416034343698204186575808495617;

  function MiMCSponge(uint256 xL, uint256 xR) public pure returns (uint256, uint256) {
    uint exp;
    uint t;
    uint xR_tmp;
    t = xL;
    exp = mulmod(t, t, FIELD_SIZE);
    exp = mulmod(exp, exp, FIELD_SIZE);
    exp = mulmod(exp, t, FIELD_SIZE);
    xR_tmp = xR;
    xR = xL;
    xL = addmod(xR_tmp, exp, FIELD_SIZE);

    return (xL, xR);
  }

  function hashLeftRight(uint256 _left, uint256 _right) public pure returns (uint256) {
    uint256 R = _left;
    uint256 C = 0;
    (R, C) = MiMCSponge(R, C);
    R = addmod(R, uint256(_right), FIELD_SIZE);
    (R, C) = MiMCSponge(R, C);
    return R;
  }
}