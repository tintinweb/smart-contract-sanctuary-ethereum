/**
 *     SPDX-License-Identifier: Apache License 2.0
 *
 *     Copyright 2018 Set Labs Inc.
 *     Copyright 2022 Smash Works Inc.
 *
 *     Licensed under the Apache License, Version 2.0 (the "License");
 *     you may not use this file except in compliance with the License.
 *     You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 *     Unless required by applicable law or agreed to in writing, software
 *     distributed under the License is distributed on an "AS IS" BASIS,
 *     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *     See the License for the specific language governing permissions and
 *     limitations under the License.
 *
 *     NOTICE
 *
 *     This is a modified code from Set Labs Inc. found at
 *
 *     https://github.com/SetProtocol/set-protocol-contracts
 *
 *     All changes made by Smash Works Inc. are described and documented at
 *
 *     https://docs.arch.finance/chambers
 *
 *
 *             %@@@@@
 *          @@@@@@@@@@@
 *        #@@@@@     @@@           @@                   @@
 *       @@@@@@       @@@         @@@@                  @@
 *      @@@@@@         @@        @@  @@    @@@@@ @@@@@  @@@*@@
 *     [email protected]@@@@          @@@      @@@@@@@@   @@    @@     @@  @@
 *     @@@@@(       (((((      @@@    @@@  @@    @@@@@  @@  @@
 *    @@@@@@   (((((((
 *    @@@@@#(((((((
 *    @@@@@(((((
 *      @@@((
 */
pragma solidity ^0.8.17.0;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {ArrayUtils} from "./lib/ArrayUtils.sol";
import {IChamberGod} from "./interfaces/IChamberGod.sol";
import {IChamber} from "./interfaces/IChamber.sol";
import {PreciseUnitMath} from "./lib/PreciseUnitMath.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

