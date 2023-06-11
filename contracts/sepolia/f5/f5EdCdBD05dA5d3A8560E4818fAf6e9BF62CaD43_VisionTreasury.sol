pragma solidity ^0.8.4;

contract VisionTreasury {
    address owner;
    address payable public visionDAO;
    
    constructor() {
        owner = msg.sender;
    }
    // Events
    event Deposit(address indexed sender, uint256 amount);
    event Withdrawal(address indexed recipient, uint256 amount);
    event OwnerChanged(address indexed previousOwner, address indexed newOwner);
    
    function deposit() external payable {
        // Accept incoming Ether and add it to the treasury
        emit Deposit(msg.sender, msg.value);
    }
    
    function withdraw() external payable {
        require(msg.sender == owner, "Only the owner can withdraw funds");
        uint256 balance = address(this).balance;
        visionDAO.transfer(balance);
        emit Withdrawal(owner, balance);
    }
    
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
    function setOwner(address _owner) external {
        require(msg.sender == owner, "Only the owner can set a new owner");
        owner = _owner;
    }
}