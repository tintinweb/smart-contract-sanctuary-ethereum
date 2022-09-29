/**
 *Submitted for verification at Etherscan.io on 2022-09-28
*/

/*  
 * EatCake - $EAT
 * 
 * https://t.me/eatcakeethportal
 * 
 * Written by: MrGreenCrypto
 * Co-Founder of CodeCraftrs.com
 * 
 * SPDX-License-Identifier: None
 */

pragma solidity 0.8.17;

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IDEXFactory {function createPair(address tokenA, address tokenB) external returns (address pair);}
interface IDEXPair {function sync() external;}

interface IDEXRouter {
    function WETH() external pure returns (address);
    function factory() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract EatCake is IBEP20 {
    string constant _name = "EatCake";
    string constant _symbol = "EAT";
    uint8 constant _decimals = 9;
    uint256 _totalSupply = 100_000_000 * (10**_decimals);
    uint256 public maxWallet = _totalSupply * 25 / 1000;
    uint256 public maxTx = _totalSupply * 125 / 10000;
    
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public limitless;

    uint256 public tax = 3;
    uint256 private liq = 1;
    uint256 private marketing = 2;
    uint256 private token = 0;
    uint256 private burn = 0;
    uint256 private taxDivisor = 100;
    uint256 private minTokensToSell = _totalSupply / 100;
    uint256 private launchTime = type(uint256).max;
    uint256 private launchBlock;

    IDEXRouter public router;
    address public constant CEO = 0xE9977B69864458776715bf8C5570df0ea09F0B57;
    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address private constant ZERO = 0x0000000000000000000000000000000000000000;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
           
    address public marketingWallet = 0xE9977B69864458776715bf8C5570df0ea09F0B57;
    address public tokenWallet = 0xE9977B69864458776715bf8C5570df0ea09F0B57;
    address public immutable pair;

    address[] private pathForSelling = new address[](2);

    modifier onlyCEO(){
        require (msg.sender == CEO, "Only the CEO can do that");
        _;
    }

    event ManualSell(uint256 tokensSold);
    event WalletsChanged(address marketingWallet, address tokenWallet);
    event MinTokensToSellSet(uint256 minTokensToSell);
    event TokenRescued(address tokenRescued, uint256 amountRescued);
    event EthRescued(uint256 balanceRescued);
    event TaxesChanged(uint256 tax, uint256 liq, uint256 marketing, uint256 token, uint256 burn, uint256 taxDivisor);
    event Launched(uint256 launchTime);
    event ExcludedAddressFromTax(address wallet);
    event UnExcludedAddressFromTax(address wallet);
    event AirdropsSent(address[] airdropWallets, uint256[] amount);
    event MarketingTaxSent();

    constructor() {
        router = IDEXRouter(0xEfF92A263d31888d860bD50809A8D171709b7b1c);
        pair = IDEXFactory(IDEXRouter(router).factory()).createPair(WETH, address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;

        limitless[CEO] = true;
        limitless[address(this)] = true;

        pathForSelling[0] = address(this);
        pathForSelling[1] = WETH;

        _balances[CEO] = _totalSupply;
        emit Transfer(address(0), CEO, _totalSupply);
    }

    receive() external payable {}
    function name() public pure override returns (string memory) {return _name;}
    function totalSupply() public view override returns (uint256) {return _totalSupply;}
    function decimals() public pure override returns (uint8) {return _decimals;}
    function symbol() public pure override returns (string memory) {return _symbol;}
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function allowance(address holder, address spender) public view override returns (uint256) {return _allowances[holder][spender];}
    function approveMax(address spender) external returns (bool) {return approve(spender, type(uint256).max);}
    
    function approve(address spender, uint256 amount) public override returns (bool) {
        require(spender != address(0), "Can't use zero address here");
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0), "Can't use zero address here");
        _allowances[msg.sender][spender]  = allowance(msg.sender, spender) + addedValue;
        emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0), "Can't use zero address here");
        require(allowance(msg.sender, spender) >= subtractedValue, "Can't subtract more than current allowance");
        _allowances[msg.sender][spender]  = allowance(msg.sender, spender) - subtractedValue;
        emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);
        return true;
    }
    
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            require(_allowances[sender][msg.sender] >= amount, "Insufficient Allowance");
            _allowances[sender][msg.sender] -= amount;
            emit Approval(sender, msg.sender, _allowances[sender][msg.sender]);
        }
        return _transferFrom(sender, recipient, amount);
    }

    function manualSell() external onlyCEO {
        emit ManualSell(_balances[address(this)]);
        letTheContractSell();
    }

    function setWallets(address marketingAddress, address tokenAddress) external onlyCEO {
        require(marketingAddress != address(0) && tokenAddress != address(0), "Can't use zero addresses here");
        marketingWallet = marketingAddress;
        tokenWallet = tokenAddress;
        emit WalletsChanged(marketingWallet, tokenWallet);
    }
    
    function setMinTokensToSell(uint256 _minTokensToSell) external onlyCEO{
        require(_minTokensToSell >= 0 && _minTokensToSell <= _totalSupply / 50, "Can't set the amount to sell to higher than 2% of totalSupply");  
        minTokensToSell = _minTokensToSell;
        emit MinTokensToSellSet(minTokensToSell);
    }

    function rescueAnyToken(address tokenToRescue) external onlyCEO {
        require(tokenToRescue != address(this), "Can't rescue your own");
        emit TokenRescued(tokenToRescue, IBEP20(tokenToRescue).balanceOf(address(this)));
        IBEP20(tokenToRescue).transfer(msg.sender, IBEP20(tokenToRescue).balanceOf(address(this)));
    }

    function rescueEth() external onlyCEO {
        emit EthRescued(address(this).balance);
        payable(msg.sender).transfer(address(this).balance);
    }

    function setTax(
        uint256 newTaxDivisor,
        uint256 newLiq,
        uint256 newMarketing,
        uint256 newToken,
        uint256 newBurn
    ) external onlyCEO {
        taxDivisor = newTaxDivisor;
        liq = newLiq;
        marketing = newMarketing;
        token = newToken;
        burn = newBurn;
        tax = liq + marketing + token + burn;
        require(tax <= taxDivisor * 9 / 100, "Taxes are limited to max. 9%");
        emit TaxesChanged(tax, liq, marketing, token, burn, taxDivisor);
    }

    function setMaxTxAndWallet(uint256 _maxTx, uint256 _maxWallet) external onlyCEO {
        require(_maxTx >= _totalSupply / 100, "MaxTx can not be less than 1% of total supply");
        require(_maxWallet >= _totalSupply / 100, "MaxWallet can not be less than 1% of total supply");
        maxTx = _maxTx;
        maxWallet = _maxWallet;
    }

    function setAddressTaxStatus(address wallet, bool status) external onlyCEO {
        limitless[wallet] = status;
        if(status) emit ExcludedAddressFromTax(wallet);
        else emit UnExcludedAddressFromTax(wallet);
    }
    
    function airdropToWallets(address[] memory airdropWallets, uint256[] memory amount) external onlyCEO {
        require(launchTime == type(uint256).max, "Can only airdrop before launch");
        for (uint256 i = 0; i < airdropWallets.length; i++) {
            address wallet = airdropWallets[i];
            uint256 airdropAmount = amount[i] * (10**_decimals);
            _lowGasTransfer(CEO, wallet, airdropAmount);
        }
        emit AirdropsSent(airdropWallets, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(amount == 0) return true;
        if (limitless[sender] || limitless[recipient]) return _lowGasTransfer(sender, recipient, amount);

        require(launchTime <= block.timestamp, "Can't trade before launch");

        if (conditionsToSwapAreMet(sender)) letTheContractSell();
        amount = tax == 0 ? amount : takeTax(sender, recipient, amount);
        return _lowGasTransfer(sender, recipient, amount);
    }

    function takeTax(address sender, address recipient, uint256 amount) internal returns (uint256) {
        uint256 taxAmount = amount * tax / taxDivisor;
        if(block.timestamp < launchTime + 5 hours){
            if(recipient == pair) taxAmount = taxAmount * (2 - (block.timestamp - launchTime) / 5 hours);
            if(sender == pair && block.timestamp < launchTime + 2 minutes) {
                taxAmount = 0;
                if(amount > maxTx) {
                    uint256 specialSnipeTax = amount - maxTx;
                    taxAmount = specialSnipeTax;
                    amount = maxTx;
                }                
                taxAmount += amount * (90 - 5*(block.number - launchBlock)) / 100; 
            }
        }

        if(sender == pair) require(_balances[recipient] + amount <= maxWallet, "Please respect the maxWallet");   
        require(amount <= maxTx, "Please respect the maxTx");
        
        if(burn > 0) _lowGasTransfer(sender, DEAD, taxAmount * burn / tax);
        if(token > 0) _lowGasTransfer(sender, tokenWallet, taxAmount * token / tax);
        if(liq > 0 || marketing > 0) _lowGasTransfer(sender, address(this), taxAmount * (marketing + liq) / tax);
        return amount - taxAmount;
    }

    function conditionsToSwapAreMet(address sender) internal view returns (bool) {
        return sender != pair && balanceOf(address(this)) >= minTokensToSell;
    }

    function _lowGasTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(sender != address(0) && recipient != address(0), "Can't use zero addresses here");
        require(amount <= _balances[sender], "Can't transfer more than you own");
        if(amount == 0) return true;
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function letTheContractSell() internal {
        if(marketing == 0 && liq == 0) return;
        uint256 tokensForMarketing = _balances[address(this)] * marketing / (marketing + liq);
        
        if(tokensForMarketing > 0)
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokensForMarketing,
            0,
            pathForSelling,
            address(this),
            block.timestamp
        );

        if(_balances[address(this)] > 0){
            _lowGasTransfer(address(this), pair, _balances[address(this)]);
            IDEXPair(pair).sync();
        }

        (bool success,) = address(marketingWallet).call{value: address(this).balance}("");
        if(success) emit MarketingTaxSent();
    }

    function launch() external onlyCEO{
        require(launchTime == type(uint256).max, "Can't call this twice");
        launchTime = block.timestamp;
        launchBlock = block.number;
        emit Launched(launchTime);
    }
}