// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./IERC20.sol";

contract ScorpionYachtClub is ERC1155, Ownable {
    
  string public name;
  string public symbol;
  uint256 public totalSupply = 0;
  uint256 public maxSupplyNYGold = 50;
  uint256 public maxSupplyNYSilver = 2000;
  uint256 public goldNYPrice = 4500 ether;
  uint256 public silverNYPrice = 180 ether;
  bool public paused = false;
  IERC20 public USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);

  mapping(uint => string) public tokenURI;

  constructor(
    string memory _goldNYURI,
    string memory _silverNYURI,
    address USDTcontract
    ) ERC1155("") {
    name = "ScorpionYachtClub";
    symbol = "SYC";
    setURI(1, _goldNYURI);
    setURI(2, _silverNYURI);
    USDT = IERC20(USDTcontract);
  }

  function mintNYGold(address _to, uint256 _amount) public payable {
    require(totalSupply + _amount <= maxSupplyNYGold && _amount > 0);

    if(msg.sender != owner()) {
      require(!paused);
      require(msg.sender == _to);
      USDT.transferFrom(msg.sender, address(this), goldNYPrice);
    }

    _mint(_to, 1, _amount, "");
    totalSupply += _amount;
  }

  function mintNYSilver(address _to, uint256 _amount) public payable {
    require(totalSupply + _amount <= maxSupplyNYSilver && _amount > 0);

    if(msg.sender != owner()) {
      require(!paused);
      require(msg.sender == _to);
      USDT.transferFrom(msg.sender, address(this), silverNYPrice);
    }

    _mint(_to, 1, _amount, "");
    totalSupply += _amount;
  }

  function burn(address account, uint256 _amount) public virtual {
    require(
      account == _msgSender() || isApprovedForAll(account, _msgSender()),
      "ERC1155: caller is not owner nor approved"
    );
    _burn(account, 1, _amount);
    totalSupply -= _amount;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }

  function setGoldNYPrice(uint256 _price) public onlyOwner {
    goldNYPrice = _price;
  }

  function setMaxSupplyNYGold(uint256 _maxSupply) public onlyOwner {
    maxSupplyNYGold = _maxSupply;
  }

  function setSilverNYPrice(uint256 _price) public onlyOwner {
    silverNYPrice = _price;
  }

  function setMaxSupplyNYSilver(uint256 _maxSupply) public onlyOwner {
    maxSupplyNYSilver = _maxSupply;
  }

  function setURI(uint _id, string memory _uri) public onlyOwner {
    tokenURI[_id] = _uri;
    emit URI(_uri, _id);
  }

  function uri(uint _id) public override view returns (string memory) {
    return tokenURI[_id];
  }
}