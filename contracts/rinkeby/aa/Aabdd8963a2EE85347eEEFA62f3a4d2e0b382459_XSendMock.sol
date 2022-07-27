// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./interfaces/IXProviderMock.sol";

contract XSendMock {
    address public xprovider; // ConnextXProviderMock
    
    constructor(
        address _xprovider
    ){
        xprovider = _xprovider;
    }

    function xSendSomeValue(uint256 _value) external { // should later on be changed to onlyDao/ onlyKeeper
        IXProviderMock(xprovider).xSend(_value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IXProviderMock {
  // interface should be standard, we'll get a diffrent implementation per cross chain technology provider
  // the function signatures below should be changed in the different core functionalities we would like to implement cross chain
  // E.g. getTotalunderlying
  function xSend(uint256 _value) external; // sending a (permissioned) value crosschain.
  // function xSendCallback() external; // sending a (permissioned) vaule crosschain and receive a callback to a specified address. 
  function xReceive(uint256 _value) external; // receiving a (permissioned) value crosschain.
  // function xReceiveCallback() external; // receiving a (permissioned) value crosschain where a callback was expected.
  // function xTransferFunds() external; // transfer funds crosschain.
  // function xReceiveFunds() external; // receive funds crosschain, maybe unnecessary.
  // function setXController() external;
  // function setGame() external;
}