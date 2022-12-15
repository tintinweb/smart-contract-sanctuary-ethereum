/**
 *Submitted for verification at Etherscan.io on 2022-12-15
*/

contract Multiply {
  function multiply(uint _a, uint _b) public pure returns(uint) {
    return _a * _b;
  }

  uint c;
  function multiply2(uint _a) public view returns(uint) {
    return c * _a;
  }
}