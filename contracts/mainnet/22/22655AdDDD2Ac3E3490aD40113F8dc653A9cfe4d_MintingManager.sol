// @author Unstoppable Domains, Inc.
// @date June 16th, 2021

pragma solidity ^0.8.0;

import './cns/IResolver.sol';
import './cns/IMintingController.sol';
import './cns/IURIPrefixController.sol';
import './IMintingManager.sol';
import './IUNSRegistry.sol';
import './metatx/ERC2771Context.sol';
import './roles/MinterRole.sol';
import './utils/Blocklist.sol';
import './utils/Pausable.sol';
import './utils/Strings.sol';

/**
 * @title MintingManager
 * @dev Defines the functions for distribution of Second Level Domains (SLD)s.
 */
contract MintingManager is ERC2771Context, MinterRole, Blocklist, Pausable, IMintingManager {
    using Strings for *;

    string public constant NAME = 'UNS: Minting Manager';
    string public constant VERSION = '0.3.4';

    IUNSRegistry public unsRegistry;
    IMintingController public cnsMintingController;
    IURIPrefixController public cnsURIPrefixController;
    IResolver public cnsResolver;

    /**
     * @dev Mapping TLD `namehash` to TLD label
     *
     * `namehash` = uint256(keccak256(abi.encodePacked(uint256(0x0), keccak256(abi.encodePacked(label)))))
     */
    mapping(uint256 => string) internal _tlds;

    /**
     * @dev The modifier checks domain's tld and label on mint.
     * @param tld should be registered.
     * @param label should not have legacy CNS free domain prefix.
     *      Legacy CNS free domain prefix is 'udtestdev-'.
     *      keccak256('udtestdev-') = 0xb551e0305c8163b812374b8e78b577c77f226f6f10c5ad03e52699578fbc34b8
     */
    modifier onlyAllowed(uint256 tld, string memory label) {
        require(_isTld(tld), 'MintingManager: TLD_NOT_REGISTERED');
        Strings.Slice memory _label = label.toSlice();
        if(_label._len > 10) {
            require(
                _label.slice(0, 10).keccak() != 0xb551e0305c8163b812374b8e78b577c77f226f6f10c5ad03e52699578fbc34b8,
                'MintingManager: TOKEN_LABEL_PROHIBITED'
            );
        }
        _;
    }

    function initialize(
        IUNSRegistry unsRegistry_,
        IMintingController cnsMintingController_,
        IURIPrefixController cnsURIPrefixController_,
        IResolver cnsResolver_,
        address forwarder
    ) public initializer {
        unsRegistry = unsRegistry_;
        cnsMintingController = cnsMintingController_;
        cnsURIPrefixController = cnsURIPrefixController_;
        cnsResolver = cnsResolver_;

        __Ownable_init_unchained();
        __MinterRole_init_unchained();
        __ERC2771Context_init_unchained(forwarder);
        __Blocklist_init_unchained();
        __Pausable_init_unchained();

        string[11] memory tlds = [
            'crypto',
            'wallet',
            'x',
            'nft',
            'blockchain',
            'bitcoin',
            '888',
            'dao',
            'zil',
            'polygon',
            'unstoppable'
        ];
        for (uint256 i = 0; i < tlds.length; i++) {
            _addTld(tlds[i]);
        }
    }

    function addTld(string calldata tld) external override onlyOwner {
        _addTld(tld);
    }

    function removeTld(uint256 tld) external override onlyOwner {
        require(_isTld(tld), 'MintingManager: TLD_NOT_REGISTERED');

        delete _tlds[tld];
        emit RemoveTld(tld);
    }

    function mintSLD(
        address to,
        uint256 tld,
        string calldata label
    ) external override onlyMinter onlyAllowed(tld, label) whenNotPaused {
        _mintSLD(to, tld, label);
    }

    function safeMintSLD(
        address to,
        uint256 tld,
        string calldata label
    ) external override onlyMinter onlyAllowed(tld, label) whenNotPaused {
        _safeMintSLD(to, tld, label, '');
    }

    function safeMintSLD(
        address to,
        uint256 tld,
        string calldata label,
        bytes calldata data
    ) external override onlyMinter onlyAllowed(tld, label) whenNotPaused {
        _safeMintSLD(to, tld, label, data);
    }

    function mintSLDWithRecords(
        address to,
        uint256 tld,
        string calldata label,
        string[] calldata keys,
        string[] calldata values
    ) external override onlyMinter onlyAllowed(tld, label) whenNotPaused {
        _mintSLDWithRecords(to, tld, label, keys, values);
    }

    function safeMintSLDWithRecords(
        address to,
        uint256 tld,
        string calldata label,
        string[] calldata keys,
        string[] calldata values
    ) external override onlyMinter onlyAllowed(tld, label) whenNotPaused {
        _safeMintSLDWithRecords(to, tld, label, keys, values, '');
    }

    function safeMintSLDWithRecords(
        address to,
        uint256 tld,
        string calldata label,
        string[] calldata keys,
        string[] calldata values,
        bytes calldata data
    ) external override onlyMinter onlyAllowed(tld, label) whenNotPaused {
        _safeMintSLDWithRecords(to, tld, label, keys, values, data);
    }

    function claim(uint256 tld, string calldata label) external override onlyAllowed(tld, label) whenNotPaused {
        _mintSLD(_msgSender(), tld, _freeSLDLabel(label));
    }

    function claimTo(
        address to,
        uint256 tld,
        string calldata label
    ) external override onlyAllowed(tld, label) whenNotPaused {
        _mintSLD(to, tld, _freeSLDLabel(label));
    }

    function claimToWithRecords(
        address to,
        uint256 tld,
        string calldata label,
        string[] calldata keys,
        string[] calldata values
    ) external override onlyAllowed(tld, label) whenNotPaused {
        _mintSLDWithRecords(to, tld, _freeSLDLabel(label), keys, values);
    }

    function setResolver(address resolver) external onlyOwner {
        cnsResolver = IResolver(resolver);
    }

    function setTokenURIPrefix(string calldata prefix) external override onlyOwner {
        unsRegistry.setTokenURIPrefix(prefix);
        if (address(cnsURIPrefixController) != address(0x0)) {
            cnsURIPrefixController.setTokenURIPrefix(prefix);
        }
    }

    function setForwarder(address forwarder) external onlyOwner {
        _setForwarder(forwarder);
    }

    function disableBlocklist() external onlyOwner {
        _disableBlocklist();
    }

    function enableBlocklist() external onlyOwner {
        _enableBlocklist();
    }

    function blocklist(uint256 tokenId) external onlyMinter {
        _block(tokenId);
    }

    function blocklistAll(uint256[] calldata tokenIds) external onlyMinter {
        _blockAll(tokenIds);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function addProxyReaders(address[] calldata addrs) external onlyOwner {
        for(uint256 i = 0; i < addrs.length; i++) {
            unsRegistry.addProxyReader(addrs[i]);
        }
    }

    function upgradeAll(uint256[] calldata tokenIds) external onlyMinter {
        unsRegistry.upgradeAll(tokenIds);
    }

    function _mintSLD(
        address to,
        uint256 tld,
        string memory label
    ) private {
        uint256 tokenId = _childId(tld, label);
        _beforeTokenMint(tokenId);

        if (_useCNS(tld)) {
            cnsMintingController.mintSLDWithResolver(to, label, address(cnsResolver));
        } else {
            unsRegistry.mint(to, tokenId, _uri(tld, label));
        }
    }

    function _safeMintSLD(
        address to,
        uint256 tld,
        string calldata label,
        bytes memory data
    ) private {
        uint256 tokenId = _childId(tld, label);
        _beforeTokenMint(tokenId);

        if (_useCNS(tld)) {
            cnsMintingController.safeMintSLDWithResolver(to, label, address(cnsResolver), data);
        } else {
            unsRegistry.safeMint(to, tokenId, _uri(tld, label), data);
        }
    }

    function _mintSLDWithRecords(
        address to,
        uint256 tld,
        string memory label,
        string[] calldata keys,
        string[] calldata values
    ) private {
        uint256 tokenId = _childId(tld, label);
        _beforeTokenMint(tokenId);

        if (_useCNS(tld)) {
            cnsMintingController.mintSLDWithResolver(to, label, address(cnsResolver));
            if (keys.length > 0) {
                cnsResolver.preconfigure(keys, values, tokenId);
            }
        } else {
            unsRegistry.mintWithRecords(to, tokenId, _uri(tld, label), keys, values);
        }
    }

    function _safeMintSLDWithRecords(
        address to,
        uint256 tld,
        string memory label,
        string[] calldata keys,
        string[] calldata values,
        bytes memory data
    ) private {
        uint256 tokenId = _childId(tld, label);
        _beforeTokenMint(tokenId);

        if (_useCNS(tld)) {
            cnsMintingController.safeMintSLDWithResolver(to, label, address(cnsResolver), data);
            if (keys.length > 0) {
                cnsResolver.preconfigure(keys, values, tokenId);
            }
        } else {
            unsRegistry.safeMintWithRecords(to, tokenId, _uri(tld, label), keys, values, data);
        }
    }

    function _childId(uint256 tokenId, string memory label) internal pure returns (uint256) {
        require(bytes(label).length != 0, 'MintingManager: LABEL_EMPTY');
        return uint256(keccak256(abi.encodePacked(tokenId, keccak256(abi.encodePacked(label)))));
    }

    function _msgSender() internal view override(ContextUpgradeable, ERC2771Context) returns (address) {
        return super._msgSender();
    }

    function _msgData() internal view override(ContextUpgradeable, ERC2771Context) returns (bytes calldata) {
        return super._msgData();
    }

    function _freeSLDLabel(string calldata label) private pure returns (string memory) {
        return string(abi.encodePacked('uns-devtest-', label));
    }

    function _uri(uint256 tld, string memory label) private view returns (string memory) {
        return string(abi.encodePacked(label, '.', _tlds[tld]));
    }

    function _beforeTokenMint(uint256 tokenId) private {
        if (!isBlocklistDisabled()) {
            require(isBlocked(tokenId) == false, 'MintingManager: TOKEN_BLOCKED');
            _block(tokenId);
        }
    }

    /**
     * @dev The function adds TLD and mint token in UNS Registry.
     * Current MintingManager has '.crypto' TLD registered, but UNS Registry does not have '.crypto' token.
     * It leads to revert on mint.
     * The function can be executed in order to mint '.crypto' token in UNS registry, while TLD already registered.
     * Sideffect: It is possible to add the same TLD multiple times, it will burn gas.
     */
    function _addTld(string memory tld) private {
        uint256 tokenId = _childId(uint256(0x0), tld);

        _tlds[tokenId] = tld;
        emit NewTld(tokenId, tld);

        if (!unsRegistry.exists(tokenId)) {
            unsRegistry.mint(address(0xdead), tokenId, tld);
        }
    }

    /**
     * @dev This function checks whether TLD exists
     */
    function _isTld(uint256 tld) private view returns (bool) {
        return bytes(_tlds[tld]).length > 0;
    }

    /**
     * @dev namehash('crypto') = 0x0f4a10a4f46c288cea365fcf45cccf0e9d901b945b9829ccdb54c10dc3cb7a6f
     */
    function _useCNS(uint256 tld) private view returns (bool) {
        return
            address(cnsMintingController) != address(0) &&
            tld == 0x0f4a10a4f46c288cea365fcf45cccf0e9d901b945b9829ccdb54c10dc3cb7a6f;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private __gap;
}

// @author Unstoppable Domains, Inc.
// @date June 16th, 2021

pragma solidity ^0.8.0;

interface IResolver {
    function preconfigure(
        string[] memory keys,
        string[] memory values,
        uint256 tokenId
    ) external;

    function get(string calldata key, uint256 tokenId) external view returns (string memory);

    function getMany(string[] calldata keys, uint256 tokenId) external view returns (string[] memory);

    function getByHash(uint256 keyHash, uint256 tokenId) external view returns (string memory key, string memory value);

    function getManyByHash(uint256[] calldata keyHashes, uint256 tokenId)
        external
        view
        returns (string[] memory keys, string[] memory values);

    function set(
        string calldata key,
        string calldata value,
        uint256 tokenId
    ) external;
}

// @author Unstoppable Domains, Inc.
// @date June 16th, 2021

pragma solidity ^0.8.0;

interface IMintingController {
    function mintSLD(address to, string calldata label) external;

    function safeMintSLD(address to, string calldata label) external;

    function safeMintSLD(
        address to,
        string calldata label,
        bytes calldata data
    ) external;

    function mintSLDWithResolver(
        address to,
        string memory label,
        address resolver
    ) external;

    function safeMintSLDWithResolver(
        address to,
        string calldata label,
        address resolver
    ) external;

    function safeMintSLDWithResolver(
        address to,
        string calldata label,
        address resolver,
        bytes calldata data
    ) external;
}

// @author Unstoppable Domains, Inc.
// @date June 16th, 2021

pragma solidity ^0.8.0;

interface IURIPrefixController {
    function setTokenURIPrefix(string calldata prefix) external;
}

// @author Unstoppable Domains, Inc.
// @date June 16th, 2021

pragma solidity ^0.8.0;

import './IERC1967.sol';

interface IMintingManager is IERC1967 {
    event NewTld(uint256 indexed tokenId, string tld);
    event RemoveTld(uint256 indexed tokenId);

    /**
     * @dev Adds new TLD
     */
    function addTld(string calldata tld) external;

    /**
     * @dev Removes TLD
     */
    function removeTld(uint256 tokenId) external;

    /**
     * @dev Mints a Second Level Domain (SLD).
     * @param to address to mint the new SLD to.
     * @param tld id of parent token.
     * @param label SLD label to mint.
     */
    function mintSLD(
        address to,
        uint256 tld,
        string calldata label
    ) external;

    /**
     * @dev Safely mints a Second Level Domain (SLD).
     * Implements a ERC721Reciever check unlike mintSLD.
     * @param to address to mint the new SLD to.
     * @param tld id of parent token.
     * @param label SLD label to mint.
     */
    function safeMintSLD(
        address to,
        uint256 tld,
        string calldata label
    ) external;

    /**
     * @dev Safely mints a Second Level Domain (SLD).
     * Implements a ERC721Reciever check unlike mintSLD.
     * @param to address to mint the new SLD to.
     * @param tld id of parent token.
     * @param label SLD label to mint.
     * @param data bytes data to send along with a safe transfer check.
     */
    function safeMintSLD(
        address to,
        uint256 tld,
        string calldata label,
        bytes calldata data
    ) external;

    /**
     * @dev Mints a Second Level Domain (SLD) with records.
     * @param to address to mint the new SLD to.
     * @param tld id of parent token.
     * @param label SLD label to mint.
     * @param keys Record keys.
     * @param values Record values.
     */
    function mintSLDWithRecords(
        address to,
        uint256 tld,
        string calldata label,
        string[] calldata keys,
        string[] calldata values
    ) external;

    /**
     * @dev Mints a Second Level Domain (SLD) with records.
     * Implements a ERC721Reciever check unlike mintSLD.
     * @param to address to mint the new SLD to.
     * @param tld id of parent token.
     * @param label SLD label to mint.
     * @param keys Record keys.
     * @param values Record values.
     */
    function safeMintSLDWithRecords(
        address to,
        uint256 tld,
        string calldata label,
        string[] calldata keys,
        string[] calldata values
    ) external;

    /**
     * @dev Mints a Second Level Domain (SLD) with records.
     * Implements a ERC721Reciever check unlike mintSLD.
     * @param to address to mint the new SLD to.
     * @param tld id of parent token.
     * @param label SLD label to mint.
     * @param keys Record keys.
     * @param values Record values.
     * @param data bytes data to send along with a safe transfer check.
     */
    function safeMintSLDWithRecords(
        address to,
        uint256 tld,
        string calldata label,
        string[] calldata keys,
        string[] calldata values,
        bytes calldata data
    ) external;

    /**
     * @dev Claims free domain. The fuction adds prefix to label.
     * @param tld id of parent token
     * @param label SLD label to mint
     */
    function claim(uint256 tld, string calldata label) external;

    /**
     * @dev Claims free domain. The fuction adds prefix to label.
     * @param to address to mint the new SLD to
     * @param tld id of parent token
     * @param label SLD label to mint
     */
    function claimTo(
        address to,
        uint256 tld,
        string calldata label
    ) external;

    /**
     * @dev Claims free domain. The fuction adds prefix to label.
     * @param to address to mint the new SLD to
     * @param tld id of parent token
     * @param label SLD label to mint
     */
    function claimToWithRecords(
        address to,
        uint256 tld,
        string calldata label,
        string[] calldata keys,
        string[] calldata values
    ) external;

    /**
     * @dev Function to set the token URI Prefix for all tokens.
     * @param prefix string URI to assign
     */
    function setTokenURIPrefix(string calldata prefix) external;
}

// @author Unstoppable Domains, Inc.
// @date June 16th, 2021

pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol';

import './IERC1967.sol';
import './IRecordStorage.sol';
import './IReverseRegistry.sol';
import './IRootRegistry.sol';
import './IChildRegistry.sol';

interface IUNSRegistry is
    IERC1967,
    IERC721MetadataUpgradeable,
    IERC721ReceiverUpgradeable,
    IRecordStorage,
    IReverseRegistry,
    IRootRegistry,
    IChildRegistry
{
    event NewURI(uint256 indexed tokenId, string uri);

    event NewURIPrefix(string prefix);

    /**
     * @dev Function to set the token URI Prefix for all tokens.
     * @param prefix string URI to assign
     */
    function setTokenURIPrefix(string calldata prefix) external;

    /**
     * @dev Returns whether the given spender can transfer a given token ID.
     * @param spender address of the spender to query
     * @param tokenId uint256 ID of the token to be transferred
     * @return bool whether the msg.sender is approved for the given token ID,
     * is an operator of the owner, or is the owner of the token
     */
    function isApprovedOrOwner(address spender, uint256 tokenId) external view returns (bool);

    /**
     * @dev Gets the resolver of the specified token ID.
     * @param tokenId uint256 ID of the token to query the resolver of
     * @return address currently marked as the resolver of the given token ID
     */
    function resolverOf(uint256 tokenId) external view returns (address);

    /**
     * @dev Provides child token (subdomain) of provided tokenId.
     * @param tokenId uint256 ID of the token
     * @param label label of subdomain (for `aaa.bbb.crypto` it will be `aaa`)
     */
    function childIdOf(uint256 tokenId, string calldata label) external pure returns (uint256);

    /**
     * @dev Existence of token.
     * @param tokenId uint256 ID of the token
     */
    function exists(uint256 tokenId) external override view returns (bool);

    /**
     * @dev Transfer domain ownership without resetting domain records.
     * @param to address of new domain owner
     * @param tokenId uint256 ID of the token to be transferred
     */
    function setOwner(address to, uint256 tokenId) external;

    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) external;

    /**
     * @dev Mints token.
     * @param to address to mint the new SLD to.
     * @param tokenId id of token.
     * @param uri domain URI.
     */
    function mint(
        address to,
        uint256 tokenId,
        string calldata uri
    ) external;

    /**
     * @dev Safely mints token.
     * Implements a ERC721Reciever check unlike mint.
     * @param to address to mint the new SLD to.
     * @param tokenId id of token.
     * @param uri domain URI.
     */
    function safeMint(
        address to,
        uint256 tokenId,
        string calldata uri
    ) external;

    /**
     * @dev Safely mints token.
     * Implements a ERC721Reciever check unlike mint.
     * @param to address to mint the new SLD to.
     * @param tokenId id of token.
     * @param uri domain URI.
     * @param data bytes data to send along with a safe transfer check
     */
    function safeMint(
        address to,
        uint256 tokenId,
        string calldata uri,
        bytes calldata data
    ) external;

    /**
     * @dev Mints token with records
     * @param to address to mint the new SLD to
     * @param tokenId id of token
     * @param keys New record keys
     * @param values New record values
     * @param uri domain URI
     */
    function mintWithRecords(
        address to,
        uint256 tokenId,
        string calldata uri,
        string[] calldata keys,
        string[] calldata values
    ) external;

    /**
     * @dev Safely mints token with records
     * @param to address to mint the new SLD to
     * @param tokenId id of token
     * @param keys New record keys
     * @param values New record values
     * @param uri domain URI
     */
    function safeMintWithRecords(
        address to,
        uint256 tokenId,
        string calldata uri,
        string[] calldata keys,
        string[] calldata values
    ) external;

    /**
     * @dev Safely mints token with records
     * @param to address to mint the new SLD to
     * @param tokenId id of token
     * @param keys New record keys
     * @param values New record values
     * @param uri domain URI
     * @param data bytes data to send along with a safe transfer check
     */
    function safeMintWithRecords(
        address to,
        uint256 tokenId,
        string calldata uri,
        string[] calldata keys,
        string[] calldata values,
        bytes calldata data
    ) external;

    /**
     * @dev Stores CNS registry address.
     * It's one-time operation required to set CNS registry address.
     * UNS registry allows to receive ERC721 tokens only from CNS registry,
     * by supporting ERC721Receiver interface.
     * @param registry address of CNS registry contract
     */
    function setCNSRegistry(address registry) external;

    /**
     * @dev Adds ProxyReader address
     * @param addr address of ProxyReader
     */
    function addProxyReader(address addr) external;

    /**
     * @dev Marks tokens as upgraded.
     * @param tokenIds[] list of tokenIds to mark upgraded
     */
    function upgradeAll(uint256[] calldata tokenIds) external;
}

// @author Unstoppable Domains, Inc.
// @date August 26th, 2021

pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol';

/**
 * @dev https://eips.ethereum.org/EIPS/eip-2771[EIP 2771] is a standard for native meta transactions.
 *
 * A base contract to be inherited by any contract that want to receive forwarded transactions.
 * The contract designed to be stateless, it supports a scenario when a inherited contract is
 * TrustedForwarder and Recipient at the same time.
 *
 * The contract supports token based nonce, that is why standard calldata extended by tokenId.
 *
 * Forwarded calldata layout: {bytes:data}{address:from}{uint256:tokenId}
 */
abstract contract ERC2771Context is Initializable, ContextUpgradeable {
    // This is the keccak-256 hash of "eip2771.forwarder" subtracted by 1
    bytes32 internal constant _FORWARDER_SLOT = 0x893ef2ea16c023f61d4f55d3e6ee3fc3f2fbfd478461323dbc2fbf919047086e;

    // solhint-disable-next-line func-name-mixedcase
    function __ERC2771Context_init(address forwarder) internal onlyInitializing {
        __Context_init_unchained();
        __ERC2771Context_init_unchained(forwarder);
    }

    // solhint-disable-next-line func-name-mixedcase
    function __ERC2771Context_init_unchained(address forwarder) internal onlyInitializing {
        _setForwarder(forwarder);
    }

    /**
     * @dev Return bool whether provided address is the trusted forwarder.
     */
    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == StorageSlotUpgradeable.getAddressSlot(_FORWARDER_SLOT).value;
    }

    /**
     * @dev Return the tokenId of this call.
     * If the call came through our trusted forwarder, return the original tokenId.
     * otherwise, return zero tokenId.
     */
    function _msgToken() internal view virtual returns (uint256 tokenId) {
        if (isTrustedForwarder(msg.sender)) {
            assembly {
                tokenId := calldataload(sub(calldatasize(), 32))
            }
        }
    }

    /**
     * @dev Return the sender of this call.
     * If the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * Should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 52)))
            }
        } else {
            return super._msgSender();
        }
    }

    /**
     * @dev Return the data of this call.
     * If the call came through our trusted forwarder, return the original data.
     * otherwise, return `msg.data`.
     * Should be used in the contract anywhere instead of msg.data
     */
    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 52];
        } else {
            return super._msgData();
        }
    }

    function _setForwarder(address forwarder) internal virtual {
        StorageSlotUpgradeable.getAddressSlot(_FORWARDER_SLOT).value = forwarder;
    }

    // uint256[50] private __gap;
}

