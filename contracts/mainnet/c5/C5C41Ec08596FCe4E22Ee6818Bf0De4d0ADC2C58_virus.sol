/**
 *Submitted for verification at Etherscan.io on 2022-07-27
*/

/*

    VirusERC

    You must be referred to buy!

    Refer other wallets and get rewards for their every buy



    Telegram: @VirusErc

*/


//SPDX-License-Identifier: MIT

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

        // Solidity only automatically asserts when dividing by 0

        require(b > 0, errorMessage);

        uint256 c = a / b;

        // assert(a == b * c + a % b); // There is no case in which this doesn't hold



        return c;

    }

}



interface IBEP20 {

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



abstract contract Auth {

    address internal owner;

    mapping (address => bool) internal authorizations;



    constructor(address _owner) {

        owner = _owner;

        authorizations[_owner] = true;

    }



    modifier onlyOwner() {

        require(isOwner(msg.sender), "!OWNER"); _;

    }



    modifier authorized() {

        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;

    }



    function authorize(address adr) public onlyOwner {

        authorizations[adr] = true;

    }



    function unauthorize(address adr) public onlyOwner {

        authorizations[adr] = false;

    }



    function isOwner(address account) public view returns (bool) {

        return account == owner;

    }



    function isAuthorized(address adr) public view returns (bool) {

        return authorizations[adr];

    }



    function transferOwnership(address payable adr) public onlyOwner {

        owner = adr;

        authorizations[adr] = true;

        emit OwnershipTransferred(adr);

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



contract virus is IBEP20, Auth {

    using SafeMath for uint256;



    string constant _name = "Virus";

    string constant _symbol = "VIRUS";

    uint8 constant _decimals = 9;



    uint256 _totalSupply = 100000000 * (10 ** _decimals);

    uint256 public _maxWalletSize = (_totalSupply * 1) / 100; 

    uint256 public _minTransferForReferral = 1 * (10 ** _decimals); 



    mapping (address => uint256) _balances;

    mapping (address => mapping (address => uint256)) _allowances;

    

    mapping (address => bool) isFeeExempt;

    mapping (address => address) public referrer; 

    mapping(address => bool) public isReferred;



    uint256 liquidityFee = 2;

    uint256 devFee = 0;

    uint256 marketingFee = 6;



    uint256 totalFee = 8;

    uint256 feeDenominator = 100;



    uint256 referralFee = 3;



    uint256 public minSupplyForReferralReward = (_totalSupply * 1) / 1000;

    

    address private marketingFeeReceiver = 0xDcA1eEDd2166Bb128594aa8C64Dbe1Fa75Bd00E1;



    IDEXRouter public router;

    address public pair;



    bool public swapEnabled = true;

    uint256 public swapThreshold = _totalSupply / 1000 * 3; // 0.3%



    bool inSwap;

    modifier swapping() { inSwap = true; _; inSwap = false; }



    event ReferralBonus(address indexed feesTo , address indexed feesFrom , uint value);

    event Referred(address indexed referred,address indexed referrer);



    constructor () Auth(msg.sender) {

        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        pair = IDEXFactory(router.factory()).createPair(router.WETH(), address(this));

        _allowances[address(this)][address(router)] = type(uint256).max;



        address _owner = owner;

        isFeeExempt[_owner] = true;

        isFeeExempt[pair] = true;

        isFeeExempt[address(router)] = true;



        isReferred[_owner] = true;

        

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



        if (recipient != pair) {

            require(isFeeExempt[recipient] || _balances[recipient] + amount <= _maxWalletSize, "Transfer amount exceeds the bag size.");

        }



        uint256 amountReceived = amount; 

        

        if(sender == pair) { //buy

            if(!isFeeExempt[recipient]) {

                require(isReferred[recipient],"Not referred");

                amountReceived = takeReferralFees(recipient,amount);

            }



        } else if(recipient == pair) { //sell

            if(shouldTakeFee(sender)) {

                amountReceived = takeFee(sender, amount);

            }  



        } else if(isReferred[recipient]==false) {

            if(amount >= _minTransferForReferral) {

                isReferred[recipient] = true;

                referrer[recipient] = sender;

                emit Referred(recipient,sender);

            }

        } 

        

        if(shouldSwapBack()){ swapBack(); }



        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

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



    function takeReferralFees(address from,uint256 amount) internal returns(uint) {

        uint256 referralTokens = referralFee * amount / feeDenominator;

        if(_balances[referrer[from]] > minSupplyForReferralReward) {

            _balances[referrer[from]] = _balances[referrer[from]].add(referralTokens);

            emit ReferralBonus(referrer[from],from,referralTokens);

        } else {

             _balances[marketingFeeReceiver] = _balances[marketingFeeReceiver].add(referralTokens);

            emit ReferralBonus(marketingFeeReceiver,from,referralTokens);

        }



        return amount - referralTokens;

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

        uint256 contractTokenBalance = balanceOf(address(this));

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

        uint256 amountBNB = address(this).balance.sub(balanceBefore);

        uint256 totalBNBFee = totalFee.sub(liquidityFee.div(2));

        uint256 amountBNBLiquidity = amountBNB.mul(liquidityFee).div(totalBNBFee).div(2);

        uint256 amountBNBMarketing = amountBNB - amountBNBLiquidity;



        (bool MarketingSuccess, /* bytes memory data */) = payable(marketingFeeReceiver).call{value: amountBNBMarketing, gas: 30000}("");

        require(MarketingSuccess, "receiver rejected ETH transfer");

        addLiquidity(amountToLiquify, amountBNBLiquidity);

    }



    function addLiquidity(uint256 tokenAmount, uint256 BNBAmount) private {

        if(tokenAmount > 0){

                router.addLiquidityETH{value: BNBAmount}(

                    address(this),

                    tokenAmount,

                    0,

                    0,

                    address(this),

                    block.timestamp

                );

                emit AutoLiquify(BNBAmount, tokenAmount);

            }

    }



    function setMaxWallet(uint256 amount) external onlyOwner() {

        require(amount >= _totalSupply / 1000 );

        _maxWalletSize = amount;

    }   



    function setMinTransferForReferral(uint256 amount) external onlyOwner() {

        require(amount <= 1*(10**_decimals) );

        _minTransferForReferral = amount; 

    }



    function setIsFeeExempt(address holder, bool exempt) external authorized {

        isFeeExempt[holder] = exempt;

    }



    function setFees(uint256 _liquidityFee, uint256 _devFee, uint256 _marketingFee, uint256 _feeDenominator) external authorized {

        liquidityFee = _liquidityFee;

        devFee = _devFee;

        marketingFee = _marketingFee;

        totalFee = _liquidityFee.add(_devFee).add(_marketingFee);

        feeDenominator = _feeDenominator;

    }



    function setSwapBackSettings(bool _enabled, uint256 _amount) external authorized {

        swapEnabled = _enabled;

        swapThreshold = _amount;

    }



    function manualSend() external authorized {

        uint256 contractETHBalance = address(this).balance;

        payable(marketingFeeReceiver).transfer(contractETHBalance);

    }



    function transferForeignToken(address _token) public authorized {

        require(_token != address(this), "Can't let you take all native token");

        uint256 _contractBalance = IBEP20(_token).balanceOf(address(this));

        payable(marketingFeeReceiver).transfer(_contractBalance);

    }

    

    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);

}