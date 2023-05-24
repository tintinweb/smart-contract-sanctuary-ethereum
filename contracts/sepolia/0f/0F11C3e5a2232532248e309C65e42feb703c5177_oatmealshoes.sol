// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

// put twitter here
// put web here
// put other tomfoolery here 

import "./ERC20.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract oatmealshoes is Ownable, Pausable, ERC20 {

  uint256 private constant  TOTAL_SUPPLY    = 1_200_000_000 ether;
  uint256 private constant  LIQUIDITY       = 900_000_000 ether;
  uint256 private constant  TEAM            = 100_000_000 ether;
  uint256 private constant  CLAIMS          = 200_000_000 ether;
  uint256 public constant   MAX_BUY         = 100_000 ether;
  uint256 public constant   DEADBLOCK_COUNT = 3;

  mapping(address => bool) private whitelist;
  mapping(address => bool) private aPool;
  mapping(address => uint) private _lastBlockTransfer;

  uint256 public deadblockStart;
  bool private _blockContracts;
  bool private _limitBuys;
  bool private _unrestricted;

  event liqPoolSet(address);

  /** errors */
  error NoZeroTransfers();
  error LimitExceeded();
  error NotAllowed();
  error ContractPaused();
  error uhohnonoworky();

  constructor(
      address oatmeal // pass an adress to WL
      ) 
      ERC20("oatmealshoes", "oat") Ownable() {
    whitelist[oatmeal] = true; //can whitelist any wallet - testing and that (currently is the wallet passed above)
    _transferOwnership(0xA7702a59E479BF6EF7b26d1b31d1835B1B0aB996); //oatmealshoes.eth for purely testing - should be the multi sig
    if (TEAM + LIQUIDITY + CLAIMS != TOTAL_SUPPLY) { revert uhohnonoworky(); }

    _mint(owner(), LIQUIDITY);
    _mint(msg.sender, TEAM); //this is up to change - should go to a wallet that disperses to every team member
    // there will be supply left to be minted/claimed which will go "unused" here

    _blockContracts = true;
    _limitBuys = true;

    _pause();
  }

  // following things are the fancy things to make contract cool 

  /** WL addy 
  * true or false
  * rmb to revoke (false the addy) after neccessary changes 
  */
  function setAddressToWhiteList(address _address, bool _allow) external onlyOwner {
    whitelist[_address] = _allow;
  }

  /** blocks contracts
  * true or false
  */
  function setBlockContracts(bool _val) external onlyOwner {
    _blockContracts = _val;
  }

  /** limit buys 
  * true or false
  */
  function setLimitBuys(bool _val) external onlyOwner {
    _limitBuys = _val;
  }

  /** make it cool :) */
  function byebyeOwner() external onlyOwner {
    _unrestricted = true;
    renounceOwnership();
  }
  
  /** sets the liquidity pool - neccesary for the sanwhich protection 
  * should be the v2 uniswap pool
  */
  function setAPool(address[] calldata _val) external onlyOwner {
    for (uint256 i = 0; i < _val.length; i++) {
      address _pool = _val[i];
      aPool[_pool] = true;
      emit liqPoolSet(address(_pool));
    }
  }

  /** pause */
  function pause() external onlyOwner {
    _pause();
  }

  /** unpause */
  function unpause() external onlyOwner {
    deadblockStart = block.number;
    _unpause();
  }

  /** checks if adress is a contract*/
  function _contractScary(address _address) internal view returns (bool) {
    uint32 size;
    assembly {
        size := extcodesize(_address)
    }
    return (size > 0);
  }

  /** checks for bot activities or is a contract */
  function _botScary(address _address) internal view returns (bool) {
    return (block.number < DEADBLOCK_COUNT + deadblockStart || _contractScary(_address)) && !whitelist[_address];
  }

  /** sandwhich protectoor */
  function _beforeTokenTransfer(address sender, address recipient, uint256 amount) internal override {
    if (amount == 0) 
    { revert NoZeroTransfers(); }
    super._beforeTokenTransfer(sender, recipient, amount);

    if (_unrestricted) { return; }
    if (paused() && !whitelist[sender]) 
    { revert ContractPaused(); }

    if (block.number == _lastBlockTransfer[sender] || block.number == _lastBlockTransfer[recipient]) {
      revert NotAllowed();
    }

    bool isBuy = aPool[sender];
    bool isSell = aPool[recipient];

    if (isBuy) {
      if (_blockContracts && _botScary(recipient)) { revert NotAllowed(); }
      if (_limitBuys && amount > MAX_BUY) { revert LimitExceeded(); }
      _lastBlockTransfer[recipient] = block.number;
    } else if (isSell) {
      _lastBlockTransfer[sender] = block.number;
    }
  }
}