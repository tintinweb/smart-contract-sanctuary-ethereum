// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract NewContract {
    enum CONTRACT_STATE {
        CONTRACTING,
        PROCESSING,
        CANCELED,
        DONE
    }
    CONTRACT_STATE public contract_state;

    string public name;
    uint256 public age;

    constructor(string memory _daughtersName, uint256 _daughtersAge) public {
        name = _daughtersName;
        age = _daughtersAge;
        contract_state = CONTRACT_STATE.CONTRACTING;
    }

    function retrieve_name() public view returns (string memory) {
        return name;
    }

    function retrieve_age() public view returns (uint256) {
        return age;
    }
}