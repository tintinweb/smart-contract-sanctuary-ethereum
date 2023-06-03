// SPDX-License-Identifier: MIT
/* 
    在上述代码中，添加了以下功能：

    marketingWallet：营销钱包的地址，税收将进入此地址。
    taxPercentage：卖出税收的百分比，以整数表示。
    taxDuration：两次交易之间需要经过的最小时间间隔，单位为秒。
    Trade 结构体：用于存储每个地址的最后一次交易的时间戳。
    TaxApplied 事件：在收取税收时触发的事件。

    修改的部分包括：

    构造函数中添加了对营销钱包地址、税收百分比和税收时间间隔的初始化。
    buy 函数中将代币直接转移给买入地址，并记录最后一次交易时间戳。
    sell 函数中，在卖出前检查是否满足税收时间间隔要求。如果满足要求，计算税收金额并转移税收给营销钱包。然后执行代币转移和记录最后一次交易时间戳的操作。
    calculateTax 函数根据两次交易的时间间隔计算税收金额。 
*/

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract MyToken is ERC20, Ownable {
    using SafeMath for uint256;

    address public marketingWallet = 0x1B9f3d4211a9747F557B8dfe5Eb81596B8CAb3A7 ;
    uint256 public taxPercentage = 99;
    uint256 public taxDuration = 5;

    struct Trade {
        uint256 timestamp;
    }

    mapping(address => Trade) public lastTrade;

    event TaxApplied(address indexed trader, uint256 taxAmount);

    constructor(/* address _marketingWallet, uint256 _taxPercentage, uint256 _taxDuration */)
        ERC20("My Token", "MTK")
    {
/*         marketingWallet = _marketingWallet;
        taxPercentage = _taxPercentage;
        taxDuration = _taxDuration; */
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }

    function setMarketingWallet(address _marketingWallet) external onlyOwner {
        marketingWallet = _marketingWallet;
    }

    function setTaxPercentage(uint256 _taxPercentage) external onlyOwner {
        require(_taxPercentage <= 100, "Tax percentage must be between 0 and 100");
        taxPercentage = _taxPercentage;
    }

    function setTaxDuration(uint256 _taxDuration) external onlyOwner {
        taxDuration = _taxDuration;
    }

    function buy(uint256 amount) external {
        _transfer(address(this), msg.sender, amount);
        lastTrade[msg.sender] = Trade(block.timestamp);
    }

    function sell(uint256 amount) external {
        require(lastTrade[msg.sender].timestamp.add(taxDuration) <= block.timestamp, "Tax duration has not elapsed");

        uint256 taxAmount = calculateTax(amount);
        if (taxAmount > 0) {
            _transfer(msg.sender, marketingWallet, taxAmount);
            emit TaxApplied(msg.sender, taxAmount);
        }

        _transfer(msg.sender, address(this), amount);
        lastTrade[msg.sender] = Trade(block.timestamp);
    }

    function calculateTax(uint256 amount) internal view returns (uint256) {
        uint256 timeSinceLastTrade = block.timestamp.sub(lastTrade[msg.sender].timestamp);
        uint256 taxAmount = 0;

        if (timeSinceLastTrade < 5 seconds) {
            taxAmount = amount.mul(taxPercentage).div(100);
        }

        return taxAmount;
    }
}