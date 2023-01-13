/**
 *Submitted for verification at Etherscan.io on 2023-01-13
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

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

    event Mint(address indexed sender, uint amount0, uint amount1);
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

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
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

library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
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

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
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

    function balanceOf(address account) public view virtual override returns (uint256) {
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

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
            unchecked {
                _approve(sender, _msgSender(), currentAllowance - amount);
            }
        }

        _transfer(sender, recipient, amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

contract Feathers is ERC20, Ownable {
    using Address for address payable;

    IUniswapV2Router02 public uniswapV2Router;
    address public  uniswapV2Pair;

    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => uint256) private _holdingTime;

    uint256 public  liquidityFeeOnBuy;
    uint256 public  liquidityFeeOnSell;

    uint256 public  marketingFeeOnBuy;
    uint256 public  marketingFeeOnSell;

    uint256 public  treasuryFeeOnBuy;
    uint256 public  treasuryFeeOnSell;

    uint256 public  burnFee;

    uint256 private _totalFeesOnBuy;
    uint256 private _totalFeesOnSell;

    uint256 private burnTokens;
    uint256 private lastBurn;

    uint256 private maxFee;

    uint256 public  walletToWalletTransferFee;

    address public  marketingWallet;
    address public  teamCEXWallet;
    address public  deploymentWallet;
    address public  treasuryWallet;

    uint256 public  swapTokensAtAmount;
    bool    private swapping;

    bool    public swapEnabled;
    uint256 public voteLimit;
    bool    public burnEnabled;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event MarketingWalletChanged(address marketingWallet);
    event SwapAndLiquify(uint256 tokensSwapped,uint256 bnbReceived,uint256 tokensIntoLiqudity);
    event SwapAndSendMarketing(uint256 tokensSwapped, uint256 bnbSend);
    event SwapTokensAtAmountUpdated(uint256 swapTokensAtAmount);

    constructor () ERC20("Feathers", "FTS") 
    {   
        address router;
        if (block.chainid == 56) {
            router = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // BSC Pancake Mainnet Router
        } else if (block.chainid == 97) {
            router = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1; // BSC Pancake Testnet Router
        } else if (block.chainid == 1 || block.chainid == 5) {
            router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // ETH Uniswap Mainnet % Testnet
        } else {
            revert();
        }

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(router);
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair   = _uniswapV2Pair;

        _approve(address(this), address(uniswapV2Router), type(uint256).max);

        liquidityFeeOnBuy  = 9;
        liquidityFeeOnSell = 9;

        marketingFeeOnBuy  = 26;
        marketingFeeOnSell = 26;

        treasuryFeeOnBuy = 4;
        treasuryFeeOnSell = 4;

        burnFee = 1; 

        maxFee             = 100;

        _totalFeesOnBuy    = liquidityFeeOnBuy  + marketingFeeOnBuy + treasuryFeeOnBuy;
        _totalFeesOnSell   = liquidityFeeOnSell + marketingFeeOnSell + treasuryFeeOnSell;

        walletToWalletTransferFee = 0;

        marketingWallet = 0xD098139c1f75D9646d6575E6fEABeEe479e4326a;
        teamCEXWallet = 0x63D398E418E2FA407dF8bd1fCBc841ebcAE2dfa8;
        deploymentWallet = 0xE4026Eed0Dc86d94c22EeFee59e7CECa98F315ED;
        treasuryWallet = 0x588075505988cc2501f39077897B5B1e056b0C93;

        maxTransactionLimitEnabled = true;

        _isExcludedFromMaxTxLimit[owner()] = true;
        _isExcludedFromMaxTxLimit[address(this)] = true;
        _isExcludedFromMaxTxLimit[address(0xdead)] = true;
        _isExcludedFromMaxTxLimit[marketingWallet] = true;
        _isExcludedFromMaxTxLimit[teamCEXWallet] = true;
        _isExcludedFromMaxTxLimit[deploymentWallet] = true;
        _isExcludedFromMaxTxLimit[treasuryWallet] = true;

        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(0xdead)] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[marketingWallet] = true;
        _isExcludedFromFees[teamCEXWallet] = true;
        _isExcludedFromFees[deploymentWallet] = true;
        _isExcludedFromFees[treasuryWallet] = true;

        _mint(owner(), 1e8 * (10 ** decimals()));
        swapTokensAtAmount = totalSupply() / 5_000;

        maxTransactionAmountBuy     = totalSupply() * 10 / 1000;
        maxTransactionAmountSell    = totalSupply() * 10 / 1000;
        voteLimit = totalSupply() / 1000;

        tradingEnabled = false;
        swapEnabled = false;
        burnEnabled = false;
    }

    receive() external payable {}

    function claimStuckTokens(address token) external onlyOwner {
        require(token != address(this), "Owner cannot claim contract's balance of its own tokens");
        if (token == address(0x0)) {
            payable(msg.sender).sendValue(address(this).balance);
            return;
        }
        IERC20 ERC20token = IERC20(token);
        uint256 balance = ERC20token.balanceOf(address(this));
        ERC20token.transfer(msg.sender, balance);
    }

    /////////////////////////////////////// FEE SYSTEM

    function excludeFromFees(address account, bool excluded) external onlyOwner{
        require(_isExcludedFromFees[account] != excluded,"Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function viewHoldingTime(address account) public view returns(uint256) {
        return _holdingTime[account];
    }

    function updateVoteLimit(uint256 _voteLimit) external onlyOwner {
        voteLimit = _voteLimit;
    }

    function updateBurnFee(uint256 _burnFee) external onlyOwner {
        burnFee = _burnFee;
        require(_burnFee < 5, "Cannot burn more than 5% per transaction");
    }

    function updateBuyFees(uint256 _liquidityFeeOnBuy, uint256 _marketingFeeOnBuy, uint256 _treasuryFeeOnBuy) external onlyOwner {
        liquidityFeeOnBuy = _liquidityFeeOnBuy;
        marketingFeeOnBuy = _marketingFeeOnBuy;
        treasuryFeeOnBuy = _treasuryFeeOnBuy;

        _totalFeesOnBuy    = liquidityFeeOnBuy  + marketingFeeOnBuy + treasuryFeeOnBuy;

        require(_totalFeesOnBuy <= maxFee, "Total Fees cannot exceed the maximum");
    }

    function updateSellFees(uint256 _liquidityFeeOnSell, uint256 _marketingFeeOnSell, uint256 _treasuryFeeOnSell) external onlyOwner {
        liquidityFeeOnSell = _liquidityFeeOnSell;
        marketingFeeOnSell = _marketingFeeOnSell;
        treasuryFeeOnSell = _treasuryFeeOnSell;

        _totalFeesOnSell   = liquidityFeeOnSell + marketingFeeOnSell + treasuryFeeOnSell;

        require(_totalFeesOnSell <= maxFee, "Total Fees cannot exceed the maximum");
    }

    function updateWalletToWalletTransferFee(uint256 _walletToWalletTransferFee) external onlyOwner {
        require(_walletToWalletTransferFee <= maxFee, "Wallet to Wallet Transfer Fee cannot exceed the maximum");
        walletToWalletTransferFee = _walletToWalletTransferFee;
    }

    function changeMarketingWallet(address _marketingWallet) external onlyOwner{
        require(_marketingWallet != marketingWallet,"Marketing wallet is already that address");
        require(_marketingWallet != address(0),"Marketing wallet cannot be the zero address");
        marketingWallet = _marketingWallet;

        emit MarketingWalletChanged(marketingWallet);
    }

    bool public tradingEnabled;

    function enableTrading() external onlyOwner{
        require(!tradingEnabled, "Trading already enabled.");
        tradingEnabled = true;
        swapEnabled = true;
        burnEnabled = true;
        lastBurn = block.timestamp;
    }
    
    function _transfer(address from,address to,uint256 amount) internal  override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(tradingEnabled || _isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading not yet enabled!");
       
        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (maxTransactionLimitEnabled) 
        {
            if ((from == uniswapV2Pair || to == uniswapV2Pair) &&
                !_isExcludedFromMaxTxLimit[from] && 
                !_isExcludedFromMaxTxLimit[to]
            ) {
                if (from == uniswapV2Pair) {
                    require(
                        amount <= maxTransactionAmountBuy,  
                        "AntiWhale: Transfer amount exceeds the maxTransactionAmount"
                    );
                } else {
                    require(
                        amount <= maxTransactionAmountSell, 
                        "AntiWhale: Transfer amount exceeds the maxTransactionAmount"
                    );
                }
            }
        }

        if (burnTokens > 0 && (lastBurn + 1 hours < block.timestamp) && burnEnabled) {
            lastBurn = block.timestamp;
            super._transfer(address(this), address(0xdead), burnTokens);
            burnTokens = 0;
        }

        uint256 contractTokenBalance = balanceOf(address(this)) - burnTokens;

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (canSwap &&
            !swapping &&
            to == uniswapV2Pair &&
            _totalFeesOnBuy + _totalFeesOnSell > 0 &&
            swapEnabled
        ) {
            swapping = true;
            contractTokenBalance = swapTokensAtAmount;

            uint256 totalFee = _totalFeesOnBuy + _totalFeesOnSell;

            uint256 liquidityShare = liquidityFeeOnBuy + liquidityFeeOnSell;
            uint256 marketingShare = marketingFeeOnBuy + marketingFeeOnSell;
            uint256 treasuryShare = treasuryFeeOnBuy + treasuryFeeOnSell;

            if (liquidityShare > 0) {
                uint256 liquidityTokens = contractTokenBalance * liquidityShare / totalFee;
                swapAndLiquify(liquidityTokens);
            }
            
            if (marketingShare + treasuryShare> 0) {
                uint256 marketingTokens = contractTokenBalance * (marketingShare + treasuryShare) / totalFee;
                swapAndSendMarketing(marketingTokens);
            }          

            swapping = false;
        }

        uint256 _totalFees;
        uint256 _burnFee;
        
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to] || swapping) {
            _totalFees = 0;
            _burnFee = 0;
        } else if (from == uniswapV2Pair) {
            _totalFees = _totalFeesOnBuy;
            _burnFee = burnFee * amount / 1000;
        } else if (to == uniswapV2Pair) {
            _totalFees = _totalFeesOnSell;
            _burnFee = burnFee * amount / 1000;
        } else {
            _totalFees = walletToWalletTransferFee;
        }

        if (_totalFees > 0) {
            uint256 fees = (amount * _totalFees) / 1000;

            amount = amount - fees;
            super._transfer(from, address(this), fees);

        }

        if (_burnFee > 0) {
            amount = amount - _burnFee;
            burnTokens += _burnFee;

            super._transfer(from, address(this), _burnFee);
        }

        super._transfer(from, to, amount);

        if(balanceOf(to) >= voteLimit && _holdingTime[to] == 0){
            _holdingTime[to] = block.timestamp;
        } else if (balanceOf(to) < voteLimit){
            _holdingTime[to]  = 0;
        }

        if(balanceOf(from) >= voteLimit && _holdingTime[from] == 0){
            _holdingTime[from] = block.timestamp;
        } else if (balanceOf(from) < voteLimit){
            _holdingTime[from]  = 0;
        }
    }

    /////////////////////////////////////// SWAP SYSTEM

    function setSwapEnabled(bool _enabled) external onlyOwner{
        require(swapEnabled != _enabled, "swapEnabled already at this state.");
        swapEnabled = _enabled;
    }

    function setSwapTokensAtAmount(uint256 newAmount) external onlyOwner{
        require(newAmount > totalSupply() / 1_000_000, "SwapTokensAtAmount must be greater than 0.0001% of total supply");
        swapTokensAtAmount = newAmount;

        emit SwapTokensAtAmountUpdated(swapTokensAtAmount);
    }

    function swapAndLiquify(uint256 tokens) private {
        uint256 half = tokens / 2;
        uint256 otherHalf = tokens - half;

        uint256 initialBalance = address(this).balance;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            half,
            0,
            path,
            address(this),
            block.timestamp);
        
        uint256 newBalance = address(this).balance - initialBalance;

        uniswapV2Router.addLiquidityETH{value: newBalance}(
            address(this),
            otherHalf,
            0,
            0,
            address(0xdead),
            block.timestamp
        );

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapAndSendMarketing(uint256 tokenAmount) private {
        uint256 initialBalance = address(this).balance;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp);

        uint256 newBalance = address(this).balance - initialBalance;

        uint256 marketingShare = marketingFeeOnBuy + marketingFeeOnSell;
        uint256 treasuryShare = treasuryFeeOnBuy + treasuryFeeOnSell;

        uint256 totalShare = marketingShare + treasuryShare;

        uint256 marketingETH = newBalance * marketingShare / totalShare;
        uint256 treasuryETH = newBalance - marketingETH;

        payable(marketingWallet).sendValue(marketingETH);
        payable(treasuryWallet).sendValue(treasuryETH);

        emit SwapAndSendMarketing(tokenAmount, newBalance);
    }

    /////////////////////////////////////// MAX-TRANSACTION SYSTEM

    mapping(address => bool) private _isExcludedFromMaxTxLimit;
    bool    public  maxTransactionLimitEnabled;
    uint256 public  maxTransactionAmountBuy;
    uint256 public  maxTransactionAmountSell;

    event ExcludedFromMaxTransactionLimit(address indexed account, bool isExcluded);
    event MaxTransactionLimitStateChanged(bool maxTransactionLimit);
    event MaxTransactionLimitAmountChanged(uint256 maxTransactionAmountBuy, uint256 maxTransactionAmountSell);

    function setEnableMaxTransactionLimit(bool enable) external onlyOwner {
        require(enable != maxTransactionLimitEnabled, "Max transaction limit is already set to that state");
        maxTransactionLimitEnabled = enable;

        emit MaxTransactionLimitStateChanged(maxTransactionLimitEnabled);
    }

    function setMaxTransactionAmounts(uint256 _maxTransactionAmountBuy, uint256 _maxTransactionAmountSell) external onlyOwner {
        require(
            _maxTransactionAmountBuy  >= (totalSupply() / (10 ** decimals())) / 1_000 && 
            _maxTransactionAmountSell >= (totalSupply() / (10 ** decimals())) / 1_000, 
            "Max Transaction limis cannot be lower than 0.1% of total supply"
        ); 
        maxTransactionAmountBuy  = _maxTransactionAmountBuy  * (10 ** decimals());
        maxTransactionAmountSell = _maxTransactionAmountSell * (10 ** decimals());

        emit MaxTransactionLimitAmountChanged(maxTransactionAmountBuy, maxTransactionAmountSell);
    }

    function excludeFromMaxTransactionLimit(address account, bool exclude) external onlyOwner {
        require( _isExcludedFromMaxTxLimit[account] != exclude, "Account is already set to that state");
        _isExcludedFromMaxTxLimit[account] = exclude;

        emit ExcludedFromMaxTransactionLimit(account, exclude);
    }

    function isExcludedFromMaxTransaction(address account) public view returns(bool) {
        return _isExcludedFromMaxTxLimit[account];
    }
}