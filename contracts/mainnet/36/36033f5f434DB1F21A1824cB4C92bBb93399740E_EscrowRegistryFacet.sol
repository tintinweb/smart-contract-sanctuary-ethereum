// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "../libraries/AppStorage.sol";

contract EscrowRegistryFacet {

    AppStorage internal s;

    function getEscrow(
        bytes memory _id,
        address _buyer,
        address _seller,
        uint256 _amount,
        uint256 _fee
    )
        public
        view
        returns (address)
    {
        bytes32 escrowID = keccak256(abi.encodePacked(_id,_buyer,_seller,_amount,_fee));
        if (s.escrows[escrowID] != address(0)) {
            return s.escrows[escrowID];
        }

        return address(0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

struct AppStorage {
    mapping (bytes32 => address) escrows;
}