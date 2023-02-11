/**
 *Submitted for verification at Etherscan.io on 2023-02-10
*/

pragma solidity ^0.8.0;

contract SniffInu {
    // Token properties
    string public constant name = "Sniff inu";
    string public constant symbol = "SNIFF";
    uint256 public constant totalSupply = 1000000000 * 10**18; // 1 billion tokens
    uint256 public constant decimals = 18;

    // Mapping to store balances for each address
    mapping (address => uint256) public balances;

    // Event to log transfer events
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    // Function to return the balance of an address
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    // Function to transfer tokens from one address to another
    function transfer(address _to, uint256 _value) public {
        // Ensure the caller has enough funds
        require(balances[msg.sender] >= _value, "Insufficient balance");

        // Ensure the recipient is not the zero address
        require(_to != address(0), "Invalid address");

        // Decrease the sender's balance
        balances[msg.sender] -= _value;

        // Increase the recipient's balance
        balances[_to] += _value;

        // Emit a transfer event
        emit Transfer(msg.sender, _to, _value);
    }
}