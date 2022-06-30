//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.15;

import "../interfaces/ICNSController.sol";

// import "../structures/AllowlistPolicyStructure.sol";

contract AllowlistPolicy {
    ICNSContoller public cns;

    // mapping(string => domain) public domains;

    constructor() {}

    // function registerPolicy(string memory _domain) public {
    //     require(cns.isDomainRegister(_domain));
    //     domains[_domain] = domain(msg.sender, _domain, new allowlist2[](0));
    // }

    function TestGetter() public view returns (uint256) {
        return cns.getTestDrive();
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.15;

interface ICNSContoller {
    function isDomainRegister(string memory _domain)
        external
        view
        returns (bool);

    function getTestDrive() external view returns (uint256);
}