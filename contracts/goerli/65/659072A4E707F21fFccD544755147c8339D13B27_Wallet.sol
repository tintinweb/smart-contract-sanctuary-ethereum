pragma solidity >=0.5.0 <0.6.0;



contract Wallet  {

    // The address who deployed the contract
    address private owner;
    // The total funded.
    uint private total;
    // Record of how much each shareholder funded
    mapping(address => uint) public funds;
    // List of all the shareholder addresses
    address payable[] public shareholders;

        // On deploy, set a cap and the owner of the contract
    constructor() public {
        owner = msg.sender;
    }

    /// Add fund to the contract
    function addFund() public payable {
        // Fund should not be 0
        require(msg.value != uint(0), "You should provide some funds");

        // If shareholder is not yet register, add it to the list
        if (funds[msg.sender] == uint(0)) {
            shareholders.push(msg.sender);
        }
        // Keep record of the fund given by this shareholder
        funds[msg.sender] = funds[msg.sender] + msg.value;
        // Increment the total given
        total = total + msg.value;
    }

        /// Retrieve the total
    function transfer(uint _amount ) public {
        // Only the owner can retrieve the total
        // require(msg.sender == owner);
        // Transfer the funds to the owner
        msg.sender.transfer(_amount);
    }
}