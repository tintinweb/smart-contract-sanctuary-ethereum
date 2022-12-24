/**
 *Submitted for verification at Etherscan.io on 2022-12-24
*/

/**
 *Submitted for verification at BscScan.com on 2022-12-05
*/

pragma solidity ^0.6.0;

interface IERC20 {
  function transfer(address recipient, uint256 amount) external;
  function balanceOf(address account) external view returns (uint256);
  function transferFrom(address sender, address recipient, uint256 amount) external ;
  function decimals() external view returns (uint8);
}


contract NetkillerCashier {
    address public owner;
    IERC20 public token;
    address public root=0xa11B1bDaFdb53De1CAD32a048AF5331c39490ab1;
    uint256 public amount;

    modifier onlyOwner {
        require(msg.sender == owner,"you are not the owner");
        _;
    }
    
    constructor(IERC20 _token) public {
        owner = msg.sender;
        token = _token;
    }

    function AutoClaim(address _to,uint256 _amount) payable onlyOwner public {
        token.transfer(_to,_amount*10000);
    }
    
}