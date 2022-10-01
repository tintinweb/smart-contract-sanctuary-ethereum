/**
 *Submitted for verification at Etherscan.io on 2022-10-01
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

// Acknowledgement of Peace, first version.

// Previously, we've deployed an Expression of Peace (EoP) contract, and as of its V2, 
// introduced the inclusion of citizenship info (country ISO code) along with the expression text.

// Now, in this, first version of the acknowledgements, we'll basically refer to those transaction hashes.
// Exclusion of the wallet address made that expression will require fetching their account address from tx history of EoP contract.
// since in any case we'll lookup tx history through an EoP contract or a wallet's history of interaction with these contracts, 
// Will be a headache until we index all potentially via, thegraph or another solution. 

// There may and probably exist a better solutions for this as-is, so.. 
// ~ Expect a new version during the Q4'2022.

contract AcknowledgementOfPeace {
    struct Acknowledgement {
        string expression_tx_to_ack; // transaction hash of an expression to acknowledge, when found peaceful.
        string acker_country_code; // country ISO code for the one that acknowledges peace
        string acked_country_code; // // country ISO code for the one, whose expression is acknowledged 
    }

    Acknowledgement ack;

    constructor(string memory _expression_tx_to_ack, string memory _acker_country_code, string memory _acked_country_code) {
        ack.expression_tx_to_ack = _expression_tx_to_ack;
        ack.acker_country_code = _acker_country_code;
        ack.acked_country_code = _acked_country_code;
    }

    // an expression can be acknowledged without inclusion of nationality in both sides.
    function acknowledge_as_world_citizen(string memory _expression_tx_to_ack) public {
        ack.expression_tx_to_ack = _expression_tx_to_ack;
    }

    // an expression can be acknowledged with inclusion of nationality in both sides.
    function acknowledge_as_citizen(string memory _expression_tx_to_ack, string memory _acker_country_code, string memory _acked_country_code) public {
        ack.expression_tx_to_ack = _expression_tx_to_ack;
        ack.acker_country_code = _acker_country_code;
        ack.acked_country_code = _acked_country_code;
    }

    function read() public view returns (Acknowledgement memory) {
        return ack;
    }
}