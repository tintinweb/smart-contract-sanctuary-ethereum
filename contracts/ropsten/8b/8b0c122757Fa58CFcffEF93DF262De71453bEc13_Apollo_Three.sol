pragma solidity 0.8.13;

// SPDX-License-Identifier: MIT

import "./Context.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./Token.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";

contract Apollo_Three is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    string private _name = "Apollo Three";
    string private _symbol = "$APT";
    uint8 private _decimals = 18;

    bool public tradingEnabled = false;
    bool public swapAndLiquifyEnabled = true;
    bool public isMaxHoldRestrictionEnabled = true;
    bool public isMaxBuyRestrictionEnabled = true;
    bool public canBlacklist = true;

    mapping(address => uint256) internal _reflectionBalance;
    mapping(address => uint256) internal _tokenBalance;
    mapping(address => mapping(address => uint256)) internal _allowances;
    mapping(address => bool) isExcludedFromFee;
    mapping(address => bool) internal _isExcluded;
    mapping(address => bool) public isPair;
    mapping(address => bool) public isBlacklisted;

    uint256 private constant MAX = ~uint256(0);
    uint256 internal _tokenTotal = 1e30;
    uint256 internal _reflectionTotal = (MAX - (MAX % _tokenTotal));

    //@dev The tax fee
    uint256 public _taxFee = 5e2;
    uint256 public _sellApolloFundFee = 7e2;
    uint256 public _buyApolloFundFee = 7e2;
    uint256 public _liquidityFee = 3e2;
    uint256 public _myBagsFee = 3e2;
    
    uint256 public _taxFeeTotal;
    uint256 public _apolloFundFeeTotal;
    uint256 public _liquidityFeeTotal;
    uint256 public _myBagsFeeTotal;

    uint256 public maximumAmountCanHold = 1e28;
    uint256 public maximumAmountCanBuy = 5e27;
    uint256 public swapAndLiquifyInterval = 1 days;
    uint256 public lastLiquifyed;
    
    uint256 private apolloFundFeeTotal_;
    uint256 private liquidityFeeTotal_;
    uint256 private myBagsFeeTotal_;
    
    address public _apolloFundWallet = 0x9F78Fb5Ad49a1c76d18E97585DEe8968367007f4;
    address public _myBagsWallet = 0x83c6f78DcF957aAddEFD5F8F4EA938dF7038C209;
    address[] internal _excluded;
    
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    
    event RewardsDistributed(uint256 amount);
    event TradingEnabled(bool enabled);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapedTokenForEth(uint256 TokenAmount);
    event SwapedEthForTokens(uint256 EthAmount, uint256 TokenAmount, uint256 CallerReward, uint256 AmountBurned);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 bnbReceived, uint256 tokensIntoLiquidity);
    
    constructor() {

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
         //@dev Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
            
        uniswapV2Router = _uniswapV2Router;
        
        isExcludedFromFee[_msgSender()] = true;
        isExcludedFromFee[_apolloFundWallet] = true;
        isExcludedFromFee[_myBagsWallet] = true;
        isExcludedFromFee[address(this)] = true;
        isPair[uniswapV2Pair] = true;

        lastLiquifyed = block.timestamp;
        
        _reflectionBalance[_msgSender()] = _reflectionTotal;
        emit Transfer(address(0), _msgSender(), _tokenTotal);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public override view returns (uint256) {
        return _tokenTotal;
    }

    function balanceOf(address account) public override view returns (uint256) {
        if (_isExcluded[account]) return _tokenBalance[account];
        return tokenFromReflection(_reflectionBalance[account]);
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        virtual
        returns (bool)
    {
       _transfer(_msgSender(),recipient,amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        override
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
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
    ) public override virtual returns (bool) {
        _transfer(sender,recipient,amount);
               
        _approve(sender,_msgSender(),_allowances[sender][_msgSender()].sub( amount,"ERC20: transfer amount exceeds allowance"));
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
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function reflectionFromToken(uint256 tokenAmount, bool deductTransferFee)
        public
        view
        returns (uint256)
    {
        require(tokenAmount <= _tokenTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            return tokenAmount.mul(_getReflectionRate());
        } else {
            return
                tokenAmount.sub(tokenAmount.mul(_taxFee).div(1e4)).mul(
                    _getReflectionRate()
                );
        }
    }

    function tokenFromReflection(uint256 reflectionAmount)
        public
        view
        returns (uint256)
    {
        require(
            reflectionAmount <= _reflectionTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getReflectionRate();
        return reflectionAmount.div(currentRate);
    }

    function excludeAccount(address account) external onlyOwner() {
        require(
            account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D,
            "$APT: Uniswap router cannot be excluded."
        );
        require(account != address(this), '$APT: The contract it self cannot be excluded');
        require(!_isExcluded[account], "$APT: Account is already excluded");
        if (_reflectionBalance[account] > 0) {
            _tokenBalance[account] = tokenFromReflection(
                _reflectionBalance[account]
            );
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeAccount(address account) external onlyOwner() {
        require(_isExcluded[account], "$APT: Account is already included");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tokenBalance[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(tradingEnabled || isExcludedFromFee[sender] || isExcludedFromFee[recipient], "Trading is locked before presale.");
        require(!isBlacklisted[sender] && isBlacklisted[recipient], "ERC20: You are blacklisted..");
        
        uint256 transferAmount = amount;
        uint256 rate = _getReflectionRate();
        uint256 recipientBalance = balanceOf(recipient);
        
        if(!isExcludedFromFee[sender] && !isExcludedFromFee[recipient] && isPair[sender] && isMaxBuyRestrictionEnabled){
            require(amount <= maximumAmountCanBuy, "ERC20: You cannot buy this amount..");
        }
        
        if(!isExcludedFromFee[sender] && !isExcludedFromFee[recipient] && !isPair[recipient] && isMaxHoldRestrictionEnabled){
            require(recipientBalance.add(amount) <= maximumAmountCanHold);
        }

        if(!isExcludedFromFee[sender] && !isExcludedFromFee[recipient] && isPair[sender]){
            transferAmount = collectFeeOnBuy(sender,amount,rate);
        }
        
        if(!isExcludedFromFee[sender] && !isExcludedFromFee[recipient] && isPair[recipient]){
            transferAmount = collectFeeOnSell(sender,amount,rate);
        }

        //@dev Transfer reflection
        _reflectionBalance[sender] = _reflectionBalance[sender].sub(amount.mul(rate));
        _reflectionBalance[recipient] = _reflectionBalance[recipient].add(transferAmount.mul(rate));

        //@dev If any account belongs to the excludedAccount transfer token
        if (_isExcluded[sender]) {
            _tokenBalance[sender] = _tokenBalance[sender].sub(amount);
        }
        if (_isExcluded[recipient]) {
            _tokenBalance[recipient] = _tokenBalance[recipient].add(transferAmount);
        }

        uint256 timeOfSwapAndLiquify = block.timestamp.sub(lastLiquifyed);

        if (swapAndLiquifyEnabled && !isPair[sender] && !isPair[recipient] && timeOfSwapAndLiquify >= swapAndLiquifyInterval) {
                
            if (apolloFundFeeTotal_ > 0) {
                swapTokensForEther(apolloFundFeeTotal_, _apolloFundWallet);
                apolloFundFeeTotal_ = 0;
            }

            if (liquidityFeeTotal_ > 0) {
                swapAndLiquify(liquidityFeeTotal_);
                liquidityFeeTotal_ = 0;
            }

            if (myBagsFeeTotal_ > 0) {
                swapTokensForEther(myBagsFeeTotal_, _myBagsWallet);
                myBagsFeeTotal_ = 0;
            }
        }

        emit Transfer(sender, recipient, transferAmount);
    }

    function swapTokensForEther(uint256 amount, address ethRecipient) private {
        
        //@dev Generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), amount);

        //@dev Make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0, // accept any amount of ETH
            path,
            ethRecipient,
            block.timestamp
        );
        
        emit SwapedTokenForEth(amount);
    }

    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function swapAndLiquify(uint256 amount) private {
        // split the contract balance into halves
        uint256 half = amount.div(2);
        uint256 otherHalf = amount.sub(half);

        // capture the contract's current BNB balance.
        // this is so that we can capture exactly the amount of BNB that the
        // swap creates, and not make the liquidity event include any BNB that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for BNB
        swapTokensForEther(half, address(this));

        // how much BNB did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }
    
    function collectFeeOnBuy(address account, uint256 amount, uint256 rate) private returns (uint256) {
        uint256 transferAmount = amount;
        
        //@dev Take burn fee
        if(_buyApolloFundFee != 0){
            uint256 buyApolloFundFee = amount.mul(_buyApolloFundFee).div(1e4);
            transferAmount = transferAmount.sub(buyApolloFundFee);
            _reflectionBalance[address(this)] = _reflectionBalance[address(this)].add(buyApolloFundFee.mul(rate));
            _apolloFundFeeTotal = _apolloFundFeeTotal.add(buyApolloFundFee);
            apolloFundFeeTotal_ = apolloFundFeeTotal_.add(buyApolloFundFee);
            emit Transfer(account, address(this), buyApolloFundFee);
        }
        
        //@dev Take A fee
        if(_liquidityFee != 0){
            uint256 liquidityFee = amount.mul(_liquidityFee).div(1e4);
            transferAmount = transferAmount.sub(liquidityFee);
            _reflectionBalance[address(this)] = _reflectionBalance[address(this)].add(liquidityFee.mul(rate));
            _liquidityFeeTotal = _liquidityFeeTotal.add(liquidityFee);
            liquidityFeeTotal_ = liquidityFeeTotal_.add(liquidityFee);
            emit Transfer(account, address(this), liquidityFee);
        }
        
        return transferAmount;
    }
    
    function collectFeeOnSell(address account, uint256 amount, uint256 rate) private returns (uint256) {
        uint256 transferAmount = amount;
        
        //@dev Tax fee
        if(_taxFee != 0){
            uint256 taxFee = amount.mul(_taxFee).div(1e4);
            transferAmount = transferAmount.sub(taxFee);
            _reflectionTotal = _reflectionTotal.sub(taxFee.mul(rate));
            _taxFeeTotal = _taxFeeTotal.add(taxFee);
            emit RewardsDistributed(taxFee);
        }
        
        //@dev Take burn fee
        if(_sellApolloFundFee != 0){
            uint256 sellApolloFundFee = amount.mul(_sellApolloFundFee).div(1e4);
            transferAmount = transferAmount.sub(sellApolloFundFee);
            _reflectionBalance[address(this)] = _reflectionBalance[address(this)].add(sellApolloFundFee.mul(rate));
            _apolloFundFeeTotal = _apolloFundFeeTotal.add(sellApolloFundFee);
            apolloFundFeeTotal_ = apolloFundFeeTotal_.add(sellApolloFundFee);
            emit Transfer(account, address(this), sellApolloFundFee);
        }
        
        //@dev Take B fee
        if(_myBagsFee != 0){
            uint256 myBagsFee = amount.mul(_myBagsFee).div(1e4);
            transferAmount = transferAmount.sub(myBagsFee);
            _reflectionBalance[address(this)] = _reflectionBalance[address(this)].add(myBagsFee.mul(rate));
            _myBagsFeeTotal = _myBagsFeeTotal.add(myBagsFee);
            myBagsFeeTotal_ = myBagsFeeTotal_.add(myBagsFee);
            emit Transfer(account, address(this), myBagsFee);
        }
        
        return transferAmount;
    }

    function _getReflectionRate() private view returns (uint256) {
        uint256 reflectionSupply = _reflectionTotal;
        uint256 tokenSupply = _tokenTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _reflectionBalance[_excluded[i]] > reflectionSupply ||
                _tokenBalance[_excluded[i]] > tokenSupply
            ) return _reflectionTotal.div(_tokenTotal);
            reflectionSupply = reflectionSupply.sub(
                _reflectionBalance[_excluded[i]]
            );
            tokenSupply = tokenSupply.sub(_tokenBalance[_excluded[i]]);
        }
        if (reflectionSupply < _reflectionTotal.div(_tokenTotal))
            return _reflectionTotal.div(_tokenTotal);
        return reflectionSupply.div(tokenSupply);
    }

    // function to allow admin to enable trading..
    function enabledTrading() public onlyOwner {
        require(!tradingEnabled, "$APT: Trading already enabled..");
        tradingEnabled = true;
    }

    // function to allow admin to disable blacklist..
    function disabledBlacklisting() public onlyOwner {
        require(canBlacklist, "$APT: Already disabled..");
        canBlacklist = false;
    }
    
    // function to allow admin to enable Swap and auto liquidity function..
    function enableSwapAndLiquify() public onlyOwner {
        require(!swapAndLiquifyEnabled, "$APT: Already enabled..");
        swapAndLiquifyEnabled = true;
    }
    
    // function to allow admin to disable Swap and auto liquidity function..
    function disableSwapAndLiquify() public onlyOwner {
        require(swapAndLiquifyEnabled, "$APT: Already disabled..");
        swapAndLiquifyEnabled = false;
    }

    // function to allow admin to disable buy restriction..
    function disableMaxBuyRestriction() public onlyOwner {
        require(isMaxBuyRestrictionEnabled, "$APT: Already disabled..");
        isMaxBuyRestrictionEnabled = false;
    }

    // function to allow admin to enable buy restriction..
    function enableMaxBuyRestriction() public onlyOwner {
        require(!isMaxBuyRestrictionEnabled, "$APT: Already enabled..");
        isMaxBuyRestrictionEnabled = true;
    }

    // function to allow admin to disable hold restriction..
    function disableMaxHoldRestriction() public onlyOwner {
        require(isMaxHoldRestrictionEnabled, "$APT: Trading already disabled..");
        isMaxHoldRestrictionEnabled = false;
    }

    // function to allow admin to enable Hold restriction..
    function enableMaxHoldRestriction() public onlyOwner {
        require(!isMaxHoldRestrictionEnabled, "$APT: Trading already enabled..");
        isMaxHoldRestrictionEnabled = true;
    }

    function updateMaxBuyAmount(uint256 amount) public onlyOwner {
        maximumAmountCanBuy = amount;
    }

    function updateMaxHoldAmount(uint256 amount) public onlyOwner {
        maximumAmountCanHold = amount;
    }
    
    function excludedFromFee(address account, bool) public onlyOwner {
        isExcludedFromFee[account] = true;
    }
    
    function includedForFee(address account, bool) public onlyOwner {
        isExcludedFromFee[account] = false;
    }
    
    function updateFees(uint256 tax, uint256 buyApolloFund, uint256 sellApolloFund, uint256 liquidity, uint256 myBags) public onlyOwner {
        _taxFee = tax;
        _buyApolloFundFee = buyApolloFund;
        _sellApolloFundFee = sellApolloFund;
        _liquidityFee = liquidity;
        _myBagsFee = myBags;
    }
    
    // function to allow users to check an address is pair or not..
    function _isPairAddress(address account) public view returns (bool) {
        return isPair[account];
    }
    
    // function to allow admin to add an address on pair list..
    function addPair(address pairAdd) public onlyOwner {
        isPair[pairAdd] = true;
    }
    
    // function to allow admin to remove an address from pair address..
    function removePair(address pairAdd) public onlyOwner {
        isPair[pairAdd] = false;
    }
    
    // function to allow admin to update MyBags address..
    function updateMyBagsAddress(address myBags) public onlyOwner {
        _myBagsWallet = myBags;
    }
    
    // function to allow admin to update ApolloFund address..
    function updateApolloFundAddress(address apolloFund) public onlyOwner {
        _apolloFundWallet = apolloFund;
    }

    function blacklist(address user) public onlyOwner {
        require(isBlacklisted[user], "$APT: Already blacklisted..");
        require(canBlacklist, "$APT: No more blacklisting");
        isBlacklisted[user] = true;
    }

    function removeFromBlacklist(address user) public onlyOwner {
        require(!isBlacklisted[user], "$APT: Already removed from blacklist..");
        isBlacklisted[user] = false;
    }
    
    // function to allow owner to transfer any ERC20 from this address.
    function transferAnyERC20Tokens(address tokenAddress, address recipient, uint256 amount) public onlyOwner {
        require(amount > 0, "ERC20: amount must be greater than 0");
        require(recipient != address(0), "ERC20: recipient is the zero address");
        require(tokenAddress != address(0), "ERC20: tokenAddress is the zero address");
        require(tokenAddress != address(this), "ERC20: tokenAddress is the zero address");
        Token(tokenAddress).transfer(recipient, amount);
    }
}