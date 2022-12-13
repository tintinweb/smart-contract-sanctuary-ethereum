// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import { StorageBase } from './StorageBase.sol';
import { ERC1155AssetAutoProxy } from './ERC1155AssetAutoProxy.sol';
import { GovernedERC1155 } from './GovernedERC1155.sol';

import { IERC165 } from './interfaces/IERC165.sol';
import { IERC1155Asset } from './interfaces/IERC1155Asset.sol';
import { IGovernedERC1155 } from './interfaces/IGovernedERC1155.sol';
import { IGovernedContract } from './interfaces/IGovernedContract.sol';
import { IERC1155AssetStorage } from './interfaces/IERC1155AssetStorage.sol';
import { IERC1155AssetGovernedProxy } from './interfaces/IERC1155AssetGovernedProxy.sol';

contract ERC1155AssetStorage is StorageBase, IERC1155AssetStorage {
    address private eRC1155AssetMinter; // this could be the relayer of a bridge - can mint/burn
    address private operations; // can withdraw minting fees from the proxy
    uint256 private mintFee;
    mapping(uint256 => address) private creators; // token ID to creator

    constructor(
        address _eRC1155AssetMinter,
        address _operations,
        uint256 _mintFee
    ) {
        eRC1155AssetMinter = _eRC1155AssetMinter;
        operations = _operations;
        mintFee = _mintFee;
    }

    /* View Functions */

    function getERC1155AssetMinter() external view override returns (address) {
        return eRC1155AssetMinter;
    }

    function getOperations() external view override returns (address) {
        return operations;
    }

    function getMintFee() external view override returns (uint256) {
        return mintFee;
    }

    function getCreator(uint256 _id) external view override returns (address) {
        return creators[_id];
    }

    /* Mutative Functions */

    function setERC1155AssetMinter(address _newERC1155AssetMinter) external override requireOwner {
        eRC1155AssetMinter = _newERC1155AssetMinter;
    }

    function setOperations(address _operations) external override requireOwner {
        operations = _operations;
    }

    function setMintFee(uint256 _mintFee) external override requireOwner {
        mintFee = _mintFee;
    }

    function setCreator(uint256 _id, address _creator) external override requireOwner {
        creators[_id] = _creator;
    }
}

