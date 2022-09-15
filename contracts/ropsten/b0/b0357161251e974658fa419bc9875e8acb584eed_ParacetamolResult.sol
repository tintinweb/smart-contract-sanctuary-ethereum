// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./ResultApproval.sol";

/**
 * @title kjk
 * @dev hjk
 */
contract ParacetamolResult is ResultApproval {

    event NewResult(string patientRef);

    event ResultsClosed(uint totalResult);

    struct Result {
        string patientRef;
        string lotId;
        bool result;
    }
    Result[] private _results;
    bool private _closed = false;

    mapping(string => bool) private _validatedPatients;

    function addResult(string memory _patientRef, string memory _lot, bool _result) external onlyApproved(msg.sender) {
        require(!_closed);
        require(!_validatedPatients[_patientRef]);
        _results.push(Result(_patientRef, _lot, _result));
        _validatedPatients[_patientRef] = true;
        emit NewResult(_patientRef);
    }

    function getResultSnapshot() public view returns (uint) {
        uint total = 0;
        if (_results.length == 0) {
            return 0;
        }
        for (uint i = 0; i < _results.length; i++) {
            if (_results[i].result) {
                total++;
            }
        }
        return total * 100 / _results.length;
    }

    function close() external onlyOwner {
        require(!_closed);
        _closed = true;
        uint totalResult = getResultSnapshot();
        emit ResultsClosed(totalResult);
    }   
}