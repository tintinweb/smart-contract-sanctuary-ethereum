/**
 *Submitted for verification at Etherscan.io on 2023-06-09
*/

/**


░░░░░██╗██╗░░░██╗░██████╗████████╗  ██╗░░██╗░█████╗░██╗░░░░░██████╗░
░░░░░██║██║░░░██║██╔════╝╚══██╔══╝  ██║░░██║██╔══██╗██║░░░░░██╔══██╗
░░░░░██║██║░░░██║╚█████╗░░░░██║░░░  ███████║██║░░██║██║░░░░░██║░░██║
██╗░░██║██║░░░██║░╚═══██╗░░░██║░░░  ██╔══██║██║░░██║██║░░░░░██║░░██║
╚█████╔╝╚██████╔╝██████╔╝░░░██║░░░  ██║░░██║╚█████╔╝███████╗██████╔╝
░╚════╝░░╚═════╝░╚═════╝░░░░╚═╝░░░  ╚═╝░░╚═╝░╚════╝░╚══════╝╚═════╝░

*********

Jeeters, they’re everywhere now. Wrecking projects in less than 2 hours upon launch, before most of them even have a chance of taking off. 

Just Hold isn't your average HODL token. Forget about old tokens like $HOLD that banked on pure hope and fizzled out. Just Hold ($JHOLD) is a revolutionary Anti-Jeet token with custom built features to incentivize and reward long term holding while strongly disincentivizing early seller behavior. It's the smarter way to hold and build wealth.

For more details visit the website: https://www.justhold.vip
Twitter: https://twitter.com/JustHoldERC20
Telegram: https://t.me/JustHoldERC20

*********

**/


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

 
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}
 
contract Ownable is Context {
    address internal _owner;
    address private _previousOwner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
 
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
 
    function owner() public view returns (address) {
        return _owner;
    }
 
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
 
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
 
 
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
        return c;
    }
}
 
interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}
 
interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
 
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
}
 
