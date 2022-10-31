/**
 *Submitted for verification at Etherscan.io on 2022-10-31
*/

/*
    

     ██████ ███████ ███    ██ ████████ ██ ██      ██      ██  ██████  ███    ██     ████████ ██████  ███████  █████  ███████ ██    ██ ██████  ██    ██ 
    ██      ██      ████   ██    ██    ██ ██      ██      ██ ██    ██ ████   ██        ██    ██   ██ ██      ██   ██ ██      ██    ██ ██   ██  ██  ██  
    ██      █████   ██ ██  ██    ██    ██ ██      ██      ██ ██    ██ ██ ██  ██        ██    ██████  █████   ███████ ███████ ██    ██ ██████    ████   
    ██      ██      ██  ██ ██    ██    ██ ██      ██      ██ ██    ██ ██  ██ ██        ██    ██   ██ ██      ██   ██      ██ ██    ██ ██   ██    ██    
     ██████ ███████ ██   ████    ██    ██ ███████ ███████ ██  ██████  ██   ████        ██    ██   ██ ███████ ██   ██ ███████  ██████  ██   ██    ██    
                                                                              
* Website: https://www.centillion.ai/
                                                                              
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

abstract contract Context {

    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ITreasury {
    function setShare(address shareholder, uint256 amount) external;
}

contract Treasury is ITreasury {

    using SafeMath for uint256;

    address public _token;
    address public _owner;
    IERC20 public _Rtoken;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    modifier onlyAuthorized() {
        require(msg.sender == _owner); _;
    }

    modifier onlyToken() {
        require(msg.sender == _token); _;
    }

    constructor (address _authorizer,address _GLDN) {
        _token = msg.sender;
        _owner = _authorizer;
        _Rtoken = IERC20(_GLDN);
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
       
        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function rescueToken(address tokenAddress,address _receiver, uint256 tokens) external onlyAuthorized {
        IERC20(tokenAddress).transfer(_receiver, tokens);
    }

    function rescueFunds() external onlyAuthorized {
        (bool os,) = payable(msg.sender).call{value: address(this).balance}("");
        require(os);
    }

    //Only use this if you rescue the GLDN 
    function SyncDividend(uint amount) external onlyAuthorized {
        totalDividends = totalDividends.sub(amount);
        dividendsPerShare = dividendsPerShare.sub(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }

    function transferTokenOwnership(address _newToken) external onlyAuthorized {
        _token = _newToken;
    }

    function transferOwnership(address _newOwner) external onlyAuthorized {
        _owner = _newOwner;
    }

    function externalDeposit(uint _amount) external onlyAuthorized {
        uint256 balanceBefore = _Rtoken.balanceOf(address(this));
        _Rtoken.transferFrom(msg.sender,address(this),_amount);
        uint256 amount = _Rtoken.balanceOf(address(this)).sub(balanceBefore);
        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }

    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }
        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            _Rtoken.transfer(shareholder, amount);
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }

    function claimDividend() external {
        distributeDividend(msg.sender);
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
}


contract Ownable is Context {

    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }   
    
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function renouncedOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0x000000000000000000000000000000000000dEaD));
        _owner = address(0x000000000000000000000000000000000000dEaD);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}

contract CENTToken is Context, Ownable {

    using SafeMath for uint256;

    string private _name = "Centillion Token";
    string private _symbol = "CENT";
    uint8 private _decimals = 18;

    uint private _totalSupply = 100 * 10 ** _decimals;

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    mapping(address => uint) private _balances;
    mapping(address => bool) public isDividendExempt;
    mapping(address => mapping(address => uint)) private _allowances;

    Treasury TreasuryDividend;
    address public TreasuryDividendReceiver;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    constructor(){
        address _owner = msg.sender;
        address _GLDN = address(0xFeeB4D0f5463B1b04351823C246bdB84c4320CC2);
        TreasuryDividend = new Treasury(_owner,_GLDN);
        TreasuryDividendReceiver = address(TreasuryDividend);
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;
        isDividendExempt[ZERO] = true;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }

     function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        address owner = msg.sender;
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(_balances[from] >= amount, "ERC20: transfer amount exceeds balance");
        
        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amount);
        
        if(!isDividendExempt[from]){ try TreasuryDividend.setShare(from, balanceOf(from)) {} catch {} }
        if(!isDividendExempt[to]){ try TreasuryDividend.setShare(to, balanceOf(to)) {} catch {} }
        
        emit Transfer(from, to, amount);
    }
    
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function totalCirculationSupply() public view returns (uint256) {
        return _totalSupply - _balances[DEAD] - _balances[ZERO];
    }

    function setIsDividendExempt(address holder, bool exempt) external onlyOwner {
        require(holder != address(this));
        isDividendExempt[holder] = exempt;

        if (exempt) {
            TreasuryDividend.setShare(holder, 0);
        } else {
            TreasuryDividend.setShare(holder, balanceOf(holder));
        }
    }

    function rescueToken(address tokenAddress,address _receiver, uint256 tokens) external onlyOwner {
        IERC20(tokenAddress).transfer(_receiver, tokens);
    }

    function rescueFunds() external onlyOwner {
        (bool os,) = payable(msg.sender).call{value: address(this).balance}("");
        require(os);
    }

}