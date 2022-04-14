// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.10;

import './interfaces/IDeployer.sol';
import './libraries/Lock.sol';
import './libraries/Pause.sol';

contract Deployer is IDeployer, Pause, Lock {
    mapping(uint256 => bytes) public bytecodes;

    constructor() Pause(msg.sender) {}

    function setBytecode(uint256 bytecodeId, bytes calldata _bytecode) external override onlyOwner {
        require(bytecodeId > 0, 'D_INVALID_BYTECODE_ID');
        bytecodes[bytecodeId] = _bytecode;

        emit BytecodeSet(bytecodeId, _bytecode.length);
    }

    function bytecode(uint256 bytecodeId) external view override returns (bytes memory) {
        require(bytecodeId > 0, 'D_INVALID_BYTECODE_ID');
        return bytecodes[bytecodeId];
    }

    function create(uint256 bytecodeId, bytes calldata constructorData)
        external
        override
        lock
        notPaused
        returns (address)
    {
        address contractAddress;
        bytes memory _bytecode = abi.encodePacked(bytecodes[bytecodeId], constructorData);
        require(_bytecode.length > 32, 'D_INVALID_BYTECODE');
        assembly {
            contractAddress := create(0, add(_bytecode, 0x20), mload(_bytecode))
        }
        require(contractAddress != address(0), 'D_CREATE_FAILED');
        emit Created(bytecodeId, contractAddress);
        return contractAddress; // TODO: In tests this is returning as null
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.10;

import './libraries/IPause.sol';

interface IDeployer is IPause {
    event BytecodeSet(uint256 bytecodeId, uint256 size);

    event Created(uint256 indexed bytecodeId, address indexed contractAddress);

    function setBytecode(uint256 bytecodeId, bytes calldata bytecode) external;

    function bytecode(uint256 bytecodeId) external view returns (bytes memory);

    function create(uint256 bytecodeId, bytes calldata constructorData) external returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.10;

abstract contract Lock {
    bool private _unlocked = true;

    modifier lock() {
        require(_unlocked, 'LL_LOCK');
        _unlocked = false;
        _;
        _unlocked = true;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.10;

import '../interfaces/libraries/IPause.sol';
import './Owner.sol';

abstract contract Pause is IPause, Owner {
    bool public override paused;

    modifier notPaused() {
        require(!paused, 'LP_PAUSED');
        _;
    }

    constructor(address _owner) Owner(_owner) {}

    function setPaused(bool _paused) external override onlyOwner {
        require(paused != _paused, 'LP_ALREADY_SET');

        paused = _paused;

        emit PausedSet(_paused);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.10;

import './IOwner.sol';

interface IPause is IOwner {
    event PausedSet(bool paused);

    function setPaused(bool paused) external;

    function paused() external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.10;

interface IOwner {
    event OwnerSet(address owner);

    function setOwner(address owner) external;

    function owner() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.10;

import '../interfaces/libraries/IOwner.sol';

abstract contract Owner is IOwner {
    address public override owner;

    modifier onlyOwner() {
        require(msg.sender == owner, 'LO_OWNER_ONLY');
        _;
    }

    constructor(address _owner) {
        require(_owner != address(0), 'LO_ADDRESS_ZERO');

        owner = _owner;

        emit OwnerSet(_owner);
    }

    function setOwner(address _owner) external onlyOwner {
        require(_owner != owner, 'LO_ALREADY_SET');
        require(_owner != address(0), 'LO_ADDRESS_ZERO');

        owner = _owner;

        emit OwnerSet(_owner);
    }
}