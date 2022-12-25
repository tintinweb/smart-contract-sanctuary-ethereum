// SPDX-License-Identifier: MIT

/**
 *
 *  @title: Delegation Management Contract
 *  @date: 21-Dec-2022 @ 10:30
 *  @version: 4.23
 *  @notes: This is a experimental contract for delegation registry
 *  @author: skynet2030 (skyn3t2030)
 *
 */

pragma solidity 0.8.17;

contract delegationManagement {
    // Variable declarations
    uint256 useCaseCounter;

    // Mapping declarations
    mapping(bytes32 => bool) public registeredDelegation;
    mapping(bytes32 => uint256) public delegationToCounterPerHash;
    mapping(bytes32 => uint256) public delegationFromCounterPerHash;

    // Struct declaration
    struct delegationAddresses {
        address mainAddress;
        uint96 registeredDate;
        bytes32 delegationGlobalHash;
        bytes32 delegationToHash;
        bytes32 delegationFromHash;
        address collectionAddress;
        uint96 expiryDate;
        address delegationAddress;
        uint96 useCase;
    }

    // bytes32 mappings with arrays
    mapping(bytes32 => delegationAddresses[]) public delegateToHashes;
    mapping(bytes32 => delegationAddresses[]) public delegateFromHashes;

    // Events declaration

    event registerDelegation(
        address indexed from,
        address indexed collectionAddress,
        address indexed delegationAddress,
        uint256 useCase
    );
    event revokeDelegation(
        address indexed from,
        address indexed collectionAddress,
        address indexed delegationAddress,
        uint256 useCase
    );
    event updateDelegation(
        address indexed from,
        address indexed collectionAddress,
        address olddelegationAddress,
        address indexed newdelegationAddress,
        uint256 useCase
    );

    // Constructor
    constructor() {
        useCaseCounter = 15;
    }

    /**
     * @notice Delegator assigns a delegation address for a specific use case on a specific NFT collection for a certain duration
     *
     */
    function registerDelegationAddress(
        address _collectionAddress,
        address _delegationAddress,
        uint96 _expiryDate,
        uint96 _useCase
    ) public {
        require(
            (_useCase > 0 && _useCase < useCaseCounter) || (_useCase == 99)
        );
        bytes32 toHash;
        bytes32 fromHash;
        bytes32 globalHash;
        globalHash = keccak256(
            abi.encodePacked(
                msg.sender,
                _collectionAddress,
                _delegationAddress,
                _useCase
            )
        );
        toHash = keccak256(
            abi.encodePacked(msg.sender, _collectionAddress, _useCase)
        );
        fromHash = keccak256(
            abi.encodePacked(_delegationAddress, _collectionAddress, _useCase)
        );
        require(registeredDelegation[globalHash] == false);
        delegationAddresses memory newdelegationAddress = delegationAddresses(
            msg.sender,
            uint96(block.timestamp),
            globalHash,
            toHash,
            fromHash,
            _collectionAddress,
            _expiryDate,
            _delegationAddress,
            _useCase
        );
        delegateToHashes[toHash].push(newdelegationAddress);
        delegateFromHashes[fromHash].push(newdelegationAddress);
        delegationToCounterPerHash[toHash] =
            delegationToCounterPerHash[toHash] +
            1;
        delegationFromCounterPerHash[fromHash] =
            delegationFromCounterPerHash[fromHash] +
            1;
        registeredDelegation[globalHash] = true;
        emit registerDelegation(
            msg.sender,
            _collectionAddress,
            _delegationAddress,
            _useCase
        );
    }

    /**
     * @notice Delegator revokes delegation rights from a delagation address given to a specific use case on a specific NFT collection
     *
     */
    function revokeDelegationAddress(
        address _collectionAddress,
        address _delegationAddress,
        uint256 _useCase
    ) public {
        bytes32 toHash;
        bytes32 fromHash;
        bytes32 globalHash;
        uint256 count;
        globalHash = keccak256(
            abi.encodePacked(
                msg.sender,
                _collectionAddress,
                _delegationAddress,
                _useCase
            )
        );
        toHash = keccak256(
            abi.encodePacked(msg.sender, _collectionAddress, _useCase)
        );
        fromHash = keccak256(
            abi.encodePacked(_delegationAddress, _collectionAddress, _useCase)
        );
        // delete from toHashes mapping
        count = 0;
        for (uint256 i = 0; i <= delegationToCounterPerHash[toHash] - 1; i++) {
            if (
                globalHash == delegateToHashes[toHash][i].delegationGlobalHash
            ) {
                count = count + 1;
            }
        }
        uint256[] memory delegationsPerUser = new uint256[](count);
        uint256 count1 = 0;
        for (uint256 i = 0; i <= delegationToCounterPerHash[toHash] - 1; i++) {
            if (
                globalHash == delegateToHashes[toHash][i].delegationGlobalHash
            ) {
                delegationsPerUser[count1] = i;
                count1 = count1 + 1;
            }
        }
        if (count1 > 0) {
            for (uint256 j = 0; j <= delegationsPerUser.length - 1; j++) {
                uint256 temp1;
                uint256 temp2;
                temp1 = delegationsPerUser[delegationsPerUser.length - 1 - j];
                temp2 = delegateToHashes[toHash].length - 1;
                delegateToHashes[toHash][temp1] = delegateToHashes[toHash][
                    temp2
                ];
                delegateToHashes[toHash].pop();
                delegationToCounterPerHash[toHash] =
                    delegationToCounterPerHash[toHash] -
                    1;
            }
        }
        // delete from fromHashes mapping
        uint256 countFrom = 0;
        for (
            uint256 i = 0;
            i <= delegationFromCounterPerHash[fromHash] - 1;
            i++
        ) {
            if (
                globalHash ==
                delegateFromHashes[fromHash][i].delegationGlobalHash
            ) {
                countFrom = countFrom + 1;
            }
        }
        uint256[] memory delegationsFromPerUser = new uint256[](countFrom);
        uint256 countFrom1 = 0;
        for (
            uint256 i = 0;
            i <= delegationFromCounterPerHash[fromHash] - 1;
            i++
        ) {
            if (
                globalHash ==
                delegateFromHashes[fromHash][i].delegationGlobalHash
            ) {
                delegationsFromPerUser[countFrom1] = i;
                countFrom1 = countFrom1 + 1;
            }
        }
        if (countFrom1 > 0) {
            for (uint256 j = 0; j <= delegationsFromPerUser.length - 1; j++) {
                uint256 temp1;
                uint256 temp2;
                temp1 = delegationsFromPerUser[
                    delegationsFromPerUser.length - 1 - j
                ];
                temp2 = delegateFromHashes[fromHash].length - 1;
                delegateFromHashes[fromHash][temp1] = delegateFromHashes[
                    fromHash
                ][temp2];
                delegateFromHashes[fromHash].pop();
                delegationFromCounterPerHash[fromHash] =
                    delegationFromCounterPerHash[fromHash] -
                    1;
            }
        }
        registeredDelegation[globalHash] = false;
        emit revokeDelegation(
            msg.sender,
            _collectionAddress,
            _delegationAddress,
            _useCase
        );
    }

    /**
     * @notice Delegator updates a delegation address for a specific use case on a specific NFT collection for a certain duration
     *
     */
    function updateDelegationAddress(
        address _collectionAddress,
        address _olddelegationAddress,
        address _newdelegationAddress,
        uint96 _expiryDate,
        uint96 _useCase
    ) public {
        registerDelegationAddress(
            _collectionAddress,
            _newdelegationAddress,
            _expiryDate,
            _useCase
        );
        revokeDelegationAddress(
            _collectionAddress,
            _olddelegationAddress,
            _useCase
        );
        emit updateDelegation(
            msg.sender,
            _collectionAddress,
            _olddelegationAddress,
            _newdelegationAddress,
            _useCase
        );
    }

    // Getter functions

    /**
     * @notice Support function used to retrieve the hash given specific parameters
     *
     */
    function retrieveHash(
        address _profileAddress,
        address _collectionAddress,
        uint256 _useCase
    ) public pure returns (bytes32) {
        bytes32 hash;
        hash = keccak256(
            abi.encodePacked(_profileAddress, _collectionAddress, _useCase)
        );
        return (hash);
    }

    /**
     * @notice Returns an array of all delegation addresses (active AND inactive) set by a delegator for a specific use case on a specific NFT collection
     *
     */
    function retrieveToDelegationAddressesPerUsecaseForCollection(
        address _profileAddress,
        address _collectionAddress,
        uint256 _useCase
    ) external view returns (address[] memory) {
        bytes32 hash;
        hash = keccak256(
            abi.encodePacked(_profileAddress, _collectionAddress, _useCase)
        );
        address[] memory allDelegations = new address[](
            delegationToCounterPerHash[hash]
        );
        uint256 count;
        count = 0;
        for (uint256 i = 0; i <= delegateToHashes[hash].length - 1; i++) {
            if (hash == delegateToHashes[hash][i].delegationToHash) {
                allDelegations[count] = delegateToHashes[hash][i]
                    .delegationAddress;
                count = count + 1;
            }
        }
        return (allDelegations);
    }

    /**
     * @notice Returns an array of all delegators (active AND inactive) for a specific use case on a specific NFT collection
     *
     */
    function retrieveFromDelegationAddressesPerUsecaseForCollection(
        address _profileAddress,
        address _collectionAddress,
        uint256 _useCase
    ) external view returns (address[] memory) {
        bytes32 hash;
        hash = keccak256(
            abi.encodePacked(_profileAddress, _collectionAddress, _useCase)
        );
        address[] memory allDelegations = new address[](
            delegationFromCounterPerHash[hash]
        );
        uint256 count;
        count = 0;
        for (uint256 i = 0; i <= delegateFromHashes[hash].length - 1; i++) {
            if (hash == delegateFromHashes[hash][i].delegationFromHash) {
                allDelegations[count] = delegateFromHashes[hash][i].mainAddress;
                count = count + 1;
            }
        }
        return (allDelegations);
    }

    // Retrieve Active Delegations

    /**
     * @notice Returns an array of all active delegations on a certain date for a specific use case on a specific NFT collection
     *
     */
    function retrieveActiveToDelegations(
        address _profileAddress,
        address _collectionAddress,
        uint256 _date,
        uint256 _useCase
    ) external view returns (address[] memory) {
        bytes32 hash;
        hash = keccak256(
            abi.encodePacked(_profileAddress, _collectionAddress, _useCase)
        );
        address[] memory allDelegations = new address[](
            delegationToCounterPerHash[hash]
        );
        uint256 count;
        count = 0;
        for (uint256 i = 0; i <= delegateToHashes[hash].length - 1; i++) {
            if (
                (hash == delegateToHashes[hash][i].delegationToHash) &&
                (delegateToHashes[hash][i].expiryDate > _date)
            ) {
                allDelegations[count] = delegateToHashes[hash][i]
                    .delegationAddress;
                count = count + 1;
            }
        }
        return (allDelegations);
    }

    /**
     * @notice Returns an array of all active delegators on a certain date for a specific use case on a specific NFT collection
     *
     */

    function retrieveActiveFromDelegations(
        address _profileAddress,
        address _collectionAddress,
        uint256 _date,
        uint256 _useCase
    ) external view returns (address[] memory) {
        bytes32 hash;
        hash = keccak256(
            abi.encodePacked(_profileAddress, _collectionAddress, _useCase)
        );
        address[] memory allDelegations = new address[](
            delegationFromCounterPerHash[hash]
        );
        uint256 count;
        count = 0;
        for (uint256 i = 0; i <= delegateFromHashes[hash].length - 1; i++) {
            if (
                (hash == delegateFromHashes[hash][i].delegationFromHash) &&
                (delegateFromHashes[hash][i].expiryDate > _date)
            ) {
                allDelegations[count] = delegateFromHashes[hash][i].mainAddress;
                count = count + 1;
            }
        }
        return (allDelegations);
    }
}