// @author Unstoppable Domains, Inc.
// @date June 16th, 2021

pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';

abstract contract MinterRole is OwnableUpgradeable, AccessControlUpgradeable {
    bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');

    modifier onlyMinter() {
        require(isMinter(_msgSender()), 'MinterRole: CALLER_IS_NOT_MINTER');
        _;
    }

    // solhint-disable-next-line func-name-mixedcase
    function __MinterRole_init() internal onlyInitializing {
        __Ownable_init_unchained();
        __AccessControl_init_unchained();
        __MinterRole_init_unchained();
    }

    // solhint-disable-next-line func-name-mixedcase
    function __MinterRole_init_unchained() internal onlyInitializing {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function transferOwnership(address newOwner) public virtual override onlyOwner {
        super.transferOwnership(newOwner);
        _setupRole(DEFAULT_ADMIN_ROLE, newOwner);
    }

    function isMinter(address account) public view returns (bool) {
        return hasRole(MINTER_ROLE, account);
    }

    function addMinter(address account) public onlyOwner {
        _addMinter(account);
    }

    function addMinters(address[] memory accounts) public onlyOwner {
        for (uint256 index = 0; index < accounts.length; index++) {
            _addMinter(accounts[index]);
        }
    }

    function removeMinter(address account) public onlyOwner {
        _removeMinter(account);
    }

    function removeMinters(address[] memory accounts) public onlyOwner {
        for (uint256 index = 0; index < accounts.length; index++) {
            _removeMinter(accounts[index]);
        }
    }

    function renounceMinter() public {
        renounceRole(MINTER_ROLE, _msgSender());
    }

    /**
     * Renounce minter account with funds' forwarding
     */
    function closeMinter(address payable receiver) external payable onlyMinter {
        require(receiver != address(0x0), 'MinterRole: RECEIVER_IS_EMPTY');

        renounceMinter();
        receiver.transfer(msg.value);
    }

    /**
     * Replace minter account by new account with funds' forwarding
     */
    function rotateMinter(address payable receiver) external payable onlyMinter {
        require(receiver != address(0x0), 'MinterRole: RECEIVER_IS_EMPTY');

        _addMinter(receiver);
        renounceMinter();
        receiver.transfer(msg.value);
    }

    function _addMinter(address account) internal {
        _setupRole(MINTER_ROLE, account);
    }

    function _removeMinter(address account) internal {
        revokeRole(MINTER_ROLE, account);
    }
}

// @author Unstoppable Domains, Inc.
// @date August 30th, 2021

pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol';

/**
 * @dev Mechanism blocks tokens' minting
 */
abstract contract Blocklist is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the `tokenId` added to blocklist.
     */
    event Blocked(uint256 tokenId);

    /**
     * @dev Emitted when the blocklist disabled by `account`.
     */
    event BlocklistDisabled(address account);

    /**
     * @dev Emitted when the blocklist enabled by `account`.
     */
    event BlocklistEnabled(address account);

    // This is the keccak-256 hash of "uns.blocklist." subtracted by 1
    bytes32 internal constant _BLOCKLIST_PREFIX_SLOT =
        0x1ec047073e2c8b15660901dbfdb6e3ff6365bd699dd9f95dcc6eab5448bebd69;

    // This is the keccak-256 hash of "uns.blocklist.disabled" subtracted by 1
    bytes32 internal constant _BLOCKLIST_DISABLED_SLOT =
        0xa85b8425a460dd344a297bd4a82e287385f0fc558cb3e78867b0489f43df2470;

    /**
     * @dev Initializes the blocklist in enabled state.
     */
    function __Blocklist_init() internal onlyInitializing {
        __Context_init_unchained();
        __Blocklist_init_unchained();
    }

    function __Blocklist_init_unchained() internal onlyInitializing {
        StorageSlotUpgradeable.getBooleanSlot(_BLOCKLIST_DISABLED_SLOT).value = false;
    }

    function isBlocklistDisabled() public view returns (bool) {
        return StorageSlotUpgradeable.getBooleanSlot(_BLOCKLIST_DISABLED_SLOT).value;
    }

    function isBlocked(uint256 tokenId) public view returns (bool) {
        return
            !isBlocklistDisabled() &&
            StorageSlotUpgradeable.getBooleanSlot(keccak256(abi.encodePacked(_BLOCKLIST_PREFIX_SLOT, tokenId))).value;
    }

    function areBlocked(uint256[] calldata tokenIds) public view returns (bool[] memory values) {
        values = new bool[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            values[i] = isBlocked(tokenIds[i]);
        }
    }

    /**
     * @dev Modifier to make a function callable only when the blocklist is enabled.
     *
     * Requirements:
     *
     * - The blocklist must be enabled.
     */
    modifier whenEnabled() {
        require(!isBlocklistDisabled(), 'Blocklist: DISABLED');
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the blocklist is disabled.
     *
     * Requirements:
     *
     * - The blocklist must be disabled.
     */
    modifier whenDisabled() {
        require(isBlocklistDisabled(), 'Blocklist: ENABLED');
        _;
    }

    function _block(uint256 tokenId) internal whenEnabled {
        StorageSlotUpgradeable
            .getBooleanSlot(keccak256(abi.encodePacked(_BLOCKLIST_PREFIX_SLOT, tokenId)))
            .value = true;
        emit Blocked(tokenId);
    }

    function _blockAll(uint256[] calldata tokenIds) internal {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _block(tokenIds[i]);
        }
    }

    function _disableBlocklist() internal whenEnabled {
        StorageSlotUpgradeable.getBooleanSlot(_BLOCKLIST_DISABLED_SLOT).value = true;
        emit BlocklistDisabled(_msgSender());
    }

    function _enableBlocklist() internal whenDisabled {
        StorageSlotUpgradeable.getBooleanSlot(_BLOCKLIST_DISABLED_SLOT).value = false;
        emit BlocklistEnabled(_msgSender());
    }
}

