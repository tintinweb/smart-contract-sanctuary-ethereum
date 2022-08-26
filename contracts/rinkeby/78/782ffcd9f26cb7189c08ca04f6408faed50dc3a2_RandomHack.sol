/**
 *Submitted for verification at Etherscan.io on 2022-08-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

// interface ITarget {
//     function mint(
//         uint256 version,
//         uint256 amount,
//         uint256 buyAmount,
//         uint256[4] memory pricesAndTimestamps,
//         bytes memory signature,
//         bytes memory dualSignature
//     ) external payable;
// }
// 
/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract RandomHack {

    // address constant targetAddress = 0xCa5f21C3b873E535df588D62F24C46B7f191C11B;

    constructor() {}

    function kecd(address addr) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(addr));
    }
    /**
     * @dev Return value 
     * @return value of 'number'
     */
    // function mintId(uint256 desiredId) external {
    //     ITarget target = ITarget(targetAddress);
    //     target.mint(
    //         0, 1, 1, [0,0,0,1], 
    //         0xa3e4662f2baf3df4f5b0fdac1afca101c9f5c9e9dbedb79e7e3958ce03331ae70f8a1bdba5212d5d874bd1c5b5491218fe82480b54757b9bba568455e8df82f61b, 
    //     0x501558fb28777cb6f71af07a6def0f31bc83aa322b510eec9662e81a92928d3b4034742cc5ccaf997ecc181f594185420a1f6517f8520fbff2c2433d06fea44a1c
    //     );
    // }
}