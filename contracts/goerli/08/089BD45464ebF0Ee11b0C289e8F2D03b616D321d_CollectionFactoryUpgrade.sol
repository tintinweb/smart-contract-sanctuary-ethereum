// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.5.16;

import { CollectionFactoryAutoProxy } from '../factory/CollectionFactoryAutoProxy.sol';
import { CollectionFactoryStorage } from '../factory/CollectionFactory.sol';
import { CollectionStorage } from '../collectionStorage/CollectionStorage.sol';
import { CollectionProxy } from '../collectionProxy/CollectionProxy.sol';
import { NonReentrant } from '../NonReentrant.sol';
import { Ownable } from '../Ownable.sol';

import { IFactoryGovernedProxy } from '../factory/IFactoryGovernedProxy.sol';
import { ICollectionFactory } from '../factory/ICollectionFactory.sol';
import { ICollectionFactoryUpgrade } from './interfaces/ICollectionFactoryUpgrade.sol';
import { ICollectionManager } from '../interfaces/ICollectionManager.sol';
import { IGovernedProxy_New } from '../interfaces/IGovernedProxy_New.sol';
import { IStorageBase } from '../interfaces/IStorageBase.sol';
import { IGovernedContract } from '../interfaces/IGovernedContract.sol';

contract CollectionFactoryUpgrade is
    Ownable,
    NonReentrant,
    CollectionFactoryAutoProxy,
    ICollectionFactory
{
    CollectionFactoryStorage public _storage;

    constructor(
        address _proxy // use the collectionFactoryProxy address
    ) public CollectionFactoryAutoProxy(_proxy, address(0)) {}

    function setSporkProxy(address payable _sporkProxy) external onlyOwner {
        IFactoryGovernedProxy(proxy).setSporkProxy(_sporkProxy);
    }

    // This function is called in order to upgrade to a new CollectionFactory implementation
    function destroy(IGovernedContract _newImpl) external requireProxy {
        IStorageBase(address(_storage)).setOwner(address(_newImpl));

        // Self destruct
        _destroy(_newImpl);
    }

    // This function will be called on the new implementation if necessary for the upgrade
    function migrate(IGovernedContract _oldImpl) external requireProxy {
        _storage = CollectionFactoryStorage(
            ICollectionFactoryUpgrade(address(_oldImpl))._storage()
        );

        _migrate(_oldImpl);
    }

    function collectionManagerImpl() private view returns (address _collectionManagerImpl) {
        _collectionManagerImpl = address(
            IGovernedProxy_New(address(uint160(_storage.getCollectionManagerProxy())))
                .implementation()
        );
    }

    // permissioned functions
    function deploy(
        string calldata baseURI,
        string calldata name,
        string calldata symbol,
        address mintFeeERC20AssetProxy,
        uint256 mintFeeERC20,
        uint256[4] calldata mintFeeETH
    )
        external
        // mintFeeETH = [baseMintFeeETH, ethMintFeeIncreaseInterval, ethMintsCountThreshold, ethMintFeeGrowthRateBps]
        onlyOwner
    {
        require(mintFeeETH[2] > 0, 'CollectionFactory: ethMintsCountThreshold should be > 0');
        address collectionStorageAddress = address(
            new CollectionStorage(
                _storage.getCollectionManagerProxy(),
                _storage.getCollectionManagerHelperProxy(),
                baseURI,
                name,
                symbol
            )
        );

        address collectionProxyAddress;

        // Deploy CollectionProxy via CREATE2
        bytes memory bytecode = abi.encodePacked(
            type(CollectionProxy).creationCode,
            abi.encode(_storage.getCollectionManagerProxy()),
            abi.encode(_storage.getCollectionManagerHelperProxy())
        );
        bytes32 salt = keccak256(abi.encode(_storage.getCollectionProxyAddressesLength() + 1));
        assembly {
            collectionProxyAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        // Register CollectionProxy, and CollectionStorage into CollectionManager
        registerCollection(
            collectionProxyAddress,
            collectionStorageAddress,
            baseURI,
            name,
            symbol,
            mintFeeERC20AssetProxy,
            mintFeeERC20,
            mintFeeETH
        );
    }

    function registerCollection(
        address collectionProxyAddress,
        address collectionStorageAddress,
        string memory baseURI,
        string memory name,
        string memory symbol,
        address mintFeeERC20AssetProxy,
        uint256 mintFeeERC20,
        uint256[4] memory mintFeeETH
    ) private {
        // Register CollectionProxy, and CollectionStorage into CollectionManager
        ICollectionManager(collectionManagerImpl()).register(
            collectionProxyAddress,
            collectionStorageAddress,
            mintFeeERC20AssetProxy,
            mintFeeERC20,
            mintFeeETH
            // mintFeeETH = [baseMintFeeETH, ethMintFeeIncreaseInterval, ethMintsCountThreshold, ethMintFeeGrowthRateBps]
        );

        _storage.pushCollectionProxyAddress(collectionProxyAddress);

        // Emit collection creation event
        IFactoryGovernedProxy(address(uint160(proxy))).emitCollectionCreated(
            collectionProxyAddress,
            collectionStorageAddress,
            baseURI,
            name,
            symbol,
            _storage.getCollectionProxyAddressesLength()
        );
    }

    function getCollectionProxyAddress(uint256 _i) external view returns (address) {
        return _storage.getCollectionProxyAddress(_i);
    }

    function getCollectionManagerProxy() external view returns (address) {
        return _storage.getCollectionManagerProxy();
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.5.16;

interface ICollectionFactoryUpgrade {
    function _storage() external view returns (address);
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.5.16;

import { IProposal } from './IProposal.sol';
import { IGovernedContract } from './IGovernedContract.sol';

contract IUpgradeProposal is IProposal {
    function impl() external view returns (IGovernedContract);
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.5.16;

interface IStorageBase {
    function setOwner(address _newOwner) external;
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.5.16;

import { IGovernedContract } from './IGovernedContract.sol';
import { IUpgradeProposal } from './IUpgradeProposal.sol';

interface ISporkRegistry {
    function createUpgradeProposal(
        IGovernedContract _implementation,
        uint256 _period,
        address payable _fee_payer
    ) external payable returns (IUpgradeProposal);

    function consensusGasLimits() external view returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

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

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.5.16;

import { IGovernedContract } from './IGovernedContract.sol';
import { IUpgradeProposal } from './IUpgradeProposal.sol';

interface IGovernedProxy_New {
    event UpgradeProposal(IGovernedContract indexed implementation, IUpgradeProposal proposal);

    event Upgraded(IGovernedContract indexed implementation, IUpgradeProposal proposal);

    function spork_proxy() external view returns (address);

    function impl() external view returns (address);

    function implementation() external view returns (address);

    function proposeUpgrade(
        IGovernedContract _newImplementation,
        uint256 _period
    ) external payable returns (IUpgradeProposal);

    function upgrade(IUpgradeProposal _proposal) external;

    function upgradeProposalImpl(
        IUpgradeProposal _proposal
    ) external view returns (IGovernedContract newImplementation);

    function listUpgradeProposals() external view returns (IUpgradeProposal[] memory);

    function collectUpgradeProposal(IUpgradeProposal _proposal) external;

    function() external payable;
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.5.16;

interface IGovernedContract {
    // Return actual proxy address for secure validation
    function proxy() external view returns (address);

    // It must check that the caller is the proxy
    // and copy all required data from the old address.
    function migrate(IGovernedContract _oldImpl) external;

    // It must check that the caller is the proxy
    // and self destruct to the new address.
    function destroy(IGovernedContract _newImpl) external;
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.5.16;

interface IERC721ManagerHelper {
    /**
     * @dev safeMint function
     */
    function safeMint(
        address collectionProxy,
        address minter,
        address to,
        uint256 quantity,
        bool payWithWETH
    ) external payable;
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.5.16;

interface IERC721Manager {
    /**
     * @dev IERC165
     */
    function supportsInterface(bytes4) external view returns (bool);

    /**
     * @dev IERC721
     */
    function balanceOf(address collectionProxy, address owner) external view returns (uint256);

    function ownerOf(address collectionProxy, uint256 tokenId) external view returns (address);

    function safeTransferFrom(
        address collectionProxy,
        address spender,
        address from,
        address to,
        uint256 tokenId,
        bytes calldata _data
    ) external;

    function transferFrom(
        address collectionProxy,
        address spender,
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(
        address collectionProxy,
        address msgSender,
        address spender,
        uint256 tokenId
    ) external;

    function getApproved(address collectionProxy, uint256 tokenId) external view returns (address);

    function setApprovalForAll(
        address collectionProxy,
        address owner,
        address operator,
        bool approved
    ) external;

    function isApprovedForAll(
        address collectionProxy,
        address owner,
        address operator
    ) external view returns (bool);

    /**
     * @dev IERC721Metadata
     */
    function name(address collectionProxy) external view returns (string memory);

    function symbol(address collectionProxy) external view returns (string memory);

    function baseURI(address collectionProxy) external view returns (string memory);

    function tokenURI(
        address collectionProxy,
        uint256 tokenId
    ) external view returns (string memory);

    /**
     * @dev IERC721Enumerable
     */
    function totalSupply(address collectionProxy) external view returns (uint256);

    function tokenByIndex(
        address collectionProxy,
        uint256 index
    ) external view returns (uint256 tokenId);

    function tokenOfOwnerByIndex(
        address collectionProxy,
        address owner,
        uint256 index
    ) external view returns (uint256 tokenId);

    /**
     * @dev IERC721Burnable
     */
    function burn(address collectionProxy, address burner, uint256 tokenId) external;

    /**
     * @dev IERC721Ownable
     */
    function owner() external view returns (address);

    /**
     * @dev IERC2981
     */
    function royaltyInfo(
        address collectionProxy,
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address, uint256);
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.5.16;

interface ICollectionManager {
    function register(
        address _collectionProxy,
        address _collectionStorage,
        address _mintFeeERC20AssetProxy,
        uint256 _mintFeeERC20,
        uint256[4] calldata _mintFeeETH
        // mintFeeETH = [baseMintFeeETH, ethMintFeeIncreaseInterval, ethMintsCountThreshold, ethMintFeeGrowthRateBps]
    ) external;
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.5.16;

interface IFactoryGovernedProxy {
    event CollectionCreated(
        address collectionProxyAddress,
        address collectionStorageAddress,
        string baseURI,
        string name,
        string symbol,
        uint256 collectionLength
    );

    function emitCollectionCreated(
        address collectionProxyAddress,
        address collectionStorageAddress,
        string calldata baseURI,
        string calldata name,
        string calldata symbol,
        uint256 collectionLength
    ) external;

    function setSporkProxy(address payable _sporkProxy) external;
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.5.16;

interface ICollectionFactory {
    function deploy(
        string calldata baseURI,
        string calldata name,
        string calldata symbol,
        address mintFeeERC20Asset,
        uint256 mintFeeERC20,
        uint256[4] calldata mintFeeETH
    ) external;

    function getCollectionProxyAddress(uint256 _i) external view returns (address);

    function getCollectionManagerProxy() external view returns (address);
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

// Energi Governance system is a fundamental part of Energi Core.

// NOTE: It's not allowed to change the compiler due to byte-to-byte
// match requirement.

pragma solidity 0.5.16;

import { NonReentrant } from '../NonReentrant.sol';

import { ISporkRegistry } from '../interfaces/ISporkRegistry.sol';
import { IUpgradeProposal } from '../interfaces/IUpgradeProposal.sol';
import { IGovernedContract } from '../interfaces/IGovernedContract.sol';
import { IGovernedProxy_New } from '../interfaces/IGovernedProxy_New.sol';

/**
 * SC-9: This contract has no chance of being updated. It must be stupid simple.
 *
 * If another upgrade logic is required in the future - it can be done as proxy stage II.
 */
contract CollectionFactoryProxy is NonReentrant, IGovernedContract, IGovernedProxy_New {
    modifier senderOrigin() {
        // Internal calls are expected to use implementation directly.
        // That's due to use of call() instead of delegatecall() on purpose.
        // solium-disable-next-line security/no-tx-origin
        require(
            tx.origin == msg.sender,
            'CollectionFactoryGovernedProxy: Only direct calls are allowed!'
        );
        _;
    }

    modifier onlyImpl() {
        require(
            msg.sender == address(implementation),
            'CollectionFactoryGovernedProxy: Only calls from implementation are allowed!'
        );
        _;
    }

    IGovernedContract public implementation;
    IGovernedContract public impl;
    IGovernedProxy_New public spork_proxy;
    mapping(address => IGovernedContract) public upgrade_proposals;
    IUpgradeProposal[] public upgrade_proposal_list;

    event CollectionCreated(
        address collectionProxyAddress,
        address collectionStorageAddress,
        string baseURI,
        string name,
        string symbol,
        uint256 collectionLength
    );

    constructor(address _implementation) public {
        implementation = IGovernedContract(_implementation);
        impl = IGovernedContract(_implementation);
    }

    function setSporkProxy(address payable _sporkProxy) external onlyImpl {
        spork_proxy = IGovernedProxy_New(_sporkProxy);
    }

    // Emit CollectionCreated event
    function emitCollectionCreated(
        address collectionProxyAddress,
        address collectionStorageAddress,
        string calldata baseURI,
        string calldata name,
        string calldata symbol,
        uint256 collectionLength
    ) external onlyImpl {
        emit CollectionCreated(
            collectionProxyAddress,
            collectionStorageAddress,
            baseURI,
            name,
            symbol,
            collectionLength
        );
    }

    /**
     * Pre-create a new contract first.
     * Then propose upgrade based on that.
     */
    function proposeUpgrade(
        IGovernedContract _newImplementation,
        uint256 _period
    ) external payable senderOrigin noReentry returns (IUpgradeProposal) {
        require(_newImplementation != implementation, 'CollectionGovernedProxy: Already active!');
        require(
            _newImplementation.proxy() == address(this),
            'CollectionFactoryGovernedProxy: Wrong proxy!'
        );

        ISporkRegistry spork_reg = ISporkRegistry(address(spork_proxy.impl()));
        IUpgradeProposal proposal = spork_reg.createUpgradeProposal.value(msg.value)(
            _newImplementation,
            _period,
            msg.sender
        );

        upgrade_proposals[address(proposal)] = _newImplementation;
        upgrade_proposal_list.push(proposal);

        emit UpgradeProposal(_newImplementation, proposal);

        return proposal;
    }

    /**
     * Once proposal is accepted, anyone can activate that.
     */
    function upgrade(IUpgradeProposal _proposal) external noReentry {
        IGovernedContract newImplementation = upgrade_proposals[address(_proposal)];
        require(
            newImplementation != implementation,
            'CollectionFactoryGovernedProxy: Already active!'
        );
        // in case it changes in the flight
        require(
            address(newImplementation) != address(0),
            'CollectionFactoryGovernedProxy: Not registered!'
        );
        require(_proposal.isAccepted(), 'CollectionFactoryGovernedProxy: Not accepted!');

        IGovernedContract oldImplementation = implementation;

        newImplementation.migrate(oldImplementation);
        implementation = newImplementation;
        impl = newImplementation;
        oldImplementation.destroy(newImplementation);

        // SECURITY: prevent downgrade attack
        _cleanupProposal(_proposal);

        // Return fee ASAP
        _proposal.destroy();

        emit Upgraded(newImplementation, _proposal);
    }

    /**
     * Map proposal to implementation
     */
    function upgradeProposalImpl(
        IUpgradeProposal _proposal
    ) external view returns (IGovernedContract newImplementation) {
        newImplementation = upgrade_proposals[address(_proposal)];
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
        IGovernedContract newImplementation = upgrade_proposals[address(_proposal)];
        require(
            address(newImplementation) != address(0),
            'CollectionFactoryGovernedProxy: Not registered!'
        );
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
        revert('CollectionFactoryGovernedProxy: Good try');
    }

    /**
     * SECURITY: prevent on-behalf-of calls
     */
    function destroy(IGovernedContract) external {
        revert('CollectionFactoryGovernedProxy: Good try');
    }

    /**
     * Proxy all other calls to implementation.
     */
    function() external payable senderOrigin {
        // SECURITY: senderOrigin() modifier is mandatory

        // A dummy delegatecall opcode in the fallback function is necessary for
        // block explorers to pick up the Energi proxy-implementation pattern
        if (false) {
            (bool success, bytes memory data) = address(0).delegatecall(
                abi.encodeWithSignature('')
            );
            require(
                success && !success && data.length == 0 && data.length != 0,
                'CollectionFactoryGovernedProxy: delegatecall cannot be used'
            );
        }

        IGovernedContract implementation_m = implementation;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)

            let res := call(sub(gas, 10000), implementation_m, callvalue, ptr, calldatasize, 0, 0)
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

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

// Energi Governance system is a fundamental part of Energi Core.

// NOTE: It's not allowed to change the compiler due to byte-to-byte
// match requirement.

pragma solidity 0.5.16;

import { GovernedContract } from '../GovernedContract.sol';
import { CollectionFactoryProxy } from './CollectionFactoryProxy.sol';

/**
 * CollectionFactoryAutoProxy is a version of GovernedContract which deploys its own proxy.
 * This is useful to avoid a circular dependency between GovernedContract and GovernedProxy
 * wherein they need each other's address in the constructor.
 * If you want a new governed contract to create a proxy, pass address(0) when deploying
 * otherwise, you can pass a proxy address like in normal GovernedContract
 */

contract CollectionFactoryAutoProxy is GovernedContract {
    constructor(address _proxy, address _implementation) public GovernedContract(_proxy) {
        if (_proxy == address(0)) {
            _proxy = address(new CollectionFactoryProxy(_implementation));
        }
        proxy = _proxy;
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.5.16;

import { CollectionStorage } from '../collectionStorage/CollectionStorage.sol';
import { CollectionProxy } from '../collectionProxy/CollectionProxy.sol';

import { CollectionFactoryAutoProxy } from './CollectionFactoryAutoProxy.sol';
import { StorageBase } from '../StorageBase.sol';
import { Ownable } from '../Ownable.sol';

import { IFactoryGovernedProxy } from './IFactoryGovernedProxy.sol';
import { ICollectionManager } from '../interfaces/ICollectionManager.sol';
import { IStorageBase } from '../interfaces/IStorageBase.sol';
import { IGovernedContract } from '../interfaces/IGovernedContract.sol';
import { ICollectionFactory } from './ICollectionFactory.sol';
import { IGovernedProxy_New } from '../interfaces/IGovernedProxy_New.sol';

contract CollectionFactoryStorage is StorageBase {
    address private collectionManagerProxy;
    address private collectionManagerHelperProxy;

    address[] private collectionProxyAddresses;

    constructor(address _collectionManagerProxy, address _collectionManagerHelperProxy) public {
        collectionManagerProxy = _collectionManagerProxy;
        collectionManagerHelperProxy = _collectionManagerHelperProxy;
    }

    function getCollectionManagerProxy() external view returns (address) {
        return collectionManagerProxy;
    }

    function getCollectionManagerHelperProxy() external view returns (address) {
        return collectionManagerHelperProxy;
    }

    function getCollectionProxyAddress(uint256 _i) external view returns (address) {
        return collectionProxyAddresses[_i];
    }

    function getCollectionProxyAddressesLength() external view returns (uint256) {
        return collectionProxyAddresses.length;
    }

    function pushCollectionProxyAddress(address collectionProxyAddress) external requireOwner {
        collectionProxyAddresses.push(collectionProxyAddress);
    }

    function popCollectionProxyAddress() external requireOwner {
        collectionProxyAddresses.pop();
    }

    function setCollectionProxyAddresses(
        uint256 _i,
        address collectionProxyAddress
    ) external requireOwner {
        collectionProxyAddresses[_i] = collectionProxyAddress;
    }

    function setCollectionManagerProxy(address _collectionManagerProxy) external requireOwner {
        collectionManagerProxy = _collectionManagerProxy;
    }

    function setCollectionManagerHelperProxy(
        address _collectionManagerHelperProxy
    ) external requireOwner {
        collectionManagerHelperProxy = _collectionManagerHelperProxy;
    }
}

contract CollectionFactory is Ownable, CollectionFactoryAutoProxy, ICollectionFactory {
    bool public initialized = false;
    CollectionFactoryStorage public _storage;

    constructor(address _proxy) public CollectionFactoryAutoProxy(_proxy, address(this)) {}

    function setSporkProxy(address payable _sporkProxy) external onlyOwner {
        IFactoryGovernedProxy(proxy).setSporkProxy(_sporkProxy);
    }

    // Initialize contract. This function can only be called once
    function initialize(
        address _collectionManagerProxy,
        address _collectionManagerHelperProxy
    ) external onlyOwner {
        require(!initialized, 'CollectionFactory: already initialized');
        _storage = new CollectionFactoryStorage(
            _collectionManagerProxy,
            _collectionManagerHelperProxy
        );
        initialized = true;
    }

    // This function is called in order to upgrade to a new CollectionFactory implementation
    function destroy(IGovernedContract _newImpl) external requireProxy {
        IStorageBase(address(_storage)).setOwner(address(_newImpl));

        // Self destruct
        _destroy(_newImpl);
    }

    // This function (placeholder) would be called on the new implementation if necessary for the upgrade
    function migrate(IGovernedContract _oldImpl) external requireProxy {
        _migrate(_oldImpl);
    }

    function collectionManagerImpl() private view returns (address _collectionManagerImpl) {
        _collectionManagerImpl = address(
            IGovernedProxy_New(address(uint160(_storage.getCollectionManagerProxy())))
                .implementation()
        );
    }

    // permissioned functions
    function deploy(
        string calldata baseURI,
        string calldata name,
        string calldata symbol,
        address mintFeeERC20AssetProxy,
        uint256 mintFeeERC20,
        uint256[4] calldata mintFeeETH
    )
        external
        // mintFeeETH = [baseMintFeeETH, ethMintFeeIncreaseInterval, ethMintsCountThreshold, ethMintFeeGrowthRateBps]
        onlyOwner
    {
        require(mintFeeETH[2] > 0, 'CollectionFactory: ethMintsCountThreshold should be > 0');
        address collectionStorageAddress = address(
            new CollectionStorage(
                _storage.getCollectionManagerProxy(),
                _storage.getCollectionManagerHelperProxy(),
                baseURI,
                name,
                symbol
            )
        );

        address collectionProxyAddress;

        // Deploy CollectionProxy via CREATE2
        bytes memory bytecode = abi.encodePacked(
            type(CollectionProxy).creationCode,
            abi.encode(_storage.getCollectionManagerProxy()),
            abi.encode(_storage.getCollectionManagerHelperProxy())
        );
        bytes32 salt = keccak256(abi.encode(_storage.getCollectionProxyAddressesLength() + 1));
        assembly {
            collectionProxyAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        // Register CollectionProxy, and CollectionStorage into CollectionManager
        registerCollection(
            collectionProxyAddress,
            collectionStorageAddress,
            baseURI,
            name,
            symbol,
            mintFeeERC20AssetProxy,
            mintFeeERC20,
            mintFeeETH
        );
    }

    function registerCollection(
        address collectionProxyAddress,
        address collectionStorageAddress,
        string memory baseURI,
        string memory name,
        string memory symbol,
        address mintFeeERC20AssetProxy,
        uint256 mintFeeERC20,
        uint256[4] memory mintFeeETH
    ) private {
        // Register CollectionProxy, and CollectionStorage into CollectionManager
        ICollectionManager(collectionManagerImpl()).register(
            collectionProxyAddress,
            collectionStorageAddress,
            mintFeeERC20AssetProxy,
            mintFeeERC20,
            mintFeeETH
            // mintFeeETH = [baseMintFeeETH, ethMintFeeIncreaseInterval, ethMintsCountThreshold, ethMintFeeGrowthRateBps]
        );

        _storage.pushCollectionProxyAddress(collectionProxyAddress);

        // Emit collection creation event
        IFactoryGovernedProxy(address(uint160(proxy))).emitCollectionCreated(
            collectionProxyAddress,
            collectionStorageAddress,
            baseURI,
            name,
            symbol,
            _storage.getCollectionProxyAddressesLength()
        );
    }

    function getCollectionProxyAddress(uint256 _i) external view returns (address) {
        return _storage.getCollectionProxyAddress(_i);
    }

    function getCollectionManagerProxy() external view returns (address) {
        return _storage.getCollectionManagerProxy();
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.5.16;

import { StorageBase } from '../StorageBase.sol';

import { IGovernedProxy_New } from '../interfaces/IGovernedProxy_New.sol';

contract CollectionStorage is StorageBase {
    struct RoyaltyInfo {
        address receiver;
        uint96 fraction;
    }

    // name of the collection
    string private name;

    // symbol of the collection
    string private symbol;

    // baseURI of the collection
    string private baseURI;

    // collectionMoved is set to true after the collection has been moved to the
    // Energi blockchain, otherwise collectionMoved is set to false.
    bool private collectionMoved = false;

    // URI to a picture on IPFS (with a movementNotice) displayed by the tokenURI method
    // for all tokens after the collection has been moved to the Energi blockchain (collectionMoved == true);
    string private movementNoticeURI;

    // Total supply of the collection
    uint256 private totalSupply;

    // Array of tokenIds
    uint256[] private tokenIds;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private owners;

    // Mapping of owner address to array of owned tokenIds
    mapping(address => uint256[]) private tokenOfOwner;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private operatorApprovals;

    // Royalties for all tokenIds
    RoyaltyInfo private royaltyInfo;

    // Collection manager proxy address
    address private collectionManagerProxyAddress;

    // Collection manager helper proxy address
    address private collectionManagerHelperProxyAddress;

    modifier requireManager() {
        require(
            msg.sender ==
                address(
                    IGovernedProxy_New(address(uint160(collectionManagerProxyAddress)))
                        .implementation()
                ) ||
                msg.sender ==
                address(
                    IGovernedProxy_New(address(uint160(collectionManagerHelperProxyAddress)))
                        .implementation()
                ),
            'CollectionStorage: FORBIDDEN, not CollectionManager'
        );
        _;
    }

    constructor(
        address _collectionManagerProxyAddress,
        address _collectionManagerHelperProxyAddress,
        string memory _baseURI,
        string memory _name,
        string memory _symbol
    ) public {
        collectionManagerProxyAddress = _collectionManagerProxyAddress;
        collectionManagerHelperProxyAddress = _collectionManagerHelperProxyAddress;
        baseURI = _baseURI;
        name = _name;
        symbol = _symbol;
    }

    // Getter functions
    //
    function getName() external view returns (string memory _name) {
        _name = name;
    }

    function getSymbol() external view returns (string memory _symbol) {
        _symbol = symbol;
    }

    function getBaseURI() external view returns (string memory _baseURI) {
        _baseURI = baseURI;
    }

    function getCollectionMoved() external view returns (bool _collectionMoved) {
        _collectionMoved = collectionMoved;
    }

    function getMovementNoticeURI() external view returns (string memory _movementNoticeURI) {
        _movementNoticeURI = movementNoticeURI;
    }

    function getTotalSupply() external view returns (uint256 _totalSupply) {
        _totalSupply = totalSupply;
    }

    function getTokenIdsCount() external view returns (uint256 _tokenIdsCount) {
        _tokenIdsCount = tokenIds.length;
    }

    function getTokenIdByIndex(uint256 _index) external view returns (uint256 _tokenId) {
        _tokenId = tokenIds[_index];
    }

    function getOwner(uint256 tokenId) external view returns (address _owner) {
        _owner = owners[tokenId];
    }

    function getBalance(address _address) external view returns (uint256 _amount) {
        _amount = tokenOfOwner[_address].length;
    }

    function getTokenOfOwnerByIndex(
        address _owner,
        uint256 _index
    ) external view returns (uint256 _tokenId) {
        _tokenId = tokenOfOwner[_owner][_index];
    }

    function getTokenApproval(uint256 _tokenId) external view returns (address _address) {
        _address = tokenApprovals[_tokenId];
    }

    function getOperatorApproval(
        address _owner,
        address _operator
    ) external view returns (bool _approved) {
        _approved = operatorApprovals[_owner][_operator];
    }

    function getRoyaltyReceiver() external view returns (address _royaltyReceiver) {
        _royaltyReceiver = royaltyInfo.receiver;
    }

    function getRoyaltyFraction() external view returns (uint96 _royaltyFraction) {
        _royaltyFraction = royaltyInfo.fraction;
    }

    function getRoyaltyInfo()
        external
        view
        returns (address _royaltyReceiver, uint96 _royaltyFraction)
    {
        _royaltyReceiver = royaltyInfo.receiver;
        _royaltyFraction = royaltyInfo.fraction;
    }

    function getCollectionManagerProxyAddress()
        external
        view
        returns (address _collectionManagerProxyAddress)
    {
        _collectionManagerProxyAddress = collectionManagerProxyAddress;
    }

    function getCollectionManagerHelperProxyAddress()
        external
        view
        returns (address _collectionManagerHelperProxyAddress)
    {
        _collectionManagerHelperProxyAddress = collectionManagerHelperProxyAddress;
    }

    // Setter functions
    //
    function setName(string calldata _name) external requireManager {
        name = _name;
    }

    function setSymbol(string calldata _symbol) external requireManager {
        symbol = _symbol;
    }

    function setBaseURI(string calldata _baseURI) external requireManager {
        baseURI = _baseURI;
    }

    function setCollectionMoved(bool _collectionMoved) external requireManager {
        collectionMoved = _collectionMoved;
    }

    function setMovementNoticeURI(string calldata _movementNoticeURI) external requireManager {
        movementNoticeURI = _movementNoticeURI;
    }

    function setTotalSupply(uint256 _value) external requireManager {
        totalSupply = _value;
    }

    function setTokenIdByIndex(uint256 _tokenId, uint256 _index) external requireManager {
        tokenIds[_index] = _tokenId;
    }

    function pushTokenId(uint256 _tokenId) external requireManager {
        tokenIds.push(_tokenId);
    }

    function popTokenId() external requireManager {
        tokenIds.pop();
    }

    function setOwner(uint256 tokenId, address owner) external requireManager {
        owners[tokenId] = owner;
    }

    function setTokenOfOwnerByIndex(
        address _owner,
        uint256 _index,
        uint256 _tokenId
    ) external requireManager {
        tokenOfOwner[_owner][_index] = _tokenId;
    }

    function pushTokenOfOwner(address _owner, uint256 _tokenId) external requireManager {
        tokenOfOwner[_owner].push(_tokenId);
    }

    function popTokenOfOwner(address _owner) external requireManager {
        tokenOfOwner[_owner].pop();
    }

    function setTokenApproval(uint256 _tokenId, address _address) external requireManager {
        tokenApprovals[_tokenId] = _address;
    }

    function setOperatorApproval(
        address _owner,
        address _operator,
        bool _approved
    ) external requireManager {
        operatorApprovals[_owner][_operator] = _approved;
    }

    function setRoyaltyInfo(address receiver, uint96 fraction) external requireManager {
        royaltyInfo.receiver = receiver;
        royaltyInfo.fraction = fraction;
    }

    function setCollectionManagerProxyAddress(
        address _collectionManagerProxyAddress
    ) external requireManager {
        collectionManagerProxyAddress = _collectionManagerProxyAddress;
    }

    function setCollectionManagerHelperProxyAddress(
        address _collectionManagerHelperProxyAddress
    ) external requireManager {
        collectionManagerHelperProxyAddress = _collectionManagerHelperProxyAddress;
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.5.16;

interface ICollectionProxy {
    /**
     * @dev IERC165
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    /**
     * @dev IERC721
     */
    function balanceOf(address user) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata _data
    ) external;

    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev IERC721Metadata
     */
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function baseURI() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    /**
     * @dev IERC721Enumerable
     */
    function totalSupply() external view returns (uint256);

    function tokenByIndex(uint256 index) external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev safeMint function
     */
    function safeMint(address to, uint256 quantity, bool payWithWETH) external payable;

    /**
     * @dev IERC721Burnable
     */
    function burn(uint256 tokenId) external;

    /**
     * @dev IERC721Ownable
     */
    function owner() external view returns (address);

    /**
     * @dev IERC2981
     */
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address, uint256);
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

// Energi Governance system is a fundamental part of Energi Core.

// NOTE: It's not allowed to change the compiler due to byte-to-byte
// match requirement.

pragma solidity 0.5.16;

import { IGovernedProxy_New } from '../interfaces/IGovernedProxy_New.sol';
import { IERC721Manager } from '../interfaces/IERC721Manager.sol';
import { IERC721ManagerHelper } from '../interfaces/IERC721ManagerHelper.sol';
import { ICollectionProxy } from './ICollectionProxy.sol';

/**
 * SC-9: This contract has no chance of being updated. It must be stupid simple.
 *
 * If another upgrade logic is required in the future - it can be done as proxy stage II.
 */
contract CollectionProxy is ICollectionProxy {
    address public collectionManagerProxy;

    address public collectionManagerHelperProxy;

    modifier senderOrigin() {
        // Internal calls are expected to use implementation directly.
        // That's due to use of call() instead of delegatecall() on purpose.
        // solium-disable-next-line security/no-tx-origin
        require(
            tx.origin == msg.sender,
            'CollectionProxy::senderOrigin: FORBIDDEN, not a direct call'
        );
        _;
    }

    function collectionManager() private view returns (address _collectionManager) {
        _collectionManager = address(
            IGovernedProxy_New(address(uint160(collectionManagerProxy))).implementation()
        );
    }

    function collectionManagerHelper() private view returns (address _collectionManagerHelper) {
        _collectionManagerHelper = address(
            IGovernedProxy_New(address(uint160(collectionManagerHelperProxy))).implementation()
        );
    }

    modifier requireManager() {
        require(
            msg.sender == collectionManager() || msg.sender == collectionManagerHelper(),
            'CollectionProxy::requireManager: FORBIDDEN, not CollectionManager or CollectionManagerHelper'
        );
        _;
    }

    /**
     * @dev ERC721 events
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // Constructor (called by CollectionFactory at deployment)
    constructor(address _collectionManagerProxy, address _collectionManagerHelperProxy) public {
        collectionManagerProxy = _collectionManagerProxy;
        collectionManagerHelperProxy = _collectionManagerHelperProxy;
    }

    /**
     * @dev Event emitter functions (called by ERC721Manager)
     */
    function emitTransfer(address from, address to, uint256 tokenId) external requireManager {
        emit Transfer(from, to, tokenId);
    }

    function emitApproval(
        address owner,
        address approved,
        uint256 tokenId
    ) external requireManager {
        emit Approval(owner, approved, tokenId);
    }

    function emitApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) external requireManager {
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev ERC165 supportsInterface function
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool returnValue) {
        return IERC721Manager(collectionManager()).supportsInterface(interfaceId);
    }

    /**
     * @dev ERC721 functions
     */
    function balanceOf(address user) external view returns (uint256) {
        return IERC721Manager(collectionManager()).balanceOf(address(this), user);
    }

    function ownerOf(uint256 tokenId) external view returns (address) {
        return IERC721Manager(collectionManager()).ownerOf(address(this), tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata _data
    ) external {
        IERC721Manager(collectionManager()).safeTransferFrom(
            address(this),
            msg.sender,
            from,
            to,
            tokenId,
            _data
        );
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external {
        IERC721Manager(collectionManager()).safeTransferFrom(
            address(this),
            msg.sender,
            from,
            to,
            tokenId,
            ''
        );
    }

    function transferFrom(address from, address to, uint256 tokenId) external {
        IERC721Manager(collectionManager()).transferFrom(
            address(this),
            msg.sender,
            from,
            to,
            tokenId
        );
    }

    function approve(address to, uint256 tokenId) external {
        IERC721Manager(collectionManager()).approve(address(this), msg.sender, to, tokenId);
    }

    function getApproved(uint256 tokenId) external view returns (address) {
        return IERC721Manager(collectionManager()).getApproved(address(this), tokenId);
    }

    function setApprovalForAll(address operator, bool approved) external {
        IERC721Manager(collectionManager()).setApprovalForAll(
            address(this),
            msg.sender,
            operator,
            approved
        );
    }

    function isApprovedForAll(address owner, address operator) external view returns (bool) {
        return IERC721Manager(collectionManager()).isApprovedForAll(address(this), owner, operator);
    }

    /**
     * @dev ERC721Metadata functions
     */
    function name() external view returns (string memory) {
        return IERC721Manager(collectionManager()).name(address(this));
    }

    function symbol() external view returns (string memory) {
        return IERC721Manager(collectionManager()).symbol(address(this));
    }

    function baseURI() external view returns (string memory) {
        return IERC721Manager(collectionManager()).baseURI(address(this));
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        return IERC721Manager(collectionManager()).tokenURI(address(this), tokenId);
    }

    /**
     * @dev ERC721Enumerable functions
     */
    function totalSupply() external view returns (uint256) {
        return IERC721Manager(collectionManager()).totalSupply(address(this));
    }

    function tokenByIndex(uint256 index) external view returns (uint256 tokenId) {
        return IERC721Manager(collectionManager()).tokenByIndex(address(this), index);
    }

    function tokenOfOwnerByIndex(
        address owner,
        uint256 index
    ) external view returns (uint256 tokenId) {
        return IERC721Manager(collectionManager()).tokenOfOwnerByIndex(address(this), owner, index);
    }

    /**
     * @dev safeMint function
     */
    function safeMint(address to, uint256 quantity, bool payWithWETH) external payable {
        IERC721ManagerHelper(collectionManagerHelper()).safeMint.value(msg.value)(
            address(this),
            msg.sender,
            to,
            quantity,
            payWithWETH
        );
    }

    /**
     * @dev ERC721Burnable burn function
     */
    function burn(uint256 tokenId) external {
        IERC721Manager(collectionManager()).burn(address(this), msg.sender, tokenId);
    }

    /**
     * @dev ERC721Ownable owner function
     */
    function owner() external view returns (address) {
        return IERC721Manager(collectionManager()).owner();
    }

    /**
     * @dev ERC2981 royaltyInfo function
     */
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address receiver, uint256 royaltyAmount) {
        return IERC721Manager(collectionManager()).royaltyInfo(address(this), tokenId, salePrice);
    }

    // SECURITY: This is to prevent on-behalf-of calls through the fallback function
    function safeMint(address, address, address, uint256, bool) external pure {
        revert('Good try');
    }

    // SECURITY: This is to prevent on-behalf-of calls through the fallback function
    function burn(address, address, uint256) external pure {
        revert('Good try');
    }

    // SECURITY: This is to prevent on-behalf-of calls through the fallback function
    function approve(address, address, address, uint256) external pure {
        revert('Good try');
    }

    // SECURITY: This is to prevent on-behalf-of calls through the fallback function
    function setApprovalForAll(address, address, address, bool) external pure {
        revert('Good try');
    }

    // SECURITY: This is to prevent on-behalf-of calls through the fallback function
    function transferFrom(address, address, address, address, uint256) external pure {
        revert('Good try');
    }

    // SECURITY: This is to prevent on-behalf-of calls through the fallback function
    function safeTransferFrom(
        address,
        address,
        address,
        address,
        uint256,
        bytes calldata
    ) external pure {
        revert('Good try');
    }

    // Proxy all other calls to CollectionManager.
    function() external payable senderOrigin {
        // SECURITY: senderOrigin() modifier is mandatory

        address _collectionManager = collectionManager();

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())

            let res := call(
                sub(gas(), 10000),
                _collectionManager,
                callvalue(),
                ptr,
                calldatasize(),
                0,
                0
            )
            // NOTE: returndatasize should allow repeatable calls
            //       what should save one opcode.
            returndatacopy(ptr, 0, returndatasize())

            switch res
            case 0 {
                revert(ptr, returndatasize())
            }
            default {
                return(ptr, returndatasize())
            }
        }
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

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

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.5.16;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, 'Ownable: Not owner');
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), 'Ownable: Zero address not allowed');
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

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

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

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