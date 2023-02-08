// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;
import "comps.sol";
// ________   ________  ___       __   ________  ___     
//|\   ___  \|\   __  \|\  \     |\  \|\   __  \|\  \    
//\ \  \\ \  \ \  \|\  \ \  \    \ \  \ \  \|\  \ \  \   
// \ \  \\ \  \ \  \\\  \ \  \  __\ \  \ \   __  \ \  \  
//  \ \  \\ \  \ \  \\\  \ \  \|\__\_\  \ \  \ \  \ \  \ 
//   \ \__\\ \__\ \_______\ \____________\ \__\ \__\ \__\
//    \|__| \|__|\|_______|\|____________|\|__|\|__|\|__|

// Join Telegram : https://t.me/nowaiAI
// Website : https://www.nowai.ai/
// Twitter : https://twitter.com/nowaiAI


 contract NOWAI is ERC20, Ownable {
    string private _name = "NOWAI";
    string private _symbol = "$NOWAI";
    uint8 private _decimals = 18;
    uint256 private _supply = 10000000000;
    uint256 public taxForLiquidity = 1;
    uint256 public taxForMarketing = 2;
    uint256 public maxWalletAmount = 1;
    address public marketingWallet = 0x47726b6e98Ef99382359EFe87E14D826b57403A1;
    address private uniswapRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    uint256 private _marketingReserves = 0;
    mapping(address => bool) private _isExcludedFromFee;
    uint256 private _numTokensSellToAddToLiquidity = 200 * 10**_decimals;
    uint256 private _numTokensSellToAddToETH = 200 * 10**_decimals;
    bool inSwapAndLiquify;
    bool live;
    uint256 unlockMaxWallet;
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor() ERC20(_name, _symbol, _decimals) {
        _mint(msg.sender, (_supply * 10**_decimals));

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(uniswapRouter);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        _isExcludedFromFee[address(uniswapV2Router)] = true;
        _isExcludedFromFee[msg.sender] = true;
        _isExcludedFromFee[marketingWallet] = true;
        _approve(msg.sender, uniswapRouter, _supply * 10** _decimals);
    }

    function startTrade() public onlyOwner{
        require(!live, "Trade already live!");
        live = true;
        unlockMaxWallet = block.timestamp + 86400;
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(balanceOf(from) >= amount, "ERC20: transfer amount exceeds balance");

        if(from != owner() && to != owner()){
            require(live,"Trading not open yet");
        }

        if ((from == uniswapV2Pair || to == uniswapV2Pair) && !inSwapAndLiquify) {
            if (from != uniswapV2Pair) {
                uint256 contractLiquidityBalance = balanceOf(address(this)) - _marketingReserves;
                if (contractLiquidityBalance >= _numTokensSellToAddToLiquidity) {
                    _swapAndLiquify(_numTokensSellToAddToLiquidity);
                }
                if ((_marketingReserves) >= _numTokensSellToAddToETH) {
                    _swapTokensForEth(_numTokensSellToAddToETH);
                    _marketingReserves -= _numTokensSellToAddToETH;
                    bool sent = payable(marketingWallet).send(address(this).balance);
                    require(sent, "Failed to send ETH");
                }
            }

            uint256 transferAmount;
            if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
                transferAmount = amount;
            } 
            else {
                if(from == uniswapV2Pair && (unlockMaxWallet > block.timestamp)){
                        require((amount + balanceOf(to)) <= (_supply * 10** _decimals) * maxWalletAmount / 100, "ERC20: balance amount exceeded max wallet amount limit");
                }

                uint256 marketingShare = ((amount * taxForMarketing) / 100);
                uint256 liquidityShare = ((amount * taxForLiquidity) / 100);
                transferAmount = amount - (marketingShare + liquidityShare);
                _marketingReserves += marketingShare;

                super._transfer(from, address(this), (marketingShare + liquidityShare));
            }
            super._transfer(from, to, transferAmount);
        } 
        else {
            super._transfer(from, to, amount);
        }
    }

    function _swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 half = (contractTokenBalance / 2);
        uint256 otherHalf = (contractTokenBalance - half);

        uint256 initialBalance = address(this).balance;

        _swapTokensForEth(half);

        uint256 newBalance = (address(this).balance - initialBalance);

        _addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function _swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            (block.timestamp + 300)
        );
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount)
        private
        lockTheSwap
    {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            address(0xdead),
            block.timestamp
        );
    }

    function changeMarketingWallet(address newWallet)
        public
        onlyOwner
        returns (bool)
    {
        marketingWallet = newWallet;
        return true;
    }

    function changeTaxForLiquidityAndMarketing(uint256 _taxForLiquidity, uint256 _taxForMarketing)
        public
        onlyOwner
        returns (bool)
    {
        require((_taxForLiquidity+_taxForMarketing) <= 100, "ERC20: total tax must not be greater than 100");
        taxForLiquidity = _taxForLiquidity;
        taxForMarketing = _taxForMarketing;

        return true;
    }

    function changeMaxWalletAmount(uint256 _maxWalletAmount)
        public
        onlyOwner
        returns (bool)
    {
        maxWalletAmount = _maxWalletAmount;

        return true;
    }

    receive() external payable {}
}