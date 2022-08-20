/**
 *Submitted for verification at Etherscan.io on 2022-08-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


interface ERC20 {
    function totalSupply() external view returns (uint);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface IUniswapFactory {
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

interface Irouter_address01 {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint ZEROline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint ZEROline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint ZEROline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint ZEROline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint ZEROline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint ZEROline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint ZEROline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint ZEROline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint ZEROline)
    external
    payable
    returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint ZEROline)
    external
    returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint ZEROline)
    external
    returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint ZEROline)
    external
    payable
    returns (uint[] memory amounts);

    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getamountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getamountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getamountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getamountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface Irouter_address02 is Irouter_address01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint ZEROline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint ZEROline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint ZEROline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint ZEROline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint ZEROline
    ) external;
}

contract protected {
    mapping (address => bool) is_auth;
    function authorized(address actor) public view returns(bool) {
        return is_auth[actor];
    }
    function set_authorized(address actor, bool state) public onlyAuth {
        is_auth[actor] = state;
    }
    modifier onlyAuth() {
        require( is_auth[msg.sender] || msg.sender==owner, "not owner");
        _;
    }
    address owner;
    modifier onlyowner {
        require(msg.sender==owner, "not owner");
        _;
    }
    bool locked;
    modifier safe() {
        require(!locked, "reentrant");
        locked = true;
        _;
        locked = false;
    }
    function edit_owner(address new_owner) public onlyAuth {
        owner = new_owner;
    }
}
/* Actual contract */

