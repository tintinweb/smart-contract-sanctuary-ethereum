// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./BaseImxNFT.sol";

/**
 * @title Illuvitar
 *
 * @dev Used for minting and store Illuvitars NFTs.
 * @dev inherit BaseImxNFT
 *
 * @author Yuri Fernandes
 */
contract Illuvitar is BaseImxNFT {
    /// @dev Initialize Illuvitar proxy
    function postConstruct(address _imxStarkContract) external initializer {
        // initialize Base IMX NFT
        super._postConstruct("Illuvitar", "ILLUVITAR", _imxStarkContract);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@imtbl/imx-contracts/contracts/IMintable.sol";
import "@imtbl/imx-contracts/contracts/utils/Minting.sol";
import "./RoyalERC721.sol";

/**
 * @title Base IMX NFT.
 *
 * @dev Inherit RoyalERC721
 * @dev Use IMX minting model (IMintable)
 * @dev Contains base functions which can be used in D1sk, Illuvitar and Accessory ERC721 tokens
 *
 * @author Yuri Fernandes
 */
abstract contract BaseImxNFT is RoyalERC721, IMintable {
    /// @dev only imxStarkContract allowed
    modifier onlyImx() {
        require(msg.sender == imxStarkContract, "Caller should be IMX Stark Contract");
        _;
    }

    /// @dev IMX Stark Contract Address
    address imxStarkContract;

    function _postConstruct(
        string memory _name,
        string memory _symbol,
        address _imxStarkContract
    ) internal virtual initializer {
        // initialize D1sk proxy
        super._postConstruct(_name, _symbol);

        // set IMX Stark Contract address
        imxStarkContract = _imxStarkContract;
    }

    /**
     * @dev Implementation of IMX's mintFor function, with no blueprint.
     *
     * @dev Mints a ERC721 token.
     *
     * @param to address to mint the token
     * @param quantity should be equal to 1
     * @param mintingBlob bytes array sent by IMX `"{tokenId}:{blueprint}`
     */
    function mintFor(
        address to,
        uint256 quantity,
        bytes calldata mintingBlob
    ) external override onlyImx {
        require(quantity == 1, "Amount must be 1");
        (uint256 id, ) = Minting.split(mintingBlob);
        _mint(to, id);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IMintable {
    function mintFor(
        address to,
        uint256 quantity,
        bytes calldata mintingBlob
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Bytes.sol";

library Minting {
    // Split the minting blob into token_id and blueprint portions
    // {token_id}:{blueprint}

    function split(bytes calldata blob)
        internal
        pure
        returns (uint256, bytes memory)
    {
        int256 index = Bytes.indexOf(blob, ":", 0);
        require(index >= 0, "Separator must exist");
        // Trim the { and } from the parameters
        uint256 tokenID = Bytes.toUint(blob[1:uint256(index) - 1]);
        uint256 blueprintLength = blob.length - uint256(index) - 3;
        if (blueprintLength == 0) {
            return (tokenID, bytes(""));
        }
        bytes calldata blueprint = blob[uint256(index) + 2:blob.length - 1];
        return (tokenID, blueprint);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interfaces/EIP2981Spec.sol";
import "./UpgradeableERC721.sol";

/**
 * @title Royal ER721
 *
 * @dev Supports EIP-2981 royalties on NFT secondary sales
 *      Supports OpenSea contract metadata royalties
 *      Introduces fake "owner" to support OpenSea collections
 *
 * @author Basil Gorin
 */
abstract contract RoyalERC721 is EIP2981, UpgradeableERC721 {
    /**
     * @notice Address to receive EIP-2981 royalties from secondary sales
     *         see https://eips.ethereum.org/EIPS/eip-2981
     */
    address public royaltyReceiver;

    /**
     * @notice Percentage of token sale price to be used for EIP-2981 royalties from secondary sales
     *         see https://eips.ethereum.org/EIPS/eip-2981
     *
     * @dev Has 2 decimal precision. E.g. a value of 500 would result in a 5% royalty fee
     */
    uint16 public royaltyPercentage; // default OpenSea value is 750

    /**
     * @notice Contract level metadata to define collection name, description, and royalty fees.
     *         see https://docs.opensea.io/docs/contract-level-metadata
     *
     * @dev Should be set by URI manager, empty by default
     */
    string public contractURI;

    /**
     * @dev Empty reserved space in storage. The size of the __gap array is calculated so that
     *      the amount of storage used by a contract always adds up to the 50.
     *      See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     *
     * @dev Note: `owner`, `royaltyReceiver`, `royaltyPercentage`, and `contractURI` occupy
     *      only 3 storage slots (not 4) since `royaltyReceiver` and `royaltyPercentage` fit
     *      into a single storage slot (160 + 16 bits)
     */
    uint256[47] private __gap;

    /**
     * @dev Fired in setContractURI()
     *
     * @param _by an address which executed update
     * @param _value new contractURI value
     */
    event ContractURIUpdated(address indexed _by, string _value);

    /**
     * @dev Fired in setRoyaltyInfo()
     *
     * @param _by an address which executed update
     * @param _receiver new royaltyReceiver value
     * @param _percentage new royaltyPercentage value
     */
    event RoyaltyInfoUpdated(address indexed _by, address indexed _receiver, uint16 _percentage);

    /**
     * @dev Fired in setOwner()
     *
     * @param _by an address which set the new "owner"
     * @param _oldVal previous "owner" address
     * @param _newVal new "owner" address
     */
    event OwnerUpdated(address indexed _by, address indexed _oldVal, address indexed _newVal);

    /**
     * @dev "Constructor replacement" for upgradeable, must be execute immediately after deployment
     *      see https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#initializers
     *
     * @param _name token name (ERC721Metadata)
     * @param _symbol token symbol (ERC721Metadata)
     */
    function _postConstruct(string memory _name, string memory _symbol) internal virtual override initializer {
        // execute all parent initializers in cascade
        UpgradeableERC721._postConstruct(_name, _symbol);

        // contractURI is as an empty string by default (zero-length array)
        // contractURI = "";
    }

    /**
     * @dev Restricted access function which updates the contract URI
     *
     * @param _contractURI new contract URI to set
     */
    function setContractURI(string memory _contractURI) public virtual onlyOwner {
        // update the contract URI
        contractURI = _contractURI;

        // emit an event
        emit ContractURIUpdated(msg.sender, _contractURI);
    }

    /**
     * @notice EIP-2981 function to calculate royalties for sales in secondary marketplaces.
     *         see https://eips.ethereum.org/EIPS/eip-2981
     *
     * @inheritdoc EIP2981
     */
    function royaltyInfo(uint256, uint256 _salePrice)
        public
        view
        virtual
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        // simply calculate the values and return the result
        return (royaltyReceiver, (_salePrice * royaltyPercentage) / 100_00);
    }

    /**
     * @dev Restricted access function which updates the royalty info
     *
     * @param _royaltyReceiver new royalty receiver to set
     * @param _royaltyPercentage new royalty percentage to set
     */
    function setRoyaltyInfo(address _royaltyReceiver, uint16 _royaltyPercentage) public virtual onlyOwner {
        // verify royalty percentage is zero if receiver is also zero
        require(_royaltyReceiver != address(0) || _royaltyPercentage == 0, "invalid receiver");
        // verify royalty percentage doesn't exceed 100%
        require(_royaltyPercentage <= 100_00, "royalty percentage exceeds 100%");

        // update the values
        royaltyReceiver = _royaltyReceiver;
        royaltyPercentage = _royaltyPercentage;

        // emit an event
        emit RoyaltyInfoUpdated(msg.sender, _royaltyReceiver, _royaltyPercentage);
    }

    /**
     * @notice Checks if the address supplied is an "owner" of the smart contract
     *      Note: an "owner" doesn't have any authority on the smart contract and is "nominal"
     *
     * @return true if the caller is the current owner.
     */
    function isOwner(address _addr) public view virtual returns (bool) {
        // just evaluate and return the result
        return _addr == realOwner();
    }

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, UpgradeableERC721)
        returns (bool)
    {
        // construct the interface support from EIP-2981 and super interfaces
        return interfaceId == type(EIP2981).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library Bytes {
    /**
     * @dev Converts a `uint256` to a `string`.
     * via OraclizeAPI - MIT licence
     * https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
     */
    function fromUint(uint256 value) internal pure returns (string memory) {
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
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + (temp % 10)));
            temp /= 10;
        }
        return string(buffer);
    }

    bytes constant alphabet = "0123456789abcdef";

    /**
     * Index Of
     *
     * Locates and returns the position of a character within a string starting
     * from a defined offset
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string acting as the haystack to be
     *              searched
     * @param _value The needle to search for, at present this is currently
     *               limited to one character
     * @param _offset The starting point to start searching from which can start
     *                from 0, but must not exceed the length of the string
     * @return int The position of the needle starting from 0 and returning -1
     *             in the case of no matches found
     */
    function indexOf(
        bytes memory _base,
        string memory _value,
        uint256 _offset
    ) internal pure returns (int256) {
        bytes memory _valueBytes = bytes(_value);

        assert(_valueBytes.length == 1);

        for (uint256 i = _offset; i < _base.length; i++) {
            if (_base[i] == _valueBytes[0]) {
                return int256(i);
            }
        }

        return -1;
    }

    function substring(
        bytes memory strBytes,
        uint256 startIndex,
        uint256 endIndex
    ) internal pure returns (string memory) {
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    function toUint(bytes memory b) internal pure returns (uint256) {
        uint256 result = 0;
        for (uint256 i = 0; i < b.length; i++) {
            uint256 val = uint256(uint8(b[i]));
            if (val >= 48 && val <= 57) {
                // input is 0-9
                result = result * 10 + (val - 48);
            } else {
                // invalid character, expecting integer input
                revert("invalid input, only numbers allowed");
            }
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title EIP-2981: NFT Royalty Standard
 *
 * @notice A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs)
 *      to enable universal support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * @author Zach Burks, James Morgan, Blaine Malone, James Seibel
 */
interface EIP2981 is IERC165 {
    /**
     * @dev ERC165 bytes to add to interface array - set in parent contract
     *      implementing this standard:
     *      bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
     *      bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
     *      _registerInterface(_INTERFACE_ID_ERC2981);
     *
     * @notice Called with the sale price to determine how much royalty
     *      is owed and to whom.
     * @param _tokenId token ID to calculate royalty info for;
     *      the NFT asset queried for royalty information
     * @param _salePrice the price (in any unit, .e.g wei, ERC20 token, et.c.) of the token to be sold;
     *      the sale price of the NFT asset specified by _tokenId
     * @return receiver the royalty receiver, an address of who should be sent the royalty payment
     * @return royaltyAmount royalty amount in the same unit as _salePrice;
     *      the royalty payment amount for _salePrice
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interfaces/ERC721SpecExt.sol";
import "../lib/SafeERC20.sol";
import "../utils/UpgradeableOwnable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";

/**
 * @title Simplified Upgradeable ERC721 Implementation with only Ownable
 *
 * @notice Zeppelin based ERC721 implementation, supporting token enumeration
 *      (ERC721EnumerableUpgradeable) and flexible token URI management (ERC721URIStorageUpgradeable)
 *
 * @dev Based on Zeppelin ERC721EnumerableUpgradeable and ERC721URIStorageUpgradeable with some modifications
 *      to tokenURI function
 *
 * @author Basil Gorin, Yuri Fernandes
 */
abstract contract UpgradeableERC721 is
    MintableERC721,
    BurnableERC721,
    ERC721EnumerableUpgradeable,
    ERC721URIStorageUpgradeable,
    OwnableUpgradeable
{
    // using ERC20.transfer wrapper from OpenZeppelin adopted SafeERC20
    using SafeERC20 for ERC20;

    /**
     * @dev Base URI is used to construct ERC721Metadata.tokenURI as
     *      `base URI + token ID` if token URI is not set (not present in `_tokenURIs` mapping)
     *
     * @dev For example, if base URI is https://api.com/token/, then token #1
     *      will have an URI https://api.com/token/1
     *
     * @dev If token URI is set with `setTokenURI()` it will be returned as is via `tokenURI()`
     */
    string public baseURI;

    /**
     * @dev Empty reserved space in storage. The size of the __gap array is calculated so that
     *      the amount of storage used by a contract always adds up to the 50.
     *      See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;

    /**
     * @dev Fired in _mint() and all the dependent functions like mint(), safeMint()
     *
     * @param _by an address which executed update
     * @param _to an address token was minted to
     * @param _tokenId token ID minted
     */
    event Minted(address indexed _by, address indexed _to, uint256 indexed _tokenId);

    /**
     * @dev Fired in _burn() and all the dependent functions like burn()
     *
     * @param _by an address which executed update
     * @param _from an address token was burnt from
     * @param _tokenId token ID burnt
     */
    event Burnt(address indexed _by, address indexed _from, uint256 indexed _tokenId);

    /**
     * @dev Fired in setBaseURI()
     *
     * @param _by an address which executed update
     * @param oldVal old _baseURI value
     * @param newVal new _baseURI value
     */
    event BaseURIUpdated(address indexed _by, string oldVal, string newVal);

    /**
     * @dev Fired in setTokenURI()
     *
     * @param _by an address which executed update
     * @param tokenId token ID which URI was updated
     * @param oldVal old _baseURI value
     * @param newVal new _baseURI value
     */
    event TokenURIUpdated(address indexed _by, uint256 tokenId, string oldVal, string newVal);

    /**
     * @dev "Constructor replacement" for upgradeable, must be execute immediately after deployment
     *      see https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#initializers
     *
     * @param _name token name (ERC721Metadata)
     * @param _symbol token symbol (ERC721Metadata)
     */
    function _postConstruct(string memory _name, string memory _symbol) internal virtual initializer {
        // execute all parent initializers in cascade
        __ERC721_init(_name, _symbol);
        __ERC721Enumerable_init_unchained();
        __ERC721URIStorage_init_unchained();
        OwnableUpgradeable.__Ownable_init();
    }

    /**
     * @inheritdoc IERC165Upgradeable
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        // calculate based on own and inherited interfaces
        return
            ERC721EnumerableUpgradeable.supportsInterface(interfaceId) ||
            interfaceId == type(MintableERC721).interfaceId ||
            interfaceId == type(BurnableERC721).interfaceId;
    }

    /**
     * @dev Restricted access function which updates base URI used to construct
     *      ERC721Metadata.tokenURI
     *
     * @dev Requires executor to have ROLE_URI_MANAGER permission
     *
     * @param __baseURI new base URI to set
     */
    function setBaseURI(string memory __baseURI) public virtual onlyOwner {
        // emit an event first - to log both old and new values
        emit BaseURIUpdated(msg.sender, baseURI, __baseURI);

        // and update base URI
        baseURI = __baseURI;
    }

    /**
     * @inheritdoc ERC721Upgradeable
     */
    function _baseURI() internal view virtual override returns (string memory) {
        // just return stored public value to support Zeppelin impl
        return baseURI;
    }

    /**
     * @dev Sets the token URI for the token defined by its ID
     *
     * @param _tokenId an ID of the token to set URI for
     * @param _tokenURI token URI to set
     */
    function setTokenURI(uint256 _tokenId, string memory _tokenURI) public virtual onlyOwner {
        // we do not verify token existence: we want to be able to
        // preallocate token URIs before tokens are actually minted

        // emit an event first - to log both old and new values
        emit TokenURIUpdated(msg.sender, _tokenId, "zeppelin", _tokenURI);

        // and update token URI - delegate to ERC721URIStorage
        _setTokenURI(_tokenId, _tokenURI);
    }

    /**
     * @inheritdoc ERC721URIStorageUpgradeable
     */
    function _setTokenURI(uint256 _tokenId, string memory _tokenURI) internal virtual override {
        // delegate to ERC721URIStorage impl
        return super._setTokenURI(_tokenId, _tokenURI);
    }

    /**
     * @inheritdoc ERC721Upgradeable
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        // delegate to ERC721URIStorage impl
        return ERC721URIStorageUpgradeable.tokenURI(_tokenId);
    }

    /**
     * @notice Checks if specified token exists
     *
     * @dev Returns whether the specified token ID has an ownership
     *      information associated with it
     * @param _tokenId ID of the token to query existence for
     * @return whether the token exists (true - exists, false - doesn't exist)
     */
    function exists(uint256 _tokenId) public view virtual override returns (bool) {
        // delegate to super implementation
        return _exists(_tokenId);
    }

    /**
     * @dev Destroys the token with token ID specified
     *
     * @param _tokenId ID of the token to burn
     */
    function burn(uint256 _tokenId) public virtual override {
        // burn token - delegate to `_burn`
        _burn(_tokenId);
    }

    /**
     * @inheritdoc ERC721Upgradeable
     */
    function _mint(address _to, uint256 _tokenId) internal virtual override {
        // delegate to super implementation
        super._mint(_to, _tokenId);

        // emit an additional event to better track who performed the operation
        emit Minted(msg.sender, _to, _tokenId);
    }

    /**
     * @inheritdoc ERC721Upgradeable
     */
    function _burn(uint256 _tokenId) internal virtual override(ERC721Upgradeable, ERC721URIStorageUpgradeable) {
        // read token owner data
        // verifies token exists under the hood
        address _from = ownerOf(_tokenId);

        // verify sender is either token owner, or approved by the token owner to burn tokens
        require(
            msg.sender == _from || msg.sender == getApproved(_tokenId) || isApprovedForAll(_from, msg.sender),
            "access denied"
        );

        // delegate to the super implementation with URI burning
        ERC721URIStorageUpgradeable._burn(_tokenId);

        // emit an additional event to better track who performed the operation
        emit Burnt(msg.sender, _from, _tokenId);
    }

    /**
     * @inheritdoc ERC721Upgradeable
     */
    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        // delegate to ERC721Enumerable impl
        ERC721EnumerableUpgradeable._beforeTokenTransfer(_from, _to, _tokenId);
    }

    /**
     * @dev Restricted access function to rescue accidentally sent ERC20 tokens,
     *      the tokens are rescued via `transfer` function call on the
     *      contract address specified and with the parameters specified:
     *      `_contract.transfer(_to, _value)`
     *
     * @param _contract smart contract address to execute `transfer` function on
     * @param _to to address in `transfer(_to, _value)`
     * @param _value value to transfer in `transfer(_to, _value)`
     */
    function rescueErc20(
        address _contract,
        address _to,
        uint256 _value
    ) public onlyOwner {
        // perform the transfer as requested, without any checks
        ERC20(_contract).safeTransfer(_to, _value);
    }
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
pragma solidity ^0.8.4;

/**
 * @title Mintable ERC721 Extension
 *
 * @notice Defines mint capabilities for ERC721 tokens.
 *      This interface should be treated as a definition of what mintable means for ERC721
 *
 * @author Basil Gorin
 */
interface MintableERC721 {
    /**
     * @notice Checks if specified token exists
     *
     * @dev Returns whether the specified token ID has an ownership
     *      information associated with it
     *
     * @param _tokenId ID of the token to query existence for
     * @return whether the token exists (true - exists, false - doesn't exist)
     */
    function exists(uint256 _tokenId) external view returns (bool);
}

/**
 * @title Batch Mintable ERC721 Extension
 *
 * @notice Defines batch minting capabilities for ERC721 tokens.
 *      This interface should be treated as a definition of what mintable means for ERC721
 *
 * @author Basil Gorin
 */
interface BatchMintable {
    /**
     * @dev Creates new tokens starting with token ID specified
     *      and assigns an ownership `_to` for these tokens
     *
     * @dev Token IDs to be minted: [_tokenId, _tokenId + n)
     *
     * @dev n must be greater or equal 2: `n > 1`
     *
     * @dev Unsafe: doesn't execute `onERC721Received` on the receiver.
     *      Prefer the use of `saveMintBatch` instead of `mintBatch`.
     *
     * @dev Should have a restricted access handled by the implementation
     *
     * @param _to an address to mint tokens to
     * @param _tokenId ID of the first token to mint
     * @param n how many tokens to mint, sequentially increasing the _tokenId
     */
    function mintBatch(
        address _to,
        uint256 _tokenId,
        uint256 n
    ) external;

    /**
     * @dev Creates new tokens starting with token ID specified
     *      and assigns an ownership `_to` for these tokens
     *
     * @dev Token IDs to be minted: [_tokenId, _tokenId + n)
     *
     * @dev n must be greater or equal 2: `n > 1`
     *
     * @dev Checks if `_to` is a smart contract (code size > 0). If so, it calls
     *      `onERC721Received` on `_to` and throws if the return value is not
     *      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
     *
     * @dev Should have a restricted access handled by the implementation
     *
     * @param _to an address to mint token to
     * @param _tokenId ID of the token to mint
     * @param n how many tokens to mint, sequentially increasing the _tokenId
     */
    function safeMintBatch(
        address _to,
        uint256 _tokenId,
        uint256 n
    ) external;

    /**
     * @dev Creates new tokens starting with token ID specified
     *      and assigns an ownership `_to` for these tokens
     *
     * @dev Token IDs to be minted: [_tokenId, _tokenId + n)
     *
     * @dev n must be greater or equal 2: `n > 1`
     *
     * @dev Checks if `_to` is a smart contract (code size > 0). If so, it calls
     *      `onERC721Received` on `_to` and throws if the return value is not
     *      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
     *
     * @dev Should have a restricted access handled by the implementation
     *
     * @param _to an address to mint token to
     * @param _tokenId ID of the token to mint
     * @param n how many tokens to mint, sequentially increasing the _tokenId
     * @param _data additional data with no specified format, sent in call to `_to`
     */
    function safeMintBatch(
        address _to,
        uint256 _tokenId,
        uint256 n,
        bytes memory _data
    ) external;
}

/**
 * @title Burnable ERC721 Extension
 *
 * @notice Defines burn capabilities for ERC721 tokens.
 *      This interface should be treated as a definition of what burnable means for ERC721
 *
 * @author Basil Gorin
 */
interface BurnableERC721 {
    /**
     * @notice Destroys the token with token ID specified
     *
     * @dev Should be accessible publicly by token owners.
     *      May have a restricted access handled by the implementation
     *
     * @param _tokenId ID of the token to burn
     */
    function burn(uint256 _tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interfaces/ERC20Spec.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title SafeERC20 by OpenZeppelin
 *
 * @dev Wrappers around ERC20 operations that throw on failure
 *      (when the token contract returns false).
 *      Tokens that return no value (and instead revert or throw on failure)
 *      are also supported, non-reverting calls are assumed to be successful.
 * @dev To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 *      which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 *
 * @author OpenZeppelin
 */
library SafeERC20 {
    // using Address.functionCall for addresses
    using Address for address;

    /**
     * @dev ERC20.transfer wrapper
     *
     * @param token ERC20 instance
     * @param to ERC20.transfer to
     * @param value ERC20.transfer value
     */
    function safeTransfer(
        ERC20 token,
        address to,
        uint256 value
    ) internal {
        // delegate to `_callOptionalReturn`
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(ERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        // execute function call and get the return data
        bytes memory retData = address(token).functionCall(data, "ERC20 low-level call failed");
        // return data is optional
        if (retData.length > 0) {
            require(abi.decode(retData, (bool)), "ERC20 transfer failed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev Modified Openzeppelin's {OwnableUpgradeable} to allow a fakeOwner to be set
 * for editing OpenSea's collection. Since OpenSea doesn't support that functionality
 * for multisig.
 *
 * @author Yuri Fernandes
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _fakeOwner;
    address private _realOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    event FakeOwnershipTransferred(address indexed previousFakeOwner, address indexed newFakeOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _transferOwnership(_msgSender());
        _transferFakeOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the fake current owner for OpenSea.
     */
    function owner() public view virtual returns (address) {
        return _fakeOwner;
    }

    /**
     * @dev Returns the address of the real current owner.
     */
    function realOwner() public view virtual returns (address) {
        return _realOwner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(realOwner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
     * @dev Set new fake owner to allow collection editing on OpenSea.
     */
    function setFakeOwner(address newFakeOwner) public virtual onlyOwner {
        _transferFakeOwnership(newFakeOwner);
    }

    /**
     * @dev Transfers fake ownership of the contract to a new account (`newFakeOwner`).
     * Internal function without access restriction.
     */
    function _transferFakeOwnership(address newFakeOwner) internal virtual {
        address oldFakeOwner = _fakeOwner;
        _fakeOwner = newFakeOwner;
        emit FakeOwnershipTransferred(oldFakeOwner, newFakeOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _realOwner;
        _realOwner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    uint256[48] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721EnumerableUpgradeable is Initializable, ERC721Upgradeable, IERC721EnumerableUpgradeable {
    function __ERC721Enumerable_init() internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721Enumerable_init_unchained();
    }

    function __ERC721Enumerable_init_unchained() internal onlyInitializing {
    }
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC721Upgradeable) returns (bool) {
        return interfaceId == type(IERC721EnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Upgradeable.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721EnumerableUpgradeable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721Upgradeable.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721Upgradeable.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorageUpgradeable is Initializable, ERC721Upgradeable {
    function __ERC721URIStorage_init() internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721URIStorage_init_unchained();
    }

    function __ERC721URIStorage_init_unchained() internal onlyInitializing {
    }
    using StringsUpgradeable for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title EIP-20: ERC-20 Token Standard
 *
 * @notice The ERC-20 (Ethereum Request for Comments 20), proposed by Fabian Vogelsteller in November 2015,
 *      is a Token Standard that implements an API for tokens within Smart Contracts.
 *
 * @notice It provides functionalities like to transfer tokens from one account to another,
 *      to get the current token balance of an account and also the total supply of the token available on the network.
 *      Besides these it also has some other functionalities like to approve that an amount of
 *      token from an account can be spent by a third party account.
 *
 * @notice If a Smart Contract implements the following methods and events it can be called an ERC-20 Token
 *      Contract and, once deployed, it will be responsible to keep track of the created tokens on Ethereum.
 *
 * @notice See https://ethereum.org/en/developers/docs/standards/tokens/erc-20/
 * @notice See https://eips.ethereum.org/EIPS/eip-20
 */
interface ERC20 {
    /**
     * @dev Fired in transfer(), transferFrom() to indicate that token transfer happened
     *
     * @param from an address tokens were consumed from
     * @param to an address tokens were sent to
     * @param value number of tokens transferred
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Fired in approve() to indicate an approval event happened
     *
     * @param owner an address which granted a permission to transfer
     *      tokens on its behalf
     * @param spender an address which received a permission to transfer
     *      tokens on behalf of the owner `_owner`
     * @param value amount of tokens granted to transfer on behalf
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @return name of the token (ex.: USD Coin)
     */
    // OPTIONAL - This method can be used to improve usability,
    // but interfaces and other contracts MUST NOT expect these values to be present.
    // function name() external view returns (string memory);

    /**
     * @return symbol of the token (ex.: USDC)
     */
    // OPTIONAL - This method can be used to improve usability,
    // but interfaces and other contracts MUST NOT expect these values to be present.
    // function symbol() external view returns (string memory);

    /**
     * @dev Returns the number of decimals used to get its user representation.
     *      For example, if `decimals` equals `2`, a balance of `505` tokens should
     *      be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * @dev Tokens usually opt for a value of 18, imitating the relationship between
     *      Ether and Wei. This is the value {ERC20} uses, unless this function is
     *      overridden;
     *
     * @dev NOTE: This information is only used for _display_ purposes: it in
     *      no way affects any of the arithmetic of the contract, including
     *      {IERC20-balanceOf} and {IERC20-transfer}.
     *
     * @return token decimals
     */
    // OPTIONAL - This method can be used to improve usability,
    // but interfaces and other contracts MUST NOT expect these values to be present.
    // function decimals() external view returns (uint8);

    /**
     * @return the amount of tokens in existence
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of a particular address
     *
     * @param _owner the address to query the the balance for
     * @return balance an amount of tokens owned by the address specified
     */
    function balanceOf(address _owner) external view returns (uint256 balance);

    /**
     * @notice Transfers some tokens to an external address or a smart contract
     *
     * @dev Called by token owner (an address which has a
     *      positive token balance tracked by this smart contract)
     * @dev Throws on any error like
     *      * insufficient token balance or
     *      * incorrect `_to` address:
     *          * zero address or
     *          * self address or
     *          * smart contract which doesn't support ERC20
     *
     * @param _to an address to transfer tokens to,
     *      must be either an external address or a smart contract,
     *      compliant with the ERC20 standard
     * @param _value amount of tokens to be transferred,, zero
     *      value is allowed
     * @return success true on success, throws otherwise
     */
    function transfer(address _to, uint256 _value) external returns (bool success);

    /**
     * @notice Transfers some tokens on behalf of address `_from' (token owner)
     *      to some other address `_to`
     *
     * @dev Called by token owner on his own or approved address,
     *      an address approved earlier by token owner to
     *      transfer some amount of tokens on its behalf
     * @dev Throws on any error like
     *      * insufficient token balance or
     *      * incorrect `_to` address:
     *          * zero address or
     *          * same as `_from` address (self transfer)
     *          * smart contract which doesn't support ERC20
     *
     * @param _from token owner which approved caller (transaction sender)
     *      to transfer `_value` of tokens on its behalf
     * @param _to an address to transfer tokens to,
     *      must be either an external address or a smart contract,
     *      compliant with the ERC20 standard
     * @param _value amount of tokens to be transferred,, zero
     *      value is allowed
     * @return success true on success, throws otherwise
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    /**
     * @notice Approves address called `_spender` to transfer some amount
     *      of tokens on behalf of the owner (transaction sender)
     *
     * @dev Transaction sender must not necessarily own any tokens to grant the permission
     *
     * @param _spender an address approved by the caller (token owner)
     *      to spend some tokens on its behalf
     * @param _value an amount of tokens spender `_spender` is allowed to
     *      transfer on behalf of the token owner
     * @return success true on success, throws otherwise
     */
    function approve(address _spender, uint256 _value) external returns (bool success);

    /**
     * @notice Returns the amount which _spender is still allowed to withdraw from _owner.
     *
     * @dev A function to check an amount of tokens owner approved
     *      to transfer on its behalf by some other address called "spender"
     *
     * @param _owner an address which approves transferring some tokens on its behalf
     * @param _spender an address approved to transfer some tokens on behalf
     * @return remaining an amount of tokens approved address `_spender` can transfer on behalf
     *      of token owner `_owner`
     */
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
        require(isContract(target), "Address: delegate call to non-contract");

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
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
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
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
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