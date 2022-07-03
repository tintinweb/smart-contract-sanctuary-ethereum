/**
 *Submitted for verification at Etherscan.io on 2022-07-03
*/

pragma solidity ^0.4.16;

// 怎么限制所有调用合约的人必须是真实的管理员账户，而不是合约账户
interface tokenRecipient {
    function receiveApproval(address _from, uint _value, address _token, bytes _extraData) public;
}

contract TokenERC20 {

    string public name;
    string public symbol;
    uint public decimals = 18; // decimals 可以有的小数点个数，最小的代币单位。18 是建议的默认值

    uint256 public totalSupply;
    //  这里的storage 与 memory不是太理解
    address[] admin;

    // 收取的手续费的地址
    address serverCost;

    // 用mapping保存每个地址对应的余额
    mapping (address => uint256) public balanceOf;

    // 给予另外一个地址对于前一个地址有操作的能力

    mapping (address => mapping (address => uint256)) public allowance;

    // 事件，用来通知客户端交易发生
    event Transfer(address indexed from, address indexed to, uint256 value);
    // 实现铸造功能, 通知客户端铸造完成
    event cast(uint initialSupply, string tokenName, string tokenSymbol);

    // 事件，用来通知客户端代币被消费
    event Burn(address indexed from, uint256 value);


    /* 构造函数 */
    // constructor() {}
    // 初试供应为10亿
    // 代币名称定为FC，描述定为FCoin
    function TokenERC20(uint initialSupply, string tokenName, string tokenSymbol) public {
        
        // 10**18 wei
        // 供应的份额，份额跟最小的代币单位有关，份额 = 币数 * 10 ** decimals, 按照以太坊的惯性规则计算
        totalSupply = initialSupply * 10 ** uint256(decimals); 
        balanceOf[msg.sender] = totalSupply; // 创造者拥有的代币
        name = tokenName;
        symbol = tokenSymbol;
        cast(initialSupply, tokenName, tokenSymbol);
    }

    // 代币交易转移的内部实现
    function _transfer(address _from, address _to, uint _value) internal {
        // 确保目标地址不为0x0，因为0x0地址代表销毁, address(0)
        require(_to != 0x0);
        // 检查发送者余额
        require(balanceOf[_from] >= _value);
        // 溢出检查
        require(balanceOf[_to] + _value > balanceOf[_to]);

        // 以下是具体交易逻辑的实现, 以及检查最后的交易是否被中断
        uint previousBalances = balanceOf[_from] + balanceOf[_to];

        balanceOf[_from] -= _value;
        // 精度问题 * 10000
        // 向上取整， 向下取整

        balanceOf[_to] += _value * 95 / 100; 

        Transfer(_from, _to, _value);

        // 用assert来检查代码逻辑
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    // 代币交易转移
    // 从自己的账号发送_value个代币到_to地址
    function transfer(address _to, uint _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) 
        // 授权from代币转移自己账户的代币
        public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    modifier isAdmin(address _admin) {
        for (uint i = 0; i < admin.length; i ++) {
            // require, reserve, throw
            require(admin[i] == _admin);
        }
        _;
    }


    function approve(address _spender, uint256 _value) public isAdmin(_spender) returns (bool success)  {
        allowance[msg.sender][_spender] = _value;
        return true;
    }


    // 设置允许一个地址(合约)以创建交易者的名义可以花费的最多代币数
    // @param _spender 被授权的地址(合约)
    // @param _value 最大可花费的代币数
    // @param _extraData 发送给合约的附加数据
    // ++ +1 add(1)

    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public isAdmin(_spender)
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            // 通知合约
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    // 销毁创建交易者账户中指定的代币
    // bool success的意思
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        Burn(msg.sender, _value);
        return true;
    }

    // 销毁用户账户中指定个代币
    // Remove `_value` tokens from the system irreversibly on behalf of `_from`.
    // @param _from the address of the sender
    // @param _value the amount of money to burn 
    // 
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value); // 检查发送者的余额是否足够
        require(_value <= allowance[_from][msg.sender]); // Check allowance
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value; // 可以
        totalSupply -= _value;
        Burn(_from, _value);
        return true;
    }


    // 添加管理员, 暂时还没有用到
    function addAdmin(address _admin) public returns (bool success) {
        require(_admin != 0x0);
        admin.push(_admin);
        return true;
    }
}