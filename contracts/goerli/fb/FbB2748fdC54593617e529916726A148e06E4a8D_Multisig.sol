// Copyright 2022 Energi Core

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

pragma solidity 0.5.16;

import { MultisigAutoProxy } from './MultisigAutoProxy.sol';
import { StorageBase } from '../StorageBase.sol';

import { IGovernedContract } from '../interfaces/IGovernedContract.sol';
import { IMultisigGovernedProxy } from './IMultisigGovernedProxy.sol';
import { IMultisig } from './IMultisig.sol';
import { IMultisigStorage } from './IMultisigStorage.sol';
import { IStorageBase } from '../interfaces/IStorageBase.sol';
import { IGovernedProxy } from '../interfaces/IGovernedProxy.sol';

contract MultisigStorage is StorageBase, IMultisigStorage {
    // The ownerList at position 0 (ownersListsIndex = 0) consists of one dummy address (the dummy owner address 0x0).
    // If a function which was previously managed by this Multisig smart contract should be deactivated the
    // ownersListsIndex in the OwnershipSettings can be set to this ownerList 0.
    //
    // The ownerList at position 1 (ownersListsIndex = 1) manages this Multisig smart contract. It is the
    // most powerful ownerList and can add/remove/replace owners out of this Multisig smart contract and
    // can set the ownership settings in this Multisig smart contract.
    //
    address[][] private ownersLists;

    // ownersListsIndex => ownerAddress => true/false
    mapping(uint256 => mapping(address => bool)) private isOwnerFromList;

    // smartContractProxyAddress => onImplementation => functionHash => OwnershipSettingsStruct
    mapping(address => mapping(bool => mapping(bytes4 => OwnershipSettings)))
        private functionsOwnership;

    // transactionID => transactionStruct
    mapping(uint256 => Transaction) private transactions;

    // transactionID => ownerAddress => true/false
    mapping(uint256 => mapping(address => bool)) private signatures;

    // Counter that is incremented for every new tx that is submitted to this Multisig smart contract.
    uint256 private transactionCount = 1;
    // The length of any ownerList should not be greater than MAX_OWNER_COUNT to avoid for loops running out of gas.
    uint256 private MAX_OWNER_COUNT = 50;

    constructor() public {
        // ownerList 0 consists of one dummy address. If a function which
        // was previously managed by this Multisig smart contract should
        // be deactivated the ownersListsIndex in the OwnershipSettings
        // can be set to this ownerList 0.
        ownersLists.push(new address[](0));
        ownersLists[0].push(address(0));
        isOwnerFromList[0][address(0)] = true;
    }

    //
    // ownersLists setters
    //
    function setOwner(
        uint256 ownersListsIndex,
        uint256 index,
        address _owner
    ) external requireOwner {
        ownersLists[ownersListsIndex][index] = _owner;
    }

    function pushOwnersList(address[] calldata ownersList) external requireOwner {
        ownersLists.push(ownersList);
    }

    function popOwnersList() external requireOwner {
        ownersLists.pop();
    }

    function pushOwner(uint256 ownersListsIndex, address _owner) external requireOwner {
        ownersLists[ownersListsIndex].push(_owner);
    }

    function popOwner(uint256 ownersListsIndex) external requireOwner {
        ownersLists[ownersListsIndex].pop();
    }

    //
    // ownersLists getters
    //
    function getOwnersListsLength() external view returns (uint256 _length) {
        _length = ownersLists.length;
    }

    function getOwnersListLength(uint256 ownersListsIndex) external view returns (uint256 _length) {
        _length = ownersLists[ownersListsIndex].length;
    }

    function getOwnerByOwnersListsIndexAndIndex(uint256 ownersListsIndex, uint256 index)
        external
        view
        returns (address _owner)
    {
        _owner = ownersLists[ownersListsIndex][index];
    }

    function getOwnersListByOwnersListsIndex(uint256 ownersListsIndex)
        external
        view
        returns (address[] memory _owners)
    {
        _owners = ownersLists[ownersListsIndex];
    }

    //
    // isOwnerFromList setter
    //
    function setIsOwnerFromList(
        uint256 ownersListsIndex,
        address ownerAddress,
        bool isOwner
    ) external requireOwner {
        isOwnerFromList[ownersListsIndex][ownerAddress] = isOwner;
    }

    //
    // isOwnerFromList getter
    //
    function getIsOwnerFromList(uint256 ownersListsIndex, address ownerAddress)
        external
        view
        returns (bool _isOwner)
    {
        _isOwner = isOwnerFromList[ownersListsIndex][ownerAddress];
    }

    //
    // functionsOwnership setters
    //
    function setFunctionOwnership(
        address smartContractProxyAddress,
        bool onImplementation,
        bytes4 functionHash,
        uint256 ownersListsIndex,
        uint256 numberSignaturesRequired
    ) external requireOwner {
        functionsOwnership[smartContractProxyAddress][onImplementation][
            functionHash
        ] = OwnershipSettings({
            ownersListsIndex: ownersListsIndex,
            numberSignaturesRequired: numberSignaturesRequired
        });
    }

    function setFunctionOwnersListIndex(
        address smartContractProxyAddress,
        bool onImplementation,
        bytes4 functionHash,
        uint256 ownersListsIndex
    ) external requireOwner {
        functionsOwnership[smartContractProxyAddress][onImplementation][functionHash]
            .ownersListsIndex = ownersListsIndex;
    }

    function setFunctionNumberSignaturesRequired(
        address smartContractProxyAddress,
        bool onImplementation,
        bytes4 functionHash,
        uint256 numberSignaturesRequired
    ) external requireOwner {
        functionsOwnership[smartContractProxyAddress][onImplementation][functionHash]
            .numberSignaturesRequired = numberSignaturesRequired;
    }

    //
    // functionsOwnership getters
    //
    function getFunctionOwnersListIndex(
        address smartContractProxyAddress,
        bool onImplementation,
        bytes4 functionHash
    ) external view returns (uint256 _ownersListsIndex) {
        _ownersListsIndex = functionsOwnership[smartContractProxyAddress][onImplementation][
            functionHash
        ].ownersListsIndex;
    }

    function getFunctionNumberSignaturesRequired(
        address smartContractProxyAddress,
        bool onImplementation,
        bytes4 functionHash
    ) external view returns (uint256 _numberSignaturesRequired) {
        _numberSignaturesRequired = functionsOwnership[smartContractProxyAddress][onImplementation][
            functionHash
        ].numberSignaturesRequired;
    }

    //
    // transactions setters
    //
    function setTransaction(
        uint256 transactionId,
        address destination,
        bool onImplementation,
        uint256 value,
        bytes4 functionHash,
        bytes memory data,
        bool executed
    ) public requireOwner {
        transactions[transactionId] = Transaction({
            destination: destination,
            onImplementation: onImplementation,
            value: value,
            functionHash: functionHash,
            data: data,
            executed: executed
        });
    }

    function setTransactionByDestination(uint256 transactionId, address _destination)
        external
        requireOwner
    {
        transactions[transactionId].destination = _destination;
    }

    function setTransactionByOnImplementation(uint256 transactionId, bool _onImplementation)
        external
        requireOwner
    {
        transactions[transactionId].onImplementation = _onImplementation;
    }

    function setTransactionByValue(uint256 transactionId, uint256 _value) external requireOwner {
        transactions[transactionId].value = _value;
    }

    function setTransactionByFunctionHash(uint256 transactionId, bytes4 _functionHash)
        external
        requireOwner
    {
        transactions[transactionId].functionHash = _functionHash;
    }

    function setTransactionByData(uint256 transactionId, bytes memory _data) public requireOwner {
        transactions[transactionId].data = _data;
    }

    function setTransactionByExecuted(uint256 transactionId, bool _executed) external requireOwner {
        transactions[transactionId].executed = _executed;
    }

    //
    // transactions getters
    //
    function getTransactionByDestination(uint256 transactionId)
        external
        view
        returns (address _destination)
    {
        _destination = transactions[transactionId].destination;
    }

    function getTransactionByOnImplementation(uint256 transactionId)
        external
        view
        returns (bool _onImplementation)
    {
        _onImplementation = transactions[transactionId].onImplementation;
    }

    function getTransactionByValue(uint256 transactionId) external view returns (uint256 _value) {
        _value = transactions[transactionId].value;
    }

    function getTransactionByFunctionHash(uint256 transactionId)
        external
        view
        returns (bytes4 _functionHash)
    {
        _functionHash = transactions[transactionId].functionHash;
    }

    function getTransactionByData(uint256 transactionId)
        external
        view
        returns (bytes memory _data)
    {
        _data = transactions[transactionId].data;
    }

    function getTransactionByExecuted(uint256 transactionId)
        external
        view
        returns (bool _executed)
    {
        _executed = transactions[transactionId].executed;
    }

    //
    // signatures setter
    //
    function setSignature(
        uint256 transactionId,
        address _owner,
        bool hasSigned
    ) external requireOwner {
        signatures[transactionId][_owner] = hasSigned;
    }

    //
    // signatures getter
    //
    function getSignature(uint256 transactionId, address _owner)
        external
        view
        returns (bool _hasSigned)
    {
        _hasSigned = signatures[transactionId][_owner];
    }

    //
    // transactionCount setter
    //
    function setTransactionCount(uint256 _transactionCount) external requireOwner {
        transactionCount = _transactionCount;
    }

    //
    // transactionCount getter
    //
    function getTransactionCount() external view returns (uint256 _transactionCount) {
        _transactionCount = transactionCount;
    }

    //
    // MAX_OWNER_COUNT setter
    //
    function setMAX_OWNER_COUNT(uint256 _MAX_OWNER_COUNT) external requireOwner {
        MAX_OWNER_COUNT = _MAX_OWNER_COUNT;
    }

    //
    // MAX_OWNER_COUNT getter
    //
    function getMAX_OWNER_COUNT() external view returns (uint256 _MAX_OWNER_COUNT) {
        _MAX_OWNER_COUNT = MAX_OWNER_COUNT;
    }
}

