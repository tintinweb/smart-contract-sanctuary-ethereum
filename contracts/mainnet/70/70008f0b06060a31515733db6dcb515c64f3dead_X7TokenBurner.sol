/**
 *Submitted for verification at Etherscan.io on 2022-09-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/*

 /$$   /$$ /$$$$$$$$       /$$$$$$$$ /$$
| $$  / $$|_____ $$/      | $$_____/|__/
|  $$/ $$/     /$$/       | $$       /$$ /$$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$  /$$$$$$
 \  $$$$/     /$$/        | $$$$$   | $$| $$__  $$ |____  $$| $$__  $$ /$$_____/ /$$__  $$
  >$$  $$    /$$/         | $$__/   | $$| $$  \ $$  /$$$$$$$| $$  \ $$| $$      | $$$$$$$$
 /$$/\  $$  /$$/          | $$      | $$| $$  | $$ /$$__  $$| $$  | $$| $$      | $$_____/
| $$  \ $$ /$$/           | $$      | $$| $$  | $$|  $$$$$$$| $$  | $$|  $$$$$$$|  $$$$$$$
|__/  |__/|__/            |__/      |__/|__/  |__/ \_______/|__/  |__/ \_______/ \_______/

Contract: Smart Contract for burning tokens, X7TokenBurner

This contract will NOT be renounced.

The following are the only functions that can be called on the contract that affect the contract:

    function setRouter(address router_) external onlyOwner {
        router = IUniswapV2Router(router_);
        emit RouterSet(router_);
    }

    function setTargetToken(address targetToken_) external onlyOwner {
        targetToken = targetToken_;
        emit TargetTokenSet(targetToken_);
    }

These functions will be passed to DAO governance once the ecosystem stabilizes.

*/

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address owner_) {
        _transferOwnership(owner_);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IUniswapV2Router {
    function WETH() external pure returns (address);
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

interface IWETH {
    function withdraw(uint) external;
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract X7TokenBurner is Ownable {

    IUniswapV2Router public router;
    address public targetToken;

    event RouterSet(address indexed routerAddress);
    event TargetTokenSet(address indexed tokenAddress);
    event TokensBurned(address indexed tokenAddress, uint256 ETHAmount);

    constructor(address router_, address targetToken_) Ownable(address(0x7000a09c425ABf5173FF458dF1370C25d1C58105)) {
        targetToken = targetToken_;
        router = IUniswapV2Router(router_);
        emit RouterSet(router_);
        emit TargetTokenSet(targetToken_);
    }

    function setRouter(address router_) external onlyOwner {
        require(router_ != address(router));
        router = IUniswapV2Router(router_);
        emit RouterSet(router_);
    }

    function setTargetToken(address targetToken_) external onlyOwner {
        require(targetToken_ != targetToken);
        targetToken = targetToken_;
        emit TargetTokenSet(targetToken_);
    }

    receive() external payable {
        if (targetToken == address(0)) {
            return;
        }

        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = targetToken;

        uint256 purchaseAmount = address(this).balance;
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: purchaseAmount}(
            0,
            path,
            address(0x000000000000000000000000000000000000dEaD),
            block.timestamp
        );

        emit TokensBurned(targetToken, purchaseAmount);
    }

    function swapTokensForEth(address tokenAddress, uint256 tokenAmount) internal {
        require(tokenAmount > 0);

        address[] memory path = new address[](2);
        path[0] = tokenAddress;
        path[1] = router.WETH();

        IERC20(tokenAddress).approve(address(router), tokenAmount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function rescueTokens(address tokenAddress) external {
        swapTokensForEth(tokenAddress, IERC20(tokenAddress).balanceOf(address(this)));
    }

    function rescueWETH() external {
        address wethAddress = router.WETH();
        IWETH(wethAddress).withdraw(IERC20(wethAddress).balanceOf(address(this)));
    }
}