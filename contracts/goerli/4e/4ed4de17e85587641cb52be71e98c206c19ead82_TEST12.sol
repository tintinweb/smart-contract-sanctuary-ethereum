/**
 *Submitted for verification at Etherscan.io on 2022-12-18
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.17;



interface IUniswapRouter01 {
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

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapRouter02 is IUniswapRouter01 {

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; 
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

 
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

 
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

 
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

 
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library Address {
   
    function isContract(address account) internal view returns (bool) {

        return account.code.length > 0;
    }


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

  
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }


    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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


    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }


    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {

        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeERC20: decreased allowance below zero"
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
        }
    }


    function _callOptionalReturn(IERC20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);


    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

   
    function totalSupply() external view returns (uint256);

   
    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address to, uint256 amount) external returns (bool);

   
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);


    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    
    function name() external view returns (string memory);

  
    function symbol() external view returns (string memory);

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


    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(msg.sender, to, amount);
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
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            allowance(msg.sender, spender) + addedValue
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = allowance(msg.sender, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(msg.sender, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

 
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
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

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

contract TEST12 is ERC20, Ownable {
    address payable public marketingFeeAddress;
    address payable public stakingFeeAddress;

    uint16 constant feeDenominator = 1000;
    uint16 constant lpDenominator = 1000;
    uint16 constant maxFeeLimit = 1000;

    bool public tradingActive;

    mapping(address => bool) public isExcludedFromFee;

    uint16 public buyBurnFee = 10;
    uint16 public buyLiquidityFee = 10;
    uint16 public buyMarketingFee = 50;
    uint16 public buyStakingFee = 0;

    uint16 public sellBurnFee = 10;
    uint16 public sellLiquidityFee = 10;
    uint16 public sellMarketingFee = 50;
    uint16 public sellStakingFee = 0;

    uint16 public transferBurnFee = 10;
    uint16 public transferLiquidityFee = 5;
    uint16 public transferMarketingFee = 5;
    uint16 public transferStakingFee = 20;

    uint256 private _liquidityTokensToSwap;
    uint256 private _marketingFeeTokensToSwap;
    uint256 private _burnFeeTokens;
    uint256 private _stakingFeeTokens;

    uint256 private lpTokens;

    mapping(address => bool) public automatedMarketMakerPairs;
    mapping(address => bool) public botWallet;
    address[] public botWallets;
    uint256 public minLpBeforeSwapping;

    IUniswapRouter02 public immutable uniswapRouter;
    address public immutable uniswapPair;
    address public bridgeAddress;

    bool inSwapAndLiquify;

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor() ERC20("TEST12", "KS") {
        _mint(msg.sender, 10000 * 10 ** decimals());

        marketingFeeAddress = payable(
            0x99eC1B9f964eC43955f71077B894474318e0429A
        );
        stakingFeeAddress = payable(0x99eC1B9f964eC43955f71077B894474318e0429A);

        minLpBeforeSwapping = 10; // this means: 10 / 1000 = 1% of the liquidity pool is the threshold before swapping
        
         address routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // ETH Mainnet
        // address routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // BSC Mainnet
        uniswapRouter = IUniswapRouter02(payable(routerAddress));

        uniswapPair = IFactory(uniswapRouter.factory()).createPair(
            address(this),
            uniswapRouter.WETH()
        );

        isExcludedFromFee[msg.sender] = true;
        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[marketingFeeAddress] = true;
        isExcludedFromFee[stakingFeeAddress] = true;

        _limits[msg.sender].isExcluded = true;
        _limits[address(this)].isExcluded = true;
        _limits[routerAddress].isExcluded = true;

        // Limits Configuration
        globalLimit = 7 ether;
        globalLimitPeriod = 24 hours;
        limitsActive = true;

        _approve(msg.sender, routerAddress, ~uint256(0));
        _setAutomatedMarketMakerPair(uniswapPair, true);
        bridgeAddress = 0xCF1F13959714896386cABfA693C590bfb7017f6a;
        isExcludedFromFee[bridgeAddress] = true;
        _limits[bridgeAddress].isExcluded = true;
        _approve(address(this), address(uniswapRouter), type(uint256).max);
    }

    function increaseRouterAllowance(address routerAddress) external onlyOwner {
        _approve(address(this), routerAddress, type(uint256).max);
    }

    function migrateBridge(address newAddress) external onlyOwner {
        require(
            newAddress != address(0) && !automatedMarketMakerPairs[newAddress],
            "Can't set this address"
        );
        bridgeAddress = newAddress;
        isExcludedFromFee[newAddress] = true;
        _limits[newAddress].isExcluded = true;
    }

    function decimals() public pure override returns (uint8) {
        return 9;
    }

    function addBotWallet(address wallet) external onlyOwner {
        require(!botWallet[wallet], "Wallet already added");
        botWallet[wallet] = true;
        botWallets.push(wallet);
    }

    function addBotWalletBulk(address[] memory wallets) external onlyOwner {
        for (uint256 i = 0; i < wallets.length; i++) {
            require(!botWallet[wallets[i]], "Wallet already added");
            botWallet[wallets[i]] = true;
            botWallets.push(wallets[i]);
        }
    }

    function getBotWallets() external view returns (address[] memory) {
        return botWallets;
    }

    function removeBotWallet(address wallet) external onlyOwner {
        require(botWallet[wallet], "Wallet not added");
        botWallet[wallet] = false;
        for (uint256 i = 0; i < botWallets.length; i++) {
            if (botWallets[i] == wallet) {
                botWallets[i] = botWallets[botWallets.length - 1];
                botWallets.pop();
                break;
            }
        }
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function enableTrading() external onlyOwner {
        tradingActive = true;
    }

    function disableTrading() external onlyOwner {
        tradingActive = false;
    }

    function totalSupply() public view override returns (uint256) {
        return super.totalSupply() - bridgeBalance();
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (account == bridgeAddress) return 0;
        return super.balanceOf(account);
    }

    function bridgeBalance() public view returns (uint256) {
        return super.balanceOf(bridgeAddress);
    }

    function updateMinLpBeforeSwapping(uint256 minLpBeforeSwapping_)
        external
        onlyOwner
    {
        minLpBeforeSwapping = minLpBeforeSwapping_;
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        external
        onlyOwner
    {
        require(pair != uniswapPair, "The pair cannot be removed");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
    }

    function excludeFromFee(address account) external onlyOwner {
        isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) external onlyOwner {
        isExcludedFromFee[account] = false;
    }

    function updateBuyFee(
        uint16 _buyBurnFee,
        uint16 _buyLiquidityFee,
        uint16 _buyMarketingFee,
        uint16 _buyStakingFee
    ) external onlyOwner {
        buyBurnFee = _buyBurnFee;
        buyLiquidityFee = _buyLiquidityFee;
        buyMarketingFee = _buyMarketingFee;
        buyStakingFee = _buyStakingFee;
        require(
            _buyBurnFee +
                _buyLiquidityFee +
                _buyMarketingFee +
                _buyStakingFee <=
                maxFeeLimit,
            "Must keep fees below 30%"
        );
    }

    function updateSellFee(
        uint16 _sellBurnFee,
        uint16 _sellLiquidityFee,
        uint16 _sellMarketingFee,
        uint16 _sellStakingFee
    ) external onlyOwner {
        sellBurnFee = _sellBurnFee;
        sellLiquidityFee = _sellLiquidityFee;
        sellMarketingFee = _sellMarketingFee;
        sellStakingFee = _sellStakingFee;
        require(
            _sellBurnFee +
                _sellLiquidityFee +
                _sellMarketingFee +
                _sellStakingFee <=
                maxFeeLimit,
            "Must keep fees <= 30%"
        );
    }

    function updateTransferFee(
        uint16 _transferBurnFee,
        uint16 _transferLiquidityFee,
        uint16 _transferMarketingFee,
        uint16 _transferStakingfee
    ) external onlyOwner {
        transferBurnFee = _transferBurnFee;
        transferLiquidityFee = _transferLiquidityFee;
        transferMarketingFee = _transferMarketingFee;
        transferStakingFee = _transferStakingfee;
        require(
            _transferBurnFee +
                _transferLiquidityFee +
                _transferMarketingFee +
                _transferStakingfee <=
                maxFeeLimit,
            "Must keep fees <= 30%"
        );
    }

    function updateMarketingFeeAddress(address marketingFeeAddress_)
        external
        onlyOwner
    {
        require(marketingFeeAddress_ != address(0), "Can't set 0");
        marketingFeeAddress = payable(marketingFeeAddress_);
    }

    function updateStakingAddress(address stakingFeeAddress_)
        external
        onlyOwner
    {
        require(stakingFeeAddress_ != address(0), "Can't set 0");
        stakingFeeAddress = payable(stakingFeeAddress_);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (!tradingActive) {
            require(
                isExcludedFromFee[from] || isExcludedFromFee[to],
                "Trading is not active yet."
            );
        }
        require(!botWallet[from] && !botWallet[to], "Bot wallet");
        checkLiquidity();

        if (
            hasLiquidity && !inSwapAndLiquify && automatedMarketMakerPairs[to]
        ) {
            uint256 contractTokenBalance = balanceOf(address(this));
            if (
                contractTokenBalance >=
                (lpTokens * minLpBeforeSwapping) / lpDenominator
            ) takeFee(contractTokenBalance);
        }

        uint256 _burnFee;
        uint256 _liquidityFee;
        uint256 _marketingFee;
        uint256 _stakingFee;

        if (!isExcludedFromFee[from] && !isExcludedFromFee[to]) {
            // Buy
            if (automatedMarketMakerPairs[from]) {
                _burnFee = (amount * buyBurnFee) / feeDenominator;
                _liquidityFee = (amount * buyLiquidityFee) / feeDenominator;
                _marketingFee = (amount * buyMarketingFee) / feeDenominator;
                _stakingFee = (amount * buyStakingFee) / feeDenominator;
            }
            // Sell
            else if (automatedMarketMakerPairs[to]) {
                _burnFee = (amount * sellBurnFee) / feeDenominator;
                _liquidityFee = (amount * sellLiquidityFee) / feeDenominator;
                _marketingFee = (amount * sellMarketingFee) / feeDenominator;
                _stakingFee = (amount * sellStakingFee) / feeDenominator;
            } else {
                _burnFee = (amount * transferBurnFee) / feeDenominator;
                _liquidityFee =
                    (amount * transferLiquidityFee) /
                    feeDenominator;
                _marketingFee =
                    (amount * transferMarketingFee) /
                    feeDenominator;
                _stakingFee = (amount * transferStakingFee) / feeDenominator;
            }

            _handleLimited(
                from,
                to,
                amount - _burnFee - _liquidityFee - _marketingFee - _stakingFee
            );
        }

        uint256 _transferAmount = amount -
            _burnFee -
            _liquidityFee -
            _marketingFee -
            _stakingFee;
        super._transfer(from, to, _transferAmount);
        uint256 _feeTotal = _burnFee +
            _liquidityFee +
            _marketingFee +
            _stakingFee;
        if (_feeTotal > 0) {
            super._transfer(from, address(this), _feeTotal);
            _liquidityTokensToSwap += _liquidityFee;
            _marketingFeeTokensToSwap += _marketingFee;
            _burnFeeTokens += _burnFee;
            _stakingFeeTokens += _stakingFee;
        }
    }

    function takeFee(uint256 contractBalance) private lockTheSwap {
        uint256 totalTokensTaken = _liquidityTokensToSwap +
            _marketingFeeTokensToSwap +
            _burnFeeTokens +
            _stakingFeeTokens;
        if (totalTokensTaken == 0 || contractBalance < totalTokensTaken) {
            return;
        }

        uint256 tokensForLiquidity = _liquidityTokensToSwap / 2;
        uint256 initialETHBalance = address(this).balance;
        uint256 toSwap = tokensForLiquidity +
            _marketingFeeTokensToSwap +
            _stakingFeeTokens;
        swapTokensForETH(toSwap);
        uint256 ethBalance = address(this).balance - initialETHBalance;

        uint256 ethForMarketing = (ethBalance * _marketingFeeTokensToSwap) /
            toSwap;
        uint256 ethForLiquidity = (ethBalance * tokensForLiquidity) / toSwap;
        uint256 ethForStaking = (ethBalance * _stakingFeeTokens) / toSwap;

        if (tokensForLiquidity > 0 && ethForLiquidity > 0) {
            addLiquidity(tokensForLiquidity, ethForLiquidity);
        }
        bool success;

        (success, ) = address(marketingFeeAddress).call{
            value: ethForMarketing,
            gas: 50000
        }("");
        (success, ) = address(stakingFeeAddress).call{
            value: ethForStaking,
            gas: 50000
        }("");

        if (_burnFeeTokens > 0) {
            _burn(address(this), _burnFeeTokens);
        }

        _liquidityTokensToSwap = 0;
        _marketingFeeTokensToSwap = 0;
        _burnFeeTokens = 0;
        _stakingFeeTokens = 0;
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        uniswapRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    receive() external payable {}

    // Limits
    event LimitSet(address indexed user, uint256 limitETH, uint256 period);

    mapping(address => LimitedWallet) private _limits;

    uint256 public globalLimit; // limit over timeframe for all
    uint256 public globalLimitPeriod; // timeframe for all

    bool public limitsActive;

    bool private hasLiquidity;

    struct LimitedWallet {
        uint256[] sellAmounts;
        uint256[] sellTimestamps;
        uint256 limitPeriod; // ability to set custom values for individual wallets
        uint256 limitETH; // ability to set custom values for individual wallets
        bool isExcluded;
    }

    function setGlobalLimit(uint256 newLimit) external onlyOwner {
        require(newLimit >= 1 ether, "Too low");
        globalLimit = newLimit;
    }

    function setGlobalLimitPeriod(uint256 newPeriod) external onlyOwner {
        require(newPeriod <= 2 weeks, "Too long");
        globalLimitPeriod = newPeriod;
    }

    function setLimitsActiveStatus(bool status) external onlyOwner {
        limitsActive = status;
    }

    function getLimits(address _address)
        external
        view
        returns (LimitedWallet memory)
    {
        return _limits[_address];
    }

    function removeLimits(address[] calldata addresses) external onlyOwner {
        for (uint256 i; i < addresses.length; i++) {
            address account = addresses[i];
            _limits[account].limitPeriod = 0;
            _limits[account].limitETH = 0;
            emit LimitSet(account, 0, 0);
        }
    }

    // Set custom limits for an address. Defaults to 0, thus will use the "globalLimitPeriod" and "globalLimitETH" if we don't set them
    function setLimits(
        address[] calldata addresses,
        uint256[] calldata limitPeriods,
        uint256[] calldata limitsETH
    ) external onlyOwner {
        require(
            addresses.length == limitPeriods.length &&
                limitPeriods.length == limitsETH.length,
            "Array lengths don't match"
        );

        for (uint256 i = 0; i < addresses.length; i++) {
            if (limitPeriods[i] == 0 && limitsETH[i] == 0) continue;
            _limits[addresses[i]].limitPeriod = limitPeriods[i];
            _limits[addresses[i]].limitETH = limitsETH[i];
            emit LimitSet(addresses[i], limitsETH[i], limitPeriods[i]);
        }
    }

    function addExcludedFromLimits(address[] calldata addresses)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            _limits[addresses[i]].isExcluded = true;
        }
    }

    function removeExcludedFromLimits(address[] calldata addresses)
        external
        onlyOwner
    {
        require(addresses.length <= 500, "Array too long");
        for (uint256 i = 0; i < addresses.length; i++) {
            _limits[addresses[i]].isExcluded = false;
        }
    }

    // Can be used to check how much a wallet sold in their timeframe
    function getSoldLastPeriod(address _address)
        public
        view
        returns (uint256 sellAmount)
    {
        LimitedWallet memory __limits = _limits[_address];
        uint256 numberOfSells = __limits.sellAmounts.length;

        if (numberOfSells == 0) {
            return sellAmount;
        }

        uint256 limitPeriod = __limits.limitPeriod == 0
            ? globalLimitPeriod
            : __limits.limitPeriod;
        while (true) {
            if (numberOfSells == 0) {
                break;
            }
            numberOfSells--;
            uint256 sellTimestamp = __limits.sellTimestamps[numberOfSells];
            if (block.timestamp - limitPeriod <= sellTimestamp) {
                sellAmount += __limits.sellAmounts[numberOfSells];
            } else {
                break;
            }
        }
    }

    function checkLiquidity() internal {
        (uint256 r1, uint256 r2, ) = IUniswapV2Pair(uniswapPair).getReserves();

        lpTokens = balanceOf(uniswapPair); // this is not a problem, since contract sell will get that unsynced balance as if we sold it, so we just get more ETH.
        hasLiquidity = r1 > 0 && r2 > 0 ? true : false;
    }

    function getETHValue(uint256 tokenAmount)
        public
        view
        returns (uint256 ethValue)
    {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();
        ethValue = uniswapRouter.getAmountsOut(tokenAmount, path)[1];
    }

    //  private sale wallets
    function _handleLimited(
        address from,
        address to,
        uint256 taxedAmount
    ) private {
        LimitedWallet memory _from = _limits[from];
        if (
            _from.isExcluded ||
            _limits[to].isExcluded ||
            !hasLiquidity ||
            automatedMarketMakerPairs[from] ||
            inSwapAndLiquify ||
            (!limitsActive && _from.limitETH == 0) // if limits are disabled and the wallet doesn't have a custom limit, we don't need to check
        ) {
            return;
        }
        uint256 ethValue = getETHValue(taxedAmount);
        _limits[from].sellTimestamps.push(block.timestamp);
        _limits[from].sellAmounts.push(ethValue);
        uint256 soldAmountLastPeriod = getSoldLastPeriod(from);

        uint256 limit = _from.limitETH == 0 ? globalLimit : _from.limitETH;
        require(
            soldAmountLastPeriod <= limit,
            "Amount over the limit for time period"
        );
    }

    function withdrawETH() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function withdrawTokens(IERC20 tokenAddress, address walletAddress)
        external
        onlyOwner
    {
        require(
            walletAddress != address(0),
            "walletAddress can't be 0 address"
        );
        SafeERC20.safeTransfer(
            tokenAddress,
            walletAddress,
            tokenAddress.balanceOf(address(this))
        );
    }
}