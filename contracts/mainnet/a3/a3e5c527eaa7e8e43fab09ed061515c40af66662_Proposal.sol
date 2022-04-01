/**
 *Submitted for verification at Etherscan.io on 2022-03-31
*/

pragma solidity 0.6.7;

abstract contract Setter {
    function modifyParameters(address receiver, bytes4 targetFunction, bytes32 parameter, uint256 val) external virtual;
    function updateResult(uint256) external virtual;
}

contract Proposal {
    address public constant GEB_MINMAX_REWARDS_ADJUSTER = 0x86EBA7b7dAaFEC537A2357f8A3a46026AF5Cb7bA;
    address public constant GEB_GAS_PRICE_ORACLE =        0x3a3e9d4D1AfC6f9d7e0E9A4032a7ddBc1500D7a5;

    function execute(bool) public {
        // Ajust gas price oracle to 150gwei
        Setter(GEB_GAS_PRICE_ORACLE).updateResult(150000000000); // 150 gwei

        // Adjust gas cost for FSM update call (adding oracleRelayer cost of 65k)
        Setter(GEB_MINMAX_REWARDS_ADJUSTER).modifyParameters(
            0x105b857583346E250FBD04a57ce0E491EB204BA3, // FSM_WRAPPER_ETH
            0x2761f27b,                                 // renumerateCaller(address)
            "gasAmountForExecution",
            265000
        );
    }
}