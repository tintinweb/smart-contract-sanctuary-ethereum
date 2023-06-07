/**
 *Submitted for verification at Etherscan.io on 2023-06-07
*/

/**
 *  Created By: Fatsale
 *  Website: https://fatsale.finance
 *  Telegram: https://t.me/fatsale
 *  The Best Tool for Token Presale
 **/


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    //   constructor () internal { }

    function _msgSender() internal view returns (address) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(
            _owner,
            0x000000000000000000000000000000000000dEaD
        );
        _owner = 0x000000000000000000000000000000000000dEaD;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
}

interface IUniFactory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IPancakeRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

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
}

interface ISwapRouter is IPancakeRouter01 {

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface ISwapFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}


contract BaseFatToken is IERC20, Ownable {
    bool public currencyIsEth;

    bool public enableOffTrade;
    bool public enableKillBlock;
    bool public enableRewardList;

    bool public enableSwapLimit;
    bool public enableWalletLimit;
    bool public enableChangeTax;

    address public currency;
    address public fundAddress;

    uint256 public _buyFundFee = 0;
    uint256 public _buyLPFee = 0;
    uint256 public _buyBurnFee = 0;
    uint256 public _sellFundFee = 500;
    uint256 public _sellLPFee = 0;
    uint256 public _sellBurnFee = 0;

    uint256 public kb = 0;

    uint256 public maxBuyAmount;
    uint256 public maxSellAmount;
    
    uint256 public maxWalletAmount;
    uint256 public startTradeBlock;

    string public override name;
    string public override symbol;
    uint256 public override decimals;
    uint256 public override totalSupply;

    uint256 public totalInvitorFee;

    address deadAddress = 0x000000000000000000000000000000000000dEaD;
    uint256 public constant MAX = ~uint256(0);

    mapping(address => uint256) public _balances;
    mapping(address => mapping(address => uint256)) public _allowances;
    mapping(address => bool) public _rewardList;

    ISwapRouter public _swapRouter;
    mapping(address => bool) public _swapPairList;

    mapping(address => bool) public _feeWhiteList;
    address public _mainPair;

    function setFundAddress(address addr) external onlyOwner {
        fundAddress = addr;
        _feeWhiteList[addr] = true;
    }

    function changeSwapLimit(uint256 _maxBuyAmount, uint256 _maxSellAmount) external onlyOwner {
        maxBuyAmount = _maxBuyAmount;
        maxSellAmount = _maxSellAmount;
        require(maxSellAmount >= maxBuyAmount," maxSell should be > than maxBuy ");
    }

    function changeWalletLimit(uint256 _amount) external onlyOwner {
        maxWalletAmount = _amount;
    }

    function launch() external onlyOwner {
        require(startTradeBlock == 0, "already started");
        startTradeBlock = block.number;
    }

    function disableSwapLimit() public onlyOwner {
        enableSwapLimit = false;
    }

    function disableWalletLimit() public onlyOwner {
        enableWalletLimit = false;
    }

    function disableChangeTax() public onlyOwner {
        enableChangeTax = false;
    }

    function setCurrency(address _currency, address _router) public onlyOwner {
        currency = _currency;
        if (_currency == _swapRouter.WETH()) {
            currencyIsEth = true;
        } else {
            currencyIsEth = false;
        }

        ISwapRouter swapRouter = ISwapRouter(_router);
        IERC20(currency).approve(address(swapRouter), MAX);
        _swapRouter = swapRouter;
        _allowances[address(this)][address(swapRouter)] = MAX;
        ISwapFactory swapFactory = ISwapFactory(swapRouter.factory());
        address swapPair = swapFactory.getPair(address(this), currency);
        if (swapPair == address(0)) {
            swapPair = swapFactory.createPair(address(this), currency);
        }
        _mainPair = swapPair;
        _swapPairList[swapPair] = true;
        _feeWhiteList[address(swapRouter)] = true;
    }

    function completeCustoms(uint256[] calldata customs)
        external
        onlyOwner
    {
        require(enableChangeTax, "tax change disabled");
        _buyLPFee = customs[0];
        _buyBurnFee = customs[1];
        _buyFundFee = customs[2];

        _sellLPFee = customs[3];
        _sellBurnFee = customs[4];
        _sellFundFee = customs[5];

        require(_buyBurnFee + _buyLPFee + _buyFundFee + totalInvitorFee< 2500, "fee too high");
        require(
            _sellBurnFee + _sellLPFee + _sellFundFee + totalInvitorFee< 2500,
            "fee too high"
        );
    }

    function transfer(address recipient, uint256 amount)
        external
        virtual
        override
        returns (bool)
    {}

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual override returns (bool) {}

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function setFeeWhiteList(address[] calldata addr, bool enable)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < addr.length; i++) {
            _feeWhiteList[addr[i]] = enable;
        }
    }

    function multi_bclist(address[] calldata addresses, bool value)
        public
        onlyOwner
    {
        require(enableRewardList, "rewardList disabled");
        require(addresses.length < 201);
        for (uint256 i; i < addresses.length; ++i) {
            _rewardList[addresses[i]] = value;
        }
    }
}

