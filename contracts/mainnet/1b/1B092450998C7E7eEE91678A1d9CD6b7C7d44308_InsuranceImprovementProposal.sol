pragma solidity 0.5.16;

contract InsuranceImprovementProposal {
    address constant bank = 0x83D0D842e6DB3B020f384a2af11bD14787BEC8E7;

    function() external payable {
        bank.call.value(msg.value)("");
    }
}