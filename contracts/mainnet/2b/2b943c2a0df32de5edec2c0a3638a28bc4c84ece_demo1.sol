pragma solidity ^0.4.24;

contract demo1 {
    
    
    mapping(address => uint256) private playerVault;
   
    modifier hasEarnings()
    {
        require(playerVault[msg.sender] > 0);
        _;
    }
    
    function myEarnings()
        external
        view
        hasEarnings
        returns(uint256)
    {
        return playerVault[msg.sender];
    }
    
    function withdraw()
        external
        hasEarnings
    {

        uint256 amount = playerVault[msg.sender];
        playerVault[msg.sender] = 0;

        msg.sender.transfer(amount);
    }
    
   

     function deposit() public payable returns (uint) {
        // Use 'require' to test user inputs, 'assert' for internal invariants
        // Here we are making sure that there isn't an overflow issue
        require((playerVault[msg.sender] + msg.value) >= playerVault[msg.sender]);

        playerVault[msg.sender] += msg.value;
        // no "this." or "self." required with state variable
        // all values set to data type's initial value by default

        return playerVault[msg.sender];
    }
    
}