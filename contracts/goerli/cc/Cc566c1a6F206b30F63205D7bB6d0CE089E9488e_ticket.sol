/**
 *Submitted for verification at Etherscan.io on 2022-07-22
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

contract ticket {
    
    mapping (address => uint256) public ticketHolders;

    function buyTickets(address  _user, uint256 _amount) public {
        addTickets(_user, _amount);
    }

    function useTickets(address  _user, uint256 _amount) public {
        subTickets(_user, _amount);
    }

    function addTickets(address _user, uint256 _amount) internal{
        ticketHolders[_user] = ticketHolders[_user] + _amount;

    }
    function subTickets(address _user, uint256 _amount) internal{
        require(ticketHolders[_user] >= _amount, "You do not have enough tickets" );
        ticketHolders[_user] = ticketHolders[_user] - _amount;

    }
}