/*
    Copyright 2022 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

import {ISetToken} from "@setprotocol/set-protocol-v2/contracts/interfaces/ISetToken.sol";
import {IWETH} from "@setprotocol/set-protocol-v2/contracts/interfaces/external/IWETH.sol";
import {IWrapModuleV2} from "@setprotocol/set-protocol-v2/contracts/interfaces/IWrapModuleV2.sol";

import {BaseGlobalExtension} from "../lib/BaseGlobalExtension.sol";
import {IDelegatedManager} from "../interfaces/IDelegatedManager.sol";
import {IManagerCore} from "../interfaces/IManagerCore.sol";

/**
 * @title WrapExtension
 * @author Set Protocol
 *
 * Smart contract global extension which provides DelegatedManager operator(s) the ability to wrap ERC20 and Ether positions
 * via third party protocols.
 *
 * Some examples of wrap actions include wrapping, DAI to cDAI (Compound) or Dai to aDai (AAVE).
 */
contract WrapExtension is BaseGlobalExtension {
    /* ============ Events ============ */

    event WrapExtensionInitialized(
        address indexed _setToken,
        address indexed _delegatedManager
    );

    /* ============ State Variables ============ */

    // Instance of WrapModuleV2
    IWrapModuleV2 public immutable wrapModule;

    /* ============ Constructor ============ */

    /**
     * Instantiate with ManagerCore address and WrapModuleV2 address.
     *
     * @param _managerCore              Address of ManagerCore contract
     * @param _wrapModule               Address of WrapModuleV2 contract
     */
    constructor(IManagerCore _managerCore, IWrapModuleV2 _wrapModule)
        public
        BaseGlobalExtension(_managerCore)
    {
        wrapModule = _wrapModule;
    }

    /* ============ External Functions ============ */

    /**
     * ONLY OWNER: Initializes WrapModuleV2 on the SetToken associated with the DelegatedManager.
     *
     * @param _delegatedManager     Instance of the DelegatedManager to initialize the WrapModuleV2 for
     */
    function initializeModule(IDelegatedManager _delegatedManager)
        external
        onlyOwnerAndValidManager(_delegatedManager)
    {
        _initializeModule(_delegatedManager.setToken(), _delegatedManager);
    }

    /**
     * ONLY OWNER: Initializes WrapExtension to the DelegatedManager.
     *
     * @param _delegatedManager     Instance of the DelegatedManager to initialize
     */
    function initializeExtension(IDelegatedManager _delegatedManager)
        external
        onlyOwnerAndValidManager(_delegatedManager)
    {
        ISetToken setToken = _delegatedManager.setToken();

        _initializeExtension(setToken, _delegatedManager);

        emit WrapExtensionInitialized(
            address(setToken),
            address(_delegatedManager)
        );
    }

    /**
     * ONLY OWNER: Initializes WrapExtension to the DelegatedManager and TradeModule to the SetToken
     *
     * @param _delegatedManager     Instance of the DelegatedManager to initialize
     */
    function initializeModuleAndExtension(IDelegatedManager _delegatedManager)
        external
        onlyOwnerAndValidManager(_delegatedManager)
    {
        ISetToken setToken = _delegatedManager.setToken();

        _initializeExtension(setToken, _delegatedManager);
        _initializeModule(setToken, _delegatedManager);

        emit WrapExtensionInitialized(
            address(setToken),
            address(_delegatedManager)
        );
    }

    /**
     * ONLY MANAGER: Remove an existing SetToken and DelegatedManager tracked by the WrapExtension
     */
    function removeExtension() external override {
        IDelegatedManager delegatedManager = IDelegatedManager(msg.sender);
        ISetToken setToken = delegatedManager.setToken();

        _removeExtension(setToken, delegatedManager);
    }

    /**
     * ONLY OPERATOR: Instructs the SetToken to wrap an underlying asset into a wrappedToken via a specified adapter.
     *
     * @param _setToken             Instance of the SetToken
     * @param _underlyingToken      Address of the component to be wrapped
     * @param _wrappedToken         Address of the desired wrapped token
     * @param _underlyingUnits      Quantity of underlying units in Position units
     * @param _integrationName      Name of wrap module integration (mapping on integration registry)
     * @param _wrapData             Arbitrary bytes to pass into the WrapV2Adapter
     */
    function wrap(
        ISetToken _setToken,
        address _underlyingToken,
        address _wrappedToken,
        uint256 _underlyingUnits,
        string calldata _integrationName,
        bytes memory _wrapData
    )
        external
        onlyOperator(_setToken)
        onlyAllowedAsset(_setToken, _wrappedToken)
    {
        bytes memory callData = abi.encodeWithSelector(
            IWrapModuleV2.wrap.selector,
            _setToken,
            _underlyingToken,
            _wrappedToken,
            _underlyingUnits,
            _integrationName,
            _wrapData
        );
        _invokeManager(_manager(_setToken), address(wrapModule), callData);
    }

    /**
     * ONLY OPERATOR: Instructs the SetToken to wrap Ether into a wrappedToken via a specified adapter. Since SetTokens
     * only hold WETH, in order to support protocols that collateralize with Ether the SetToken's WETH must be unwrapped
     * first before sending to the external protocol.
     *
     * @param _setToken             Instance of the SetToken
     * @param _wrappedToken         Address of the desired wrapped token
     * @param _underlyingUnits      Quantity of underlying units in Position units
     * @param _integrationName      Name of wrap module integration (mapping on integration registry)
     * @param _wrapData             Arbitrary bytes to pass into the WrapV2Adapter
     */
    function wrapWithEther(
        ISetToken _setToken,
        address _wrappedToken,
        uint256 _underlyingUnits,
        string calldata _integrationName,
        bytes memory _wrapData
    ) external onlyOperator(_setToken) {
        bytes memory callData = abi.encodeWithSelector(
            IWrapModuleV2.wrapWithEther.selector,
            _setToken,
            _wrappedToken,
            _underlyingUnits,
            _integrationName,
            _wrapData
        );
        _invokeManager(_manager(_setToken), address(wrapModule), callData);
    }

    /**
     * ONLY OPERATOR: Instructs the SetToken to unwrap a wrapped asset into its underlying via a specified adapter.
     *
     * @param _setToken             Instance of the SetToken
     * @param _underlyingToken      Address of the underlying asset
     * @param _wrappedToken         Address of the component to be unwrapped
     * @param _wrappedUnits         Quantity of wrapped tokens in Position units
     * @param _integrationName      ID of wrap module integration (mapping on integration registry)
     * @param _unwrapData           Arbitrary bytes to pass into the WrapV2Adapter
     */
    function unwrap(
        ISetToken _setToken,
        address _underlyingToken,
        address _wrappedToken,
        uint256 _wrappedUnits,
        string calldata _integrationName,
        bytes memory _unwrapData
    )
        external
        onlyOperator(_setToken)
        onlyAllowedAsset(_setToken, _underlyingToken)
    {
        bytes memory callData = abi.encodeWithSelector(
            IWrapModuleV2.unwrap.selector,
            _setToken,
            _underlyingToken,
            _wrappedToken,
            _wrappedUnits,
            _integrationName,
            _unwrapData
        );
        _invokeManager(_manager(_setToken), address(wrapModule), callData);
    }

    /**
     * ONLY OPERATOR: Instructs the SetToken to unwrap a wrapped asset collateralized by Ether into Wrapped Ether. Since
     * external protocol will send back Ether that Ether must be Wrapped into WETH in order to be accounted for by SetToken.
     *
     * @param _setToken                 Instance of the SetToken
     * @param _wrappedToken             Address of the component to be unwrapped
     * @param _wrappedUnits             Quantity of wrapped tokens in Position units
     * @param _integrationName          ID of wrap module integration (mapping on integration registry)
     * @param _unwrapData           Arbitrary bytes to pass into the WrapV2Adapter
     */
    function unwrapWithEther(
        ISetToken _setToken,
        address _wrappedToken,
        uint256 _wrappedUnits,
        string calldata _integrationName,
        bytes memory _unwrapData
    )
        external
        onlyOperator(_setToken)
        onlyAllowedAsset(_setToken, address(wrapModule.weth()))
    {
        bytes memory callData = abi.encodeWithSelector(
            IWrapModuleV2.unwrapWithEther.selector,
            _setToken,
            _wrappedToken,
            _wrappedUnits,
            _integrationName,
            _unwrapData
        );
        _invokeManager(_manager(_setToken), address(wrapModule), callData);
    }

    /* ============ Internal Functions ============ */

    /**
     * Internal function to initialize WrapModuleV2 on the SetToken associated with the DelegatedManager.
     *
     * @param _setToken             Instance of the SetToken corresponding to the DelegatedManager
     * @param _delegatedManager     Instance of the DelegatedManager to initialize the WrapModuleV2 for
     */
    function _initializeModule(
        ISetToken _setToken,
        IDelegatedManager _delegatedManager
    ) internal {
        bytes memory callData = abi.encodeWithSelector(
            IWrapModuleV2.initialize.selector,
            _setToken
        );
        _invokeManager(_delegatedManager, address(wrapModule), callData);
    }
}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title ISetToken
 * @author Set Protocol
 *
 * Interface for operating with SetTokens.
 */
