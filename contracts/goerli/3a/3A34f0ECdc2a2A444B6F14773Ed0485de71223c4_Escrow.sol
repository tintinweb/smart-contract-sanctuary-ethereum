/**
 *Submitted for verification at Etherscan.io on 2023-03-04
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
pragma experimental ABIEncoderV2;


contract Escrow {
	// The struct of an escrow contract: ID, depositor, arbiter, beneficiary, amount, timestamp,  and approval status.
    struct Contract {
        uint256 id;
        address depositor;
        address arbiter;
        address beneficiary;
        uint256 amount;
        uint256 timestamp;
        bool isApproved;
    }

		// Public array of escrow contracts stored in the contract
    Contract[] public contracts;

		// Create a new escrow contract
    function createContract(address _arbiter, address _beneficiary)
        external
        payable
    {
				// Require vaule to be greater than 0 to be sent with the transaction
        require(msg.value > 0);
				// Push new contract onto the Contracts array
        contracts.push(
            Contract(
                contracts.length + 1,
                msg.sender,
                _arbiter,
                _beneficiary,
                msg.value,
                block.number,
                false
								
            )
        );
    }



	// Return the array of contracts in which the sender is the depositor
    function getListContracts() public view returns (Contract[] memory) {
        uint256 length = 0;
        for (uint256 i = 0; i < contracts.length; i++) {
            if (contracts[i].depositor == msg.sender) {
                length++;
            }
        }
        Contract[] memory data = new Contract[](length);
        length = 0;
        for (uint256 i = 0; i < contracts.length; i++) {
            if (contracts[i].depositor == msg.sender) {
                data[length] = contracts[i];
                length++;
            }
        }
        return data;
    }
		// Returns an array of contracts in which the sender is the arbiter and that need approval.
    function getContractsToApprove()
        public
        view
        returns (Contract[] memory)
    {
				//Set length to 0
        uint256 length = 0;
        for (uint256 i = 0; i < contracts.length; i++) {
            if (contracts[i].arbiter == msg.sender) {
                length++;
            }
        }
        Contract[] memory data = new Contract[](length);
        length = 0;
        for (uint256 i = 0; i < contracts.length; i++) {
            if (contracts[i].arbiter == msg.sender) {
                data[length] = contracts[i];
                length++;
            }
        }
        return data;
    }
		// An event that is emitted when an escrow contract is approved
    event ContractApproved(uint256);

		// Approve an escrow contract
    function approve(uint256 _id) external {
        Contract memory data;
        for (uint256 i = 0; i < contracts.length; i++) {
            if (contracts[i].id == _id) {
                data = contracts[i];
            }
        }
        require(data.id > 0, "Contract not found");
				// Require the artbiter to only approve it
        require(msg.sender == data.arbiter, "Only the arbiter can approve it");
				// Send the amount of ether to the beneficiary
        (bool sent, ) = payable(data.beneficiary).call{value: data.amount}("");
        require(sent, "Failed to send Ether");
        contracts[_id - 1].isApproved = true;
        emit ContractApproved(_id);
    }

		// Return a specific escrow contract based on its ID
    function getContract(uint256 _id)
        external
        view
        returns (Contract memory data)
    {
        for (uint256 i = 0; i < contracts.length; i++) {
            if (contracts[i].id == _id) {
                data = contracts[i];
            }
        }
    }
}