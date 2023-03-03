/**
 *Submitted for verification at Etherscan.io on 2023-03-03
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

/**
 * @title Shuffle
 * @dev Store & retrieve address list in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract Shuffle {
    address[] addresses;
    mapping(address => uint) balances;

    function deposit() payable external {
        // record the value sent 
        // to the address that sent it
        balances[msg.sender] += msg.value;
    }

    /**
     * @dev Store return value in variable
     * @return shuffled
     */
    function shuffleList(address[] memory list, uint256 seed) payable public returns (address[] memory) {
        uint256 n = list.length;
        address[] memory shuffled = new address[](n);

        for (uint256 i = 0; i < n; i++) {
            shuffled[i] = list[i];
        }

        for (uint256 i = n - 1; i > 0; i--) {
            uint256 j = uint256(keccak256(abi.encodePacked(seed, i))) % (i + 1);
            address temp = shuffled[i];
            shuffled[i] = shuffled[j];
            shuffled[j] = temp;
        }
        
        return addresses = shuffled;
    }

    /**
     * @dev Return value 
     * @return value of 'addresses'
     */
    function retrieveShuffledList() public view returns (address[] memory){
        return addresses;
    }
}