// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract ChallengeFactory {
    // @notice create challenges contract
    function deploy(address player) external payable virtual returns (address[] memory);
    function deployValue() external view virtual returns (uint256);

    // @notice return name of the contract challenges
    function contractNames() external view virtual returns (string[] memory);

    /// @notice Will true if player has complete the challenge
    function isComplete(address[] calldata) external view virtual returns (bool);

    // @notice return name for rendering the nft
    function name() external view virtual returns (string memory);

    // @notice return name for rendering the nft
    function description() external view virtual returns (string memory);

    // @notice return image for rendering the nft
    function image() external view virtual returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ChallengeFactory} from "../ChallengeFactory.sol";
import {GoldenTicket} from "./ChallengeGoldenTicket.sol";

contract ChallengeGoldenTicketFactory is ChallengeFactory {
    mapping(address => address) private _challengePlayer;
    string[] _contractnames = ["GoldenTicket"];

    function deploy(address _player) external payable override returns (address[] memory ret) {
        require(msg.value == 0, "Dont send ether");
        address _challenge = address(new GoldenTicket());
        ret = new address[](1);
        ret[0] = _challenge;
        _challengePlayer[_challenge] = _player;
    }

    function deployValue() external pure override returns (uint256) {
        return 0;
    }

    function contractNames() external view override returns (string[] memory) {
        return _contractnames;
    }

    function isComplete(address[] calldata _challenges) external view override returns (bool) {
        // @dev to win this challenge you must drain the contract
        // @dev to win this challenge you must drain the contract
        address _player = _challengePlayer[_challenges[0]];
        return GoldenTicket(_challenges[0]).hasTicket(_player);
    }

    function path() external pure returns (string memory) {
        return "/tracks/eko2022/the-golden-ticket";
    }

    /// @dev optional to give a link to a readme or plain text
    function readme() external pure returns (string memory) {
        return "Mint your ticket to the eko party, if you are patient and lucky enough.";
    }

    function name() external pure override returns (string memory) {
        return "Golden Ticket";
    }

    function description() external pure override returns (string memory) {
        return "Proud owner of the golden ticket";
    }

    function image() external pure override returns (string memory) {
        return "ipfs://QmdwGmeeweZya62pCsGJrmqstxtkwTq4rwFHEJ9LQEjm4P";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title The Golden Ticket
/// @author https://twitter.com/AlanRacciatti
/// @notice Mint your ticket to the EKOparty, if you are patient and lucky enough.
/// @custom:url https://www.ctfprotocol.com/tracks/eko2022/the-golden-ticket
contract GoldenTicket {
    mapping(address => uint40) public waitlist;
    mapping(address => bool) public hasTicket;

    function joinWaitlist() external {
        require(waitlist[msg.sender] == 0, "Already on waitlist");
        unchecked {
            ///@dev 10 years wait list
            waitlist[msg.sender] = uint40(block.timestamp + 10 * 365 days);
        }
    }

    function updateWaitTime(uint256 _time) external {
        require(waitlist[msg.sender] != 0, "Join waitlist first");
        unchecked {
            waitlist[msg.sender] += uint40(_time);
        }
    }

    function joinRaffle(uint256 _guess) external {
        require(waitlist[msg.sender] != 0, "Not in waitlist");
        require(waitlist[msg.sender] <= block.timestamp, "Still have to wait");
        require(!hasTicket[msg.sender], "Already have a ticket");
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp)));
        if (randomNumber == _guess) {
            hasTicket[msg.sender] = true;
        }
        delete waitlist[msg.sender];
    }

    function giftTicket(address _to) external {
        require(hasTicket[msg.sender], "Yoy dont own a ticket");
        hasTicket[msg.sender] = false;
        hasTicket[_to] = true;
    }
}