/**
 *Submitted for verification at Etherscan.io on 2022-06-29
*/

pragma solidity ^0.4.11;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract ERC20Constant {
    function balanceOf(address who) constant returns (uint256 value);
}

contract ERC20Stateful {
    function transfer(address to, uint256 value) returns (bool ok);
}

contract ERC20Events {
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Constant, ERC20Stateful, ERC20Events {}

contract Owned {
    address public owner;

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}

contract PrivateSale is Owned {
    ERC20 public syspadToken;

    // Amount of syspad received per ETH
    uint256 public syspadPerEth;

    // Sales start at this timestamp
    uint256 public initialTimestamp;

    // The sale goes on through 6 days.
    // Each day, users are allowed to buy up to a certain (cummulative) limit of syspad.

    // This mapping stores the addresses for whitelisted users
    mapping(address => bool) public whitelisted;

    // Used to calculate the current limit
    mapping(address => uint256) public bought;

    // The initial values allowed per day are copied from this array
    uint256[4] public limitPerMonth;

    // Forwarding address
    address public receiver;

    event LogWithdrawal(uint256 _value);
    event LogBought(uint256 orderInsyspad);
    event LogUserAdded(address user);
    event LogUserRemoved(address user);

    function PrivateSale(
        ERC20 _syspadToken,
        address _receiver
    ) Owned() {
        syspadToken = _syspadToken;
        initialTimestamp = block.timestamp;
        receiver = _receiver;

        syspadPerEth = 12000; // Price per ETH
        limitPerMonth[0] = 1950000 ether;
        limitPerMonth[1] = 3900000 ether + limitPerMonth[0];
        limitPerMonth[2] = 3900000 ether + limitPerMonth[1];
        limitPerMonth[3] = 5460000 ether + limitPerMonth[2];
    }

    // Withdraw syspad (only owner)
    function withdrawsyspad(uint256 _value) onlyOwner returns (bool ok) {
        return withdrawToken(syspadToken, _value);
    }

    // Withdraw any ERC20 token (just in case)
    function withdrawToken(address _token, uint256 _value)
        onlyOwner
        returns (bool ok)
    {
        return ERC20(_token).transfer(owner, _value);
        LogWithdrawal(_value);
    }

    // Change address where funds are received
    function changeReceiver(address _receiver) onlyOwner {
        require(_receiver != 0);
        receiver = _receiver;
    }

    // Calculate which month into the sale are we.
    function getMonth() returns (uint256) {
        return SafeMath.sub(block.timestamp, initialTimestamp) / 30 days;
    }

    modifier onlyIfActive() {
        require(getMonth() >= 0);
        require(getMonth() < 30);
        _;
    }

    function buy(address beneficiary) payable onlyIfActive {
        require(beneficiary != 0);
        require(whitelisted[msg.sender]);

        uint256 month = getMonth();
        uint256 allowedForSender = limitPerMonth[month] - bought[msg.sender];

        if (msg.value > allowedForSender) revert();

        uint256 balanceInsyspad = syspadToken.balanceOf(address(this));

        uint256 orderInsyspad = msg.value * syspadPerEth;
        if (orderInsyspad > balanceInsyspad) revert();

        bought[msg.sender] = SafeMath.add(bought[msg.sender], msg.value);
        syspadToken.transfer(beneficiary, orderInsyspad);
        receiver.transfer(msg.value);

        LogBought(orderInsyspad);
    }

    // Add a user to the whitelist
    function addUser(address user) onlyOwner {
        whitelisted[user] = true;
        LogUserAdded(user);
    }

    // Remove an user from the whitelist
    function removeUser(address user) onlyOwner {
        whitelisted[user] = false;
        LogUserRemoved(user);
    }

    // Batch add users
    function addManyUsers(address[] users) onlyOwner {
        require(users.length < 10000);
        for (uint256 index = 0; index < users.length; index++) {
            whitelisted[users[index]] = true;
            LogUserAdded(users[index]);
        }
    }

    function() payable {
        buy(msg.sender);
    }
}