contract Chamber is IChamber, Owned, ReentrancyGuard, ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 CONSTANTS
    //////////////////////////////////////////////////////////////*/

    IChamberGod private god;

    /*//////////////////////////////////////////////////////////////
                                 LIBRARIES
    //////////////////////////////////////////////////////////////*/

    using ArrayUtils for address[];
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;
    using Address for address;
    using PreciseUnitMath for uint256;

    /*//////////////////////////////////////////////////////////////
                            CHAMBER STORAGE
    //////////////////////////////////////////////////////////////*/

    address[] public constituents;

    mapping(address => uint256) public constituentQuantities;

    EnumerableSet.AddressSet private wizards;
    EnumerableSet.AddressSet private managers;
    EnumerableSet.AddressSet private allowedContracts;

    ChamberState private chamberLockState = ChamberState.UNLOCKED;

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyManager() virtual {
        require(isManager(msg.sender), "Must be Manager");

        _;
    }

    modifier onlyWizard() virtual {
        require(isWizard(msg.sender), "Must be a wizard");

        _;
    }

    modifier chambersNonReentrant() virtual {
        require(chamberLockState == ChamberState.UNLOCKED, "Non reentrancy allowed");
        chamberLockState = ChamberState.LOCKED;
        _;
        chamberLockState = ChamberState.UNLOCKED;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @param _owner        Owner of the chamber
     * @param _name         Name of the chamber token
     * @param _symbol       Symbol of the chamber token
     * @param _constituents Initial constituents addresses of the chamber
     * @param _quantities   Initial quantities of the chamber constituents
     * @param _wizards      Allowed addresses that can access onlyWizard functions
     * @param _managers     Allowed addresses that can access onlyManager functions
     */
    constructor(
        address _owner,
        string memory _name,
        string memory _symbol,
        address[] memory _constituents,
        uint256[] memory _quantities,
        address[] memory _wizards,
        address[] memory _managers
    ) Owned(_owner) ERC20(_name, _symbol, 18) {
        constituents = _constituents;
        god = IChamberGod(msg.sender);

        for (uint256 i = 0; i < _wizards.length; i++) {
            require(wizards.add(_wizards[i]), "Cannot add wizard");
        }

        for (uint256 i = 0; i < _managers.length; i++) {
            require(managers.add(_managers[i]), "Cannot add manager");
        }

        for (uint256 j = 0; j < _constituents.length; j++) {
            constituentQuantities[_constituents[j]] = _quantities[j];
        }
    }

    /*//////////////////////////////////////////////////////////////
                               CHAMBER MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    /**
     * Allows the wizard to add a new constituent to the Chamber
     *
     * @param _constituent The address of the constituent to add
     */
    function addConstituent(address _constituent) external onlyWizard nonReentrant {
        require(!isConstituent(_constituent), "Must not be constituent");

        constituents.push(_constituent);

        emit ConstituentAdded(_constituent);
    }

    /**
     * Allows the wizard to remove a constituent from the Chamber
     *
     * @param _constituent The address of the constituent to remove
     */
    function removeConstituent(address _constituent) external onlyWizard nonReentrant {
        require(isConstituent(_constituent), "Must be constituent");

        constituents.removeStorage(_constituent);

        emit ConstituentRemoved(_constituent);
    }

    /**
     * Checks if the address is a manager of the Chamber
     *
     * @param _manager The address of a manager
     *
     * @return bool True/False if the address is a manager or not
     */
    function isManager(address _manager) public view returns (bool) {
        return managers.contains(_manager);
    }

    /**
     * Checks if the address is a wizard of the Chamber
     *
     * @param _wizard The address of a wizard
     *
     * @return bool True/False if the address is a wizard or not
     */
    function isWizard(address _wizard) public view returns (bool) {
        return wizards.contains(_wizard);
    }

    /**
     * Checks if the address is a constituent of the Chamber
     *
     * @param _constituent The address of a constituent
     *
     * @return bool True/False if the address is a constituent or not
     */
    function isConstituent(address _constituent) public view returns (bool) {
        return constituents.contains(_constituent);
    }

    /**
     * Allows the Owner to add a new manager to the Chamber
     *
     * @param _manager The address of the manager to add
     */
    function addManager(address _manager) external onlyOwner nonReentrant {
        require(!isManager(_manager), "Already manager");
        require(_manager != address(0), "Cannot add null address");

        require(managers.add(_manager), "Cannot add manager");

        emit ManagerAdded(_manager);
    }

    /**
     * Allows the Owner to remove a manager from the Chamber
     *
     * @param _manager The address of the manager to remove
     */
    function removeManager(address _manager) external onlyOwner nonReentrant {
        require(isManager(_manager), "Not a manager");

        require(managers.remove(_manager), "Cannot remove manager");

        emit ManagerRemoved(_manager);
    }

    /**
     * Allows a Manager to add a new wizard to the Chamber
     *
     * @param _wizard The address of the wizard to add
     */
    function addWizard(address _wizard) external onlyManager nonReentrant {
        require(god.isWizard(_wizard), "Wizard not validated in ChamberGod");
        require(!isWizard(_wizard), "Wizard already in Chamber");

        require(wizards.add(_wizard), "Cannot add wizard");

        emit WizardAdded(_wizard);
    }

    /**
     * Allows a Manager to remove a wizard from the Chamber
     *
     * @param _wizard The address of the wizard to remove
     */
    function removeWizard(address _wizard) external onlyManager nonReentrant {
        require(isWizard(_wizard), "Wizard not in chamber");

        require(wizards.remove(_wizard), "Cannot remove wizard");

        emit WizardRemoved(_wizard);
    }

    /**
     * Returns an array with the addresses of all the constituents of the
     * Chamber
     *
     * @return an array of addresses for the constituents
     */
    function getConstituentsAddresses() external view returns (address[] memory) {
        return constituents;
    }

    /**
     * Returns an array with the quantities of all the constituents of the
     * Chamber
     *
     * @return an array of uint256 for the quantities of the constituents
     */
    function getQuantities() external view returns (uint256[] memory) {
        uint256[] memory quantities = new uint256[](constituents.length);
        for (uint256 i = 0; i < constituents.length; i++) {
            quantities[i] = constituentQuantities[constituents[i]];
        }

        return quantities;
    }

    /**
     * Returns the quantity of a constituent of the Chamber
     *
     * @param _constituent The address of the constituent
     *
     * @return uint256 The quantity of the constituent
     */
    function getConstituentQuantity(address _constituent) external view returns (uint256) {
        return constituentQuantities[_constituent];
    }

    /**
     * Returns the addresses of all the wizards of the Chamber
     *
     * @return address[] Array containing the addresses of the wizards of the Chamber
     */
    function getWizards() external view returns (address[] memory) {
        return wizards.values();
    }

    /**
     * Returns the addresses of all the managers of the Chamber
     *
     * @return address[] Array containing the addresses of the managers of the Chamber
     */
    function getManagers() external view returns (address[] memory) {
        return managers.values();
    }

    /**
     * Returns the addresses of all the allowedContracts of the Chamber
     *
     * @return address[] Array containing the addresses of the allowedContracts of the Chamber
     */
    function getAllowedContracts() external view returns (address[] memory) {
        return allowedContracts.values();
    }

    /**
     * Allows a Manager to add a new allowedContract to the Chamber
     *
     * @param _target The address of the allowedContract to add
     */
    function addAllowedContract(address _target) external onlyManager nonReentrant {
        require(god.isAllowedContract(_target), "Contract not allowed in ChamberGod");
        require(!isAllowedContract(_target), "Contract already allowed");

        require(allowedContracts.add(_target), "Cannot add contract");

        emit AllowedContractAdded(_target);
    }

    /**
     * Allows a Manager to remove an allowedContract from the Chamber
     *
     * @param _target The address of the allowedContract to remove
     */
    function removeAllowedContract(address _target) external onlyManager nonReentrant {
        require(isAllowedContract(_target), "Contract not allowed");

        require(allowedContracts.remove(_target), "Cannot remove contract");

        emit AllowedContractRemoved(_target);
    }

    /**
     * Checks if the address is an allowedContract of the Chamber
     *
     * @param _target The address of an allowedContract
     *
     * @return bool True/False if the address is an allowedContract or not
     */
    function isAllowedContract(address _target) public view returns (bool) {
        return allowedContracts.contains(_target);
    }

    /*//////////////////////////////////////////////////////////////
                               CHAMBER LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * Allows a wizard to mint an specific amount of chamber tokens
     * to a recipient
     *
     * @param _recipient   The address of the recipient
     * @param _quantity    The quantity of the chamber to mint
     */
    function mint(address _recipient, uint256 _quantity) external onlyWizard nonReentrant {
        _mint(_recipient, _quantity);
    }

    /**
     * Allows a wizard to burn an specific amount of chamber tokens
     * from a source
     *
     * @param _from          The address of the source to burn from
     * @param _quantity      The quantity of the chamber tokens to burn
     */
    function burn(address _from, uint256 _quantity) external onlyWizard nonReentrant {
        _burn(_from, _quantity);
    }

    /**
     * Locks the chamber from potentially malicious outside calls of contracts
     * that were not created by arch-protocol
     */
    function lockChamber() external onlyWizard nonReentrant {
        require(chamberLockState == ChamberState.UNLOCKED, "Chamber locked");
        chamberLockState = ChamberState.LOCKED;
    }

    /**
     * Unlocks the chamber from potentially malicious outside calls of contracts
     * that were not created by arch-protocol
     */
    function unlockChamber() external onlyWizard nonReentrant {
        require(chamberLockState == ChamberState.LOCKED, "Chamber already unlocked");
        chamberLockState = ChamberState.UNLOCKED;
    }

    /**
     * Allows a wizard to transfer an specific amount of constituent tokens
     * to a recipient
     *
     * @param _constituent   The address of the constituent
     * @param _recipient     The address of the recipient to transfer tokens to
     * @param _quantity      The quantity of the constituent to transfer
     */
    function withdrawTo(address _constituent, address _recipient, uint256 _quantity)
        external
        onlyWizard
        nonReentrant
    {
        if (_quantity > 0) {
            // Retrieve current balance of token for the vault
            uint256 existingVaultBalance = IERC20(_constituent).balanceOf(address(this));

            // Call specified ERC20 token contract to transfer tokens from Vault to user
            IERC20(_constituent).safeTransfer(_recipient, _quantity);

            // Verify transfer quantity is reflected in balance
            uint256 newVaultBalance = IERC20(_constituent).balanceOf(address(this));

            // Check to make sure current balances are as expected
            require(
                newVaultBalance >= existingVaultBalance - _quantity,
                "Chamber.withdrawTo: Invalid post-withdraw balance"
            );
        }
    }

    /**
     * Update the quantities of the constituents in the chamber based on the
     * total suppply of tokens. Only considers constituents in the constituents
     * list. Used by wizards. E.g. after an uncollateralized mint in the streaming fee wizard .
     *
     */
    function updateQuantities() external onlyWizard nonReentrant chambersNonReentrant {
        for (uint256 i = 0; i < constituents.length; i++) {
            address _constituent = constituents[i];
            uint256 currentBalance = IERC20(_constituent).balanceOf(address(this));
            uint256 _newQuantity = currentBalance.preciseDiv(totalSupply, decimals);

            require(_newQuantity > 0, "Zero quantity not allowed");

            constituentQuantities[_constituent] = _newQuantity;
        }
    }

    /**
     * Allows wizards to make low level calls to contracts that have been
     * added to the allowedContracts mapping.
     *
     * @param _sellToken          The address of the token to sell
     * @param _sellQuantity       The amount of sellToken to sell
     * @param _buyToken           The address of the token to buy
     * @param _minBuyQuantity     The minimum amount of buyToken that should be bought
     * @param _data               The data to be passed to the contract
     * @param _target            The address of the contract to call
     * @param _allowanceTarget    The address of the contract to give allowance of tokens
     *
     * @return tokenAmountBought  The amount of buyToken bought
     */
    function executeTrade(
        address _sellToken,
        uint256 _sellQuantity,
        address _buyToken,
        uint256 _minBuyQuantity,
        bytes memory _data,
        address payable _target,
        address _allowanceTarget
    ) external onlyWizard nonReentrant returns (uint256 tokenAmountBought) {
        require(_target != address(this), "Cannot invoke the Chamber");
        require(isAllowedContract(_target), "Target not allowed");
        uint256 tokenAmountBefore = IERC20(_buyToken).balanceOf(address(this));
        uint256 currentAllowance = IERC20(_sellToken).allowance(address(this), _allowanceTarget);

        if (currentAllowance < _sellQuantity) {
            IERC20(_sellToken).safeIncreaseAllowance(
                _allowanceTarget, (_sellQuantity - currentAllowance)
            );
        }
        _invokeContract(_data, _target);

        currentAllowance = IERC20(_sellToken).allowance(address(this), _allowanceTarget);
        IERC20(_sellToken).safeDecreaseAllowance(_allowanceTarget, currentAllowance);

        uint256 tokenAmountAfter = IERC20(_buyToken).balanceOf(address(this));
        tokenAmountBought = tokenAmountAfter - tokenAmountBefore;
        require(tokenAmountBought >= _minBuyQuantity, "Underbought buy quantity");

        return tokenAmountBought;
    }

    /**
     * Low level call to a contract. Only allowed contracts can be called.
     *
     * @param _data           The encoded calldata to be passed to the contract
     * @param _target         The address of the contract to call
     *
     * @return response       The response bytes from the contract call
     */
    function _invokeContract(bytes memory _data, address payable _target)
        internal
        returns (bytes memory response)
    {
        response = address(_target).functionCall(_data);
        require(response.length > 0, "Low level functionCall failed");
        return (response);
    }
}

