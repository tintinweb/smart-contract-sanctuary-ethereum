/**
 *Submitted for verification at Etherscan.io on 2023-02-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract _Quic_Ipfs_Storage {
    address public masterOwner;

    // structure of how hash realted information are stored for each address.
    struct currentIpfsHash {
        string[] ipfsHash;
        uint256 numOfHashs;
    }

    mapping(address => currentIpfsHash) public ipfsHash_Holder;

    constructor() {
        masterOwner = msg.sender;
    }

    // Start a whole new transaction for an addrees that allows it to store a new Hash value.
    function createIpfsHashOwner(string memory newHash) public payable {
        require(msg.value >= .01 ether);
        ipfsHash_Holder[msg.sender].numOfHashs += 1; // counting the number of hash an address contain.
        ipfsHash_Holder[msg.sender].ipfsHash.push(newHash); // adding newhas to the user stack
    }

    // get the hash from an address by an index.
    function fetchHashFromAddress(string memory index)
        public
        view
        returns (string memory)
    {
        return ipfsHash_Holder[msg.sender].ipfsHash[strToUint(index)];
    }

    // give back the amount of hashes stored in an account.
    function fetchAmountOfHashsFromAddress() public view returns (uint256) {
        return ipfsHash_Holder[msg.sender].numOfHashs;
    }

    // give back to contract master, for testing only
    function gatherEthBackFromdevEnv() public payable {
        payable(masterOwner).transfer(address(this).balance);
    }

    // function changeHashOwner(string memory newHash) public{
    //   require(ipfsHash_Holder[msg.sender]==)

    // }
}


// Pure Functions, e.g. conversions
function strToUint(string memory _str) pure returns(uint256 res) {
    
    for (uint256 i = 0; i < bytes(_str).length; i++) {
        if ((uint8(bytes(_str)[i]) - 48) < 0 || (uint8(bytes(_str)[i]) - 48) > 9) {
            return (0);
        }
        res += (uint8(bytes(_str)[i]) - 48) * 10**(bytes(_str).length - i - 1);
    }
    
    return (res);
}