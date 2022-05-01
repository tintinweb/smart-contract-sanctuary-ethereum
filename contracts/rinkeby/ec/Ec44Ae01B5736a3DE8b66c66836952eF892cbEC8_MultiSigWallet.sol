/**
 *Submitted for verification at Etherscan.io on 2022-05-01
*/

//SPDX-License-Identifier:MIT

pragma solidity ^0.8.10;


interface IERC20{
    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function decimals() external view returns(uint8);
    function totalSupply() external view returns(uint256);
    function balanceOf(address _owner) external view returns(uint256 balance);
    function transfer(address _to,uint256 _value) external  returns(bool success);
    function transferFrom(address _from,address _to,uint256 _value) external returns(bool success);
    function approve(address _spender,uint256 _value) external returns(bool success);
    function allowance(address _owner,address _spender) external view returns(uint256 remaining);

    event Transfer(address indexed _from,address indexed _to,uint256 _value);
    event Approval(address indexed _owner,address indexed _spender,uint256 _value);
} 

contract MultiSigWallet{
    //充值 触发事件
    event Deposit(address indexed sender, uint amount);
    //提交 提款申请
    event Submit(uint indexed txId);
    //授权批准
    event Approve(address indexed owner, uint indexed txId);
    //取消 提款
    event Revoke(address indexed owner, uint indexed txId);
    //执行 提款
    event Execute(uint indexed txId);
    // 提款转入地址，数量 ，是否执行了
    struct Transaction{
        address payable to;  //提款地址
        uint  value;         //提款数量
        bool executed;       //是否执行提款了
        bool istoken;        //是否是token  false-主币  
        address token;       //代币token
    }
    //可以提请 授权 和提款申请的 地址
    address [] public owners;
    //  此地址是否有权限 提款和 授权批准
    mapping (address => bool) public isOwner;
    //需要 多少人确认了 执行提款交易
    uint public required;  
    Transaction [] public transactions;  //交易数组

    struct StructListWeb{
        uint txid;
        string symbol;
        address token;
        address to;
        bool istoken;
        uint approves;
    }
    //一条交易 的地址  是否已经批准了
    mapping (uint => mapping (address => bool)) public approved;

    modifier onlyOwner(){
        require(isOwner[msg.sender],"not owner");
        _;
    }
    //交易是否存在
    modifier txExists(uint _txId){
        require(_txId < transactions.length, " tx is not exist");
        _;
    }
    //此交易ID 是否被发起者 已经批准
    modifier notApproved(uint _txId){
        require(!approved[_txId][msg.sender], "tx already approved");
        _;
    }
    //此交易  是否已经执行了
    modifier notExecuted(uint _txId){
        require(!transactions[_txId].executed,"tx already executed");
        _;
    }
    constructor(address [] memory _owners, uint _required) payable{
        require(_owners.length > 0, "owners must be >0");
        require(_required > 0 && _required <= _owners.length ," invalid required number of owners");
        for(uint i = 0; i<_owners.length ;i++){
            address owner = _owners[i];
            require(owner != address(0) ," not address");  //不能是0地址
            require(!isOwner[owner], "owner is ready");  //已经存在地址
            isOwner[owner] = true;
            owners.push(owner);  
        }
        required = _required;
    }
    receive() external payable{
        emit Deposit(msg.sender, msg.value);
    }
    //发起 申请 一笔 提款
    function submit(address payable _to, uint _value, address _token, bool _istoken) external onlyOwner {
             if(transactions.length>0){
                require(transactions[transactions.length-1].executed," shoud be  approved");
             }
            if(_istoken){
                require(IERC20(_token).balanceOf(address(this)) >= _value , "Not Enough");
            }
            else{
                require(address(this).balance >=  _value,"Not Enough");
            }
            transactions.push(Transaction({
                to:_to,
                value:_value,
                executed:false,
                istoken:_istoken,
                token:_token
            }));
            emit Submit(transactions.length - 1);
            Approved(transactions.length - 1);   //谁增加的 自动批准
    }
    //批准 一笔 提款
    function Approved(uint _txId) public onlyOwner txExists(_txId) notApproved(_txId) notExecuted(_txId){
        approved[_txId][msg.sender] = true;
        emit Approve(msg.sender, _txId);
        if(_getApproveCount(_txId) >= required){
            doExecute(_txId);   //最后一个批准自动执行
        }

    }
    //返回 每笔提款 有多少 批准了
    function _getApproveCount(uint _txId) private view returns(uint count){
        for(uint i = 0; i<owners.length;i++){
            if(approved[_txId][owners[i]]){
                count += 1;
            }
        }
    }
    //执行 提款操作
    function doExecute(uint _txId) public onlyOwner txExists(_txId) notExecuted(_txId){
            require(_getApproveCount(_txId) >= required ," approvals < required");
            Transaction storage transaction = transactions[_txId];
            transaction.executed = true;
            if(transaction.istoken){
               bool isdo = IERC20(transaction.token).transfer(transaction.to,transaction.value);
               if(isdo){
                    emit Execute(_txId); 
               }
               else{
                   require(false ," erc20 transfer error");
               }
            }
            else{
                transaction.to.transfer(transaction.value);
                emit Execute(_txId);
            }   
    }
    //撤销 批准
    function doRevoke(uint _txId) external onlyOwner txExists(_txId) notExecuted(_txId) { 
        require(approved[_txId][msg.sender],"tx Not approved");
        approved[_txId][msg.sender] = false;
        emit Revoke(msg.sender,_txId);
    }
    //返回代币的 精度 多少个0
    function getTokenDecimals(address _token) view public returns(uint decimals){
        decimals = (10 ** IERC20(_token).decimals());
    }
    //返回 代币简称
    function getTokenName(address _token) view public returns(string memory symbol){
        symbol = IERC20(_token).symbol();
    }
    //返回 合约 代币的数量
    function getTokenBalanceOf(address _token) view external returns(uint balances){
        balances = IERC20(_token).balanceOf(address(this));
    }
    //返回主币的 精度
    function getMainDecimals() pure public returns(uint256 decimals){
        decimals = (10 ** 18);
    }
    function getLastTransactionInfo() view external returns(
        uint txId_,
        address to_,
        uint value_,
        bool istoken_,
        address token_,
        uint approves_,
        bool executed_,
        bool thisapprove_
    ){
            require(transactions.length > 0 ," no transactions");
            Transaction memory ts =  transactions[transactions.length-1];
            txId_= (transactions.length-1);
            to_ = ts.to;
            value_ = ts.value;
            istoken_ = ts.istoken;
            token_ = ts.token;
            approves_ = _getApproveCount(txId_);
            executed_ = ts.executed;
            thisapprove_ = approved[txId_][msg.sender];

    }
    
    


}