/**
 *     SPDX-License-Identifier: Apache License 2.0
 *
 *     Copyright 2018 Set Labs Inc.
 *     Copyright 2022 Smash Works Inc.
 *
 *     Licensed under the Apache License, Version 2.0 (the "License");
 *     you may not use this file except in compliance with the License.
 *     You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 *     Unless required by applicable law or agreed to in writing, software
 *     distributed under the License is distributed on an "AS IS" BASIS,
 *     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *     See the License for the specific language governing permissions and
 *     limitations under the License.
 *
 *     NOTICE
 *
 *     This is a modified code from Set Labs Inc. found at
 *
 *     https://github.com/SetProtocol/set-protocol-contracts
 *
 *     All changes made by Smash Works Inc. are described and documented at
 *
 *     https://docs.arch.finance/chambers
 *
 *
 *             %@@@@@
 *          @@@@@@@@@@@
 *        #@@@@@     @@@           @@                   @@
 *       @@@@@@       @@@         @@@@                  @@
 *      @@@@@@         @@        @@  @@    @@@@@ @@@@@  @@@*@@
 *     [email protected]@@@@          @@@      @@@@@@@@   @@    @@     @@  @@
 *     @@@@@(       (((((      @@@    @@@  @@    @@@@@  @@  @@
 *    @@@@@@   (((((((
 *    @@@@@#(((((((
 *    @@@@@(((((
 *      @@@((
 */
