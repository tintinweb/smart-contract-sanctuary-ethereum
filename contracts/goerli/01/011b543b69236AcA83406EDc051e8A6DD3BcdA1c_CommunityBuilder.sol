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

import { Mutable } from "../../contracts/access/Mutable.sol";

/// @title AlwaysFinal
/// @notice Marker indicating this contract is never mutable
contract AlwaysFinal is Mutable {
    /// @notice call to confirm mutability during configuration
    modifier onlyMutable() {
        revert ContractFinal();
        _;
    }

    modifier onlyFinal() {
        _;
    }

    /// @return bool True if this object is final
    function isFinal() external pure returns (bool) {
        return true;
    }

    /// @notice set the control object to final.
    /// @dev always reverts
    // solhint-disable-next-line no-empty-blocks
    function makeFinal() public virtual {
        revert ContractFinal();
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

import { Mutable } from "../../contracts/access/Mutable.sol";

/// @title ConfigurableMutable
/// @notice Allow configuration during a period of mutability that ends
/// when finalized
contract ConfigurableMutable is Mutable {
    bool internal contractFinal = false;

    /// @notice call to confirm mutability during configuration
    modifier onlyMutable() {
        if (contractFinal) revert ContractFinal();
        _;
    }

    modifier onlyFinal() {
        if (!contractFinal) revert NotFinal();
        _;
    }

    /// @return bool True if this object is final
    function isFinal() external view returns (bool) {
        return contractFinal;
    }

    /// @notice set the control object to final.
    /// no further change is allowed via onlyMutable
    function makeFinal() public virtual onlyMutable {
        contractFinal = true;
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

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC165 } from "@openzeppelin/contracts/interfaces/IERC165.sol";
import { ERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import { Constant } from "../../contracts/Constant.sol";
import { Versioned } from "../../contracts/access/Versioned.sol";
import { VersionedContract } from "../../contracts/access/VersionedContract.sol";
import { AddressCollection } from "../../contracts/collection/AddressSet.sol";
import { WeightedCommunityClass } from "../../contracts/community/CommunityClass.sol";
import { WeightedClassFactory, ProjectClassFactory } from "../../contracts/community/CommunityFactory.sol";
import { CommunityClassVoterPool } from "../../contracts/community/CommunityClassVoterPool.sol";
import { CommunityClassOpenVote } from "../../contracts/community/CommunityClassOpenVote.sol";
import { CommunityClassERC721 } from "../../contracts/community/CommunityClassERC721.sol";
import { CommunityClassClosedERC721 } from "../../contracts/community/CommunityClassClosedERC721.sol";

/// @title Community Creator
/// @notice This builder is for creating a community class for use with the Collective
/// Governance contract
contract CommunityBuilder is VersionedContract, ERC165, Ownable {
    string public constant NAME = "community builder";
    uint256 public constant DEFAULT_WEIGHT = 1;

    error CommunityTypeRequired();
    error CommunityTypeChange();
    error ProjectTokenRequired(address tokenAddress);
    error TokenThresholdRequired(uint256 tokenThreshold);
    error NonZeroWeightRequired(uint256 weight);
    error NonZeroQuorumRequired(uint256 quorum);
    error VoterRequired();
    error VoterPoolRequired();

    event CommunityClassInitialized(address sender);
    event CommunityClassType(CommunityType communityType);
    event CommunityVoter(address voter);
    event CommunityClassWeight(uint256 weight);
    event CommunityClassQuorum(uint256 quorum);
    event CommunityClassMinimumVoteDelay(uint256 delay);
    event CommunityClassMaximumVoteDelay(uint256 delay);
    event CommunityClassMinimumVoteDuration(uint256 duration);
    event CommunityClassMaximumVoteDuration(uint256 duration);
    event CommunityClassGasUsedRebate(uint256 gasRebate);
    event CommunityClassBaseFeeRebate(uint256 baseFeeRebate);
    event CommunityClassSupervisor(address supervisor);
    event CommunityClassCreated(address class);

    enum CommunityType {
        NONE,
        OPEN,
        POOL,
        ERC721,
        ERC721_CLOSED
    }

    struct CommunityProperties {
        uint256 weight;
        uint256 minimumProjectQuorum;
        uint256 minimumVoteDelay;
        uint256 maximumVoteDelay;
        uint256 minimumVoteDuration;
        uint256 maximumVoteDuration;
        uint256 maximumGasUsedRebate;
        uint256 maximumBaseFeeRebate;
        AddressCollection communitySupervisor;
        CommunityType communityType;
        address projectToken;
        uint256 tokenThreshold;
        AddressCollection poolSet;
    }

    mapping(address => CommunityProperties) private _buildMap;

    WeightedClassFactory private _weightedFactory;

    ProjectClassFactory private _projectFactory;

    constructor() {
        _weightedFactory = new WeightedClassFactory();
        _projectFactory = new ProjectClassFactory();
    }

    modifier requirePool() {
        CommunityProperties storage _properties = _buildMap[msg.sender];
        if (_properties.communityType != CommunityType.POOL) revert VoterPoolRequired();
        _;
    }

    modifier requireNone() {
        CommunityProperties storage _properties = _buildMap[msg.sender];
        if (_properties.communityType != CommunityType.NONE) revert CommunityTypeChange();
        _;
    }

    /**
     * reset the community class builder for this address
     *
     * @return CommunityBuilder - this contract
     */
    function aCommunity() external returns (CommunityBuilder) {
        reset();
        emit CommunityClassInitialized(msg.sender);
        return this;
    }

    /**
     * build an open community
     *
     * @return CommunityBuilder - this contract
     */
    function asOpenCommunity() external requireNone returns (CommunityBuilder) {
        CommunityProperties storage _properties = _buildMap[msg.sender];
        _properties.communityType = CommunityType.OPEN;
        emit CommunityClassType(CommunityType.OPEN);
        return this;
    }

    /**
     * build a pool community
     *
     * @return CommunityBuilder - this contract
     */
    function asPoolCommunity() external requireNone returns (CommunityBuilder) {
        CommunityProperties storage _properties = _buildMap[msg.sender];
        _properties.communityType = CommunityType.POOL;
        _properties.poolSet = Constant.createAddressSet();
        emit CommunityClassType(CommunityType.POOL);
        return this;
    }

    /**
     * build ERC-721 community
     *
     * @param project the token contract address
     *
     * @return CommunityBuilder - this contract
     */
    function asErc721Community(address project) external requireNone returns (CommunityBuilder) {
        CommunityProperties storage _properties = _buildMap[msg.sender];
        _properties.communityType = CommunityType.ERC721;
        _properties.projectToken = project;
        emit CommunityClassType(CommunityType.ERC721);
        return this;
    }

    /**
     * build Closed ERC-721 community
     *
     * @param project the token contract address
     * @param tokenThreshold the number of tokens required to propose
     *
     * @return CommunityBuilder - this contract
     */
    function asClosedErc721Community(address project, uint256 tokenThreshold) external requireNone returns (CommunityBuilder) {
        CommunityProperties storage _properties = _buildMap[msg.sender];
        _properties.communityType = CommunityType.ERC721_CLOSED;
        _properties.projectToken = project;
        _properties.tokenThreshold = tokenThreshold;
        emit CommunityClassType(CommunityType.ERC721_CLOSED);
        return this;
    }

    /**
     * append a voter for a pool community
     *
     * @param voter the wallet address
     *
     * @return CommunityBuilder - this contract
     */
    function withVoter(address voter) external requirePool returns (CommunityBuilder) {
        CommunityProperties storage _properties = _buildMap[msg.sender];
        _properties.poolSet.add(voter);
        emit CommunityVoter(voter);
        return this;
    }

    /**
     * set the voting weight for each authorized voter
     *
     * @param _weight the voting weight
     *
     * @return CommunityBuilder - this contract
     */
    function withWeight(uint256 _weight) external returns (CommunityBuilder) {
        CommunityProperties storage _properties = _buildMap[msg.sender];
        _properties.weight = _weight;
        emit CommunityClassWeight(_weight);
        return this;
    }

    /**
     * set the minimum quorum for this community
     *
     * @param _quorum the minimum quorum
     *
     * @return CommunityBuilder - this contract
     */
    function withQuorum(uint256 _quorum) external returns (CommunityBuilder) {
        CommunityProperties storage _properties = _buildMap[msg.sender];
        _properties.minimumProjectQuorum = _quorum;
        emit CommunityClassQuorum(_quorum);
        return this;
    }

    /**
     * set the minimum vote delay for the community
     *
     * @param _delay - minimum vote delay in Ethereum (epoch) seconds
     *
     * @return CommunityBuilder - this contract
     */
    function withMinimumVoteDelay(uint256 _delay) external returns (CommunityBuilder) {
        CommunityProperties storage _properties = _buildMap[msg.sender];
        _properties.minimumVoteDelay = _delay;
        emit CommunityClassMinimumVoteDelay(_delay);
        return this;
    }

    /**
     * set the maximum vote delay for the community
     *
     * @param _delay - maximum vote delay in Ethereum (epoch) seconds
     *
     * @return CommunityBuilder - this contract
     */
    function withMaximumVoteDelay(uint256 _delay) external returns (CommunityBuilder) {
        CommunityProperties storage _properties = _buildMap[msg.sender];
        _properties.maximumVoteDelay = _delay;
        emit CommunityClassMaximumVoteDelay(_delay);
        return this;
    }

    /**
     * set the minimum vote duration for the community
     *
     * @param _duration - minimum vote duration in Ethereum (epoch) seconds
     *
     * @return CommunityBuilder - this contract
     */
    function withMinimumVoteDuration(uint256 _duration) external returns (CommunityBuilder) {
        CommunityProperties storage _properties = _buildMap[msg.sender];
        _properties.minimumVoteDuration = _duration;
        emit CommunityClassMinimumVoteDuration(_duration);
        return this;
    }

    /**
     * set the maximum vote duration for the community
     *
     * @param _duration - maximum vote duration in Ethereum (epoch) seconds
     *
     * @return CommunityBuilder - this contract
     */
    function withMaximumVoteDuration(uint256 _duration) external returns (CommunityBuilder) {
        CommunityProperties storage _properties = _buildMap[msg.sender];
        _properties.maximumVoteDuration = _duration;
        emit CommunityClassMaximumVoteDuration(_duration);
        return this;
    }

    /**
     * set the maximum gas used rebate
     *
     * @param _gasRebate the gas used rebate
     *
     * @return CommunityBuilder - this contract
     */
    function withMaximumGasUsedRebate(uint256 _gasRebate) external returns (CommunityBuilder) {
        CommunityProperties storage _properties = _buildMap[msg.sender];
        _properties.maximumGasUsedRebate = _gasRebate;
        emit CommunityClassGasUsedRebate(_gasRebate);
        return this;
    }

    /**
     * set the maximum base fee rebate
     *
     * @param _baseFeeRebate the base fee rebate
     *
     * @return CommunityBuilder - this contract
     */
    function withMaximumBaseFeeRebate(uint256 _baseFeeRebate) external returns (CommunityBuilder) {
        CommunityProperties storage _properties = _buildMap[msg.sender];
        _properties.maximumBaseFeeRebate = _baseFeeRebate;
        emit CommunityClassBaseFeeRebate(_baseFeeRebate);
        return this;
    }

    /**
     * add community supervisor
     *
     * @param _supervisor the supervisor address
     *
     * @return CommunityBuilder - this contract
     */
    function withCommunitySupervisor(address _supervisor) external returns (CommunityBuilder) {
        CommunityProperties storage _properties = _buildMap[msg.sender];
        _properties.communitySupervisor.add(_supervisor);
        emit CommunityClassSupervisor(_supervisor);
        return this;
    }

    /**
     * Build the contract with the configured settings.
     *
     * @return address - The address of the newly created contract
     */
    function build() public returns (address) {
        CommunityProperties storage _properties = _buildMap[msg.sender];
        WeightedCommunityClass _proxy;
        if (_properties.weight < 1) revert NonZeroWeightRequired(_properties.weight);
        if (_properties.minimumProjectQuorum < 1) revert NonZeroQuorumRequired(_properties.minimumProjectQuorum);
        if (_properties.communityType == CommunityType.ERC721_CLOSED) {
            if (_properties.projectToken == address(0x0)) revert ProjectTokenRequired(_properties.projectToken);
            if (_properties.tokenThreshold == 0) revert TokenThresholdRequired(_properties.tokenThreshold);
            _proxy = _projectFactory.createClosedErc721(
                _properties.projectToken,
                _properties.tokenThreshold,
                _properties.weight,
                _properties.minimumProjectQuorum,
                _properties.minimumVoteDelay,
                _properties.maximumVoteDelay,
                _properties.minimumVoteDuration,
                _properties.maximumVoteDuration,
                _properties.maximumGasUsedRebate,
                _properties.maximumBaseFeeRebate,
                _properties.communitySupervisor
            );
        } else if (_properties.communityType == CommunityType.ERC721) {
            if (_properties.projectToken == address(0x0)) revert ProjectTokenRequired(_properties.projectToken);
            _proxy = _projectFactory.createErc721(
                _properties.projectToken,
                _properties.weight,
                _properties.minimumProjectQuorum,
                _properties.minimumVoteDelay,
                _properties.maximumVoteDelay,
                _properties.minimumVoteDuration,
                _properties.maximumVoteDuration,
                _properties.maximumGasUsedRebate,
                _properties.maximumBaseFeeRebate,
                _properties.communitySupervisor
            );
        } else if (_properties.communityType == CommunityType.OPEN) {
            _proxy = _weightedFactory.createOpenVote(
                _properties.weight,
                _properties.minimumProjectQuorum,
                _properties.minimumVoteDelay,
                _properties.maximumVoteDelay,
                _properties.minimumVoteDuration,
                _properties.maximumVoteDuration,
                _properties.maximumGasUsedRebate,
                _properties.maximumBaseFeeRebate,
                _properties.communitySupervisor
            );
        } else if (_properties.communityType == CommunityType.POOL) {
            CommunityClassVoterPool _pool = _weightedFactory.createVoterPool(
                _properties.weight,
                _properties.minimumProjectQuorum,
                _properties.minimumVoteDelay,
                _properties.maximumVoteDelay,
                _properties.minimumVoteDuration,
                _properties.maximumVoteDuration,
                _properties.maximumGasUsedRebate,
                _properties.maximumBaseFeeRebate,
                _properties.communitySupervisor
            );
            if (_properties.poolSet.size() == 0) revert VoterRequired();
            for (uint256 i = 1; i <= _properties.poolSet.size(); ++i) {
                _pool.addVoter(_properties.poolSet.get(i));
            }
            _pool.makeFinal();
            _proxy = _pool;
        } else {
            revert CommunityTypeRequired();
        }
        address payable proxyAddress = payable(address(_proxy));
        emit CommunityClassCreated(proxyAddress);
        return proxyAddress;
    }

    function name() external pure returns (string memory) {
        return NAME;
    }

    /// @notice see ERC-165
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return
            interfaceId == type(Versioned).interfaceId ||
            interfaceId == type(Ownable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function reset() public {
        CommunityProperties storage _properties = _buildMap[msg.sender];
        _properties.weight = DEFAULT_WEIGHT;
        _properties.communityType = CommunityType.NONE;
        _properties.minimumProjectQuorum = 0;
        _properties.minimumVoteDelay = Constant.MINIMUM_VOTE_DELAY;
        _properties.maximumVoteDelay = Constant.MAXIMUM_VOTE_DELAY;
        _properties.minimumVoteDuration = Constant.MINIMUM_VOTE_DURATION;
        _properties.maximumVoteDuration = Constant.MAXIMUM_VOTE_DURATION;
        _properties.maximumGasUsedRebate = Constant.MAXIMUM_REBATE_GAS_USED;
        _properties.maximumBaseFeeRebate = Constant.MAXIMUM_REBATE_BASE_FEE;
        _properties.communitySupervisor = Constant.createAddressSet();
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

import { IERC721 } from "@openzeppelin/contracts/interfaces/IERC721.sol";

import { AddressCollection } from "../../contracts/collection/AddressSet.sol";
import { CommunityClassERC721 } from "../../contracts/community/CommunityClassERC721.sol";

/// @title Closed ERC721 VoterClass
/// @notice similar to CommunityClassERC721 however proposals are only allowed for voters
contract CommunityClassClosedERC721 is CommunityClassERC721 {
    error RequiredParameterIsZero();

    // number of tokens required to propose
    uint256 public _tokenRequirement;

    /// @param _contract Address of the token contract
    /// @param _requirement The token requirement
    /// @param _voteWeight The integral weight to apply to each token held by the wallet
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
        uint256 _requirement,
        uint256 _voteWeight,
        uint256 _minimumQuorum,
        uint256 _minimumDelay,
        uint256 _maximumDelay,
        uint256 _minimumDuration,
        uint256 _maximumDuration,
        uint256 _gasUsedRebate,
        uint256 _baseFeeRebate,
        AddressCollection _supervisorList
    ) public requireNonZero(_requirement) {
        initialize(
            _contract,
            _voteWeight,
            _minimumQuorum,
            _minimumDelay,
            _maximumDelay,
            _minimumDuration,
            _maximumDuration,
            _gasUsedRebate,
            _baseFeeRebate,
            _supervisorList
        );
        _tokenRequirement = _requirement;
    }

    modifier requireNonZero(uint256 _requirement) {
        if (_requirement < 1) revert RequiredParameterIsZero();
        _;
    }

    /// @notice determine if adding a proposal is approved for this voter
    /// @return bool true if this address is approved
    function canPropose(address _wallet) external view virtual override(CommunityClassERC721) onlyFinal returns (bool) {
        uint256 balance = IERC721(_contractAddress).balanceOf(_wallet);
        return balance >= _tokenRequirement;
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

import { IERC721 } from "@openzeppelin/contracts/interfaces/IERC721.sol";
import { IERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

import { AlwaysFinal } from "../../contracts/access/AlwaysFinal.sol";
import { AddressCollection } from "../../contracts/collection/AddressSet.sol";
import { ProjectCommunityClass } from "../../contracts/community/CommunityClass.sol";
import { ScheduledCommunityClass } from "../../contracts/community/ScheduledCommunityClass.sol";

/// @title ERC721 Implementation of CommunityClass
/// @notice This contract implements a voter pool based on ownership of an ERC-721 token.
/// A class member is considered a voter if they have signing access to a wallet that is marked
/// ownerOf a token of the specified address
/// @dev ERC721Enumerable is supported for discovery, however if the token contract does not support enumeration
/// then vote by specific tokenId is still supported
contract CommunityClassERC721 is ScheduledCommunityClass, ProjectCommunityClass, AlwaysFinal {
    error ERC721EnumerableRequired(address contractAddress);

    string public constant NAME = "CommunityClassERC721";

    address internal _contractAddress;

    /// @param _contract Address of the token contract
    /// @param _voteWeight The integral weight to apply to each token held by the wallet
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
    ) public virtual {
        initialize(
            _voteWeight,
            _minimumQuorum,
            _minimumDelay,
            _maximumDelay,
            _minimumDuration,
            _maximumDuration,
            _gasUsedRebate,
            _baseFeeRebate,
            _supervisorList
        );
        _contractAddress = _contract;
    }

    /// @param _voteWeight The integral weight to apply to each token held by the wallet
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
    ) public virtual {
        initialize(
            _voteWeight,
            _minimumQuorum,
            _minimumDelay,
            _maximumDelay,
            _minimumDuration,
            _maximumDuration,
            _gasUsedRebate,
            _baseFeeRebate,
            _supervisorList,
            msg.sender
        );
    }

    modifier requireValidToken(uint256 _shareId) {
        if (_shareId == 0) revert UnknownToken(_shareId);
        _;
    }

    /// @notice determine if wallet holds at least one token from the ERC-721 contract
    /// @return bool true if wallet can sign for votes on this class
    function isVoter(address _wallet) public view onlyFinal returns (bool) {
        return IERC721(_contractAddress).balanceOf(_wallet) > 0;
    }

    /// @notice determine if adding a proposal is approved for this voter
    /// @return bool true if this address is approved
    function canPropose(address) external view virtual onlyFinal returns (bool) {
        return true;
    }

    /// @notice tabulate the number of votes available for the specific wallet and tokenId
    /// @param _wallet The wallet to test for ownership
    /// @param _tokenId The id of the token associated with the ERC-721 contract
    function votesAvailable(address _wallet, uint256 _tokenId) external view onlyFinal returns (uint256) {
        address tokenOwner = IERC721(_contractAddress).ownerOf(_tokenId);
        if (_wallet == tokenOwner) {
            return 1;
        }
        return 0;
    }

    /// @notice discover an array of tokenIds associated with the specified wallet
    /// @dev discovery requires support for ERC721Enumerable, otherwise execution will revert
    /// @return uint256[] array in memory of share ids
    function discover(address _wallet) external view onlyFinal returns (uint256[] memory) {
        bytes4 interfaceId721 = type(IERC721Enumerable).interfaceId;
        if (!IERC721(_contractAddress).supportsInterface(interfaceId721)) revert ERC721EnumerableRequired(_contractAddress);
        IERC721Enumerable enumContract = IERC721Enumerable(_contractAddress);
        IERC721 _nft = IERC721(_contractAddress);
        uint256 tokenBalance = _nft.balanceOf(_wallet);
        if (tokenBalance == 0) revert NotVoter(_wallet);
        uint256[] memory tokenIdList = new uint256[](tokenBalance);
        for (uint256 i = 0; i < tokenBalance; i++) {
            tokenIdList[i] = enumContract.tokenOfOwnerByIndex(_wallet, i);
        }
        return tokenIdList;
    }

    /// @notice confirm tokenId is associated with wallet for voting
    /// @dev does not require IERC721Enumerable, tokenId ownership is checked directly using ERC-721
    /// @return uint256 The number of weighted votes confirmed
    function confirm(address _wallet, uint256 _tokenId) external view onlyFinal requireValidToken(_tokenId) returns (uint256) {
        uint256 voteCount = this.votesAvailable(_wallet, _tokenId);
        if (voteCount == 0) revert NotVoter(_wallet);
        return weight() * voteCount;
    }

    /// @notice return the name of this implementation
    /// @return string memory representation of name
    function name() external pure virtual returns (string memory) {
        return NAME;
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

import { AddressCollection } from "../../contracts/collection/AddressSet.sol";
import { AlwaysFinal } from "../../contracts/access/AlwaysFinal.sol";
import { ScheduledCommunityClass } from "../../contracts/community/ScheduledCommunityClass.sol";

/// @notice OpenVote CommunityClass allows every wallet to participate in an open vote
contract CommunityClassOpenVote is ScheduledCommunityClass, AlwaysFinal {
    string public constant NAME = "CommunityClassOpenVote";

    modifier requireValidShare(address _wallet, uint256 _shareId) {
        if (_shareId != uint160(_wallet)) revert UnknownToken(_shareId);
        _;
    }

    /// @param _voteWeight The integral weight to apply to each token held by the wallet
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
    ) public {
        super.initialize(
            _voteWeight,
            _minimumQuorum,
            _minimumDelay,
            _maximumDelay,
            _minimumDuration,
            _maximumDuration,
            _gasUsedRebate,
            _baseFeeRebate,
            _supervisorList,
            msg.sender
        );
    }

    /// @notice return true for all wallets
    /// @dev always returns true
    /// @return bool true if voter
    function isVoter(address) external pure returns (bool) {
        return true;
    }

    /// @notice determine if adding a proposal is approved for this voter
    /// @return bool always true
    function canPropose(address) external pure returns (bool) {
        return true;
    }

    /// @notice discover an array of shareIds associated with the specified wallet
    /// @dev the shareId of the open vote is the numeric value of the wallet address itself
    /// @return uint256[] array in memory of share ids
    function discover(address _wallet) external pure returns (uint256[] memory) {
        uint256[] memory shareList = new uint256[](1);
        shareList[0] = uint160(_wallet);
        return shareList;
    }

    /// @notice confirm shareid is associated with wallet for voting
    /// @return uint256 The number of weighted votes confirmed
    function confirm(address _wallet, uint256 _shareId) external view requireValidShare(_wallet, _shareId) returns (uint256) {
        return weight();
    }

    /// @notice return the name of this implementation
    /// @return string memory representation of name
    function name() external pure virtual returns (string memory) {
        return NAME;
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

import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import { CommunityClass, WeightedCommunityClass, ProjectCommunityClass } from "../../contracts/community/CommunityClass.sol";
import { CommunityClassClosedERC721 } from "../../contracts/community/CommunityClassClosedERC721.sol";
import { AddressCollection } from "../../contracts/collection/AddressSet.sol";

contract WeightedCommunityClassProxy is ERC1967Proxy {
    /// @notice create a new community class proxy
    /// @param _implementation the address of the community class implementation
    /// @param _voteWeight the weight of a single voting share
    /// @param _minimumQuorum the least possible quorum for any vote
    /// @param _minimumDelay the least possible vote delay
    /// @param _maximumDelay the least possible vote delay
    /// @param _minimumDuration the least possible voting duration
    /// @param _maximumDuration the least possible voting duration
    /// @param _gasUsedRebate The maximum rebate for gas used
    /// @param _baseFeeRebate The maximum base fee rebate
    /// @param _supervisorList the list of supervisors for this project
    constructor(
        address _implementation,
        uint256 _voteWeight,
        uint256 _minimumQuorum,
        uint256 _minimumDelay,
        uint256 _maximumDelay,
        uint256 _minimumDuration,
        uint256 _maximumDuration,
        uint256 _gasUsedRebate,
        uint256 _baseFeeRebate,
        AddressCollection _supervisorList
    )
        ERC1967Proxy(
            _implementation,
            abi.encodeWithSelector(
                WeightedCommunityClass.initialize.selector,
                _voteWeight,
                _minimumQuorum,
                _minimumDelay,
                _maximumDelay,
                _minimumDuration,
                _maximumDuration,
                _gasUsedRebate,
                _baseFeeRebate,
                _supervisorList
            )
        )
    // solhint-disable-next-line no-empty-blocks
    {

    }

    function upgrade(
        address _implementation,
        uint256 _voteWeight,
        uint256 _minimumQuorum,
        uint256 _minimumDelay,
        uint256 _maximumDelay,
        uint256 _minimumDuration,
        uint256 _maximumDuration,
        uint256 _gasUsedRebate,
        uint256 _baseFeeRebate,
        AddressCollection _supervisorList
    ) external {
        _upgradeToAndCallUUPS(
            _implementation,
            abi.encodeWithSelector(
                WeightedCommunityClass.upgrade.selector,
                _voteWeight,
                _minimumQuorum,
                _minimumDelay,
                _maximumDelay,
                _minimumDuration,
                _maximumDuration,
                _gasUsedRebate,
                _baseFeeRebate,
                _supervisorList
            ),
            false
        );
    }
}

contract ProjectCommunityClassProxy is ERC1967Proxy {
    /// @notice create a new community class proxy
    /// @param _implementation the address of the community class implementation
    /// @param _contract Address of the token contract
    /// @param _voteWeight the weight of a single voting share
    /// @param _minimumQuorum the least possible quorum for any vote
    /// @param _minimumDelay the least possible vote delay
    /// @param _maximumDelay the least possible vote delay
    /// @param _minimumDuration the least possible voting duration
    /// @param _maximumDuration the least possible voting duration
    /// @param _gasUsedRebate The maximum rebate for gas used
    /// @param _baseFeeRebate The maximum base fee rebate
    /// @param _supervisorList the list of supervisors for this project
    constructor(
        address _implementation,
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
    )
        ERC1967Proxy(
            _implementation,
            abi.encodeWithSelector(
                ProjectCommunityClass.initialize.selector,
                _contract,
                _voteWeight,
                _minimumQuorum,
                _minimumDelay,
                _maximumDelay,
                _minimumDuration,
                _maximumDuration,
                _gasUsedRebate,
                _baseFeeRebate,
                _supervisorList
            )
        )
    // solhint-disable-next-line no-empty-blocks
    {

    }

    function upgrade(
        address _implementation,
        uint256 _voteWeight,
        uint256 _minimumQuorum,
        uint256 _minimumDelay,
        uint256 _maximumDelay,
        uint256 _minimumDuration,
        uint256 _maximumDuration,
        uint256 _gasUsedRebate,
        uint256 _baseFeeRebate,
        AddressCollection _supervisorList
    ) external {
        _upgradeToAndCallUUPS(
            _implementation,
            abi.encodeWithSelector(
                WeightedCommunityClass.upgrade.selector,
                _voteWeight,
                _minimumQuorum,
                _minimumDelay,
                _maximumDelay,
                _minimumDuration,
                _maximumDuration,
                _gasUsedRebate,
                _baseFeeRebate,
                _supervisorList
            ),
            false
        );
    }
}

contract ClosedProjectCommunityClassProxy is ERC1967Proxy {
    /// @notice create a new community class proxy
    /// @param _implementation the address of the community class implementation
    /// @param _contract Address of the token contract
    /// @param _voteWeight the weight of a single voting share
    /// @param _minimumQuorum the least possible quorum for any vote
    /// @param _minimumDelay the least possible vote delay
    /// @param _maximumDelay the least possible vote delay
    /// @param _minimumDuration the least possible voting duration
    /// @param _maximumDuration the least possible voting duration
    /// @param _gasUsedRebate The maximum rebate for gas used
    /// @param _baseFeeRebate The maximum base fee rebate
    /// @param _supervisorList the list of supervisors for this project
    constructor(
        address _implementation,
        address _contract,
        uint256 _tokenThreshold,
        uint256 _voteWeight,
        uint256 _minimumQuorum,
        uint256 _minimumDelay,
        uint256 _maximumDelay,
        uint256 _minimumDuration,
        uint256 _maximumDuration,
        uint256 _gasUsedRebate,
        uint256 _baseFeeRebate,
        AddressCollection _supervisorList
    )
        ERC1967Proxy(
            _implementation,
            abi.encodeWithSelector(
                CommunityClassClosedERC721.initialize.selector,
                _contract,
                _tokenThreshold,
                _voteWeight,
                _minimumQuorum,
                _minimumDelay,
                _maximumDelay,
                _minimumDuration,
                _maximumDuration,
                _gasUsedRebate,
                _baseFeeRebate,
                _supervisorList
            )
        )
    // solhint-disable-next-line no-empty-blocks
    {

    }

    function upgrade(
        address _implementation,
        uint256 _voteWeight,
        uint256 _minimumQuorum,
        uint256 _minimumDelay,
        uint256 _maximumDelay,
        uint256 _minimumDuration,
        uint256 _maximumDuration,
        uint256 _gasUsedRebate,
        uint256 _baseFeeRebate,
        AddressCollection _supervisorList
    ) external {
        _upgradeToAndCallUUPS(
            _implementation,
            abi.encodeWithSelector(
                WeightedCommunityClass.upgrade.selector,
                _voteWeight,
                _minimumQuorum,
                _minimumDelay,
                _maximumDelay,
                _minimumDuration,
                _maximumDuration,
                _gasUsedRebate,
                _baseFeeRebate,
                _supervisorList
            ),
            false
        );
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

import { Constant } from "../../contracts/Constant.sol";
import { ConfigurableMutable } from "../../contracts/access/ConfigurableMutable.sol";
import { AddressCollection } from "../../contracts/collection/AddressSet.sol";
import { ScheduledCommunityClass } from "../../contracts/community/ScheduledCommunityClass.sol";

/// @title interface for VoterPool
/// @notice sets the requirements for contracts implementing a VoterPool
/// @custom:type interface
interface VoterPool {
    error DuplicateRegistration(address voter);
    event RegisterVoter(address voter);
    event BurnVoter(address voter);

    /// @notice add voter to pool
    /// @param _wallet the address of the wallet
    function addVoter(address _wallet) external;

    /// @notice remove voter from the pool
    /// @param _wallet the address of the wallet
    function removeVoter(address _wallet) external;
}

/// @title CommunityClassVoterPool contract
/// @notice This contract supports voting for a specific list of wallet addresses.   Each address must be added
/// to the contract prior to voting at which time the pool must be marked as final so that it becomes impossible
/// to modify
contract CommunityClassVoterPool is ScheduledCommunityClass, ConfigurableMutable, VoterPool {
    string public constant NAME = "CommunityClassVoterPool";

    // whitelisted voters
    AddressCollection private _voterPool;

    /// @param _voteWeight The integral weight to apply to each token held by the wallet
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
    ) public {
        super.initialize(
            _voteWeight,
            _minimumQuorum,
            _minimumDelay,
            _maximumDelay,
            _minimumDuration,
            _maximumDuration,
            _gasUsedRebate,
            _baseFeeRebate,
            _supervisorList,
            msg.sender
        );
        _voterPool = Constant.createAddressSet();
    }

    modifier requireValidShare(address _wallet, uint256 _shareId) {
        if (_shareId == 0 || _shareId != uint160(_wallet)) revert UnknownToken(_shareId);
        _;
    }

    modifier requireVoter(address _wallet) {
        if (!_voterPool.contains(_wallet)) revert NotVoter(_wallet);
        _;
    }

    /// @notice add a voter to the voter pool
    /// @dev only possible if not final
    /// @param _wallet the address to add
    function addVoter(address _wallet) external onlyOwner onlyMutable {
        if (!_voterPool.contains(_wallet)) {
            _voterPool.add(_wallet);
            emit RegisterVoter(_wallet);
        } else {
            revert DuplicateRegistration(_wallet);
        }
    }

    /// @notice remove a voter from the voter pool
    /// @dev only possible if not final
    /// @param _wallet the address to add
    function removeVoter(address _wallet) external onlyOwner onlyMutable {
        if (!_voterPool.erase(_wallet)) revert NotVoter(_wallet);
        emit BurnVoter(_wallet);
    }

    /// @notice test if wallet represents an allowed voter for this class
    /// @return bool true if wallet is a voter
    function isVoter(address _wallet) public view returns (bool) {
        return _voterPool.contains(_wallet);
    }

    /// @notice determine if adding a proposal is approved for this voter
    /// @dev listed voter is required for proposal
    /// @param _sender The address of the sender
    /// @return bool true if this address is approved
    function canPropose(address _sender) external view returns (bool) {
        return isVoter(_sender);
    }

    /// @notice discover an array of shareIds associated with the specified wallet
    /// @return uint256[] array in memory of share ids
    function discover(address _wallet) external view requireVoter(_wallet) onlyFinal returns (uint256[] memory) {
        uint256[] memory shareList = new uint256[](1);
        shareList[0] = uint160(_wallet);
        return shareList;
    }

    /// @notice confirm shareid is associated with wallet for voting
    /// @return uint256 The number of weighted votes confirmed
    function confirm(
        address _wallet,
        uint256 _shareId
    ) external view onlyFinal requireVoter(_wallet) requireValidShare(_wallet, _shareId) returns (uint256) {
        return weight();
    }

    /// @notice set the voterpool final.   No further changes may be made to the voting pool.
    function makeFinal() public override(ConfigurableMutable) onlyOwner {
        if (_voterPool.size() == 0) revert EmptyCommunity();
        super.makeFinal();
    }

    /// @notice see ERC-165
    function supportsInterface(bytes4 interfaceId) public view virtual override(ScheduledCommunityClass) returns (bool) {
        return interfaceId == type(VoterPool).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @notice return the name of this implementation
    /// @return string memory representation of name
    function name() external pure virtual returns (string memory) {
        return NAME;
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

import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import { AddressCollection } from "../../contracts/collection/AddressSet.sol";
import { ScheduledCommunityClass } from "../../contracts/community/ScheduledCommunityClass.sol";
import { WeightedCommunityClass, ProjectCommunityClass, CommunityClass } from "../../contracts/community/CommunityClass.sol";
import { CommunityClassOpenVote } from "../../contracts/community/CommunityClassOpenVote.sol";
import { CommunityClassVoterPool } from "../../contracts/community/CommunityClassVoterPool.sol";
import { CommunityClassERC721 } from "../../contracts/community/CommunityClassERC721.sol";
import { CommunityClassClosedERC721 } from "../../contracts/community/CommunityClassClosedERC721.sol";
import { WeightedCommunityClassProxy, ProjectCommunityClassProxy, ClosedProjectCommunityClassProxy } from "../../contracts/community/CommunityClassProxy.sol";

// solhint-disable-next-line func-visibility
function upgradeOpenVote(
    address payable proxyAddress,
    uint256 weight,
    uint256 minimumProjectQuorum,
    uint256 minimumVoteDelay,
    uint256 maximumVoteDelay,
    uint256 minimumVoteDuration,
    uint256 maximumVoteDuration,
    uint256 _gasUsedRebate,
    uint256 _baseFeeRebate,
    AddressCollection _supervisorList
) {
    CommunityClass _class = new CommunityClassOpenVote();
    WeightedCommunityClassProxy _proxy = WeightedCommunityClassProxy(proxyAddress);
    _proxy.upgrade(
        address(_class),
        weight,
        minimumProjectQuorum,
        minimumVoteDelay,
        maximumVoteDelay,
        minimumVoteDuration,
        maximumVoteDuration,
        _gasUsedRebate,
        _baseFeeRebate,
        _supervisorList
    );
}

// solhint-disable-next-line func-visibility
function upgradeVoterPool(
    address payable proxyAddress,
    uint256 weight,
    uint256 minimumProjectQuorum,
    uint256 minimumVoteDelay,
    uint256 maximumVoteDelay,
    uint256 minimumVoteDuration,
    uint256 maximumVoteDuration,
    uint256 _gasUsedRebate,
    uint256 _baseFeeRebate,
    AddressCollection _supervisorList
) {
    CommunityClass _class = new CommunityClassVoterPool();
    WeightedCommunityClassProxy _proxy = WeightedCommunityClassProxy(proxyAddress);
    _proxy.upgrade(
        address(_class),
        weight,
        minimumProjectQuorum,
        minimumVoteDelay,
        maximumVoteDelay,
        minimumVoteDuration,
        maximumVoteDuration,
        _gasUsedRebate,
        _baseFeeRebate,
        _supervisorList
    );
}

// solhint-disable-next-line func-visibility
function upgradeErc721(
    address payable proxyAddress,
    uint256 weight,
    uint256 minimumProjectQuorum,
    uint256 minimumVoteDelay,
    uint256 maximumVoteDelay,
    uint256 minimumVoteDuration,
    uint256 maximumVoteDuration,
    uint256 _gasUsedRebate,
    uint256 _baseFeeRebate,
    AddressCollection _supervisorList
) {
    CommunityClass _class = new CommunityClassERC721();
    ProjectCommunityClassProxy _proxy = ProjectCommunityClassProxy(proxyAddress);
    _proxy.upgrade(
        address(_class),
        weight,
        minimumProjectQuorum,
        minimumVoteDelay,
        maximumVoteDelay,
        minimumVoteDuration,
        maximumVoteDuration,
        _gasUsedRebate,
        _baseFeeRebate,
        _supervisorList
    );
}

// solhint-disable-next-line func-visibility
function upgradeClosedErc721(
    address payable proxyAddress,
    uint256 weight,
    uint256 minimumProjectQuorum,
    uint256 minimumVoteDelay,
    uint256 maximumVoteDelay,
    uint256 minimumVoteDuration,
    uint256 maximumVoteDuration,
    uint256 _gasUsedRebate,
    uint256 _baseFeeRebate,
    AddressCollection _supervisorList
) {
    CommunityClass _class = new CommunityClassClosedERC721();
    ProjectCommunityClassProxy _proxy = ProjectCommunityClassProxy(proxyAddress);
    _proxy.upgrade(
        address(_class),
        weight,
        minimumProjectQuorum,
        minimumVoteDelay,
        maximumVoteDelay,
        minimumVoteDuration,
        maximumVoteDuration,
        _gasUsedRebate,
        _baseFeeRebate,
        _supervisorList
    );
}

/**
 * @title Weighted Class Factory
 * @notice small factory intended to reduce construction size impact for weighted community classes
 */
contract WeightedClassFactory {
    /// @notice create a new community class representing an open vote
    /// @param weight the weight of a single voting share
    /// @param minimumProjectQuorum the least possible quorum for any vote
    /// @param minimumVoteDelay the least possible vote delay
    /// @param maximumVoteDelay the least possible vote delay
    /// @param minimumVoteDuration the least possible voting duration
    /// @param maximumVoteDuration the least possible voting duration
    /// @param _gasUsedRebate The maximum rebate for gas used
    /// @param _baseFeeRebate The maximum base fee rebate
    /// @param _supervisorList the list of supervisors for this project
    function createOpenVote(
        uint256 weight,
        uint256 minimumProjectQuorum,
        uint256 minimumVoteDelay,
        uint256 maximumVoteDelay,
        uint256 minimumVoteDuration,
        uint256 maximumVoteDuration,
        uint256 _gasUsedRebate,
        uint256 _baseFeeRebate,
        AddressCollection _supervisorList
    ) external returns (WeightedCommunityClass) {
        CommunityClass _class = new CommunityClassOpenVote();
        ERC1967Proxy _proxy = new WeightedCommunityClassProxy(
            address(_class),
            weight,
            minimumProjectQuorum,
            minimumVoteDelay,
            maximumVoteDelay,
            minimumVoteDuration,
            maximumVoteDuration,
            _gasUsedRebate,
            _baseFeeRebate,
            _supervisorList
        );
        ScheduledCommunityClass _proxyClass = ScheduledCommunityClass(address(_proxy));
        _proxyClass.transferOwnership(msg.sender);
        return _proxyClass;
    }

    /// @notice create a new community class representing a voter pool
    /// @param weight the weight of a single voting share
    /// @param minimumProjectQuorum the least possible quorum for any vote
    /// @param minimumVoteDelay the least possible vote delay
    /// @param maximumVoteDelay the least possible vote delay
    /// @param minimumVoteDuration the least possible voting duration
    /// @param maximumVoteDuration the least possible voting duration
    /// @param _gasUsedRebate The maximum rebate for gas used
    /// @param _baseFeeRebate The maximum base fee rebate
    /// @param _supervisorList the list of supervisors for this project
    function createVoterPool(
        uint256 weight,
        uint256 minimumProjectQuorum,
        uint256 minimumVoteDelay,
        uint256 maximumVoteDelay,
        uint256 minimumVoteDuration,
        uint256 maximumVoteDuration,
        uint256 _gasUsedRebate,
        uint256 _baseFeeRebate,
        AddressCollection _supervisorList
    ) external returns (CommunityClassVoterPool) {
        CommunityClass _class = new CommunityClassVoterPool();
        ERC1967Proxy _proxy = new WeightedCommunityClassProxy(
            address(_class),
            weight,
            minimumProjectQuorum,
            minimumVoteDelay,
            maximumVoteDelay,
            minimumVoteDuration,
            maximumVoteDuration,
            _gasUsedRebate,
            _baseFeeRebate,
            _supervisorList
        );
        CommunityClassVoterPool _proxyClass = CommunityClassVoterPool(address(_proxy));
        _proxyClass.transferOwnership(msg.sender);
        return _proxyClass;
    }
}

/**
 * @title Project Class Factory
 * @notice small factory intended to reduce construction size for project community classes
 */
contract ProjectClassFactory {
    /// @notice create a new community class representing an ERC-721 token based community
    /// @param projectToken the token underlier for the community
    /// @param weight the weight of a single voting share
    /// @param minimumProjectQuorum the least possible quorum for any vote
    /// @param minimumVoteDelay the least possible vote delay
    /// @param maximumVoteDelay the least possible vote delay
    /// @param minimumVoteDuration the least possible voting duration
    /// @param maximumVoteDuration the least possible voting duration
    /// @param _gasUsedRebate The maximum rebate for gas used
    /// @param _baseFeeRebate The maximum base fee rebate
    /// @param _supervisorList the list of supervisors for this project
    function createErc721(
        address projectToken,
        uint256 weight,
        uint256 minimumProjectQuorum,
        uint256 minimumVoteDelay,
        uint256 maximumVoteDelay,
        uint256 minimumVoteDuration,
        uint256 maximumVoteDuration,
        uint256 _gasUsedRebate,
        uint256 _baseFeeRebate,
        AddressCollection _supervisorList
    ) external returns (ProjectCommunityClass) {
        CommunityClass _class = new CommunityClassERC721();
        ERC1967Proxy _proxy = new ProjectCommunityClassProxy(
            address(_class),
            projectToken,
            weight,
            minimumProjectQuorum,
            minimumVoteDelay,
            maximumVoteDelay,
            minimumVoteDuration,
            maximumVoteDuration,
            _gasUsedRebate,
            _baseFeeRebate,
            _supervisorList
        );
        CommunityClassERC721 _proxyClass = CommunityClassERC721(address(_proxy));
        _proxyClass.transferOwnership(msg.sender);
        return _proxyClass;
    }

    /// @notice create a new community class representing a closed ERC-721 token based community
    /// @param projectToken the token underlier for the community
    /// @param tokenThreshold the number of tokens required to propose a vote
    /// @param weight the weight of a single voting share
    /// @param minimumProjectQuorum the least possible quorum for any vote
    /// @param minimumVoteDelay the least possible vote delay
    /// @param maximumVoteDelay the least possible vote delay
    /// @param minimumVoteDuration the least possible voting duration
    /// @param maximumVoteDuration the least possible voting duration
    /// @param _gasUsedRebate The maximum rebate for gas used
    /// @param _baseFeeRebate The maximum base fee rebate
    /// @param _supervisorList the list of supervisors for this project
    function createClosedErc721(
        address projectToken,
        uint256 tokenThreshold,
        uint256 weight,
        uint256 minimumProjectQuorum,
        uint256 minimumVoteDelay,
        uint256 maximumVoteDelay,
        uint256 minimumVoteDuration,
        uint256 maximumVoteDuration,
        uint256 _gasUsedRebate,
        uint256 _baseFeeRebate,
        AddressCollection _supervisorList
    ) external returns (ProjectCommunityClass) {
        CommunityClass _class = new CommunityClassClosedERC721();
        ERC1967Proxy _proxy = new ClosedProjectCommunityClassProxy(
            address(_class),
            projectToken,
            tokenThreshold,
            weight,
            minimumProjectQuorum,
            minimumVoteDelay,
            maximumVoteDelay,
            minimumVoteDuration,
            maximumVoteDuration,
            _gasUsedRebate,
            _baseFeeRebate,
            _supervisorList
        );
        CommunityClassClosedERC721 _proxyClass = CommunityClassClosedERC721(address(_proxy));
        _proxyClass.transferOwnership(msg.sender);
        return _proxyClass;
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

import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { IERC165 } from "@openzeppelin/contracts/interfaces/IERC165.sol";
import { ERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

import { Constant } from "../../contracts/Constant.sol";
import { AddressCollection } from "../../contracts/collection/AddressSet.sol";
import { Mutable } from "../../contracts/access/Mutable.sol";
import { ConfigurableMutable } from "../../contracts/access/ConfigurableMutable.sol";
import { Versioned } from "../../contracts/access/Versioned.sol";
import { VersionedContract } from "../../contracts/access/VersionedContract.sol";
import { VoterClass } from "../../contracts/community/VoterClass.sol";
import { WeightedCommunityClass, CommunityClass } from "../../contracts/community/CommunityClass.sol";
import { OwnableInitializable } from "../../contracts/access/OwnableInitializable.sol";

/// @title ScheduledCommunityClass
/// @notice defines the configurable parameters for a community
abstract contract ScheduledCommunityClass is
    WeightedCommunityClass,
    VersionedContract,
    OwnableInitializable,
    UUPSUpgradeable,
    Initializable,
    ERC165
{
    event UpgradeAuthorized(address sender, address owner);
    event Initialized(
        uint256 voteWeight,
        uint256 minimumQuorum,
        uint256 minimumDelay,
        uint256 maximumDelay,
        uint256 minimumDuration,
        uint256 maximumDuration,
        uint256 _gasUsedRebate,
        uint256 _baseFeeRebate
    );
    event Upgraded(
        uint256 voteWeight,
        uint256 minimumQuorum,
        uint256 minimumDelay,
        uint256 maximumDelay,
        uint256 minimumDuration,
        uint256 maximumDuration,
        uint256 _gasUsedRebate,
        uint256 _baseFeeRebate
    );

    /// @notice weight of a single voting share
    uint256 private _weight;

    /// @notice minimum vote delay for any vote
    uint256 private _minimumVoteDelay;

    /// @notice maximum vote delay for any vote
    uint256 private _maximumVoteDelay;

    /// @notice minimum time for any vote
    uint256 private _minimumVoteDuration;

    /// @notice maximum time for any vote
    uint256 private _maximumVoteDuration;

    /// @notice minimum quorum for any vote
    uint256 private _minimumProjectQuorum;

    uint256 private _maximumGasUsedRebate;

    uint256 private _maximumBaseFeeRebate;

    AddressCollection private _communitySupervisorSet;

    /// @notice create a new community class representing community preferences
    /// @param _voteWeight the weight of a single voting share
    /// @param _minimumQuorum the least possible quorum for any vote
    /// @param _minimumDelay the least possible vote delay
    /// @param _maximumDelay the least possible vote delay
    /// @param _minimumDuration the least possible voting duration
    /// @param _maximumDuration the least possible voting duration
    /// @param _gasUsedRebate The maximum rebate for gas used
    /// @param _baseFeeRebate The maximum base fee rebate
    /// @param _supervisorList the list of supervisors for this project
    /// @param _owner the owner for the class
    function initialize(
        uint256 _voteWeight,
        uint256 _minimumQuorum,
        uint256 _minimumDelay,
        uint256 _maximumDelay,
        uint256 _minimumDuration,
        uint256 _maximumDuration,
        uint256 _gasUsedRebate,
        uint256 _baseFeeRebate,
        AddressCollection _supervisorList,
        address _owner
    )
        internal
        virtual
        initializer
        requireValidWeight(_voteWeight)
        requireProjectQuorum(_minimumQuorum)
        requireMinimumDelay(_minimumDelay)
        requireMaximumDelay(_maximumDelay)
        requireMinimumDuration(_minimumDuration)
        requireMaximumGasUsedRebate(_gasUsedRebate)
        requireMaximumBaseFeeRebate(_baseFeeRebate)
        requireNonEmptySupervisorList(_supervisorList)
    {
        if (_minimumDelay > _maximumDelay) revert MinimumDelayExceedsMaximum(_minimumDelay, _maximumDelay);
        if (_minimumDuration >= _maximumDuration) revert MinimumDurationExceedsMaximum(_minimumDuration, _maximumDuration);
        ownerInitialize(_owner);

        _weight = _voteWeight;
        _minimumVoteDelay = _minimumDelay;
        _maximumVoteDelay = _maximumDelay;
        _minimumVoteDuration = _minimumDuration;
        _maximumVoteDuration = _maximumDuration;
        _minimumProjectQuorum = _minimumQuorum;
        _maximumGasUsedRebate = _gasUsedRebate;
        _maximumBaseFeeRebate = _baseFeeRebate;
        _communitySupervisorSet = Constant.createAddressSet();
        for (uint256 i = 1; i <= _supervisorList.size(); ++i) {
            _communitySupervisorSet.add(_supervisorList.get(i));
        }
        emit Initialized(
            _voteWeight,
            _minimumQuorum,
            _minimumDelay,
            _maximumDelay,
            _minimumDuration,
            _maximumDuration,
            _maximumGasUsedRebate,
            _maximumBaseFeeRebate
        );
    }

    /// @notice reset voting parameters for upgrade
    /// @param _voteWeight the weight of a single voting share
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
    )
        public
        onlyOwner
        requireValidWeight(_voteWeight)
        requireProjectQuorum(_minimumQuorum)
        requireMinimumDelay(_minimumDelay)
        requireMaximumDelay(_maximumDelay)
        requireMinimumDuration(_minimumDuration)
        requireMaximumGasUsedRebate(_gasUsedRebate)
        requireMaximumBaseFeeRebate(_baseFeeRebate)
        requireNonEmptySupervisorList(_supervisorList)
    {
        if (_minimumDelay > _maximumDelay) revert MinimumDelayExceedsMaximum(_minimumDelay, _maximumDelay);
        if (_minimumDuration >= _maximumDuration) revert MinimumDurationExceedsMaximum(_minimumDuration, _maximumDuration);

        _weight = _voteWeight;
        _minimumVoteDelay = _minimumDelay;
        _maximumVoteDelay = _maximumDelay;
        _minimumVoteDuration = _minimumDuration;
        _maximumVoteDuration = _maximumDuration;
        _minimumProjectQuorum = _minimumQuorum;
        _maximumGasUsedRebate = _gasUsedRebate;
        _maximumBaseFeeRebate = _baseFeeRebate;
        _communitySupervisorSet = Constant.createAddressSet();
        for (uint256 i = 1; i <= _supervisorList.size(); ++i) {
            _communitySupervisorSet.add(_supervisorList.get(i));
        }
        emit Upgraded(
            _voteWeight,
            _minimumQuorum,
            _minimumDelay,
            _maximumDelay,
            _minimumDuration,
            _maximumDuration,
            _maximumGasUsedRebate,
            _maximumBaseFeeRebate
        );
    }

    modifier requireValidWeight(uint256 _voteWeight) {
        if (_voteWeight < 1) revert VoteWeightMustBeNonZero();
        _;
    }

    modifier requireProjectQuorum(uint256 _minimumQuorum) {
        if (_minimumQuorum < Constant.MINIMUM_PROJECT_QUORUM)
            revert MinimumQuorumNotPermitted(_minimumQuorum, Constant.MINIMUM_PROJECT_QUORUM);
        _;
    }

    modifier requireMinimumDelay(uint256 _minimumDelay) {
        if (_minimumDelay < Constant.MINIMUM_VOTE_DELAY)
            revert MinimumDelayExceedsMaximum(_minimumDelay, Constant.MINIMUM_VOTE_DELAY);
        _;
    }

    modifier requireMaximumDelay(uint256 _maximumDelay) {
        if (_maximumDelay > Constant.MAXIMUM_VOTE_DELAY)
            revert MaximumDelayNotPermitted(_maximumDelay, Constant.MAXIMUM_VOTE_DELAY);
        _;
    }

    modifier requireMinimumDuration(uint256 _minimumDuration) {
        if (_minimumDuration < Constant.MINIMUM_VOTE_DURATION)
            revert MinimumDurationExceedsMaximum(_minimumDuration, Constant.MINIMUM_VOTE_DURATION);
        _;
    }

    modifier requireMaximumDuration(uint256 _maximumDuration) {
        if (_maximumDuration > Constant.MAXIMUM_VOTE_DURATION)
            revert MaximumDurationNotPermitted(_maximumDuration, Constant.MAXIMUM_VOTE_DURATION);
        _;
    }

    modifier requireNonEmptySupervisorList(AddressCollection _supervisorList) {
        if (_supervisorList.size() == 0) revert SupervisorListEmpty();
        _;
    }

    modifier requireMaximumGasUsedRebate(uint256 _gasUsedRebate) {
        if (_gasUsedRebate < Constant.MAXIMUM_REBATE_GAS_USED)
            revert GasUsedRebateMustBeLarger(_gasUsedRebate, Constant.MAXIMUM_REBATE_GAS_USED);
        _;
    }

    modifier requireMaximumBaseFeeRebate(uint256 _baseFeeRebate) {
        if (_baseFeeRebate < Constant.MAXIMUM_REBATE_BASE_FEE)
            revert BaseFeeRebateMustBeLarger(_baseFeeRebate, Constant.MAXIMUM_REBATE_BASE_FEE);
        _;
    }

    /// @notice return voting weight of each confirmed share
    /// @return uint256 weight applied to one share
    function weight() public view returns (uint256) {
        return _weight;
    }

    /// @notice get the project quorum requirement
    /// @return uint256 the least quorum allowed for any vote
    function minimumProjectQuorum() public view returns (uint256) {
        return _minimumProjectQuorum;
    }

    /// @notice get the project vote delay requirement
    /// @return uint the least vote delay allowed for any vote
    function minimumVoteDelay() public view returns (uint256) {
        return _minimumVoteDelay;
    }

    /// @notice get the project vote delay maximum
    /// @return uint the max vote delay allowed for any vote
    function maximumVoteDelay() public view returns (uint256) {
        return _maximumVoteDelay;
    }

    /// @notice get the vote duration in seconds
    /// @return uint256 the least duration of a vote in seconds
    function minimumVoteDuration() public view returns (uint256) {
        return _minimumVoteDuration;
    }

    /// @notice get the vote duration in seconds
    /// @return uint256 the vote duration of a vote in seconds
    function maximumVoteDuration() public view returns (uint256) {
        return _maximumVoteDuration;
    }

    /// @notice maximum gas used rebate
    /// @return uint256 the maximum rebate
    function maximumGasUsedRebate() external view returns (uint256) {
        return _maximumGasUsedRebate;
    }

    /// @notice maximum base fee rebate
    /// @return uint256 the base fee rebate
    function maximumBaseFeeRebate() external view returns (uint256) {
        return _maximumBaseFeeRebate;
    }

    /// @notice return the community supervisors
    /// @return AddressSet the supervisor set
    function communitySupervisorSet() external view returns (AddressCollection) {
        return _communitySupervisorSet;
    }

    /// @notice see ERC-165
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return
            interfaceId == type(Mutable).interfaceId ||
            interfaceId == type(VoterClass).interfaceId ||
            interfaceId == type(CommunityClass).interfaceId ||
            interfaceId == type(WeightedCommunityClass).interfaceId ||
            interfaceId == type(Versioned).interfaceId ||
            interfaceId == type(Initializable).interfaceId ||
            super.supportsInterface(interfaceId);
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/ERC1967/ERC1967Proxy.sol)

pragma solidity ^0.8.0;

import "../Proxy.sol";
import "./ERC1967Upgrade.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 */
contract ERC1967Proxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializing the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        _upgradeToAndCall(_logic, _data, false);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }
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
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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