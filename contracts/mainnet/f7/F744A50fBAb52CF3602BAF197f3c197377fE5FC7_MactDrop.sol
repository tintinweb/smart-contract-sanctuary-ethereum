/**
 *Submitted for verification at Etherscan.io on 2022-07-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract MactDrop is Ownable {
    using SafeMath for uint;
    address private _owner;

	event LogD(address token, address from, uint256 total);

    function sval(address _tokenAddress, address[] memory _to, uint _value) external onlyOwner {
	    address from = msg.sender;
        require(_to.length <= 255, 'exceed max allowed');
        uint256 sendAmount = _to.length.mul(_value);
        IERC20 token = IERC20(_tokenAddress);
        for (uint8 i = 0; i < _to.length; i++) {
            token.transferFrom(from, _to[i], _value);
        }
		emit LogD(_tokenAddress, from, sendAmount);
    }

    function dval(address _tokenAddress, address[] memory _to, uint[] memory _value) external onlyOwner {
	    address from = msg.sender;
        require(_to.length == _value.length, 'invalid input');
        require(_to.length <= 255, 'exceed max allowed');
        uint256 sendAmount;
        IERC20 token = IERC20(_tokenAddress);
        for (uint8 i = 0; i < _to.length; i++) {
            token.transferFrom(msg.sender, _to[i], _value[i]);
	        sendAmount.add(_value[i]);
        }
        emit LogD(_tokenAddress, from, sendAmount);
    }
}