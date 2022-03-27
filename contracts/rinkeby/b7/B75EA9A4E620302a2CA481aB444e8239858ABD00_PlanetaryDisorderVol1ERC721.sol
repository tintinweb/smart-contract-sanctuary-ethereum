/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/// @title: Planetary Disorder (Smart Contract)
/// @author: Mozart Alexander Louis A.k.A prodbymozart.eth
////////////////////////////////////////////////////////////////////////////////
///                                                                          ///
///                                                                          ///
///     _____               _ _                                        _     ///
///    |  __ \             | | |                                      | |    ///
///    | |__) | __ ___   __| | |__  _   _ _ __ ___   ___ ______ _ _ __| |_   ///
///    |  ___/ '__/ _ \ / _` | '_ \| | | | '_ ` _ \ / _ \_  / _` | '__| __|  ///
///    | |   | | | (_) | (_| | |_) | |_| | | | | | | (_) / / (_| | |  | |_   ///
///    |_|   |_|  \___/ \__,_|_.__/ \__, |_| |_| |_|\___/___\__,_|_|   \__|  ///
///                                  __/ |                                   ///
///                                 |___/                                    ///
///                                                                          ///
///                                                                          ///
////////////////////////////////////////////////////////////////////////////////

/// Imports
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./@rarible/royalties/contracts/impl/RoyaltiesV2Impl.sol";
import "./@rarible/royalties/contracts/LibPart.sol";
import "./@rarible/royalties/contracts/LibRoyaltiesV2.sol";
import "./@ERC2981/royalties/contracts/IERC2981.sol";

contract PlanetaryDisorderVol1ErrorCodes {
  uint8 public constant _AT_LEAST_ONE_TOKEN_MUST_BE_MINTED = 0;
  uint8 public constant _MAX_TOKEN_SUPPLY_EXCEEDED = 1;
  uint8 public constant _USER_MINT_AMOUNT_LIMIT_EXCEEDED = 2;
  uint8 public constant _USER_WHITELIST_MINT_AMOUNT_LIMIT_EXCEEDED = 3;
  uint8 public constant _USER_TOKENS_PER_ADDRESS_LIMIT_EXCEEDED = 4;
  uint8 public constant _USER_IS_NOT_WHITELISTED = 5;
  uint8 public constant _NOT_ENOUGH_FUNDS = 6;
  uint8 public constant _ROYALTY_MAX_LIMIT_EXCEEDED = 7;
  uint8 public constant _ROYALTY_PAYMENT_FAILED = 8;
  uint8 public constant _TOKEN_DOES_NOT_EXIST = 9;
  uint8 public constant _WITHDRAWAL_REQUEST_FAILED = 10;
}

