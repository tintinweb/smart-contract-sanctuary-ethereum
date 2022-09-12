pragma solidity ^0.8.0;

import "./Ticket.sol";

contract MiniVault {
    using Ticket for bytes;

    address ticketAuthority;
    uint256 public start = 29;
    uint256 public goal = 99;
    uint256 public n;
    bytes32 private x;

    struct Player {
        address a;
        uint8 level;
    }

    struct Level {
        uint8 completedCount;
        uint256 reward;
        address winner;
    }

    mapping(uint8 => Player) public players;
    mapping(uint8 => Level) public levels;

    constructor(address _auth) payable {
        ticketAuthority = _auth;
        n = start;
        x = keccak256(abi.encodePacked(block.number));
        levels[1].reward = 0.01 ether;
        levels[2].reward = 0.02 ether;
        levels[3].reward = 0.03 ether;

        uint256 totalReward = (levels[1].reward * 3) + (levels[2].reward * 2) + (levels[3].reward * 1);
        require(msg.value == totalReward, "Inadequate Funding");
    }

    function level1(bytes memory _ticket) public {
        uint8 ticketId = checkTicket(_ticket);
        require(players[ticketId].level == 0, "L1 - 1");
        players[ticketId].a = msg.sender;
        players[ticketId].level = 1;

        if (levels[1].winner == address(0)) {
            levels[1].winner = players[ticketId].a;
        }
        if (levels[1].completedCount < 2) {
            require(
                payable(players[ticketId].a).send(levels[1].reward),
                "Could not send funds"
            );
        }
        levels[1].completedCount++;
    }

    function level2(bytes memory _ticket, bytes32 _h) public {
        uint8 ticketId = checkTicket(_ticket);
        require(players[ticketId].a == msg.sender, "L2 - 1");
        require(players[ticketId].level == 1, "L2 - 2");
        require(_h == x, "L2 - 3");

        if (levels[2].winner == address(0)) {
            levels[2].winner = players[ticketId].a;
        }
        if (levels[2].completedCount < 2) {
            require(
                payable(players[ticketId].a).send(levels[2].reward),
                "Could not send funds"
            );
        }
        players[ticketId].level = 2;
        levels[2].completedCount++;
    }

    function level3(bytes memory _ticket) public {
        uint8 ticketId = checkTicket(_ticket);
        require(players[ticketId].level == 2, "L3 - 1");

        if (n == goal) {
            // win
            if (levels[3].winner == address(0)) {
                levels[3].winner = players[ticketId].a;
            }
            if (levels[3].completedCount < 1) {
                require(
                    payable(players[ticketId].a).send(levels[2].reward),
                    "Could not send funds"
                );
            }
            players[ticketId].level = 3;
            levels[3].completedCount++;

            // reset first to original value
            resetN();
        }
    }

    function resetN() public {
        n = start;
    }

    function ns3() public {
        n -= 3;
    }

    function np39() public {
        n += 39;
    }

    function nm3() public {
        n *= 3;
    }

    function nd2() public {
        n /= 2;
    }

    function checkTicket(bytes memory _ticket) public view returns (uint8 tid) {
        require(
            ticketAuthority == _ticket.checkTicketSigner(),
            "Invalid Ticket"
        );
        assembly {
            tid := byte(1, mload(add(_ticket, 0x60)))
        }
    }
}