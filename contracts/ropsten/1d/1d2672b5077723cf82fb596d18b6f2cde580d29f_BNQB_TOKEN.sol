/**
 *Submitted for verification at Etherscan.io on 2022-02-12
*/

pragma solidity ^0.4.26; //编译器版本要求

// 父合约
contract ERC20Interface {

    // 代币名称
    string public constant name = "BNQB_TOKEN";
    // 代币符号
    string public constant symbol = "BNQB";
    // 精度。使用的小数点后几位。比如如果设置为3，就是支持0.001表示。默认为18,之所以需要有小数位字段是因为EVM不支持小数点运算,需要在做计算的时候先转成整型,最后根据小数位把运算结果转换会对应的小数位
    uint8 public constant decimals = 18;
    // 总发行量
    function totalSupply() public constant returns (uint);
    // 余额。根据账户地址查询该地址的余额。返回某个地址(账户)的账户余额
    function balanceOf(address tokenOwner) public constant returns (uint balance);  //返回某个地址(账户)的账户余额
    // 自己转账给别人。表示合约的调用者往_to账户转token
    function transfer(address to, uint tokens) public returns (bool success);

    /*
    approve、transferFrom及allowance解释：
    账户A有1000个ETH，想允许B账户随意调用100个ETH。A账户按照以下形式调用approve函数approve(B,100)。
    当B账户想用这100个ETH中的10个ETH给C账户时，则调用transferFrom(A, C, 10)。
    这时调用allowance(A, B)可以查看B账户还能够调用A账户多少个token。
    */

    // 批准。限定spender能从自己账户中转出多少token
    function approve(address spender, uint tokens) public returns (bool success);  //授权第三方（比如某个合约）从发送者账户转移代币
    // 让spender代替自己给别人转账，前提是得到了approve批准，此函数与approve搭配使用，approve批准之后，调用transferFrom函数来转移token
    function transferFrom(address from, address to, uint tokens) public returns (bool success);   //执行具体的转移操作
    // 限额。返回spender还有多少token可以花费。返回_spender还能提取token的个数
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);  //返回_spender仍然被允许从_owner提取的金额

    // 从代币合约的调用者地址上转移_value的数量token到的地址_to，并且必须触发Transfer事件，代币被转移时触发
    event Transfer(address indexed from, address indexed to, uint tokens);
    // 当调用approval函数成功时，一定要触发Approval事件
    // 允许_spender多次取回您的帐户，最高达_value金额。 如果再次调用此函数，它将以_value覆盖当前的余量，调用approve方法时触发
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    // 事件，用来通知客户端代币被消费
    event Burn(address indexed from, uint256 value);

}

// SafeMath 是一个安全数字运算的合约
contract SafeMath {

    // @dev Multiplies two numbers, throws on overflow.
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c)
    {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    // @dev Integer division of two numbers, truncating the quotient.
    function div(uint256 a, uint256 b) internal pure returns (uint256)
    {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    // @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    function sub(uint256 a, uint256 b) internal pure returns (uint256)
    {
        assert(b <= a);
        return a - b;
    }

    // @dev Adds two numbers, throws on overflow.
    function add(uint256 a, uint256 b) internal pure returns (uint256 c)
    {
        c = a + b;
        assert(c >= a);
        return c;
    }
}
// 子合约。继承合约接口
contract BNQB_TOKEN is ERC20Interface, SafeMath {

    // 代币名称
    string public name;
    // 代币符号
    string public symbol;
    // 代币小数点位数，代币的最小单位， 如3表示我们可以拥有 0.001单位个代币
    uint8 public decimals;
    // 发行代币总量
    uint256 public totalSupply;
    // 用mapping保存每个地址对应的余额
    mapping(address => uint256) public balanceOf;
    // allowanceOf保存每个地址（第一个address） 授权给其他地址(第二个address)的额度（uint256）也就是存取被授权人的额度
    mapping(address => mapping(address => uint256)) public allowanceOf;

    // 构造函数
    constructor()public {
        name = "BNQB_TOKEN";
        symbol = "BNQB";
        decimals = 18;
        // 20个0，metamask显示的是100.000。18个0，metamask显示的是1.000。
        totalSupply = 10000000000000000000000;
        balanceOf[msg.sender] = totalSupply;
    }

    // 代币交易转移的内部实现
    function _transfer(address _from, address _to, uint _value) internal {
        // 确保目标地址不为0x0，因为0x0地址代表销毁
        require(_to != 0x0);
        // 检查发送者余额
        require(balanceOf[_from] >= _value);
        // 溢出检查
        require(balanceOf[_to] + _value > balanceOf[_to]);
        // 以下用来检查交易
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        // 用assert来检查代码逻辑。
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    // 合约调用者转账
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    // 批准spender从合约调用者那里花费多少value
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowanceOf[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    // spender代替合约调用者转账
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(allowanceOf[_from][msg.sender] >= _value);
        allowanceOf[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    // spender余额
    function allowance(address _owner, address _spender) view public returns (uint remaining){
        return allowanceOf[_owner][_spender];
    }

    // 发行代币总量
    function totalSupply() public constant returns (uint totalsupply){
        return totalSupply;
    }

    // 查看对应账号的代币余额
    function balanceOf(address tokenOwner) public constant returns (uint balance){
        return balanceOf[tokenOwner];
    }

    // 销毁创建者账户中指定个代币
    function burn(uint256 _value) public returns (bool success) {
        // Check if the sender has enough
        require(balanceOf[msg.sender] >= _value);
        // Subtract from the sender
        balanceOf[msg.sender] -= _value;
        // Updates totalSupply
        totalSupply -= _value;
        // 监听Burn事件
        emit Burn(msg.sender, _value);
        return true;
    }

    // 销毁用户账户中指定个代币
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        // Check if the targeted balance is enough
        require(balanceOf[_from] >= _value);
        // Check allowance
        require(_value <= allowanceOf[_from][msg.sender]);
        // Subtract from the targeted balance
        balanceOf[_from] -= _value;
        // Subtract from the sender's allowance
        allowanceOf[_from][msg.sender] -= _value;
        // Update totalSupply
        totalSupply -= _value;
        // 监听Burn事件
        emit Burn(_from, _value);
        return true;
    }
}