// @author Unstoppable Domains, Inc.
// @date September 10th, 2021

pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol';

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    // This is the keccak-256 hash of 'uns.pausable.paused' subtracted by 1
    bytes32 internal constant _PAUSED_SLOT = 0x5496787fc1ebdfeba375028c1865f13fbb1d63c0caa356ccc1b29a80f3ebd622;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        StorageSlotUpgradeable.getBooleanSlot(_PAUSED_SLOT).value = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return StorageSlotUpgradeable.getBooleanSlot(_PAUSED_SLOT).value;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), 'Pausable: PAUSED');
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), 'Pausable: NOT_PAUSED');
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        StorageSlotUpgradeable.getBooleanSlot(_PAUSED_SLOT).value = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        StorageSlotUpgradeable.getBooleanSlot(_PAUSED_SLOT).value = false;
        emit Unpaused(_msgSender());
    }
}

// @author Unstoppable Domains, Inc.
// @date December 22nd, 2021

pragma solidity ^0.8.0;

library Strings {
    struct Slice {
        uint _len;
        uint _ptr;
    }

    /**
     * @dev Returns a slice containing the entire string.
     * @param self The string to make a slice from.
     * @return A newly allocated slice containing the entire string.
     */
    function toSlice(string memory self) internal pure returns (Slice memory) {
        uint ptr;
        /* solium-disable-next-line security/no-inline-assembly */
        assembly { ptr := add(self, 0x20) }
        return Slice(bytes(self).length, ptr);
    }

    /**
     * @dev Returns the keccak-256 hash of the slice.
     * @param self The slice to hash.
     * @return ret The hash of the slice.
     */
    function keccak(Slice memory self) internal pure returns (bytes32 ret) {
        /* solium-disable-next-line security/no-inline-assembly */
        assembly {
            ret := keccak256(mload(add(self, 32)), mload(self))
        }
    }

    /**
     * @dev Returns the slice of the original slice.
     * @param self The slice to hash.
     * @param index The index of original slice for slice ptr.
     * @param len The sub slice length.
     * @return The slice of the original slice.
     */
    function slice(Slice memory self, uint index, uint len) internal pure returns (Slice memory) {
        return Slice(len, self._ptr + index);
    }
}