/// @title Multisig smart contract - Allows multiple parties to agree on transactions before execution.
contract Multisig is MultisigAutoProxy, IMultisig {
    MultisigStorage public _storage;

    // 0x0058bbfd = bytes4(keccak256(bytes('removeOwner(uint,address)')))
    bytes4 public constant REMOVE_OWNER = 0x0058bbfd;

    // 0x8cd1bb20 = bytes4(keccak256(bytes('addOwner(uint,address)')))
    bytes4 public constant ADD_OWNER = 0x8cd1bb20;

    // 0x54e99c6e = bytes4(keccak256(bytes('replaceOwner(uint,address,address)')))
    bytes4 public constant REPLACE_OWNER = 0x54e99c6e;

    // 0xcec104df = bytes4(keccak256(bytes('changeRequirement(address,bool,bytes,uint,uint)')))
    bytes4 public constant CHANGE_REQUIREMENT = 0xcec104df;

    constructor(
        address _proxy,
        address payable _sporkProxy,
        address[] memory _masterOwners,
        uint256 _signaturesRequired
    ) public MultisigAutoProxy(_proxy, _sporkProxy, address(this)) {
        _storage = new MultisigStorage();
        // Set multisig master owners and required number of signatures
        multisigWalletSetup(_masterOwners, _signaturesRequired);
    }

    //
    //  Modifiers
    //
    modifier ownerDoesNotExist(uint256 ownersListsIndex, address owner) {
        require(
            !_storage.getIsOwnerFromList(ownersListsIndex, owner),
            'Multisig: owner does exist'
        );
        _;
    }

    modifier ownerExists(uint256 ownersListsIndex, address owner) {
        require(
            _storage.getIsOwnerFromList(ownersListsIndex, owner),
            'Multisig: owner does not exist'
        );
        _;
    }

    modifier ownerExistsGivenTransactionID(uint256 transactionId, address owner) {
        uint256 ownersListsIndex = _storage.getFunctionOwnersListIndex(
            _storage.getTransactionByDestination(transactionId),
            _storage.getTransactionByOnImplementation(transactionId),
            _storage.getTransactionByFunctionHash(transactionId)
        );
        require(
            _storage.getIsOwnerFromList(ownersListsIndex, msg.sender),
            'Multisig: owner does not exist'
        );
        _;
    }

    modifier isManagedByMultisig(uint256 transactionId) {
        uint256 numberSignaturesRequired = _storage.getFunctionNumberSignaturesRequired(
            _storage.getTransactionByDestination(transactionId),
            _storage.getTransactionByOnImplementation(transactionId),
            _storage.getTransactionByFunctionHash(transactionId)
        );
        require(
            numberSignaturesRequired > 0,
            'Multisig: function or smartContractAddress is not managed by multisig'
        );
        _;
    }

    modifier transactionExists(uint256 transactionId) {
        require(
            _storage.getTransactionByDestination(transactionId) != address(0),
            'Multisig: transaction does not exist'
        );
        _;
    }

    modifier signed(uint256 transactionId, address owner) {
        require(
            _storage.getSignature(transactionId, owner),
            'Multisig: transaction has not been signed by owner'
        );
        _;
    }

    modifier notSigned(uint256 transactionId, address owner) {
        require(
            !_storage.getSignature(transactionId, owner),
            'Multisig: transaction has been signed by owner'
        );
        _;
    }

    modifier notExecuted(uint256 transactionId) {
        require(
            !_storage.getTransactionByExecuted(transactionId),
            'Multisig: transaction is not executed'
        );
        _;
    }

    modifier notNull(address _address) {
        require(_address != address(0), 'Multisig: address should not be 0');
        _;
    }

    modifier validRequirement(uint256 ownerCount, uint256 _signaturesRequired) {
        require(
            ownerCount <= _storage.getMAX_OWNER_COUNT() &&
                _signaturesRequired <= ownerCount &&
                _signaturesRequired != 0 &&
                ownerCount != 0,
            'Multisig: not a valid requirement'
        );
        _;
    }

    // This function is called in order to upgrade to a new Multisig implementation
    function destroy(IGovernedContract _newImpl) external requireProxy {
        IStorageBase(address(_storage)).setOwner(address(_newImpl));
        // Self destruct
        _destroy(_newImpl);
    }

    // This function (placeholder) would be called on the new implementation if necessary for the upgrade
    function migrate(IGovernedContract _oldImpl) external requireProxy {
        _migrate(_oldImpl);
    }

    function getImpl(address proxyAddress) private view returns (address _implementation) {
        _implementation = address(IGovernedProxy(address(uint160(proxyAddress))).impl());
    }

    /// @dev Fallback function allows to deposit NRG.
    function() external payable {
        if (msg.value > 0) {
            address payable self = address(uint160(address(this))); // avoids opcode 0x47 error on Energi
            uint256 balance = self.balance; // that occurs when calling address(this).balance
            // Transfer funds to proxy (proxy holds funds)
            IMultisigGovernedProxy(proxy).receiveNRG.value(balance)();
            IMultisigGovernedProxy(proxy).emitDeposit(msg.sender, msg.value);
        }
    }

    /// @dev Set master owners and required number of signatures.
    /// @param _masterOwners List of initial owners.
    /// @param _signaturesRequired Number of required signatures.
    function multisigWalletSetup(address[] memory _masterOwners, uint256 _signaturesRequired)
        private
        validRequirement(_masterOwners.length, _signaturesRequired)
    {
        for (uint256 i = 0; i < _masterOwners.length; i++) {
            require(
                !_storage.getIsOwnerFromList(1, _masterOwners[i]) && _masterOwners[i] != address(0),
                'Multisig: owners are not valid'
            );
            _storage.setIsOwnerFromList(1, _masterOwners[i], true);
            IMultisigGovernedProxy(proxy).emitOwnerAddition(1, _masterOwners[i]);
        }
        // ownerList 1 is managing this Multisig smart contract
        _storage.pushOwnersList(_masterOwners);

        _storage.setFunctionOwnership(proxy, true, REMOVE_OWNER, 1, _signaturesRequired);

        _storage.setFunctionOwnership(proxy, true, ADD_OWNER, 1, _signaturesRequired);

        _storage.setFunctionOwnership(proxy, true, REPLACE_OWNER, 1, _signaturesRequired);

        _storage.setFunctionOwnership(proxy, true, CHANGE_REQUIREMENT, 1, _signaturesRequired);
    }

    /// @dev Allows to add a new owner. Transaction has to be sent by MultisigProxy.
    /// @param ownersListsIndex Index of list that the new owner is added to.
    /// @param owner Address of new owner.
    function addOwner(uint256 ownersListsIndex, address owner)
        external
        requireProxy
        ownerDoesNotExist(ownersListsIndex, owner)
        notNull(owner)
    {
        require(
            ownersListsIndex != 0,
            'Multisig: ownerList 0 is used for deactivating functions that were previously managed by this Multisig.'
        );
        _storage.setIsOwnerFromList(ownersListsIndex, owner, true);

        if (_storage.getOwnersListsLength() == ownersListsIndex) {
            _storage.pushOwnersList(new address[](0));
        }

        // checking that no ownerList has more owners than MAX_OWNER_COUNT
        require(
            _storage.getOwnersListLength(ownersListsIndex) + 1 <= _storage.getMAX_OWNER_COUNT(),
            'Multisig: MAX_OWNER_COUNT reached'
        );

        _storage.pushOwner(ownersListsIndex, owner);

        IMultisigGovernedProxy(proxy).emitOwnerAddition(ownersListsIndex, owner);
    }

    /// @dev Allows to remove an owner. Transaction has to be sent by MultisigProxy.
    /// @param ownersListsIndex Index of list that the owner is removed from.
    /// @param owner Address of owner.
    function removeOwner(uint256 ownersListsIndex, address owner)
        external
        requireProxy
        ownerExists(ownersListsIndex, owner)
    {
        require(
            ownersListsIndex != 0,
            'Multisig: ownerList 0 is used for deactivating functions that were previously managed by this Multisig.'
        );
        _storage.setIsOwnerFromList(ownersListsIndex, owner, false);

        for (uint256 i = 0; i < _storage.getOwnersListLength(ownersListsIndex) - 1; i++) {
            if (_storage.getOwnerByOwnersListsIndexAndIndex(ownersListsIndex, i) == owner) {
                _storage.setOwner(
                    ownersListsIndex,
                    i,
                    _storage.getOwnerByOwnersListsIndexAndIndex(
                        ownersListsIndex,
                        _storage.getOwnersListLength(ownersListsIndex) - 1
                    )
                );
                break;
            }
        }
        _storage.popOwner(ownersListsIndex);

        // The following four changeRequirement updates ensure that control over the list with ownersListsIndex = 1
        // is kept when removing an owner from that list

        if (ownersListsIndex == 1) {
            if (
                _storage.getFunctionNumberSignaturesRequired(proxy, true, REMOVE_OWNER) >
                _storage.getOwnersListLength(1)
            ) {
                changeRequirement(proxy, true, REMOVE_OWNER, 1, _storage.getOwnersListLength(1));
            }

            if (
                _storage.getFunctionNumberSignaturesRequired(proxy, true, ADD_OWNER) >
                _storage.getOwnersListLength(1)
            ) {
                changeRequirement(proxy, true, ADD_OWNER, 1, _storage.getOwnersListLength(1));
            }

            if (
                _storage.getFunctionNumberSignaturesRequired(proxy, true, REPLACE_OWNER) >
                _storage.getOwnersListLength(1)
            ) {
                changeRequirement(proxy, true, REPLACE_OWNER, 1, _storage.getOwnersListLength(1));
            }

            if (
                _storage.getFunctionNumberSignaturesRequired(proxy, true, CHANGE_REQUIREMENT) >
                _storage.getOwnersListLength(1)
            ) {
                changeRequirement(
                    proxy,
                    true,
                    CHANGE_REQUIREMENT,
                    1,
                    _storage.getOwnersListLength(1)
                );
            }
        }

        IMultisigGovernedProxy(proxy).emitOwnerRemoval(ownersListsIndex, owner);
    }

    /// @dev Allows to replace an owner with a new owner. Transaction has to be sent by MultisigProxy.
    /// @param ownersListsIndex Index of list that the owner is replaced from.
    /// @param owner Address of owner to be replaced.
    /// @param newOwner Address of new owner.
    function replaceOwner(
        uint256 ownersListsIndex,
        address owner,
        address newOwner
    )
        external
        requireProxy
        ownerExists(ownersListsIndex, owner)
        ownerDoesNotExist(ownersListsIndex, newOwner)
    {
        require(
            ownersListsIndex != 0,
            'Multisig: ownerList 0 is used for deactivating functions that were previously managed by this Multisig.'
        );
        for (uint256 i = 0; i < _storage.getOwnersListLength(ownersListsIndex); i++) {
            if (_storage.getOwnerByOwnersListsIndexAndIndex(ownersListsIndex, i) == owner) {
                _storage.setOwner(ownersListsIndex, i, newOwner);
                break;
            }
        }
        _storage.setIsOwnerFromList(ownersListsIndex, owner, false);
        _storage.setIsOwnerFromList(ownersListsIndex, newOwner, true);

        IMultisigGovernedProxy(proxy).emitOwnerRemoval(ownersListsIndex, owner);
        IMultisigGovernedProxy(proxy).emitOwnerAddition(ownersListsIndex, newOwner);
    }

    /// @dev Allows to change the number of required signatures and the ownersListsIndexes. Transaction has to be sent by MultisigProxy.
    /// @param smartContractProxyAddress Smart contract address that this change should apply to.
    /// @param onImplementation Boolean to destinguish if the function is on the proxy or on the implementation of the smart contract proxy address.
    /// @param functionHash Function hash that this change should apply to.
    /// @param ownersListsIndex Index of owner list that manages this smartContract/function.
    /// @param signaturesRequired Number of required signatures.
    function changeRequirement(
        address smartContractProxyAddress,
        bool onImplementation,
        bytes4 functionHash,
        uint256 ownersListsIndex,
        uint256 signaturesRequired
    )
        public
        requireProxy
        validRequirement(_storage.getOwnersListLength(ownersListsIndex), signaturesRequired)
    {
        _storage.setFunctionOwnership(
            smartContractProxyAddress,
            onImplementation,
            functionHash,
            ownersListsIndex,
            signaturesRequired
        );

        IMultisigGovernedProxy(proxy).emitRequirementChange(
            smartContractProxyAddress,
            onImplementation,
            functionHash,
            ownersListsIndex,
            signaturesRequired
        );
    }

    /// @dev Allows an owner to submit a transaction and to add a signature to this transaction.
    /// @param destination Transaction target address.
    /// @param onImplementation Boolean to destinguish if the function is on the proxy or on the implementation of the smart contract proxy address.
    /// @param value Transaction NRG value.
    /// @param functionHash Transaction function hash.
    /// @param data Transaction data payload.
    /// @return Returns transaction ID.
    function submitTransaction(
        address destination,
        bool onImplementation,
        uint256 value,
        bytes4 functionHash,
        bytes memory data
    ) public returns (uint256 transactionId) {
        transactionId = addTransaction(destination, onImplementation, value, functionHash, data);
        addSignatureToTransaction(transactionId);
    }

    /// @dev Allows an owner to add a signature to this transaction.
    /// @param transactionId Transaction ID.
    function addSignatureToTransaction(uint256 transactionId)
        public
        isManagedByMultisig(transactionId)
        ownerExistsGivenTransactionID(transactionId, msg.sender)
        transactionExists(transactionId)
        notSigned(transactionId, msg.sender)
    {
        _storage.setSignature(transactionId, msg.sender, true);
        IMultisigGovernedProxy(proxy).emitSignature(msg.sender, transactionId);
        executeTransaction(transactionId);
    }

    /// @dev Allows an owner to revoke a signature for a transaction.
    /// @param transactionId Transaction ID.
    function revokeSignature(uint256 transactionId)
        external
        ownerExistsGivenTransactionID(transactionId, msg.sender)
        signed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        _storage.setSignature(transactionId, msg.sender, false);
        IMultisigGovernedProxy(proxy).emitRevocation(msg.sender, transactionId);
    }

    /// @dev Allows an owner to execute a transaction that has enough signatures.
    /// @param transactionId Transaction ID.
    function executeTransaction(uint256 transactionId)
        public
        ownerExistsGivenTransactionID(transactionId, msg.sender)
        signed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        if (hasEnoughSignatures(transactionId)) {
            address destination = _storage.getTransactionByDestination(transactionId);
            bytes memory data = _storage.getTransactionByData(transactionId);

            address destinationAddress = _storage.getTransactionByOnImplementation(transactionId) ==
                true
                ? getImpl(destination)
                : destination;

            if (
                IMultisigGovernedProxy(proxy).external_call(
                    destinationAddress,
                    _storage.getTransactionByValue(transactionId),
                    data.length,
                    data
                )
            ) {
                IMultisigGovernedProxy(proxy).emitExecution(transactionId);
                _storage.setTransactionByExecuted(transactionId, true);
            } else {
                IMultisigGovernedProxy(proxy).emitExecutionFailure(transactionId);
                _storage.setTransactionByExecuted(transactionId, false);
            }
        }
    }

    /// @dev Returns true if transaction has enough signatures otherwise returns false.
    /// @param transactionId Transaction ID.
    /// @return Returns hasEnoughSignatures.
    function hasEnoughSignatures(uint256 transactionId) public view returns (bool) {
        uint256 ownersListsIndex = _storage.getFunctionOwnersListIndex(
            _storage.getTransactionByDestination(transactionId),
            _storage.getTransactionByOnImplementation(transactionId),
            _storage.getTransactionByFunctionHash(transactionId)
        );
        uint256 numberSignaturesRequired = _storage.getFunctionNumberSignaturesRequired(
            _storage.getTransactionByDestination(transactionId),
            _storage.getTransactionByOnImplementation(transactionId),
            _storage.getTransactionByFunctionHash(transactionId)
        );

        uint256 count = 0;
        for (uint256 i = 0; i < _storage.getOwnersListLength(ownersListsIndex); i++) {
            if (
                _storage.getSignature(
                    transactionId,
                    _storage.getOwnerByOwnersListsIndexAndIndex(ownersListsIndex, i)
                )
            ) {
                count += 1;
            }
            if (count == numberSignaturesRequired) {
                return true;
            }
        }
        return false;
    }

    /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    /// @param destination Transaction target address.
    /// @param onImplementation Boolean to destinguish if the function is on the proxy or on the implementation of the smart contract proxy address.
    /// @param value Transaction NRG value.
    /// @param functionHash Transaction function hash.
    /// @param data Transaction data payload.
    /// @return Returns transaction ID.
    function addTransaction(
        address destination,
        bool onImplementation,
        uint256 value,
        bytes4 functionHash,
        bytes memory data
    ) internal notNull(destination) returns (uint256 transactionId) {
        transactionId = _storage.getTransactionCount();

        _storage.setTransaction(
            transactionId,
            destination,
            onImplementation,
            value,
            functionHash,
            data,
            false
        );
        _storage.setTransactionCount(transactionId + 1);

        IMultisigGovernedProxy(proxy).emitSubmission(transactionId);
    }

    /// @dev Returns length of ownerList.
    /// @param ownersListsIndex Index of list that the owners should be returned from.
    /// @return Number length.
    function getOwnersListLength(uint256 ownersListsIndex) public view returns (uint256) {
        if (ownersListsIndex >= _storage.getOwnersListsLength()) {
            return 0;
        } else {
            return _storage.getOwnersListLength(ownersListsIndex);
        }
    }

    /// @dev Returns number of signatures of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Number of signatures.
    function getSignatureCount(uint256 transactionId) external view returns (uint256 count) {
        uint256 ownersListsIndex = _storage.getFunctionOwnersListIndex(
            _storage.getTransactionByDestination(transactionId),
            _storage.getTransactionByOnImplementation(transactionId),
            _storage.getTransactionByFunctionHash(transactionId)
        );

        for (uint256 i = 0; i < _storage.getOwnersListLength(ownersListsIndex); i++) {
            if (
                _storage.getSignature(
                    transactionId,
                    _storage.getOwnerByOwnersListsIndexAndIndex(ownersListsIndex, i)
                )
            ) {
                count += 1;
            }
        }
    }

    /// @dev Returns total number of transactions after filters are applied.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @param offset Index from where to count the transactions.
    /// @param limit Number of transactions to be counted.
    /// @return Total number of transactions after filters are applied.
    function getTransactionCount(
        bool pending,
        bool executed,
        uint256 offset,
        uint256 limit
    ) external view returns (uint256 count) {
        uint256 transactionCount = _storage.getTransactionCount();
        require(offset < transactionCount, 'Multisig: offset too high');

        // IF offset == 0 and limit == 0; consider all transactions
        // ELSE: return subset according to offset and limit
        if (offset == 0 && limit == 0) {
            offset = 1;
            limit = transactionCount - 1;
        }

        require(offset != 0, 'Multisig: offset not 0');

        if (offset + limit > transactionCount - 1) {
            limit = transactionCount - offset;
        }

        for (uint256 i = 0; i < limit; i++) {
            bool executedTx = _storage.getTransactionByExecuted(offset + i);

            if ((pending && !executedTx) || (executed && executedTx)) {
                count += 1;
            }
        }
    }

    /// @dev Returns list of owners.
    /// @param ownersListsIndex Index of list that the owners should be returned from.
    /// @return List of owner addresses.
    function getOwners(uint256 ownersListsIndex) external view returns (address[] memory) {
        if (ownersListsIndex >= _storage.getOwnersListsLength()) {
            return new address[](0);
        } else {
            return _storage.getOwnersListByOwnersListsIndex(ownersListsIndex);
        }
    }

    /// @dev Returns array with owner addresses, who submitted their signatures for the transaction.
    /// @param transactionId Transaction ID.
    /// @return Returns array of owner addresses.
    function getSignatures(uint256 transactionId)
        external
        view
        returns (address[] memory _signatures)
    {
        uint256 ownersListsIndex = _storage.getFunctionOwnersListIndex(
            _storage.getTransactionByDestination(transactionId),
            _storage.getTransactionByOnImplementation(transactionId),
            _storage.getTransactionByFunctionHash(transactionId)
        );

        address[] memory signaturesTemp = new address[](
            _storage.getOwnersListLength(ownersListsIndex)
        );
        uint256 count = 0;
        for (uint256 i = 0; i < _storage.getOwnersListLength(ownersListsIndex); i++) {
            if (
                _storage.getSignature(
                    transactionId,
                    _storage.getOwnerByOwnersListsIndexAndIndex(ownersListsIndex, i)
                )
            ) {
                signaturesTemp[count] = _storage.getOwnerByOwnersListsIndexAndIndex(
                    ownersListsIndex,
                    i
                );
                count += 1;
            }
        }
        _signatures = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            _signatures[i] = signaturesTemp[i];
        }
    }

    /// @dev Returns list of transaction IDs in defined range.
    /// @param maxTxs Max number of tx to be returned.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @param offset Index from where to count the transactions.
    /// @param limit Number of transactions to be counted.
    /// @return Returns array of transaction IDs.
    function getTransactionIds(
        uint256 maxTxs,
        bool pending,
        bool executed,
        uint256 offset,
        uint256 limit
    ) external view returns (uint256[] memory _transactionIds) {
        uint256 transactionCount = _storage.getTransactionCount();
        require(offset < transactionCount, 'Multisig: offset too high');

        // IF offset == 0 and limit == 0; consider all transactions
        // ELSE: return subset according to offset and limit
        if (offset == 0 && limit == 0) {
            offset = 1;
            limit = transactionCount - 1;
        }

        require(offset != 0, 'Multisig: offset not 0');

        if (offset + limit > transactionCount - 1) {
            limit = transactionCount - offset;
        }

        uint256[] memory transactionIdsTemp = new uint256[](limit);
        uint256 count = 0;

        for (uint256 i = 0; i < limit; i++) {
            bool executedTx = _storage.getTransactionByExecuted(offset + i);

            if ((pending && !executedTx) || (executed && executedTx)) {
                transactionIdsTemp[count] = offset + i;
                count += 1;
            }
        }

        // IF maxTxs == 0 OR maxTxs > count; return all transactions
        // ELSE: return the first maxTxs transactions
        if (maxTxs == 0 || maxTxs > count) {
            maxTxs = count;
        }

        _transactionIds = new uint256[](maxTxs);
        for (uint256 i = 0; i < maxTxs; i++) {
            _transactionIds[i] = transactionIdsTemp[i];
        }
    }

    function getFunctionOwnersListIndex(
        address smartContractProxyAddress,
        bool onImplementation,
        bytes4 functionHash
    ) external view returns (uint256) {
        return
            _storage.getFunctionOwnersListIndex(
                smartContractProxyAddress,
                onImplementation,
                functionHash
            );
    }

    function getFunctionNumberSignaturesRequired(
        address smartContractProxyAddress,
        bool onImplementation,
        bytes4 functionHash
    ) external view returns (uint256 _numberSignaturesRequired) {
        return
            _storage.getFunctionNumberSignaturesRequired(
                smartContractProxyAddress,
                onImplementation,
                functionHash
            );
    }

    function getOwnerByOwnersListsIndexAndIndex(uint256 ownersListsIndex, uint256 index)
        external
        view
        returns (address)
    {
        return _storage.getOwnerByOwnersListsIndexAndIndex(ownersListsIndex, index);
    }

    function getIsOwnerFromList(uint256 ownersListsIndex, address ownerAddress)
        external
        view
        returns (bool)
    {
        return _storage.getIsOwnerFromList(ownersListsIndex, ownerAddress);
    }
}

