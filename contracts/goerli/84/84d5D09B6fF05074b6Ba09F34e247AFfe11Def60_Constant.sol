// SPDX-License-Identifier: BSD-3-Clause
/*
 *                          88  88                                   88
 *                          88  88                            ,d     ""
 *                          88  88                            88
 *  ,adPPYba,   ,adPPYba,   88  88   ,adPPYba,   ,adPPYba,  MM88MMM  88  8b       d8   ,adPPYba,
 * a8"     ""  a8"     "8a  88  88  a8P_____88  a8"     ""    88     88  `8b     d8'  a8P_____88
 * 8b          8b       d8  88  88  8PP"""""""  8b            88     88   `8b   d8'   8PP"""""""
 * "8a,   ,aa  "8a,   ,a8"  88  88  "8b,   ,aa  "8a,   ,aa    88,    88    `8b,d8'    "8b,   ,aa
 *  `"Ybbd8"'   `"YbbdP"'   88  88   `"Ybbd8"'   `"Ybbd8"'    "Y888  88      "8"       `"Ybbd8"'
 *
 */
/*
 * BSD 3-Clause License
 *
 * Copyright (c) 2022, collective
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
pragma solidity ^0.8.15;

import { AddressCollection, AddressSet } from "../contracts/collection/AddressSet.sol";
import { MetaCollection, MetaSet } from "../contracts/collection/MetaSet.sol";
import { TransactionCollection, TransactionSet } from "../contracts/collection/TransactionSet.sol";
import { ChoiceCollection, ChoiceSet } from "../contracts/collection/ChoiceSet.sol";

/**
 * @notice extract global manifest constants
 */
library Constant {
    uint256 public constant UINT_MAX = type(uint256).max;

    /// @notice minimum quorum
    uint256 public constant MINIMUM_PROJECT_QUORUM = 1;

    /// @notice minimum vote delay
    /// @dev A vote delay is recommended to support cancellation of votes, however it is not
    ///      required
    uint256 public constant MINIMUM_VOTE_DELAY = 0 days;

    /// @notice maximum vote delay
    /// @dev default of unlimited is recommended
    uint256 public constant MAXIMUM_VOTE_DELAY = UINT_MAX;

    /// @notice minimum vote duration
    /// @dev For security reasons this must be a relatively long time compared to seconds
    uint256 public constant MINIMUM_VOTE_DURATION = 1 hours;

    /// @notice maximum vote duration
    /// @dev default of unlimited is recommended
    uint256 public constant MAXIMUM_VOTE_DURATION = UINT_MAX;

    // timelock setup

    /// @notice maximum time allowed after the nonce to successfully execute the time lock
    uint256 public constant TIMELOCK_GRACE_PERIOD = 14 days;
    /// @notice the minimum lock period
    uint256 public constant TIMELOCK_MINIMUM_DELAY = MINIMUM_VOTE_DURATION;
    /// @notice the maximum lock period
    uint256 public constant TIMELOCK_MAXIMUM_DELAY = 30 days;

    /// @notice limit for string information in meta data
    uint256 public constant STRING_DATA_LIMIT = 1024;

    /// @notice The maximum priority fee
    uint256 public constant MAXIMUM_REBATE_PRIORITY_FEE = 2 gwei;
    /// @notice The vote rebate gas overhead, including 7K for ETH transfer and 29K for general transaction overhead
    uint256 public constant REBATE_BASE_GAS = 36000;
    /// @notice The maximum refundable gas used
    uint256 public constant MAXIMUM_REBATE_GAS_USED = 200_000;
    /// @notice the maximum allowed gas fee for rebate
    uint256 public constant MAXIMUM_REBATE_BASE_FEE = 200 gwei;

    /// software versions
    uint32 public constant CURRENT_VERSION = 3;

    /// @notice Compute the length of any string in solidity
    /// @dev This method is expensive and is used only for validating
    ///      inputs on the creation of new Governance contract
    ///      or upon the configuration of a new vote
    function len(string memory str) public pure returns (uint256) {
        uint256 bytelength = bytes(str).length;
        uint256 i = 0;
        uint256 length;
        for (length = 0; i < bytelength; length++) {
            bytes1 b = bytes(str)[i];
            if (b < 0x80) {
                i += 1;
            } else if (b < 0xE0) {
                i += 2;
            } else if (b < 0xF0) {
                i += 3;
            } else if (b < 0xF8) {
                i += 4;
            } else if (b < 0xFC) {
                i += 5;
            } else {
                i += 6;
            }
        }
        return length;
    }

    /// @return bool True if empty string
    function empty(string memory str) external pure returns (bool) {
        return len(str) == 0;
    }

    /// factory  implementation
    /**
     * @notice create an AddressSet
     * @return AddressSet the created set
     */
    function createAddressSet() external returns (AddressCollection) {
        return new AddressSet();
    }

    /**
     * @notice create an MetaSet
     * @return MetaSet the created set
     */
    function createMetaSet() external returns (MetaCollection) {
        return new MetaSet();
    }

    /**
     * @notice create an TransactionSet
     * @return TransactionSet the created set
     */
    function createTransactionSet() external returns (TransactionCollection) {
        return new TransactionSet();
    }

    /**
     * @notice create an ChoiceSet
     * @return ChoiceSet the created set
     */
    function createChoiceSet() external returns (ChoiceCollection) {
        return new ChoiceSet();
    }
}

