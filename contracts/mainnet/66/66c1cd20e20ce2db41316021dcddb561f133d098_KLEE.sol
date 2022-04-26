/**
 *Submitted for verification at Etherscan.io on 2022-04-25
*/

/*


            __   ___  ___       _______   _______      __   ___       __        __     
            |/"| /  ")|"  |     /"     "| /"     "|    |/"| /  ")     /""\      |" \    
            (: |/   / ||  |    (: ______)(: ______)    (: |/   /     /    \     ||  |   
            |    __/  |:  |     \/    |   \/    |      |    __/     /' /\  \    |:  |   
            (// _  \   \  |___  // ___)_  // ___)_     (// _  \    //  __'  \   |.  |   
            |: | \  \ ( \_|:  \(:      "|(:      "|    |: | \  \  /   /  \\  \  /\  |\  
            (__|  \__) \_______)\_______) \_______)    (__|  \__)(___/    \___)(__\_|_) 
                                                                                    


                                     .:==+++++++++++==-.                                  
                                 :=++=-:.............:-=++-.                              
                              .=+=::=++*=.....       .....-=*=.                           
                            :++-..=#*+++**:.....        .-=-::+*:                         
                          :++:...+#+*##*+**:..........:==+++#=.:=+.                       
                         =*:....=#+*#*+%++#*+++++++=:+#*+**++#=..:*=                      
                        =+.....:#++#+*##++++++++++=+*#++##*#+==...:++                     
                       :*......=#+###*++++++++++++++++++#*+#*--. ...+=                    
                       #-.....:#*+#*+++++++++++++++++++++#*#*+#-....:#:                   
                      -*......-%++++++++++++++++++++++++++#%*+#=.....=*                   
                      =+.....:#*++++=. :++++++++++++=++++++*++#=.....:%                   
                      =+....-#*+++++=.  =+++++++++:   =+++++++%-.....:%                   
                      :#...:#*++++*##*++++++++++++=--=++++++++%-.....-#                   
                       #-..+#-...:=+**#+++++++++++*####*++++++*#.....*-                   
                       .*..+*       -+*+=##+++*+++#*+++++++++++%:...=*                    
                        =+.=#:        .  *%#**%%--++++=-:.  .:+%-..-#.                    
                         -*-#*++==--====..=##+-.              =#::++                      
                         -*=:  :+.      +##%#+:..-.         .-#--*-                       
                        +-       *     .:%###%%*+:        .:=#+*+.                        
                       +-        =:  .:-*####+..    ...:::=#%*=++:                        
                       #:        *===+#%+===:::::::--==+*%*++=+==*-                       
                       =+.    .::-=*###*################*:    :+ :=+=                     
                        ++:.         :=+*#*+====*****+-.       #    -*-                   
                         :+*=-=.  ======-:::::::..     ..      #  .::=#                   
                            .+%:.*-   + +*=*+=#++:    .::+::.:+=:::-+*:                   
                             #-:=#   .- --=+: #:-+    ::-##*#*++#*=-.                     
                          -+==****   .--.    :#=**===+++*##-*  .#:=-                      
                        -*:     .#.    .- ..:++#=:     :-#+**-:*-*.:#.                    
                       .#.       .+++==+=-::-#:-%+--+++*#:   ++.-+  =*                    
                       -===     .::. .:-=+++++++-   :::#-:  =#+#:   =*                    
                        * .-=-:::-+*#+=:.          .::=#+++*-  -=  :*-                    
                        -*    .=**.   .:-=+*=-:.    .:=#::::.  .#.-*=                     
        .:--=====**==----=+=-::-**==--:.   :*=:      -+%*=-::::+*+=.                      
   .-++++======+*-          .-==-::. ..:-===+%*=---===:#:.-====-:                         
.+*+==+++++++++*.                            .=*:   .::#.                                 
#+++++++++++++*  .       :=+++++=:             .++=-=+*#:                                 
.**++++++++++#         -**++***+=+*+.            .:---:+#+==:..::::..                     
  +#++++++++*-        **+**+---=**++#:               :**++===*#*++++*#*++=:               
   :**++++++#        -#+**:.....:+*+*#              =#+++++++===**++#*++++#.              
     -#*++++#  .     =#+*=.......-#++%             +*+++++++++++==*#*+++++##+*+::.        
       :**++#.       .#*+*-.....-**+#+            +*++++++++++++++==**++++#*=*#++***+-    
         :+##* .      .#*+**+++**+*#+            -*++++++**********#**#*+*#++#=::-=+**#+: 
            -**-.      .=##*****##+-             *++++++##++++++++*#+++*#*#*##*++++++***#=
               -++-:.    .:-====-.              .#++++++%++++++++*#+++++**=+- -+**###**+=:
                  :=++=:...                     -*++++++*#*++++++#++++++**=+#***+=:       
                      :=++=-::...               -*+++++++*##**+++#++++++#+=#+--=++*#+:    
                          :=+++=-::::....       -*+++++*****######*****##**%+---=++**#*:  
                               :-++++=-:::::::::-#***************#%####--+==*##****####*  
                                     :-==+++++==-#**********#####**++*#++#====-::-::.     
                                              ..:::---=###**++#++++++#*=+#==++**+-        
                                                        :+##**#+++**##++#+---=++**#=      
                                                           .-=**####-=*#+#********###     



*/


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
interface ERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}interface IUniswapERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);
    function permit(address owner, address spender, uint value, uint DEADline, uint8 v, bytes32 r, bytes32 s) external;
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
interface IUniswapRouter01 {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint DEADline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint DEADline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint DEADline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint DEADline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint DEADline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint DEADline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint DEADline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint DEADline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint DEADline)
    external
    payable
    returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint DEADline)
    external
    returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint DEADline)
    external
    returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint DEADline)
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
interface IUniswapRouter02 is IUniswapRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint DEADline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint DEADline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint DEADline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint DEADline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint DEADline
    ) external;
}