interface ISetToken is IERC20 {

    /* ============ Enums ============ */

    enum ModuleState {
        NONE,
        PENDING,
        INITIALIZED
    }

    /* ============ Structs ============ */
    /**
     * The base definition of a SetToken Position
     *
     * @param component           Address of token in the Position
     * @param module              If not in default state, the address of associated module
     * @param unit                Each unit is the # of components per 10^18 of a SetToken
     * @param positionState       Position ENUM. Default is 0; External is 1
     * @param data                Arbitrary data
     */
    struct Position {
        address component;
        address module;
        int256 unit;
        uint8 positionState;
        bytes data;
    }

    /**
     * A struct that stores a component's cash position details and external positions
     * This data structure allows O(1) access to a component's cash position units and 
     * virtual units.
     *
     * @param virtualUnit               Virtual value of a component's DEFAULT position. Stored as virtual for efficiency
     *                                  updating all units at once via the position multiplier. Virtual units are achieved
     *                                  by dividing a "real" value by the "positionMultiplier"
     * @param componentIndex            
     * @param externalPositionModules   List of external modules attached to each external position. Each module
     *                                  maps to an external position
     * @param externalPositions         Mapping of module => ExternalPosition struct for a given component
     */
    struct ComponentPosition {
      int256 virtualUnit;
      address[] externalPositionModules;
      mapping(address => ExternalPosition) externalPositions;
    }

