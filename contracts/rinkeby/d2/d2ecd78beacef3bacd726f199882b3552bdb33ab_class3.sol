/**
 *Submitted for verification at Etherscan.io on 2022-08-18
*/

contract class3 {

// ======================= 事件 +++++++++++++++++++++++++++++++++
///////////////////////////////////////////////////////////////////////////

//  Solidity中的事件（event）是EVM上日志的抽象，它具有两个特点：
//  响应：应用程序（ether.js）可以通过RPC接口订阅和监听这些事件，并在前端做响应。
//  经济：事件是EVM上比较经济的存储数据的方式，每个大概消耗2,000 gas；相比之下，链上存储一个新变量至少需要20,000 gas。

//  规则
// 事件的声明由event关键字开头，然后跟事件名称，括号里面写好事件需要记录的变量类型和变量名。以ERC20代币合约的Transfer事件为例：

    // 事先声明变量，Transfer是名字，括号内是事件中的元素的格式以及内容。被indexed的变量最多3个作为Topic，其他进入data里面。
    event Transfer(address indexed from, address indexed to, uint256 value);

    // 定义_balances映射变量，记录每个地址的持币数量
    mapping(address => uint256) public _balances;

    // 定义_transfer函数，执行转账逻辑
    function transfer(
        address from,
        address to,
        uint256 amount
    ) external {

        _balances[from] = 10000000; // 给转账地址一些初始代币

        _balances[from] -=  amount; // from地址减去转账数量
        _balances[to] += amount; // to地址加上转账数量

    }
}