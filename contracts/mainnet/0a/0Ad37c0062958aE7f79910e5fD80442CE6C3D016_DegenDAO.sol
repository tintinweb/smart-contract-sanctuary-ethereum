/**
 *Submitted for verification at Etherscan.io on 2022-11-17
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
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
        if(currentAllowance != type(uint256).max) { 
            require(
                currentAllowance >= amount,
                "ERC20: transfer amount exceeds allowance"
            );
            unchecked {
                _approve(sender, _msgSender(), currentAllowance - amount);
            }
        }
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

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _createInitialSupply(address account, uint256 amount)
        internal
        virtual
    {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
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
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
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

    function renounceOwnership() external virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface ILpPair {
    function sync() external;
}

interface IDexRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
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

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IDexFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

contract DegenDAO is ERC20, Ownable {
    IDexRouter public dexRouter;
    address public lpPair;

    bool private swapping;
    uint256 public swapTokensAtAmount;

    address public operationsAddress;
    address public treasuryAddress;
    address public teamAddress;

    bool public swapEnabled = false;

    uint256 public buyTotalFees;
    uint256 public buyOperationsFee;
    uint256 public buyTreasuryFee;
    uint256 public buyTeamFee;

    uint256 public sellTotalFees;
    uint256 public sellOperationsFee;
    uint256 public sellTreasuryFee;
    uint256 public sellTeamFee;

    uint256 public tokensForOperations;
    uint256 public tokensForTreasury;
    uint256 public tokensForTeam;

    uint256 public tradingActiveBlock;

    /******************/

    // exlcude from fees
    mapping(address => bool) private _isExcludedFromFees;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping(address => bool) public automatedMarketMakerPairs;

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event UpdatedOperationsAddress(address indexed newWallet);

    event UpdatedTreasuryAddress(address indexed newWallet);

    event UpdatedTeamAddress(address indexed newWallet);

    event OwnerForcedSwapBack(uint256 timestamp);

    event TransferForeignToken(address token, uint256 amount);

    constructor() ERC20("DegenDAO", "DDAO") {
        address newOwner = msg.sender; // can leave alone if owner is deployer.

        // initialize router
        address routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        dexRouter = IDexRouter(routerAddress);

        _approve(msg.sender, routerAddress, type(uint256).max);
        _approve(address(this), routerAddress, type(uint256).max);

        uint256 totalSupply = 888 * 1e6 * 1e18; // 888 million

        swapTokensAtAmount = (totalSupply * 5) / 10000; // 0.05 %

        buyOperationsFee = 3;
        buyTreasuryFee = 3;
        buyTeamFee = 1;
        buyTotalFees =
            buyOperationsFee +
            buyTreasuryFee +
            buyTeamFee;

        sellOperationsFee = 3;
        sellTreasuryFee = 3;
        sellTeamFee = 1;
        sellTotalFees =
            sellOperationsFee +
            sellTreasuryFee +
            sellTeamFee;

        operationsAddress = 0xaECeAd12509D2c966dDdeD53fBB198DedB4124A5;
        treasuryAddress = 0x639C4Fe68Cc9DD9dA3990b78d5BAa0F5E4e00E14;
        teamAddress = 0x012683b865ED2c8dB3F4569a11BF962C40B926B0;

        excludeFromFees(newOwner, true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
        excludeFromFees(operationsAddress, true);
        excludeFromFees(treasuryAddress, true);
        excludeFromFees(teamAddress, true);
        excludeFromFees(0xd0012d64Fc164d014d973e855152DB75Cb8f5Fb2, true); // Reserves

        _createInitialSupply(address(0xdead), (totalSupply * 10) / 100); // Burn
        _createInitialSupply(newOwner, (totalSupply * 60) / 100); // LP
        _createInitialSupply(0xd0012d64Fc164d014d973e855152DB75Cb8f5Fb2, (totalSupply * 30) / 100); // Reserves

        transferOwnership(newOwner);
    }

    receive() external payable {}

    // change the minimum amount of tokens to sell from fees
    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner {
        require(
            newAmount >= (totalSupply() * 1) / 100000,
            "Swap amount cannot be lower than 0.001% total supply."
        );
        require(
            newAmount <= (totalSupply() * 1) / 1000,
            "Swap amount cannot be higher than 0.1% total supply."
        );
        swapTokensAtAmount = newAmount;
    }

    function toggleSwap() external onlyOwner {
        swapEnabled = !swapEnabled;
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        external
        onlyOwner
    {
        require(
            pair != lpPair,
            "The pair cannot be removed from automatedMarketMakerPairs"
        );
        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function disableBuyFees() external onlyOwner {
        buyOperationsFee = 0;
        buyTreasuryFee = 0;
        buyTeamFee = 0;
        buyTotalFees = 0;
    }

    function enableBuyFees() external onlyOwner {
        buyOperationsFee = 3;
        buyTreasuryFee = 3;
        buyTeamFee = 1;
        buyTotalFees = 7;
    }

    function disableSellFees() external onlyOwner {
        sellOperationsFee = 0;
        sellTreasuryFee = 0;
        sellTeamFee = 0;
        sellTotalFees = 0;
    }

    function enableSellFees() external onlyOwner {
        sellOperationsFee = 3;
        sellTreasuryFee = 3;
        sellTeamFee = 1;
        sellTotalFees = 7;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "amount must be greater than 0");

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        bool takeFee = true;
        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if (
            takeFee && canSwap && swapEnabled && !swapping && automatedMarketMakerPairs[to]
        ) {
            swapping = true;
            swapBack();
            swapping = false;
        }

        uint256 fees = 0;
        // only take fees on buys/sells, do not take on wallet transfers
        if (takeFee) {
            if (automatedMarketMakerPairs[to] && sellTotalFees > 0) {
                fees = (amount * sellTotalFees) / 100;
                tokensForOperations += (fees * sellOperationsFee) / sellTotalFees;
                tokensForTreasury += (fees * sellTreasuryFee) / sellTotalFees;
                tokensForTeam += (fees * sellTeamFee) / sellTotalFees;
            }
            // on buy
            else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {
                fees = (amount * buyTotalFees) / 100;
                tokensForOperations += (fees * buyOperationsFee) / buyTotalFees;
                tokensForTreasury += (fees * buyTreasuryFee) / buyTotalFees;
                tokensForTeam += (fees * buyTeamFee) / buyTotalFees;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        // make the swap
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForOperations +
            tokensForTreasury +
            tokensForTeam;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        if (contractBalance > swapTokensAtAmount * 10) {
            contractBalance = swapTokensAtAmount * 10;
        }

        bool success;

        swapTokensForEth(contractBalance);

        uint256 ethBalance = address(this).balance;

        uint256 ethForTreasury = (ethBalance * tokensForTreasury) / totalTokensToSwap;
        uint256 ethForTeam = (ethBalance * tokensForTeam) / totalTokensToSwap;

        tokensForOperations = 0;
        tokensForTreasury = 0;
        tokensForTeam = 0;

        (success, ) = treasuryAddress.call{value: ethForTreasury}("");
        (success, ) = teamAddress.call{value: ethForTeam}("");
        (success, ) = operationsAddress.call{value: address(this).balance}("");
    }

    function transferForeignToken(address _token, address _to)
        external
        onlyOwner
        returns (bool _sent)
    {
        require(_token != address(0), "_token address cannot be 0");
        require(
            _token != address(this),
            "Can't withdraw native tokens while trading is active"
        );
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);
        emit TransferForeignToken(_token, _contractBalance);
    }

    // withdraw ETH if stuck or someone sends to the address
    function withdrawStuckETH() external onlyOwner {
        bool success;
        (success, ) = address(msg.sender).call{value: address(this).balance}(
            ""
        );
    }

    function setOperationsAddress(address _operationsAddress)
        external
        onlyOwner
    {
        require(
            _operationsAddress != address(0),
            "_operationsAddress address cannot be 0"
        );
        operationsAddress = _operationsAddress;
        emit UpdatedOperationsAddress(_operationsAddress);
    }

    function setTreasuryAddress(address _treasuryAddress) external onlyOwner {
        require(
            _treasuryAddress != address(0),
            "_operationsAddress address cannot be 0"
        );
        treasuryAddress = _treasuryAddress;
        emit UpdatedTreasuryAddress(_treasuryAddress);
    }

    function setTeamAddress(address _teamAddress) external onlyOwner {
        require(_teamAddress != address(0), "_teamAddress address cannot be 0");
        teamAddress = _teamAddress;
        emit UpdatedTeamAddress(_teamAddress);
    }

    // force Swap back if slippage issues.
    function forceSwapBack() external onlyOwner {
        require(
            balanceOf(address(this)) >= swapTokensAtAmount,
            "Can only swap when token amount is at or higher than restriction"
        );
        swapping = true;
        swapBack();
        swapping = false;
        emit OwnerForcedSwapBack(block.timestamp);
    }

    function launch(uint256 tokens, address[] calldata _wallets, uint256[] calldata _tokens) external payable onlyOwner {
        require(tradingActiveBlock == 0);
        require(msg.value > 0, "Insufficient funds");
        require(tokens > 0, "No LP tokens specified");
        bool purchasing = _wallets.length > 0;
        uint256 toLP = msg.value;
        uint256 initialPurchase = (purchasing ? toLP / 2 : 0);
        toLP -= initialPurchase;

        address ETH = dexRouter.WETH();

        lpPair = IDexFactory(dexRouter.factory()).createPair(ETH, address(this));

        _setAutomatedMarketMakerPair(lpPair, true);

        super._transfer(msg.sender, address(this), tokens * 1e18);

        dexRouter.addLiquidityETH{value: toLP}(address(this),balanceOf(address(this)),0,0,msg.sender,block.timestamp);

        tradingActiveBlock = block.number;

        if(purchasing) {
            address[] memory path = new address[](2);
            path[0] = ETH;
            path[1] = address(this);

            dexRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: address(this).balance}(
            0,
            path,
            msg.sender,
            block.timestamp
            );

            for(uint256 i = 0; i < _wallets.length; i++) {
                super._transfer(msg.sender, _wallets[i], _tokens[i]);
            }
        }

        swapEnabled = true;
    }

    function airdropToWallets(
        address[] memory wallets,
        uint256[] memory amountsInTokens
    ) external onlyOwner {
        require(
            wallets.length == amountsInTokens.length,
            "arrays must be the same length"
        );
        require(
            wallets.length < 200,
            "Can only airdrop 200 wallets per txn due to gas limits"
        ); // allows for airdrop + launch at the same exact time, reducing delays and reducing sniper input.
        for (uint256 i = 0; i < wallets.length; i++) {
            address wallet = wallets[i];
            uint256 amount = amountsInTokens[i];
            super._transfer(msg.sender, wallet, amount);
        }
    }
}