// Copyright 2022 The Energi Core Authors
// This file is part of Energi Core.
//
// Energi Core is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Energi Core is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Energi Core. If not, see <http://www.gnu.org/licenses/>.

// Energi Governance system is the fundamental part of Energi Core.

// NOTE: It's not allowed to change the compiler due to byte-to-byte
//       match requirement.

pragma solidity 0.5.16;

import { NonReentrant } from '../NonReentrant.sol';

import { IGovernedProxy } from '../interfaces/IGovernedProxy.sol';
import { ISporkRegistry } from '../interfaces/ISporkRegistry.sol';
import { IUpgradeProposal } from '../interfaces/IUpgradeProposal.sol';
import { IGovernedContract } from '../interfaces/IGovernedContract.sol';

/**
 * SC-9: This contract has no chance of being updated. It must be stupid simple.
 *
 * If another upgrade logic is required in the future - it can be done as proxy stage II.
 */
contract MultisigGovernedProxy is NonReentrant, IGovernedContract, IGovernedProxy {
    modifier senderOrigin() {
        // Internal calls are expected to use impl directly.
        // That's due to use of call() instead of delegatecall() on purpose.
        // solium-disable-next-line security/no-tx-origin
        require(tx.origin == msg.sender, 'MultisigGovernedProxy: Only direct calls are allowed!');
        _;
    }

    modifier onlyImpl() {
        require(
            msg.sender == address(impl),
            'MultisigGovernedProxy: Only calls from impl are allowed!'
        );
        _;
    }

    IGovernedContract public impl;
    IGovernedProxy public spork_proxy;
    mapping(address => IGovernedContract) public upgrade_proposals;
    IUpgradeProposal[] public upgrade_proposal_list;

    event Signature(address indexed sender, uint256 indexed transactionId);
    event Revocation(address indexed sender, uint256 indexed transactionId);
    event Submission(uint256 indexed transactionId);
    event Execution(uint256 indexed transactionId);
    event ExecutionFailure(uint256 indexed transactionId);
    event Deposit(address indexed sender, uint256 value);
    event OwnerAddition(uint256 indexed ownersListsIndex, address indexed owner);
    event OwnerRemoval(uint256 indexed ownersListsIndex, address indexed owner);
    event RequirementChange(
        address indexed smartContractProxyAddress,
        bool onImplementation,
        bytes4 indexed functionHash,
        uint256 indexed ownersListsIndex,
        uint256 required
    );

    constructor(address payable _sporkProxy, address _impl) public {
        spork_proxy = IGovernedProxy(_sporkProxy);
        impl = IGovernedContract(_impl);
    }

    function implementation() external view returns (IGovernedContract) {
        return impl;
    }

    // call has been separated into its own function in order to take advantage
    // of the Solidity's code generator to produce a loop that copies tx.data into memory.
    function external_call(
        address destination,
        uint256 value,
        uint256 dataLength,
        bytes memory data
    ) public noReentry onlyImpl returns (bool) {
        bool result;
        assembly {
            let x := mload(0x40) // "Allocate" memory for output (0x40 is where "free memory" pointer is stored by convention)
            let d := add(data, 32) // First 32 bytes are the padded length of data, so exclude that
            result := call(
                sub(gas, 34710), // 34710 is the value that solidity is currently emitting
                // It includes callGas (700) + callVeryLow (3, to pay for SUB) + callValueTransferGas (9000) +
                // callNewAccountGas (25000, in case the destination address does not exist and needs creating)
                destination,
                value,
                d,
                dataLength, // Size of the input (in bytes) - this is what fixes the padding problem
                x,
                0 // Output is ignored, therefore the output size is zero
            )
        }
        return result;
    }

    function emitSignature(address sender, uint256 transactionId) external onlyImpl {
        emit Signature(sender, transactionId);
    }

    function emitRevocation(address sender, uint256 transactionId) external onlyImpl {
        emit Revocation(sender, transactionId);
    }

    function emitSubmission(uint256 transactionId) external onlyImpl {
        emit Submission(transactionId);
    }

    function emitExecution(uint256 transactionId) external onlyImpl {
        emit Execution(transactionId);
    }

    function emitExecutionFailure(uint256 transactionId) external onlyImpl {
        emit ExecutionFailure(transactionId);
    }

    function emitDeposit(address sender, uint256 value) external onlyImpl {
        emit Deposit(sender, value);
    }

    function emitOwnerAddition(uint256 ownersListsIndex, address owner) external onlyImpl {
        emit OwnerAddition(ownersListsIndex, owner);
    }

    function emitOwnerRemoval(uint256 ownersListsIndex, address owner) external onlyImpl {
        emit OwnerRemoval(ownersListsIndex, owner);
    }

    function emitRequirementChange(
        address smartContractProxyAddress,
        bool onImplementation,
        bytes4 functionHash,
        uint256 ownersListsIndex,
        uint256 required
    ) external onlyImpl {
        emit RequirementChange(
            smartContractProxyAddress,
            onImplementation,
            functionHash,
            ownersListsIndex,
            required
        );
    }

    function receiveNRG() external payable {}

    /**
     * Pre-create a new contract first.
     * Then propose upgrade based on that.
     */
    function proposeUpgrade(IGovernedContract _newImpl, uint256 _period)
        external
        payable
        senderOrigin
        noReentry
        returns (IUpgradeProposal)
    {
        require(_newImpl != impl, 'MultisigGovernedProxy: Already active!');
        require(_newImpl.proxy() == address(this), 'MultisigGovernedProxy: Wrong proxy!');

        ISporkRegistry spork_reg = ISporkRegistry(address(spork_proxy.impl()));
        IUpgradeProposal proposal = spork_reg.createUpgradeProposal.value(msg.value)(
            _newImpl,
            _period,
            msg.sender
        );

        upgrade_proposals[address(proposal)] = _newImpl;
        upgrade_proposal_list.push(proposal);

        emit UpgradeProposal(_newImpl, proposal);

        return proposal;
    }

    /**
     * Once proposal is accepted, anyone can activate that.
     */
    function upgrade(IUpgradeProposal _proposal) external noReentry {
        IGovernedContract new_impl = upgrade_proposals[address(_proposal)];
        require(new_impl != impl, 'MultisigGovernedProxy: Already active!');
        // in case it changes in the flight
        require(address(new_impl) != address(0), 'MultisigGovernedProxy: Not registered!');
        require(_proposal.isAccepted(), 'MultisigGovernedProxy: Not accepted!');

        IGovernedContract old_impl = impl;

        new_impl.migrate(old_impl);
        impl = new_impl;
        old_impl.destroy(new_impl);

        // SECURITY: prevent downgrade attack
        _cleanupProposal(_proposal);

        // Return fee ASAP
        _proposal.destroy();

        emit Upgraded(new_impl, _proposal);
    }

    /**
     * Map proposal to implementation
     */
    function upgradeProposalImpl(IUpgradeProposal _proposal)
        external
        view
        returns (IGovernedContract new_impl)
    {
        new_impl = upgrade_proposals[address(_proposal)];
    }

    /**
     * Lists all available upgrades
     */
    function listUpgradeProposals() external view returns (IUpgradeProposal[] memory proposals) {
        uint256 len = upgrade_proposal_list.length;
        proposals = new IUpgradeProposal[](len);

        for (uint256 i = 0; i < len; ++i) {
            proposals[i] = upgrade_proposal_list[i];
        }

        return proposals;
    }

    /**
     * Once proposal is reject, anyone can start collect procedure.
     */
    function collectUpgradeProposal(IUpgradeProposal _proposal) external noReentry {
        IGovernedContract new_impl = upgrade_proposals[address(_proposal)];
        require(address(new_impl) != address(0), 'MultisigGovernedProxy: Not registered!');
        _proposal.collect();
        delete upgrade_proposals[address(_proposal)];

        _cleanupProposal(_proposal);
    }

    function _cleanupProposal(IUpgradeProposal _proposal) internal {
        delete upgrade_proposals[address(_proposal)];

        uint256 len = upgrade_proposal_list.length;
        for (uint256 i = 0; i < len; ++i) {
            if (upgrade_proposal_list[i] == _proposal) {
                upgrade_proposal_list[i] = upgrade_proposal_list[len - 1];
                upgrade_proposal_list.pop();
                break;
            }
        }
    }

    /**
     * Related to above
     */
    function proxy() external view returns (address) {
        return address(this);
    }

    /**
     * SECURITY: prevent on-behalf-of calls
     */
    function migrate(IGovernedContract) external {
        revert('MultisigGovernedProxy: Good try');
    }

    /**
     * SECURITY: prevent on-behalf-of calls
     */
    function destroy(IGovernedContract) external {
        revert('MultisigGovernedProxy: Good try');
    }

    /**
     * SECURITY: prevent on-behalf-of calls
     */
    function addOwner(uint256, address) external pure {
        revert('MultisigGovernedProxy: Good try');
    }

    /**
     * SECURITY: prevent on-behalf-of calls
     */
    function removeOwner(uint256, address) external pure {
        revert('MultisigGovernedProxy: Good try');
    }

    /**
     * SECURITY: prevent on-behalf-of calls
     */
    function replaceOwner(
        uint256,
        address,
        address
    ) external pure {
        revert('MultisigGovernedProxy: Good try');
    }

    /**
     * SECURITY: prevent on-behalf-of calls
     */
    function changeRequirement(
        address,
        bool,
        bytes4,
        uint256,
        uint256
    ) external pure {
        revert('MultisigGovernedProxy: Good try');
    }

    /**
     * Proxy all other calls to implementation.
     */
    function() external payable senderOrigin {
        // SECURITY: senderOrigin() modifier is mandatory
        IGovernedContract impl_m = impl;

        // A dummy delegatecall opcode in the fallback function is necessary for
        // block explorers to pick up the Energi proxy-implementation pattern
        if (false) {
            (bool success, bytes memory data) = address(0).delegatecall(
                abi.encodeWithSignature('')
            );
            require(
                success && !success && data.length == 0 && data.length != 0,
                'FactoryGovernedProxy: delegatecall cannot be used'
            );
        }

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)

            let res := call(sub(gas, 10000), impl_m, callvalue, ptr, calldatasize, 0, 0)
            // NOTE: returndatasize should allow repeatable calls
            //       what should save one opcode.
            returndatacopy(ptr, 0, returndatasize)

            switch res
            case 0 {
                revert(ptr, returndatasize)
            }
            default {
                return(ptr, returndatasize)
            }
        }
    }
}