// SPDX-License-Identifier: BSD-3-Clause
/*
 *                          88  88                                   88
 *                          88  88                            ,d     ""
 *                          88  88                            88
 *  ,adPPYba,   ,adPPYba,   88  88   ,adPPYba,   ,adPPYba,  MM88MMM  88  8b       d8   ,adPPYba,
 * a8"     ""  a8"     "8a  88  88  a8P_____88  a8"     ""    88     88  `8b     d8'  a8P_____88
 * 8b          8b       d8  88  88  8PP"""""""  8b            88     88   `8b   d8'   8PP"""""""
 * "8a,   ,aa  "8a,   ,a8"  88  88  "8b,   ,aa  "8a,   ,aa    88,    88    `8b,d8'    "8b,   ,aa
 *  `"Ybbd8"'   `"YbbdP"'   88  88   `"Ybbd8"'   `"Ybbd8"'    "Y888  88      "8"       `"Ybbd8"'
 *
 */
/*
 * BSD 3-Clause License
 *
 * Copyright (c) 2023, collective
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
pragma solidity ^0.8.15;

/// @title minimal implementation of Ownable
/// Ownable pushed some contracts over the initsize limit
/// this is the absolute minimum implementation to secure methods
/// while controlling the initsize cost
/// @dev only one owner is permitted ever
abstract contract OneOwner {
    error NotOwner(address sender);

    address private immutable _owner;

    constructor() {
        _owner = msg.sender;
    }

    /**
     * @dev revert if called by any account other than the owner.
     */
    modifier onlyOwner() {
        if (_owner != msg.sender) revert NotOwner(msg.sender);
        _;
    }

    /**
     * @return address the owner address
     */
    function owner() public view returns (address) {
        return _owner;
    }
}

// SPDX-License-Identifier: BSD-3-Clause
/*
 *                          88  88                                   88
 *                          88  88                            ,d     ""
 *                          88  88                            88
 *  ,adPPYba,   ,adPPYba,   88  88   ,adPPYba,   ,adPPYba,  MM88MMM  88  8b       d8   ,adPPYba,
 * a8"     ""  a8"     "8a  88  88  a8P_____88  a8"     ""    88     88  `8b     d8'  a8P_____88
 * 8b          8b       d8  88  88  8PP"""""""  8b            88     88   `8b   d8'   8PP"""""""
 * "8a,   ,aa  "8a,   ,a8"  88  88  "8b,   ,aa  "8a,   ,aa    88,    88    `8b,d8'    "8b,   ,aa
 *  `"Ybbd8"'   `"YbbdP"'   88  88   `"Ybbd8"'   `"Ybbd8"'    "Y888  88      "8"       `"Ybbd8"'
 *
 */
