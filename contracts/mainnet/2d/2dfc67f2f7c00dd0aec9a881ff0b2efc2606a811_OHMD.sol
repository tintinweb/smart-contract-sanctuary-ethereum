/**
 *Submitted for verification at Etherscan.io on 2023-01-13
*/

/*



                                                                                                    
                                    .:^~~!~~^::.                                                    
                                :~?Y5555555555YYJ?!^.       .^!7?JJYYYYJ?!^.                        
                             .!J5P55YYYYYYYYYYYYYY55YJ~.:!?Y555YYYYYYYYYY55Y?:                      
                           .75P55YYYYYYYYYYYYYYYYYYYYY55G5YYYYYYYYYYYYYYYYYY5P!                     
                         .75P5YYYYYYYYYYYY5555555YYYYYYY5GYYYYYYYYYYYYYYYYYYYYP!                    
                        ^5P55YYYYYYY5555555YYYYY555555YYJ5PYYYYYYYYYYYYYYYYYYYYP^                   
                       7P555YYYYY555YYYYYYYYYYYYYYYYYY5555G55555555555555555555P5~^.                
                      JP555YYYYYYYYYYYYYYYYYYYYYYYYYYYYYY5PP5YYYYYYYYYYYYYYYYYYYYY5YY?~             
                   .:YP5YYYYYYYYYYYYYYYYYYYYYY55555555555555PP5YYYYYYYYY55555555555555P5^           
                !YGB####BGP5YJYYYYYYYYYYY55555PPP555555555P5555PP555555555555555555PPP5PPY?: .      
               ?&#GGG55PPG###G5YYYYYY555555P5YJJJJYYY?!^^~7?J55PPPGGGP555J?5Y5GGP5J7JYPPPB#BPGP.    
              ^5G5YPPYYYYYY5PB##GP55555PPP5?!~Y#5?B&&#BYY55PGB#B####B####GG#PG####BGGBB#######&!    
            .JP5Y5YPGY5YYYYYYYYP######BBBBBBBB#B##BBB############&P~:B#GGB#B##################&!    
           :5PY555Y555YYYYYYYYYY55P#BBB#########################&B:  Y&#####################&&G.    
          :P5Y5555555YYYYYYYYYYYYYJ5############################B5^:::J#&#################&&#Y.     
          YPY5555555YYYYYYYYYYYYYYYYP#&&#####################&#P5P5YYYJ5GB##&&&&&######&&#P?:       
         !GY5555555YYYYYYYYYYYYYYYYYYYPB###&&&&&&&&&&&&&####BGP55YYYYYYYYYY5PGGGBBBBBB#P7:          
         55Y555555YYYYYYYYYYYYYYYYYYYYYYY5PPGGGBBBGGGGGPPPPPYJYYYYYYYYYYYYYJJJJYYYY55J~             
        ^G55555555YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY5555YYYYYYYYYYY5555P55555555PP?:               
        7P5555555YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY55555YYYYYYYYYYYYYYYYYYY5P5YYYYYYYY5Y~              
        YPY555555YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY5J.            
        55Y555555YYYYYYYYYYYYYYY5PPPPPP5YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY5Y            
      .5#GP5Y5555YYYYYYYYYYYYYYPG555555PPPP5YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYJP!           
      !&###BG5YY5YYYYYYYYYYYYYYG5555GP55555PPP55YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYP5^          
      ?#######GP5YYYYYYYYYYYYYY5G5555PGGPP5555PPPPPPP55555YYYYYYYYYYYYYYYYYYYYYYY55PPPPPPG:         
      Y#########BP5YJYYYYYYYYYYYYPPP5555PPPPPPPPP555555PPPPPPPPPPPPPPPPPPPPPPPPPPPP5555PP?.         
     .B############BP5YYYYYYYYYYYYY5PPPP555555PPPPPPPPPPPPPPPPPP5555555555555PPPPPPPPGY!:           
     7#################BGP55YYYYYYYYYYY55PPPPPPP555555555PPPPPPPPPPPPPPPPPPPPPPPPPPP5GY             
     P######################BBGPP5YYYJJJJYYYYY5555PPPPPPPPPPPP555555555555555555PPPPPY^             
    ^##############################BBGPP55YYYJJJJJYYYYYYYY555555555555PPPPP555PP?!!~:               
    7######################################BBGPP55YYYYYYYYYYYYYYYYYYYYYJJJYYPGBJ~:                  
    J&#############################################BB5YYYYYYYYYYYYYYYYY5PGB#######G5J!^.            
    7&##############################################GYYYYYYYYYYY55PGGB#############&&&#BG57         
    :##############################################B555PPPPPPPPPB#####################&#GJ!         
     7############################################P55555555Y55PBBBBB################&B?^            
      ~P#########################################BPPPPPPPPPGBBBBBBBBBBB#############Y:              
        ~JG######################################BBBBBBBBBBBBBBBBBBBBBBBB########&B!                
          .^75G#################################BBBBBBBBBBBBBBBBBBBBBBBB##&&&&&&#P^                 
              .^!JPB###########################BBBBBBBBBBBBBBBBBBB####BGPJ7?JJJ?~                   
                   .^7J5G####################################BBBGP5Y?!^:                            
                        .:~7J5PGB############5JJJJJ????777!!~^^:..                                  
                               .:^~!7?JYY555J. 


*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

interface ERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {
        owner = _owner;
    }
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }
    function renounceOwnership() public onlyOwner {
        owner = address(0);
        emit OwnershipTransferred(address(0));
    }  
    event OwnershipTransferred(address owner);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
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

contract OHMD is ERC20, Ownable {
    using SafeMath for uint256;
    address routerAdress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address DEAD = 0x000000000000000000000000000000000000dEaD;

    string constant _name = "One Hundred Million Degens";
    string constant _symbol = "OHMD";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 100000000 * (10 ** _decimals);
    uint256 public _maxWalletAmount = (_totalSupply * 20) / 1000;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;

    uint256 liquidityFee = 0; 
    uint256 marketingFee = 7;
    uint256 totalFee = liquidityFee + marketingFee;
    uint256 feeDenominator = 100;

    address internal marketingFeeReceiver = 0x35F76B0568F96e2E7e407eDF9a8bB3fDE5d60607;

    IDEXRouter public router;
    address public pair;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 1000 * 5; // 0.5%
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () Ownable(msg.sender) {
        router = IDEXRouter(routerAdress);
        pair = IDEXFactory(router.factory()).createPair(router.WETH(), address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;

        address _owner = owner;
        isFeeExempt[0x35F76B0568F96e2E7e407eDF9a8bB3fDE5d60607] = true;
        isTxLimitExempt[_owner] = true;
        isTxLimitExempt[0x35F76B0568F96e2E7e407eDF9a8bB3fDE5d60607] = true;
        isTxLimitExempt[DEAD] = true;

        _balances[_owner] = _totalSupply;
        emit Transfer(address(0), _owner, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
        
        if (recipient != pair && recipient != DEAD) {
            require(isTxLimitExempt[recipient] || _balances[recipient] + amount <= _maxWalletAmount, "Transfer amount exceeds the bag size.");
        }
        
        if(shouldSwapBack()){ swapBack(); } 

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(sender, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function takeFee(address sender, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(totalFee).div(feeDenominator);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        return amount.sub(feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
        uint256 contractTokenBalance = swapThreshold;
        uint256 amountToLiquify = contractTokenBalance.mul(liquidityFee).div(totalFee).div(2);
        uint256 amountToSwap = contractTokenBalance.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 amountETH = address(this).balance.sub(balanceBefore);
        uint256 totalETHFee = totalFee.sub(liquidityFee.div(2));
        uint256 amountETHLiquidity = amountETH.mul(liquidityFee).div(totalETHFee).div(2);
        uint256 amountETHMarketing = amountETH.mul(marketingFee).div(totalETHFee);


        (bool MarketingSuccess, /* bytes memory data */) = payable(marketingFeeReceiver).call{value: amountETHMarketing, gas: 30000}("");
        require(MarketingSuccess, "receiver rejected ETH transfer");

        if(amountToLiquify > 0){
            router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
               0x35F76B0568F96e2E7e407eDF9a8bB3fDE5d60607,
                block.timestamp
            );
            emit AutoLiquify(amountETHLiquidity, amountToLiquify);
        }
    }

    function buyTokens(uint256 amount, address to) internal swapping {
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(this);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            to,
            block.timestamp
        );
    }

    function clearStuckBalance() external {
        payable(marketingFeeReceiver).transfer(address(this).balance);
    }

    function setWalletLimit(uint256 amountPercent) external onlyOwner {
        _maxWalletAmount = (_totalSupply * amountPercent ) / 1000;
    }

    function setFee(uint256 _liquidityFee, uint256 _marketingFee) external onlyOwner {
         liquidityFee = _liquidityFee; 
         marketingFee = _marketingFee;
         totalFee = liquidityFee + marketingFee;
    }    
    
    event AutoLiquify(uint256 amountETH, uint256 amountBOG);
}