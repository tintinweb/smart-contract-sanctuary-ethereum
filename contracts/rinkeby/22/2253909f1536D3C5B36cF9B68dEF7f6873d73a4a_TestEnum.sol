// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <8.10.0;

contract TestEnum {
    enum ActionChoices { GoLeft, GoRight, GoStraight, SitStill }
    ActionChoices choice;
    ActionChoices constant defaultChoice = ActionChoices.GoStraight;

    function setGoStraight() public {
        choice = ActionChoices.GoStraight;
    }
        
    function setChoice(ActionChoices newChoice) public {
        choice = newChoice;
    }

    function getChoice() public view returns (ActionChoices) {
        return choice;
    }
    function getDefaultChoice() public pure returns (uint) {
        return uint(defaultChoice);
    }
}