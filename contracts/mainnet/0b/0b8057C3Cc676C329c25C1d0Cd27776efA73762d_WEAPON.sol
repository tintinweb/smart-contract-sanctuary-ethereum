/**
 *Submitted for verification at Etherscan.io on 2022-04-05
*/

pragma solidity 0.8.1;


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
// SPDX-License-Identifier: MIT

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IWEAPONStakable is IERC20 {
    function stakedBalanceOf(address account) external view returns (uint256);
    function getStake(address account) external view returns (uint256, uint256, uint256);

    function stake(address account, uint256 amount, uint256 unstakeTime, bool isPlayer, uint256 adjustedStake) external;
    function unstake(address account, uint256 unstakeAmount, bool isPlayer, uint256 adjustedStake) external;
    function sync(address account, uint256 adjustedStake) external;
    function toggleStaking() external;
}


contract WEAPON is Context, IWEAPONStakable {

    bool private _swapping;

    bool public stakingEnabled = false;

    bool public mintLocked = true;
    uint public mintLockTime = 1643673599;

    mapping (address => bool) private _isPool;

    mapping (address => uint256) private _balances;
    mapping (address => uint256) private _stakedBalances;
    mapping (address => uint256) private _stakeExpireTime;
    mapping (address => uint256) private _stakeBeginTime;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply = 10 * 10**6 * 10**9; 

    string private constant _name = "Megaweapon";
    string private constant _symbol = "$WEAPON";
    string private constant _version = "2";
    uint8 private constant _decimals = 9;
    uint8 private _buyTax = 10;
    uint8 private _sellTax = 10;
    uint8 private _stakingRewards = 20;

    address immutable private _lp;
    address payable immutable private _vault;
    address payable immutable private _multiSig;
    address payable private _stakingContract;
    address private constant _uniRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    IUniswapV2Router02 private UniV2Router;

    constructor(address vault, address multiSig) {
        require(vault != address(0) && multiSig != address(0), "$WEAPON: cannot assign privilege to zero address");
        _lp = _msgSender();
        _balances[_msgSender()] = _totalSupply;
        UniV2Router = IUniswapV2Router02(_uniRouter);
        _vault = payable(vault);
        _multiSig = payable(multiSig);
    }

    event Stake(address indexed staker, uint256 amount, uint256 stakeTime, uint256 stakeExpire);
    event Unstake(address indexed staker, uint256 amount, uint256 stakeAmountRemaining);
    event Adjust(address indexed staker, uint256 oldStake, uint256 newStake);
    event ChangeBuyTax(uint256 prevTax, uint256 newTax);
    event ChangeSellTax(uint256 prevTax, uint256 newTax);
    event ChangeRewards(uint256 prevRew, uint256 newRew);
    event ToggleStaking(bool enabled);
    event SetStakingContract(address stakingCon);
    event SetPool(address isNowPool);
    event FailsafeTokenSwap(uint256 amount);
    event FailsafeETHTransfer(uint256 amount);
    event FreezeMint(uint256 mintLockTime);
    event ThawMint(uint256 mintLockTime);

    modifier onlyMultiSig {
        require (_msgSender() == _multiSig, "$WEAPON: unauthorized");
        _;
    }

    modifier lockSwap {
        _swapping = true;
        _;
        _swapping = false;
    }

    function name() external pure returns (string memory) {
        return _name;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function version() external pure returns (string memory) {
        return _version;
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function stakedBalanceOf(address account) external view override returns (uint256) {
        return _stakedBalances[account];    
    }

    function getStake(address account) external view override returns (uint256, uint256, uint256) {
        if (stakingEnabled && _stakedBalances[account] > 0)
            return (_stakedBalances[account], _stakeBeginTime[account], _stakeExpireTime[account]);
        else return (0,0,0);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require (_allowances[sender][_msgSender()] >= amount, "ERC20: transfer amount exceeds allowance");
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(_balances[sender] >= amount, "ERC20: transfer exceeds balance");
        require(amount > 0, "$WEAPON: cannot transfer zero");
        require(!(_isPool[sender] && _isPool[recipient]), "$WEAPON: cannot transfer pool to pool");

        uint256 taxedAmount = amount;
        uint256 tax = 0;
    
        if (_isPool[sender] == true && recipient != _lp && recipient != _uniRouter) {
            tax = amount * _buyTax / 100;
            taxedAmount = amount - tax;
            _balances[address(this)] += tax;
        }
        if (_isPool[recipient] == true && sender != _lp && sender != _uniRouter){ 
            tax = amount * _sellTax / 100;
            taxedAmount = amount - tax;
            _balances[address(this)] += tax;

            if (_balances[address(this)] > 100 * 10**9 && !_swapping) {
                uint256 _swapAmount = _balances[address(this)];
                if (_swapAmount > amount * 40 / 100) _swapAmount = amount * 40 / 100;
                _tokensToETH(_swapAmount);
            }
        }
    
        _balances[recipient] += taxedAmount;
        _balances[sender] -= amount;

        emit Transfer(sender, recipient, amount);
    }

    function stake(address account, uint256 amount, uint256 unstakeTime, bool isPlayer, uint256 adjustedStake) external override {
        require (_msgSender() == _stakingContract, "$WEAPON: must stake through staking contract");
        require (account != address(0), "$WEAPON: cannot stake zero address");
        require (stakingEnabled, "$WEAPON: staking currently not enabled"); 

        if (isPlayer)
        { 
            if (_stakedBalances[account] != adjustedStake){
                emit Adjust(account, _stakedBalances[account], adjustedStake);
                _stakedBalances[account] = adjustedStake;
            }
        }

        require (unstakeTime > (block.timestamp + 86100),"$WEAPON: minimum stake time 23 hours 55 min"); 
        require (unstakeTime >= _stakeExpireTime[account], "$WEAPON: new stake time cannot be shorter");
        require (_balances[account] >= amount, "$WEAPON: stake exceeds available balance");
        if (_stakedBalances[account] == 0) require (amount > 0, "$WEAPON: cannot stake 0 tokens");

        _balances[account] = _balances[account] - amount;
        _balances[_stakingContract] = _balances[_stakingContract] + amount;
        _stakedBalances[account] = _stakedBalances[account] + amount;

        _stakeExpireTime[account] = unstakeTime;
        _stakeBeginTime[account] = block.timestamp;

        emit Stake(account, amount, block.timestamp, unstakeTime);
    }

    function unstake(address account, uint256 unstakeAmount, bool isPlayer, uint256 adjustedStake) external override {
        require (_msgSender() == _stakingContract, "$WEAPON: must unstake through staking contract");
        require (account != address(0), "$WEAPON: cannot unstake zero address");
        require(unstakeAmount > 0, "$WEAPON: cannot unstake zero tokens");

        if (isPlayer)
        { 
            if (_stakedBalances[account] != adjustedStake){
                emit Adjust(account, _stakedBalances[account], adjustedStake);
                _stakedBalances[account] = adjustedStake;
            }
        }

        require(unstakeAmount <= _stakedBalances[account], "$WEAPON: unstake exceeds staked balance");
        
        _stakedBalances[account] = _stakedBalances[account] - unstakeAmount;
        _balances[account] = _balances[account] + unstakeAmount;
        _balances[_stakingContract] = _balances[_stakingContract] - unstakeAmount;
        
        emit Unstake(account, unstakeAmount, _stakedBalances[account]);
    }

    function sync(address account, uint256 adjustedStake) external override {
        require (_msgSender() == _stakingContract, "$WEAPON: unauthorized");
        require (account != address(0), "$WEAPON: cannot sync zero address");
        emit Adjust(account, _stakedBalances[account], adjustedStake);
        _stakedBalances[account] = adjustedStake;
    }

    function freezeMint(uint256 timestamp) external onlyMultiSig {
        require (timestamp > mintLockTime, "$WEAPON: cannot reduce lock time");
        mintLocked = true;
        mintLockTime = timestamp;

        emit FreezeMint(mintLockTime);
    }

    function thawMint() external onlyMultiSig {
        require (block.timestamp >= mintLockTime, "$WEAPON: still frozen");
        mintLocked = false;
        mintLockTime = block.timestamp + 86400;

        emit ThawMint(mintLockTime);
    } 

    function mint(uint256 amount, address recipient) external onlyMultiSig {
        require (block.timestamp > mintLockTime && mintLocked == false, "$WEAPON: still frozen");
        _totalSupply = _totalSupply + amount;
        _balances[recipient] = _balances[recipient] + amount;

        emit Transfer(address(0), recipient, amount);
    }

    function toggleStaking() external override onlyMultiSig {
        require (_stakingContract != address(0), "$WEAPON: staking contract not set");
        if (stakingEnabled == true) stakingEnabled = false;
        else stakingEnabled = true;
        emit ToggleStaking(stakingEnabled);
    }

    function setStakingContract(address addr) external onlyMultiSig {
        require(addr != address(0), "$WEAPON: cannot be zero address");
        _stakingContract = payable(addr);
        emit SetStakingContract(addr);
    }

    function getStakingContract() external view returns (address) {
        return _stakingContract;
    }

    function setBuyTax(uint8 newTax) external onlyMultiSig {
        require (newTax <= 10, "$WEAPON: tax cannot exceed 10%");
        emit ChangeBuyTax(_buyTax, newTax);
        _buyTax = newTax;
    }

    function setSellTax(uint8 newTax) external onlyMultiSig {
        require (newTax <= 10, "$WEAPON: tax cannot exceed 10%");
        emit ChangeSellTax(_sellTax, newTax);
        _sellTax = newTax;
    }

    function setRewards(uint8 newRewards) external onlyMultiSig {
        require (newRewards >= 20, "$WEAPON: rewards minimum 20%");
        require (newRewards <= 100, "$WEAPON: rewards maximum 100%");
        emit ChangeRewards(_stakingRewards, newRewards);
        _stakingRewards = newRewards;
    }

    function setPool(address addr) external onlyMultiSig {
        require(addr != address(0), "$WEAPON: zero address cannot be pool");
        _isPool[addr] = true;
        emit SetPool(addr);
    }
    
    function isPool(address addr) external view returns (bool){
        return _isPool[addr];
    }

    function _transferETH(uint256 amount, address payable _to) private {
        (bool sent, bytes memory data) = _to.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    function _tokensToETH(uint256 amount) private lockSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = UniV2Router.WETH();

        _approve(address(this), _uniRouter, amount);
        UniV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(amount, 0, path, address(this), block.timestamp);

        if (address(this).balance > 0) 
        {
            if (stakingEnabled) {
                uint stakingShare = address(this).balance * _stakingRewards / 100;
                _transferETH(stakingShare, _stakingContract);
            }
            _transferETH(address(this).balance, _vault);
        }
    }
    
    function failsafeTokenSwap(uint256 amount) external onlyMultiSig {
        _tokensToETH(amount);
        emit FailsafeTokenSwap(amount);
    }

    function failsafeETHtransfer() external onlyMultiSig {
        emit FailsafeETHTransfer(address(this).balance);
        (bool sent, bytes memory data) = _msgSender().call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    receive() external payable {}

    fallback() external payable {}
}