// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.17;

import './ERC20.sol';
import './Ownable.sol';
import './IUniswapV2Factory.sol';
import './IUniswapV2Pair.sol';
import './IUniswapV2Router02.sol';

contract aptoschain is ERC20, Ownable {
    uint256 public buyFee               = 10;
    uint256 public sellFee              = 10;
    uint256 public walletToWalletFee    = 0;

    uint256 public treasuryShare         = 80;
    uint256 public marketingShare       = 20;

    address public marketingWallet = 0x8dB8028C5EE495aFeb23D241C09e9e3900419A8b;
    address public treasuryWallet = 0x8dB8028C5EE495aFeb23D241C09e9e3900419A8b;

    bool public walletToWalletTransferWithoutFee = false;

    IUniswapV2Router02 public uniswapV2Router;
    address public  uniswapV2Pair;
    
    address private DEAD = 0x000000000000000000000000000000000000dEaD;

    bool    private swapping;
    uint256 public swapTokensAtAmount;

    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) public automatedMarketMakerPairs;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event BuyFeesUpdated(uint256 buyFee);
    event SellFeesUpdated(uint256 sellFee);
    event MarketingWalletChanged(address marketingWallet);
    event treasuryWalletChanged(address treasuryWallet);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event SwapAndSendToWallet(address to, uint256 tokensSwapped, uint256 bnbSend);


    constructor () ERC20("APTOSCHAIN", "APTOSC") 
    {   
        address newOwner = 0x8dB8028C5EE495aFeb23D241C09e9e3900419A8b;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair   = _uniswapV2Pair;

        _approve(address(this), address(uniswapV2Router), type(uint256).max);

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[newOwner] = true;
        _isExcludedFromFees[DEAD] = true;
        _isExcludedFromFees[address(this)] = true;
        
        _mint(newOwner, 100e4 * (10 ** 18));
        swapTokensAtAmount = totalSupply() / 2000;
    }

    receive() external payable {

  	}

    function claimStuckTokens(address token) external onlyOwner {
        require(token != address(this), "Owner cannot claim native tokens");
        if (token == address(0x0)) {
            payable(msg.sender).transfer(address(this).balance);
            return;
        }
        IERC20 ERC20token = IERC20(token);
        uint256 balance = ERC20token.balanceOf(address(this));
        ERC20token.transfer(msg.sender, balance);
    }

    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function sendBNB(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
 
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    //=======FeeManagement=======//
    function excludeFromFees(address account, bool excluded) external onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function updateBuyFees(uint256 _buyFee) external onlyOwner {
        require(_buyFee<= 15, "Fees cannot be more than 15%");
        buyFee = _buyFee;
        emit BuyFeesUpdated(buyFee);
    }

    function updateSellFees(uint256 _sellFee) external onlyOwner {
        require(_sellFee<= 15, "Fees cannot be more than 15%");
        sellFee = _sellFee;
        emit SellFeesUpdated(sellFee);
    }

    function updateWalletToWalletFee(uint256 _walletToWalletFee) external onlyOwner {
        require(_walletToWalletFee <= 15, "Fees cannot be more than 15%");
        walletToWalletFee = _walletToWalletFee;
    }

    function updateShares(uint256 _treasuryShare, uint256 _marketingShare) external onlyOwner {
        require(_treasuryShare + _marketingShare == 100, "Shares must add up to 100%");
        treasuryShare = _treasuryShare;
        marketingShare = _marketingShare;
    }

    function enableWalletToWalletTransferWithoutFee(bool enable) external onlyOwner {
        require(walletToWalletTransferWithoutFee != enable, "Wallet to wallet transfer without fee is already set to that value");
        walletToWalletTransferWithoutFee = enable;
    }

    function changeMarketingWallet(address _marketingWallet) external onlyOwner {
        require(_marketingWallet != marketingWallet, "Marketing wallet is already that address");
        require(!isContract(_marketingWallet), "Marketing wallet cannot be a contract");
        marketingWallet = _marketingWallet;
        emit MarketingWalletChanged(marketingWallet);
    }

    function changetreasuryWallet(address _treasuryWallet) external onlyOwner {
        require(_treasuryWallet != treasuryWallet, "treasury wallet is already that address");
        require(!isContract(_treasuryWallet), "treasury wallet cannot be a contract");
        treasuryWallet = _treasuryWallet;
        emit treasuryWalletChanged(treasuryWallet);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal  override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
       
        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
		uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if( canSwap &&
            !swapping &&
            !automatedMarketMakerPairs[from]
        ) {
            swapping = true;

            if(treasuryShare > 0) {
                uint256 treasuryTokens = contractTokenBalance * treasuryShare / 100;
                swapAndSendToWallet(treasuryTokens, treasuryWallet);
            }
            
            if(marketingShare > 0) {
                uint256 marketingTokens = contractTokenBalance * marketingShare / 100;
                swapAndSendToWallet(marketingTokens, marketingWallet);
            }          

            swapping = false;
        }

        bool takeFee = !swapping;

        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if(walletToWalletTransferWithoutFee && from != uniswapV2Pair && to != uniswapV2Pair) {
            takeFee = false;
        }

        if(takeFee) {
            uint256 _totalFees;
            if(from == uniswapV2Pair) {
                _totalFees = buyFee;
            } else if(to == uniswapV2Pair) {
                _totalFees = sellFee;
            }
            else {
                _totalFees = walletToWalletFee;
            }
            if (_totalFees > 0) {
                uint256 fees = amount * _totalFees / 100;
                amount = amount - fees;
                super._transfer(from, address(this), fees);
            }
        }

        super._transfer(from, to, amount);

    }


    function swapAndSendToWallet(uint256 tokenAmount, address to) private {
        uint256 initialBalance = address(this).balance;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp);

        uint256 newBalance = address(this).balance - initialBalance;

        sendBNB(payable(to), newBalance);

        emit SwapAndSendToWallet(to, tokenAmount, newBalance);
    }

    function setSwapTokensAtAmount(uint256 newAmount) external onlyOwner{
        require(newAmount > totalSupply() / 100000, "SwapTokensAtAmount must be greater than 0.001% of total supply");
        swapTokensAtAmount = newAmount;
    }
}