    /**
     * A struct that stores a component's external position details including virtual unit and any
     * auxiliary data.
     *
     * @param virtualUnit       Virtual value of a component's EXTERNAL position.
     * @param data              Arbitrary data
     */
    struct ExternalPosition {
      int256 virtualUnit;
      bytes data;
    }


    /* ============ Functions ============ */
    
    function addComponent(address _component) external;
    function removeComponent(address _component) external;
    function editDefaultPositionUnit(address _component, int256 _realUnit) external;
    function addExternalPositionModule(address _component, address _positionModule) external;
    function removeExternalPositionModule(address _component, address _positionModule) external;
    function editExternalPositionUnit(address _component, address _positionModule, int256 _realUnit) external;
    function editExternalPositionData(address _component, address _positionModule, bytes calldata _data) external;

    function invoke(address _target, uint256 _value, bytes calldata _data) external returns(bytes memory);

    function editPositionMultiplier(int256 _newMultiplier) external;

    function mint(address _account, uint256 _quantity) external;
    function burn(address _account, uint256 _quantity) external;

    function lock() external;
    function unlock() external;

    function addModule(address _module) external;
    function removeModule(address _module) external;
    function initializeModule() external;

    function setManager(address _manager) external;

    function manager() external view returns (address);
    function moduleStates(address _module) external view returns (ModuleState);
    function getModules() external view returns (address[] memory);
    
    function getDefaultPositionRealUnit(address _component) external view returns(int256);
    function getExternalPositionRealUnit(address _component, address _positionModule) external view returns(int256);
    function getComponents() external view returns(address[] memory);
    function getExternalPositionModules(address _component) external view returns(address[] memory);
    function getExternalPositionData(address _component, address _positionModule) external view returns(bytes memory);
    function isExternalPositionModule(address _component, address _module) external view returns(bool);
    function isComponent(address _component) external view returns(bool);
    
    function positionMultiplier() external view returns (int256);
    function getPositions() external view returns (Position[] memory);
    function getTotalComponentRealUnits(address _component) external view returns(int256);

    function isInitializedModule(address _module) external view returns(bool);
    function isPendingModule(address _module) external view returns(bool);
    function isLocked() external view returns (bool);
}

/*
    Copyright 2018 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.6.10;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IWETH
 * @author Set Protocol
 *
 * Interface for Wrapped Ether. This interface allows for interaction for wrapped ether's deposit and withdrawal
 * functionality.
 */
interface IWETH is IERC20{
    function deposit()
        external
        payable;

