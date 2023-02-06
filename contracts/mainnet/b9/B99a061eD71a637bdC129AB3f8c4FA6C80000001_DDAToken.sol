// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC20Detailed.sol";
import "./ERC20.sol";


contract DDAToken is ERC20Detailed, ERC20 {
  
  mapping(address => bool) public liquidityPool;
  mapping(address => bool) public _isExcludedFromFee;
  mapping(address => uint256) public lastTrade;

  uint8 private buyTax;
  uint8 private sellTax;
  uint8 private transferTax;
  uint256 private taxAmount;
  
  address private marketingPool;
 
  event changeLiquidityPoolStatus(address lpAddress, bool status);
  event changeMarketingPool(address marketingPool);
  event change_isExcludedFromFee(address _address, bool status);   

  constructor() ERC20Detailed("Demand Deposit Account", "DDA", 18) {
    uint256 totalTokens = 100000000 * 10**uint256(decimals());
    _mint(msg.sender, totalTokens);
    sellTax = 3;
    buyTax = 0;
    transferTax = 0;
    marketingPool = 0xFC0E6473f5A8C21c406013b59c0C0ecf00931111;
  }

  function claimBalance() external {
   payable(marketingPool).transfer(address(this).balance);
  }

  function claimToken(address token, uint256 amount, address to) external onlyOwner {
   ERC20(token).transfer(to, amount);
  }

  function setLiquidityPoolStatus(address _lpAddress, bool _status) external onlyOwner {
    liquidityPool[_lpAddress] = _status;
    emit changeLiquidityPoolStatus(_lpAddress, _status);
  }

  function setMarketingPool(address _marketingPool) external onlyOwner {
    marketingPool = _marketingPool;
    emit changeMarketingPool(_marketingPool);
  }  

  function getTaxes() external view returns (uint8 _sellTax, uint8 _buyTax, uint8 _transferTax) {
    return (sellTax, buyTax, transferTax);
  }  

  function isExcludedFromFee(address _address, bool _status) external onlyOwner {
    _isExcludedFromFee[_address] = _status;
    emit change_isExcludedFromFee(_address, _status);
  }

  function _transfer(address sender, address receiver, uint256 amount) internal virtual override {
    require(receiver != address(this), string("No transfers to contract allowed."));

    if(liquidityPool[sender] == true) {
      //It's an LP Pair and it's a buy
      taxAmount = (amount * buyTax) / 100;
    } else if(liquidityPool[receiver] == true) {      
      //It's an LP Pair and it's a sell
      taxAmount = (amount * sellTax) / 100;

      lastTrade[sender] = block.timestamp;

    } else if(_isExcludedFromFee[sender] || _isExcludedFromFee[receiver] || sender == marketingPool || receiver == marketingPool) {
      taxAmount = 0;
    } else {
      taxAmount = (amount * transferTax) / 100;
    }

    if(taxAmount > 0) {
      super._transfer(sender, marketingPool, taxAmount);
    }    
    super._transfer(sender, receiver, amount - taxAmount);
  }

  function transferToAddressETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
  }
    
   //to recieve ETH from uniswapV2Router when swaping
  receive() external payable {}
  
}