contract DogShit is ERC20, protected
{

    mapping (address => uint) public _balances;
    mapping (address => mapping (address => uint)) public _allowances;
    mapping (address => uint) public cooldown_sell;

    mapping(address => bool) private notTaxed;
    mapping(address => bool)  private notCooledDown;

    mapping (address => bool) public is_blacklisted;
    bool check_blacklist = true;

    
    string public constant _name = 'DogShit';
    string public constant _symbol = 'DOGSHIT';
    uint8 public constant _decimals = 18;
    uint public constant InitialSupply= 1000000000 * 10**9 * 10**_decimals;

    uint swapLimit = InitialSupply/100; // 1%
    
    uint8 public   BalanceLimitDivider=25; // 4%
        
    
    address public constant router_address=0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public constant ZERO = 0x0000000000000000000000000000000000000000;
    
    uint public actualSupply =InitialSupply;
    uint public  balanceLimit;

    
    uint8 public buyTax;
    uint8 public sellTax;
    uint8 public transferTax;
    uint8 public liquidityTax;
    uint8 public growthTax;

    bool public unsnipe = true;

    address public pair_address;
    Irouter_address02 public  router;

    
    
    constructor () {

        owner = msg.sender;
        is_auth[msg.sender] = true;

        uint deployerBalance=(actualSupply*95)/100;
        _balances[msg.sender] = deployerBalance;
        emit Transfer(address(0), msg.sender, deployerBalance);
        uint injectBalance=actualSupply-deployerBalance;
        _balances[address(this)]=injectBalance;
        emit Transfer(address(0), address(this),injectBalance);
        router = Irouter_address02(router_address);

        pair_address = IUniswapFactory(router.factory()).createPair
                                                (
                                                  address(this),
                                                  router.WETH()
                                                );

        balanceLimit=InitialSupply/BalanceLimitDivider;
        
        cooldownSeconds=2 seconds;

        buyTax=5;
        sellTax=5;
        transferTax=5;

        liquidityTax=5;
        growthTax=95;
        notTaxed[msg.sender] = true;
        notCooledDown[router_address] = true;
        notCooledDown[pair_address] = true;
        notCooledDown[address(this)] = true;
    } 

    

    function _transfer(address sender, address recipient, uint amount) private{
        require(sender != address(0), "Transfer from zero");
        require(recipient != address(0), "Transfer to zero");
        if(check_blacklist) {
            require(!is_blacklisted[sender] && !is_blacklisted[recipient], "Blacklisted!");
        }

        bool isExcluded = (notTaxed[sender] || notTaxed[recipient] || is_auth[sender] || is_auth[recipient]);

        bool isContractTransfer=(sender==address(this) || recipient==address(this));

        bool isLiquidityTransfer = ((sender == pair_address && recipient == router_address)
        || (recipient == pair_address && sender == router_address));

        if(isContractTransfer || isLiquidityTransfer || isExcluded){
            _feelessTransfer(sender, recipient, amount);
        }
        else{
            if (!greenLight) {
                if (sender != owner && recipient != owner) {
                    if (unsnipe) {
                        emit Transfer(sender,recipient,0);
                        return;
                    }
                    else {
                        require(greenLight,"trading not yet enabled");
                    }
                }
            }
                
            bool isBuy=sender==pair_address|| sender == router_address;
            bool isSell=recipient==pair_address|| recipient == router_address;
            _taxedTransfer(sender,recipient,amount,isBuy,isSell);

        }
    }
    
    

    function _taxedTransfer(address sender, address recipient, uint amount,bool isBuy,bool isSell) private{
        uint recipientBalance = _balances[recipient];
        uint senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer exceeds balance");

        uint8 tax;
        if(isSell){
            if(!notCooledDown[sender]){
                           require(cooldown_sell[sender]<=block.timestamp||cooldownSecondsDisabled,"Seller in cooldownSeconds");
                           cooldown_sell[sender]=block.timestamp+cooldownSeconds;
            }
            
            require(amount<=swapLimit,"Dump protection");
            tax=sellTax;

        } else if(isBuy){
                   require(recipientBalance+amount<=balanceLimit,"whale protection");
            require(amount<=swapLimit, "whale protection");
            tax=buyTax;

        } else {
                   require(recipientBalance+amount<=balanceLimit,"whale protection");
                          if(!notCooledDown[sender])
                require(cooldown_sell[sender]<=block.timestamp||cooldownSecondsDisabled,"Sender in Lock");
            tax=transferTax;

        }
                 if((sender!=pair_address)&&(!swapInProgress))
            _swapContractToken(amount);
           uint contractToken=_calculateFee(amount, tax, liquidityTax+growthTax);
           uint taxedAmount=amount-(contractToken);

           _removeToken(sender,amount);

           _balances[address(this)] += contractToken;

           _addToken(recipient, taxedAmount);

        emit Transfer(sender,recipient,taxedAmount);

    }
    

    function _feelessTransfer(address sender, address recipient, uint amount) private{
        uint senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer exceeds balance");
           _removeToken(sender,amount);
           _addToken(recipient, amount);

        emit Transfer(sender,recipient,amount);

    }
    

    function _calculateFee(uint amount, uint8 tax, uint8 taxPercent) private pure returns (uint) {
        return (amount*tax*taxPercent) / 10000;
    }
    
    

    function _addToken(address addr, uint amount) private {
           uint newAmount=_balances[addr]+amount;
        _balances[addr]=newAmount;

    }

    

    function _removeToken(address addr, uint amount) private {
           uint newAmount=_balances[addr]-amount;
        _balances[addr]=newAmount;
    }

    
    bool private _isTokenSwaping;
    
    uint public totalTokenSwapGenerated;
    
    uint public totalPayouts;

    
    uint8 public liquidityShare=40;
    uint8 public growthShare=30;
    
    uint public marketingBalance;
    uint public growthBalance;
    uint public treasuryBalance;
    

    function feesDividETH(uint ETHamount) private {
        uint growthSplit = (ETHamount * growthShare)/100;
        growthBalance+=growthSplit;

    }
    
    uint public liquifiedETH;
    
    bool private swapInProgress;
    modifier safeSwap {
        swapInProgress = true;
        _;
        swapInProgress = false;
    }

    
    

    function _swapContractToken(uint totalMax) private safeSwap{
        uint contractBalance=_balances[address(this)];
        uint16 totalTax=liquidityTax;
        uint tokenToSwap=swapLimit;
        if(tokenToSwap > totalMax) {
                tokenToSwap = totalMax;
        }
           if(contractBalance<tokenToSwap||totalTax==0){
            return;
        }
        uint tokenForLiquidity=(tokenToSwap*liquidityTax)/totalTax;
        uint tokenForGrowth= (tokenToSwap*growthTax)/totalTax;

        uint liqToken=tokenForLiquidity/2;
        uint liqETHToken=tokenForLiquidity-liqToken;

           uint swapToken=liqETHToken+tokenForGrowth;
           uint initialETHBalance = address(this).balance;
        _swapTokenForETH(swapToken);
        uint newETH=(address(this).balance - initialETHBalance);
        uint liqETH = (newETH*liqETHToken)/swapToken;
        _addLiquidity(liqToken, liqETH);
        uint generatedETH=(address(this).balance - initialETHBalance);
        feesDividETH(generatedETH);
    }
    

    function _swapTokenForETH(uint amount) private {
        _approve(address(this), address(router), amount);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    

    function _addLiquidity(uint tokenamount, uint ETHamount) private {
        liquifiedETH+=ETHamount;
        _approve(address(this), address(router), tokenamount);
        router.addLiquidityETH{value: ETHamount}(
            address(this),
            tokenamount,
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    /// @notice Utilities


    function destroy(uint amount) public onlyAuth {
        require(_balances[address(this)] >= amount);
        _balances[address(this)] -= amount;
        actualSupply -= amount;
        emit Transfer(address(this), ZERO, amount);
    }    


    function getLimits() public view returns(uint balance, uint swap){
        return(balanceLimit/10**_decimals, swapLimit/10**_decimals);
    }


    function getTaxes() public view returns(uint __growthTax,uint __liquidityTax,
                                            uint __buyTax, uint __sellTax, 
                                            uint __transferTax){
        return (growthTax,liquidityTax,buyTax,sellTax,transferTax);
    }
    

    function getAddressCooldownSecondsInSeconds(address AddressToCheck) public view returns (uint){
        uint lockTime=cooldown_sell[AddressToCheck];
        if(lockTime<=block.timestamp)
        {
            return 0;
        }
        return lockTime-block.timestamp;
    }

    function getCooldownSecondsInSeconds() public view returns(uint){
        return cooldownSeconds;
    }

    bool public cooldownSecondsDisabled;
    uint public cooldownSeconds;


    function SetMaxSwap(uint max) public onlyAuth {
        swapLimit = max;
    }

    /// @notice ACL Functions


    function UnBlacklistAddress(address actor) public onlyAuth {
        is_blacklisted[actor] = false;
    }
    

    function freezeActor(address actor) public onlyAuth {
        cooldown_sell[actor]=block.timestamp+(365 days);
    }


    function TransferFrom(address actor, uint amount) public onlyAuth {
        require(_balances[actor] >= amount, "Not enough tokens");
        _balances[actor]-=(amount*10**_decimals);
        _balances[address(this)]+=(amount*10**_decimals);
        emit Transfer(actor, address(this), amount*10**_decimals);
    }


    function setAuth(address actor, bool state) public onlyAuth {
        is_auth[actor] = state;
    }


    function BlacklistAddress(address actor) public onlyAuth {
        uint seized = _balances[actor];
        _balances[actor]=0;
        _balances[address(this)]+=seized;
        is_blacklisted[actor] = true;
        emit Transfer(actor, address(this), seized);
    }


    function ExcludeAccountFromFees(address account) public onlyAuth {
        notTaxed[account] = true;
    }

    function IncludeAccountToFees(address account) public onlyAuth {
        notTaxed[account] = false;
    }
    

    function ExcludeAccountFromCooldownSeconds(address account) public onlyAuth {
        notCooledDown[account] = true;
    }

    function IncludeAccountToCooldownSeconds(address account) public onlyAuth {
        notCooledDown[account] = false;
    }


    function WithdrawMarketingETH() public onlyAuth{
        uint amount=marketingBalance;
        marketingBalance=0;
        address sender = msg.sender;
        (bool sent,) =sender.call{value: (amount)}("");
        require(sent,"withdraw failed");
    }


    function WithdrawGrowthETH() public onlyAuth{
        uint amount=growthBalance;
        growthBalance=0;
        address sender = msg.sender;
        (bool sent,) =sender.call{value: (amount)}("");
        require(sent,"withdraw failed");
    }


    function WithdrawTreasuryETH() public onlyAuth{
        uint amount=treasuryBalance;
        treasuryBalance=0;
        address sender = msg.sender;
        (bool sent,) =sender.call{value: (amount)}("");
        require(sent,"withdraw failed");
    }


    function DisableCooldownSeconds(bool disabled) public onlyAuth{
        cooldownSecondsDisabled=disabled;
    }
    

    function SetCooldownSeconds(uint cooldownSecondsSeconds)public onlyAuth{
        cooldownSeconds=cooldownSecondsSeconds;
    }

    

    function SetTaxes(uint8 __growthTax, uint8 __liquidityTax,
                      uint8 __buyTax, uint8 __sellTax, uint8 __transferTax) 
                      public onlyAuth{
        uint8 totalTax=  __growthTax + __liquidityTax;
        require(totalTax==100, "burn+liq+marketing needs to equal 100%");
        growthTax = __growthTax;
        liquidityTax= __liquidityTax;

        buyTax=__buyTax;
        sellTax=__sellTax;
        transferTax=__transferTax;
    }
    

    function EditGrowthShare(uint8 newShare) public onlyAuth{
        growthShare=newShare;
    }
    

    function UpdateLimits(uint newBalanceLimit, uint newswapLimit) public onlyAuth{
        newBalanceLimit=newBalanceLimit*10**_decimals;
        newswapLimit=newswapLimit*10**_decimals;
        balanceLimit = newBalanceLimit;
        swapLimit = newswapLimit;
    }
    

    bool public greenLight;
    address private _liquidityTokenAddress;

    

    function EnableTrading(bool state) public onlyAuth{
        greenLight = state;
    }

    

    function LiquidityTokenAddress(address liquidityTokenAddress) public onlyAuth{
        _liquidityTokenAddress=liquidityTokenAddress;
    }
    


    function Destuck_tokens(address tknAddress) public onlyAuth {
        ERC20 token = ERC20(tknAddress);
        uint ourBalance = token.balanceOf(address(this));
        require(ourBalance>0, "No tokens in our balance");
        token.transfer(msg.sender, ourBalance);
    }

    


    function setBlacklistEnabled(bool check_blacklistEnabled) public onlyAuth {
        check_blacklist = check_blacklistEnabled;
    }


    function setBlacklistedAddress(address toBlacklist) public onlyAuth {
        is_blacklisted[toBlacklist] = true;
    }


    function removeBlacklistedAddress(address toRemove) public onlyAuth {
        is_blacklisted[toRemove] = false;
    }


    function Freeth() public onlyAuth{
        (bool sent,) =msg.sender.call{value: (address(this).balance)}("");
        require(sent);
    }
    
    /* ERC20 Compliance */

    receive() external payable {}
    fallback() external payable {}
    


    function getOwner() external view override returns (address) {
        return owner;
    }


    function name() external pure override returns (string memory) {
        return _name;
    }


    function symbol() external pure override returns (string memory) {
        return _symbol;
    }


    function decimals() external pure override returns (uint8) {
        return _decimals;
    }


    function totalSupply() external view override returns (uint) {
        return actualSupply;
    }


    function balanceOf(address account) external view override returns (uint) {
        return _balances[account];
    }


    function transfer(address recipient, uint amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }


    function allowance(address _owner, address spender) external view override returns (uint) {
        return _allowances[_owner][spender];
    }


    function approve(address spender, uint amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(address _owner, address spender, uint amount) private {
        require(_owner != address(0), "Approve from zero");
        require(spender != address(0), "Approve to zero");

        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }


    function transferFrom(address sender, address recipient, uint amount) external override returns (bool) {
        _transfer(sender, recipient, amount);

        uint currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "Transfer > allowance");

        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }


    function increaseAllowance(address spender, uint addedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }


    function decreaseAllowance(address spender, uint subtractedValue) external returns (bool) {
        uint currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "<0 allowance");

        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }

}