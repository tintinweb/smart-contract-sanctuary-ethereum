// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

import { ERC721ManagerAutoProxy } from '../eRC721Manager/ERC721ManagerAutoProxy.sol';
import { ERC721ManagerStorage } from '../eRC721Manager/ERC721Manager.sol';
import { Pausable } from '../Pausable.sol';
import { ERC165 } from '../eRC721Manager/ERC165.sol';

import { ICollectionProxy_ManagerFunctions } from '../interfaces/ICollectionProxy_ManagerFunctions.sol';
import { IERC721ManagerUpgrade } from './interfaces/IERC721ManagerUpgrade.sol';
import { IERC721ManagerProxy } from '../interfaces/IERC721ManagerProxy.sol';
import { ICollectionStorage } from '../interfaces/ICollectionStorage.sol';
import { IERC721Enumerable } from '../interfaces/IERC721Enumerable.sol';
import { IERC721Metadata } from '../interfaces/IERC721Metadata.sol';
import { IERC721Receiver } from '../interfaces/IERC721Receiver.sol';
import { IGovernedProxy } from '../interfaces/IGovernedProxy.sol';
import { IStorageBase } from '../interfaces/IStorageBase.sol';
import { IERC2981 } from '../interfaces/IERC2981.sol';
import { IERC721 } from '../interfaces/IERC721.sol';
import { IOperatorFilterRegistry } from '../interfaces/IOperatorFilterRegistry.sol';
import { IFarmingManager } from '../interfaces/IFarmingManager.sol';

import { Address } from '../libraries/Address.sol';
import { Strings } from '../libraries/Strings.sol';

