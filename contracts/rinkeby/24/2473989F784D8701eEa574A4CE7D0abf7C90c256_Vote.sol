// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "../government/IGovernment.sol";
import "../government/Government.sol";
import "../local/ILocal.sol";
import "../local/Local.sol";
import "./IVote.sol";

contract Vote is IVote, Local {
    using Counters for Counters.Counter;
    Counters.Counter private _index;

    mapping(uint256 => TheVote) public voteIndex;
    string private _name;
    address private _localContract;
    address private _governmentContract;

    constructor(address governmentAddress, address localAddress) {
        _name = "2022 Presidential Election";
        government[indexGOV++] = msg.sender;
        _localContract = localAddress;
        _governmentContract = governmentAddress;
    }

    function addAllowance (address _address, string memory _local) public {
        ILocal(_localContract)._addAllowance(_address, _local);
    }

    function isAllowed(address _address) public view returns (bool) {
        return IGovernment(_governmentContract)._isAllowed(_address);
    }

    function stringToBytes(string memory a) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(a));
    }

    function exists(string memory hashId) public override view returns (bool) {
        bytes32 _bytesHashId = stringToBytes(hashId);
        for (uint256 i = 0; i < supply(); i++) {
            if (stringToBytes(hashIdByIndex(i)) == _bytesHashId) return true; 
        }
        return false;
    }

    function vote(string memory hashId, uint256 option) public onlyGovernment {
        require(!exists(hashId), "This Hash Id have already voted !!!");
        uint256 index = _index.current();
        voteIndex[index] = TheVote(hashId, option, block.timestamp);
        _index.increment();
    }

    function hashIdOption(string memory hashId) public override view returns (uint256) {
        require(exists(hashId), "This Hash Id haven't voted yet !!!"); 
        bytes32 _bytesHashId = stringToBytes(hashId);
        for (uint256 i = 0; i < supply(); i++) {
            if (stringToBytes(hashIdByIndex(i)) == _bytesHashId) 
                return optionByIndex(i);
        }
        return 666;
    }

    function name() public override view returns (string memory) {
        return _name;
    }

    function supply() public override view returns (uint256) {
        return _index.current();
    }

    function voteByIndex(uint256 index) public override view returns (TheVote memory) {
        return voteIndex[index];
    }

    function hashIdByIndex(uint256 index) public override view returns (string memory) {
        return voteIndex[index].hashId;
    }

    function optionByIndex(uint256 index) public override view returns (uint256) {
        return voteIndex[index].option;
    }
}

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
pragma solidity ^0.8.0;

interface IGovernment {
    function _isAllowed(address _address) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IGovernment.sol";

contract Government is IGovernment {
    mapping(uint256 => address) public government;
    uint256 internal indexGOV;

    constructor() {
        indexGOV = 0;
    }

    function _isAllowed(address _address) external override view returns (bool) {
        for (uint256 i=0; i<indexGOV; i++) {
            if (_address == government[i]) return true;
        }
        return false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILocal {
    function _addAllowance(address _address, string memory _local) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ILocal.sol";
import "../government/Government.sol";

contract Local is ILocal, Government {
    modifier onlyGovernment() {
        require(msg.sender == government[0], "You're not allowed");
        _;
    }

    mapping(string => address) public local;

    function _addAllowance(address _address, string memory _local) 
        external override onlyGovernment 
    {
        government[indexGOV++] = _address;
        local[_local] = _address;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVote {
    struct TheVote {
        string hashId;
        uint256 option;
        uint256 time;
    }

    function exists(string memory hashId) external view returns (bool);

    function hashIdOption(string memory hashId) external view returns (uint256);

    function name() external view returns (string memory);

    function supply() external view returns (uint256);

    function voteByIndex(uint256 index) external view returns (TheVote memory);

    function hashIdByIndex(uint256 index) external view returns (string memory);

    function optionByIndex(uint256 index) external view returns (uint256);
}