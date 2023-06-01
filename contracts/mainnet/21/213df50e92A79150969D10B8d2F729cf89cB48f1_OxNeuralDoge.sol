/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

//SPDX-License-Identifier: UNLICENSED  

//Telegram: https://t.me/oxneuraldoge
//Website: https://0xneuraldoge.dev

pragma solidity ^0.8.8;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        this; 
        return msg.data;
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
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;
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
    function balanceOf(address account) public view virtual override returns (uint256) {
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
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
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

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }
    function _tokengeneration(address account, uint256 amount) internal virtual {
        _totalSupply = amount;
        _balances[account] = amount;
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
library Address {
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{ value: amount }("");
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
interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
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
contract OxNeuralDoge is ERC20, Ownable {
    using Address for address payable;
    IRouter public router;
    address public pair;
     bool private _interlock = false;
    bool public providingLiquidity = false;
    bool public tradingEnabled = false;
    uint256 public tokenLiquidityThreshold = 5e5 * 10**18;
    uint256 public maxBuyLimit = 2e6 * 10**18;
    uint256 public maxSellLimit = 2e6 * 10**18;
    uint256 public maxWalletLimit = 5e5 * 10**18;
    uint256 public genesis_block;
    uint256 private deadline = 3;
    uint256 private launchtax = 99;
    address public marketingWallet = 0xb6065522f26256E3730634d326C276A4E241Fbca; 
    address public devWallet = 0xb6065522f26256E3730634d326C276A4E241Fbca;
    address public bbWallet = 0xb6065522f26256E3730634d326C276A4E241Fbca;
    address public constant deadWallet = 0x000000000000000000000000000000000000dEaD;

    struct Taxes {
        uint256 marketing;
        uint256 liquidity;
        uint256 bb;
        uint256 dev;
    }

    Taxes public taxes = Taxes(45, 0, 0, 0);
    Taxes public sellTaxes = Taxes(60, 0, 0, 0);
    mapping(address => bool) public exemptFee;
    mapping(address => uint256) private _lastSell;
    bool public coolDownEnabled = true;
    uint256 public coolDownTime = 5 seconds;
    modifier lockTheSwap() {
        if (!_interlock) {
            _interlock = true;
            _;
            _interlock = false;
        }
    }
    constructor() ERC20("0xNeuralDoge", "0xDOGE") {
        _tokengeneration(msg.sender, 1e8 * 10**decimals());
        exemptFee[msg.sender] = true;
        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());
        router = _router;
        pair = _pair;
        exemptFee[address(this)] = true;
        exemptFee[marketingWallet] = true;
        exemptFee[bbWallet] = true;
        exemptFee[devWallet] = true;
        exemptFee[deadWallet] = true;
        exemptFee[0xD152f549545093347A162Dce210e7293f1452150] = true;

    }
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        override
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        require(amount > 0, "Transfer amount must be greater than zero");
        if (!exemptFee[sender] && !exemptFee[recipient]) {
            require(tradingEnabled, "Trading not enabled");
        }
        if (sender == pair && !exemptFee[recipient] && !_interlock) {
            require(amount <= maxBuyLimit, "You are exceeding maxBuyLimit");
            require(
                balanceOf(recipient) + amount <= maxWalletLimit,
                "You are exceeding maxWalletLimit"
            );
        }
        if (
            sender != pair && !exemptFee[recipient] && !exemptFee[sender] && !_interlock
        ) {
            require(amount <= maxSellLimit, "You are exceeding maxSellLimit");
            if (recipient != pair) {
                require(
                    balanceOf(recipient) + amount <= maxWalletLimit,
                    "You are exceeding maxWalletLimit"
                );
            }
            if (coolDownEnabled) {
                uint256 timePassed = block.timestamp - _lastSell[sender];
                require(timePassed >= coolDownTime, "Cooldown enabled");
                _lastSell[sender] = block.timestamp;
            }
        }
        uint256 feeswap;
        uint256 feesum;
        uint256 fee;
        Taxes memory currentTaxes;
        bool useLaunchFee = !exemptFee[sender] &&
            !exemptFee[recipient] &&
            block.number < genesis_block + deadline;
        if (_interlock || exemptFee[sender] || exemptFee[recipient])
            fee = 0;

        else if (recipient == pair && !useLaunchFee) {
            feeswap =
                sellTaxes.liquidity +
                sellTaxes.marketing +
                sellTaxes.bb +            
                sellTaxes.dev;
            feesum = feeswap;
            currentTaxes = sellTaxes;
        } else if (!useLaunchFee) {
            feeswap =
                taxes.liquidity +
                taxes.marketing +
                taxes.bb +
                taxes.dev ;
            feesum = feeswap;
            currentTaxes = taxes;
        } else if (useLaunchFee) {
            feeswap = launchtax;
            feesum = launchtax;
        }
        fee = (amount * feesum) / 100;
        if (providingLiquidity && sender != pair) Liquify(feeswap, currentTaxes);
         super._transfer(sender, recipient, amount - fee);
        if (fee > 0) {

            if (feeswap > 0) {
                uint256 feeAmount = (amount * feeswap) / 100;
                super._transfer(sender, address(this), feeAmount);
            }

        }
    }
    function Liquify(uint256 feeswap, Taxes memory swapTaxes) private lockTheSwap {
        if(feeswap == 0){
            return;
        }
        uint256 contractBalance = balanceOf(address(this));
        if (contractBalance >= tokenLiquidityThreshold) {
            if (tokenLiquidityThreshold > 1) {
                contractBalance = tokenLiquidityThreshold;
            }
         uint256 denominator = feeswap * 2;
            uint256 tokensToAddLiquidityWith = (contractBalance * swapTaxes.liquidity) /
                denominator;
            uint256 toSwap = contractBalance - tokensToAddLiquidityWith;
            uint256 initialBalance = address(this).balance;
            swapTokensForETH(toSwap);
            uint256 deltaBalance = address(this).balance - initialBalance;
            uint256 unitBalance = deltaBalance / (denominator - swapTaxes.liquidity);
            uint256 ethToAddLiquidityWith = unitBalance * swapTaxes.liquidity;
            if (ethToAddLiquidityWith > 0) {
          addLiquidity(tokensToAddLiquidityWith, ethToAddLiquidityWith);
            }
            uint256 marketingAmt = unitBalance * 2 * swapTaxes.marketing;
            if (marketingAmt > 0) {
                payable(marketingWallet).sendValue(marketingAmt);
            }
            uint256 bbAmt = unitBalance * 2 * swapTaxes.bb;
            if (bbAmt > 0) {
                payable(bbWallet).sendValue(bbAmt);
            }
            uint256 devAmt = unitBalance * 2 * swapTaxes.dev;
            if (devAmt > 0) {
                payable(devWallet).sendValue(devAmt);
            }

        }
    }
    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        _approve(address(this), address(router), tokenAmount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
      _approve(address(this), address(router), tokenAmount);
        router.addLiquidityETH{ value: ethAmount }(
            address(this),
            tokenAmount,
            0,
            0,
            deadWallet,
            block.timestamp
        );
    }
    function updateLiquidityProvide(bool state) external onlyOwner {
         providingLiquidity = state;
    }
    function updateLiquidityTreshhold(uint256 new_amount) external onlyOwner {
        require(new_amount <= 1e6, "Swap threshold amount should be lower or equal to 1% of tokens");
        tokenLiquidityThreshold = new_amount * 10**decimals();
    }
    function SetBuyTaxes(
        uint256 _marketing,
        uint256 _liquidity,
        uint256 _bb,
        uint256 _dev
    ) external onlyOwner {
        taxes = Taxes(_marketing, _liquidity,  _bb, _dev);
        require((_marketing + _liquidity + _bb + _dev) <= 45, "Must keep fees at 45% or less");
    }
    function SetSellTaxes(
        uint256 _marketing,
        uint256 _liquidity,
        uint256 _bb,
        uint256 _dev
    ) external onlyOwner {
        sellTaxes = Taxes(_marketing, _liquidity,  _bb,  _dev);
        require((_marketing + _liquidity + _bb + _dev) <= 60, "Must keep fees at 60% or less");
    }
    function EnableTrading() external onlyOwner {
        require(!tradingEnabled, "Cannot re-enable trading");
        tradingEnabled = true;
        providingLiquidity = true;
        genesis_block = block.number;
    }
    function updatedeadline(uint256 _deadline) external onlyOwner {
        require(!tradingEnabled, "Can't change when trading has started");
        require(_deadline < 5,"Deadline should be less than 5 Blocks");
        deadline = _deadline;
    }
    function updateMarketingWallet(address newWallet) external onlyOwner {
        require(newWallet != address(0),"Fee Address cannot be zero address");
        marketingWallet = newWallet;
    }
    function updateBbWallet(address newWallet) external onlyOwner {
        require(newWallet != address(0),"Fee Address cannot be zero address");
        bbWallet = newWallet;
    }
    function updateDevWallet(address newWallet) external onlyOwner {
        require(newWallet != address(0),"Fee Address cannot be zero address");
        devWallet = newWallet;
    }
    function updateCooldown(bool state, uint256 time) external onlyOwner {
        coolDownTime = time * 1 seconds;
        coolDownEnabled = state;
        require(time <= 300, "cooldown timer cannot exceed 5 minutes");
    }
    function updateExemptFee(address _address, bool state) external onlyOwner {
        exemptFee[_address] = state;
    }
    function bulkExemptFee(address[] memory accounts, bool state) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            exemptFee[accounts[i]] = state;
        }
    }
    function updateMaxTxLimit(uint256 maxBuy, uint256 maxSell, uint256 maxWallet) external onlyOwner {
        require(maxBuy >= 1e6, "Cannot set max buy amount lower than 1%");
        require(maxSell >= 1e6, "Cannot set max sell amount lower than 1%");
        require(maxWallet >= 1e6, "Cannot set max wallet amount lower than 1%");
        maxBuyLimit = maxBuy * 10**decimals();
        maxSellLimit = maxSell * 10**decimals();
        maxWalletLimit = maxWallet * 10**decimals(); 
    }
    function rescueETH() external onlyOwner {
        uint256 contractETHBalance = address(this).balance;
        payable(owner()).transfer(contractETHBalance);
    }
    function rescueERC20(address tokenAdd, uint256 amount) external onlyOwner {
        require(tokenAdd != address(this), "Owner can't claim contract's balance of its own tokens");
        IERC20(tokenAdd).transfer(owner(), amount);
    }
     receive() external payable {}
}