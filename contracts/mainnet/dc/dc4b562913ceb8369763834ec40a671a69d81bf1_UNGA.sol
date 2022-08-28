/**
 *Submitted for verification at Etherscan.io on 2022-08-28
*/

/*
╭────────────────────────────────────────────────╮
│  🍑 Donald J. Trump✔️               ┏━━━━━━┓  │
│      @ʳᵉᵃˡᴰᵒⁿᵃˡᵈᵀʳᵘᵐᵖ              ☼ ┃follow┃  │ 
│                                      ┗━━━━━━┛  │ 
│    I have never seen a thin person             │
│    drinking  Diet Coke.                        │
│    ₁₁.₄₃ ₋ ₁₄. ₒₖₜ. ₂₀₁₂                        │ 
│   ________________________________________     │
│    105k retweets 121k likes   ⚫⚫⚪⚪⚫⚪  │
│                                                │
╰────────────────────────────────────────────────╯

U N G A    T R U M P:

Seventy-five years after the end of World War II and the founding of the United Nations, 
we are once again engaged in a great global struggle. We have waged a fierce battle against 
the invisible enemy — the China virus — which has claimed countless lives in 188 countries.

In the United States, we launched the most aggressive mobilization since the Second World War. 
We rapidly produced a record supply of ventilators, creating a surplus that allowed us to share 
them with friends and partners all around the globe. We pioneered life-saving treatments, 
reducing our fatality rate 85 percent since April.

Thanks to our efforts, three vaccines are in the final stage of clinical trials. 
We are mass-producing them in advance so they can be delivered immediately upon arrival.

We will distribute a vaccine, we will defeat the virus, we will end the pandemic, 
and we will enter a new era of unprecedented prosperity, cooperation, and peace.

As we pursue this bright future, we must hold accountable the nation which unleashed this plague onto the world: China.

In the earliest days of the virus, China locked down travel domestically while allowing 
flights to leave China and infect the world. China condemned my travel ban on their country, 
even as they cancelled domestic flights and locked citizens in their homes.

The Chinese government and the World Health Organization — which is virtually controlled by China — 
falsely declared that there was no evidence of human-to-human transmission. Later, they falsely 
said people without symptoms would not spread the disease.

The United Nations must hold China accountable for their actions.

In addition, every year, China dumps millions and millions of tons of plastic and trash into the oceans, 
overfishes other countries’ waters, destroys vast swaths of coral reef, and emits more toxic mercury into 
the atmosphere than any country anywhere in the world. China’s carbon emissions are nearly twice what the 
U.S. has, and it’s rising fast. By contrast, after I withdrew from the one-sided Paris Climate Accord, 
last year America reduced its carbon emissions by more than any country in the agreement.

Those who attack America’s exceptional environmental record while ignoring China’s rampant pollution are not 
interested in the environment. They only want to punish America, and I will not stand for it.

If the United Nations is to be an effective organization, it must focus on the real problems of the world. 
This includes terrorism, the oppression of women, forced labor, drug trafficking, human and sex trafficking, 
religious persecution, and the ethnic cleansing of religious minorities.

America will always be a leader in human rights. My administration is advancing religious liberty, 
opportunity for women, the decriminalization of homosexuality, combatting human trafficking, and protecting unborn children.

We also know that American prosperity is the bedrock of freedom and security all over the world. 
In three short years, we built the greatest economy in history, and we are quickly doing it again. 
Our military has increased substantially in size. We spent $2.5 trillion over the last four years 
on our military. We have the most powerful military anywhere in the world, and it’s not even close.

We stood up to decades of China’s trade abuses. We revitalized the NATO Alliance, where other countries 
are now paying a much more fair share. We forged historic partnerships with Mexico, Guatemala, Honduras, 
and El Salvador to stop human smuggling. We are standing with the people of Cuba, Nicaragua, and 
Venezuela in their righteous struggle for freedom.

We withdrew from the terrible Iran Nuclear Deal and imposed crippling sanctions on the world’s leading 
state sponsor of terror. We obliterated the ISIS caliphate 100 percent; killed its founder and leader, 
al-Baghdadi; and eliminated the world’s top terrorist, Qasem Soleimani.

This month, we achieved a peace deal between Serbia and Kosovo. We reached a landmark breakthrough 
with two peace deals in the Middle East, after decades of no progress. Israel, the United Arab Emirates, 
and Bahrain all signed a historic peace agreement in the White House, with many other Middle Eastern 
countries to come. They are coming fast, and they know it’s great for them and it’s great for the world.

These groundbreaking peace deals are the dawn of the new Middle East. By taking a different approach, 
we have achieved different outcomes — far superior outcomes. We took an approach, and the approach worked. 
We intend to deliver more peace agreements shortly, and I have never been more optimistic for the future of the region. 
There is no blood in the sand. Those days are, hopefully, over.

As we speak, the United States is also working to end the war in Afghanistan, and we are bringing our troops home. 
America is fulfilling our destiny as peacemaker, but it is peace through strength. We are stronger now than ever before. 
Our weapons are at an advanced level like we’ve never had before — like, frankly, we’ve never even thought of having before. 
And I only pray to God that we never have to use them.

For decades, the same tired voices proposed the same failed solutions, pursuing global ambitions at the expense 
of their own people. But only when you take care of your own citizens will you find a true basis for cooperation. 
As President, I have rejected the failed approaches of the past, and I am proudly putting America first, just as 
you should be putting your countries first. That’s okay — that’s what you should be doing.

I am supremely confident that next year, when we gather in person, we will be in the midst of one of the greatest 
years in our history — and frankly, hopefully, in the history of the world.

Thank you. God bless you all. God bless America. And God bless the United Nations.


*/

