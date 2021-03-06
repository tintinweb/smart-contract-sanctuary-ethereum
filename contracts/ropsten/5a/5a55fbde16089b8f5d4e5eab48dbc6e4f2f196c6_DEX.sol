/**
 *Submitted for verification at Etherscan.io on 2021-02-16
*/

pragma solidity ^0.6.0;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}




library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
}

contract DEX {


    uint public tokenPrice=0.007 ether;
    event Bought(address user,uint256 amount);
    event Sold(address user,uint256 amount);


    IERC20 public token;

    constructor(IERC20 _hexa) public {
        token = _hexa;
    }

    function buy(uint amount) payable public {
        uint256 amountTobuy = amount;
        uint256 eVal=(amount*tokenPrice);
        require(msg.value>=eVal,"Invalid Amount");
        uint256 dexBalance = token.balanceOf(address(this));
        require(amountTobuy > 10, "You need to send some Ether");
        require(amountTobuy <= dexBalance, "Not enough tokens in the reserve");
        token.transfer(msg.sender, amount);
        emit Bought(msg.sender,amount);
    }

    function sell(uint256 amount) public {
        require(amount >=10, "You need to sell at least some tokens");
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= amount, "Check the token allowance");
        token.transferFrom(msg.sender, address(this), amount);
        uint256 eVal=(amount*tokenPrice);
        msg.sender.transfer(eVal);
        emit Sold(msg.sender,amount);
    }

}