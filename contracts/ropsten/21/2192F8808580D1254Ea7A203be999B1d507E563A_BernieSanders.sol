// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract BernieSanders {

    uint public max_participants;
    address payable[] public participants;

    constructor(uint init_max_participants) {
        max_participants = init_max_participants;
    }

    receive () external payable {
        // The contract no longer receives funds if the funds were already distributed
        require(participants.length < max_participants, "Funds have already been distributed");

        // If they're already a participant then don't increment num_participants
        uint participant_idx;
        bool sender_already_participant = false;
        for (uint i = 0; i < participants.length; ++i) {
            if (msg.sender == participants[i]) {
                participant_idx = i;
                sender_already_participant = true;
                break;
            }
        }

        if (!sender_already_participant) {
            participants.push(payable(msg.sender));
        }

        // Redistribute funds once we reach the max number of participants.
        if (participants.length == max_participants) {
            uint reward = address(this).balance / participants.length;
            for (uint i = 0; i < participants.length; ++i) {
                address payable participant_address = participants[i];
                participant_address.transfer(reward);
            }
        }
    }
}