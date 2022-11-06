// contracts/BoxV3.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BoxV2.sol";

contract BoxV3 is BoxV2{
    string public name;
    address public owner;

    event NameChanged(string name);

    modifier onlyOwner() {
        require(msgSender() == owner);
        _;
    }

    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
    }

    function msgSender() private returns (address) {
        return msg.sender;
    }

    function setName(string memory _name) public {
        name = _name;
        emit NameChanged(name);
    }
}

// contracts/BoxV2.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Box.sol";

// Author: test123
contract BoxV2 is Box {
    // Increments the stored value by 1
    function increment() public {
        store(retrieve()+1);
    }
}

// contracts/Box.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Author: test123
contract Box {
    uint256 private _value;

    // Emitted when the stored value changes
    event ValueUpdated(uint256 value);

    // Stores a new value in the contract
    function store(uint256 value) public {
        _value = value;
        emit ValueUpdated(value);
    }

    // Reads the last stored value
    function retrieve() public view returns (uint256) {
        return _value;
    }
}