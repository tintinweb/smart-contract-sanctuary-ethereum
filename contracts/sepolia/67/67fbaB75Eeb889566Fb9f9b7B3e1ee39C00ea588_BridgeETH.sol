// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import './bridgeBase.sol';

contract BridgeETH is BridgeBase {
  constructor(address token) BridgeBase(token) {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import './Itoken.sol';

contract BridgeBase {
  address public admin;
  IToken public token;
  uint public nonce;
  mapping(uint => bool) public processedNonces;

  enum Step { Burn, Mint }
  event Transfer(
    address from,
    address to,
    uint amount,
    uint date,
    uint nonce,
    Step indexed step
  );

  constructor(address _token) {
    admin = msg.sender;
    token = IToken(_token);
  }

  function burn(address to, uint amount) external {
    require(to != address(0),'Invalid to address');
    require(amount > 0,'Invalid amount');

    token.burn(msg.sender, amount);

    emit Transfer(
      msg.sender,
      to,
      amount,
      block.timestamp,
      nonce,
      Step.Burn
    );

    nonce++;
  }

  function mint(address to, uint amount, uint otherChainNonce) external {
    require(msg.sender == admin, 'only admin');
    require(processedNonces[otherChainNonce] == false, 'transfer already processed');

    processedNonces[otherChainNonce] = true;
    
    token.mint(to, amount);
    
    emit Transfer(
      msg.sender,
      to,
      amount,
      block.timestamp,
      otherChainNonce,
      Step.Mint
    );
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IToken {
  function mint(address to, uint amount) external;
  function burn(address owner, uint amount) external;
}