/**
 *Submitted for verification at Etherscan.io on 2022-07-20
*/

pragma solidity 0.6.7;

abstract contract Setter {
    function modifyParameters(address, bytes4, bytes32, uint256) external virtual;
    function setPerBlockAllowance(address, uint256) external virtual;
    function setTotalAllowance(address , uint256) external virtual;
}

contract Proposal {
    address public constant GEB_MINMAX_REWARDS_ADJUSTER = 0x86EBA7b7dAaFEC537A2357f8A3a46026AF5Cb7bA;
    address public constant GEB_AUTO_SURPLUS_BUFFER = 0x5376BC11C92189684B4B73282F8d6b30a434D31C;
    address public constant GEB_STABILITY_FEE_TREASURY = 0x83533fdd3285f48204215E9CF38C785371258E76;

    function execute(bool) public {
        // adjust gasAmountForExecution
        Setter(GEB_MINMAX_REWARDS_ADJUSTER).modifyParameters(
            GEB_AUTO_SURPLUS_BUFFER,
            bytes4(0xbf1ad0db), // adjustSurplusBuffer(address)
            "gasAmountForExecution",
            90000
        );

        // cleanup old contract allowances
        address payable[6] memory oldContracts = [
            0x7235a0094eD56eB2Bd0de168d307C8990233645f,
            0x6A4B575Ba61D2FB86ad0Ff5e5BE286960580E71A,
            0x59536C9Ad1a390fA0F60813b2a4e8B957903Efc7,
            0x1450f40E741F2450A95F9579Be93DD63b8407a25,
            0x0262Bd031B99c5fb99B47Dc4bEa691052f671447,
            0x9fe16154582ecCe3414536FdE57A201c17398b2A
        ];

        for(uint i; i < 6; i++)
            cleanAllowances(oldContracts[i]);
    }

    function cleanAllowances(address who) internal {
        Setter(GEB_STABILITY_FEE_TREASURY).setPerBlockAllowance(who, 0);
        Setter(GEB_STABILITY_FEE_TREASURY).setTotalAllowance(who, 0);
    }
}