contract ERC1155Asset is ERC1155AssetAutoProxy, IERC1155Asset {
    ERC1155AssetStorage public eRC1155AssetStorage;

    modifier onlyOwnerOrOperations() {
        require(
            msg.sender == owner || msg.sender == eRC1155AssetStorage.getOperations(),
            'ERC1155Asset: FORBIDDEN'
        );
        _;
    }

    constructor(
        address _proxy,
        address _owner,
        address _pausingOwner,
        address _minter,
        address _operations,
        uint256 _mintFee
    ) ERC1155AssetAutoProxy(_proxy, address(this), _owner, _pausingOwner) {
        eRC1155AssetStorage = new ERC1155AssetStorage(_minter, _operations, _mintFee);
    }

    // Governance functions

    // This function allows to set sporkProxy address after deployment in order to enable upgrades
    function setSporkProxy(address payable _sporkProxy) external onlyOwner {
        IERC1155AssetGovernedProxy(proxy).setSporkProxy(_sporkProxy);
    }

    // This function is called in order to upgrade to a new ERC1155 implementation
    function destroy(IGovernedContract _newImplementation) external requireProxy {
        eRC1155AssetStorage.setOwner(_newImplementation);
        _destroyERC1155(_newImplementation);
        _destroyERC2981(_newImplementation);
        _destroy(_newImplementation);
    }

    // This function (placeholder) would be called on the new implementation if necessary for the upgrade
    function migrate(IGovernedContract _oldImplementation) external requireProxy {
        eRC1155AssetStorage = ERC1155AssetStorage(
            IERC1155Asset(address(_oldImplementation)).eRC1155AssetStorage()
        );
        _migrateERC1155(address(_oldImplementation));
        _migrateERC2981(address(_oldImplementation));
        _migrate(_oldImplementation);
    }

    function withdrawETH(address _recipient, uint256 _amount) external onlyOwnerOrOperations {
        IERC1155AssetGovernedProxy(proxy).safeTransferETH(_recipient, _amount);
    }

    /* External mutative functions */

    function implMint(
        address caller,
        address account,
        uint256 id,
        uint256 value,
        string calldata _uri,
        bytes calldata data
    ) external payable virtual override whenNotPaused requireProxy {
        uint256 mintFee = eRC1155AssetStorage.getMintFee();

        if (mintFee > 0) {
            // Check if minting fee can be paid
            require(msg.value >= mintFee, 'ERC1155Asset: msg.value is too low');

            // Forward minting fee to proxy (proxy holds funds)
            // selector = bytes4(keccak256(bytes('receiveETH()')))
            (bool success, bytes memory returnData) = proxy.call{ value: mintFee }(
                abi.encodeWithSelector(0x3ecfd51e)
            );
            require(
                success && (returnData.length == 0 || abi.decode(returnData, (bool))),
                'ERC1155Asset: failed to forward minting fee'
            );
        }

        if (msg.value > mintFee) {
            // Transfer excess ETH back to caller
            (bool success, bytes memory returnData) = caller.call{ value: msg.value - mintFee }('');
            require(
                success && (returnData.length == 0 || abi.decode(returnData, (bool))),
                'ERC1155Asset: failed to return excess ETH'
            );
        }

        require(
            caller == owner || // owner is allowed
                caller == eRC1155AssetStorage.getERC1155AssetMinter() || // minter is allowed
                caller == eRC1155AssetStorage.getCreator(id) || // creator of token ID is allowed
                governedERC1155Storage.getTotalSupply(id) == 0, // if this is a new token, everyone can mint
            'ERC1155Asset: FORBIDDEN'
        );
        _mint(caller, account, id, value, _uri, data);
    }

    // The `mintBatch` function has to be called on the implementation directly and not via the proxy.
    function mintBatch(
        address account,
        uint256[] calldata ids,
        uint256[] calldata values,
        string[] calldata uris,
        bytes calldata data
    ) external payable virtual override noReentry whenNotPaused {
        require(msg.sender != proxy, 'ERC1155Asset: cannot call through proxy');

        address caller = msg.sender;

        uint256 mintFee = eRC1155AssetStorage.getMintFee();

        if (mintFee > 0) {
            // Check if minting fee can be paid
            require(msg.value >= mintFee * ids.length, 'ERC1155Asset: msg.value is too low');

            // Forward minting fee to proxy (proxy holds funds)
            // selector = bytes4(keccak256(bytes('receiveETH()')))
            (bool success, bytes memory returnData) = proxy.call{ value: mintFee * ids.length }(
                abi.encodeWithSelector(0x3ecfd51e)
            );
            require(
                success && (returnData.length == 0 || abi.decode(returnData, (bool))),
                'ERC1155Asset: failed to forward minting fee'
            );
        }

        if (msg.value > mintFee * ids.length) {
            // Transfer excess ETH back to caller
            (bool success, bytes memory returnData) = caller.call{
                value: msg.value - mintFee * ids.length
            }('');
            require(
                success && (returnData.length == 0 || abi.decode(returnData, (bool))),
                'ERC1155Asset: failed to return excess ETH'
            );
        }

        for (uint256 i = 0; i < ids.length; ++i) {
            require(
                caller == owner || // owner is authorized
                    caller == eRC1155AssetStorage.getERC1155AssetMinter() || // minter is authorized
                    caller == eRC1155AssetStorage.getCreator(ids[i]) || // creator of token ID is authorized
                    governedERC1155Storage.getTotalSupply(ids[i]) == 0, // if this is a new token, everyone can mint
                'ERC1155Asset: FORBIDDEN'
            );
        }
        _mintBatch(caller, account, ids, values, uris, data);
    }

    function implBurn(
        address caller,
        address account,
        uint256 id,
        uint256 value
    ) external virtual override whenNotPaused requireProxy {
        require(
            caller == owner || // owner is authorized
                caller == eRC1155AssetStorage.getERC1155AssetMinter() || // minter is authorized
                caller == account || // owner of the token ID is authorized
                isApprovedForAll(account, caller), // operator of the token ID is authorized
            'ERC1155Asset: FORBIDDEN'
        );
        _burn(caller, account, id, value);
    }

    function implBurnBatch(
        address caller,
        address account,
        uint256[] calldata ids,
        uint256[] calldata values
    ) external virtual override whenNotPaused requireProxy {
        require(
            caller == owner || // owner is authorized
                caller == eRC1155AssetStorage.getERC1155AssetMinter() || // minter is authorized
                caller == account || // owner of the token ID is authorized
                isApprovedForAll(account, caller), // operator of the token ID is authorized
            'ERC1155Asset: FORBIDDEN'
        );
        _burnBatch(caller, account, ids, values);
    }

    // ERC2981 related Royalty functions
    // feeNumerator is expressed in basepoints (between 0 and feeDenominator)
    function implSetTokenRoyalty(
        address caller,
        uint256 id,
        address beneficiary,
        uint96 feeNumerator
    ) external virtual override whenNotPaused requireProxy {
        require(
            caller == owner || // owner is authorized
                caller == eRC1155AssetStorage.getCreator(id), // creator is authorized
            'ERC1155Asset: FORBIDDEN'
        );
        _setTokenRoyalty(id, beneficiary, feeNumerator);
    }

    function implResetTokenRoyalty(address caller, uint256 id)
        external
        virtual
        override
        whenNotPaused
        requireProxy
    {
        require(
            caller == owner || // owner is authorized
                caller == eRC1155AssetStorage.getCreator(id), // creator is authorized
            'ERC1155Asset: FORBIDDEN'
        );
        _resetTokenRoyalty(id);
    }

    function feeDenominator() external pure returns (uint96) {
        return _feeDenominator();
    }

    /* external View Functions */

    function eRC1155AssetMinter() external view override returns (address) {
        return eRC1155AssetStorage.getERC1155AssetMinter();
    }

    function getOperations() external view override returns (address) {
        return eRC1155AssetStorage.getOperations();
    }

    function getMintFee() external view override returns (uint256) {
        return eRC1155AssetStorage.getMintFee();
    }

    function creator(uint256 id) external view virtual override returns (address) {
        return eRC1155AssetStorage.getCreator(id);
    }

    function uri(uint256 tokenId) external view virtual override returns (string memory) {
        return governedERC1155Storage.getUri(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(GovernedERC1155, IGovernedERC1155, IERC165)
        returns (bool)
    {
        return
            interfaceId == 0xd9b67a26 || // INTERFACE_ID_ERC1155
            interfaceId == 0x0e89341c || //INTERFACE_ID_ERC1155Metadata_URI
            super.supportsInterface(interfaceId);
    }

    /* Reserved mutative functions for contract owner */

    function setERC1155AssetMinter(address _newERC1155AssetMinter) external override onlyOwner {
        eRC1155AssetStorage.setERC1155AssetMinter(_newERC1155AssetMinter);
    }

    function setOperations(address _operations) external override onlyOwner {
        eRC1155AssetStorage.setOperations(_operations);
    }

    function setMintFee(uint256 _mintFee) external override onlyOwner {
        eRC1155AssetStorage.setMintFee(_mintFee);
    }

    function setDefaultRoyalty(address _beneficiary, uint96 _feeNumerator)
        external
        override
        onlyOwner
    {
        _setDefaultRoyalty(_beneficiary, _feeNumerator);
    }

    function deleteDefaultRoyalty() external override onlyOwner {
        _deleteDefaultRoyalty();
    }

    // internal functions

    function _mint(
        address caller,
        address account,
        uint256 id,
        uint256 value,
        string calldata _uri,
        bytes calldata data
    ) internal virtual {
        require(account != address(0), 'ERC1155Asset: cannot mint to address(0)');
        uint256 totalSupply = governedERC1155Storage.getTotalSupply(id);

        if (totalSupply == 0) {
            eRC1155AssetStorage.setCreator(id, caller); // Creator is set on first mint and can't be changed
            governedERC1155Storage.setUri(id, _uri); // URI is set on first mint and can't be changed
            IERC1155AssetGovernedProxy(proxy).emitURI(_uri, id); // Emit URI event when a new URI is set
        }
        governedERC1155Storage.setBalance(
            id,
            account,
            governedERC1155Storage.getBalance(id, account) + value
        );
        governedERC1155Storage.setTotalSupply(id, totalSupply + value);

        IERC1155AssetGovernedProxy(proxy).emitTransferSingle(
            caller,
            address(0),
            account,
            id,
            value
        );

        _doSafeTransferAcceptanceCheck(caller, address(0), account, id, value, data);
    }

    function _mintBatch(
        address caller,
        address account,
        uint256[] calldata ids,
        uint256[] calldata values,
        string[] calldata uris,
        bytes calldata data
    ) internal virtual {
        require(account != address(0), 'ERC1155Asset: cannot mint to address(0)');
        require(ids.length == values.length, 'ERC1155Asset: ids and values length mismatch');
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 totalSupply = governedERC1155Storage.getTotalSupply(ids[i]);

            if (totalSupply == 0) {
                eRC1155AssetStorage.setCreator(ids[i], caller); // Creator is set on first mint and can't be changed
                governedERC1155Storage.setUri(ids[i], uris[i]); // URI is set on first mint and can't be changed
                IERC1155AssetGovernedProxy(proxy).emitURI(uris[i], ids[i]); // Emit URI event when a new URI is set
            }
            uint256 accountBalance = governedERC1155Storage.getBalance(ids[i], account);
            governedERC1155Storage.setBalance(ids[i], account, accountBalance + values[i]);
            governedERC1155Storage.setTotalSupply(ids[i], totalSupply + values[i]);
        }

        IERC1155AssetGovernedProxy(proxy).emitTransferBatch(
            caller,
            address(0),
            account,
            ids,
            values
        );

        _doSafeBatchTransferAcceptanceCheck(caller, address(0), account, ids, values, data);
    }

    function _burn(
        address caller,
        address account,
        uint256 id,
        uint256 value
    ) internal virtual {
        require(account != address(0), 'ERC1155Asset: cannot burn from address(0)');
        uint256 fromBalance = governedERC1155Storage.getBalance(id, account);
        require(fromBalance >= value, 'ERC1155Asset: burn amount exceeds balance');
        governedERC1155Storage.setBalance(
            id,
            account,
            fromBalance - value
        );
        uint256 newSupply = governedERC1155Storage.getTotalSupply(id) - value;
        governedERC1155Storage.setTotalSupply(id, newSupply);
        if (newSupply == 0) {
            _resetTokenRoyalty(id);
            governedERC1155Storage.deleteUri(id);
        }

        IERC1155AssetGovernedProxy(proxy).emitTransferSingle(
            caller,
            account,
            address(0),
            id,
            value
        );
    }

    function _burnBatch(
        address caller,
        address account,
        uint256[] calldata ids,
        uint256[] calldata values
    ) internal virtual {
        require(account != address(0), 'ERC1155Asset: cannot burn from address(0)');
        require(ids.length == values.length, 'ERC1155Asset: ids and amounts length mismatch');
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 fromBalance = governedERC1155Storage.getBalance(ids[i], account);
            require(fromBalance >= values[i], 'ERC1155Asset: insufficient balance');
            governedERC1155Storage.setBalance(
                ids[i],
                account,
                fromBalance - values[i]
            );
            uint256 newSupply = governedERC1155Storage.getTotalSupply(ids[i]) - values[i];
            governedERC1155Storage.setTotalSupply(ids[i], newSupply);
            if (newSupply == 0) {
                _resetTokenRoyalty(ids[i]);
                governedERC1155Storage.deleteUri(ids[i]);
            }

            IERC1155AssetGovernedProxy(proxy).emitTransferBatch(
                caller,
                account,
                address(0),
                ids,
                values
            );
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import { IERC165 } from '../IERC165.sol';

interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import { IProposal } from './IProposal.sol';
import { IGovernedContract } from './IGovernedContract.sol';

/**
 * Interface of UpgradeProposal
 */
interface IUpgradeProposal is IProposal {
    function implementation() external view returns (IGovernedContract);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

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

pragma solidity 0.8.15;
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
    event UpgradeProposal(IGovernedContract indexed implementation, IUpgradeProposal proposal);

    event Upgraded(IGovernedContract indexed implementation, IUpgradeProposal proposal);

    function implementation() external view returns (IGovernedContract);

    function initialize(address _implementation) external;

    function proposeUpgrade(IGovernedContract _newImplementation, uint256 _period)
        external
        payable
        returns (IUpgradeProposal);

    function upgrade(IUpgradeProposal _proposal) external;

    function upgradeProposalImpl(IUpgradeProposal _proposal)
        external
        view
        returns (IGovernedContract newImplementation);

    function listUpgradeProposals() external view returns (IUpgradeProposal[] memory proposals);

    function collectUpgradeProposal(IUpgradeProposal _proposal) external;

    fallback() external;

    receive() external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IGovernedERC2981Storage {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    function getDefaultRoyaltyInfo() external view returns (address, uint96);

    function getTokenRoyaltyInfo(uint256 _tokenId) external view returns (address, uint96);

    function setDefaultRoyaltyInfo(address _receiver, uint96 _royaltyFraction) external;

    function deleteDefaultRoyaltyInfo() external;

    function setTokenRoyaltyInfo(
        uint256 _tokenId,
        address _receiver,
        uint96 _royaltyFraction
    ) external;

    function resetTokenRoyaltyInfo(uint256 _tokenId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import { IERC165 } from './IERC165.sol';

import { GovernedERC2981Storage } from '../GovernedERC2981.sol';

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IGovernedERC2981 is IERC165 {
    function governedERC2981Storage()
        external
        view
        returns (GovernedERC2981Storage governedERC2981Storage);

    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IGovernedERC1155Storage {
    function getUri(uint256 _id) external view returns (string memory);

    function getTotalSupply(uint256 _id) external view returns (uint256);

    function getBalance(uint256 _id, address _account) external view returns (uint256);

    function getOperatorApproval(address _account, address _operator) external view returns (bool);

    function setUri(uint256 _id, string calldata _uri) external;

    function deleteUri(uint256 _id) external;

    function setTotalSupply(uint256 _id, uint256 _totalSupply) external;

    function setBalance(
        uint256 _id,
        address _account,
        uint256 _balance
    ) external;

    function setOperatorApproval(
        address _account,
        address _operator,
        bool _approval
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import { GovernedERC1155Storage } from '../GovernedERC1155.sol';

import { IERC165 } from './IERC165.sol';

interface IGovernedERC1155 is IERC165 {
    function governedERC1155Storage()
        external
        view
        returns (GovernedERC1155Storage governedERC1155Storage);

    function implSetApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) external;

    function isApprovedForAll(address account, address operator) external view returns (bool);

    function implSafeTransferFrom(
        address caller,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function implSafeBatchTransferFrom(
        address caller,
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    function totalSupply(uint256 id) external view returns (uint256);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        external
        view
        returns (uint256[] memory);

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

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

pragma solidity 0.8.15;

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

pragma solidity 0.8.15;

interface IERC1155AssetStorage {
    function getERC1155AssetMinter() external view returns (address);

    function getOperations() external view returns (address);

    function getMintFee() external view returns (uint256);

    function getCreator(uint256 _id) external view returns (address);

    function setERC1155AssetMinter(address _newERC1155AssetMinter) external;

    function setOperations(address _operations) external;

    function setMintFee(uint256 _mintFee) external;

    function setCreator(uint256 _id, address _creator) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import { IERC165 } from './IERC165.sol';

interface IERC1155AssetGovernedProxy is IERC165 {
    // Event emitter functions

    function emitTransferSingle(
        address _operator,
        address _from,
        address _to,
        uint256 _id,
        uint256 _value
    ) external;

    function emitTransferBatch(
        address _operator,
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values
    ) external;

    function emitApprovalForAll(
        address _owner,
        address _operator,
        bool _approved
    ) external;

    function emitURI(string calldata _uri, uint256 _id) external;

    // Setter functions

    function setSporkProxy(address payable _sporkProxy) external;

    // Transfer functions

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes calldata _data
    ) external;

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _amounts,
        bytes calldata _data
    ) external;

    function safeTransferETH(address to, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import { IGovernedERC2981 } from './IGovernedERC2981.sol';
import { IGovernedERC1155 } from './IGovernedERC1155.sol';

import { ERC1155AssetStorage } from '../ERC1155Asset.sol';

interface IERC1155Asset is IGovernedERC2981, IGovernedERC1155 {
    function eRC1155AssetStorage() external view returns (ERC1155AssetStorage eRC1155AssetStorage);

    function implMint(
        address caller,
        address account,
        uint256 id,
        uint256 value,
        string calldata _uri,
        bytes calldata data
    ) external payable;

    function mintBatch(
        address account,
        uint256[] calldata ids,
        uint256[] calldata values,
        string[] calldata uris,
        bytes calldata data
    ) external payable;

    function implBurn(
        address caller,
        address account,
        uint256 id,
        uint256 value
    ) external;

    function implBurnBatch(
        address caller,
        address account,
        uint256[] calldata ids,
        uint256[] calldata values
    ) external;

    function implSetTokenRoyalty(
        address caller,
        uint256 id,
        address beneficiary,
        uint96 feeNumerator
    ) external;

    function implResetTokenRoyalty(address caller, uint256 id) external;

    function feeDenominator() external view returns (uint96);

    function eRC1155AssetMinter() external view returns (address);

    function getOperations() external view returns (address);

    function getMintFee() external view returns (uint256);

    function creator(uint256 id) external view returns (address);

    function uri(uint256 tokenId) external view returns (string memory);

    function setERC1155AssetMinter(address _newERC1155AssetMinter) external;

    function setOperations(address _operations) external;

    function setMintFee(uint256 _mintFee) external;

    function setDefaultRoyalty(address _beneficiary, uint96 _feeNumerator) external;

    function deleteDefaultRoyalty() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

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
        owner = payable(msg.sender);
    }

    function setOwner(IGovernedContract _newOwner) external requireOwner {
        owner = payable(address(uint160(address(_newOwner))));
    }

    function kill() external requireOwner {
        selfdestruct(payable(msg.sender));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import { Ownable } from './Ownable.sol';

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    /**
     * @dev Emitted when pause() is called.
     * @param account of contract owner issuing the event.
     * @param unpauseBlock block number when contract will be unpaused.
     */
    event Paused(address account, uint256 unpauseBlock);

    /**
     * @dev Emitted when pause is lifted by unpause() by
     * @param account.
     */
    event Unpaused(address account);

    event PausingOwnershipTransferred(
        address indexed previousPausingOwner,
        address indexed newPausingOwner
    );

    /**
     * @dev state variable
     */
    uint256 public blockNumberWhenToUnpause = 0;

    address public pausingOwner; // Can pause/unpause the implementation contract; This owner should be managed by 1 out of N Gnosis Safe.

    constructor(address _owner, address _pausingOwner) Ownable(_owner) {
        pausingOwner = _pausingOwner;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not
     *      paused. It checks whether the current block number
     *      has already reached blockNumberWhenToUnpause.
     */
    modifier whenNotPaused() {
        require(
            block.number >= blockNumberWhenToUnpause,
            'Pausable: Revert - Code execution is still paused'
        );
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(
            block.number < blockNumberWhenToUnpause,
            'Pausable: Revert - Code execution is not paused'
        );
        _;
    }

    /**
     * @dev Throws if called by any account other than the pausingOwner.
     */
    modifier onlyPausingOwner() {
        require(msg.sender == pausingOwner, 'Pausable: Not pausingOwner');
        _;
    }

    modifier onlyOwnerOrPausingOwner() {
        require(
            msg.sender == owner || msg.sender == pausingOwner,
            'Pausable: Not owner or pausingOwner'
        );
        _;
    }

    /**
     * @dev Triggers or extends pause state.
     *
     * Requirements:
     *
     * - @param blocks needs to be greater than 0.
     */
    function pause(uint256 blocks) external onlyPausingOwner {
        require(
            blocks > 0,
            'Pausable: Revert - Pause did not activate. Please enter a positive integer.'
        );
        blockNumberWhenToUnpause = block.number + blocks;
        emit Paused(msg.sender, blockNumberWhenToUnpause);
    }

    /**
     * @dev Returns to normal code execution.
     */
    function unpause() external onlyPausingOwner {
        blockNumberWhenToUnpause = block.number;
        emit Unpaused(msg.sender);
    }

    /**
     * @dev Allows the current owner or pausingOwner to transfer pausingOwner to a newPausingOwner.
     * @param newPausingOwner The new pausing owner address.
     */
    function transferPausingOwnership(address newPausingOwner) public onlyOwnerOrPausingOwner {
        require(newPausingOwner != address(0), 'Pausable: Zero address not allowed');
        emit PausingOwnershipTransferred(pausingOwner, newPausingOwner);
        pausingOwner = newPausingOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of 'user permissions'.
 */
contract Ownable {
    address public owner; // Can execute owner-protected functions; This owner should be managed by M out of N Gnosis Safe.

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor(address _owner) {
        owner = _owner;
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

pragma solidity 0.8.15;

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

pragma solidity 0.8.15;

import { ERC165 } from './ERC165.sol';
import { StorageBase } from './StorageBase.sol';

import { IERC165 } from './interfaces/IERC165.sol';
import { IGovernedERC2981 } from './interfaces/IGovernedERC2981.sol';
import { IGovernedContract } from './interfaces/IGovernedContract.sol';
import { IGovernedERC2981Storage } from './interfaces/IGovernedERC2981Storage.sol';

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
contract GovernedERC2981Storage is StorageBase, IGovernedERC2981Storage {
    RoyaltyInfo private _defaultRoyaltyInfo;

    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    function getDefaultRoyaltyInfo() external view override returns (address, uint96) {
        return (_defaultRoyaltyInfo.receiver, _defaultRoyaltyInfo.royaltyFraction);
    }

    function getTokenRoyaltyInfo(uint256 _tokenId)
        external
        view
        override
        returns (address, uint96)
    {
        return (_tokenRoyaltyInfo[_tokenId].receiver, _tokenRoyaltyInfo[_tokenId].royaltyFraction);
    }

    function setDefaultRoyaltyInfo(address _receiver, uint96 _royaltyFraction)
        external
        override
        requireOwner
    {
        _defaultRoyaltyInfo = RoyaltyInfo(_receiver, _royaltyFraction);
    }

    function deleteDefaultRoyaltyInfo() external override requireOwner {
        delete _defaultRoyaltyInfo;
    }

    function setTokenRoyaltyInfo(
        uint256 _tokenId,
        address _receiver,
        uint96 _royaltyFraction
    ) external override requireOwner {
        _tokenRoyaltyInfo[_tokenId] = RoyaltyInfo(_receiver, _royaltyFraction);
    }

    function resetTokenRoyaltyInfo(uint256 _tokenId) external override requireOwner {
        delete _tokenRoyaltyInfo[_tokenId];
    }
}

contract GovernedERC2981 is IGovernedERC2981, ERC165 {
    GovernedERC2981Storage public governedERC2981Storage;

    constructor() {
        governedERC2981Storage = new GovernedERC2981Storage();
    }

    // This function is called in order to upgrade to a new ERC1155 implementation
    function _destroyERC2981(IGovernedContract _newImplementation) internal {
        governedERC2981Storage.setOwner(_newImplementation);
    }

    // This function (placeholder) would be called on the new implementation if necessary for the upgrade
    function _migrateERC2981(address _oldImplementation) internal {
        governedERC2981Storage = GovernedERC2981Storage(
            IGovernedERC2981(_oldImplementation).governedERC2981Storage()
        );
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC165)
        returns (bool)
    {
        return
            //INTERFACE_ID_ERC2981
            interfaceId == 0x2a55205a || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IGovernedERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        virtual
        override
        returns (address, uint256)
    {
        (address receiver, uint96 royaltyFraction) = governedERC2981Storage.getTokenRoyaltyInfo(
            _tokenId
        );

        if (receiver == address(0)) {
            (receiver, royaltyFraction) = governedERC2981Storage.getDefaultRoyaltyInfo();
        }

        uint256 royaltyAmount = (_salePrice * royaltyFraction) / _feeDenominator();

        return (receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(
            feeNumerator <= _feeDenominator(),
            'GovernedERC2981: royalty fee will exceed salePrice'
        );
        require(receiver != address(0), 'GovernedERC2981: zero address can not receive royalties');

        governedERC2981Storage.setDefaultRoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        governedERC2981Storage.deleteDefaultRoyaltyInfo();
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `tokenId` must be already minted.
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(
            feeNumerator <= _feeDenominator(),
            'GovernedERC2981: royalty fee will exceed salePrice'
        );
        require(receiver != address(0), 'GovernedERC2981: zero address can not receive royalties');

        governedERC2981Storage.setTokenRoyaltyInfo(tokenId, receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        governedERC2981Storage.resetTokenRoyaltyInfo(tokenId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import { GovernedERC2981 } from './GovernedERC2981.sol';
import { Pausable } from './Pausable.sol';
import { StorageBase } from './StorageBase.sol';
import { NonReentrant } from './NonReentrant.sol';
import { GovernedContract } from './GovernedContract.sol';

import { IGovernedERC1155 } from './interfaces/IGovernedERC1155.sol';
import { IGovernedContract } from './interfaces/IGovernedContract.sol';
import { IERC1155Receiver } from './interfaces/helpers/IERC1155Receiver.sol';
import { IGovernedERC1155Storage } from './interfaces/IGovernedERC1155Storage.sol';
import { IERC1155AssetGovernedProxy } from './interfaces/IERC1155AssetGovernedProxy.sol';

contract GovernedERC1155Storage is StorageBase, IGovernedERC1155Storage {
    mapping(uint256 => string) private uri; // token ID to uri
    mapping(uint256 => uint256) private totalSupplies; // token ID to totalSupply
    mapping(uint256 => mapping(address => uint256)) private balances; // token ID to users to balances
    mapping(address => mapping(address => bool)) private operatorApprovals; // owner to operator to approval

    /* View Functions */

    function getUri(uint256 _id) external view override returns (string memory) {
        return uri[_id];
    }

    function getTotalSupply(uint256 _id) external view override returns (uint256) {
        return totalSupplies[_id];
    }

    function getBalance(uint256 _id, address _account) external view override returns (uint256) {
        return balances[_id][_account];
    }

    function getOperatorApproval(address _account, address _operator)
        external
        view
        override
        returns (bool)
    {
        return operatorApprovals[_account][_operator];
    }

    /* Mutative Functions */

    function setUri(uint256 _id, string calldata _uri) external override requireOwner {
        uri[_id] = _uri;
    }

    function deleteUri(uint256 _id) external override requireOwner {
        delete uri[_id];
    }

    function setTotalSupply(uint256 _id, uint256 _newTotalSupply) external override requireOwner {
        totalSupplies[_id] = _newTotalSupply;
    }

    function setBalance(
        uint256 _id,
        address _account,
        uint256 _balance
    ) external override requireOwner {
        balances[_id][_account] = _balance;
    }

    function setOperatorApproval(
        address _account,
        address _operator,
        bool _approval
    ) external override requireOwner {
        operatorApprovals[_account][_operator] = _approval;
    }
}

contract GovernedERC1155 is
    Pausable,
    NonReentrant,
    GovernedContract,
    GovernedERC2981,
    IGovernedERC1155
{
    GovernedERC1155Storage public governedERC1155Storage;

    constructor(
        address _proxy,
        address _owner,
        address _pausingOwner
    ) Pausable(_owner, _pausingOwner) GovernedContract(_proxy) {
        governedERC1155Storage = new GovernedERC1155Storage();
    }

    // This function is called in order to upgrade to a new ERC1155 implementation
    function _destroyERC1155(IGovernedContract _newImplementation) internal {
        governedERC1155Storage.setOwner(_newImplementation);
    }

    // This function (placeholder) would be called on the new implementation if necessary for the upgrade
    function _migrateERC1155(address _oldImplementation) internal {
        governedERC1155Storage = GovernedERC1155Storage(
            IGovernedERC1155(_oldImplementation).governedERC1155Storage()
        );
    }

    /* External mutative functions */

    function implSafeTransferFrom(
        address caller,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external virtual override whenNotPaused noReentry requireProxy {
        require(
            caller == from || // caller is owner
                isApprovedForAll(from, caller), // caller is operator
            'GovernedERC1155: caller is not owner nor approved'
        );
        _safeTransferFrom(caller, from, to, id, amount, data);
    }

    function implSafeBatchTransferFrom(
        address caller,
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external virtual override whenNotPaused noReentry requireProxy {
        require(
            caller == from || // caller is owner
                isApprovedForAll(from, caller), // caller is operator
            'GovernedERC1155: caller is not owner nor approved'
        );
        _safeBatchTransferFrom(caller, from, to, ids, amounts, data);
    }

    function implSetApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) external override whenNotPaused noReentry requireProxy {
        require(owner != operator, 'GovernedERC1155: setting approval status for self');
        governedERC1155Storage.setOperatorApproval(owner, operator, approved);
        // Emit ApprovalForAll event
        IERC1155AssetGovernedProxy(proxy).emitApprovalForAll(owner, operator, approved);
    }

    /* External View Functions */

    function totalSupply(uint256 id) external view override returns (uint256) {
        return governedERC1155Storage.getTotalSupply(id);
    }

    function balanceOf(address account, uint256 id) external view override returns (uint256) {
        return governedERC1155Storage.getBalance(id, account);
    }

    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        external
        view
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, 'GovernedERC1155: accounts and ids length mismatch');
        uint256[] memory batchBalances = new uint256[](ids.length);
        for (uint256 i = 0; i < ids.length; ++i) {
            batchBalances[i] = governedERC1155Storage.getBalance(ids[i], accounts[i]);
        }
        return batchBalances;
    }

    function isApprovedForAll(address account, address operator)
        public
        view
        override
        returns (bool)
    {
        return governedERC1155Storage.getOperatorApproval(account, operator);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(GovernedERC2981, IGovernedERC1155)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /* Internal functions */

    function _safeTransferFrom(
        address caller,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) internal virtual {
        require(from != address(0), 'GovernedERC1155: can not transfer from zero address');
        require(to != address(0), 'GovernedERC1155: can not transfer to zero address');
        uint256 fromBalance = governedERC1155Storage.getBalance(id, from);
        require(fromBalance >= amount, 'GovernedERC1155: insufficient balance for transfer');
        governedERC1155Storage.setBalance(id, from, fromBalance - amount);
        governedERC1155Storage.setBalance(
            id,
            to,
            governedERC1155Storage.getBalance(id, to) + amount
        );
        // Emit TransferSingle event
        IERC1155AssetGovernedProxy(proxy).emitTransferSingle(caller, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(caller, from, to, id, amount, data);
    }

    function _safeBatchTransferFrom(
        address caller,
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) internal virtual {
        require(
            from != address(0),
            'ERC1155GovernedERC1155Internal: can not transfer from zero address'
        );
        require(to != address(0), 'GovernedERC1155: can not transfer to zero address');
        require(ids.length == amounts.length, 'GovernedERC1155: ids and amounts length mismatch');
        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 fromBalance = governedERC1155Storage.getBalance(ids[i], from);
            uint256 toBalance = governedERC1155Storage.getBalance(ids[i], to);
            require(
                fromBalance >= amounts[i],
                'GovernedERC1155: insufficient balance for transfer'
            );
            governedERC1155Storage.setBalance(ids[i], from, fromBalance - amounts[i]);
            governedERC1155Storage.setBalance(ids[i], to, toBalance + amounts[i]);
        }
        // Emit TransferBatch event
        IERC1155AssetGovernedProxy(proxy).emitTransferBatch(caller, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(caller, from, to, ids, amounts, data);
    }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) internal {
        if (to.code.length > 0) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert('GovernedERC1155: ERC1155Receiver rejected tokens');
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert('GovernedERC1155: transfer to non ERC1155Receiver implementer');
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) internal {
        if (to.code.length > 0) {
            try
                IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data)
            returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert('GovernedERC1155: ERC1155Receiver rejected tokens');
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert('GovernedERC1155: transfer to non ERC1155Receiver implementer');
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

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

    function _destroy(IGovernedContract _newImplementation) internal {
        selfdestruct(payable(address(uint160(address(_newImplementation)))));
    }

    function _callerAddress() internal view returns (address payable) {
        if (msg.sender == proxy) {
            // This is guarantee of the GovernedProxy
            // solium-disable-next-line security/no-tx-origin
            return payable(tx.origin);
        } else {
            return payable(msg.sender);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import { IERC165 } from './interfaces/IERC165.sol';

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == 0x01ffc9a7; //INTERFACE_ID_ERC165
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import { GovernedERC1155 } from './GovernedERC1155.sol';

import { IGovernedProxy } from './interfaces/IGovernedProxy.sol';

contract ERC1155AssetAutoProxy is GovernedERC1155 {
    constructor(
        address _proxy,
        address _implementation,
        address _owner,
        address _pausingOwner
    ) GovernedERC1155(_proxy, _owner, _pausingOwner) {
        proxy = _proxy;
        IGovernedProxy(payable(proxy)).initialize(_implementation);
    }
}