// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@solidstate/contracts/token/ERC721/ERC721.sol";
import "@solidstate/contracts/access/OwnableStorage.sol";

import "../../interfaces/IPerkToken.sol";
import "../../interfaces/IPerkPropertyRegistry.sol";
import "../helpers/Hooks.sol";
import "../helpers/PerkTokenInternal.sol";
import "../storage/PerkTokenStorage.sol";
import "../storage/PerkTokenHooksStorage.sol";
import "../storage/PerkGovernanceStorage.sol";


contract PerkToken is ERC721, IPerkToken, PerkTokenInternal {
    using Hooks for Hooks.Hook;
    using PerkTokenStorage for PerkTokenStorage.Layout;
    
    //TODO Replace Ownable with AccessControl
    modifier onlyOwner { 
        require(msg.sender == OwnableStorage.layout().owner, "!owner");
        _;
    }

    modifier onlyMinter {
        require(_isMinter(msg.sender), "!minter");
        _;
    }

    function registerBeforeTransferHook(address facet, bytes4 selector) onlyOwner external {
        PerkTokenHooksStorage.addBeforeTokenTransferHook(PerkTokenHooksStorage.layout(), facet, selector);
    }
   
    function unregisterBeforeTransferHook(address facet, bytes4 selector) onlyOwner external {
        PerkTokenHooksStorage.removeBeforeTokenTransferHook(PerkTokenHooksStorage.layout(), facet, selector);
    }


    function mint(address account) external onlyMinter returns(uint256) {
        require(balanceOf(account) == 0, "Token already minted");
        return _mintInternal(account);
    }

    function getToken(address account, bytes32 prop) external view returns (uint256) {
        return findTokenInternal(account, prop);
    }

    function getAllTokensWithProperty(address account, bytes32 prop) external view returns (uint256[] memory) {
        return findAllTokensWithPropertyInternal(account, prop);
    }

    function getOrMintToken(address account, bytes32 prop) external returns (uint256) {
        uint256 pid = findTokenInternal(account, prop);
        if(pid == 0) {
            require(_isMinter(msg.sender), "!minter");
            return _mintInternal(account);
        }
        return pid;
    }

    function attach(uint256 fromPid, uint256 toPid, bytes32[] calldata categories) external {
        //TODO implement
    }

    function detach(uint256 pid, bytes32 category) external returns(uint256 newPid) {
        //TODO implement
    }



    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        Hooks.Hook[] storage hooks = PerkTokenHooksStorage.layout().beforeTokenTransferHooks;
        for(uint256 i=0; i < hooks.length; i++) {
            hooks[i].execute(abi.encode(from, to, tokenId));
        }
    }

    function _isMinter(address sender) internal view returns(bool){
        return IPerkPropertyRegistry(PerkGovernanceStorage.layout().propertyRegistry).isMinter(sender);
    }

    function _mintInternal(address beneficiary) internal returns(uint256){
        uint256 newPid = PerkTokenStorage.layout().generateNextPid();
        _mint(beneficiary, newPid);
        return newPid;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ERC721Base, ERC721BaseInternal } from './base/ERC721Base.sol';
import { ERC721Enumerable } from './enumerable/ERC721Enumerable.sol';
import { ERC721Metadata } from './metadata/ERC721Metadata.sol';
import { ERC165 } from '../../introspection/ERC165.sol';

/**
 * @notice SolidState ERC721 implementation, including recommended extensions
 */