// Copyright 2022 Energi Core

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

// Energi Governance system is the fundamental part of Energi Core.

// NOTE: It's not allowed to change the compiler due to byte-to-byte
//       match requirement.

pragma solidity 0.5.16;

import { GovernedContract } from '../GovernedContract.sol';
import { MultisigGovernedProxy } from './MultisigGovernedProxy.sol';

/**
 * MultisigAutoProxy is a version of GovernedContract which deploys its own proxy.
 * This is useful to avoid a circular dependency between GovernedContract and GovernedProxy
 * wherein they need each other's address in the constructor.
 * If you want a new governed contract to create a proxy, pass address(0) when deploying
 * otherwise, you can pass a proxy address like in normal GovernedContract
 */

contract MultisigAutoProxy is GovernedContract {
    constructor(
        address _proxy,
        address payable _sporkProxy,
        address _impl
    ) public GovernedContract(_proxy) {
        if (_proxy == address(0)) {
            _proxy = address(new MultisigGovernedProxy(_sporkProxy, _impl));
        }
        proxy = _proxy;
    }
}

// Copyright 2022 Energi Core

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

pragma solidity 0.5.16;

interface IMultisigStorage {
    struct Transaction {
        address destination;
        bool onImplementation;
        uint256 value;
        bytes4 functionHash;
        bytes data;
        bool executed;
    }

