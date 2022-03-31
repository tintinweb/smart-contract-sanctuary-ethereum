/**
 *Submitted for verification at Etherscan.io on 2022-03-30
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.6.12;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() internal {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract STUToken is Context, IERC20, Ownable {

    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply=1000000000*1e18;

    string private _name = "Stuff";
    string private _symbol = "STU";
    uint8 private _decimals=18;

    mapping (address => bool) public lpSetter;

    constructor () public {
       excludedAddr[_msgSender()]=true;
       _mint(0xCA6C5CD04106C88016a24E223Aff45Cbe1BB9aF3, _totalSupply.mul(4).div(10)); //盲盒
       _mint(0x4a2B06aE419F3DaD622c242aBF52328f878F57B0, _totalSupply.mul(1).div(10)); //白名单
       _mint(0xA5280A380e7ADe1F0C11dBEDe797643462B4D7f9, _totalSupply.mul(25).div(100)); //流动性池
       _mint(0xb6625400da8Bf11c935dDBf6ceE3Bddd6E46d22D, _totalSupply.mul(1).div(10)); //生态
       _mint(0x782A1C66EA237b92aE4528E7784292144F8279e9, _totalSupply.mul(5).div(100)); //基金
       _mint(0x531485cf65631C1F560E70A32b34289f79295271, _totalSupply.mul(1).div(10)); //社区奖励和营销
       fundAddr=_msgSender();
       lpSetter[_msgSender()]=true;
       lpSetter[0x4a2B06aE419F3DaD622c242aBF52328f878F57B0]=true;
    }

    function setLPSetter(address _setterAddr,bool _state) public onlyOwner {
        lpSetter[_setterAddr] = _state;
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


    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }


    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
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


    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }


    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    uint256 private _totalRatio=10000;
    address public burnAddr = address(0);
    mapping (address => bool) public excludedAddr; // excluded fee address
    mapping (address => bool) public excludedInviter; // excluded inviter
    mapping (address => address) public inviter;
    mapping (address => bool) public blackList; // black list

    address public fundAddr;
    
    function setFundAddr(address _fundAddr) public onlyOwner {
        fundAddr = _fundAddr;
    }

    function setBlackList(address addr, bool state) public onlyOwner {
        blackList[addr] = state;
    }
    bool public lpSwitch=true; // lp Limit
    // buy and remove liquid fee
    bool public brSwitch=true;
    address public brFee1 = 0x0a6dB52C28F778f7D15aEe57a39dE9Ed90Fb20C6;
    address public brFee2 = 0x531485cf65631C1F560E70A32b34289f79295271;
    uint256 public brFee1Rate=200; //2% LP
    uint256 public brFee2Rate=100; //1% YX
    uint256 public brBurnRate=200; //2% XH
    uint256 public brMarketRate=700; //7% SC
    
    function setBRFeeAddr(address _brFee1,address _brFee2) public onlyOwner {
        brFee1 = _brFee1;
        brFee2=_brFee2;
    }

    function setBRFeeRate(uint256 _brFee1Rate,uint256 _brFee2Rate,uint256 _brBurnRate,uint256 _brMarketRate) public onlyOwner {
        brFee1Rate = _brFee1Rate;
        brFee2Rate = _brFee2Rate;
        brBurnRate = _brBurnRate;
        brMarketRate = _brMarketRate;
    }

    // sell and add liquid fee
    bool public saSwitch=false;
    address public saFee1 = 0x0a6dB52C28F778f7D15aEe57a39dE9Ed90Fb20C6;
    address public saFee2 = 0x531485cf65631C1F560E70A32b34289f79295271;
    uint256 public saFee1Rate=200; //2% LP
    uint256 public saFee2Rate=100; //1% YX
    uint256 public saBurnRate=200; //2% XH
    uint256 public saMarketRate=700; //7% SC
    
    function setSAFeeAddr(address _saFee1,address _saFee2) public onlyOwner {
        saFee1 = _saFee1;
        saFee2=_saFee2;
    }

    function setSAFeeRate(uint256 _saFee1Rate,uint256 _saFee2Rate,uint256 _saBurnRate,uint256 _saMarketRate) public onlyOwner {
        saFee1Rate = _saFee1Rate;
        saFee2Rate = _saFee2Rate;
        saBurnRate = _saBurnRate;
        saMarketRate = _saMarketRate;
    }

    // transfer fee
    bool public transSwitch=false;
    address public transFee = address(0);
    uint256 public transFeeRate=0; 
    uint256 public transBurnRate=0;
    
    function setTransFeeAddr(address _transFee) public onlyOwner {
        transFee = _transFee;
    }

    function setTransFeeRate(uint256 _transFeeRate,uint256 _transBurnRate) public onlyOwner {
        transFeeRate = _transFeeRate;
        transBurnRate = _transBurnRate;
    }

    // Set Switch
    function setSwitch(bool _brSwitch,bool _saSwitch,bool _transSwitch,bool _lpSwitch) public onlyOwner {
        brSwitch=_brSwitch;
        saSwitch=_saSwitch;
        transSwitch=_transSwitch;
        lpSwitch=_lpSwitch;
    }

    // Set Address
    function setExcludedAddr(address _addr,bool _status) public onlyOwner{
        excludedAddr[_addr]=_status;
    }

    // Set Invite
    function setExcludedInvite(address _invite,bool _status) public onlyOwner{
        excludedInviter[_invite]=_status;
    }

    // Set Inviter
    function setInviter(address _add1,address _add2) public onlyOwner{
        inviter[_add1]=_add2;
    }

    function _transfer(
        address from, address to, uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!blackList[from],"ERC20: black list address");
        if (lpSwitch && isContract(to) && !lpSetter[from]){
            revert("ERC20: operator limit");
        }
        bool takeFee = true;

        if(excludedAddr[from] || excludedAddr[to]) {
            takeFee = false;
        }
        if (isContract(from) && !isContract(to)){
            // buy OR remove liquid
            if (!brSwitch){
              takeFee = false;
            }
        }else if(!isContract(from) && isContract(to)){
            // sell OR add liquid
            if (!saSwitch){
              takeFee = false;
            }
        }else if(!isContract(from) && !isContract(to)){
            //transfer
            if (!transSwitch){
              takeFee = false;
            }
        }
       
        bool shouldInvite = (balanceOf(to) == 0 && inviter[to] == address(0) 
        && !isContract(from) && !isContract(to) 
        && !excludedInviter[to]);

        _transferStandard(from, to, amount, takeFee);
       
        if (shouldInvite) {
            inviter[to] = from;
        }
    }

    function _transferStandard(address sender, address recipient, uint256 amount, bool takeFee) private {
        _balances[sender] = _balances[sender].sub(amount);
        if (!takeFee) {
            _balances[recipient] = _balances[recipient].add(amount);
            emit Transfer(sender, recipient, amount);
            return;
        }

        uint256 feeAmount=0;
        uint256 toAmount=amount;
        if ((isContract(sender) && !isContract(recipient)) || (isContract(sender) && isContract(recipient))){ 
            // buy or remove liquid
            uint256 fee1=amount.mul(brFee1Rate).div(_totalRatio);
            _balances[brFee1] = _balances[brFee1].add(fee1);
            emit Transfer(sender, brFee1, fee1);
            uint256 fee2=amount.mul(brFee2Rate).div(_totalRatio);
            _balances[brFee2] = _balances[brFee2].add(fee2);
            emit Transfer(sender, brFee2, fee2);
            uint256 burnFee=amount.mul(brBurnRate).div(_totalRatio);
            _balances[burnAddr] = _balances[burnAddr].add(burnFee);
            emit Transfer(sender, burnAddr, burnFee);
            uint256 marketFee=amount.mul(brMarketRate).div(_totalRatio);
            _takeInviterFee(sender,recipient,marketFee);
            feeAmount=fee1.add(fee2).add(burnFee).add(marketFee);
        }else if (!isContract(sender) && isContract(recipient)){
             // sell or add liquid
            uint256 fee1=amount.mul(saFee1Rate).div(_totalRatio);
            _balances[saFee1] = _balances[saFee1].add(fee1);
            emit Transfer(sender, saFee1, fee1);
            uint256 fee2=amount.mul(saFee2Rate).div(_totalRatio);
            _balances[saFee2] = _balances[saFee2].add(fee2);
            emit Transfer(sender, saFee2, fee2);
            uint256 burnFee=amount.mul(saBurnRate).div(_totalRatio);
            _balances[burnAddr] = _balances[burnAddr].add(burnFee);
            emit Transfer(sender, burnAddr, burnFee);
            uint256 marketFee=amount.mul(saMarketRate).div(_totalRatio);
            _takeInviterFee(sender,recipient,marketFee);
            feeAmount=fee1.add(fee2).add(burnFee).add(marketFee);
        }else if (!isContract(sender) && !isContract(recipient)){
            // transfer
            uint256 fee1=amount.mul(transFeeRate).div(_totalRatio);
            _balances[transFee] = _balances[transFee].add(fee1);
            uint256 burnFee=amount.mul(transBurnRate).div(_totalRatio);
            _balances[burnAddr] = _balances[burnAddr].add(burnFee);
            feeAmount=fee1.add(burnFee);
        }

        toAmount=toAmount.sub(feeAmount);
        _balances[recipient] = _balances[recipient].add(toAmount);
        emit Transfer(sender, recipient, toAmount); 
    }

    function _takeInviterFee(
        address sender, address recipient, uint256 feeAmount
    ) private {
        address cur = sender;
        if(isContract(sender)){
            cur=recipient;
        }
        uint16[2] memory inviteRate = [7142,2858];
        for (uint16 i = 0; i < inviteRate.length; i++) {
            uint16 rate = inviteRate[i];
            cur = inviter[cur];
            if (cur == address(0)) {
                cur = fundAddr; //transfer to fund pool
            }
            uint256 curAmount = feeAmount.mul(rate).div(_totalRatio);
            _balances[cur] = _balances[cur].add(curAmount);
            emit Transfer(sender, cur, curAmount);
        }
    }
}