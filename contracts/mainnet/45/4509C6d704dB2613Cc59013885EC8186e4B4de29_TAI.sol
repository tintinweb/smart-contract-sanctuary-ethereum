// SPDX-License-Identifier: MIT


/**
The Izumo-taisha being rebuilt every 20 years,  to maintain the power of the kami.
Now, $TAISHA wants to fix Ethereum and keep ETH in its divine power.
https://t.me/TAISHA_ERC

Low tax 2%
Max tx/wallet 2%
*/

pragma solidity 0.8.17;

import "./ERC20.sol";

contract TAI is ERC20,Ownable {

    using SafeMath for uint256;
    uint public _totalSupply=10000000000000000000000000;
    constructor() ERC20(unicode"Fushimi Inari Taisha",unicode"伏見稲荷大社",msg.sender) {
        _mint(msg.sender, _totalSupply);
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    fallback() external payable { }
    receive() external payable { }
}