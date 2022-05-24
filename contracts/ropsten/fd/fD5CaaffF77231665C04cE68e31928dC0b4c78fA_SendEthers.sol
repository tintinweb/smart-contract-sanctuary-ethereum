// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;


import './IsendEth.sol';

contract SendEthers is ISendEth {
    
    function sendEther( address payable _addrs , uint256  _amt) external override payable{
        _addrs.transfer(_amt);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

interface ISendEth {
    function sendEther(address payable _addrs , uint256 _amt) external payable;
}