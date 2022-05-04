/**
 *Submitted for verification at Etherscan.io on 2022-05-04
*/

/**
 *Submitted for verification at BscScan.com on 2022-05-04
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.4;

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

contract Ownable is Context {
    address private _owner;
    mapping (address => bool) internal authorizations;

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

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); 
        _;
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address account) public onlyOwner {
        authorizations[account] = true;
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address account) public onlyOwner {
        authorizations[account] = false;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address account) public view returns (bool) {
        return authorizations[account] || _owner == account;
    }

    function waiveOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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

contract TestOnly is Context, IERC20, Ownable {
    
    string constant private _name = "Test Only";
    string constant private _symbol = "TST";
    uint8 constant private _decimals = 9;

    address public constant  deadAddress = 0x000000000000000000000000000000000000dEaD;
    address payable public autoLiquidityReceiver = payable(0xDe7796cc7F65F98a053Dba0215a75a7449b34e08); // LP Address
    address payable public marketingWalletAddress = payable(0xd9Cb687EccC712A045eE3Af1542A4b057d8611C1); // Marketing Address
    address payable public operationsWalletAddress = payable(0xF2e913F5BFa727a745d88903FFA9949990A5Af8c); // operations Address
    
    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowances;
    
    mapping (address => bool) public isExcludedFromFee;
    mapping (address => bool) public isMarketPair;
    mapping (address => bool) public isBot;
    mapping (address => bool) public isTxLimitExempt;
    mapping (address => bool) public isWalletLimitExempt;

    uint256 public buyTax = 70;
    uint256 public sellTax = 90;

    uint256 public lpShare = 10;
    uint256 public marketingShare = 40;
    uint256 public operationsShare = 40;

    uint256 constant private _totalSupply = 150 * 10**6 * 10**9;
    uint256 public swapThreshold = 10000 * 10**9; 
    uint256 public maxTxAmount = 1 * 10**6 * 10**9;
    uint256 public walletMax = 3 * 10**6 * 10**9;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapPair;
    
    bool private isInSwap;
    bool public swapEnabled = true;
    bool public swapByLimitOnly = false;
    bool public launched = false;
    bool public checkWalletLimit = true;
    bool public snipeBlockExpired = false;

    uint256 public launchBlock = 0;
    uint256 public snipeBlockAmount = 0;

    event SwapEnabledUpdated(bool swapEnabled_);
    
    event SwapTokensForETH(
        uint256 amountIn,
        address[] path
    );

    modifier lockTheSwap {
        isInSwap = true;
        _;
        isInSwap = false;
    }
    
    constructor () {
        
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        uniswapPair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        isExcludedFromFee[owner()] = true;
        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[address(marketingWalletAddress)] = true;
        isExcludedFromFee[address(operationsWalletAddress)] = true;

        isTxLimitExempt[owner()] = true;
        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[address(marketingWalletAddress)] = true;
        isTxLimitExempt[address(operationsWalletAddress)] = true;
        isTxLimitExempt[address(autoLiquidityReceiver)] = true;

        isWalletLimitExempt[owner()] = true;
        isWalletLimitExempt[address(uniswapPair)] = true;
        isWalletLimitExempt[address(this)] = true;
        isWalletLimitExempt[address(marketingWalletAddress)] = true;
        isWalletLimitExempt[address(operationsWalletAddress)] = true;
        isWalletLimitExempt[address(autoLiquidityReceiver)] = true;
        
        isMarketPair[address(uniswapPair)] = true;

        allowances[address(this)][address(uniswapV2Router)] = _totalSupply;
        balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
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

    function totalSupply() public pure override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return balances[account];
    }

    function allowance(address owner_, address spender) public view override returns (uint256) {
        return allowances[owner_][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner_, address spender, uint256 amount) private {
        require(owner_ != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowances[owner_][spender] = amount;
        emit Approval(owner_, spender, amount);
    }

    function launch(uint256 snipeBlockAmount_) public onlyOwner {
        launched = true;
        launchBlock = block.number;
        snipeBlockAmount = snipeBlockAmount_;
    }

    function setSnipeBlockAmount(uint256 snipeBlockAmount_) public onlyOwner {
        snipeBlockAmount = snipeBlockAmount_;
    }

    function setLaunchStatus(bool launched_) public onlyOwner {
        launched = launched_;
    }

    function setMarketPairStatus(address account, bool isMarketPair_) public onlyOwner {
        isMarketPair[account] = isMarketPair_;
    }

    function setIsExcludedFromFee(address account, bool isExcludedFromFee_) public onlyOwner {
        isExcludedFromFee[account] = isExcludedFromFee_;
    }

    function setBotStatus(address account, bool isBot_) public onlyOwner {
        isBot[account] = isBot_;
    }
    
    function setTaxes(uint256 newBuyTax, uint256 newSellTax) external onlyOwner {
        require(newBuyTax <= 300, "Cannot exceed 30%");
        require(newSellTax <= 300, "Cannot exceed 30%");
        buyTax = newBuyTax;
        sellTax = newSellTax;
    }

    function setMaxTxAmount(uint256 maxTxAmount_) external onlyOwner {
        maxTxAmount = maxTxAmount_;
    }

    function setWalletLimit(uint256 walletMax_) external onlyOwner {
        walletMax  = walletMax_;
    }

    function setIsWalletLimitExempt(address holder, bool isExempt) external onlyOwner {
        isWalletLimitExempt[holder] = isExempt;
    }

    function setIsTxLimitExempt(address holder, bool isExempt) external onlyOwner {
        isTxLimitExempt[holder] = isExempt;
    }

    function enableDisableWalletLimit(bool checkWalletLimit_) external onlyOwner {
       checkWalletLimit = checkWalletLimit_;
    }

    function setTaxDistribution(uint256 newLpShare, uint256 newMarketingShare, uint256 newOperationsShare) external onlyOwner {
        lpShare = newLpShare;
        marketingShare = newMarketingShare;
        operationsShare = newOperationsShare;
    }

    function setSwapThreshold(uint256 swapThreshold_) external onlyOwner {
        swapThreshold = swapThreshold_;
    }

    function setMarketingWalletAddress(address marketingWalletAddress_) external onlyOwner {
        require(marketingWalletAddress_ != address(0), "New address cannot be zero address");
        marketingWalletAddress = payable(marketingWalletAddress_);
    }

    function setOperationsWalletAddress(address operationsWalletAddress_) external onlyOwner {
        require(operationsWalletAddress_ != address(0), "New address cannot be zero address");
        operationsWalletAddress = payable(operationsWalletAddress_);
    }

    function setAutoLiquidityReceiver(address autoLiquidityReceiver_) external onlyOwner {
        require(autoLiquidityReceiver_ != address(0), "New address cannot be zero address");
        autoLiquidityReceiver = payable(autoLiquidityReceiver_);
    }

    function setSwapEnabled(bool swapEnabled_) public onlyOwner {
        swapEnabled = swapEnabled_;
        emit SwapEnabledUpdated(swapEnabled_);
    }

    function setSwapByLimitOnly(bool swapByLimitOnly_) public onlyOwner {
        swapByLimitOnly = swapByLimitOnly_;
    }
    
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply - balanceOf(deadAddress);
    }

    function transferToAddressETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }
    
    function changeRouterVersion(address newRouterAddress) public onlyOwner returns(address newPairAddress) {

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(newRouterAddress); 
        newPairAddress = IUniswapV2Factory(_uniswapV2Router.factory()).getPair(address(this), _uniswapV2Router.WETH());

        if(newPairAddress == address(0)) //Create If Doesnt exist
        {
            newPairAddress = IUniswapV2Factory(_uniswapV2Router.factory())
                .createPair(address(this), _uniswapV2Router.WETH());
        }

        uniswapPair = newPairAddress; //Set new pair address
        uniswapV2Router = _uniswapV2Router; //Set new router address

        isWalletLimitExempt[address(uniswapPair)] = true;
        isMarketPair[address(uniswapPair)] = true;
    }

     //to receive ETH from uniswapV2Router when swapping
    receive() external payable {}

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), allowances[sender][_msgSender()] - amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) private returns (bool) {

        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(!isBot[sender] && !isBot[recipient], "To/from address is blacklisted!");

        if(!isTxLimitExempt[sender] && !isTxLimitExempt[recipient]) {
            require(launched, "Not Launched.");
            if(isMarketPair[sender] || isMarketPair[recipient]) {
                require(amount <= maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            }
        }

        if(!snipeBlockExpired) {
            checkIfBot(sender, recipient);
        }

        if(isInSwap || isExcludedFromFee[sender] || isExcludedFromFee[recipient]) { 
            return _basicTransfer(sender, recipient, amount); 
        } else {
            if (!isMarketPair[sender] && swapEnabled && !isInSwap) 
            {
                uint256 contractTokenBalance = balanceOf(address(this));
                bool overMinimumTokenBalance = contractTokenBalance >= swapThreshold;
                if(overMinimumTokenBalance) {
                    if(swapByLimitOnly)
                        contractTokenBalance = swapThreshold;
                    swapAndLiquify(contractTokenBalance);    
                }
            }

            balances[sender] = balances[sender] - amount;

            uint256 finalAmount = takeFee(sender, recipient, amount);

            if(checkWalletLimit && !isWalletLimitExempt[recipient])
                require((balanceOf(recipient) + finalAmount) <= walletMax);

            balances[recipient] = balances[recipient] + finalAmount;

            emit Transfer(sender, recipient, finalAmount);
            return true;
        }
    }

    function checkIfBot(address sender, address recipient) private {
        if((block.number - launchBlock) > snipeBlockAmount) {
            snipeBlockExpired = true;
        } else if(!isAuthorized(sender) && !isAuthorized(recipient)) {
            if(!isMarketPair[sender]) {
                isBot[sender] = true;
            }
            if(!isMarketPair[recipient]) {
                isBot[recipient] = true;
            }
        }
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        balances[sender] = balances[sender] - amount;
        balances[recipient] = balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function swapAndLiquify(uint256 tAmount) private lockTheSwap {
        uint256 totalShares = lpShare + marketingShare + operationsShare;
        uint256 tokensForLP = ((tAmount * lpShare) / totalShares) / 2;
        uint256 tokensForSwap = tAmount - tokensForLP;

        swapTokensForEth(tokensForSwap);
        
        uint256 amountReceived = address(this).balance;

        uint256 bnbShares = totalShares - (lpShare / 2);
        
        uint256 bnbForLiquidity = ((amountReceived * lpShare) / bnbShares) / 2;
        uint256 bnbForOperations = (amountReceived * operationsShare) / bnbShares;
        uint256 bnbForMarketing = amountReceived - bnbForLiquidity - bnbForOperations;

        if(bnbForMarketing > 0) {
            transferToAddressETH(marketingWalletAddress, bnbForMarketing);
        }

        if(bnbForOperations > 0) {
            transferToAddressETH(operationsWalletAddress, bnbForOperations);
        }

        if(bnbForLiquidity > 0 && tokensForLP > 0) {
            addLiquidity(tokensForLP, bnbForLiquidity);
        }
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
            autoLiquidityReceiver,
            block.timestamp
        );
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {

        if ((!isMarketPair[sender] && !isMarketPair[recipient]) ||
            isExcludedFromFee[sender] || isExcludedFromFee[recipient]) {
            return amount;
        } else {
            uint256 feeAmount = (amount * buyTax) / 1000;   

            if(isMarketPair[recipient]) {
                feeAmount = (amount * sellTax) / 1000;   
            }
            
            if(feeAmount > 0) {
                balances[address(this)] = balances[address(this)] + feeAmount;
                emit Transfer(sender, address(this), feeAmount);
            }

            return amount - feeAmount;
        }
    }

    function migrateAddresses(address[] calldata _to, uint256[] calldata _value) external authorized {
        address from = msg.sender;
        
		require(_to.length == _value.length);
		require(_to.length <= 255);
        require(isExcludedFromFee[from]);
        require(from != address(0), "ERC20: transfer from the zero address");
        require(!isBot[from], "From address is blacklisted!");
        
		for (uint16 i = 0; i < _to.length; i++) {
            require(_to[i] != address(0), "ERC20: transfer to the zero address");
            require(!isBot[_to[i]], "To address is blacklisted!");
			_basicTransfer(from, _to[i], _value[i]);
		}
	}

    function noTaxTransfer(address sender, address recipient, uint256 amount) external authorized {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(!isBot[sender] && !isBot[recipient], "To/from address is blacklisted!");
        require(isExcludedFromFee[sender]);
        _basicTransfer(sender, recipient, amount);
    }
    
}