// @author Unstoppable Domains, Inc.
// @date December 22nd, 2021

pragma solidity ^0.8.0;

interface IERC1967 {
    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// @author Unstoppable Domains, Inc.
// @date June 16th, 2021

pragma solidity ^0.8.0;

import './IRecordReader.sol';

interface IRecordStorage is IRecordReader {
    event Set(uint256 indexed tokenId, string indexed keyIndex, string indexed valueIndex, string key, string value);

    event NewKey(uint256 indexed tokenId, string indexed keyIndex, string key);

    event ResetRecords(uint256 indexed tokenId);

    /**
     * @dev Set record by key
     * @param key The key set the value of
     * @param value The value to set key to
     * @param tokenId ERC-721 token id to set
     */
    function set(
        string calldata key,
        string calldata value,
        uint256 tokenId
    ) external;

    /**
     * @dev Set records by keys
     * @param keys The keys set the values of
     * @param values Records values
     * @param tokenId ERC-721 token id of the domain
     */
    function setMany(
        string[] memory keys,
        string[] memory values,
        uint256 tokenId
    ) external;

    /**
     * @dev Set record by key hash
     * @param keyHash The key hash set the value of
     * @param value The value to set key to
     * @param tokenId ERC-721 token id to set
     */
    function setByHash(
        uint256 keyHash,
        string calldata value,
        uint256 tokenId
    ) external;

