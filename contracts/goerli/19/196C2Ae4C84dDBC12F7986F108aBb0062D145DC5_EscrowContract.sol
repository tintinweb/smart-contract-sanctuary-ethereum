// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/Counters.sol";

// custom errors
error Escrow__IndependentArbiterNeeded();
error Escrow__NotAuthorized();
error Escrow__TransferFailed();
error Escrow__AlreadyPaidOut(uint escrowId);

contract EscrowContract { 
    using Counters for Counters.Counter;

    struct Escrow {
        address depositor;
        address beneficiay;
        address arbiter;
        uint lockedAmount;
        bool isExecuted;
    }

    // events
	event newEscrow(uint escrowId, address indexed depositor, address indexed beneficiary, address indexed arbiter);
    event Approved(uint escrowId);
    event Revoked(uint escrowId);

    // storage variables
    mapping(uint256 => Escrow) internal s_escrows;
    Counters.Counter internal _idCounter;
	
    // modifiers
    modifier onlyArbiter(uint _escrowId) {
        if(s_escrows[_escrowId].arbiter != msg.sender) {
            revert Escrow__NotAuthorized();
        }
        _;
    }

    modifier notExecuted(uint _escrowId) {
        if(s_escrows[_escrowId].isExecuted) {
            revert Escrow__AlreadyPaidOut(_escrowId);
        }
        _;
    }

    // external functions

    /**
     * @notice create new escrow agreement. The sender is set as the depositor.
     * @param _beneficiary address of beneficiary
     * @param _arbiter address of independent arbiter. Beneficiary or depositor can not act as arbiter.
     * returns escrowId
     */
	function createNewEscrow(address _beneficiary, address _arbiter) external payable returns(uint256){
        if(msg.sender == _arbiter || _beneficiary == _arbiter) {
            revert Escrow__IndependentArbiterNeeded();
        }
        uint256 id = _idCounter.current();
        _idCounter.increment();
        s_escrows[id] = Escrow(msg.sender, _beneficiary, _arbiter, msg.value, false);
        emit newEscrow(id, msg.sender, _beneficiary, _arbiter);
        return id;
	}

    /**
     * @notice Arbiter calls approve function when agreement is fulfilled. The locked amount is sent to the beneficiary.
     * @param _escrowId escrowId
     */
	function approve(uint _escrowId) external onlyArbiter(_escrowId) notExecuted(_escrowId) {
		uint balance = s_escrows[_escrowId].lockedAmount;
        s_escrows[_escrowId].isExecuted = true;
		(bool sent, ) = payable(s_escrows[_escrowId].beneficiay).call{value: balance}("");
 		if(!sent){
            revert Escrow__TransferFailed();
        }
		emit Approved(_escrowId);
	}

    /**
     * @notice Arbiter calls revoke function when agreement is revoked. The locked amount is sent back to the depositor.
     * @param _escrowId escrowId
     */
    function revoke(uint _escrowId) external onlyArbiter(_escrowId) notExecuted(_escrowId) {
		uint balance = s_escrows[_escrowId].lockedAmount;
        s_escrows[_escrowId].isExecuted = true;
		(bool sent, ) = payable(s_escrows[_escrowId].depositor).call{value: balance}("");
 		if(!sent){
            revert Escrow__TransferFailed();
        }
		emit Revoked(_escrowId);
	}
    
    // view functions
    function getDepositor(uint _escrowId) external view returns (address) {
        return s_escrows[_escrowId].depositor;
    }

    function getBeneficiary(uint _escrowId) external view returns (address) {
        return s_escrows[_escrowId].beneficiay;
    }

    function getArbiter(uint _escrowId) external view returns (address) {
        return s_escrows[_escrowId].arbiter;
    }

    function getLockedAmount(uint _escrowId) external view returns (uint) {
        return s_escrows[_escrowId].lockedAmount;
    }

    function isExecuted(uint _escrowId) external view returns(bool) {
        return s_escrows[_escrowId].isExecuted;
    }
}