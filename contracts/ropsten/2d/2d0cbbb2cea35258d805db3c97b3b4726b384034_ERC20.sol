/**
 *Submitted for verification at Etherscan.io on 2022-08-01
*/

//date:2022/4/18
pragma solidity ^0.5.0;
/*
modifier onlyOwner {
        require(msg.sender == owner);
        _; // 標示哪裡會呼叫函式
}
*/
contract ERC20 {
    address public owner;// 公司address
    event Transfer(address indexed _from, address indexed _to, uint256 _value);//Transfer event , active it when the token is being transfer
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);//Approval event , active it when succesfully execute "approve" method 
    uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) private balances;//建立一個address映射到uint256類別balances,顯示該address帳戶餘額
    mapping (address => mapping (address => uint256)) private allowed;//建立一個address映射到address,uint256類別allowed,顯示該帳戶允許哪個帳戶操作他多少金額
    string private _name;// token name     
    string private _symbol;//token symbol
    uint8 private _decimal=0;//小數位為0
    //測試用 正式版應改為totalSupplyAmount=0
    uint256 private totalSupplyAmount=10000;//10000 tokens in total          
    ///////new/////////////////////////////////////////////////////////////////////
    mapping (uint256 => uint256)private service;

    constructor(string memory name_, string memory symbol_) public{//constructor
        _name = name_;
        _symbol = symbol_;
        owner=msg.sender;
        //測試用，正式版不該給公司帳號10000枚代幣
        balances[owner]=totalSupplyAmount;//將總共的10000沒tokens都給initial owner
        emit Transfer(address(0), owner, 10000);
    }

    function name()public view returns(string memory)//the function which returns token name
    {
        return _name;
    } 

    function symbol()public view returns(string memory)//the function which returns tokens symbol 
    {
        return _symbol;
    }

    function decimals()public view returns(uint8)//the function which returns the decimal (0)
    {
        return _decimal;
    }

    function totalSupply()public view returns(uint256)//the function which returns the total amount of tokens
    {
        return totalSupplyAmount;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {//the function transfer token from owner account to other account , if success ,return true.
        require(_to!=address(0),"recipient cannot be zero address");
        require(balances[msg.sender] >= _value);//確認使用者要匯出的tokens比他的有的tokens還要少
        balances[msg.sender] -= _value;//使用者原有的tokens數量-他要匯出的數量
        balances[_to] += _value;//接收者原有的tokens數量+他得到的數量
        emit Transfer(msg.sender, _to, _value); //trigger Transfer event
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {//the function transfer token from the account which allowed user to operate to other account, if success,return true
        require(_to!=address(0)&&_from!=address(0),"sender and recipient cannot be zero address");
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);//確認使用者要匯出的tokens比他的有的tokens還要少也同時比allowance還要少
        balances[_to] += _value;//接收者原有的tokens數量+他得到的數量
        balances[_from] -= _value;//tokenes original owner原有的tokens數量-他要匯出的數量
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;//將allowance減去匯出的數量
        }
        emit Transfer(_from, _to, _value); //trigger Transfer event
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {//the function returns the balances of user
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {//owner approve the other having right to operate _value tokens
        allowed[msg.sender][_spender] = _value;//allowance set up to _value
        emit Approval(msg.sender, _spender, _value); //trigger approval event
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {//input the owner and spender ,and the function will return the allowance
        return allowed[_owner][_spender];
    }

    function mint()public payable//ETH to Atrustek
    {
        require( msg.value >= 0.0001 ether, "0.0001 ETH");//TODO
        uint256 buyQuantity=msg.value/100000000000;
        balances[msg.sender]+=buyQuantity;
        totalSupplyAmount+=buyQuantity;
        emit Transfer(address(0),msg.sender,buyQuantity); 
    }
    function withDraw(uint256 _value) external returns(bool success)
    {
        require(balanceOf(msg.sender)>=_value,"not enough money");
        uint256 amount =_value*100000000000;//TODO
        totalSupplyAmount-=_value;
        balances[msg.sender]-=_value;
        emit Transfer(msg.sender, address(0), _value);
        msg.sender.transfer(amount);
        return true;
    }
    function setTheServicePrice(uint256 serviceId, uint256 price) external returns(bool success)
    {
        require(msg.sender==owner,"only Owner");
        service[serviceId]=price;
        return true;
    }
    function getTheServicePrice(uint256 serviceId)external view returns(uint256 price)
    {
        return service[serviceId];
    }
    function clientBuyService(uint256 serviceId)external returns(bool success)
    {
        uint256 servicePrice=service[serviceId];
        require(servicePrice>0,"service unset");//防止使用者購買尚未設定的服務
        require(balanceOf(msg.sender)>=servicePrice,"not enough money");
        balances[msg.sender] -= servicePrice;//使用者原有的tokens數量-他要匯出的數量
        balances[owner] += servicePrice;//接收者原有的tokens數量+他得到的數量
        emit Transfer(msg.sender,owner, servicePrice); //trigger Transfer event
        return true;
    }
}