    /**
     * @dev Set records by key hashes
     * @param keyHashes The key hashes set the values of
     * @param values Records values
     * @param tokenId ERC-721 token id of the domain
     */
    function setManyByHash(
        uint256[] calldata keyHashes,
        string[] calldata values,
        uint256 tokenId
    ) external;

    /**
     * @dev Reset all domain records and set new ones
     * @param keys New record keys
     * @param values New record values
     * @param tokenId ERC-721 token id of the domain
     */
    function reconfigure(
        string[] memory keys,
        string[] memory values,
        uint256 tokenId
    ) external;

    /**
     * @dev Function to reset all existing records on a domain.
     * @param tokenId ERC-721 token id to set.
     */
    function reset(uint256 tokenId) external;
}

// @author Unstoppable Domains, Inc.
// @date March 29th, 2022

pragma solidity ^0.8.0;

/**
 * @title Reverse registry interface
 */
interface IReverseRegistry {
    /**
     * @dev Emitted when the reverse record is set.
     */
    event SetReverse(address indexed addr, uint256 indexed tokenId);

    /**
     * @dev Emitted when the reverse record is removed.
     */
    event RemoveReverse(address indexed addr);

    /**
     * @dev Sets the reverse record associated with the calling account.
     * @param tokenId The token to set for this address.
     */
    function setReverse(uint256 tokenId) external;

