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

// File: contracts/WeatherInsurance.sol

pragma solidity ^0.8.0;


contract WeatherInsurance is OpenContract {

    struct parameters {
        uint256 payout;
        uint256 price;
        address insurer;
        bool active;
    }

    mapping(bytes32 => mapping(address => parameters)) public policy;

    constructor() {
        setOracleHash(this.settle.selector, 0x72102889e3b88d5e2e6a41a6a8b2c9e064b199220f9f4c054e952c0927db615a);
    }

    function policyID(int8 latitude, int8 longitude, uint8 year, uint8 month, uint8 threshold) public pure returns(bytes32) {
        return keccak256(abi.encode(latitude, longitude, year, month, threshold));
    }

    function request(bytes32 policyID, uint256 payout) public payable {
        require(!policy[policyID][msg.sender].active, "Your policy is already active.");
        policy[policyID][msg.sender].price += msg.value;
        policy[policyID][msg.sender].payout = payout;
    }

    function retract(bytes32 policyID) public {
        require(!policy[policyID][msg.sender].active, "Your policy is already active.");
        uint256 payment = policy[policyID][msg.sender].price;
        policy[policyID][msg.sender].price = 0;
        payable(msg.sender).transfer(payment);
    }

    function provide(address beneficiary, bytes32 policyID) public payable {
        require(!policy[policyID][beneficiary].active, "The policy is already active.");
        require(msg.value >= policy[policyID][beneficiary].payout, "You did not send enough ETH to provide the insurance.");
        policy[policyID][beneficiary].active = true;
        policy[policyID][beneficiary].insurer = msg.sender;
        uint256 payment = policy[policyID][beneficiary].price;
        policy[policyID][beneficiary].price = 0;
        payable(msg.sender).transfer(payment);
    }

    function settle(address beneficiary, bytes32 policyID, bool damageOccured) requiresOracle public {
        require(policy[policyID][beneficiary].active, "The insurance is not active.");
        uint256 payout = policy[policyID][beneficiary].payout;
        if (damageOccured) {
            payable(beneficiary).transfer(payout);
        } else {
            payable(policy[policyID][beneficiary].insurer).transfer(payout);
        }
    }
}