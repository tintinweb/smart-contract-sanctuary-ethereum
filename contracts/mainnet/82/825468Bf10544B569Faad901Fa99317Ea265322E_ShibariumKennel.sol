/**


   ___|   |     _)  |                  _)                        |  /                            | 
 \___ \   __ \   |  __ \    _` |   __|  |  |   |  __ `__ \       ' /    _ \  __ \   __ \    _ \  | 
       |  | | |  |  |   |  (   |  |     |  |   |  |   |   |      . \    __/  |   |  |   |   __/  | 
 _____/  _| |_| _| _.__/  \__,_| _|    _| \__,_| _|  _|  _|     _|\_\ \___| _|  _| _|  _| \___| _| 
                                                                                                   


*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.9;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./ERC20.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

contract ShibariumKennel is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    address private constant DEAD = address(0xdead);
    address private constant ZERO = address(0);

    /* Naming */
    string private _name = "Shibarium Kennel";
    string private _symbol = "SKENNEL";

    bool private swapping;
    uint256 public swapTokensAtAmount;

    bool public tradingEnabled = false;
    bool public swapEnabled = false;

    uint256 public taxFee;
    address private taxWallet;

    /* Max transaction amount */
    bool public maxTnxAmountEnabled = true;
    uint256 public maxTnxAmount;

    /* Maps */
    mapping(address => bool) private isExcludedFromFees;
    mapping(address => bool) private isExcludedMaxTnxAmount;
    mapping(address => bool) private automatedMarketMakerPairs;

    constructor() ERC20(_name, _symbol) {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        excludeFromMaxTnxAmount(address(_uniswapV2Router), true);

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        automatedMarketMakerPairs[address(uniswapV2Pair)] = true;
        excludeFromMaxTnxAmount(address(uniswapV2Pair), true);

        uint256 totalSupply = 1000000 * 10**decimals();
        maxTnxAmount = totalSupply.mul(2).div(100);
        swapTokensAtAmount = totalSupply.mul(1).div(1000);

        taxFee = 12;
        taxWallet = _msgSender();

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);

        excludeFromMaxTnxAmount(owner(), true);
        excludeFromMaxTnxAmount(address(this), true);
        excludeFromMaxTnxAmount(DEAD, true);

        _mint(_msgSender(), totalSupply);
    }

    receive() external payable {}

    function openTrading() external onlyOwner {
        require(tradingEnabled == false, "TOKEN: The trading has been openned.");
        tradingEnabled = swapEnabled = true;
    }

    function toggleSwapEnabled() external onlyOwner {
        swapEnabled = !swapEnabled;
    }

    function updateTaxFee(uint256 _taxFee) external onlyOwner {
        require(_taxFee <= 7, "TOKEN: Must keep fees at 7% or less.");
        taxFee = _taxFee;
    }

    function updateTaxWallet(address _taxWallet) external onlyOwner {
        taxWallet = _taxWallet;
    }

    function removeMaxTnxAmount() external onlyOwner {
        require(maxTnxAmountEnabled == true, "TOKEN: Max Tnx amount has been removed.");
        maxTnxAmountEnabled = false;
    }

    function excludeFromMaxTnxAmount(address _address, bool excluded) public onlyOwner {
        isExcludedMaxTnxAmount[_address] = excluded;
    }

    function excludeFromFees(address _address, bool excluded) public onlyOwner {
        isExcludedFromFees[_address] = excluded;
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != ZERO, "ERC20: transfer from the zero address.");
        require(to != DEAD, "ERC20: transfer to the zero address.");
        require(amount > 0, "ERC20: transfer amount must be greater than zero.");

        if (from != owner() && to != owner() && to != ZERO && to != DEAD && !swapping) {
            if (!tradingEnabled) {
                require(isExcludedFromFees[from] || isExcludedFromFees[to], "TOKEN: Trading is not active.");
            }

            if (maxTnxAmountEnabled) {
                if (automatedMarketMakerPairs[from] && !isExcludedMaxTnxAmount[to]) {
                    require(amount <= maxTnxAmount, "TOKEN: Buy transfer amount exceeds the max Tnx amount.");
                } else if (automatedMarketMakerPairs[to] && !isExcludedMaxTnxAmount[from]) {
                    require(amount <= maxTnxAmount, "TOKEN: Sell transfer amount exceeds the max Tnx amount.");
                }
            }
        }

        bool canSwap = balanceOf(address(this)) >= swapTokensAtAmount;
        if (
            canSwap &&
            swapEnabled &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            !isExcludedFromFees[from] &&
            !isExcludedFromFees[to]
        ) {
            swapping = true;
            swapBack();
            swapping = false;
        }

        bool takeFee = !swapping;

        if (isExcludedFromFees[from] || isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        if (takeFee) {
            if(automatedMarketMakerPairs[to] || automatedMarketMakerPairs[from]) {
                fees = amount.mul(taxFee).div(100);
            }
            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }
            amount -= fees;
        }
        super._transfer(from, to, amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
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

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        bool success;

        if (contractBalance == 0) {
            return;
        }

        if (contractBalance > swapTokensAtAmount * 20) {
            contractBalance = swapTokensAtAmount * 20;
        }

        swapTokensForEth(contractBalance);
        (success, ) = address(taxWallet).call{value: address(this).balance}("");
    }
}