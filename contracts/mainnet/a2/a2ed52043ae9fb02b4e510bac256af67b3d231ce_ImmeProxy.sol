// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

interface IERC20 {
    function balanceOf(address owner) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract ImmeProxy {

    using SafeMath for uint;
     
    address public owner;
    address payable public taxWallet;
    uint256 total;

    constructor() {
        owner = msg.sender;
        taxWallet = payable(0xa891b69138FCafc2c15a82A186373B5a6882D5F6);
    }

    function secureSendEther(address payable _to, uint256 _amount, uint256 _fee) external payable {
        require(msg.sender.balance >= ((_amount).add(_fee)), "Address: insufficient balance for call");
        (bool success,) = _to.call{value: _amount}("");
        if (success) {
            (bool successFee,) = taxWallet.call{value: _fee}("");
            require(successFee, "Failed to send Ether");
        }
        require(success, "Failed to send Ether");
    }

    function secureSendToken(address tokenAddress, address payable _to, uint256 _value) external payable{
        require(msg.sender.balance >= msg.value, "Address: insufficient Eth balance for call");
        (bool successFee,) = taxWallet.call{value: msg.value}("");
        require(successFee, "Failed to send Ether");

        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(msg.sender) >= _value, "Address: insufficient token balance for call");
        require(token.transferFrom(msg.sender, address(this), _value));
        require(token.transfer(_to, _value));
        
    }
}