/**
 *Submitted for verification at Etherscan.io on 2022-10-12
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;

// EIP中定义的ERC20标准接口
interface IERC20 {
    // 返回存在的代币总数量
    function totalSupply() external view returns (uint256);

    // 返回 account 拥有的代币数量
    function balanceOf(address account) external view returns (uint256);

    // 将 amount 代币从调用者账户移动到 recipient
    // 返回一个布尔值表示操作是否成功
    // 发出 {Transfer} 事件
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    // 返回 spender 允许 owner 通过 {transferFrom}消费剩余的代币数量
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    // 调用者设置 spender 消费自己amount数量的代币
    function approve(address spender, uint256 amount) external returns (bool);

    // 将amount数量的代币从 sender 移动到 recipient ，从调用者的账户扣除 amount
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    // 当value数量的代币从一个form账户移动到另一个to账户
    event Transfer(address indexed from, address indexed to, uint256 value);
    // 当调用{approve}时，触发该事件
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Test is IERC20{
   uint public override totalSupply;
   mapping(address => uint) public override balanceOf;
   mapping(address => mapping(address => uint)) override  public allowance;
   string public name = "Test";
   string public symbol = "test";
   uint8 public decimals =18;

   function transfer(address recipient, uint256 amount) override external returns (bool){
     balanceOf[msg.sender] -= amount;
     balanceOf[recipient] += amount;
     emit Transfer(msg.sender, recipient, amount);
     return true;
   }


    // 调用者设置 spender 消费自己amount数量的代币
    function approve(address spender, uint256 amount) external  override returns (bool){
      allowance[msg.sender][spender] = amount;
      emit Approval(msg.sender, spender, amount);
      return true;
    }
  
  function transferFrom(
        address sender,
        address recipient,
        uint256 amount
      ) override external returns (bool){
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
      }

    function mint(uint amount) external {
      balanceOf[msg.sender] += amount;
      totalSupply += amount;
      emit Transfer(address(0), msg.sender, amount);
    }
  

}