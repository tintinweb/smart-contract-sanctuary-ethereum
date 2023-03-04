/* SPDX-License-Identifier: MIT */
pragma solidity ^0.8.17;

import { IGreeter } from "./interfaces/IGreeter.sol";

contract Greeter is IGreeter {
    string private _name;

    function setName(string calldata name) external virtual override {
        _name = name;
    }

    function getName() public view virtual override returns (string memory) {
        return _name;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title IGreeter
 * @dev Interface for the Greeter contract
 */
interface IGreeter {
    /**
     * @dev Sets the name to be greeted
     * @param name Name to be set
     */
    function setName(string calldata name) external;

    /**
     * @dev Gets the name currently being greeted
     * @return Current greeting name
     */
    function getName() external returns (string memory);
}