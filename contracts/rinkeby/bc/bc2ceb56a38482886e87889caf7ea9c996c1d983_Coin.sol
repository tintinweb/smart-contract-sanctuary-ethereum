/**
 *Submitted for verification at Etherscan.io on 2022-06-23
*/

pragma solidity >=0.4.22 <0.6.0;

 
// 一个合约
contract Coin {
    
    // 地址类型成员变量，访问权限public
    address public minter;
    
    // hash类型，key的address类型，value是uint类型
    mapping(address=>uint) public balances;
    
    // 定义一个事件
    event Sent(address from, address to, uint amount);
    
    // 构造方法
    constructor() {
        minter = msg.sender;
    }
    
    // 给指定地址发币
    function mint(address receiver, uint amount) public {
        require(msg.sender == minter);
        balances[receiver] += amount;
    }
    
    // 给指定地址转账，实际并未上链，只是保存在合约内部
    function send(address receiver, uint amount) public {
    		// 校验
        require(balances[msg.sender] >= amount);
        balances[msg.sender] -= amount;
        balances[receiver] += amount;
        
        // 触发事件
        emit Sent(msg.sender, receiver, amount);
    }
}