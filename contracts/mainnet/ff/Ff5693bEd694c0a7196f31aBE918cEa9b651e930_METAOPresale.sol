/**
 *Submitted for verification at Etherscan.io on 2022-12-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface USDTETHToken {
    function transferFrom(address from, address to, uint value) external;
}
interface POLCToken {
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
}
interface IUniswap {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

contract METAOPresale {
  struct TXDetail {
    uint256 amount;
    address wallet;
    uint8 coin;
  }
  TXDetail[] txDetails;
  bool public paused;
  uint256 public maxAmount;
  uint256 sold;
  mapping(uint256=>bool) aAmounts;
  mapping(address=>uint256) public byWallet;
  address polcToken;
  address usdtToken;
  address wCoin;
  IUniswap uniswapRouter;
  uint256 price;
  address payable wallet;
  address[] polcRoute;
  address[] wRoute;
 mapping (address => bool) public managers;
 
  modifier onlyManagers() {
    require(managers[msg.sender] == true, "Caller is not manager");
    _;
  }

  constructor() {
    polcToken = 0xaA8330FB2B4D5D07ABFE7A72262752a8505C6B37;
    usdtToken = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    wCoin = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; 
    uniswapRouter = IUniswap(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    polcRoute.push(usdtToken);
    polcRoute.push(wCoin);
    polcRoute.push(polcToken);

    wRoute.push(usdtToken);
    wRoute.push(wCoin);

    paused = true;
    maxAmount = 200000;
    aAmounts[500] = true;
    aAmounts[1000] = true;
    aAmounts[5000] = true;
    aAmounts[10000] = true;
    price = 2 * 10**5;  
    wallet = payable(0x840588cc6426E0522E85591632E1a5B1fc6Efe29); 
    managers[msg.sender] = true;
  }

  function txCount() public view returns(uint256 count) {
    return txDetails.length;
  }

  function availableAmount() public view returns(uint256 _amount) {
    return(maxAmount - sold);
  }

  function getPrice(uint _amount, uint256 _coin) public view returns (uint256) {
    require(aAmounts[_amount] == true, "Invalid amount");
    return calcByCoin(_amount, _coin);
  }

  function calcByCoin(uint256 _amount, uint256 _coin) private view returns(uint256 _price) {
    if (_coin == 5) { return (_amount * price);}
    if (_coin == 2) {
      uint256[] memory r = uniswapRouter.getAmountsOut((_amount*price), polcRoute);
      return r[2];
    }
    if (_coin == 1) {
      uint256[] memory r = uniswapRouter.getAmountsOut((_amount*price), wRoute);
      return r[1];
    }
  
  }
  
  function calcMaxSlippage(uint256 _amount) private pure returns (uint256) {
    return (_amount - ((_amount) / 100));
  }

  function buyWithEth(uint256 _amount) public payable {
    require(!paused, "Contract is paused");
    require(sold + _amount <= maxAmount, "Amount not available");
    uint256 sPrice = getPrice(_amount, 1);
    require(msg.value >= (calcMaxSlippage(sPrice)), 'Invalid amount');
    wallet.transfer(msg.value);
    sold += _amount;
    txDetails.push(TXDetail(_amount, msg.sender, uint8(1)));
    byWallet[msg.sender] += _amount;
  }

  function buyWithTokens(uint256 _amount, uint256 _coin) public {
    require(!paused, "Contract is paused");
    require(sold + _amount <= maxAmount, "Amount not available");
    require(_coin == 5 || _coin == 2, "Invalid token");
    uint256 sPrice = getPrice(_amount, _coin);
    if (_coin == 5) {
      USDTETHToken token = USDTETHToken(usdtToken);
      token.transferFrom(msg.sender, wallet, sPrice);
    } else {
      POLCToken token = POLCToken(polcToken);
      require(token.transferFrom(msg.sender, wallet, sPrice));
    }
    sold += _amount;
    txDetails.push(TXDetail(_amount, msg.sender, uint8(_coin)));
    byWallet[msg.sender] += _amount;
  }

  function getTradeDetails(uint256 _id) public view returns(uint256 _amount, address _wallet, uint8 _coin) {
    return(txDetails[_id].amount, txDetails[_id].wallet, txDetails[_id].coin);
  }

  function setPause(bool _paused) public onlyManagers {
    paused = _paused;
  }

  function setMax(uint256 _max) public onlyManagers {
    maxAmount = _max;
  }
}