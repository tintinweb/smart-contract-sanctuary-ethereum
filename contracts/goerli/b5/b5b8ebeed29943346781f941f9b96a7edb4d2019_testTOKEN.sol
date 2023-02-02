/**
 *Submitted for verification at Etherscan.io on 2023-02-02
*/

// SPDX-License-Identifier: 9skin
pragma solidity >=0.4.16 <0.7.0;
// import "hardhat/console.sol";

interface IERC20 {  //ERC20标准
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256); 

    function allowance(address owner, address spender) external view returns (uint256); 

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 indexed value); 

    event Approval(address indexed sender, address indexed spender, uint256 value);
}

contract testTOKEN is IERC20 {
    string private name = "testTOKEN"; // 代幣名称
    string private symbol = "TWDT";  // 代幣簡稱
    uint8 private decimals = 0;  // 代幣数量的小数点位数

    address private CrossChain_bridge; //跨鏈橋地址，用於跨鍊時鑄幣

    uint256 private _totalSupply;
    address private _admin;
    address private _exchange;
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) public allowed; 

    constructor(uint256 initialSupply, address Cross_Bridge, address Exchange) public {
        //設定幣擁有者
        _admin = msg.sender;
        //設定交易所
        _exchange = Exchange;
        //設定代幣總數
        _totalSupply = initialSupply;
        // 创建者拥有所有代币 
        // 若為替代幣數量應為0
        balances[msg.sender] = _totalSupply * 10**uint256(decimals);
        // 跨鏈橋合約地址
        CrossChain_bridge = Cross_Bridge;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {   //轉帳
        require(balances[msg.sender] >= amount, "token balance too low"); 
        balances[msg.sender] -= amount;
        balances[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool){   //從誰轉給誰
        uint256 allowance = allowed[sender][msg.sender];
        require(allowance >= amount,"allowance too low");  //判斷可被使用的金額是否超過
        require(balances[sender]>=amount,"token balance too low");   //判斷可用餘額夠不夠
        allowed[sender][msg.sender] -= amount;
        balances[sender] -= amount;
        balances[recipient] += amount;
        emit Transfer(sender,recipient,amount);// 抛出事件日志
        return true;
    }

    function business(address recipient, uint amount) public returns (bool) {  //皆由交易所控制轉帳，只有交易所可呼叫此function
        //皆為交易所控制，msg.sender必須為交易所，只有交易所可以發起轉帳
        approve(msg.sender, amount);  //授權可用金額
        transferFrom(msg.sender, recipient, amount);  //轉出'amount個'的幣

        return true;
    } 

    function approve (address spender, uint256 amount ) public override returns (bool) {    //授權可用金額，只有交易所可呼叫此function
        require(balances[msg.sender]>=amount,"token balances too low");
        allowed[_exchange][spender] = amount;
        emit Approval(msg.sender,spender,amount);
        return true;
    }

    // function birdge_approve (address spender, uint256 amount ) public only_brdige returns (bool) {  //授權跨鏈橋可用金額（同approve）只有跨鏈橋可呼叫此function
    //     require(balances[msg.sender]>=amount,"token balances too low");
    //     allowed[_exchange][spender] = amount;
    //     emit Approval(msg.sender,spender,amount);
    //     return true;
    // }

    function Bridge_business(address to, uint amount) public only_brdige returns (bool) {

        approve(msg.sender, amount);  //讓跨鏈橋可以使用amount個幣(原function已經寫死，跨鏈所需判斷條件不相同)
        cross_transfer(to, amount);   //轉帳到指定地址(to)，直接從橋轉出去
        return true;
    }

    function cross_transfer(address to, uint256 value) public only_brdige returns (bool) { //僅跨鏈橋地址可以呼叫此函數
        mine(value);  // 鑄幣
        transfer(to,value);  //把幣轉給指定地址
        return true;
    }

    function mine( uint256 value) internal returns (bool){   //鑄幣function，僅用於跨鏈時鑄造
        _totalSupply += value;
        balances[msg.sender] += value;
        return true;
    }

    function burnt ( uint256 value ) public returns (bool) {  //燒毀代幣
        require(balances[msg.sender] >=value);
        balances[msg.sender] -= value;
        _totalSupply -= value;
        return true;
    }

    function allowance (address owner, address spender) public override view returns (uint256){
        return allowed[owner][spender];
    }

    function balanceOf(address account) public override view returns (uint256) {
        return balances[account];
    }

    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    modifier only_brdige() {  //判斷跨鏈橋地址是否符合
        require ( msg.sender == CrossChain_bridge,"Only KB_CrossChain_Bridge can call this function.");
        _;
    }

    modifier only_owner() {  //判斷擁有者（鑄幣者）地址是否符合
        require ( msg.sender == _admin, "Only admin can call this function.");
        _;
    }

    modifier only_exchange() {  //判斷交易所地址是否符合
        require ( msg.sender == _exchange, "Only Exchange can call this function.");
        _;
    }
}