/**
 *Submitted for verification at Etherscan.io on 2023-02-28
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Escrow {
    struct Contract {
        uint id;
        address arbiter;
	    address beneficiary;
        uint amount;
        bool isApproved;
    }
    Contract[] public contracts;
    Contract private nullContract;

	event Created(uint);

    function create(address arbiter, address beneficiary) external payable returns (uint id) {
        id = uint(keccak256(abi.encodePacked(arbiter, beneficiary, msg.sender, msg.value, block.timestamp)));
        contracts.push(Contract(id, arbiter, beneficiary, msg.value, false));
		emit Created(id);
    }

	event Approved(uint);

	function approve(uint id) external {
        Contract storage escrow = findContract(id);
        require(id == escrow.id, "invalid ID");
		require(msg.sender == escrow.arbiter, "you are not the arbiter");
        require(!escrow.isApproved, "escrow contract has been approaved");

		escrow.isApproved = true;

		(bool s, ) = payable(escrow.beneficiary).call{ value: escrow.amount }("");
 		require(s, "failed to send Ether");

		emit Approved(id);
	}

	function findContract(uint id) private view returns (Contract storage) {
        for (uint i = 0; i < contracts.length; i++) {
            if (id == contracts[i].id) return contracts[i];
        }
        return nullContract;
    }

	function getContracts() external view returns (Contract[] memory) {
		return contracts;
	}
}