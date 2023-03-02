// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

/// library defining the data structure of our contract
library NumberStorage {
    /// specify the storage location, needs to be unique
    bytes32 public constant NUMBER_STORAGE_POSITION = keccak256("number.storage");

    /// the state data struct
    struct Data {
        uint256 number;
    }

    /// state accessor, always use this to access the state data
    function numberStorage() internal pure returns (Data storage numberData) {
        bytes32 position = NUMBER_STORAGE_POSITION;
        assembly {
            numberData.slot := position
        }
    }
}

/// implementation of our contract's logic, notice the lack of local state
/// state is always accessed via the storage library defined above
contract Number {

    function setNumber(uint256 _newNumber) external {
        NumberStorage.Data storage data = NumberStorage.numberStorage();
        data.number = _newNumber;
    }

    function getNumber() external view returns (uint256) {
        NumberStorage.Data storage data = NumberStorage.numberStorage();
        return data.number;
    }
}