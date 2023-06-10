// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./AuditorNFT.sol";

// TODO: Create second version which stores security data on IPFS
contract SmartContractNFT {
  // STORAGE
  // struct for the Audit Security JSON
  struct AuditSecurityData {
    address auditor;
    // keccak256 of the contract name, ex: keccak("flashloan")
    bytes32 contractType;
  }

  // struct for the Contract Security JSON
  struct ContractSecurityData {
    address contractAddress;
    bytes32 contractType;
    uint8 score;
  }
  // address of the Auditor NFT contract (to update array)

  mapping(address contractAddress => AuditSecurityData[]) private s_contractAudits;

  mapping(address contractAddress => ContractSecurityData) private s_contractSecurity;

  // EVENTS
  event MintSmartContractNFT(address auditor, address contractAddress, AuditSecurityData securityData);

  modifier onlyAuditor() {
    // check if has auditor NFT, revert otherwise

    _;
  }

  // FUNCTIONS

  // computeSecurityData internal
  function _computeSecurityData(address contractAddress) internal {
    AuditSecurityData[] memory audits = s_contractAudits[contractAddress];
    uint8 currentMaximumReputation = 0;
    uint256 totalReputationScore = 0;
    bytes32 bestContractType = audits[0].contractType;

    for (uint256 i = 0; i < audits.length; i++) {
      // TODO: remove mock and get the reputation score when AuditorSBT is implemented
      uint8 auditorReputationScore = 50;

      // get data from auditor with best reputation
      if (auditorReputationScore > currentMaximumReputation) {
        currentMaximumReputation = auditorReputationScore;
        bestContractType = audits[i].contractType;
      }
      totalReputationScore += auditorReputationScore;
    }

    uint8 averageReputationScore = uint8(totalReputationScore / audits.length);

    s_contractSecurity[contractAddress] = ContractSecurityData(
      contractAddress,
      bestContractType,
      averageReputationScore
    );
  }

  // mint(contractAddress, securityJSON)
  function mint(
    address contractAddress,
    AuditSecurityData calldata newAuditSecurityData
  ) external onlyAuditor {
    s_contractAudits[contractAddress].push(newAuditSecurityData);

    _computeSecurityData(contractAddress);

    // update tokenIds
    // call ERC721 mint

    emit MintSmartContractNFT(msg.sender, contractAddress, newAuditSecurityData);
  }

  // getContractSecurity(contractAddress) returns (uint8 score)
  function getContractSecurity(address contractAddress) external view returns (ContractSecurityData memory) {
    return s_contractSecurity[contractAddress];
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract AuditorNFT {
    // STORAGE
    // address of the SmartContractNFT contract (to update array)

    struct AuditorData {
        uint8 reputationScore; // 0 to 100
        // TODO: implement audit data struct
    }

    // EVENTS
    event MintAuditorNFT(address auditor);

    // FUNCTIONS
    function mint() external {}
}