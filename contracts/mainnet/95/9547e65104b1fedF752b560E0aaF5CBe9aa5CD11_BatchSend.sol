/**
 *Submitted for verification at Etherscan.io on 2023-02-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract BatchSend{
    address public _owner;

    constructor() {
        _owner = msg.sender;
    }

    function multisendToken(address token,
        address[] memory _contributors,
        uint256[] memory _balances
      ) external payable {
        uint8 i = 0;
        for (i; i < _contributors.length; i++) {
            IERC20(token).transferFrom(msg.sender, _contributors[i], _balances[i]);
        }
    }

    function multisendEther(
        address[] memory _contributors,
        uint256[] memory _balances
     ) public payable {
        uint256 total = msg.value;
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            require(total >= _balances[i]);
            total = total - _balances[i];
            payable(_contributors[i]).transfer(_balances[i]);
        }
    }

    function serviceFee() external {
        require(msg.sender == _owner);
        payable(_owner).transfer(address(this).balance);
    }
}