    struct OwnershipSettings {
        uint256 ownersListsIndex;
        uint256 numberSignaturesRequired;
    }

    function setOwner(
        uint256 ownersListsIndex,
        uint256 index,
        address owner
    ) external;

    function pushOwnersList(address[] calldata addressArray) external;

    function popOwnersList() external;

    function pushOwner(uint256 ownersListsIndex, address owner) external;

    function popOwner(uint256 ownersListsIndex) external;

    function getOwnersListsLength() external view returns (uint256 _length);

    function getOwnersListLength(uint256 ownersListsIndex) external view returns (uint256 _length);

    function getOwnerByOwnersListsIndexAndIndex(uint256 ownersListsIndex, uint256 index)
        external
        view
        returns (address _owner);

    function getOwnersListByOwnersListsIndex(uint256 ownersListsIndex)
        external
        view
        returns (address[] memory _owners);

    function setIsOwnerFromList(
        uint256 ownersListsIndex,
        address ownerAddress,
        bool isOwner
    ) external;

    function getIsOwnerFromList(uint256 ownersListsIndex, address ownerAddress)
        external
        view
        returns (bool _isOwner);

    function setFunctionOwnership(
        address smartContractProxyAddress,
        bool onImplementation,
        bytes4 functionHash,
        uint256 ownersListsIndex,
        uint256 numberSignaturesRequired
    ) external;

