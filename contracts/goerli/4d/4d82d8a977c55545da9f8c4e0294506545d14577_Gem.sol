// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

import "./Uniswap.sol";
import "./ERC20.sol";

contract Gem is ERC20 {
    using SafeMath for uint256;

    uint256 public maxSupply = 1000000 * 10**18;

    IUniswapV2Router02 public immutable uniswapV2Router;
    mapping(address => bool) public ammPairs;
    bool public isSellEnabled;
    bool public isBuyEnabled;
    constructor() {
        _initialize("GEM", "GEM", 18, maxSupply);
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        ammPairs[_uniswapV2Pair] = true;
        isSellEnabled = false;
        isBuyEnabled = false;
    }

    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    function mint(address receiver, uint256 amount) external onlyOwner {
        _mint(receiver, amount);
    }

     function changeBuySell(bool _buy, bool _sell) external onlyOwner {
        isBuyEnabled = _buy;
        isSellEnabled = _sell;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        bool isBuy = ammPairs[sender];
        bool isSell = ammPairs[recipient];
        if(isBuy) {
            require(isBuyEnabled, "swap buy not enabled");
        }
        if(isSell) {
            require(isSellEnabled, "swap sell not enabled");
        }

        super._transfer(sender, recipient, amount);
    }

    // receive eth from uniswap swap
    receive() external payable {}
}