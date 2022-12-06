// Copyright (C) 2021  Echooo Labs Ltd. <https://echooo.xyz>

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.3;

import "../../trustlists_contracts/interfaces/IFilter.sol";
import "../../trustlists_contracts/DappRegistry.sol";
import "../storage/ITransferStorage.sol";
import "../../modules/common/Utils.sol";

/**
 * @title MultiCallHelper
 * @notice Helper contract that can be used to check in 1 call if and why a sequence of transactions is authorised to be executed by a wallet.
 * @author Skywalker - <[email protected]>
 */
contract MultiCallHelper {

    uint256 private constant MAX_UINT = type(uint256).max;

    struct Call {
        address to;
        uint256 value;
        bytes data;
    }

    // The trusted contacts storage
    ITransferStorage internal immutable userWhitelist;
    // The dapp registry contract
    DappRegistry internal immutable dappRegistry;

    constructor(ITransferStorage _userWhitelist, DappRegistry _dappRegistry) {
        userWhitelist = _userWhitelist;
        dappRegistry = _dappRegistry;
    }

    /**
     * @notice Checks if a sequence of transactions is authorised to be executed by a wallet.
     * The method returns false if any of the inner transaction is not to a trusted contact or an authorised dapp.
     * @param _wallet The target wallet.
     * @param _transactions The sequence of transactions.
     */
    function isMultiCallAuthorised(address _wallet, Call[] calldata _transactions) external view returns (bool) {
        for(uint i = 0; i < _transactions.length; i++) {
            address spender = Utils.recoverSpender(_transactions[i].to, _transactions[i].data);
            if (
                (spender != _transactions[i].to && _transactions[i].value != 0) ||
                (!isWhitelisted(_wallet, spender) && isAuthorised(_wallet, spender, _transactions[i].to, _transactions[i].data) == MAX_UINT)
            ) {
                return false;
            }
        }
        return true;
    }

    /**
     * @notice Checks if each of the transaction of a sequence of transactions is authorised to be executed by a wallet.
     * For each transaction of the sequence it returns an Id where:
     *     - Id is in [0,255]: the transaction is to an address authorised in registry Id of the DappRegistry
     *     - Id = 256: the transaction is to an address authorised in the trusted contacts of the wallet
     *     - Id = MAX_UINT: the transaction is not authorised
     * @param _wallet The target wallet.
     * @param _transactions The sequence of transactions.
     */
    function multiCallAuthorisation(address _wallet, Call[] calldata _transactions) external view returns (uint256[] memory registryIds) {
        registryIds = new uint256[](_transactions.length);
        for(uint i = 0; i < _transactions.length; i++) {
            address spender = Utils.recoverSpender(_transactions[i].to, _transactions[i].data);
            if (spender != _transactions[i].to && _transactions[i].value != 0) {
                registryIds[i] = MAX_UINT;
            } else if (isWhitelisted(_wallet, spender)) {
                registryIds[i] = 256;
            } else {
                registryIds[i] = isAuthorised(_wallet, spender, _transactions[i].to, _transactions[i].data);
            }
        }
    }

    function isAuthorised(address _wallet, address _spender, address _to, bytes calldata _data) internal view returns (uint256) {
        uint registries = uint(dappRegistry.enabledRegistryIds(_wallet));
        // Check Echooo Default Registry first. It is enabled by default, implying that a zero 
        // at position 0 of the `registries` bit vector means that the Echooo Registry is enabled)
        for(uint registryId = 0; registryId == 0 || (registries >> registryId) > 0; registryId++) {
            bool isEnabled = (((registries >> registryId) & 1) > 0) /* "is bit set for regId?" */ == (registryId > 0) /* "not Echooo registry?" */;
            if(isEnabled) { // if registryId is enabled
                uint auth = uint(dappRegistry.authorisations(uint8(registryId), _spender)); 
                uint validAfter = auth & 0xffffffffffffffff;
                if (0 < validAfter && validAfter <= block.timestamp) { // if the current time is greater than the validity time
                    address filter = address(uint160(auth >> 64));
                    if(filter == address(0) || IFilter(filter).isValid(_wallet, _spender, _to, _data)) {
                        return registryId;
                    }
                }
            }
        }
        return MAX_UINT;
    }

    function isAuthorisedInRegistry(address _wallet, Call[] calldata _transactions, uint8 _registryId) external view returns (bool) {
        for(uint i = 0; i < _transactions.length; i++) {
            address spender = Utils.recoverSpender(_transactions[i].to, _transactions[i].data);

            uint auth = uint(dappRegistry.authorisations(_registryId, spender)); 
            uint validAfter = auth & 0xffffffffffffffff;
            if (0 < validAfter && validAfter <= block.timestamp) { // if the current time is greater than the validity time
                address filter = address(uint160(auth >> 64));
                if(filter != address(0) && !IFilter(filter).isValid(_wallet, spender, _transactions[i].to, _transactions[i].data)) {
                    return false;
                }
            } else {
                return false;
            }
        }

        return true;
    }

    function isWhitelisted(address _wallet, address _target) internal view returns (bool _isWhitelisted) {
        uint whitelistAfter = userWhitelist.getWhitelist(_wallet, _target);
        return whitelistAfter > 0 && whitelistAfter < block.timestamp;
    }
}

