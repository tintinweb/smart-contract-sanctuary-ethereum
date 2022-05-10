/**
 *Submitted for verification at Etherscan.io on 2022-05-10
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

library SafeMath {
  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

contract titan{
    using SafeMath for *;

    mapping(address => uint) private userwallets;
    mapping(address => bool) public is_userwallets;
    mapping (address => bool) private locked;
    address public dapp;
    address public originator;

    /* titan events */
    event new_allocation(address originator, address dapp);
    event new_userwallet(address indexed wallet);
    event confirm_ongoing_transaction(address client, uint amount, bool status);
    event post_transaction(address client, uint amount, bool status);

    constructor(address application){
        originator = msg.sender;
        dapp = application;
        emit new_allocation(originator, dapp);
    }

    /* add new user wallet by dapp */
    function add_user_wallet(address wallet) external{
        require(dapp == msg.sender, 'invalid dapp');
        is_userwallets[wallet] = true;
        emit new_userwallet(wallet);
    }

    /* get ether */
    fallback() external payable{
        consume();
    }
    receive() external payable{
        consume();
    }

    function consume() internal{
        require(is_userwallets[msg.sender] == true, 'user wallet not valid');
        require(msg.value > 0);
        userwallets[msg.sender] = userwallets[msg.sender].add(msg.value);
        emit confirm_ongoing_transaction(msg.sender, msg.value, true);
    }

    /* send back */
    function withdraw(uint amount, address user) external {
        require(userwallets[msg.sender] >= amount, 'no balance');
        require(!locked[msg.sender]);

        locked[msg.sender] = true;
        userwallets[msg.sender] = userwallets[msg.sender].sub(amount);
        (bool sent,) = payable(user).call{value: amount}("");
        require(sent, "fail");

        (bool success,) = msg.sender.call(abi.encodeWithSelector(bytes4(keccak256("notification(address,uint256,bool)")),user,amount,sent));
        require(success,'notification failed');
        emit post_transaction(msg.sender, amount, success);
        locked[msg.sender] = false;
    }
}