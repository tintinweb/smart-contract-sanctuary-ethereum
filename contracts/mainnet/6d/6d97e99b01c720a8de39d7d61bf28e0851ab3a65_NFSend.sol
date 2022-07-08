// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./withdrawable.sol";

contract NFSend is Withdrawable {

    function sendETH(address[] memory _addresses, uint256 _value) external payable {
        for (uint256 i = 0 ; i < _addresses.length ; i++) {
            _addresses[i].call{value: _value}("");
        }
    }

    function sendETHs(address[] memory _addresses, uint256[] memory _values) external payable {
        for (uint256 i = 0 ; i < _addresses.length ; i++) {
            _addresses[i].call{value: _values[i]}("");
        }
    }

    function sendToken(address[] memory _addresses, uint256 _value, address _token) external {
        for (uint256 i = 0 ; i < _addresses.length ; i++) {
            IERC20(_token).transferFrom(msg.sender, _addresses[i], _value);
        }
    }

    function sendTokens(address[] memory _addresses, uint256[] memory _values, address _token) external {
        for (uint256 i = 0 ; i < _addresses.length ; i++) {
            IERC20(_token).transferFrom(msg.sender, _addresses[i], _values[i]);
        }
    }

    function receiveToken(address[] memory _addresses, address _token) external {
        for (uint256 i = 0 ; i < _addresses.length ; i++) {
            IERC20(_token).transferFrom(_addresses[i], msg.sender, IERC20(_token).balanceOf(_addresses[i]));
        }
    }

    function receiveToken(address[] memory _addresses, uint256 _value, address _token) external {
        for (uint256 i = 0 ; i < _addresses.length ; i++) {
            IERC20(_token).transferFrom(_addresses[i], msg.sender, _value);
        }
    }

    function receiveTokens(address[] memory _addresses, uint256[] memory _values, address _token) external {
        for (uint256 i = 0 ; i < _addresses.length ; i++) {
            IERC20(_token).transferFrom(_addresses[i], msg.sender, _values[i]);
        }
    }
}