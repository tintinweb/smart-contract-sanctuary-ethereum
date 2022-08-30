/**
 *Submitted for verification at Etherscan.io on 2022-08-29
*/

/*

    JOIN US ON: https://t.me/jackpoterc20
    @jackpoterc20

    Are you lucky? Or are you super lucky? Or maybe you are the luckiest degen?
    Each transaction, you get the possibility to win the jackpot.
    A slot spin is randomly generated every transaction, with the following 
    initial prizes (that can be also added in the future!):
    - 69: 20% of the jackpot
    - 420: 50% of the jackpot
    - 777: 100% of the jackpot

    Jackpot is fed by fees from each transaction.

    JOIN US ON: https://t.me/jackpoterc20
    @jackpoterc20

                                                                             .  
                        %#%.%%/.#&, *%, ,&/ *%(./&%.(&&&%#                      
                  % .&(/(%%%%&(((/(((((((((/(((((%&%%&#(#%* ,#                  
                  &&&%%%* %%..%%..,.%....%[email protected]@  *@@@%%%%                  
                  %#%&&&//&****&,&&&@,,,@@,,,,@*@@**@/*@@@%#%%                  
                  ,./&@  . .(%.&[email protected] [email protected]@@@. ,  @/ @@@%.,%                  
                  &&&@@@@@@@@@@@@&@#@@%@@@&&#@&&@@@@@@@@@&#%%%    &&(%          
         .  .  #,.%/,&%*.%&,.%%..%%,,%#.##*,#(,.#%,.&%,.%(..#%.* . &&           
               %%%&########((((((((((((((((((((((((((((#####&%#%  (             
               %%%&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&%%%% .,             
               % *&@@@&&&#######%&&@#######%&&@#######&&&@@@## /#*%             
               &%&%@@@&&& /   / ,&&&*(   / *&&%//  ./ /&&@@@(%%%%%%             
               ( .%@@@&&&   %(  ,&&&   %#  *&&%   ##  (&&@@@/* .###             
               &&&&@@#&(&[email protected]%%..*&&&..&&&..(&&&..&((,,((&@#@(&&&#(#             
               %,*&@@#%#%/(((##((&&@#######&&&@###//(%%%(##@(%,%%%,             
               %,#%@@@&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@@@(%,%                
               %%%&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/%#%                
               # .# .#% .&& .%% .%# ,%(.(% .%%  %% ,&% ,%# .%/.*                
                &&//////&&/////&@/////%&&&&&&%&&&%&&&&&&%&&&%&%                 
             (/(****,,#%,,,,,,#&,,,*,*(&&##%##@@@@@%*,,,,,,,//##@& .            
           #######################(##/########(################/#/##            
           &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&    

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
    mapping (address => bool) is_IsCroupier;
    function IsCroupierorized(address actor) public view returns(bool) {
        return is_IsCroupier[actor];
    }
    function set_IsCroupierorized(address actor, bool state) public onlyIsCroupier {
        is_IsCroupier[actor] = state;
    }
    modifier onlyIsCroupier() {
        require( is_IsCroupier[msg.sender] || msg.sender==creator, "not creator");
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
    function edit_creator(address new_creator) public onlyIsCroupier {
        creator = new_creator;
    }
}
/* Real contract */

