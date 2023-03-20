// contracts/Tametori.sol
// SPDX-License-Identifier: MIT
// 100%safu TametorisVision contracts


pragma solidity 0.8.0;
import "ERC20.sol";
import "Address.sol";

contract Tametori is ERC20 {

  mapping(address => uint256) private _blockNumberByAddress;

  uint256 private _initialSupply = 1000000000000000000000000000000000;//  80% for initial liquidity, 15% for CEX listing, Tokens to be sent to marketing wallet 5% of total supply
  address private _shibaBurnAddress;
  address private _rewardsAddress;
  uint256 private _burnRate;

  constructor() ERC20("Tametori", "TAM") {
    _rewardsAddress = address(0x113070981b0DE91E4b83ED6aDE817633a25e5221);
    _shibaBurnAddress = address(0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE);
    _mint(msg.sender, _initialSupply);
    _burnRate = 100;
  }

  function burnAddress() public view override returns (address) {
    return _shibaBurnAddress;
  }

  function burnRate() public view returns (uint256) {
    return _burnRate;
  }

  function transfer(address _to, uint256 _value) public virtual override returns (bool) {
    address _from = _msgSender();
    address human = ensureOneHuman(_from, _to);
    ensureOneTxPerBlock(human);

    uint256 toBurnAndToShare = _value / _burnRate;

    if (ERC20.transfer(_to, _value - (2 * toBurnAndToShare))) {
      _burn(_msgSender(), toBurnAndToShare);
      ERC20.transfer(_rewardsAddress, toBurnAndToShare);
      _blockNumberByAddress[human] = block.number;
      return true;
    } else return false;
  }

  function lastTxFrom(address _from) public view returns (uint256) {
    return  _blockNumberByAddress[_from];
  }

  function ensureOneHuman(address _to, address _from) internal virtual returns (address) {
    require(!Address.isContract(_to) || !Address.isContract(_from), 'Tametori says: No bots allowed!');
    if (Address.isContract(_to)) return _from;
    else return _to;
  }

  function ensureOneTxPerBlock(address addr) internal virtual {
    bool isNewBlock = _blockNumberByAddress[addr] == 0 ||
      _blockNumberByAddress[addr] < block.number;

    require(isNewBlock, 'Tametori says: Only one transaction per block!');
  }

  function transferFrom(address _from, address _to, uint256 _value) public virtual override returns (bool) {
    address human = ensureOneHuman(_from, _to);
    ensureOneTxPerBlock(human);

    uint256 toBurnAndToShare = _value / _burnRate;

    if (ERC20.transferFrom(_from, _to, _value - (2 * toBurnAndToShare))) {
      _burn(_from, toBurnAndToShare);
      ERC20.transferFrom(_from, _rewardsAddress, toBurnAndToShare);
      _blockNumberByAddress[human] = block.number;
      return true;
    } else return false; 
  }
}