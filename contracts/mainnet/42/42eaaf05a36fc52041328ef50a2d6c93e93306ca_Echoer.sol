/**
 *Submitted for verification at Etherscan.io on 2022-11-28
*/

// SPDX-License-Identifier: MIT
// https://www.tornadocash2.com  http://tornadoccyk5y3yn.onion
/*
888888  dP"Yb  88""Yb 88b 88    db    8888b.   dP"Yb       dP""b8    db    .dP"Y8 88  88     Yb    dP oP"Yb. 
  88   dP   Yb 88__dP 88Yb88   dPYb    8I  Yb dP   Yb     dP   `"   dPYb   `Ybo." 88  88      Yb  dP  "' dP' 
  88   Yb   dP 88"Yb  88 Y88  dP__Yb   8I  dY Yb   dP     Yb       dP__Yb  o.`Y8b 888888       YbdP     dP'  
  88    YbodP  88  Yb 88  Y8 dP""""Yb 8888Y"   YbodP       YboodP dP""""Yb 8bodP' 88  88        YP    .d8888 
*/
pragma solidity ^0.6.0;

contract Echoer {
  event Echo(address indexed who, bytes data);

  function echo(bytes calldata _data) external {
    emit Echo(msg.sender, _data);
  }
}