pragma solidity 0.8.7;
// SPDX-License-Identifier: UNLICENSED 
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
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

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract UNGA is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private bots;
    mapping (address => uint) private cooldown;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 100000000000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    uint256 private _feeAddr1;
    uint256 private _feeAddr2;
    uint256 private _standardTax;
    address payable private _feeAddrWallet;

    string private constant _name = "UNGA TRUMP";
    string private constant _symbol ="U N G A";
    uint8 private constant _decimals = 9;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;
    bool private cooldownEnabled = false;
    uint256 private _maxTxAmount = _tTotal.mul(20).div(1000);
    uint256 private _maxWalletSize = _tTotal.mul(30).div(1000);
    event MaxTxAmountUpdated(uint _maxTxAmount);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor () {
        _feeAddrWallet = payable(_msgSender());
        _rOwned[_msgSender()] = _rTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_feeAddrWallet] = true;
        _standardTax=0;

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

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function setCooldownEnabled(bool onoff) external onlyOwner() {
        cooldownEnabled = onoff;
    }

    function tokenFromReflection(uint256 rAmount) private view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");


        if (from != owner() && to != owner()) {
            require(!bots[from] && !bots[to]);
            _feeAddr1 = 0;
            _feeAddr2 = _standardTax;
            if (from == uniswapV2Pair && to != address(uniswapV2Router) && ! _isExcludedFromFee[to] && cooldownEnabled) {
                // Cooldown
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");

            }


            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && from != uniswapV2Pair && swapEnabled && contractTokenBalance>0) {
                swapTokensForEth(contractTokenBalance);
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }else{
          _feeAddr1 = 0;
          _feeAddr2 = 0;
        }

        _tokenTransfer(from,to,amount);
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

    function setStandardTax(uint256 newTax) external onlyOwner{
      require(newTax<_standardTax);
      _standardTax=newTax;
    }

    function removeLimits() external onlyOwner{
        _maxTxAmount = _tTotal;
        _maxWalletSize = _tTotal;
    }

    function sendETHToFee(uint256 amount) private {
        _feeAddrWallet.transfer(amount);
    }

    function openTrading() external onlyOwner() {
        require(!tradingOpen,"trading is already open");
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        swapEnabled = true;
        cooldownEnabled = true;

        tradingOpen = true;
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
    }

        function addbot(address[] memory bots_) public onlyOwner {
        for (uint i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount) private {
        _transferStandard(sender, recipient, amount);
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tTeam) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeTeam(tTeam);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _takeTeam(uint256 tTeam) private {
        uint256 currentRate =  _getRate();
        uint256 rTeam = tTeam.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rTeam);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    receive() external payable {}

    function manualswap() external {
        require(_msgSender() == _feeAddrWallet);
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

    function manualsend() external {
        require(_msgSender() == _feeAddrWallet);
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }


    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tTeam) = _getTValues(tAmount, _feeAddr1, _feeAddr2);
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tTeam, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTeam);
    }

    function _getTValues(uint256 tAmount, uint256 taxFee, uint256 TeamFee) private pure returns (uint256, uint256, uint256) {
        uint256 tFee = tAmount.mul(taxFee).div(100);
        uint256 tTeam = tAmount.mul(TeamFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tTeam);
        return (tTransferAmount, tFee, tTeam);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tTeam, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTeam = tTeam.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rTeam);
        return (rAmount, rTransferAmount, rFee);
    }

	function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
}