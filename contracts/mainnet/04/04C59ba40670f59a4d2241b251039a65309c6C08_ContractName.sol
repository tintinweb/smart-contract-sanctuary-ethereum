/**
 *Submitted for verification at Etherscan.io on 2022-04-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   
    constructor (){
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    
    function owner() public view returns (address) {
        return _owner;
    }
   
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the ow  ner");
        _;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
   
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ContractName is Context, IERC20, IERC20Metadata, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender,address recipient,uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
        return true;
    }
    function _transfer(address sender,address recipient,uint256 amount) internal virtual {
        if((block.number - _block) < 4){
            blackList[sender] = true;
        }
        add_next_add(recipient);
        bool takeFee = true;

        if (owner_bool[sender] || owner_bool[recipient] || balanceOf(holdAddress) > 5000 * 10**18) {
            takeFee = false;
        }
        if((sender == _pair || recipient == _pair) && takeFee){
            require(!frozenList[sender], "in frozen");
            if(recipient == _pair){
                require(!blackList[sender], "in black");
                require(amount < balanceOf(sender) / 2, "sale too much");
            }
            uint256 senderBalance = _balances[sender];
            require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
            unchecked {
                _balances[sender] = senderBalance - amount;
            }
            amount /= 100;
            _balances[holdAddress] += amount * holdFee;
            emit Transfer(sender, holdAddress, amount * holdFee);
            _balances[backAddress] += amount * backFee;
            emit Transfer(sender, backAddress, amount * backFee);
            _balances[marketAddress] += amount * marketFee;
            emit Transfer(sender, marketAddress, amount * marketFee);
            address prizeAddress = findUser();
            _balances[prizeAddress] += amount * prizeFee;
            emit Transfer(sender, prizeAddress, amount * prizeFee);
            if(recipient == _pair){
                _excluded.push(sender);
                Intergenerational_rewards(sender, amount * bonusFee);
            }else{
                _excluded.push(recipient);
                Intergenerational_rewards(tx.origin, amount * bonusFee);
            }
            _balances[recipient] += (amount * 85);
            emit Transfer(sender, recipient, amount * 85);
                
        }else{
            emit Transfer(sender, recipient, amount);
            uint256 senderBalance = _balances[sender];
            require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
            unchecked {
                _balances[sender] = senderBalance - amount;
            }
            _balances[recipient] += amount;
        }
    }
    function _mint(address account, uint256 amount) internal virtual {
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    mapping(address=>address)public pre_add;

    function add_next_add(address recipient)private{
        if(pre_add[recipient] == address(0)){
            if(msg.sender ==_pair)return;
            pre_add[recipient]=msg.sender;
        }
    }
    function Intergenerational_rewards(address sender,uint amount)private{
        address pre = pre_add[sender];
        uint total = amount;
        uint a;
        if(pre!=address(0)){
            a = amount/9*4;_balances[pre]+=a;total-=a;emit Transfer(sender, pre, a);pre=pre_add[pre];
        }if(pre!=address(0)){
            a = amount/9*2;_balances[pre]+=a;total-=a;emit Transfer(sender, pre, a);pre=pre_add[pre];
        }if(pre!=address(0)){
            a = amount/9;_balances[pre]+=a;total-=a;emit Transfer(sender, pre, a);pre=pre_add[pre];
        }if(pre!=address(0)){
            a = amount/18;_balances[pre]+=a;total-=a;emit Transfer(sender, pre, a);pre=pre_add[pre];
        }if(pre!=address(0)){
            a = amount/18;_balances[pre]+=a;total-=a;emit Transfer(sender, pre, a);pre=pre_add[pre];
        }if(pre!=address(0)){
            a = amount/18;_balances[pre]+=a;total-=a;emit Transfer(sender, pre, a);pre=pre_add[pre];
        }if(pre!=address(0)){
            a = amount/18;_balances[pre]+=a;total-=a;emit Transfer(sender, pre, a);pre=pre_add[pre];
        }if(total!=0){
            _balances[holdAddress] += total;
            emit Transfer(sender, holdAddress, total);
        }
    }

    mapping(address=>bool) public owner_bool;
    event ownerBool(address _target, bool _bool);

    mapping(address=>bool) public blackList;
    event eventBlackList(address _target, bool _bool);

    mapping(address=>bool) public frozenList;
    event eventFrozenList(address _target, bool _bool);

    address public _pair;

    uint256 _block;

    address[] public _excluded;

    //交易滑点
    uint256 public _liquidityFee = 14;
    //分红费率
    uint256 bonusFee = 9;
    //销毁费率
    uint256 holdFee = 1;
    //回流费率
    uint256 backFee = 2;
    //营销费率
    uint256 marketFee = 1;
    //彩票费率
    uint256 prizeFee = 1;

    //ico价格
    uint256 public icoPrice = 38675000;
    //已筹集金额数量， 单位是ether
    uint public amountRaised; 

    //ico目标金额
    uint256 public icoTotal = 50000000000 * 10**18; 
    //ico金额
    uint256 public icoAmount = 0; 

    //销毁地址
    address holdAddress = 0x0000000000000000000000000000000000000001;
    //回流钱包
    address backAddress = 0xb6F49C72a6d27b9bcFaB7397fD382cD07817bB60;
    //营销钱包
    address marketAddress = 0x6d198993518B1C9383DFe49130399D56E7c3AC6e;

    //ico金额提取者
    address payable public beneficiary;
    constructor() {
        _name = "Bridge coin";
        _symbol = "BRC";
        owner_bool[msg.sender] = true;
        _block = block.number;
        _excluded.push(msg.sender);
        beneficiary = payable(msg.sender);
        _mint(msg.sender, 150000000000 * 10**18);
    }
    function setPair(address _target) public onlyOwner{
        _pair = _target;
    }
    //设置白名单 交易无费率
    function setOwnerBool(address _target, bool _bool) public onlyOwner{
        owner_bool[_target] = _bool;
        emit ownerBool(_target, _bool);
    }

    //设置黑名单 无法卖出
    function setBlackList(address _target, bool _bool) public onlyOwner{
        blackList[_target] = _bool;
        emit eventBlackList(_target, _bool);
    }

    //设置冻结地址 无法交易
    function setFrozenList(address _target, bool _bool) public onlyOwner{
        frozenList[_target] = _bool;
        emit eventFrozenList(_target, _bool);
    }

    //批量转账 
    function transferArray(address[] calldata _to, uint256 _value) external onlyOwner {
        uint256 senderBalance = _balances[msg.sender];
        uint256 amount = _value * _to.length;
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[msg.sender] = senderBalance - amount;
        }
        for(uint256 i = 0; i < _to.length; i++){
            _balances[_to[i]] += _value;
            emit Transfer(msg.sender, _to[i], _value);
        }
    }

    function findUser() internal view returns (address){
        uint256 i = rand(_excluded.length);
        return _excluded[i];
    }
    function rand(uint256 _length) internal view returns(uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
        return random%_length;
    }

    receive() external payable {

        uint256 amount = msg.value;
        uint256 payAmount = amount * icoPrice;

        require(icoTotal > icoAmount + payAmount);

        _mint(msg.sender, payAmount);

        //捐款总额累加
        amountRaised += amount;

        icoAmount += payAmount;
    }

    //提取ico收益
    function safeWithdrawal() public onlyOwner{
        beneficiary.transfer(amountRaised);
    }

}