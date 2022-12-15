/**
 *Submitted for verification at Etherscan.io on 2022-12-15
*/

contract A {

  uint public a;

  function setA(uint _num) public {
    a = _num;
  }

  function getA() public view returns(uint) {
    return a;
  }

}