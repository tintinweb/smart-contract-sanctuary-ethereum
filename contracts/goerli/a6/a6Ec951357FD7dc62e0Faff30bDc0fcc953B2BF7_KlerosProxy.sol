/**
 *Submitted for verification at Etherscan.io on 2023-06-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

// Deployed something here: https://goerli.etherscan.io/address/0x868d33519061db42446d79489372ee5b4400d117#code

interface LightGTCRFactory {

    // Functions
    function deploy(
        address _arbitrator, // Simplifying from IArbitrator
        bytes calldata _arbitratorExtraData,
        address _connectedTCR,
        string calldata _registrationMetaEvidence,
        string calldata _clearingMetaEvidence,
        address _governor,
        uint256[4] calldata _baseDeposits,
        uint256 _challengePeriodDuration,
        uint256[3] calldata _stakeMultipliers,
        address _relayContract
    ) external;

    function count() external view returns (uint256);
    function instances(uint256 _index) external view returns (address);

}

struct Organisation { 
    string orgId;
    string name;
}

contract KlerosProxy {

    LightGTCRFactory public klerosFactory;
    address KlerosFactoryAddress = 0x55A3d9Bd99F286F1817CAFAAB124ddDDFCb0F314; // https://goerli.etherscan.io/address/0x55A3d9Bd99F286F1817CAFAAB124ddDDFCb0F314#code

    constructor() {
        klerosFactory = LightGTCRFactory(KlerosFactoryAddress);
    }

    Organisation[] public organisations;
    uint public organisationsLength;
    event OrganisationAdded(uint index, string orgId, string name);

    mapping (string => bool) public guidCollisions; // guids are generated on the front-end, need to ensure they are unique

    modifier guidUnique(string memory guid) {
      require(guidCollisions[guid] == false, "guid is not unique");
      guidCollisions[guid] = true;
      _;
    }

    function addOrganisation(string memory orgId, string memory name) public guidUnique(orgId) returns (address) {
        Organisation memory organisation = Organisation(orgId, name);
        organisations.push(organisation);
        emit OrganisationAdded(organisationsLength, orgId, name);
        organisationsLength++;

        // Kleros integration
        // factory.deploy(
        //         _arbitrator,
        //         _arbitratorExtraData,
        //         _connectedTCR,
        //         _registrationMetaEvidence,
        //         _clearingMetaEvidence,
        //         _governor,
        //         _baseDeposits,
        //         _challengePeriodDuration,
        //         _stakeMultipliers,
        //         _relayContract
        //     );

        klerosFactory.deploy(
            0x1128eD55ab2d796fa92D2F8E1f336d745354a77A,
            abi.encodePacked(bytes1(uint8(1))),
            0x0000000000000000000000000000000000000000,
            "/ipfs/QmcLd4ucxkU9TvjTUzKk2u2EzFcNV24UuvxwRq1JMhupmN/reg-meta-evidence.json",
            "/ipfs/QmaiZUrRtKk1a12mW9zArG7TW1hXBraYB3u6AXwrrVGBH3/clr-meta-evidence.json",
            0x85A363699C6864248a6FfCA66e4a1A5cCf9f5567,
            [uint256(0.05 ether), uint256(0.05 ether), 0, uint256(0.05 ether)],
            302400,
            [uint256(10000), uint256(10000), uint256(20000)],
            0x0000000000000000000000000000000000000000
        );

        uint256 count = klerosFactory.count();
        address deployedOrg = klerosFactory.instances(count - 1);

        return deployedOrg; 
    }


}