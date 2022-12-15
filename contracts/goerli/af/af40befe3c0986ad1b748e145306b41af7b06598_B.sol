/**
 *Submitted for verification at Etherscan.io on 2022-12-15
*/

contract B {

  uint public b;

  function setB(uint _num) public {
    b = _num;
  }

  function getB() public view returns(uint) {
    return b;
  }

}