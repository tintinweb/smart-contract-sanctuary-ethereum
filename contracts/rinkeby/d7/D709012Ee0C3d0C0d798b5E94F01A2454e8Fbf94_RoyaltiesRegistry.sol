// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.7.6;
pragma abicoder v2;

import { RoyaltiesRegistryAutoProxy } from './RoyaltiesRegistryAutoProxy.sol';
import { StorageBase } from '../StorageBase.sol';
import { Ownable } from '../Ownable.sol';

import { LibPartTypes } from '../libraries/LibPartTypes.sol';
import { LibRoyaltiesV2 } from '../libraries/LibRoyaltiesV2.sol';
import { LibRoyaltiesV1 } from '../libraries/LibRoyaltiesV1.sol';

import { IRoyaltiesRegistryGovernedProxy } from '../interfaces/IRoyaltiesRegistryGovernedProxy.sol';
import { IRoyaltiesRegistryStorage } from './IRoyaltiesRegistryStorage.sol';
import { IRoyaltiesRegistry } from './IRoyaltiesRegistry.sol';
import { IGovernedContract } from '../interfaces/IGovernedContract.sol';
import { IStorageBase } from '../interfaces/IStorageBase.sol';
import { IRoyaltiesV1 } from '../interfaces/IRoyaltiesV1.sol';
import { IRoyaltiesV2 } from '../interfaces/IRoyaltiesV2.sol';
import { IERC165 } from '../interfaces/IERC165.sol';
import { IOwnable } from '../interfaces/IOwnable.sol';

contract RoyaltiesRegistryStorage is StorageBase, IRoyaltiesRegistryStorage {
    mapping(bytes32 => LibRoyaltiesV2.RoyaltiesSet) private royaltiesByTokenAndTokenId;
    mapping(address => LibRoyaltiesV2.RoyaltiesSet) private royaltiesByToken;
    mapping(address => address) private royaltiesProviders; // royaltiesProviders are other contracts providing royalties

    // royaltiesByTokenAndTokenId getter
    //
    function getRoyaltiesByTokenAndTokenId(address token, uint256 tokenId)
        external
        view
        override
        returns (LibRoyaltiesV2.RoyaltiesSet memory)
    {
        return royaltiesByTokenAndTokenId[keccak256(abi.encode(token, tokenId))];
    }

    //
    // royaltiesByTokenAndTokenId setters
    //
    function initializeRoyaltiesByTokenAndTokenId(address token, uint256 tokenId)
        external
        override
        requireOwner
    {
        royaltiesByTokenAndTokenId[keccak256(abi.encode(token, tokenId))].initialized = true;
    }

    function pushRoyaltyByTokenAndTokenId(
        address token,
        uint256 tokenId,
        LibPartTypes.Part memory royalty
    ) external override requireOwner {
        royaltiesByTokenAndTokenId[keccak256(abi.encode(token, tokenId))].royalties.push(royalty);
    }

    function deleteRoyaltiesByTokenAndTokenId(address token, uint256 tokenId)
        external
        override
        requireOwner
    {
        delete royaltiesByTokenAndTokenId[keccak256(abi.encode(token, tokenId))].royalties;
    }

    //
    // royaltiesByToken getter
    //
    function getRoyaltiesByToken(address token)
        external
        view
        override
        returns (LibRoyaltiesV2.RoyaltiesSet memory)
    {
        return royaltiesByToken[token];
    }

    //
    // royaltiesByToken setters
    //
    function initializeRoyaltiesByToken(address token) external override requireOwner {
        royaltiesByToken[token].initialized = true;
    }

    function pushRoyaltyByToken(address token, LibPartTypes.Part memory royalty)
        external
        override
        requireOwner
    {
        royaltiesByToken[token].royalties.push(royalty);
    }

    function deleteRoyaltiesByToken(address token) external override requireOwner {
        delete royaltiesByToken[token];
    }

    //
    // royaltiesProviders getter
    //
    function getProviderByToken(address token) external view override returns (address) {
        return royaltiesProviders[token];
    }

    //
    // royaltiesProviders setters
    //
    function setProviderByToken(address token, address provider) external override requireOwner {
        royaltiesProviders[token] = provider;
    }
}

