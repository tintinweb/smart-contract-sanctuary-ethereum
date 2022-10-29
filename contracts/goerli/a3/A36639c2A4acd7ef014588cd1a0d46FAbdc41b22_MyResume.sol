// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract MyResume {
    address payable owner;

    constructor() {
        owner = payable(msg.sender);
    }

    struct Aboutme {
        string firstName;
        string lastName;
        string email;
        uint256 phoneNumber;
    }

    struct Skill {
        string languages;
        string general;
    }

    Aboutme public AboutMe =
        Aboutme("Knyte", "Bennett-Jeremiah", "[email protected]", 8087726277);

    Skill public Skills =
        Skill(
            "Solidity, Javascript, HTML, CSS",
            "Out-of-the-box thinker with a strong ability to learn anything"
        );

    string public constant Education = "Current student @ Alchemy University";
    string jobStatus = "Seeking Employment";

    function LetsWorkTogether() external {
        // workStatus = Status.employed;
        jobStatus = "Let's get to work!";
    }

    function LetMeThink() external {
        // workStatus = Status.pending;
        jobStatus = "Pending";
    }

    function SorryButNo() external {
        // workStatus = Status.unemployed;
        jobStatus = "Thank you for the opportunity!";
    }

    function WorkStatus() external view returns (string memory) {
        return (jobStatus);
    }
}