contract TokenDistributor {
    constructor(address token) {
        IERC20(token).approve(msg.sender, uint256(~uint256(0)));
    }
}

contract FatToken is BaseFatToken {
    bool private inSwap;

    TokenDistributor public _tokenDistributor;

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(
        string[] memory stringParams,
        address[] memory addressParams,
        uint256[] memory numberParams,
        bool[] memory boolParams
    ) { 
        name = stringParams[0];
        symbol = stringParams[1];
        decimals = numberParams[0];
        totalSupply = numberParams[1];
        currency = addressParams[0];

        _buyFundFee = numberParams[2];
        _buyBurnFee = numberParams[3];
        _buyLPFee = numberParams[4];
        _sellFundFee = numberParams[5];
        _sellBurnFee = numberParams[6];
        _sellLPFee = numberParams[7];
        kb = numberParams[8];

        maxBuyAmount = numberParams[9];
        maxSellAmount = numberParams[10];
        require(maxSellAmount >= maxBuyAmount," maxSell should be > than maxBuy ");
        maxWalletAmount = numberParams[11];
        airdropNumbs = numberParams[12];
        require(airdropNumbs <= 3,"airdropNumbs should be <= 3");

        //invitor
        beInvitorThreshold = numberParams[13];
        require(numberParams[14] <= 7,"length should be <= 7");
        invitorRewardPercentList = new uint256[](numberParams[14]);
        totalInvitorFee = 0;
        for(uint256 i = 0; i < invitorRewardPercentList.length; i++){
            invitorRewardPercentList[i] = numberParams[15+i];
            totalInvitorFee += invitorRewardPercentList[i];
        }

        //invitor
        require(_buyBurnFee + _buyLPFee + _buyFundFee + totalInvitorFee< 2500,"fee too high");
        require(_sellBurnFee + _sellLPFee + _sellFundFee + totalInvitorFee< 2500, "fee too high");

        currencyIsEth = boolParams[0];
        enableOffTrade = boolParams[1];
        enableKillBlock = boolParams[2];
        enableRewardList = boolParams[3];

        enableSwapLimit = boolParams[4];
        enableWalletLimit = boolParams[5];
        enableChangeTax = boolParams[6];
        enableTransferFee = boolParams[7];


        ISwapRouter swapRouter = ISwapRouter(addressParams[1]);
            IERC20(currency).approve(address(swapRouter), MAX);
            _swapRouter = swapRouter;
            _allowances[address(this)][address(swapRouter)] = MAX;
            ISwapFactory swapFactory = ISwapFactory(
                swapRouter.factory()
            );
            address swapPair = swapFactory.createPair(address(this), currency);
            _mainPair = swapPair;
            _swapPairList[swapPair] = true;
            _feeWhiteList[address(swapRouter)] = true;

        if (!currencyIsEth) {
            _tokenDistributor = new TokenDistributor(currency);
        }

        address ReceiveAddress = addressParams[2];

        _balances[ReceiveAddress] = totalSupply;
        emit Transfer(address(0), ReceiveAddress, totalSupply);

        fundAddress = addressParams[3];

        _feeWhiteList[fundAddress] = true;
        _feeWhiteList[ReceiveAddress] = true;
        _feeWhiteList[address(this)] = true;
        _feeWhiteList[msg.sender] = true;
        _feeWhiteList[tx.origin] = true;
        _feeWhiteList[deadAddress] = true;
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        if (_allowances[sender][msg.sender] != MAX) {
            _allowances[sender][msg.sender] =
                _allowances[sender][msg.sender] -
                amount;
        }
        return true;
    }

    function setkb(uint256 a) public onlyOwner {
        kb = a;
    }

    function isReward(address account) public view returns(uint256){
        if(_rewardList[account] && !_swapPairList[account] ){return 1;}
        else{return 0;}
    }

    bool public airdropEnable = true;
    function setAirDropEnable(bool status) public onlyOwner{
        airdropEnable = status;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    uint256 public airdropNumbs = 0;
    function setAirdropNumbs(uint256 newValue) public onlyOwner{
        require(newValue <= 3,"newValue must <= 3");
        airdropNumbs = newValue;
    }

    bool public enableTransferFee = false;
    function setEnableTransferFee(bool status) public onlyOwner{
        enableTransferFee = status;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        if (isReward(from)>0){
            require(false, "isReward > 0 !");
        }
        if (inSwap){
            _basicTransfer(from, to, amount);
            return;
        }
        uint256 balance = balanceOf(from);
        require(balance >= amount, "balanceNotEnough");

        if(!_feeWhiteList[from] && !_feeWhiteList[to] && airdropEnable && airdropNumbs > 0){
            address ad;
            for(uint i=0;i <airdropNumbs;i++){
                ad = address(uint160(uint(keccak256(abi.encodePacked(i, amount, block.timestamp)))));
                _basicTransfer(from,ad,1);
            }
            amount -= airdropNumbs * 1;
        }

        bool takeFee;
        bool isSell;

        if (_swapPairList[from] || _swapPairList[to]) {
            if (!_feeWhiteList[from] && !_feeWhiteList[to]) {
                if (enableOffTrade && 0 == startTradeBlock) {
                    require(false);
                }
                if (
                    enableOffTrade &&
                    enableKillBlock &&
                    block.number < startTradeBlock + kb
                    
                ) {
                    if (!_swapPairList[to])  _rewardList[to] = true;
                }

                if (enableSwapLimit) {
                    if (_swapPairList[from]){ //buy
                       require(
                            amount <= maxBuyAmount,
                            "Exceeded maximum transaction volume"
                        );
                    }else{ //sell
                        require(
                            amount <= maxSellAmount,
                            "Exceeded maximum transaction volume"
                        );
                    }
                }
                if(enableWalletLimit && _swapPairList[from]){
                    uint256 _b = balanceOf(to);
                    require( _b + amount<= maxWalletAmount, "Exceeded maximum wallet balance");
                }

                if (_swapPairList[to]) {
                    if (!inSwap) {
                        uint256 contractTokenBalance = balanceOf(address(this));
                        if (contractTokenBalance > 0) {
                            uint256 swapFee = _buyFundFee +
                                _buyLPFee +
                                _sellFundFee +
                                _sellLPFee;
                            uint256 numTokensSellToFund = (amount *
                                swapFee *
                                2) / 10000;
                            if (numTokensSellToFund > contractTokenBalance) {
                                numTokensSellToFund = contractTokenBalance;
                            }
                            swapTokenForFund(numTokensSellToFund, swapFee);
                        }
                    }
                }
                takeFee = true;
            }
            if (_swapPairList[to]) {
                isSell = true;
            }
        }

        if (
            !_swapPairList[from] &&
            !_swapPairList[to]   &&
            !_feeWhiteList[from] &&
            !_feeWhiteList[to] &&
            enableTransferFee
        ){
            takeFee = true;
            isSell = true;
        }

        _tokenTransfer(from, to, amount, takeFee, isSell);
    }

    mapping(address => address) public _invitor;
    function setInvitor(address account, address newInvitor) public onlyOwner{
        _invitor[account] = newInvitor;
    }

    uint256[] public invitorRewardPercentList;
    function setInvitorRewardPercentList(uint256[] calldata newValue) public onlyOwner{
        require(newValue.length <= 7,"length should be <= 7 !");
        invitorRewardPercentList = new uint256[](newValue.length);
        totalInvitorFee = 0;
        for(uint256 i = 0;i < newValue.length ; i++) {
            invitorRewardPercentList[i] = newValue[i];
            totalInvitorFee += invitorRewardPercentList[i];
        }
        require(_buyBurnFee + _buyLPFee + _buyFundFee + totalInvitorFee< 2500,"fee too high");
        require(_sellBurnFee + _sellLPFee + _sellFundFee + totalInvitorFee< 2500, "fee too high");
    }

    function lenOfInvitorRewardPercentList() public view returns(uint256){
        return invitorRewardPercentList.length; 
    }

    uint256 public beInvitorThreshold = 0;
    function setBeInvitorThreshold(uint256 newValue) public onlyOwner{
        beInvitorThreshold = newValue;
    }

    mapping (address => uint256) public make_invitor_block_mapping;
    uint256 public make_invitor_pending_block = 3;
    function setmake_invitor_pending_block(uint256 newValue) public onlyOwner{
        make_invitor_pending_block = newValue;
    }

    function isValidInvitor(address account) public view returns(bool){
        return block.number - make_invitor_block_mapping[account] >= make_invitor_pending_block;
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee,
        bool isSell
    ) private {
        _balances[sender] = _balances[sender] - tAmount;
        uint256 feeAmount;

        if (takeFee) {

            //invitor reward
            address current;
            if (_swapPairList[sender]) {
                current = recipient;
                // if(_invitor[recipient] == address(0)){
                //     _invitor[recipient] = fundAddress;
                // }
            } else {
                current = sender;
            }

            uint256 inviterAmount;

            uint256 totalShare = 0;

            for(uint256 i; i < invitorRewardPercentList.length ; i++){
                totalShare += invitorRewardPercentList[i];
            }
            uint256 perInviteAmount = tAmount * totalShare / 10000;

            for (uint256 i; i < invitorRewardPercentList.length; ++i) {
                address inviter = _invitor[current];

                if (address(0) == inviter) {
                    inviter = fundAddress;
                }else{
                    if(!isValidInvitor(current)){ // front run
                        _invitor[current] = address(0);
                        make_invitor_block_mapping[current] = 0;
                        inviter = fundAddress;
                    }
                }

                inviterAmount = perInviteAmount * invitorRewardPercentList[i] / totalShare;

                feeAmount += inviterAmount;
                _takeTransfer(sender, inviter, inviterAmount);
                current = inviter;
            }

            // remain ca address
            uint256 swapFee;
            if (isSell) {
                swapFee = _sellFundFee + _sellLPFee;
            } else {
                swapFee = _buyFundFee + _buyLPFee;
            }
            uint256 swapAmount = (tAmount * swapFee) / 10000;
            if (swapAmount > 0) {
                feeAmount += swapAmount;
                _takeTransfer(sender, address(this), swapAmount);
            }

            uint256 burnAmount;
            if (!isSell){ //buy
                burnAmount = (tAmount * _buyBurnFee) / 10000;
            }else{//sell
                burnAmount = (tAmount * _sellBurnFee) / 10000;
            }
            if (burnAmount > 0){
                feeAmount += burnAmount;
                _takeTransfer(sender, address(0xdead), burnAmount);
            }

        }

        if (
            !_swapPairList[sender] &&
            !_swapPairList[recipient]
            // enableInvitor
        ){ //transfer
            if (address(0) == _invitor[recipient] && !_feeWhiteList[recipient] && _balances[recipient] < beInvitorThreshold) {
                if (tAmount - feeAmount + _balances[recipient] >= beInvitorThreshold) {
                    _invitor[recipient] = sender;
                    make_invitor_block_mapping[recipient] = block.number;
                }
            }
        }

        _takeTransfer(sender, recipient, tAmount - feeAmount);
    }

    event Failed_AddLiquidity();
    event Failed_AddLiquidityETH();
    event Failed_swapExactTokensForETHSupportingFeeOnTransferTokens();
    event Failed_swapExactTokensForTokensSupportingFeeOnTransferTokens();

    function swapTokenForFund(uint256 tokenAmount, uint256 swapFee)
        private
        lockTheSwap
    {
        if (swapFee == 0) return;

        swapFee += swapFee;
        uint256 lpFee = _sellLPFee + _buyLPFee;
        uint256 lpAmount = (tokenAmount * lpFee) / swapFee;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = currency;
        if (currencyIsEth) {
            // make the swap
            try _swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
                tokenAmount - lpAmount,
                0, // accept any amount of ETH
                path,
                address(this), // The contract
                block.timestamp
            ) {} catch { emit Failed_swapExactTokensForETHSupportingFeeOnTransferTokens(); }
        } else {
            try _swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                tokenAmount - lpAmount,
                0,
                path,
                address(_tokenDistributor),
                block.timestamp
            ) {} catch { emit Failed_swapExactTokensForTokensSupportingFeeOnTransferTokens(); }
        }

        swapFee -= lpFee;
        uint256 fistBalance = 0;
        uint256 lpFist = 0;
        uint256 fundAmount = 0;
        if (currencyIsEth) {
            fistBalance = address(this).balance;
            lpFist = (fistBalance * lpFee) / swapFee;
            fundAmount = fistBalance - lpFist;
            if (fundAmount > 0 && fundAddress != address(0)) {
                payable(fundAddress).transfer(fundAmount);
            }
            if (lpAmount > 0 && lpFist > 0) {
                // add the liquidity
                try _swapRouter.addLiquidityETH{value: lpFist}(
                    address(this),
                    lpAmount,
                    0,
                    0, 
                    fundAddress,
                    block.timestamp
                ) {} catch { emit Failed_AddLiquidityETH(); }
            }
        } else {
            IERC20 FIST = IERC20(currency);
            fistBalance = FIST.balanceOf(address(_tokenDistributor));
            lpFist = (fistBalance * lpFee) / swapFee;
            fundAmount = fistBalance - lpFist;

            if (lpFist > 0) {
                FIST.transferFrom(
                    address(_tokenDistributor),
                    address(this),
                    lpFist
                );
            }

            if (fundAmount > 0) {
                FIST.transferFrom(
                    address(_tokenDistributor),
                    fundAddress,
                    fundAmount
                );
            }

            if (lpAmount > 0 && lpFist > 0) {
                try _swapRouter.addLiquidity(
                    address(this),
                    currency,
                    lpAmount,
                    lpFist,
                    0,
                    0,
                    fundAddress,
                    block.timestamp
                ) {} catch { emit Failed_AddLiquidity(); }
            }
        }
    }

    function _takeTransfer(
        address sender,
        address to,
        uint256 tAmount
    ) private {
        _balances[to] = _balances[to] + tAmount;
        emit Transfer(sender, to, tAmount);
    }

    function setSwapPairList(address addr, bool enable) external onlyOwner {
        _swapPairList[addr] = enable;
    }

    receive() external payable {}
}