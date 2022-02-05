// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ERC721Connecter.sol';

contract Kryptobird is ERC721Connecter {

  constructor() ERC721Connecter('KryptoBird', 'KBIRDZ') {}

  string[] public kryptoBirdz;
  mapping (string => bool) _kryptoBirdzExists;

  function mint(string memory _kryptoBird) public {
    require(!_kryptoBirdzExists[_kryptoBird], 'KryptoBird already exists!');
    kryptoBirdz.push(_kryptoBird);
    uint256 _id = kryptoBirdz.length -1;

    _mint(msg.sender, _id);
    _kryptoBirdzExists[_kryptoBird] = true;
  }

}