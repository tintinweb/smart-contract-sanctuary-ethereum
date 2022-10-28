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
pragma solidity ^0.6.11;

import "IQueryableFactRegistry.sol";

contract FactRegistry is IQueryableFactRegistry {
    // Mapping: fact hash -> true.
    mapping (bytes32 => bool) private verifiedFact;

    // Indicates whether the Fact Registry has at least one fact registered.
    bool anyFactRegistered;

    /*
      Checks if a fact has been verified.
    */
    function isValid(bytes32 fact)
        external view override
        returns(bool)
    {
        return _factCheck(fact);
    }


    /*
      This is an internal method to check if the fact is already registered.
      In current implementation of FactRegistry it's identical to isValid().
      But the check is against the local fact registry,
      So for a derived referral fact registry, it's not the same.
    */
    function _factCheck(bytes32 fact)
        internal view
        returns(bool)
    {
        return verifiedFact[fact];
    }

    function registerFact(
        bytes32 factHash
        )
        internal
    {
        // This function stores the fact hash in the mapping.
        verifiedFact[factHash] = true;

        // Mark first time off.
        if (!anyFactRegistered) {
            anyFactRegistered = true;
        }
    }

    /*
      Indicates whether at least one fact was registered.
    */
    function hasRegisteredFact()
        external view override
        returns(bool)
    {
        return anyFactRegistered;
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
pragma solidity ^0.6.11;

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
pragma solidity ^0.6.11;

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
pragma solidity ^0.6.11;

interface Identity {
    /*
      Allows a caller, typically another contract,
      to ensure that the provided address is of the expected type and version.
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
pragma solidity ^0.6.11;

import "Identity.sol";
import "FactRegistry.sol";

contract MessageRegistry is FactRegistry, Identity {
    event LogMsgRegistered(address from, address to, bytes32 msgHash);

    function identify() external pure virtual override returns (string memory) {
        return "StarkWare_MessageRegistry_2021_1";
    }

    // NOLINTNEXTLINE: external-function.
    function registerMessage(address to, bytes32 messageHash) public {
        bytes32 messageFact = keccak256(abi.encodePacked(msg.sender, to, messageHash));
        registerFact(messageFact);
        emit LogMsgRegistered(msg.sender, to, messageHash);
    }

    function isMessageRegistered(
        address from,
        address to,
        bytes32 messageHash
    ) external view returns (bool) {
        bytes32 messageFact = keccak256(abi.encodePacked(from, to, messageHash));
        return _factCheck(messageFact);
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
pragma solidity ^0.6.11;

import "MessageRegistry.sol";

contract OrderRegistry is MessageRegistry {
    event LogL1LimitOrderRegistered(
        address userAddress,
        address exchangeAddress,
        uint256 tokenIdSell,
        uint256 tokenIdBuy,
        uint256 tokenIdFee,
        uint256 amountSell,
        uint256 amountBuy,
        uint256 amountFee,
        uint256 vaultIdSell,
        uint256 vaultIdBuy,
        uint256 vaultIdFee,
        uint256 nonce,
        uint256 expirationTimestamp
    );

    uint256 constant MASK_32 = 0xFFFFFFFF;
    uint256 constant MASK_64 = 0xFFFFFFFFFFFFFFFF;
    uint256 constant LIMIT_ORDER_TYPE = 0x3;

    function identify() external pure override returns (string memory) {
        return "StarkWare_OrderRegistry_2021_1";
    }

    function calcL1LimitOrderHash(
        uint256 tokenIdSell,
        uint256 tokenIdBuy,
        uint256 tokenIdFee,
        uint256 amountSell,
        uint256 amountBuy,
        uint256 amountFee,
        uint256 vaultIdSell,
        uint256 vaultIdBuy,
        uint256 vaultIdFee,
        uint256 nonce,
        uint256 expirationTimestamp
    ) public pure returns (bytes32) {
        uint256 packed_word0 = amountSell & MASK_64;
        packed_word0 = (packed_word0 << 64) + (amountBuy & MASK_64);
        packed_word0 = (packed_word0 << 64) + (amountFee & MASK_64);
        packed_word0 = (packed_word0 << 32) + (nonce & MASK_32);

        uint256 packed_word1 = LIMIT_ORDER_TYPE;
        packed_word1 = (packed_word1 << 64) + (vaultIdFee & MASK_64);
        packed_word1 = (packed_word1 << 64) + (vaultIdSell & MASK_64);
        packed_word1 = (packed_word1 << 64) + (vaultIdBuy & MASK_64);
        packed_word1 = (packed_word1 << 32) + (expirationTimestamp & MASK_32);
        packed_word1 = packed_word1 << 17;

        return
            keccak256(
                abi.encode(
                    [
                        bytes32(tokenIdSell),
                        bytes32(tokenIdBuy),
                        bytes32(tokenIdFee),
                        bytes32(packed_word0),
                        bytes32(packed_word1)
                    ]
                )
            );
    }

    function registerLimitOrder(
        address exchangeAddress,
        uint256 tokenIdSell,
        uint256 tokenIdBuy,
        uint256 tokenIdFee,
        uint256 amountSell,
        uint256 amountBuy,
        uint256 amountFee,
        uint256 vaultIdSell,
        uint256 vaultIdBuy,
        uint256 vaultIdFee,
        uint256 nonce,
        uint256 expirationTimestamp
    ) external {
        bytes32 orderHash = calcL1LimitOrderHash(
            tokenIdSell,
            tokenIdBuy,
            tokenIdFee,
            amountSell,
            amountBuy,
            amountFee,
            vaultIdSell,
            vaultIdBuy,
            vaultIdFee,
            nonce,
            expirationTimestamp
        );
        registerMessage(exchangeAddress, orderHash);

        emit LogL1LimitOrderRegistered(
            msg.sender,
            exchangeAddress,
            tokenIdSell,
            tokenIdBuy,
            tokenIdFee,
            amountSell,
            amountBuy,
            amountFee,
            vaultIdSell,
            vaultIdBuy,
            vaultIdFee,
            nonce,
            expirationTimestamp
        );
    }
}