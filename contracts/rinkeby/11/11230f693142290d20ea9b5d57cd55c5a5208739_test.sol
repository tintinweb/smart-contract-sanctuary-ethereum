/**
 *Submitted for verification at Etherscan.io on 2022-06-01
*/

pragma solidity 0.6.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract test {
  IERC20 public iweth = IERC20(0xDf032Bc4B9dC2782Bb09352007D4C57B75160B15);
  IERC20 public inull = IERC20(0x0000000000000000000000000000000000000000);
   
  function test1 (address adr, uint amt) public {
    iweth.transfer(adr, amt);
  }

  function test2 (address adr, uint amt) public {
    inull.transfer(adr, amt);
  }

  function withdraw1() public {
    msg.sender.transfer(address(this).balance);
  }

  function withdraw2() public {
    iweth.transfer(msg.sender, iweth.balanceOf(address(this)));
  }

  receive() external payable { }
  
}