/*
 * BSD 3-Clause License
 *
 * Copyright (c) 2023, collective
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
pragma solidity ^0.8.15;

import { OneOwner } from "../access/OneOwner.sol";

interface AddressCollection {
    error IndexInvalid(uint256 index);
    error DuplicateAddress(address _address);

    event AddressAdded(address element);
    event AddressRemoved(address element);

    function add(address _element) external returns (uint256);

    function size() external view returns (uint256);

    function get(uint256 index) external view returns (address);

    function contains(address _element) external view returns (bool);

    function erase(address _element) external returns (bool);
}

/// @title dynamic collection of addresses
contract AddressSet is OneOwner, AddressCollection {
    uint256 private _elementCount;

    mapping(uint256 => address) private _elementMap;

    mapping(address => uint256) private _elementPresent;

    constructor() {
        _elementCount = 0;
    }

    modifier requireValidIndex(uint256 index) {
        if (index == 0 || index > _elementCount) revert IndexInvalid(index);
        _;
    }

    /// @notice add an element
    /// @param _element the address
    /// @return uint256 the elementId of the transaction
    function add(address _element) external onlyOwner returns (uint256) {
        uint256 elementIndex = ++_elementCount;
        _elementMap[elementIndex] = _element;
        if (_elementPresent[_element] > 0) revert DuplicateAddress(_element);
        _elementPresent[_element] = elementIndex;
        emit AddressAdded(_element);
        return elementIndex;
    }

    /// @notice erase an element
    /// @dev swaps element to end and deletes the end
    /// @param _index The address to erase
    /// @return bool True if element was removed
    function erase(uint256 _index) external onlyOwner returns (bool) {
        address _element = _elementMap[_index];
        return erase(_element);
    }

    /// @notice erase an element
    /// @dev swaps element to end and deletes the end
    /// @param _element The address to erase
    /// @return bool True if element was removed
    function erase(address _element) public onlyOwner returns (bool) {
        uint256 elementIndex = _elementPresent[_element];
        if (elementIndex > 0) {
            address _lastElement = _elementMap[_elementCount];
            _elementMap[elementIndex] = _lastElement;
            _elementPresent[_lastElement] = elementIndex;
            _elementMap[_elementCount] = address(0x0);
            _elementPresent[_element] = 0;
            delete _elementMap[_elementCount];
            delete _elementPresent[_element];
            _elementCount--;
            emit AddressRemoved(_element);
            return true;
        }
        return false;
    }

    /// @return uint256 The size of the set
    function size() external view returns (uint256) {
        return _elementCount;
    }

    /// @param index The index to return
    /// @return address The requested address
    function get(uint256 index) external view requireValidIndex(index) returns (address) {
        return _elementMap[index];
    }

    /// @param _element The element to test
    /// @return bool True if address is contained
    function contains(address _element) external view returns (bool) {
        return find(_element) > 0;
    }

    /// @param _element The element to find
    /// @return uint256 The index associated with element
    function find(address _element) public view returns (uint256) {
        return _elementPresent[_element];
    }
}

// SPDX-License-Identifier: BSD-3-Clause
/*
 *                          88  88                                   88
 *                          88  88                            ,d     ""
 *                          88  88                            88
 *  ,adPPYba,   ,adPPYba,   88  88   ,adPPYba,   ,adPPYba,  MM88MMM  88  8b       d8   ,adPPYba,
 * a8"     ""  a8"     "8a  88  88  a8P_____88  a8"     ""    88     88  `8b     d8'  a8P_____88
 * 8b          8b       d8  88  88  8PP"""""""  8b            88     88   `8b   d8'   8PP"""""""
 * "8a,   ,aa  "8a,   ,a8"  88  88  "8b,   ,aa  "8a,   ,aa    88,    88    `8b,d8'    "8b,   ,aa
 *  `"Ybbd8"'   `"YbbdP"'   88  88   `"Ybbd8"'   `"Ybbd8"'    "Y888  88      "8"       `"Ybbd8"'
 *
 */