// Copyright (C) 2021  Argent Labs Ltd. <https://argent.xyz>

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.3;

interface IFilter {
    function isValid(address _wallet, address _spender, address _to, bytes calldata _data) external view returns (bool valid);
}

// Copyright (C) 2021  Argent Labs Ltd. <https://argent.xyz>

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.3;

import "./interfaces/IAuthoriser.sol";
import "./interfaces/IFilter.sol";

contract DappRegistry is IAuthoriser {

    // The timelock period
    uint64 public timelockPeriod;
    // The new timelock period
    uint64 public newTimelockPeriod;
    // Time at which the new timelock becomes effective
    uint64 public timelockPeriodChangeAfter;

    // bit vector of enabled registry ids for each wallet
    mapping (address => bytes32) public enabledRegistryIds; // [wallet] => [bit vector of 256 registry ids]
    // authorised dapps and their filters for each registry id
    mapping (uint8 => mapping (address => bytes32)) public authorisations; // [registryId] => [dapp] => [{filter:160}{validAfter:64}]
    // pending authorised dapps and their filters for each registry id
    mapping (uint8 => mapping (address => bytes32)) public pendingFilterUpdates; // [registryId] => [dapp] => [{filter:160}{validAfter:64}]
    // owners for each registry id
    mapping (uint8 => address) public registryOwners; // [registryId] => [owner]
    
    event RegistryCreated(uint8 registryId, address registryOwner);
    event OwnerChanged(uint8 registryId, address newRegistryOwner);
    event TimelockChangeRequested(uint64 newTimelockPeriod);
    event TimelockChanged(uint64 newTimelockPeriod);
    event FilterUpdated(uint8 indexed registryId, address dapp, address filter, uint256 validAfter);
    event FilterUpdateRequested(uint8 indexed registryId, address dapp, address filter, uint256 validAfter);
    event DappAdded(uint8 indexed registryId, address dapp, address filter, uint256 validAfter);
    event DappRemoved(uint8 indexed registryId, address dapp);
    event ToggledRegistry(address indexed sender, uint8 registryId, bool enabled);

    modifier onlyOwner(uint8 _registryId) {
        validateOwner(_registryId);
        _;
    }
    
    constructor(uint64 _timelockPeriod) {
        // set the timelock period
        timelockPeriod = _timelockPeriod;
        // set the owner of the Argent Registry (registryId = 0)
        registryOwners[0] = msg.sender;

        emit RegistryCreated(0, msg.sender);
        emit TimelockChanged(_timelockPeriod);
    }

    /********* Wallet-centered functions *************/

    /**
    * @notice Returns whether a registry is enabled for a wallet
    * @param _wallet The wallet
    * @param _registryId The registry id
    */
    function isEnabledRegistry(address _wallet, uint8 _registryId) external view returns (bool isEnabled) {
        uint registries = uint(enabledRegistryIds[_wallet]);
        return (((registries >> _registryId) & 1) > 0) /* "is bit set for regId?" */ == (_registryId > 0) /* "not Argent registry?" */;
    }

    /**
    * @notice Returns whether a (_spender, _to, _data) call is authorised for a wallet
    * @param _wallet The wallet
    * @param _spender The spender of the tokens for token approvals, or the target of the transaction otherwise
    * @param _to The target of the transaction
    * @param _data The calldata of the transaction
    */
    function isAuthorised(address _wallet, address _spender, address _to, bytes calldata _data) public view override returns (bool) {
        uint registries = uint(enabledRegistryIds[_wallet]);
        // Check Argent Default Registry first. It is enabled by default, implying that a zero 
        // at position 0 of the `registries` bit vector means that the Argent Registry is enabled)
        for(uint registryId = 0; registryId == 0 || (registries >> registryId) > 0; registryId++) {
            bool isEnabled = (((registries >> registryId) & 1) > 0) /* "is bit set for regId?" */ == (registryId > 0) /* "not Argent registry?" */;
            if(isEnabled) { // if registryId is enabled
                uint auth = uint(authorisations[uint8(registryId)][_spender]); 
                uint validAfter = auth & 0xffffffffffffffff;
                if (0 < validAfter && validAfter <= block.timestamp) { // if the current time is greater than the validity time
                    address filter = address(uint160(auth >> 64));
                    if(filter == address(0) || IFilter(filter).isValid(_wallet, _spender, _to, _data)) {
                        return true;
                    }
                }
            }
        }
        return false;
    }

    /**
    * @notice Returns whether a collection of (_spender, _to, _data) calls are authorised for a wallet
    * @param _wallet The wallet
    * @param _spenders The spenders of the tokens for token approvals, or the targets of the transaction otherwise
    * @param _to The targets of the transaction
    * @param _data The calldata of the transaction
    */
    function areAuthorised(
        address _wallet,
        address[] calldata _spenders,
        address[] calldata _to,
        bytes[] calldata _data
    )
        external
        view
        override
        returns (bool) 
    {
        for(uint i = 0; i < _spenders.length; i++) {
            if(!isAuthorised(_wallet, _spenders[i], _to[i], _data[i])) {
                return false;
            }
        }
        return true;
    }

    /**
    * @notice Allows a wallet to decide whether _registryId should be part of the list of enabled registries for that wallet
    * @param _registryId The id of the registry to enable/disable
    * @param _enabled Whether the registry should be enabled (true) or disabled (false)
    */
    function toggleRegistry(uint8 _registryId, bool _enabled) external {
        require(registryOwners[_registryId] != address(0), "DR: unknown registry");
        uint registries = uint(enabledRegistryIds[msg.sender]);
        bool current = (((registries >> _registryId) & 1) > 0) /* "is bit set for regId?" */ == (_registryId > 0) /* "not Argent registry?" */;
        if(current != _enabled) {
            enabledRegistryIds[msg.sender] = bytes32(registries ^ (uint(1) << _registryId)); // toggle [_registryId]^th bit
            emit ToggledRegistry(msg.sender, _registryId, _enabled);
        }
    }

    /**************  Management of registry list  *****************/

    /**
    * @notice Create a new registry. Only the owner of the Argent registry (i.e. the registry with id 0 -- hence the use of `onlyOwner(0)`)
    * can create a new registry.
    * @param _registryId The id of the registry to create
    * @param _registryOwner The owner of that new registry
    */
    function createRegistry(uint8 _registryId, address _registryOwner) external onlyOwner(0) {
        require(_registryOwner != address(0), "DR: registry owner is 0");
        require(registryOwners[_registryId] == address(0), "DR: duplicate registry");
        registryOwners[_registryId] = _registryOwner;
        emit RegistryCreated(_registryId, _registryOwner);
    }

    // Note: removeRegistry is not supported because that would allow the owner to replace registries that 
    // have already been enabled by users with a new (potentially maliciously populated) registry 

    /**
    * @notice Lets a registry owner change the owner of the registry.
    * @param _registryId The id of the registry
    * @param _newRegistryOwner The new owner of the registry
    */
    function changeOwner(uint8 _registryId, address _newRegistryOwner) external onlyOwner(_registryId) {
        require(_newRegistryOwner != address(0), "DR: new registry owner is 0");
        registryOwners[_registryId] = _newRegistryOwner;
        emit OwnerChanged(_registryId, _newRegistryOwner);
    }

    /**
    * @notice Request a change of the timelock value. Only the owner of the Argent registry (i.e. the registry with id 0 -- 
    * hence the use of `onlyOwner(0)`) can perform that action. This action can be confirmed after the (old) timelock period.
    * @param _newTimelockPeriod The new timelock period
    */
    function requestTimelockChange(uint64 _newTimelockPeriod) external onlyOwner(0) {
        newTimelockPeriod = _newTimelockPeriod;
        timelockPeriodChangeAfter = uint64(block.timestamp) + timelockPeriod;
        emit TimelockChangeRequested(_newTimelockPeriod);
    }

    /**
    * @notice Confirm a change of the timelock value requested by `requestTimelockChange()`.
    */
    function confirmTimelockChange() external {
        uint64 newPeriod = newTimelockPeriod;
        require(timelockPeriodChangeAfter > 0 && timelockPeriodChangeAfter <= block.timestamp, "DR: can't (yet) change timelock");
        timelockPeriod = newPeriod;
        newTimelockPeriod = 0;
        timelockPeriodChangeAfter = 0;
        emit TimelockChanged(newPeriod);
    }

    /**************  Management of registries' content  *****************/

    /**
    * @notice Returns the (filter, validAfter) tuple recorded for a dapp in a given registry.
    * `filter` is the authorisation filter stored for the dapp (if any) and `validAfter` is the 
    * timestamp after which the filter becomes active.
    * @param _registryId The registry id
    * @param _dapp The dapp
    */
    function getAuthorisation(uint8 _registryId, address _dapp) external view returns (address filter, uint64 validAfter) {
        uint auth = uint(authorisations[_registryId][_dapp]);
        filter = address(uint160(auth >> 64));
        validAfter = uint64(auth & 0xffffffffffffffff);
    }

    /**
    * @notice Add a new dapp to the registry with an optional filter
    * @param _registryId The id of the registry to modify
    * @param _dapp The address of the dapp contract to authorise.
    * @param _filter The address of the filter contract to use, if any.
    */
    function addDapp(uint8 _registryId, address _dapp, address _filter) external onlyOwner(_registryId) {
        require(authorisations[_registryId][_dapp] == bytes32(0), "DR: dapp already added");
        uint validAfter = block.timestamp + timelockPeriod;
        // Store the new authorisation as {filter:160}{validAfter:64}.
        authorisations[_registryId][_dapp] = bytes32((uint(uint160(_filter)) << 64) | validAfter);
        emit DappAdded(_registryId, _dapp, _filter, validAfter);
    }


    /**
    * @notice Deauthorise a dapp in a registry
    * @param _registryId The id of the registry to modify
    * @param _dapp The address of the dapp contract to deauthorise.
    */
    function removeDapp(uint8 _registryId, address _dapp) external onlyOwner(_registryId) {
        require(authorisations[_registryId][_dapp] != bytes32(0), "DR: unknown dapp");
        delete authorisations[_registryId][_dapp];
        delete pendingFilterUpdates[_registryId][_dapp];
        emit DappRemoved(_registryId, _dapp);
    }

    /**
    * @notice Request to change an authorisation filter for a dapp that has previously been authorised. We cannot 
    * immediately override the existing filter and need to store the new filter for a timelock period before being 
    * able to change the filter.
    * @param _registryId The id of the registry to modify
    * @param _dapp The address of the dapp contract to authorise.
    * @param _filter The address of the new filter contract to use.
    */
    function requestFilterUpdate(uint8 _registryId, address _dapp, address _filter) external onlyOwner(_registryId) {
        require(authorisations[_registryId][_dapp] != bytes32(0), "DR: unknown dapp");
        uint validAfter = block.timestamp + timelockPeriod;
        // Store the future authorisation as {filter:160}{validAfter:64}
        pendingFilterUpdates[_registryId][_dapp] = bytes32((uint(uint160(_filter)) << 64) | validAfter);
        emit FilterUpdateRequested(_registryId, _dapp, _filter, validAfter);
    }

    /**
    * @notice Confirm the filter change requested by `requestFilterUpdate`
    * @param _registryId The id of the registry to modify
    * @param _dapp The address of the dapp contract to authorise.
    */
    function confirmFilterUpdate(uint8 _registryId, address _dapp) external {
        uint newAuth = uint(pendingFilterUpdates[_registryId][_dapp]);
        require(newAuth > 0, "DR: no pending filter update");
        uint validAfter = newAuth & 0xffffffffffffffff;
        require(validAfter <= block.timestamp, "DR: too early to confirm auth");
        authorisations[_registryId][_dapp] = bytes32(newAuth);
        emit FilterUpdated(_registryId, _dapp, address(uint160(newAuth >> 64)), validAfter); 
        delete pendingFilterUpdates[_registryId][_dapp];
    }

    /********  Internal Functions ***********/

    function validateOwner(uint8 _registryId) internal view {
        address owner = registryOwners[_registryId];
        require(owner != address(0), "DR: unknown registry");
        require(msg.sender == owner, "DR: sender != registry owner");
    }
}

