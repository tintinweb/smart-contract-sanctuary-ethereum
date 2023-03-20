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

/// @title Interface for mutable objects
/// @notice used to determine if a class is modifiable
/// @custom:type interface
interface Mutable {
    error NotFinal();
    error ContractFinal();

    /// @return bool True if this object is final
    function isFinal() external view returns (bool);
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

abstract contract OwnableInitializable {
    error NotInitialized();
    error OwnerInitialized(address owner);
    error NotOwner(address sender);

    event OwnershipTransferred(address _from, address _to);

    address internal _owner;

    modifier onlyInitialized() {
        if (_owner == address(0x0)) revert NotInitialized();
        _;
    }

    modifier notInitialized() {
        if (_owner != address(0x0)) revert OwnerInitialized(_owner);
        _;
    }

    modifier onlyOwner() {
        if (owner() != msg.sender) revert NotOwner(msg.sender);
        _;
    }

    function ownerInitialize(address _delegateOwner) internal notInitialized {
        _owner = _delegateOwner;
        emit OwnershipTransferred(address(0x0), _owner);
    }

    function owner() public view onlyInitialized returns (address) {
        return _owner;
    }

    function transferOwnership(address _delegateOwner) public onlyOwner {
        address _current = _owner;
        _owner = _delegateOwner;
        emit OwnershipTransferred(_current, _owner);
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

/// @title requirement for Versioned contract
/// @custom:type interface
interface Versioned {

    function version() external pure returns (uint32);
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

import { Constant } from "../../contracts/Constant.sol";
import { Versioned } from "../../contracts/access/Versioned.sol";

/// @title Versioned contract
abstract contract VersionedContract is Versioned {
    /// @notice return the version number of this contract
    /// @return uint32 the version number
    function version() external pure returns (uint32) {
        return Constant.CURRENT_VERSION;
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

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

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
contract AddressSet is Ownable, AddressCollection {
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

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

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
contract ChoiceSet is Ownable, ChoiceCollection {
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

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

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
contract MetaSet is Ownable, MetaCollection {
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

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

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
contract TransactionSet is Ownable, TransactionCollection {
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

import { IERC165 } from "@openzeppelin/contracts/interfaces/IERC165.sol";

import { VoterClass } from "../community/VoterClass.sol";
import { AddressCollection } from "../../contracts/collection/AddressSet.sol";

/// @title CommunityClass interface
/// @notice defines the configurable parameters for a community
/// @custom:type interface
interface CommunityClass is VoterClass {
    // setup errors
    error SupervisorListEmpty();
    error GasUsedRebateMustBeLarger(uint256 gasUsedRebate, uint256 minimumRebate);
    error BaseFeeRebateMustBeLarger(uint256 baseFee, uint256 minimumBaseFee);
    error VoteWeightMustBeNonZero();
    error MinimumDelayExceedsMaximum(uint256 delay, uint256 minimumDelay);
    error MaximumDelayNotPermitted(uint256 delay, uint256 maximumDelay);
    error MinimumDurationExceedsMaximum(uint256 duration, uint256 minimumDuration);
    error MaximumDurationNotPermitted(uint256 duration, uint256 maximumDuration);
    error MinimumQuorumNotPermitted(uint256 quorum, uint256 minimumProjectQuorum);

    /// @notice get the project vote delay requirement
    /// @return uint256 the least vote delay allowed for any vote
    function minimumVoteDelay() external view returns (uint256);

    /// @notice get the project vote delay maximum
    /// @return uint256 the max vote delay allowed for any vote
    function maximumVoteDelay() external view returns (uint256);

    /// @notice get the vote duration minimum in seconds
    /// @return uint256 the least duration of a vote in seconds
    function minimumVoteDuration() external view returns (uint256);

    /// @notice get the vote duration maximum in seconds
    /// @return uint256 the vote duration of a vote in seconds
    function maximumVoteDuration() external view returns (uint256);

    /// @notice get the project quorum requirement
    /// @return uint256 the least quorum allowed for any vote
    function minimumProjectQuorum() external view returns (uint256);

    /// @notice maximum gas used rebate
    /// @return uint256 the maximum rebate
    function maximumGasUsedRebate() external view returns (uint256);

    /// @notice maximum base fee rebate
    /// @return uint256 the base fee rebate
    function maximumBaseFeeRebate() external view returns (uint256);

    /// @notice return the community supervisors
    /// @return AddressSet the supervisor set
    function communitySupervisorSet() external view returns (AddressCollection);

    /// @notice determine if adding a proposal is approved for this voter
    /// @param _sender The address of the sender
    /// @return bool true if this address is approved
    function canPropose(address _sender) external view returns (bool);
}

interface WeightedCommunityClass is CommunityClass {
    /// @notice create a new community class representing community preferences
    /// @param _voteWeight the weight of a vote
    /// @param _minimumQuorum the least possible quorum for any vote
    /// @param _minimumDelay the least possible vote delay
    /// @param _maximumDelay the least possible vote delay
    /// @param _minimumDuration the least possible voting duration
    /// @param _maximumDuration the least possible voting duration
    /// @param _gasUsedRebate The maximum rebate for gas used
    /// @param _baseFeeRebate The maximum base fee rebate
    /// @param _supervisorList the list of supervisors for this project
    function initialize(
        uint256 _voteWeight,
        uint256 _minimumQuorum,
        uint256 _minimumDelay,
        uint256 _maximumDelay,
        uint256 _minimumDuration,
        uint256 _maximumDuration,
        uint256 _gasUsedRebate,
        uint256 _baseFeeRebate,
        AddressCollection _supervisorList
    ) external;

    /// @notice reset voting parameters for upgrade
    /// @param _voteWeight the weight of a vote
    /// @param _minimumQuorum the least possible quorum for any vote
    /// @param _minimumDelay the least possible vote delay
    /// @param _maximumDelay the least possible vote delay
    /// @param _minimumDuration the least possible voting duration
    /// @param _maximumDuration the least possible voting duration
    /// @param _gasUsedRebate The maximum rebate for gas used
    /// @param _baseFeeRebate The maximum base fee rebate
    /// @param _supervisorList the list of supervisors for this project
    function upgrade(
        uint256 _voteWeight,
        uint256 _minimumQuorum,
        uint256 _minimumDelay,
        uint256 _maximumDelay,
        uint256 _minimumDuration,
        uint256 _maximumDuration,
        uint256 _gasUsedRebate,
        uint256 _baseFeeRebate,
        AddressCollection _supervisorList
    ) external;

    /// @notice return voting weight of each confirmed share
    /// @return uint256 weight applied to one share
    function weight() external view returns (uint256);
}

interface ProjectCommunityClass is WeightedCommunityClass {
    /// @notice create a new community class representing community preferences
    /// @param _contract the token project contract address
    /// @param _voteWeight the weight of a vote
    /// @param _minimumQuorum the least possible quorum for any vote
    /// @param _minimumDelay the least possible vote delay
    /// @param _maximumDelay the least possible vote delay
    /// @param _minimumDuration the least possible voting duration
    /// @param _maximumDuration the least possible voting duration
    /// @param _gasUsedRebate The maximum rebate for gas used
    /// @param _baseFeeRebate The maximum base fee rebate
    /// @param _supervisorList the list of supervisors for this project
    function initialize(
        address _contract,
        uint256 _voteWeight,
        uint256 _minimumQuorum,
        uint256 _minimumDelay,
        uint256 _maximumDelay,
        uint256 _minimumDuration,
        uint256 _maximumDuration,
        uint256 _gasUsedRebate,
        uint256 _baseFeeRebate,
        AddressCollection _supervisorList
    ) external;
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

import { IERC165 } from "@openzeppelin/contracts/interfaces/IERC165.sol";

import { Mutable } from "../../contracts/access/Mutable.sol";
import { Versioned } from "../../contracts/access/Versioned.sol";

/// @title VoterClass interface
/// @notice The VoterClass interface defines the requirements for specifying a
/// population or grouping of acceptable voting wallets
/// @dev The VoterClass is stateless and therefore does not require any special
/// privledges.   It can be called by anyone.
/// @custom:type interface
interface VoterClass is Mutable, Versioned, IERC165 {
    error NotVoter(address wallet);
    error EmptyCommunity();
    error UnknownToken(uint256 tokenId);

    /// @notice test if wallet represents an allowed voter for this class
    /// @return bool true if wallet is a voter
    function isVoter(address _wallet) external view returns (bool);

    /// @notice discover an array of shareIds associated with the specified wallet
    /// @return uint256[] array in memory of share ids
    function discover(address _wallet) external view returns (uint256[] memory);

    /// @notice confirm shareid is associated with wallet for voting
    /// @return uint256 The number of weighted votes confirmed
    function confirm(address _wallet, uint256 shareId) external returns (uint256);

    /// @notice return the name of this implementation
    /// @return string memory representation of name
    function name() external pure returns (string memory);
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

import { IERC165 } from "@openzeppelin/contracts/interfaces/IERC165.sol";
import { ERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { Constant } from "../../contracts/Constant.sol";
import { Storage } from "../../contracts/storage/Storage.sol";
import { MetaStorage } from "../../contracts/storage/MetaStorage.sol";
import { Governance } from "../../contracts/governance/Governance.sol";
import { VoteStrategy } from "../../contracts/governance/VoteStrategy.sol";
import { CommunityClass } from "../../contracts/community/CommunityClass.sol";
import { TimeLocker } from "../../contracts/treasury/TimeLocker.sol";
import { Versioned } from "../../contracts/access/Versioned.sol";
import { VersionedContract } from "../../contracts/access/VersionedContract.sol";
import { Transaction, getHash } from "../../contracts/collection/TransactionSet.sol";
import { Choice } from "../../contracts/collection/ChoiceSet.sol";
import { AddressCollection } from "../../contracts/collection/AddressSet.sol";

/// @notice bounded gas rebate calculation
/// @param startGas the initial value of gasleft() function
/// @param balance maximum balance of WEI to spend
/// @param _maximumBaseFeeRebate maximum base fee rebate
/// @param _maximumGasUsedRebate maximum gas used
/// @return rebate The rebate
/// @return gasUsed The total gas used from gasleft to this call
// solhint-disable-next-line func-visibility
function calculateGasRebate(
    uint256 startGas,
    uint256 balance,
    uint256 _maximumBaseFeeRebate,
    uint256 _maximumGasUsedRebate
) view returns (uint256 rebate, uint256 gasUsed) {
    uint256 permittedBaseFee = Math.min(block.basefee, _maximumBaseFeeRebate);
    uint256 permittedGasPrice = Math.min(tx.gasprice, permittedBaseFee + Constant.MAXIMUM_REBATE_PRIORITY_FEE);

    uint256 totalGasUsed = startGas - gasleft();

    uint256 gasUsedForRebate = Math.min(totalGasUsed + Constant.REBATE_BASE_GAS, _maximumGasUsedRebate);
    uint256 rebateQuantity = Math.min(permittedGasPrice * gasUsedForRebate, balance);
    return (rebateQuantity, totalGasUsed);
}

/// @title Collective Governance implementation
/// @notice Governance contract implementation for Collective.   This contract implements voting by
/// groups of pooled voters, open voting or based on membership, such as class members who hold a specific
/// ERC-721 token in their wallet.
/// Creating a Vote is a three step process
///
/// First, propose the vote.  Next, Configure the vote.  Finally, start the vote.
///
/// Voting may proceed according to the conditions established during configuration.
///
/// @dev The VoterClass is common to all proposed votes as are the project supervisors.   Individual supervisors may
/// be configured as part of the proposal creation workflow but project supervisors are always included.
contract CollectiveGovernance is VoteStrategy, Governance, ERC165, VersionedContract {
    string public constant NAME = "collective governance";

    CommunityClass public immutable _communityClass;

    Storage public immutable _storage;

    TimeLocker public immutable _timeLock;

    /// @notice voting is open or not
    mapping(uint256 => bool) private isVoteOpenByProposalId;

    /// @notice create a new collective governance contract
    /// @dev This should be invoked through the GovernanceBuilder.  Gas Rebate
    /// is contingent on contract being funded through a transfer.
    /// @param _class the VoterClass for this project
    /// @param _governanceStorage The storage contract for this governance

    constructor(CommunityClass _class, Storage _governanceStorage, TimeLocker _timeLocker) {
        _communityClass = _class;
        _storage = _governanceStorage;
        _timeLock = _timeLocker;
    }

    modifier requireNotFinal(uint256 _proposalId) {
        if (_storage.isFinal(_proposalId)) revert VoteFinal(_proposalId);
        _;
    }

    modifier requireVoteFinal(uint256 _proposalId) {
        if (!_storage.isFinal(_proposalId)) revert VoteNotFinal(_proposalId);
        _;
    }

    modifier requireVoteClosed(uint256 _proposalId) {
        if (isVoteOpenByProposalId[_proposalId]) revert VoteIsOpen(_proposalId);
        _;
    }

    modifier requireVoteOpen(uint256 _proposalId) {
        if (!isVoteOpenByProposalId[_proposalId]) revert VoteIsClosed(_proposalId);
        _;
    }

    modifier requireVoteAccepted(uint256 _proposalId) {
        if (_storage.isCancel(_proposalId)) revert VoteCancelled(_proposalId);
        if (_storage.isVeto(_proposalId)) revert VoteVetoed(_proposalId);
        _;
    }

    modifier requireSupervisor(uint256 _proposalId) {
        if (!_storage.isSupervisor(_proposalId, msg.sender)) revert NotSupervisor(_proposalId, msg.sender);
        _;
    }

    modifier requireSender(uint256 _proposalId) {
        if (_storage.getSender(_proposalId) != msg.sender) revert Storage.NotSender(_proposalId, msg.sender);
        _;
    }

    // @dev recieve funds for the purpose of offering a rebate on gas fees
    receive() external payable {
        emit RebateFund(msg.sender, msg.value, getRebateBalance());
    }

    // solhint-disable-next-line payable-fallback
    fallback() external {
        revert NotPermitted(msg.sender);
    }

    /// @notice propose a vote for the community
    /// @dev Only one new proposal is allowed per msg.sender
    /// @return uint256 The id of the new proposal
    function propose() external returns (uint256) {
        return _proposeVote(msg.sender);
    }

    /// @notice Attach a transaction to the specified proposal.
    ///         If successfull, it will be executed when voting is ended.
    /// @dev required prior to calling configure
    /// @param _proposalId the id of the proposal
    /// @param _target the target address for this transaction
    /// @param _value the value to pass to the call
    /// @param _signature the tranaction signature
    /// @param _calldata the call data to pass to the call
    /// @param _scheduleTime the expected call time, within the timelock grace,
    ///        for the transaction
    /// @return uint256 the transactionId
    function attachTransaction(
        uint256 _proposalId,
        address _target,
        uint256 _value,
        string memory _signature,
        bytes memory _calldata,
        uint256 _scheduleTime
    ) external requireSender(_proposalId) returns (uint256) {
        Transaction memory _transaction = Transaction(_target, _value, _signature, _calldata, _scheduleTime);
        bytes32 txHash = _timeLock.queueTransaction(
            _transaction.target,
            _transaction.value,
            _transaction.signature,
            _transaction._calldata,
            _transaction.scheduleTime
        );
        uint256 transactionId = _storage.addTransaction(_proposalId, _transaction, msg.sender);
        emit ProposalTransactionAttached(
            msg.sender,
            _proposalId,
            transactionId,
            _transaction.target,
            _transaction.value,
            _transaction.scheduleTime,
            txHash
        );
        return transactionId;
    }

    /// @notice set a choice by choice id
    /// @dev requires supervisor
    /// @param _proposalId the id of the proposal
    /// @param _name the name of the metadata field
    /// @param _description the detailed description of the choice
    /// @param _transactionId The id of the transaction to execute
    function addChoice(
        uint256 _proposalId,
        bytes32 _name,
        string memory _description,
        uint256 _transactionId
    ) external requireSender(_proposalId) returns (uint256) {
        Choice memory choice = Choice(_name, _description, _transactionId, "", 0);
        uint256 _choiceId = _storage.addChoice(_proposalId, choice, msg.sender);
        emit ProposalChoice(_proposalId, _choiceId, _name, _description, _transactionId);
        return _choiceId;
    }

    /// @notice configure an existing proposal by id
    /// @param _proposalId The numeric id of the proposed vote
    /// @param _quorumRequired The threshold of participation that is required for a successful conclusion of voting
    function configure(uint256 _proposalId, uint256 _quorumRequired) public requireSupervisor(_proposalId) {
        address _sender = msg.sender;
        _storage.setQuorumRequired(_proposalId, _quorumRequired, _sender);
        _storage.makeFinal(_proposalId, _sender);
        emit ProposalFinal(_proposalId, _quorumRequired);
    }

    /// @notice configure an existing proposal by id
    /// @param _proposalId The numeric id of the proposed vote
    /// @param _quorumRequired The threshold of participation that is required for a successful conclusion of voting
    /// @param _requiredDelay The minimum time required before the start of voting
    /// @param _requiredDuration The minimum time for voting to proceed before ending the vote is allowed
    function configure(
        uint256 _proposalId,
        uint256 _quorumRequired,
        uint256 _requiredDelay,
        uint256 _requiredDuration
    ) external requireSupervisor(_proposalId) {
        address _sender = msg.sender;
        _storage.setVoteDelay(_proposalId, _requiredDelay, _sender);
        _storage.setVoteDuration(_proposalId, _requiredDuration, _sender);
        configure(_proposalId, _quorumRequired);
        emit ProposalDelay(_requiredDelay, _requiredDuration);
    }

    /// @notice start the voting process by proposal id
    /// @param _proposalId The numeric id of the proposed vote
    function startVote(uint256 _proposalId) external requireVoteFinal(_proposalId) requireVoteAccepted(_proposalId) {
        if (_storage.quorumRequired(_proposalId) == Constant.UINT_MAX) revert QuorumNotConfigured(_proposalId);
        if (isVoteOpenByProposalId[_proposalId]) revert VoteIsOpen(_proposalId);
        isVoteOpenByProposalId[_proposalId] = true;
        emit VoteOpen(_proposalId);
    }

    /// @notice test if an existing proposal is open
    /// @param _proposalId The numeric id of the proposed vote
    /// @return bool True if the proposal is open
    function isOpen(uint256 _proposalId) external view returns (bool) {
        uint256 endTime = _storage.endTime(_proposalId);
        bool voteProceeding = !_storage.isCancel(_proposalId) && !_storage.isVeto(_proposalId);
        return isVoteOpenByProposalId[_proposalId] && getBlockTimestamp() < endTime && voteProceeding;
    }

    /// @notice end voting on an existing proposal by id
    /// @param _proposalId The numeric id of the proposed vote
    /// @dev it is not possible to end voting until the required duration has elapsed
    function endVote(uint256 _proposalId) public requireVoteOpen(_proposalId) {
        uint256 _endTime = _storage.endTime(_proposalId);
        if (_endTime > getBlockTimestamp() && !_storage.isVeto(_proposalId) && !_storage.isCancel(_proposalId))
            revert VoteInProgress(_proposalId);
        isVoteOpenByProposalId[_proposalId] = false;
        if (!_storage.isVeto(_proposalId) && getVoteSucceeded(_proposalId)) {
            executeTransaction(_proposalId);
        } else {
            cancelTransaction(_proposalId);
        }
        emit VoteClosed(_proposalId);
    }

    /// @notice cast an affirmative vote for the measure by id
    /// @param _proposalId The numeric id of the proposed vote
    /// @param _choiceId The choice to vote for
    function voteChoice(
        uint256 _proposalId,
        uint256 _choiceId
    ) public requireVoteFinal(_proposalId) requireVoteOpen(_proposalId) requireVoteAccepted(_proposalId) {
        uint256 startGas = gasleft();
        uint256[] memory _shareList = _communityClass.discover(msg.sender);
        for (uint256 i = 0; i < _shareList.length; i++) {
            _castVoteFor(_proposalId, _shareList[i], _choiceId);
        }
        sendGasRebate(msg.sender, startGas);
    }

    /// @notice cast an affirmative vote for the measure by id
    /// @param _proposalId The numeric id of the proposed vote
    /// @dev Auto discovery is attempted and if possible the method will proceed using the discovered shares
    function voteFor(uint256 _proposalId) external {
        voteChoice(_proposalId, 0);
    }

    /// @notice cast an affirmative vote for the measure by id
    /// @param _proposalId The numeric id of the proposed vote
    /// @param _shareList A array of tokens or shares that confer the right to vote
    function voteFor(uint256 _proposalId, uint256[] memory _shareList) external {
        voteFor(_proposalId, _shareList, 0);
    }

    /// @notice cast an affirmative vote for the measure by id
    /// @param _proposalId The numeric id of the proposed vote
    /// @param _tokenIdList A array of tokens or shares that confer the right to vote
    /// @param _choiceId The choice to vote for
    function voteFor(
        uint256 _proposalId,
        uint256[] memory _tokenIdList,
        uint256 _choiceId
    ) public requireVoteFinal(_proposalId) requireVoteOpen(_proposalId) requireVoteAccepted(_proposalId) {
        uint256 startGas = gasleft();
        for (uint256 i = 0; i < _tokenIdList.length; i++) {
            _castVoteFor(_proposalId, _tokenIdList[i], _choiceId);
        }
        sendGasRebate(msg.sender, startGas);
    }

    /// @notice cast an affirmative vote for the measure by id
    /// @param _proposalId The numeric id of the proposed vote
    /// @param _tokenId The id of a token or share representing the right to vote
    function voteFor(uint256 _proposalId, uint256 _tokenId) external {
        voteFor(_proposalId, _tokenId, 0);
    }

    /// @notice cast an affirmative vote for the measure by id
    /// @param _proposalId The numeric id of the proposed vote
    /// @param _tokenId The id of a token or share representing the right to vote
    /// @param _choiceId The choice to vote for
    function voteFor(
        uint256 _proposalId,
        uint256 _tokenId,
        uint256 _choiceId
    ) public requireVoteFinal(_proposalId) requireVoteOpen(_proposalId) requireVoteAccepted(_proposalId) {
        uint256 startGas = gasleft();
        _castVoteFor(_proposalId, _tokenId, _choiceId);
        sendGasRebate(msg.sender, startGas);
    }

    /// @notice cast an against vote by id
    /// @dev auto discovery is attempted and if possible the method will proceed using the discovered shares
    /// @param _proposalId The numeric id of the proposed vote
    function voteAgainst(
        uint256 _proposalId
    ) external requireVoteFinal(_proposalId) requireVoteOpen(_proposalId) requireVoteAccepted(_proposalId) {
        uint256 startGas = gasleft();
        uint256[] memory _shareList = _communityClass.discover(msg.sender);
        for (uint256 i = 0; i < _shareList.length; i++) {
            _castVoteAgainst(_proposalId, _shareList[i]);
        }
        sendGasRebate(msg.sender, startGas);
    }

    /// @notice cast an against vote by id
    /// @param _proposalId The numeric id of the proposed vote
    /// @param _shareList A array of tokens or shares that confer the right to vote
    function voteAgainst(
        uint256 _proposalId,
        uint256[] memory _shareList
    ) external requireVoteFinal(_proposalId) requireVoteOpen(_proposalId) requireVoteAccepted(_proposalId) {
        uint256 startGas = gasleft();
        for (uint256 i = 0; i < _shareList.length; i++) {
            _castVoteAgainst(_proposalId, _shareList[i]);
        }
        sendGasRebate(msg.sender, startGas);
    }

    /// @notice cast an against vote by id
    /// @param _proposalId The numeric id of the proposed vote
    /// @param _tokenId The id of a token or share representing the right to vote
    function voteAgainst(
        uint256 _proposalId,
        uint256 _tokenId
    ) external requireVoteFinal(_proposalId) requireVoteOpen(_proposalId) requireVoteAccepted(_proposalId) {
        uint256 startGas = gasleft();
        _castVoteAgainst(_proposalId, _tokenId);
        sendGasRebate(msg.sender, startGas);
    }

    /// @notice abstain from vote by id
    /// @dev auto discovery is attempted and if possible the method will proceed using the discovered shares
    /// @param _proposalId The numeric id of the proposed vote
    function abstainFrom(
        uint256 _proposalId
    ) external requireVoteFinal(_proposalId) requireVoteOpen(_proposalId) requireVoteAccepted(_proposalId) {
        uint256 startGas = gasleft();
        uint256[] memory _shareList = _communityClass.discover(msg.sender);
        for (uint256 i = 0; i < _shareList.length; i++) {
            _castAbstention(_proposalId, _shareList[i]);
        }
        sendGasRebate(msg.sender, startGas);
    }

    /// @notice abstain from vote by id
    /// @param _proposalId The numeric id of the proposed vote
    /// @param _shareList A array of tokens or shares that confer the right to vote
    function abstainFrom(
        uint256 _proposalId,
        uint256[] memory _shareList
    ) external requireVoteFinal(_proposalId) requireVoteOpen(_proposalId) requireVoteAccepted(_proposalId) {
        uint256 startGas = gasleft();
        for (uint256 i = 0; i < _shareList.length; i++) {
            _castAbstention(_proposalId, _shareList[i]);
        }
        sendGasRebate(msg.sender, startGas);
    }

    /// @notice abstain from vote by id
    /// @param _proposalId The numeric id of the proposed vote
    /// @param _tokenId The id of a token or share representing the right to vote
    function abstainFrom(
        uint256 _proposalId,
        uint256 _tokenId
    ) external requireVoteFinal(_proposalId) requireVoteOpen(_proposalId) requireVoteAccepted(_proposalId) {
        uint256 startGas = gasleft();
        _castAbstention(_proposalId, _tokenId);
        sendGasRebate(msg.sender, startGas);
    }

    /// @notice veto proposal by id
    /// @param _proposalId The numeric id of the proposed vote
    /// @dev transaction must be signed by a supervisor wallet
    function veto(
        uint256 _proposalId
    )
        external
        requireSupervisor(_proposalId)
        requireVoteFinal(_proposalId)
        requireVoteOpen(_proposalId)
        requireVoteAccepted(_proposalId)
    {
        _storage.veto(_proposalId, msg.sender);
        emit ProposalVeto(_proposalId, msg.sender);
    }

    /// @notice get the result of the vote
    /// @return bool True if the vote is closed and passed
    /// @dev This method will fail if the vote was vetoed
    function getVoteSucceeded(
        uint256 _proposalId
    ) public view requireVoteAccepted(_proposalId) requireVoteFinal(_proposalId) requireVoteClosed(_proposalId) returns (bool) {
        uint256 totalVotesCast = _storage.quorum(_proposalId);
        bool quorumRequirementMet = totalVotesCast >= _storage.quorumRequired(_proposalId);
        return
            quorumRequirementMet &&
            ((_storage.forVotes(_proposalId) > _storage.againstVotes(_proposalId)) || _storage.isChoiceVote(_proposalId));
    }

    /// @notice see ERC-165
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return
            interfaceId == type(Governance).interfaceId ||
            interfaceId == type(VoteStrategy).interfaceId ||
            interfaceId == type(Versioned).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @notice cancel a proposal if it is not yet open
    /// @dev proposal must be finalized and ready but voting must not yet be open
    /// @param _proposalId The numeric id of the proposed vote
    function cancel(uint256 _proposalId) public requireSupervisor(_proposalId) {
        uint256 _startTime = _storage.startTime(_proposalId);
        if (isVoteOpenByProposalId[_proposalId] || getBlockTimestamp() > _startTime)
            revert CancelNotPossible(_proposalId, msg.sender);
        uint256 transactionCount = _storage.transactionCount(_proposalId);
        for (uint256 tid = 0; tid < transactionCount; tid++) {
            Transaction memory transaction = _storage.getTransaction(_proposalId, tid);
            _timeLock.cancelTransaction(
                transaction.target,
                transaction.value,
                transaction.signature,
                transaction._calldata,
                transaction.scheduleTime
            );
            _storage.clearTransaction(_proposalId, tid, msg.sender);
            emit ProposalTransactionCancelled(
                _proposalId,
                tid,
                transaction.target,
                transaction.value,
                transaction.scheduleTime,
                getHash(transaction)
            );
        }
        _storage.cancel(_proposalId, msg.sender);
    }

    function executeTransaction(uint256 _proposalId) private {
        if (_storage.isExecuted(_proposalId)) revert TransactionExecuted(_proposalId);
        _storage.setExecuted(_proposalId);
        uint256 transactionCount = _storage.transactionCount(_proposalId);
        if (transactionCount > 0) {
            uint256 executedCount = 0;
            if (_storage.isChoiceVote(_proposalId)) {
                uint256 winningChoice = _storage.getWinningChoice(_proposalId);
                if (winningChoice == 0 || winningChoice > _storage.choiceCount(_proposalId))
                    revert InvalidChoice(_proposalId, winningChoice);
                Choice memory choice = _storage.getChoice(_proposalId, winningChoice);
                if (choice.transactionId > 0) {
                    executeTransaction(_proposalId, choice.transactionId, choice.txHash);
                    executedCount++;
                }

                emit WinningChoice(_proposalId, choice.name, choice.description, choice.transactionId, choice.voteCount);
            } else {
                for (uint256 transactionId = 1; transactionId <= transactionCount; transactionId++) {
                    executeTransaction(_proposalId, transactionId, "");
                    executedCount++;
                }
            }
            emit ProposalExecuted(_proposalId, executedCount);
        }
    }

    function executeTransaction(uint256 _proposalId, uint256 _transactionId, bytes32 _txHash) private {
        Transaction memory transaction = _storage.getTransaction(_proposalId, _transactionId);
        bytes32 txHash = getHash(transaction);
        if (_txHash != 0x0 && txHash != _txHash) revert TransactionSignatureNotMatching(_proposalId, _transactionId);
        if (txHash.length > 0 && _timeLock.queuedTransaction(txHash)) {
            _timeLock.executeTransaction(
                transaction.target,
                transaction.value,
                transaction.signature,
                transaction._calldata,
                transaction.scheduleTime
            );
            emit ProposalTransactionExecuted(
                _proposalId,
                _transactionId,
                transaction.target,
                transaction.value,
                transaction.scheduleTime,
                txHash
            );
        }
    }

    function cancelTransaction(uint256 _proposalId) private {
        uint256 transactionCount = _storage.transactionCount(_proposalId);
        if (transactionCount > 0) {
            for (uint256 tid = 1; tid <= transactionCount; tid++) {
                Transaction memory transaction = _storage.getTransaction(_proposalId, tid);
                bytes32 txHash = getHash(transaction);
                if (txHash.length > 0 && _timeLock.queuedTransaction(txHash)) {
                    _timeLock.cancelTransaction(
                        transaction.target,
                        transaction.value,
                        transaction.signature,
                        transaction._calldata,
                        transaction.scheduleTime
                    );
                }
            }
        }
    }

    /// @notice return the name of this implementation
    /// @return string memory representation of name
    function name() external pure virtual returns (string memory) {
        return NAME;
    }

    function sendGasRebate(address recipient, uint256 startGas) internal {
        uint256 balance = getRebateBalance();
        if (balance == 0) {
            return;
        }
        // determine rebate and transfer
        (uint256 rebate, uint256 gasUsed) = calculateGasRebate(
            startGas,
            balance,
            _communityClass.maximumBaseFeeRebate(),
            _communityClass.maximumGasUsedRebate()
        );
        payable(recipient).transfer(rebate);
        emit RebatePaid(recipient, rebate, gasUsed);
    }

    function _proposeVote(address _sender) private returns (uint256) {
        if (!_communityClass.canPropose(_sender)) revert NotPermitted(_sender);
        uint256 proposalId = _storage.initializeProposal(_sender);
        AddressCollection _supervisorSet = _communityClass.communitySupervisorSet();
        for (uint256 i = 1; i <= _supervisorSet.size(); ++i) {
            _storage.registerSupervisor(proposalId, _supervisorSet.get(i), true, _sender);
        }
        if (!_storage.isSupervisor(proposalId, _sender)) {
            _storage.registerSupervisor(proposalId, _sender, _sender);
        }
        emit ProposalCreated(_sender, proposalId);
        return proposalId;
    }

    function _castVoteFor(uint256 _proposalId, uint256 _tokenId, uint256 _choiceId) internal {
        uint256 voteCount = 0;
        voteCount = _storage.voteForByShare(_proposalId, msg.sender, _tokenId, _choiceId);
        if (voteCount > 0) {
            emit VoteStrategy.VoteCount(_proposalId, msg.sender, _tokenId, voteCount, 0);
        } else {
            revert VoteStrategy.NotVoter(_proposalId, msg.sender);
        }
    }

    function _castVoteAgainst(uint256 _proposalId, uint256 _tokenId) internal {
        uint256 count = _storage.voteAgainstByShare(_proposalId, msg.sender, _tokenId);
        if (count > 0) {
            emit VoteStrategy.VoteCount(_proposalId, msg.sender, _tokenId, 0, count);
        } else {
            revert VoteStrategy.NotVoter(_proposalId, msg.sender);
        }
    }

    function _castAbstention(uint256 _proposalId, uint256 _tokenId) internal {
        uint256 count = _storage.abstainForShare(_proposalId, msg.sender, _tokenId);
        if (count > 0) {
            emit VoteStrategy.VoteCount(_proposalId, msg.sender, _tokenId, 0, 0);
        } else {
            revert VoteStrategy.NotVoter(_proposalId, msg.sender);
        }
    }

    function getBlockTimestamp() internal view returns (uint256) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp;
    }

    function getRebateBalance() internal view returns (uint256) {
        return address(this).balance;
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
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { IERC165 } from "@openzeppelin/contracts/interfaces/IERC165.sol";

import { Versioned } from "../../contracts/access/Versioned.sol";
import { Constant } from "../../contracts/Constant.sol";

/// @title Governance interface
/// @notice Requirements for Governance implementation
/// @custom:type interface
interface Governance is Versioned, IERC165 {
    error NotEnoughChoices();
    error NotPermitted(address sender);
    error CancelNotPossible(uint256 proposalId, address sender);
    error NotSupervisor(uint256 proposalId, address sender);
    error VoteIsOpen(uint256 proposalId);
    error VoteIsClosed(uint256 proposalId);
    error VoteCancelled(uint256 proposalId);
    error VoteVetoed(uint256 proposalId);
    error VoteFinal(uint256 proposalId);
    error VoteNotFinal(uint256 proposalId);
    error ProposalNotSender(uint256 proposalId, address sender);
    error QuorumNotConfigured(uint256 proposalId);
    error VoteInProgress(uint256 proposalId);
    error TransactionExecuted(uint256 proposalId);
    error NotExecuted(uint256 proposalId);
    error InvalidChoice(uint256 proposalId, uint256 choiceId);
    error TransactionSignatureNotMatching(uint256 proposalId, uint256 transactionId);

    /// @notice A new proposal was created
    event ProposalCreated(address sender, uint256 proposalId);
    /// @notice transaction attached to proposal
    event ProposalTransactionAttached(
        address creator,
        uint256 proposalId,
        uint256 transactionId,
        address target,
        uint256 value,
        uint256 scheduleTime,
        bytes32 txHash
    );
    /// @notice transaction canceled on proposal
    event ProposalTransactionCancelled(
        uint256 proposalId,
        uint256 transactionId,
        address target,
        uint256 value,
        uint256 scheduleTime,
        bytes32 txHash
    );
    /// @notice transaction executed on proposal
    event ProposalTransactionExecuted(
        uint256 proposalId,
        uint256 transactionId,
        address target,
        uint256 value,
        uint256 scheduleTime,
        bytes32 txHash
    );

    /// @notice ProposalChoice Set
    event ProposalChoice(uint256 proposalId, uint256 choiceId, bytes32 name, string description, uint256 transactionId);
    /// @notice The proposal is final - vote is ready
    event ProposalFinal(uint256 proposalId, uint256 quorum);
    /// @notice Timing information
    event ProposalDelay(uint256 voteDelay, uint256 voteDuration);

    /// @notice The attached transactions are executed
    event ProposalExecuted(uint256 proposalId, uint256 executedTransactionCount);
    /// @notice The proposal has been vetoed
    event ProposalVeto(uint256 proposalId, address sender);
    /// @notice The contract has been funded to provide gas rebates
    event RebateFund(address sender, uint256 transfer, uint256 totalFund);
    /// @notice Gas rebate payment
    event RebatePaid(address recipient, uint256 rebate, uint256 gasPaid);

    /// @notice Winning choice in choice vote
    event WinningChoice(uint256 proposalId, bytes32 name, string description, uint256 transactionId, uint256 voteCount);

    /// @notice propose a vote for the community
    /// @return uint256 The id of the new proposal
    function propose() external returns (uint256);

    /// @notice Attach a transaction to the specified proposal.
    ///         If successfull, it will be executed when voting is ended.
    /// @dev required prior to calling configure
    /// @param _proposalId the id of the proposal
    /// @param _target the target address for this transaction
    /// @param _value the value to pass to the call
    /// @param _signature the tranaction signature
    /// @param _calldata the call data to pass to the call
    /// @param _scheduleTime the expected call time, within the timelock grace,
    ///        for the transaction
    /// @return uint256 the transactionId
    function attachTransaction(
        uint256 _proposalId,
        address _target,
        uint256 _value,
        string memory _signature,
        bytes memory _calldata,
        uint256 _scheduleTime
    ) external returns (uint256);

    /// @notice add a choice
    /// @dev requires supervisor
    /// @param _proposalId the id of the proposal
    /// @param _name the name of the metadata field
    /// @param _description the detailed description of the choice
    /// @param _transactionId The id of the transaction to execute
    /// @return uint256 The choiceId
    function addChoice(
        uint256 _proposalId,
        bytes32 _name,
        string memory _description,
        uint256 _transactionId
    ) external returns (uint256);

    /// @notice cancel a proposal if it is not yet open
    /// @param _proposalId The numeric id of the proposed vote
    function cancel(uint256 _proposalId) external;

    /// @notice configure an existing proposal by id
    /// @param _proposalId The numeric id of the proposed vote
    /// @param _quorumRequired The threshold of participation that is required for a successful conclusion of voting
    function configure(uint256 _proposalId, uint256 _quorumRequired) external;

    /// @notice configure an existing proposal by id
    /// @param _proposalId The numeric id of the proposed vote
    /// @param _quorumThreshold The threshold of participation that is required for a successful conclusion of voting
    /// @param _requiredDelay The minimum time required before the start of voting
    /// @param _requiredDuration The minimum time for voting to proceed before ending the vote is allowed
    function configure(uint256 _proposalId, uint256 _quorumThreshold, uint256 _requiredDelay, uint256 _requiredDuration) external;

    /// @notice return the name of this implementation
    /// @return string memory representation of name
    function name() external pure returns (string memory);

    /// @notice start the voting process by proposal id
    /// @param _proposalId The numeric id of the proposed vote
    function startVote(uint256 _proposalId) external;

    /// @notice test if an existing proposal is open
    /// @param _proposalId The numeric id of the proposed vote
    /// @return bool True if the proposal is open
    function isOpen(uint256 _proposalId) external view returns (bool);

    /// @notice end voting on an existing proposal by id
    /// @param _proposalId The numeric id of the proposed vote
    function endVote(uint256 _proposalId) external;
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

import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import { IERC165 } from "@openzeppelin/contracts/interfaces/IERC165.sol";
import { ERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import { CommunityClass } from "../../contracts/community/CommunityClass.sol";
import { Storage } from "../../contracts/storage/Storage.sol";
import { MetaStorage } from "../../contracts/storage/MetaStorage.sol";
import { TimeLocker } from "../../contracts/treasury/TimeLocker.sol";
import { Governance } from "../../contracts/governance/Governance.sol";
import { CollectiveGovernance } from "../../contracts/governance/CollectiveGovernance.sol";
import { Versioned } from "../../contracts/access/Versioned.sol";
import { VersionedContract } from "../../contracts/access/VersionedContract.sol";
import { OwnableInitializable } from "../../contracts/access/OwnableInitializable.sol";

/**
 * @title CollectiveGovernance creator
 *
 * @dev This library proxy is required by the code size limit to avoid including the constructor for
 * CollectiveGovernance in the Builder.  The GovernanceBuilder should be preferred for creating a new
 * instance of the contract.
 */
contract GovernanceFactory is VersionedContract, OwnableInitializable, UUPSUpgradeable, Initializable, ERC165 {
    event UpgradeAuthorized(address sender, address owner);

    function initialize() public initializer {
        ownerInitialize(msg.sender);
    }

    /// @notice create a new collective governance contract
    /// @dev this should be invoked through the GovernanceBuilder
    /// @param _class the VoterClass for this project
    /// @param _storage The storage contract for this governance
    /// @param _timeLock The timelock for the contract
    function create(CommunityClass _class, Storage _storage, TimeLocker _timeLock) external returns (Governance) {
        return new CollectiveGovernance(_class, _storage, _timeLock);
    }

    /// @notice see ERC-165
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return interfaceId == type(Versioned).interfaceId || super.supportsInterface(interfaceId);
    }

    /// see UUPSUpgradeable
    function _authorizeUpgrade(address _caller) internal virtual override(UUPSUpgradeable) onlyOwner {
        emit UpgradeAuthorized(_caller, owner());
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

/// @title VoteStrategy interface
/// Requirements for voting implementations in Collective Governance
/// @custom:type interface
interface VoteStrategy {
    /// @notice voting is open and ready on this proposal
    event VoteOpen(uint256 proposalId);
    /// @notice all voting is now closed for proposal
    event VoteClosed(uint256 proposalId);
    /// @notice a vote has been cast by wallet
    event VoteCount(uint256 proposalId, address wallet, uint256 shareId, uint256 count, uint256 againstCount);

    // setup errors
    error NotVoter(uint256 proposalId, address sender);

    /// @notice cast an affirmative vote for the measure by id
    /// @param _proposalId The numeric id of the proposed vote
    function voteFor(uint256 _proposalId) external;

    /// @notice cast an affirmative vote for the measure by id
    /// @param _proposalId The numeric id of the proposed vote
    /// @param _choiceId The choice to vote for
    function voteChoice(uint256 _proposalId, uint256 _choiceId) external;

    /// @notice cast an affirmative vote for the measure by id
    /// @param _proposalId The numeric id of the proposed vote
    /// @param _tokenId The id of a token or share representing the right to vote
    function voteFor(uint256 _proposalId, uint256 _tokenId) external;

    /// @notice cast an affirmative vote for the measure by id
    /// @param _proposalId The numeric id of the proposed vote
    /// @param _tokenId The id of a token or share representing the right to vote
    /// @param _choiceId The choice to vote for
    function voteFor(uint256 _proposalId, uint256 _tokenId, uint256 _choiceId) external;

    /// @notice cast an affirmative vote for the measure by id
    /// @param _proposalId The numeric id of the proposed vote
    /// @param _tokenIdList A array of tokens or shares that confer the right to vote
    function voteFor(uint256 _proposalId, uint256[] memory _tokenIdList) external;

    /// @notice cast an affirmative vote for the measure by id
    /// @param _proposalId The numeric id of the proposed vote
    /// @param _tokenIdList A array of tokens or shares that confer the right to vote
    /// @param _choiceId The choice to vote for
    function voteFor(uint256 _proposalId, uint256[] memory _tokenIdList, uint256 _choiceId) external;

    /// @notice cast an against vote by id
    /// @param _proposalId The numeric id of the proposed vote
    function voteAgainst(uint256 _proposalId) external;

    /// @notice cast an against vote by id
    /// @param _proposalId The numeric id of the proposed vote
    /// @param _tokenId The id of a token or share representing the right to vote
    function voteAgainst(uint256 _proposalId, uint256 _tokenId) external;

    /// @notice cast an against vote by id
    /// @param _proposalId The numeric id of the proposed vote
    /// @param _tokenIdList A array of tokens or shares that confer the right to vote
    function voteAgainst(uint256 _proposalId, uint256[] memory _tokenIdList) external;

    /// @notice abstain from vote by id
    /// @param _proposalId The numeric id of the proposed vote
    function abstainFrom(uint256 _proposalId) external;

    /// @notice abstain from vote by id
    /// @param _proposalId The numeric id of the proposed vote
    /// @param _tokenId The id of a token or share representing the right to vote
    function abstainFrom(uint256 _proposalId, uint256 _tokenId) external;

    /// @notice abstain from vote by id
    /// @param _proposalId The numeric id of the proposed vote
    /// @param _tokenIdList A array of tokens or shares that confer the right to vote
    function abstainFrom(uint256 _proposalId, uint256[] memory _tokenIdList) external;

    /// @notice veto proposal by id
    /// @param _proposalId The numeric id of the proposed vote
    /// @dev transaction must be signed by a supervisor wallet
    function veto(uint256 _proposalId) external;

    /// @notice get the result of the vote
    /// @return bool True if the vote is closed and passed
    /// @dev This method will fail if the vote was vetoed
    function getVoteSucceeded(uint256 _proposalId) external view returns (bool);
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

import { IERC165 } from "@openzeppelin/contracts/interfaces/IERC165.sol";

import { Versioned } from "../../contracts/access/Versioned.sol";
import { Meta, MetaCollection } from "../../contracts/collection/MetaSet.sol";

/// @title Metadata storage interface
/// @notice store community metadata
/// @custom:type interface
interface MetaStorage is Versioned, IERC165 {
    error StringSizeLimit(uint256 length);
    error IndexInvaliddataId(uint256 metadataId);

    event DescribeMeta(uint256 metadataId, string url, string description);
    event AddMeta(uint256 metadataId, uint256 metaId, bytes32 name, string value);

    struct MetaStore {
        /// @notice id of metadata store
        /// @dev implements a parity check to prevent accessing uninitialized storage
        uint256 id;
        /// @notice metadata description
        string description;
        /// @notice metadata url
        string url;
        /// arbitrary metadata
        MetaCollection meta;
    }

    /// @notice return the name of the community
    /// @return bytes32 the community name
    function community() external view returns (bytes32);

    /// @notice return the community url
    /// @return string memory representation of url
    function url() external view returns (string memory);

    /// @notice return community description
    /// @return string memory representation of community description
    function description() external view returns (string memory);

    /// @notice get the metadata url
    /// @param _metaId the id of the metadata
    /// @return string the url
    function url(uint256 _metaId) external returns (string memory);

    /// @notice set metadata
    /// @dev requires owner
    /// @param _metaId the id of the metadata
    /// @param _url the url
    /// @param _description the description
    function describe(uint256 _metaId, string memory _url, string memory _description) external;

    /// @notice get the metadata description
    /// @param _metaId the id of the metadata
    /// @return string the url
    function description(uint256 _metaId) external returns (string memory);

    /// @notice get the number of attached metadata
    /// @param _metaId the id of the metadata
    /// @return uint256 current number of meta elements
    function size(uint256 _metaId) external view returns (uint256);

    /// @notice attach arbitrary metadata to metadata
    /// @dev requires ownera
    /// @param _metaId the id of the metadata
    /// @param _name the name of the metadata field
    /// @param _value the value of the metadata
    /// @return uint256 the meta element id
    function add(uint256 _metaId, bytes32 _name, string memory _value) external returns (uint256);

    /// @notice get arbitrary metadata from metadata
    /// @param _metaId the id of the metadata
    /// @param _metaElementId the id of the metadata
    /// @return Meta the meta data
    function get(uint256 _metaId, uint256 _metaElementId) external returns (Meta memory);

    /// @notice return the name of this implementation
    /// @return string memory representation of name
    function name() external pure returns (string memory);
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

import { IERC165 } from "@openzeppelin/contracts/interfaces/IERC165.sol";

import { Versioned } from "../../contracts/access/Versioned.sol";
import { Transaction, TransactionCollection } from "../../contracts/collection/TransactionSet.sol";
import { Choice, ChoiceCollection } from "../../contracts/collection/ChoiceSet.sol";
import { CommunityClass } from "../../contracts/community/CommunityClass.sol";

/// @title Storage interface
/// @dev Eternal storage of strategy proxy
/// @notice provides the requirements for Storage contract implementation
/// @custom:type interface
interface Storage is Versioned, IERC165 {
    error NotSupervisor(uint256 proposalId, address supervisor);
    error NotSender(uint256 proposalId, address sender);
    error SupervisorAlreadyRegistered(uint256 proposalId, address supervisor, address sender);
    error AlreadyVetoed(uint256 proposalId, address sender);
    error DelayNotPermitted(uint256 proposalId, uint256 quorum, uint256 minimumProjectQuorum);
    error DurationNotPermitted(uint256 proposalId, uint256 quorum, uint256 minimumProjectQuorum);
    error QuorumNotPermitted(uint256 proposalId, uint256 quorum, uint256 minimumProjectQuorum);
    error VoterClassNotFinal(string name, uint256 version);
    error NoProposal(address _wallet);
    error InvalidProposal(uint256 proposalId);
    error InvalidReceipt(uint256 proposalId, uint256 receiptId);
    error NeverVoted(uint256 proposalId, uint256 receiptId);
    error VoteRescinded(uint256 proposalId, uint256 receiptId);
    error NotVoter(uint256 proposalId, uint256 receiptId, address wallet);
    error AffirmativeVoteRequired(uint256 proposalId, uint256 receiptId);
    error TooManyProposals(address sender, uint256 lastProposalId);
    error InvalidTokenId(uint256 proposalId, address sender, uint256 tokenId);
    error TokenVoted(uint256 proposalId, address sender, uint256 tokenId);
    error InvalidTransaction(uint256 proposalId, uint256 transactionId);
    error MarkedExecuted(uint256 proposalId);
    error TokenIdIsNotValid(uint256 proposalId, uint256 tokenId);
    error VoteIsFinal(uint256 proposalId);
    error VoteNotFinal(uint256 proposalId);
    error UndoNotEnabled(uint256 proposalId);
    error ProjectSupervisor(uint256 proposalId, address supervisor);
    error VoteInProgress(uint256 proposalId);
    error VoteNotActive(uint256 proposalId, uint256 startTime, uint256 endTime);
    error ChoiceVoteRequiresSetup(uint256 proposalId);
    error NotChoiceVote(uint256 proposalId);
    error ChoiceRequired(uint256 proposalId);
    error ChoiceVoteCountInvalid(uint256 proposalId);
    error ChoiceNameRequired(uint256 proposalId);
    error StringSizeLimit(uint256 length);

    // event section
    event InitializeProposal(uint256 proposalId, address owner);
    event AddSupervisor(uint256 proposalId, address supervisor, bool isProject);
    event BurnSupervisor(uint256 proposalId, address supervisor);
    event SetQuorumRequired(uint256 proposalId, uint256 passThreshold);
    event SetVoteDelay(uint256 proposalId, uint256 voteDelay);
    event SetVoteDuration(uint256 proposalId, uint256 voteDuration);
    event AddChoice(
        uint256 proposalId,
        uint256 choiceId,
        bytes32 name,
        string description,
        uint256 transactionId,
        bytes32 txHash
    );
    event AddTransaction(
        uint256 proposalId,
        uint256 transactionId,
        address target,
        uint256 value,
        uint256 scheduleTime,
        bytes32 txHash
    );
    event ClearTransaction(uint256 proposalId, uint256 transactionId, uint256 scheduleTime, bytes32 txHash);
    event Executed(uint256 proposalId);

    event VoteCast(uint256 proposalId, address voter, uint256 shareId, uint256 totalVotesCast);
    event ChoiceVoteCast(uint256 proposalId, address voter, uint256 shareId, uint256 choiceId, uint256 totalVotesCast);
    event VoteVeto(uint256 proposalId, address supervisor);
    event VoteFinal(uint256 proposalId, uint256 startTime, uint256 endTime);
    event VoteCancel(uint256 proposalId, address supervisor);

    /// @notice The current state of a proposal.
    /// CONFIG indicates the proposal is currently mutable with building
    /// and setup operations underway.
    /// Both FINAL and CANCELLED are immutable states indicating the proposal is final,
    /// however the CANCELLED state indicates the proposal never entered a voting phase.
    enum Status {
        CONFIG,
        FINAL,
        CANCELLED
    }

    /// @notice Struct describing the data required for a specific vote.
    /// @dev proposal is only valid if id != 0 and proposal.id == id;
    struct Proposal {
        /// @notice Unique id for looking up a proposal
        uint256 id;
        /// @notice Creator of the proposal
        address proposalSender;
        /// @notice The number of votes in support of a proposal required in
        /// order for a quorum to be reached and for a vote to succeed
        uint256 quorumRequired;
        /// @notice The number of blocks to delay the first vote from voting open
        uint256 voteDelay;
        /// @notice The number of blocks duration for the vote, last vote must be cast prior
        uint256 voteDuration;
        /// @notice The time when voting begins
        uint256 startTime;
        /// @notice The time when voting ends
        uint256 endTime;
        /// @notice Current number of votes in favor of this proposal
        uint256 forVotes;
        /// @notice Current number of votes in opposition to this proposal
        uint256 againstVotes;
        /// @notice Current number of votes for abstaining for this proposal
        uint256 abstentionCount;
        /// @notice Flag marking whether the proposal has been vetoed
        bool isVeto;
        /// @notice Flag marking whether the proposal has been executed
        bool isExecuted;
        /// @notice current status for this proposal
        Status status;
        /// @notice table of mapped transactions
        TransactionCollection transaction;
        /// @notice table of mapped choices
        ChoiceCollection choice;
        /// @notice Receipts of ballots for the entire set of voters
        mapping(uint256 => Receipt) voteReceipt;
        /// @notice configured supervisors
        mapping(address => Supervisor) supervisorPool;
    }

    /// @notice Ballot receipt record for a voter
    struct Receipt {
        /// @notice address of voting wallet
        address wallet;
        /// @notice id of reserved shares
        uint256 shareId;
        /// @notice number of votes cast for
        uint256 shareFor;
        /// @notice The number of votes the voter had, which were cast
        uint256 votesCast;
        /// @noitce choiceId in the case of multi choice voting
        uint256 choiceId;
        /// @notice did the voter abstain
        bool abstention;
    }

    struct Supervisor {
        bool isEnabled;
        bool isProject;
    }

    /// @notice Register a new supervisor on the specified proposal.
    /// The supervisor has rights to add or remove voters prior to start of voting
    /// in a Voter Pool. The supervisor also has the right to veto the outcome of the vote.
    /// @dev requires proposal creator
    /// @param _proposalId the id of the proposal
    /// @param _supervisor the supervisor address
    /// @param _sender original wallet for this request
    function registerSupervisor(uint256 _proposalId, address _supervisor, address _sender) external;

    /// @notice Register a new supervisor on the specified proposal.
    /// The supervisor has rights to add or remove voters prior to start of voting
    /// in a Voter Pool. The supervisor also has the right to veto the outcome of the vote.
    /// @dev requires proposal creator
    /// @param _proposalId the id of the proposal
    /// @param _supervisor the supervisor address
    /// @param _isProject true if supervisor is project supervisor
    /// @param _sender original wallet for this request
    function registerSupervisor(uint256 _proposalId, address _supervisor, bool _isProject, address _sender) external;

    /// @notice remove a supervisor from the proposal along with its ability to change or veto
    /// @dev requires proposal creator
    /// @param _proposalId the id of the proposal
    /// @param _supervisor the supervisor address
    /// @param _sender original wallet for this request
    function burnSupervisor(uint256 _proposalId, address _supervisor, address _sender) external;

    /// @notice set the minimum number of participants for a successful outcome
    /// @dev requires supervisor
    /// @param _proposalId the id of the proposal
    /// @param _quorum the number required for quorum
    /// @param _sender original wallet for this request
    function setQuorumRequired(uint256 _proposalId, uint256 _quorum, address _sender) external;

    /// @notice set the delay period required to preceed the vote
    /// @dev requires supervisor
    /// @param _proposalId the id of the proposal
    /// @param _voteDelay the quorum number
    /// @param _sender original wallet for this request
    function setVoteDelay(uint256 _proposalId, uint256 _voteDelay, address _sender) external;

    /// @notice set the required duration for the vote
    /// @dev requires supervisor
    /// @param _proposalId the id of the proposal
    /// @param _voteDuration the quorum number
    /// @param _sender original wallet for this request
    function setVoteDuration(uint256 _proposalId, uint256 _voteDuration, address _sender) external;

    /// @notice get the number of attached choices
    /// @param _proposalId the id of the proposal
    /// @return uint current number of choices
    function choiceCount(uint256 _proposalId) external view returns (uint256);

    /// @notice set a choice by choice id
    /// @dev requires supervisor
    /// @param _proposalId the id of the proposal
    /// @param _choice the choice
    /// @param _sender The sender of the choice
    /// @return uint256 The choiceId
    function addChoice(uint256 _proposalId, Choice memory _choice, address _sender) external returns (uint256);

    /// @notice get the choice by id
    /// @param _proposalId the id of the proposal
    /// @param _choiceId the id of the choice
    /// @return Choice the choice
    function getChoice(uint256 _proposalId, uint256 _choiceId) external view returns (Choice memory);

    /// @notice return the choice with the highest vote count
    /// @dev quorum is ignored for this caluclation
    /// @param _proposalId the id of the proposal
    /// @return uint256 The winning choice
    function getWinningChoice(uint256 _proposalId) external view returns (uint256);

    /// @notice get the address of the proposal sender
    /// @param _proposalId the id of the proposal
    /// @return address the address of the sender
    function getSender(uint256 _proposalId) external view returns (address);

    /// @notice get the quorum required
    /// @param _proposalId the id of the proposal
    /// @return uint256 the number required for quorum
    function quorumRequired(uint256 _proposalId) external view returns (uint256);

    /// @notice get the vote delay
    /// @dev return value is seconds
    /// @param _proposalId the id of the proposal
    /// @return uint256 the delay
    function voteDelay(uint256 _proposalId) external view returns (uint256);

    /// @notice get the vote duration
    /// @dev return value is seconds
    /// @param _proposalId the id of the proposal
    /// @return uint256 the duration
    function voteDuration(uint256 _proposalId) external view returns (uint256);

    /// @notice get the start time
    /// @dev timestamp in epoch seconds since January 1, 1970
    /// @param _proposalId the id of the proposal
    /// @return uint256 the start time
    function startTime(uint256 _proposalId) external view returns (uint256);

    /// @notice get the end time
    /// @dev timestamp in epoch seconds since January 1, 1970
    /// @param _proposalId the id of the proposal
    /// @return uint256 the end time
    function endTime(uint256 _proposalId) external view returns (uint256);

    /// @notice get the for vote count
    /// @param _proposalId the id of the proposal
    /// @return uint256 the number of votes in favor
    function forVotes(uint256 _proposalId) external view returns (uint256);

    /// @notice get the vote count for a choice
    /// @param _proposalId the id of the proposal
    /// @param _choiceId the id of the choice
    /// @return uint256 the number of votes in favor
    function voteCount(uint256 _proposalId, uint256 _choiceId) external view returns (uint256);

    /// @notice get the against vote count
    /// @param _proposalId the id of the proposal
    /// @return uint256 the number of against votes
    function againstVotes(uint256 _proposalId) external view returns (uint256);

    /// @notice get the number of abstentions
    /// @param _proposalId the id of the proposal
    /// @return uint256 the number abstentions
    function abstentionCount(uint256 _proposalId) external view returns (uint256);

    /// @notice get the current number counting towards quorum
    /// @param _proposalId the id of the proposal
    /// @return uint256 the amount of participation
    function quorum(uint256 _proposalId) external view returns (uint256);

    /// @notice get the CommunityClass
    /// @return CommunityClass the voter class
    function communityClass() external view returns (CommunityClass);

    /// @notice test if the address is a supervisor on the specified proposal
    /// @param _proposalId the id of the proposal
    /// @param _supervisor the address to check
    /// @return bool true if the address is a supervisor
    function isSupervisor(uint256 _proposalId, address _supervisor) external view returns (bool);

    /// @notice test if address is a voter on the specified proposal
    /// @param _proposalId the id of the proposal
    /// @param _voter the address to check
    /// @return bool true if the address is a voter
    function isVoter(uint256 _proposalId, address _voter) external view returns (bool);

    /// @notice test if proposal is ready or in the setup phase
    /// @param _proposalId the id of the proposal
    /// @return bool true if the proposal is marked ready
    function isFinal(uint256 _proposalId) external view returns (bool);

    /// @notice test if proposal is cancelled
    /// @param _proposalId the id of the proposal
    /// @return bool true if the proposal is marked cancelled
    function isCancel(uint256 _proposalId) external view returns (bool);

    /// @notice test if proposal is veto
    /// @param _proposalId the id of the proposal
    /// @return bool true if the proposal is marked veto
    function isVeto(uint256 _proposalId) external view returns (bool);

    /// @notice test if proposal is a choice vote
    /// @param _proposalId the id of the proposal
    /// @return bool true if proposal is a choice vote
    function isChoiceVote(uint256 _proposalId) external view returns (bool);

    /// @notice get the id of the last proposal for sender
    /// @return uint256 the id of the most recent proposal for sender
    function latestProposal(address _sender) external view returns (uint256);

    /// @notice get the vote receipt
    /// @param _proposalId the id of the proposal
    /// @param _shareId the id of the share voted
    /// @return shareId the share id for the vote
    /// @return shareFor the shares cast in favor
    /// @return votesCast the number of votes cast
    /// @return choiceId the choice voted, 0 if not a choice vote
    /// @return isAbstention true if vote was an abstention
    function getVoteReceipt(
        uint256 _proposalId,
        uint256 _shareId
    ) external view returns (uint256 shareId, uint256 shareFor, uint256 votesCast, uint256 choiceId, bool isAbstention);

    /// @notice initialize a new proposal and return the id
    /// @param _sender the proposal sender
    /// @return uint256 the id of the proposal
    function initializeProposal(address _sender) external returns (uint256);

    /// @notice indicate the proposal is ready for voting and should be frozen
    /// @dev requires supervisor
    /// @param _proposalId the id of the proposal
    /// @param _sender original wallet for this request
    function makeFinal(uint256 _proposalId, address _sender) external;

    /// @notice cancel the proposal if it is not yet started
    /// @dev requires supervisor
    /// @param _proposalId the id of the proposal
    /// @param _sender original wallet for this request
    function cancel(uint256 _proposalId, address _sender) external;

    /// @notice veto the specified proposal
    /// @dev supervisor is required
    /// @param _proposalId the id of the proposal
    /// @param _sender the address of the veto sender
    function veto(uint256 _proposalId, address _sender) external;

    /// @notice cast an affirmative vote for the specified share
    /// @param _proposalId the id of the proposal
    /// @param _wallet the wallet represented for the vote
    /// @param _shareId the id of the share
    /// @return uint256 the number of votes cast
    function voteForByShare(uint256 _proposalId, address _wallet, uint256 _shareId) external returns (uint256);

    /// @notice cast an affirmative vote for the specified share
    /// @param _proposalId the id of the proposal
    /// @param _wallet the wallet represented for the vote
    /// @param _shareId the id of the share
    /// @param _choiceId The choice to vote for
    /// @return uint256 the number of votes cast
    function voteForByShare(uint256 _proposalId, address _wallet, uint256 _shareId, uint256 _choiceId) external returns (uint256);

    /// @notice cast an against vote for the specified share
    /// @param _proposalId the id of the proposal
    /// @param _wallet the wallet represented for the vote
    /// @param _shareId the id of the share
    /// @return uint256 the number of votes cast
    function voteAgainstByShare(uint256 _proposalId, address _wallet, uint256 _shareId) external returns (uint256);

    /// @notice cast an abstention for the specified share
    /// @param _proposalId the id of the proposal
    /// @param _wallet the wallet represented for the vote
    /// @param _shareId the id of the share
    /// @return uint256 the number of votes cast
    function abstainForShare(uint256 _proposalId, address _wallet, uint256 _shareId) external returns (uint256);

    /// @notice add a transaction to the specified proposal
    /// @param _proposalId the id of the proposal
    /// @param _transaction the transaction
    /// @param _sender for this proposal
    /// @return uint256 the id of the transaction that was added
    function addTransaction(uint256 _proposalId, Transaction memory _transaction, address _sender) external returns (uint256);

    /// @notice return the stored transaction by id
    /// @param _proposalId the proposal where the transaction is stored
    /// @param _transactionId The id of the transaction on the proposal
    /// @return Transaction the transaction
    function getTransaction(uint256 _proposalId, uint256 _transactionId) external view returns (Transaction memory);

    /// @notice clear a stored transaction
    /// @param _proposalId the proposal where the transaction is stored
    /// @param _transactionId The id of the transaction on the proposal
    function clearTransaction(uint256 _proposalId, uint256 _transactionId, address _sender) external;

    /// @notice set proposal state executed
    /// @param _proposalId the id of the proposal
    function setExecuted(uint256 _proposalId) external;

    /// @notice get the current state if executed or not
    /// @param _proposalId the id of the proposal
    /// @return bool true if already executed
    function isExecuted(uint256 _proposalId) external view returns (bool);

    /// @notice get the number of attached transactions
    /// @param _proposalId the id of the proposal
    /// @return uint256 current number of transactions
    function transactionCount(uint256 _proposalId) external view returns (uint256);

    /// @notice return the name of this implementation
    /// @return string memory representation of name
    function name() external pure returns (string memory);
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

/**
 * @notice TimeLock transactions until a future time.   This is useful to guarantee that a Transaction
 * is specified in advance of a vote and to make it impossible to execute before the end of voting.
 */
/// @custom:type interface
interface TimeLocker {
    /// @notice operation is not used or forbidden
    error NotPermitted(address sender);
    /// @notice A transaction has been queued previously
    error QueueCollision(bytes32 txHash);
    /// @notice The timestamp or nonce specified does not meet the requirements for the timelock
    error TimestampNotInLockRange(bytes32 txHash, uint256 timestamp, uint256 scheduleTime, uint256 lockStart, uint256 lockEnd);
    /// @notice The provided delay does not meet the requirements for the TimeLock
    error RequiredDelayNotInRange(uint256 lockDelay, uint256 minDelay, uint256 maxDelay);
    /// @notice It is impossible to execute a call which is not in the queue already
    error NotInQueue(bytes32 txHash);
    /// @notice The specified transaction is currently locked.  Caller must wait to scheduleTime
    error TransactionLocked(bytes32 txHash, uint256 untilTime);
    /// @notice The grace period is past and the transaction is lost
    error TransactionStale(bytes32 txHash);
    /// @notice Call failed
    error ExecutionFailed(bytes32 txHash);

    /// @notice logs the receipt of eth in the Timelock for purposes of depensing later
    event TimelockEth(address sender, uint256 amount);

    /// @notice named transaction was cancelled
    event CancelTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 scheduleTime
    );

    /// @notice named transaction was executed
    event ExecuteTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 scheduleTime
    );

    /// @notice specified transaction was queued
    event QueueTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 scheduleTime
    );

    /**
     * @notice Mark a transaction as queued for this time lock
     * @dev It is only possible to execute a queued transaction.   Queueing in the context of a TimeLock is
     * the process of identifying in advance or naming the transaction to be executed.  Nothing is actually queued.
     * @param _target the target address for this transaction
     * @param _value the value to pass to the call
     * @param _signature the tranaction signature
     * @param _calldata the call data to pass to the call
     * @param _scheduleTime the expected time when the _target should be available to call
     * @return bytes32 the hash value for the transaction used for the internal index
     */
    function queueTransaction(
        address _target,
        uint256 _value,
        string calldata _signature,
        bytes calldata _calldata,
        uint256 _scheduleTime
    ) external returns (bytes32);

    /**
     * @notice cancel a queued transaction from the timelock
     *
     * @dev this method unmarks the named transaction so that it may not be executed
     *
     * @param _target the target address for this transaction
     * @param _value the value to pass to the call
     * @param _signature the tranaction signature
     * @param _calldata the call data to pass to the call
     * @param _scheduleTime the expected time when the _target should be available to call
     */
    function cancelTransaction(
        address _target,
        uint256 _value,
        string calldata _signature,
        bytes calldata _calldata,
        uint256 _scheduleTime
    ) external returns (bytes32);

    /**
     * @notice Execute the scheduled transaction at the end of the time lock or scheduled time.
     * @dev It is only possible to execute a queued transaction.
     * @param _target the target address for this transaction
     * @param _value the value to pass to the call
     * @param _signature the tranaction signature
     * @param _calldata the call data to pass to the call
     * @param _scheduleTime the expected time when the _target should be available to call
     * @return bytes The return data from the executed call
     */
    function executeTransaction(
        address _target,
        uint256 _value,
        string calldata _signature,
        bytes calldata _calldata,
        uint256 _scheduleTime
    ) external payable returns (bytes memory);

    /**
     * @notice get a queued transaction
     * @param _txHash Transaction hash to check
     * @return bool True if transaction is queued and false otherwise
     */
    function queuedTransaction(bytes32 _txHash) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822.sol";
import "../ERC1967/ERC1967Upgrade.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is IERC1822Proxiable, ERC1967Upgrade {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}