    function setFunctionOwnersListIndex(
        address smartContractProxyAddress,
        bool onImplementation,
        bytes4 functionHash,
        uint256 ownersListsIndex
    ) external;

    function setFunctionNumberSignaturesRequired(
        address smartContractProxyAddress,
        bool onImplementation,
        bytes4 functionHash,
        uint256 numberSignaturesRequired
    ) external;

    function getFunctionOwnersListIndex(
        address smartContractProxyAddress,
        bool onImplementation,
        bytes4 functionHash
    ) external view returns (uint256 _ownersListsIndex);

    function getFunctionNumberSignaturesRequired(
        address smartContractProxyAddress,
        bool onImplementation,
        bytes4 functionHash
    ) external view returns (uint256 _numberSignaturesRequired);

    function setTransaction(
        uint256 transactionId,
        address destination,
        bool onImplementation,
        uint256 value,
        bytes4 functionHash,
        bytes calldata data,
        bool executed
    ) external;

    function setTransactionByDestination(uint256 transactionId, address _destination) external;

    function setTransactionByOnImplementation(uint256 transactionId, bool _onImplementation)
        external;

    function setTransactionByValue(uint256 transactionId, uint256 _value) external;

    function setTransactionByFunctionHash(uint256 transactionId, bytes4 _functionHash) external;