contract JustHold  is Context, IERC20, Ownable {
 
    using SafeMath for uint256;
 
    string private constant _name = unicode"Just Hold (堅持)";
    string private constant _symbol = "JHOLD";
    uint8 private constant _decimals = 9;
 
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    uint256 private constant MAX = ~uint256(0);

    uint256 private constant _tTotal = 1_000_000_000 * 10**9;

    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    //Temporary Initial launch tax
    uint256 private _taxFeeOnLaunchBuy = 30;  
    uint256 private _taxFeeOnLaunchSell = 35;
 
    uint256 private _taxFee = _taxFeeOnLaunchSell;
 
    uint256 private _previoustaxFee = _taxFee;
 
    mapping(address => bool) public bots;
    address payable private _marketingAddress = payable(0x3c395d6Ad1E94DB73f0B9833360DE4fB21Fccb15);
    address payable private _buybackAddress = payable(0x180d959c1B26354f50924866D36fcC290D6b19a3);
    address payable private _taxrewardsAddress = payable(0x51ffeef5a6BB6a76FC80E07c47bD7f0760ec4F65);
 
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    address private _uncxLPLocker = 0x663A5C229c09b049E36dCc11a9B0d4a8Eb9db214;
    address private _cexwallet = 0x552866Bfe6cAaE60aD77E3babEA18bf7112361Fb;
 
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = true;

    bool private dynamicTaxEnabled = false;
 
    uint256 public _maxWalletSize = _tTotal.mul(2).div(100); 
    uint256 public _swapTokensAtAmount = _tTotal.mul(1).div(1000);


    mapping (address => uint256) public userBuyTime;
    mapping (address => bool) public thresholdReached;
    mapping (address => bool) public checkpointBuy;
    uint256 public eligibleTaxThreshold = _tTotal.mul(2).div(1000);

    mapping (address => bool) public markedForReward;

    address[] public eligibleHolders;

    bool private accountTransfersAllowed = false;

    mapping(address => bool) private _isExcludedFromTransferBan;
 
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
 
    constructor() {
 
        _rOwned[_msgSender()] = _rTotal;
 
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
 
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_marketingAddress] = true;
        _isExcludedFromFee[_buybackAddress] = true;
        _isExcludedFromFee[_taxrewardsAddress] = true;
        _isExcludedFromFee[address(_uniswapV2Router)] = true;
        _isExcludedFromFee[_uncxLPLocker] = true; //UNCX LP Lock address
        _isExcludedFromFee[_cexwallet] = true;

        _isExcludedFromTransferBan[owner()] = true;
        _isExcludedFromTransferBan[address(this)] = true;
        _isExcludedFromTransferBan[_marketingAddress] = true;
        _isExcludedFromTransferBan[_buybackAddress] = true;
        _isExcludedFromTransferBan[_taxrewardsAddress] = true;
        _isExcludedFromTransferBan[address(_uniswapV2Router)] = true;
        _isExcludedFromTransferBan[_uncxLPLocker] = true; //UNCX LP Lock address
        _isExcludedFromTransferBan[_cexwallet] = true;
        


        emit Transfer(address(0), _msgSender(), _tTotal);

    }
 
    function name() public pure returns (string memory) {
        return _name;
    }
 
    function symbol() public pure returns (string memory) {
        return _symbol;
    }
 
    function decimals() public pure returns (uint8) {
        return _decimals;
    }
 
    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }
 
    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(_rOwned[account]);
    }
 
    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
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
        _approve(_msgSender(), spender, amount);
        return true;
    }
 
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }
 
    function tokenFromReflection(uint256 rAmount)
        private
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }
 
    function removeAllFee() private {
        if (_taxFee == 0) return;
 
        _previoustaxFee = _taxFee;
        _taxFee = 0;
    }
 
    function restoreAllFee() private {
        _taxFee = _previoustaxFee;
    }
 
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
 
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
 
        if (from != owner() && to != owner()) {
 
            //Trade start check
            if (!tradingOpen) {
                require(from == owner(), "TOKEN: This account cannot send tokens until trading is enabled");
            }

            
            require(!bots[from] && !bots[to], "TOKEN: Your account is blacklisted!");

            
            if(to != uniswapV2Pair) {
                require(balanceOf(to) + amount < _maxWalletSize, "TOKEN: Balance exceeds wallet size!");
            }

            if(from != uniswapV2Pair && to != uniswapV2Pair && !_isExcludedFromTransferBan[from] && !_isExcludedFromTransferBan[to]) {
                require(accountTransfersAllowed);
            }
 
            uint256 contractTokenBalance = balanceOf(address(this));
            bool canSwap = contractTokenBalance >= _swapTokensAtAmount;
 
            if (canSwap && !inSwap && from != uniswapV2Pair && swapEnabled && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
                swapTokensForEth(contractTokenBalance);
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        } 
 
        bool takeFee = true;

 
        //Transfer Tokens
        if ((_isExcludedFromFee[from] || _isExcludedFromFee[to]) || (from != uniswapV2Pair && to != uniswapV2Pair)) {
            takeFee = false;
        } else {
 
            //Set Fee for Buys
            if(from == uniswapV2Pair && to != address(uniswapV2Router)) {

                
                if(!thresholdReached[to]) {

                    if(!checkpointBuy[to]) {
                         userBuyTime[to] = block.timestamp;
                          checkpointBuy[to] == true;
                     }

                     if(balanceOf(to) + amount >= eligibleTaxThreshold) {
                         userBuyTime[to] = block.timestamp;
                          thresholdReached[to] = true;
                    }

                }


                if(!dynamicTaxEnabled) {
                    _taxFee = _taxFeeOnLaunchBuy;

                } else {

                    uint currentTime = block.timestamp;

                    if(currentTime >= (userBuyTime[to] + 24 hours) && currentTime < (userBuyTime[to] + 48 hours)) {
                        _taxFee = 2;
                    } else if(currentTime >= (userBuyTime[to] + 48 hours) && currentTime < (userBuyTime[to] + 72 hours) && thresholdReached[to]) {
                        _taxFee = 1;
                    } else if(currentTime >= (userBuyTime[to] + 72 hours) && thresholdReached[to]) {
                        _taxFee = 0;

                    } else {
                        _taxFee = 5;
                    }

                }

                
            }
 
            //Set Fee for Sells
            if (to == uniswapV2Pair && from != address(uniswapV2Router)) {

                uint currentTime = block.timestamp;

                if(!dynamicTaxEnabled) {
                    _taxFee = _taxFeeOnLaunchSell;

                } else {

                    if(currentTime >= (userBuyTime[from] + 24 hours) && currentTime < (userBuyTime[from] + 48 hours)) {
                        _taxFee = 15;
                    } else if(currentTime >= (userBuyTime[from] + 48 hours) && currentTime < (userBuyTime[from] + 72 hours) && thresholdReached[from]) {
                        _taxFee = 5;
                    } else if(currentTime >= (userBuyTime[from] + 72 hours) && thresholdReached[from]) {
                        _taxFee = 0;

                    } else {
                        _taxFee = 25;
                    }

                }

                userBuyTime[from] = currentTime; //Reset tax rate if any amount of tokens is sold
                checkpointBuy[from] == false;

                if(balanceOf(from) - amount < eligibleTaxThreshold) {
                    thresholdReached[from] = false;
                }

                    
                
            }
 
        }
 
        _tokenTransfer(from, to, amount, takeFee);
    }
 
    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
 
    function sendETHToFee(uint256 amount) private {

        if(dynamicTaxEnabled) {
            _marketingAddress.transfer(amount.mul(3).div(5));
            _buybackAddress.transfer(amount.mul(1).div(5));
            _taxrewardsAddress.transfer(amount.mul(1).div(5));

        } else {
            _marketingAddress.transfer(amount);
        }
        
    }
 
    function openTrading() public onlyOwner {
        tradingOpen = true;
    }
 
    function manualswap() external {
        require( _msgSender() == _marketingAddress);
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }
 
    function manualsend() external {
        require( _msgSender() == _marketingAddress);
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }
 
    function blockBots(address[] memory bots_) public onlyOwner {
        for (uint256 i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }
 
    function unblockBot(address notbot) public onlyOwner {
        bots[notbot] = false;
    }
 
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeAllFee();
        _transferStandard(sender, recipient, amount);
        if (!takeFee) restoreAllFee();
    }
 
    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 tTransferAmount,
            uint256 tTeam
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeTeam(tTeam);
        emit Transfer(sender, recipient, tTransferAmount);
    }
 
    function _takeTeam(uint256 tTeam) private {
        uint256 currentRate = _getRate();
        uint256 rTeam = tTeam.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rTeam);
    }
 
 
    receive() external payable {}
 
    function _getValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (uint256 tTransferAmount, uint256 tTeam) =
            _getTValues(tAmount, _taxFee);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount) =
            _getRValues(tAmount, tTeam, currentRate);
        return (rAmount, rTransferAmount, tTransferAmount, tTeam);
    }
 
    function _getTValues(
        uint256 tAmount,
        uint256 taxFee
    )
        private
        pure
        returns (
            uint256,
            uint256
        )
    {
        uint256 tTeam = tAmount.mul(taxFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tTeam);
        return (tTransferAmount, tTeam);
    }
 
    function _getRValues(
        uint256 tAmount,
        uint256 tTeam,
        uint256 currentRate
    )
        private
        pure
        returns (
            uint256,
            uint256
        )
    {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rTeam = tTeam.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rTeam);
        return (rAmount, rTransferAmount);
    }
 
    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }
 
    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }


    function removeFromList(address _address) internal {
        uint index = findAddress(_address);
        if (index >= eligibleHolders.length) return;

        // Remove the address.
        for (uint i = index; i<eligibleHolders.length-1; i++){
            eligibleHolders[i] = eligibleHolders[i+1];
        }
        eligibleHolders.pop();
    }

    function findAddress(address _address) internal view returns(uint) {
        uint i = 0;
        while (eligibleHolders[i] != _address) {
            i++;
            if (i == eligibleHolders.length) break;
        }
        return i;
    }

    //Called once daily to keep track of holders that are eligible for tax rewards
    function updateTaxRewardList(address[] calldata holders) public returns( address[] memory) {
        require( _msgSender() == _taxrewardsAddress || _msgSender() == _marketingAddress);

        
        for(uint i=0; i < holders.length; i++) {

            bool isEligible = isEligibleForTaxRewards(holders[i]);

            if(isEligible && !markedForReward[holders[i]]) {
                markedForReward[holders[i]] = true;
                eligibleHolders.push(holders[i]);
            }

            if(!isEligible && markedForReward[holders[i]]) {
                markedForReward[holders[i]] = false;
                removeFromList(holders[i]);
            }

        }

        return eligibleHolders;

    }

    function totalEligibleForTaxReward() public view returns(uint256) {
        return eligibleHolders.length;
    }

    //Lookup a holder's current buy/sell tax rate
    function getUserCurrentBuySellTax(address user) public view returns(uint256 buy, uint256 sell) {

        if(dynamicTaxEnabled) {

            uint256 currentTime = block.timestamp;
            uint256 _buy;
            uint256 _sell;

            if(currentTime >= (userBuyTime[user] + 24 hours) && currentTime < (userBuyTime[user] + 48 hours)) {
                _buy = 2;
                _sell = 15;
                return (_buy, _sell);

            } else if(currentTime >= (userBuyTime[user] + 48 hours) && currentTime < (userBuyTime[user] + 72 hours) && thresholdReached[user]) {
                _buy = 1;
                _sell = 5;
                return (_buy, _sell);

            } else if(currentTime >= (userBuyTime[user] + 72 hours) && thresholdReached[user]) {
                _buy = 0;
                _sell = 0;
                return (_buy, _sell);
            } else {
                _buy = 5;
                _sell = 25;
                return (_buy, _sell);
            }

        } else {
            return(_taxFeeOnLaunchBuy, _taxFeeOnLaunchSell);
        }

    }


    function isEligibleForTaxRewards(address user) public view returns(bool) {
        if(block.timestamp >= (userBuyTime[user] + 72 hours) && thresholdReached[user]) {
            return true;
        }

        return false;
    }
 

    function enableDynamicTax() public onlyOwner {
        dynamicTaxEnabled = true;
    }

    //The threshold for eligiblity of full tax reduction may be adjusted in the future by the marketing wallet to keep the price fair and affordable. 
    function updateEligibleTaxThreshold(uint256 amountPrecision) public {
        // amountPrecision of 1 is 0.01%
        // amountPrecision of 10 is 0.1%
        // amountPrecision of 100 is 1%
        require( _msgSender() == _marketingAddress);
        require(amountPrecision <= 200, "Can only set to 2% or lower");

        eligibleTaxThreshold = (_tTotal * amountPrecision ) / 10000;
    }

    //Used for enabling or disabling transfers of tokens between ethereum wallets. Disabled by default. Does not impact buying/selling on Uniswap.
    function setTransfersBetweenAccountsAllowed(bool allowed) public {
        require( _msgSender() == _marketingAddress);
        accountTransfersAllowed = allowed;
    }

    //May be necessary to exempt future addresses for CEX listings
    function exemptFromBetweenAccountsTransferBan(address account) public {
        require( _msgSender() == _marketingAddress);
        _isExcludedFromTransferBan[account] = true;
    }

    //May be necessary to exempt future addresses for CEX listings
    function exemptFromFee(address account) public {
        require( _msgSender() == _marketingAddress);
        _isExcludedFromFee[account] = true;
    }
    
 
    function setMinSwapTokensThreshold(uint256 swapTokensAtAmount) public {
        require( _msgSender() == _marketingAddress);
        _swapTokensAtAmount = swapTokensAtAmount;
    }
 
    function setMaxWalletSize(uint256 amountPercent) public onlyOwner {
        require(amountPercent>0);
        _maxWalletSize = (_tTotal * amountPercent ) / 100;
    }

    function removeMaxWalletLimit() external onlyOwner{
        _maxWalletSize = _tTotal;
    }


}