    function withdraw(
        uint256 wad
    )
        external;
}

/*
    Copyright 2022 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

import { ISetToken } from "./ISetToken.sol";
import { IWETH } from "./external/IWETH.sol";

interface IWrapModuleV2 {
    function weth() external view returns(IWETH);

    function initialize(ISetToken _setToken) external;

    function wrap(
        ISetToken _setToken,
        address _underlyingToken,
        address _wrappedToken,
        uint256 _underlyingUnits,
        string calldata _integrationName,
        bytes memory _wrapData
    ) external;

    function wrapWithEther(
        ISetToken _setToken,
        address _wrappedToken,
        uint256 _underlyingUnits,
        string calldata _integrationName,
        bytes memory _wrapData
    ) external;

    function unwrap(
        ISetToken _setToken,
        address _underlyingToken,
        address _wrappedToken,
        uint256 _wrappedUnits,
        string calldata _integrationName,
        bytes memory _unwrapData
    ) external;

    function unwrapWithEther(
        ISetToken _setToken,
        address _wrappedToken,
        uint256 _wrappedUnits,
        string calldata _integrationName,
        bytes memory _unwrapData
    ) external;
}

/*
    Copyright 2022 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.6.10;

import { AddressArrayUtils } from "@setprotocol/set-protocol-v2/contracts/lib/AddressArrayUtils.sol";
import { ISetToken } from "@setprotocol/set-protocol-v2/contracts/interfaces/ISetToken.sol";

import { IDelegatedManager } from "../interfaces/IDelegatedManager.sol";
import { IManagerCore } from "../interfaces/IManagerCore.sol";

/**
 * @title BaseGlobalExtension
 * @author Set Protocol
 *
 * Abstract class that houses common global extension-related functions. Global extensions must
 * also have their own initializeExtension function (not included here because interfaces will vary).
 */
abstract contract BaseGlobalExtension {
    using AddressArrayUtils for address[];

    /* ============ Events ============ */

    event ExtensionRemoved(
        address indexed _setToken,
        address indexed _delegatedManager
    );

    /* ============ State Variables ============ */

    // Address of the ManagerCore
    IManagerCore public immutable managerCore;

    // Mapping from Set Token to DelegatedManager
    mapping(ISetToken => IDelegatedManager) public setManagers;

    /* ============ Modifiers ============ */

    /**
     * Throws if the sender is not the SetToken manager contract owner
     */
    modifier onlyOwner(ISetToken _setToken) {
        require(msg.sender == _manager(_setToken).owner(), "Must be owner");
        _;
    }

    /**
     * Throws if the sender is not the SetToken methodologist
     */
    modifier onlyMethodologist(ISetToken _setToken) {
        require(msg.sender == _manager(_setToken).methodologist(), "Must be methodologist");
        _;
    }

    /**
     * Throws if the sender is not a SetToken operator
     */
    modifier onlyOperator(ISetToken _setToken) {
        require(_manager(_setToken).operatorAllowlist(msg.sender), "Must be approved operator");
        _;
    }

    /**
     * Throws if the sender is not the SetToken manager contract owner or if the manager is not enabled on the ManagerCore
     */
    modifier onlyOwnerAndValidManager(IDelegatedManager _delegatedManager) {
        require(msg.sender == _delegatedManager.owner(), "Must be owner");
        require(managerCore.isManager(address(_delegatedManager)), "Must be ManagerCore-enabled manager");
        _;
    }

    /**
     * Throws if asset is not allowed to be held by the Set
     */
    modifier onlyAllowedAsset(ISetToken _setToken, address _asset) {
        require(_manager(_setToken).isAllowedAsset(_asset), "Must be allowed asset");
        _;
    }

    /* ============ Constructor ============ */

    /**
     * Set state variables
     *
     * @param _managerCore             Address of managerCore contract
     */
    constructor(IManagerCore _managerCore) public {
        managerCore = _managerCore;
    }

    /* ============ External Functions ============ */

    /**
     * ONLY MANAGER: Deletes SetToken/Manager state from extension. Must only be callable by manager!
     */
    function removeExtension() external virtual;

    /* ============ Internal Functions ============ */

    /**
     * Invoke call from manager
     *
     * @param _delegatedManager      Manager to interact with
     * @param _module                Module to interact with
     * @param _encoded               Encoded byte data
     */
    function _invokeManager(IDelegatedManager _delegatedManager, address _module, bytes memory _encoded) internal {
        _delegatedManager.interactManager(_module, _encoded);
    }

    /**
     * Internal function to grab manager of passed SetToken from extensions data structure.
     *
     * @param _setToken         SetToken who's manager is needed
     */
    function _manager(ISetToken _setToken) internal view returns (IDelegatedManager) {
        return setManagers[_setToken];
    }

    /**
     * Internal function to initialize extension to the DelegatedManager.
     *
     * @param _setToken             Instance of the SetToken corresponding to the DelegatedManager
     * @param _delegatedManager     Instance of the DelegatedManager to initialize
     */
    function _initializeExtension(ISetToken _setToken, IDelegatedManager _delegatedManager) internal {
        setManagers[_setToken] = _delegatedManager;

        _delegatedManager.initializeExtension();
    }

    /**
     * ONLY MANAGER: Internal function to delete SetToken/Manager state from extension
     */
    function _removeExtension(ISetToken _setToken, IDelegatedManager _delegatedManager) internal {
        require(msg.sender == address(_manager(_setToken)), "Must be Manager");

        delete setManagers[_setToken];

        emit ExtensionRemoved(address(_setToken), address(_delegatedManager));
    }
}