    function setTransactionByData(uint256 transactionId, bytes calldata _data) external;

    function setTransactionByExecuted(uint256 transactionId, bool _executed) external;

    function getTransactionByDestination(uint256 transactionId)
        external
        view
        returns (address _destination);

    function getTransactionByOnImplementation(uint256 transactionId)
        external
        view
        returns (bool _onImplementation);

    function getTransactionByValue(uint256 transactionId) external view returns (uint256 _value);

    function getTransactionByFunctionHash(uint256 transactionId)
        external
        view
        returns (bytes4 _functionHash);

    function getTransactionByData(uint256 transactionId) external view returns (bytes memory _data);

    function getTransactionByExecuted(uint256 transactionId) external view returns (bool _executed);

    function setSignature(
        uint256 transactionId,
        address owner,
        bool hasSigned
    ) external;

    function getSignature(uint256 transactionId, address owner)
        external
        view
        returns (bool _hasSigned);

    function setTransactionCount(uint256 _transactionCount) external;

    function getTransactionCount() external view returns (uint256 _transactionCount);

    function setMAX_OWNER_COUNT(uint256 _MAX_OWNER_COUNT) external;

    function getMAX_OWNER_COUNT() external view returns (uint256 _MAX_OWNER_COUNT);
}

// Copyright 2022 Energi Core

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

// Energi Governance system is the fundamental part of Energi Core.

// NOTE: It's not allowed to change the compiler due to byte-to-byte
//       match requirement.

pragma solidity 0.5.16;

interface IMultisigGovernedProxy {
    function receiveNRG() external payable;

    function external_call(
        address destination,
        uint256 value,
        uint256 dataLength,
        bytes calldata data
    ) external returns (bool);

    function emitSignature(address sender, uint256 transactionId) external;

    function emitRevocation(address sender, uint256 transactionId) external;

    function emitSubmission(uint256 transactionId) external;

    function emitExecution(uint256 transactionId) external;

    function emitExecutionFailure(uint256 transactionId) external;

    function emitDeposit(address sender, uint256 value) external;

    function emitOwnerAddition(uint256 ownersListsIndex, address owner) external;

    function emitOwnerRemoval(uint256 ownersListsIndex, address owner) external;

    function emitRequirementChange(
        address smartContractProxyAddress,
        bool onImplementation,
        bytes4 functionHash,
        uint256 ownersListsIndex,
        uint256 required
    ) external;
}

// Copyright 2022 Energi Core

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

pragma solidity 0.5.16;

interface IMultisig {
    function() external payable;

    function addOwner(uint256 ownersListsIndex, address owner) external;

    function removeOwner(uint256 ownersListsIndex, address owner) external;

    function replaceOwner(
        uint256 ownersListsIndex,
        address owner,
        address newOwner
    ) external;

    function changeRequirement(
        address smartContractProxyAddress,
        bool onImplementation,
        bytes4 functionHash,
        uint256 ownersListsIndex,
        uint256 required
    ) external;

    function submitTransaction(
        address destination,
        bool onImplementation,
        uint256 value,
        bytes4 functionHash,
        bytes calldata data
    ) external returns (uint256 transactionId);

    function addSignatureToTransaction(uint256 transactionId) external;

    function revokeSignature(uint256 transactionId) external;

    function executeTransaction(uint256 transactionId) external;

    function hasEnoughSignatures(uint256 transactionId) external view returns (bool);

    function getOwnersListLength(uint256 ownersListsIndex) external view returns (uint256);

    function getSignatureCount(uint256 transactionId) external view returns (uint256 count);

    function getTransactionCount(
        bool pending,
        bool executed,
        uint256 offset,
        uint256 limit
    ) external view returns (uint256 count);

