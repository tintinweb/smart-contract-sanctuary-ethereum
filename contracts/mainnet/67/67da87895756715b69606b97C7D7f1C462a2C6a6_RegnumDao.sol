/**
 *Submitted for verification at Etherscan.io on 2022-11-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
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
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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


interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
    external
    view
    returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
    external
    returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}


interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
    external
    returns (
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
    external
    payable
    returns (
        uint256 amountToken,
        uint256 amountETH,
        uint256 liquidity
    );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract RegnumDao is Context, IERC20, IERC20Metadata, Ownable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;
    mapping (address => bool) public _isExcludedFromFee;
    mapping(address => bool) public _isBlacklisted;
    mapping(address => bool) public _tradeAllowedList;

    string private _name = "RegnumDAO";
    string private _symbol = "REX";
    uint8 private _decimals = 9;

    uint256 private _initSupply = 100_000_000;
    uint256 private _totalSupply = _initSupply * 10**_decimals;

    address public _liqWallet;
    address payable public _devMarketingWallet;

    uint256 public _maxTxAmount;
    uint256 public _maxWalletAmount;
    uint256 private _amountToFlush;
    uint256 public _lpExtraSum;
    uint256 public _devMarketingSum;
    bool private _inSwapAndLiquify;

    IUniswapV2Router02 public immutable _uniswapV2Router;
    address public immutable _uniswapV2Pair;

    uint256 private _feeDenominator = 1000;

    bool public _tradeEnabled;
    bool public _tResolverEnabled;

    event Boom();
    event ThirdEyeResolver(address wallet);
    event ToDevMarketing(uint256 balance0);
    event ToLiquidity(uint256 balance0, uint256 balance1);

    struct IThirdEye {
        uint256 startedAt;
        bool safu;
        uint256 when;
    }

    IThirdEye public _thirdEye =
    IThirdEye({
    startedAt: 0,
    safu: true,
    when: 3
    });

    struct ITax {
        uint256 lpFee;
        uint256 devMarketingFee;
        uint256 burnFee;
    }

    ITax public _buyTax =
    ITax({
    lpFee: 10,
    devMarketingFee: 40,
    burnFee: 0
    });

    ITax public _sellTax =
    ITax({
    lpFee: 10,
    devMarketingFee: 40,
    burnFee: 0
    });

    ITax public _transferTax =
    ITax({
    lpFee: 10,
    devMarketingFee: 40,
    burnFee: 0
    });

    modifier busySwap() {
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }

    constructor(address mWallet_) {
        _maxTxAmount = 1000000 * 10**_decimals; //1%
        _maxWalletAmount = 2000000 * 10**_decimals; //2%
        _amountToFlush = 100000 * 10**_decimals; //0.1%

        _liqWallet = _msgSender();
        _devMarketingWallet = payable(mWallet_);

        _tradeEnabled = false;

        _lpExtraSum = 0;
        _devMarketingSum = 0;

        _isExcludedFromFee[_msgSender()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_devMarketingWallet] = true;

        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);

        _balances[address(this)] = 0;
        _balances[_devMarketingWallet] = 0;

        _tradeAllowedList[_msgSender()] = true;
        _tradeAllowedList[address(this)] = true;

        //IUniswapV2Router02 uniswapV2Router_ = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); //bsc-tesnet
        IUniswapV2Router02 uniswapV2Router_ = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); //eth-uni

        _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router_.factory()).createPair(address(this), uniswapV2Router_.WETH());
        _uniswapV2Router = uniswapV2Router_;

        _approve(_msgSender(), address(uniswapV2Router_), type(uint256).max);
        _approve(address(this), address(uniswapV2Router_), type(uint256).max);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
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

    function transferFrom(address sender,address recipient,uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - (amount));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool){
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + (addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - (subtractedValue));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function setDevMarketingWallet(address payable newAddress) external onlyOwner {
        _devMarketingWallet = payable(newAddress);
    }

    function setLiqWallet(address newAddress) external onlyOwner {
        _liqWallet = newAddress;
    }

    function flushReserveBalance() external onlyOwner {
        uint256 amountETH = address(this).balance;
        payable(_devMarketingWallet).transfer(amountETH);
    }

    function flushMarketingTax(uint256 tokenBalance) external onlyOwner {
        shouldTakeDevMarketing(tokenBalance);
    }

    function setAccountFromFee(address account, bool flag) public onlyOwner {
        _isExcludedFromFee[account] = flag;
    }

    function excludeFromBlacklist(address account) public onlyOwner {
        _isBlacklisted[account] = false;
    }

    function setResolverStatus(bool flag) public onlyOwner {
        _tResolverEnabled = flag;
    }

    function setSettings(uint256 maxWallet, uint256 maxTx, uint256 toFlush) public onlyOwner {
        require(maxWallet * 10**_decimals > 1000000 * 10**_decimals, "Max Wallet must be above 1% of total supply.");
        require(maxTx * 10**_decimals > 500000 * 10**_decimals, "Max Transaction must be above 0.5% of total supply.");

        _maxWalletAmount = maxWallet * 10**_decimals;
        _maxTxAmount = maxTx * 10**_decimals;
        _amountToFlush = toFlush * 10**_decimals;
    }

    function setFee(uint8 feeType, uint256 liqFee, uint256 devMarketingFee, uint256 burnFee) public onlyOwner {
        require(liqFee + devMarketingFee + burnFee <= 100);

        if(feeType == 0) {
            _buyTax = ITax({
            lpFee: liqFee,
            devMarketingFee: devMarketingFee,
            burnFee: burnFee
            });
        }else if(feeType == 1){
            _sellTax = ITax({
            lpFee: liqFee,
            devMarketingFee: devMarketingFee,
            burnFee: burnFee
            });
        }else if(feeType == 2){
            _transferTax = ITax({
            lpFee: liqFee,
            devMarketingFee: devMarketingFee,
            burnFee: burnFee
            });
        }
    }

    function setupThirdEye() external onlyOwner {
        if (_thirdEye.startedAt == 0) {
            _thirdEye.startedAt = block.number;
            _tResolverEnabled = true;

            emit Boom();

            _tradeEnabled = true;
        }
    }

    function thirdEyeResolver(address account) private{
        if(account == _uniswapV2Pair || account == address(this) || account == address(_uniswapV2Router)) {revert();}

        _isBlacklisted[account] = true;
        emit ThirdEyeResolver(account);
    }

    function shouldTakeLiq(uint256 tokenBalance) private busySwap {
        if (tokenBalance > 0) {
            uint256 splittedBalance = tokenBalance / 2;
            uint256 initBalance = address(this).balance;
            swapTokensForEth(splittedBalance);
            uint256 currentBalance = address(this).balance;

            uint256 ethBalance = uint256(currentBalance - initBalance);
            if (ethBalance > 0) {
                addLiquidity(splittedBalance, ethBalance);
                emit ToLiquidity(splittedBalance, ethBalance);
                _lpExtraSum -= tokenBalance;
            }
        }
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        if(_allowances[address(this)][address(_uniswapV2Router)] < tokenAmount) {
            _approve(address(this), address(_uniswapV2Router), type(uint256).max);
        }

        _uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            _liqWallet,
            block.timestamp
        );
    }

    function shouldTakeDevMarketing(uint256 tokenBalance) private busySwap {
        if (tokenBalance > 0) {
            uint256 initBalance = address(this).balance;
            swapTokensForEth(tokenBalance);
            uint256 currentBalance = address(this).balance;

            uint256 ethBalance = uint256(currentBalance - initBalance);
            if (ethBalance > 0) {
                _devMarketingWallet.transfer(ethBalance);
                emit ToDevMarketing(ethBalance);
                _devMarketingSum -= tokenBalance;
            }
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();

        if(_allowances[address(this)][address(_uniswapV2Router)] < tokenAmount) {
            _approve(address(this), address(_uniswapV2Router), type(uint256).max);
        }

        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(_isBlacklisted[from] == false, "Third-eye is watching you");
        require(_isBlacklisted[to] == false, "Third-eye is watching you");

        if (!_tradeEnabled) {
            require(_tradeAllowedList[from] || _tradeAllowedList[to], "Transfer: not allowed");
            require(balanceOf(_uniswapV2Pair) == 0 || to != _uniswapV2Pair, "Transfer: not allowed");
        }

        if(from != owner() && to != owner() || to != address(0xdead) && to != address(0))
        {
            if (from == _uniswapV2Pair || to == _uniswapV2Pair && (!_isExcludedFromFee[to] && !_isExcludedFromFee[from])) {
                require(amount <= _maxTxAmount);
            }
            if(to != address(_uniswapV2Router) && to != _uniswapV2Pair && !_isExcludedFromFee[to]) {
                require(balanceOf(to) + amount <= _maxWalletAmount);
            }
        }

        if(!_inSwapAndLiquify && from != _uniswapV2Pair && _tResolverEnabled) {
            if (_lpExtraSum > _amountToFlush) {
                shouldTakeLiq(_amountToFlush);
            }else{
                if (_devMarketingSum > _amountToFlush) {
                    shouldTakeDevMarketing(_amountToFlush);
                }
            }
        }

        bool shouldTakeFee = true;
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            shouldTakeFee = false;
        }

        if(!_tResolverEnabled) {
            shouldTakeFee = false;
        }

        _tokenTransfer(from, to, amount, shouldTakeFee);
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool shouldTakeFee) private {
        uint256 liqFee = 0;
        uint256 devMarketingFee = 0;
        uint256 burnFee = 0;

        uint256 liqFeeAmount = 0;
        uint256 devMarketingFeeAmount = 0;
        uint256 burnFeeAmount = 0;

        uint256 feeAmount = 0;

        bool thirdEyeFee = false;

        if (_thirdEye.safu) {
            uint256 thirdEyeResolveNumber = (_thirdEye.startedAt + _thirdEye.when);
            if (_thirdEye.startedAt > 0 && block.number > thirdEyeResolveNumber) {
                _thirdEye.safu = false;
            } else {
                if (sender == _uniswapV2Pair && recipient != address(_uniswapV2Router) && !_isExcludedFromFee[recipient]) {
                    thirdEyeResolver(recipient);
                    thirdEyeFee = true;
                }
            }
        }

        if (shouldTakeFee) {
            if (thirdEyeFee) {
                liqFee = 800;
                devMarketingFee = 0;
                burnFee = 0;
            }else{
                if (sender == _uniswapV2Pair) {
                    liqFee = _buyTax.lpFee;
                    devMarketingFee = _buyTax.devMarketingFee;
                    burnFee = _buyTax.burnFee;
                } else if (recipient == _uniswapV2Pair) {
                    liqFee = _sellTax.lpFee;
                    devMarketingFee = _sellTax.devMarketingFee;
                    burnFee = _sellTax.burnFee;
                } else {
                    liqFee = _transferTax.lpFee;
                    devMarketingFee = _transferTax.devMarketingFee;
                    burnFee = _transferTax.burnFee;
                }
            }

            feeAmount = (amount * (liqFee + devMarketingFee + burnFee)) / (1000);

            if ((liqFee + devMarketingFee + burnFee) > 0) {
                liqFeeAmount = feeAmount * liqFee / (liqFee + devMarketingFee + burnFee);
                devMarketingFeeAmount = feeAmount * devMarketingFee / (liqFee + devMarketingFee + burnFee);
                burnFeeAmount = feeAmount * burnFee / (liqFee + devMarketingFee + burnFee);
            }

            _lpExtraSum += liqFeeAmount;
            _devMarketingSum += devMarketingFeeAmount;
        }

        _balances[sender] -= amount;
        _balances[address(this)] += (liqFeeAmount + devMarketingFeeAmount);
        emit Transfer(sender, address(this), (liqFeeAmount + devMarketingFeeAmount));

        uint256 finalAmount = amount - (liqFeeAmount + devMarketingFeeAmount + burnFeeAmount);
        _balances[recipient] += finalAmount;
        emit Transfer(sender, recipient, finalAmount);

        if (burnFeeAmount > 0) {
            _balances[address(0xdead)] += burnFeeAmount;
            emit Transfer(sender, address(0xdead), burnFeeAmount);
        }
    }

    receive() external payable {}
}