abstract contract ERC721 is
    ERC721Base,
    ERC721Enumerable,
    ERC721Metadata,
    ERC165
{
    /**
     * @notice ERC721 hook: revert if value is included in external approve function call
     * @inheritdoc ERC721BaseInternal
     */
    function _handleApproveMessageValue(
        address operator,
        uint256 tokenId,
        uint256 value
    ) internal virtual override {
        require(value == 0, 'ERC721: payable approve calls not supported');
        super._handleApproveMessageValue(operator, tokenId, value);
    }

    /**
     * @notice ERC721 hook: revert if value is included in external transfer function call
     * @inheritdoc ERC721BaseInternal
     */
    function _handleTransferMessageValue(
        address from,
        address to,
        uint256 tokenId,
        uint256 value
    ) internal virtual override {
        require(value == 0, 'ERC721: payable transfer calls not supported');
        super._handleTransferMessageValue(from, to, tokenId, value);
    }

    /**
     * @inheritdoc ERC721BaseInternal
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721BaseInternal, ERC721Metadata) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library OwnableStorage {
    struct Layout {
        address owner;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.Ownable');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function setOwner(Layout storage l, address owner) internal {
        l.owner = owner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@solidstate/contracts/token/ERC721/IERC721.sol";
import "./IAttachConflictResolver.sol";

interface IPerkToken is IERC721 {

    function mint(address beneficiary) external returns (uint256);
    function getToken(address beneficiary, bytes32 property) external view returns (uint256);
    function getOrMintToken(address beneficiary, bytes32 property) external returns (uint256);
    function getAllTokensWithProperty(address beneficiary, bytes32 property) external view returns (uint256[] memory);

    /**
     * @notice Joins two NFTs of the same owner
     * @param fromPid Second NFT (properties will be removed from this one)
     * @param toPid Main NFT (properties will be added to this one)
     */
    function attach(uint256 fromPid, uint256 toPid, bytes32[] calldata categories) external;

    /**
     * @notice Splits a PerkNFTs into two
     * @param pid Id of the NFT to split
     * @param category Category of the NFT to detatch
     * @return newPid Id of the new NFT holding the detached Category
     */
    function detach(uint256 pid, bytes32 category) external returns(uint256 newPid);


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPerkPropertyRegistry {
    function getCategoryInfoForProperty(bytes32 property) external view returns(bytes32 category, bool splitAllowed);
    function getCategoryInfo(bytes32 category) external view returns(bytes32[] memory properties, bool splitAllowed);
    function isCategoryManager(bytes32 category, address manager) external view returns(bool);
    function isPropertyManager(bytes32 property, address manager) external view returns(bool);
    function isMinter(address manager) external view returns(bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Hooks {

    struct Hook {
        address target;     // Address of the facet or external contract with the hook
        bytes4 selector;    // Hook function selector
    }

    /**
     * @notice Execute a facet hook via delegatecall
     */
    function execute(Hook storage h, bytes memory data) internal {
        bytes memory dataWithSelector = bytes.concat(h.selector, data);
        (bool success, bytes memory returnData) = h.target.delegatecall(dataWithSelector);
        if(!success) assembly {
            revert(add(returnData,32), returnData) // Reverts with an error message from the returnData
        }
    }

    /**
     * @notice Execute a hook in an external contract via low-level call
     */
    function executeExternal(Hook storage h, bytes memory data) internal {
        bytes memory dataWithSelector = bytes.concat(h.selector, data);
        (bool success, bytes memory returnData) = h.target.call(dataWithSelector);
        if(!success) assembly {
            revert(add(returnData,32), returnData) // Reverts with an error message from the returnData
        }
    }

    function add(Hook[] storage hooks, address target, bytes4 selector) internal {
        //TODO revert if exists
        hooks.push(Hook({
            target: target,
            selector: selector
        }));
    }
    
    function remove(Hook[] storage hooks, address target, bytes4 selector) internal {
        //TODO revert if not exists
        for(uint256 i=0; i < hooks.length; i++) {
            Hook storage h = hooks[i];
            if( h.target==target && h.selector==selector ) {
                if(i < hooks.length - 1) {
                    hooks[i] = hooks[hooks.length - 1];
                }
                hooks.pop();
                break;
            }
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@solidstate/contracts/access/OwnableInternal.sol";
import "@solidstate/contracts/token/ERC721/base/ERC721BaseStorage.sol";
import "@solidstate/contracts/utils/EnumerableSet.sol";

import "../storage/PerkRestrictionsStorage.sol";
import "../storage/PerkPropertiesStorage.sol";


contract PerkTokenInternal {
    using ERC721BaseStorage for ERC721BaseStorage.Layout;
    using PerkPropertiesStorage for PerkPropertiesStorage.Layout;
    using EnumerableSet for EnumerableSet.UintSet;


    function findTokenInternal(address account, bytes32 prop) internal view returns(uint256){
        uint256 balance = ERC721BaseStorage.layout().holderTokens[account].length();
        if (balance == 0) {
            return 0;
        } else {
            // Searching for pid with required property
            for(uint256 i=0; i < balance; i++){
                uint256 pid = ERC721BaseStorage.layout().tokenOfOwnerByIndex(account, i);
                if(PerkPropertiesStorage.layout().exist(pid, prop)) return pid;
            }
            // No pid with required property found. Return first one.
            return ERC721BaseStorage.layout().tokenOfOwnerByIndex(account, 0);
        }
    }

    function findAllTokensWithPropertyInternal(address account, bytes32 prop) internal view returns(uint256[] memory){
        uint256 balance = ERC721BaseStorage.layout().holderTokens[account].length();
        if (balance == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory tokens = new uint256[](balance);
            uint256 found;
            for(uint256 i=0; i < balance; i++){
                uint256 pid = ERC721BaseStorage.layout().tokenOfOwnerByIndex(account, i);
                if(PerkPropertiesStorage.layout().exist(pid, prop)){
                    tokens[found++] = pid;
                }
            }
            if (found == 0) {
                return new uint256[](0);
            } else {
                //return tokens[0:found];
                uint256[] memory tokensFound = new uint256[](found);
                for(uint256 j=0; j<found; j++) {
                    tokensFound[j] = tokens[j];
                }
                return tokensFound;
            }
        }
    }

    function tokenExistsInternal(uint256 pid) internal view returns(bool) {
        return ERC721BaseStorage.layout().exists(pid);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


library PerkTokenStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256('allianceblock.perknft.core.storage.PerkTokenHooksStorage');


    struct Layout {
        uint256 mintCounter;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function generateNextPid(Layout storage l) internal returns(uint256) {
        l.mintCounter++;
        return l.mintCounter;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../helpers/Hooks.sol";

library PerkTokenHooksStorage {
    using Hooks for Hooks.Hook;
    using Hooks for Hooks.Hook[];

    bytes32 internal constant STORAGE_SLOT = keccak256('allianceblock.perknft.core.storage.PerkTokenHooksStorage');


    struct Layout {
        Hooks.Hook[] beforeTokenTransferHooks;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function addBeforeTokenTransferHook(Layout storage l, address facet, bytes4 selector) internal {
        l.beforeTokenTransferHooks.add(facet, selector);
    }

    function removeBeforeTokenTransferHook(Layout storage l, address facet, bytes4 selector) internal {
        l.beforeTokenTransferHooks.remove(facet, selector);
    }    

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library PerkGovernanceStorage {

    bytes32 internal constant STORAGE_SLOT = keccak256('allianceblock.perknft.core.storage.PerkGovernanceStorage');

    struct Layout {
        address propertyRegistry;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function setPropertyRegistry(Layout storage l, address propertyRegistry) internal {
        l.propertyRegistry = propertyRegistry;
    }

  
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { AddressUtils } from '../../../utils/AddressUtils.sol';
import { EnumerableMap } from '../../../utils/EnumerableMap.sol';
import { EnumerableSet } from '../../../utils/EnumerableSet.sol';
import { IERC721 } from '../IERC721.sol';
import { IERC721Receiver } from '../IERC721Receiver.sol';
import { ERC721BaseStorage } from './ERC721BaseStorage.sol';
import { ERC721BaseInternal } from './ERC721BaseInternal.sol';

/**
 * @notice Base ERC721 implementation, excluding optional extensions
 */
abstract contract ERC721Base is IERC721, ERC721BaseInternal {
    using AddressUtils for address;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using EnumerableSet for EnumerableSet.UintSet;

    /**
     * @inheritdoc IERC721
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balanceOf(account);
    }

    /**
     * @inheritdoc IERC721
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        return _ownerOf(tokenId);
    }

    /**
     * @inheritdoc IERC721
     */
    function getApproved(uint256 tokenId) public view returns (address) {
        return _getApproved(tokenId);
    }

    /**
     * @inheritdoc IERC721
     */
    function isApprovedForAll(address account, address operator)
        public
        view
        returns (bool)
    {
        return _isApprovedForAll(account, operator);
    }

    /**
     * @inheritdoc IERC721
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable {
        _handleTransferMessageValue(from, to, tokenId, msg.value);
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            'ERC721: transfer caller is not owner or approved'
        );
        _transfer(from, to, tokenId);
    }

    /**
     * @inheritdoc IERC721
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @inheritdoc IERC721
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable {
        _handleTransferMessageValue(from, to, tokenId, msg.value);
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            'ERC721: transfer caller is not owner or approved'
        );
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @inheritdoc IERC721
     */
    function approve(address operator, uint256 tokenId) public payable {
        _handleApproveMessageValue(operator, tokenId, msg.value);
        address owner = ownerOf(tokenId);
        require(operator != owner, 'ERC721: approval to current owner');
        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            'ERC721: approve caller is not owner nor approved for all'
        );
        _approve(operator, tokenId);
    }

    /**
     * @inheritdoc IERC721
     */
    function setApprovalForAll(address operator, bool status) public {
        require(operator != msg.sender, 'ERC721: approve to caller');
        ERC721BaseStorage.layout().operatorApprovals[msg.sender][
            operator
        ] = status;
        emit ApprovalForAll(msg.sender, operator, status);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { EnumerableMap } from '../../../utils/EnumerableMap.sol';
import { EnumerableSet } from '../../../utils/EnumerableSet.sol';
import { ERC721BaseStorage } from '../base/ERC721BaseStorage.sol';
import { IERC721Enumerable } from './IERC721Enumerable.sol';
import { ERC721EnumerableInternal } from './ERC721EnumerableInternal.sol';

abstract contract ERC721Enumerable is
    IERC721Enumerable,
    ERC721EnumerableInternal
{
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using EnumerableSet for EnumerableSet.UintSet;

    /**
     * @inheritdoc IERC721Enumerable
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply();
    }

    /**
     * @inheritdoc IERC721Enumerable
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        returns (uint256)
    {
        return _tokenOfOwnerByIndex(owner, index);
    }

    /**
     * @inheritdoc IERC721Enumerable
     */
    function tokenByIndex(uint256 index) public view returns (uint256) {
        return _tokenByIndex(index);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { UintUtils } from '../../../utils/UintUtils.sol';
import { ERC721BaseInternal, ERC721BaseStorage } from '../base/ERC721Base.sol';
import { ERC721MetadataStorage } from './ERC721MetadataStorage.sol';
import { ERC721MetadataInternal } from './ERC721MetadataInternal.sol';
import { IERC721Metadata } from './IERC721Metadata.sol';

/**
 * @notice ERC721 metadata extensions
 */
abstract contract ERC721Metadata is IERC721Metadata, ERC721MetadataInternal {
    using ERC721BaseStorage for ERC721BaseStorage.Layout;
    using UintUtils for uint256;

    /**
     * @notice inheritdoc IERC721Metadata
     */
    function name() public view virtual returns (string memory) {
        return ERC721MetadataStorage.layout().name;
    }

    /**
     * @notice inheritdoc IERC721Metadata
     */
    function symbol() public view virtual returns (string memory) {
        return ERC721MetadataStorage.layout().symbol;
    }

    /**
     * @notice inheritdoc IERC721Metadata
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        returns (string memory)
    {
        require(
            ERC721BaseStorage.layout().exists(tokenId),
            'ERC721Metadata: URI query for nonexistent token'
        );

        ERC721MetadataStorage.Layout storage l = ERC721MetadataStorage.layout();

        string memory tokenIdURI = l.tokenURIs[tokenId];
        string memory baseURI = l.baseURI;

        if (bytes(baseURI).length == 0) {
            return tokenIdURI;
        } else if (bytes(tokenIdURI).length > 0) {
            return string(abi.encodePacked(baseURI, tokenIdURI));
        } else {
            return string(abi.encodePacked(baseURI, tokenId.toString()));
        }
    }

    /**
     * @inheritdoc ERC721MetadataInternal
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC165 } from './IERC165.sol';
import { ERC165Storage } from './ERC165Storage.sol';

/**
 * @title ERC165 implementation
 */
abstract contract ERC165 is IERC165 {
    using ERC165Storage for ERC165Storage.Layout;

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return ERC165Storage.layout().isSupportedInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { UintUtils } from './UintUtils.sol';

library AddressUtils {
    using UintUtils for uint256;

    function toString(address account) internal pure returns (string memory) {
        return uint256(uint160(account)).toHexString(20);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable account, uint256 amount) internal {
        (bool success, ) = account.call{ value: amount }('');
        require(success, 'AddressUtils: failed to send value');
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionCall(target, data, 'AddressUtils: failed low-level call');
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory error
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, error);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                'AddressUtils: failed low-level call with value'
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            'AddressUtils: insufficient balance for call'
        );
        return _functionCallWithValue(target, data, value, error);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) private returns (bytes memory) {
        require(
            isContract(target),
            'AddressUtils: function call to non-contract'
        );

        (bool success, bytes memory returnData) = target.call{ value: value }(
            data
        );

        if (success) {
            return returnData;
        } else if (returnData.length > 0) {
            assembly {
                let returnData_size := mload(returnData)
                revert(add(32, returnData), returnData_size)
            }
        } else {
            revert(error);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Map implementation with enumeration functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library EnumerableMap {
    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        MapEntry[] _entries;
        // 1-indexed to allow 0 to signify nonexistence
        mapping(bytes32 => uint256) _indexes;
    }

    struct AddressToAddressMap {
        Map _inner;
    }

    struct UintToAddressMap {
        Map _inner;
    }

    function at(AddressToAddressMap storage map, uint256 index)
        internal
        view
        returns (address, address)
    {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        address addressKey;
        assembly {
            addressKey := mload(add(key, 20))
        }
        return (addressKey, address(uint160(uint256(value))));
    }

    function at(UintToAddressMap storage map, uint256 index)
        internal
        view
        returns (uint256, address)
    {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    function contains(AddressToAddressMap storage map, address key)
        internal
        view
        returns (bool)
    {
        return _contains(map._inner, bytes32(uint256(uint160(key))));
    }

    function contains(UintToAddressMap storage map, uint256 key)
        internal
        view
        returns (bool)
    {
        return _contains(map._inner, bytes32(key));
    }

    function length(AddressToAddressMap storage map)
        internal
        view
        returns (uint256)
    {
        return _length(map._inner);
    }

    function length(UintToAddressMap storage map)
        internal
        view
        returns (uint256)
    {
        return _length(map._inner);
    }

    function get(AddressToAddressMap storage map, address key)
        internal
        view
        returns (address)
    {
        return
            address(
                uint160(
                    uint256(_get(map._inner, bytes32(uint256(uint160(key)))))
                )
            );
    }

    function get(UintToAddressMap storage map, uint256 key)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }

    function set(
        AddressToAddressMap storage map,
        address key,
        address value
    ) internal returns (bool) {
        return
            _set(
                map._inner,
                bytes32(uint256(uint160(key))),
                bytes32(uint256(uint160(value)))
            );
    }

    function set(
        UintToAddressMap storage map,
        uint256 key,
        address value
    ) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    function remove(AddressToAddressMap storage map, address key)
        internal
        returns (bool)
    {
        return _remove(map._inner, bytes32(uint256(uint160(key))));
    }

    function remove(UintToAddressMap storage map, uint256 key)
        internal
        returns (bool)
    {
        return _remove(map._inner, bytes32(key));
    }

    function _at(Map storage map, uint256 index)
        private
        view
        returns (bytes32, bytes32)
    {
        require(
            map._entries.length > index,
            'EnumerableMap: index out of bounds'
        );

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    function _contains(Map storage map, bytes32 key)
        private
        view
        returns (bool)
    {
        return map._indexes[key] != 0;
    }

    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, 'EnumerableMap: nonexistent key');
        unchecked {
            return map._entries[keyIndex - 1]._value;
        }
    }

    function _set(
        Map storage map,
        bytes32 key,
        bytes32 value
    ) private returns (bool) {
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) {
            map._entries.push(MapEntry({ _key: key, _value: value }));
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            unchecked {
                map._entries[keyIndex - 1]._value = value;
            }
            return false;
        }
    }

    function _remove(Map storage map, bytes32 key) private returns (bool) {
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) {
            unchecked {
                MapEntry storage last = map._entries[map._entries.length - 1];

                // move last entry to now-vacant index
                map._entries[keyIndex - 1] = last;
                map._indexes[last._key] = keyIndex;
            }

            // clear last index
            map._entries.pop();
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Set implementation with enumeration functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library EnumerableSet {
    struct Set {
        bytes32[] _values;
        // 1-indexed to allow 0 to signify nonexistence
        mapping(bytes32 => uint256) _indexes;
    }

    struct Bytes32Set {
        Set _inner;
    }

    struct AddressSet {
        Set _inner;
    }

    struct UintSet {
        Set _inner;
    }

    function at(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return _at(set._inner, index);
    }

    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function at(UintSet storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
        return uint256(_at(set._inner, index));
    }

    function contains(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, value);
    }

    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(UintSet storage set, uint256 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(value));
    }

    function indexOf(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, value);
    }

    function indexOf(AddressSet storage set, address value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, bytes32(uint256(uint160(value))));
    }

    function indexOf(UintSet storage set, uint256 value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, bytes32(value));
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function add(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _add(set._inner, value);
    }

    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, value);
    }

    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(UintSet storage set, uint256 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        require(
            set._values.length > index,
            'EnumerableSet: index out of bounds'
        );
        return set._values[index];
    }

    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
        return set._indexes[value] != 0;
    }

    function _indexOf(Set storage set, bytes32 value)
        private
        view
        returns (uint256)
    {
        unchecked {
            return set._indexes[value] - 1;
        }
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            unchecked {
                bytes32 last = set._values[set._values.length - 1];

                // move last value to now-vacant index

                set._values[valueIndex - 1] = last;
                set._indexes[last] = valueIndex;
            }
            // clear last index

            set._values.pop();
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC165 } from '../../introspection/IERC165.sol';
import { IERC721Internal } from './IERC721Internal.sol';

/**
 * @notice ERC721 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721 is IERC721Internal, IERC165 {
    /**
     * @notice query the balance of given address
     * @return balance quantity of tokens held
     */
    function balanceOf(address account) external view returns (uint256 balance);

    /**
     * @notice query the owner of given token
     * @param tokenId token to query
     * @return owner token owner
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @notice transfer token between given addresses, checking for ERC721Receiver implementation if applicable
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId token id
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @notice transfer token between given addresses, checking for ERC721Receiver implementation if applicable
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId token id
     * @param data data payload
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;

    /**
     * @notice transfer token between given addresses, without checking for ERC721Receiver implementation if applicable
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId token id
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @notice grant approval to given account to spend token
     * @param operator address to be approved
     * @param tokenId token to approve
     */
    function approve(address operator, uint256 tokenId) external payable;

    /**
     * @notice get approval status for given token
     * @param tokenId token to query
     * @return operator address approved to spend token
     */
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    /**
     * @notice grant approval to or revoke approval from given account to spend all tokens held by sender
     * @param operator address to be approved
     * @param status approval status
     */
    function setApprovalForAll(address operator, bool status) external;

    /**
     * @notice query approval status of given operator with respect to given address
     * @param account address to query for approval granted
     * @param operator address to query for approval received
     * @return status whether operator is approved to spend tokens held by account
     */
    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool status);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { EnumerableMap } from '../../../utils/EnumerableMap.sol';
import { EnumerableSet } from '../../../utils/EnumerableSet.sol';

library ERC721BaseStorage {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC721Base');

    struct Layout {
        EnumerableMap.UintToAddressMap tokenOwners;
        mapping(address => EnumerableSet.UintSet) holderTokens;
        mapping(uint256 => address) tokenApprovals;
        mapping(address => mapping(address => bool)) operatorApprovals;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function exists(Layout storage l, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        return l.tokenOwners.contains(tokenId);
    }

    function totalSupply(Layout storage l) internal view returns (uint256) {
        return l.tokenOwners.length();
    }

    function tokenOfOwnerByIndex(
        Layout storage l,
        address owner,
        uint256 index
    ) internal view returns (uint256) {
        return l.holderTokens[owner].at(index);
    }

    function tokenByIndex(Layout storage l, uint256 index)
        internal
        view
        returns (uint256)
    {
        (uint256 tokenId, ) = l.tokenOwners.at(index);
        return tokenId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { AddressUtils } from '../../../utils/AddressUtils.sol';
import { EnumerableMap } from '../../../utils/EnumerableMap.sol';
import { EnumerableSet } from '../../../utils/EnumerableSet.sol';
import { IERC721Internal } from '../IERC721Internal.sol';
import { IERC721Receiver } from '../IERC721Receiver.sol';
import { ERC721BaseStorage } from './ERC721BaseStorage.sol';

/**
 * @notice Base ERC721 internal functions
 */
abstract contract ERC721BaseInternal is IERC721Internal {
    using ERC721BaseStorage for ERC721BaseStorage.Layout;
    using AddressUtils for address;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using EnumerableSet for EnumerableSet.UintSet;

    function _balanceOf(address account) internal view returns (uint256) {
        require(
            account != address(0),
            'ERC721: balance query for the zero address'
        );
        return ERC721BaseStorage.layout().holderTokens[account].length();
    }

    function _ownerOf(uint256 tokenId) internal view returns (address) {
        address owner = ERC721BaseStorage.layout().tokenOwners.get(tokenId);
        require(owner != address(0), 'ERC721: invalid owner');
        return owner;
    }

    function _getApproved(uint256 tokenId) internal view returns (address) {
        ERC721BaseStorage.Layout storage l = ERC721BaseStorage.layout();

        require(
            l.exists(tokenId),
            'ERC721: approved query for nonexistent token'
        );

        return l.tokenApprovals[tokenId];
    }

    function _isApprovedForAll(address account, address operator)
        internal
        view
        returns (bool)
    {
        return ERC721BaseStorage.layout().operatorApprovals[account][operator];
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        require(
            ERC721BaseStorage.layout().exists(tokenId),
            'ERC721: query for nonexistent token'
        );

        address owner = _ownerOf(tokenId);

        return (spender == owner ||
            _getApproved(tokenId) == spender ||
            _isApprovedForAll(owner, spender));
    }

    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), 'ERC721: mint to the zero address');

        ERC721BaseStorage.Layout storage l = ERC721BaseStorage.layout();

        require(!l.exists(tokenId), 'ERC721: token already minted');

        _beforeTokenTransfer(address(0), to, tokenId);

        l.holderTokens[to].add(tokenId);
        l.tokenOwners.set(tokenId, to);

        emit Transfer(address(0), to, tokenId);
    }

    function _safeMint(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId, '');
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            'ERC721: transfer to non ERC721Receiver implementer'
        );
    }

    function _burn(uint256 tokenId) internal {
        address owner = _ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        _approve(address(0), tokenId);

        ERC721BaseStorage.Layout storage l = ERC721BaseStorage.layout();
        l.holderTokens[owner].remove(tokenId);
        l.tokenOwners.remove(tokenId);

        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        require(
            _ownerOf(tokenId) == from,
            'ERC721: transfer of token that is not own'
        );
        require(to != address(0), 'ERC721: transfer to the zero address');

        _beforeTokenTransfer(from, to, tokenId);

        _approve(address(0), tokenId);

        ERC721BaseStorage.Layout storage l = ERC721BaseStorage.layout();
        l.holderTokens[from].remove(tokenId);
        l.holderTokens[to].add(tokenId);
        l.tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, data),
            'ERC721: transfer to non ERC721Receiver implementer'
        );
    }

    function _approve(address operator, uint256 tokenId) internal {
        ERC721BaseStorage.layout().tokenApprovals[tokenId] = operator;
        emit Approval(_ownerOf(tokenId), operator, tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal returns (bool) {
        if (!to.isContract()) {
            return true;
        }

        bytes memory returnData = to.functionCall(
            abi.encodeWithSelector(
                IERC721Receiver(to).onERC721Received.selector,
                msg.sender,
                from,
                tokenId,
                data
            ),
            'ERC721: transfer to non ERC721Receiver implementer'
        );

        bytes4 returnValue = abi.decode(returnData, (bytes4));
        return returnValue == type(IERC721Receiver).interfaceId;
    }

    /**
     * @notice ERC721 hook, called before externally called approvals for processing of included message value
     * @param operator beneficiary of approval
     * @param tokenId id of transferred token
     * @param value message value
     */
    function _handleApproveMessageValue(
        address operator,
        uint256 tokenId,
        uint256 value
    ) internal virtual {}

    /**
     * @notice ERC721 hook, called before externally called transfers for processing of included message value
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId id of transferred token
     * @param value message value
     */
    function _handleTransferMessageValue(
        address from,
        address to,
        uint256 tokenId,
        uint256 value
    ) internal virtual {}

    /**
     * @notice ERC721 hook, called before all transfers including mint and burn
     * @dev function should be overridden and new implementation must call super
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId id of transferred token
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title utility functions for uint256 operations
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
library UintUtils {
    bytes16 private constant HEX_SYMBOLS = '0123456789abcdef';

    function toString(uint256 value) internal pure returns (string memory) {
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

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0x00';
        }

        uint256 length = 0;

        for (uint256 temp = value; temp != 0; temp >>= 8) {
            unchecked {
                length++;
            }
        }

        return toHexString(value, length);
    }

    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = '0';
        buffer[1] = 'x';

        unchecked {
            for (uint256 i = 2 * length + 1; i > 1; --i) {
                buffer[i] = HEX_SYMBOLS[value & 0xf];
                value >>= 4;
            }
        }

        require(value == 0, 'UintUtils: hex length insufficient');

        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC165 interface registration interface
 * @dev see https://eips.ethereum.org/EIPS/eip-165
 */
interface IERC165 {
    /**
     * @notice query whether contract has registered support for given interface
     * @param interfaceId interface id
     * @return bool whether interface is supported
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @notice Partial ERC721 interface needed by internal functions
 */
interface IERC721Internal {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Approval(
        address indexed owner,
        address indexed operator,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC721Enumerable {
    /**
     * @notice get total token supply
     * @return total supply
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice get token of given owner at given internal storage index
     * @param owner token holder to query
     * @param index position in owner's token list to query
     * @return tokenId id of retrieved token
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 tokenId);

    /**
     * @notice get token at given internal storage index
     * @param index position in global token list to query
     * @return tokenId id of retrieved token
     */
    function tokenByIndex(uint256 index)
        external
        view
        returns (uint256 tokenId);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ERC721BaseStorage } from '../base/ERC721BaseStorage.sol';

abstract contract ERC721EnumerableInternal {
    using ERC721BaseStorage for ERC721BaseStorage.Layout;

    /**
     * @notice TODO
     */
    function _totalSupply() internal view returns (uint256) {
        return ERC721BaseStorage.layout().totalSupply();
    }

    /**
     * @notice TODO
     */
    function _tokenOfOwnerByIndex(address owner, uint256 index)
        internal
        view
        returns (uint256)
    {
        return ERC721BaseStorage.layout().tokenOfOwnerByIndex(owner, index);
    }

    /**
     * @notice TODO
     */
    function _tokenByIndex(uint256 index) internal view returns (uint256) {
        return ERC721BaseStorage.layout().tokenByIndex(index);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library ERC721MetadataStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC721Metadata');

    struct Layout {
        string name;
        string symbol;
        string baseURI;
        mapping(uint256 => string) tokenURIs;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ERC721BaseInternal } from '../base/ERC721Base.sol';
import { ERC721MetadataStorage } from './ERC721MetadataStorage.sol';

/**
 * @notice ERC721Metadata internal functions
 */
abstract contract ERC721MetadataInternal is ERC721BaseInternal {
    /**
     * @notice ERC721 hook: clear per-token URI data on burn
     * @inheritdoc ERC721BaseInternal
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (to == address(0)) {
            delete ERC721MetadataStorage.layout().tokenURIs[tokenId];
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721Metadata interface
 */
interface IERC721Metadata {
    /**
     * @notice get token name
     * @return token name
     */
    function name() external view returns (string memory);

    /**
     * @notice get token symbol
     * @return token symbol
     */
    function symbol() external view returns (string memory);

    /**
     * @notice get generated URI for given token
     * @return token URI
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library ERC165Storage {
    struct Layout {
        mapping(bytes4 => bool) supportedInterfaces;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC165');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function isSupportedInterface(Layout storage l, bytes4 interfaceId)
        internal
        view
        returns (bool)
    {
        return l.supportedInterfaces[interfaceId];
    }

    function setSupportedInterface(
        Layout storage l,
        bytes4 interfaceId,
        bool status
    ) internal {
        require(interfaceId != 0xffffffff, 'ERC165: invalid interface id');
        l.supportedInterfaces[interfaceId] = status;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAttachConflictResolver {
    function resolveConflictAndMoveProperty(uint256 from, uint256 to, bytes32 property) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { OwnableStorage } from './OwnableStorage.sol';

abstract contract OwnableInternal {
    using OwnableStorage for OwnableStorage.Layout;

    modifier onlyOwner() {
        require(
            msg.sender == OwnableStorage.layout().owner,
            'Ownable: sender must be owner'
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../interfaces/IPerkRestrictions.sol";

library PerkRestrictionsStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256('allianceblock.perknft.core.storage.PerkRestrictionsStorage');

    
    /**
     * Pointer to find a restriction in a PropertyRestrictions struct:
     * RestrictionPointer storage rp = ... ;
     * PropertyRestrictions storage prs  = layout().propertyRestriction;
     * Restriction storage r = prs.restrictions[rp.property][rp.restrictionIndex]
     */
    struct RestrictionPointer {
        bytes32 property;
        uint256 restrictionIndex;
    }

    struct PropertyRestrictions {
        mapping(bytes32 => IPerkRestrictions.Restriction[]) restrictions; //Maps property to an array of linked restrictions
        mapping(bytes32 => RestrictionPointer[]) restrictionsByType; //Maps restriction type to a list of restriction pointeres
    }

    struct Layout {
        mapping(uint256=>PropertyRestrictions) propertyRestriction; //Maps nftID to restrictions storage
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function add(Layout storage l, uint256 pid, bytes32 property, IPerkRestrictions.Restriction memory r) internal returns(RestrictionPointer memory rp) {
        PropertyRestrictions storage prs = l.propertyRestriction[pid];
        uint256 nextIdx = prs.restrictions[property].length;
        prs.restrictions[property].push(r);
        rp = RestrictionPointer({
            property: property,
            restrictionIndex: nextIdx
        });
        prs.restrictionsByType[r.rtype].push(rp);
    }

    function remove(Layout storage l, uint256 pid, RestrictionPointer memory rp) internal {
        //TODO implement
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DataStorageLib.sol";

library PerkPropertiesStorage {
    using DataStorageLib for DataStorageLib.DataStorage;

    bytes32 internal constant STORAGE_SLOT = keccak256('allianceblock.perknft.core.storage.PerkPropertiesStorage');
    
    struct PropertyData {
        bool enabled; // Whether the property is enabled
        DataStorageLib.DataStorage data; // Data storage for this property
    }


    struct Layout {
        mapping(uint256 => mapping(bytes32 => PropertyData)) properties; // Maps pid to a mapping (prop => PropertyData)
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function exist(Layout storage l, uint256 pid, bytes32 prop) internal view returns(bool){
        return l.properties[pid][prop].enabled;
    }

    function add(Layout storage l, uint256 pid, bytes32 prop) internal {
        l.properties[pid][prop].enabled = true;
    }

    function remove(Layout storage l, uint256 pid, bytes32 prop) internal {
        l.properties[pid][prop].enabled = false;
        l.properties[pid][prop].data.clear();
    }

    function getDataBytes32(Layout storage l, uint256 pid, bytes32 prop, bytes32 key) internal view returns(bytes32) {
        return l.properties[pid][prop].data.getBytes32Value(key);
    }
    function setDataBytes32(Layout storage l, uint256 pid, bytes32 prop, bytes32 key, bytes32 value) internal {
        l.properties[pid][prop].data.setValue(key, value);
    }

    function getDataBytes(Layout storage l, uint256 pid, bytes32 prop, bytes32 key) internal view returns(bytes memory) {
        return l.properties[pid][prop].data.getBytesValue(key);
    }
    function setDataBytes(Layout storage l, uint256 pid, bytes32 prop, bytes32 key, bytes memory value) internal {
        l.properties[pid][prop].data.setValue(key, value);
    }

    function getDataSetContainsValue(Layout storage l, uint256 pid, bytes32 prop, bytes32 key, bytes32 value) internal view returns(bool) {
        return l.properties[pid][prop].data.getSetContainsValue(key, value);
    }
    function getDataSetLength(Layout storage l, uint256 pid, bytes32 prop, bytes32 key) internal view returns(uint256) {
        return l.properties[pid][prop].data.getSetLength(key);
    }
    function getDataSetAllValues(Layout storage l, uint256 pid, bytes32 prop, bytes32 key) internal view returns(bytes32[] memory) {
        return l.properties[pid][prop].data.getSetAllValues(key);
    }
    function setDataSetAddValue(Layout storage l, uint256 pid, bytes32 prop, bytes32 key, bytes32 value) internal {
        l.properties[pid][prop].data.setValue(key, value, false);
    }
    function setDataSetRemoveValue(Layout storage l, uint256 pid, bytes32 prop, bytes32 key, bytes32 value) internal {
        l.properties[pid][prop].data.setValue(key, value, true);
    }

    function getDataMapValue(Layout storage l, uint256 pid, bytes32 prop, bytes32 key, bytes32 vKey) internal view returns(bytes32) {
        return l.properties[pid][prop].data.getMapValue(key, vKey);
    }
    function getDataMapLength(Layout storage l, uint256 pid, bytes32 prop, bytes32 key) internal view returns(uint256) {
        return l.properties[pid][prop].data.getMapLength(key);
    }
    function getDataMapAllEntries(Layout storage l, uint256 pid, bytes32 prop, bytes32 key) internal view returns(bytes32[] memory, bytes32[] memory) {
        return l.properties[pid][prop].data.getMapAllEntries(key);
    }
    function setDataMapSetValue(Layout storage l, uint256 pid, bytes32 prop, bytes32 key, bytes32 vKey, bytes32 vValue) internal {
        l.properties[pid][prop].data.setValue(key, vKey, vValue);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IAttachConflictResolver.sol";

interface IPerkRestrictions {

    struct Restriction {
        bytes32 rtype;
        bytes data;
    }


    function addRestriction(uint256 pid, bytes32 prop, Restriction calldata restr) external returns (uint256 idx);
    function removeRestriction(uint256 pid, bytes32 prop, uint256 ridx) external ;
    function removeRestrictions(uint256 pid, bytes32 prop, uint256[] calldata ridxs) external;
    function getRestrictions(uint256 pid, bytes32 prop) external view returns(Restriction[] memory);
    function moveRestrictions(uint256 fromPid, uint256 toPid, bytes32 prop) external returns (uint256[] memory newIdxs);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@solidstate/contracts/utils/EnumerableSet.sol";
import "../../utils/EnumerableMapMod.sol";

/**
 * @title AllianceBlock Data Storage Library
 * @dev Storage of data for the AllianceBlock PerkNFT Properties
*/
library DataStorageLib {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableMapMod for EnumerableMapMod.Bytes32ToBytes32Map;

    struct DataStorage {
        mapping(bytes32=>bytes32) keyValueData;
        mapping(bytes32=>bytes) keyBytesData;
        mapping(bytes32=>EnumerableSet.Bytes32Set) keySetData;
        mapping(bytes32=>EnumerableMapMod.Bytes32ToBytes32Map) keyMapData;

        // This arrays we need to allow clearing/moving all data. See clear() and moveData()
        // TODO Change this arrays to EnumerableSet.Bytes32Set
        bytes32[] kvKeys;   // Array of keys of keyValueData mapping
        bytes32[] kbKeys;   // Array of keys of keyBytesData mapping
        bytes32[] ksKeys;   // Array of keys of keySetData mapping 
        bytes32[] kmKeys;   // Array of keys of keyMapData mapping 
    }

    /**
     * @notice Internal setter for keyValueData data
     * @param ds DataStorage struct
     * @param key the key to set
     * @param value the value to set
     */
    function setValue(DataStorage storage ds, bytes32 key, bytes32 value) internal {
        bytes32 oldValue = ds.keyValueData[key];
        ds.keyValueData[key] = value;

        if(value == 0x00 && oldValue != 0x00){
            removeKeyFromArray(ds.kvKeys, key);
        } else if(value != 0x00 && oldValue == 0x00) {
            ds.kvKeys.push(key);
        }
    }

    /**
     * @notice Internal setter for keyBytesData
     * @param ds DataStorage struct
     * @param key the key to set
     * @param value the value to set
     */
    function setValue(DataStorage storage ds, bytes32 key, bytes memory value) internal {
        bool oldValueIsEmpty = (ds.keyBytesData[key].length == 0);
        bool newValueIsEmpty = (value.length == 0);
        ds.keyBytesData[key] = value;

        if(newValueIsEmpty && !oldValueIsEmpty){
            removeKeyFromArray(ds.kbKeys, key);
        } else if(!newValueIsEmpty && oldValueIsEmpty) {
            ds.kbKeys.push(key);
        }
    }

    /**
     * @notice Internal setter for keySetData
     * @param ds DataStorage struct
     * @param key the key to set
     * @param value Value to add/remove
     * @param remove if false - add value, if true - remove value
     */
    function setValue(DataStorage storage ds, bytes32 key, bytes32 value, bool remove) internal {
        bool oldValueIsEmpty = (ds.keySetData[key].length() == 0);
        if(remove) {
            ds.keySetData[key].remove(value);
        } else {
            ds.keySetData[key].add(value);
        }
        bool newValueIsEmpty = (ds.keySetData[key].length() == 0);

        if(newValueIsEmpty && !oldValueIsEmpty){
            removeKeyFromArray(ds.ksKeys, key);
        } else if(!newValueIsEmpty && oldValueIsEmpty) {
            ds.ksKeys.push(key);
        }
    }

    /**
     * @notice Internal setter for keyMapData
     * @param ds DataStorage struct
     * @param key the key to set
     * @param vKey second-level key
     * @param vValue second-level value, if zero - second-level key will be removed
     */
    function setValue(DataStorage storage ds, bytes32 key, bytes32 vKey, bytes32 vValue) internal {
        bool oldValueIsEmpty = (ds.keyMapData[key].length() == 0);
        if(vValue == bytes32(0)) {
            ds.keyMapData[key].remove(vKey);
        } else {
            ds.keyMapData[key].set(vKey, vValue);
        }
        bool newValueIsEmpty = (ds.keyMapData[key].length() == 0);

        if(newValueIsEmpty && !oldValueIsEmpty){
            removeKeyFromArray(ds.kmKeys, key);
        } else if(!newValueIsEmpty && oldValueIsEmpty) {
            ds.kmKeys.push(key);
        }
    }

    /**
     * @notice Internal getter for key value data function
     * @param ds DataStorage struct
     * @param key the key to get
     * @return bytes32 the value of the key
     */
    function getBytes32Value(DataStorage storage ds, bytes32 key) internal view returns(bytes32){
        return ds.keyValueData[key];
    }

    /**
     * @notice Internal getter for key value data function
     * @param ds DataStorage struct
     * @param key the key to get
     * @return bytes the value of the key
     */
    function getBytesValue(DataStorage storage ds, bytes32 key) internal view returns(bytes memory){
        return ds.keyBytesData[key];
    }

    function getSetContainsValue(DataStorage storage ds, bytes32 key, bytes32 value) internal view returns(bool){
        return ds.keySetData[key].contains(value);
    }

    function getSetLength(DataStorage storage ds, bytes32 key) internal view returns(uint256){
        return ds.keySetData[key].length();
    }

    function getSetAllValues(DataStorage storage ds, bytes32 key) internal view returns(bytes32[] memory){
        return ds.keySetData[key]._inner._values;
    }

    function getMapValue(DataStorage storage ds, bytes32 key, bytes32 vKey) internal view returns(bytes32){
        if(ds.keyMapData[key].contains(vKey)){
            return ds.keyMapData[key].get(vKey);
        } else {
            return bytes32(0);
        }
    }

    function getMapLength(DataStorage storage ds, bytes32 key) internal view returns(uint256){
        return ds.keyMapData[key].length();
    }

    function getMapAllEntries(DataStorage storage ds, bytes32 key) internal view returns(bytes32[] memory vKeys, bytes32[] memory vValues){
        EnumerableMapMod.MapEntry[] storage entries = ds.keyMapData[key]._inner._entries;
        vKeys = new bytes32[](entries.length);
        vValues = new bytes32[](entries.length);
        for(uint256 i=0; i<entries.length; i++){
            vKeys[i] = entries[i]._key;
            vValues[i] = entries[i]._value;
        }
    }

    /**
     * @notice Internal Clear DataStorage function
     * @param ds DataStorage struct to clear
     */
    function clear(DataStorage storage ds) internal {
        for(uint256 i = 0; i < ds.kvKeys.length; i++){
            bytes32 key = ds.kvKeys[i];
            delete ds.keyValueData[key];
        }
        delete ds.kvKeys;

        for(uint256 i = 0; i < ds.kbKeys.length; i++){
            bytes32 key = ds.kbKeys[i];
            delete ds.keyBytesData[key];
        }
        delete ds.kbKeys;

        //TODO clear ks and km
    }

    function isEmpty(DataStorage storage ds) internal view returns(bool){
        return (ds.kvKeys.length == 0) && (ds.kbKeys.length == 0) && (ds.ksKeys.length == 0) && (ds.kmKeys.length == 0);
    }

    /**
     * @notice Internal move data function
     * @param from DataStorage struct to move from
     * @param to DataStorage struct to move to, should be empty
     */
    function moveData(DataStorage storage from, DataStorage storage to) internal {
        require(isEmpty(to), "target DataStorage isn't empty");
        moveKVData(from, to);
        moveKBData(from, to);
        moveKSData(from, to);
        moveKMData(from, to);
    }

    /**
     * @notice Internal move keyValueData function
     * @dev we expect to storage to be empty
     * @param from DataStorage struct to move from
     * @param to DataStorage struct to move to
     */
    function moveKVData(DataStorage storage from, DataStorage storage to) private {
        for(uint256 i = 0; i < from.kvKeys.length; i++){
            bytes32 key = from.kvKeys[i];
            to.keyValueData[key] = from.keyValueData[key];
            to.kvKeys.push(key);
            from.keyValueData[key] = 0x00;
        }
        delete from.kvKeys;
    }

    /**
     * @notice Internal move keyBytesData function
     * @dev we expect to storage to be empty
     * @param from DataStorage struct to move from
     * @param to DataStorage struct to move to
     */
    function moveKBData(DataStorage storage from, DataStorage storage to) private {
        for(uint256 i = 0; i < from.kbKeys.length; i++){
            bytes32 key = from.kbKeys[i];
            to.keyBytesData[key] = from.keyBytesData[key];
            to.kvKeys.push(key);
            from.keyBytesData[key] = bytes("");
        }
        delete from.kbKeys;
    }

    /**
     * @notice Internal move keySetData function
     * @dev we expect to storage to be empty
     * @param from DataStorage struct to move from
     * @param to DataStorage struct to move to
     */
    function moveKSData(DataStorage storage from, DataStorage storage to) private {
        for(uint256 i = 0; i < from.ksKeys.length; i++){
            bytes32 key = from.ksKeys[i];
            EnumerableSet.Bytes32Set storage vSetFrom = to.keySetData[key];
            EnumerableSet.Bytes32Set storage vSetTo = to.keySetData[key];
            uint256 j;
            for(j=0; j < vSetFrom.length(); j++){
                bytes32 v = vSetFrom.at(j);
                vSetTo.add(v);
            }
            deleteAllFromEnumerableSet(vSetFrom);
        }
        delete from.ksKeys;
    }

    /**
     * @notice Internal move keyMapData function
     * @dev we expect to storage to be empty
     * @param from DataStorage struct to move from
     * @param to DataStorage struct to move to
     */
    function moveKMData(DataStorage storage from, DataStorage storage to) private {
        for(uint256 i = 0; i < from.kmKeys.length; i++){
            bytes32 key = from.kmKeys[i];
            EnumerableMapMod.Bytes32ToBytes32Map storage vMapFrom = to.keyMapData[key];
            EnumerableMapMod.Bytes32ToBytes32Map storage vMapTo = to.keyMapData[key];
            uint256 j;
            for(j=0; j < vMapFrom.length(); j++){
                (bytes32 vk, bytes32 vv) = vMapFrom.at(j);
                vMapTo.set(vk, vv);
            }
            deleteAllFromEnumerableMap(vMapFrom);
        }
        delete from.kmKeys;
    }

    /**
     * @notice Internal remove key from array function
     * @param arr array to remove from
     * @param key key to remove
     */
    function removeKeyFromArray(bytes32[] storage arr, bytes32 key) private {
        uint256 arrLength = arr.length;
        if(arrLength > 1)  {
            uint256 i;
            for(i = 0; i < arrLength; i++) {
                if(arr[i] == key) break;
            }
            //if(i == arrLength) return; // key not found
            require(i < arrLength, "Key not found");
            arr[i] = arr[arrLength-1]; // replace key with the last one
        }
        arr.pop();
    }


    function deleteAllFromEnumerableSet(EnumerableSet.Bytes32Set storage set) private {
        EnumerableSet.Set storage innerSet = set._inner;
        for(uint256 i=0; i < innerSet._values.length; i++) {
            bytes32 v = innerSet._values[i];
            delete innerSet._indexes[v];
        }
        delete innerSet._values;
    }

    function deleteAllFromEnumerableMap(EnumerableMapMod.Bytes32ToBytes32Map storage map) private {
        EnumerableMapMod.Map storage innerMap = map._inner;
        for(uint256 i=0; i < innerMap._entries.length; i++) {
            EnumerableMapMod.MapEntry storage me = innerMap._entries[i];
            delete innerMap._indexes[me._key];
        }
        delete innerMap._entries;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Map implementation with enumeration functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 * @dev derived from https://github.com/solidstate-network/solidstate-solidity/blob/master/contracts/utils/EnumerableMap.sol
 */
library EnumerableMapMod {
    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        MapEntry[] _entries;
        // 1-indexed to allow 0 to signify nonexistence
        mapping(bytes32 => uint256) _indexes;
    }

    struct Bytes32ToBytes32Map {
        Map _inner;
    }

    struct AddressToAddressMap {
        Map _inner;
    }

    struct UintToAddressMap {
        Map _inner;
    }

    function at(Bytes32ToBytes32Map storage map, uint256 index)
        internal
        view
        returns (bytes32, bytes32)
    {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (key, value);
    }

    function at(AddressToAddressMap storage map, uint256 index)
        internal
        view
        returns (address, address)
    {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        address addressKey;
        assembly {
            addressKey := mload(add(key, 20))
        }
        return (addressKey, address(uint160(uint256(value))));
    }

    function at(UintToAddressMap storage map, uint256 index)
        internal
        view
        returns (uint256, address)
    {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    function contains(Bytes32ToBytes32Map storage map, bytes32 key)
        internal
        view
        returns (bool)
    {
        return _contains(map._inner, key);
    }

    function contains(AddressToAddressMap storage map, address key)
        internal
        view
        returns (bool)
    {
        return _contains(map._inner, bytes32(uint256(uint160(key))));
    }

    function contains(UintToAddressMap storage map, uint256 key)
        internal
        view
        returns (bool)
    {
        return _contains(map._inner, bytes32(key));
    }

    function length(Bytes32ToBytes32Map storage map)
        internal
        view
        returns (uint256)
    {
        return _length(map._inner);
    }

    function length(AddressToAddressMap storage map)
        internal
        view
        returns (uint256)
    {
        return _length(map._inner);
    }

    function length(UintToAddressMap storage map)
        internal
        view
        returns (uint256)
    {
        return _length(map._inner);
    }

    function get(Bytes32ToBytes32Map storage map, bytes32 key)
        internal
        view
        returns (bytes32)
    {
        return _get(map._inner, key);
    }

    function get(AddressToAddressMap storage map, address key)
        internal
        view
        returns (address)
    {
        return
            address(
                uint160(
                    uint256(_get(map._inner, bytes32(uint256(uint160(key)))))
                )
            );
    }

    function get(UintToAddressMap storage map, uint256 key)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }

    function set(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        bytes32 value
    ) internal returns (bool) {
        return _set(map._inner, key, value);
    }

    function set(
        AddressToAddressMap storage map,
        address key,
        address value
    ) internal returns (bool) {
        return
            _set(
                map._inner,
                bytes32(uint256(uint160(key))),
                bytes32(uint256(uint160(value)))
            );
    }

    function set(
        UintToAddressMap storage map,
        uint256 key,
        address value
    ) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    function remove(Bytes32ToBytes32Map storage map, bytes32 key)
        internal
        returns (bool)
    {
        return _remove(map._inner, key);
    }

    function remove(AddressToAddressMap storage map, address key)
        internal
        returns (bool)
    {
        return _remove(map._inner, bytes32(uint256(uint160(key))));
    }

    function remove(UintToAddressMap storage map, uint256 key)
        internal
        returns (bool)
    {
        return _remove(map._inner, bytes32(key));
    }

    function _at(Map storage map, uint256 index)
        private
        view
        returns (bytes32, bytes32)
    {
        require(
            map._entries.length > index,
            'EnumerableMap: index out of bounds'
        );

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    function _contains(Map storage map, bytes32 key)
        private
        view
        returns (bool)
    {
        return map._indexes[key] != 0;
    }

    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, 'EnumerableMap: nonexistent key');
        unchecked {
            return map._entries[keyIndex - 1]._value;
        }
    }

    function _set(
        Map storage map,
        bytes32 key,
        bytes32 value
    ) private returns (bool) {
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) {
            map._entries.push(MapEntry({ _key: key, _value: value }));
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            unchecked {
                map._entries[keyIndex - 1]._value = value;
            }
            return false;
        }
    }

    function _remove(Map storage map, bytes32 key) private returns (bool) {
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) {
            unchecked {
                MapEntry storage last = map._entries[map._entries.length - 1];

                // move last entry to now-vacant index
                map._entries[keyIndex - 1] = last;
                map._indexes[last._key] = keyIndex;
            }

            // clear last index
            map._entries.pop();
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }
}