/*
 * BSD 3-Clause License
 *
 * Copyright (c) 2023, collective
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
pragma solidity ^0.8.15;

import { OneOwner } from "../access/OneOwner.sol";

/// @notice choice for multiple choice voting
/// @dev choice voting is enabled by initializing the number of choices when the proposal is created
struct Choice {
    bytes32 name;
    string description;
    uint256 transactionId;
    bytes32 txHash;
    uint256 voteCount;
}

// solhint-disable-next-line func-visibility
function getHash(Choice memory choice) pure returns (bytes32) {
    return keccak256(abi.encode(choice));
}

interface ChoiceCollection {
    error IndexInvalid(uint256 index);
    error HashCollision(bytes32 txId);

    event ChoiceAdded(bytes32 choiceHash);
    event ChoiceRemoved(bytes32 choiceHash);
    event ChoiceIncrement(uint256 index, uint256 voteCount);

    function add(Choice memory choice) external returns (uint256);

    function size() external view returns (uint256);

    function get(uint256 index) external view returns (Choice memory);

    function contains(uint256 _choiceId) external view returns (bool);

    function incrementVoteCount(uint256 index) external returns (uint256);
}

/// @title dynamic collection of choicedata
contract ChoiceSet is OneOwner, ChoiceCollection {
    uint256 private _elementCount;

    mapping(uint256 => Choice) private _elementMap;

    mapping(bytes32 => uint256) private _elementPresent;

    constructor() {
        _elementCount = 0;
    }

    modifier requireValidIndex(uint256 index) {
        if (index == 0 || index > _elementCount) revert IndexInvalid(index);
        _;
    }

    /// @notice add choice
    /// @param _element the choice
    /// @return uint256 the elementId of the choice
    function add(Choice memory _element) external onlyOwner returns (uint256) {
        uint256 elementIndex = ++_elementCount;
        _elementMap[elementIndex] = _element;
        bytes32 _elementHash = getHash(_element);
        if (_elementPresent[_elementHash] > 0) revert HashCollision(_elementHash);
        _elementPresent[_elementHash] = elementIndex;
        emit ChoiceAdded(_elementHash);
        return elementIndex;
    }

    function erase(Choice memory _choice) public onlyOwner returns (bool) {
        bytes32 choiceHash = getHash(_choice);
        uint256 index = _elementPresent[choiceHash];
        return erase(index);
    }

    /// @notice erase a choice
    /// @param _index the index to remove
    /// @return bool True if element was removed
    function erase(uint256 _index) public onlyOwner returns (bool) {
        Choice memory choice = _elementMap[_index];
        bytes32 choiceHash = getHash(choice);
        uint256 elementIndex = _elementPresent[choiceHash];
        if (elementIndex > 0 && elementIndex == _index) {
            Choice memory _lastChoice = _elementMap[_elementCount];
            _elementMap[elementIndex] = _lastChoice;
            bytes32 _lastChoiceHash = getHash(_lastChoice);
            _elementPresent[_lastChoiceHash] = elementIndex;
            _elementMap[_elementCount] = Choice("", "", 0, "", 0);
            _elementPresent[choiceHash] = 0;
            delete _elementMap[_elementCount];
            delete _elementPresent[choiceHash];
            _elementCount--;
            emit ChoiceRemoved(choiceHash);
            return true;
        }
        return false;
    }

    /// @return uint256 The size of the set
    function size() external view returns (uint256) {
        return _elementCount;
    }

    /// @param index The index to return
    /// @return address The requested address
    function get(uint256 index) external view requireValidIndex(index) returns (Choice memory) {
        return _elementMap[index];
    }

    /// increment the votecount choice parameter
    /// @param index The index to increment
    /// @return uint256 The updated count
    function incrementVoteCount(uint256 index) external requireValidIndex(index) returns (uint256) {
        Choice storage choice = _elementMap[index];
        choice.voteCount += 1;
        emit ChoiceIncrement(index, choice.voteCount);
        return choice.voteCount;
    }

    /// @param _choice The element to test
    /// @return bool True if address is contained
    function contains(Choice memory _choice) external view returns (bool) {
        return find(_choice) > 0;
    }

    /// @param _choiceId The element to test
    /// @return bool True if address is contained
    function contains(uint256 _choiceId) external view returns (bool) {
        return _choiceId > 0 && _choiceId <= _elementCount;
    }

    /// @param _choice The element to find
    /// @return uint256 The index associated with element
    function find(Choice memory _choice) public view returns (uint256) {
        bytes32 choiceHash = getHash(_choice);
        return _elementPresent[choiceHash];
    }
}

// SPDX-License-Identifier: BSD-3-Clause
/*
 *                          88  88                                   88
 *                          88  88                            ,d     ""
 *                          88  88                            88
 *  ,adPPYba,   ,adPPYba,   88  88   ,adPPYba,   ,adPPYba,  MM88MMM  88  8b       d8   ,adPPYba,
 * a8"     ""  a8"     "8a  88  88  a8P_____88  a8"     ""    88     88  `8b     d8'  a8P_____88
 * 8b          8b       d8  88  88  8PP"""""""  8b            88     88   `8b   d8'   8PP"""""""
 * "8a,   ,aa  "8a,   ,a8"  88  88  "8b,   ,aa  "8a,   ,aa    88,    88    `8b,d8'    "8b,   ,aa
 *  `"Ybbd8"'   `"YbbdP"'   88  88   `"Ybbd8"'   `"Ybbd8"'    "Y888  88      "8"       `"Ybbd8"'
 *
 */
