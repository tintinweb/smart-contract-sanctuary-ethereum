/**
 *Submitted for verification at Etherscan.io on 2022-10-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract SafeMath {
    
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
    function safeMod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface ERC20Interface {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function transferinternal(address from, address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


interface ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) external;
}


contract Owned {
    address public owner;
    address public newOwner;
    event OwnershipTransferred(address indexed _from, address indexed _to);
    constructor()  {
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner,"Only Owner");
        _;
    }
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0),"address(0) not allowed");
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner,"Allowed only for new owner");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
    function renounceOwnership() public {
        require(msg.sender == owner,"Only Owner");
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
        newOwner = address(0);
    }
}
interface IHoldingContract {
    function initiate(address,uint256) external returns (bool);
    function getBalance() external view returns(uint);
    function getMainContract() external view returns(address);
    function withdrawfunds() external ; 
    event HoldBonus(address , uint);
    function transferAnyERC20Token(address, uint) external  returns (bool) ;
}

contract HoldingContract is IHoldingContract {
     
    address public MAINCONTRACT;
    constructor() {
        MAINCONTRACT = msg.sender;
    }
    function initiate(address receiver,uint256 tokens) external returns (bool success) {
        require(msg.sender == MAINCONTRACT, "Forbidden");
        uint balance = ERC20Interface(MAINCONTRACT).balanceOf(address(this));
        if(balance<tokens) return false;
        if(receiver == address(0)) return false;
        if(receiver == 0x000000000000000000000000000000000000dEaD) return false;
           return ERC20Interface(MAINCONTRACT).transferinternal(address(this),receiver, tokens);
    }
    function getBalance() external view returns(uint) {
        return ERC20Interface(MAINCONTRACT).balanceOf(address(this));
    }
    function getMainContract() public view returns(address) {
        return MAINCONTRACT;
    }
    function withdrawfunds() external  {
        payable(getMainContract()).transfer(address(this).balance);
    }
    function transferAnyERC20Token(address _tokenAddress, uint tokens) external  returns (bool) {
        require(_tokenAddress != MAINCONTRACT,  "Self contract funds cannot be withdrawn");
        return ERC20Interface(_tokenAddress).transfer(MAINCONTRACT, tokens);
    }
}

contract CleverMinu is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    uint256 public IMO_BURNRATIO = 100;
    uint256 public USER_BURNRATIO = 1;
    uint256 public HOLDING_BONUSRATIO = 1; //divided by 10000 resulting 0.01% 
    uint256 public MAX_TXN_AMOUNT;
    address public Holding_CONTRACT;
    address public ContractAddress;
    uint256 public TotalReferralSent=0;
    mapping(address => uint) balances;
    mapping(address => uint256) public lastDepositTIme;
    mapping(address => mapping(address => uint)) allowed;
    mapping(address => bool) private _whitelisted;
    uint256 public IMOENDTIME=0;
    
    constructor() {
        symbol = "CLEVERMINU";
        name = "Clever Minu";
        decimals = 9;
        _totalSupply = safeMul(1000000000000 , 10**9);
        MAX_TXN_AMOUNT= safeMul(1000000000 , 10**9);
        Holding_CONTRACT = address(new HoldingContract());
        addtoWhiteList(msg.sender);
        addtoWhiteList(0x000000000000000000000000000000000000dEaD);
        addtoWhiteList(address(0));
        addtoWhiteList(Holding_CONTRACT);
    }
    function init(uint256 _imoenddate) external onlyOwner 
    {
        require(IMOENDTIME==0,"Already Initiated");
        require(_imoenddate>=getBlocktimestamp(),"End time cannot be old time");
        IMOENDTIME=_imoenddate;
        balances[address(this)] = _totalSupply;
        emit Transfer(address(0), address(this), _totalSupply);
        ContractAddress=address(this);
        addtoWhiteList(address(this));
    }
    function totalSupply() public view returns (uint) {
        return safeSub(safeSub(_totalSupply , balances[address(0)]) , balances[0x000000000000000000000000000000000000dEaD]);
    }
    function IMOsale(address to, uint amount) external returns (bool success)
    {
        require(isWhitelisted(msg.sender) , "Transfer is allowed for trusted users only");
        require(IMOENDTIME >= block.timestamp,"IMO completed");
        require(amount <= MAX_TXN_AMOUNT,"Max limit reached");
        require( getmybalance() >=  safeAdd(getburntokencount(amount),amount) , "Tokens not enough");
        bool _status=ERC20Interface(address(this)).transfer(to, amount);
        if(IMO_BURNRATIO>0)
            ERC20Interface(address(this)).transfer(0x000000000000000000000000000000000000dEaD, getburntokencount(amount));
        return _status;
    }
    function IMOreferral(address to, uint amount) external returns (bool success)
    {
        require(isWhitelisted(msg.sender) , "Transfer is allowed for trusted users only");
        require(IMOENDTIME >= block.timestamp,"IMO completed");
        require(amount <= MAX_TXN_AMOUNT,"Max limit reached");
        require(getmybalance() >=  amount , "Tokens not enough");
        TotalReferralSent= safeAdd(TotalReferralSent,amount);
        bool _status=ERC20Interface(address(this)).transferinternal(address(this),to, amount);
        return _status;
    }
    function getmybalance() public view returns (uint balance) {
        return balances[address(this)];
    }
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }
    function getTotalReferralsent() external view returns (uint256 balance)
    {
        return TotalReferralSent;
    }
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    function approveAndCall(address spender, uint tokens, bytes memory data) external returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }
    function isWhitelisted(address account) public view returns (bool) {
        return _whitelisted[account];
    }
    function addtoWhiteList(address account) public onlyOwner {
      _whitelisted[account] = true;
    }
    function removefromWhiteList(address account) external onlyOwner {
      _whitelisted[account] = false;
    }
    function approve(address spender, uint tokens) public returns (bool success) {
        require( (block.timestamp > IMOENDTIME) || (isWhitelisted(spender)) , "Approve Allowed for whitelisted accounts");
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    function transfer(address to, uint tokens) public returns (bool success)
    {
        require( (block.timestamp > IMOENDTIME) || (isWhitelisted(to)) || (isWhitelisted(msg.sender)), "Transfer is disabled until IMO complete");
        if( (block.timestamp < IMOENDTIME) )
        {
            balances[msg.sender] = safeSub(balances[msg.sender], tokens);
            balances[to] = safeAdd(balances[to], tokens);
            emit Transfer(msg.sender, to,tokens);
        }
        else
        {
            if((msg.sender != to))
            {
                creditholdingbonus(msg.sender);
                creditholdingbonus(to);
            }
            else
            {
                creditholdingbonus(msg.sender);
            }
            balances[msg.sender] = safeSub(balances[msg.sender], tokens);
            uint256 _amount=safeDiv(safeMul(tokens,safeSub(100,USER_BURNRATIO)),100);
            balances[to] = safeAdd(balances[to], _amount);
            balances[Holding_CONTRACT] = safeAdd(balances[Holding_CONTRACT], safeSub(tokens,_amount));
            emit Transfer(msg.sender, to, _amount);
            emit Transfer(msg.sender, Holding_CONTRACT, safeSub(tokens,_amount));
        }
        return true;
    }
    function creditholdingbonus(address _address) internal
    {
        if( (_address == ContractAddress) || (_address == 0x000000000000000000000000000000000000dEaD) || (_address == 0x0000000000000000000000000000000000000000))
        {
            // no bonus for contract address , dead and address(0)
        }
        else if(safeSub(block.timestamp ,lastDepositTIme[_address]) < 3600 )
        {
            // no bonus if transaction is done in less than 1 hour
        }
        else if(lastDepositTIme[_address]>0)
        {
            uint256 _holdingbonus= safeDiv(safeMul(safeMul(uint256(safeSub(block.timestamp , lastDepositTIme[_address])),balances[_address]),HOLDING_BONUSRATIO),safeMul(safeMul(3600,24),10000));
            if((_holdingbonus <= balances[Holding_CONTRACT]) && (_holdingbonus>0) )
            {
                IHoldingContract(Holding_CONTRACT).initiate(_address,_holdingbonus);
            }
        }
        lastDepositTIme[_address]=block.timestamp;
    }
    function transferinternal(address from, address to, uint256 amount ) public returns (bool success)
    {
        require((msg.sender == Holding_CONTRACT) || (msg.sender == ContractAddress) , "only owner");
        balances[from] = safeSub(balances[from], amount);
        balances[to] = safeAdd(balances[to], amount);
        emit Transfer(from, to, amount);
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
            address owner = msg.sender;
            uint256 currentAllowance = allowance(owner, spender);
            require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
            unchecked {
                _approve(owner, spender, currentAllowance - subtractedValue);
            }
            return true;
    }
    function _approve(address owner,address spender,uint256 amount ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        allowed[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function transferFrom(address from, address to, uint tokens) public returns (bool success)
    {
        require( (block.timestamp > IMOENDTIME) || (isWhitelisted(from)) || (isWhitelisted(to)) || (isWhitelisted(msg.sender)), "Transfer is disabled until IMO complete");
        if( (block.timestamp < IMOENDTIME) )
        {
            allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
            balances[from] = safeSub(balances[from], tokens);
            balances[to] = safeAdd(balances[to], tokens);
            emit Transfer(from, to, tokens);
        }
        else
        {
            allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
            balances[from] = safeSub(balances[from], tokens);
            uint256 _amount=safeDiv(safeMul(tokens,safeSub(100,USER_BURNRATIO)),100);
            balances[to] = safeAdd(balances[to], _amount);
            balances[Holding_CONTRACT] = safeAdd(balances[Holding_CONTRACT], safeSub(tokens,_amount));
            if((msg.sender != to) && (from != to))
            {
                creditholdingbonus(msg.sender);
                creditholdingbonus(from);
                creditholdingbonus(to);
            }
            else if((msg.sender == to) && (msg.sender != from))
            {
                creditholdingbonus(msg.sender);
                creditholdingbonus(from);
            }
            else if((msg.sender != to) && (msg.sender == from))
            {
                creditholdingbonus(msg.sender);
                creditholdingbonus(to);
            }
            else if((msg.sender == from) && (msg.sender == to))
            {
                creditholdingbonus(msg.sender);
            }
            emit Transfer(from, to, _amount);
            emit Transfer(from, Holding_CONTRACT, safeSub(tokens,_amount));
        }
        return true;        
    }
    function transferAnyERC20Token(address _tokenAddress, uint tokens) external onlyOwner returns (bool success) {
        require(_tokenAddress != ContractAddress,  "Self contract funds cannot be withdran");
        return ERC20Interface(_tokenAddress).transfer(owner, tokens);
    }
    function transferetherAdmin() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
    function transferAnyERC20HoldingToken(address _tokenAddress, uint tokens) external returns (bool success) {
        require(_tokenAddress != ContractAddress,  "Self contract funds cannot be withdran");
        return IHoldingContract(Holding_CONTRACT).transferAnyERC20Token(_tokenAddress,tokens);
    }
    function transferetherHoldingContract() external onlyOwner {
        IHoldingContract(Holding_CONTRACT).withdrawfunds();
    }
    function BurnRemainingTokens() public onlyOwner returns (bool success) {
        require(IMOENDTIME < block.timestamp,"IMO completed");
        balances[ContractAddress] = safeSub(balances[ContractAddress], balances[ContractAddress]);
        balances[0x000000000000000000000000000000000000dEaD] = safeAdd(balances[0x000000000000000000000000000000000000dEaD], balances[ContractAddress]);
        emit Transfer(ContractAddress, 0x000000000000000000000000000000000000dEaD, balances[ContractAddress]);
        return true;
    }
    function setIMOendTime( uint256 time) external onlyOwner {
        require(time>=getBlocktimestamp(),"End time cannot be old time");
        IMOENDTIME=time;
    }
    function setMAXamount( uint256 _amount) external onlyOwner {
        require(_amount<=totalSupply(),"Amount exceed total supply");
        MAX_TXN_AMOUNT=_amount;
    }
    function getburntokencount(uint amount) public view returns (uint balance) {
        return safeDiv(safeMul(amount,IMO_BURNRATIO),100);
    }
    /////////////
    // _debug method
    /////////////
    function getBlockCount() public view returns (uint balance) {
        return block.number;
    }
    function getBlocktimestamp() public view returns (uint balance) {
        return block.timestamp;
    }
}