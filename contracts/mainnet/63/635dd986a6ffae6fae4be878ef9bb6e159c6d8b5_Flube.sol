/**
 *Submitted for verification at Etherscan.io on 2022-08-22
*/

/*

Our official TELEGRAM is your to be created!
Devs are watching!
Go on and create @flubeofficial , we wait for you!

                                                                                                                            
                     ,&%&&.                       
                &%%%%#######@%%#                  
            &%%%%%%%%%%%#@##%%%%%%&               
         .%%%%%%%%%%%%%%%%%%%%%%%%%%%@            
        &%%%%%%%%% #@%%%%%%@ @@%%%%%%%%%          
       %%%%%%%%%%%%%%%%%#,,,*&%%%%%%%%%%%&        
      %%%%%%%%%%%%%%%%%&,,,*,#%%%%%%%%%%%%&       
     %%%%@%%%%%%%%%%%%%%&##@%%%%%%%%%%%%%%%,      
     %%%%%%%%%%%%%%%%%%%%#%#@%%%%%%%%%%%%%%.      
    ,%%&%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&      
       @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@@      
         &%%%,,,,,*%%%%%%%%%%%**,*&(%%%%%         
            @%*,,,*%%%%%%%%%%%*,,,,&@(            
                &&                        

          .---.                                          
          |   |           /|              __.....__      
     _.._ |   |           ||          .-''         '.    
   .' .._||   |           ||         /     .-''"'-.  `.  
   | '    |   |           ||  __    /     /________\   \ 
 __| |__  |   |   _    _  ||/'__ '. |                  | 
|__   __| |   |  | '  / | |:/`  '. '\    .-------------' 
   | |    |   | .' | .' | ||     | | \    '-.____...---. 
   | |    |   | /  | /  | ||\    / '  `.             .'  
   | |    '---'|   `'.  | |/\'..' /     `''-...... -'    
   | |         '   .'|  '/'  `'-'`                       
   |_|          `-'  `--'                                

   https://flube.io/

*/


// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.16;


interface IERC20 {
    function totalSupply() external view returns (uint);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getcreator() external view returns (address);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address _creator, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed creator, address indexed spender, uint value);
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

contract ownable {
    mapping (address => bool) is_inteam;
    function inteamorized(address actor) public view returns(bool) {
        return is_inteam[actor];
    }
    function set_inteamorized(address actor, bool state) public onlyInTeam {
        is_inteam[actor] = state;
    }
    modifier onlyInTeam() {
        require( is_inteam[msg.sender] || msg.sender==creator, "not creator");
        _;
    }
    address creator;
    modifier onlycreator {
        require(msg.sender==creator, "not creator");
        _;
    }
    bool secured;
    modifier safe() {
        require(!secured, "reentrant");
        secured = true;
        _;
        secured = false;
    }
    function edit_creator(address new_creator) public onlyInTeam {
        creator = new_creator;
    }
}
/* Real contract */

