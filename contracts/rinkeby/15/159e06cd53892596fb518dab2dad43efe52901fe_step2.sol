/**
 *Submitted for verification at Etherscan.io on 2022-08-06
*/

pragma solidity ^0.8.15;

pragma solidity >=0.4.22 <0.9.0;

interface ERC20{
  function deposit() external payable;
  function withdraw(uint256 amount) external;
}

contract step2{
  ERC20 weth;

  constructor(address _weth) public {
    weth = ERC20(_weth);
  }

  function swapEthForWeth() public payable {
    weth.deposit{value: msg.value}();
  }

    fallback() external payable {    
    }
    receive() external payable {
    }
}