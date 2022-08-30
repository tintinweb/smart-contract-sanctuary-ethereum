/**
 *Submitted for verification at Etherscan.io on 2022-08-30
*/

//SPDX-License-Identifier:Unlicensed

pragma solidity ^0.8.15;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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

library Address {

    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }


    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            
            if (returndata.length > 0) {
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


contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

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
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }
    
    function getTime() public view returns (uint256) {
        return block.timestamp;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

// pragma solidity >=0.5.0;

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


// pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// pragma solidity >=0.6.2;

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



// pragma solidity >=0.6.2;

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





contract Kongnobi is Context, IERC20, Ownable {
    using Address for address;
    address payable public marketingWalletAddress = payable(0x4C49579450e9c96af4A698eE5d2610408E620EC4); // Marketing Wallet Address
    address payable public devWalletAddress = payable(0x4C49579450e9c96af4A698eE5d2610408E620EC4); // dev Wallet Address
    address public constant deadWallet =  0x000000000000000000000000000000000000dEaD;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    event Log(string, uint256);
    event LogTokenApproval(address from, uint256 total);
    event LogTokenBulkSentETH(address from, uint256 total);
    event LogTokenBulkSent(address token, address from, uint256 total);
    event AuditLog (string, address);
    
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) public _isExcludedMaxTransactionAmount;
    mapping (address => bool) public _isBlacklisted;

    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 10 * 10**12 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;


    string private constant _name = "Kongnobi";
    string private constant _symbol = "KONGNOBI";
    uint8 private constant _decimals = 9;


    uint256 public _taxFee = 2;
    uint256 private _previousTaxFee = _taxFee;
    
    uint256 public _liquidityFee = 4;  
    uint256 private _previousLiquidityFee = _liquidityFee;

    uint256 public _devFee = 0; 
    uint256 private _previousDevFee = _devFee;

    uint256 public _marketingFee = 4; 
    uint256 private _previousMarketingFee = _marketingFee;

    uint256 public totalSwapableFee = _liquidityFee + _devFee + _marketingFee ;

    uint256 _saleTaxFee = 2;
    uint256 _saleLiquidityFee = 10;
    uint256 _saleDevFee = 0;
    uint256 _saleMarketingFee = 12;

    uint256 public totalSwapableSaleFee = _saleTaxFee + _saleLiquidityFee + _saleDevFee + _saleMarketingFee ;

    uint256 public _transferTaxFee = 0;
    uint256 public _transferLiquidityFee = 0;
    uint256 _transferDevFee = 0;
    uint256 _transferMarketingFee = 0;

    uint256 public totalSwapableTransferFee = _transferTaxFee + _transferLiquidityFee + _transferDevFee + _transferMarketingFee ;

    uint256 public liquidityTokensCollected = 0;
    uint256 public devTokensCollected = 0;
    uint256 public marketingTokensCollected = 0;

    uint256 public maxTransactionAmount;
    uint256 public maxWallet;
    uint256 private minimumTokensBeforeSwap = 10**9;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public currentRouter;
    address public immutable uniswapV2Pair;
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;
    bool public tradingActive = false;
    bool public limitsInEffect = false;


    event RewardLiquidityProviders(uint256 tokenAmount);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    
    
    event SwapTokensForETH(
        uint256 amountIn,
        address[] path
    );
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    constructor () {
        address _owner = 0xFdE9083933b9115f22D99D96AADA2AAe437BE9a6;
        _rOwned[_owner] = _rTotal;
        maxTransactionAmount = totalSupply() * 1 / 100; // 1% maxTransactionAmountTxn
        maxWallet = totalSupply() * 4 / 100; // 4% maxWallet

        //Adding Variables for all the routers for easier deployment for our customers.
        if (block.chainid == 56) {
            currentRouter = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // PCS Router
        } else if (block.chainid == 97) {
            currentRouter = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1; // PCS Testnet
        } else if (block.chainid == 43114) {
            currentRouter = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4; //Avax Mainnet
        } else if (block.chainid == 137) {
            currentRouter = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff; //Polygon Ropsten
        } else if (block.chainid == 250) {
            currentRouter = 0xF491e7B69E4244ad4002BC14e878a34207E38c29; //SpookySwap FTM
        } else if (block.chainid == 3) {
            currentRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; //Ropsten
        } else if (block.chainid == 1 || block.chainid == 4) {
            currentRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; //Mainnet
        } else {
            revert();
        }

        //End of Router Variables.

        _isExcludedFromFee[_owner] = true;
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(currentRouter);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        transferOwnership(_owner);

        emit Transfer(address(0), _owner, _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    
    function minimumTokensBeforeSwapAmount() public view returns (uint256) {
        return minimumTokensBeforeSwap;
    }


    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) external view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount/currentRate;
    }

    function excludeFromReward(address account) external onlyOwner() {

        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already excluded");
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

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // once enabled, can never be turned off
    function enableTrading() external onlyOwner {
        tradingActive = true;
        swapAndLiquifyEnabled = true;
        limitsInEffect = true;
    }

    // remove limits after token is stable
    function removeLimits() external onlyOwner returns (bool){
        limitsInEffect = false;
        return true;
    }

    function updateMaxAmount(uint256 newNum) external onlyOwner {
        require(newNum >= (totalSupply() * 1 / 100)/1e9, "Cannot set maxTransactionAmount lower than 0.5%");
        maxTransactionAmount = newNum * (10**9);
    }
    
    function updateMaxWallet(uint256 newNum) external onlyOwner {
        require(newNum >= (totalSupply() * 1 / 100)/1e9, "Cannot set maxTransactionAmount lower than 0.5%");
        maxWallet= newNum * (10**9);
    }

    function excludeFromMaxTransaction(address updAds, bool isEx) public onlyOwner {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if(!tradingActive){
            require(_isExcludedFromFee[from] || _isExcludedFromFee[to], "Trading is not active yet.");
        }

        require(!_isBlacklisted[from] && !_isBlacklisted[to], "You cant trade with blacklisted wallets");

        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinimumTokenBalance = contractTokenBalance >= minimumTokensBeforeSwap;

        if (limitsInEffect && !(_isExcludedFromFee[from] || _isExcludedFromFee[to]) && !inSwapAndLiquify){
            if (from == uniswapV2Pair && !_isExcludedMaxTransactionAmount[to]) {
                require(amount <= maxTransactionAmount, "Buy transfer amount exceeds the maxTransactionAmount.");
                require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
            }
            
            //when sell
            else if (to == uniswapV2Pair && !_isExcludedMaxTransactionAmount[from]) {
                require(amount <= maxTransactionAmount, "Sell transfer amount exceeds the maxTransactionAmount.");
            }
            else {
                require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
            }
        }
        
        if (!inSwapAndLiquify && swapAndLiquifyEnabled && from != uniswapV2Pair && from != owner() 
            && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]) 
        {
            if (overMinimumTokenBalance) 
            {
                swapAndLiquify();    
            }
        }
        if(to==uniswapV2Pair) { setSaleFee(); } 
        if(to != uniswapV2Pair && from != uniswapV2Pair) { setTransferFee(); }

        bool takeFee = true;
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to])
        {
            takeFee = false;
        }
        _tokenTransfer(from,to,amount,takeFee);
    }

    function swapAndLiquify() public lockTheSwap 
    {   
        uint256 initialBalance = address(this).balance;
        uint256 halfLiquidityTokens = liquidityTokensCollected/2;
        uint256 newBalance;
        if (halfLiquidityTokens > 0){
            swapTokensForEth(halfLiquidityTokens);
            newBalance = address(this).balance - initialBalance;
            addLiquidity(halfLiquidityTokens, newBalance);
            emit SwapAndLiquify(halfLiquidityTokens, newBalance, halfLiquidityTokens);
        }
        
        uint256 totalTokens = balanceOf(address(this));

        if (devTokensCollected> 0 && totalTokens >= devTokensCollected){
            _tokenTransfer( address(this), devWalletAddress, devTokensCollected, false);
        }

        totalTokens = balanceOf(address(this));
        if (totalTokens == 0) return;
        swapTokensForEth(totalTokens);
        newBalance = address(this).balance; 

        if (newBalance > 0){
            transferToAddressETH(marketingWalletAddress, newBalance);
        }

        liquidityTokensCollected = 0;
        devTokensCollected = 0;
        marketingTokensCollected = 0;

    }


    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );
        
        emit SwapTokensForETH(tokenAmount, path);
    }


    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            deadWallet,
            block.timestamp
        );
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        if(!takeFee) { removeAllFee(); }
        countUpFeeShare(amount);
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else 
        {
            _transferStandard(sender, recipient, amount);
        }
        restoreAllFee();
    }

    function setSaleFee() private {
        _taxFee = _saleTaxFee;
        _liquidityFee = _saleLiquidityFee;
        _devFee = _saleDevFee;
        _marketingFee = _saleMarketingFee;
        totalSwapableFee = _liquidityFee + _devFee + _marketingFee ; 
    }

    function setTransferFee() private {
        _taxFee = _transferTaxFee;
        _liquidityFee = _transferLiquidityFee;
        _devFee = _transferDevFee;
        _marketingFee = _transferMarketingFee;
        totalSwapableFee = _liquidityFee + _devFee + _marketingFee ; 
    }

    function countUpFeeShare(uint256 amount) private
    {
        if(totalSwapableFee==0) { return; }
        liquidityTokensCollected += (amount * _liquidityFee)/100;
        devTokensCollected += (amount * _devFee)/100;
        marketingTokensCollected += (amount *_marketingFee)/100;
    }


    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender] - rAmount; 
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount; 
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;        
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender] - tAmount;
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;   
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender] - tAmount; 
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;    
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal - rFee;
        _tFeeTotal = _tFeeTotal + tFee;
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = (tAmount - tFee) - tLiquidity;
        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount * currentRate;
        uint256 rFee = tFee * currentRate;
        uint256 rLiquidity = tLiquidity * currentRate;
        uint256 rTransferAmount = (rAmount - rFee) - rLiquidity;
        return (rAmount, rTransferAmount, rFee);
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
            rSupply = rSupply - _rOwned[_excluded[i]];
            tSupply = tSupply - _tOwned[_excluded[i]];
        }
        if (rSupply < (_rTotal/_tTotal)) return (_rTotal, _tTotal); 
        return (rSupply, tSupply);
    }
    
    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity * currentRate;
        _rOwned[address(this)] = _rOwned[address(this)] + rLiquidity;
        if(_isExcluded[address(this)]) { _tOwned[address(this)] = _tOwned[address(this)] + tLiquidity; } //TODO: Verify Change
    }
    
    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return (_amount * _taxFee)/10**2;
    }
    
    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return (_amount * totalSwapableFee) /100;
    }
    
    function removeAllFee() private 
    {
        _taxFee = 0;
        _liquidityFee = 0;
        _devFee = 0;
        _marketingFee = 0;
        totalSwapableFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
        _devFee = _previousDevFee;
        _marketingFee = _previousMarketingFee;
        totalSwapableFee = _liquidityFee + _devFee + _marketingFee;
    }

    function setAllFeePercent(uint256 taxFee, uint256 liquidityFee, uint256 devFee, uint256 marketingFee) 
    external onlyOwner() 
    {
        _taxFee = taxFee;
        _previousTaxFee = _taxFee;
        _liquidityFee = liquidityFee;
        _previousLiquidityFee = _liquidityFee;
        _devFee = devFee;
        _previousDevFee = _devFee;
        _marketingFee = marketingFee;
        _previousMarketingFee = _marketingFee;
        totalSwapableFee = _taxFee + _liquidityFee + _devFee + _marketingFee ; 
        require(taxFee > 0 && liquidityFee > 0 && devFee > 0 && marketingFee > 0, "All fee Must be greater than 0");
        require(totalSwapableFee <= 30, "Must be less than 30% total");
        emit Log("We have updated total buy tax", totalSwapableFee);
    }

    function setSaleFeePercent(uint256 taxFee, uint256 liquidityFee, uint256 devFee, uint256 marketingFee) 
    external onlyOwner() 
    {
        _saleTaxFee = taxFee;
        _saleLiquidityFee = liquidityFee;
        _saleDevFee = devFee;
        _saleMarketingFee = marketingFee;

        totalSwapableSaleFee = _saleTaxFee + _saleLiquidityFee + _saleDevFee + _saleMarketingFee;
        require(taxFee > 0 && liquidityFee > 0 && devFee > 0 && marketingFee > 0, "All fee Must be greater than 0");
        require(totalSwapableSaleFee <= 30, "Must be less than 30% total");
        emit Log("We have updated total sale tax", totalSwapableSaleFee);
    }

    function setTransferFeePercent (uint256 taxFee, uint256 liquidityFee, uint256 devFee, uint256 marketingFee)
    external onlyOwner()
    {
        _transferTaxFee = taxFee;
        _transferLiquidityFee = liquidityFee;
        _transferDevFee = devFee;
        _transferMarketingFee = marketingFee;

        totalSwapableTransferFee = _transferTaxFee + _transferLiquidityFee + _transferDevFee + _transferMarketingFee;
        require(taxFee > 0 && liquidityFee > 0 && devFee > 0 && marketingFee > 0, "All fee Must be greater than 0");
        require(totalSwapableTransferFee <= 25, "Must be less than 25% total");
        emit Log("We have updated total transfer tax", totalSwapableSaleFee);
    }

    function isExcludedFromFee(address account) external view returns(bool) {
        return _isExcludedFromFee[account];
    }

    
    function setExcludeFromFee(address account, bool _flag) external onlyOwner {
        _isExcludedFromFee[account] = _flag;
        emit AuditLog("We have excluded the following walled in fees:", account);
    }
    
    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
        emit AuditLog("We have include the following walled in fees:", account);
    }

    function setNumTokensSellToAddToLiquidity(uint256 _minimumTokensBeforeSwap) external onlyOwner() {
        minimumTokensBeforeSwap = _minimumTokensBeforeSwap;
        emit Log("We have updated minimunTokensBeforeSwap to:", minimumTokensBeforeSwap);
    }

    function setMarketingWalletAddress(address _marketingWallet) external onlyOwner() {
        require(_marketingWallet != address(0), "setMarketingWalletAddress: ZERO");
        marketingWalletAddress = payable(_marketingWallet);
        emit AuditLog("We have Updated the MarketingWallet:", marketingWalletAddress);
    }

    function setDevWalletAddress(address _devWallet) external onlyOwner() {
        require(_devWallet != address(0), "setDevWalletAddress: ZERO");
        devWalletAddress = payable(_devWallet);
        emit AuditLog("We have Updated the DevWallet:", devWalletAddress);

    }

    function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);

    }

    function setBlacklisted(address bot, bool flag) external onlyOwner {
        _isBlacklisted[bot] = flag;
    }
    
    
    function transferToAddressETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }
    
     //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

/////---dev----////    
    event SwapETHForTokens(uint256 amountIn, address[] path);
   
    address public constant deadAddress = 0x000000000000000000000000000000000000dEaD;


    function swapETHForTokens(uint256 amount) private 
    {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);
      // make the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0, // accept any amount of Tokens
            path, deadAddress, // Burn address
            block.timestamp + 300);
        emit SwapETHForTokens(amount, path);
    }
 

    function manualBurn(uint256 burnAmount) external onlyOwner
    {
        removeAllFee();
         _tTotal = _tTotal - burnAmount;
        _transferStandard(owner(), deadWallet, burnAmount);
        restoreAllFee();
        emit Log("We have manually burned a Total Of:", burnAmount);
    
    }


}