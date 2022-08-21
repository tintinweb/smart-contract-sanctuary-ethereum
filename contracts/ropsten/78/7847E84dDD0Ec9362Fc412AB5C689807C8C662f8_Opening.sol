// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0 <0.9.0;
pragma experimental ABIEncoderV2;

// contract Opening {
//     event emitOpening(uint256 opening_session_id, address opener_id, uint256[13][] openingshares);
//     function SendOpeningInfo(uint256 opening_session_id,  uint256[13][] memory openingshares) public  {
//             emit emitOpening(opening_session_id, msg.sender, openingshares);
//         }
// }

contract Opening {
    modifier onlyOwner {
        require(msg.sender == 0x5F795E5727B5350fcDAFe4bab2355014BAD9778d || msg.sender == 0x72E5a03d6EDCc3EC5C06Bf80b7e197c8d085F362 || msg.sender == 0x5f6111A353118637C0aF2A3734082f166d10b903 || msg.sender == 0xb8D96bA1ffB3994f2d79Fc45A2640Bc220aCFeBe);
        _;
    }
    event emitOpening(uint256 opening_session_id, address opener_id, uint256[13][] openingshares);
    function SendOpeningInfo(uint256 opening_session_id,  uint256[13][] memory openingshares) public {
            emit emitOpening(opening_session_id, msg.sender, openingshares);
        }
}