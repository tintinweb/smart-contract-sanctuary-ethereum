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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Counters.sol";

contract SupplyChainProcess {
    using Counters for Counters.Counter;

    enum Status {
        INIT,
        GOOD,
        INVESTIGATE,
        REFUND
    }

    struct Process {
        uint256 id;
        string name;
        address[] validators;
        uint256 insuranceDeposit;
        string formHash;
        string coverImageHash;
        Status status;
    }

    Process[] public processes;
    Counters.Counter private processIdTracker;
    mapping(uint256 => Process) public processesById;
    mapping(uint256 => mapping(address => string[])) validatorReportByIdAndAddress;

    event SupplyChainProcessAdded(
        uint256 indexed id, string name, uint256 insuranceDeposit, string formHash, string coverImageHash
    );
    event ReportSubmitted(uint256 indexed id, address indexed submitter, string report, Status currentStatus);

    constructor() {}

    function addProcess(
        string memory name,
        address[] memory validators,
        uint256 insuranceDeposit,
        string memory formHash,
        string memory coverImageHash
    ) external {
        processes.push(
            Process(
                processIdTracker.current(), name, validators, insuranceDeposit, formHash, coverImageHash, Status.INIT
            )
        );
        processesById[processIdTracker.current()] = processes[processes.length - 1];
        emit SupplyChainProcessAdded(processIdTracker.current(), name, insuranceDeposit, formHash, coverImageHash);
        processIdTracker.increment();
    }

    function submitReport(uint256 id, Status currentStatus, string memory report) external {
        require(isProcessValidator(id), "You are not a validator for this project");
        require(processesById[id].status == Status.INVESTIGATE, "No new reports until investigation is done");
        processesById[id].status = currentStatus;
        validatorReportByIdAndAddress[id][msg.sender].push(report);
        emit ReportSubmitted(id, msg.sender, report,currentStatus);
    }
 
    

    function isProcessValidator(uint256 id) public view returns (bool) {
        address[] memory validators = processesById[id].validators;
        for (uint256 i = 0; i < validators.length; i++) {
            if (validators[i] == msg.sender) return true;
        }
        return false;
    }

    function getValidatorsById(uint256 id) external view returns (address[] memory) {
        return processesById[id].validators;
    }
}