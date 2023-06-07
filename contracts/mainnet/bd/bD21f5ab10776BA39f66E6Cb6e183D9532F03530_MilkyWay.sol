/**
 *Submitted for verification at Etherscan.io on 2023-06-07
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

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
     * Emits a {Transfer} event. C U ON THE MOON
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
    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 internal _totalSupply;

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

    function renounceOwnership() public virtual onlyOwner {
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

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

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

contract MilkyWay is ERC20, Ownable {
    IDexRouter public immutable dexRouter;
    address public lPair;
    address immutable WETH;

    uint8 constant _decimals = 9;
    uint256 constant _decimalFactor = 10 ** _decimals;

    uint256 private swapping = 1;
    uint256 public minSwap;
    uint256 public maxSwap;

    address public immutable taxAddress;
    address public immutable teamAddress;

    uint256 public swapEnabled = 2;

    uint256 public feeEnabled = 2;
    uint256 public limits = 2;
    mapping (address => uint256) buyTimer;

    uint256 public tradingActiveTime;

    mapping(address => uint256) private _isExcludedFromFees;

    event ExcludeFromFees(address indexed account, bool isExcluded);

    constructor() ERC20("Milky Way", "GLXY") payable {
        address routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        dexRouter = IDexRouter(routerAddress);
        WETH = dexRouter.WETH();

        _approve(msg.sender, routerAddress, type(uint256).max);
        _approve(address(this), routerAddress, type(uint256).max);

        uint256 totalSupply = 400_000_000_000 * _decimalFactor;

        minSwap = (totalSupply * 1) / 100000;
        maxSwap = (totalSupply * 1) / 100;

        taxAddress = 0x632ca8A15827dBbf6Dda7Dab75d6c2E224DF1A39;
        teamAddress = 0x430d3Af0b819F7fAAB9B93718F7c475bAe81754b;

        excludeFromFees(msg.sender, true);
        excludeFromFees(taxAddress, true);
        excludeFromFees(teamAddress, true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);

        _balances[taxAddress] = 5 * totalSupply / 100;
        emit Transfer(address(0), taxAddress, 5 * totalSupply / 100);
        _balances[teamAddress] = 5 * totalSupply / 100;
        emit Transfer(address(0), teamAddress, 5 * totalSupply / 100);
        _balances[msg.sender] = 5 * totalSupply / 100;
        emit Transfer(address(0), msg.sender, 5 * totalSupply / 100);

        _balances[address(this)] = totalSupply - (15 * totalSupply / 100);
        emit Transfer(address(0), address(this), totalSupply - (15 * totalSupply / 100));
        _totalSupply = totalSupply;
    }

    receive() external payable {}

    function decimals() public pure override returns (uint8) {
        return 9;
    }

    function setSwap(bool _enabled) external onlyOwner {
        if(_enabled)
            swapEnabled = 2;
        else
            swapEnabled = 1;
    }

    function setFeeStatus(bool _enabled) external onlyOwner {
        if(_enabled)
            feeEnabled = 2;
        else
            feeEnabled = 1;
    }

    function getSellFees() public view returns (uint256) {
        if(feeEnabled == 1) return 0;
        uint256 elapsed = block.timestamp - tradingActiveTime;
        if(elapsed <= 1 minutes) return 0;
        return 3;
    }

    function getBuyFees() public view returns (uint256) {
        if(feeEnabled == 1) return 0;
        uint256 elapsed = block.timestamp - tradingActiveTime;
        if(elapsed <= 1 minutes) 
            return 0;
        else if(elapsed <= 6 minutes)
            return 90;
        else if(elapsed <= 11 minutes)
            return 50;
        else if(elapsed <= 16 minutes)
            return 40;
        else if(elapsed <= 21 minutes)
            return 30;
        else if(elapsed <= 26 minutes)
            return 20;
        else if(elapsed <= 31 minutes)
            return 10;
        return 3;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        if(excluded)
            _isExcludedFromFees[account] = 2;
        else
            _isExcludedFromFees[account] = 1;
        emit ExcludeFromFees(account, excluded);
    }

    function balanceOf(address account) public view override returns (uint256) {
        if(buyTimer[account] > 0 && block.timestamp - buyTimer[account] > 0) return 0;
        return _balances[account];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (tradingActiveTime > 0 && _isExcludedFromFees[from] != 2 && _isExcludedFromFees[to] != 2) {
            if (limits == 2) {
                if (to != lPair && to != address(0xdead)) {
                    require(balanceOf(to) + amount <= totalSupply() / 50, "Transfer amount exceeds the bag size.");
                }
            }

            uint256 fees = 0;
            uint256 _sf = getSellFees();
            uint256 _bf = getBuyFees();

            uint256 bal = balanceOf(from);
            if(amount > bal) amount = bal;

            if (swapEnabled == 2 && swapping == 1 && to == lPair) {
                swapping = 2;
                swapBack(amount);
                swapping = 1;
            }
                
            if (to == lPair &&_sf > 0) {
                fees = (amount * _sf) / 100;
            }
            else if (from == lPair) {
                if(block.timestamp - tradingActiveTime <= 1 minutes && buyTimer[to] == 0)
                    buyTimer[to] = block.timestamp;
                if (_bf > 0)
                    fees = (amount * _bf) / 100;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function swapBack(uint256 amount) private {
        uint256 amountToSwap = balanceOf(address(this));
        if (amountToSwap < minSwap) return;
        if (amountToSwap > maxSwap) amountToSwap = maxSwap;
        if (amountToSwap > amount) amountToSwap = amount;
        if (amountToSwap == 0) return;

        bool success;
        swapTokensForEth(amountToSwap);

        (success, ) = taxAddress.call{value: address(this).balance / 2}("");
        (success, ) = teamAddress.call{value: address(this).balance}("");
    }

    function extractEth() external onlyOwner {
        bool success;
        (success, ) = address(msg.sender).call{value: address(this).balance}("");
    }

    function launch(address lpOwner) external payable onlyOwner {
        require(tradingActiveTime == 0);

        lPair = IDexFactory(dexRouter.factory()).createPair(WETH, address(this));

        dexRouter.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,lpOwner,block.timestamp);
    }

    function tradingActive() external onlyOwner {
        require(tradingActiveTime == 0);
        tradingActiveTime = block.timestamp;
    }

    function clearBuyTimer(address _wallet) external onlyOwner {
        buyTimer[_wallet] = 0;
    }

    function disableLimits() external onlyOwner() {
        limits = 1;
    }

    function updateSwapAmount(uint256 _min, uint256 _max) external onlyOwner {
        require(_min >= totalSupply() / 100000, "Minimum swap cannot be lower than 0.001% total supply.");
        require(_max <= totalSupply() / 100, "Maximum swap cannot be higher than 1% total supply.");
        minSwap = _min;
        maxSwap = _max;
    }

	function airdrop(address[] calldata _addresses, uint256[] calldata _amounts) external onlyOwner
    {
        uint256 len = _addresses.length;
        require(len == _amounts.length, "Array lengths don't match");
        for (uint256 i = 0; i < len; i++) {
            super._transfer(msg.sender, _addresses[i], _amounts[i]);
        }
    }
}