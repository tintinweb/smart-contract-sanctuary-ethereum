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

import { ISetToken } from "@setprotocol/set-protocol-v2/contracts/interfaces/ISetToken.sol";
import { ITradeModule } from "@setprotocol/set-protocol-v2/contracts/interfaces/ITradeModule.sol";
import { StringArrayUtils } from "@setprotocol/set-protocol-v2/contracts/lib/StringArrayUtils.sol";

import { BaseGlobalExtension } from "../lib/BaseGlobalExtension.sol";
import { IDelegatedManager } from "../interfaces/IDelegatedManager.sol";
import { IManagerCore } from "../interfaces/IManagerCore.sol";

/**
 * @title BatchTradeExtension
 * @author Set Protocol
 *
 * Smart contract global extension which provides DelegatedManager operator(s) the ability to execute a batch of trades
 * on a DEX and the owner the ability to restrict operator(s) permissions with an asset whitelist.
 */
contract BatchTradeExtension is BaseGlobalExtension {
    using StringArrayUtils for string[];

    /* ============ Structs ============ */

    struct TradeInfo {
        string exchangeName;             // Human readable name of the exchange in the integrations registry
        address sendToken;               // Address of the token to be sent to the exchange
        uint256 sendQuantity;            // Max units of `sendToken` sent to the exchange
        address receiveToken;            // Address of the token that will be received from the exchange
        uint256 receiveQuantity;         // Min units of `receiveToken` to be received from the exchange
        bytes data;                      // Arbitrary bytes to be used to construct trade call data
    }

    /* ============ Events ============ */

    event IntegrationAdded(
        string _integrationName          // String name of TradeModule exchange integration to allow
    );

    event IntegrationRemoved(
        string _integrationName          // String name of TradeModule exchange integration to disallow
    );

    event BatchTradeExtensionInitialized(
        address indexed _setToken,                 // Address of the SetToken which had BatchTradeExtension initialized on their manager
        address indexed _delegatedManager          // Address of the DelegatedManager which initialized the BatchTradeExtension
    );

    event StringTradeFailed(
        address indexed _setToken,       // Address of the SetToken which the failed trade targeted
        uint256 indexed _index,          // Index of trade that failed in _trades parameter of batchTrade call
        string _reason,                  // String reason for the trade failure
        TradeInfo _tradeInfo             // Input TradeInfo of the failed trade
    );

    event BytesTradeFailed(
        address indexed _setToken,       // Address of the SetToken which the failed trade targeted
        uint256 indexed _index,          // Index of trade that failed in _trades parameter of batchTrade call
        bytes _lowLevelData,             // Bytes low level data reason for the trade failure
        TradeInfo _tradeInfo             // Input TradeInfo of the failed trade
    );

    /* ============ State Variables ============ */

    // Instance of TradeModule
    ITradeModule public immutable tradeModule;

    // List of allowed TradeModule exchange integrations
    string[] public integrations;

    // Mapping to check whether string is allowed TradeModule exchange integration
    mapping(string => bool) public isIntegration;

    /* ============ Modifiers ============ */

    /**
     * Throws if the sender is not the ManagerCore contract owner
     */
    modifier onlyManagerCoreOwner() {
        require(msg.sender == managerCore.owner(), "Caller must be ManagerCore owner");
        _;
    }

    /* ============ Constructor ============ */

    /**
     * Instantiate with ManagerCore address, TradeModule address, and allowed TradeModule integration strings.
     *
     * @param _managerCore              Address of ManagerCore contract
     * @param _tradeModule              Address of TradeModule contract
     * @param _integrations             List of TradeModule exchange integrations to allow
     */
    constructor(
        IManagerCore _managerCore,
        ITradeModule _tradeModule,
        string[] memory _integrations
    )
        public
        BaseGlobalExtension(_managerCore)
    {
        tradeModule = _tradeModule;

        integrations = _integrations;
        uint256 integrationsLength = _integrations.length;
        for (uint256 i = 0; i < integrationsLength; i++) {
            _addIntegration(_integrations[i]);
        }
    }

    /* ============ External Functions ============ */

    /**
     * MANAGER OWNER ONLY. Allows manager owner to add allowed TradeModule exchange integrations
     *
     * @param _integrations     List of TradeModule exchange integrations to allow
     */
    function addIntegrations(string[] memory _integrations) external onlyManagerCoreOwner {
        uint256 integrationsLength = _integrations.length;
        for (uint256 i = 0; i < integrationsLength; i++) {
            require(!isIntegration[_integrations[i]], "Integration already exists");

            integrations.push(_integrations[i]);

            _addIntegration(_integrations[i]);
        }
    }

    /**
     * MANAGER OWNER ONLY. Allows manager owner to remove allowed TradeModule exchange integrations
     *
     * @param _integrations     List of TradeModule exchange integrations to disallow
     */
    function removeIntegrations(string[] memory _integrations) external onlyManagerCoreOwner {
        uint256 integrationsLength = _integrations.length;
        for (uint256 i = 0; i < integrationsLength; i++) {
            require(isIntegration[_integrations[i]], "Integration does not exist");

            integrations.removeStorage(_integrations[i]);

            isIntegration[_integrations[i]] = false;

            IntegrationRemoved(_integrations[i]);
        }
    }

    /**
     * ONLY OWNER: Initializes TradeModule on the SetToken associated with the DelegatedManager.
     *
     * @param _delegatedManager     Instance of the DelegatedManager to initialize the TradeModule for
     */
    function initializeModule(IDelegatedManager _delegatedManager) external onlyOwnerAndValidManager(_delegatedManager) {
        _initializeModule(_delegatedManager.setToken(), _delegatedManager);
    }

    /**
     * ONLY OWNER: Initializes BatchTradeExtension to the DelegatedManager.
     *
     * @param _delegatedManager     Instance of the DelegatedManager to initialize
     */
    function initializeExtension(IDelegatedManager _delegatedManager) external onlyOwnerAndValidManager(_delegatedManager) {
        ISetToken setToken = _delegatedManager.setToken();

        _initializeExtension(setToken, _delegatedManager);

        emit BatchTradeExtensionInitialized(address(setToken), address(_delegatedManager));
    }

    /**
     * ONLY OWNER: Initializes BatchTradeExtension to the DelegatedManager and TradeModule to the SetToken
     *
     * @param _delegatedManager     Instance of the DelegatedManager to initialize
     */
    function initializeModuleAndExtension(IDelegatedManager _delegatedManager) external onlyOwnerAndValidManager(_delegatedManager){
        ISetToken setToken = _delegatedManager.setToken();

        _initializeExtension(setToken, _delegatedManager);
        _initializeModule(setToken, _delegatedManager);

        emit BatchTradeExtensionInitialized(address(setToken), address(_delegatedManager));
    }

    /**
     * ONLY MANAGER: Remove an existing SetToken and DelegatedManager tracked by the BatchTradeExtension
     */
    function removeExtension() external override {
        IDelegatedManager delegatedManager = IDelegatedManager(msg.sender);
        ISetToken setToken = delegatedManager.setToken();

        _removeExtension(setToken, delegatedManager);
    }

    /**
     * ONLY OPERATOR: Executes a batch of trades on a supported DEX. If any individual trades fail, events are emitted.
     * @dev Although the SetToken units are passed in for the send and receive quantities, the total quantity
     * sent and received is the quantity of component units multiplied by the SetToken totalSupply.
     *
     * @param _setToken             Instance of the SetToken to trade
     * @param _trades               Array of TradeInfo structs containing information about trades
     */
    function batchTrade(
        ISetToken _setToken,
        TradeInfo[] memory _trades
    )
        external
        onlyOperator(_setToken)
    {
        uint256 tradesLength = _trades.length;
        IDelegatedManager manager = _manager(_setToken);
        for(uint256 i = 0; i < tradesLength; i++) {
            require(isIntegration[_trades[i].exchangeName], "Must be allowed integration");
            require(manager.isAllowedAsset(_trades[i].receiveToken), "Must be allowed asset");

            bytes memory callData = abi.encodeWithSelector(
                ITradeModule.trade.selector,
                _setToken,
                _trades[i].exchangeName,
                _trades[i].sendToken,
                _trades[i].sendQuantity,
                _trades[i].receiveToken,
                _trades[i].receiveQuantity,
                _trades[i].data
            );

            // ZeroEx (for example) throws custom errors which slip through OpenZeppelin's
            // functionCallWithValue error management and surface here as `bytes`. These should be
            // decode-able off-chain given enough context about protocol targeted by the adapter.
            try manager.interactManager(address(tradeModule), callData) {}
            catch Error(string memory reason) {
                emit StringTradeFailed(
                    address(_setToken),
                    i,
                    reason,
                    _trades[i]
                );
            } catch (bytes memory lowLevelData) {
                emit BytesTradeFailed(
                    address(_setToken),
                    i,
                    lowLevelData,
                    _trades[i]
                );
            }
        }
    }

    /* ============ External Getter Functions ============ */

    function getIntegrations() external view returns (string[] memory) {
        return integrations;
    }

    /* ============ Internal Functions ============ */

    /**
     * Add an allowed TradeModule exchange integration to the BatchTradeExtension
     *
     * @param _integrationName               Name of TradeModule exchange integration to allow
     */
    function _addIntegration(string memory _integrationName) internal {
        isIntegration[_integrationName] = true;

        emit IntegrationAdded(_integrationName);
    }

    /**
     * Internal function to initialize TradeModule on the SetToken associated with the DelegatedManager.
     *
     * @param _setToken             Instance of the SetToken corresponding to the DelegatedManager
     * @param _delegatedManager     Instance of the DelegatedManager to initialize the TradeModule for
     */
    function _initializeModule(ISetToken _setToken, IDelegatedManager _delegatedManager) internal {
        bytes memory callData = abi.encodeWithSelector(ITradeModule.initialize.selector, _setToken);
        _invokeManager(_delegatedManager, address(tradeModule), callData);
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

interface ITradeModule {
    function initialize(ISetToken _setToken) external;

    function trade(
        ISetToken _setToken,
        string memory _exchangeName,
        address _sendToken,
        uint256 _sendQuantity,
        address _receiveToken,
        uint256 _minReceiveQuantity,
        bytes memory _data
    ) external;
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

/**
 * @title StringArrayUtils
 * @author Set Protocol
 *
 * Utility functions to handle String Arrays
 */
library StringArrayUtils {

    /**
     * Finds the index of the first occurrence of the given element.
     * @param A The input string to search
     * @param a The value to find
     * @return Returns (index and isIn) for the first occurrence starting from index 0
     */
    function indexOf(string[] memory A, string memory a) internal pure returns (uint256, bool) {
        uint256 length = A.length;
        for (uint256 i = 0; i < length; i++) {
            if (keccak256(bytes(A[i])) == keccak256(bytes(a))) {
                return (i, true);
            }
        }
        return (uint256(-1), false);
    }

    /**
     * @param A The input array to search
     * @param a The string to remove
     */
    function removeStorage(string[] storage A, string memory a)
        internal
    {
        (uint256 index, bool isIn) = indexOf(A, a);
        if (!isIn) {
            revert("String not in array.");
        } else {
            uint256 lastIndex = A.length - 1; // If the array would be empty, the previous line would throw, so no underflow here
            if (index != lastIndex) { A[index] = A[lastIndex]; }
            A.pop();
        }
    }
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

import { ISetToken } from "@setprotocol/set-protocol-v2/contracts/interfaces/ISetToken.sol";

import { BaseGlobalExtension } from "../lib/BaseGlobalExtension.sol";
import { IDelegatedManager } from "../interfaces/IDelegatedManager.sol";
import { IManagerCore } from "../interfaces/IManagerCore.sol";
import { ModuleMock } from "./ModuleMock.sol";

contract BaseGlobalExtensionMock is BaseGlobalExtension {

    /* ============ State Variables ============ */

    ModuleMock public immutable module;

    /* ============ Constructor ============ */

    constructor(
        IManagerCore _managerCore,
        ModuleMock _module
    )
        public
        BaseGlobalExtension(_managerCore)
    {
        module = _module;
    }

    /* ============ External Functions ============ */

    function initializeExtension(
        IDelegatedManager _delegatedManager
    )
        external
        onlyOwnerAndValidManager(_delegatedManager)
    {
        require(_delegatedManager.isPendingExtension(address(this)), "Extension must be pending");

        _initializeExtension(_delegatedManager.setToken(), _delegatedManager);
    }

    function initializeModuleAndExtension(
        IDelegatedManager _delegatedManager
    )
        external
        onlyOwnerAndValidManager(_delegatedManager)
    {
        require(_delegatedManager.isPendingExtension(address(this)), "Extension must be pending");

        ISetToken setToken = _delegatedManager.setToken();

        _initializeExtension(setToken, _delegatedManager);

        bytes memory callData = abi.encodeWithSignature("initialize(address)", setToken);
        _invokeManager(_delegatedManager, address(module), callData);
    }

    function testInvokeManager(ISetToken _setToken, address _module, bytes calldata _encoded) external {
        _invokeManager(_manager(_setToken), _module, _encoded);
    }

    function testOnlyOwner(ISetToken _setToken)
        external
        onlyOwner(_setToken)
    {}

    function testOnlyMethodologist(ISetToken _setToken)
        external
        onlyMethodologist(_setToken)
    {}

    function testOnlyOperator(ISetToken _setToken)
        external
        onlyOperator(_setToken)
    {}

    function testOnlyOwnerAndValidManager(IDelegatedManager _delegatedManager)
        external
        onlyOwnerAndValidManager(_delegatedManager)
    {}

    function testOnlyAllowedAsset(ISetToken _setToken, address _asset)
        external
        onlyAllowedAsset(_setToken, _asset)
    {}

    function removeExtension() external override {
        IDelegatedManager delegatedManager = IDelegatedManager(msg.sender);
        ISetToken setToken = delegatedManager.setToken();

        _removeExtension(setToken, delegatedManager);
    }
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

import { IController } from "@setprotocol/set-protocol-v2/contracts/interfaces/IController.sol";
import { ISetToken } from "@setprotocol/set-protocol-v2/contracts/interfaces/ISetToken.sol";
import { ModuleBase } from "@setprotocol/set-protocol-v2/contracts/protocol/lib/ModuleBase.sol";

contract ModuleMock is ModuleBase {

    bool public removed;

    /* ============ Constructor ============ */

    constructor(IController _controller) public ModuleBase(_controller) {}

    /* ============ External Functions ============ */

    function initialize(
        ISetToken _setToken
    )
        external
        onlyValidAndPendingSet(_setToken)
        onlySetManager(_setToken, msg.sender)
    {
        _setToken.initializeModule();
    }

    function removeModule() external override {
        removed = true;
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

interface IController {
    function addSet(address _setToken) external;
    function feeRecipient() external view returns(address);
    function getModuleFee(address _module, uint256 _feeType) external view returns(uint256);
    function isModule(address _module) external view returns(bool);
    function isSet(address _setToken) external view returns(bool);
    function isSystemContract(address _contractAddress) external view returns (bool);
    function resourceId(uint256 _id) external view returns(address);
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

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { AddressArrayUtils } from "../../lib/AddressArrayUtils.sol";
import { ExplicitERC20 } from "../../lib/ExplicitERC20.sol";
import { IController } from "../../interfaces/IController.sol";
import { IModule } from "../../interfaces/IModule.sol";
import { ISetToken } from "../../interfaces/ISetToken.sol";
import { Invoke } from "./Invoke.sol";
import { Position } from "./Position.sol";
import { PreciseUnitMath } from "../../lib/PreciseUnitMath.sol";
import { ResourceIdentifier } from "./ResourceIdentifier.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/SafeCast.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { SignedSafeMath } from "@openzeppelin/contracts/math/SignedSafeMath.sol";

/**
 * @title ModuleBase
 * @author Set Protocol
 *
 * Abstract class that houses common Module-related state and functions.
 *
 * CHANGELOG:
 * - 4/21/21: Delegated modifier logic to internal helpers to reduce contract size
 *
 */
abstract contract ModuleBase is IModule {
    using AddressArrayUtils for address[];
    using Invoke for ISetToken;
    using Position for ISetToken;
    using PreciseUnitMath for uint256;
    using ResourceIdentifier for IController;
    using SafeCast for int256;
    using SafeCast for uint256;
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    /* ============ State Variables ============ */

    // Address of the controller
    IController public controller;

    /* ============ Modifiers ============ */

    modifier onlyManagerAndValidSet(ISetToken _setToken) {
        _validateOnlyManagerAndValidSet(_setToken);
        _;
    }

    modifier onlySetManager(ISetToken _setToken, address _caller) {
        _validateOnlySetManager(_setToken, _caller);
        _;
    }

    modifier onlyValidAndInitializedSet(ISetToken _setToken) {
        _validateOnlyValidAndInitializedSet(_setToken);
        _;
    }

    /**
     * Throws if the sender is not a SetToken's module or module not enabled
     */
    modifier onlyModule(ISetToken _setToken) {
        _validateOnlyModule(_setToken);
        _;
    }

    /**
     * Utilized during module initializations to check that the module is in pending state
     * and that the SetToken is valid
     */
    modifier onlyValidAndPendingSet(ISetToken _setToken) {
        _validateOnlyValidAndPendingSet(_setToken);
        _;
    }

    /* ============ Constructor ============ */

    /**
     * Set state variables and map asset pairs to their oracles
     *
     * @param _controller             Address of controller contract
     */
    constructor(IController _controller) public {
        controller = _controller;
    }

    /* ============ Internal Functions ============ */

    /**
     * Transfers tokens from an address (that has set allowance on the module).
     *
     * @param  _token          The address of the ERC20 token
     * @param  _from           The address to transfer from
     * @param  _to             The address to transfer to
     * @param  _quantity       The number of tokens to transfer
     */
    function transferFrom(IERC20 _token, address _from, address _to, uint256 _quantity) internal {
        ExplicitERC20.transferFrom(_token, _from, _to, _quantity);
    }

    /**
     * Gets the integration for the module with the passed in name. Validates that the address is not empty
     */
    function getAndValidateAdapter(string memory _integrationName) internal view returns(address) { 
        bytes32 integrationHash = getNameHash(_integrationName);
        return getAndValidateAdapterWithHash(integrationHash);
    }

    /**
     * Gets the integration for the module with the passed in hash. Validates that the address is not empty
     */
    function getAndValidateAdapterWithHash(bytes32 _integrationHash) internal view returns(address) { 
        address adapter = controller.getIntegrationRegistry().getIntegrationAdapterWithHash(
            address(this),
            _integrationHash
        );

        require(adapter != address(0), "Must be valid adapter"); 
        return adapter;
    }

    /**
     * Gets the total fee for this module of the passed in index (fee % * quantity)
     */
    function getModuleFee(uint256 _feeIndex, uint256 _quantity) internal view returns(uint256) {
        uint256 feePercentage = controller.getModuleFee(address(this), _feeIndex);
        return _quantity.preciseMul(feePercentage);
    }

    /**
     * Pays the _feeQuantity from the _setToken denominated in _token to the protocol fee recipient
     */
    function payProtocolFeeFromSetToken(ISetToken _setToken, address _token, uint256 _feeQuantity) internal {
        if (_feeQuantity > 0) {
            _setToken.strictInvokeTransfer(_token, controller.feeRecipient(), _feeQuantity); 
        }
    }

    /**
     * Returns true if the module is in process of initialization on the SetToken
     */
    function isSetPendingInitialization(ISetToken _setToken) internal view returns(bool) {
        return _setToken.isPendingModule(address(this));
    }

    /**
     * Returns true if the address is the SetToken's manager
     */
    function isSetManager(ISetToken _setToken, address _toCheck) internal view returns(bool) {
        return _setToken.manager() == _toCheck;
    }

    /**
     * Returns true if SetToken must be enabled on the controller 
     * and module is registered on the SetToken
     */
    function isSetValidAndInitialized(ISetToken _setToken) internal view returns(bool) {
        return controller.isSet(address(_setToken)) &&
            _setToken.isInitializedModule(address(this));
    }

    /**
     * Hashes the string and returns a bytes32 value
     */
    function getNameHash(string memory _name) internal pure returns(bytes32) {
        return keccak256(bytes(_name));
    }

    /* ============== Modifier Helpers ===============
     * Internal functions used to reduce bytecode size
     */

    /**
     * Caller must SetToken manager and SetToken must be valid and initialized
     */
    function _validateOnlyManagerAndValidSet(ISetToken _setToken) internal view {
       require(isSetManager(_setToken, msg.sender), "Must be the SetToken manager");
       require(isSetValidAndInitialized(_setToken), "Must be a valid and initialized SetToken");
    }

    /**
     * Caller must SetToken manager
     */
    function _validateOnlySetManager(ISetToken _setToken, address _caller) internal view {
        require(isSetManager(_setToken, _caller), "Must be the SetToken manager");
    }

    /**
     * SetToken must be valid and initialized
     */
    function _validateOnlyValidAndInitializedSet(ISetToken _setToken) internal view {
        require(isSetValidAndInitialized(_setToken), "Must be a valid and initialized SetToken");
    }

    /**
     * Caller must be initialized module and module must be enabled on the controller
     */
    function _validateOnlyModule(ISetToken _setToken) internal view {
        require(
            _setToken.moduleStates(msg.sender) == ISetToken.ModuleState.INITIALIZED,
            "Only the module can call"
        );

        require(
            controller.isModule(msg.sender),
            "Module must be enabled on controller"
        );
    }

    /**
     * SetToken must be in a pending state and module must be in pending state
     */
    function _validateOnlyValidAndPendingSet(ISetToken _setToken) internal view {
        require(controller.isSet(address(_setToken)), "Must be controller-enabled SetToken");
        require(isSetPendingInitialization(_setToken), "Must be pending initialization");
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

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @title ExplicitERC20
 * @author Set Protocol
 *
 * Utility functions for ERC20 transfers that require the explicit amount to be transferred.
 */
library ExplicitERC20 {
    using SafeMath for uint256;

    /**
     * When given allowance, transfers a token from the "_from" to the "_to" of quantity "_quantity".
     * Ensures that the recipient has received the correct quantity (ie no fees taken on transfer)
     *
     * @param _token           ERC20 token to approve
     * @param _from            The account to transfer tokens from
     * @param _to              The account to transfer tokens to
     * @param _quantity        The quantity to transfer
     */
    function transferFrom(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _quantity
    )
        internal
    {
        // Call specified ERC20 contract to transfer tokens (via proxy).
        if (_quantity > 0) {
            uint256 existingBalance = _token.balanceOf(_to);

            SafeERC20.safeTransferFrom(
                _token,
                _from,
                _to,
                _quantity
            );

            uint256 newBalance = _token.balanceOf(_to);

            // Verify transfer quantity is reflected in balance
            require(
                newBalance == existingBalance.add(_quantity),
                "Invalid post transfer balance"
            );
        }
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


/**
 * @title IModule
 * @author Set Protocol
 *
 * Interface for interacting with Modules.
 */
interface IModule {
    /**
     * Called by a SetToken to notify that this module was removed from the Set token. Any logic can be included
     * in case checks need to be made or state needs to be cleared.
     */
    function removeModule() external;
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

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

import { ISetToken } from "../../interfaces/ISetToken.sol";


/**
 * @title Invoke
 * @author Set Protocol
 *
 * A collection of common utility functions for interacting with the SetToken's invoke function
 */
library Invoke {
    using SafeMath for uint256;

    /* ============ Internal ============ */

    /**
     * Instructs the SetToken to set approvals of the ERC20 token to a spender.
     *
     * @param _setToken        SetToken instance to invoke
     * @param _token           ERC20 token to approve
     * @param _spender         The account allowed to spend the SetToken's balance
     * @param _quantity        The quantity of allowance to allow
     */
    function invokeApprove(
        ISetToken _setToken,
        address _token,
        address _spender,
        uint256 _quantity
    )
        internal
    {
        bytes memory callData = abi.encodeWithSignature("approve(address,uint256)", _spender, _quantity);
        _setToken.invoke(_token, 0, callData);
    }

    /**
     * Instructs the SetToken to transfer the ERC20 token to a recipient.
     *
     * @param _setToken        SetToken instance to invoke
     * @param _token           ERC20 token to transfer
     * @param _to              The recipient account
     * @param _quantity        The quantity to transfer
     */
    function invokeTransfer(
        ISetToken _setToken,
        address _token,
        address _to,
        uint256 _quantity
    )
        internal
    {
        if (_quantity > 0) {
            bytes memory callData = abi.encodeWithSignature("transfer(address,uint256)", _to, _quantity);
            _setToken.invoke(_token, 0, callData);
        }
    }

    /**
     * Instructs the SetToken to transfer the ERC20 token to a recipient.
     * The new SetToken balance must equal the existing balance less the quantity transferred
     *
     * @param _setToken        SetToken instance to invoke
     * @param _token           ERC20 token to transfer
     * @param _to              The recipient account
     * @param _quantity        The quantity to transfer
     */
    function strictInvokeTransfer(
        ISetToken _setToken,
        address _token,
        address _to,
        uint256 _quantity
    )
        internal
    {
        if (_quantity > 0) {
            // Retrieve current balance of token for the SetToken
            uint256 existingBalance = IERC20(_token).balanceOf(address(_setToken));

            Invoke.invokeTransfer(_setToken, _token, _to, _quantity);

            // Get new balance of transferred token for SetToken
            uint256 newBalance = IERC20(_token).balanceOf(address(_setToken));

            // Verify only the transfer quantity is subtracted
            require(
                newBalance == existingBalance.sub(_quantity),
                "Invalid post transfer balance"
            );
        }
    }

    /**
     * Instructs the SetToken to unwrap the passed quantity of WETH
     *
     * @param _setToken        SetToken instance to invoke
     * @param _weth            WETH address
     * @param _quantity        The quantity to unwrap
     */
    function invokeUnwrapWETH(ISetToken _setToken, address _weth, uint256 _quantity) internal {
        bytes memory callData = abi.encodeWithSignature("withdraw(uint256)", _quantity);
        _setToken.invoke(_weth, 0, callData);
    }

    /**
     * Instructs the SetToken to wrap the passed quantity of ETH
     *
     * @param _setToken        SetToken instance to invoke
     * @param _weth            WETH address
     * @param _quantity        The quantity to unwrap
     */
    function invokeWrapWETH(ISetToken _setToken, address _weth, uint256 _quantity) internal {
        bytes memory callData = abi.encodeWithSignature("deposit()");
        _setToken.invoke(_weth, _quantity, callData);
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
import { SafeCast } from "@openzeppelin/contracts/utils/SafeCast.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { SignedSafeMath } from "@openzeppelin/contracts/math/SignedSafeMath.sol";

import { ISetToken } from "../../interfaces/ISetToken.sol";
import { PreciseUnitMath } from "../../lib/PreciseUnitMath.sol";


/**
 * @title Position
 * @author Set Protocol
 *
 * Collection of helper functions for handling and updating SetToken Positions
 *
 * CHANGELOG:
 *  - Updated editExternalPosition to work when no external position is associated with module
 */
library Position {
    using SafeCast for uint256;
    using SafeMath for uint256;
    using SafeCast for int256;
    using SignedSafeMath for int256;
    using PreciseUnitMath for uint256;

    /* ============ Helper ============ */

    /**
     * Returns whether the SetToken has a default position for a given component (if the real unit is > 0)
     */
    function hasDefaultPosition(ISetToken _setToken, address _component) internal view returns(bool) {
        return _setToken.getDefaultPositionRealUnit(_component) > 0;
    }

    /**
     * Returns whether the SetToken has an external position for a given component (if # of position modules is > 0)
     */
    function hasExternalPosition(ISetToken _setToken, address _component) internal view returns(bool) {
        return _setToken.getExternalPositionModules(_component).length > 0;
    }
    
    /**
     * Returns whether the SetToken component default position real unit is greater than or equal to units passed in.
     */
    function hasSufficientDefaultUnits(ISetToken _setToken, address _component, uint256 _unit) internal view returns(bool) {
        return _setToken.getDefaultPositionRealUnit(_component) >= _unit.toInt256();
    }

    /**
     * Returns whether the SetToken component external position is greater than or equal to the real units passed in.
     */
    function hasSufficientExternalUnits(
        ISetToken _setToken,
        address _component,
        address _positionModule,
        uint256 _unit
    )
        internal
        view
        returns(bool)
    {
       return _setToken.getExternalPositionRealUnit(_component, _positionModule) >= _unit.toInt256();    
    }

    /**
     * If the position does not exist, create a new Position and add to the SetToken. If it already exists,
     * then set the position units. If the new units is 0, remove the position. Handles adding/removing of 
     * components where needed (in light of potential external positions).
     *
     * @param _setToken           Address of SetToken being modified
     * @param _component          Address of the component
     * @param _newUnit            Quantity of Position units - must be >= 0
     */
    function editDefaultPosition(ISetToken _setToken, address _component, uint256 _newUnit) internal {
        bool isPositionFound = hasDefaultPosition(_setToken, _component);
        if (!isPositionFound && _newUnit > 0) {
            // If there is no Default Position and no External Modules, then component does not exist
            if (!hasExternalPosition(_setToken, _component)) {
                _setToken.addComponent(_component);
            }
        } else if (isPositionFound && _newUnit == 0) {
            // If there is a Default Position and no external positions, remove the component
            if (!hasExternalPosition(_setToken, _component)) {
                _setToken.removeComponent(_component);
            }
        }

        _setToken.editDefaultPositionUnit(_component, _newUnit.toInt256());
    }

    /**
     * Update an external position and remove and external positions or components if necessary. The logic flows as follows:
     * 1) If component is not already added then add component and external position. 
     * 2) If component is added but no existing external position using the passed module exists then add the external position.
     * 3) If the existing position is being added to then just update the unit and data
     * 4) If the position is being closed and no other external positions or default positions are associated with the component
     *    then untrack the component and remove external position.
     * 5) If the position is being closed and other existing positions still exist for the component then just remove the
     *    external position.
     *
     * @param _setToken         SetToken being updated
     * @param _component        Component position being updated
     * @param _module           Module external position is associated with
     * @param _newUnit          Position units of new external position
     * @param _data             Arbitrary data associated with the position
     */
    function editExternalPosition(
        ISetToken _setToken,
        address _component,
        address _module,
        int256 _newUnit,
        bytes memory _data
    )
        internal
    {
        if (_newUnit != 0) {
            if (!_setToken.isComponent(_component)) {
                _setToken.addComponent(_component);
                _setToken.addExternalPositionModule(_component, _module);
            } else if (!_setToken.isExternalPositionModule(_component, _module)) {
                _setToken.addExternalPositionModule(_component, _module);
            }
            _setToken.editExternalPositionUnit(_component, _module, _newUnit);
            _setToken.editExternalPositionData(_component, _module, _data);
        } else {
            require(_data.length == 0, "Passed data must be null");
            // If no default or external position remaining then remove component from components array
            if (_setToken.getExternalPositionRealUnit(_component, _module) != 0) {
                address[] memory positionModules = _setToken.getExternalPositionModules(_component);
                if (_setToken.getDefaultPositionRealUnit(_component) == 0 && positionModules.length == 1) {
                    require(positionModules[0] == _module, "External positions must be 0 to remove component");
                    _setToken.removeComponent(_component);
                }
                _setToken.removeExternalPositionModule(_component, _module);
            }
        }
    }

    /**
     * Get total notional amount of Default position
     *
     * @param _setTokenSupply     Supply of SetToken in precise units (10^18)
     * @param _positionUnit       Quantity of Position units
     *
     * @return                    Total notional amount of units
     */
    function getDefaultTotalNotional(uint256 _setTokenSupply, uint256 _positionUnit) internal pure returns (uint256) {
        return _setTokenSupply.preciseMul(_positionUnit);
    }

    /**
     * Get position unit from total notional amount
     *
     * @param _setTokenSupply     Supply of SetToken in precise units (10^18)
     * @param _totalNotional      Total notional amount of component prior to
     * @return                    Default position unit
     */
    function getDefaultPositionUnit(uint256 _setTokenSupply, uint256 _totalNotional) internal pure returns (uint256) {
        return _totalNotional.preciseDiv(_setTokenSupply);
    }

    /**
     * Get the total tracked balance - total supply * position unit
     *
     * @param _setToken           Address of the SetToken
     * @param _component          Address of the component
     * @return                    Notional tracked balance
     */
    function getDefaultTrackedBalance(ISetToken _setToken, address _component) internal view returns(uint256) {
        int256 positionUnit = _setToken.getDefaultPositionRealUnit(_component); 
        return _setToken.totalSupply().preciseMul(positionUnit.toUint256());
    }

    /**
     * Calculates the new default position unit and performs the edit with the new unit
     *
     * @param _setToken                 Address of the SetToken
     * @param _component                Address of the component
     * @param _setTotalSupply           Current SetToken supply
     * @param _componentPreviousBalance Pre-action component balance
     * @return                          Current component balance
     * @return                          Previous position unit
     * @return                          New position unit
     */
    function calculateAndEditDefaultPosition(
        ISetToken _setToken,
        address _component,
        uint256 _setTotalSupply,
        uint256 _componentPreviousBalance
    )
        internal
        returns(uint256, uint256, uint256)
    {
        uint256 currentBalance = IERC20(_component).balanceOf(address(_setToken));
        uint256 positionUnit = _setToken.getDefaultPositionRealUnit(_component).toUint256();

        uint256 newTokenUnit;
        if (currentBalance > 0) {
            newTokenUnit = calculateDefaultEditPositionUnit(
                _setTotalSupply,
                _componentPreviousBalance,
                currentBalance,
                positionUnit
            );
        } else {
            newTokenUnit = 0;
        }

        editDefaultPosition(_setToken, _component, newTokenUnit);

        return (currentBalance, positionUnit, newTokenUnit);
    }

    /**
     * Calculate the new position unit given total notional values pre and post executing an action that changes SetToken state
     * The intention is to make updates to the units without accidentally picking up airdropped assets as well.
     *
     * @param _setTokenSupply     Supply of SetToken in precise units (10^18)
     * @param _preTotalNotional   Total notional amount of component prior to executing action
     * @param _postTotalNotional  Total notional amount of component after the executing action
     * @param _prePositionUnit    Position unit of SetToken prior to executing action
     * @return                    New position unit
     */
    function calculateDefaultEditPositionUnit(
        uint256 _setTokenSupply,
        uint256 _preTotalNotional,
        uint256 _postTotalNotional,
        uint256 _prePositionUnit
    )
        internal
        pure
        returns (uint256)
    {
        // If pre action total notional amount is greater then subtract post action total notional and calculate new position units
        uint256 airdroppedAmount = _preTotalNotional.sub(_prePositionUnit.preciseMul(_setTokenSupply));
        return _postTotalNotional.sub(airdroppedAmount).preciseDiv(_setTokenSupply);
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
pragma experimental ABIEncoderV2;

import { SafeCast } from "@openzeppelin/contracts/utils/SafeCast.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { SignedSafeMath } from "@openzeppelin/contracts/math/SignedSafeMath.sol";


/**
 * @title PreciseUnitMath
 * @author Set Protocol
 *
 * Arithmetic for fixed-point numbers with 18 decimals of precision. Some functions taken from
 * dYdX's BaseMath library.
 *
 * CHANGELOG:
 * - 9/21/20: Added safePower function
 * - 4/21/21: Added approximatelyEquals function
 * - 12/13/21: Added preciseDivCeil (int overloads) function
 * - 12/13/21: Added abs function
 */
library PreciseUnitMath {
    using SafeMath for uint256;
    using SignedSafeMath for int256;
    using SafeCast for int256;

    // The number One in precise units.
    uint256 constant internal PRECISE_UNIT = 10 ** 18;
    int256 constant internal PRECISE_UNIT_INT = 10 ** 18;

    // Max unsigned integer value
    uint256 constant internal MAX_UINT_256 = type(uint256).max;
    // Max and min signed integer value
    int256 constant internal MAX_INT_256 = type(int256).max;
    int256 constant internal MIN_INT_256 = type(int256).min;

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function preciseUnit() internal pure returns (uint256) {
        return PRECISE_UNIT;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function preciseUnitInt() internal pure returns (int256) {
        return PRECISE_UNIT_INT;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function maxUint256() internal pure returns (uint256) {
        return MAX_UINT_256;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function maxInt256() internal pure returns (int256) {
        return MAX_INT_256;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function minInt256() internal pure returns (int256) {
        return MIN_INT_256;
    }

    /**
     * @dev Multiplies value a by value b (result is rounded down). It's assumed that the value b is the significand
     * of a number with 18 decimals precision.
     */
    function preciseMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a.mul(b).div(PRECISE_UNIT);
    }

    /**
     * @dev Multiplies value a by value b (result is rounded towards zero). It's assumed that the value b is the
     * significand of a number with 18 decimals precision.
     */
    function preciseMul(int256 a, int256 b) internal pure returns (int256) {
        return a.mul(b).div(PRECISE_UNIT_INT);
    }

    /**
     * @dev Multiplies value a by value b (result is rounded up). It's assumed that the value b is the significand
     * of a number with 18 decimals precision.
     */
    function preciseMulCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }
        return a.mul(b).sub(1).div(PRECISE_UNIT).add(1);
    }

    /**
     * @dev Divides value a by value b (result is rounded down).
     */
    function preciseDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return a.mul(PRECISE_UNIT).div(b);
    }


    /**
     * @dev Divides value a by value b (result is rounded towards 0).
     */
    function preciseDiv(int256 a, int256 b) internal pure returns (int256) {
        return a.mul(PRECISE_UNIT_INT).div(b);
    }

    /**
     * @dev Divides value a by value b (result is rounded up or away from 0).
     */
    function preciseDivCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "Cant divide by 0");

        return a > 0 ? a.mul(PRECISE_UNIT).sub(1).div(b).add(1) : 0;
    }

    /**
     * @dev Divides value a by value b (result is rounded up or away from 0). When `a` is 0, 0 is
     * returned. When `b` is 0, method reverts with divide-by-zero error.
     */
    function preciseDivCeil(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "Cant divide by 0");
        
        a = a.mul(PRECISE_UNIT_INT);
        int256 c = a.div(b);

        if (a % b != 0) {
            // a ^ b == 0 case is covered by the previous if statement, hence it won't resolve to --c
            (a ^ b > 0) ? ++c : --c;
        }

        return c;
    }

    /**
     * @dev Divides value a by value b (result is rounded down - positive numbers toward 0 and negative away from 0).
     */
    function divDown(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "Cant divide by 0");
        require(a != MIN_INT_256 || b != -1, "Invalid input");

        int256 result = a.div(b);
        if (a ^ b < 0 && a % b != 0) {
            result -= 1;
        }

        return result;
    }

    /**
     * @dev Multiplies value a by value b where rounding is towards the lesser number.
     * (positive values are rounded towards zero and negative values are rounded away from 0).
     */
    function conservativePreciseMul(int256 a, int256 b) internal pure returns (int256) {
        return divDown(a.mul(b), PRECISE_UNIT_INT);
    }

    /**
     * @dev Divides value a by value b where rounding is towards the lesser number.
     * (positive values are rounded towards zero and negative values are rounded away from 0).
     */
    function conservativePreciseDiv(int256 a, int256 b) internal pure returns (int256) {
        return divDown(a.mul(PRECISE_UNIT_INT), b);
    }

    /**
    * @dev Performs the power on a specified value, reverts on overflow.
    */
    function safePower(
        uint256 a,
        uint256 pow
    )
        internal
        pure
        returns (uint256)
    {
        require(a > 0, "Value must be positive");

        uint256 result = 1;
        for (uint256 i = 0; i < pow; i++){
            uint256 previousResult = result;

            // Using safemath multiplication prevents overflows
            result = previousResult.mul(a);
        }

        return result;
    }

    /**
     * @dev Returns true if a =~ b within range, false otherwise.
     */
    function approximatelyEquals(uint256 a, uint256 b, uint256 range) internal pure returns (bool) {
        return a <= b.add(range) && a >= b.sub(range);
    }

    /**
     * Returns the absolute value of int256 `a` as a uint256
     */
    function abs(int256 a) internal pure returns (uint) {
        return a >= 0 ? a.toUint256() : a.mul(-1).toUint256();
    }

    /**
     * Returns the negation of a
     */
    function neg(int256 a) internal pure returns (int256) {
        require(a > MIN_INT_256, "Inversion overflow");
        return -a;
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

import { IController } from "../../interfaces/IController.sol";
import { IIntegrationRegistry } from "../../interfaces/IIntegrationRegistry.sol";
import { IPriceOracle } from "../../interfaces/IPriceOracle.sol";
import { ISetValuer } from "../../interfaces/ISetValuer.sol";

/**
 * @title ResourceIdentifier
 * @author Set Protocol
 *
 * A collection of utility functions to fetch information related to Resource contracts in the system
 */
library ResourceIdentifier {

    // IntegrationRegistry will always be resource ID 0 in the system
    uint256 constant internal INTEGRATION_REGISTRY_RESOURCE_ID = 0;
    // PriceOracle will always be resource ID 1 in the system
    uint256 constant internal PRICE_ORACLE_RESOURCE_ID = 1;
    // SetValuer resource will always be resource ID 2 in the system
    uint256 constant internal SET_VALUER_RESOURCE_ID = 2;

    /* ============ Internal ============ */

    /**
     * Gets the instance of integration registry stored on Controller. Note: IntegrationRegistry is stored as index 0 on
     * the Controller
     */
    function getIntegrationRegistry(IController _controller) internal view returns (IIntegrationRegistry) {
        return IIntegrationRegistry(_controller.resourceId(INTEGRATION_REGISTRY_RESOURCE_ID));
    }

    /**
     * Gets instance of price oracle on Controller. Note: PriceOracle is stored as index 1 on the Controller
     */
    function getPriceOracle(IController _controller) internal view returns (IPriceOracle) {
        return IPriceOracle(_controller.resourceId(PRICE_ORACLE_RESOURCE_ID));
    }

    /**
     * Gets the instance of Set valuer on Controller. Note: SetValuer is stored as index 2 on the Controller
     */
    function getSetValuer(IController _controller) internal view returns (ISetValuer) {
        return ISetValuer(_controller.resourceId(SET_VALUER_RESOURCE_ID));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;


/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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

interface IIntegrationRegistry {
    function addIntegration(address _module, string memory _id, address _wrapper) external;
    function getIntegrationAdapter(address _module, string memory _id) external view returns(address);
    function getIntegrationAdapterWithHash(address _module, bytes32 _id) external view returns(address);
    function isValidIntegration(address _module, string memory _id) external view returns(bool);
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
 * @title IPriceOracle
 * @author Set Protocol
 *
 * Interface for interacting with PriceOracle
 */
interface IPriceOracle {

    /* ============ Functions ============ */

    function getPrice(address _assetOne, address _assetTwo) external view returns (uint256);
    function masterQuoteAsset() external view returns (address);
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

import { ISetToken } from "../interfaces/ISetToken.sol";

interface ISetValuer {
    function calculateSetTokenValuation(ISetToken _setToken, address _quoteAsset) external view returns (uint256);
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
pragma experimental ABIEncoderV2;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Math } from "@openzeppelin/contracts/math/Math.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/SafeCast.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { SignedSafeMath } from "@openzeppelin/contracts/math/SignedSafeMath.sol";

import { IAccountBalance } from "@setprotocol/set-protocol-v2/contracts/interfaces/external/perp-v2/IAccountBalance.sol";
import { IPerpV2LeverageModuleV2 } from "@setprotocol/set-protocol-v2/contracts/interfaces/IPerpV2LeverageModuleV2.sol";
import { ISetToken } from "@setprotocol/set-protocol-v2/contracts/interfaces/ISetToken.sol";
import { IVault } from "@setprotocol/set-protocol-v2/contracts/interfaces/external/perp-v2/IVault.sol";
import { PreciseUnitMath } from "@setprotocol/set-protocol-v2/contracts/lib/PreciseUnitMath.sol";
import { StringArrayUtils } from "@setprotocol/set-protocol-v2/contracts/lib/StringArrayUtils.sol";

import { BaseExtension } from "../lib/BaseExtension.sol";
import { IBaseManager } from "../interfaces/IBaseManager.sol";
import { IPriceFeed } from "../interfaces/IPriceFeed.sol";


/**
 * @title PerpV2LeverageStrategyExtension
 * @author Set Protocol
 *
 * Smart contract that enables trustless leverage tokens with USDC as collateral. This extension is paired with the PerpV2LeverageModule from
 * Set protocol where module interactions are invoked via the IBaseManager contract. Any leveraged token can be constructed as long as the
 * market  is listed on Perp V2. This extension contract also allows the operator to set an ETH reward to incentivize keepers calling the
 * rebalance function at different leverage thresholds.
 */
contract PerpV2LeverageStrategyExtension is BaseExtension {
    using Address for address;
    using PreciseUnitMath for uint256;
    using PreciseUnitMath for int256;
    using SafeMath for uint256;
    using SignedSafeMath for int256;
    using SafeCast for int256;
    using SafeCast for uint256;
    using StringArrayUtils for string[];

    /* ============ Enums ============ */

    enum ShouldRebalance {
        NONE,                   // Indicates no rebalance action can be taken
        REBALANCE,              // Indicates rebalance() function can be successfully called
        ITERATE_REBALANCE,      // Indicates iterateRebalance() function can be successfully called
        RIPCORD                 // Indicates ripcord() function can be successfully called
    }

    /* ============ Structs ============ */

    struct ActionInfo {
        int256 baseBalance;                                 // Balance of virtual base asset from Perp in precise units (10e18). E.g. vWBTC = 10e18
        int256 quoteBalance;                                // Balance of virtual quote asset from Perp in precise units (10e18). E.g. vUSD = 10e18
        IPerpV2LeverageModuleV2.AccountInfo accountInfo;      // Info on perpetual account including, collateral balance, owedRealizedPnl and pendingFunding
        int256 basePositionValue;                           // Valuation in USD adjusted for decimals in precise units (10e18)
        int256 quoteValue;                                  // Valuation in USD adjusted for decimals in precise units (10e18)
        int256 basePrice;                                   // Price of base asset in precise units (10e18) from PerpV2 Oracle
        int256 quotePrice;                                  // Price of quote asset in precise units (10e18) from PerpV2 Oracle
        uint256 setTotalSupply;                             // Total supply of SetToken
    }

    struct LeverageInfo {
        ActionInfo action;
        int256 currentLeverageRatio;                    // Current leverage ratio of Set. For short tokens, this will be negative
        uint256 slippageTolerance;                      // Allowable percent trade slippage in preciseUnits (1% = 10^16)
        uint256 twapMaxTradeSize;                       // Max trade size in base asset units allowed for rebalance action
    }

    struct ContractSettings {
        ISetToken setToken;                             // Instance of leverage token
        IPerpV2LeverageModuleV2 perpV2LeverageModule;     // Instance of Perp V2 leverage module
        IAccountBalance perpV2AccountBalance;           // Instance of Perp V2 AccountBalance contract used to fetch position balances
        IPriceFeed baseUSDPriceOracle;                  // PerpV2 oracle that returns TWAP price for base asset in USD. IPriceFeed is a PerpV2 specific interface
                                                        // to interact with differnt oracle providers, e.g. Band Protocol and Chainlink, for different assets
                                                        // listed on PerpV2
        uint256 twapInterval;                           // TWAP interval to be used to fetch base asset price in seconds
                                                        // PerpV2 uses a 15 min TWAP interval, i.e. twapInterval = 900
        uint256 basePriceDecimalAdjustment;             // Decimal adjustment for the price returned by the PerpV2 oracle for the base asset.
                                                        // Equal to vBaseAsset.decimals() - baseUSDPriceOracle.decimals()
        address virtualBaseAddress;                     // Address of virtual base asset (e.g. vETH, vWBTC etc)
        address virtualQuoteAddress;                    // Address of virtual USDC quote asset. The Perp V2 system uses USDC for all markets
    }

    struct MethodologySettings {
        int256 targetLeverageRatio;                     // Long term target ratio in precise units (10e18). For short tokens target ratio is negative.
                                                        // E.g. 2e18 for ETH 2x and -2e18 for ETH -2x.
        int256 minLeverageRatio;                        // For both long and short tokens, if magnitude of current leverage is lower, rebalance target is
                                                        // this ratio. In precise units (10e18). E.g. 1.7e17 for ETH 2x and -1.7e17 for ETH -1x.
        int256 maxLeverageRatio;                        // For both long and short tokens, if magniutde of current leverage is higher, rebalance target is
                                                        // this ratio. In precise units (10e18). E.g. 1.7e17 for ETH 2x and -1.7e17 for ETH -1x.
        uint256 recenteringSpeed;                       // % at which to rebalance back to target leverage in precise units (10e18). Always a positive number
        uint256 rebalanceInterval;                      // Period of time required since last rebalance timestamp in seconds
    }

    struct ExecutionSettings {
        uint256 slippageTolerance;                       // % in precise units to price min token receive amount from trade quantities
        uint256 twapCooldownPeriod;                      // Cooldown period required since last trade timestamp in seconds
    }

    struct ExchangeSettings {
        uint256 twapMaxTradeSize;                        // Max trade size in base assset base units. Always a positive number
        uint256 incentivizedTwapMaxTradeSize;            // Max trade size for incentivized rebalances in base asset units. Always a positive number
    }

    struct IncentiveSettings {
        uint256 etherReward;                             // ETH reward for incentivized rebalances
        int256 incentivizedLeverageRatio;                // Leverage ratio for incentivized rebalances. For long tokens, this is a positive number higher than
                                                         // maxLeverageRatio. For short tokens, this is a negative number lower than maxLeverageRatio
        uint256 incentivizedSlippageTolerance;           // Slippage tolerance percentage for incentivized rebalances
        uint256 incentivizedTwapCooldownPeriod;          // TWAP cooldown in seconds for incentivized rebalances
    }

    /* ============ Events ============ */

    event Engaged(int256 _currentLeverageRatio, int256 _newLeverageRatio, int256 _chunkRebalanceNotional, int256 _totalRebalanceNotional);
    event Rebalanced(
        int256 _currentLeverageRatio,
        int256 _newLeverageRatio,
        int256 _chunkRebalanceNotional,
        int256 _totalRebalanceNotional
    );
    event RebalanceIterated(
        int256 _currentLeverageRatio,
        int256 _newTwapLeverageRatio,
        int256 _chunkRebalanceNotional,
        int256 _totalRebalanceNotional
    );
    event RipcordCalled(
        int256 _currentLeverageRatio,
        int256 _newLeverageRatio,
        int256 _rebalanceNotional,
        uint256 _etherIncentive
    );
    event Disengaged(int256 _currentLeverageRatio, int256 _newLeverageRatio, int256 _chunkRebalanceNotional, int256 _totalRebalanceNotional);
    event MethodologySettingsUpdated(
        int256 _targetLeverageRatio,
        int256 _minLeverageRatio,
        int256 _maxLeverageRatio,
        uint256 _recenteringSpeed,
        uint256 _rebalanceInterval
    );
    event ExecutionSettingsUpdated(
        uint256 _twapCooldownPeriod,
        uint256 _slippageTolerance
    );
    event ExchangeSettingsUpdated(
        uint256 _twapMaxTradeSize,
        uint256 _incentivizedTwapMaxTradeSize
    );
    event IncentiveSettingsUpdated(
        uint256 _etherReward,
        int256 _incentivizedLeverageRatio,
        uint256 _incentivizedSlippageTolerance,
        uint256 _incentivizedTwapCooldownPeriod
    );

    /* ============ Modifiers ============ */

    /**
     * Throws if rebalance is currently in TWAP
     */
    modifier noRebalanceInProgress() {
        require(twapLeverageRatio == 0, "Rebalance is currently in progress");
        _;
    }

    /* ============ State Variables ============ */

    ContractSettings internal strategy;                     // Struct of contracts used in the strategy (SetToken, price oracles, leverage module etc)
    MethodologySettings internal methodology;               // Struct containing methodology parameters
    ExecutionSettings internal execution;                   // Struct containing execution parameters
    ExchangeSettings internal exchange;                     // Struct containing exchange settings
    IncentiveSettings internal incentive;                   // Struct containing incentive parameters for ripcord
    int256 public twapLeverageRatio;                        // Stored leverage ratio to keep track of target between TWAP rebalances
    uint256 public lastTradeTimestamp;                      // Last rebalance timestamp. Current timestamp must be greater than this variable + rebalance interval to rebalance

    /* ============ Constructor ============ */

    /**
     * Instantiate addresses, methodology parameters, execution parameters, exchange parameters and incentive parameters.
     *
     * @param _manager                  Address of IBaseManager contract
     * @param _strategy                 Struct of contract addresses
     * @param _methodology              Struct containing methodology parameters
     * @param _execution                Struct containing execution parameters
     * @param _incentive                Struct containing incentive parameters for ripcord
     * @param _exchange                 Struct containing exchange parameters
     */
    constructor(
        IBaseManager _manager,
        ContractSettings memory _strategy,
        MethodologySettings memory _methodology,
        ExecutionSettings memory _execution,
        IncentiveSettings memory _incentive,
        ExchangeSettings memory _exchange
    )
        public
        BaseExtension(_manager)
    {
        strategy = _strategy;
        methodology = _methodology;
        execution = _execution;
        incentive = _incentive;
        exchange = _exchange;

        _validateExchangeSettings(_exchange);
        _validateNonExchangeSettings(methodology, execution, incentive);
    }

    /* ============ External Functions ============ */

    /**
     * OPERATOR ONLY: Engage to target leverage ratio for the first time. SetToken will open a new base token position on PerpV2. Under the hood, perp would
     * mint virtual quote assets (vUSDC) for SetToken and swap them for base token. If target leverage ratio is above max trade size, then TWAP is kicked off.
     * To complete engage if TWAP, any valid caller must call iterateRebalance until target is met.
     * Note: Engage should be called after collateral has been deposited to PerpV2 using `deposit()`.
     */
    function engage() external onlyOperator {
        LeverageInfo memory leverageInfo = _getAndValidateEngageInfo();

        // Calculate total rebalance units and kick off TWAP if above max trade size
        (
            int256 chunkRebalanceNotional,
            int256 totalRebalanceNotional
        ) = _calculateEngageRebalanceSize(leverageInfo, methodology.targetLeverageRatio);

        _trade(leverageInfo, chunkRebalanceNotional);

        _updateRebalanceState(
            chunkRebalanceNotional,
            totalRebalanceNotional,
            methodology.targetLeverageRatio
        );

        emit Engaged(
            leverageInfo.currentLeverageRatio,
            methodology.targetLeverageRatio,
            chunkRebalanceNotional,
            totalRebalanceNotional
        );
    }

    /**
     * ONLY EOA AND ALLOWED CALLER: Rebalance product. If |min leverage ratio| < |current leverage ratio| < |max leverage ratio|, then rebalance
     * can only be called once the rebalance interval has elapsed since last timestamp. If outside the max and min but below incentivized leverage ratio,
     * rebalance can be called anytime to bring leverage ratio back to the max or min bounds. The methodology will determine whether to delever or lever.
     *
     * Note: If the calculated current leverage ratio is above the incentivized leverage ratio or in TWAP then rebalance cannot be called. Instead, you must call
     * ripcord() which is incentivized with a reward in Ether or iterateRebalance().
     */
    function rebalance() external onlyEOA onlyAllowedCaller(msg.sender) {
        LeverageInfo memory leverageInfo = _getAndValidateLeveragedInfo(
            execution.slippageTolerance,
            exchange.twapMaxTradeSize
        );

        _validateNormalRebalance(leverageInfo, methodology.rebalanceInterval, lastTradeTimestamp);
        _validateNonTWAP();

        int256 newLeverageRatio = _calculateNewLeverageRatio(leverageInfo.currentLeverageRatio);

        (
            int256 chunkRebalanceNotional,
            int256 totalRebalanceNotional
        ) = _handleRebalance(leverageInfo, newLeverageRatio);

        _updateRebalanceState(chunkRebalanceNotional, totalRebalanceNotional, newLeverageRatio);

        emit Rebalanced(
            leverageInfo.currentLeverageRatio,
            newLeverageRatio,
            chunkRebalanceNotional,
            totalRebalanceNotional
        );
    }

    /**
     * ONLY EOA AND ALLOWED CALLER: Iterate a rebalance when in TWAP. TWAP cooldown period must have elapsed. If price moves advantageously, then
     * exit without rebalancing and clear TWAP state. This function can only be called when |current leverage ratio| < |incentivized leverage ratio|
     * and in TWAP state.
     */
    function iterateRebalance() external onlyEOA onlyAllowedCaller(msg.sender) {
        LeverageInfo memory leverageInfo = _getAndValidateLeveragedInfo(
            execution.slippageTolerance,
            exchange.twapMaxTradeSize
        );

        _validateNormalRebalance(leverageInfo, execution.twapCooldownPeriod, lastTradeTimestamp);
        _validateTWAP();

        int256 chunkRebalanceNotional;
        int256 totalRebalanceNotional;
        if (!_isAdvantageousTWAP(leverageInfo.currentLeverageRatio)) {
            (chunkRebalanceNotional, totalRebalanceNotional) = _handleRebalance(leverageInfo, twapLeverageRatio);
        }

        // If not advantageous, then rebalance is skipped and chunk and total rebalance notional are both 0, which means TWAP state is cleared
        _updateIterateState(chunkRebalanceNotional, totalRebalanceNotional);

        emit RebalanceIterated(
            leverageInfo.currentLeverageRatio,
            twapLeverageRatio,
            chunkRebalanceNotional,
            totalRebalanceNotional
        );
    }

    /**
     * ONLY EOA: In case |current leverage ratio| > |incentivized leverage ratio|, the ripcord function can be called by anyone to return leverage ratio
     * back to the max leverage ratio. This function typically would only be called during times of high downside/upside volatility and / or normal keeper malfunctions. The
     * caller of ripcord() will receive a reward in Ether. The ripcord function uses it's own TWAP cooldown period, slippage tolerance and TWAP max trade size which are
     * typically looser than in regular rebalances. If chunk rebalance size is above max incentivized trade size, then caller must continue to call this function to pull
     * the leverage ratio under the incentivized leverage ratio. Incentivized TWAP cooldown period must have elapsed. The function iterateRebalance will not work.
     */
    function ripcord() external onlyEOA {
        LeverageInfo memory leverageInfo = _getAndValidateLeveragedInfo(
            incentive.incentivizedSlippageTolerance,
            exchange.incentivizedTwapMaxTradeSize
        );

        _validateRipcord(leverageInfo, lastTradeTimestamp);

        ( int256 chunkRebalanceNotional, ) = _calculateChunkRebalanceNotional(leverageInfo, methodology.maxLeverageRatio);

        _trade(leverageInfo, chunkRebalanceNotional);

        _updateRipcordState();

        uint256 etherTransferred = _transferEtherRewardToCaller(incentive.etherReward);

        emit RipcordCalled(
            leverageInfo.currentLeverageRatio,
            methodology.maxLeverageRatio,
            chunkRebalanceNotional,
            etherTransferred
        );
    }

    /**
     * OPERATOR ONLY: Close open baseToken position on Perpetual Protocol. TWAP cooldown period must have elapsed. This can be used for upgrading or shutting down the strategy. SetToken will sell all
     * virtual base token positions into virtual USDC. If the chunk rebalance size is less than the total notional size, then this function will trade out of base
     * token position in one go. If chunk rebalance size is above max trade size, then operator must continue to call this function to completely unwind position.
     * The function iterateRebalance will not work.
     *
     * Note: If rebalancing is open to anyone disengage TWAP can be counter traded by a griefing party calling rebalance. Set anyoneCallable to false before disengage to prevent such attacks.
     */
    function disengage() external onlyOperator {
        LeverageInfo memory leverageInfo = _getAndValidateLeveragedInfo(
            execution.slippageTolerance,
            exchange.twapMaxTradeSize
        );

        _validateDisengage(lastTradeTimestamp);

        // Reduce leverage to 0
        int256 newLeverageRatio = 0;

        (
            int256 chunkRebalanceNotional,
            int256 totalRebalanceNotional
        ) = _calculateChunkRebalanceNotional(leverageInfo, newLeverageRatio);

        _trade(leverageInfo, chunkRebalanceNotional);

        _updateDisengageState();

        emit Disengaged(
            leverageInfo.currentLeverageRatio,
            newLeverageRatio,
            chunkRebalanceNotional,
            totalRebalanceNotional
        );
    }

    /**
     * OEPRATOR ONLY: Deposits specified units of current USDC tokens not already being used as collateral into Perpetual Protocol.
     *
     * @param  _collateralUnits     Collateral to deposit in position units
     */
    function deposit(uint256 _collateralUnits) external onlyOperator {
        bytes memory depositCalldata = abi.encodeWithSelector(
            IPerpV2LeverageModuleV2.deposit.selector,
            address(strategy.setToken),
            _collateralUnits
        );

        invokeManager(address(strategy.perpV2LeverageModule), depositCalldata);
    }

    /**
     * OPERATOR ONLY: Withdraws specified units of USDC tokens from Perpetual Protocol and adds it as default position on the SetToken.
     *
     * @param  _collateralUnits     Collateral to withdraw in position units
     */
    function withdraw(uint256 _collateralUnits) external onlyOperator {
        bytes memory withdrawCalldata = abi.encodeWithSelector(
            IPerpV2LeverageModuleV2.withdraw.selector,
            address(strategy.setToken),
            _collateralUnits
        );

        invokeManager(address(strategy.perpV2LeverageModule), withdrawCalldata);
    }

    /**
     * OPERATOR ONLY: Set methodology settings and check new settings are valid. Note: Need to pass in existing parameters if only changing a few settings. Must not be
     * in a rebalance.
     *
     * @param _newMethodologySettings          Struct containing methodology parameters
     */
    function setMethodologySettings(MethodologySettings memory _newMethodologySettings) external onlyOperator noRebalanceInProgress {
        methodology = _newMethodologySettings;

        _validateNonExchangeSettings(methodology, execution, incentive);

        emit MethodologySettingsUpdated(
            methodology.targetLeverageRatio,
            methodology.minLeverageRatio,
            methodology.maxLeverageRatio,
            methodology.recenteringSpeed,
            methodology.rebalanceInterval
        );
    }

    /**
     * OPERATOR ONLY: Set execution settings and check new settings are valid. Note: Need to pass in existing parameters if only changing a few settings. Must not be
     * in a rebalance.
     *
     * @param _newExecutionSettings          Struct containing execution parameters
     */
    function setExecutionSettings(ExecutionSettings memory _newExecutionSettings) external onlyOperator noRebalanceInProgress {
        execution = _newExecutionSettings;

        _validateNonExchangeSettings(methodology, execution, incentive);

        emit ExecutionSettingsUpdated(
            execution.twapCooldownPeriod,
            execution.slippageTolerance
        );
    }

    /**
     * OPERATOR ONLY: Set incentive settings and check new settings are valid. Note: Need to pass in existing parameters if only changing a few settings. Must not be
     * in a rebalance.
     *
     * @param _newIncentiveSettings          Struct containing incentive parameters
     */
    function setIncentiveSettings(IncentiveSettings memory _newIncentiveSettings) external onlyOperator noRebalanceInProgress {
        incentive = _newIncentiveSettings;

        _validateNonExchangeSettings(methodology, execution, incentive);

        emit IncentiveSettingsUpdated(
            incentive.etherReward,
            incentive.incentivizedLeverageRatio,
            incentive.incentivizedSlippageTolerance,
            incentive.incentivizedTwapCooldownPeriod
        );
    }

    /**
     * OPERATOR ONLY: Set exchange settings and check new settings are valid.Updating exchange settings during rebalances is allowed, as it is not possible
     * to enter an unexpected state while doing so. Note: Need to pass in existing parameters if only changing a few settings.
     *
     * @param _newExchangeSettings     Struct containing exchange parameters
     */
    function setExchangeSettings(ExchangeSettings memory _newExchangeSettings)
        external
        onlyOperator
    {
        exchange = _newExchangeSettings;
        _validateExchangeSettings(_newExchangeSettings);

        exchange.twapMaxTradeSize = _newExchangeSettings.twapMaxTradeSize;
        exchange.incentivizedTwapMaxTradeSize = _newExchangeSettings.incentivizedTwapMaxTradeSize;

        emit ExchangeSettingsUpdated(
            _newExchangeSettings.twapMaxTradeSize,
            _newExchangeSettings.incentivizedTwapMaxTradeSize
        );
    }

    /**
     * OPERATOR ONLY: Withdraw entire balance of ETH in this contract to operator. Rebalance must not be in progress
     */
    function withdrawEtherBalance() external onlyOperator noRebalanceInProgress {
        msg.sender.transfer(address(this).balance);
    }

    receive() external payable {}

    /* ============ External Getter Functions ============ */

    /**
     * Get current leverage ratio. Current leverage ratio is defined as the sum of USD values of all SetToken open positions on Perp V2 divided by its account value on
     * PerpV2. Prices for base and quote asset are retrieved from the Chainlink Price Oracle.
     *
     * return currentLeverageRatio         Current leverage ratio in precise units (10e18)
     */
    function getCurrentLeverageRatio() public view returns(int256) {
        ActionInfo memory currentLeverageInfo = _createActionInfo();

        return _calculateCurrentLeverageRatio(currentLeverageInfo);
    }

    /**
     * Calculates the chunk rebalance size. This can be used by external contracts and keeper bots to track rebalances and fetch assets to be bought and sold.
     * Note: This function does not take into account timestamps, so it may return a nonzero value even when shouldRebalance would return ShouldRebalance.NONE
     * (since minimum delays have not elapsed).
     *
     * @return size             Total notional chunk size. Measured in the asset that would be sold.
     * @return sellAsset        Asset that would be sold during a rebalance
     * @return buyAsset         Asset that would be purchased during a rebalance
     */
    function getChunkRebalanceNotional()
        external
        view
        returns(int256 size, address sellAsset, address buyAsset)
    {

        int256 newLeverageRatio;
        int256 currentLeverageRatio = getCurrentLeverageRatio();
        bool isRipcord = false;

        // if over incentivized leverage ratio, always ripcord
        if (currentLeverageRatio.abs() > incentive.incentivizedLeverageRatio.abs()) {
            newLeverageRatio = methodology.maxLeverageRatio;
            isRipcord = true;
        // if we are in an ongoing twap, use the cached twapLeverageRatio as our target leverage
        } else if (twapLeverageRatio != 0) {
            newLeverageRatio = twapLeverageRatio;
        // if all else is false, then we would just use the normal rebalance new leverage ratio calculation
        } else {
            newLeverageRatio = _calculateNewLeverageRatio(currentLeverageRatio);
        }

        ActionInfo memory actionInfo = _createActionInfo();

        LeverageInfo memory leverageInfo = LeverageInfo({
            action: actionInfo,
            currentLeverageRatio: currentLeverageRatio,
            slippageTolerance: isRipcord ? incentive.incentivizedSlippageTolerance : execution.slippageTolerance,
            twapMaxTradeSize: isRipcord ?
                exchange.incentivizedTwapMaxTradeSize :
                exchange.twapMaxTradeSize
        });

        (size, ) = _calculateChunkRebalanceNotional(leverageInfo, newLeverageRatio);

        bool increaseLeverage = newLeverageRatio.abs() > currentLeverageRatio.abs();

        /*
        ------------------------------------------------------------------------------
        |   New LR             |  increaseLeverage |    sellAsset   |    buyAsset    |
        ------------------------------------------------------------------------------
        |   = 0 (not possible) |        x          |        x       |      x         |
        |   > 0  (long)        |       true        |      quote     |    base        |
        |   > 0  (long)        |       false       |      base      |    quote       |
        |   < 0  (short)       |       true        |      base      |    quote       |
        |   < 0  (short)       |       false       |      quote     |    base        |
        ------------------------------------------------------------------------------
        */

        if (newLeverageRatio > 0) {
            sellAsset = increaseLeverage ? strategy.virtualQuoteAddress : strategy.virtualBaseAddress;
            buyAsset = increaseLeverage ? strategy.virtualBaseAddress : strategy.virtualQuoteAddress;
        } else {
            sellAsset = increaseLeverage ? strategy.virtualBaseAddress : strategy.virtualQuoteAddress;
            buyAsset = increaseLeverage ? strategy.virtualQuoteAddress : strategy.virtualBaseAddress;
        }
    }

    /**
     * Get current Ether incentive for when current leverage ratio exceeds incentivized leverage ratio and ripcord can be called. If ETH balance on the contract is
     * below the etherReward, then return the balance of ETH instead.
     *
     * return etherReward               Quantity of ETH reward in base units (10e18)
     */
    function getCurrentEtherIncentive() external view returns(uint256) {
        int256 currentLeverageRatio = getCurrentLeverageRatio();

        if (currentLeverageRatio.abs() >= incentive.incentivizedLeverageRatio.abs()) {
            // If ETH reward is below the balance on this contract, then return ETH balance on contract instead
            return incentive.etherReward < address(this).balance ? incentive.etherReward : address(this).balance;
        } else {
            return 0;
        }
    }

    /**
     * Helper that checks if conditions are met for rebalance or ripcord. Returns an enum with 0 = no rebalance, 1 = call rebalance(), 2 = call iterateRebalance()
     * 3 = call ripcord()
     *
     * @return ShouldRebalance      Enum representing whether should rebalance
     */
    function shouldRebalance() external view returns(ShouldRebalance) {
        int256 currentLeverageRatio = getCurrentLeverageRatio();

        return _shouldRebalance(currentLeverageRatio, methodology.minLeverageRatio, methodology.maxLeverageRatio);
    }

    /**
     * Helper that checks if conditions are met for rebalance or ripcord with custom max and min bounds specified by caller. This function simplifies the
     * logic for off-chain keeper bots to determine what threshold to call rebalance when leverage exceeds max or drops below min. Returns an enum with
     * 0 = no rebalance, 1 = call rebalance(), 2 = call iterateRebalance(), 3 = call ripcord()
     *
     * @param _customMinLeverageRatio          Min leverage ratio passed in by caller
     * @param _customMaxLeverageRatio          Max leverage ratio passed in by caller
     *
     * @return ShouldRebalance      Enum representing whether should rebalance
     */
    function shouldRebalanceWithBounds(
        int256 _customMinLeverageRatio,
        int256 _customMaxLeverageRatio
    )
        external
        view
        returns(ShouldRebalance)
    {
        require (
            _customMinLeverageRatio.abs() <= methodology.minLeverageRatio.abs()
            && _customMaxLeverageRatio.abs() >= methodology.maxLeverageRatio.abs(),
            "Custom bounds must be valid"
        );

        int256 currentLeverageRatio = getCurrentLeverageRatio();

        return _shouldRebalance(currentLeverageRatio, _customMinLeverageRatio, _customMaxLeverageRatio);
    }

    /**
     * Explicit getter functions for parameter structs are defined as workaround to issues fetching structs that have dynamic types.
     */
    function getStrategy() external view returns (ContractSettings memory) { return strategy; }
    function getMethodology() external view returns (MethodologySettings memory) { return methodology; }
    function getExecution() external view returns (ExecutionSettings memory) { return execution; }
    function getIncentive() external view returns (IncentiveSettings memory) { return incentive; }
    function getExchangeSettings() external view returns (ExchangeSettings memory) { return exchange; }

    /* ============ Internal Functions ============ */

    /**
     * Calculate base rebalance units, opposite bound units and invoke trade on PerpV2LeverageModule.
     */
    function _trade(
        LeverageInfo memory _leverageInfo,
        int256 _chunkRebalanceNotional
    )
        internal
    {
        int256 baseRebalanceUnits = _chunkRebalanceNotional.preciseDiv(_leverageInfo.action.setTotalSupply.toInt256());

        uint256 oppositeBoundUnits = _calculateOppositeBoundUnits(baseRebalanceUnits, _leverageInfo.action, _leverageInfo.slippageTolerance);

        bytes memory tradeCallData = abi.encodeWithSelector(
            IPerpV2LeverageModuleV2.trade.selector,
            address(strategy.setToken),
            strategy.virtualBaseAddress,
            baseRebalanceUnits,
            oppositeBoundUnits
        );

        invokeManager(address(strategy.perpV2LeverageModule), tradeCallData);
    }

    /**
     * Calculates chunk rebalance notional and calls trade to open a position. Used in the rebalance() and iterateRebalance() functions
     *
     * return uint256           Calculated notional to trade
     * return uint256           Total notional to rebalance over TWAP
     */
    function _handleRebalance(LeverageInfo memory _leverageInfo, int256 _newLeverageRatio) internal returns(int256, int256) {
        (
            int256 chunkRebalanceNotional,
            int256 totalRebalanceNotional
        ) = _calculateChunkRebalanceNotional(_leverageInfo, _newLeverageRatio);

        _trade(_leverageInfo, chunkRebalanceNotional);

        return (chunkRebalanceNotional, totalRebalanceNotional);
    }

    /**
     * Validate the Set is not already engaged. Create the leverage info struct to be used in engage.
     */
    function _getAndValidateEngageInfo() internal view returns(LeverageInfo memory) {
        ActionInfo memory engageInfo = _createActionInfo();

        require(engageInfo.accountInfo.collateralBalance > 0, "Collateral balance must be > 0");

        // Assert base position unit is zero. Asserting base position unit instead of base balance allows us to neglect small dust amounts.
        require(engageInfo.baseBalance.preciseDiv(strategy.setToken.totalSupply().toInt256()) == 0, "Base position must NOT exist");

        return LeverageInfo({
            action: engageInfo,
            currentLeverageRatio: 0, // 0 position leverage
            slippageTolerance: execution.slippageTolerance,
            twapMaxTradeSize: exchange.twapMaxTradeSize
        });
    }

    /**
     * Create the leverage info struct to be used in internal functions.
     *
     * return LeverageInfo                Struct containing ActionInfo and other data
     */
    function _getAndValidateLeveragedInfo(uint256 _slippageTolerance, uint256 _maxTradeSize) internal view returns(LeverageInfo memory) {
        ActionInfo memory actionInfo = _createActionInfo();

        require(actionInfo.setTotalSupply > 0, "SetToken must have > 0 supply");

        // Get current leverage ratio
        int256 currentLeverageRatio = _calculateCurrentLeverageRatio(actionInfo);

        // This function is called during rebalance, iterateRebalance, ripcord and disengage.
        // Assert currentLeverageRatio is 0 as the set should be engaged before this function is called.
        require(currentLeverageRatio.abs() > 0, "Current leverage ratio must NOT be 0");

        return LeverageInfo({
            action: actionInfo,
            currentLeverageRatio: currentLeverageRatio,
            slippageTolerance: _slippageTolerance,
            twapMaxTradeSize: _maxTradeSize
        });
    }

    /**
     * Create the action info struct to be used in internal functions
     *
     * return ActionInfo                Struct containing data used by internal lever and delever functions
     */
    function _createActionInfo() internal view returns(ActionInfo memory) {
        ActionInfo memory rebalanceInfo;

        // Fetch base token prices from PerpV2 oracles and adjust them to 18 decimal places.
        int256 rawBasePrice = strategy.baseUSDPriceOracle.getPrice(strategy.twapInterval).toInt256();
        rebalanceInfo.basePrice = rawBasePrice.mul((10 ** strategy.basePriceDecimalAdjustment).toInt256());

        // vUSD price is fixed to 1$
        rebalanceInfo.quotePrice = PreciseUnitMath.preciseUnit().toInt256();

        // Note: getTakerPositionSize returns zero if base balance is less than 10 wei
        rebalanceInfo.baseBalance = strategy.perpV2AccountBalance.getTakerPositionSize(address(strategy.setToken), strategy.virtualBaseAddress);

        // Note: Fetching quote balance associated with a single position and not the net quote balance
        rebalanceInfo.quoteBalance = strategy.perpV2AccountBalance.getTakerOpenNotional(address(strategy.setToken), strategy.virtualBaseAddress);

        rebalanceInfo.accountInfo = strategy.perpV2LeverageModule.getAccountInfo(strategy.setToken);

        // In Perp v2, all virtual tokens have 18 decimals, therefore we do not need to make further adjustments to determine base valuation.
        rebalanceInfo.basePositionValue = rebalanceInfo.basePrice.preciseMul(rebalanceInfo.baseBalance);
        rebalanceInfo.quoteValue = rebalanceInfo.quoteBalance;

        rebalanceInfo.setTotalSupply = strategy.setToken.totalSupply();

        return rebalanceInfo;
    }

    /**
     * Validate non-exchange settings in constructor and setters when updating.
     */
    function _validateNonExchangeSettings(
        MethodologySettings memory _methodology,
        ExecutionSettings memory _execution,
        IncentiveSettings memory _incentive
    )
        internal
        pure
    {
        uint256 minLeverageRatioAbs = _methodology.minLeverageRatio.abs();
        uint256 targetLeverageRatioAbs = _methodology.targetLeverageRatio.abs();
        uint256 maxLeverageRatioAbs = _methodology.maxLeverageRatio.abs();
        uint256 incentivizedLeverageRatioAbs = _incentive.incentivizedLeverageRatio.abs();

        require (
            minLeverageRatioAbs <= targetLeverageRatioAbs && minLeverageRatioAbs > 0,
            "Must be valid min leverage"
        );
        require (
            maxLeverageRatioAbs >= targetLeverageRatioAbs,
            "Must be valid max leverage"
        );
        require (
            _methodology.recenteringSpeed <= PreciseUnitMath.preciseUnit() && _methodology.recenteringSpeed > 0,
            "Must be valid recentering speed"
        );
        require (
            _execution.slippageTolerance <= PreciseUnitMath.preciseUnit(),
            "Slippage tolerance must be <100%"
        );
        require (
            _incentive.incentivizedSlippageTolerance <= PreciseUnitMath.preciseUnit(),
            "Incentivized slippage tolerance must be <100%"
        );
        require (
            incentivizedLeverageRatioAbs >= maxLeverageRatioAbs,
            "Incentivized leverage ratio must be > max leverage ratio"
        );
        require (
            _methodology.rebalanceInterval >= _execution.twapCooldownPeriod,
            "Rebalance interval must be greater than TWAP cooldown period"
        );
        require (
            _execution.twapCooldownPeriod >= _incentive.incentivizedTwapCooldownPeriod,
            "TWAP cooldown must be greater than incentivized TWAP cooldown"
        );
    }

    /**
     * Validate an ExchangeSettings struct settings.
     */
    function _validateExchangeSettings(ExchangeSettings memory _settings) internal pure {
        require(_settings.twapMaxTradeSize != 0, "Max TWAP trade size must not be 0");
        require(
            _settings.twapMaxTradeSize <= _settings.incentivizedTwapMaxTradeSize,
            "Max TWAP trade size must not be greater than incentivized max TWAP trade size"
        );
    }

    /**
     * Validate that current leverage is below incentivized leverage ratio and cooldown / rebalance period has elapsed or outsize max/min bounds. Used
     * in rebalance() and iterateRebalance() functions
     */
    function _validateNormalRebalance(LeverageInfo memory _leverageInfo, uint256 _coolDown, uint256 _lastTradeTimestamp) internal view {
        uint256 currentLeverageRatioAbs = _leverageInfo.currentLeverageRatio.abs();
        require(currentLeverageRatioAbs < incentive.incentivizedLeverageRatio.abs(), "Must be below incentivized leverage ratio");
        require(
            block.timestamp.sub(_lastTradeTimestamp) > _coolDown
            || currentLeverageRatioAbs > methodology.maxLeverageRatio.abs()
            || currentLeverageRatioAbs < methodology.minLeverageRatio.abs(),
            "Cooldown not elapsed or not valid leverage ratio"
        );
    }

    /**
     * Validate that current leverage is above incentivized leverage ratio and incentivized cooldown period has elapsed in ripcord()
     */
    function _validateRipcord(LeverageInfo memory _leverageInfo, uint256 _lastTradeTimestamp) internal view {
        require(_leverageInfo.currentLeverageRatio.abs() >= incentive.incentivizedLeverageRatio.abs(), "Must be above incentivized leverage ratio");
        // If currently in the midst of a TWAP rebalance, ensure that the cooldown period has elapsed
        require(_lastTradeTimestamp.add(incentive.incentivizedTwapCooldownPeriod) < block.timestamp, "TWAP cooldown must have elapsed");
    }

    /**
     * Validate cooldown period has elapsed in disengage()
     */
    function _validateDisengage(uint256 _lastTradeTimestamp) internal view {
        require(_lastTradeTimestamp.add(execution.twapCooldownPeriod) < block.timestamp, "TWAP cooldown must have elapsed");
    }

    /**
     * Validate TWAP in the iterateRebalance() function
     */
    function _validateTWAP() internal view {
        require(twapLeverageRatio != 0, "Not in TWAP state");
    }

    /**
     * Validate not TWAP in the rebalance() function
     */
    function _validateNonTWAP() internal view {
        require(twapLeverageRatio == 0, "Must call iterate");
    }

    /**
     * Check if price has moved advantageously while in the midst of the TWAP rebalance. This means the current leverage ratio has moved over/under
     * the stored TWAP leverage ratio on lever/delever so there is no need to execute a rebalance. Used in iterateRebalance()
     *
     * return bool          True if price has moved advantageously, false otherwise
     */
    function _isAdvantageousTWAP(int256 _currentLeverageRatio) internal view returns (bool) {
        uint256 twapLeverageRatioAbs = twapLeverageRatio.abs();
        uint256 targetLeverageRatioAbs = methodology.targetLeverageRatio.abs();
        uint256 currentLeverageRatioAbs = _currentLeverageRatio.abs();

        return (
            (twapLeverageRatioAbs < targetLeverageRatioAbs && currentLeverageRatioAbs >= twapLeverageRatioAbs)
            || (twapLeverageRatioAbs > targetLeverageRatioAbs && currentLeverageRatioAbs <= twapLeverageRatioAbs)
        );
    }

    /**
     * Calculate the current leverage ratio.
     *
     * return int256            Current leverage ratio
     */
    function _calculateCurrentLeverageRatio(ActionInfo memory _actionInfo) internal pure returns(int256) {
        /*
        Account Specs:
        -------------
        collateral:= balance of USDC in vault
        owedRealizedPnl:= realized PnL (in USD) that hasn't been settled
        pendingFundingPayment := funding payment (in USD) that hasn't been settled

        settling collateral (on withdraw)
            collateral <- collateral + owedRealizedPnL
            owedRealizedPnL <- 0

        settling funding (on every trade)
            owedRealizedPnL <- owedRealizedPnL + pendingFundingPayment
            pendingFundingPayment <- 0

        Note: Collateral balance, owedRealizedPnl and pendingFundingPayments belong to the entire account and
        NOT just the single market managed by this contract. So, while managing multiple positions across multiple
        markets via multiple separate extension contracts, `totalCollateralValue` should be counted only once.
        */
        int256 totalCollateralValue = _actionInfo.accountInfo.collateralBalance
            .add(_actionInfo.accountInfo.owedRealizedPnl)
            .add(_actionInfo.accountInfo.pendingFundingPayments);

        // Note: Both basePositionValue and quoteValue are values that belong to the single market managed by this contract.
        int256 unrealizedPnl = _actionInfo.basePositionValue.add(_actionInfo.quoteValue);

        int256 accountValue = totalCollateralValue.add(unrealizedPnl);

        if (accountValue <= 0) {
            return 0;
        }

        // `accountValue` is always positive. Do not use absolute value of basePositionValue in the below equation,
        //  to keep the sign of CLR same as that of basePositionValue.
        return _actionInfo.basePositionValue.preciseDiv(accountValue);
    }

    /**
     * Calculate the new leverage ratio. The methodology reduces the size of each rebalance by weighting
     * the current leverage ratio against the target leverage ratio by the recentering speed percentage. The lower the recentering speed, the slower
     * the leverage token will move towards the target leverage each rebalance.
     *
     * return int256          New leverage ratio
     */
    function _calculateNewLeverageRatio(int256 _currentLeverageRatio) internal view returns(int256) {
        // Convert int256 variables to uint256 prior to passing through methodology
        uint256 currentLeverageRatioAbs = _currentLeverageRatio.abs();
        uint256 targetLeverageRatioAbs = methodology.targetLeverageRatio.abs();
        uint256 maxLeverageRatioAbs = methodology.maxLeverageRatio.abs();
        uint256 minLeverageRatioAbs = methodology.minLeverageRatio.abs();

        // CLRt+1 = max(MINLR, min(MAXLR, CLRt * (1 - RS) + TLR * RS))
        // a: TLR * RS
        // b: (1- RS) * CLRt
        // c: (1- RS) * CLRt + TLR * RS
        // d: min(MAXLR, CLRt * (1 - RS) + TLR * RS)
        uint256 a = targetLeverageRatioAbs.preciseMul(methodology.recenteringSpeed);
        uint256 b = PreciseUnitMath.preciseUnit().sub(methodology.recenteringSpeed).preciseMul(currentLeverageRatioAbs);
        uint256 c = a.add(b);
        uint256 d = Math.min(c, maxLeverageRatioAbs);
        uint256 newLeverageRatio = Math.max(minLeverageRatioAbs, d);

        return _currentLeverageRatio > 0 ? newLeverageRatio.toInt256() : newLeverageRatio.toInt256().neg();
    }

    /**
     * Calculate total notional rebalance quantity and chunked rebalance quantity in base asset units.
     *
     * return int256          Chunked rebalance notional in base asset units
     * return int256          Total rebalance notional in base asset units
     */
    function _calculateChunkRebalanceNotional(
        LeverageInfo memory _leverageInfo,
        int256 _newLeverageRatio
    )
        internal
        pure
        returns (int256, int256)
    {
        // Calculate difference between new and current leverage ratio
        int256 leverageRatioDifference = _newLeverageRatio.sub(_leverageInfo.currentLeverageRatio);

        int256 totalRebalanceNotional = leverageRatioDifference.preciseDiv(_leverageInfo.currentLeverageRatio).preciseMul(_leverageInfo.action.baseBalance);

        uint256 chunkRebalanceNotionalAbs = Math.min(totalRebalanceNotional.abs(), _leverageInfo.twapMaxTradeSize);
        return (
            // Return int256 chunkRebalanceNotional
            totalRebalanceNotional >= 0 ? chunkRebalanceNotionalAbs.toInt256() : chunkRebalanceNotionalAbs.toInt256().neg(),
            totalRebalanceNotional
        );
    }

    /**
     * Calculate total notional rebalance quantity and chunked rebalance quantity in base asset units for engaging the SetToken. Used in engage().
     * Leverage ratio (for the base asset) is zero before engage. We open a new base asset position with size equals to (collateralBalance * targetLeverageRatio / baseAssetPrice)
     * to gain (targetLeverageRatio * collateralBalance) worth of exposure to the base asset.
     * Note: We can't use `_calculateChunkRebalanceNotional` function because CLR is 0 during engage and it would lead to a divison by zero error.
     *
     * return int256          Chunked rebalance notional in base asset units
     * return int256          Total rebalance notional in base asset units
     */
    function _calculateEngageRebalanceSize(
        LeverageInfo memory _leverageInfo,
        int256 _targetLeverageRatio
    )
        internal
        pure
        returns (int256, int256)
    {
        int256 totalRebalanceNotional = _leverageInfo.action.accountInfo.collateralBalance.preciseMul(_targetLeverageRatio).preciseDiv(_leverageInfo.action.basePrice);

        uint256 chunkRebalanceNotionalAbs = Math.min(totalRebalanceNotional.abs(), _leverageInfo.twapMaxTradeSize);

        return (
            // Return int256 chunkRebalanceNotional
            totalRebalanceNotional >= 0 ? chunkRebalanceNotionalAbs.toInt256() : chunkRebalanceNotionalAbs.toInt256().neg(),
            totalRebalanceNotional
        );
    }

    /**
     * Derive the quote token units for slippage tolerance. The units are calculated by the base token units multiplied by base asset price divided by quote asset price.
     * Output is measured to precise units (1e18).
     *
     * return int256           Position units to quote
     */
    function _calculateOppositeBoundUnits(int256 _baseRebalanceUnits, ActionInfo memory _actionInfo, uint256 _slippageTolerance) internal pure returns (uint256) {
        uint256 oppositeBoundUnits;
        if (_baseRebalanceUnits > 0) {
            oppositeBoundUnits = _baseRebalanceUnits
                .preciseMul(_actionInfo.basePrice)
                .preciseDiv(_actionInfo.quotePrice)
                .preciseMul(PreciseUnitMath.preciseUnit().add(_slippageTolerance).toInt256()).toUint256();
        } else {
            oppositeBoundUnits = _baseRebalanceUnits
                .neg()
                .preciseMul(_actionInfo.basePrice)
                .preciseDiv(_actionInfo.quotePrice)
                .preciseMul(PreciseUnitMath.preciseUnit().sub(_slippageTolerance).toInt256()).toUint256();
        }
        return oppositeBoundUnits;
    }

    /**
     * Update last trade timestamp and if chunk rebalance size is less than total rebalance notional, store new leverage ratio to kick off TWAP. Used in
     * the engage() and rebalance() functions
     */
    function _updateRebalanceState(
        int256 _chunkRebalanceNotional,
        int256 _totalRebalanceNotional,
        int256 _newLeverageRatio
    )
        internal
    {
        _updateLastTradeTimestamp();

        if (_chunkRebalanceNotional.abs() < _totalRebalanceNotional.abs()) {
            twapLeverageRatio = _newLeverageRatio;
        }
    }

    /**
     * Update last trade timestamp and if chunk rebalance size is equal to the total rebalance notional, end TWAP by clearing state. This function is used
     * in iterateRebalance()
     */
    function _updateIterateState(int256 _chunkRebalanceNotional, int256 _totalRebalanceNotional) internal {

        _updateLastTradeTimestamp();

        // If the chunk size is equal to the total notional meaning that rebalances are not chunked, then clear TWAP state.
        if (_chunkRebalanceNotional == _totalRebalanceNotional) {
            delete twapLeverageRatio;
        }
    }

    /**
     * Update last trade timestamp and if currently in a TWAP, delete the TWAP state. Used in the ripcord() function.
     */
    function _updateRipcordState() internal {

        _updateLastTradeTimestamp();

        // If TWAP leverage ratio is stored, then clear state. This may happen if we are currently in a TWAP rebalance, and the leverage ratio moves above the
        // incentivized threshold for ripcord.
        if (twapLeverageRatio != 0) {
            delete twapLeverageRatio;
        }
    }

    /**
     * Update last trade timestamp. Used in the disengage() function.
     */
    function _updateDisengageState() internal {
        _updateLastTradeTimestamp();
    }

    /**
     * Update lastTradeTimestamp value. This function updates the global timestamp so that the epoch rebalance can use the global timestamp.
     */
     function _updateLastTradeTimestamp() internal {
        lastTradeTimestamp = block.timestamp;
     }

    /**
     * Transfer ETH reward to caller of the ripcord function. If the ETH balance on this contract is less than required
     * incentive quantity, then transfer contract balance instead to prevent reverts.
     *
     * return uint256           Amount of ETH transferred to caller
     */
    function _transferEtherRewardToCaller(uint256 _etherReward) internal returns(uint256) {
        uint256 etherToTransfer = _etherReward < address(this).balance ? _etherReward : address(this).balance;

        msg.sender.transfer(etherToTransfer);

        return etherToTransfer;
    }

    /**
     * Internal function returning the ShouldRebalance enum used in shouldRebalance and shouldRebalanceWithBounds external getter functions
     *
     * return ShouldRebalance         Enum detailing whether to rebalance, iterateRebalance, ripcord or no action
     */
    function _shouldRebalance(
        int256 _currentLeverageRatio,
        int256 _minLeverageRatio,
        int256 _maxLeverageRatio
    )
        internal
        view
        returns(ShouldRebalance)
    {
        // If none of the below conditions are satisfied, then should not rebalance
        ShouldRebalance shouldRebalanceEnum = ShouldRebalance.NONE;

        // Get absolute value of current leverage ratio
        uint256 currentLeverageRatioAbs = _currentLeverageRatio.abs();

        // If above ripcord threshold, then check if incentivized cooldown period has elapsed
        if (currentLeverageRatioAbs >= incentive.incentivizedLeverageRatio.abs()) {
            if (lastTradeTimestamp.add(incentive.incentivizedTwapCooldownPeriod) < block.timestamp) {
                shouldRebalanceEnum = ShouldRebalance.RIPCORD;
            }
        } else {
            // If TWAP, then check if the cooldown period has elapsed
            if (twapLeverageRatio != 0) {
                if (lastTradeTimestamp.add(execution.twapCooldownPeriod) < block.timestamp) {
                    shouldRebalanceEnum = ShouldRebalance.ITERATE_REBALANCE;
                }
            } else {
                // If not TWAP, then check if the rebalance interval has elapsed OR current leverage is above max leverage OR current leverage is below
                // min leverage
                if (
                    block.timestamp.sub(lastTradeTimestamp) > methodology.rebalanceInterval
                    || currentLeverageRatioAbs > _maxLeverageRatio.abs()
                    || currentLeverageRatioAbs < _minLeverageRatio.abs()
                ) {
                    shouldRebalanceEnum = ShouldRebalance.REBALANCE;
                }
            }
        }

        return shouldRebalanceEnum;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
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
pragma experimental ABIEncoderV2;

interface IAccountBalance {
    function getBaseTokens(address trader) external view returns (address[] memory);
    function hasOrder(address trader) external view returns (bool);
    function getMarginRequirementForLiquidation(address trader) external view returns (int256);
    function getTotalDebtValue(address trader) external view returns (uint256);
    function getPnlAndPendingFee(address trader) external view returns (int256,int256,uint256);
    function getBase(address trader, address baseToken) external view returns (int256);
    function getQuote(address trader, address baseToken) external view returns (int256);
    function getNetQuoteBalanceAndPendingFee(address trader) external view returns (int256, uint256);
    function getTotalPositionSize(address trader, address baseToken) external view returns (int256);
    function getTotalPositionValue(address trader, address baseToken) external view returns (int256);
    function getTotalAbsPositionValue(address trader) external view returns (uint256);
    function getClearingHouseConfig() external view returns (address);
    function getExchange() external view returns (address);
    function getOrderBook() external view returns (address);
    function getVault() external view returns (address);
    function getTakerPositionSize(address trader, address baseToken) external view returns (int256);
    function getTakerOpenNotional(address trader, address baseToken) external view returns (int256);
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

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISetToken } from "./ISetToken.sol";
import { IDebtIssuanceModule } from "./IDebtIssuanceModule.sol";
import { IAccountBalance } from "./external/perp-v2/IAccountBalance.sol";
import { IClearingHouse } from "./external/perp-v2/IClearingHouse.sol";
import { IExchange } from "./external/perp-v2/IExchange.sol";
import { IVault } from "./external/perp-v2/IVault.sol";
import { IQuoter } from "./external/perp-v2/IQuoter.sol";
import { IMarketRegistry } from "./external/perp-v2/IMarketRegistry.sol";
import { PerpV2Positions } from "../protocol/integration/lib/PerpV2Positions.sol";

/**
 * @title IPerpV2LeverageModuleV2
 * @author Set Protocol
 *
 * Interface for the PerpV2LeverageModuleV2. Only specifies Manager permissioned functions, events
 * and getters. PerpV2LeverageModuleV2 also inherits from ModuleBase and SetTokenAccessible which support
 * additional methods.
 */
interface IPerpV2LeverageModuleV2 {

    /* ============ Structs ============ */

    // Note: when `pendingFundingPayments` is positive it will be credited to account on settlement,
    // when negative it's a debt owed that will be repaid on settlement. (PerpProtocol.Exchange returns the value
    // with the opposite meaning, e.g positively signed payments are owed by account to system).
    struct AccountInfo {
        int256 collateralBalance;       // Quantity of collateral deposited in Perp vault in 10**18 decimals
        int256 owedRealizedPnl;         // USDC quantity of profit and loss in 10**18 decimals not yet settled to vault
        int256 pendingFundingPayments;  // USDC quantity of pending funding payments in 10**18 decimals
        int256 netQuoteBalance;         // USDC quantity of net quote balance for all open positions in Perp account
    }

    /* ============ Events ============ */

    /**
     * @dev Emitted on trade
     * @param _setToken         Instance of SetToken
     * @param _baseToken        Virtual token minted by the Perp protocol
     * @param _deltaBase        Change in baseToken position size resulting from trade
     * @param _deltaQuote       Change in vUSDC position size resulting from trade
     * @param _protocolFee      Quantity in collateral decimals sent to fee recipient during lever trade
     * @param _isBuy            True when baseToken is being bought, false when being sold
     */
    event PerpTraded(
        ISetToken indexed _setToken,
        address indexed _baseToken,
        uint256 _deltaBase,
        uint256 _deltaQuote,
        uint256 _protocolFee,
        bool _isBuy
    );

    /**
     * @dev Emitted on deposit (not issue or redeem)
     * @param _setToken             Instance of SetToken
     * @param _collateralToken      Token being deposited as collateral (USDC)
     * @param _amountDeposited      Amount of collateral being deposited into Perp
     */
    event CollateralDeposited(
        ISetToken indexed _setToken,
        IERC20 _collateralToken,
        uint256 _amountDeposited
    );

    /**
     * @dev Emitted on withdraw (not issue or redeem)
     * @param _setToken             Instance of SetToken
     * @param _collateralToken      Token being withdrawn as collateral (USDC)
     * @param _amountWithdrawn      Amount of collateral being withdrawn from Perp
     */
    event CollateralWithdrawn(
        ISetToken indexed _setToken,
        IERC20 _collateralToken,
        uint256 _amountWithdrawn
    );

    /* ============ State Variable Getters ============ */

    // PerpV2 contract which provides getters for base, quote, and owedRealizedPnl balances
    function perpAccountBalance() external view returns(IAccountBalance);

    // PerpV2 contract which provides a trading API
    function perpClearingHouse() external view returns(IClearingHouse);

    // PerpV2 contract which manages trading logic. Provides getters for UniswapV3 pools and pending funding balances
    function perpExchange() external view returns(IExchange);

    // PerpV2 contract which handles deposits and withdrawals. Provides getter for collateral balances
    function perpVault() external view returns(IVault);

    // PerpV2 contract which makes it possible to simulate a trade before it occurs
    function perpQuoter() external view returns(IQuoter);

    // PerpV2 contract which provides a getter for baseToken UniswapV3 pools
    function perpMarketRegistry() external view returns(IMarketRegistry);

    // Token (USDC) used as a vault deposit, Perp currently only supports USDC as it's settlement and collateral token
    function collateralToken() external view returns(IERC20);

    // Decimals of collateral token. We set this in the constructor for later reading
    function collateralDecimals() external view returns(uint8);

    /* ============ External Functions ============ */

    /**
     * @dev MANAGER ONLY: Initializes this module to the SetToken. Either the SetToken needs to be on the
     * allowed list or anySetAllowed needs to be true.
     *
     * @param _setToken             Instance of the SetToken to initialize
     */
    function initialize(ISetToken _setToken) external;

    /**
     * @dev MANAGER ONLY: Allows manager to buy or sell perps to change exposure to the underlying baseToken.
     * Providing a positive value for `_baseQuantityUnits` buys vToken on UniswapV3 via Perp's ClearingHouse,
     * Providing a negative value sells the token. `_quoteBoundQuantityUnits` defines a min-receive-like slippage
     * bound for the amount of vUSDC quote asset the trade will either pay or receive as a result of the action.
     *
     * NOTE: This method doesn't update the externalPositionUnit because it is a function of UniswapV3 virtual
     * token market prices and needs to be generated on the fly to be meaningful.
     *
     * As a user when levering, e.g increasing the magnitude of your position, you'd trade as below
     * | ----------------------------------------------------------------------------------------------- |
     * | Type  |  Action | Goal                      | `quoteBoundQuantity`        | `baseQuantityUnits` |
     * | ----- |-------- | ------------------------- | --------------------------- | ------------------- |
     * | Long  | Buy     | pay least amt. of vQuote  | upper bound of input quote  | positive            |
     * | Short | Sell    | get most amt. of vQuote   | lower bound of output quote | negative            |
     * | ----------------------------------------------------------------------------------------------- |
     *
     * As a user when delevering, e.g decreasing the magnitude of your position, you'd trade as below
     * | ----------------------------------------------------------------------------------------------- |
     * | Type  |  Action | Goal                      | `quoteBoundQuantity`        | `baseQuantityUnits` |
     * | ----- |-------- | ------------------------- | --------------------------- | ------------------- |
     * | Long  | Sell    | get most amt. of vQuote   | upper bound of input quote  | negative            |
     * | Short | Buy     | pay least amt. of vQuote  | lower bound of output quote | positive            |
     * | ----------------------------------------------------------------------------------------------- |
     *
     * @param _setToken                     Instance of the SetToken
     * @param _baseToken                    Address virtual token being traded
     * @param _baseQuantityUnits            Quantity of virtual token to trade in position units
     * @param _quoteBoundQuantityUnits      Max/min of vQuote asset to pay/receive when buying or selling
     */
    function trade(
        ISetToken _setToken,
        address _baseToken,
        int256 _baseQuantityUnits,
        uint256 _quoteBoundQuantityUnits
    )
        external;

    /**
     * @dev MANAGER ONLY: Deposits default position collateral token into the PerpV2 Vault, increasing
     * the size of the Perp account external position. This method is useful for establishing initial
     * collateralization ratios, e.g the flow when setting up a 2X external position would be to deposit
     * 100 units of USDC and execute a lever trade for ~200 vUSDC worth of vToken with the difference
     * between these made up as automatically "issued" margin debt in the PerpV2 system.
     *
     * @param  _setToken                    Instance of the SetToken
     * @param  _collateralQuantityUnits     Quantity of collateral to deposit in position units
     */
    function deposit(ISetToken _setToken, uint256 _collateralQuantityUnits) external;


    /**
     * @dev MANAGER ONLY: Withdraws collateral token from the PerpV2 Vault to a default position on
     * the SetToken. This method is useful when adjusting the overall composition of a Set which has
     * a Perp account external position as one of several components.
     *
     * NOTE: Within PerpV2, `withdraw` settles `owedRealizedPnl` and any pending funding payments
     * to the Perp vault prior to transfer.
     *
     * @param  _setToken                    Instance of the SetToken
     * @param  _collateralQuantityUnits     Quantity of collateral to withdraw in position units
     */
    function withdraw(ISetToken _setToken, uint256 _collateralQuantityUnits) external;


    /* ============ External Getter Functions ============ */

    /**
     * @dev Gets the positive equity collateral externalPositionUnit that would be calculated for
     * issuing a quantity of SetToken, representing the amount of collateral that would need to
     * be transferred in per SetToken. Values in the returned arrays map to the same index in the
     * SetToken's components array
     *
     * @param _setToken             Instance of SetToken
     * @param _setTokenQuantity     Number of sets to issue
     *
     * @return equityAdjustments array containing a single element and an empty debtAdjustments array
     */
    function getIssuanceAdjustments(ISetToken _setToken, uint256 _setTokenQuantity)
        external
        returns (int256[] memory, int256[] memory);


    /**
     * @dev Gets the positive equity collateral externalPositionUnit that would be calculated for
     * redeeming a quantity of SetToken representing the amount of collateral returned per SetToken.
     * Values in the returned arrays map to the same index in the SetToken's components array.
     *
     * @param _setToken             Instance of SetToken
     * @param _setTokenQuantity     Number of sets to issue
     *
     * @return equityAdjustments array containing a single element and an empty debtAdjustments array
     */
    function getRedemptionAdjustments(ISetToken _setToken, uint256 _setTokenQuantity)
        external
        returns (int256[] memory, int256[] memory);

    /**
     * @dev Returns a PositionUnitNotionalInfo array representing all positions open for the SetToken.
     *
     * @param _setToken         Instance of SetToken
     *
     * @return PositionUnitInfo array, in which each element has properties:
     *
     *         + baseToken: address,
     *         + baseBalance:  baseToken balance as notional quantity (10**18)
     *         + quoteBalance: USDC quote asset balance as notional quantity (10**18)
     */
    function getPositionNotionalInfo(ISetToken _setToken) external view returns (PerpV2Positions.PositionNotionalInfo[] memory);

    /**
     * @dev Returns a PositionUnitInfo array representing all positions open for the SetToken.
     *
     * @param _setToken         Instance of SetToken
     *
     * @return PositionUnitInfo array, in which each element has properties:
     *
     *         + baseToken: address,
     *         + baseUnit:  baseToken balance as position unit (10**18)
     *         + quoteUnit: USDC quote asset balance as position unit (10**18)
     */
    function getPositionUnitInfo(ISetToken _setToken) external view returns (PerpV2Positions.PositionUnitInfo[] memory);

    /**
     * @dev Gets Perp account info for SetToken. Returns an AccountInfo struct containing account wide
     * (rather than position specific) balance info
     *
     * @param  _setToken            Instance of the SetToken
     *
     * @return accountInfo          struct with properties for:
     *
     *         + collateral balance (10**18, regardless of underlying collateral decimals)
     *         + owed realized Pnl` (10**18)
     *         + pending funding payments (10**18)
     *         + net quote balance (10**18)
     */
    function getAccountInfo(ISetToken _setToken) external view returns (AccountInfo memory accountInfo);
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

interface IVault {
    function getBalance(address account) external view returns (int256);
    function decimals() external view returns (uint8);
    function getFreeCollateral(address trader) external view returns (uint256);
    function getFreeCollateralByRatio(address trader, uint24 ratio) external view returns (int256);
    function getLiquidateMarginRequirement(address trader) external view returns (int256);
    function getSettlementToken() external view returns (address);
    function getAccountBalance() external view returns (address);
    function getClearingHouse() external view returns (address);
    function getExchange() external view returns (address);
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

import { AddressArrayUtils } from "@setprotocol/set-protocol-v2/contracts/lib/AddressArrayUtils.sol";

import { IBaseManager } from "../interfaces/IBaseManager.sol";

/**
 * @title BaseExtension
 * @author Set Protocol
 *
 * Abstract class that houses common extension-related state and functions.
 */
abstract contract BaseExtension {
    using AddressArrayUtils for address[];

    /* ============ Events ============ */

    event CallerStatusUpdated(address indexed _caller, bool _status);
    event AnyoneCallableUpdated(bool indexed _status);

    /* ============ Modifiers ============ */

    /**
     * Throws if the sender is not the SetToken operator
     */
    modifier onlyOperator() {
        require(msg.sender == manager.operator(), "Must be operator");
        _;
    }

    /**
     * Throws if the sender is not the SetToken methodologist
     */
    modifier onlyMethodologist() {
        require(msg.sender == manager.methodologist(), "Must be methodologist");
        _;
    }

    /**
     * Throws if caller is a contract, can be used to stop flash loan and sandwich attacks
     */
    modifier onlyEOA() {
        require(msg.sender == tx.origin, "Caller must be EOA Address");
        _;
    }

    /**
     * Throws if not allowed caller
     */
    modifier onlyAllowedCaller(address _caller) {
        require(isAllowedCaller(_caller), "Address not permitted to call");
        _;
    }

    /* ============ State Variables ============ */

    // Instance of manager contract
    IBaseManager public manager;

    // Boolean indicating if anyone can call function
    bool public anyoneCallable;

    // Mapping of addresses allowed to call function
    mapping(address => bool) public callAllowList;

    /* ============ Constructor ============ */

    constructor(IBaseManager _manager) public { manager = _manager; }

    /* ============ External Functions ============ */

    /**
     * OPERATOR ONLY: Toggle ability for passed addresses to call only allowed caller functions
     *
     * @param _callers           Array of caller addresses to toggle status
     * @param _statuses          Array of statuses for each caller
     */
    function updateCallerStatus(address[] calldata _callers, bool[] calldata _statuses) external onlyOperator {
        require(_callers.length == _statuses.length, "Array length mismatch");
        require(_callers.length > 0, "Array length must be > 0");
        require(!_callers.hasDuplicate(), "Cannot duplicate callers");

        for (uint256 i = 0; i < _callers.length; i++) {
            address caller = _callers[i];
            bool status = _statuses[i];
            callAllowList[caller] = status;
            emit CallerStatusUpdated(caller, status);
        }
    }

    /**
     * OPERATOR ONLY: Toggle whether anyone can call function, bypassing the callAllowlist
     *
     * @param _status           Boolean indicating whether to allow anyone call
     */
    function updateAnyoneCallable(bool _status) external onlyOperator {
        anyoneCallable = _status;
        emit AnyoneCallableUpdated(_status);
    }

    /* ============ Internal Functions ============ */

    /**
     * Invoke call from manager
     *
     * @param _module           Module to interact with
     * @param _encoded          Encoded byte data
     */
    function invokeManager(address _module, bytes memory _encoded) internal {
        manager.interactManager(_module, _encoded);
    }

    /**
     * Determine if passed address is allowed to call function. If anyoneCallable set to true anyone can call otherwise needs to be approved.
     *
     * return bool              Boolean indicating if allowed caller
     */
    function isAllowedCaller(address _caller) internal view virtual returns (bool) {
        return anyoneCallable || callAllowList[_caller];
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

interface IBaseManager {
    function setToken() external returns(ISetToken);

    function methodologist() external returns(address);

    function operator() external returns(address);

    function interactManager(address _module, bytes calldata _encoded) external;

    function transferTokens(address _token, address _destination, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT License
pragma solidity 0.6.10;

interface IPriceFeed {
    function decimals() external view returns (uint8);

    /// @dev Returns the index price of the token.
    /// @param interval The interval represents twap interval.
    function getPrice(uint256 interval) external view returns (uint256);
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

import { ISetToken } from "./ISetToken.sol";

/**
 * @title IDebtIssuanceModule
 * @author Set Protocol
 *
 * Interface for interacting with Debt Issuance module interface.
 */
interface IDebtIssuanceModule {

    /**
     * Called by another module to register itself on debt issuance module. Any logic can be included
     * in case checks need to be made or state needs to be updated.
     */
    function registerToIssuanceModule(ISetToken _setToken) external;

    /**
     * Called by another module to unregister itself on debt issuance module. Any logic can be included
     * in case checks need to be made or state needs to be cleared.
     */
    function unregisterFromIssuanceModule(ISetToken _setToken) external;
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
pragma experimental ABIEncoderV2;

interface IClearingHouse {
    struct OpenPositionParams {
        address baseToken;
        bool isBaseToQuote;
        bool isExactInput;
        uint256 amount;
        // B2Q + exact input, want more output quote as possible, so we set a lower bound of output quote
        // B2Q + exact output, want less input base as possible, so we set a upper bound of input base
        // Q2B + exact input, want more output base as possible, so we set a lower bound of output base
        // Q2B + exact output, want less input quote as possible, so we set a upper bound of input quote
        // when it's 0 in exactInput, means ignore slippage protection
        // when it's maxUint in exactOutput = ignore
        // when it's over or under the bound, it will be reverted
        uint256 oppositeAmountBound;
        uint256 deadline;
        // B2Q: the price cannot be less than this value after the swap
        // Q2B: The price cannot be greater than this value after the swap
        // it will fill the trade until it reach the price limit instead of reverted
        uint160 sqrtPriceLimitX96;
        bytes32 referralCode;
    }

    struct ClosePositionParams {
        address baseToken;
        uint160 sqrtPriceLimitX96;
        uint256 oppositeAmountBound;
        uint256 deadline;
        bytes32 referralCode;
    }

    function openPosition(OpenPositionParams memory params)
        external
        returns (uint256 deltaBase, uint256 deltaQuote);

    function closePosition(ClosePositionParams calldata params)
        external
        returns (uint256 deltaBase, uint256 deltaQuote);

    function getAccountValue(address trader) external view returns (int256);
    function getPositionSize(address trader, address baseToken) external view returns (int256);
    function getPositionValue(address trader, address baseToken) external view returns (int256);
    function getOpenNotional(address trader, address baseToken) external view returns (int256);
    function getOwedRealizedPnl(address trader) external view returns (int256);
    function getTotalInitialMarginRequirement(address trader) external view returns (uint256);
    function getNetQuoteBalance(address trader) external view returns (int256);
    function getTotalUnrealizedPnl(address trader) external view returns (int256);
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
pragma experimental ABIEncoderV2;

interface IExchange {
    struct FundingGrowth {
        int256 twPremiumX96;
        int256 twPremiumDivBySqrtPriceX96;
    }

    struct SwapParams {
        address trader;
        address baseToken;
        bool isBaseToQuote;
        bool isExactInput;
        uint256 amount;
        uint160 sqrtPriceLimitX96;
        FundingGrowth fundingGrowthGlobal;
    }

    struct SwapResponse {
        uint256 deltaAvailableBase;
        uint256 deltaAvailableQuote;
        int256 exchangedPositionSize;
        int256 exchangedPositionNotional;
        uint256 fee;
        uint256 insuranceFundFee;
        int24 tick;
        int256 realizedPnl;
        int256 openNotional;
    }

    // Note: Do *NOT* add `getFundingGrowthGlobalAndTwaps` to this interface. It may work with the
    // custom bytecode we generated to expose the method in our TS tests but it's no longer part of the
    // public interface of the deployed PerpV2 system contracts. (Removed in v0.15.0).

    function getPool(address baseToken) external view returns (address);
    function getTick(address baseToken) external view returns (int24);
    function getSqrtMarkTwapX96(address baseToken, uint32 twapInterval) external view returns (uint160);
    function getMaxTickCrossedWithinBlock(address baseToken) external view returns (uint24);
    function getAllPendingFundingPayment(address trader) external view returns (int256);
    function getPendingFundingPayment(address trader, address baseToken) external view returns (int256);
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
pragma experimental ABIEncoderV2;

interface IQuoter {
    struct SwapParams {
        address baseToken;
        bool isBaseToQuote;
        bool isExactInput;
        uint256 amount;
        uint160 sqrtPriceLimitX96; // price slippage protection
    }

    struct SwapResponse {
        uint256 deltaAvailableBase;
        uint256 deltaAvailableQuote;
        int256 exchangedPositionSize;
        int256 exchangedPositionNotional;
        uint160 sqrtPriceX96;
    }

    function swap(SwapParams memory params) external returns (SwapResponse memory response);
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
pragma experimental ABIEncoderV2;

interface IMarketRegistry {
    //
    // EXTERNAL VIEW
    //

    function getPool(address baseToken) external view returns (address);

    function getQuoteToken() external view returns (address);

    function getUniswapV3Factory() external view returns (address);

    function hasPool(address baseToken) external view returns (bool);
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
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SignedSafeMath.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { AddressArrayUtils } from "../../../lib/AddressArrayUtils.sol";
import { IAccountBalance } from "../../../interfaces/external/perp-v2/IAccountBalance.sol";
import { ISetToken } from "../../../interfaces/ISetToken.sol";
import { Position } from "../../../protocol/lib/Position.sol";
import { PreciseUnitMath } from "../../../lib/PreciseUnitMath.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/SafeCast.sol";
import { UnitConversionUtils } from "../../../lib/UnitConversionUtils.sol";

/**
 * @title PerpV2Positions
 * @author Set Protocol
 *
 * Collection of PerpV2 getter functions.
 */
library PerpV2Positions {
    using Position for ISetToken;
    using SignedSafeMath for int256;
    using SafeCast for uint256;
    using PreciseUnitMath for int256;
    using AddressArrayUtils for address[];
    
    struct PositionNotionalInfo {
        address baseToken;              // Virtual token minted by the Perp protocol
        int256 baseBalance;             // Base position notional quantity in 10**18 decimals. When negative, position is short
        int256 quoteBalance;            // vUSDC "debt" notional quantity minted to open position. When positive, position is short
    }

    struct PositionUnitInfo {
        address baseToken;              // Virtual token minted by the Perp protocol
        int256 baseUnit;                // Base position unit. When negative, position is short
        int256 quoteUnit;               // vUSDC "debt" position unit. When positive, position is short
    }

    /**
     * @dev Retrieves net quote balance of all open positions.
     *
     * @param _setToken             Instance of SetToken
     * @param _baseTokens           PerpV2 market addresses in which SetToken has positions
     * @param _perpAccountBalance   Instance of PerpV2 AccountBalance
     * @return netQuoteBalance      Net quote balance of all open positions
     */
    function getNetQuoteBalance(
        ISetToken _setToken, 
        address[] memory _baseTokens, 
        IAccountBalance _perpAccountBalance
    ) 
        external 
        view 
        returns (int256 netQuoteBalance) 
    {
        uint256 numBaseTokens = _baseTokens.length;
        for (uint256 i = 0; i < numBaseTokens; i++) {
            netQuoteBalance = netQuoteBalance.add(
                _perpAccountBalance.getQuote(address(_setToken), _baseTokens[i])
            );
        }
    }

    /**
     * @dev Returns a PositionUnitNotionalInfo array representing all positions open for the SetToken.
     *
     * @param _setToken             Instance of SetToken
     * @param _baseTokens           PerpV2 market addresses in which SetToken has positions
     * @param _perpAccountBalance   Instance of PerpV2 AccountBalance
     *
     * @return PositionUnitInfo array, in which each element has properties:
     *
     *         + baseToken: address,
     *         + baseBalance:  baseToken balance as notional quantity (10**18)
     *         + quoteBalance: USDC quote asset balance as notional quantity (10**18)
     */
    function getPositionNotionalInfo(
        ISetToken _setToken, 
        address[] memory _baseTokens, 
        IAccountBalance _perpAccountBalance
    ) 
        public 
        view 
        returns (PositionNotionalInfo[] memory) 
    {
        uint256 numBaseTokens = _baseTokens.length;
        PositionNotionalInfo[] memory positionInfo = new PositionNotionalInfo[](numBaseTokens);

        for(uint i = 0; i < numBaseTokens; i++){
            address baseToken = _baseTokens[i];
            positionInfo[i] = PositionNotionalInfo({
                baseToken: baseToken,
                baseBalance: _perpAccountBalance.getBase(
                    address(_setToken),
                    baseToken
                ),
                quoteBalance: _perpAccountBalance.getQuote(
                    address(_setToken),
                    baseToken
                )
            });
        }

        return positionInfo;
    }
    
    /**
     * @dev Returns a PerpV2Positions.PositionUnitInfo array representing all positions open for the SetToken.
     *
     * @param _setToken             Instance of SetToken
     * @param _baseTokens           PerpV2 market addresses in which SetToken has positions
     * @param _perpAccountBalance   Instance of PerpV2 AccountBalance
     *
     * @return PerpV2Positions.PositionUnitInfo array, in which each element has properties:
     *
     *         + baseToken: address,
     *         + baseUnit:  baseToken balance as position unit (10**18)
     *         + quoteUnit: USDC quote asset balance as position unit (10**18)
     */
    function getPositionUnitInfo(
        ISetToken _setToken, 
        address[] memory _baseTokens, 
        IAccountBalance _perpAccountBalance
    ) 
        external 
        view 
        returns (PositionUnitInfo[] memory) 
    {
        int256 totalSupply = _setToken.totalSupply().toInt256();
        PositionNotionalInfo[] memory positionNotionalInfo = getPositionNotionalInfo(
            _setToken,
            _baseTokens,
            _perpAccountBalance
        );
        
        uint256 positionLength = positionNotionalInfo.length;
        PositionUnitInfo[] memory positionUnitInfo = new PositionUnitInfo[](positionLength);

        for(uint i = 0; i < positionLength; i++){
            PositionNotionalInfo memory currentPosition = positionNotionalInfo[i];
            positionUnitInfo[i] = PositionUnitInfo({
                baseToken: currentPosition.baseToken,
                baseUnit: currentPosition.baseBalance.preciseDiv(totalSupply),
                quoteUnit: currentPosition.quoteBalance.preciseDiv(totalSupply)
            });
        }

        return positionUnitInfo;
    }

    /**
     * @dev Returns issuance or redemption adjustments in the format expected by `SlippageIssuanceModule`.
     * The last recorded externalPositionUnit (current) is subtracted from a dynamically generated
     * externalPositionUnit (new) and set in an `equityAdjustments` array which is the same length as
     * the SetToken's components array, at the same index the collateral token occupies in the components
     * array. All other values are left unset (0). An empty-value components length debtAdjustments
     * array is also returned.
     *
     * @param _setToken                         Instance of the SetToken
     * @param _adjustComponent                  Address of component token whose position unit is to be adjusted
     * @param _currentExternalPositionUnit      Current external position unit of `_adjustComponent`
     * @param _newExternalPositionUnit          New external position unit of `_adjustComponent`
     * @return int256[]                         Components-length array with equity adjustment value at appropriate index
     * @return int256[]                         Components-length array of zeroes (debt adjustements)
     */
    function formatAdjustments(
        ISetToken _setToken,
        address _adjustComponent,
        int256 _currentExternalPositionUnit,
        int256 _newExternalPositionUnit
    )
        external
        view
        returns (int256[] memory, int256[] memory)
    {
        address[] memory components = _setToken.getComponents();

        int256[] memory equityAdjustments = new int256[](components.length);
        int256[] memory debtAdjustments = new int256[](components.length);

        (uint256 index, bool isIn) = components.indexOf(_adjustComponent);

        if (isIn) {
            equityAdjustments[index] = _newExternalPositionUnit.sub(_currentExternalPositionUnit);
        }

        return (equityAdjustments, debtAdjustments);
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

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { SignedSafeMath } from "@openzeppelin/contracts/math/SignedSafeMath.sol";

/**
 * @title UnitConversionUtils
 * @author Set Protocol
 *
 * Utility functions to convert PRECISE_UNIT values to and from other decimal units
 */
library UnitConversionUtils {
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    /**
     * @dev Converts a uint256 PRECISE_UNIT quote quantity into an alternative decimal format.
     *
     * This method is borrowed from PerpProtocol's `lushan` repo in lib/SettlementTokenMath
     *
     * @param _amount       PRECISE_UNIT amount to convert from
     * @param _decimals     Decimal precision format to convert to
     * @return              Input converted to alternative decimal precision format
     */
    function fromPreciseUnitToDecimals(uint256 _amount, uint8 _decimals) internal pure returns (uint256) {
        return _amount.div(10**(18 - uint(_decimals)));
    }

    /**
     * @dev Converts an int256 PRECISE_UNIT quote quantity into an alternative decimal format.
     *
     * This method is borrowed from PerpProtocol's `lushan` repo in lib/SettlementTokenMath
     *
     * @param _amount       PRECISE_UNIT amount to convert from
     * @param _decimals     Decimal precision format to convert to
     * @return              Input converted to alternative decimal precision format
     */
    function fromPreciseUnitToDecimals(int256 _amount, uint8 _decimals) internal pure returns (int256) {
        return _amount.div(int256(10**(18 - uint(_decimals))));
    }

    /**
     * @dev Converts an arbitrarily decimalized quantity into a int256 PRECISE_UNIT quantity.
     *
     * @param _amount       Non-PRECISE_UNIT amount to convert
     * @param _decimals     Decimal precision of amount being converted to PRECISE_UNIT
     * @return              Input converted to int256 PRECISE_UNIT decimal format
     */
    function toPreciseUnitsFromDecimals(int256 _amount, uint8 _decimals) internal pure returns (int256) {
        return _amount.mul(int256(10**(18 - (uint(_decimals)))));
    }

    /**
     * @dev Converts an arbitrarily decimalized quantity into a uint256 PRECISE_UNIT quantity.
     *
     * @param _amount       Non-PRECISE_UNIT amount to convert
     * @param _decimals     Decimal precision of amount being converted to PRECISE_UNIT
     * @return              Input converted to uint256 PRECISE_UNIT decimal format
     */
    function toPreciseUnitsFromDecimals(uint256 _amount, uint8 _decimals) internal pure returns (uint256) {
        return _amount.mul(10**(18 - (uint(_decimals))));
    }
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
pragma experimental ABIEncoderV2;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Math } from "@openzeppelin/contracts/math/Math.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/SafeCast.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { SignedSafeMath } from "@openzeppelin/contracts/math/SignedSafeMath.sol";

import { BytesLib } from "@setprotocol/set-protocol-v2/external/contracts/uniswap/v3/lib/BytesLib.sol";
import { BytesArrayUtils } from "@setprotocol/set-protocol-v2/contracts/lib/BytesArrayUtils.sol";
import { IAccountBalance } from "@setprotocol/set-protocol-v2/contracts/interfaces/external/perp-v2/IAccountBalance.sol";
import { IPerpV2BasisTradingModule } from "@setprotocol/set-protocol-v2/contracts/interfaces/IPerpV2BasisTradingModule.sol";
import { IPerpV2LeverageModuleV2 } from "@setprotocol/set-protocol-v2/contracts/interfaces/IPerpV2LeverageModuleV2.sol";
import { ISetToken } from "@setprotocol/set-protocol-v2/contracts/interfaces/ISetToken.sol";
import { ITradeModule } from "@setprotocol/set-protocol-v2/contracts/interfaces/ITradeModule.sol";
import { IVault } from "@setprotocol/set-protocol-v2/contracts/interfaces/external/perp-v2/IVault.sol";
import { PreciseUnitMath } from "@setprotocol/set-protocol-v2/contracts/lib/PreciseUnitMath.sol";
import { StringArrayUtils } from "@setprotocol/set-protocol-v2/contracts/lib/StringArrayUtils.sol";
import { UnitConversionUtils } from "@setprotocol/set-protocol-v2/contracts/lib/UnitConversionUtils.sol";

import { BaseExtension } from "../lib/BaseExtension.sol";
import { IBaseManager } from "../interfaces/IBaseManager.sol";
import { IPriceFeed } from "../interfaces/IPriceFeed.sol";
import { IUniswapV3Quoter } from "../interfaces/IUniswapV3Quoter.sol";

/**
 * @title DeltaNeutralBasisTradingStrategyExtension
 * @author Set Protocol
 *
 * Strategy smart contract that transforms a SetToken into an on-chain delta neutral basis trading token that earns yield by shorting assets
 * on PerpV2 and collecting funding, while maintaing delta neutral exposure to the short asset by holding an equal amount of spot asset.
 * This extension is paired with the PerpV2BasisTradingModule from Set Protocol where module interactions are invoked via the IBaseManager
 * contract. Any basis trading token can be constructed as long as the market is listed on Perp V2 and there is enough liquidity for the
 * corresponding spot asset on UniswapV3. This extension contract also allows the operator to set an ETH reward to incentivize keepers
 * calling the rebalance function at different leverage thresholds.
 */
contract DeltaNeutralBasisTradingStrategyExtension is BaseExtension {
    using Address for address;
    using PreciseUnitMath for uint256;
    using PreciseUnitMath for int256;
    using SafeMath for uint256;
    using SignedSafeMath for int256;
    using SafeCast for int256;
    using SafeCast for uint256;
    using StringArrayUtils for string[];
    using BytesLib for bytes;
    using BytesArrayUtils for bytes;
    using UnitConversionUtils for int256;
    using UnitConversionUtils for uint256;

    /* ============ Enums ============ */

    enum ShouldRebalance {
        NONE,                   // Indicates no rebalance action can be taken
        REBALANCE,              // Indicates rebalance() function can be successfully called
        ITERATE_REBALANCE,      // Indicates iterateRebalance() function can be successfully called
        RIPCORD,                // Indicates ripcord() function can be successfully called
        REINVEST                // Indicates reinvest() function can be successfully called
    }

    /* ============ Structs ============ */

    struct ActionInfo {
        int256 baseBalance;                                 // Balance of virtual base asset from Perp in precise units (10e18). E.g. vWBTC = 10e18
        int256 quoteBalance;                                // Balance of virtual quote asset from Perp in precise units (10e18). E.g. vUSD = 10e18
        IPerpV2BasisTradingModule.AccountInfo accountInfo;  // Info on perpetual account including, collateral balance, owedRealizedPnl and pendingFunding
        int256 basePositionValue;                           // Valuation in USD adjusted for decimals in precise units (10e18)
        int256 quoteValue;                                  // Valuation in USD adjusted for decimals in precise units (10e18)
        int256 basePrice;                                   // Price of base asset in precise units (10e18) from PerpV2 Oracle
        int256 quotePrice;                                  // Price of quote asset in precise units (10e18) from PerpV2 Oracle
        uint256 setTotalSupply;                             // Total supply of SetToken
    }

    struct LeverageInfo {
        ActionInfo action;
        int256 currentLeverageRatio;                    // Current leverage ratio of Set. For short tokens, this will be negative
        uint256 slippageTolerance;                      // Allowable percent trade slippage in preciseUnits (1% = 10^16)
        uint256 twapMaxTradeSize;                       // Max trade size in base asset units allowed for rebalance action
    }

    struct ContractSettings {
        ISetToken setToken;                                 // Instance of leverage token
        IPerpV2BasisTradingModule basisTradingModule;       // Instance of PerpV2 basis trading module
        ITradeModule tradeModule;                           // Instance of the trade module
        IUniswapV3Quoter quoter;                            // Instance of UniswapV3 Quoter
        IAccountBalance perpV2AccountBalance;               // Instance of PerpV2 AccountBalance contract used to fetch position balances
        IPriceFeed baseUSDPriceOracle;                      // PerpV2 oracle that returns TWAP price for base asset in USD. IPriceFeed is a PerpV2 specific interface
                                                            // to interact with differnt oracle providers, e.g. Band Protocol and Chainlink, for different assets
                                                            // listed on PerpV2.
        uint256 twapInterval;                               // TWAP interval to be used to fetch base asset price in seconds
                                                            // PerpV2 uses a 15 min TWAP interval, i.e. twapInterval = 900
        uint256 basePriceDecimalAdjustment;                 // Decimal adjustment for the price returned by the PerpV2 oracle for the base asset.
                                                            // Equal to vBaseAsset.decimals() - baseUSDPriceOracle.decimals()
        address virtualBaseAddress;                         // Address of virtual base asset (e.g. vETH, vWBTC etc)
        address virtualQuoteAddress;                        // Address of virtual USDC quote asset. The Perp V2 system uses USDC for all markets
        address spotAssetAddress;                           // Address of spot asset corresponding to virtual base asset (e.g. if base asset is vETH, spot asset would be WETH)
    }

    struct MethodologySettings {
        int256 targetLeverageRatio;                     // Long term target ratio in precise units (10e18) for the Perpetual position.
                                                        // Should be negative as strategy is shorting the perp. E.g. -1 for ETH -1x.
        int256 minLeverageRatio;                        // If magnitude of current leverage is lower, rebalance target is this ratio. In precise units (10e18).
                                                        // Should be negative as strategy is shorting the perp. E.g. -0.7e18 for ETH -1x.
        int256 maxLeverageRatio;                        // If magniutde of current leverage is higher, rebalance target is this ratio. In precise units (10e18).
                                                        // Should be negative as strategy is shorting the perp. E.g. -1.3e18 for ETH -1x.
        uint256 recenteringSpeed;                       // % at which to rebalance back to target leverage in precise units (10e18). Always a positive number
        uint256 rebalanceInterval;                      // Period of time required since last rebalance timestamp in seconds
        uint256 reinvestInterval;                       // Period of time required since last reinvestment timestamp in seconds
        uint256 minReinvestUnits;                       // Minimum reinvestment amount per Set at which `shouldRebalance` returns 4 (`ShouldRebalance.REINVEST`)
                                                        // provided the reinvest interval has elapsed. This threshold helps to avoid weird rounding errors that
                                                        // can happen while reinvesting very small amounts and helps the methodologist to not waste gas on reinvesting
                                                        // very small amounts. In collateral decimals (10e6 for USDC).

    }

    struct ExecutionSettings {
        uint256 slippageTolerance;                      // % in precise units to price min token receive amount from trade quantities
                                                        // NOTE: Applies to both perpetual and dex trades.
        uint256 twapCooldownPeriod;                     // Cooldown period required since last trade timestamp in seconds
                                                        // NOTE: Applies to both perpetual and dex trades.
    }

    struct ExchangeSettings {
        string exchangeName;                            // Name of the exchange adapter to be used for dex trade. This contract only supports UnisawpV3 trades.
                                                        // So should be "UniswapV3ExchangeAdapterV2".
        bytes buyExactSpotTradeData;                    // Bytes containing path and fixIn boolean which will be passed to TradeModule#trade to buy exact amount of spot asset.
                                                        // Can be generated using UniswapV3ExchangeAdapterV2#generateDataParam
        bytes sellExactSpotTradeData;                   // Bytes containing path and fixIn boolean which will be passed to TradeModule#trade to sell exact amount of spot asset
                                                        // Can be generated using UniswapV3ExchangeAdapterV2#generateDataParam
        bytes buySpotQuoteExactInputPath;               // Bytes containing UniswapV3 path to buy spot asset using exact amount of input asset (USDC). Will be passed to Quoter#getExactInput.
        uint256 twapMaxTradeSize;                       // Max trade size in base assset base units. Always a positive number
                                                        // NOTE: Applies to both perpetual and dex trades.
        uint256 incentivizedTwapMaxTradeSize;           // Max trade size for incentivized rebalances in base asset units. Always a positive number
                                                        // NOTE: Applies to both perpetual and dex trades.
    }

    struct IncentiveSettings {
        uint256 etherReward;                            // ETH reward for incentivized rebalances
        int256 incentivizedLeverageRatio;               // Leverage ratio for incentivized rebalances. Is a negative number lower than maxLeverageRatio.
                                                        // E.g. -2x for ETH -1x.
        uint256 incentivizedSlippageTolerance;          // Slippage tolerance percentage for incentivized rebalances
                                                        // NOTE: Applies to both perpetual and dex trades.
        uint256 incentivizedTwapCooldownPeriod;         // TWAP cooldown in seconds for incentivized rebalances
                                                        // NOTE: Applies to both perpetual and dex trades.
    }

    /* ============ Events ============ */

    // Below events emit `_chunkPerpRebalanceNotional` and `_totalPerpRebalanceNotional`. Spot rebalance notional amounts can be calculated by
    // _chunkSpotRebalanceNotional = _chunkPerpRebalanceNotional * -1 and _totalSpotRebalanceNotional = _totalPerpRebalanceNotional * -1
    event Engaged(
        int256 _currentLeverageRatio,
        int256 _newLeverageRatio,
        int256 _chunkPerpRebalanceNotional,
        int256 _totalPerpRebalanceNotional
    );
    event Rebalanced(
        int256 _currentLeverageRatio,
        int256 _newLeverageRatio,
        int256 _chunkPerpRebalanceNotional,
        int256 _totalPerpRebalanceNotional
    );
    event RebalanceIterated(
        int256 _currentLeverageRatio,
        int256 _newTwapLeverageRatio,
        int256 _chunkPerpRebalanceNotional,
        int256 _totalPerpRebalanceNotional
    );
    event RipcordCalled(
        int256 _currentLeverageRatio,
        int256 _newLeverageRatio,
        int256 _perpRebalanceNotional,
        uint256 _etherIncentive
    );
    event Disengaged(
        int256 _currentLeverageRatio,
        int256 _newLeverageRatio,
        int256 _chunkPerpRebalanceNotional,
        int256 _totalPerpRebalanceNotional
    );
    event Reinvested(
        uint256 _usdcReinvestedNotional,
        uint256 _spotRebalanceNotional
    );
    event MethodologySettingsUpdated(
        int256 _targetLeverageRatio,
        int256 _minLeverageRatio,
        int256 _maxLeverageRatio,
        uint256 _recenteringSpeed,
        uint256 _rebalanceInterval,
        uint256 _reinvestInterval,
        uint256 _minReinvestUnits
    );
    event ExecutionSettingsUpdated(
        uint256 _twapCooldownPeriod,
        uint256 _slippageTolerance
    );
    event ExchangeSettingsUpdated(
        string _exchangeName,
        bytes _buyExactSpotTradeData,
        bytes _sellExactSpotTradeData,
        bytes _buySpotQuoteExactInputPath,
        uint256 _twapMaxTradeSize,
        uint256 _incentivizedTwapMaxTradeSize
    );
    event IncentiveSettingsUpdated(
        uint256 _etherReward,
        int256 _incentivizedLeverageRatio,
        uint256 _incentivizedSlippageTolerance,
        uint256 _incentivizedTwapCooldownPeriod
    );

    /* ============ Modifiers ============ */

    /**
     * Throws if rebalance is currently in TWAP
     */
    modifier noRebalanceInProgress() {
        require(twapLeverageRatio == 0, "Rebalance is currently in progress");
        _;
    }

    /* ============ State Variables ============ */

    ContractSettings internal strategy;                     // Struct of contracts used in the strategy (SetToken, price oracles, leverage module etc)
    MethodologySettings internal methodology;               // Struct containing methodology parameters
    ExecutionSettings internal execution;                   // Struct containing execution parameters
    ExchangeSettings internal exchange;                     // Struct containing exchange settings
    IncentiveSettings internal incentive;                   // Struct containing incentive parameters for ripcord

    IERC20 internal collateralToken;                        // Collateral token to be deposited to PerpV2. We set this in the constructor for reading later.
    uint8 internal collateralDecimals;                      // Decimals of collateral token. We set this in the constructor for reading later.

    int256 public twapLeverageRatio;                        // Stored leverage ratio to keep track of target between TWAP rebalances
    uint256 public lastTradeTimestamp;                      // Last rebalance timestamp. Current timestamp must be greater than this variable + rebalance
                                                            // interval to rebalance
    uint256 public lastReinvestTimestamp;                   // Last reinvest timestamp. Current timestamp must be greater than this variable + reinvest
                                                            // interval to reinvest

    /* ============ Constructor ============ */

    /**
     * Instantiate addresses, methodology parameters, execution parameters, exchange parameters and incentive parameters.
     *
     * @param _manager                  Address of IBaseManager contract
     * @param _strategy                 Struct of contract addresses
     * @param _methodology              Struct containing methodology parameters
     * @param _execution                Struct containing execution parameters
     * @param _incentive                Struct containing incentive parameters for ripcord
     * @param _exchange                 Struct containing exchange parameters
     */
    constructor(
        IBaseManager _manager,
        ContractSettings memory _strategy,
        MethodologySettings memory _methodology,
        ExecutionSettings memory _execution,
        IncentiveSettings memory _incentive,
        ExchangeSettings memory _exchange
    )
        public
        BaseExtension(_manager)
    {
        strategy = _strategy;
        methodology = _methodology;
        execution = _execution;
        incentive = _incentive;
        exchange = _exchange;

        collateralToken = strategy.basisTradingModule.collateralToken();
        collateralDecimals = ERC20(address(collateralToken)).decimals();

        _validateExchangeSettings(_exchange);
        _validateNonExchangeSettings(methodology, execution, incentive);

        // Set reinvest interval, so that first reinvestment takes place one reinvestment interval after deployment
        lastReinvestTimestamp = block.timestamp;
    }

    /* ============ External Functions ============ */

    /**
     * OEPRATOR ONLY: Deposits specified units of current USDC tokens not already being used as collateral into Perpetual Protocol.
     *
     * @param  _collateralUnits     Collateral to deposit in position units
     */
    function deposit(uint256 _collateralUnits) external onlyOperator {
        _deposit(_collateralUnits);
    }

    /**
     * OPERATOR ONLY: Withdraws specified units of USDC tokens from Perpetual Protocol and adds it as default position on the SetToken.
     *
     * @param  _collateralUnits     Collateral to withdraw in position units
     */
    function withdraw(uint256 _collateralUnits) external onlyOperator {
        _withdraw(_collateralUnits);
    }

    /**
     * OPERATOR ONLY: Engage to enter delta neutral position for the first time. SetToken will use 50% of the collateral token to acquire spot asset on Uniswapv3, and deposit
     * rest of the collateral token to PerpV2 to open a new short base token position on PerpV2 such that net exposure to the spot assetis zero. If total rebalance notional
     * is above max trade size, then TWAP is kicked off.
     * To complete engage if TWAP, any valid caller must call iterateRebalance until target is met.
     * Note: Unlike PerpV2LeverageStrategyExtension, `deposit()` should NOT be called before `engage()`.
     */
    function engage() external onlyOperator {
        LeverageInfo memory leverageInfo = _getAndValidateEngageInfo();

        // Calculate total rebalance units and kick off TWAP if above max trade size
        (
            int256 chunkRebalanceNotional,
            int256 totalRebalanceNotional
        ) = _calculateEngageRebalanceSize(leverageInfo, methodology.targetLeverageRatio);

        _executeEngageTrades(leverageInfo, chunkRebalanceNotional);

        _updateRebalanceState(
            chunkRebalanceNotional,
            totalRebalanceNotional,
            methodology.targetLeverageRatio
        );

        emit Engaged(
            leverageInfo.currentLeverageRatio,
            methodology.targetLeverageRatio,
            chunkRebalanceNotional,
            totalRebalanceNotional
        );
    }

    /**
     * ONLY EOA AND ALLOWED CALLER: Rebalance product. If |min leverage ratio| < |current leverage ratio| < |max leverage ratio|, then rebalance
     * can only be called once the rebalance interval has elapsed since last timestamp. If outside the max and min but below incentivized leverage ratio,
     * rebalance can be called anytime to bring leverage ratio back to the max or min bounds. The methodology will determine whether to delever or lever.
     * If levering up, SetToken increases the short position on PerpV2, withdraws collateral asset from PerpV2 and uses it to acquire more spot asset to keep
     * the position delta-neutral. If delevering, SetToken decreases the short position on PerpV2, sells spot asset on UniswapV3 and deposits the returned
     * collateral token to PerpV2 to collateralize the PerpV2 position.
     *
     * Note: If the calculated current leverage ratio is above the incentivized leverage ratio or in TWAP then rebalance cannot be called. Instead, you must call
     * ripcord() which is incentivized with a reward in Ether or iterateRebalance().
     */
    function rebalance() external onlyEOA onlyAllowedCaller(msg.sender) {
        LeverageInfo memory leverageInfo = _getAndValidateLeveragedInfo(
            execution.slippageTolerance,
            exchange.twapMaxTradeSize
        );

        _validateNormalRebalance(leverageInfo, methodology.rebalanceInterval, lastTradeTimestamp);
        _validateNonTWAP();

        int256 newLeverageRatio = _calculateNewLeverageRatio(leverageInfo.currentLeverageRatio);

        (
            int256 chunkRebalanceNotional,
            int256 totalRebalanceNotional
        ) = _handleRebalance(leverageInfo, newLeverageRatio);

        _updateRebalanceState(chunkRebalanceNotional, totalRebalanceNotional, newLeverageRatio);

        emit Rebalanced(
            leverageInfo.currentLeverageRatio,
            newLeverageRatio,
            chunkRebalanceNotional,
            totalRebalanceNotional
        );
    }

    /**
     * ONLY EOA AND ALLOWED CALLER: Iterate a rebalance when in TWAP. TWAP cooldown period must have elapsed. If price moves advantageously, then
     * exit without rebalancing and clear TWAP state. This function can only be called when |current leverage ratio| < |incentivized leverage ratio|
     * and in TWAP state.
     */
    function iterateRebalance() external onlyEOA onlyAllowedCaller(msg.sender) {
        LeverageInfo memory leverageInfo = _getAndValidateLeveragedInfo(
            execution.slippageTolerance,
            exchange.twapMaxTradeSize
        );

        _validateNormalRebalance(leverageInfo, execution.twapCooldownPeriod, lastTradeTimestamp);
        _validateTWAP();

        int256 chunkRebalanceNotional;
        int256 totalRebalanceNotional;
        if (!_isAdvantageousTWAP(leverageInfo.currentLeverageRatio)) {
            (chunkRebalanceNotional, totalRebalanceNotional) = _handleRebalance(leverageInfo, twapLeverageRatio);
        }

        // If not advantageous, then rebalance is skipped and chunk and total rebalance notional are both 0, which means TWAP state is cleared
        _updateIterateState(chunkRebalanceNotional, totalRebalanceNotional);

        emit RebalanceIterated(
            leverageInfo.currentLeverageRatio,
            twapLeverageRatio,
            chunkRebalanceNotional,
            totalRebalanceNotional
        );
    }

    /**
     * ONLY EOA: In case |current leverage ratio| > |incentivized leverage ratio|, the ripcord function can be called by anyone to return leverage ratio
     * back to the max leverage ratio. This function typically would only be called during times of high downside/upside volatility and / or normal keeper malfunctions. The
     * caller of ripcord() will receive a reward in Ether. The ripcord function uses it's own TWAP cooldown period, slippage tolerance and TWAP max trade size which are
     * typically looser than in regular rebalances. If chunk rebalance size is above max incentivized trade size, then caller must continue to call this function to pull
     * the leverage ratio under the incentivized leverage ratio. Incentivized TWAP cooldown period must have elapsed. The function iterateRebalance will not work.
     */
    function ripcord() external onlyEOA {
        LeverageInfo memory leverageInfo = _getAndValidateLeveragedInfo(
            incentive.incentivizedSlippageTolerance,
            exchange.incentivizedTwapMaxTradeSize
        );

        _validateRipcord(leverageInfo, lastTradeTimestamp);

        ( int256 chunkRebalanceNotional, ) = _calculateChunkRebalanceNotional(leverageInfo, methodology.maxLeverageRatio);

        _executeRebalanceTrades(leverageInfo, chunkRebalanceNotional);

        _updateRipcordState();

        uint256 etherTransferred = _transferEtherRewardToCaller(incentive.etherReward);

        emit RipcordCalled(
            leverageInfo.currentLeverageRatio,
            methodology.maxLeverageRatio,
            chunkRebalanceNotional,
            etherTransferred
        );
    }

    /**
     * OPERATOR ONLY: Close open baseToken position on Perpetual Protocol and sell spot assets. TWAP cooldown period must have elapsed. This can be used for upgrading or shutting down the strategy.
     * SetToken will sell all virtual base token positions into virtual USDC and all spot asset to the collateral token (USDC). It deposits the recieved USDC to PerpV2 to collateralize the Perpetual
     * position. If the chunk rebalance size is less than the total notional size, then this function will trade out of base and spot token position in one go. If chunk rebalance size is above max
     * trade size, then operator must continue to call this function to completely unwind position. The function iterateRebalance will not work.
     *
     * Note: If rebalancing is open to anyone disengage TWAP can be counter traded by a griefing party calling rebalance. Set anyoneCallable to false before disengage to prevent such attacks.
     */
    function disengage() external onlyOperator {
        LeverageInfo memory leverageInfo = _getAndValidateLeveragedInfo(
            execution.slippageTolerance,
            exchange.twapMaxTradeSize
        );

        _validateDisengage(lastTradeTimestamp);

        // Reduce leverage to 0
        int256 newLeverageRatio = 0;

        (
            int256 chunkRebalanceNotional,
            int256 totalRebalanceNotional
        ) = _calculateChunkRebalanceNotional(leverageInfo, newLeverageRatio);

        _executeRebalanceTrades(leverageInfo, chunkRebalanceNotional);

        _updateDisengageState();

        emit Disengaged(
            leverageInfo.currentLeverageRatio,
            newLeverageRatio,
            chunkRebalanceNotional,
            totalRebalanceNotional
        );
    }

    /**
     * ONLY EOA AND ALLOWED CALLER: Reinvests tracked settled funding to increase position. SetToken withdraws funding as collateral token using
     * PerpV2BasisTradingModule. It uses the collateral token to acquire more spot asset and deposit the rest to PerpV2 to increase short perp position.
     * It can only be called once the reinvest interval has elapsed since last reinvest timestamp. TWAP is not supported because reinvestment amounts
     * would be generally small.
     *
     * NOTE: Rebalance is prioritized over reinvestment. This function can not be called when leverage ratio is out of bounds. Call `rebalance()` instead.
     */
    function reinvest() external onlyEOA onlyAllowedCaller(msg.sender) {
        // Uses the same slippage tolerance and twap max trade size as rebalancing
        LeverageInfo memory leverageInfo = _getAndValidateLeveragedInfo(
            execution.slippageTolerance,
            exchange.twapMaxTradeSize
        );

        _validateReinvest(leverageInfo);

        _withdrawFunding(PreciseUnitMath.MAX_UINT_256);    // Pass MAX_UINT_256 to withdraw all funding.

        (
            uint256 totalReinvestNotional,
            uint256 spotReinvestNotional,
            uint256 spotBuyNotional
        ) = _calculateReinvestNotional(leverageInfo);

        require(totalReinvestNotional > 0, "Zero accrued funding");

        _executeReinvestTrades(leverageInfo, spotReinvestNotional, spotBuyNotional);

        _updateReinvestState();

        emit Reinvested(totalReinvestNotional, spotBuyNotional);
    }

    /**
     * OPERATOR ONLY: Set methodology settings and check new settings are valid. Note: Need to pass in existing parameters if only changing a few settings.
     * Must not be in a rebalance.
     *
     * @param _newMethodologySettings          Struct containing methodology parameters
     */
    function setMethodologySettings(MethodologySettings memory _newMethodologySettings) external onlyOperator noRebalanceInProgress {
        methodology = _newMethodologySettings;

        _validateNonExchangeSettings(methodology, execution, incentive);

        emit MethodologySettingsUpdated(
            methodology.targetLeverageRatio,
            methodology.minLeverageRatio,
            methodology.maxLeverageRatio,
            methodology.recenteringSpeed,
            methodology.rebalanceInterval,
            methodology.reinvestInterval,
            methodology.minReinvestUnits
        );
    }

    /**
     * OPERATOR ONLY: Set execution settings and check new settings are valid. Note: Need to pass in existing parameters if only changing a few settings.
     * Must not be in a rebalance.
     *
     * @param _newExecutionSettings          Struct containing execution parameters
     */
    function setExecutionSettings(ExecutionSettings memory _newExecutionSettings) external onlyOperator noRebalanceInProgress {
        execution = _newExecutionSettings;

        _validateNonExchangeSettings(methodology, execution, incentive);

        emit ExecutionSettingsUpdated(
            execution.twapCooldownPeriod,
            execution.slippageTolerance
        );
    }

    /**
     * OPERATOR ONLY: Set incentive settings and check new settings are valid. Note: Need to pass in existing parameters if only changing a few settings.
     * Must not be in a rebalance.
     *
     * @param _newIncentiveSettings          Struct containing incentive parameters
     */
    function setIncentiveSettings(IncentiveSettings memory _newIncentiveSettings) external onlyOperator noRebalanceInProgress {
        incentive = _newIncentiveSettings;

        _validateNonExchangeSettings(methodology, execution, incentive);

        emit IncentiveSettingsUpdated(
            incentive.etherReward,
            incentive.incentivizedLeverageRatio,
            incentive.incentivizedSlippageTolerance,
            incentive.incentivizedTwapCooldownPeriod
        );
    }

    /**
     * OPERATOR ONLY: Set exchange settings and check new settings are valid. Updating exchange settings during rebalances is allowed, as it is not possible
     * to enter an unexpected state while doing so. Note: Need to pass in existing parameters if only changing a few settings.
     *
     * @param _newExchangeSettings     Struct containing exchange parameters
     */
    function setExchangeSettings(ExchangeSettings memory _newExchangeSettings)
        external
        onlyOperator
    {
        _validateExchangeSettings(_newExchangeSettings);

        exchange = _newExchangeSettings;

        emit ExchangeSettingsUpdated(
            exchange.exchangeName,
            exchange.buyExactSpotTradeData,
            exchange.sellExactSpotTradeData,
            exchange.buySpotQuoteExactInputPath,
            exchange.twapMaxTradeSize,
            exchange.incentivizedTwapMaxTradeSize
        );
    }

    /**
     * OPERATOR ONLY: Withdraw entire balance of ETH in this contract to operator. Rebalance must not be in progress
     */
    function withdrawEtherBalance() external onlyOperator noRebalanceInProgress {
        msg.sender.transfer(address(this).balance);
    }

    receive() external payable {}

    /* ============ External Getter Functions ============ */

    /**
     * Get current leverage ratio. Current leverage ratio is defined as the sum of USD values of all SetToken open positions on Perp V2 divided by its
     * account value on PerpV2. Prices for base and quote asset are retrieved from the Chainlink Price Oracle.
     *
     * return currentLeverageRatio         Current leverage ratio in precise units (10e18)
     */
    function getCurrentLeverageRatio() public view returns(int256) {
        ActionInfo memory currentLeverageInfo = _createActionInfo();

        return _calculateCurrentLeverageRatio(currentLeverageInfo);
    }

    /**
     * Calculates the chunk rebalance size. This can be used by external contracts and keeper bots to track rebalances and fetch assets to be bought and sold.
     * Note: This function does not take into account timestamps, so it may return a nonzero value even when shouldRebalance would return ShouldRebalance.NONE
     * (since minimum delays have not elapsed).
     *
     * @return size                   Total notional chunk size. Measured in the asset that would be sold.
     * @return sellAssetOnPerp        Asset that would be sold during a rebalance on Perpetual protocol
     * @return buyAssetOnPerp         Asset that would be purchased during a rebalance on Perpetual protocol
     * @return sellAssetOnDex         Asset that would be sold during a rebalance on decentralized exchange
     * @return buyAssetOnDex          Asset that would be purchased during a rebalance on decentralized exchange
     */
    function getChunkRebalanceNotional()
        external
        view
        returns(int256 size, address sellAssetOnPerp, address buyAssetOnPerp, address sellAssetOnDex, address buyAssetOnDex)
    {

        int256 newLeverageRatio;
        int256 currentLeverageRatio = getCurrentLeverageRatio();
        bool isRipcord = false;

        // if over incentivized leverage ratio, always ripcord
        if (currentLeverageRatio.abs() > incentive.incentivizedLeverageRatio.abs()) {
            newLeverageRatio = methodology.maxLeverageRatio;
            isRipcord = true;
        // if we are in an ongoing twap, use the cached twapLeverageRatio as our target leverage
        } else if (twapLeverageRatio != 0) {
            newLeverageRatio = twapLeverageRatio;
        // if all else is false, then we would just use the normal rebalance new leverage ratio calculation
        } else {
            newLeverageRatio = _calculateNewLeverageRatio(currentLeverageRatio);
        }

        ActionInfo memory actionInfo = _createActionInfo();

        LeverageInfo memory leverageInfo = LeverageInfo({
            action: actionInfo,
            currentLeverageRatio: currentLeverageRatio,
            slippageTolerance: isRipcord ?
                incentive.incentivizedSlippageTolerance
                : execution.slippageTolerance,
            twapMaxTradeSize: isRipcord ?
                exchange.incentivizedTwapMaxTradeSize
                : exchange.twapMaxTradeSize
        });

        (size, ) = _calculateChunkRebalanceNotional(leverageInfo, newLeverageRatio);

        bool increaseLeverage = newLeverageRatio.abs() > currentLeverageRatio.abs();

        /*
        ------------------------------------------------------------------------------------------------------------------------
        |   New LR             |  increaseLeverage | sellAssetOnPerp |  buyAssetOnPerp | sellAssetOnDex    |  buyAssetOnDex    |
        ------------------------------------------------------------------------------------------------------------------------
        |   = 0 (not possible) |        x          |        x        |      x          |        x          |      x            |
        |   > 0 (not possible) |        x          |        x        |      x          |        x          |      x            |
        |   < 0  (short)       |       true        |  base (vETH)    |  quote (vUSD)   | collateral (USDC) |    spot (WETH)    |
        |   < 0  (short)       |       false       |  quote (vUSD)   |  base (vETH)    |     spot (WETH)   | collateral (USDC) |
        ------------------------------------------------------------------------------------------------------------------------
        */

        sellAssetOnPerp = increaseLeverage ? strategy.virtualBaseAddress : strategy.virtualQuoteAddress;
        buyAssetOnPerp = increaseLeverage ? strategy.virtualQuoteAddress : strategy.virtualBaseAddress;
        sellAssetOnDex = increaseLeverage ? address(collateralToken): strategy.spotAssetAddress;
        buyAssetOnDex = increaseLeverage ? strategy.spotAssetAddress : address(collateralToken);
    }

    /**
     * Get current Ether incentive for when current leverage ratio exceeds incentivized leverage ratio and ripcord can be called. If ETH balance on the contract
     * is below the etherReward, then return the balance of ETH instead.
     *
     * return etherReward               Quantity of ETH reward in base units (10e18)
     */
    function getCurrentEtherIncentive() external view returns(uint256) {
        int256 currentLeverageRatio = getCurrentLeverageRatio();

        if (currentLeverageRatio.abs() >= incentive.incentivizedLeverageRatio.abs()) {
            // If ETH reward is below the balance on this contract, then return ETH balance on contract instead
            return incentive.etherReward < address(this).balance ? incentive.etherReward : address(this).balance;
        } else {
            return 0;
        }
    }

    /**
     * Helper that checks if conditions are met for rebalance or ripcord. Returns an enum with 0 = no rebalance, 1 = call rebalance(), 2 = call iterateRebalance()
     * 3 = call ripcord() and 4 = call reinvest()
     *
     * @return ShouldRebalance      Enum representing whether should rebalance
     */
    function shouldRebalance() external view returns(ShouldRebalance) {
        int256 currentLeverageRatio = getCurrentLeverageRatio();

        return _shouldRebalance(currentLeverageRatio, methodology.minLeverageRatio, methodology.maxLeverageRatio);
    }

    /**
     * Helper that checks if conditions are met for rebalance or ripcord with custom max and min bounds specified by caller. This function simplifies the
     * logic for off-chain keeper bots to determine what threshold to call rebalance when leverage exceeds max or drops below min. Returns an enum with
     * 0 = no rebalance, 1 = call rebalance(), 2 = call iterateRebalance(), 3 = call ripcord() and 4 = call reinvest()
     *
     * @param _customMinLeverageRatio          Min leverage ratio passed in by caller
     * @param _customMaxLeverageRatio          Max leverage ratio passed in by caller
     *
     * @return ShouldRebalance      Enum representing whether should rebalance
     */
    function shouldRebalanceWithBounds(
        int256 _customMinLeverageRatio,
        int256 _customMaxLeverageRatio
    )
        external
        view
        returns(ShouldRebalance)
    {
        require (
            _customMinLeverageRatio.abs() <= methodology.minLeverageRatio.abs()
            && _customMaxLeverageRatio.abs() >= methodology.maxLeverageRatio.abs(),
            "Custom bounds must be valid"
        );

        int256 currentLeverageRatio = getCurrentLeverageRatio();

        return _shouldRebalance(currentLeverageRatio, _customMinLeverageRatio, _customMaxLeverageRatio);
    }

    /**
     * Explicit getter functions for parameter structs are defined as workaround to issues fetching structs that have dynamic types.
     */
    function getStrategy() external view returns (ContractSettings memory) { return strategy; }
    function getMethodology() external view returns (MethodologySettings memory) { return methodology; }
    function getExecution() external view returns (ExecutionSettings memory) { return execution; }
    function getIncentive() external view returns (IncentiveSettings memory) { return incentive; }
    function getExchangeSettings() external view returns (ExchangeSettings memory) { return exchange; }


    /* ============ Internal Functions ============ */

    /**
     * Deposits specified units of current USDC tokens not already being used as collateral into Perpetual Protocol.
     *
     * @param  _collateralUnits     Collateral to deposit in position units
     */
    function _deposit(uint256 _collateralUnits) internal {
        bytes memory depositCalldata = abi.encodeWithSelector(
            IPerpV2LeverageModuleV2.deposit.selector,
            address(strategy.setToken),
            _collateralUnits
        );

        invokeManager(address(strategy.basisTradingModule), depositCalldata);
    }

    /**
     * Deposits all current USDC tokens held in the Set to Perpetual Protocol.
     */
    function _depositAll() internal {
        uint256 defaultUsdcUnits = strategy.setToken.getDefaultPositionRealUnit(address(collateralToken)).toUint256();
        _deposit(defaultUsdcUnits);
    }

    /**
     * Withdraws specified units of USDC tokens from Perpetual Protocol and adds it as default position on the SetToken.
     *
     * @param  _collateralUnits     Collateral to withdraw in position units
     */
    function _withdraw(uint256 _collateralUnits) internal {
        bytes memory withdrawCalldata = abi.encodeWithSelector(
            IPerpV2LeverageModuleV2.withdraw.selector,
            address(strategy.setToken),
            _collateralUnits
        );

        invokeManager(address(strategy.basisTradingModule), withdrawCalldata);
    }

    /**
     * Calculates chunk rebalance notional and calls `_executeEngageTrades` to open required positions. Used in the rebalance() and iterateRebalance() functions
     *
     * return uint256           Calculated notional to trade
     * return uint256           Total notional to rebalance over TWAP
     */
    function _handleRebalance(LeverageInfo memory _leverageInfo, int256 _newLeverageRatio) internal returns(int256, int256) {
        (
            int256 chunkRebalanceNotional,
            int256 totalRebalanceNotional
        ) = _calculateChunkRebalanceNotional(_leverageInfo, _newLeverageRatio);

        _executeRebalanceTrades(_leverageInfo, chunkRebalanceNotional);

        return (chunkRebalanceNotional, totalRebalanceNotional);
    }

    /**
     * Calculate base rebalance units and opposite bound units. Invoke trade on TradeModule to acquire spot asset. Deposit rest of the collateral token to PerpV2
     * and invoke trade on PerpV2BasisTradingModule to open short perp position.
     */
    function _executeEngageTrades(
        LeverageInfo memory _leverageInfo,
        int256 _chunkRebalanceNotional
    )
        internal
    {
        int256 baseRebalanceUnits = _chunkRebalanceNotional.preciseDiv(_leverageInfo.action.setTotalSupply.toInt256());

        uint256 oppositeBoundUnits = _calculateOppositeBoundUnits(
            baseRebalanceUnits.neg(),
            _leverageInfo.action,
            _leverageInfo.slippageTolerance
        ).fromPreciseUnitToDecimals(collateralDecimals);

        _executeDexTrade(baseRebalanceUnits.abs(), oppositeBoundUnits, true);

        _depositAll();

        _executePerpTrade(baseRebalanceUnits, _leverageInfo);
    }

    /**
     * Calculate base rebalance units and opposite bound units. Invoke trade on PerpV2BasisTradingModule to lever/delever perp short position. If levering, withdraw
     * collateral token and invoke trade on TradeModule to acquire more spot assets. If delevering, invoke trade on TradeModule to sell spot assets and deposit the
     * recieved collateral token to PerpV2.
     */
    function _executeRebalanceTrades(
        LeverageInfo memory _leverageInfo,
        int256 _chunkRebalanceNotional
    )
        internal
    {
        int256 baseRebalanceUnits = _chunkRebalanceNotional.preciseDiv(_leverageInfo.action.setTotalSupply.toInt256());
        uint256 oppositeBoundUnits = _calculateOppositeBoundUnits(
            baseRebalanceUnits.neg(),
            _leverageInfo.action,
            _leverageInfo.slippageTolerance
        ).fromPreciseUnitToDecimals(collateralDecimals);

        _executePerpTrade(baseRebalanceUnits, _leverageInfo);

        if (baseRebalanceUnits < 0) {
            _withdraw(oppositeBoundUnits);

            _executeDexTrade(baseRebalanceUnits.abs(), oppositeBoundUnits, true);
        } else {
            _executeDexTrade(baseRebalanceUnits.abs(), oppositeBoundUnits, false);
        }

        // Deposit unused USDC during lever; Deposit received USDC during delever
        _depositAll();
    }

    /**
     * Executes trades on PerpV2.
     */
    function _executePerpTrade(int256 _baseRebalanceUnits, LeverageInfo memory _leverageInfo) internal {
        uint256 oppositeBoundUnits = _calculateOppositeBoundUnits(_baseRebalanceUnits, _leverageInfo.action, _leverageInfo.slippageTolerance);

        bytes memory perpTradeCallData = abi.encodeWithSelector(
            IPerpV2BasisTradingModule.tradeAndTrackFunding.selector,        // tradeAndTrackFunding
            address(strategy.setToken),
            strategy.virtualBaseAddress,
            _baseRebalanceUnits,
            oppositeBoundUnits
        );

        invokeManager(address(strategy.basisTradingModule), perpTradeCallData);
    }

    /**
     * Executes trades on Dex.
     * Note: Only supports Uniswap V3.
     */
    function _executeDexTrade(uint256 _baseUnits, uint256 _usdcUnits, bool _buy) internal {
        bytes memory dexTradeCallData = _buy
            ? abi.encodeWithSelector(
                ITradeModule.trade.selector,
                address(strategy.setToken),
                exchange.exchangeName,
                address(collateralToken),
                _usdcUnits,
                address(strategy.spotAssetAddress),
                _baseUnits,
                exchange.buyExactSpotTradeData      // buy exact amount
            )
            : abi.encodeWithSelector(
                ITradeModule.trade.selector,
                address(strategy.setToken),
                exchange.exchangeName,
                address(strategy.spotAssetAddress),
                _baseUnits,
                address(collateralToken),
                _usdcUnits,
                exchange.sellExactSpotTradeData     // sell exact amount
            );

        invokeManager(address(strategy.tradeModule), dexTradeCallData);
    }

    /**
     * Invokes PerpV2BasisTradingModule to withdraw funding to be reinvested. Pass MAX_UINT_256 to withdraw all funding.
     */
    function _withdrawFunding(uint256 _fundingNotional) internal {
        bytes memory withdrawCallData = abi.encodeWithSelector(
            IPerpV2BasisTradingModule.withdrawFundingAndAccrueFees.selector,
            strategy.setToken,
            _fundingNotional
        );

        invokeManager(address(strategy.basisTradingModule), withdrawCallData);
    }

    /**
     * Reinvests default USDC position to spot asset and deposits the rest to PerpV2 to increase the short perp position.
     * Used in the reinvest() function.
     */
    function _executeReinvestTrades(
        LeverageInfo memory _leverageInfo,
        uint256 _spotReinvestNotional,
        uint256 _spotBuyNotional
    ) internal {

        uint256 setTotalSupply = strategy.setToken.totalSupply();
        uint256 baseUnits = _spotBuyNotional.preciseDiv(setTotalSupply);
        uint256 spotReinvestUnits = _spotReinvestNotional.preciseDivCeil(setTotalSupply);

        // Increase spot position
        _executeDexTrade(baseUnits, spotReinvestUnits, true);

        // Deposit rest
        _depositAll();

        // Increase perp position
        _executePerpTrade(baseUnits.toInt256().neg(), _leverageInfo);
    }

    /* ============ Calculation functions ============ */

    /**
     * Calculate the current leverage ratio.
     *
     * return int256            Current leverage ratio
     */
    function _calculateCurrentLeverageRatio(ActionInfo memory _actionInfo) internal pure returns(int256) {
        /*
        Account Specs:
        -------------
        collateral:= balance of USDC in vault
        owedRealizedPnl:= realized PnL (in USD) that hasn't been settled
        pendingFundingPayment := funding payment (in USD) that hasn't been settled

        settling collateral (on withdraw)
            collateral <- collateral + owedRealizedPnL
            owedRealizedPnL <- 0

        settling funding (on every trade)
            owedRealizedPnL <- owedRealizedPnL + pendingFundingPayment
            pendingFundingPayment <- 0

        Note: Collateral balance, owedRealizedPnl and pendingFundingPayments belong to the entire account and
        NOT just the single market managed by this contract. So, while managing multiple positions across multiple
        markets via multiple separate extension contracts, `totalCollateralValue` should be counted only once.
        */
        int256 totalCollateralValue = _actionInfo.accountInfo.collateralBalance
            .add(_actionInfo.accountInfo.owedRealizedPnl)
            .add(_actionInfo.accountInfo.pendingFundingPayments);

        // Note: Both basePositionValue and quoteValue are values that belong to the single market managed by this contract.
        int256 unrealizedPnl = _actionInfo.basePositionValue.add(_actionInfo.quoteValue);

        int256 accountValue = totalCollateralValue.add(unrealizedPnl);

        if (accountValue <= 0) {
            return 0;
        }

        // `accountValue` is always positive. Do not use absolute value of basePositionValue in the below equation,
        //  to keep the sign of CLR same as that of basePositionValue.
        return _actionInfo.basePositionValue.preciseDiv(accountValue);
    }

    /**
     * Calculate the new leverage ratio. The methodology reduces the size of each rebalance by weighting
     * the current leverage ratio against the target leverage ratio by the recentering speed percentage. The lower the recentering speed, the slower
     * the leverage token will move towards the target leverage each rebalance.
     *
     * return int256          New leverage ratio
     */
    function _calculateNewLeverageRatio(int256 _currentLeverageRatio) internal view returns(int256) {
        // Convert int256 variables to uint256 prior to passing through methodology
        uint256 currentLeverageRatioAbs = _currentLeverageRatio.abs();
        uint256 targetLeverageRatioAbs = methodology.targetLeverageRatio.abs();
        uint256 maxLeverageRatioAbs = methodology.maxLeverageRatio.abs();
        uint256 minLeverageRatioAbs = methodology.minLeverageRatio.abs();

        // CLRt+1 = max(MINLR, min(MAXLR, CLRt * (1 - RS) + TLR * RS))
        // a: TLR * RS
        // b: (1- RS) * CLRt
        // c: (1- RS) * CLRt + TLR * RS
        // d: min(MAXLR, CLRt * (1 - RS) + TLR * RS)
        uint256 a = targetLeverageRatioAbs.preciseMul(methodology.recenteringSpeed);
        uint256 b = PreciseUnitMath.preciseUnit().sub(methodology.recenteringSpeed).preciseMul(currentLeverageRatioAbs);
        uint256 c = a.add(b);
        uint256 d = Math.min(c, maxLeverageRatioAbs);
        uint256 newLeverageRatio = Math.max(minLeverageRatioAbs, d);

        return _currentLeverageRatio > 0 ? newLeverageRatio.toInt256() : newLeverageRatio.toInt256().neg();
    }

    /**
     * Calculate total notional rebalance quantity and chunked rebalance quantity in base asset units for engaging the SetToken. Used in engage().
     * Leverage ratio (for the base asset) is zero before engage. We open a new base asset position with size equals to
     * (collateralBalance/2) * targetLeverageRatio / baseAssetPrice) to gain (targetLeverageRatio * collateralBalance/2) worth of exposure to the base asset.
     * Note: We can't use `_calculateChunkRebalanceNotional` function because CLR is 0 during engage and it would lead to a divison by zero error.
     *
     * return int256          Chunked rebalance notional in base asset units
     * return int256          Total rebalance notional in base asset units
     */
    function _calculateEngageRebalanceSize(
        LeverageInfo memory _leverageInfo,
        int256 _targetLeverageRatio
    )
        internal
        view
        returns (int256, int256)
    {
        // Let C be the total collateral available. Let c be the amount of collateral deposited to Perp to open perp position.
        // Then we acquire, (C - c) worth of spot position. To maintain delta neutrality, we short same amount on PerpV2.
        // So, TLR = (C - c) / c, or c = C / (1 + TLR)
        int256 collateralAmount = collateralToken.balanceOf(address(strategy.setToken))
            .preciseDiv(PreciseUnitMath.preciseUnit().add(methodology.targetLeverageRatio.abs()))
            .toPreciseUnitsFromDecimals(collateralDecimals)
            .toInt256();
        int256 totalRebalanceNotional = collateralAmount.preciseMul(_targetLeverageRatio).preciseDiv(_leverageInfo.action.basePrice);

        uint256 chunkRebalanceNotionalAbs = Math.min(totalRebalanceNotional.abs(), _leverageInfo.twapMaxTradeSize);

        return (
            // Return int256 chunkRebalanceNotional
            totalRebalanceNotional >= 0 ? chunkRebalanceNotionalAbs.toInt256() : chunkRebalanceNotionalAbs.toInt256().neg(),
            totalRebalanceNotional
        );
    }

    /**
     * Calculate total notional funding to be reinvested (in USD), notional funding to be reinvested into spot position
     * and notional amount of spot asset to be bought during reinvestment.
     *
     * return uint256          Total notional funding to be reinvested
     * return uint256          Notional funding to be reinvested into spot position
     * return uint256          Notional amount of spot asset to be bought during reinvestment
     */
    function _calculateReinvestNotional(LeverageInfo memory _leverageInfo) internal returns (uint256, uint256, uint256) {

        uint256 defaultUsdcUnits = strategy.setToken.getDefaultPositionRealUnit(address(collateralToken)).toUint256();

        if (defaultUsdcUnits == 0) { return (0, 0, 0); }

        uint256 setTotalSupply = strategy.setToken.totalSupply();
        uint256 totalReinvestNotional = defaultUsdcUnits.preciseMul(setTotalSupply);

        // Let C be the total collateral available. Let c be the amount of collateral deposited to Perp to open perp position.
        // Then we acquire, (C - c) worth of spot position. To maintain delta neutrality, we short same amount on PerpV2.
        // Also, we need to maintiain the same leverage ratio as CLR.
        // So, CLR = (C - c) / c, or c = C / (1 + CLR). And amount used to acquire spot, (C - c) = C * CLR / (1 + CLR)
        uint256 multiplicationFactor = _leverageInfo.currentLeverageRatio.abs()
            .preciseDiv(PreciseUnitMath.preciseUnit().add(_leverageInfo.currentLeverageRatio.abs()));

        uint256 spotReinvestNotional = totalReinvestNotional.preciseMul(multiplicationFactor);

        uint256 spotBuyNotional = strategy.quoter.quoteExactInput(exchange.buySpotQuoteExactInputPath, spotReinvestNotional);

        return (totalReinvestNotional, spotReinvestNotional, spotBuyNotional);
    }

    /**
     * Calculate total notional rebalance quantity and chunked rebalance quantity in base asset units.
     *
     * return int256          Chunked rebalance notional in base asset units
     * return int256          Total rebalance notional in base asset units
     */
    function _calculateChunkRebalanceNotional(
        LeverageInfo memory _leverageInfo,
        int256 _newLeverageRatio
    )
        internal
        pure
        returns (int256, int256)
    {
        // Calculate difference between new and current leverage ratio
        int256 leverageRatioDifference = _newLeverageRatio.sub(_leverageInfo.currentLeverageRatio);
        int256 denominator = _leverageInfo.currentLeverageRatio.preciseMul(PreciseUnitMath.preciseUnitInt().sub(_newLeverageRatio));
        int256 totalRebalanceNotional = leverageRatioDifference.preciseMul(_leverageInfo.action.baseBalance).preciseDiv(denominator);

        uint256 chunkRebalanceNotionalAbs = Math.min(totalRebalanceNotional.abs(), _leverageInfo.twapMaxTradeSize);
        return (
            // Return int256 chunkRebalanceNotional
            totalRebalanceNotional >= 0 ? chunkRebalanceNotionalAbs.toInt256() : chunkRebalanceNotionalAbs.toInt256().neg(),
            totalRebalanceNotional
        );
    }

    /**
     * Derive the quote token units for slippage tolerance. The units are calculated by the base token units multiplied by base asset price divided by quote
     * asset price. Output is measured to precise units (1e18).
     *
     * return int256           Position units to quote
     */
    function _calculateOppositeBoundUnits(
        int256 _baseRebalanceUnits,
        ActionInfo memory _actionInfo,
        uint256 _slippageTolerance
    )
        internal pure returns (uint256)
    {
        uint256 oppositeBoundUnits;
        if (_baseRebalanceUnits > 0) {
            oppositeBoundUnits = _baseRebalanceUnits
                .preciseMul(_actionInfo.basePrice)
                .preciseDiv(_actionInfo.quotePrice)
                .preciseMul(PreciseUnitMath.preciseUnit().add(_slippageTolerance).toInt256()).toUint256();
        } else {
            oppositeBoundUnits = _baseRebalanceUnits
                .neg()
                .preciseMul(_actionInfo.basePrice)
                .preciseDiv(_actionInfo.quotePrice)
                .preciseMul(PreciseUnitMath.preciseUnit().sub(_slippageTolerance).toInt256()).toUint256();
        }
        return oppositeBoundUnits;
    }

    /* ========== Action Info functions ============ */

    /**
     * Validate there are no deposits on Perpetual protocol and the Set is not already engaged. Create the leverage info struct to be used in engage.
     */
    function _getAndValidateEngageInfo() internal view returns(LeverageInfo memory) {
        ActionInfo memory engageInfo = _createActionInfo();

        // Check that there is zero position unit of USDC of collateral value. Allows to neglect dust amounts.
        require(
            engageInfo.accountInfo.collateralBalance.preciseDiv(engageInfo.setTotalSupply.toInt256()) == 0,
            "PerpV2 collateral balance must be 0"
        );

        return LeverageInfo({
            action: engageInfo,
            currentLeverageRatio: 0, // 0 position leverage
            slippageTolerance: execution.slippageTolerance,
            twapMaxTradeSize: exchange.twapMaxTradeSize
        });
    }

    /**
     * Create the leverage info struct to be used in internal functions.
     *
     * return LeverageInfo                Struct containing ActionInfo and other data
     */
    function _getAndValidateLeveragedInfo(uint256 _slippageTolerance, uint256 _maxTradeSize) internal view returns(LeverageInfo memory) {
        ActionInfo memory actionInfo = _createActionInfo();

        require(actionInfo.setTotalSupply > 0, "SetToken must have > 0 supply");

        // Get current leverage ratio
        int256 currentLeverageRatio = _calculateCurrentLeverageRatio(actionInfo);

        // This function is called during rebalance, iterateRebalance, ripcord and disengage.
        // Assert currentLeverageRatio is 0 as the set should be engaged before this function is called.
        require(currentLeverageRatio.abs() > 0, "Current leverage ratio must NOT be 0");

        return LeverageInfo({
            action: actionInfo,
            currentLeverageRatio: currentLeverageRatio,
            slippageTolerance: _slippageTolerance,
            twapMaxTradeSize: _maxTradeSize
        });
    }

    /**
     * Create the action info struct to be used in internal functions
     *
     * return ActionInfo                Struct containing data used by internal lever and delever functions
     */
    function _createActionInfo() internal view returns(ActionInfo memory) {
        ActionInfo memory rebalanceInfo;

        // Fetch base token prices from PerpV2 oracles and adjust them to 18 decimal places.
        // NOTE: The same basePrice is used for both the virtual and the spot asset.
        int256 rawBasePrice = strategy.baseUSDPriceOracle.getPrice(strategy.twapInterval).toInt256();
        rebalanceInfo.basePrice = rawBasePrice.mul((10 ** strategy.basePriceDecimalAdjustment).toInt256());

        // vUSD price is fixed to 1$
        rebalanceInfo.quotePrice = PreciseUnitMath.preciseUnit().toInt256();

        // Note: getTakerPositionSize returns zero if base balance is less than 10 wei
        rebalanceInfo.baseBalance = strategy.perpV2AccountBalance.getTakerPositionSize(address(strategy.setToken), strategy.virtualBaseAddress);

        // Note: Fetching quote balance associated with a single position and not the net quote balance
        rebalanceInfo.quoteBalance = strategy.perpV2AccountBalance.getTakerOpenNotional(address(strategy.setToken), strategy.virtualBaseAddress);

        rebalanceInfo.accountInfo = strategy.basisTradingModule.getAccountInfo(strategy.setToken);

        // In Perp v2, all virtual tokens have 18 decimals, therefore we do not need to make further adjustments to determine base valuation.
        rebalanceInfo.basePositionValue = rebalanceInfo.basePrice.preciseMul(rebalanceInfo.baseBalance);
        rebalanceInfo.quoteValue = rebalanceInfo.quoteBalance;

        rebalanceInfo.setTotalSupply = strategy.setToken.totalSupply();

        return rebalanceInfo;
    }

    /* =========== Udpate state functions ============= */

    /**
     * Update last trade timestamp and if chunk rebalance size is less than total rebalance notional, store new leverage ratio to kick off TWAP. Used in
     * the engage() and rebalance() functions
     */
    function _updateRebalanceState(
        int256 _chunkRebalanceNotional,
        int256 _totalRebalanceNotional,
        int256 _newLeverageRatio
    )
        internal
    {
        _updateLastTradeTimestamp();

        if (_chunkRebalanceNotional.abs() < _totalRebalanceNotional.abs()) {
            twapLeverageRatio = _newLeverageRatio;
        }
    }

    /**
     * Update last trade timestamp and if chunk rebalance size is equal to the total rebalance notional, end TWAP by clearing state. This function is used
     * in iterateRebalance()
     */
    function _updateIterateState(int256 _chunkRebalanceNotional, int256 _totalRebalanceNotional) internal {

        _updateLastTradeTimestamp();

        // If the chunk size is equal to the total notional meaning that rebalances are not chunked, then clear TWAP state.
        if (_chunkRebalanceNotional == _totalRebalanceNotional) {
            delete twapLeverageRatio;
        }
    }

    /**
     * Update last trade timestamp and if currently in a TWAP, delete the TWAP state. Used in the ripcord() function.
     */
    function _updateRipcordState() internal {

        _updateLastTradeTimestamp();

        // If TWAP leverage ratio is stored, then clear state. This may happen if we are currently in a TWAP rebalance, and the leverage ratio moves above the
        // incentivized threshold for ripcord.
        if (twapLeverageRatio != 0) {
            delete twapLeverageRatio;
        }
    }

    /**
     * Update last trade timestamp. Used in the disengage() function.
     */
    function _updateDisengageState() internal {
        _updateLastTradeTimestamp();
    }

    /**
     * Update last reinvest timestamp. Used in the reinvest() function.
     */
    function _updateReinvestState() internal {
        _updateLastReinvestTimestamp();
    }

    /**
     * Update lastTradeTimestamp value. This function updates the global trade timestamp so that the epoch rebalance can use the global timestamp.
     */
    function _updateLastTradeTimestamp() internal {
        lastTradeTimestamp = block.timestamp;
    }

    /**
     * Update lastReinvestTimestamp value.
     */
    function _updateLastReinvestTimestamp() internal {
        lastReinvestTimestamp = block.timestamp;
    }

    /* =========== Miscallaneous functions ============ */

    /**
     * Check if price has moved advantageously while in the midst of the TWAP rebalance. This means the current leverage ratio has moved over/under
     * the stored TWAP leverage ratio on lever/delever so there is no need to execute a rebalance. Used in iterateRebalance()
     *
     * return bool          True if price has moved advantageously, false otherwise
     */
    function _isAdvantageousTWAP(int256 _currentLeverageRatio) internal view returns (bool) {
        uint256 twapLeverageRatioAbs = twapLeverageRatio.abs();
        uint256 targetLeverageRatioAbs = methodology.targetLeverageRatio.abs();
        uint256 currentLeverageRatioAbs = _currentLeverageRatio.abs();

        return (
            (twapLeverageRatioAbs < targetLeverageRatioAbs && currentLeverageRatioAbs >= twapLeverageRatioAbs)
            || (twapLeverageRatioAbs > targetLeverageRatioAbs && currentLeverageRatioAbs <= twapLeverageRatioAbs)
        );
    }

    /**
     * Transfer ETH reward to caller of the ripcord function. If the ETH balance on this contract is less than required
     * incentive quantity, then transfer contract balance instead to prevent reverts.
     *
     * return uint256           Amount of ETH transferred to caller
     */
    function _transferEtherRewardToCaller(uint256 _etherReward) internal returns(uint256) {
        uint256 etherToTransfer = _etherReward < address(this).balance ? _etherReward : address(this).balance;

        msg.sender.transfer(etherToTransfer);

        return etherToTransfer;
    }

    /**
     * Internal function returning the ShouldRebalance enum used in shouldRebalance and shouldRebalanceWithBounds external getter functions
     *
     * return ShouldRebalance         Enum detailing whether to rebalance, iterateRebalance, ripcord or no action
     */
    function _shouldRebalance(
        int256 _currentLeverageRatio,
        int256 _minLeverageRatio,
        int256 _maxLeverageRatio
    )
        internal
        view
        returns(ShouldRebalance)
    {
        // Get absolute value of current leverage ratio
        uint256 currentLeverageRatioAbs = _currentLeverageRatio.abs();

        // If above ripcord threshold, then check if incentivized cooldown period has elapsed
        if (currentLeverageRatioAbs >= incentive.incentivizedLeverageRatio.abs()) {
            if (lastTradeTimestamp.add(incentive.incentivizedTwapCooldownPeriod) < block.timestamp) {
                return ShouldRebalance.RIPCORD;
            }
            return ShouldRebalance.NONE;
        }

        // If TWAP, then check if the cooldown period has elapsed
        if (twapLeverageRatio != 0) {
            if (lastTradeTimestamp.add(execution.twapCooldownPeriod) < block.timestamp) {
                return ShouldRebalance.ITERATE_REBALANCE;
            }
            return ShouldRebalance.NONE;
        }

        // If not TWAP, then check if the rebalance interval has elapsed OR current leverage is above max leverage OR current leverage is below
        // min leverage
        if (
            block.timestamp.sub(lastTradeTimestamp) > methodology.rebalanceInterval
            || currentLeverageRatioAbs > _maxLeverageRatio.abs()
            || currentLeverageRatioAbs < _minLeverageRatio.abs()
        ) {
            return ShouldRebalance.REBALANCE;
        }

        // Rebalancing is given priority over reinvestment. This might lead to scenarios where this function returns `ShouldRebalance.REINVEST` in
        // the current block and `ShouldRebalance.REBALANCE` in the next blocks. This might be due to two reasons
        // 1. The leverage ratio moves out of bounds in the next block.
        // - In this case, the `reinvest()` transaction sent by the keeper would revert with "Invalid leverage ratio". The keeper can send a new
        //   `rebalance()` transaction in the next blocks.
        // 2. The rebalance interval elapses in the next block.
        // - In this case, the `reinvest()` transaction would not revert. The keeper can SAFELY send the `rebalance()` transaction after the
        //   `reinvest()` transaction is mined.
        if (block.timestamp.sub(lastReinvestTimestamp) > methodology.reinvestInterval) {
            uint256 reinvestmentNotional = strategy.basisTradingModule.getUpdatedSettledFunding(strategy.setToken);
            uint256 setTotalSupply = strategy.setToken.totalSupply();
            uint256 reinvestUnits = reinvestmentNotional.fromPreciseUnitToDecimals(collateralDecimals).preciseDiv(setTotalSupply);

            if (reinvestUnits >= methodology.minReinvestUnits) {
                return ShouldRebalance.REINVEST;
            }
        }

        return ShouldRebalance.NONE;
    }

    /* =========== Validation Functions =========== */

    /**
     * Validate non-exchange settings in constructor and setters when updating.
     */
    function _validateNonExchangeSettings(
        MethodologySettings memory _methodology,
        ExecutionSettings memory _execution,
        IncentiveSettings memory _incentive
    )
        internal
        pure
    {
        uint256 minLeverageRatioAbs = _methodology.minLeverageRatio.abs();
        uint256 targetLeverageRatioAbs = _methodology.targetLeverageRatio.abs();
        uint256 maxLeverageRatioAbs = _methodology.maxLeverageRatio.abs();
        uint256 incentivizedLeverageRatioAbs = _incentive.incentivizedLeverageRatio.abs();

        require (
            _methodology.minLeverageRatio < 0 && minLeverageRatioAbs <= targetLeverageRatioAbs && minLeverageRatioAbs > 0,
            "Must be valid min leverage"
        );
        require (
            _methodology.maxLeverageRatio < 0 && maxLeverageRatioAbs >= targetLeverageRatioAbs,
            "Must be valid max leverage"
        );
        require(_methodology.targetLeverageRatio < 0, "Must be valid target leverage");
        require (
            _methodology.recenteringSpeed <= PreciseUnitMath.preciseUnit() && _methodology.recenteringSpeed > 0,
            "Must be valid recentering speed"
        );
        require(_methodology.minReinvestUnits > 0, "Must be valid min reinvest units");
        require (
            _execution.slippageTolerance <= PreciseUnitMath.preciseUnit(),
            "Slippage tolerance must be <100%"
        );
        require (
            _incentive.incentivizedSlippageTolerance <= PreciseUnitMath.preciseUnit(),
            "Incentivized slippage tolerance must be <100%"
        );
        require(_incentive.incentivizedLeverageRatio < 0, "Must be valid incentivized leverage ratio");
        require (
            incentivizedLeverageRatioAbs >= maxLeverageRatioAbs,
            "Incentivized leverage ratio must be > max leverage ratio"
        );
        require (
            _methodology.rebalanceInterval >= _execution.twapCooldownPeriod,
            "Rebalance interval must be greater than TWAP cooldown period"
        );
        require (
            _execution.twapCooldownPeriod >= _incentive.incentivizedTwapCooldownPeriod,
            "TWAP cooldown must be greater than incentivized TWAP cooldown"
        );
    }

    /**
     * Validate an ExchangeSettings struct settings.
     */
    function _validateExchangeSettings(ExchangeSettings memory _settings) internal view {
        require(
            keccak256(abi.encodePacked((_settings.exchangeName))) == keccak256(abi.encodePacked(("UniswapV3ExchangeAdapterV2"))),
            "Invalid exchange name"
        );
        require(_settings.twapMaxTradeSize != 0, "Max TWAP trade size must not be 0");
        require(
            _settings.twapMaxTradeSize <= _settings.incentivizedTwapMaxTradeSize,
            "Max TWAP trade size must not be greater than incentivized max TWAP trade size"
        );

        bytes memory data;

        // For a single hop trade, trade data bytes length is 44. 20 source/destination token address + 3 fees + 20 source/destination token
        // address + 1 fixInput bool. For multi-hop trades, trade data bytes length is greater than 44.
        // `buyExactSpotTradeData` is trade data for an exact output trade. And exact output paths are reversed in UniswapV3.
        data = _settings.buyExactSpotTradeData;
        require(
            data.length >= 44
            && data.toAddress(0) == strategy.spotAssetAddress
            && data.toAddress(data.length - 21) == address(collateralToken)
            && !data.toBool(data.length - 1),                           // FixIn is false; since exactOutput
            "Invalid buyExactSpotTradeData data"
        );

        // `sellExactSpotTradeData` is trade data for an exact input trade.
        data = _settings.sellExactSpotTradeData;
        require(
            data.length >= 44
            && data.toAddress(0) == strategy.spotAssetAddress
            && data.toAddress(data.length - 21) == address(collateralToken)
            && data.toBool(data.length - 1),                            // FixIn is true; since exactInput
            "Invalid sellExactSpotTradeData data"
        );

        data = _settings.buySpotQuoteExactInputPath;
        require(
            data.length >= 43                                           // No FixIn bool at end
            && data.toAddress(0) == address(collateralToken)
            && data.toAddress(data.length - 20) == strategy.spotAssetAddress,
            "Invalid buySpotQuoteExactInputPath data"
        );
    }

    /**
     * Validate that current leverage is below incentivized leverage ratio and cooldown / rebalance period has elapsed or outsize max/min bounds. Used
     * in rebalance() and iterateRebalance() functions
     */
    function _validateNormalRebalance(LeverageInfo memory _leverageInfo, uint256 _coolDown, uint256 _lastTradeTimestamp) internal view {
        uint256 currentLeverageRatioAbs = _leverageInfo.currentLeverageRatio.abs();
        require(currentLeverageRatioAbs < incentive.incentivizedLeverageRatio.abs(), "Must be below incentivized leverage ratio");
        require(
            block.timestamp.sub(_lastTradeTimestamp) > _coolDown
            || currentLeverageRatioAbs > methodology.maxLeverageRatio.abs()
            || currentLeverageRatioAbs < methodology.minLeverageRatio.abs(),
            "Cooldown not elapsed or not valid leverage ratio"
        );
    }

    /**
     * Validate that current leverage is above incentivized leverage ratio and incentivized cooldown period has elapsed in ripcord()
     */
    function _validateRipcord(LeverageInfo memory _leverageInfo, uint256 _lastTradeTimestamp) internal view {
        require(_leverageInfo.currentLeverageRatio.abs() >= incentive.incentivizedLeverageRatio.abs(), "Must be above incentivized leverage ratio");
        // If currently in the midst of a TWAP rebalance, ensure that the cooldown period has elapsed
        require(_lastTradeTimestamp.add(incentive.incentivizedTwapCooldownPeriod) < block.timestamp, "TWAP cooldown must have elapsed");
    }

    /**
     * Validate cooldown period has elapsed in disengage()
     */
    function _validateDisengage(uint256 _lastTradeTimestamp) internal view {
        require(_lastTradeTimestamp.add(execution.twapCooldownPeriod) < block.timestamp, "TWAP cooldown must have elapsed");
    }

    /**
     * Validate reinvest interval has elapsed  and valid leverage ratio. Called in the reinvest() function
     */
    function _validateReinvest(LeverageInfo memory _leverageInfo) internal view {
        uint256 currentLeverageRatioAbs = _leverageInfo.currentLeverageRatio.abs();
        require(block.timestamp.sub(methodology.reinvestInterval) > lastReinvestTimestamp, "Reinvestment interval not elapsed");
        require(
            currentLeverageRatioAbs < methodology.maxLeverageRatio.abs()
            && currentLeverageRatioAbs > methodology.minLeverageRatio.abs(),
            "Invalid leverage ratio"
        );
    }

    /**
     * Validate TWAP in the iterateRebalance() function
     */
    function _validateTWAP() internal view {
        require(twapLeverageRatio != 0, "Not in TWAP state");
    }

    /**
     * Validate not TWAP in the rebalance() function
     */
    function _validateNonTWAP() internal view {
        require(twapLeverageRatio == 0, "Must call iterate");
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: GPL-2.0-or-later
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity 0.6.10;

library BytesLib {
    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_start + _length >= _start, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
                case 0 {
                    // Get a location of some free memory and store it in tempBytes as
                    // Solidity does for memory variables.
                    tempBytes := mload(0x40)

                    // The first word of the slice result is potentially a partial
                    // word read from the original array. To read it, we calculate
                    // the length of that partial word and start copying that many
                    // bytes into the array. The first word we copy will start with
                    // data we don't care about, but the last `lengthmod` bytes will
                    // land at the beginning of the contents of the new array. When
                    // we're done copying, we overwrite the full first word with
                    // the actual length of the slice.
                    let lengthmod := and(_length, 31)

                    // The multiplication in the next line is necessary
                    // because when slicing multiples of 32 bytes (lengthmod == 0)
                    // the following copy loop was copying the origin's length
                    // and then ending prematurely not copying everything it should.
                    let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                    let end := add(mc, _length)

                    for {
                        // The multiplication in the next line has the same exact purpose
                        // as the one above.
                        let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                    } lt(mc, end) {
                        mc := add(mc, 0x20)
                        cc := add(cc, 0x20)
                    } {
                        mstore(mc, mload(cc))
                    }

                    mstore(tempBytes, _length)

                    //update free-memory pointer
                    //allocating the array padded to 32 bytes like the compiler does now
                    mstore(0x40, and(add(mc, 31), not(31)))
                }
                //if we want a zero-length slice let's just return a zero-length array
                default {
                    tempBytes := mload(0x40)
                    //zero out the 32 bytes slice we are about to return
                    //we need to do it because Solidity does not garbage collect
                    mstore(tempBytes, 0)

                    mstore(0x40, add(tempBytes, 0x20))
                }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_start + 20 >= _start, "toAddress_overflow");
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint24(bytes memory _bytes, uint256 _start) internal pure returns (uint24) {
        require(_start + 3 >= _start, "toUint24_overflow");
        require(_bytes.length >= _start + 3, "toUint24_outOfBounds");
        uint24 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }

        return tempUint;
    }
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

/**
 * @title BytesArrayUtils
 * @author Set Protocol
 *
 * Utility library to type cast bytes arrays. Extends BytesLib (external/contracts/uniswap/v3/lib/BytesLib.sol)
 * library functionality.
 */
library BytesArrayUtils {

    /**
     * Type cast byte to boolean.
     * @param _bytes        Bytes array
     * @param _start        Starting index
     * @return bool        Boolean value
     */
    function toBool(bytes memory _bytes, uint256 _start) internal pure returns (bool) {
        require(_start + 1 >= _start, "toBool_overflow");
        require(_bytes.length >= _start + 1, "toBool_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        require(tempUint <= 1, "Invalid bool data");     // Should be either 0 or 1

        return (tempUint == 0) ? false : true;
    }
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

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IPerpV2LeverageModuleV2 } from "./IPerpV2LeverageModuleV2.sol";
import { ISetToken } from "./ISetToken.sol";

/**
 * @title IPerpV2BasisTradingModule
 * @author Set Protocol
 *
 * Interface for the PerpV2BasisTradingModule. Only specifies Manager permissioned functions, events
 * and getters. PerpV2BasisTradingModule also inherits from ModuleBaseV2 and SetTokenAccessible which support
 * additional methods.
 */
interface IPerpV2BasisTradingModule is IPerpV2LeverageModuleV2 {

    /* ============ Structs ============ */

    struct FeeState {
        address feeRecipient;                     // Address to accrue fees to
        uint256 maxPerformanceFeePercentage;      // Max performance fee manager commits to using (1% = 1e16, 100% = 1e18)
        uint256 performanceFeePercentage;         // Performance fees accrued to manager (1% = 1e16, 100% = 1e18)
    }

    /* ============ Events ============ */

    /**
     * @dev Emitted on performance fee update
     * @param _setToken             Instance of SetToken
     * @param _newPerformanceFee    New performance fee percentage (1% = 1e16)
     */
    event PerformanceFeeUpdated(ISetToken indexed _setToken, uint256 _newPerformanceFee);

    /**
     * @dev Emitted on fee recipient update
     * @param _setToken             Instance of SetToken
     * @param _newFeeRecipient      New performance fee recipient
     */
    event FeeRecipientUpdated(ISetToken indexed _setToken, address _newFeeRecipient);

    /**
     * @dev Emitted on funding withdraw
     * @param _setToken             Instance of SetToken
     * @param _collateralToken      Token being withdrawn as funding (USDC)
     * @param _amountWithdrawn      Amount of funding being withdrawn from Perp (USDC)
     * @param _managerFee           Amount of performance fee accrued to manager (USDC)
     * @param _protocolFee          Amount of performance fee accrued to protocol (USDC)
     */
    event FundingWithdrawn(
        ISetToken indexed  _setToken,
        IERC20 _collateralToken,
        uint256 _amountWithdrawn,
        uint256 _managerFee,
        uint256 _protocolFee
    );

    /* ============ State Variable Getters ============ */

    // Mapping to store fee settings for each SetToken
    function feeSettings(ISetToken _setToken) external view returns(FeeState memory);

    // Mapping to store funding that has been settled on Perpetual Protocol due to actions via this module
    // and hasn't been withdrawn for reinvesting yet. Values are stored in precise units (10e18).
    function settledFunding(ISetToken _settledFunding) external view returns (uint256);

    /* ============ External Functions ============ */

    /**
     * @dev MANAGER ONLY: Initializes this module to the SetToken and sets fee settings. Either the SetToken needs to
     * be on the allowed list or anySetAllowed needs to be true.
     *
     * @param _setToken             Instance of the SetToken to initialize
     */
    function initialize(
        ISetToken _setToken,
        FeeState memory _settings
    )
        external;

    /**
     * @dev MANAGER ONLY: Similar to PerpV2LeverageModuleV2#trade. Allows manager to buy or sell perps to change exposure
     * to the underlying baseToken. Any pending funding that would be settled during opening a position on Perpetual
     * protocol is added to (or subtracted from) `settledFunding[_setToken]` and can be withdrawn later using
     * `withdrawFundingAndAccrueFees` by the SetToken manager.
     * NOTE: Calling a `nonReentrant` function from another `nonReentrant` function is not supported. Hence, we can't
     * add the `nonReentrant` modifier here because `PerpV2LeverageModuleV2#trade` function has a reentrancy check.
     * NOTE: This method doesn't update the externalPositionUnit because it is a function of UniswapV3 virtual
     * token market prices and needs to be generated on the fly to be meaningful.
     *
     * @param _setToken                     Instance of the SetToken
     * @param _baseToken                    Address virtual token being traded
     * @param _baseQuantityUnits            Quantity of virtual token to trade in position units
     * @param _quoteBoundQuantityUnits      Max/min of vQuote asset to pay/receive when buying or selling
     */
    function tradeAndTrackFunding(
        ISetToken _setToken,
        address _baseToken,
        int256 _baseQuantityUnits,
        uint256 _quoteBoundQuantityUnits
    )
        external;

    /**
     * @dev MANAGER ONLY: Withdraws tracked settled funding (in USDC) from the PerpV2 Vault to a default position
     * on the SetToken. Collects manager and protocol performance fees on the withdrawn amount.
     * This method is useful when withdrawing funding to be reinvested into the Basis Trading product.
     *
     * NOTE: Within PerpV2, `withdraw` settles `owedRealizedPnl` and any pending funding payments
     * to the Perp vault prior to transfer.
     *
     * @param _setToken                 Instance of the SetToken
     * @param _notionalFunding          Notional amount of funding to withdraw (in USDC decimals)
     */
    function withdrawFundingAndAccrueFees(
        ISetToken _setToken,
        uint256 _notionalFunding
    )
        external;

    /* ============ External Setter Functions ============ */

    /**
     * @dev MANAGER ONLY. Update performance fee percentage.
     *
     * @param _setToken         Instance of SetToken
     * @param _newFee           New performance fee percentage in precise units (1e16 = 1%)
     */
    function updatePerformanceFee(
        ISetToken _setToken,
        uint256 _newFee
    )
        external;

    /**
     * @dev MANAGER ONLY. Update performance fee recipient (address to which performance fees are sent).
     *
     * @param _setToken             Instance of SetToken
     * @param _newFeeRecipient      Address of new fee recipient
     */
    function updateFeeRecipient(ISetToken _setToken, address _newFeeRecipient)
        external;

    /* ============ External Getter Functions ============ */

    /**
     * @dev Adds pending funding payment to tracked settled funding. Returns updated settled funding value in precise units (10e18).
     *
     * NOTE: Tracked settled funding value can not be less than zero, hence it is reset to zero if pending funding
     * payment is negative and |pending funding payment| >= |settledFunding[_setToken]|.
     *
     * NOTE: Returned updated settled funding value is correct only for the current block since pending funding payment
     * updates every block.
     *
     * @param _setToken             Instance of SetToken
     */
    function getUpdatedSettledFunding(ISetToken _setToken) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;

/// @title Quoter Interface
/// @notice Supports quoting the calculated amounts from exact input or exact output swaps
/// @dev These functions are not marked view because they rely on calling non-view functions and reverting
/// to compute the result. They are also not gas efficient and should not be called on-chain.
interface IUniswapV3Quoter {
    /// @notice Returns the amount out received for a given exact input swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee
    /// @param amountIn The amount of the first token to swap
    /// @return amountOut The amount of the last token that would be received
    function quoteExactInput(bytes memory path, uint256 amountIn) external returns (uint256 amountOut);

    /// @notice Returns the amount out received for a given exact input but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountIn The desired input amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountOut The amount of `tokenOut` that would be received
    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);

    /// @notice Returns the amount in required for a given exact output swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee. Path must be provided in reverse order
    /// @param amountOut The amount of the last token to receive
    /// @return amountIn The amount of first token required to be paid
    function quoteExactOutput(bytes memory path, uint256 amountOut) external returns (uint256 amountIn);

    /// @notice Returns the amount in required to receive the given exact output amount but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountOut The desired output amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountIn The amount required as the input for the swap in order to receive `amountOut`
    function quoteExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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

import { BaseExtension } from "../lib/BaseExtension.sol";
import { IBaseManager } from "../interfaces/IBaseManager.sol";

contract BaseExtensionMock is BaseExtension {

    constructor(IBaseManager _manager) public BaseExtension(_manager) {}

    /* ============ External Functions ============ */

    function testInvokeManager(address _module, bytes calldata _encoded) external {
        invokeManager(_module, _encoded);
    }

    function testOnlyOperator()
        external
        onlyOperator
    {}

    function testOnlyMethodologist()
        external
        onlyMethodologist
    {}

    function testOnlyEOA()
        external
        onlyEOA
    {}

    function testOnlyAllowedCaller(address _caller)
        external
        onlyAllowedCaller(_caller)
    {}

    function interactManager(address _target, bytes calldata _data) external {
        invokeManager(_target, _data);
    }
}

/*
    Copyright 2021 IndexCooperative

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
pragma experimental ABIEncoderV2;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

import { ISetToken } from "@setprotocol/set-protocol-v2/contracts/interfaces/ISetToken.sol";
import { PreciseUnitMath } from "@setprotocol/set-protocol-v2/contracts/lib/PreciseUnitMath.sol";
import { IIssuanceModule } from "@setprotocol/set-protocol-v2/contracts/interfaces/IIssuanceModule.sol";
import { IStreamingFeeModule } from "@setprotocol/set-protocol-v2/contracts/interfaces/IStreamingFeeModule.sol";

import { BaseExtension } from "../lib/BaseExtension.sol";
import { IBaseManager } from "../interfaces/IBaseManager.sol";
import { TimeLockUpgrade } from "../lib/TimeLockUpgrade.sol";


/**
 * @title FeeSplitExtension
 * @author Set Protocol
 *
 * Smart contract extension that allows for splitting and setting streaming and mint/redeem fees.
 */
contract FeeSplitExtension is BaseExtension, TimeLockUpgrade {
    using Address for address;
    using PreciseUnitMath for uint256;
    using SafeMath for uint256;

    /* ============ Events ============ */

    event FeesDistributed(
        address indexed _operatorFeeRecipient,
        address indexed _methodologist,
        uint256 _operatorTake,
        uint256 _methodologistTake
    );

    /* ============ State Variables ============ */

    ISetToken public setToken;
    IStreamingFeeModule public streamingFeeModule;
    IIssuanceModule public issuanceModule;

    // Percent of fees in precise units (10^16 = 1%) sent to operator, rest to methodologist
    uint256 public operatorFeeSplit;

    // Address which receives operator's share of fees when they're distributed. (See IIP-72)
    address public operatorFeeRecipient;

    /* ============ Constructor ============ */

    constructor(
        IBaseManager _manager,
        IStreamingFeeModule _streamingFeeModule,
        IIssuanceModule _issuanceModule,
        uint256 _operatorFeeSplit,
        address _operatorFeeRecipient
    )
        public
        BaseExtension(_manager)
    {
        streamingFeeModule = _streamingFeeModule;
        issuanceModule = _issuanceModule;
        operatorFeeSplit = _operatorFeeSplit;
        operatorFeeRecipient = _operatorFeeRecipient;
        setToken = manager.setToken();
    }

    /* ============ External Functions ============ */

    /**
     * ANYONE CALLABLE: Accrues fees from streaming fee module. Gets resulting balance after fee accrual, calculates fees for
     * operator and methodologist, and sends to operator fee recipient and methodologist respectively. NOTE: mint/redeem fees
     * will automatically be sent to this address so reading the balance of the SetToken in the contract after accrual is
     * sufficient for accounting for all collected fees.
     */
    function accrueFeesAndDistribute() public {
        // Emits a FeeActualized event
        streamingFeeModule.accrueFee(setToken);

        uint256 totalFees = setToken.balanceOf(address(this));

        address methodologist = manager.methodologist();

        uint256 operatorTake = totalFees.preciseMul(operatorFeeSplit);
        uint256 methodologistTake = totalFees.sub(operatorTake);

        if (operatorTake > 0) {
            setToken.transfer(operatorFeeRecipient, operatorTake);
        }

        if (methodologistTake > 0) {
            setToken.transfer(methodologist, methodologistTake);
        }

        emit FeesDistributed(operatorFeeRecipient, methodologist, operatorTake, methodologistTake);
    }

    /**
     * ONLY OPERATOR: Updates streaming fee on StreamingFeeModule.
     * Because the method is timelocked, each party must call it twice: once to set the lock and once to execute.
     *
     * Method is timelocked to protect token owners from sudden changes in fee structure which
     * they would rather not bear. The delay gives them a chance to exit their positions without penalty.
     *
     * NOTE: This will accrue streaming fees though not send to operator fee recipient and methodologist.
     *
     * @param _newFee       Percent of Set accruing to fee extension annually (1% = 1e16, 100% = 1e18)
     */
    function updateStreamingFee(uint256 _newFee)
        external
        onlyOperator
        timeLockUpgrade
    {
        bytes memory callData = abi.encodeWithSignature("updateStreamingFee(address,uint256)", manager.setToken(), _newFee);
        invokeManager(address(streamingFeeModule), callData);
    }

    /**
     * ONLY OPERATOR: Updates issue fee on IssuanceModule. Only is executed once time lock has passed.
     * Because the method is timelocked, each party must call it twice: once to set the lock and once to execute.
     *
     * Method is timelocked to protect token owners from sudden changes in fee structure which
     * they would rather not bear. The delay gives them a chance to exit their positions without penalty.
     *
     * @param _newFee           New issue fee percentage in precise units (1% = 1e16, 100% = 1e18)
     */
    function updateIssueFee(uint256 _newFee)
        external
        onlyOperator
        timeLockUpgrade
    {
        bytes memory callData = abi.encodeWithSignature("updateIssueFee(address,uint256)", manager.setToken(), _newFee);
        invokeManager(address(issuanceModule), callData);
    }

    /**
     * ONLY OPERATOR: Updates redeem fee on IssuanceModule. Only is executed once time lock has passed.
     * Because the method is timelocked, each party must call it twice: once to set the lock and once to execute.
     *
     * Method is timelocked to protect token owners from sudden changes in fee structure which
     * they would rather not bear. The delay gives them a chance to exit their positions without penalty.
     *
     * @param _newFee           New redeem fee percentage in precise units (1% = 1e16, 100% = 1e18)
     */
    function updateRedeemFee(uint256 _newFee)
        external
        onlyOperator
        timeLockUpgrade
    {
        bytes memory callData = abi.encodeWithSignature("updateRedeemFee(address,uint256)", manager.setToken(), _newFee);
        invokeManager(address(issuanceModule), callData);
    }

    /**
     * ONLY OPERATOR: Updates fee recipient on both streaming fee and issuance modules.
     *
     * @param _newFeeRecipient  Address of new fee recipient. This should be the address of the fee extension itself.
     */
    function updateFeeRecipient(address _newFeeRecipient)
        external
        onlyOperator
    {
        bytes memory callData = abi.encodeWithSignature("updateFeeRecipient(address,address)", manager.setToken(), _newFeeRecipient);
        invokeManager(address(streamingFeeModule), callData);
        invokeManager(address(issuanceModule), callData);
    }

    /**
     * ONLY OPERATOR: Updates fee split between operator and methodologist. Split defined in precise units (1% = 10^16).
     *
     * @param _newFeeSplit      Percent of fees in precise units (10^16 = 1%) sent to operator, (rest go to the methodologist).
     */
    function updateFeeSplit(uint256 _newFeeSplit)
        external
        onlyOperator
    {
        require(_newFeeSplit <= PreciseUnitMath.preciseUnit(), "Fee must be less than 100%");
        accrueFeesAndDistribute();
        operatorFeeSplit = _newFeeSplit;
    }

    /**
     * ONLY OPERATOR: Updates the address that receives the operator's fees (see IIP-72)
     *
     * @param _newOperatorFeeRecipient  Address to send operator's fees to.
     */
    function updateOperatorFeeRecipient(address _newOperatorFeeRecipient)
        external
        onlyOperator
    {
        require(_newOperatorFeeRecipient != address(0), "Zero address not valid");
        operatorFeeRecipient = _newOperatorFeeRecipient;
    }
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

import { ISetToken } from "./ISetToken.sol";

/**
 * @title IIssuanceModule
 * @author Set Protocol
 *
 * Interface for interacting with Issuance module interface.
 */
interface IIssuanceModule {
    function updateIssueFee(ISetToken _setToken, uint256 _newIssueFee) external;
    function updateRedeemFee(ISetToken _setToken, uint256 _newRedeemFee) external;
    function updateFeeRecipient(ISetToken _setToken, address _newRedeemFee) external;

    function initialize(
        ISetToken _setToken,
        uint256 _maxManagerFee,
        uint256 _managerIssueFee,
        uint256 _managerRedeemFee,
        address _feeRecipient,
        address _managerIssuanceHook
    ) external;
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

import { ISetToken } from "./ISetToken.sol";

interface IStreamingFeeModule {
    struct FeeState {
        address feeRecipient;
        uint256 maxStreamingFeePercentage;
        uint256 streamingFeePercentage;
        uint256 lastStreamingFeeTimestamp;
    }

    function feeStates(ISetToken _setToken) external view returns (FeeState memory);
    function getFee(ISetToken _setToken) external view returns (uint256);
    function accrueFee(ISetToken _setToken) external;
    function updateStreamingFee(ISetToken _setToken, uint256 _newFee) external;
    function updateFeeRecipient(ISetToken _setToken, address _newFeeRecipient) external;
    function initialize(ISetToken _setToken, FeeState memory _settings) external;
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

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @title TimeLockUpgrade
 * @author Set Protocol
 *
 * The TimeLockUpgrade contract contains a modifier for handling minimum time period updates
 */
contract TimeLockUpgrade is
    Ownable
{
    using SafeMath for uint256;

    /* ============ State Variables ============ */

    // Timelock Upgrade Period in seconds
    uint256 public timeLockPeriod;

    // Mapping of upgradable units and initialized timelock
    mapping(bytes32 => uint256) public timeLockedUpgrades;

    /* ============ Events ============ */

    event UpgradeRegistered(
        bytes32 _upgradeHash,
        uint256 _timestamp
    );

    /* ============ Modifiers ============ */

    modifier timeLockUpgrade() {
        // If the time lock period is 0, then allow non-timebound upgrades.
        // This is useful for initialization of the protocol and for testing.
        if (timeLockPeriod == 0) {
            _;

            return;
        }

        // The upgrade hash is defined by the hash of the transaction call data,
        // which uniquely identifies the function as well as the passed in arguments.
        bytes32 upgradeHash = keccak256(
            abi.encodePacked(
                msg.data
            )
        );

        uint256 registrationTime = timeLockedUpgrades[upgradeHash];

        // If the upgrade hasn't been registered, register with the current time.
        if (registrationTime == 0) {
            timeLockedUpgrades[upgradeHash] = block.timestamp;

            emit UpgradeRegistered(
                upgradeHash,
                block.timestamp
            );

            return;
        }

        require(
            block.timestamp >= registrationTime.add(timeLockPeriod),
            "TimeLockUpgrade: Time lock period must have elapsed."
        );

        // Reset the timestamp to 0
        timeLockedUpgrades[upgradeHash] = 0;

        // Run the rest of the upgrades
        _;
    }

    /* ============ Function ============ */

    /**
     * Change timeLockPeriod period. Generally called after initially settings have been set up.
     *
     * @param  _timeLockPeriod   Time in seconds that upgrades need to be evaluated before execution
     */
    function setTimeLockPeriod(
        uint256 _timeLockPeriod
    )
        virtual
        external
        onlyOwner
    {
        // Only allow setting of the timeLockPeriod if the period is greater than the existing
        require(
            _timeLockPeriod > timeLockPeriod,
            "TimeLockUpgrade: New period must be greater than existing"
        );

        timeLockPeriod = _timeLockPeriod;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/Context.sol";
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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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

import { ISetToken } from "@setprotocol/set-protocol-v2/contracts/interfaces/ISetToken.sol";

import { IGlobalExtension } from "../interfaces/IGlobalExtension.sol";

contract ManagerMock {
    ISetToken public immutable setToken;

    constructor(
        ISetToken _setToken
    )
        public
    {
        setToken = _setToken;
    }

    function removeExtensions(address[] memory _extensions) external {
        for (uint256 i = 0; i < _extensions.length; i++) {
            address extension = _extensions[i];
            IGlobalExtension(extension).removeExtension();
        }
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

interface IGlobalExtension {
    function removeExtension() external;
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

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import { AddressArrayUtils } from "@setprotocol/set-protocol-v2/contracts/lib/AddressArrayUtils.sol";
import { ISetToken } from "@setprotocol/set-protocol-v2/contracts/interfaces/ISetToken.sol";
import { PreciseUnitMath } from "@setprotocol/set-protocol-v2/contracts/lib/PreciseUnitMath.sol";

import { IGlobalExtension } from "../interfaces/IGlobalExtension.sol";
import { MutualUpgradeV2 } from "../lib/MutualUpgradeV2.sol";


/**
 * @title DelegatedManager
 * @author Set Protocol
 *
 * Smart contract manager that maintains permissions and SetToken admin functionality via owner role. Owner
 * works alongside methodologist to ensure business agreements are kept. Owner is able to delegate maintenance
 * operations to operator(s). There can be more than one operator, however they have a global role so once
 * delegated to they can perform any operator delegated roles. The owner is able to set restrictions on what
 * operators can do in the form of asset whitelists. Operators cannot trade/wrap/claim/etc. an asset that is not
 * a part of the asset whitelist, hence they are a semi-trusted party. It is recommended that the owner address
 * be managed by a multi-sig or some form of permissioning system.
 */
contract DelegatedManager is Ownable, MutualUpgradeV2 {
    using Address for address;
    using AddressArrayUtils for address[];
    using SafeERC20 for IERC20;

    /* ============ Enums ============ */

    enum ExtensionState {
        NONE,
        PENDING,
        INITIALIZED
    }

    /* ============ Events ============ */

    event MethodologistChanged(
        address indexed _newMethodologist
    );

    event ExtensionAdded(
        address indexed _extension
    );

    event ExtensionRemoved(
        address indexed _extension
    );

    event ExtensionInitialized(
        address indexed _extension
    );

    event OperatorAdded(
        address indexed _operator
    );

    event OperatorRemoved(
        address indexed _operator
    );

    event AllowedAssetAdded(
        address indexed _asset
    );

    event AllowedAssetRemoved(
        address indexed _asset
    );

    event UseAssetAllowlistUpdated(
        bool _status
    );

    event OwnerFeeSplitUpdated(
        uint256 _newFeeSplit
    );

    event OwnerFeeRecipientUpdated(
        address indexed _newFeeRecipient
    );

    /* ============ Modifiers ============ */

    /**
     * Throws if the sender is not the SetToken methodologist
     */
    modifier onlyMethodologist() {
        require(msg.sender == methodologist, "Must be methodologist");
        _;
    }

    /**
     * Throws if the sender is not an initialized extension
     */
    modifier onlyExtension() {
        require(extensionAllowlist[msg.sender] == ExtensionState.INITIALIZED, "Must be initialized extension");
        _;
    }

    /* ============ State Variables ============ */

    // Instance of SetToken
    ISetToken public immutable setToken;

    // Address of factory contract used to deploy contract
    address public immutable factory;

    // Mapping to check which ExtensionState a given extension is in
    mapping(address => ExtensionState) public extensionAllowlist;

    // Array of initialized extensions
    address[] internal extensions;

    // Mapping indicating if address is an approved operator
    mapping(address=>bool) public operatorAllowlist;

    // List of approved operators
    address[] internal operators;

    // Mapping indicating if asset is approved to be traded for, wrapped into, claimed, etc.
    mapping(address=>bool) public assetAllowlist;

    // List of allowed assets
    address[] internal allowedAssets;

    // Toggle if asset allow list is being enforced
    bool public useAssetAllowlist;

    // Global owner fee split that can be referenced by Extensions
    uint256 public ownerFeeSplit;

    // Address owners portions of fees get sent to
    address public ownerFeeRecipient;

    // Address of methodologist which serves as providing methodology for the index and receives fee splits
    address public methodologist;

    /* ============ Constructor ============ */

    constructor(
        ISetToken _setToken,
        address _factory,
        address _methodologist,
        address[] memory _extensions,
        address[] memory _operators,
        address[] memory _allowedAssets,
        bool _useAssetAllowlist
    )
        public
    {
        setToken = _setToken;
        factory = _factory;
        methodologist = _methodologist;
        useAssetAllowlist = _useAssetAllowlist;
        emit UseAssetAllowlistUpdated(_useAssetAllowlist);

        _addExtensions(_extensions);
        _addOperators(_operators);
        _addAllowedAssets(_allowedAssets);
    }

    /* ============ External Functions ============ */

    /**
     * ONLY EXTENSION: Interact with a module registered on the SetToken. In order to ensure SetToken admin
     * functions can only be changed from this contract no calls to the SetToken can originate from Extensions.
     * To transfer SetTokens use the `transferTokens` function.
     *
     * @param _module           Module to interact with
     * @param _data             Byte data of function to call in module
     */
    function interactManager(address _module, bytes calldata _data) external onlyExtension {
        require(_module != address(setToken), "Extensions cannot call SetToken");
        // Invoke call to module, assume value will always be 0
        _module.functionCallWithValue(_data, 0);
    }

    /**
     * EXTENSION ONLY: Transfers _tokens held by the manager to _destination. Can be used to
     * distribute fees or recover anything sent here accidentally.
     *
     * @param _token           ERC20 token to send
     * @param _destination     Address receiving the tokens
     * @param _amount          Quantity of tokens to send
     */
    function transferTokens(address _token, address _destination, uint256 _amount) external onlyExtension {
        IERC20(_token).safeTransfer(_destination, _amount);
    }

    /**
     * Initializes an added extension from PENDING to INITIALIZED state and adds to extension array. An
     * address can only enter a PENDING state if it is an enabled extension added by the manager. Only
     * callable by the extension itself, hence msg.sender is the subject of update.
     */
    function initializeExtension() external {
        require(extensionAllowlist[msg.sender] == ExtensionState.PENDING, "Extension must be pending");

        extensionAllowlist[msg.sender] = ExtensionState.INITIALIZED;
        extensions.push(msg.sender);

        emit ExtensionInitialized(msg.sender);
    }

    /**
     * ONLY OWNER: Add new extension(s) that the DelegatedManager can call. Puts extensions into PENDING
     * state, each must be initialized in order to be used.
     *
     * @param _extensions           New extension(s) to add
     */
    function addExtensions(address[] memory _extensions) external onlyOwner {
        _addExtensions(_extensions);
    }

    /**
     * ONLY OWNER: Remove existing extension(s) tracked by the DelegatedManager. Removed extensions are
     * placed in NONE state.
     *
     * @param _extensions           Old extension to remove
     */
    function removeExtensions(address[] memory _extensions) external onlyOwner {
        for (uint256 i = 0; i < _extensions.length; i++) {
            address extension = _extensions[i];

            require(extensionAllowlist[extension] == ExtensionState.INITIALIZED, "Extension not initialized");

            extensions.removeStorage(extension);

            extensionAllowlist[extension] = ExtensionState.NONE;

            IGlobalExtension(extension).removeExtension();

            emit ExtensionRemoved(extension);
        }
    }

    /**
     * ONLY OWNER: Add new operator(s) address(es)
     *
     * @param _operators           New operator(s) to add
     */
    function addOperators(address[] memory _operators) external onlyOwner {
        _addOperators(_operators);
    }

    /**
     * ONLY OWNER: Remove operator(s) from the allowlist
     *
     * @param _operators           New operator(s) to remove
     */
    function removeOperators(address[] memory _operators) external onlyOwner {
        for (uint256 i = 0; i < _operators.length; i++) {
            address operator = _operators[i];

            require(operatorAllowlist[operator], "Operator not already added");

            operators.removeStorage(operator);

            operatorAllowlist[operator] = false;

            emit OperatorRemoved(operator);
        }
    }

    /**
     * ONLY OWNER: Add new asset(s) that can be traded to, wrapped to, or claimed
     *
     * @param _assets           New asset(s) to add
     */
    function addAllowedAssets(address[] memory _assets) external onlyOwner {
        _addAllowedAssets(_assets);
    }

    /**
     * ONLY OWNER: Remove asset(s) so that it/they can't be traded to, wrapped to, or claimed
     *
     * @param _assets           Asset(s) to remove
     */
    function removeAllowedAssets(address[] memory _assets) external onlyOwner {
        for (uint256 i = 0; i < _assets.length; i++) {
            address asset = _assets[i];

            require(assetAllowlist[asset], "Asset not already added");

            allowedAssets.removeStorage(asset);

            assetAllowlist[asset] = false;

            emit AllowedAssetRemoved(asset);
        }
    }

    /**
     * ONLY OWNER: Toggle useAssetAllowlist on and off. When false asset allowlist is ignored
     * when true it is enforced.
     *
     * @param _useAssetAllowlist           Bool indicating whether to use asset allow list
     */
    function updateUseAssetAllowlist(bool _useAssetAllowlist) external onlyOwner {
        useAssetAllowlist = _useAssetAllowlist;

        emit UseAssetAllowlistUpdated(_useAssetAllowlist);
    }

    /**
     * MUTUAL UPGRADE: Update percent of fees that are sent to owner. Owner and Methodologist must each call this function to execute
     * the update. If Owner and Methodologist point to the same address, the update can be executed in a single call.
     *
     * @param _newFeeSplit           Percent in precise units (100% = 10**18) of fees that accrue to owner
     */
    function updateOwnerFeeSplit(uint256 _newFeeSplit) external mutualUpgrade(owner(), methodologist) {
        require(_newFeeSplit <= PreciseUnitMath.preciseUnit(), "Invalid fee split");

        ownerFeeSplit = _newFeeSplit;

        emit OwnerFeeSplitUpdated(_newFeeSplit);
    }

    /**
     * ONLY OWNER: Update address owner receives fees at
     *
     * @param _newFeeRecipient           Address to send owner fees to
     */
    function updateOwnerFeeRecipient(address _newFeeRecipient) external onlyOwner {
        require(_newFeeRecipient != address(0), "Null address passed");

        ownerFeeRecipient = _newFeeRecipient;

        emit OwnerFeeRecipientUpdated(_newFeeRecipient);
    }

    /**
     * ONLY METHODOLOGIST: Update the methodologist address
     *
     * @param _newMethodologist           New methodologist address
     */
    function setMethodologist(address _newMethodologist) external onlyMethodologist {
        require(_newMethodologist != address(0), "Null address passed");

        methodologist = _newMethodologist;

        emit MethodologistChanged(_newMethodologist);
    }

    /**
     * ONLY OWNER: Update the SetToken manager address.
     *
     * @param _newManager           New manager address
     */
    function setManager(address _newManager) external onlyOwner {
        require(_newManager != address(0), "Zero address not valid");
        require(extensions.length == 0, "Must remove all extensions");
        setToken.setManager(_newManager);
    }

    /**
     * ONLY OWNER: Add a new module to the SetToken.
     *
     * @param _module           New module to add
     */
    function addModule(address _module) external onlyOwner {
        setToken.addModule(_module);
    }

    /**
     * ONLY OWNER: Remove a module from the SetToken.
     *
     * @param _module           Module to remove
     */
    function removeModule(address _module) external onlyOwner {
        setToken.removeModule(_module);
    }

    /* ============ External View Functions ============ */

    function isAllowedAsset(address _asset) external view returns(bool) {
        return !useAssetAllowlist || assetAllowlist[_asset];
    }

    function isPendingExtension(address _extension) external view returns(bool) {
        return extensionAllowlist[_extension] == ExtensionState.PENDING;
    }

    function isInitializedExtension(address _extension) external view returns(bool) {
        return extensionAllowlist[_extension] == ExtensionState.INITIALIZED;
    }

    function getExtensions() external view returns(address[] memory) {
        return extensions;
    }

    function getOperators() external view returns(address[] memory) {
        return operators;
    }

    function getAllowedAssets() external view returns(address[] memory) {
        return allowedAssets;
    }

    /* ============ Internal Functions ============ */

    /**
     * Add extensions that the DelegatedManager can call.
     *
     * @param _extensions           New extension to add
     */
    function _addExtensions(address[] memory _extensions) internal {
        for (uint256 i = 0; i < _extensions.length; i++) {
            address extension = _extensions[i];

            require(extensionAllowlist[extension] == ExtensionState.NONE , "Extension already exists");

            extensionAllowlist[extension] = ExtensionState.PENDING;

            emit ExtensionAdded(extension);
        }
    }

    /**
     * Add new operator(s) address(es)
     *
     * @param _operators           New operator to add
     */
    function _addOperators(address[] memory _operators) internal {
        for (uint256 i = 0; i < _operators.length; i++) {
            address operator = _operators[i];

            require(!operatorAllowlist[operator], "Operator already added");

            operators.push(operator);

            operatorAllowlist[operator] = true;

            emit OperatorAdded(operator);
        }
    }

    /**
     * Add new assets that can be traded to, wrapped to, or claimed
     *
     * @param _assets           New asset to add
     */
    function _addAllowedAssets(address[] memory _assets) internal {
        for (uint256 i = 0; i < _assets.length; i++) {
            address asset = _assets[i];

            require(!assetAllowlist[asset], "Asset already added");

            allowedAssets.push(asset);

            assetAllowlist[asset] = true;

            emit AllowedAssetAdded(asset);
        }
    }
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

/**
 * @title MutualUpgradeV2
 * @author Set Protocol
 *
 * The MutualUpgradeV2 contract contains a modifier for handling mutual upgrades between two parties
 *
 * CHANGELOG:
 * - Update mutualUpgrade to allow single transaction execution if the two signing addresses are the same
 */
contract MutualUpgradeV2 {
    /* ============ State Variables ============ */

    // Mapping of upgradable units and if upgrade has been initialized by other party
    mapping(bytes32 => bool) public mutualUpgrades;

    /* ============ Events ============ */

    event MutualUpgradeRegistered(
        bytes32 _upgradeHash
    );

    /* ============ Modifiers ============ */

    modifier mutualUpgrade(address _signerOne, address _signerTwo) {
        require(
            msg.sender == _signerOne || msg.sender == _signerTwo,
            "Must be authorized address"
        );

        // If the two signing addresses are the same, skip upgrade hash step
        if (_signerOne == _signerTwo) {
            _;
        }

        address nonCaller = _getNonCaller(_signerOne, _signerTwo);

        // The upgrade hash is defined by the hash of the transaction call data and sender of msg,
        // which uniquely identifies the function, arguments, and sender.
        bytes32 expectedHash = keccak256(abi.encodePacked(msg.data, nonCaller));

        if (!mutualUpgrades[expectedHash]) {
            bytes32 newHash = keccak256(abi.encodePacked(msg.data, msg.sender));

            mutualUpgrades[newHash] = true;

            emit MutualUpgradeRegistered(newHash);

            return;
        }

        delete mutualUpgrades[expectedHash];

        // Run the rest of the upgrades
        _;
    }

    /* ============ Internal Functions ============ */

    function _getNonCaller(address _signerOne, address _signerTwo) internal view returns(address) {
        return msg.sender == _signerOne ? _signerTwo : _signerOne;
    }
}

// SPDX-License-Identifier: Apache License, Version 2.0
pragma solidity 0.6.10;

import { MutualUpgradeV2 } from "../lib/MutualUpgradeV2.sol";


// Mock contract implementation of MutualUpgradeV2 functions
contract MutualUpgradeV2Mock is
    MutualUpgradeV2
{
    uint256 public testUint;
    address public owner;
    address public methodologist;

    constructor(address _owner, address _methodologist) public {
        owner = _owner;
        methodologist = _methodologist;
    }

    function testMutualUpgrade(
        uint256 _testUint
    )
        external
        mutualUpgrade(owner, methodologist)
    {
        testUint = _testUint;
    }
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

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

import { ISetToken } from "@setprotocol/set-protocol-v2/contracts/interfaces/ISetToken.sol";
import { IStreamingFeeModule } from "@setprotocol/set-protocol-v2/contracts/interfaces/IStreamingFeeModule.sol";
import { PreciseUnitMath } from "@setprotocol/set-protocol-v2/contracts/lib/PreciseUnitMath.sol";

import { BaseGlobalExtension } from "../lib/BaseGlobalExtension.sol";
import { IDelegatedManager } from "../interfaces/IDelegatedManager.sol";
import { IManagerCore } from "../interfaces/IManagerCore.sol";

/**
 * @title StreamingFeeSplitExtension
 * @author Set Protocol
 *
 * Smart contract global extension which provides DelegatedManager owner and methodologist the ability to accrue and split
 * streaming fees. Owner may configure the fee split percentages.
 *
 * Notes
 * - the fee split is set on the Delegated Manager contract
 * - when fees distributed via this contract will be inclusive of all fee types
 */
contract StreamingFeeSplitExtension is BaseGlobalExtension {
    using Address for address;
    using PreciseUnitMath for uint256;
    using SafeMath for uint256;

    /* ============ Events ============ */

    event StreamingFeeSplitExtensionInitialized(
        address indexed _setToken,
        address indexed _delegatedManager
    );

    event FeesDistributed(
        address _setToken,
        address indexed _ownerFeeRecipient,
        address indexed _methodologist,
        uint256 _ownerTake,
        uint256 _methodologistTake
    );

    /* ============ State Variables ============ */

    // Instance of StreamingFeeModule
    IStreamingFeeModule public immutable streamingFeeModule;

    /* ============ Constructor ============ */

    constructor(
        IManagerCore _managerCore,
        IStreamingFeeModule _streamingFeeModule
    )
        public
        BaseGlobalExtension(_managerCore)
    {
        streamingFeeModule = _streamingFeeModule;
    }

    /* ============ External Functions ============ */

    /**
     * ANYONE CALLABLE: Accrues fees from streaming fee module. Gets resulting balance after fee accrual, calculates fees for
     * owner and methodologist, and sends to owner fee recipient and methodologist respectively.
     */
    function accrueFeesAndDistribute(ISetToken _setToken) public {
        // Emits a FeeActualized event
        streamingFeeModule.accrueFee(_setToken);

        IDelegatedManager delegatedManager = _manager(_setToken);

        uint256 totalFees = _setToken.balanceOf(address(delegatedManager));

        address methodologist = delegatedManager.methodologist();
        address ownerFeeRecipient = delegatedManager.ownerFeeRecipient();

        uint256 ownerTake = totalFees.preciseMul(delegatedManager.ownerFeeSplit());
        uint256 methodologistTake = totalFees.sub(ownerTake);

        if (ownerTake > 0) {
            delegatedManager.transferTokens(address(_setToken), ownerFeeRecipient, ownerTake);
        }

        if (methodologistTake > 0) {
            delegatedManager.transferTokens(address(_setToken), methodologist, methodologistTake);
        }

        emit FeesDistributed(address(_setToken), ownerFeeRecipient, methodologist, ownerTake, methodologistTake);
    }

    /**
     * ONLY OWNER: Initializes StreamingFeeModule on the SetToken associated with the DelegatedManager.
     *
     * @param _delegatedManager     Instance of the DelegatedManager to initialize the StreamingFeeModule for
     * @param _settings             FeeState struct defining fee parameters for StreamingFeeModule initialization
     */
    function initializeModule(
        IDelegatedManager _delegatedManager,
        IStreamingFeeModule.FeeState memory _settings
    )
        external
        onlyOwnerAndValidManager(_delegatedManager)
    {
        require(_delegatedManager.isInitializedExtension(address(this)), "Extension must be initialized");

        _initializeModule(_delegatedManager.setToken(), _delegatedManager, _settings);
    }

    /**
     * ONLY OWNER: Initializes StreamingFeeSplitExtension to the DelegatedManager.
     *
     * @param _delegatedManager     Instance of the DelegatedManager to initialize
     */
    function initializeExtension(IDelegatedManager _delegatedManager) external onlyOwnerAndValidManager(_delegatedManager) {
        require(_delegatedManager.isPendingExtension(address(this)), "Extension must be pending");

        ISetToken setToken = _delegatedManager.setToken();

        _initializeExtension(setToken, _delegatedManager);

        emit StreamingFeeSplitExtensionInitialized(address(setToken), address(_delegatedManager));
    }

    /**
     * ONLY OWNER: Initializes StreamingFeeSplitExtension to the DelegatedManager and StreamingFeeModule to the SetToken
     *
     * @param _delegatedManager     Instance of the DelegatedManager to initialize
     * @param _settings             FeeState struct defining fee parameters for StreamingFeeModule initialization
     */
    function initializeModuleAndExtension(
        IDelegatedManager _delegatedManager,
        IStreamingFeeModule.FeeState memory _settings
    )
        external
        onlyOwnerAndValidManager(_delegatedManager)
    {
        require(_delegatedManager.isPendingExtension(address(this)), "Extension must be pending");

        ISetToken setToken = _delegatedManager.setToken();

        _initializeExtension(setToken, _delegatedManager);
        _initializeModule(setToken, _delegatedManager, _settings);

        emit StreamingFeeSplitExtensionInitialized(address(setToken), address(_delegatedManager));
    }

    /**
     * ONLY MANAGER: Remove an existing SetToken and DelegatedManager tracked by the StreamingFeeSplitExtension
     */
    function removeExtension() external override {
        IDelegatedManager delegatedManager = IDelegatedManager(msg.sender);
        ISetToken setToken = delegatedManager.setToken();

        _removeExtension(setToken, delegatedManager);
    }

    /**
     * ONLY OWNER: Updates streaming fee on StreamingFeeModule.
     *
     * NOTE: This will accrue streaming fees though not send to owner fee recipient and methodologist.
     *
     * @param _setToken     Instance of the SetToken to update streaming fee for
     * @param _newFee       Percent of Set accruing to fee extension annually (1% = 1e16, 100% = 1e18)
     */
    function updateStreamingFee(ISetToken _setToken, uint256 _newFee)
        external
        onlyOwner(_setToken)
    {
        bytes memory callData = abi.encodeWithSignature("updateStreamingFee(address,uint256)", _setToken, _newFee);
        _invokeManager(_manager(_setToken), address(streamingFeeModule), callData);
    }

    /**
     * ONLY OWNER: Updates fee recipient on StreamingFeeModule
     *
     * @param _setToken         Instance of the SetToken to update fee recipient for
     * @param _newFeeRecipient  Address of new fee recipient. This should be the address of the DelegatedManager
     */
    function updateFeeRecipient(ISetToken _setToken, address _newFeeRecipient)
        external
        onlyOwner(_setToken)
    {
        bytes memory callData = abi.encodeWithSignature("updateFeeRecipient(address,address)", _setToken, _newFeeRecipient);
        _invokeManager(_manager(_setToken), address(streamingFeeModule), callData);
    }

    /* ============ Internal Functions ============ */

    /**
     * Internal function to initialize StreamingFeeModule on the SetToken associated with the DelegatedManager.
     *
     * @param _setToken                     Instance of the SetToken corresponding to the DelegatedManager
     * @param _delegatedManager     Instance of the DelegatedManager to initialize the TradeModule for
     * @param _settings             FeeState struct defining fee parameters for StreamingFeeModule initialization
     */
    function _initializeModule(
        ISetToken _setToken,
        IDelegatedManager _delegatedManager,
        IStreamingFeeModule.FeeState memory _settings
    )
        internal
    {
        bytes memory callData = abi.encodeWithSignature(
            "initialize(address,(address,uint256,uint256,uint256))",
            _setToken,
            _settings);
        _invokeManager(_delegatedManager, address(streamingFeeModule), callData);
    }
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
pragma experimental ABIEncoderV2;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import { AddressArrayUtils } from "@setprotocol/set-protocol-v2/contracts/lib/AddressArrayUtils.sol";
import { IController } from "@setprotocol/set-protocol-v2/contracts/interfaces/IController.sol";
import { ISetToken } from "@setprotocol/set-protocol-v2/contracts/interfaces/ISetToken.sol";
import { ISetTokenCreator } from "@setprotocol/set-protocol-v2/contracts/interfaces/ISetTokenCreator.sol";

import { DelegatedManager } from "../manager/DelegatedManager.sol";
import { IDelegatedManager } from "../interfaces/IDelegatedManager.sol";
import { IManagerCore } from "../interfaces/IManagerCore.sol";

/**
 * @title DelegatedManagerFactory
 * @author Set Protocol
 *
 * Factory smart contract which gives asset managers the ability to:
 * > create a Set Token managed with a DelegatedManager contract
 * > create a DelegatedManager contract for an existing Set Token to migrate to
 * > initialize extensions and modules for SetTokens using the DelegatedManager system
 */
contract DelegatedManagerFactory {
    using AddressArrayUtils for address[];
    using Address for address;

    /* ============ Structs ============ */

    struct InitializeParams{
        address deployer;
        address owner;
        address methodologist;
        IDelegatedManager manager;
        bool isPending;
    }

    /* ============ Events ============ */

    /**
     * @dev Emitted on DelegatedManager creation
     * @param _setToken             Instance of the SetToken being created
     * @param _manager              Address of the DelegatedManager
     * @param _deployer             Address of the deployer
    */
    event DelegatedManagerCreated(
        ISetToken indexed _setToken,
        DelegatedManager indexed _manager,
        address _deployer
    );

    /**
     * @dev Emitted on DelegatedManager initialization
     * @param _setToken             Instance of the SetToken being initialized
     * @param _manager              Address of the DelegatedManager owner
    */
    event DelegatedManagerInitialized(
        ISetToken indexed _setToken,
        IDelegatedManager indexed _manager
    );

    /* ============ State Variables ============ */

    // ManagerCore address
    IManagerCore public immutable managerCore;

    // Controller address
    IController public immutable controller;

    // SetTokenFactory address
    ISetTokenCreator public immutable setTokenFactory;

    // Mapping which stores manager creation metadata between creation and initialization steps
    mapping(ISetToken=>InitializeParams) public initializeState;

    /* ============ Constructor ============ */

    /**
     * @dev Sets managerCore and setTokenFactory address.
     * @param _managerCore                      Address of ManagerCore protocol contract
     * @param _controller                       Address of Controller protocol contract
     * @param _setTokenFactory                  Address of SetTokenFactory protocol contract
     */
    constructor(
        IManagerCore _managerCore,
        IController _controller,
        ISetTokenCreator _setTokenFactory
    )
        public
    {
        managerCore = _managerCore;
        controller = _controller;
        setTokenFactory = _setTokenFactory;
    }

    /* ============ External Functions ============ */

    /**
     * ANYONE CAN CALL: Deploys a new SetToken and DelegatedManager. Sets some temporary metadata about
     * the deployment which will be read during a subsequent intialization step which wires everything
     * together.
     *
     * @param _components       List of addresses of components for initial Positions
     * @param _units            List of units. Each unit is the # of components per 10^18 of a SetToken
     * @param _name             Name of the SetToken
     * @param _symbol           Symbol of the SetToken
     * @param _owner            Address to set as the DelegateManager's `owner` role
     * @param _methodologist    Address to set as the DelegateManager's methodologist role
     * @param _modules          List of modules to enable. All modules must be approved by the Controller
     * @param _operators        List of operators authorized for the DelegateManager
     * @param _assets           List of assets DelegateManager can trade. When empty, asset allow list is not enforced
     * @param _extensions       List of extensions authorized for the DelegateManager
     *
     * @return (ISetToken, address) The created SetToken and DelegatedManager addresses, respectively
     */
    function createSetAndManager(
        address[] memory _components,
        int256[] memory _units,
        string memory _name,
        string memory _symbol,
        address _owner,
        address _methodologist,
        address[] memory _modules,
        address[] memory _operators,
        address[] memory _assets,
        address[] memory _extensions
    )
        external
        returns (ISetToken, address)
    {
        _validateManagerParameters(_components, _extensions, _assets);

        ISetToken setToken = _deploySet(
            _components,
            _units,
            _modules,
            _name,
            _symbol
        );

        DelegatedManager manager = _deployManager(
            setToken,
            _extensions,
            _operators,
            _assets
        );

        _setInitializationState(setToken, address(manager), _owner, _methodologist);

        return (setToken, address(manager));
    }

    /**
     * ONLY SETTOKEN MANAGER: Deploys a DelegatedManager and sets some temporary metadata about the
     * deployment which will be read during a subsequent intialization step which wires everything together.
     * This method is used when migrating an existing SetToken to the DelegatedManager system.
     *
     * (Note: This flow should work well for SetTokens managed by an EOA. However, existing
     * contract-managed Sets may need to have their ownership temporarily transferred to an EOA when
     * migrating. We don't anticipate high demand for this migration case though.)
     *
     * @param  _setToken         Instance of SetToken to migrate to the DelegatedManager system
     * @param  _owner            Address to set as the DelegateManager's `owner` role
     * @param  _methodologist    Address to set as the DelegateManager's methodologist role
     * @param  _operators        List of operators authorized for the DelegateManager
     * @param  _assets           List of assets DelegateManager can trade. When empty, asset allow list is not enforced
     * @param  _extensions       List of extensions authorized for the DelegateManager
     *
     * @return (address) Address of the created DelegatedManager
     */
    function createManager(
        ISetToken _setToken,
        address _owner,
        address _methodologist,
        address[] memory _operators,
        address[] memory _assets,
        address[] memory _extensions
    )
        external
        returns (address)
    {
        require(controller.isSet(address(_setToken)), "Must be controller-enabled SetToken");
        require(msg.sender == _setToken.manager(), "Must be manager");

        _validateManagerParameters(_setToken.getComponents(), _extensions, _assets);

        DelegatedManager manager = _deployManager(
            _setToken,
            _extensions,
            _operators,
            _assets
        );

        _setInitializationState(_setToken, address(manager), _owner, _methodologist);

        return address(manager);
    }

    /**
     * ONLY DEPLOYER: Wires SetToken, DelegatedManager, global manager extensions, and modules together
     * into a functioning package.
     *
     * NOTE: When migrating to this manager system from an existing SetToken, the SetToken's current manager address
     * must be reset to point at the newly deployed DelegatedManager contract in a separate, final transaction.
     *
     * @param  _setToken                Instance of the SetToken
     * @param  _ownerFeeSplit           Percent of fees in precise units (10^16 = 1%) sent to owner, rest to methodologist
     * @param  _ownerFeeRecipient       Address which receives owner's share of fees when they're distributed
     * @param  _extensions              List of addresses of extensions which need to be initialized
     * @param  _initializeBytecode      List of bytecode encoded calls to relevant target's initialize function
     */
    function initialize(
        ISetToken _setToken,
        uint256 _ownerFeeSplit,
        address _ownerFeeRecipient,
        address[] memory _extensions,
        bytes[] memory _initializeBytecode
    )
        external
    {
        require(initializeState[_setToken].isPending, "Manager must be awaiting initialization");
        require(msg.sender == initializeState[_setToken].deployer, "Only deployer can initialize manager");
        _extensions.validatePairsWithArray(_initializeBytecode);

        IDelegatedManager manager = initializeState[_setToken].manager;

        // If the SetToken was factory-deployed & factory is its current `manager`, transfer
        // managership to the new DelegatedManager
        if (_setToken.manager() == address(this)) {
            _setToken.setManager(address(manager));
        }

        _initializeExtensions(manager, _extensions, _initializeBytecode);

        _setManagerState(
            manager,
            initializeState[_setToken].owner,
            initializeState[_setToken].methodologist,
            _ownerFeeSplit,
            _ownerFeeRecipient
        );

        delete initializeState[_setToken];

        emit DelegatedManagerInitialized(_setToken, manager);
    }

    /* ============ Internal Functions ============ */

    /**
     * Deploys a SetToken, setting this factory as its manager temporarily, pending initialization.
     * Managership is transferred to a newly created DelegatedManager during `initialize`
     *
     * @param _components       List of addresses of components for initial Positions
     * @param _units            List of units. Each unit is the # of components per 10^18 of a SetToken
     * @param _modules          List of modules to enable. All modules must be approved by the Controller
     * @param _name             Name of the SetToken
     * @param _symbol           Symbol of the SetToken
     *
     * @return Address of created SetToken;
     */
    function _deploySet(
        address[] memory _components,
        int256[] memory _units,
        address[] memory _modules,
        string memory _name,
        string memory _symbol
    )
        internal
        returns (ISetToken)
    {
        address setToken = setTokenFactory.create(
            _components,
            _units,
            _modules,
            address(this),
            _name,
            _symbol
        );

        return ISetToken(setToken);
    }

    /**
     * Deploys a DelegatedManager. Sets owner and methodologist roles to address(this) and the resulting manager address is
     * saved to the ManagerCore.
     *
     * @param  _setToken         Instance of SetToken to migrate to the DelegatedManager system
     * @param  _extensions       List of extensions authorized for the DelegateManager
     * @param  _operators        List of operators authorized for the DelegateManager
     * @param  _assets           List of assets DelegateManager can trade. When empty, asset allow list is not enforced
     *
     * @return Address of created DelegatedManager
     */
    function _deployManager(
        ISetToken _setToken,
        address[] memory _extensions,
        address[] memory _operators,
        address[] memory _assets
    )
        internal
        returns (DelegatedManager)
    {
        // If asset array is empty, manager's useAssetAllowList will be set to false
        // and the asset allow list is not enforced
        bool useAssetAllowlist = _assets.length > 0;

        DelegatedManager newManager = new DelegatedManager(
            _setToken,
            address(this),
            address(this),
            _extensions,
            _operators,
            _assets,
            useAssetAllowlist
        );

        // Registers manager with ManagerCore
        managerCore.addManager(address(newManager));

        emit DelegatedManagerCreated(
            _setToken,
            newManager,
            msg.sender
        );

        return newManager;
    }

    /**
     * Initialize extensions on the DelegatedManager. Checks that extensions are tracked on the ManagerCore and that the
     * provided bytecode targets the input manager.
     *
     * @param  _manager                  Instance of DelegatedManager
     * @param  _extensions               List of addresses of extensions to initialize
     * @param  _initializeBytecode       List of bytecode encoded calls to relevant extensions's initialize function
     */
    function _initializeExtensions(
        IDelegatedManager _manager,
        address[] memory _extensions,
        bytes[] memory _initializeBytecode
    ) internal {
        for (uint256 i = 0; i < _extensions.length; i++) {
            address extension = _extensions[i];
            require(managerCore.isExtension(extension), "Target must be ManagerCore-enabled Extension");

            bytes memory initializeBytecode = _initializeBytecode[i];

            // Each input initializeBytecode is a varible length bytes array which consists of a 32 byte prefix for the
            // length parameter, a 4 byte function selector, a 32 byte DelegatedManager address, and any additional parameters
            // as shown below:
            // [32 bytes - length parameter, 4 bytes - function selector, 32 bytes - DelegatedManager address, additional parameters]
            // It is required that the input DelegatedManager address is the DelegatedManager address corresponding to the caller
            address inputManager;
            assembly {
                inputManager := mload(add(initializeBytecode, 36))
            }
            require(inputManager == address(_manager), "Must target correct DelegatedManager");

            // Because we validate uniqueness of _extensions only one transaction can be sent to each extension during this
            // transaction. Due to this no extension can be used for any SetToken transactions other than initializing these contracts
            extension.functionCallWithValue(initializeBytecode, 0);
        }
    }

    /**
     * Stores temporary creation metadata during the contract creation step. Data is retrieved, read and
     * finally deleted during `initialize`.
     *
     * @param  _setToken         Instance of SetToken
     * @param  _manager          Address of DelegatedManager created for SetToken
     * @param  _owner            Address that will be given the `owner` DelegatedManager's role on initialization
     * @param  _methodologist    Address that will be given the `methodologist` DelegatedManager's role on initialization
     */
    function _setInitializationState(
        ISetToken _setToken,
        address _manager,
        address _owner,
        address _methodologist
    ) internal {
        initializeState[_setToken] = InitializeParams({
            deployer: msg.sender,
            owner: _owner,
            methodologist: _methodologist,
            manager: IDelegatedManager(_manager),
            isPending: true
        });
    }

    /**
     * Initialize fee settings on DelegatedManager and transfer `owner` and `methodologist` roles.
     *
     * @param  _manager                 Instance of DelegatedManager
     * @param  _owner                   Address that will be given the `owner` DelegatedManager's role
     * @param  _methodologist           Address that will be given the `methodologist` DelegatedManager's role
     * @param  _ownerFeeSplit           Percent of fees in precise units (10^16 = 1%) sent to owner, rest to methodologist
     * @param  _ownerFeeRecipient       Address which receives owner's share of fees when they're distributed
     */
    function _setManagerState(
        IDelegatedManager _manager,
        address _owner,
        address _methodologist,
        uint256 _ownerFeeSplit,
        address _ownerFeeRecipient
    ) internal {
        _manager.updateOwnerFeeSplit(_ownerFeeSplit);
        _manager.updateOwnerFeeRecipient(_ownerFeeRecipient);

        _manager.transferOwnership(_owner);
        _manager.setMethodologist(_methodologist);
    }

    /**
     * Validates that all components currently held by the Set are on the asset allow list. Validate that the manager is
     * deployed with at least one extension in the PENDING state.
     *
     * @param  _components       List of addresses of components for initial/current Set positions
     * @param  _extensions       List of extensions authorized for the DelegateManager
     * @param  _assets           List of assets DelegateManager can trade. When empty, asset allow list is not enforced
     */
    function _validateManagerParameters(
        address[] memory _components,
        address[] memory _extensions,
        address[] memory _assets
    )
        internal
        pure
    {
        require(_extensions.length > 0, "Must have at least 1 extension");

        if (_assets.length != 0) {
            _validateComponentsIncludedInAssetsList(_components, _assets);
        }
    }

    /**
     * Validates that all SetToken components are included in the assets whitelist. This prevents the
     * DelegatedManager from being initialized with some components in an untrade-able state.
     *
     * @param _components       List of addresses of components for initial Positions
     * @param  _assets          List of assets DelegateManager can trade.
     */
    function _validateComponentsIncludedInAssetsList(
        address[] memory _components,
        address[] memory _assets
    ) internal pure {
        for (uint256 i = 0; i < _components.length; i++) {
            require(_assets.contains(_components[i]), "Asset list must include all components");
        }
    }
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

interface ISetTokenCreator {
    function create(
        address[] memory _components,
        int256[] memory _units,
        address[] memory _modules,
        address _manager,
        string memory _name,
        string memory _symbol
    )
        external
        returns (address);
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

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { AddressArrayUtils } from "@setprotocol/set-protocol-v2/contracts/lib/AddressArrayUtils.sol";

/**
 * @title ManagerCore
 * @author Set Protocol
 *
 *  Registry for governance approved GlobalExtensions, DelegatedManagerFactories, and DelegatedManagers.
 */
contract ManagerCore is Ownable {
    using AddressArrayUtils for address[];

    /* ============ Events ============ */

    event ExtensionAdded(address indexed _extension);
    event ExtensionRemoved(address indexed _extension);
    event FactoryAdded(address indexed _factory);
    event FactoryRemoved(address indexed _factory);
    event ManagerAdded(address indexed _manager, address indexed _factory);
    event ManagerRemoved(address indexed _manager);

    /* ============ Modifiers ============ */

    /**
     * Throws if function is called by any address other than a valid factory.
     */
    modifier onlyFactory() {
        require(isFactory[msg.sender], "Only valid factories can call");
        _;
    }

    modifier onlyInitialized() {
        require(isInitialized, "Contract must be initialized.");
        _;
    }

    /* ============ State Variables ============ */

    // List of enabled extensions
    address[] public extensions;
    // List of enabled factories of managers
    address[] public factories;
    // List of enabled managers
    address[] public managers;

    // Mapping to check whether address is valid Extension, Factory, or Manager
    mapping(address => bool) public isExtension;
    mapping(address => bool) public isFactory;
    mapping(address => bool) public isManager;


    // Return true if the ManagerCore is initialized
    bool public isInitialized;

    /* ============ External Functions ============ */

    /**
     * Initializes any predeployed factories. Note: This function can only be called by
     * the owner once to batch initialize the initial system contracts.
     *
     * @param _extensions            List of extensions to add
     * @param _factories             List of factories to add
     */
    function initialize(
        address[] memory _extensions,
        address[] memory _factories
    )
        external
        onlyOwner
    {
        require(!isInitialized, "ManagerCore is already initialized");

        extensions = _extensions;
        factories = _factories;

        // Loop through and initialize isExtension and isFactory mapping
        for (uint256 i = 0; i < _extensions.length; i++) {
            _addExtension(_extensions[i]);
        }
        for (uint256 i = 0; i < _factories.length; i++) {
            _addFactory(_factories[i]);
        }

        // Set to true to only allow initialization once
        isInitialized = true;
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Allows governance to add an extension
     *
     * @param _extension               Address of the extension contract to add
     */
    function addExtension(address _extension) external onlyInitialized onlyOwner {
        require(!isExtension[_extension], "Extension already exists");

        _addExtension(_extension);

        extensions.push(_extension);
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Allows governance to remove an extension
     *
     * @param _extension               Address of the extension contract to remove
     */
    function removeExtension(address _extension) external onlyInitialized onlyOwner {
        require(isExtension[_extension], "Extension does not exist");

        extensions.removeStorage(_extension);

        isExtension[_extension] = false;

        emit ExtensionRemoved(_extension);
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Allows governance to add a factory
     *
     * @param _factory               Address of the factory contract to add
     */
    function addFactory(address _factory) external onlyInitialized onlyOwner {
        require(!isFactory[_factory], "Factory already exists");

        _addFactory(_factory);

        factories.push(_factory);
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Allows governance to remove a factory
     *
     * @param _factory               Address of the factory contract to remove
     */
    function removeFactory(address _factory) external onlyInitialized onlyOwner {
        require(isFactory[_factory], "Factory does not exist");

        factories.removeStorage(_factory);

        isFactory[_factory] = false;

        emit FactoryRemoved(_factory);
    }

    /**
     * PRIVILEGED FACTORY FUNCTION. Adds a newly deployed manager as an enabled manager.
     *
     * @param _manager               Address of the manager contract to add
     */
    function addManager(address _manager) external onlyInitialized onlyFactory {
        require(!isManager[_manager], "Manager already exists");

        isManager[_manager] = true;

        managers.push(_manager);

        emit ManagerAdded(_manager, msg.sender);
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Allows governance to remove a manager
     *
     * @param _manager               Address of the manager contract to remove
     */
    function removeManager(address _manager) external onlyInitialized onlyOwner {
        require(isManager[_manager], "Manager does not exist");

        managers.removeStorage(_manager);

        isManager[_manager] = false;

        emit ManagerRemoved(_manager);
    }

    /* ============ External Getter Functions ============ */

    function getExtensions() external view returns (address[] memory) {
        return extensions;
    }

    function getFactories() external view returns (address[] memory) {
        return factories;
    }

    function getManagers() external view returns (address[] memory) {
        return managers;
    }

    /* ============ Internal Functions ============ */

    /**
     * Add an extension tracked on the ManagerCore
     *
     * @param _extension               Address of the extension contract to add
     */
    function _addExtension(address _extension) internal {
        require(_extension != address(0), "Zero address submitted.");

        isExtension[_extension] = true;

        emit ExtensionAdded(_extension);
    }

    /**
     * Add a factory tracked on the ManagerCore
     *
     * @param _factory               Address of the factory contract to add
     */
    function _addFactory(address _factory) internal {
        require(_factory != address(0), "Zero address submitted.");

        isFactory[_factory] = true;

        emit FactoryAdded(_factory);
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
pragma experimental ABIEncoderV2;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

import { IManagerIssuanceHook } from "@setprotocol/set-protocol-v2/contracts/interfaces/IManagerIssuanceHook.sol";
import { ISetToken } from "@setprotocol/set-protocol-v2/contracts/interfaces/ISetToken.sol";


/**
 * @title SupplyCapIssuanceHook
 * @author Set Protocol
 *
 * Issuance hook that checks new issuances won't push SetToken totalSupply over supply cap.
 */
contract SupplyCapIssuanceHook is Ownable, IManagerIssuanceHook {
    using SafeMath for uint256;

    /* ============ Events ============ */

    event SupplyCapUpdated(uint256 _newCap);

    /* ============ State Variables ============ */

    // Cap on totalSupply of Sets
    uint256 public supplyCap;

    /* ============ Constructor ============ */

    /**
     * Constructor, overwrites owner and original supply cap.
     *
     * @param _initialOwner     Owner address, overwrites Ownable logic which sets to deployer as default
     * @param _supplyCap        Supply cap for Set (in wei of Set)
     */
    constructor(
        address _initialOwner,
        uint256 _supplyCap
    )
        public
    {
        supplyCap = _supplyCap;

        // Overwrite _owner param of Ownable contract
        transferOwnership(_initialOwner);
    }

    /**
     * Adheres to IManagerIssuanceHook interface, and checks to make sure the current issue call won't push total supply over cap.
     */
    function invokePreIssueHook(
        ISetToken _setToken,
        uint256 _issueQuantity,
        address /*_sender*/,
        address /*_to*/
    )
        external
        override
    {
        uint256 totalSupply = _setToken.totalSupply();

        require(totalSupply.add(_issueQuantity) <= supplyCap, "Supply cap exceeded");
    }

    /**
     * Adheres to IManagerIssuanceHook interface
     */
    function invokePreRedeemHook(
        ISetToken _setToken,
        uint256 _redeemQuantity,
        address _sender,
        address _to
    )
        external
        override
    {}

    /**
     * ONLY OWNER: Updates supply cap
     */
    function updateSupplyCap(uint256 _newCap) external onlyOwner {
        supplyCap = _newCap;
        SupplyCapUpdated(_newCap);
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

import { ISetToken } from "./ISetToken.sol";

interface IManagerIssuanceHook {
    function invokePreIssueHook(ISetToken _setToken, uint256 _issueQuantity, address _sender, address _to) external;
    function invokePreRedeemHook(ISetToken _setToken, uint256 _redeemQuantity, address _sender, address _to) external;
}

// SPDX-License-Identifier: Apache License, Version 2.0
pragma solidity 0.6.10;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * Trade Adapter that doubles as a mock exchange
 */
contract TradeAdapterMock {

    /* ============ Helper Functions ============ */

    function withdraw(address _token)
        external
    {
        uint256 balance = ERC20(_token).balanceOf(address(this));
        require(ERC20(_token).transfer(msg.sender, balance), "ERC20 transfer failed");
    }

    /* ============ Trade Functions ============ */

    function trade(
        address _sourceToken,
        address _destinationToken,
        address _destinationAddress,
        uint256 _sourceQuantity,
        uint256 _minDestinationQuantity
    )
        external
    {
        uint256 destinationBalance = ERC20(_destinationToken).balanceOf(address(this));
        require(ERC20(_sourceToken).transferFrom(_destinationAddress, address(this), _sourceQuantity), "ERC20 TransferFrom failed");
        if (_minDestinationQuantity == 1) { // byte revert case, min nonzero uint256 minimum receive quantity
            bytes memory data = abi.encodeWithSelector(
                bytes4(keccak256("trade(address,address,address,uint256,uint256)")),
                _sourceToken,
                _destinationToken,
                _destinationAddress,
                _sourceQuantity,
                _minDestinationQuantity
            );
            assembly { revert(add(data, 32), mload(data)) }
        }
        if (destinationBalance >= _minDestinationQuantity) { // normal case
            require(ERC20(_destinationToken).transfer(_destinationAddress, destinationBalance), "ERC20 transfer failed");
        }
        else { // string revert case, minimum destination quantity not in exchange
            revert("Insufficient funds in exchange");
        }
    }

    /* ============ Adapter Functions ============ */

    function getSpender()
        external
        view
        returns (address)
    {
        return address(this);
    }

    function getTradeCalldata(
        address _sourceToken,
        address _destinationToken,
        address _destinationAddress,
        uint256 _sourceQuantity,
        uint256 _minDestinationQuantity,
        bytes memory /* _data */
    )
        external
        view
        returns (address, uint256, bytes memory)
    {
        // Encode method data for SetToken to invoke
        bytes memory methodData = abi.encodeWithSignature(
            "trade(address,address,address,uint256,uint256)",
            _sourceToken,
            _destinationToken,
            _destinationAddress,
            _sourceQuantity,
            _minDestinationQuantity
        );

        return (address(this), 0, methodData);
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

import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import { AddressArrayUtils } from "@setprotocol/set-protocol-v2/contracts/lib/AddressArrayUtils.sol";
import { ISetToken } from "@setprotocol/set-protocol-v2/contracts/interfaces/ISetToken.sol";

import { IAdapter } from "../interfaces/IAdapter.sol";


/**
 * @title BaseManager
 * @author Set Protocol
 *
 * Smart contract manager that contains permissions and admin functionality
 */
contract BaseManager {
    using Address for address;
    using AddressArrayUtils for address[];

    /* ============ Events ============ */

    event AdapterAdded(
        address _adapter
    );

    event AdapterRemoved(
        address _adapter
    );

    event MethodologistChanged(
        address _oldMethodologist,
        address _newMethodologist
    );

    event OperatorChanged(
        address _oldOperator,
        address _newOperator
    );

    /* ============ Modifiers ============ */

    /**
     * Throws if the sender is not the SetToken operator
     */
    modifier onlyOperator() {
        require(msg.sender == operator, "Must be operator");
        _;
    }

    /**
     * Throws if the sender is not the SetToken methodologist
     */
    modifier onlyMethodologist() {
        require(msg.sender == methodologist, "Must be methodologist");
        _;
    }

    /**
     * Throws if the sender is not a listed adapter
     */
    modifier onlyAdapter() {
        require(isAdapter[msg.sender], "Must be adapter");
        _;
    }

    /* ============ State Variables ============ */

    // Instance of SetToken
    ISetToken public setToken;

    // Array of listed adapters
    address[] internal adapters;

    // Mapping to check if adapter is added
    mapping(address => bool) public isAdapter;

    // Address of operator which typically executes manager only functions on Set Protocol modules
    address public operator;

    // Address of methodologist which serves as providing methodology for the index
    address public methodologist;

    /* ============ Constructor ============ */

    constructor(
        ISetToken _setToken,
        address _operator,
        address _methodologist
    )
        public
    {
        setToken = _setToken;
        operator = _operator;
        methodologist = _methodologist;
    }

    /* ============ External Functions ============ */

    /**
     * MUTUAL UPGRADE: Update the SetToken manager address. Operator and Methodologist must each call
     * this function to execute the update.
     *
     * @param _newManager           New manager address
     */
    function setManager(address _newManager) external onlyOperator {
        require(_newManager != address(0), "Zero address not valid");
        setToken.setManager(_newManager);
    }

    /**
     * MUTUAL UPGRADE: Add a new adapter that the BaseManager can call.
     *
     * @param _adapter           New adapter to add
     */
    function addAdapter(address _adapter) external onlyOperator {
        require(!isAdapter[_adapter], "Adapter already exists");
        require(address(IAdapter(_adapter).manager()) == address(this), "Adapter manager invalid");

        adapters.push(_adapter);

        isAdapter[_adapter] = true;

        emit AdapterAdded(_adapter);
    }

    /**
     * MUTUAL UPGRADE: Remove an existing adapter tracked by the BaseManager.
     *
     * @param _adapter           Old adapter to remove
     */
    function removeAdapter(address _adapter) external onlyOperator {
        require(isAdapter[_adapter], "Adapter does not exist");

        adapters.removeStorage(_adapter);

        isAdapter[_adapter] = false;

        emit AdapterRemoved(_adapter);
    }

    /**
     * ADAPTER ONLY: Interact with a module registered on the SetToken.
     *
     * @param _module           Module to interact with
     * @param _data             Byte data of function to call in module
     */
    function interactManager(address _module, bytes calldata _data) external onlyAdapter {
        // Invoke call to module, assume value will always be 0
        _module.functionCallWithValue(_data, 0);
    }

    /**
     * OPERATOR ONLY: Add a new module to the SetToken.
     *
     * @param _module           New module to add
     */
    function addModule(address _module) external onlyOperator {
        setToken.addModule(_module);
    }

    /**
     * OPERATOR ONLY: Remove a new module from the SetToken.
     *
     * @param _module           Module to remove
     */
    function removeModule(address _module) external onlyOperator {
        setToken.removeModule(_module);
    }

    /**
     * METHODOLOGIST ONLY: Update the methodologist address
     *
     * @param _newMethodologist           New methodologist address
     */
    function setMethodologist(address _newMethodologist) external onlyMethodologist {
        emit MethodologistChanged(methodologist, _newMethodologist);

        methodologist = _newMethodologist;
    }

    /**
     * OPERATOR ONLY: Update the operator address
     *
     * @param _newOperator           New operator address
     */
    function setOperator(address _newOperator) external onlyOperator {
        emit OperatorChanged(operator, _newOperator);

        operator = _newOperator;
    }

    /* ============ External Getters ============ */

    function getAdapters() external view returns(address[] memory) {
        return adapters;
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

import { IBaseManager } from "./IBaseManager.sol";

interface IAdapter {
    function manager() external view returns (IBaseManager);
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

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

import { ISetToken } from "@setprotocol/set-protocol-v2/contracts/interfaces/ISetToken.sol";
import { IIssuanceModule } from "@setprotocol/set-protocol-v2/contracts/interfaces/IIssuanceModule.sol";
import { PreciseUnitMath } from "@setprotocol/set-protocol-v2/contracts/lib/PreciseUnitMath.sol";

import { BaseGlobalExtension } from "../lib/BaseGlobalExtension.sol";
import { IDelegatedManager } from "../interfaces/IDelegatedManager.sol";
import { IManagerCore } from "../interfaces/IManagerCore.sol";

/**
 * @title IssuanceExtension
 * @author Set Protocol
 *
 * Smart contract global extension which provides DelegatedManager owner and methodologist the ability to accrue and split
 * issuance and redemption fees. Owner may configure the fee split percentages.
 *
 * Notes
 * - the fee split is set on the Delegated Manager contract
 * - when fees distributed via this contract will be inclusive of all fee types that have already been accrued
 */
contract IssuanceExtension is BaseGlobalExtension {
    using Address for address;
    using PreciseUnitMath for uint256;
    using SafeMath for uint256;

    /* ============ Events ============ */

    event IssuanceExtensionInitialized(
        address indexed _setToken,
        address indexed _delegatedManager
    );

    event FeesDistributed(
        address _setToken,
        address indexed _ownerFeeRecipient,
        address indexed _methodologist,
        uint256 _ownerTake,
        uint256 _methodologistTake
    );

    /* ============ State Variables ============ */

    // Instance of IssuanceModule
    IIssuanceModule public immutable issuanceModule;

    /* ============ Constructor ============ */

    constructor(
        IManagerCore _managerCore,
        IIssuanceModule _issuanceModule
    )
        public
        BaseGlobalExtension(_managerCore)
    {
        issuanceModule = _issuanceModule;
    }

    /* ============ External Functions ============ */

    /**
     * ANYONE CALLABLE: Distributes fees accrued to the DelegatedManager. Calculates fees for
     * owner and methodologist, and sends to owner fee recipient and methodologist respectively.
     */
    function distributeFees(ISetToken _setToken) public {
        IDelegatedManager delegatedManager = _manager(_setToken);

        uint256 totalFees = _setToken.balanceOf(address(delegatedManager));

        address methodologist = delegatedManager.methodologist();
        address ownerFeeRecipient = delegatedManager.ownerFeeRecipient();

        uint256 ownerTake = totalFees.preciseMul(delegatedManager.ownerFeeSplit());
        uint256 methodologistTake = totalFees.sub(ownerTake);

        if (ownerTake > 0) {
            delegatedManager.transferTokens(address(_setToken), ownerFeeRecipient, ownerTake);
        }

        if (methodologistTake > 0) {
            delegatedManager.transferTokens(address(_setToken), methodologist, methodologistTake);
        }

        emit FeesDistributed(address(_setToken), ownerFeeRecipient, methodologist, ownerTake, methodologistTake);
    }

    /**
     * ONLY OWNER: Initializes IssuanceModule on the SetToken associated with the DelegatedManager.
     *
     * @param _delegatedManager             Instance of the DelegatedManager to initialize the IssuanceModule for
     * @param _maxManagerFee                Maximum fee that can be charged on issue and redeem
     * @param _managerIssueFee              Fee to charge on issuance
     * @param _managerRedeemFee             Fee to charge on redemption
     * @param _feeRecipient                 Address to send fees to
     * @param _managerIssuanceHook          Instance of the contract with the Pre-Issuance Hook function
     */
    function initializeModule(
        IDelegatedManager _delegatedManager,
        uint256 _maxManagerFee,
        uint256 _managerIssueFee,
        uint256 _managerRedeemFee,
        address _feeRecipient,
        address _managerIssuanceHook
    )
        external
        onlyOwnerAndValidManager(_delegatedManager)
    {
        require(_delegatedManager.isInitializedExtension(address(this)), "Extension must be initialized");

        _initializeModule(
            _delegatedManager.setToken(),
            _delegatedManager,
            _maxManagerFee,
            _managerIssueFee,
            _managerRedeemFee,
            _feeRecipient,
            _managerIssuanceHook
        );
    }

    /**
     * ONLY OWNER: Initializes IssuanceExtension to the DelegatedManager.
     *
     * @param _delegatedManager     Instance of the DelegatedManager to initialize
     */
    function initializeExtension(IDelegatedManager _delegatedManager) external onlyOwnerAndValidManager(_delegatedManager) {
        require(_delegatedManager.isPendingExtension(address(this)), "Extension must be pending");

        ISetToken setToken = _delegatedManager.setToken();

        _initializeExtension(setToken, _delegatedManager);

        emit IssuanceExtensionInitialized(address(setToken), address(_delegatedManager));
    }

    /**
     * ONLY OWNER: Initializes IssuanceExtension to the DelegatedManager and IssuanceModule to the SetToken
     *
     * @param _delegatedManager             Instance of the DelegatedManager to initialize
     * @param _maxManagerFee                Maximum fee that can be charged on issue and redeem
     * @param _managerIssueFee              Fee to charge on issuance
     * @param _managerRedeemFee             Fee to charge on redemption
     * @param _feeRecipient                 Address to send fees to
     * @param _managerIssuanceHook          Instance of the contract with the Pre-Issuance Hook function
     */
    function initializeModuleAndExtension(
        IDelegatedManager _delegatedManager,
        uint256 _maxManagerFee,
        uint256 _managerIssueFee,
        uint256 _managerRedeemFee,
        address _feeRecipient,
        address _managerIssuanceHook
    )
        external
        onlyOwnerAndValidManager(_delegatedManager)
    {
        require(_delegatedManager.isPendingExtension(address(this)), "Extension must be pending");

        ISetToken setToken = _delegatedManager.setToken();

        _initializeExtension(setToken, _delegatedManager);
        _initializeModule(
            setToken,
            _delegatedManager,
            _maxManagerFee,
            _managerIssueFee,
            _managerRedeemFee,
            _feeRecipient,
            _managerIssuanceHook
        );

        emit IssuanceExtensionInitialized(address(setToken), address(_delegatedManager));
    }

    /**
     * ONLY MANAGER: Remove an existing SetToken and DelegatedManager tracked by the IssuanceExtension
     */
    function removeExtension() external override {
        IDelegatedManager delegatedManager = IDelegatedManager(msg.sender);
        ISetToken setToken = delegatedManager.setToken();

        _removeExtension(setToken, delegatedManager);
    }

    /**
     * ONLY OWNER: Updates issuance fee on IssuanceModule.
     *
     * @param _setToken     Instance of the SetToken to update issue fee for
     * @param _newFee       New issue fee percentage in precise units (1% = 1e16, 100% = 1e18)
     */
    function updateIssueFee(ISetToken _setToken, uint256 _newFee)
        external
        onlyOwner(_setToken)
    {
        bytes memory callData = abi.encodeWithSignature("updateIssueFee(address,uint256)", _setToken, _newFee);
        _invokeManager(_manager(_setToken), address(issuanceModule), callData);
    }

    /**
     * ONLY OWNER: Updates redemption fee on IssuanceModule.
     *
     * @param _setToken     Instance of the SetToken to update redeem fee for
     * @param _newFee       New redeem fee percentage in precise units (1% = 1e16, 100% = 1e18)
     */
    function updateRedeemFee(ISetToken _setToken, uint256 _newFee)
        external
        onlyOwner(_setToken)
    {
        bytes memory callData = abi.encodeWithSignature("updateRedeemFee(address,uint256)", _setToken, _newFee);
        _invokeManager(_manager(_setToken), address(issuanceModule), callData);
    }

    /**
     * ONLY OWNER: Updates fee recipient on IssuanceModule
     *
     * @param _setToken         Instance of the SetToken to update fee recipient for
     * @param _newFeeRecipient  Address of new fee recipient. This should be the address of the DelegatedManager
     */
    function updateFeeRecipient(ISetToken _setToken, address _newFeeRecipient)
        external
        onlyOwner(_setToken)
    {
        bytes memory callData = abi.encodeWithSignature("updateFeeRecipient(address,address)", _setToken, _newFeeRecipient);
        _invokeManager(_manager(_setToken), address(issuanceModule), callData);
    }

    /* ============ Internal Functions ============ */

    /**
     * Internal function to initialize IssuanceModule on the SetToken associated with the DelegatedManager.
     *
     * @param _setToken                     Instance of the SetToken corresponding to the DelegatedManager
     * @param _delegatedManager             Instance of the DelegatedManager to initialize the TradeModule for
     * @param _maxManagerFee                Maximum fee that can be charged on issue and redeem
     * @param _managerIssueFee              Fee to charge on issuance
     * @param _managerRedeemFee             Fee to charge on redemption
     * @param _feeRecipient                 Address to send fees to
     * @param _managerIssuanceHook          Instance of the contract with the Pre-Issuance Hook function
     */
    function _initializeModule(
        ISetToken _setToken,
        IDelegatedManager _delegatedManager,
        uint256 _maxManagerFee,
        uint256 _managerIssueFee,
        uint256 _managerRedeemFee,
        address _feeRecipient,
        address _managerIssuanceHook
    )
        internal
    {
        bytes memory callData = abi.encodeWithSignature(
            "initialize(address,uint256,uint256,uint256,address,address)",
            _setToken,
            _maxManagerFee,
            _managerIssueFee,
            _managerRedeemFee,
            _feeRecipient,
            _managerIssuanceHook
        );
        _invokeManager(_delegatedManager, address(issuanceModule), callData);
    }
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

import { ISetToken } from "@setprotocol/set-protocol-v2/contracts/interfaces/ISetToken.sol";
import { ITradeModule } from "@setprotocol/set-protocol-v2/contracts/interfaces/ITradeModule.sol";

import { BaseGlobalExtension } from "../lib/BaseGlobalExtension.sol";
import { IDelegatedManager } from "../interfaces/IDelegatedManager.sol";
import { IManagerCore } from "../interfaces/IManagerCore.sol";

/**
 * @title TradeExtension
 * @author Set Protocol
 *
 * Smart contract global extension which provides DelegatedManager privileged operator(s) the ability to trade on a DEX
 * and the owner the ability to restrict operator(s) permissions with an asset whitelist.
 */
contract TradeExtension is BaseGlobalExtension {

    /* ============ Events ============ */

    event TradeExtensionInitialized(
        address indexed _setToken,
        address indexed _delegatedManager
    );

    /* ============ State Variables ============ */

    // Instance of TradeModule
    ITradeModule public immutable tradeModule;

    /* ============ Constructor ============ */

    constructor(
        IManagerCore _managerCore,
        ITradeModule _tradeModule
    )
        public
        BaseGlobalExtension(_managerCore)
    {
        tradeModule = _tradeModule;
    }

    /* ============ External Functions ============ */

    /**
     * ONLY OWNER: Initializes TradeModule on the SetToken associated with the DelegatedManager.
     *
     * @param _delegatedManager     Instance of the DelegatedManager to initialize the TradeModule for
     */
    function initializeModule(IDelegatedManager _delegatedManager) external onlyOwnerAndValidManager(_delegatedManager) {
        require(_delegatedManager.isInitializedExtension(address(this)), "Extension must be initialized");

        _initializeModule(_delegatedManager.setToken(), _delegatedManager);
    }

    /**
     * ONLY OWNER: Initializes TradeExtension to the DelegatedManager.
     *
     * @param _delegatedManager     Instance of the DelegatedManager to initialize
     */
    function initializeExtension(IDelegatedManager _delegatedManager) external onlyOwnerAndValidManager(_delegatedManager) {
        require(_delegatedManager.isPendingExtension(address(this)), "Extension must be pending");

        ISetToken setToken = _delegatedManager.setToken();

        _initializeExtension(setToken, _delegatedManager);

        emit TradeExtensionInitialized(address(setToken), address(_delegatedManager));
    }

    /**
     * ONLY OWNER: Initializes TradeExtension to the DelegatedManager and TradeModule to the SetToken
     *
     * @param _delegatedManager     Instance of the DelegatedManager to initialize
     */
    function initializeModuleAndExtension(IDelegatedManager _delegatedManager) external onlyOwnerAndValidManager(_delegatedManager){
        require(_delegatedManager.isPendingExtension(address(this)), "Extension must be pending");

        ISetToken setToken = _delegatedManager.setToken();

        _initializeExtension(setToken, _delegatedManager);
        _initializeModule(setToken, _delegatedManager);

        emit TradeExtensionInitialized(address(setToken), address(_delegatedManager));
    }

    /**
     * ONLY MANAGER: Remove an existing SetToken and DelegatedManager tracked by the TradeExtension
     */
    function removeExtension() external override {
        IDelegatedManager delegatedManager = IDelegatedManager(msg.sender);
        ISetToken setToken = delegatedManager.setToken();

        _removeExtension(setToken, delegatedManager);
    }

    /**
     * ONLY OPERATOR: Executes a trade on a supported DEX.
     * @dev Although the SetToken units are passed in for the send and receive quantities, the total quantity
     * sent and received is the quantity of SetToken units multiplied by the SetToken totalSupply.
     *
     * @param _setToken             Instance of the SetToken to trade
     * @param _exchangeName         Human readable name of the exchange in the integrations registry
     * @param _sendToken            Address of the token to be sent to the exchange
     * @param _sendQuantity         Units of token in SetToken sent to the exchange
     * @param _receiveToken         Address of the token that will be received from the exchange
     * @param _minReceiveQuantity   Min units of token in SetToken to be received from the exchange
     * @param _data                 Arbitrary bytes to be used to construct trade call data
     */
    function trade(
        ISetToken _setToken,
        string memory _exchangeName,
        address _sendToken,
        uint256 _sendQuantity,
        address _receiveToken,
        uint256 _minReceiveQuantity,
        bytes memory _data
    )
        external
        onlyOperator(_setToken)
        onlyAllowedAsset(_setToken, _receiveToken)
    {
        bytes memory callData = abi.encodeWithSignature(
            "trade(address,string,address,uint256,address,uint256,bytes)",
            _setToken,
            _exchangeName,
            _sendToken,
            _sendQuantity,
            _receiveToken,
            _minReceiveQuantity,
            _data
        );
        _invokeManager(_manager(_setToken), address(tradeModule), callData);
    }

    /* ============ Internal Functions ============ */

    /**
     * Internal function to initialize TradeModule on the SetToken associated with the DelegatedManager.
     *
     * @param _setToken             Instance of the SetToken corresponding to the DelegatedManager
     * @param _delegatedManager     Instance of the DelegatedManager to initialize the TradeModule for
     */
    function _initializeModule(ISetToken _setToken, IDelegatedManager _delegatedManager) internal {
        bytes memory callData = abi.encodeWithSignature("initialize(address)", _setToken);
        _invokeManager(_delegatedManager, address(tradeModule), callData);
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

import { IBaseManager } from "./IBaseManager.sol";

interface IExtension {
    function manager() external view returns (IBaseManager);
}