/*
  Copyright 2019-2022 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

import "SimpleAdminable.sol";

/**
  A simple base class for finalizable contracts.
*/
abstract contract Finalizable is SimpleAdminable {
    event Finalized();

    bool finalized;

    function isFinalized() public view returns (bool) {
        return finalized;
    }

    modifier notFinalized() {
        require(!isFinalized(), "FINALIZED");
        _;
    }

    function finalize() external onlyAdmin notFinalized {
        finalized = true;
        emit Finalized();
    }
}

/*
  Copyright 2019-2022 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

import "Finalizable.sol";
import "GpsFactRegistryAdapter.sol";
import "IQueryableFactRegistry.sol";

/**
  A finalizable version of GpsFactRegistryAdapter.
  It allows resetting the gps program hash, until finalized.
*/
contract FinalizableGpsFactAdapterForTesting is GpsFactRegistryAdapter, Finalizable {
    constructor(IQueryableFactRegistry gpsStatementContract, uint256 programHash_)
        public
        GpsFactRegistryAdapter(gpsStatementContract, programHash_)
    {}

    function setProgramHash(uint256 newProgramHash) external notFinalized onlyAdmin {
        programHash = newProgramHash;
    }

    function identify() external pure override returns (string memory) {
        return "StarkWare_FinalizableGpsFactAdapterForTesting_2021_1";
    }
}

/*
  Copyright 2019-2022 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

import "Identity.sol";
import "IQueryableFactRegistry.sol";

/*
  The GpsFactRegistryAdapter contract is used as an adapter between a Dapp contract and a GPS fact
  registry. An isValid(fact) query is answered by querying the GPS contract about
  new_fact := keccak256(programHash, fact).

  The goal of this contract is to simplify the verifier upgradability logic in the Dapp contract
  by making the upgrade flow the same regardless of whether the update is to the program hash or
  the gpsContractAddress.
*/
contract GpsFactRegistryAdapter is IQueryableFactRegistry, Identity {
    IQueryableFactRegistry public gpsContract;
    uint256 public programHash;

    constructor(IQueryableFactRegistry gpsStatementContract, uint256 programHash_) public {
        gpsContract = gpsStatementContract;
        programHash = programHash_;
    }

    function identify() external pure virtual override returns (string memory) {
        return "StarkWare_GpsFactRegistryAdapter_2020_1";
    }

    /*
      Checks if a fact has been verified.
    */
    function isValid(bytes32 fact) external view override returns (bool) {
        return gpsContract.isValid(keccak256(abi.encode(programHash, fact)));
    }

    /*
      Indicates whether at least one fact was registered.
    */
    function hasRegisteredFact() external view override returns (bool) {
        return gpsContract.hasRegisteredFact();
    }
}

/*
  Copyright 2019-2022 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

/*
  The Fact Registry design pattern is a way to separate cryptographic verification from the
  business logic of the contract flow.

  A fact registry holds a hash table of verified "facts" which are represented by a hash of claims
  that the registry hash check and found valid. This table may be queried by accessing the
  isValid() function of the registry with a given hash.

  In addition, each fact registry exposes a registry specific function for submitting new claims
  together with their proofs. The information submitted varies from one registry to the other
  depending of the type of fact requiring verification.

  For further reading on the Fact Registry design pattern see this
  `StarkWare blog post <https://medium.com/starkware/the-fact-registry-a64aafb598b6>`_.
*/
interface IFactRegistry {
    /*
      Returns true if the given fact was previously registered in the contract.
    */
    function isValid(bytes32 fact) external view returns (bool);
}

/*
  Copyright 2019-2022 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

import "IFactRegistry.sol";

/*
  Extends the IFactRegistry interface with a query method that indicates
  whether the fact registry has successfully registered any fact or is still empty of such facts.
*/
interface IQueryableFactRegistry is IFactRegistry {
    /*
      Returns true if at least one fact has been registered.
    */
    function hasRegisteredFact() external view returns (bool);
}

/*
  Copyright 2019-2022 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

interface Identity {
    /*
      Allows a caller to ensure that the provided address is of the expected type and version.
    */
    function identify() external pure returns (string memory);
}

/*
  Copyright 2019-2022 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

abstract contract SimpleAdminable {
    address owner;
    address ownerCandidate;
    mapping(address => bool) admins;

    constructor() internal {
        owner = msg.sender;
        admins[msg.sender] = true;
    }

    // Admin/Owner Modifiers.
    modifier onlyOwner() {
        require(isOwner(msg.sender), "ONLY_OWNER");
        _;
    }

    function isOwner(address testedAddress) public view returns (bool) {
        return owner == testedAddress;
    }

    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "ONLY_ADMIN");
        _;
    }

    function isAdmin(address testedAddress) public view returns (bool) {
        return admins[testedAddress];
    }

    function registerAdmin(address newAdmin) external onlyOwner {
        if (!isAdmin(newAdmin)) {
            admins[newAdmin] = true;
        }
    }

    function removeAdmin(address removedAdmin) external onlyOwner {
        require(!isOwner(removedAdmin), "OWNER_CANNOT_BE_REMOVED_AS_ADMIN");
        delete admins[removedAdmin];
    }

    function nominateNewOwner(address newOwner) external onlyOwner {
        require(!isOwner(newOwner), "ALREADY_OWNER");
        ownerCandidate = newOwner;
    }

    function acceptOwnership() external {
        // Previous owner is still an admin.
        require(msg.sender == ownerCandidate, "NOT_A_CANDIDATE");
        owner = ownerCandidate;
        admins[ownerCandidate] = true;
        ownerCandidate = address(0x0);
    }
}