    /**
     * @dev Removes the reverse record associated with the calling account.
     */
    function removeReverse() external;

    /**
     * @dev Returns the reverse record for a given account's reverse record.
     * @param addr The address of the reverse record.
     * @return tokenId The token associated with the address.
     */
    function reverseOf(address addr) external view returns (uint256);
}

// @author Unstoppable Domains, Inc.
// @date December 21st, 2021

pragma solidity ^0.8.0;

import './@maticnetwork/IMintableERC721.sol';

interface IRootRegistry is IMintableERC721 {
    /**
     * @dev Stores RootChainManager address.
     * It's one-time operation required to set RootChainManager address.
     * RootChainManager is a contract responsible for bridging Ethereum
     * and Polygon networks.
     * @param rootChainManager address of RootChainManager contract
     */
    function setRootChainManager(address rootChainManager) external;

    /**
     * @dev Deposits token to Polygon through RootChainManager contract.
     * @param tokenId id of token
     */
    function depositToPolygon(uint256 tokenId) external;

    /**
     * @dev Exit from Polygon through RootChainManager contract.
     *      It withdraws token with records update.
     * @param tokenId id of token
     * @param keys New record keys
     * @param values New record values
     */
    function withdrawFromPolygon(
        bytes calldata inputData,
        uint256 tokenId,
        string[] calldata keys,
        string[] calldata values
    ) external;
}

// @author Unstoppable Domains, Inc.
// @date December 21st, 2021

pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol';

import './@maticnetwork/IChildToken.sol';

interface IChildRegistry is IERC721Upgradeable, IChildToken {
    event WithdrawnBatch(address indexed user, uint256[] tokenIds);

