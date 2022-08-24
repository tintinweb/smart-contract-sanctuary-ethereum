/**
 *Submitted for verification at Etherscan.io on 2022-08-24
*/

// File: contracts/UpointActivity.sol


pragma solidity ^0.8.7;

/**
 * airdrop UPOINT 
 */

interface UpointFaucet {
    function availableDrips() external view returns (uint256 upointDrips);
    function drip(address to, uint256 amount) external returns (bool success);
}

contract UpointActivity {

    UpointFaucet private immutable _upointFaucet; 

    address private owner;

    /// @notice Addresses of super operators
    mapping(address => bool) public superOperators;

    /// @notice Requires sender to be contract super operator
    modifier isSuperOperator() {
        // Ensure sender is super operator
        require(superOperators[msg.sender], "Not super operator");
        _;
    }

    /**
     * UpointFaucet 
     */
    constructor(address UpointFaucetContract) {
       _upointFaucet = UpointFaucet(UpointFaucetContract);
       superOperators[msg.sender] = true;
       owner = msg.sender;
    }

    /// @notice airdrop to users
    function airdrop(address[] calldata users, uint256[] calldata quantities) public isSuperOperator {
        require(users.length > 0 && users.length == quantities.length, "Parameters error");
        for (uint256 i = 0; i < users.length; i++) {
            if (quantities[i] < 1) {
                continue;
            }
            _upointFaucet.drip(users[i], quantities[i]);
        }
    }


    /// @notice Allows receiving ETH
    receive() external payable {
        payable(owner).transfer(msg.value);
    }

    
}