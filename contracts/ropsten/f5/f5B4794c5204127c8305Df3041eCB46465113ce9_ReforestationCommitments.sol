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

// File: contracts/ReforestationIncentives.sol

pragma solidity ^0.8.0;


contract ReforestationCommitments is OpenContract {
    uint32 public rainforestKm2In2021 = 3470909;
    uint8 public lastRewardedYear = 21;

    uint256[] public deposits;
    uint256[] public valuesPerKm2PerYear;

    constructor() {
        setOracleHash(this.measureRainforest.selector, 0x80d414e7627bc411045ab1b731006fd2a2c458853f61cf27fcd9fb6a0f27a828);
    }

    function deposit(uint256 valuePerKm2PerYear) public payable {
        deposits.push(msg.value);
        valuesPerKm2PerYear.push(valuePerKm2PerYear);
    }

    function measureRainforest(uint256 rainforestKm2, uint8 mo, uint8 yr) public requiresOracle {
        require(mo == 1, "The contract currently rewards rainforest size yearly, every January.");
        require(yr > lastRewardedYear, "The reward for the submitted year was already claimed.");
        lastRewardedYear += 1;
        uint256 reward = 0;
        for (uint32 i=0; i<deposits.length; i++) {
            uint256 valueGenerated = valuesPerKm2PerYear[i] * (rainforestKm2 - rainforestKm2In2021);
            if (valueGenerated > deposits[i]) {
                reward += deposits[i];
                deposits[i] = 0;
            } else {
                reward += valueGenerated;
                deposits[i] -= valueGenerated;
            }
        }
        PayATwitterAccount(0x507D995e5E1aDf0e6B77BD18AC15F8Aa747B6D07).deposit{value:reward}("govbrazil");
    }
}

interface PayATwitterAccount {
    function deposit(string memory twitterHandle) external payable;
}