// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibERC20Storage} from "../libraries/LibERC20Storage.sol";
contract ChangeERC20Metadata {
    function changeERC20NameSymbol(string calldata _name, string calldata _symbol) external {
        LibERC20Storage.ERC20Storage storage es = LibERC20Storage.erc20Storage();
        es.name = _name;
        es.symbol = _symbol;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibERC20Storage {
    bytes32 constant ERC20_STORAGE_POSITION = keccak256("ciety.governance.token.storage");

    struct ERC20Storage {
        string name;
        string symbol;
        uint256 totalSupply;
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;
    }

    function erc20Storage() internal pure returns (ERC20Storage storage es) {
        bytes32 position = ERC20_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }
}