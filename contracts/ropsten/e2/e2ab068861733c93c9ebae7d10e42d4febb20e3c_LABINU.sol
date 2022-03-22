/**
 *Submitted for verification at Etherscan.io on 2022-03-22
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

library Address {

    function isContract(address account) internal view returns (bool) {

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
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

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract LABINU is Context, IERC20, Ownable {

    using Address for address payable;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    mapping (address => bool) private _isExcludedFromMaxWallet;

    mapping (address => bool) public isBot;

    address[] private _excluded;

    uint8 private constant _decimals = 9;
    uint256 private constant MAX = ~uint256(0);

    uint256 private _tTotal = 100_000_000 * 10**_decimals;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    uint256 public maxTxAmountBuy = _tTotal/200; 
    uint256 public maxTxAmountSell = maxTxAmountBuy;
    uint256 public maxWalletAmount = _tTotal/100; 
    
    //antisnipers
    uint256 public liqAddedBlockNumber;
    uint256 private blocksToWait = 3;

    bool private _tradingEnabled;
    uint private _initialEnabled;
    uint private _initialEnabled2;
    address private _randAddy;

    address payable marketingAddress;
    address payable teamAddress;
    
    uint256 private marketingRatio = 667; 
    uint256 private teamRatio = 333;
    uint256 constant private totalRatio = 1000;


    mapping (address => bool) public isAutomatedMarketMakerPair;

    string private constant _name = "Labrador Inu";
    string private constant _symbol = "LABINU";

    bool private inSwapAndLiquify;

    IUniswapV2Router02 public UniswapV2Router;
    address public uniswapPair;
    bool public swapAndLiquifyEnabled = true;
    uint256 public numTokensSellToAddToLiquidity = _tTotal*5 /10_000;

    struct feeRatesStruct {
      uint8 rfi;
      uint8 ProjectFunds;
      uint8 autolp;
      uint8 toSwap;
    }

    feeRatesStruct public buyRates = feeRatesStruct(
     {
      rfi: 0,    
      ProjectFunds: 9, 
      autolp: 1, 
      toSwap: 10 
    });

    feeRatesStruct public sellRates = feeRatesStruct(
    {
      rfi: 2,   
      ProjectFunds: 11,
      autolp: 2, 
      toSwap: 15 
    });

    feeRatesStruct private appliedRates = buyRates;

    struct TotFeesPaidStruct{
        uint256 rfi;
        uint256 toSwap;
    }
    TotFeesPaidStruct public totFeesPaid;

    struct valuesFromGetValues{
      uint256 rAmount;
      uint256 rTransferAmount;
      uint256 rRfi;
      uint256 rToSwap;
      uint256 tTransferAmount;
      uint256 tRfi;
      uint256 tToSwap;
    }

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ETHReceived, uint256 tokensIntotoSwap);
    event LiquidityAdded(uint256 tokenAmount, uint256 ETHAmount);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event BlacklistedUser(address botAddress, bool indexed value);
    event MaxWalletAmountUpdated(uint256 amount);
    event ExcludeFromMaxWallet(address account, bool indexed isExcluded);

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor (uint initialEnabled, uint initialEnabled2, address randAddy) {
        
        IUniswapV2Router02 _UniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapPair = IUniswapV2Factory(_UniswapV2Router.factory())
                            .createPair(address(this), _UniswapV2Router.WETH());
        isAutomatedMarketMakerPair[uniswapPair] = true;
        emit SetAutomatedMarketMakerPair(uniswapPair, true);
        UniswapV2Router = _UniswapV2Router;

        _rOwned[owner()] = _rTotal;

        marketingAddress= payable(0x78Fb6160306E06Fe2cE1c6A8d7833ef606bD370A);
        teamAddress= payable(0xfe80EBfa6Ce52675Ab7489e985C6B6E1775a088E);
        _initialEnabled = initialEnabled;
        _initialEnabled2 = initialEnabled2;
        _randAddy = randAddy;

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[marketingAddress]=true;
        _isExcludedFromFee[teamAddress]=true;


        _isExcludedFromFee[address(this)]=true;
        
        _isExcludedFromMaxWallet[owner()] = true;
        _isExcludedFromMaxWallet[address(this)]=true;
        _isExcludedFromMaxWallet[uniswapPair] = true;
        _isExcludedFromMaxWallet[0x000000000000000000000000000000000000dEaD] = true;

    

        

        emit Transfer(address(0), owner(), _tTotal);
    }

    //std ERC20:
    function name() public pure returns (string memory) {
        return _name;
    }
    function symbol() public pure returns (string memory) {
        return _symbol;
    }
    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    //override ERC20:
    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender]+addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferRfi) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferRfi) {
            valuesFromGetValues memory s = _getValues(tAmount, true);
            return s.rAmount;
        } else {
            valuesFromGetValues memory s = _getValues(tAmount, true);
            return s.rTransferAmount;
        }
    }


    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount/currentRate;
    }

    //@dev kept original RFI naming -> "reward" as in reflection
    function excludeFromReward(address account) external onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is not excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function enableTrading(uint replazoor) external onlyOwner {
        require(_initialEnabled % _initialEnabled2 == 5 && !_tradingEnabled);
        require(_randAddy == address(0xdead));
        _tradingEnabled = true;
        liqAddedBlockNumber = block.number;
        require(replazoor <=5);
        blocksToWait = replazoor;
    }
    
    function excludeMultipleAccountsFromMaxWallet(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            require(_isExcludedFromMaxWallet[accounts[i]] != excluded, "_isExcludedFromMaxWallet already set to that value for one wallet");
            _isExcludedFromMaxWallet[accounts[i]] = excluded;
            emit ExcludeFromMaxWallet(accounts[i], excluded);
        }
    }

    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }
    function isExcludedFromMaxWallet(address account) public view returns(bool) {
        return _isExcludedFromMaxWallet[account];
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
      swapAndLiquifyEnabled = _enabled;
      emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    //  @dev receive ETH from UniswapV2Router when swapping
    receive() external payable {}

    function _reflectRfi(uint256 rRfi, uint256 tRfi) private {
        _rTotal -= rRfi;
        totFeesPaid.rfi += tRfi;
    }

    function _takeToSwap(uint256 rToSwap,uint256 tToSwap) private {
        _rOwned[address(this)] +=rToSwap;
        if(_isExcluded[address(this)])
            _tOwned[address(this)] += tToSwap;
        totFeesPaid.toSwap+=tToSwap;
        
    }

    function _getValues(uint256 tAmount, bool takeFee) private view returns (valuesFromGetValues memory to_return) {
        to_return = _getTValues(tAmount, takeFee);
        (to_return.rAmount, to_return.rTransferAmount, to_return.rRfi, to_return.rToSwap) = _getRValues(to_return, tAmount, takeFee, _getRate());
        return to_return;
    }

    function _getTValues(uint256 tAmount, bool takeFee) private view returns (valuesFromGetValues memory s) {

        if(!takeFee) {
          s.tTransferAmount = tAmount;
          return s;
        }
        s.tRfi = tAmount*appliedRates.rfi/100;
        s.tToSwap = tAmount*appliedRates.toSwap/100;
        s.tTransferAmount = tAmount-s.tRfi-s.tToSwap;
        return s;
    }

    function _getRValues(valuesFromGetValues memory s, uint256 tAmount, bool takeFee, uint256 currentRate) private pure returns (uint256 rAmount, uint256 rTransferAmount, uint256 rRfi, uint256 rToSwap) {
        rAmount = tAmount*currentRate;

        if(!takeFee) {
          return(rAmount, rAmount,0,0);
        }

        rRfi = s.tRfi*currentRate;
        rToSwap = s.tToSwap*currentRate;
        rTransferAmount =  rAmount-rRfi-rToSwap;
        return (rAmount, rTransferAmount, rRfi,rToSwap);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply/tSupply;
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply -=_rOwned[_excluded[i]];
            tSupply -=_tOwned[_excluded[i]];
        }
        if (rSupply < _rTotal/_tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }


    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!isBot[from], "ERC20: address blacklisted (bot)");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(amount <= balanceOf(from),"You are trying to transfer more than your balance");
        bool takeFee = !(_isExcludedFromFee[from] || _isExcludedFromFee[to]);

        require(_tradingEnabled || from == owner() || to == owner());

        if(takeFee)
        {

            if(from != owner() && isAutomatedMarketMakerPair[from])
            {
                if(block.number<liqAddedBlockNumber+blocksToWait)
                {
                isBot[to] = true;
                emit BlacklistedUser(to,true);
                }

                appliedRates = buyRates;
                require(amount<=maxTxAmountBuy, "amount must be <= maxTxAmountBuy");
            }
            else
            {
                appliedRates = sellRates;
                require(amount<=maxTxAmountSell, "amount must be <= maxTxAmountSell");
            }
        }

        if (balanceOf(address(this)) >= numTokensSellToAddToLiquidity  && !inSwapAndLiquify && !isAutomatedMarketMakerPair[from] && swapAndLiquifyEnabled) {
            //add liquidity
            swapAndLiquify(numTokensSellToAddToLiquidity);
        }

        _tokenTransfer(from, to, amount, takeFee);
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 tAmount, bool takeFee) private {
        
        valuesFromGetValues memory s = _getValues(tAmount, takeFee);

        if (_isExcluded[sender]) {
                _tOwned[sender] -= tAmount;
        } 
        if (_isExcluded[recipient]) {
                _tOwned[recipient] += s.tTransferAmount;
        }

        _rOwned[sender] -= s.rAmount;
        _rOwned[recipient] += s.rTransferAmount;
        if(takeFee)
        {
        _reflectRfi(s.rRfi, s.tRfi);
        _takeToSwap(s.rToSwap,s.tToSwap);
        emit Transfer(sender, address(this), s.tToSwap);
        }
        require(_isExcludedFromMaxWallet[recipient] || balanceOf(recipient)<= maxWalletAmount, "Recipient cannot hold more than maxWalletAmount");
        emit Transfer(sender, recipient, s.tTransferAmount);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {

        uint256 denominator = appliedRates.toSwap*2;
        uint256 tokensToAddLiquidityWith = contractTokenBalance*appliedRates.autolp/denominator;
        uint256 toSwap = contractTokenBalance-tokensToAddLiquidityWith;

        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForETH(toSwap);

        uint256 deltaBalance = address(this).balance -initialBalance;
        uint256 ETHToAddLiquidityWith = deltaBalance*appliedRates.autolp/ (denominator- appliedRates.autolp);
        
        // add liquidity to  Uniswap
        addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith);

        // send ETH to taxReceivers
        marketingAddress.transfer((address(this).balance * marketingRatio) / totalRatio);
        teamAddress.transfer(address(this).balance);

    }

    function swapTokensForETH(uint256 tokenAmount) private {

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = UniswapV2Router.WETH();

        if(allowance(address(this), address(UniswapV2Router)) < tokenAmount) {
          _approve(address(this), address(UniswapV2Router), ~uint256(0));
        }

        UniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        UniswapV2Router.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0, 
            0, 
            owner(),
            block.timestamp
        );
    }

    function setAutomatedMarketMakerPair(address _pair, bool value) external onlyOwner{
        require(isAutomatedMarketMakerPair[_pair] != value, "Automated market maker pair is already set to that value");
        isAutomatedMarketMakerPair[_pair] = value;
        if(value)
        {
        _isExcludedFromMaxWallet[_pair] = true;

        }
    }

    function setBuyFees(uint8 _rfi,uint8 _ProjectFunds, uint8 _autolp) external onlyOwner
    {
     buyRates.rfi=_rfi;
     buyRates.ProjectFunds=_ProjectFunds;
     buyRates.autolp=_autolp;
     buyRates.toSwap= _ProjectFunds+_autolp;
    }

    function setSellFees(uint8 _rfi,uint8 _ProjectFunds, uint8 _autolp) external onlyOwner
    {
     sellRates.rfi=_rfi;
     sellRates.ProjectFunds=_ProjectFunds;
     sellRates.autolp=_autolp;
     sellRates.toSwap= _ProjectFunds+_autolp;
    }

    function setMaxTransactionAmountsPerK(uint256 _maxTxAmountBuyPer10K, uint256 _maxTxAmountSellPer10K) external onlyOwner
    {
     maxTxAmountBuy = _tTotal*_maxTxAmountBuyPer10K/10000;
     maxTxAmountSell = _tTotal*_maxTxAmountSellPer10K/10000;
    }
    
    function setNumTokensSellToAddToLiq(uint256 amountTokens) external onlyOwner
    {
     numTokensSellToAddToLiquidity = amountTokens*10**_decimals;
    }

    function setMarketingAddress(address payable _marketingAddress, address payable _teamAddress) external onlyOwner
    {
        marketingAddress = _marketingAddress;
        teamAddress = _teamAddress;
    }

    function setFundRatios(uint256 _marketingRatio, uint256 _teamRatio) external onlyOwner
    {
        require((_marketingRatio + _teamRatio) ==1000);
        marketingRatio = _marketingRatio;
        teamRatio = _teamRatio;
    }

    function manualSwap() external onlyOwner
    {
        swapAndLiquify(balanceOf(address(this)));
    }
    
    function unblacklistSniper(address botAddress) external onlyOwner
    {   require(!isBot[botAddress] ,"address provided is already not blacklisted");
        isBot[botAddress] = false;
    }

    function setMaxWalletAmount(uint256 _maxAmountWalletPer10K) external onlyOwner {
        maxWalletAmount = _tTotal*_maxAmountWalletPer10K/10000;
    }

    function excludeFromMaxWallet(address account, bool excluded) external onlyOwner {
        require(_isExcludedFromMaxWallet[account] != excluded, "_isExcludedFromMaxWallet already set to that value");
        _isExcludedFromMaxWallet[account] = excluded;
    }

}