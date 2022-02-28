/**
 *Submitted for verification at Etherscan.io on 2022-02-28
*/

// File: https://github.com/open-contracts/protocol/blob/main/solidity_contracts/OpenContractRopsten.sol

pragma solidity >=0.8.0;

contract OpenContract {
    OpenContractsHub private hub = OpenContractsHub(0x059dE2588d076B67901b07A81239286076eC7b89);
 
    // this call tells the Hub which oracleID is allowed for a given contract function
    function setOracleHash(bytes4 selector, bytes32 oracleHash) internal {
        hub.setOracleHash(selector, oracleHash);
    }
 
    modifier requiresOracle {
        // the Hub uses the Verifier to ensure that the calldata came from the right oracleID
        require(msg.sender == address(hub), "Can only be called via Open Contracts Hub.");
        _;
    }
}

interface OpenContractsHub {
    function setOracleHash(bytes4, bytes32) external;
}

// File: contracts/ProofOfID.sol

pragma solidity ^0.8.0;


contract PayATwitterAccount is OpenContract {
    
    mapping(string => uint256) public balances;
    
    constructor () {
        setOracleHash(this.claim.selector, 0x18397129c99c63baae375f7b480aa97f2fcf1d747b171b7db033c788fd732098);
    }
    
    function claim(string memory twitterHandle, address user) public requiresOracle {
        uint256 balance = balances[twitterHandle];
        balances[twitterHandle] = 0;
        payable(user).transfer(balance);
    }

    function deposit(string memory twitterHandle) public payable {
        balances[twitterHandle] += msg.value;
    }
}