pragma solidity ^0.8.17.0;

interface IChamber {
    /*//////////////////////////////////////////////////////////////
                                 ENUMS
    //////////////////////////////////////////////////////////////*/

    enum ChamberState {
        LOCKED,
        UNLOCKED
    }

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event ManagerAdded(address indexed _manager);

    event ManagerRemoved(address indexed _manager);

    event ConstituentAdded(address indexed _constituent);

    event ConstituentRemoved(address indexed _constituent);

    event WizardAdded(address indexed _wizard);

    event WizardRemoved(address indexed _wizard);

    event AllowedContractAdded(address indexed _allowedContract);

    event AllowedContractRemoved(address indexed _allowedContract);

    /*//////////////////////////////////////////////////////////////
                               CHAMBER MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    function addConstituent(address _constituent) external;

    function removeConstituent(address _constituent) external;

    function isManager(address _manager) external view returns (bool);

    function isWizard(address _wizard) external view returns (bool);

    function isConstituent(address _constituent) external view returns (bool);

    function addManager(address _manager) external;

    function removeManager(address _manager) external;

    function addWizard(address _wizard) external;

    function removeWizard(address _wizard) external;

    function getConstituentsAddresses() external view returns (address[] memory);

    function getQuantities() external view returns (uint256[] memory);

    function getConstituentQuantity(address _constituent) external view returns (uint256);

    function getWizards() external view returns (address[] memory);

    function getManagers() external view returns (address[] memory);

    function getAllowedContracts() external view returns (address[] memory);

    function mint(address _recipient, uint256 _quantity) external;

    function burn(address _from, uint256 _quantity) external;

    function withdrawTo(address _constituent, address _recipient, uint256 _quantity) external;

    function updateQuantities() external;

    function lockChamber() external;

    function unlockChamber() external;

    function addAllowedContract(address target) external;

    function removeAllowedContract(address target) external;

    function isAllowedContract(address _target) external returns (bool);

    function executeTrade(
        address _sellToken,
        uint256 _sellQuantity,
        address _buyToken,
        uint256 _minBuyQuantity,
        bytes memory _data,
        address payable _target,
        address _allowanceTarget
    ) external returns (uint256 tokenAmountBought);
}

/**
 *     SPDX-License-Identifier: Apache License 2.0
 *
 *     Copyright 2018 Set Labs Inc.
 *     Copyright 2022 Smash Works Inc.
 *
 *     Licensed under the Apache License, Version 2.0 (the "License");
 *     you may not use this file except in compliance with the License.
 *     You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 *     Unless required by applicable law or agreed to in writing, software
 *     distributed under the License is distributed on an "AS IS" BASIS,
 *     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *     See the License for the specific language governing permissions and
 *     limitations under the License.
 *
 *     NOTICE
 *
 *     This is a modified code from Set Labs Inc. found at
 *
 *     https://github.com/SetProtocol/set-protocol-contracts
 *
 *     All changes made by Smash Works Inc. are described and documented at
 *
 *     https://docs.arch.finance/chambers
 *
 *
 *             %@@@@@
 *          @@@@@@@@@@@
 *        #@@@@@     @@@           @@                   @@
 *       @@@@@@       @@@         @@@@                  @@
 *      @@@@@@         @@        @@  @@    @@@@@ @@@@@  @@@*@@
 *     [email protected]@@@@          @@@      @@@@@@@@   @@    @@     @@  @@
 *     @@@@@(       (((((      @@@    @@@  @@    @@@@@  @@  @@
 *    @@@@@@   (((((((
 *    @@@@@#(((((((
 *    @@@@@(((((
 *      @@@((
 */
pragma solidity ^0.8.17.0;

interface IChamberGod {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event ChamberCreated(address indexed _chamber, address _owner, string _name, string _symbol);

