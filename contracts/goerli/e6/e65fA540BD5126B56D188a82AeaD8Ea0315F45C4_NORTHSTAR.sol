/// SPDX-License-Identifier: UNLICENCSED
/// @title Endowment Token
/// @author Independent Development
/// @notice This contract is proprietary and may not be copied or used without permission.
/// InfContract v0.0.1
pragma solidity ^0.8.17;

//RRCHANGE remove the testing contract and replace with the stakable endowment contract

//import "./StakableEndowmentToken.sol";
import "./ERC20.sol";
// import "./ERC20FixedSupply.sol";

contract NORTHSTAR is ERC20 {
    constructor() {
        setNameAndSymbol("NORTHSTAR Token", "NORTHSTAR");
        uint intitialTotalSupply = 3000000000000000000000000000000; //3M Tokens x 18 Decimals
        _mint(msg.sender, intitialTotalSupply);
    }

    receive()
    payable
    external
    {
        uint256 fbfail = 1;
        require(fbfail == 0, string(abi.encodePacked(name(), ": You can not send ETH to this contract!")));
    }

    fallback() external {}
}