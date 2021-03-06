// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import { PaymentSplitter, ERC721, Ownable, ProxyRegistry } from './OpenZeppelinDependencies.sol';

contract NothingBurger is ERC721, Ownable {
  uint public constant START_PRICE = 0.1 ether;

  uint public constant END_PRICE = 0.1 ether;

  uint public startTime;

  uint public immutable DURATION;

  uint public immutable PRICE_PER_SECOND;

  uint public constant MAX_SUPPLY = 10_000;

  uint public constant MAX_MINT_AMOUNT = 10;

  uint public ownerMintsRemaining = 0;

  string private _contractURI = "";

  string public baseURI = "";

  address public immutable proxyRegistryAddress;

  uint public constant decimals = 0;

  uint public totalSupply = 0;

  event Log(address indexed to, uint price, uint amount, uint cost, uint sent, uint change);

  constructor(
    uint durationInHours,
    address _proxyRegistryAddress,
    address _Burger
    
  ) ERC721('NothingBurger', 'BURGER')
 {
    DURATION = durationInHours * 60 * 60;
    PRICE_PER_SECOND = (START_PRICE - END_PRICE) / (durationInHours * 60 * 60);
    proxyRegistryAddress = _proxyRegistryAddress;
    Burger = _Burger;
  }

  /**
   * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
   */
  function isApprovedForAll(address owner, address operator) public view override(ERC721) returns (bool) {

      ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);

      // Whitelist OpenSea proxy contract for easy trading.
      if (proxyRegistry.proxies(owner) == operator) {
          return true;
      }
      return super.isApprovedForAll(owner, operator);
  }

  function start() public onlyOwner {
    require(startTime == 0, 'Already started');
    startTime = block.timestamp;
  }

  /// @notice Reserved for owner to mint
  function ownerMint(address to, uint amount) public onlyOwner {

    uint mintsRemaining = ownerMintsRemaining;

    /// @notice Owner mints cannot be minted after the maximum has been reached
    require(mintsRemaining > 0, "Max owner mint limit reached");

    if (amount > mintsRemaining){
      amount = mintsRemaining;
    }

    uint currentTotalSupply = totalSupply;

    _mintAmountTo(to, amount, currentTotalSupply);

    ownerMintsRemaining = mintsRemaining - amount;

    totalSupply = currentTotalSupply + amount;
  }

  /// @notice Batch owner minting
  function batchOwnerMint(address[] calldata addresses, uint[] calldata amounts) public onlyOwner {
    require(addresses.length == amounts.length, "batch length mismatch");

    for (uint i=0; i<addresses.length; i++){
      ownerMint(addresses[i], amounts[i]);
    }
  }

  /// @notice Public mints
  function mint(uint amount) public payable {


    /// @notice public can mint a maximum quantity at a time.
    require(amount <= MAX_MINT_AMOUNT, 'mint amount exceeds maximum');

    uint currentTotalSupply = totalSupply;

    /// @notice Cannot exceed maximum supply
    require(currentTotalSupply+amount+ownerMintsRemaining <= MAX_SUPPLY, "Not enough mints remaining");

    uint price = priceAtTime(block.timestamp);

    uint cost = amount * price;

    /// @notice public must send in correct funds
    require(msg.value > 0 && msg.value >= cost, "Not enough value sent");

    if (msg.value > cost){
      uint change = msg.value - cost;
      (bool success, ) = msg.sender.call{value: change}("");
      require(success, "Change send unsuccessful");
      emit Log(msg.sender, price, amount, cost, msg.value, change);
    } else {
      emit Log(msg.sender, price, amount, cost, msg.value, 0);
    }

    _mintAmountTo(msg.sender, amount, currentTotalSupply);

    totalSupply = currentTotalSupply + amount;
  }

  function _mintAmountTo(address to, uint amount, uint startId) internal {
    for (uint i = 1; i<=amount; i++){
      _mint(to, startId+i);
    }
  }

  function setBaseURI(string memory newBaseURI) external onlyOwner {
    baseURI = newBaseURI;
  }

  function _baseURI() internal override view returns (string memory){
    return baseURI;
  }

  function setContractURI(string memory newContractURI) external onlyOwner {
    _contractURI = newContractURI;
  }

  function contractURI() external view returns (string memory){
    return _contractURI;
  }

  function currentPrice() public view returns (uint){
    return priceAtTime(block.timestamp);
  }

  function priceAtTime(uint time) public view returns (uint){
    uint _startTime = startTime;

    if (_startTime == 0 || time <= _startTime) return START_PRICE;

    if (time >= _startTime + DURATION) return END_PRICE;

    /// @notice Calculate the price decrease since start and subtract it from the starting price
    return START_PRICE - (PRICE_PER_SECOND * (time - _startTime));
  }

  function endTime() public view returns (uint){
    if (startTime == 0) return 0;
    return startTime + DURATION;
  }

     function withdraw() public  {
        (bool success, ) = Burger.call{value: address(this).balance}("");
        require(success, "Failed to send to Burger.");
    } 

  function details() public view returns(uint _startTime, uint _endTime, uint _duration, uint _startPrice, uint _endPrice, uint _priceSecond, uint _priceAtBlock, uint _blockTimestamp){
    return (startTime, endTime(), DURATION, START_PRICE, END_PRICE, PRICE_PER_SECOND, priceAtTime(block.timestamp), block.timestamp);
  }


    address public              Burger;

}