    /**
     * @notice called when user wants to withdraw token back to root chain
     * @dev Should handle withraw by burning user's token.
     * This transaction will be verified when exiting on root chain
     * @param tokenId tokenId to withdraw
     */
    function withdraw(uint256 tokenId) external;

    /**
     * @notice called when user wants to withdraw multiple tokens back to root chain
     * @dev Should burn user's tokens. This transaction will be verified when exiting on root chain
     * @param tokenIds tokenId list to withdraw
     */
    function withdrawBatch(uint256[] calldata tokenIds) external;

    /**
     * @notice called when user wants to withdraw token back to root chain with token URI
     * @dev Should handle withraw by burning user's token.
     * This transaction will be verified when exiting on root chain
     * @param tokenId tokenId to withdraw
     */
    function withdrawWithMetadata(uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
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

// @author Unstoppable Domains, Inc.
// @date June 16th, 2021

pragma solidity ^0.8.0;

interface IRecordReader {
    /**
     * @dev Function to get record.
     * @param key The key to query the value of.
     * @param tokenId The token id to fetch.
     * @return The value string.
     */
    function get(string calldata key, uint256 tokenId) external view returns (string memory);

    /**
     * @dev Function to get multiple record.
     * @param keys The keys to query the value of.
     * @param tokenId The token id to fetch.
     * @return The values.
     */
    function getMany(string[] calldata keys, uint256 tokenId) external view returns (string[] memory);

    /**
     * @dev Function get value by provied key hash.
     * @param keyHash The key to query the value of.
     * @param tokenId The token id to set.
     */
    function getByHash(uint256 keyHash, uint256 tokenId) external view returns (string memory key, string memory value);

    /**
     * @dev Function get values by provied key hashes.
     * @param keyHashes The key to query the value of.
     * @param tokenId The token id to set.
     */
    function getManyByHash(uint256[] calldata keyHashes, uint256 tokenId)
        external
        view
        returns (string[] memory keys, string[] memory values);
}

pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol';

interface IMintableERC721 is IERC721Upgradeable {
    /**
     * @notice called by predicate contract to mint tokens while withdrawing
     * @dev Should be callable only by MintableERC721Predicate
     * Make sure minting is done only by this function
     * @param user user address for whom token is being minted
     * @param tokenId tokenId being minted
     */
    function mint(address user, uint256 tokenId) external;

    /**
     * @notice called by predicate contract to mint tokens while withdrawing with metadata from L2
     * @dev Should be callable only by MintableERC721Predicate
     * Make sure minting is only done either by this function/ 👆
     * @param user user address for whom token is being minted
     * @param tokenId tokenId being minted
     * @param metaData Associated token metadata, to be decoded & set using `setTokenMetadata`
     */
    function mint(address user, uint256 tokenId, bytes calldata metaData) external;

    /**
     * @notice check if token already exists, return true if it does exist
     * @dev this check will be used by the predicate to determine if the token needs to be minted or transfered
     * @param tokenId tokenId being checked
     */
    function exists(uint256 tokenId) external view returns (bool);
}

pragma solidity ^0.8.0;

interface IChildToken {
    /**
     * @notice called when token is deposited on root chain
     * @dev Should be callable only by ChildChainManager
     * Should handle deposit by minting the required tokenId for user
     * Make sure minting is done only by this function
     * @param user user address for whom deposit is being done
     * @param depositData abi encoded tokenId
     */
    function deposit(address user, bytes calldata depositData) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
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
            return "0x00";
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
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}