/**
 *Submitted for verification at Etherscan.io on 2022-05-27
*/

// SPDX-License-Identifier:MIT
pragma solidity ^0.8.7;

contract MultiSigWallet {
    event Deposit(address indexed sender, uint amount);
    // 提交交易申请
    event Submit(uint indexed txId);
    // 由合约签名人批准
    event Approve(address indexed owner, uint indexed txId);
    // 撤销批准
    event Revoke(address indexed owner, uint indexed txId);
    // 执行
    event Execute(uint indexed txId);

    // 交易的结构体:保存这每一次对外发出ETH的交易数据
    struct Transaction { 
        address  to; // 交易发送的目标地址
        uint value; // 交易发送的ETH数量
        bytes data; // data意味着如果目标地址是合约地址,可以执行合约中的一些函数
        bool executed; // 交易是否执行成功
    }

    address[] public owners; // 签名人数组
    mapping(address => bool) public isOwner; // 通过映射查询某个地址是不是合约的签名人
    uint public required; // 确认数:满足确认数的签名人同意

    // 用数组记录合约中所有的交易,索引值就是交易的ID号
    Transaction[] public transactions;
    // 二重映射,表示交易ID之下,某个签名人的地址是否批准了这交易
    mapping(uint => mapping(address => bool)) public approved; 

    // 修改器:判断当前消息发送者是不是签名人数组中的一个成员
    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    // 修改器:判断交易ID是否存在
    modifier txExists(uint _txId) {
        require(_txId < transactions.length, "tx does not exist");
        _;
    }

    // 修改器: 判断当前消息的调用者没有批准过这次交易id
    modifier notApproved(uint _txId) {
        require(!approved[_txId][msg.sender], "tx already approved");
        _;
    }

    // 修改器: 判断这个交易id没有被执行过
    modifier notExecuted(uint _txId) {
        require(transactions[_txId].executed, "tx already executed");
        _;
    }

    // 构造函数中传入合约所有的签名人的地址和最小的确认数
    constructor(address[] memory _owners, uint _required) {
        require(_owners.length > 0, "owners required");
        require(_required >0 && _required <= _owners.length,
        "invalid required number of owners"
    );

    // 判断签名人数组owners中所有的地址都是有效地址(不是0地址,且不是已添加过的地址)
    for (uint i; i < _owners.length; i++){
        address owner = _owners[i];

        require(owner != address(0), "invalid owner");
        require(!isOwner[owner], "owner is not unique");

        isOwner[owner] = true;
        owners.push(owner); // 将局部变量的地址push到签名人数组中
    }

    required = _required; // 把确认数从输入变量出入到状态变量中
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value); // 记录发送者,和收款数量
    }

    // 提交交易的函数:只能由签名人提交
    function sumbit(address _to, uint _value, bytes calldata _data)
        external 
        onlyOwner
        {
            transactions.push(Transaction({
                to : _to,
                value: _value,
                data: _data,
                executed: false
            }));
            emit Submit(transactions.length - 1);
        } 

    // 批准的函数:当一个签名人提交了一次交易,由其他签名人对这次交易进行批准
    function approve(uint _txId) 
        external 
        onlyOwner 
        txExists(_txId) 
        notApproved(_txId)
        notExecuted(_txId)
    {
            approved[_txId][msg.sender] = true;
            emit Approve(msg.sender, _txId);
    }

    // 内部函数:计算某个交易id下面的签名人有多少个批准了,方便后面其他函数去使用
    // 遍历签名人数组,查询队形的交易id中,签名人是否批准了
    function _getApprovalCount(uint _txId) private view returns (uint count) {
        for (uint i; i < owners.length; i++) {
            if (approved[_txId][owners[i]]) {
                count += 1;
            }
        }
    }

    // 执行函数:当一个交易id的批准人数达到了最小确认数,就以运行执行方法
    function exeute(uint _txId) external txExists(_txId) notExecuted(_txId) {
        require(_getApprovalCount(_txId) >= required, "approvals < required");
        Transaction storage transaction = transactions[_txId]; // 把交易的结构体读取出来,用storage指针来改里面的数据

        transaction.executed = true; // 将交易结构体中的已执行修改为true,这样这笔交易就不能被再次执行了

        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        require(success, "tx failed");

        emit Execute(_txId);
    }
    // 撤销函数:允许签名人在交易没被执行之前撤销批准
    function revoke(uint _txId) 
        external 
        onlyOwner 
        txExists(_txId) 
        notExecuted(_txId) 
    {
        require(approved[_txId][msg.sender], "tx not approved");
        approved[_txId][msg.sender] = false; // approved改为false,表示撤销了批准
        emit Revoke(msg.sender, _txId);
    }
}