/// Custom smart contract for the Planetary Disorder Vol. 1 NFT collection.
/// Contract Features:
///   - 707 maximum token supply.
///   - ERC2981 Royalty standard support
///   - Rarible LibRoyaltiesV2 support
///   - 0.07 ETH mint price (locked, cannot increase)
///   - 0.01 ETH Owner mint cost ETH mint price (locked, cannot decrease)
contract PlanetaryDisorderVol1ERC721 is
  ERC721Enumerable,
  IERC2981,
  Ownable,
  RoyaltiesV2Impl,
  PlanetaryDisorderVol1ErrorCodes
{
  ////////////////////////// Constants //////////////////////////
  /// @dev Quick access for converting uint256 variables to Strings.
  using Strings for uint256;
  using Strings for uint8;

  /// @dev ERC2981 interface id for signifying ERC2981 support.
  bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

  ////////////////////////// Members //////////////////////////
  /// @notice The cost for minting A token on this contract. This value is
  ///         locked and will not increase.
  uint256 public constant txCost = 0.07 ether;

  /// @notice The cost for minting A token on this contract for the owner. This
  ///         value is locked and will not increase.
  uint256 public constant txOwnerCost = 0.01 ether;

  /// @notice The maximum supply of this token, locked and will not increase.
  uint16 public constant txMaxSupply = 707;

  /// @notice Unlocked base uri for the contract assets.
  string public txUnlockedBaseUri;

  /// @notice Placeholder uri for the contract assets.
  string public txPlaceholderUri;

  /// @notice Base extension for the contract assets metadata.
  string public txAssetBaseExtension = ".json";

  /// @notice Restricts each address to a limit of 3 contract tokens. This value
  ///         is locked and will not change.
  uint8 public constant txPerAddressLimit = 3;

  /// @notice Controls whether to contracts assets will be unlocked for access.
  bool public txAssetsLocked = true;

  /// @notice Whitelisted addressed that will be aloud to mint before the public
  ///         mint.
  address[] public txWhitelistedAddresses;

  /// @notice Enables only whitelist members to mint A token.
  bool public txWhitelistMintingOnly = true;

  /// @notice Limits the number to addresses allowed on the whitelist. This is
  ///         the limit whitelisting abuse by owner for spam social media
  ///         promising many whitelist spots.
  uint8 public constant txWhitelistAddressesLimit = 7;

  /// @notice Each whitelist member during the whitelist period is only allowed
  ///         to mint at most x token(s).
  uint8 public constant txWhitelistMintLimit = 1;

  /// @notice Map containing the amount of tokens minted to the address.
  mapping(address => uint256) public txAddressMintedBalance;

  /// @notice The amount of token the owner of this contract can mint for free.
  /// @dev The owner of this contract can mint up to [tokenOwnerFreeMintMaximum]
  ///      token for free (Only paying the gas fees). This is to assure that the
  ///      owner cannot abuse free minting power.
  uint16 public txOwnerFreeMintAmount = 0;
  uint8 public constant txOwnerFreeMintMaximum = 15;

  /// @notice The amount in royalties the owner of this contract is paid for
  ///         each token .mint and resale on marketplaces.
  /// @dev All royalties are calculated using percent bases point (PBP).
  ///      This is initially set to 1000 (or 10%), but can be decreased or
  ///      increased to A maximum of 1500 (or 15%).
  uint16 public txOwnerRoyaltyPercentageBases = 1000;
  uint16 public constant txOwnerRoyaltyMaxPercentageBases = 1500;

  /// @notice The commission address for the developer of this contract.
  /// @dev The current address is resolves to -> prodbymozart.eth (ENS), the
  ///      original developer of the contract. Feel free to remove this or
  ///      change this to another address, but if you keep it the same it is
  ///      super appreciated! :)
  address public txDevCommissionAddress =
    0x3A18f92850047bbc19Cc3DeFba6749675f94aC5C;

  /// @notice Default constructor.
  ///
  /// @param _name Name of the project.
  /// @param _symbol The Symbol of this project.
  /// @param _initialUnlockedBaseUri Initial base uri (likely empty at the
  ///                                start of this project).
  /// @param _initialPlaceholderUri Initial placeholder uri.
  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initialUnlockedBaseUri,
    string memory _initialPlaceholderUri
  ) ERC721(_name, _symbol) {
    setUnlockedBaseUri(_initialUnlockedBaseUri);
    setPlaceholderUri(_initialPlaceholderUri);
  }

  ////////////////////////// Public Functions //////////////////////////

  /// @notice mints A number of tokens based on the  amount given. A
  ///         commission is given to the owner of this contract for minting
  ///         this token.
  /// @param _amount Amount of tokens to mint.
  function mintToken(uint256 _amount) public payable {
    // Run minting checks to assure minting eligibility.
    mintPreRequisites(_amount);

    // Mint tokens in a loop and set royalties for each token.
    uint256 supply = totalSupply();
    for (uint256 i = 1; i <= _amount; i++) {
      uint256 newTokenId = supply + i;
      _safeMint(msg.sender, newTokenId);
      setTokenRoyalties(newTokenId);
      txAddressMintedBalance[msg.sender]++;
    }

    // A commission is given to the owner for every mint of the, the rest is
    // given to the contract.
    (bool success, ) = payable(owner()).call{
      value: calculateRoyaltyPayout(msg.value, txOwnerRoyaltyPercentageBases)
    }("");
    require(success, _ROYALTY_PAYMENT_FAILED.toString());
  }

  /// @notice Checks the contract [tokenWhitelistedAddresses] for the given
  ///         user.
  /// @param _user Address of the user to check.
  /// @return True if user is in the whitelist, Otherwise false.
  function isAddressWhitelisted(address _user) public view returns (bool) {
    for (uint256 i = 0; i < txWhitelistedAddresses.length; i++) {
      if (txWhitelistedAddresses[i] == _user) {
        return true;
      }
    }
    return false;
  }

  /// @notice Retrieves a list of token IDS owned by the given address.
  /// @param _address Address of the user.
  /// @return Amount of token owned by the user.
  function tokensIDsOwnedByUser(address _address)
    public
    view
    returns (uint256[] memory)
  {
    uint256 count = balanceOf(_address);
    uint256[] memory ids = new uint256[](count);

    for (uint256 i; i < count; i++) {
      ids[i] = tokenOfOwnerByIndex(_address, i);
    }

    return ids;
  }

  /// @notice Provides the tokenURI from this contract for the given token.
  ///         The owner has the ability to change the base URI and placeholder
  ///         URI in-case of any issues to fixes on assets.
  /// @param _id Token id for constructing the Uri.
  /// @return A constructed URL
  function tokenURI(uint256 _id)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(_exists(_id), _TOKEN_DOES_NOT_EXIST.toString());

    // Placeholder url for used if assets are currently locked.
    if (txAssetsLocked == true) {
      return txPlaceholderUri;
    }

    // Construct token uri.
    string memory uriBase = _baseURI();
    return
      bytes(uriBase).length > 0
        ? string(
          abi.encodePacked(uriBase, _id.toString(), txAssetBaseExtension)
        )
        : "";
  }

  ///
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721Enumerable, IERC165)
    returns (bool)
  {
    if (interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
      return true;
    }

    if (interfaceId == _INTERFACE_ID_ERC2981) {
      return true;
    }

    return super.supportsInterface(interfaceId);
  }

  ////////////////////////// External Functions //////////////////////////

  /// @notice Retrieves the royalty info for a given token.
  /// @dev This is an override required by the ERC2981 This function utilizes
  ///      the Rarible AbstractRoyalties to apply the same percents for all
  ///      ERC2981 compliant marketplaces, which keeps royalties on all platform
  ///      uniform.
  function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
    external
    view
    override(IERC2981)
    returns (address receiver, uint256 royaltyAmount)
  {
    LibPart.Part[] memory _royalties = royalties[_tokenId];
    if (_royalties.length > 0) {
      LibPart.Part memory lastRoyalty = _royalties[_royalties.length - 1];
      return (lastRoyalty.account, (_salePrice * lastRoyalty.value) / 10000);
    }
    return (address(0), 0);
  }

  ////////////////////////// Internal Functions //////////////////////////

  /// @notice Internal mint function which
  /// @param _amount Amount of tokens to mint.
  function internalMint(uint256 _amount) internal {}

  /// @notice Check all pre-requisites for minting A token. This apples to both
  ///         the owner and all users.
  /// @param _amount Amount of tokens to mint.
  function mintPreRequisites(uint256 _amount) internal {
    require(_amount > 0, _AT_LEAST_ONE_TOKEN_MUST_BE_MINTED.toString());
    require(
      totalSupply() + _amount <= txMaxSupply,
      _MAX_TOKEN_SUPPLY_EXCEEDED.toString()
    );

    // Minting pre-requisites are different for users than the owner
    if (msg.sender != owner()) userMintPreRequisites(_amount);
    else ownerMintPreRequisites(_amount);
  }

  /// @notice Check all pre-requisites for minting A token specific to the
  ///         non-contract owners.
  /// @param _amount Amount of tokens to mint.
  function userMintPreRequisites(uint256 _amount) internal {
    require(
      _amount <= txPerAddressLimit,
      _USER_MINT_AMOUNT_LIMIT_EXCEEDED.toString()
    );
    require(
      txAddressMintedBalance[msg.sender] + _amount <= txPerAddressLimit,
      _USER_TOKENS_PER_ADDRESS_LIMIT_EXCEEDED.toString()
    );

    if (txWhitelistMintingOnly == true) {
      require(
        isAddressWhitelisted(msg.sender),
        _USER_IS_NOT_WHITELISTED.toString()
      );

      require(
        _amount <= txWhitelistMintLimit,
        _USER_WHITELIST_MINT_AMOUNT_LIMIT_EXCEEDED.toString()
      );
    }

    require(msg.value >= txCost * _amount, _NOT_ENOUGH_FUNDS.toString());
  }

  /// @notice Check all pre-requisites for minting A token specific to the
  ///         contract owner.
  /// @param _amount Amount of tokens to mint.
  function ownerMintPreRequisites(uint256 _amount) internal {
    // The owner is able to mint up to [tokenOwnerFreeMintMaximum] for free
    // (only paying gas fees). Once this limit is surpassed, the owner must pay
    // 20% of the token cost.
    if (txOwnerFreeMintAmount + _amount > txOwnerFreeMintMaximum) {
      require(
        msg.value >=
          txOwnerCost *
            ((txOwnerFreeMintAmount + _amount) - txOwnerFreeMintMaximum),
        _NOT_ENOUGH_FUNDS.toString()
      );
      txOwnerFreeMintAmount = txOwnerFreeMintMaximum;
    } else {
      txOwnerFreeMintAmount = txOwnerFreeMintAmount + uint16(_amount);
    }
  }

  /// @notice Sets the royalties amount for the given token id, payable to the
  ///         owner for resales on Marketplaces. This works for:
  ///           - Rarible.
  ///           - Opensea.
  ///           - Mintable.
  ///           - Any ERC2981 Complaint Marketplace.
  /// @param _tokenId Token id to set these royalties on.
  function setTokenRoyalties(uint256 _tokenId) internal {
    LibPart.Part[] memory royalties = new LibPart.Part[](1);
    royalties[0].value = txOwnerRoyaltyPercentageBases;
    royalties[0].account = payable(owner());
    _saveRoyalties(_tokenId, royalties);
  }

  /// @notice Calculates the amount of royalties to payout based on an amount.
  /// @dev This can be tricky at first glance because percentage bases point
  ///      evaluate as such:
  ///         - 1 PBP = 0.01%
  ///         - 100 PBP = 1%
  ///         - 1000 PBP = 10%
  ///         - 10000 PBP = 100%
  /// @param _amount Total amount to calculate royalties on.
  /// @param _percentBasesPoints percentage of royalties in bases points.
  function calculateRoyaltyPayout(uint256 _amount, uint96 _percentBasesPoints)
    internal
    pure
    returns (uint256)
  {
    uint96 basesPointsConvertedToPercent = _percentBasesPoints / 100;
    return (_amount * basesPointsConvertedToPercent) / 100;
  }

  /// @notice Overrides and retrieves the unlocked base uri.
  function _baseURI() internal view virtual override returns (string memory) {
    return txUnlockedBaseUri;
  }

  ////////////////////////// Owner Functions //////////////////////////

  /// @notice Sets a new unlocked base uri.
  /// @param _newUri The new placeholder Uri
  function setUnlockedBaseUri(string memory _newUri) public onlyOwner {
    txUnlockedBaseUri = _newUri;
  }

  /// @notice Sets a new placeholder base uri.
  /// @param _newUri The new placeholder Uri
  function setPlaceholderUri(string memory _newUri) public onlyOwner {
    txPlaceholderUri = _newUri;
  }

  /// @notice Unlocks the contract assets for token owners to view the provided
  ///         assets with the token.
  function unlockAssets() public onlyOwner {
    txAssetsLocked = false;
  }

  /// @notice Sets whitelist only minting state.
  /// @param _enabled Whether whitelist minting only should be enabled or not.
  function setWhitelistMintingOnly(bool _enabled) public onlyOwner {
    txWhitelistMintingOnly = _enabled;
  }

  /// @notice Sets the list of whitelisted addresses that will be able to mint
  ///         before the public mint.
  /// @param _address full list of addresses that will be whitelisted
  function setWhitelistAddresses(address[] calldata _address) public onlyOwner {
    delete txWhitelistedAddresses;
    txWhitelistedAddresses = _address;
  }

  /**
   * @notice Sets the royalty amount of every minted token as well as sets
   *        the new royalty amount for any future minted token.
   * @dev If the owner sets [_percentBasesPoints] to 0 to indicate 0 percent
   *      royalties, then the contract will auto set it to 1 because the
   *      rarible royalties must be positive. 0 = 0.01% though so this is
   *      negligible imo.
   * @param _percentBasesPoints royalty in percent bases points.
   */
  function setAllTokenRoyalties(uint16 _percentBasesPoints) public onlyOwner {
    require(
      _percentBasesPoints <= txOwnerRoyaltyMaxPercentageBases,
      _ROYALTY_MAX_LIMIT_EXCEEDED.toString()
    );

    if (_percentBasesPoints == 0) txOwnerRoyaltyPercentageBases = 1;
    else txOwnerRoyaltyPercentageBases = _percentBasesPoints;

    uint256 supply = totalSupply();
    for (uint256 i = 1; i <= supply; i++) {
      setTokenRoyalties(i);
    }
  }

  /// @notice Withdraws all of the eth on this contract to the owners wallet.
  /// @dev If the developer of this contract is different from the owner, the
  ///      developer (in this case, prodbymozart.eth) receives a royalty payout
  ///      of at least 10% or higher based on the
  ///      [tokenOwnerRoyaltyPercentageBases].
  function withdrawContractEth() public payable onlyOwner {
    if (owner() != txDevCommissionAddress) {
      // Commission 10% of the contract balance to the developer wallet
      uint96 developerCommissionInPercentBasesPoints = 1000;
      (bool developerCommission, ) = payable(txDevCommissionAddress).call{
        value: calculateRoyaltyPayout(
          address(this).balance,
          developerCommissionInPercentBasesPoints
        )
      }("");
      require(developerCommission, _ROYALTY_PAYMENT_FAILED.toString());
    }

    // Pays out the rest of the contract balance to the owners wallet.
    (bool ownerCommission, ) = payable(owner()).call{
      value: address(this).balance
    }("");
    require(ownerCommission, _WITHDRAWAL_REQUEST_FAILED.toString());
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./AbstractRoyalties.sol";
import "../RoyaltiesV2.sol";

contract RoyaltiesV2Impl is AbstractRoyalties, RoyaltiesV2 {
    function getRaribleV2Royalties(uint256 id)
        external
        view
        override
        returns (LibPart.Part[] memory)
    {
        return royalties[id];
    }

    function _onRoyaltiesSet(uint256 _id, LibPart.Part[] memory _royalties)
        internal
        override
    {
        emit RoyaltiesSet(_id, _royalties);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../LibPart.sol";

abstract contract AbstractRoyalties {
  mapping(uint256 => LibPart.Part[]) public royalties;

  function _saveRoyalties(uint256 _id, LibPart.Part[] memory _royalties)
    internal
  {
    for (uint256 i = 0; i < _royalties.length; i++) {
      require(
        _royalties[i].account != address(0x0),
        "Recipient should be present"
      );
      require(_royalties[i].value != 0, "Royalty value should be positive");
      royalties[_id].push(_royalties[i]);
    }
    _onRoyaltiesSet(_id, _royalties);
  }

  function _updateAccount(
    uint256 _id,
    address _from,
    address _to
  ) internal {
    uint256 length = royalties[_id].length;
    for (uint256 i = 0; i < length; i++) {
      if (royalties[_id][i].account == _from) {
        royalties[_id][i].account = payable(address(uint160(_to)));
      }
    }
  }

  function _onRoyaltiesSet(uint256 _id, LibPart.Part[] memory _royalties)
    internal
    virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./LibPart.sol";

interface RoyaltiesV2 {
    event RoyaltiesSet(uint256 tokenId, LibPart.Part[] royalties);

    function getRaribleV2Royalties(uint256 id)
        external
        view
        returns (LibPart.Part[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

library LibRoyaltiesV2 {
    /*
     * bytes4(keccak256('getRoyalties(LibAsset.AssetType)')) == 0x44c74bcc
     */
    bytes4 constant _INTERFACE_ID_ROYALTIES = 0x44c74bcc;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

library LibPart {
    bytes32 public constant TYPE_HASH =
        keccak256("Part(address account,uint96 value)");

    struct Part {
        address payable account;
        uint96 value;
    }

    function hash(Part memory part) internal pure returns (bytes32) {
        return keccak256(abi.encode(TYPE_HASH, part.account, part.value));
    }
}

// SPDX-License-Identifier: MIT
///
pragma solidity ^0.8.11;
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

///
/// @dev Interface for the NFT Royalty Standard
///
interface IERC2981 is IERC165 {
    /// ERC165 bytes to add to interface array - set in parent contract
    /// implementing this standard
    ///
    /// bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
    /// bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    /// _registerInterface(_INTERFACE_ID_ERC2981);

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _salePrice
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (
        address receiver,
        uint256 royaltyAmount
    );
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
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
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
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
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
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
        uint256 length = ERC721.balanceOf(to);
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

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

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
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
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
        address owner = ERC721.ownerOf(tokenId);
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
        address owner = ERC721.ownerOf(tokenId);
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
        address owner = ERC721.ownerOf(tokenId);

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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
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
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}