    event WizardAdded(address indexed _wizard);

    event WizardRemoved(address indexed _wizard);

    event AllowedContractAdded(address indexed _allowedContract);

    event AllowedContractRemoved(address indexed _allowedContract);

    /*//////////////////////////////////////////////////////////////
                            CHAMBER GOD LOGIC
    //////////////////////////////////////////////////////////////*/

    function createChamber(
        string memory _name,
        string memory _symbol,
        address[] memory _constituents,
        uint256[] memory _quantities,
        address[] memory _wizards,
        address[] memory _managers
    ) external returns (address);

    function getWizards() external view returns (address[] memory);

    function getChambers() external view returns (address[] memory);

    function isWizard(address _wizard) external view returns (bool);

    function isChamber(address _chamber) external view returns (bool);

    function addWizard(address _wizard) external;

    function removeWizard(address _wizard) external;

    function getAllowedContracts() external view returns (address[] memory);

    function addAllowedContract(address _target) external;

    function removeAllowedContract(address _target) external;

    function isAllowedContract(address _target) external view returns (bool);
}

/**
 *     SPDX-License-Identifier: Apache License 2.0
 *
 *     Copyright 2018 Set Labs Inc.
 *     Copyright 2022 Smash Works Inc.
 *
 *     Licensed under the Apache License, Version 2.0 (the "License");
 *     you may not use this file except in compliance with the License.
 *     You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 *     Unless required by applicable law or agreed to in writing, software
 *     distributed under the License is distributed on an "AS IS" BASIS,
 *     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *     See the License for the specific language governing permissions and
 *     limitations under the License.
 *
 *     NOTICE
 *
 *     This is a modified code from Set Labs Inc. found at
 *
 *     https://github.com/SetProtocol/set-protocol-contracts
 *
 *     All changes made by Smash Works Inc. are described and documented at
 *
 *     https://docs.arch.finance/chambers
 *
 *
 *             %@@@@@
 *          @@@@@@@@@@@
 *        #@@@@@     @@@           @@                   @@
 *       @@@@@@       @@@         @@@@                  @@
 *      @@@@@@         @@        @@  @@    @@@@@ @@@@@  @@@*@@
 *     [email protected]@@@@          @@@      @@@@@@@@   @@    @@     @@  @@
 *     @@@@@(       (((((      @@@    @@@  @@    @@@@@  @@  @@
 *    @@@@@@   (((((((
 *    @@@@@#(((((((
 *    @@@@@(((((
 *      @@@((
 */
pragma solidity ^0.8.17.0;

library ArrayUtils {
    /**
     * Returns the index of the element 'a' in the _array provided. It also returns true if
     * the element was found, and false if not, as -1 is not a possible output.
     *
     * @param _array    Array to check
     * @param a         Element to check in array
     *
     * @return A tuple with the index of the element, and a bool
     */
    function indexOf(address[] memory _array, address a) internal pure returns (uint256, bool) {
        uint256 length = _array.length;
        for (uint256 i = 0; i < length; i++) {
            if (_array[i] == a) {
                return (i, true);
            }
        }
        return (0, false);
    }

    /**
     * Returns true if the element 'a' is in the _array provided, and false otherwise.
     *
     * @param _array    Array to check
     * @param a         Element to check in array
     *
     * @return True if the element is present in the array
     */
    function contains(address[] memory _array, address a) internal pure returns (bool) {
        (, bool isIn) = indexOf(_array, a);
        return isIn;
    }

    /**
     * Returns true if the _array contains duplicates, and false otherwise.
     *
     * @param _array    Array to check
     *
     * @return True if there are duplicates in the array
     */
    function hasDuplicate(address[] memory _array) internal pure returns (bool) {
        require(_array.length > 0, "_array is empty");

        for (uint256 i = 0; i < _array.length - 1; i++) {
            address current = _array[i];
            for (uint256 j = i + 1; j < _array.length; j++) {
                if (current == _array[j]) {
                    return true;
                }
            }
        }
        return false;
    }

    /**
     * Removes the element 'a' from the memory _array if present. Will revert if the
     * element is not present. Returns a new array.
     *
     * @param _array    Array to check
     * @param a         Element to remove
     *
     * @return A new array without the element
     */
    function remove(address[] memory _array, address a) internal pure returns (address[] memory) {
        (uint256 index, bool isIn) = indexOf(_array, a);
        if (!isIn) {
            revert("Address not in array");
        } else {
            (address[] memory _newArray,) = pop(_array, index);
            return _newArray;
        }
    }

    /**
     * Removes the element 'a' from the storage _array if present. Will revert if the
     * element is not present. Moves the last element in the _array to the index in
     * which the element 'a' is present. Changes the array in-place.
     *
     * @param _array    Array to modify
     * @param a         Element to remove
     */
    function removeStorage(address[] storage _array, address a) internal {
        (uint256 index, bool isIn) = indexOf(_array, a);
        if (!isIn) {
            revert("Address not in array");
        } else {
            uint256 lastIndex = _array.length - 1; // If the array would be empty, the previous line would throw, so no underflow here
            if (index != lastIndex) _array[index] = _array[lastIndex];
            _array.pop();
        }
    }

    /**
     * Removes from the array the element in the index specified. Returns a new array and
     * the element removed, as a tuple.
     *
     * @param _array    Array to modify
     * @param index     Index of element to remove
     *
     * @return New array amd the removed element, as a tuple
     */
    function pop(address[] memory _array, uint256 index)
        internal
        pure
        returns (address[] memory, address)
    {
        uint256 length = _array.length;
        require(index < _array.length, "Index must be < _array length");
        address[] memory newAddresses = new address[](length - 1);
        for (uint256 i = 0; i < index; i++) {
            newAddresses[i] = _array[i];
        }
        for (uint256 j = index + 1; j < length; j++) {
            newAddresses[j - 1] = _array[j];
        }
        return (newAddresses, _array[index]);
    }
}

/**
 *     SPDX-License-Identifier: Apache License 2.0
 *
 *     Copyright 2018 Set Labs Inc.
 *     Copyright 2022 Smash Works Inc.
 *
 *     Licensed under the Apache License, Version 2.0 (the "License");
 *     you may not use this file except in compliance with the License.
 *     You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 *     Unless required by applicable law or agreed to in writing, software
 *     distributed under the License is distributed on an "AS IS" BASIS,
 *     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *     See the License for the specific language governing permissions and
 *     limitations under the License.
 *
 *     NOTICE
 *
 *     This is a modified code from Set Labs Inc. found at
 *
 *     https://github.com/SetProtocol/set-protocol-contracts
 *
 *     All changes made by Smash Works Inc. are described and documented at
 *
 *     https://docs.arch.finance/chambers
 *
 *
 *             %@@@@@
 *          @@@@@@@@@@@
 *        #@@@@@     @@@           @@                   @@
 *       @@@@@@       @@@         @@@@                  @@
 *      @@@@@@         @@        @@  @@    @@@@@ @@@@@  @@@*@@
 *     [email protected]@@@@          @@@      @@@@@@@@   @@    @@     @@  @@
 *     @@@@@(       (((((      @@@    @@@  @@    @@@@@  @@  @@
 *    @@@@@@   (((((((
 *    @@@@@#(((((((
 *    @@@@@(((((
 *      @@@((
 */
pragma solidity ^0.8.17.0;

library PreciseUnitMath {
    /**
     * Multiplies value _a by value _b (result is rounded down). It's assumed that the value _b is the significand
     * of a number with _deicmals precision, so the result of the multiplication will be divided by [10e_decimals].
     * The result can be interpreted as [wei].
     *
     * @param _a          Unsigned integer [wei]
     * @param _b          Unsigned integer [10e_decimals]
     * @param _decimals   Decimals of _b
     */
    function preciseMul(uint256 _a, uint256 _b, uint256 _decimals)
        internal
        pure
        returns (uint256)
    {
        uint256 preciseUnit = 10 ** _decimals;
        return (_a * _b) / preciseUnit;
    }

    /**
     * Multiplies value _a by value _b (result is rounded up). It's assumed that the value _b is the significand
     * of a number with _decimals precision, so the result of the multiplication will be divided by [10e_decimals].
     * The result will never reach zero. The result can be interpreted as [wei].
     *
     * @param _a          Unsigned integer [wei]
     * @param _b          Unsigned integer [10e_decimals]
     * @param _decimals   Decimals of _b
     */
    function preciseMulCeil(uint256 _a, uint256 _b, uint256 _decimals)
        internal
        pure
        returns (uint256)
    {
        if (_a == 0 || _b == 0) {
            return 0;
        }
        uint256 preciseUnit = 10 ** _decimals;
        return (((_a * _b) - 1) / preciseUnit) + 1;
    }

    /**
     * Divides value _a by value _b (result is rounded down). Value _a is scaled up to match value _b decimals.
     * The result can be interpreted as [wei].
     *
     * @param _a          Unsigned integer [wei]
     * @param _b          Unsigned integer [10e_decimals]
     * @param _decimals   Decimals of _b
     */
    function preciseDiv(uint256 _a, uint256 _b, uint256 _decimals)
        internal
        pure
        returns (uint256)
    {
        require(_b != 0, "Cannot divide by 0");

        uint256 preciseUnit = 10 ** _decimals;
        return (_a * preciseUnit) / _b;
    }

    /**
     * Divides value _a by value _b (result is rounded up or away from 0). Value _a is scaled up to match
     * value _b decimals. The result will never be zero, except when _a is zero. The result can be interpreted
     * as [wei].
     *
     * @param _a          Unsigned integer [wei]
     * @param _b          Unsigned integer [10e_decimals]
     * @param _decimals   Decimals of _b
     */
    function preciseDivCeil(uint256 _a, uint256 _b, uint256 _decimals)
        internal
        pure
        returns (uint256)
    {
        require(_b != 0, "Cannot divide by 0");

        uint256 preciseUnit = 10 ** _decimals;
        return _a > 0 ? ((((_a * preciseUnit) - 1) / _b) + 1) : 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
import "../../../utils/Address.sol";

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
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}