// Copyright (C) 2020  Echooo Labs Ltd. <https://echooo.xyz>

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.5.4 <0.9.0;

/**
 * @title ITransferStorage
 * @notice TransferStorage interface
 */
interface ITransferStorage {
    function setWhitelist(address _wallet, address _target, uint256 _value) external;

    function getWhitelist(address _wallet, address _target) external view returns (uint256);
}

// Copyright (C) 2020  Echooo Labs Ltd. <https://echooo.xyz>

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.3;

/**
 * @title Utils
 * @notice Common utility methods used by modules.
 */
library Utils {

    // ERC20, ERC721 & ERC1155 transfers & approvals
    bytes4 private constant ERC20_TRANSFER = bytes4(keccak256("transfer(address,uint256)"));
    bytes4 private constant ERC20_APPROVE = bytes4(keccak256("approve(address,uint256)"));
    bytes4 private constant ERC721_SET_APPROVAL_FOR_ALL = bytes4(keccak256("setApprovalForAll(address,bool)"));
    bytes4 private constant ERC721_TRANSFER_FROM = bytes4(keccak256("transferFrom(address,address,uint256)"));
    bytes4 private constant ERC721_SAFE_TRANSFER_FROM = bytes4(keccak256("safeTransferFrom(address,address,uint256)"));
    bytes4 private constant ERC721_SAFE_TRANSFER_FROM_BYTES = bytes4(keccak256("safeTransferFrom(address,address,uint256,bytes)"));
    bytes4 private constant ERC1155_SAFE_TRANSFER_FROM = bytes4(keccak256("safeTransferFrom(address,address,uint256,uint256,bytes)"));

    bytes4 private constant OWNER_SIG = 0x8da5cb5b;
    /**
    * @notice Helper method to recover the signer at a given position from a list of concatenated signatures.
    * @param _signedHash The signed hash
    * @param _signatures The concatenated signatures.
    * @param _index The index of the signature to recover.
    */
    function recoverSigner(bytes32 _signedHash, bytes memory _signatures, uint _index) internal pure returns (address) {
        uint8 v;
        bytes32 r;
        bytes32 s;
        // we jump 32 (0x20) as the first slot of bytes contains the length
        // we jump 65 (0x41) per signature
        // for v we load 32 bytes ending with v (the first 31 come from s) then apply a mask
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(_signatures, add(0x20,mul(0x41,_index))))
            s := mload(add(_signatures, add(0x40,mul(0x41,_index))))
            v := and(mload(add(_signatures, add(0x41,mul(0x41,_index)))), 0xff)
        }
        require(v == 27 || v == 28, "Utils: bad v value in signature");

        address recoveredAddress = ecrecover(_signedHash, v, r, s);
        require(recoveredAddress != address(0), "Utils: ecrecover returned 0");
        return recoveredAddress;
    }

    /**
    * @notice Helper method to recover the spender from a contract call. 
    * The method returns the contract unless the call is to a standard method of a ERC20/ERC721/ERC1155 token
    * in which case the spender is recovered from the data.
    * @param _to The target contract.
    * @param _data The data payload.
    */
    function recoverSpender(address _to, bytes memory _data) internal pure returns (address spender) {
        if(_data.length >= 68) {
            bytes4 methodId;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                methodId := mload(add(_data, 0x20))
            }
            if(
                methodId == ERC20_TRANSFER ||
                methodId == ERC20_APPROVE ||
                methodId == ERC721_SET_APPROVAL_FOR_ALL) 
            {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    spender := mload(add(_data, 0x24))
                }
                return spender;
            }
            if(
                methodId == ERC721_TRANSFER_FROM ||
                methodId == ERC721_SAFE_TRANSFER_FROM ||
                methodId == ERC721_SAFE_TRANSFER_FROM_BYTES ||
                methodId == ERC1155_SAFE_TRANSFER_FROM)
            {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    spender := mload(add(_data, 0x44))
                }
                return spender;
            }
        }

        spender = _to;
    }

    /**
    * @notice Helper method to parse data and extract the method signature.
    */
    function functionPrefix(bytes memory _data) internal pure returns (bytes4 prefix) {
        require(_data.length >= 4, "Utils: Invalid functionPrefix");
        // solhint-disable-next-line no-inline-assembly
        assembly {
            prefix := mload(add(_data, 0x20))
        }
    }

    /**
    * @notice Checks if an address is a contract.
    * @param _addr The address.
    */
    function isContract(address _addr) internal view returns (bool) {
        uint32 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    /**
    * @notice Checks if an address is a guardian or an account authorised to sign on behalf of a smart-contract guardian
    * given a list of guardians.
    * @param _guardians the list of guardians
    * @param _guardian the address to test
    * @return true and the list of guardians minus the found guardian upon success, false and the original list of guardians if not found.
    */
    function isGuardianOrGuardianSigner(address[] memory _guardians, address _guardian) internal view returns (bool, address[] memory) {
        if (_guardians.length == 0 || _guardian == address(0)) {
            return (false, _guardians);
        }
        bool isFound = false;
        address[] memory updatedGuardians = new address[](_guardians.length - 1);
        uint256 index = 0;
        for (uint256 i = 0; i < _guardians.length; i++) {
            if (!isFound) {
                // check if _guardian is an account guardian
                if (_guardian == _guardians[i]) {
                    isFound = true;
                    continue;
                }
                // check if _guardian is the owner of a smart contract guardian
                if (isContract(_guardians[i]) && isGuardianOwner(_guardians[i], _guardian)) {
                    isFound = true;
                    continue;
                }
            }
            if (index < updatedGuardians.length) {
                updatedGuardians[index] = _guardians[i];
                index++;
            }
        }
        return isFound ? (true, updatedGuardians) : (false, _guardians);
    }

    /**
    * @notice Checks if an address is the owner of a guardian contract.
    * The method does not revert if the call to the owner() method consumes more then 25000 gas.
    * @param _guardian The guardian contract
    * @param _owner The owner to verify.
    */
    function isGuardianOwner(address _guardian, address _owner) internal view returns (bool) {
        address owner = address(0);

        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr,OWNER_SIG)
            let result := staticcall(25000, _guardian, ptr, 0x20, ptr, 0x20)
            if eq(result, 1) {
                owner := mload(ptr)
            }
        }
        return owner == _owner;
    }

    /**
    * @notice Returns ceil(a / b).
    */
    function ceil(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        if (a % b == 0) {
            return c;
        } else {
            return c + 1;
        }
    }
}

// Copyright (C) 2021  Argent Labs Ltd. <https://argent.xyz>

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.3;

interface IAuthoriser {
    function isAuthorised(address _wallet, address _spender, address _to, bytes calldata _data) external view returns (bool);
    function areAuthorised(
        address _wallet,
        address[] calldata _spenders,
        address[] calldata _to,
        bytes[] calldata _data
    )
        external
        view
        returns (bool);
}