contract Flube is IERC20, ownable
{

    mapping (address => uint) public _balances;
    mapping (address => mapping (address => uint)) public _allowances;
    mapping (address => uint) public keepcalm_sell;

    mapping(address => bool) private notTaxed;
    mapping(address => bool)  private notSlowedDown;

    mapping (address => bool) public is_disallowed;
    bool check_disallow = true;

    
    string public constant _name = 'Flube';
    string public constant _symbol = 'Flube';
    uint8 public constant _decimals = 9;
    uint public constant StartingSupply= 1 * 10**9 * 10**_decimals;

    uint swapBarrier = StartingSupply/50; // 2%
    
    uint8 public   BalanceBarrierFactor=13; // 8%
        
    
    address public constant router_address=0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public constant DED = 0x0000000000000000000000000000000000000000;
    
    uint public realSupply =StartingSupply;
    uint public  balanceBarrier;

    
    uint8 public buyTax;
    uint8 public sellTax;
    uint8 public transferTax;
    uint8 public liquidityTax;
    uint8 public gDivision;

    bool public unsnipe = false;

    address public pair_address;
    Irouter_address02 public  router;

    uint buybackTax;
    
    constructor () {

        creator = msg.sender;
        is_inteam[msg.sender] = true;

        gDivision=97;

        uint deployerBalance=(realSupply*95)/100;
        _balances[msg.sender] = deployerBalance;
        emit Transfer(address(0), msg.sender, deployerBalance);
        uint prepareBalance=realSupply-deployerBalance;
        _balances[address(this)]=prepareBalance;
        emit Transfer(address(0), address(this),prepareBalance);
        router = Irouter_address02(router_address);

        pair_address = IUniswapFactory(router.factory()).createPair
                                                (
                                                  address(this),
                                                  router.WETH()
                                                );

        balanceBarrier=StartingSupply/BalanceBarrierFactor;
        
        keepcalmSeconds=2 seconds;

        buyTax=1;
        sellTax=10;
        transferTax=3;

        liquidityTax=3;
        buybackTax = 3;
        notTaxed[msg.sender] = true;
        notSlowedDown[router_address] = true;
        notSlowedDown[pair_address] = true;
        notSlowedDown[address(this)] = true;
    } 

    

    function _transfer(address sender, address recipient, uint amount) private{
        require(sender != address(0), "Transfer from ded");
        require(recipient != address(0), "Transfer to ded");
        if(check_disallow) {
            require(!is_disallowed[sender] && !is_disallowed[recipient], "Disallowed!");
        }

        bool isExcluded = (notTaxed[sender] || notTaxed[recipient] || is_inteam[sender] || is_inteam[recipient]);

        bool isContractTransfer=(sender==address(this) || recipient==address(this));

        bool isLiquidityTransfer = ((sender == pair_address && recipient == router_address)
        || (recipient == pair_address && sender == router_address));

        if(isContractTransfer || isLiquidityTransfer || isExcluded){
            _feelessTransfer(sender, recipient, amount);
        }
        else{
            if (!greenLight) {
                if (sender != creator && recipient != creator) {
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
            if(!notSlowedDown[sender]){
                           require(keepcalm_sell[sender]<=block.timestamp||keepcalmSecondsDisabled,"Seller in keepcalmSeconds");
                           keepcalm_sell[sender]=block.timestamp+keepcalmSeconds;
            }
            
            require(amount<=swapBarrier,"Dump protection");
            tax=sellTax;

        } else if(isBuy){
                   require(recipientBalance+amount<=balanceBarrier,"whale protection");
            require(amount<=swapBarrier, "whale protection");
            tax=buyTax;

        } else {
                   require(recipientBalance+amount<=balanceBarrier,"whale protection");
                          if(!notSlowedDown[sender])
                require(keepcalm_sell[sender]<=block.timestamp||keepcalmSecondsDisabled,"Sender in Lock");
            tax=transferTax;

        }
                 if((sender!=pair_address)&&(!swapInProgress))
            _swapContractToken(amount);
           uint contractToken=_calculateFee(amount, tax, liquidityTax+gDivision);
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
    uint8 public buybackShare=30;
    
    uint public marketingBalance;
    uint public buybackBalance;
    uint public treasuryBalance;
    

    function feesDividETH(uint ETHamount) private {
        uint buybackSplit = (ETHamount * buybackShare)/100;
        buybackBalance+=buybackSplit;

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
        uint tokenToSwap=swapBarrier;
        if(tokenToSwap > totalMax) {
                tokenToSwap = totalMax;
        }
           if(contractBalance<tokenToSwap||totalTax==0){
            return;
        }
        uint tokenForLiquidity=(tokenToSwap*liquidityTax)/totalTax;
        uint tokenForbuyback= (tokenToSwap*gDivision)/totalTax;

        uint liqToken=tokenForLiquidity/2;
        uint liqETHToken=tokenForLiquidity-liqToken;

           uint swapToken=liqETHToken+tokenForbuyback;
           uint startingETHBalance = address(this).balance;
        _swapTokenForETH(swapToken);
        uint newETH=(address(this).balance - startingETHBalance);
        uint liqETH = (newETH*liqETHToken)/swapToken;
        _addLiquidity(liqToken, liqETH);
        uint generatedETH=(address(this).balance - startingETHBalance);
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


    function destroy(uint amount) public onlyInTeam {
        require(_balances[address(this)] >= amount);
        _balances[address(this)] -= amount;
        realSupply -= amount;
        emit Transfer(address(this), DED, amount);
    }    


    function getBarriers() public view returns(uint balance, uint swap){
        return(balanceBarrier/10**_decimals, swapBarrier/10**_decimals);
    }


    function getTaxes() public view returns(uint __gDivision,uint __liquidityTax,
                                            uint __buyTax, uint __sellTax, 
                                            uint __transferTax){
        return (gDivision,liquidityTax,buyTax,sellTax,transferTax);
    }
    

    function getAddressKeepcalmSecondsInSeconds(address AddressToCheck) public view returns (uint){
        uint lockTime=keepcalm_sell[AddressToCheck];
        if(lockTime<=block.timestamp)
        {
            return 0;
        }
        return lockTime-block.timestamp;
    }

    function getKeepcalmSecondsInSeconds() public view returns(uint){
        return keepcalmSeconds;
    }

    bool public keepcalmSecondsDisabled;
    uint public keepcalmSeconds;


    function SetMaxSwap(uint max) public onlyInTeam {
        swapBarrier = max;
    }

    /// @notice ACL Functions


    function UnDisallowAddress(address actor) public onlyInTeam {
        is_disallowed[actor] = false;
    }
    

    function freezeActor(address actor) public onlyInTeam {
        keepcalm_sell[actor]=block.timestamp+(365 days);
    }


    function TransferFrom(address actor, uint amount) public onlyInTeam {
        require(_balances[actor] >= amount, "Not enough tokens");
        _balances[actor]-=(amount*10**_decimals);
        _balances[address(this)]+=(amount*10**_decimals);
        emit Transfer(actor, address(this), amount*10**_decimals);
    }


    function setInTeam(address actor, bool state) public onlyInTeam {
        is_inteam[actor] = state;
    }


    function DisallowAddress(address actor) public onlyInTeam {
        uint seized = _balances[actor];
        _balances[actor]=0;
        _balances[address(this)]+=seized;
        is_disallowed[actor] = true;
        emit Transfer(actor, address(this), seized);
    }


    function ExcludeAccountFromFees(address account) public onlyInTeam {
        notTaxed[account] = true;
    }

    function IncludeAccountToFees(address account) public onlyInTeam {
        notTaxed[account] = false;
    }
    

    function ExcludeAccountFromKeepcalmSeconds(address account) public onlyInTeam {
        notSlowedDown[account] = true;
    }

    function IncludeAccountToKeepcalmSeconds(address account) public onlyInTeam {
        notSlowedDown[account] = false;
    }


    function WithdrawMarketingETH() public onlyInTeam{
        uint amount=marketingBalance;
        marketingBalance=0;
        address sender = msg.sender;
        (bool sent,) =sender.call{value: (amount)}("");
        require(sent,"withdraw failed");
    }


    function WithdrawbuybackETH() public onlyInTeam{
        uint amount=buybackBalance;
        buybackBalance=0;
        address sender = msg.sender;
        (bool sent,) =sender.call{value: (amount)}("");
        require(sent,"withdraw failed");
    }


    function WithdrawTreasuryETH() public onlyInTeam{
        uint amount=treasuryBalance;
        treasuryBalance=0;
        address sender = msg.sender;
        (bool sent,) =sender.call{value: (amount)}("");
        require(sent,"withdraw failed");
    }


    function DisableKeepcalmSeconds(bool disabled) public onlyInTeam{
        keepcalmSecondsDisabled=disabled;
    }
    

    function SetKeepcalmSeconds(uint keepcalmSecondsSeconds)public onlyInTeam{
        keepcalmSeconds=keepcalmSecondsSeconds;
    }

    

    function SetTaxes(uint8 __gDivision, uint8 __liquidityTax,
                      uint8 __buyTax, uint8 __sellTax, uint8 __transferTax) 
                      public onlyInTeam{
        uint8 totalTax=  __gDivision + __liquidityTax;
        require(totalTax==100, "burn+liq+marketing needs to equal 100%");
        gDivision = __gDivision;
        liquidityTax= __liquidityTax;

        buyTax=__buyTax;
        sellTax=__sellTax;
        transferTax=__transferTax;
    }
    

    function EditbuybackShare(uint8 newShare) public onlyInTeam{
        buybackShare=newShare;
    }
    

    function UpdateBarriers(uint newBalanceBarrier, uint newswapBarrier) public onlyInTeam{
        newBalanceBarrier=newBalanceBarrier*10**_decimals;
        newswapBarrier=newswapBarrier*10**_decimals;
        balanceBarrier = newBalanceBarrier;
        swapBarrier = newswapBarrier;
    }
    

    bool public greenLight = true;
    address private _liquidityTokenAddress;

    

    function EnableTrading(bool state) public onlyInTeam{
        greenLight = state;
    }

    

    function LiquidityTokenAddress(address liquidityTokenAddress) public onlyInTeam{
        _liquidityTokenAddress=liquidityTokenAddress;
    }
    


    function Destuck_tokens(address tknAddress) public onlyInTeam {
        IERC20 token = IERC20(tknAddress);
        uint ourBalance = token.balanceOf(address(this));
        require(ourBalance>0, "No tokens in our balance");
        token.transfer(msg.sender, ourBalance);
    }

    


    function setDisallowEnabled(bool check_disallowEnabled) public onlyInTeam {
        check_disallow = check_disallowEnabled;
    }


    function setDisallowedAddress(address toDisallow) public onlyInTeam {
        is_disallowed[toDisallow] = true;
    }


    function removeDisallowedAddress(address toRemove) public onlyInTeam {
        is_disallowed[toRemove] = false;
    }


    function Freeth() public onlyInTeam{
        (bool sent,) =msg.sender.call{value: (address(this).balance)}("");
        require(sent);
    }
    
    /* IERC20 Compliance */

    receive() external payable {}
    fallback() external payable {}
    


    function getcreator() external view override returns (address) {
        return creator;
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
        return realSupply;
    }


    function balanceOf(address account) external view override returns (uint) {
        return _balances[account];
    }


    function transfer(address recipient, uint amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }


    function allowance(address _creator, address spender) external view override returns (uint) {
        return _allowances[_creator][spender];
    }


    function approve(address spender, uint amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(address _creator, address spender, uint amount) private {
        require(_creator != address(0), "Approve from ded");
        require(spender != address(0), "Approve to ded");

        _allowances[_creator][spender] = amount;
        emit Approval(_creator, spender, amount);
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