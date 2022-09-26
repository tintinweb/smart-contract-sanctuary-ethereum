/**
 *Submitted for verification at Etherscan.io on 2022-09-26
*/

pragma solidity ^0.4.26;

/**
合约写于2022-09-21 完成于2022-9-21
提交以太坊验证于2022-9-26
*/
interface Erc20 {
  function approve(address, uint256) public;

  function transfer(address, uint256) public;
    
  function balanceOf(address) view public returns (uint256);
}

contract OwnbitMultiSig {
    event Submission(uint indexed transactionId);//提交事件变动
    event Confirmation(address indexed sender, uint indexed transactionId);//签字事务变动
    event Execution(uint indexed transactionId);//交易成功变动
    event ExecutionFailure(uint indexed transactionId);//交易失败变动

    uint constant public MAX_OWNER_COUNT = 50;//最大人数
    mapping(address => bool) private isOwner;//是否合约主人的映射
    struct Transaction {//交易事务
        uint id;//事务ID
        address destination;//提交人
        uint value;//涉及价值
        bytes data;//所带数据字段
        bool executed;//是否已执行
    }
    mapping (uint => Transaction) public transactions;//交易事务的映射
    mapping (uint => mapping (address => bool)) public confirmations;//确认人数的映射
    uint public transactionCount = 0;//交易事务的次数
    address[] private owners;//合约所有者地址
    uint private required;//必要的签名人数
    // 契约nonce不能被契约访问，因此我们实现了一个非类变量来进行重放保护。
    uint256 private spendNonce = 0;

    //  验证部署数据是否有效
    //  参数：用户数及必要签名人数
    modifier validRequirement(uint ownerCount, uint _required) {
        require (ownerCount <= MAX_OWNER_COUNT
                && _required <= ownerCount
                && _required >= 1);
        _;
    }
    //  验证交互者是否是合约本身
    modifier onlyWallet() {
        require (msg.sender != address(this),"不能和自身交互");
        _;
    }
    //  验证交互者是否是合约主人
    modifier is_owner(address owner) {
        require (isOwner[owner],"你不是合约所有者");
        _;
    }
    //  验证事务ID是否存在
    modifier transactionExists(uint transactionId) {
        require(transactions[transactionId].destination != 0,"交易事务不存在");
        _;
    }
    //  是否对这个ID的事务签过字
    modifier notConfirmed(uint transactionId, address owner) {
        require(!confirmations[transactionId][owner],"你已经签过了");
        _;
    }

    /// 契约构造函数设置初始所有者和所需的确认数量。
    /// _owners 初始所有者列表
    /// _required 需要确认签名的人数
    constructor(address[] _owners, uint _required) public validRequirement(_owners.length, _required) {
        for (uint i = 0; i < _owners.length; i++) {
            //Onwer应该是不同的，且非零
            require ( (!isOwner[_owners[i]]) || _owners[i] != address(0x0),"用户重复或地址为0");
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
    }
    function transderToContract() public payable{}// 用于Remix里调试转账
    function() public payable {}// 此合约的回退函数
    //  返回合约的所有主人
    function getOwners() public view returns (address[]) {return owners;}
    //  返回当前的交易号
    function getSpendNonce() public view returns (uint256) {return spendNonce;}
    //  返回合约的必要人数
    function getRequired() public view returns (uint) {return required;}
    
    //  提交一笔交易
    function submitTransaction(address destination, uint value, bytes data) public 
        onlyWallet()
        is_owner(msg.sender)
        returns (uint transactionId){
        transactionId = addTransaction(destination, value, data);
        confirmTransaction(transactionId);
    }
    //  如果事务还不存在，则将新事务添加到事务映射中。
    function addTransaction(address destination, uint value, bytes data) private returns (uint transactionId){
        transactionId = transactionCount;//等于已经+1后的事务id
        transactions[transactionId] = Transaction({//添加映射
            id:transactionCount,
            destination: destination,
            value: value,
            data: data,
            executed: false
        });
        transactionCount += 1;//事务id+1
        emit Submission(transactionId);
    }
    /// 允许所有者确认事务
    /// 参数-事务ID
    function confirmTransaction(uint transactionId) public
        onlyWallet()
        is_owner(msg.sender)
        transactionExists(transactionId)
        notConfirmed(transactionId, msg.sender)
    {
        confirmations[transactionId][msg.sender] = true;//设置为对这次事务已签过字
        emit Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
    }
    /// 此ID事务满足条件即触发
    /// 参数-事务ID
    function executeTransaction(uint transactionId) private {
        if (isConfirmed(transactionId)) {
            transactions[transactionId].executed = true;
            if (transactions[transactionId].destination.call.value(transactions[transactionId].value)(transactions[transactionId].data)){
                emit Execution(transactionId);
                spendNonce += 1;
            }else {
                emit ExecutionFailure(transactionId);
                transactions[transactionId].executed = false;
            }
        }
    }
    /// 返回事务的确认状态
    /// 参数-事务ID
    function isConfirmed(uint transactionId) public constant returns (bool){
        uint count = 0;
        for (uint i=0; i<owners.length; i++) {
            if (confirmations[transactionId][owners[i]])
                count += 1;
            if (count == required)
                return true;
        }
        return false;
    }
}