/*
    Copyright 2021 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

import { ISetToken } from "@setprotocol/set-protocol-v2/contracts/interfaces/ISetToken.sol";

interface IDelegatedManager {
    function interactManager(address _module, bytes calldata _encoded) external;

    function initializeExtension() external;

    function transferTokens(address _token, address _destination, uint256 _amount) external;

    function updateOwnerFeeSplit(uint256 _newFeeSplit) external;

    function updateOwnerFeeRecipient(address _newFeeRecipient) external;

    function setMethodologist(address _newMethodologist) external;

    function transferOwnership(address _owner) external;

    function setToken() external view returns(ISetToken);
    function owner() external view returns(address);
    function methodologist() external view returns(address);
    function operatorAllowlist(address _operator) external view returns(bool);
    function assetAllowlist(address _asset) external view returns(bool);
    function useAssetAllowlist() external view returns(bool);
    function isAllowedAsset(address _asset) external view returns(bool);
    function isPendingExtension(address _extension) external view returns(bool);
    function isInitializedExtension(address _extension) external view returns(bool);
    function getExtensions() external view returns(address[] memory);
    function getOperators() external view returns(address[] memory);
    function getAllowedAssets() external view returns(address[] memory);
    function ownerFeeRecipient() external view returns(address);
    function ownerFeeSplit() external view returns(uint256);
}

/*
    Copyright 2022 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.6.10;

interface IManagerCore {
    function addManager(address _manager) external;
    function isExtension(address _extension) external view returns(bool);
    function isFactory(address _factory) external view returns(bool);
    function isManager(address _manager) external view returns(bool);
    function owner() external view returns(address);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0

*/

pragma solidity 0.6.10;

/**
 * @title AddressArrayUtils
 * @author Set Protocol
 *
 * Utility functions to handle Address Arrays
 *
 * CHANGELOG:
 * - 4/21/21: Added validatePairsWithArray methods
 */
