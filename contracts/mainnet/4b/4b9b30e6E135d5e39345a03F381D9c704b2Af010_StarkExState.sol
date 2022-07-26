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

import "Escapes.sol";
import "StarkExForcedActionState.sol";
import "UpdateState.sol";
import "Freezable.sol";
import "MainGovernance.sol";
import "StarkExOperator.sol";
import "AcceptModifications.sol";
import "StateRoot.sol";
import "TokenQuantization.sol";
import "SubContractor.sol";

contract StarkExState is
    MainGovernance,
    SubContractor,
    StarkExOperator,
    Freezable,
    AcceptModifications,
    TokenQuantization,
    StarkExForcedActionState,
    StateRoot,
    Escapes,
    UpdateState
{
    // InitializationArgStruct contains 2 * address + 8 * uint256 + 1 * bool = 352 bytes.
    uint256 constant INITIALIZER_SIZE = 11 * 32;

    struct InitializationArgStruct {
        uint256 globalConfigCode;
        address escapeVerifierAddress;
        uint256 sequenceNumber;
        uint256 validiumVaultRoot;
        uint256 rollupVaultRoot;
        uint256 orderRoot;
        uint256 validiumTreeHeight;
        uint256 rollupTreeHeight;
        uint256 orderTreeHeight;
        bool strictVaultBalancePolicy;
        address orderRegistryAddress;
    }

    /*
      Initialization flow:
      1. Extract initialization parameters from data.
      2. Call internalInitializer with those parameters.
    */
    function initialize(bytes calldata data) external virtual override {
        // This initializer sets roots etc. It must not be applied twice.
        // I.e. it can run only when the state is still empty.
        string memory ALREADY_INITIALIZED_MSG = "STATE_ALREADY_INITIALIZED";
        require(validiumVaultRoot == 0, ALREADY_INITIALIZED_MSG);
        require(validiumTreeHeight == 0, ALREADY_INITIALIZED_MSG);
        require(rollupVaultRoot == 0, ALREADY_INITIALIZED_MSG);
        require(rollupTreeHeight == 0, ALREADY_INITIALIZED_MSG);
        require(orderRoot == 0, ALREADY_INITIALIZED_MSG);
        require(orderTreeHeight == 0, ALREADY_INITIALIZED_MSG);

        require(data.length == INITIALIZER_SIZE, "INCORRECT_INIT_DATA_SIZE_352");

        // Copies initializer values into initValues.
        // TODO(zuphit,01/06/2021): Add a struct parsing test.
        InitializationArgStruct memory initValues;
        bytes memory _data = data;
        assembly {
            initValues := add(32, _data)
        }
        require(initValues.globalConfigCode < K_MODULUS, "GLOBAL_CONFIG_CODE >= PRIME");

        initGovernance();
        StarkExOperator.initialize();
        StateRoot.initialize(
            initValues.sequenceNumber,
            initValues.validiumVaultRoot,
            initValues.rollupVaultRoot,
            initValues.orderRoot,
            initValues.validiumTreeHeight,
            initValues.rollupTreeHeight,
            initValues.orderTreeHeight
        );
        Escapes.initialize(initValues.escapeVerifierAddress);
        globalConfigCode = initValues.globalConfigCode;
        strictVaultBalancePolicy = initValues.strictVaultBalancePolicy;
        orderRegistryAddress = initValues.orderRegistryAddress;
    }

    /*
      The call to initializerSize is done from MainDispatcherBase using delegatecall,
      thus the existing state is already accessible.
    */
    function initializerSize() external view virtual override returns (uint256) {
        return INITIALIZER_SIZE;
    }

    function validatedSelectors() external pure override returns (bytes4[] memory selectors) {
        uint256 len_ = 1;
        uint256 index_ = 0;

        selectors = new bytes4[](len_);
        selectors[index_++] = Escapes.escape.selector;
        require(index_ == len_, "INCORRECT_SELECTORS_ARRAY_LENGTH");
    }

    function identify() external pure override returns (string memory) {
        return "StarkWare_StarkExState_2022_4";
    }
}