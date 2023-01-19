pragma solidity ^0.8.0;

contract Shareholder {
    // Mapping to store shareholder addresses and their corresponding number of shares
    mapping (address => uint) public shares;
    // Event to emit when shares are transferred
    event ShareTransfer(address from, address to, uint shares);

    // Function to issue new shares
    function issueShares(uint _shares) public {
        // Add the issued shares to the msg.sender's existing shares
        shares[msg.sender] += _shares;
    }

    // Function to transfer shares from one shareholder to another
    function transferShares(address _to, uint _shares) public {
        require(shares[msg.sender] >= _shares, "Not enough shares.");
        // Subtract the transferred shares from the msg.sender's existing shares
        shares[msg.sender] -= _shares;
        // Add the transferred shares to the recipient's existing shares
        shares[_to] += _shares;
        emit ShareTransfer(msg.sender, _to, _shares);
    }
}