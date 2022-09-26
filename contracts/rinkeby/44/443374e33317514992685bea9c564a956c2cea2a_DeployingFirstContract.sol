/**
 *Submitted for verification at Etherscan.io on 2022-09-26
*/

// SPDX-License-Identifier: MIT 
pragma solidity ^ 0.8.8; 

// Timestamp | 2:53:37

contract DeployingFirstContract {
    
    uint256 favoriteNumber;

    // [1] Create a mapping with type string, visibility as public, called nameToFaveNumber 
    // We can use this to map every name to a specific number 
    mapping(string => uint256) public nameToFaveNumber; 

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;
    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }
    
    function retrieve() public view returns (uint256){
        return favoriteNumber;
    }

    // [2] Let's enhance the addPerson function 
    // Beyond adding people to the array, let's add to the mapping 
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
       
        // Let's map the _name to _favoriteNumber
        nameToFaveNumber [_name] = _favoriteNumber;
    }
}

/*   =====   DEPLOYING CONTRACT  =====   */

 /* Goal - We would like to send to testnet 
    to have others interact with it
    
    We are moving from the JavaScript VM to 
    either Injected Web3 or Web3 Provider 

    Injected Web3 - Injecting MetaMask for use, with Rinkeby at this time
    Web3 Provider - More detailed 

    -- Observations --

    Once deployed, MetaMask surfaces to confirm the transaction 
    We are signing and sending the transaction
    We can see the data referring to the contract we've created 
    The payment information (gas) is included as well 

    The transaction to deploy was successful! Transaction details are on Etherscan
    https://rinkeby.etherscan.io/tx/0xc52c6a3653c7c060f69a2f7280c79c08e60f9c88772fcb162b765ab3e228d01c
    Hash: 0xc52c6a3653c7c060f69a2f7280c79c08e60f9c88772fcb162b765ab3e228d01c

    I've stored a value of 3 as a fave number and signed with MetaMask
    The data is visible on the blockchain! Input data reflects uint256 with value of 3
    Hash: 0xe3cebf022545ab1a1c82e0c30a4eba7793ed0ad46d3416c8105191c74aeaa6a0

    Next, I've stored my name and fave number (and signed)
    Can see the Method as "Add Person" with the string for name and uint256 for number included
    Hash: 0x48e2923d56539bd708389f55c3780e00320b78990e4470068af09f496814d16e

    It's exciting to actually deploy my first contract to an actual testnet 
    and view what the transactions look like on Etherscan! ^_^ 

    ⠀⠀⠀⠀⠀⠀⠀⠀⣀⣤⣴⣶⣾⣿⣿⣿⣿⣷⣶⣦⣤⣀⠀⠀⠀⠀⠀⠀⠀⠀
    ⠀⠀⠀⠀⠀⣠⣴⣿⣿⣿⣿⣿⣿⣿⣿⢿⣿⣿⣿⣿⣿⣿⣿⣦⣄⠀⠀⠀⠀⠀
    ⠀⠀⠀⣠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⠏⠀⠹⣿⣿⣿⣿⣿⣿⣿⣿⣷⣄⠀⠀⠀
    ⠀⠀⣴⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠃⠀⠀⠀⠙⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⠀⠀
    ⠀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠁⠀⠀⠀⠀⠀⠈⢿⣿⣿⣿⣿⣿⣿⣿⣿⣧⠀
    ⢰⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⠀⠀⠀⠀⣀⠀⠀⠀⠈⢻⣿⣿⣿⣿⣿⣿⣿⣿⡆
    ⣾⣿⣿⣿⣿⣿⣿⣿⣿⠏⠀⣀⡤⠖⠛⠉⠛⠶⣤⣀⠀⠹⣿⣿⣿⣿⣿⣿⣿⣷
    ⣿⣿⣿⣿⣿⣿⣿⣿⡿⠞⠋⠁⠀⠀⠀⠀⠀⠀⠀⠈⠙⠳⣿⣿⣿⣿⣿⣿⣿⣿
    ⢿⣿⣿⣿⣿⣿⣿⣿⣿⡳⢦⣄⠀⠀⠀⠀⠀⠀⠀⣠⡴⢚⣿⣿⣿⣿⣿⣿⣿⡿
    ⠸⣿⣿⣿⣿⣿⣿⣿⣿⣷⣄⠈⠙⠶⣄⣀⣤⠖⠋⠁⣠⣿⣿⣿⣿⣿⣿⣿⣿⠇
    ⠀⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⡀⠀⠀⠉⠀⠀⢀⣴⣿⣿⣿⣿⣿⣿⣿⣿⡟⠀
    ⠀⠀⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⡄⠀⠀⠀⣠⣾⣿⣿⣿⣿⣿⣿⣿⣿⠟⠀⠀
    ⠀⠀⠀⠙⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣆⠀⣴⣿⣿⣿⣿⣿⣿⣿⣿⡿⠋⠀⠀⠀
    ⠀⠀⠀⠀⠀⠙⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠋⠀⠀⠀⠀⠀
    ⠀⠀⠀⠀⠀⠀⠀⠀⠉⠛⠻⠿⢿⣿⣿⣿⣿⡿⠿⠟⠛⠉⠀⠀⠀⠀⠀⠀⠀⠀

 */