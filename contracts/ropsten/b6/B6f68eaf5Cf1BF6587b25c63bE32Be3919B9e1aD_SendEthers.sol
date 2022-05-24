// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;


import './IsendEth.sol';

contract SendEthers is ISendEth {
    
    function sendEther( address payable _addrs) external override payable{
        _addrs.transfer(msg.value);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface ISendEth {
    function sendEther( address payable _addrs) external payable;
}