/*
 * BSD 3-Clause License
 *
 * Copyright (c) 2023, collective
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
pragma solidity ^0.8.15;

import { OneOwner } from "../access/OneOwner.sol";

/// @notice User defined metadata
struct Meta {
    /// @notice metadata key or name
    bytes32 name;
    /// @notice metadata value
    string value;
}

// solhint-disable-next-line func-visibility
function getHash(Meta memory meta) pure returns (bytes32) {
    return keccak256(abi.encode(meta));
}

interface MetaCollection {
    error IndexInvalid(uint256 index);
    error HashCollision(bytes32 txId);

    event MetaAdded(bytes32 metaHash);
    event MetaRemoved(bytes32 metaHash);

    function add(Meta memory meta) external returns (uint256);

    function size() external view returns (uint256);

    function get(uint256 index) external view returns (Meta memory);
}

/// @title dynamic collection of metadata
contract MetaSet is OneOwner, MetaCollection {
    uint256 private _elementCount;

    mapping(uint256 => Meta) private _elementMap;

    mapping(bytes32 => uint256) private _elementPresent;

    constructor() {
        _elementCount = 0;
    }

    modifier requireValidIndex(uint256 index) {
        if (index == 0 || index > _elementCount) revert IndexInvalid(index);
        _;
    }

    /// @notice add meta
    /// @param _element the meta
    /// @return uint256 the elementId of the meta
    function add(Meta memory _element) external onlyOwner returns (uint256) {
        uint256 elementIndex = ++_elementCount;
        _elementMap[elementIndex] = _element;
        bytes32 _elementHash = getHash(_element);
        if (_elementPresent[_elementHash] > 0) revert HashCollision(_elementHash);
        _elementPresent[_elementHash] = elementIndex;
        emit MetaAdded(_elementHash);
        return elementIndex;
    }

    function erase(Meta memory _meta) public onlyOwner returns (bool) {
        bytes32 metaHash = getHash(_meta);
        uint256 index = _elementPresent[metaHash];
        return erase(index);
    }

    /// @notice erase a meta
    /// @param _index the index to remove
    /// @return bool True if element was removed
    function erase(uint256 _index) public onlyOwner returns (bool) {
        Meta memory meta = _elementMap[_index];
        bytes32 metaHash = getHash(meta);
        uint256 elementIndex = _elementPresent[metaHash];
        if (elementIndex > 0 && elementIndex == _index) {
            Meta memory _lastMeta = _elementMap[_elementCount];
            _elementMap[elementIndex] = _lastMeta;
            bytes32 _lastMetaHash = getHash(_lastMeta);
            _elementPresent[_lastMetaHash] = elementIndex;
            _elementMap[_elementCount] = Meta("", "");
            _elementPresent[metaHash] = 0;
            delete _elementMap[_elementCount];
            delete _elementPresent[metaHash];
            _elementCount--;
            emit MetaRemoved(metaHash);
            return true;
        }
        return false;
    }

    /// @return uint256 The size of the set
    function size() external view returns (uint256) {
        return _elementCount;
    }

    /// @param index The index to return
    /// @return address The requested address
    function get(uint256 index) external view requireValidIndex(index) returns (Meta memory) {
        return _elementMap[index];
    }

    /// @param _meta The element to test
    /// @return bool True if address is contained
    function contains(Meta memory _meta) external view returns (bool) {
        return find(_meta) > 0;
    }

    /// @param _meta The element to find
    /// @return uint256 The index associated with element
    function find(Meta memory _meta) public view returns (uint256) {
        bytes32 metaHash = getHash(_meta);
        return _elementPresent[metaHash];
    }
}

// SPDX-License-Identifier: BSD-3-Clause
/*
 *                          88  88                                   88
 *                          88  88                            ,d     ""
 *                          88  88                            88
 *  ,adPPYba,   ,adPPYba,   88  88   ,adPPYba,   ,adPPYba,  MM88MMM  88  8b       d8   ,adPPYba,
 * a8"     ""  a8"     "8a  88  88  a8P_____88  a8"     ""    88     88  `8b     d8'  a8P_____88
 * 8b          8b       d8  88  88  8PP"""""""  8b            88     88   `8b   d8'   8PP"""""""
 * "8a,   ,aa  "8a,   ,a8"  88  88  "8b,   ,aa  "8a,   ,aa    88,    88    `8b,d8'    "8b,   ,aa
 *  `"Ybbd8"'   `"YbbdP"'   88  88   `"Ybbd8"'   `"Ybbd8"'    "Y888  88      "8"       `"Ybbd8"'
 *
 */
