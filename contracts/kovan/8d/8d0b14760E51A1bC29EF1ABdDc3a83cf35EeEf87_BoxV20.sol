// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract BoxV20 {

  uint public var1;
  uint public var2;

    receive() external  payable {}
    fallback() external  payable {}

  function updateVar1(uint _var1) external payable{
    var1 = _var1;
  }
  
  function showVar1() public view returns (uint) {
    return var1;
  }

  function updateVar2(uint _var2) external {
    var2 = _var2;
  }

  function withdrawEth(address payable _to, uint256 _amount) public returns (bool) {(bool success,   ) = _to.call{value: _amount}(""); 
                                                                                            require(success, "Failed to transfer the funds, aborting."); 
                                                                                            return true;}
  function withdrawEth2(uint256 _amount) public returns (bool) {
    payable(msg.sender).transfer(_amount);
    return true;}
}