/**
 *Submitted for verification at Etherscan.io on 2022-11-30
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Tickets
 * @dev Implements tickets buy / usage process
 */
contract Tickets {
    address public contract_owner;
    uint256 public ticket_price;

    mapping(address => bool) public admins;
    mapping(address => uint256) public tickets;

    event ticketBuy(address user, uint256 amount);
    event ticketUse(address user, uint256 amount);
    event adminEdit(address user, string action);

    /**
     * @dev Create a "ticket selling machine"
     * @param base_price default price for tickets (in gwei)
     */
    constructor(uint256 base_price) {
        contract_owner = msg.sender;
        admin_set(contract_owner);
        ticket_price = base_price * 10e8;
    }

    /**
     * @dev Set a user admin
     * @param _user user address who will become admin (require to be owner to play)
     */
    function admin_set(address _user) public {
        require(
            msg.sender == contract_owner,
            "You need to be owner to set a new admin"
        );
        admins[_user] = true;
        emit adminEdit(_user, "set");
    }

    /**
     * @dev Revoke user admin power
     * @param _user user address who admin power will be revoked (require to be owner to play)
     */
    function admin_revoke(address _user) public {
        require(
            msg.sender == contract_owner,
            "You need to be owner to revoke an existing admin"
        );
        admins[_user] = false;
        emit adminEdit(_user, "revoke");
    }

    /**
     * @dev Buy a ticket
     * @param _amount number of tickets wanted, require exact value as msg.value
     */
    function ticket_buy(uint256 _amount) external payable {
        uint256 order_value = _amount * ticket_price;

        require(msg.value == order_value, "Need to send exact amount of ETH");

        (bool sent, bytes memory data) = contract_owner.call{
            value: order_value
        }("");
        require(sent, "Failed to send Tickets");
        data = data;
        tickets[msg.sender] += _amount;

        emit ticketBuy(msg.sender, _amount);
    }

    /**
     * @dev Use a ticket
     * @param _amount amount of ticket to use for defined user
     * @param _user user which tickets will be used
     */
    function ticket_use(uint256 _amount, address _user) public {
        require(admins[msg.sender], "You need to be admin to use tickets");
        require(
            tickets[_user] >= _amount,
            "User don't have enough tickets left"
        );
        tickets[_user] -= _amount;
        emit ticketUse(_user, _amount);
    }
}