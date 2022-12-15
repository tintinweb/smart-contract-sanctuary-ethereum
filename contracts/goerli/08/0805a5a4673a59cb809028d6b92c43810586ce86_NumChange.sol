/**
 *Submitted for verification at Etherscan.io on 2022-12-15
*/

contract NumChange {
  uint a;
  function setA(uint _a) public returns(uint) {
    a = _a;
    return a;
  }

  function add(uint _a, uint _b) public pure returns(uint) {
    return _a + _b;
  }
}