/*
 * BSD 3-Clause License
 *
 * Copyright (c) 2023, collective
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
pragma solidity ^0.8.15;

import { OneOwner } from "../../contracts/access/OneOwner.sol";

/// @notice The executable transaction
struct Transaction {
    /// @notice target for call instruction
    address target;
    /// @notice value to pass
    uint256 value;
    /// @notice signature for call
    string signature;
    /// @notice call data of the call
    bytes _calldata;
    /// @notice future dated start time for call within the TimeLocked grace period
    uint256 scheduleTime;
}

// solhint-disable-next-line func-visibility
function getHash(Transaction memory transaction) pure returns (bytes32) {
    return keccak256(abi.encode(transaction));
}

interface TransactionCollection {
    error InvalidTransaction(uint256 index);
    error HashCollision(bytes32 txId);

    event TransactionAdded(bytes32 transactionHash);
    event TransactionRemoved(bytes32 transactionHash);

    function add(Transaction memory transaction) external returns (uint256);

    function size() external view returns (uint256);

    function get(uint256 index) external view returns (Transaction memory);

    function erase(uint256 _index) external returns (bool);
}

/// @title dynamic collection of transaction
contract TransactionSet is OneOwner, TransactionCollection {
    uint256 private _elementCount;

    mapping(uint256 => Transaction) private _elementMap;
    mapping(bytes32 => uint256) private _elementPresent;

    constructor() {
        _elementCount = 0;
    }

    modifier requireValidIndex(uint256 index) {
        if (index == 0 || index > _elementCount) revert InvalidTransaction(index);
        _;
    }

    /// @notice add transaction
    /// @param _element the transaction
    /// @return uint256 the elementId of the transaction
    function add(Transaction memory _element) external onlyOwner returns (uint256) {
        uint256 elementIndex = ++_elementCount;
        _elementMap[elementIndex] = _element;
        bytes32 _elementHash = getHash(_element);
        if (_elementPresent[_elementHash] > 0) revert HashCollision(_elementHash);
        _elementPresent[_elementHash] = elementIndex;
        emit TransactionAdded(_elementHash);
        return elementIndex;
    }

    function erase(Transaction memory _transaction) public onlyOwner returns (bool) {
        bytes32 transactionHash = getHash(_transaction);
        uint256 index = _elementPresent[transactionHash];
        return erase(index);
    }

    /// @notice erase a transaction
    /// @param _index the index to remove
    /// @return bool True if element was removed
    function erase(uint256 _index) public onlyOwner returns (bool) {
        Transaction memory transaction = _elementMap[_index];
        bytes32 transactionHash = getHash(transaction);
        uint256 elementIndex = _elementPresent[transactionHash];
        if (elementIndex > 0 && elementIndex == _index) {
            Transaction memory _lastTransaction = _elementMap[_elementCount];
            _elementMap[elementIndex] = _lastTransaction;
            bytes32 _lastTransactionHash = getHash(_lastTransaction);
            _elementPresent[_lastTransactionHash] = elementIndex;
            _elementMap[_elementCount] = Transaction(address(0x0), 0, "", "", 0);
            _elementPresent[transactionHash] = 0;
            delete _elementMap[_elementCount];
            delete _elementPresent[transactionHash];
            _elementCount--;
            emit TransactionRemoved(transactionHash);
            return true;
        }
        return false;
    }

    /// @return uint256 The size of the set
    function size() external view returns (uint256) {
        return _elementCount;
    }

    /// @param index The index to return
    /// @return address The requested address
    function get(uint256 index) external view requireValidIndex(index) returns (Transaction memory) {
        return _elementMap[index];
    }

    /// @param _transaction The element to test
    /// @return bool True if address is contained
    function contains(Transaction memory _transaction) external view returns (bool) {
        return find(_transaction) > 0;
    }

    /// @param _transaction The element to find
    /// @return uint256 The index associated with element
    function find(Transaction memory _transaction) public view returns (uint256) {
        bytes32 transactionHash = getHash(_transaction);
        return _elementPresent[transactionHash];
    }
}