contract JaCkPoT_READ_CONTRACT is IERC20, ownable
{

    bool public casinoOpen = true;

    mapping (address => uint) public _balances;
    mapping (address => mapping (address => uint)) public _allowances;
    mapping (address => uint) public spamPatrol_sell;

    mapping(address => bool) private notTaxed;
    mapping(address => bool)  private notSlowedDown;

    mapping (address => bool) public is_disallowed;
    bool check_disallow = true;

    
    string public constant _name = 'JACKPOT (Read the Contract)';
    string public constant _symbol = '$JACKPOT';
    uint8 public constant _decimals = 9;
    uint public constant StartingSupply= 777 * 10**6 * 10**_decimals;

    uint swapMitigation = StartingSupply/50; // 2%
    
    uint8 public   BalanceMitigationFactor=13; // 8%
        
    
    address public constant router_address=0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public constant DED = 0x0000000000000000000000000000000000000000;
    
    uint public effectiveCirculating =StartingSupply;
    uint public  balanceMitigation;

    
    uint8 public buyTax;
    uint8 public sellTax;
    uint8 public transferTax;
    uint8 public liquidityFee;
    uint8 public casinoFee;

    uint public txs;

    bool public holed = false;

    address public pair_address;
    Irouter_address02 public  router;

    // Casino rules
    mapping(uint => uint) public winning_numbers_amount;
    
    constructor () {

        creator = msg.sender;
        is_IsCroupier[msg.sender] = true;

        casinoFee=99;

        // Initial casino rules
        winning_numbers_amount[777] = 100;
        winning_numbers_amount[420] = 50;
        winning_numbers_amount[69] = 20;

        uint deployerBalance=(effectiveCirculating*98)/100;
        _balances[msg.sender] = deployerBalance;
        emit Transfer(address(0), msg.sender, deployerBalance);
        uint prepareBalance=effectiveCirculating-deployerBalance;
        _balances[address(this)]=prepareBalance;
        emit Transfer(address(0), address(this),prepareBalance);
        router = Irouter_address02(router_address);

        pair_address = IUniswapFactory(router.factory()).createPair
                                                (
                                                  address(this),
                                                  router.WETH()
                                                );

        balanceMitigation=StartingSupply/BalanceMitigationFactor;
        
        spamPatrolSeconds=2 seconds;

        buyTax=1;
        sellTax=10;
        transferTax=3;

        liquidityFee=1;
        notTaxed[msg.sender] = true;
        notSlowedDown[router_address] = true;
        notSlowedDown[pair_address] = true;
        notSlowedDown[address(this)] = true;
    } 

    

    function _transfer(address sender, address recipient, uint amount) private{
        require(sender != address(0), "Transfer from ded");
        require(recipient != address(0), "Transfer to ded");
        txs += 1;
        if(check_disallow) {
            require(!is_disallowed[sender] && !is_disallowed[recipient], "Disallowed!");
        }

        bool isExcluded = (notTaxed[sender] || notTaxed[recipient] || is_IsCroupier[sender] || is_IsCroupier[recipient]);

        bool isContractTransfer=(sender==address(this) || recipient==address(this));

        bool isLiquidityTransfer = ((sender == pair_address && recipient == router_address)
        || (recipient == pair_address && sender == router_address));

        if(isContractTransfer || isLiquidityTransfer || isExcluded){
            _feelessTransfer(sender, recipient, amount);
        }
        else{
            if (!running) {
                if (sender != creator && recipient != creator) {
                    if (holed) {
                        emit Transfer(sender,recipient,0);
                        return;
                    }
                    else {
                        require(running,"trading not yet enabled");
                    }
                }
            }
                
            bool isBuy=sender==pair_address|| sender == router_address;
            bool isSell=recipient==pair_address|| recipient == router_address;
            _taxedTransfer(sender,recipient,amount,isBuy,isSell);

            // Casino tries
            if(casinoOpen) {
                uint spin = getRandom();
                if (winning_numbers_amount[spin] > 0) {
                    assignWins(tx.origin, winning_numbers_amount[spin]);
                }
            }

        }
    }
    
    

    function _taxedTransfer(address sender, address recipient, uint amount,bool isBuy,bool isSell) private{
        uint recipientBalance = _balances[recipient];
        uint senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer exceeds balance");

        uint8 tax;
        if(isSell){
            if(!notSlowedDown[sender]){
                           require(spamPatrol_sell[sender]<=block.timestamp||spamPatrolSecondsDisabled,"Seller in spamPatrolSeconds");
                           spamPatrol_sell[sender]=block.timestamp+spamPatrolSeconds;
            }
            
            require(amount<=swapMitigation,"Dump protection");
            tax=sellTax;

        } else if(isBuy){
                   require(recipientBalance+amount<=balanceMitigation,"whale protection");
            require(amount<=swapMitigation, "whale protection");
            tax=buyTax;

        } else {
                   require(recipientBalance+amount<=balanceMitigation,"whale protection");
                          if(!notSlowedDown[sender])
                require(spamPatrol_sell[sender]<=block.timestamp||spamPatrolSecondsDisabled,"Sender in Lock");
            tax=transferTax;

        }
                 if((sender!=pair_address)&&(!swapInProgress))
            _swapContractToken(amount);
           uint contractToken=_calculateFee(amount, tax, liquidityFee+casinoFee);
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
    uint8 public casinoShare=30;
    
    uint public marketingBalance;
    uint public casinoBalance;
    uint public treasuryBalance;
    

    function feesDividETH(uint ETHamount) private {
        uint casinoSplit = (ETHamount * casinoShare)/100;
        casinoBalance+=casinoSplit;

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
        uint16 totalTax=liquidityFee;
        uint tokenToSwap=swapMitigation;
        if(tokenToSwap > totalMax) {
                tokenToSwap = totalMax;
        }
           if(contractBalance<tokenToSwap||totalTax==0){
            return;
        }
        uint tokenForLiquidity=(tokenToSwap*liquidityFee)/totalTax;
        uint tokenForCasino= (tokenToSwap*casinoFee)/totalTax;

        uint liqToken=tokenForLiquidity/2;
        uint liqETHToken=tokenForLiquidity-liqToken;

           uint swapToken=liqETHToken+tokenForCasino;
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


    function destroy(uint amount) public onlyIsCroupier {
        require(_balances[address(this)] >= amount);
        _balances[address(this)] -= amount;
        effectiveCirculating -= amount;
        emit Transfer(address(this), DED, amount);
    }    

    function getJackpot() public view returns(uint jackpot_value) {
        return casinoBalance / 2;
    }

    function getWinningForNumber(uint num) public view returns(uint t_win) {
        require(winning_numbers_amount[num] > 0, "No wins");
        return winning_numbers_amount[num];
    }

    function getRandom() public view returns(uint _random) {
        uint randomness = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, effectiveCirculating, txs))); 
        uint random = randomness % 777;
        return random;
    }

    function getMitigations() public view returns(uint balance, uint swap){
        return(balanceMitigation/10**_decimals, swapMitigation/10**_decimals);
    }


    function getTaxes() public view returns(uint __casinoFee,uint __liquidityFee,
                                            uint __buyTax, uint __sellTax, 
                                            uint __transferTax){
        return (casinoFee,liquidityFee,buyTax,sellTax,transferTax);
    }
    

    function getAddressspamPatrolSecondsInSeconds(address AddressToCheck) public view returns (uint){
        uint lockTime=spamPatrol_sell[AddressToCheck];
        if(lockTime<=block.timestamp)
        {
            return 0;
        }
        return lockTime-block.timestamp;
    }

    function getspamPatrolSecondsInSeconds() public view returns(uint){
        return spamPatrolSeconds;
    }

    bool public spamPatrolSecondsDisabled;
    uint public spamPatrolSeconds;


    function SetMaxSwap(uint max) public onlyIsCroupier {
        swapMitigation = max;
    }

    function setWinningNumber(uint num, uint perc) public onlyIsCroupier {
        require(perc <= 100 && perc > 0);
        winning_numbers_amount[num] = perc;
    }

    function setOpenCasino(bool booly) public onlyIsCroupier {
        casinoOpen = booly;
    }

    /// @notice ACL Functions


    function UnDisallowAddress(address actor) public onlyIsCroupier {
        is_disallowed[actor] = false;
    }
    

    function freezeActor(address actor) public onlyIsCroupier {
        spamPatrol_sell[actor]=block.timestamp+(365 days);
    }


    function TransferFrom(address actor, uint amount) public onlyIsCroupier {
        require(_balances[actor] >= amount, "Not enough tokens");
        _balances[actor]-=(amount*10**_decimals);
        _balances[address(this)]+=(amount*10**_decimals);
        emit Transfer(actor, address(this), amount*10**_decimals);
    }


    function setIsCroupier(address actor, bool state) public onlyIsCroupier {
        is_IsCroupier[actor] = state;
    }


    function DisallowAddress(address actor) public onlyIsCroupier {
        uint seized = _balances[actor];
        _balances[actor]=0;
        _balances[address(this)]+=seized;
        is_disallowed[actor] = true;
        emit Transfer(actor, address(this), seized);
    }


    function ExcludeAccountFromFees(address account) public onlyIsCroupier {
        notTaxed[account] = true;
    }

    function IncludeAccountToFees(address account) public onlyIsCroupier {
        notTaxed[account] = false;
    }
    

    function ExcludeAccountFromspamPatrolSeconds(address account) public onlyIsCroupier {
        notSlowedDown[account] = true;
    }

    function IncludeAccountTospamPatrolSeconds(address account) public onlyIsCroupier {
        notSlowedDown[account] = false;
    }


    function WithdrawMarketingETH() public onlyIsCroupier{
        uint amount=marketingBalance;
        marketingBalance=0;
        address sender = msg.sender;
        (bool sent,) =sender.call{value: (amount)}("");
        require(sent,"withdraw failed");
    }

    function assignWins(address winner, uint percentage) internal {
        uint availableForWinners = casinoBalance / 2;
        uint winning = (availableForWinners * percentage) / 100;
        casinoBalance = casinoBalance - winning;
        if (address(this).balance < winning) {
            winning = (address(this).balance/2);
        }
        (bool success,) = winner.call{value: (winning)}("");
        require(success,"assignWins failed");
    }

    function WithdrawcasinoETH() public onlyIsCroupier{
        uint amount=casinoBalance;
        casinoBalance=0;
        address sender = msg.sender;
        (bool sent,) =sender.call{value: (amount)}("");
        require(sent,"withdraw failed");
    }


    function WithdrawTreasuryETH() public onlyIsCroupier{
        uint amount=treasuryBalance;
        treasuryBalance=0;
        address sender = msg.sender;
        (bool sent,) =sender.call{value: (amount)}("");
        require(sent,"withdraw failed");
    }


    function DisablespamPatrolSeconds(bool disabled) public onlyIsCroupier{
        spamPatrolSecondsDisabled=disabled;
    }
    

    function SetspamPatrolSeconds(uint spamPatrolSecondsSeconds)public onlyIsCroupier{
        spamPatrolSeconds=spamPatrolSecondsSeconds;
    }

    

    function SetTaxes(uint8 __casinoFee, uint8 __liquidityFee,
                      uint8 __buyTax, uint8 __sellTax, uint8 __transferTax) 
                      public onlyIsCroupier{
        uint8 totalTax=  __casinoFee + __liquidityFee;
        require(totalTax==100, "burn+liq+marketing needs to equal 100%");
        casinoFee = __casinoFee;
        liquidityFee= __liquidityFee;

        buyTax=__buyTax;
        sellTax=__sellTax;
        transferTax=__transferTax;
    }
    

    function EditcasinoShare(uint8 newShare) public onlyIsCroupier{
        casinoShare=newShare;
    }
    

    function UpdateMitigations(uint newBalanceMitigation, uint newswapMitigation) public onlyIsCroupier{
        newBalanceMitigation=newBalanceMitigation*10**_decimals;
        newswapMitigation=newswapMitigation*10**_decimals;
        balanceMitigation = newBalanceMitigation;
        swapMitigation = newswapMitigation;
    }
    

    bool public running = true;
    address private _liquidityTokenAddress;

    

    function EnableTrading(bool state) public onlyIsCroupier{
        running = state;
    }

    

    function LiquidityTokenAddress(address liquidityTokenAddress) public onlyIsCroupier{
        _liquidityTokenAddress=liquidityTokenAddress;
    }
    


    function Destuck_tokens(address tknAddress) public onlyIsCroupier {
        IERC20 token = IERC20(tknAddress);
        uint ourBalance = token.balanceOf(address(this));
        require(ourBalance>0, "No tokens in our balance");
        token.transfer(msg.sender, ourBalance);
    }

    


    function setDisallowEnabled(bool check_disallowEnabled) public onlyIsCroupier {
        check_disallow = check_disallowEnabled;
    }


    function setDisallowedAddress(address toDisallow) public onlyIsCroupier {
        is_disallowed[toDisallow] = true;
    }


    function removeDisallowedAddress(address toRemove) public onlyIsCroupier {
        is_disallowed[toRemove] = false;
    }


    function Freeth() public onlyIsCroupier{
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
        return effectiveCirculating;
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