// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "IERC20.sol";
import "IERC20Metadata.sol";
import "Context.sol";
import "Ownable.sol";
import "IUniswapV2Factory.sol";
import "IUniswapV2Router02.sol";

contract ERC20 is Context, IERC20, IERC20Metadata, Ownable{

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcludedFromReward;
    address[] private _excluded;
    
    string private constant _name = unicode"MetaLand";
    string private constant _symbol = unicode"MLAND";
    
    uint8 private constant _decimals = 18;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1_500_000_000 * 10**_decimals; //TEMP 
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    uint256 private _liquidityFee = 2; //TEMP 
    uint256 private _reflectionFee = 5; //TEMP 
    uint256 private _treasuryFee = 4; //TEMP 
    uint256 private _mktDevFee = 3; //TEMP 

    // For fee exclusions
    uint256 private _tempLiquidityFee = _liquidityFee;
    uint256 private _tempReflectionFee = _reflectionFee;
    uint256 private _tempTreasuryFee = _treasuryFee;
    uint256 private _tempMktDevFee = _mktDevFee;

    uint256 private _presaleRate = 200000; //TEMP 
    uint256 private _presaleTokenLimit = 700_000_000 * 10**_decimals; //TEMP 
    uint256 private _presaleTokensSold = 0;
    uint256 private minInvestment = 10 * 10**_decimals; //TEMP 

    address private _mktDevAddress;
    address private _treasuryAddress;

    bool public swapAndLiquifyEnabled = true;
    
    uint256 private numTokensSellToAddToLiquidity = 100_000 * 10**_decimals; //TEMP 

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable pair;

    bool private tradingEnabled = false;
    bool private canSwap = true;
    bool private inSwap = false;
   
    event MaxBuyAmountUpdated(uint _maxBuyAmount);
    event CooldownEnabledUpdated(bool _cooldown);
    event FeeMultiplierUpdated(uint _multiplier);
    event FeeRateUpdated(uint _rate);
    event swapLiquidity(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount);

    uint256 openingTime = 1649223954; //TEMP 1650427200; //epoch time april 20 12AM
    uint256 closingTime = 1649223954 + 86400; //TEMP 1650427200; //epoch time april 20 12AM

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    modifier onlyWhileOpen {
        require(block.timestamp >= openingTime, "Token purchase must be within presale period");
        require(block.timestamp <= closingTime, "Token purchase must be within presale period");
        _;
    }

    struct getTValuesReturn {
        uint256 treasuryFee;
        uint256 mktDevFee;
        uint256 liquidityFee;
        uint256 reflectionFee;
        uint256 transferAmount;
    }

    struct getRValuesReturn {
        uint256 amount;
        uint256 treasuryFee;
        uint256 mktDevFee;
        uint256 liquidityFee;
        uint256 reflectionFee;
        uint256 transferAmount;
    }


    struct getValuesReturn {
        uint256 rAmount;
        uint256 rTreasuryFee;
        uint256 rMktDevFee;
        uint256 rLiquidityFee;
        uint256 rReflectionFee;
        uint256 rTransferAmount;
        uint256 tTreasuryFee;
        uint256 tMktDevFee;
        uint256 tLiquidityFee;
        uint256 tReflectionFee;
        uint256 tTransferAmount;
    }

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(address payable mktDevAddress_, address payable treasuryAddress_) payable {
        _mktDevAddress = mktDevAddress_;
        _treasuryAddress = treasuryAddress_;
        
        _rOwned[_msgSender()] = _rTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_mktDevAddress] = true;
        _isExcludedFromFee[_treasuryAddress] = true;
        emit Transfer(address(0), _msgSender(), _tTotal);

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        // IERC20(pair).approve(address(_uniswapV2Router), type(uint).max);
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

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
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

    function setLiquidityFee(uint256 newFee) external onlyOwner {
        _liquidityFee = newFee;
    }

    function setReflectionFee(uint256 newFee) external onlyOwner {
        _reflectionFee = newFee;
    }

    function setTreasuryFee(uint256 newFee) external onlyOwner {
        _treasuryFee = newFee;
    }

    function setMktDevFee(uint256 newFee) external onlyOwner {
        _mktDevFee = newFee;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _tTotal;
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply - _rOwned[_excluded[i]];
            tSupply = tSupply - _tOwned[_excluded[i]];
        }
        if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount / currentRate;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        if (_isExcludedFromReward[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
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

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
    }

    function excludeFromReward(address account) public onlyOwner() {
        // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Uniswap router.');
        require(!_isExcludedFromReward[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcludedFromReward[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcludedFromReward[account], "Account is already included");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcludedFromReward[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    receive() external payable {
        (bool sent, bytes memory data) = owner().call{value: msg.value}("");
        require(sent, "Failed to send Ether");
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcludedFromReward[account];
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function calculateTreasuryFee(uint256 _amount) private view returns (uint256) {
        return _amount * _treasuryFee / 10**2;
    }

    function calculateMktDevFee(uint256 _amount) private view returns (uint256) {
        return _amount * _mktDevFee / 10**2;
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount * _liquidityFee / 10**2;
    }

    function calculateReflectionFee(uint256 _amount) private view returns (uint256) {
        return _amount * _reflectionFee / 10**2;
    }

    function _getTValues(uint256 tAmount) private view returns (getTValuesReturn memory) {
        uint256 tTreasuryFee = calculateTreasuryFee(tAmount);
        uint256 tMktDevFee = calculateMktDevFee(tAmount);
        uint256 tLiquidityFee = calculateLiquidityFee(tAmount);
        uint256 tReflectionFee = calculateReflectionFee(tAmount);
        uint256 tTransferAmount = tAmount - tTreasuryFee - tMktDevFee - tLiquidityFee - tReflectionFee;
        return getTValuesReturn(tTreasuryFee, tMktDevFee, tLiquidityFee, tReflectionFee, tTransferAmount);
    }

    function _getRValues(uint256 tAmount, uint256 tTreasuryFee, uint256 tMktDevFee, uint256 tLiquidityFee, uint256 tReflectionFee, uint256 currentRate) private pure returns (getRValuesReturn memory) {
        uint256 rAmount = tAmount * currentRate;
        uint256 rTreasuryFee = tTreasuryFee * currentRate;
        uint256 rMktDevFee = tMktDevFee * currentRate;
        uint256 rLiquidityFee = tLiquidityFee * currentRate;
        uint256 rReflectionFee = tReflectionFee * currentRate;
        uint256 rTransferAmount = rAmount - rTreasuryFee - rMktDevFee - rLiquidityFee - rReflectionFee;
        return getRValuesReturn(rAmount, rTreasuryFee, rMktDevFee, rLiquidityFee, rReflectionFee, rTransferAmount);
    }

    function _getValues(uint256 tAmount) private view returns (getValuesReturn memory) {
        getTValuesReturn memory t = _getTValues(tAmount);
        getRValuesReturn memory r = _getRValues(tAmount, t.treasuryFee, t.mktDevFee, t.liquidityFee, t.reflectionFee, _getRate());
        return getValuesReturn(r.amount, r.treasuryFee, r.mktDevFee, r.liquidityFee, r.reflectionFee, r.transferAmount, t.treasuryFee, t.mktDevFee, t.liquidityFee, t.reflectionFee, t.transferAmount);
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        getValuesReturn memory v = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender] - v.rAmount;
        _rOwned[recipient] = _rOwned[recipient] + v.rTransferAmount;
        _takeFees(v.rTreasuryFee, v.rMktDevFee, v.rLiquidityFee, v.rReflectionFee, v.tTreasuryFee, v.tMktDevFee, v.tLiquidityFee, v.tReflectionFee);
        emit Transfer(sender, recipient, v.tTransferAmount);
    } 

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        getValuesReturn memory v = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender] - v.rAmount;
        _tOwned[recipient] = _tOwned[recipient] + v.tTransferAmount;
        _rOwned[recipient] = _rOwned[recipient] + v.rTransferAmount;           
        _takeFees(v.rTreasuryFee, v.rMktDevFee, v.rLiquidityFee, v.rReflectionFee, v.tTreasuryFee, v.tMktDevFee, v.tLiquidityFee, v.tReflectionFee);
        emit Transfer(sender, recipient, v.tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        getValuesReturn memory v = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender] - tAmount;
        _rOwned[sender] = _rOwned[sender] - v.rAmount;
        _rOwned[recipient] = _rOwned[recipient] + v.rTransferAmount;   
        _takeFees(v.rTreasuryFee, v.rMktDevFee, v.rLiquidityFee, v.rReflectionFee, v.tTreasuryFee, v.tMktDevFee, v.tLiquidityFee, v.tReflectionFee);
        emit Transfer(sender, recipient, v.tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        getValuesReturn memory v = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender] - tAmount;
        _rOwned[sender] = _rOwned[sender] - v.rAmount;
        _tOwned[recipient] = _tOwned[recipient] + v.tTransferAmount;
        _rOwned[recipient] = _rOwned[recipient] + v.rTransferAmount;        
        _takeFees(v.rTreasuryFee, v.rMktDevFee, v.rLiquidityFee, v.rReflectionFee, v.tTreasuryFee, v.tMktDevFee, v.tLiquidityFee, v.tReflectionFee);
        emit Transfer(sender, recipient, v.tTransferAmount);
    }

    function _takeFees(uint256 rTreasuryFee, uint256 rMktDevFee, uint256 rLiquidityFee, uint256 rReflectionFee, uint256 tTreasuryFee, uint256 tMktDevFee, uint256 tLiquidityFee, uint256 tReflectionFee) private {
        _transferTreasury(rTreasuryFee,tTreasuryFee);
        _transferMktDev(rMktDevFee,tMktDevFee);
        _transferLiquidity(rLiquidityFee,tLiquidityFee);
        _reflectFee(rReflectionFee, tReflectionFee);
    }

    function _transferTreasury(uint256 rFee, uint256 tFee) private {
        _rOwned[_treasuryAddress] += rFee;
        _tOwned[_treasuryAddress] += tFee;
    }

    function _transferMktDev(uint256 rFee, uint256 tFee) private {
        _rOwned[_mktDevAddress] += rFee;
        _tOwned[_mktDevAddress] += tFee;
    }

    function _transferLiquidity(uint256 rFee, uint256 tFee) private {
        _rOwned[address(this)] += rFee;
        _tOwned[address(this)] += tFee;
    }
    
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal - rFee;
        _tFeeTotal = _tFeeTotal + tFee;
    }

    function removeAllFee() private {
        if(_reflectionFee == 0 && _liquidityFee == 0 && _treasuryFee == 0 && _mktDevFee == 0) return;
        
        _tempReflectionFee = _reflectionFee;
        _tempLiquidityFee = _liquidityFee;
        _tempTreasuryFee = _treasuryFee;
        _tempMktDevFee = _mktDevFee;
        
        _reflectionFee = 0;
        _liquidityFee = 0;
        _treasuryFee = 0;
        _mktDevFee = 0;
    }
    
    function restoreAllFee() private {
        _reflectionFee = _tempReflectionFee;
        _liquidityFee = _tempLiquidityFee;
        _treasuryFee = _tempTreasuryFee;
        _mktDevFee = _tempMktDevFee;
    }

    function _transferToken(address sender, address recipient, uint256 amount, bool takeFee) private {
        if(!takeFee) removeAllFee();

        if (_isExcludedFromReward[sender] && !_isExcludedFromReward[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcludedFromReward[sender] && _isExcludedFromReward[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcludedFromReward[sender] && !_isExcludedFromReward[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcludedFromReward[sender] && _isExcludedFromReward[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }

        if(!takeFee) restoreAllFee();
    } 

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcludedFromReward[sender], "Excluded addresses cannot call this function");
        uint256 rAmount = _getValues(tAmount).rAmount;
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rTotal = _rTotal - rAmount;
        _tFeeTotal = _tFeeTotal + tAmount;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(balanceOf(from) >= amount, "From account must have enough tokens");
        require((block.timestamp > closingTime) || ((from == owner()) || (to == owner()) || (from == address(this)) || (to == address(this))),"Metaland tokens may not be transacted until the presale period ends");

        uint256 contractTokenBalance = balanceOf(address(this));
                
        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwap &&
            from != pair &&
            swapAndLiquifyEnabled
        ) {
            swapAndAddLiquidity(numTokensSellToAddToLiquidity);
        }

        bool takeFee = true;
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }

        _transferToken(from, to, amount, takeFee);

    }

    function swapAndAddLiquidity(uint256 contractBalance) private lockTheSwap {
        uint256 half1 = contractBalance / 2;
        uint256 half2 = contractBalance - half1;

        uint256 initBalance = address(this).balance;

        bool swapSuccess = swapForETH(half1);

        uint256 ethToAdd = address(this).balance - initBalance;

        if (swapSuccess){
            addLiquidity(half2, ethToAdd);
            emit swapLiquidity(half1, ethToAdd, half2);
        }
    }

    function swapForETH(uint256 tokenAmount) private returns (bool){
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        try uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        ){
            return true;
        } catch {
            return false;
        }
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.addLiquidityETH{value:ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
    }

    // function _burn(address account, uint256 amount) internal virtual {
    //     require(account != address(0), "ERC20: burn from the zero address");

    //     _transfer(account, address(0), amount);

    //     emit Transfer(account, address(0), amount);
    // }

    function buyBackAndBurn() external payable onlyOwner {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);

        // uint256 initBalance = balanceOf(address(this));

        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value:msg.value}(
            0,
            path,
            address(0),
            block.timestamp
        );

        // uint256 diffBalance = balanceOf(address(this))-initBalance;

        // _burn(address(this),diffBalance);
    }

    function drainTokens() external onlyOwner {
        _transfer(address(this),_msgSender(),balanceOf(address(this)));
    }

    function getPresaleValues() public view returns(uint256,uint256,uint256,uint256,uint256) {
        return (_presaleTokenLimit,_presaleRate,_presaleTokensSold,openingTime,closingTime);
    }

    function buyTokens() public payable onlyWhileOpen {
        uint256 weiAmount = msg.value;
        uint256 tokens = _presaleRate * weiAmount;
        _presaleTokensSold = _presaleTokensSold + tokens;

        require(_msgSender() != address(0));
        require(validPurchase(tokens));

        _transfer(address(this),_msgSender(),tokens);

        (bool sent, bytes memory data) = owner().call{value: msg.value}("");
        require(sent, "Failed to send Ether");

        emit TokenPurchase(_msgSender(), weiAmount, tokens);
    }

    // return true if the transaction can buy tokens
    function validPurchase(uint256 tokens) internal view returns (bool) {

        bool notSmallAmount = tokens >= minInvestment;
        bool withinCap = _presaleTokensSold <= _presaleTokenLimit;

        return (notSmallAmount && withinCap);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
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

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.8.0;

import "IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "Context.sol";

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
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

pragma solidity ^0.8.13;

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

pragma solidity ^0.8.13;

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