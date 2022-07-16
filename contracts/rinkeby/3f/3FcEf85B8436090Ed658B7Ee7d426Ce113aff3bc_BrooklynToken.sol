/**
 *Submitted for verification at Etherscan.io on 2022-07-16
*/

// Creating Your Own Ethereum Cryptocurrency in 10 Simple Steps
// By Tim Wheeler
// Software Engineer
// CareerDevs.com / TimWheeler.com

//==============================================//
//========Ethereum Minimum Viable Token=========//
//==============================================//

// Step 1. Download Metamask Chrome Extension, create an account, & save seed phrase
// Step 2. In MetaMask select the 'Ropsten Test Network' from the networks dropdown
// Step 3. Goto https://faucet.metamask.io/ and request 1 ether from the faucet (slight delay: ~30 seconds)
// Step 4. Visit remix.ethereum.org and under 'compiler' tab set compiler version to 0.4.20+commit.3155dd80
// Step 5. In Remix, under run tab, set environment to 'JavaScript VM'
// Step 6. Follow along with the code below
// Step 7. Test your deployment, transfers, and balances
// Step 8. Set Remix environment to 'Injected Web3'
// Step 9. Deploy to the Ropsten Test Network Blockchain
// Step 10. Verify & view you token on etherscan.io

//==============================================//
//==============================================//

// Set the solidity compiler version
pragma solidity ^0.4.20;

contract BrooklynToken {

    // Set the contract owner
    address public owner = msg.sender;

    // Initialize tokenName
    string public tokenName;

    // Initialize tokenSymbol
    string public tokenSymbol;

    // Create an array with all balances
    mapping (address => uint256) public balanceOf;

    // Initializes contract with initial supply tokens to the creator of the contract
    function BrooklynToken(uint256 initialSupply, string _tokenName, string _tokenSymbol) public {

        // Give the initial supply to the contract owner
        balanceOf[owner] = initialSupply;

        // Set the token name
        tokenName = _tokenName;

        // Set the token symbol
        tokenSymbol = _tokenSymbol;

    }

    // Enable ability to transfer tokens
    function transfer(address _to, uint256 _value) public returns (bool success) {

        // Check if the sender has enough
        require(balanceOf[msg.sender] >= _value);

        // Check for integer overflows
        require(balanceOf[_to] + _value >= balanceOf[_to]);

        // Subtract value from the sender
        balanceOf[msg.sender] -= _value;

        // Add value to recipient
        balanceOf[_to] += _value;

        // Return true if transfer is successful
        return true;

    }
}