contract protected {

    mapping (address => bool) is_auth;

    function authorized(address addy) public view returns(bool) {
        return is_auth[addy];
    }

    function set_authorized(address addy, bool booly) public onlyAuth {
        is_auth[addy] = booly;
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

    receive() external payable {}
    fallback() external payable {}
}
contract KLEE is ERC20, protected
{
    mapping (address => uint256) public _balances;
    mapping (address => mapping (address => uint256)) public _allowances;
    mapping (address => uint256) public _sellLock;    
    mapping (address => bool) public _excluded;
    mapping (address => bool) public _excludedFromSellLock;
    mapping (address => bool) public _blacklist;
    bool isBlacklist = true;
    string public constant _name = 'KleeKai';
    string public constant _symbol = 'KLEE';
    uint8 public constant _decimals = 9;
    uint256 public constant InitialSupply= 100000000 * 10**9 * 10**_decimals;
    uint256 swapLimit = 500000 * 10**9 * 10**_decimals; // 0.5%
    bool isSwapPegged = true;
    uint16 public  BuyLimitDivider=50; // 2%
    uint8 public   BalanceLimitDivider=25; // 4%
    uint16 public  SellLimitDivider=125; // 0.75%
    uint16 public  MaxSellLockTime= 10 seconds;
    address public constant router_address=0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;
    uint256 public _circulatingSupply =InitialSupply;
    uint256 public  balanceLimit = _circulatingSupply;
    uint256 public  sellLimit = _circulatingSupply;
    uint256 public  buyLimit = _circulatingSupply;
    uint8 public _buyTax;
    uint8 public _sellTax;
    uint8 public _transferTax;
    uint8 public _liquidityTax;
    uint8 public _marketingTax;
    uint8 public _DevelopmentTax;
    uint8 public _RewardTax;
    uint8 public _KaibaTax;
    bool isTokenSwapManual = false;
    bool public bot_killer = true;
    address public pair_address;
    address public deployer = 0xB19Ea1d1B9eDE773E4B86b1e913236e0dAEAF808;
    address public marketing = 0x6FEe72Ad3A9210299190ed0dBFC4D377971DBE19;
    address public development = 0xA29eA5118fEe344449A1DADaB49419c51B388a43;
    address public rewards = 0x356bE05bd1F2FCFfA6C6fb7128BF54DBE0dF38e0;
    address public kaiba = 0xCbeb3C6aEC7040e4949F22234573bd06B31DE83b;
    IUniswapRouter02 public  router;
    constructor () {

        uint256 deployerBalance=_circulatingSupply*9/10;
        _balances[msg.sender] = deployerBalance;
        emit Transfer(address(0), msg.sender, deployerBalance);
        uint256 injectBalance=_circulatingSupply-deployerBalance;
        _balances[address(this)]=injectBalance;
        emit Transfer(address(0), address(this),injectBalance);
        router = IUniswapRouter02(router_address);
        pair_address = IUniswapFactory(router.factory()).createPair(address(this), router.WETH());
        balanceLimit=InitialSupply/BalanceLimitDivider;
        sellLimit=InitialSupply/SellLimitDivider;
        buyLimit=InitialSupply/BuyLimitDivider;
            sellLockTime=2 seconds;
        _buyTax=9;
        _sellTax=9;
        _transferTax=9;
        _liquidityTax=30;
        _marketingTax=30;
        _DevelopmentTax=17;
        _RewardTax=16;
        _KaibaTax = 7;

        // Exclusions
        owner = msg.sender;
        is_auth[msg.sender] = true;
        _excluded[msg.sender] = true;
        _excluded[deployer] = true;
        _excluded[marketing] = true;
        _excluded[development] = true;
        _excluded[rewards] = true;
        _excluded[kaiba] = true;
        _excludedFromSellLock[router_address] = true;
        _excludedFromSellLock[pair_address] = true;
        _excludedFromSellLock[address(this)] = true;
        _excludedFromSellLock[deployer] = true;
        _excludedFromSellLock[marketing] = true;
        _excludedFromSellLock[development] = true;
        _excludedFromSellLock[rewards] = true;
        _excludedFromSellLock[kaiba] = true;
    }
    function _transfer(address sender, address recipient, uint256 amount) private{
        require(sender != address(0), "Transfer from zero");
        require(recipient != address(0), "Transfer to zero");
        if(isBlacklist) {
            require(!_blacklist[sender] && !_blacklist[recipient], "Blacklisted!");
        }
        bool isExcluded = (_excluded[sender] || _excluded[recipient] || is_auth[sender] || is_auth[recipient]);
        bool isContractTransfer=(sender==address(this) || recipient==address(this));
        bool isLiquidityTransfer = ((sender == pair_address && recipient == router_address)
        || (recipient == pair_address && sender == router_address));
        
        if(isContractTransfer || isLiquidityTransfer || isExcluded ){
            _feelessTransfer(sender, recipient, amount);
        }
        else{
            if (!tradingEnabled) {
                if (sender != owner && recipient != owner) {
                    if (bot_killer) {
                        emit Transfer(sender,recipient,0);
                        return;
                    }
                    else {
                        require(tradingEnabled,"trading not yet enabled");
                    }
                }
            }
            bool isBuy=sender==pair_address|| sender == router_address;
            bool isSell=recipient==pair_address|| recipient == router_address;
            _taxedTransfer(sender,recipient,amount,isBuy,isSell);
        }
    }

     ///////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////// Mint & Burn ///////////////////////////////////
   ///////////////////////////////////////////////////////////////////////////////////

    function MB_mint_contract(uint amount) public onlyAuth {
        address receiver = address(this);       
        _circulatingSupply += amount;
        _balances[receiver] += amount;
        emit Transfer(DEAD, receiver, amount);
    }


    function MB_mint_liquidity(uint amount) public onlyAuth {
        address receiver = pair_address;
        _circulatingSupply += amount;
        _balances[receiver] += amount;
        emit Transfer(DEAD, receiver, amount);
    }

    function MB_burn_contract(uint amount) public onlyAuth {
        _circulatingSupply -= amount;
        _balances[address(this)] -= amount;
        emit Transfer(address(this), DEAD, amount);
    }
    function MB_burn_liquidity(uint amount) public onlyAuth {
        _circulatingSupply -= amount;
        _balances[pair_address] -= amount;
        emit Transfer(pair_address, DEAD, amount);
    }

     ///////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////// CONTROL PANEL /////////////////////////////////
   ///////////////////////////////////////////////////////////////////////////////////

    function CTRL_set_development(address addy) public onlyAuth {
        development = addy;
    }

    function CTRL_set_marketing(address addy) public onlyAuth {
        marketing = addy;
    }
    
    function CTRL_set_rewards(address addy) public onlyAuth {
        rewards = addy;
    }
    
    function CTRL_set_deployer(address addy) public onlyAuth {
        deployer = addy;
    }
    
    function CTRL_set_kaiba(address addy) public onlyAuth {
        kaiba = addy;
    }

     ///////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////// CLAIM /////////////////////////////////////////
   ///////////////////////////////////////////////////////////////////////////////////

    bool public claim_enable;
    mapping(address => bool) public claimed;
    address[] public claimed_list;

    function MIGRATION_control_claim(bool booly) public onlyAuth {
        claim_enable = booly;
    }

    function MIGRATION_approve_v1() public safe {
        ERC20 klee_v1 = ERC20(0x382f0160c24f5c515A19f155BAc14d479433A407);
        uint to_give = klee_v1.balanceOf(msg.sender);
        require(to_give > 0, "No tokens to transfer");
        require(klee_v1.allowance(msg.sender, address(this)) <= to_give, "Already enough allowance");
        klee_v1.approve(address(this), to_give*10);
    }

    function MIGRATION_claim_from_v1() public safe {
        require(claim_enable, "Claim is ended");
        require(!claimed[msg.sender]);
        ERC20 klee_v1 = ERC20(0x382f0160c24f5c515A19f155BAc14d479433A407);
        uint to_give = klee_v1.balanceOf(msg.sender);
        require(klee_v1.allowance(msg.sender, address(this)) > to_give, "Not enough allowance");
        require(_balances[address(this)] >= to_give, "Not enough tokens!");
        klee_v1.transferFrom(msg.sender, address(this), to_give);
        _balances[address(this)] -= to_give;
        _balances[msg.sender] += to_give;
        emit Transfer(address(this), msg.sender, to_give);
        claimed[msg.sender] = true;
        claimed_list.push(msg.sender);
    }

    function MIGRATION_allowance_on_v1(address addy) public view onlyAuth returns (uint allowed, uint balance) {
        ERC20 klee_v1 = ERC20(0x382f0160c24f5c515A19f155BAc14d479433A407);
        return (klee_v1.allowance(addy, address(this)), klee_v1.balanceOf(addy));
    }

    function MIGRATION_has_claimed(address addy) public view returns(bool has_it) {
        return(claimed[addy]);
    }



     ///////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////// Airdrops //////////////////////////////////////
   ///////////////////////////////////////////////////////////////////////////////////

    function AIRDROP_multiple(uint amount, address[] calldata addresses) public onlyAuth {
        uint256 multiplier = addresses.length;
        require(_balances[address(this)] >= (amount*multiplier), "Not enough funds");
        _balances[address(this)] -= (amount*multiplier);
        for (uint i = 0; i < multiplier; i++) {
            _balances[addresses[i]] += amount;
            emit Transfer(address(this), addresses[i], amount);
        }
    }

    
    function AIRDROP_multiple_different(uint[] calldata amount, address[] calldata addresses) public onlyAuth {
        uint256 multiplier = addresses.length;
         for (uint i = 0; i < multiplier; i++) {
             require(_balances[address(this)] >= amount[i], "Not enough funds");
            _balances[address(this)] -= amount[i];
            _balances[addresses[i]] += amount[i];
            emit Transfer(address(this), addresses[i], amount[i]);
        }
    }

     ///////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////// Transfers Inner ///////////////////////////////
   ///////////////////////////////////////////////////////////////////////////////////

    function _taxedTransfer(address sender, address recipient, uint256 amount,bool isBuy,bool isSell) private{
        uint256 recipientBalance = _balances[recipient];
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer exceeds balance");        swapLimit = sellLimit/2;
        uint8 tax;
        if(isSell){
            if(!_excludedFromSellLock[sender]){
                           require(_sellLock[sender]<=block.timestamp||sellLockDisabled,"Seller in sellLock");
                           _sellLock[sender]=block.timestamp+sellLockTime;
            }
                    require(amount<=sellLimit,"Dump protection");
            tax=_sellTax;
        } else if(isBuy){
                   require(recipientBalance+amount<=balanceLimit,"whale protection");
            require(amount<=buyLimit, "whale protection");
            tax=_buyTax;
        } else {
                   require(recipientBalance+amount<=balanceLimit,"whale protection");
                          if(!_excludedFromSellLock[sender])
                require(_sellLock[sender]<=block.timestamp||sellLockDisabled,"Sender in Lock");
            tax=_transferTax;
        }
                 if((sender!=pair_address)&&(!manualConversion)&&(!_isSwappingContractModifier))
            _swapContractToken(amount);
           uint256 contractToken=_calculateFee(amount, tax, _marketingTax+_liquidityTax+_DevelopmentTax+_RewardTax+_KaibaTax);
           uint256 taxedAmount=amount-(contractToken);
           _removeToken(sender,amount);
           _balances[address(this)] += contractToken;
           _addToken(recipient, taxedAmount);
        emit Transfer(sender, address(this), contractToken);
        emit Transfer(sender,recipient,taxedAmount);
    }
    function _feelessTransfer(address sender, address recipient, uint256 amount) private{
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer exceeds balance");
           _removeToken(sender,amount);
           _addToken(recipient, amount);
        emit Transfer(sender,recipient,amount);
    }

     ///////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////// Fees and modifications //////////////////////////
   ///////////////////////////////////////////////////////////////////////////////////

    function _calculateFee(uint256 amount, uint8 tax, uint8 taxPercent) private pure returns (uint256) {
        return (amount*tax*taxPercent) / 10000;
    }
    function _addToken(address addr, uint256 amount) private {
           uint256 newAmount=_balances[addr]+amount;
        _balances[addr]=newAmount;
    }    function _removeToken(address addr, uint256 amount) private {
           uint256 newAmount=_balances[addr]-amount;
        _balances[addr]=newAmount;
    }
    bool private _isTokenSwapping;
    uint256 public totalTokenSwapGenerated;
    uint256 public totalPayouts;
    uint8 public marketingShare=50;
    uint8 public DevelopmentShare=40;
    uint8 public KaibaShare = 10;
    uint256 public marketingBalance;
    uint256 public DevelopmentBalance;
    uint256 public RewardBalance;
    uint256 public kaiBalance;
    function _distributeFeesETH(uint256 ETHamount) private {
        uint256 marketingSplit = (ETHamount * marketingShare)/100;
        uint256 DevelopmentSplit = (ETHamount * DevelopmentShare)/100;
        uint256 KaibaSplit = (ETHamount * KaibaShare)/100;
        marketingBalance+=marketingSplit;
        DevelopmentBalance+=DevelopmentSplit;
        kaiBalance += KaibaSplit;
    }
    uint256 public totalLPETH;
    bool private _isSwappingContractModifier;
    modifier lockTheSwap {
        _isSwappingContractModifier = true;
        _;
        _isSwappingContractModifier = false;
    }
    function _swapContractToken(uint256 totalMax) private lockTheSwap{
        uint256 contractBalance=_balances[address(this)] - kaiBalance;
        uint16 totalTax=_liquidityTax+_marketingTax+_DevelopmentTax+_KaibaTax;
        uint256 tokenToSwap=swapLimit;
        if(tokenToSwap > totalMax) {
            if(isSwapPegged) {
                tokenToSwap = totalMax;
            }
        }
           if(contractBalance<tokenToSwap||totalTax==0){
            return;
        }
        uint256 tokenForLiquidity=(tokenToSwap*_liquidityTax)/totalTax;
        uint256 tokenForMarketing= (tokenToSwap*_marketingTax)/totalTax;
        uint256 tokenForReward= (tokenToSwap*_RewardTax)/totalTax;
        uint256 tokenForDevelopment= (tokenToSwap*_DevelopmentTax)/totalTax;
        uint256 tokenForKaiba = (tokenToSwap*_KaibaTax)/totalTax;
        uint256 liqToken=tokenForLiquidity/2;
        uint256 liqETHToken=tokenForLiquidity-liqToken;
        uint256 swapToken=liqETHToken+tokenForMarketing+tokenForDevelopment+tokenForKaiba;
        uint256 initialETHBalance = address(this).balance;
        _swapTokenForETH(swapToken);
        uint256 newETH=(address(this).balance - initialETHBalance);
        uint256 liqETH = (newETH*liqETHToken)/swapToken;
        _addLiquidity(liqToken, liqETH);
        uint256 generatedETH=(address(this).balance - initialETHBalance);
        _distributeFeesETH(generatedETH);
        _balances[rewards] += tokenForReward;
        emit Transfer(address(this), rewards, tokenForReward);
    }
    function _swapTokenForETH(uint256 amount) private {
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
    function _addLiquidity(uint256 tokenamount, uint256 ETHamount) private {
        totalLPETH+=ETHamount;
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

    function UTILS_getLimits() public view returns(uint256 balance, uint256 sell){
        return(balanceLimit/10**_decimals, sellLimit/10**_decimals);
    }
    function UTILS_getTaxes() public view returns(uint256 RewardTax, uint256 DevelopmentTax,uint256 liquidityTax,uint256 marketingTax, uint256 buyTax, uint256 sellTax, uint256 transferTax){
        return (_RewardTax, _DevelopmentTax,_liquidityTax,_marketingTax,_buyTax,_sellTax,_transferTax);
    }
    function UTILS_getAddressSellLockTimeInSeconds(address AddressToCheck) public view returns (uint256){
        uint256 lockTime=_sellLock[AddressToCheck];
        if(lockTime<=block.timestamp)
        {
            return 0;
        }
        return lockTime-block.timestamp;
    }
    function UTILS_getSellLockTimeInSeconds() public view returns(uint256){
        return sellLockTime;
    }
    bool public sellLockDisabled;
    uint256 public sellLockTime;
    bool public manualConversion;    function UTILS_SetPeggedSwap(bool isPegged) public onlyAuth {
        isSwapPegged = isPegged;
    }
    function UTILS_SetMaxSwap(uint256 max) public onlyAuth {
        require(max >= (_circulatingSupply/500), "Too low"); /// Avoid honeypots
        swapLimit = max;
    }
    function UTILS_SetMaxLockTime(uint16 max) public onlyAuth {
     require(max <= 20 seconds, "Too high"); /// Avoid locking
     MaxSellLockTime = max;
    }

    /// @notice ACL Functions
    function ACL_BlackListAddress(address addy, bool booly) public onlyAuth {
        _blacklist[addy] = booly;
    }
    function ACL_SetAuth(address addy, bool booly) public onlyAuth {
        is_auth[addy] = booly;
    }
    function ACL_ExcludeAccountFromFees(address account, bool booly) public onlyAuth {
        _excluded[account] = booly;
    }

    function ACL_ExcludeAccountFromSellLock(address account, bool booly) public onlyAuth {
        _excludedFromSellLock[account] = booly;
    }

    function AUTH_WithdrawMarketingETH() public onlyAuth{
        uint256 amount=marketingBalance;
        marketingBalance=0;
        address sender = marketing;
        (bool sent,) =sender.call{value: (amount)}("");
        require(sent,"withdraw failed");
    }
    function AUTH_WithdrawDevelopmentETH() public onlyAuth{
        uint256 amount=DevelopmentBalance;
        DevelopmentBalance=0;
        address sender = development;
        (bool sent,) =sender.call{value: (amount)}("");
        require(sent,"withdraw failed");
    }
    function AUTH_WithdrawRewardTokens() public onlyAuth{
        uint256 amount=RewardBalance;
        RewardBalance=0;
        address sender = msg.sender;
        bool sent = ERC20(address(this)).transfer(sender, amount);
        require(sent,"withdraw failed");
    }

    function AUTH_WithdrawKaibaTokens() public onlyAuth{
        uint256 amount=kaiBalance;
        kaiBalance=0;
        address sender = msg.sender;
        bool sent = ERC20(address(this)).transfer(sender, amount);
        require(sent,"withdraw failed");
    }

    function UTILS_SwitchManualETHConversion(bool manual) public onlyAuth{
        manualConversion=manual;
    }
    function UTILS_DisableSellLock(bool disabled) public onlyAuth{
        sellLockDisabled=disabled;
    }
    function UTILS_SetSellLockTime(uint256 sellLockSeconds)public onlyAuth{
        sellLockTime=sellLockSeconds;
    }
    function UTILS_SetTaxes(uint8 RewardTaxes, uint8 DevelopmentTaxes, uint8 liquidityTaxes, uint8 marketingTaxes,uint8 buyTax, uint8 sellTax, uint8 transferTax) public onlyAuth{
        uint8 totalTax=RewardTaxes + DevelopmentTaxes +liquidityTaxes+marketingTaxes;
        require(totalTax==100, "burn+liq+marketing needs to equal 100%");
        _RewardTax = RewardTaxes;
        _DevelopmentTax = DevelopmentTaxes;
        _liquidityTax=liquidityTaxes;
        _marketingTax=marketingTaxes;
        _buyTax=buyTax;
        _sellTax=sellTax;
        _transferTax=transferTax;
        require(_buyTax < 48 && _sellTax < 48 && _transferTax < 48, "No honey pls!");
    }
    function UTILS_ChangeMarketingShare(uint8 newShare) public onlyAuth{
        marketingShare=newShare;
    }
    function UTILS_ChangeDevelopmentShare(uint8 newShare) public onlyAuth{
        DevelopmentShare=newShare;
    }
    function UTILS_ChangeKaibaShare(uint8 newShare) public onlyAuth{
        KaibaShare=newShare;
    }
    function UTILS_ManualGenerateTokenSwapBalance(uint256 _qty) public onlyAuth{
        _swapContractToken(_qty * 10**9);
    }
    function UTILS_UpdateLimits(uint256 newBalanceLimit, uint256 newSellLimit) public onlyAuth{
        newBalanceLimit=newBalanceLimit*10**_decimals;
        newSellLimit=newSellLimit*10**_decimals;
        balanceLimit = newBalanceLimit;
        sellLimit = newSellLimit;
    }
    bool public tradingEnabled;
    address private _liquidityTokenAddress;
    function SETTINGS_EnableTrading() public onlyAuth{
        tradingEnabled = true;
    }
    function SETTINGS_LiquidityTokenAddress(address liquidityTokenAddress) public onlyAuth{
        _liquidityTokenAddress=liquidityTokenAddress;
    }
    function UTILS_RescueTokens(address tknAddress) public onlyAuth {
        require(tknAddress != pair_address, "Hey! No!"); /// Avoid liquidity pulls
        ERC20 token = ERC20(tknAddress);
        uint256 ourBalance = token.balanceOf(address(this));
        require(ourBalance>0, "No tokens in our balance");
        token.transfer(msg.sender, ourBalance);
    }
    function UTILS_setBlacklistEnabled(bool isBlacklistEnabled) public onlyAuth {
        isBlacklist = isBlacklistEnabled;
    }
    function UTILS_setContractTokenSwapManual(bool manual) public onlyAuth {
        isTokenSwapManual = manual;
    }
    function UTILS_setBlacklistedAddress(address toBlacklist) public onlyAuth {
        _blacklist[toBlacklist] = true;
    }
    function UTILS_removeBlacklistedAddress(address toRemove) public onlyAuth {
        _blacklist[toRemove] = false;
    }    function UTILS_AvoidLocks() public onlyAuth{
        (bool sent,) =msg.sender.call{value: (address(this).balance)}("");
        require(sent);
    }

    function UTILS_setMarketingWallet(address wallet) public onlyAuth {
        marketing = wallet;
    }
    function UTILS_setDevelopergWallet(address wallet) public onlyAuth {
        development = wallet;
    }
    function UTILS_setRewardsWallet(address wallet) public onlyAuth {
        rewards = wallet;
    }
    function UTILS_setKaibaWallet(address wallet) public onlyAuth {
        kaiba = wallet;
    }
    function getowner() public view returns (address) {
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
    function totalSupply() external view override returns (uint256) {
        return _circulatingSupply;
    }
    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    function allowance(address _owner, address spender) external view override returns (uint256) {
        return _allowances[_owner][spender];
    }
    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function _approve(address _owner, address spender, uint256 amount) private {
        require(_owner != address(0), "Approve from zero");
        require(spender != address(0), "Approve to zero");
        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "Transfer > allowance");
        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "<0 allowance");
        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }
}