library AddressArrayUtils {

    /**
     * Finds the index of the first occurrence of the given element.
     * @param A The input array to search
     * @param a The value to find
     * @return Returns (index and isIn) for the first occurrence starting from index 0
     */
    function indexOf(address[] memory A, address a) internal pure returns (uint256, bool) {
        uint256 length = A.length;
        for (uint256 i = 0; i < length; i++) {
            if (A[i] == a) {
                return (i, true);
            }
        }
        return (uint256(-1), false);
    }

    /**
    * Returns true if the value is present in the list. Uses indexOf internally.
    * @param A The input array to search
    * @param a The value to find
    * @return Returns isIn for the first occurrence starting from index 0
    */
    function contains(address[] memory A, address a) internal pure returns (bool) {
        (, bool isIn) = indexOf(A, a);
        return isIn;
    }

    /**
    * Returns true if there are 2 elements that are the same in an array
    * @param A The input array to search
    * @return Returns boolean for the first occurrence of a duplicate
    */
    function hasDuplicate(address[] memory A) internal pure returns(bool) {
        require(A.length > 0, "A is empty");

        for (uint256 i = 0; i < A.length - 1; i++) {
            address current = A[i];
            for (uint256 j = i + 1; j < A.length; j++) {
                if (current == A[j]) {
                    return true;
                }
            }
        }
        return false;
    }

    /**
     * @param A The input array to search
     * @param a The address to remove
     * @return Returns the array with the object removed.
     */
    function remove(address[] memory A, address a)
        internal
        pure
        returns (address[] memory)
    {
        (uint256 index, bool isIn) = indexOf(A, a);
        if (!isIn) {
            revert("Address not in array.");
        } else {
            (address[] memory _A,) = pop(A, index);
            return _A;
        }
    }

    /**
     * @param A The input array to search
     * @param a The address to remove
     */
    function removeStorage(address[] storage A, address a)
        internal
    {
        (uint256 index, bool isIn) = indexOf(A, a);
        if (!isIn) {
            revert("Address not in array.");
        } else {
            uint256 lastIndex = A.length - 1; // If the array would be empty, the previous line would throw, so no underflow here
            if (index != lastIndex) { A[index] = A[lastIndex]; }
            A.pop();
        }
    }

    /**
    * Removes specified index from array
    * @param A The input array to search
    * @param index The index to remove
    * @return Returns the new array and the removed entry
    */
    function pop(address[] memory A, uint256 index)
        internal
        pure
        returns (address[] memory, address)
    {
        uint256 length = A.length;
        require(index < A.length, "Index must be < A length");
        address[] memory newAddresses = new address[](length - 1);
        for (uint256 i = 0; i < index; i++) {
            newAddresses[i] = A[i];
        }
        for (uint256 j = index + 1; j < length; j++) {
            newAddresses[j - 1] = A[j];
        }
        return (newAddresses, A[index]);
    }

    /**
     * Returns the combination of the two arrays
     * @param A The first array
     * @param B The second array
     * @return Returns A extended by B
     */
    function extend(address[] memory A, address[] memory B) internal pure returns (address[] memory) {
        uint256 aLength = A.length;
        uint256 bLength = B.length;
        address[] memory newAddresses = new address[](aLength + bLength);
        for (uint256 i = 0; i < aLength; i++) {
            newAddresses[i] = A[i];
        }
        for (uint256 j = 0; j < bLength; j++) {
            newAddresses[aLength + j] = B[j];
        }
        return newAddresses;
    }

    /**
     * Validate that address and uint array lengths match. Validate address array is not empty
     * and contains no duplicate elements.
     *
     * @param A         Array of addresses
     * @param B         Array of uint
     */
    function validatePairsWithArray(address[] memory A, uint[] memory B) internal pure {
        require(A.length == B.length, "Array length mismatch");
        _validateLengthAndUniqueness(A);
    }

    /**
     * Validate that address and bool array lengths match. Validate address array is not empty
     * and contains no duplicate elements.
     *
     * @param A         Array of addresses
     * @param B         Array of bool
     */
    function validatePairsWithArray(address[] memory A, bool[] memory B) internal pure {
        require(A.length == B.length, "Array length mismatch");
        _validateLengthAndUniqueness(A);
    }

    /**
     * Validate that address and string array lengths match. Validate address array is not empty
     * and contains no duplicate elements.
     *
     * @param A         Array of addresses
     * @param B         Array of strings
     */
    function validatePairsWithArray(address[] memory A, string[] memory B) internal pure {
        require(A.length == B.length, "Array length mismatch");
        _validateLengthAndUniqueness(A);
    }

    /**
     * Validate that address array lengths match, and calling address array are not empty
     * and contain no duplicate elements.
     *
     * @param A         Array of addresses
     * @param B         Array of addresses
     */
    function validatePairsWithArray(address[] memory A, address[] memory B) internal pure {
        require(A.length == B.length, "Array length mismatch");
        _validateLengthAndUniqueness(A);
    }

    /**
     * Validate that address and bytes array lengths match. Validate address array is not empty
     * and contains no duplicate elements.
     *
     * @param A         Array of addresses
     * @param B         Array of bytes
     */
    function validatePairsWithArray(address[] memory A, bytes[] memory B) internal pure {
        require(A.length == B.length, "Array length mismatch");
        _validateLengthAndUniqueness(A);
    }

    /**
     * Validate address array is not empty and contains no duplicate elements.
     *
     * @param A          Array of addresses
     */
    function _validateLengthAndUniqueness(address[] memory A) internal pure {
        require(A.length > 0, "Array length must be > 0");
        require(!hasDuplicate(A), "Cannot duplicate addresses");
    }
}