contract RoyaltiesRegistry is Ownable, RoyaltiesRegistryAutoProxy, IRoyaltiesRegistry {
    RoyaltiesRegistryStorage public _storage;

    modifier requireOwnerOrTokenOwner(address token) {
        require(
            // RoyaltiesRegistry owner must call on impl while token owner can also call on proxy
            msg.sender == owner || _callerAddress() == IOwnable(token).owner(),
            'RoyaltiesRegistry: FORBIDDEN, not contract or token owner'
        );
        _;
    }

    constructor(address _proxy) RoyaltiesRegistryAutoProxy(_proxy, address(this)) {
        _storage = new RoyaltiesRegistryStorage();
    }

    // Governance functions
    //
    // This function allows to set sporkProxy address after deployment in order to enable upgrades
    function setSporkProxy(address payable _sporkProxy) public onlyOwner {
        IRoyaltiesRegistryGovernedProxy(proxy).setSporkProxy(_sporkProxy);
    }

    // This function is called in order to upgrade to a new RoyaltiesRegistry implementation
    function destroy(IGovernedContract _newImpl) external requireProxy {
        IStorageBase(address(_storage)).setOwner(address(_newImpl));
        // Self destruct
        _destroy(_newImpl);
    }

    // This function (placeholder) would be called on the new implementation if necessary for the upgrade
    function migrate(IGovernedContract _oldImpl) external requireProxy {
        _migrate(_oldImpl);
    }

    // Royalties setters (to be called by RoyaltiesRegistry owner or by token owner)
    function setProviderByToken(address token, address provider)
        external
        override
        requireOwnerOrTokenOwner(token)
    {
        _storage.setProviderByToken(token, provider);
    }

    function setRoyaltiesByToken(address token, LibPartTypes.Part[] memory royalties)
        external
        override
        requireOwnerOrTokenOwner(token)
    {
        // Delete previous royalties data
        _storage.deleteRoyaltiesByToken(token);
        uint256 sumRoyalties = 0;
        // Iterate over new royalties array
        address[] memory royaltiesRecipients = new address[](royalties.length);
        uint96[] memory royaltiesAmounts = new uint96[](royalties.length);
        for (uint256 i = 0; i < royalties.length; i++) {
            require(
                royalties[i].account != address(0x0),
                'RoyaltiesRegistry: royaltiesByToken recipient should be present'
            );
            // Register new royalties
            _storage.pushRoyaltyByToken(token, royalties[i]);
            sumRoyalties += royalties[i].value;
            // Split royalties (array of structs) into two arrays to be passed the even emitter function on the proxy
            royaltiesRecipients[i] = address(royalties[i].account);
            royaltiesAmounts[i] = royalties[i].value;
        }
        // Make sure total royalties do not represent more than 100% of token sale amount
        require(
            sumRoyalties < 10000,
            'RoyaltiesRegistry: royalties for token cannot be more than 100%'
        );
        // Register royalties set as initialized
        _storage.initializeRoyaltiesByToken(token);
        // Emit RoyaltiesSetForContract event from proxy
        IRoyaltiesRegistryGovernedProxy(proxy).emitRoyaltiesSetForContract(
            token,
            royaltiesRecipients,
            royaltiesAmounts
        );
    }

    function setRoyaltiesByTokenAndTokenId(
        address token,
        uint256 tokenId,
        LibPartTypes.Part[] memory royalties
    ) external override requireOwnerOrTokenOwner(token) {
        // Delete previous royalties data
        _storage.deleteRoyaltiesByTokenAndTokenId(token, tokenId);
        uint256 sumRoyalties = 0;
        // Iterate over new royalties array
        address[] memory royaltiesRecipients = new address[](royalties.length);
        uint96[] memory royaltiesAmounts = new uint96[](royalties.length);
        for (uint256 i = 0; i < royalties.length; i++) {
            require(
                royalties[i].account != address(0x0),
                'RoyaltiesRegistry: royaltiesByTokenAndTokenId recipient should be present'
            );
            // Register new royalties
            _storage.pushRoyaltyByTokenAndTokenId(token, tokenId, royalties[i]);
            sumRoyalties += royalties[i].value;
            // Split royalties (array of structs) into two arrays to be passed the even emitter function on the proxy
            royaltiesRecipients[i] = address(royalties[i].account);
            royaltiesAmounts[i] = royalties[i].value;
        }
        // Make sure total royalties do not represent more than 100% of token sale amount
        require(
            sumRoyalties < 10000,
            'RoyaltiesRegistry: royalties for token and tokenID cannot be more than 100%'
        );
        // Register royalties set as initialized
        _storage.initializeRoyaltiesByTokenAndTokenId(token, tokenId);
        // Emit RoyaltiesSetForToken event from proxy
        IRoyaltiesRegistryGovernedProxy(proxy).emitRoyaltiesSetForToken(
            token,
            tokenId,
            royaltiesRecipients,
            royaltiesAmounts
        );
    }

    // Royalties getter
    function getRoyalties(address token, uint256 tokenId)
        external
        view
        override
        returns (LibPartTypes.Part[] memory)
    {
        // Get royalties from RoyaltiesRegistry storage using token address and token id
        LibRoyaltiesV2.RoyaltiesSet memory royaltiesSet = _storage.getRoyaltiesByTokenAndTokenId(
            token,
            tokenId
        );
        if (royaltiesSet.initialized) {
            return royaltiesSet.royalties;
        }
        // Get royalties from RoyaltiesRegistry storage using token address only
        royaltiesSet = _storage.getRoyaltiesByToken(token);
        if (royaltiesSet.initialized) {
            return royaltiesSet.royalties;
        }
        // Get royalties from another royalties provider
        (bool result, LibPartTypes.Part[] memory resultRoyalties) = providerExtractor(
            token,
            tokenId
        );
        if (result == false) {
            // Get royalties from the token contract itself assuming it implements Rarible's RoyaltiesV1/V2 standards
            resultRoyalties = royaltiesFromContract(token, tokenId);
        }
        return resultRoyalties;
    }

    // This function fetches royalties from the token contract
    function royaltiesFromContract(address token, uint256 tokenId)
        internal
        view
        returns (LibPartTypes.Part[] memory)
    {
        try IERC165(token).supportsInterface(LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) returns (
            bool id_royalties_supported
        ) {
            if (id_royalties_supported) {
                IRoyaltiesV2 royaltiesV2 = IRoyaltiesV2(token);
                try royaltiesV2.getRaribleV2Royalties(tokenId) returns (
                    LibPartTypes.Part[] memory res
                ) {
                    return res;
                } catch {}
            } else {
                address payable[] memory recipients;

                try
                    IERC165(token).supportsInterface(LibRoyaltiesV1._INTERFACE_ID_FEE_RECIPIENTS)
                returns (bool id_fee_recipients_supported) {
                    if (id_fee_recipients_supported) {
                        IRoyaltiesV1 royaltiesV1 = IRoyaltiesV1(token);
                        try royaltiesV1.getFeeRecipients(tokenId) returns (
                            address payable[] memory res
                        ) {
                            recipients = res;
                        } catch {
                            return new LibPartTypes.Part[](0);
                        }
                    }
                } catch {}

                uint256[] memory values;

                try IERC165(token).supportsInterface(LibRoyaltiesV1._INTERFACE_ID_FEE_BPS) returns (
                    bool id_fee_bps_supported
                ) {
                    if (id_fee_bps_supported) {
                        IRoyaltiesV1 royaltiesV1 = IRoyaltiesV1(token);
                        try royaltiesV1.getFeeBps(tokenId) returns (uint256[] memory res) {
                            values = res;
                        } catch {
                            return new LibPartTypes.Part[](0);
                        }
                    }
                } catch {}

                if (values.length != recipients.length) {
                    return new LibPartTypes.Part[](0);
                }
                LibPartTypes.Part[] memory result = new LibPartTypes.Part[](values.length);
                for (uint256 i = 0; i < values.length; i++) {
                    result[i].value = uint96(values[i]);
                    result[i].account = recipients[i];
                }
                return result;
            }
        } catch {}
        return new LibPartTypes.Part[](0);
    }

    // This function fetches royalties from an external royalties provider
    function providerExtractor(address token, uint256 tokenId)
        internal
        view
        returns (bool result, LibPartTypes.Part[] memory royalties)
    {
        result = false;
        address providerAddress = _storage.getProviderByToken(token);
        if (providerAddress != address(0x0)) {
            IRoyaltiesRegistry provider = IRoyaltiesRegistry(providerAddress);
            try provider.getRoyalties(token, tokenId) returns (
                LibPartTypes.Part[] memory royaltiesByProvider
            ) {
                royalties = royaltiesByProvider;
                result = true;
            } catch {}
        }
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.7.6;

import { GovernedContract } from '../GovernedContract.sol';
import { IGovernedProxy } from '../interfaces/IGovernedProxy.sol';

/**
 * RoyaltiesRegistryAutoProxy is a version of GovernedContract which deploys its own proxy.
 * This is useful to avoid a circular dependency between GovernedContract and GovernedProxy
 * wherein they need each other's address in the constructor.
 * If you want a new governed contract to create a proxy, pass address(0) when deploying
 * otherwise, you can pass a proxy address like in normal GovernedContract
 */

contract RoyaltiesRegistryAutoProxy is GovernedContract {
    constructor(address _proxy, address _impl) GovernedContract(_proxy) {
        proxy = _proxy;
        IGovernedProxy(payable(proxy)).initialize(_impl);
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.7.6;
pragma abicoder v2;

import { LibPartTypes } from '../libraries/LibPartTypes.sol';
import { LibRoyaltiesV2 } from '../libraries/LibRoyaltiesV2.sol';

interface IRoyaltiesRegistryStorage {
    function getRoyaltiesByTokenAndTokenId(address token, uint256 tokenId)
        external
        view
        returns (LibRoyaltiesV2.RoyaltiesSet memory);

    function initializeRoyaltiesByTokenAndTokenId(address token, uint256 tokenId) external;

    function pushRoyaltyByTokenAndTokenId(
        address token,
        uint256 tokenId,
        LibPartTypes.Part memory royalty
    ) external;

    function deleteRoyaltiesByTokenAndTokenId(address token, uint256 tokenId) external;

    function getRoyaltiesByToken(address token)
        external
        view
        returns (LibRoyaltiesV2.RoyaltiesSet memory);

    function initializeRoyaltiesByToken(address token) external;

    function pushRoyaltyByToken(address token, LibPartTypes.Part memory royalty) external;

    function deleteRoyaltiesByToken(address token) external;

    function getProviderByToken(address token) external view returns (address);

    function setProviderByToken(address token, address provider) external;
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.7.6;
pragma abicoder v2;

import { LibPartTypes } from '../libraries/LibPartTypes.sol';

interface IRoyaltiesRegistry {
    // Royalties setters
    function setProviderByToken(address token, address provider) external;

    function setRoyaltiesByToken(address token, LibPartTypes.Part[] memory royalties) external;

    function setRoyaltiesByTokenAndTokenId(
        address token,
        uint256 tokenId,
        LibPartTypes.Part[] memory royalties
    ) external;

    // Royalties getter
    function getRoyalties(address token, uint256 tokenId)
        external
        view
        returns (LibPartTypes.Part[] memory);
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.7.6;

import { LibPartTypes } from './LibPartTypes.sol';

library LibRoyaltiesV2 {
    struct RoyaltiesSet {
        bool initialized;
        LibPartTypes.Part[] royalties;
    }

    // bytes4(keccak256('getRaribleV2Royalties(uint256)')) == 0xcad96cca
    bytes4 constant _INTERFACE_ID_ROYALTIES = 0xcad96cca;
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.7.6;

library LibRoyaltiesV1 {
    // bytes4(keccak256('getFeeRecipients(uint256)')) == 0xb9c4d9fb
    bytes4 constant _INTERFACE_ID_FEE_RECIPIENTS = 0xb9c4d9fb;

    // bytes4(keccak256('getFeeBps(uint256)')) == 0x0ebd4c7f
    bytes4 constant _INTERFACE_ID_FEE_BPS = 0x0ebd4c7f;
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.7.6;

library LibPartTypes {
    struct Part {
        address payable account;
        uint96 value;
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

// Energi Governance system is the fundamental part of Energi Core.

// NOTE: It's not allowed to change the compiler due to byte-to-byte
// match requirement.

pragma solidity 0.7.6;

import { IProposal } from './IProposal.sol';
import { IGovernedContract } from './IGovernedContract.sol';

/**
 * Interface of UpgradeProposal
 */
interface IUpgradeProposal is IProposal {
    function impl() external view returns (IGovernedContract);
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.7.6;

interface IStorageBase {
    function setOwner(address _newOwner) external;
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.7.6;
pragma abicoder v2;

import { LibPartTypes } from '../libraries/LibPartTypes.sol';

interface IRoyaltiesV2 {
    event RoyaltiesSet(uint256 tokenId, LibPartTypes.Part[] royalties);

    function getRaribleV2Royalties(uint256 id) external view returns (LibPartTypes.Part[] memory);
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.7.6;

interface IRoyaltiesV1 {
    event SecondarySaleFees(uint256 tokenId, address[] recipients, uint256[] bps);

    function getFeeRecipients(uint256 id) external view returns (address payable[] memory);

    function getFeeBps(uint256 id) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

// Energi Governance system is the fundamental part of Energi Core.

// NOTE: It's not allowed to change the compiler due to byte-to-byte
// match requirement.

pragma solidity 0.7.6;
pragma abicoder v2;

interface IRoyaltiesRegistryGovernedProxy {
    function initialize(address _impl) external;

    function setSporkProxy(address payable _sporkProxy) external;

    function emitRoyaltiesSetForToken(
        address token,
        uint256 tokenId,
        address[] calldata royaltiesRecipients,
        uint96[] calldata royaltiesAmounts
    ) external;

    function emitRoyaltiesSetForContract(
        address token,
        address[] calldata royaltiesRecipients,
        uint96[] calldata royaltiesAmounts
    ) external;
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

// Energi Governance system is the fundamental part of Energi Core.

// NOTE: It's not allowed to change the compiler due to byte-to-byte
// match requirement.

pragma solidity 0.7.6;

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

// Copyright 2022 Energi Core

pragma solidity 0.7.6;

interface IOwnable {
    function owner() external view returns (address);
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

// Energi Governance system is the fundamental part of Energi Core.

// NOTE: It's not allowed to change the compiler due to byte-to-byte
// match requirement.

pragma solidity 0.7.6;
//pragma experimental SMTChecker;

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

    function initialize(address _impl) external;

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

    fallback() external;

    receive() external payable;
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

// Energi Governance system is the fundamental part of Energi Core.

// NOTE: It's not allowed to change the compiler due to byte-to-byte
// match requirement.

pragma solidity 0.7.6;

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
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.7.6;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

// Copyright 2022 Energi Core

pragma solidity 0.7.6;

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

    constructor() {
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

// Copyright 2022 Energi Core

pragma solidity 0.7.6;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of 'user permissions'.
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() {
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

// Copyright 2022 Energi Core

// Energi Governance system is the fundamental part of Energi Core.

// NOTE: It's not allowed to change the compiler due to byte-to-byte
// match requirement.

pragma solidity 0.7.6;

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
contract GovernedContract {
    address public proxy;

    constructor(address _proxy) {
        proxy = _proxy;
    }

    modifier requireProxy() {
        require(msg.sender == proxy, 'Governed Contract: Not proxy');
        _;
    }

    function getProxy() internal view returns (address _proxy) {
        _proxy = proxy;
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