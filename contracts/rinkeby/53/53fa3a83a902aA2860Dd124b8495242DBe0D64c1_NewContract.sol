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
    address public admin;

    constructor(
        string memory _daughtersName,
        uint256 _daughtersAge,
        address _contractadmin
    ) public {
        name = _daughtersName;
        age = _daughtersAge;
        admin = _contractadmin;
        contract_state = CONTRACT_STATE.CONTRACTING;
    }

    function retrieve_name() public view returns (string memory) {
        return name;
    }

    function retrieve_age() public view returns (uint256) {
        return age;
    }

    function retrieve_admin() public view returns (address) {
        return admin;
    }
}