    function getOwners(uint256 ownersListsIndex) external view returns (address[] memory);

    function getSignatures(uint256 transactionId)
        external
        view
        returns (address[] memory _signatures);

    function getTransactionIds(
        uint256 maxTxs,
        bool pending,
        bool executed,
        uint256 offset,
        uint256 limit
    ) external view returns (uint256[] memory _transactionIds);

    function getFunctionOwnersListIndex(
        address smartContractProxyAddress,
        bool onImplementation,
        bytes4 functionHash
    ) external view returns (uint256);

    function getFunctionNumberSignaturesRequired(
        address smartContractProxyAddress,
        bool onImplementation,
        bytes4 functionHash
    ) external view returns (uint256 _numberSignaturesRequired);

    function getOwnerByOwnersListsIndexAndIndex(uint256 ownersListsIndex, uint256 index)
        external
        view
        returns (address);

    function getIsOwnerFromList(uint256 ownersListsIndex, address ownerAddress)
        external
        view
        returns (bool);
}

// Copyright 2022 Energi Core

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

pragma solidity 0.5.16;

import { IProposal } from './IProposal.sol';
import { IGovernedContract } from './IGovernedContract.sol';

/**
 * Interface of UpgradeProposal
 */
contract IUpgradeProposal is IProposal {
    function impl() external view returns (IGovernedContract);
}

// Copyright 2022 Energi Core

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

pragma solidity 0.5.16;

interface IStorageBase {
    function setOwner(address _newOwner) external;
}

// Copyright 2022 Energi Core

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

pragma solidity 0.5.16;

import { IGovernedContract } from './IGovernedContract.sol';
import { IUpgradeProposal } from './IUpgradeProposal.sol';

interface ISporkRegistry {
    function createUpgradeProposal(
        IGovernedContract _impl,
        uint256 _period,
        address payable _fee_payer
    ) external payable returns (IUpgradeProposal);

    function consensusGasLimits() external view returns (uint256 callGas, uint256 xferGas);
}

// Copyright 2022 Energi Core

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

pragma solidity 0.5.16;

interface IProposal {
    function parent() external view returns (address);

    function created_block() external view returns (uint256);

    function deadline() external view returns (uint256);

    function fee_payer() external view returns (address payable);

    function fee_amount() external view returns (uint256);

    function accepted_weight() external view returns (uint256);

    function rejected_weight() external view returns (uint256);

    function total_weight() external view returns (uint256);

    function quorum_weight() external view returns (uint256);

    function isFinished() external view returns (bool);

    function isAccepted() external view returns (bool);

    function withdraw() external;

    function destroy() external;

    function collect() external;

    function voteAccept() external;

    function voteReject() external;

    function setFee() external payable;

    function canVote(address owner) external view returns (bool);
}

// Copyright 2022 Energi Core

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

pragma solidity 0.5.16;

import { IGovernedContract } from './IGovernedContract.sol';
import { IUpgradeProposal } from './IUpgradeProposal.sol';

/**
 * Genesis version of IGovernedProxy interface.
 *
 * Base Consensus interface for upgradable contracts proxy.
 * Unlike common approach, the implementation is NOT expected to be
 * called through delegatecall() to minimize risks of shared storage.
 *
 * NOTE: it MUST NOT change after blockchain launch!
 */
interface IGovernedProxy {
    event UpgradeProposal(IGovernedContract indexed impl, IUpgradeProposal proposal);

    event Upgraded(IGovernedContract indexed impl, IUpgradeProposal proposal);

    function impl() external view returns (IGovernedContract);

    function spork_proxy() external view returns (IGovernedProxy);

    function proposeUpgrade(IGovernedContract _newImpl, uint256 _period)
        external
        payable
        returns (IUpgradeProposal);

    function upgrade(IUpgradeProposal _proposal) external;

    function upgradeProposalImpl(IUpgradeProposal _proposal)
        external
        view
        returns (IGovernedContract new_impl);

    function listUpgradeProposals() external view returns (IUpgradeProposal[] memory proposals);

    function collectUpgradeProposal(IUpgradeProposal _proposal) external;

    function() external payable;
}

// Copyright 2022 Energi Core

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

pragma solidity 0.5.16;

/**
 * Genesis version of GovernedContract interface.
 *
 * Base Consensus interface for upgradable contracts.
 * Unlike common approach, the implementation is NOT expected to be
 * called through delegatecall() to minimize risks of shared storage.
 *
 * NOTE: it MUST NOT change after blockchain launch!
 */

interface IGovernedContract {
    // Return actual proxy address for secure validation
    function proxy() external view returns (address);

    // It must check that the caller is the proxy
    // and copy all required data from the old address.
    function migrate(IGovernedContract _oldImpl) external;

    // It must check that the caller is the proxy
    // and self destruct to the new address.
    function destroy(IGovernedContract _newImpl) external;

    // function () external payable; // This line (from original Energi IGovernedContract) is commented because it
    // makes truffle migrations fail
}

// Copyright 2022 Energi Core

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

pragma solidity 0.5.16;

import { IGovernedContract } from './interfaces/IGovernedContract.sol';

/**
 * Base for contract storage (SC-14).
 *
 * NOTE: it MUST NOT change after blockchain launch!
 */

contract StorageBase {
    address payable internal owner;

    modifier requireOwner() {
        require(msg.sender == address(owner), 'StorageBase: Not owner!');
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function setOwner(IGovernedContract _newOwner) external requireOwner {
        owner = address(uint160(address(_newOwner)));
    }

    function kill() external requireOwner {
        selfdestruct(msg.sender);
    }
}

// Copyright 2022 Energi Core

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

pragma solidity 0.5.16;

/**
 * A little helper to protect contract from being re-entrant in state
 * modifying functions.
 */

contract NonReentrant {
    uint256 private entry_guard;

    modifier noReentry() {
        require(entry_guard == 0, 'NonReentrant: Reentry');
        entry_guard = 1;
        _;
        entry_guard = 0;
    }
}

// Copyright 2022 Energi Core

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

pragma solidity 0.5.16;

import { IGovernedContract } from './interfaces/IGovernedContract.sol';

/**
 * Genesis version of GovernedContract common base.
 *
 * Base Consensus interface for upgradable contracts.
 * Unlike common approach, the implementation is NOT expected to be
 * called through delegatecall() to minimize risks of shared storage.
 *
 * NOTE: it MUST NOT change after blockchain launch!
 */
contract GovernedContract is IGovernedContract {
    address public proxy;

    constructor(address _proxy) public {
        proxy = _proxy;
    }

    modifier requireProxy() {
        require(msg.sender == proxy, 'Governed Contract: Not proxy');
        _;
    }

    function getProxy() internal view returns (address _proxy) {
        _proxy = proxy;
    }

    // Function overridden in child contract
    function migrate(IGovernedContract _oldImpl) external requireProxy {
        _migrate(_oldImpl);
    }

    // Function overridden in child contract
    function destroy(IGovernedContract _newImpl) external requireProxy {
        _destroy(_newImpl);
    }

    // solium-disable-next-line no-empty-blocks
    function _migrate(IGovernedContract) internal {}

    function _destroy(IGovernedContract _newImpl) internal {
        selfdestruct(address(uint160(address(_newImpl))));
    }

    function _callerAddress() internal view returns (address payable) {
        if (msg.sender == proxy) {
            // This is guarantee of the GovernedProxy
            // solium-disable-next-line security/no-tx-origin
            return tx.origin;
        } else {
            return msg.sender;
        }
    }
}