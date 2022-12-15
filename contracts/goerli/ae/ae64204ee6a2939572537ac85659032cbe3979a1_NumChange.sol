/**
 *Submitted for verification at Etherscan.io on 2022-12-15
*/

contract NumChange {
  uint num;
  function setNum(uint _a) public returns(uint) {
    num = _a;
    return num;
  }

  function getNum() public view returns(uint) {
    return num;
  }

  function add(uint _a, uint _b) public pure returns(uint) {
    return _a + _b;
  }
}