contract ERC721ManagerUpgrade is Pausable, ERC721ManagerAutoProxy, ERC165 {
    using Strings for uint256;
    using Address for address;

    address public helperProxy;
    address public factoryProxy;
    address public farmingManagerProxy;

    IOperatorFilterRegistry public operatorFilterRegistry;

    ERC721ManagerStorage public _storage;

    constructor(
        address _proxy,
        address _helperProxy,
        address _factoryProxy,
        address _operatorFilterRegistry,
        address _registrant
    ) ERC721ManagerAutoProxy(_proxy, address(0)) {
        helperProxy = _helperProxy;
        factoryProxy = _factoryProxy;

        operatorFilterRegistry = IOperatorFilterRegistry(_operatorFilterRegistry);
        IOperatorFilterRegistry(_operatorFilterRegistry).registerAndSubscribe(
            address(this),
            _registrant
        );
    }

    modifier requireCollectionProxy() {
        require(
            address(_storage.getCollectionStorage(msg.sender)) != address(0),
            'ERC721Manager: FORBIDDEN, not a Collection proxy'
        );
        _;
    }

    // Modifier for self-custodial farming
    modifier requireNotStaked(address collectionProxy, uint256 tokenId) {
        // When token is staked, transferring or burning token is not allowed
        if (farmingManagerProxy != address(0)) {
            require(
                !IFarmingManager(IGovernedProxy(payable(farmingManagerProxy)).impl()).isStaked(
                    collectionProxy,
                    tokenId
                ),
                'ERC721Manager: cannot transfer or burn staked tokens'
            );
        }
        _;
    }

    /**
     * @dev A helper function to check if an operator is allowed.
     */
    modifier onlyAllowedOperator(address from, address msgSender) {
        // Allow spending tokens from addresses with balance
        // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
        // from an EOA.
        if (from != msgSender) {
            _checkFilterOperator(msgSender);
        }
        _;
    }

    /**
     * @dev A helper function to check if an operator approval is allowed.
     */
    modifier onlyAllowedOperatorApproval(address operator) {
        _checkFilterOperator(operator);
        _;
    }

    /**
     * @dev A helper function to check if an operator is allowed.
     */
    function _checkFilterOperator(address operator) private view {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(operatorFilterRegistry).code.length > 0) {
            // under normal circumstances, this function will revert rather than return false, but inheriting contracts
            // may specify their own OperatorFilterRegistry implementations, which may behave differently
            require(
                operatorFilterRegistry.isOperatorAllowed(address(this), operator),
                'ERC721Manager: operator not allowed'
            );
        }
    }

    /**
     * @dev Governance functions
     */
    // This function is called in order to upgrade to a new ERC721Manager implementation
    function destroy(address _newImpl) external requireProxy {
        IStorageBase(address(_storage)).setOwner(address(_newImpl));
        // Self destruct
        _destroy(_newImpl);
    }

    // This function will be called on the new implementation if necessary for the upgrade
    function migrate(address _oldImpl) external requireProxy {
        _storage = ERC721ManagerStorage(IERC721ManagerUpgrade(address(_oldImpl))._storage());
        _migrate(_oldImpl);
    }

    /**
     * @dev Factory restricted function
     */
    // This function is called by Factory implementation at a new collection creation
    // Register a new Collection's proxy address, and Collection's storage address
    function register(
        address _collectionProxy,
        address _collectionStorage,
        address _mintFeeERC20AssetProxy,
        uint256 _mintFeeERC20,
        uint256[4] calldata _mintFeeETH
    )
        external
        // _mintFeeETH = [baseMintFeeETH, ethMintFeeIncreaseInterval, ethMintsCountThreshold, ethMintFeeGrowthRateBps]
        whenNotPaused
    {
        require(
            msg.sender == address(IGovernedProxy(payable(factoryProxy)).impl()),
            'ERC721Manager: Not factory implementation!'
        );
        _storage.setCollectionStorage(_collectionProxy, _collectionStorage);
        _storage.pushCollectionProxy(_collectionProxy);
        _storage.setMintFeeERC20AssetProxy(_collectionProxy, _mintFeeERC20AssetProxy);
        _storage.setMintFeeERC20(_collectionProxy, _mintFeeERC20);
        _storage.setMintFeeETH(_collectionProxy, _mintFeeETH);
    }

    /**
     * @dev ERC165
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId ||
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev ERC721
     */
    function balanceOf(address collectionProxy, address owner) external view returns (uint256) {
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        require(owner != address(0), 'ERC721Manager: balance query for the zero address');
        return collectionStorage.getBalance(owner);
    }

    function ownerOf(address collectionProxy, uint256 tokenId) external view returns (address) {
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        address owner = collectionStorage.getOwner(tokenId);
        require(owner != address(0), 'ERC721Manager: owner query for nonexistent token');
        return owner;
    }

    function safeTransferFrom(
        address collectionProxy,
        address spender,
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    )
        external
        requireCollectionProxy
        whenNotPaused
        requireNotStaked(collectionProxy, tokenId)
        onlyAllowedOperator(from, spender)
    {
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        address owner = collectionStorage.getOwner(tokenId);
        require(owner != address(0), 'ERC721Manager: nonexistent token');
        require(
            spender == owner ||
                collectionStorage.getTokenApproval(tokenId) == spender ||
                collectionStorage.getOperatorApproval(owner, spender),
            'ERC721Manager: transfer caller is not owner nor approved'
        );

        _safeTransferFrom(
            collectionStorage,
            collectionProxy,
            owner,
            spender,
            from,
            to,
            tokenId,
            _data
        );
    }

    function transferFrom(
        address collectionProxy,
        address spender,
        address from,
        address to,
        uint256 tokenId
    )
        external
        requireCollectionProxy
        whenNotPaused
        requireNotStaked(collectionProxy, tokenId)
        onlyAllowedOperator(from, spender)
    {
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        address owner = collectionStorage.getOwner(tokenId);
        require(owner != address(0), 'ERC721Manager: nonexistent token');
        require(
            spender == owner ||
                collectionStorage.getTokenApproval(tokenId) == spender ||
                collectionStorage.getOperatorApproval(owner, spender),
            'ERC721Manager: transfer caller is not owner nor approved'
        );

        _transfer(collectionStorage, collectionProxy, owner, from, to, tokenId);
    }

    function approve(
        address collectionProxy,
        address msgSender,
        address spender,
        uint256 tokenId
    ) external requireCollectionProxy whenNotPaused onlyAllowedOperatorApproval(spender) {
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        address owner = collectionStorage.getOwner(tokenId);
        require(owner != address(0), 'ERC721Manager: nonexistent token');
        require(spender != owner, 'ERC721Manager: approval to current owner');
        require(
            msgSender == owner || collectionStorage.getOperatorApproval(owner, msgSender),
            'ERC721Manager: approve caller is not owner nor approved for all'
        );

        _approve(collectionStorage, collectionProxy, owner, spender, tokenId);
    }

    function getApproved(address collectionProxy, uint256 tokenId) external view returns (address) {
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        require(
            _exists(collectionStorage, tokenId),
            'ERC721Manager: approved query for nonexistent token'
        );

        return collectionStorage.getTokenApproval(tokenId);
    }

    function setApprovalForAll(
        address collectionProxy,
        address owner,
        address operator,
        bool approved
    ) external requireCollectionProxy whenNotPaused onlyAllowedOperatorApproval(operator) {
        _setApprovalForAll(collectionProxy, owner, operator, approved);
    }

    function isApprovedForAll(
        address collectionProxy,
        address owner,
        address operator
    ) external view returns (bool) {
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        return collectionStorage.getOperatorApproval(owner, operator);
    }

    /**
     * @dev ERC721Metadata
     */
    function name(address collectionProxy) external view returns (string memory) {
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        return collectionStorage.getName();
    }

    function symbol(address collectionProxy) external view returns (string memory) {
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        return collectionStorage.getSymbol();
    }

    function baseURI(address collectionProxy) external view returns (string memory) {
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        if (collectionStorage.getCollectionMoved()) {
            return collectionStorage.getMovementNoticeURI();
        }

        string memory baseURI_local = collectionStorage.getBaseURI();
        return baseURI_local;
    }

    function tokenURI(
        address collectionProxy,
        uint256 tokenId
    ) external view returns (string memory) {
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        require(
            _exists(collectionStorage, tokenId),
            'ERC721Manager: URI query for nonexistent token'
        );

        if (collectionStorage.getCollectionMoved()) {
            return collectionStorage.getMovementNoticeURI();
        }

        string memory baseURI_local = collectionStorage.getBaseURI();
        return
            bytes(baseURI_local).length > 0
                ? string(abi.encodePacked(baseURI_local, tokenId.toString()))
                : '';
    }

    /**
     * @dev ERC721Enumerable
     */
    function totalSupply(address collectionProxy) external view returns (uint256) {
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        return collectionStorage.getTotalSupply();
    }

    function tokenByIndex(
        address collectionProxy,
        uint256 index
    ) external view returns (uint256 tokenId) {
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        require(
            index < collectionStorage.getTotalSupply(),
            'ERC721Manager: index must be less than total supply'
        );
        tokenId = collectionStorage.getTokenIdByIndex(index);
    }

    function tokenOfOwnerByIndex(
        address collectionProxy,
        address owner,
        uint256 index
    ) external view returns (uint256 tokenId) {
        require(
            owner != address(0),
            'ERC721Manager: tokenOfOwnerByIndex query for the zero address'
        );
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        require(
            collectionStorage.getBalance(owner) > index,
            'ERC721Manager: index must be less than address balance'
        );
        tokenId = collectionStorage.getTokenOfOwnerByIndex(owner, index);
    }

    /**
     * @dev ERC721Burnable
     */
    function burn(
        address collectionProxy,
        address burner,
        uint256 tokenId
    ) external requireCollectionProxy whenNotPaused requireNotStaked(collectionProxy, tokenId) {
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        address owner = collectionStorage.getOwner(tokenId);
        require(owner != address(0), 'ERC721Manager: nonexistent token');
        require(
            burner == owner ||
                collectionStorage.getTokenApproval(tokenId) == burner ||
                collectionStorage.getOperatorApproval(owner, burner),
            'ERC721Manager: burn caller is not owner nor approved'
        );

        _burn(collectionStorage, collectionProxy, owner, tokenId);
    }

    /**
     * @dev ERC2981
     */
    function royaltyInfo(
        address collectionProxy,
        uint256, // Royalties are identical for all tokenIds
        uint256 salePrice
    ) external view returns (address, uint256) {
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        address receiver = collectionStorage.getRoyaltyReceiver();
        uint256 royaltyAmount;
        if (receiver != address(0)) {
            uint96 fraction = collectionStorage.getRoyaltyFraction();
            royaltyAmount = (salePrice * fraction) / _storage.getFeeDenominator();
        } else {
            royaltyAmount = 0;
        }

        return (receiver, royaltyAmount);
    }

    /**
     * @dev Private ERC721 functions
     */
    function _exists(
        ICollectionStorage collectionStorage,
        uint256 tokenId
    ) private view returns (bool) {
        return collectionStorage.getOwner(tokenId) != address(0);
    }

    function _transfer(
        ICollectionStorage collectionStorage,
        address collectionProxy,
        address owner,
        address from,
        address to,
        uint256 tokenId
    ) private {
        require(to != address(0), 'ERC721Manager: transfer to the zero address');
        require(owner == from, 'ERC721Manager: transfer from incorrect owner');
        // Clear approvals from the previous owner
        _approve(collectionStorage, collectionProxy, owner, address(0), tokenId);
        // Update tokenId ownership
        uint256 fromBalance = collectionStorage.getBalance(from);
        for (uint256 i = 0; i < fromBalance; i++) {
            if (collectionStorage.getTokenOfOwnerByIndex(from, i) == tokenId) {
                if (i < fromBalance - 1) {
                    // If transferred tokenId is not in the last position in tokenOfOwner array, replace it with the
                    // tokenId which is in the last position
                    uint256 lastTokenIdOfFrom = collectionStorage.getTokenOfOwnerByIndex(
                        from,
                        fromBalance - 1
                    );
                    collectionStorage.setTokenOfOwnerByIndex(from, i, lastTokenIdOfFrom);
                }
                // Pop last tokenId from tokenOfOwner array
                collectionStorage.popTokenOfOwner(from);
                break;
            }
        }
        collectionStorage.pushTokenOfOwner(to, tokenId);
        collectionStorage.setOwner(tokenId, to);
        // Emit Transfer event
        ICollectionProxy_ManagerFunctions(collectionProxy).emitTransfer(from, to, tokenId);
    }

    function _safeTransferFrom(
        ICollectionStorage collectionStorage,
        address collectionProxy,
        address owner,
        address spender,
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private {
        _transfer(collectionStorage, collectionProxy, owner, from, to, tokenId);
        require(
            _checkOnERC721Received(spender, from, to, tokenId, _data),
            'ERC721Manager: transfer to non ERC721Receiver implementer'
        );
    }

    function _approve(
        ICollectionStorage collectionStorage,
        address collectionProxy,
        address owner,
        address spender,
        uint256 tokenId
    ) private {
        // Set new approval value for spender
        collectionStorage.setTokenApproval(tokenId, spender);
        // Emit Approval event
        ICollectionProxy_ManagerFunctions(collectionProxy).emitApproval(owner, spender, tokenId);
    }

    function _setApprovalForAll(
        address collectionProxy,
        address owner,
        address operator,
        bool approved
    ) private {
        require(owner != operator, 'ERC721Manager: approve to caller');
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        // Set new approval value for operator
        collectionStorage.setOperatorApproval(owner, operator, approved);
        // Emit Approval event
        ICollectionProxy_ManagerFunctions(collectionProxy).emitApprovalForAll(
            owner,
            operator,
            approved
        );
    }

    function _burn(
        ICollectionStorage collectionStorage,
        address collectionProxy,
        address owner,
        uint256 tokenId
    ) private {
        // Clear approvals
        _approve(collectionStorage, collectionProxy, owner, address(0), tokenId);
        // Update totalSupply
        collectionStorage.setTotalSupply(collectionStorage.getTotalSupply() - 1);
        // Update tokenIds array (set value to 0 at tokenId index to signal that token was burned)
        collectionStorage.setTokenIdByIndex(0, tokenId - 1);
        // Update tokenId ownership
        uint256 ownerBalance = collectionStorage.getBalance(owner);
        for (uint256 i = 0; i < ownerBalance; i++) {
            if (collectionStorage.getTokenOfOwnerByIndex(owner, i) == tokenId) {
                if (i < ownerBalance - 1) {
                    // If burned tokenId is not in the last position in tokenOfOwner array, replace it with the tokenId
                    // which is in the last position
                    uint256 lastTokenIdOfOwner = collectionStorage.getTokenOfOwnerByIndex(
                        owner,
                        ownerBalance - 1
                    );
                    collectionStorage.setTokenOfOwnerByIndex(owner, i, lastTokenIdOfOwner);
                }
                // Pop last tokenId from tokenOfOwner array
                collectionStorage.popTokenOfOwner(owner);
                break;
            }
        }
        collectionStorage.setOwner(tokenId, address(0));
        // Emit Transfer event
        ICollectionProxy_ManagerFunctions(collectionProxy).emitTransfer(owner, address(0), tokenId);
    }

    function _checkOnERC721Received(
        address msgSender,
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(msgSender, from, tokenId, _data) returns (
                bytes4 retval
            ) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert('ERC721Manager: transfer to non ERC721Receiver implementer');
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Owner-restricted setter functions
     */
    function setSporkProxy(address payable sporkProxy) external onlyOwner {
        IERC721ManagerProxy(proxy).setSporkProxy(sporkProxy);
    }

    function setFarmingManagerProxy(address _farmingManagerProxy) external onlyOwner {
        farmingManagerProxy = _farmingManagerProxy;
    }

    function setBaseURI(address collectionProxy, string calldata uri) external onlyOwner {
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        collectionStorage.setBaseURI(uri);
    }

    function setName(address collectionProxy, string calldata newName) external onlyOwner {
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        collectionStorage.setName(newName);
    }

    function setSymbol(address collectionProxy, string calldata newSymbol) external onlyOwner {
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        collectionStorage.setSymbol(newSymbol);
    }

    function setWhitelisted(
        address collectionProxy,
        address[] calldata users,
        bool[] calldata whitelisted
    ) external onlyOwner {
        require(
            users.length == whitelisted.length,
            'ERC721Manager: _users and _whitelisted arrays must have the same length'
        );
        for (uint256 i = 0; i < users.length; i++) {
            _storage.setWhitelisted(collectionProxy, users[i], whitelisted[i]);
        }
    }

    function setMAX_WHITELIST_MINT_PER_ADDRESS(
        address collectionProxy,
        uint256 value
    ) external onlyOwner {
        _storage.setMAX_WHITELIST_MINT_PER_ADDRESS(collectionProxy, value);
    }

    function setMAX_PUBLIC_MINT_PER_ADDRESS(
        address collectionProxy,
        uint256 value
    ) external onlyOwner {
        _storage.setMAX_PUBLIC_MINT_PER_ADDRESS(collectionProxy, value);
    }

    function setMAX_SUPPLY(address collectionProxy, uint256 value) external onlyOwner {
        _storage.setMAX_SUPPLY(collectionProxy, value);
    }

    function setWhitelistPhase(
        address collectionProxy,
        uint256 blockStartWhitelistPhase,
        uint256 blockEndWhitelistPhase
    ) external onlyOwner {
        _storage.setWhitelistPhase(
            collectionProxy,
            blockStartWhitelistPhase,
            blockEndWhitelistPhase
        );
    }

    function setPublicPhase(
        address collectionProxy,
        uint256 blockStartPublicPhase,
        uint256 blockEndPublicPhase
    ) external onlyOwner {
        _storage.setPublicPhase(collectionProxy, blockStartPublicPhase, blockEndPublicPhase);
    }

    function setCollectionMoved(address collectionProxy, bool collectionMoved) external onlyOwner {
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        collectionStorage.setCollectionMoved(collectionMoved);
    }

    function setMovementNoticeURI(
        address collectionProxy,
        string calldata movementNoticeURI
    ) external onlyOwner {
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        collectionStorage.setMovementNoticeURI(movementNoticeURI);
    }

    function setMintFeeRecipient(address mintFeeRecipient) external onlyOwner {
        _storage.setMintFeeRecipient(mintFeeRecipient);
    }

    function setFeeDenominator(uint96 value) external onlyOwner {
        _storage.setFeeDenominator(value);
    }

    function setRoyalty(
        address collectionProxy,
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        require(
            feeNumerator <= _storage.getFeeDenominator(),
            'ERC721Manager: royalty fee will exceed salePrice'
        );
        collectionStorage.setRoyaltyInfo(receiver, feeNumerator);
    }

    function setMintFeeERC20AssetProxy(
        address collectionProxy,
        address mintFeeERC20AssetProxy
    ) external onlyOwner {
        _storage.setMintFeeERC20AssetProxy(collectionProxy, mintFeeERC20AssetProxy);
    }

    function setMintFeeERC20(address collectionProxy, uint256 mintFeeERC20) external onlyOwner {
        _storage.setMintFeeERC20(collectionProxy, mintFeeERC20);
    }

    function setBaseMintFeeETH(address collectionProxy, uint256 baseMintFeeETH) external onlyOwner {
        _storage.setBaseMintFeeETH(collectionProxy, baseMintFeeETH);
    }

    function setETHMintFeeGrowthRateBps(
        address collectionProxy,
        uint256 ethMintFeeGrowthRateBps
    ) external onlyOwner {
        _storage.setETHMintFeeGrowthRateBps(collectionProxy, ethMintFeeGrowthRateBps);
    }

    function setETHMintFeeIncreaseInterval(
        address collectionProxy,
        uint256 ethMintFeeIncreaseInterval
    ) external onlyOwner {
        _storage.setETHMintFeeIncreaseInterval(collectionProxy, ethMintFeeIncreaseInterval);
    }

    function setOperatorFilterRegistry(
        IOperatorFilterRegistry _operatorFilterRegistry
    ) external onlyOwner {
        operatorFilterRegistry = _operatorFilterRegistry;
    }

    function setETHMintsCountThreshold(
        address collectionProxy,
        uint256 ethMintsCountThreshold
    ) external onlyOwner {
        _storage.setETHMintsCountThreshold(collectionProxy, ethMintsCountThreshold);
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

interface IERC721ManagerUpgrade {
    function _storage() external view returns (address);
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = '0123456789abcdef';

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return '0';
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0x00';
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = '0';
        buffer[1] = 'x';
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, 'Strings: hex length insufficient');
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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
        require(address(this).balance >= amount, 'Address: insufficient balance');

        (bool success, ) = recipient.call{ value: amount }('');
        require(success, 'Address: unable to send value, recipient may have reverted');
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
        return functionCall(target, data, 'Address: low-level call failed');
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
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
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        require(isContract(target), 'Address: call to non-contract');

        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data
    ) internal view returns (bytes memory) {
        return functionStaticCall(target, data, 'Address: low-level static call failed');
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
        require(isContract(target), 'Address: static call to non-contract');

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return functionDelegateCall(target, data, 'Address: low-level delegate call failed');
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
        require(isContract(target), 'Address: delegate call to non-contract');

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

import { IProposal } from './IProposal.sol';
import { IGovernedContract } from './IGovernedContract.sol';

/**
 * Interface of UpgradeProposal
 */
interface IUpgradeProposal is IProposal {
    function implementation() external view returns (IGovernedContract);
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

interface IStorageBase {
    function setOwner(address _newOwner) external;

    function setOwnerHelper(address _newOwnerHelper) external;
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

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

pragma solidity 0.8.0;

interface IOperatorFilterRegistry {
    /**
     * @notice Returns true if operator is not filtered for a given token, either by address or codeHash. Also returns
     *         true if supplied registrant address is not registered.
     */
    function isOperatorAllowed(address registrant, address operator) external view returns (bool);

    /**
     * @notice Registers an address with the registry. May be called by address itself or by EIP-173 owner.
     */
    function register(address registrant) external;

    /**
     * @notice Registers an address with the registry and "subscribes" to another address's filtered operators and codeHashes.
     */
    function registerAndSubscribe(address registrant, address subscription) external;

    /**
     * @notice Registers an address with the registry and copies the filtered operators and codeHashes from another
     *         address without subscribing.
     */
    function registerAndCopyEntries(address registrant, address registrantToCopy) external;

    /**
     * @notice Unregisters an address with the registry and removes its subscription. May be called by address itself or by EIP-173 owner.
     *         Note that this does not remove any filtered addresses or codeHashes.
     *         Also note that any subscriptions to this registrant will still be active and follow the existing filtered addresses and codehashes.
     */
    function unregister(address addr) external;

    /**
     * @notice Update an operator address for a registered address - when filtered is true, the operator is filtered.
     */
    function updateOperator(address registrant, address operator, bool filtered) external;

    /**
     * @notice Update multiple operators for a registered address - when filtered is true, the operators will be filtered. Reverts on duplicates.
     */
    function updateOperators(
        address registrant,
        address[] calldata operators,
        bool filtered
    ) external;

    /**
     * @notice Update a codeHash for a registered address - when filtered is true, the codeHash is filtered.
     */
    function updateCodeHash(address registrant, bytes32 codehash, bool filtered) external;

    /**
     * @notice Update multiple codeHashes for a registered address - when filtered is true, the codeHashes will be filtered. Reverts on duplicates.
     */
    function updateCodeHashes(
        address registrant,
        bytes32[] calldata codeHashes,
        bool filtered
    ) external;

    /**
     * @notice Subscribe an address to another registrant's filtered operators and codeHashes. Will remove previous
     *         subscription if present.
     *         Note that accounts with subscriptions may go on to subscribe to other accounts - in this case,
     *         subscriptions will not be forwarded. Instead the former subscription's existing entries will still be
     *         used.
     */
    function subscribe(address registrant, address registrantToSubscribe) external;

    /**
     * @notice Unsubscribe an address from its current subscribed registrant, and optionally copy its filtered operators and codeHashes.
     */
    function unsubscribe(address registrant, bool copyExistingEntries) external;

    /**
     * @notice Get the subscription address of a given registrant, if any.
     */
    function subscriptionOf(address addr) external returns (address registrant);

    /**
     * @notice Get the set of addresses subscribed to a given registrant.
     *         Note that order is not guaranteed as updates are made.
     */
    function subscribers(address registrant) external returns (address[] memory);

    /**
     * @notice Get the subscriber at a given index in the set of addresses subscribed to a given registrant.
     *         Note that order is not guaranteed as updates are made.
     */
    function subscriberAt(address registrant, uint256 index) external returns (address);

    /**
     * @notice Copy filtered operators and codeHashes from a different registrantToCopy to addr.
     */
    function copyEntriesOf(address registrant, address registrantToCopy) external;

    /**
     * @notice Returns true if operator is filtered by a given address or its subscription.
     */
    function isOperatorFiltered(address registrant, address operator) external returns (bool);

    /**
     * @notice Returns true if the hash of an address's code is filtered by a given address or its subscription.
     */
    function isCodeHashOfFiltered(
        address registrant,
        address operatorWithCode
    ) external returns (bool);

    /**
     * @notice Returns true if a codeHash is filtered by a given address or its subscription.
     */
    function isCodeHashFiltered(address registrant, bytes32 codeHash) external returns (bool);

    /**
     * @notice Returns a list of filtered operators for a given address or its subscription.
     */
    function filteredOperators(address addr) external returns (address[] memory);

    /**
     * @notice Returns the set of filtered codeHashes for a given address or its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredCodeHashes(address addr) external returns (bytes32[] memory);

    /**
     * @notice Returns the filtered operator at the given index of the set of filtered operators for a given address or
     *         its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredOperatorAt(address registrant, uint256 index) external returns (address);

    /**
     * @notice Returns the filtered codeHash at the given index of the list of filtered codeHashes for a given address or
     *         its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredCodeHashAt(address registrant, uint256 index) external returns (bytes32);

    /**
     * @notice Returns true if an address has registered
     */
    function isRegistered(address addr) external returns (bool);

    /**
     * @dev Convenience method to compute the code hash of an arbitrary contract
     */
    function codeHashOf(address addr) external returns (bytes32);
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

import { IGovernedContract } from './IGovernedContract.sol';
import { IUpgradeProposal } from './IUpgradeProposal.sol';

interface IGovernedProxy {
    event UpgradeProposal(IGovernedContract indexed implementation, IUpgradeProposal proposal);

    event Upgraded(IGovernedContract indexed implementation, IUpgradeProposal proposal);

    function spork_proxy() external view returns (address);

    function impl() external returns (address);

    function implementation() external view returns (IGovernedContract);

    function initialize(address _implementation) external;

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

    fallback() external;

    receive() external payable;
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

interface IGovernedContract {
    // Return actual proxy address for secure validation
    function proxy() external view returns (address);
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

interface IFarmingManager {
    function isStaked(address erc721TokenAddress, uint256 tokenId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

/**
 * @dev ERC721 token receiver interface for any contract that wants to support safeTransfers from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

import './IERC165.sol';

/**
 * @dev Required interface of an ERC721Metadata compliant contract.
 */
interface IERC721Metadata is IERC165 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function baseURI() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

interface IERC721ManagerProxy {
    function setSporkProxy(address payable _sporkProxy) external;
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

import './IERC165.sol';

/**
 * @dev Required interface of an ERC721Enumerable compliant contract.
 */
interface IERC721Enumerable is IERC165 {
    function totalSupply() external view returns (uint256);

    function tokenByIndex(uint256 index) external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

import { IERC165 } from './IERC165.sol';
import { IERC721Enumerable } from './IERC721Enumerable.sol';

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165, IERC721Enumerable {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address user) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata _data
    ) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

import './IERC165.sol';

/**
 * @dev Required interface of an ERC2981 compliant contract.
 */
interface IERC2981 is IERC165 {
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address, uint256);
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

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

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

interface ICollectionStorage {
    // Getter functions
    //
    function getName() external view returns (string memory);

    function getSymbol() external view returns (string memory);

    function getBaseURI() external view returns (string memory);

    function getCollectionMoved() external view returns (bool);

    function getMovementNoticeURI() external view returns (string memory);

    function getTotalSupply() external view returns (uint256);

    function getTokenIdsCount() external view returns (uint256);

    function getTokenIdByIndex(uint256 _index) external view returns (uint256);

    function getOwner(uint256 tokenId) external view returns (address);

    function getBalance(address _address) external view returns (uint256);

    function getTokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);

    function getTokenApproval(uint256 _tokenId) external view returns (address);

    function getOperatorApproval(address _owner, address _operator) external view returns (bool);

    function getRoyaltyReceiver() external view returns (address);

    function getRoyaltyFraction() external view returns (uint96);

    function getRoyaltyInfo() external view returns (address, uint96);

    function getCollectionManagerProxyAddress() external view returns (address);

    function getCollectionManagerHelperProxyAddress() external view returns (address);

    // Setter functions
    //
    function setName(string calldata _name) external;

    function setSymbol(string calldata _symbol) external;

    function setBaseURI(string calldata _baseURI) external;

    function setCollectionMoved(bool _collectionMoved) external;

    function setMovementNoticeURI(string calldata _movementNoticeURI) external;

    function setTotalSupply(uint256 _value) external;

    function setTokenIdByIndex(uint256 _tokenId, uint256 _index) external;

    function pushTokenId(uint256 _tokenId) external;

    function popTokenId() external;

    function setOwner(uint256 tokenId, address owner) external;

    function setTokenOfOwnerByIndex(address _owner, uint256 _index, uint256 _tokenId) external;

    function pushTokenOfOwner(address _owner, uint256 _tokenId) external;

    function popTokenOfOwner(address _owner) external;

    function setTokenApproval(uint256 _tokenId, address _address) external;

    function setOperatorApproval(address _owner, address _operator, bool _approved) external;

    function setRoyaltyInfo(address receiver, uint96 fraction) external;

    function setCollectionManagerProxyAddress(address _collectionManagerProxyAddress) external;

    function setCollectionManagerHelperProxyAddress(
        address _collectionManagerHelperProxyAddress
    ) external;
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

interface ICollectionProxy_ManagerFunctions {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    function emitTransfer(address from, address to, uint256 tokenId) external;

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    function emitApproval(address owner, address approved, uint256 tokenId) external;

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    function emitApprovalForAll(address owner, address operator, bool approved) external;
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

import { GovernedContract } from '../GovernedContract.sol';
import { IGovernedProxy } from '../interfaces/IGovernedProxy.sol';

/**
 * ERC721ManagerAutoProxy is a version of GovernedContract which initializes its own proxy.
 * This is useful to avoid a circular dependency between GovernedContract and GovernedProxy
 * wherein they need each other's address in the constructor.
 */

contract ERC721ManagerAutoProxy is GovernedContract {
    constructor(address _proxy, address _implementation) GovernedContract(_proxy) {
        proxy = _proxy;
        IGovernedProxy(payable(proxy)).initialize(_implementation);
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

import { StorageBaseExtension } from '../StorageBaseExtension.sol';
import { ERC721ManagerAutoProxy } from './ERC721ManagerAutoProxy.sol';
import { ERC165 } from './ERC165.sol';
import { Pausable } from '../Pausable.sol';

import { ICollectionStorage } from '../interfaces/ICollectionStorage.sol';
import { ICollectionProxy_ManagerFunctions } from '../interfaces/ICollectionProxy_ManagerFunctions.sol';
import { IERC721ManagerProxy } from '../interfaces/IERC721ManagerProxy.sol';
import { IERC721 } from '../interfaces/IERC721.sol';
import { IERC721Enumerable } from '../interfaces/IERC721Enumerable.sol';
import { IERC721Metadata } from '../interfaces/IERC721Metadata.sol';
import { IERC2981 } from '../interfaces/IERC2981.sol';
import { IERC721Receiver } from '../interfaces/IERC721Receiver.sol';
import { IGovernedProxy } from '../interfaces/IGovernedProxy.sol';
import { IOperatorFilterRegistry } from '../interfaces/IOperatorFilterRegistry.sol';
import { IFarmingManager } from '../interfaces/IFarmingManager.sol';

import { Address } from '../libraries/Address.sol';
import { Strings } from '../libraries/Strings.sol';

contract ERC721ManagerStorage is StorageBaseExtension {
    // List of all deployed collections' proxies
    address[] private allCollectionProxies;

    // Mapping of collectionProxy address to collectionStorage address
    mapping(address => ICollectionStorage) private collectionStorage;

    // Mapping of collectionProxy address to maximum supply of NFTs in this collection
    mapping(address => uint256) private MAX_SUPPLY;

    // Mapping of collectionProxy address to maximum number of NFTs that can be minted per address during the whitelist mint phase
    mapping(address => uint256) private MAX_WHITELIST_MINT_PER_ADDRESS;

    // Mapping of collectionProxy address to maximum number of NFTs that can be minted per address during the public mint phase
    mapping(address => uint256) private MAX_PUBLIC_MINT_PER_ADDRESS;

    // Mapping of collectionProxy address to block from which the whitelist mint phase is enabled
    mapping(address => uint256) private blockStartWhitelistPhase;

    // Mapping of collectionProxy address to block after which the whitelist mint phase is disabled
    mapping(address => uint256) private blockEndWhitelistPhase;

    // Mapping of collectionProxy address to block from which the public mint phase is enabled
    mapping(address => uint256) private blockStartPublicPhase;

    // Mapping of collectionProxy address to block after which the public mint phase is disabled
    mapping(address => uint256) private blockEndPublicPhase;

    // Mapping of collectionProxy address to mapping of whitelisted user addresses to whitelist status
    mapping(address => mapping(address => bool)) private whitelisted;

    // Mapping of collectionProxy address to mapping of whitelisted user addresses to whitelist index
    // whitelistIndex is the position of the user address in the whitelist array
    mapping(address => mapping(address => uint256)) private whitelistIndex;

    // Mapping of collectionProxy address to array of whitelisted user addresses
    mapping(address => address[]) private whitelist;

    // Mapping of collectionProxy address to mapping of minter address to minted token count during whitelist phase
    mapping(address => mapping(address => uint256)) private whitelistMintCount;

    // Mapping of collectionProxy address to mapping of minter address to minted token count during public phase
    mapping(address => mapping(address => uint256)) private publicMintCount;

    // Mapping of collectionProxy address to address of ERC20 asset allowed for mint fee payments
    mapping(address => address) private mintFeeERC20AssetProxy;

    // Mapping of collectionProxy address to ERC20 asset mint fee (in wei)
    mapping(address => uint256) private mintFeeERC20;

    // Mapping of collectionProxy address to ETH base mint fee (in wei)
    mapping(address => uint256) private baseMintFeeETH;

    // Mapping of collectionProxy address to ETH mint fee increase interval (in wei)
    mapping(address => uint256) private ethMintFeeIncreaseInterval;

    // Mapping of collectionProxy address to ETH mint fee growth rate (bps)
    mapping(address => uint256) private ethMintFeeGrowthRateBps;

    // Mapping of collectionProxy address to ETH mints count threshold (number of ETH mints above which ETH mint fee
    // increases by ethMintFeeGrowthRateBps bps per ETH mint)
    mapping(address => uint256) private ethMintsCountThreshold;

    // Mapping of collectionProxy address to number of tokens minted with ETH mint fee
    mapping(address => uint256) private ethMintsCount;

    // Mapping of collectionProxy address to lastETHMintFeeAboveThreshold
    // We store the last ETH mint fee applied above ethMintsCountThreshold to avoid calculating ETH mint fee from scratch
    // at every mint above ethMintsCountThreshold
    mapping(address => uint256) private lastETHMintFeeAboveThreshold;

    // recipient address for mint fee payments
    address private mintFeeRecipient;

    // Denominator for ETH mint fee and royalties calculations
    uint96 private feeDenominator = 10000;

    constructor(
        address _helperProxy,
        address _mintFeeRecipient
    ) StorageBaseExtension(address(IGovernedProxy(payable(_helperProxy)).impl())) {
        mintFeeRecipient = _mintFeeRecipient;
    }

    // Getter functions
    //
    function getCollectionStorage(
        address collectionProxy
    ) external view returns (ICollectionStorage _collectionStorage) {
        _collectionStorage = collectionStorage[collectionProxy];
    }

    function getCollectionProxy(uint256 index) external view returns (address _collectionProxy) {
        _collectionProxy = allCollectionProxies[index];
    }

    function getCollectionsCount() external view returns (uint256 _length) {
        _length = allCollectionProxies.length;
    }

    function getMAX_SUPPLY(address collectionProxy) external view returns (uint256 _MAX_SUPPLY) {
        _MAX_SUPPLY = MAX_SUPPLY[collectionProxy];
    }

    function getMAX_WHITELIST_MINT_PER_ADDRESS(
        address collectionProxy
    ) external view returns (uint256 _MAX_WHITELIST_MINT_PER_ADDRESS) {
        _MAX_WHITELIST_MINT_PER_ADDRESS = MAX_WHITELIST_MINT_PER_ADDRESS[collectionProxy];
    }

    function getMAX_PUBLIC_MINT_PER_ADDRESS(
        address collectionProxy
    ) external view returns (uint256 _MAX_PUBLIC_MINT_PER_ADDRESS) {
        _MAX_PUBLIC_MINT_PER_ADDRESS = MAX_PUBLIC_MINT_PER_ADDRESS[collectionProxy];
    }

    function getBlockStartWhitelistPhase(
        address collectionProxy
    ) external view returns (uint256 _blockStartWhitelistPhase) {
        _blockStartWhitelistPhase = blockStartWhitelistPhase[collectionProxy];
    }

    function getBlockEndWhitelistPhase(
        address collectionProxy
    ) external view returns (uint256 _blockEndWhitelistPhase) {
        _blockEndWhitelistPhase = blockEndWhitelistPhase[collectionProxy];
    }

    function getBlockStartPublicPhase(
        address collectionProxy
    ) external view returns (uint256 _blockStartPublicPhase) {
        _blockStartPublicPhase = blockStartPublicPhase[collectionProxy];
    }

    function getBlockEndPublicPhase(
        address collectionProxy
    ) external view returns (uint256 _blockEndPublicPhase) {
        _blockEndPublicPhase = blockEndPublicPhase[collectionProxy];
    }

    function isWhitelisted(
        address collectionProxy,
        address _user
    ) external view returns (bool _isWhitelisted) {
        _isWhitelisted = whitelisted[collectionProxy][_user];
    }

    function getWhitelistIndex(
        address collectionProxy,
        address _user
    ) external view returns (uint256 _index) {
        _index = whitelistIndex[collectionProxy][_user];
    }

    function getWhitelistedUsersCount(
        address collectionProxy
    ) external view returns (uint256 _whitelistedUsersCount) {
        // address(0) is the first element of whitelist array
        _whitelistedUsersCount = whitelist[collectionProxy].length - 1;
    }

    function getWhitelistedUserByIndex(
        address collectionProxy,
        uint256 _index
    ) external view returns (address _whitelistedUser) {
        _whitelistedUser = whitelist[collectionProxy][_index];
    }

    function getWhitelistMintCount(
        address collectionProxy,
        address _address
    ) external view returns (uint256 _amount) {
        _amount = whitelistMintCount[collectionProxy][_address];
    }

    function getPublicMintCount(
        address collectionProxy,
        address _address
    ) external view returns (uint256 _amount) {
        _amount = publicMintCount[collectionProxy][_address];
    }

    function getMintFeeERC20AssetProxy(
        address collectionProxy
    ) external view returns (address _mintFeeERC20AssetProxy) {
        _mintFeeERC20AssetProxy = mintFeeERC20AssetProxy[collectionProxy];
    }

    function getMintFeeERC20(
        address collectionProxy
    ) external view returns (uint256 _mintFeeERC20) {
        _mintFeeERC20 = mintFeeERC20[collectionProxy];
    }

    function getBaseMintFeeETH(
        address collectionProxy
    ) external view returns (uint256 _baseMintFeeETH) {
        _baseMintFeeETH = baseMintFeeETH[collectionProxy];
    }

    function getETHMintFeeIncreaseInterval(
        address collectionProxy
    ) external view returns (uint256 _ethMintFeeIncreaseInterval) {
        _ethMintFeeIncreaseInterval = ethMintFeeIncreaseInterval[collectionProxy];
    }

    function getETHMintFeeGrowthRateBps(
        address collectionProxy
    ) external view returns (uint256 _ethMintFeeGrowthRateBps) {
        _ethMintFeeGrowthRateBps = ethMintFeeGrowthRateBps[collectionProxy];
    }

    function getETHMintsCountThreshold(
        address collectionProxy
    ) external view returns (uint256 _ethMintsCountThreshold) {
        _ethMintsCountThreshold = ethMintsCountThreshold[collectionProxy];
    }

    function getETHMintsCount(
        address collectionProxy
    ) external view returns (uint256 _ethMintsCount) {
        _ethMintsCount = ethMintsCount[collectionProxy];
    }

    function getLastETHMintFeeAboveThreshold(
        address collectionProxy
    ) external view returns (uint256 _lastETHMintFeeAboveThreshold) {
        _lastETHMintFeeAboveThreshold = lastETHMintFeeAboveThreshold[collectionProxy];
    }

    function getMintFeeRecipient() external view returns (address _mintFeeRecipient) {
        _mintFeeRecipient = mintFeeRecipient;
    }

    function getFeeDenominator() external view returns (uint96 _feeDenominator) {
        _feeDenominator = feeDenominator;
    }

    // Setter functions
    //
    function setCollectionStorage(
        address collectionProxy,
        address _collectionStorage
    ) external requireOwner {
        collectionStorage[collectionProxy] = ICollectionStorage(_collectionStorage);
    }

    function pushCollectionProxy(address collectionProxy) external requireOwner {
        allCollectionProxies.push(collectionProxy);
    }

    function popCollectionProxy() external requireOwner {
        allCollectionProxies.pop();
    }

    function setCollectionProxy(uint256 index, address collectionProxy) external requireOwner {
        allCollectionProxies[index] = collectionProxy;
    }

    function setMAX_SUPPLY(address collectionProxy, uint256 _value) external requireOwner {
        MAX_SUPPLY[collectionProxy] = _value;
    }

    function setMAX_WHITELIST_MINT_PER_ADDRESS(
        address collectionProxy,
        uint256 _value
    ) external requireOwner {
        MAX_WHITELIST_MINT_PER_ADDRESS[collectionProxy] = _value;
    }

    function setMAX_PUBLIC_MINT_PER_ADDRESS(
        address collectionProxy,
        uint256 _value
    ) external requireOwner {
        MAX_PUBLIC_MINT_PER_ADDRESS[collectionProxy] = _value;
    }

    function setWhitelistPhase(
        address collectionProxy,
        uint256 _blockStartWhitelistPhase,
        uint256 _blockEndWhitelistPhase
    ) external requireOwner {
        blockStartWhitelistPhase[collectionProxy] = _blockStartWhitelistPhase;
        blockEndWhitelistPhase[collectionProxy] = _blockEndWhitelistPhase;
    }

    function setPublicPhase(
        address collectionProxy,
        uint256 _blockStartPublicPhase,
        uint256 _blockEndPublicPhase
    ) external requireOwner {
        blockStartPublicPhase[collectionProxy] = _blockStartPublicPhase;
        blockEndPublicPhase[collectionProxy] = _blockEndPublicPhase;
    }

    function setWhitelisted(
        address collectionProxy,
        address _user,
        bool _isWhitelisted
    ) external requireOwner {
        // Initialize whitelist if needed
        if (whitelist[collectionProxy].length == 0) {
            // We push address(0) as the first element of whitelist in order to only have whitelistIndex > 0 for
            // whitelisted users, and we use the 0 value in whitelistIndex to identify users who were removed from the
            // whitelist, or were never added (as whitelistIndex mapping values default to 0)
            whitelist[collectionProxy].push(address(0));
        }
        // Set whitelisted status for user
        whitelisted[collectionProxy][_user] = _isWhitelisted;
        // Get whitelist index of user
        uint256 userWhitelistIndex = whitelistIndex[collectionProxy][_user];
        if (_isWhitelisted) {
            // Add user to whitelist
            if (userWhitelistIndex == 0) {
                // Is user is not already in whitelist, push user to whitelist array and register new whitelistIndex
                whitelist[collectionProxy].push(_user);
                whitelistIndex[collectionProxy][_user] = whitelist[collectionProxy].length - 1;
            }
        } else {
            // Remove user from whitelist
            if (userWhitelistIndex > 0) {
                if (userWhitelistIndex < whitelist[collectionProxy].length - 1) {
                    // If user is not in the last position in whitelist array, replace it with the address
                    // which is in the last position
                    // Get the user which is at the last index of whitelist array
                    address lastWhitelistedUser = whitelist[collectionProxy][
                        whitelist[collectionProxy].length - 1
                    ];
                    // Replace user with the user which is at the last index of whitelist array
                    whitelist[collectionProxy][userWhitelistIndex] = lastWhitelistedUser;
                    // Update whitelistIndex for the lastWhitelistedUser address which was moved from the last position
                    // to a new position in whitelist array
                    whitelistIndex[collectionProxy][lastWhitelistedUser] = userWhitelistIndex;
                }
                // Pop the last element of whitelist array
                whitelist[collectionProxy].pop();
                // Set whitelistIndex to 0 for user
                whitelistIndex[collectionProxy][_user] = 0;
            }
        }
    }

    function setWhitelistMintCount(
        address collectionProxy,
        address _address,
        uint256 _amount
    ) external requireOwner {
        whitelistMintCount[collectionProxy][_address] = _amount;
    }

    function setPublicMintCount(
        address collectionProxy,
        address _address,
        uint256 _amount
    ) external requireOwner {
        publicMintCount[collectionProxy][_address] = _amount;
    }

    function setMintFeeERC20AssetProxy(
        address collectionProxy,
        address _mintFeeERC20AssetProxy
    ) external requireOwner {
        mintFeeERC20AssetProxy[collectionProxy] = _mintFeeERC20AssetProxy;
    }

    function setMintFeeERC20(address collectionProxy, uint256 _mintFeeERC20) external requireOwner {
        mintFeeERC20[collectionProxy] = _mintFeeERC20;
    }

    function setMintFeeETH(
        address collectionProxy,
        uint256[4] memory _mintFeeETH
    ) external requireOwner {
        baseMintFeeETH[collectionProxy] = _mintFeeETH[0];
        ethMintFeeIncreaseInterval[collectionProxy] = _mintFeeETH[1];
        ethMintsCountThreshold[collectionProxy] = _mintFeeETH[2];
        ethMintFeeGrowthRateBps[collectionProxy] = _mintFeeETH[3];
        lastETHMintFeeAboveThreshold[collectionProxy] = _mintFeeETH[0] * _mintFeeETH[2]; // Initialize lastETHMintFeeAboveThreshold
    }

    function setBaseMintFeeETH(
        address collectionProxy,
        uint256 _baseMintFeeETH
    ) external requireOwner {
        baseMintFeeETH[collectionProxy] = _baseMintFeeETH;
    }

    function setETHMintFeeIncreaseInterval(
        address collectionProxy,
        uint256 _ethMintFeeIncreaseInterval
    ) external requireOwner {
        ethMintFeeIncreaseInterval[collectionProxy] = _ethMintFeeIncreaseInterval;
    }

    function setETHMintFeeGrowthRateBps(
        address collectionProxy,
        uint256 _ethMintFeeGrowthRateBps
    ) external requireOwner {
        ethMintFeeGrowthRateBps[collectionProxy] = _ethMintFeeGrowthRateBps;
    }

    function setETHMintsCountThreshold(
        address collectionProxy,
        uint256 _ethMintsCountThreshold
    ) external requireOwner {
        ethMintsCountThreshold[collectionProxy] = _ethMintsCountThreshold;
    }

    function setETHMintsCount(
        address collectionProxy,
        uint256 _ethMintsCount
    ) external requireOwner {
        ethMintsCount[collectionProxy] = _ethMintsCount;
    }

    function setLastETHMintFeeAboveThreshold(
        address collectionProxy,
        uint256 _lastETHMintFeeAboveThreshold
    ) external requireOwner {
        lastETHMintFeeAboveThreshold[collectionProxy] = _lastETHMintFeeAboveThreshold;
    }

    function setMintFeeRecipient(address _mintFeeRecipient) external requireOwner {
        mintFeeRecipient = _mintFeeRecipient;
    }

    function setFeeDenominator(uint96 value) external requireOwner {
        feeDenominator = value;
    }
}

contract ERC721Manager is Pausable, ERC721ManagerAutoProxy, ERC165 {
    using Strings for uint256;
    using Address for address;

    address public helperProxy;
    address public factoryProxy;
    address public farmingManagerProxy;

    IOperatorFilterRegistry public operatorFilterRegistry;

    ERC721ManagerStorage public _storage;

    constructor(
        address _proxy,
        address _helperProxy,
        address _factoryProxy,
        address _mintFeeRecipient,
        address _operatorFilterRegistry
    ) ERC721ManagerAutoProxy(_proxy, address(this)) {
        _storage = new ERC721ManagerStorage(_helperProxy, _mintFeeRecipient);
        helperProxy = _helperProxy;
        factoryProxy = _factoryProxy;

        operatorFilterRegistry = IOperatorFilterRegistry(_operatorFilterRegistry);
    }

    modifier requireCollectionProxy() {
        require(
            address(_storage.getCollectionStorage(msg.sender)) != address(0),
            'ERC721Manager: FORBIDDEN, not a Collection proxy'
        );
        _;
    }

    // Modifier for self-custodial farming
    modifier requireNotStaked(address collectionProxy, uint256 tokenId) {
        // When token is staked, transferring or burning token is not allowed
        if (farmingManagerProxy != address(0)) {
            require(
                !IFarmingManager(IGovernedProxy(payable(farmingManagerProxy)).impl()).isStaked(
                    collectionProxy,
                    tokenId
                ),
                'ERC721Manager: cannot transfer or burn staked tokens'
            );
        }
        _;
    }

    /**
     * @dev A helper function to check if an operator is allowed.
     */
    modifier onlyAllowedOperator(address from, address msgSender) {
        // Allow spending tokens from addresses with balance
        // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
        // from an EOA.
        if (from != msgSender) {
            _checkFilterOperator(msgSender);
        }
        _;
    }

    /**
     * @dev A helper function to check if an operator approval is allowed.
     */
    modifier onlyAllowedOperatorApproval(address operator) {
        _checkFilterOperator(operator);
        _;
    }

    /**
     * @dev A helper function to check if an operator is allowed.
     */
    function _checkFilterOperator(address operator) private view {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(operatorFilterRegistry).code.length > 0) {
            // under normal circumstances, this function will revert rather than return false, but inheriting contracts
            // may specify their own OperatorFilterRegistry implementations, which may behave differently
            require(
                operatorFilterRegistry.isOperatorAllowed(address(this), operator),
                'ERC721Manager: operator not allowed'
            );
        }
    }

    /**
     * @dev Governance functions
     */
    // This function is called in order to upgrade to a new ERC721Manager implementation
    function destroy(address _newImpl) external requireProxy {
        StorageBaseExtension(address(_storage)).setOwner(address(_newImpl));
        // Self destruct
        _destroy(_newImpl);
    }

    // This function (placeholder) would be called on the new implementation if necessary for the upgrade
    function migrate(address _oldImpl) external requireProxy {
        _migrate(_oldImpl);
    }

    /**
     * @dev Factory restricted function
     */
    // This function is called by Factory implementation at a new collection creation
    // Register a new Collection's proxy address, and Collection's storage address
    function register(
        address _collectionProxy,
        address _collectionStorage,
        address _mintFeeERC20AssetProxy,
        uint256 _mintFeeERC20,
        uint256[4] calldata _mintFeeETH
    )
        external
        // _mintFeeETH = [baseMintFeeETH, ethMintFeeIncreaseInterval, ethMintsCountThreshold, ethMintFeeGrowthRateBps]
        whenNotPaused
    {
        require(
            msg.sender == address(IGovernedProxy(payable(factoryProxy)).impl()),
            'ERC721Manager: Not factory implementation!'
        );
        _storage.setCollectionStorage(_collectionProxy, _collectionStorage);
        _storage.pushCollectionProxy(_collectionProxy);
        _storage.setMintFeeERC20AssetProxy(_collectionProxy, _mintFeeERC20AssetProxy);
        _storage.setMintFeeERC20(_collectionProxy, _mintFeeERC20);
        _storage.setMintFeeETH(_collectionProxy, _mintFeeETH);
    }

    /**
     * @dev ERC165
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId ||
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev ERC721
     */
    function balanceOf(address collectionProxy, address owner) external view returns (uint256) {
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        require(owner != address(0), 'ERC721Manager: balance query for the zero address');
        return collectionStorage.getBalance(owner);
    }

    function ownerOf(address collectionProxy, uint256 tokenId) external view returns (address) {
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        address owner = collectionStorage.getOwner(tokenId);
        require(owner != address(0), 'ERC721Manager: owner query for nonexistent token');
        return owner;
    }

    function safeTransferFrom(
        address collectionProxy,
        address spender,
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    )
        external
        requireCollectionProxy
        whenNotPaused
        requireNotStaked(collectionProxy, tokenId)
        onlyAllowedOperator(from, spender)
    {
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        address owner = collectionStorage.getOwner(tokenId);
        require(owner != address(0), 'ERC721Manager: nonexistent token');
        require(
            spender == owner ||
                collectionStorage.getTokenApproval(tokenId) == spender ||
                collectionStorage.getOperatorApproval(owner, spender),
            'ERC721Manager: transfer caller is not owner nor approved'
        );

        _safeTransferFrom(
            collectionStorage,
            collectionProxy,
            owner,
            spender,
            from,
            to,
            tokenId,
            _data
        );
    }

    function transferFrom(
        address collectionProxy,
        address spender,
        address from,
        address to,
        uint256 tokenId
    )
        external
        requireCollectionProxy
        whenNotPaused
        requireNotStaked(collectionProxy, tokenId)
        onlyAllowedOperator(from, spender)
    {
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        address owner = collectionStorage.getOwner(tokenId);
        require(owner != address(0), 'ERC721Manager: nonexistent token');
        require(
            spender == owner ||
                collectionStorage.getTokenApproval(tokenId) == spender ||
                collectionStorage.getOperatorApproval(owner, spender),
            'ERC721Manager: transfer caller is not owner nor approved'
        );

        _transfer(collectionStorage, collectionProxy, owner, from, to, tokenId);
    }

    function approve(
        address collectionProxy,
        address msgSender,
        address spender,
        uint256 tokenId
    ) external requireCollectionProxy whenNotPaused onlyAllowedOperatorApproval(spender) {
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        address owner = collectionStorage.getOwner(tokenId);
        require(owner != address(0), 'ERC721Manager: nonexistent token');
        require(spender != owner, 'ERC721Manager: approval to current owner');
        require(
            msgSender == owner || collectionStorage.getOperatorApproval(owner, msgSender),
            'ERC721Manager: approve caller is not owner nor approved for all'
        );

        _approve(collectionStorage, collectionProxy, owner, spender, tokenId);
    }

    function getApproved(address collectionProxy, uint256 tokenId) external view returns (address) {
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        require(
            _exists(collectionStorage, tokenId),
            'ERC721Manager: approved query for nonexistent token'
        );

        return collectionStorage.getTokenApproval(tokenId);
    }

    function setApprovalForAll(
        address collectionProxy,
        address owner,
        address operator,
        bool approved
    ) external requireCollectionProxy whenNotPaused onlyAllowedOperatorApproval(operator) {
        _setApprovalForAll(collectionProxy, owner, operator, approved);
    }

    function isApprovedForAll(
        address collectionProxy,
        address owner,
        address operator
    ) external view returns (bool) {
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        return collectionStorage.getOperatorApproval(owner, operator);
    }

    /**
     * @dev ERC721Metadata
     */
    function name(address collectionProxy) external view returns (string memory) {
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        return collectionStorage.getName();
    }

    function symbol(address collectionProxy) external view returns (string memory) {
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        return collectionStorage.getSymbol();
    }

    function baseURI(address collectionProxy) external view returns (string memory) {
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        if (collectionStorage.getCollectionMoved()) {
            return collectionStorage.getMovementNoticeURI();
        }

        string memory baseURI_local = collectionStorage.getBaseURI();
        return baseURI_local;
    }

    function tokenURI(
        address collectionProxy,
        uint256 tokenId
    ) external view returns (string memory) {
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        require(
            _exists(collectionStorage, tokenId),
            'ERC721Manager: URI query for nonexistent token'
        );

        if (collectionStorage.getCollectionMoved()) {
            return collectionStorage.getMovementNoticeURI();
        }

        string memory baseURI_local = collectionStorage.getBaseURI();
        return
            bytes(baseURI_local).length > 0
                ? string(abi.encodePacked(baseURI_local, tokenId.toString()))
                : '';
    }

    /**
     * @dev ERC721Enumerable
     */
    function totalSupply(address collectionProxy) external view returns (uint256) {
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        return collectionStorage.getTotalSupply();
    }

    function tokenByIndex(
        address collectionProxy,
        uint256 index
    ) external view returns (uint256 tokenId) {
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        require(
            index < collectionStorage.getTotalSupply(),
            'ERC721Manager: index must be less than total supply'
        );
        tokenId = collectionStorage.getTokenIdByIndex(index);
    }

    function tokenOfOwnerByIndex(
        address collectionProxy,
        address owner,
        uint256 index
    ) external view returns (uint256 tokenId) {
        require(
            owner != address(0),
            'ERC721Manager: tokenOfOwnerByIndex query for the zero address'
        );
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        require(
            collectionStorage.getBalance(owner) > index,
            'ERC721Manager: index must be less than address balance'
        );
        tokenId = collectionStorage.getTokenOfOwnerByIndex(owner, index);
    }

    /**
     * @dev ERC721Burnable
     */
    function burn(
        address collectionProxy,
        address burner,
        uint256 tokenId
    ) external requireCollectionProxy whenNotPaused requireNotStaked(collectionProxy, tokenId) {
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        address owner = collectionStorage.getOwner(tokenId);
        require(owner != address(0), 'ERC721Manager: nonexistent token');
        require(
            burner == owner ||
                collectionStorage.getTokenApproval(tokenId) == burner ||
                collectionStorage.getOperatorApproval(owner, burner),
            'ERC721Manager: burn caller is not owner nor approved'
        );

        _burn(collectionStorage, collectionProxy, owner, tokenId);
    }

    /**
     * @dev ERC2981
     */
    function royaltyInfo(
        address collectionProxy,
        uint256, // Royalties are identical for all tokenIds
        uint256 salePrice
    ) external view returns (address, uint256) {
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        address receiver = collectionStorage.getRoyaltyReceiver();
        uint256 royaltyAmount;
        if (receiver != address(0)) {
            uint96 fraction = collectionStorage.getRoyaltyFraction();
            royaltyAmount = (salePrice * fraction) / _storage.getFeeDenominator();
        } else {
            royaltyAmount = 0;
        }

        return (receiver, royaltyAmount);
    }

    /**
     * @dev Private ERC721 functions
     */
    function _exists(
        ICollectionStorage collectionStorage,
        uint256 tokenId
    ) private view returns (bool) {
        return collectionStorage.getOwner(tokenId) != address(0);
    }

    function _transfer(
        ICollectionStorage collectionStorage,
        address collectionProxy,
        address owner,
        address from,
        address to,
        uint256 tokenId
    ) private {
        require(to != address(0), 'ERC721Manager: transfer to the zero address');
        require(owner == from, 'ERC721Manager: transfer from incorrect owner');
        // Clear approvals from the previous owner
        _approve(collectionStorage, collectionProxy, owner, address(0), tokenId);
        // Update tokenId ownership
        uint256 fromBalance = collectionStorage.getBalance(from);
        for (uint256 i = 0; i < fromBalance; i++) {
            if (collectionStorage.getTokenOfOwnerByIndex(from, i) == tokenId) {
                if (i < fromBalance - 1) {
                    // If transferred tokenId is not in the last position in tokenOfOwner array, replace it with the
                    // tokenId which is in the last position
                    uint256 lastTokenIdOfFrom = collectionStorage.getTokenOfOwnerByIndex(
                        from,
                        fromBalance - 1
                    );
                    collectionStorage.setTokenOfOwnerByIndex(from, i, lastTokenIdOfFrom);
                }
                // Pop last tokenId from tokenOfOwner array
                collectionStorage.popTokenOfOwner(from);
                break;
            }
        }
        collectionStorage.pushTokenOfOwner(to, tokenId);
        collectionStorage.setOwner(tokenId, to);
        // Emit Transfer event
        ICollectionProxy_ManagerFunctions(collectionProxy).emitTransfer(from, to, tokenId);
    }

    function _safeTransferFrom(
        ICollectionStorage collectionStorage,
        address collectionProxy,
        address owner,
        address spender,
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private {
        _transfer(collectionStorage, collectionProxy, owner, from, to, tokenId);
        require(
            _checkOnERC721Received(spender, from, to, tokenId, _data),
            'ERC721Manager: transfer to non ERC721Receiver implementer'
        );
    }

    function _approve(
        ICollectionStorage collectionStorage,
        address collectionProxy,
        address owner,
        address spender,
        uint256 tokenId
    ) private {
        // Set new approval value for spender
        collectionStorage.setTokenApproval(tokenId, spender);
        // Emit Approval event
        ICollectionProxy_ManagerFunctions(collectionProxy).emitApproval(owner, spender, tokenId);
    }

    function _setApprovalForAll(
        address collectionProxy,
        address owner,
        address operator,
        bool approved
    ) private {
        require(owner != operator, 'ERC721Manager: approve to caller');
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        // Set new approval value for operator
        collectionStorage.setOperatorApproval(owner, operator, approved);
        // Emit Approval event
        ICollectionProxy_ManagerFunctions(collectionProxy).emitApprovalForAll(
            owner,
            operator,
            approved
        );
    }

    function _burn(
        ICollectionStorage collectionStorage,
        address collectionProxy,
        address owner,
        uint256 tokenId
    ) private {
        // Clear approvals
        _approve(collectionStorage, collectionProxy, owner, address(0), tokenId);
        // Update totalSupply
        collectionStorage.setTotalSupply(collectionStorage.getTotalSupply() - 1);
        // Update tokenIds array (set value to 0 at tokenId index to signal that token was burned)
        collectionStorage.setTokenIdByIndex(0, tokenId - 1);
        // Update tokenId ownership
        uint256 ownerBalance = collectionStorage.getBalance(owner);
        for (uint256 i = 0; i < ownerBalance; i++) {
            if (collectionStorage.getTokenOfOwnerByIndex(owner, i) == tokenId) {
                if (i < ownerBalance - 1) {
                    // If burned tokenId is not in the last position in tokenOfOwner array, replace it with the tokenId
                    // which is in the last position
                    uint256 lastTokenIdOfOwner = collectionStorage.getTokenOfOwnerByIndex(
                        owner,
                        ownerBalance - 1
                    );
                    collectionStorage.setTokenOfOwnerByIndex(owner, i, lastTokenIdOfOwner);
                }
                // Pop last tokenId from tokenOfOwner array
                collectionStorage.popTokenOfOwner(owner);
                break;
            }
        }
        collectionStorage.setOwner(tokenId, address(0));
        // Emit Transfer event
        ICollectionProxy_ManagerFunctions(collectionProxy).emitTransfer(owner, address(0), tokenId);
    }

    function _checkOnERC721Received(
        address msgSender,
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(msgSender, from, tokenId, _data) returns (
                bytes4 retval
            ) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert('ERC721Manager: transfer to non ERC721Receiver implementer');
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Owner-restricted setter functions
     */
    function setSporkProxy(address payable sporkProxy) external onlyOwner {
        IERC721ManagerProxy(proxy).setSporkProxy(sporkProxy);
    }

    function setFarmingManagerProxy(address _farmingManagerProxy) external onlyOwner {
        farmingManagerProxy = _farmingManagerProxy;
    }

    function setBaseURI(address collectionProxy, string calldata uri) external onlyOwner {
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        collectionStorage.setBaseURI(uri);
    }

    function setName(address collectionProxy, string calldata newName) external onlyOwner {
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        collectionStorage.setName(newName);
    }

    function setSymbol(address collectionProxy, string calldata newSymbol) external onlyOwner {
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        collectionStorage.setSymbol(newSymbol);
    }

    function setWhitelisted(
        address collectionProxy,
        address[] calldata users,
        bool[] calldata whitelisted
    ) external onlyOwner {
        require(
            users.length == whitelisted.length,
            'ERC721Manager: _users and _whitelisted arrays must have the same length'
        );
        for (uint256 i = 0; i < users.length; i++) {
            _storage.setWhitelisted(collectionProxy, users[i], whitelisted[i]);
        }
    }

    function setMAX_WHITELIST_MINT_PER_ADDRESS(
        address collectionProxy,
        uint256 value
    ) external onlyOwner {
        _storage.setMAX_WHITELIST_MINT_PER_ADDRESS(collectionProxy, value);
    }

    function setMAX_PUBLIC_MINT_PER_ADDRESS(
        address collectionProxy,
        uint256 value
    ) external onlyOwner {
        _storage.setMAX_PUBLIC_MINT_PER_ADDRESS(collectionProxy, value);
    }

    function setMAX_SUPPLY(address collectionProxy, uint256 value) external onlyOwner {
        _storage.setMAX_SUPPLY(collectionProxy, value);
    }

    function setWhitelistPhase(
        address collectionProxy,
        uint256 blockStartWhitelistPhase,
        uint256 blockEndWhitelistPhase
    ) external onlyOwner {
        _storage.setWhitelistPhase(
            collectionProxy,
            blockStartWhitelistPhase,
            blockEndWhitelistPhase
        );
    }

    function setPublicPhase(
        address collectionProxy,
        uint256 blockStartPublicPhase,
        uint256 blockEndPublicPhase
    ) external onlyOwner {
        _storage.setPublicPhase(collectionProxy, blockStartPublicPhase, blockEndPublicPhase);
    }

    function setCollectionMoved(address collectionProxy, bool collectionMoved) external onlyOwner {
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        collectionStorage.setCollectionMoved(collectionMoved);
    }

    function setMovementNoticeURI(
        address collectionProxy,
        string calldata movementNoticeURI
    ) external onlyOwner {
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        collectionStorage.setMovementNoticeURI(movementNoticeURI);
    }

    function setMintFeeRecipient(address mintFeeRecipient) external onlyOwner {
        _storage.setMintFeeRecipient(mintFeeRecipient);
    }

    function setFeeDenominator(uint96 value) external onlyOwner {
        _storage.setFeeDenominator(value);
    }

    function setRoyalty(
        address collectionProxy,
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        require(
            feeNumerator <= _storage.getFeeDenominator(),
            'ERC721Manager: royalty fee will exceed salePrice'
        );
        collectionStorage.setRoyaltyInfo(receiver, feeNumerator);
    }

    function setMintFeeERC20AssetProxy(
        address collectionProxy,
        address mintFeeERC20AssetProxy
    ) external onlyOwner {
        _storage.setMintFeeERC20AssetProxy(collectionProxy, mintFeeERC20AssetProxy);
    }

    function setMintFeeERC20(address collectionProxy, uint256 mintFeeERC20) external onlyOwner {
        _storage.setMintFeeERC20(collectionProxy, mintFeeERC20);
    }

    function setBaseMintFeeETH(address collectionProxy, uint256 baseMintFeeETH) external onlyOwner {
        _storage.setBaseMintFeeETH(collectionProxy, baseMintFeeETH);
    }

    function setETHMintFeeGrowthRateBps(
        address collectionProxy,
        uint256 ethMintFeeGrowthRateBps
    ) external onlyOwner {
        _storage.setETHMintFeeGrowthRateBps(collectionProxy, ethMintFeeGrowthRateBps);
    }

    function setETHMintFeeIncreaseInterval(
        address collectionProxy,
        uint256 ethMintFeeIncreaseInterval
    ) external onlyOwner {
        _storage.setETHMintFeeIncreaseInterval(collectionProxy, ethMintFeeIncreaseInterval);
    }

    function setOperatorFilterRegistry(
        IOperatorFilterRegistry _operatorFilterRegistry
    ) external onlyOwner {
        operatorFilterRegistry = _operatorFilterRegistry;
    }

    function setETHMintsCountThreshold(
        address collectionProxy,
        uint256 ethMintsCountThreshold
    ) external onlyOwner {
        _storage.setETHMintsCountThreshold(collectionProxy, ethMintsCountThreshold);
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

import '../interfaces/IERC165.sol';

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
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

import { IGovernedContract } from './interfaces/IGovernedContract.sol';

/**
 * This is an extension of the original StorageBase contract, allowing for a second ownerHelper address to access
 * owner-restricted functions
 */

contract StorageBaseExtension {
    address payable internal owner;
    address payable internal ownerHelper;

    modifier requireOwner() {
        require(
            msg.sender == address(owner) || msg.sender == address(ownerHelper),
            'StorageBase: Not owner or ownerHelper!'
        );
        _;
    }

    constructor(address _ownerHelper) {
        owner = payable(msg.sender);
        ownerHelper = payable(_ownerHelper);
    }

    function setOwner(address _newOwner) external requireOwner {
        owner = payable(_newOwner);
    }

    function setOwnerHelper(address _newOwnerHelper) external requireOwner {
        ownerHelper = payable(_newOwnerHelper);
    }

    function kill() external requireOwner {
        selfdestruct(payable(msg.sender));
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

import { Context } from './Context.sol';
import { Ownable } from './Ownable.sol';

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Context, Ownable {
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

    /**
     * @dev state variable
     */
    uint256 public blockNumberWhenToUnpause = 0;

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
     * @dev Triggers or extends pause state.
     *
     * Requirements:
     *
     * - @param blocks needs to be greater than 0.
     */
    function pause(uint256 blocks) external onlyOwner {
        require(
            blocks > 0,
            'Pausable: Revert - Pause did not activate. Please enter a positive integer.'
        );
        blockNumberWhenToUnpause = block.number + blocks;
        emit Paused(_msgSender(), blockNumberWhenToUnpause);
    }

    /**
     * @dev Returns to normal code execution.
     */
    function unpause() external onlyOwner {
        blockNumberWhenToUnpause = block.number;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

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

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

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
    function _migrate(address) internal {}

    function _destroy(address _newImpl) internal {
        selfdestruct(payable(_newImpl));
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

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

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

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() {}

    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _txOrigin() internal view returns (address payable) {
        return payable(tx.origin);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}