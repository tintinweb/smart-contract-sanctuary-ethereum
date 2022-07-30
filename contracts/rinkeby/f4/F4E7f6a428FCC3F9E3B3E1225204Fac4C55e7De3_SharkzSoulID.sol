// SPDX-License-Identifier: MIT

/**
       █                                                                        
▐█████▄█ ▀████ █████  ▐████    ████████    ███████████  ████▌  ▄████ ███████████
▐██████ █▄ ▀██ █████  ▐████   ██████████   ████   ████▌ ████▌ ████▀       ████▀ 
  ▀████ ███▄ ▀ █████▄▄▐████  ████ ▐██████  ████▄▄▄████  █████████        ████▀  
▐▄  ▀██ █████▄ █████▀▀▐████ ▄████   ██████ █████████    █████████      ▄████    
▐██▄  █ ██████ █████  ▐█████████▀    ▐█████████ ▀████▄  █████ ▀███▄   █████     
▐████  █▀█████ █████  ▐████████▀        ███████   █████ █████   ████ ███████████
       █                                                                        
                                                                       
 *******************************************************************************
 * Sharkz Soul ID
 *******************************************************************************
 * Creator: Sharkz
 * Author: Jason Hoi
 * Date: 2022-07-29
 *
 */

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../lib/sharkz/ISoulData.sol";
import "../lib/sharkz/vote/IVoteScore.sol";
import "../lib/sharkz/Adminable.sol";
import "../lib/712/EIP712Whitelist.sol";
import "../lib/4973/ERC4973SoulContainer.sol";

interface IBalanceOf {
  function balanceOf(address owner) external view returns (uint256 balance);
}

contract SharkzSoulID is IVoteScore, Adminable, EIP712Whitelist, ERC4973SoulContainer, ReentrancyGuard {
    // Implementation version number
    function version() external pure virtual returns (uint256) { return 1; }
    
    // Emits when new Soul Badge contract is registered
    event BadgeContractLinked(address indexed addr);

    // Emits when existing Soul Badge contract removed
    event BadgeContractUnlinked(address indexed addr);

    // Keep track of total minted token count
    uint256 internal _tokenMinted;

    // Keep track of total destroyed token
    uint256 internal _tokenBurned;

    // Public mint mode, 0 = free-mint, 1 = restrict minting to target token owner
    uint256 internal _publicMintMode;

    // Restricted public mint with target token contract
    address internal _tokenContract;

    // Minting by claim contract
    address internal _claimContract;

    // Token metadata, name prefix
    string internal _metaName;

    // Token metadata, description
    string internal _metaDesc;

    // Compiler will pack the struct into multiple uint256 space
    struct BadgeSetting {
        address contractAddress;
        // limited to 2**80-1 vote score value 
        uint80 voteScore;
        // limited to 2**16 = 255x multiplier
        uint16 scoreMultiplier;
    }

    // Badge contract settings
    BadgeSetting[] public badgeSettings;

    // Link to on-chain data storage
    ISoulData public soulData;

    constructor() 
        ERC4973SoulContainer("Sharkz Soul ID", "SSID") 
        EIP712Whitelist() 
    {
        _metaName = "Sharkz Soul ID #";
        _metaDesc = "Sharkz Soul ID is 100% on-chain generated token based on ERC4973-Soul Container designed by Sharkz Entertainment. Soul ID is the way to join our decentralized governance and allow owner to permanently stores Soul Badges from the ecosystem.";
        // restrict public mint by default
        _publicMintMode = 1;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // See: https://eips.ethereum.org/EIPS/eip-165
        // return true to show proof of supporting following interface, we use bytes4 
        // interface id to avoid importing the whole interface codes.
        return super.supportsInterface(interfaceId) || 
               interfaceId == type(IVoteScore).interfaceId;
    }

    // Setup contract data storage
    function setSoulDataContract(address _contract) 
        external 
        virtual 
        onlyAdmin 
    {
        soulData = ISoulData(_contract);
    }

    // Returns whether badge contract is linked
    function isBadgeContractLinked(address addr) public view virtual returns (bool) {
        for (uint256 i = 0; i < badgeSettings.length; i++) {
          if (addr == badgeSettings[i].contractAddress)
          {
            return true;
          }
        }
        return false;
    }

    // Link/unlink Soul Badge contract
    // Noted that vote score multiplier is limited to the max value from BadgeSetting strcut
    function setBadgeContract(address _contract, uint256 _scoreMultiplier, bool approved) 
        external 
        virtual 
        onlyAdmin 
    {
        bool exists = isBadgeContractLinked(_contract);
        
        // approve = true, adding
        // approve = false, removing
        if (approved) {
            require(!exists, "Adding existing badge contract");

            // target contract should support certain interfaces
            require(soulData.isImplementing(_contract, 0x5b5e139f), "Target contract need to support ERC721Metadata");
            _linkBadgeContract(_contract, _scoreMultiplier);
        } else {
            require(exists, "Removing non-existent badge contract");
            _unlinkBadgeContract(_contract);
        }
    }

    function _badgeSettingIndex(address addr) internal view virtual returns (uint256) {
        for (uint256 i = 0; i < badgeSettings.length; i++) {
            if (addr == badgeSettings[i].contractAddress && addr != address(0)) {
                return i;
            }
        }
        revert("Badge contract index not found");
    }

    // Register a badge contract
    function _linkBadgeContract(address _contract, uint256 _scoreMultiplier) internal virtual {
        BadgeSetting memory object;
        object.contractAddress = _contract;
        object.scoreMultiplier = uint16(_scoreMultiplier);

        if (soulData.isImplementing(_contract, type(IVoteScore).interfaceId)) {
            object.voteScore = uint80(soulData.getSoulBadgeVoteScore(_contract));
        } else {
            object.voteScore = 0;
        }

        badgeSettings.push(object);
        emit BadgeContractLinked(_contract);
    }

    // Remove registration of a badge contract
    function _unlinkBadgeContract(address _contract) internal virtual {
        uint256 total = badgeSettings.length;

        // replace current array element with last element, and pop() remove last element
        if (_contract != badgeSettings[total - 1].contractAddress) {
            uint256 index = _badgeSettingIndex(_contract);
            badgeSettings[index] = badgeSettings[total - 1];
            badgeSettings.pop();
        } else {
            badgeSettings.pop();
        }

        emit BadgeContractUnlinked(_contract);
    }

    // Returns the token voting score
    function _tokenVotingScore(uint256 _tokenId) internal virtual view returns (uint256) {
        // base score for current contract
        uint256 totalScore = voteScore();
      
        // loop through each badge contract to accumulate all vote score (with multiplier)
        BadgeSetting memory badge;
        uint256 badgeBalance;

        for (uint256 i = 0; i < badgeSettings.length; i++) {
            badge = badgeSettings[i];

            // detect if target badge contract is ERC721, interface code 0x80ac58cd
            if (soulData.isImplementing(badge.contractAddress, 0x80ac58cd)) {
                try IBalanceOf(badge.contractAddress).balanceOf(_ownerOf(_tokenId)) returns (uint256 balance) {
                    badgeBalance = balance;
                } catch (bytes memory) {
                    badgeBalance = 0;
                }
                totalScore += badge.scoreMultiplier * badge.voteScore * badgeBalance;
            } else {
                totalScore += badge.scoreMultiplier * badge.voteScore * soulData.getSoulBadgeBalanceForSoul(address(this), _tokenId, badge.contractAddress);
            }
        }

        return totalScore;
    }

    /**
     * @dev See {IVoteScore-voteScore}.
     */
    function voteScore() public pure virtual override returns (uint256) {
        return 1;
    }

    /**
     * @dev See {IVoteScore-voteScoreByToken}.
     */
    function voteScoreByToken(uint256 _tokenId) external view virtual override returns (uint256) {
        if (_exists(_tokenId)) {
          return _tokenVotingScore(_tokenId);
        } else {
          return 0;
        }
    }

    /**
     * @dev See {IVoteScore-voteScoreByAddress}.
     */
    function voteScoreByAddress(address _addr) external view virtual override returns (uint256) {
        if (_addressData[_addr].balance > 0) {
            return _tokenVotingScore(tokenIdOf(_addr));
        } else {
            return 0;
        }
    }

    // Caller must not be an wallet account
    modifier callerIsUser() {
        require(tx.origin == _msgSenderERC4973(), "Caller should not be a contract");
        _;
    }

    // Update token meta data desc
    function setTokenDescription(string calldata _desc) external virtual onlyAdmin {
        _metaDesc = _desc;
    }

    // Update linking ERC721 contract address
    function setMintRestrictContract(address _addr) external virtual onlyAdmin {
        _tokenContract = _addr;
    }

    // Update public mint mode
    function setPublicMintMode(uint256 _mode) external virtual onlyAdmin {
        _publicMintMode = _mode;
    }

    // Update linking claim contract
    function setClaimContract(address _addr) external virtual onlyAdmin {
        _claimContract = _addr;
    }

    // Returns total valid token count
    function totalSupply() public virtual view returns (uint256) {
        return _tokenMinted - _tokenBurned;
    }

    // Create a new token for an address
    function _runMint(address _to) 
        internal 
        virtual 
        nonReentrant 
    {
        // token id starts from index 0
        _mint(_to, _tokenMinted);
        unchecked {
          _tokenMinted += 1;
        }
    }

    // Minting by admin to any address
    function ownerMint(address _to) 
        external 
        virtual 
        onlyAdmin 
    {
        _runMint(_to);
    }

    // Minting from claim contract
    function claimMint(address _to) 
        external 
        virtual 
    {
        require(_claimContract != address(0), "Linked claim contract is not set");
        require(_claimContract == _msgSenderERC4973(), "Caller is not claim contract");
        _runMint(_to);
    }

    // Public minting
    function publicMint() 
        external 
        virtual 
        callerIsUser 
    {
        if (_publicMintMode == 1) {
            require(_tokenContract != address(0), "Invalid token contract address with zero address");
            require(soulData.getERC721Balance(_tokenContract, _msgSenderERC4973()) > 0, "Caller is not a target token owner");
        }
        _runMint(_msgSenderERC4973());
    }

    // Minting with signature from contract EIP712 signer
    function whitelistMint(bytes calldata _signature) 
        external 
        virtual 
        callerIsUser 
        checkWhitelist(_signature) 
    {
        _runMint(_msgSenderERC4973());
    }

    function burn(uint256 _tokenId) public virtual override {
      super.burn(_tokenId);
      unchecked {
          _tokenBurned += 1;
      }
    }

    /**
     * @dev Token SVG image and metadata is 100% on-chain generated.
     */
    function tokenURI(uint256 _tokenId) public virtual view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        // string concatenation is separated into 2 parts to avoid abi.encode with "stack too deep" issue
        string memory partA = string(
            abi.encodePacked(
                'data:application/json;utf8,',
                '{"name":"', _metaName, _toString(_tokenId),
                '","description":"', _metaDesc
            )
        );
        return string(
            abi.encodePacked(
                partA,
                '","image":"data:image/svg+xml;utf8,', soulData.tokenImage(_tokenId, _tokenCreationTime(_tokenId)), '","attributes":[',
                '{"trait_type":"ID","value":"', _toString(_tokenId), '"},',
                '{"trait_type":"Creation Time","value":"', _toString(_tokenCreationTime(_tokenId)), '"},',
                tokenBadgeTraits(_tokenId),
                '{"trait_type":"Vote Score","value":"', _toString(_tokenVotingScore(_tokenId)), '"}]}'
            )
        );
    }

    /**
     * @dev Render `Badge` traits
     * @dev Make sure the registered badge contract `balanceOf()` or 
     * `balanceOfSoul()` gas fee is high, otherwise `tokenURI()` may hit 
     * (read operation) gas limit and become unavailable to public.
     * 
     * Please unlink any badly implemented contract to avoid this situation.
     */
    function tokenBadgeTraits(uint256 _tokenId) public virtual view returns (string memory) {
        string memory output = "";
        address badgeContract;
        address ownerAddress = ownerOf(_tokenId);
        
        for (uint256 badgeIndex = 0; badgeIndex < badgeSettings.length; badgeIndex++) {
            badgeContract = badgeSettings[badgeIndex].contractAddress;
            output = string(abi.encodePacked(output, soulData.getBadgeTrait(badgeContract, badgeIndex, address(this), _tokenId, ownerAddress)));
        }
        return output;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

/**
 *******************************************************************************
 * ISharkzSoulIDData interface
 *******************************************************************************
 * Creator: Sharkz
 * Author: Jason Hoi
 * Date: 2022-07-27
 *
 */

pragma solidity ^0.8.7;

/**
 * @dev Interface of Sharkz external contract data storage
 */
interface ISoulData {
    /**
     * @dev Save/Reset a page of data with a key, max size is 24576 bytes (24KB), 
     * please prepare your data in binary chunks.
     */
    function saveData(string memory key, uint256 pageNumber, bytes memory data) external;

    /**
     * @dev Get all data from all data pages for a key
     */
    function getData(string memory key) external view returns (bytes memory);

    /**
     * @dev Get one page of data chunk
     */
    function getPageData(string memory key, uint256 pageNumber) external view returns (bytes memory);
    
    /**
     * @dev Get svg token image
     */
    function tokenImage(uint256 tokenId, uint256 creationTime) external view returns (string memory);

    /**
     * @dev Try to get external Token collection name
     */
    function getTokenCollectionName(address _contract) external view returns (string memory);

    /**
     * @dev Returns Soul Balance for a Soul Badge contract
     */
    function getSoulBadgeBalanceForSoul(address _soulContract, uint256 _soulTokenId, address _badgeContract) external view returns (uint256);

    /**
     * @dev Returns Soul Badge uint vote score
     */
    function getSoulBadgeVoteScore(address _badgeContract) external pure returns (uint256);

    /**
     * @dev Returns the token metadata trait string for a badge contract (support ERC721 and ERC5114 Soul Badge)
     */
    function getBadgeTrait(address _badgeContract, uint256 _traitIndex, address _soulContract, uint256 _soulTokenId, address _soulTokenOwner) external view returns (string memory);

    /**
     * @dev Returns whether an address is token owner
     */
    function getERC721Balance(address _contract, address _ownerAddress) external view returns (uint256);

    /**
     * @dev Returns whether target contract reported it implementing an interface (based on IERC165)
     */
    function isImplementing(address _contract, bytes4 _interfaceCode) external view returns (bool);

    /** 
     * @dev Converts a `uint256` to ASCII base26 alphabet sequence code
     * For example, 0:A, 1:B 2:C ... 25:Z, 26:AA, 27:AB...
     */
    function toAlphabetCode(uint256 value) external pure returns (string memory);

    /**
     * @dev Converts `uint256` to ASCII `string`
     */
    function toString(uint256 value) external pure returns (string memory ptr);
}

// SPDX-License-Identifier: MIT

/**
 *******************************************************************************
 * IVoteScore interface
 *******************************************************************************
 * Creator: Sharkz
 * Author: Jason Hoi
 * Date: 2022-07-21
 *
 */

pragma solidity ^0.8.7;

/**
 * @dev Interface of voting score, it allows external contract to use the score
 * to calculate voting power.
 */
interface IVoteScore {
    /**
     * @dev Get vote score for each one token (each token get same unit score)
     */
    function voteScore() external pure returns (uint256);

    /**
     * @dev Get vote score for individual `tokenId`
     * This function is needed only when score varies between token ids.
     * In order to accumulate score, try to avoid any revert() if user submitted 
     * non-existent token id or owner address.
     *
     */
    function voteScoreByToken(uint256 tokenId) external view returns (uint256);

    /**
     * @dev Get vote score of an address
     * In order to accumulate score, try to avoid any revert() if user submitted 
     * non-existent token id or owner address.
     *
     */
    function voteScoreByAddress(address addr) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

/**
 *******************************************************************************
 * Adminable access control
 *******************************************************************************
 * Creator: Sharkz
 * Author: Jason Hoi
 * Date: 2022-07-27
 *
 */
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Contract module which provides basic multiple admins access control 
 * mechanism, admins are granted exclusive access to specific functions with the 
 * provided modifier.
 *
 * By default, the contract owner is the first admin.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyAdmin`, which can be applied to your functions to restrict access for  
 * admins only.
 * 
 */
contract Adminable is Context {
    event AdminCreated(address indexed addr);
    event AdminRemoved(address indexed addr);
    event AdminTransfer(address indexed from, address indexed to);

    // Array of admin addresses
    address[] private _admins;

    // add the first admin with contract creator
    constructor() {
        _createAdmin(_msgSender());
    }

    modifier onlyAdmin() {
        require(_msgSender() != address(0), "Adminable: caller is the zero address");

        bool found = false;
        for (uint256 i = 0; i < _admins.length; i++) {
            if (_msgSender() == _admins[i]) {
                found = true;
            }
        }
        require(found, "Adminable: caller is not admin");
        _;
    }

    function isAdmin(address addr) public view virtual onlyAdmin returns (bool) {
        for (uint256 i = 0; i < _admins.length; i++) {
          if (addr == _admins[i])
          {
            return true;
          }
        }
        return false;
    }

    function countAdmin() external view virtual returns (uint256) {
        return _admins.length;
    }

    function getAdmin(uint256 _index) external view virtual onlyAdmin returns (address) {
        return _admins[_index];
    }

    function setAdmin(address to, bool approved) public virtual onlyAdmin {
        bool existingAdmin = isAdmin(to);

        // approve = true, adding
        // approve = false, removing
        if (approved) {
            require(!existingAdmin, "Adminable: add admin for existing admin");
            _createAdmin(to);

        } else {
            // for safety, prevent removing initial admin
            require(to != _admins[0], "Adminable: can not remove initial admin with setAdmin");

            // remove existing admin
            require(existingAdmin, "Adminable: remove non-existent admin");
            uint256 total = _admins.length;

            // replace current array element with last element, and pop() remove last element
            if (to != _admins[total - 1]) {
                _admins[_adminIndex(to)] = _admins[total - 1];
                _admins.pop();
            } else {
                _admins.pop();
            }

            emit AdminRemoved(to);
        }
    }

    function _adminIndex(address addr) internal view virtual returns (uint256) {
        for (uint256 i = 0; i < _admins.length; i++) {
            if (addr == _admins[i] && addr != address(0)) {
                return i;
            }
        }
        revert("Adminable: admin index not found");
    }

    function _createAdmin(address addr) internal virtual {
        _admins.push(addr);
        emit AdminCreated(addr);
    }

    /**
     * @dev Transfers message sender admin account to a new address
     */
    function transferAdmin(address to) public virtual onlyAdmin {
        require(to != address(0), "Adminable: address is the zero address");
        
        _admins[_adminIndex(_msgSender())] = to;
        emit AdminTransfer(_msgSender(), to);
    }

    /**
     * @dev Leaves the contract without admin.
     *
     * NOTE: Renouncing the last admin will leave the contract without any admins,
     * thereby removing any functionality that is only available to admins.
     */
    function renounceLastAdmin() public virtual onlyAdmin {
        require(_admins.length == 1, "Adminable: can not renounce admin when there are more than one admins");

        delete _admins;
        emit AdminRemoved(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

/**                                                                 
 *******************************************************************************
 * EIP 721 whitelist
 *******************************************************************************
 * Author: Jason Hoi
 * Date: 2022-07-23
 *
 */

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../sharkz/Adminable.sol";

contract EIP712Whitelist is Adminable {
    event SetSigner(address indexed sender, address indexed signer);
    
    using ECDSA for bytes32;

    // Verify signature with this signer address
    address public eip712Signer;

    // Domain separator is EIP-712 defined struct to make sure 
    // signature is coming from the this contract in same ETH newtork.
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md#definition-of-domainseparator
    // @MATCHING cliend-side code
    bytes32 public DOMAIN_SEPARATOR;

    // HASH_STRUCT should not contain unnecessary whitespace between each parameters
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md#definition-of-encodetype
    // @MATCHING cliend-side code
    bytes32 public constant HASH_STRUCT = keccak256("Minter(address wallet)");

    constructor() {
        // @MATCHING cliend-side code
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                // @MATCHING cliend-side code
                keccak256(bytes("WhitelistToken")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );

        // initial signer is contract creator
        setSigner(_msgSender());
    }

    function setSigner(address _addr) public onlyAdmin {
        eip712Signer = _addr;

        emit SetSigner(_msgSender(), _addr);
    }

    modifier checkWhitelist(bytes calldata _signature) {
        require(eip712Signer == _recoverSigner(_signature), "EIP712: Invalid Signature");
        _;
    }

    // Verify signature (relating to _msgSender()) comes by correct signer
    function verifySignature(bytes calldata _signature) public view returns (bool) {
        return eip712Signer == _recoverSigner(_signature);
    }

    // Recover the signer address
    function _recoverSigner(bytes calldata _signature) internal view returns (address) {
        require(eip712Signer != address(0), "EIP712: Whitelist not enabled");

        // Verify EIP-712 signature by recreating the data structure
        // that we signed on the client side, and then using that to recover
        // the address that signed the signature for this data.
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(HASH_STRUCT, _msgSender()))
            )
        );
        return digest.recover(_signature);
    }
}

// SPDX-License-Identifier: MIT

/**
 *******************************************************************************
 * ERC4973 Soul Container
 *******************************************************************************
 * Creator: Sharkz
 * Author: Jason Hoi
 * Date: 2022-07-26
 *
 */

pragma solidity ^0.8.7;

import "./IERC4973SoulContainer.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

/**
 * @dev See https://eips.ethereum.org/EIPS/eip-4973
 * @dev Implementation of IERC4973 and the additional IERC4973 Soul Container interface
 * 
 * Please noted that EIP-4973 is a draft proposal by the time of contract design, EIP 
 * final definition can be changed.
 * 
 * This implementation included many features for real-life usage, by including ERC721
 * Metadata extension, we allow NFT platforms to recognize the token name, symbol and token
 * metadata, ex. token image, attributes. By design, ERC721 transfer, operator, and approval 
 * mechanisms are all removed.
 *
 * Access controls applied user roles: token owner, token guardians, admins, public users.
 * 
 * Assumes that the max value for token ID, and guardians numbers are 2**256 (uint256).
 *
 */
contract ERC4973SoulContainer is IERC721Metadata, IERC4973SoulContainer {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     * It is required for NFT platforms to detect token creation.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Token ID and address is 1:1 binding, however, existing token can be renewed or burnt, 
     * releasing old address to be bind to new token ID.
     *
     * Compiler will pack this into a single 256bit word.
     */
    struct AddressData {
        // address token ID
        uint256 tokenId;
        // We use smallest uint8 to record 0 or 1 value
        uint8 balance;
        // Token create time for the single token per address
        uint40 createTimestamp;
        // Keep track of minted token amount, address can mint more token only after 
        // previous token is burnt by token owner
        uint64 numberMinted;
        // Keep track of burnt token amount
        uint64 numberBurned;
        // Keep track of renewal counter for address
        uint80 numberRenewal;
    }

    // Mapping address to address token data
    mapping(address => AddressData) internal _addressData;

    // Renewal request struct
    struct RenewalRequest {
        // Requester address can be token owner or guardians
        address requester;
        // Request created time
        uint40 createTimestamp;
        // Request expiry time
        uint40 expireTimestamp;
        // uint16 leaveover in uint256 struct
    }

    // Mapping token ID to renewal request, only store last request to allow easy override
    mapping(uint256 => RenewalRequest) private _renewalRequest;

    // Mapping request hash key to approver addresses
    mapping(uint256 => mapping(address => bool)) private _renewalApprovers;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping token ID to multiple guardians.
    mapping(uint256 => address[]) private _guardians;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // See: https://eips.ethereum.org/EIPS/eip-165
        // return true to show proof of supporting following interface, we use bytes4 
        // interface id to avoid importing the whole interface codes.
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x5b5e139f || // ERC165 interface ID for ERC721Metadata.
            interfaceId == type(IERC4973).interfaceId ||
            interfaceId == type(IERC4973SoulContainer).interfaceId;
    }

    /**
     * Returns the address unique token creation timestamp
     */
    function _tokenCreationTime(uint256 _tokenId) internal view virtual returns (uint256) {
        return uint256(_addressData[_ownerOf(_tokenId)].createTimestamp);
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view virtual returns (uint256) {
        return uint256(_addressData[owner].numberMinted);
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view virtual returns (uint256) {
        return uint256(_addressData[owner].numberBurned);
    }

    /**
     * @dev See {IERC4973-tokenIdOf}.
     */
    function tokenIdOf(address owner) public view virtual override returns (uint256) {
        require(balanceOf(owner) > 0, "ERC4973SoulContainer: token id query for non-existent owner");
        return uint256(_addressData[owner].tokenId);
    }

    /**
     * @dev See {IERC4973-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC4973SoulContainer: balance query for the zero address");
        return uint256(_addressData[owner].balance);
    }

    // Returns owner address of a token ID
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev See {IERC4973-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC4973SoulContainer: owner query for non-existent token");
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
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation with `baseURI` and the `tokenId`.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) external view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for non-existent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : "";
    }

    /**
     * Returns whether `tokenId` exists.
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * Returns whether the address is either the owner or guardian
     */
    function _isOwnerOrGuardian(address addr, uint256 tokenId) internal view virtual returns (bool) {
        return (addr != address(0) && (addr == _ownerOf(tokenId) || _isGuardian(addr, tokenId)));
    }

    /**
     * Returns guardian index by address for the token
     */
    function _getGuardianIndex(address addr, uint256 tokenId) internal view virtual returns (uint256) {
        for (uint256 i = 0; i < _guardians[tokenId].length; i++) {
            if (addr == _guardians[tokenId][i]) {
                return i;
            }
        }
        revert("ERC4973SoulContainer: guardian index error");
    }

    /**
     * Returns guardian index by address for the token
     */
    function getGuardianIndex(address addr, uint256 tokenId) external view virtual returns (uint256) {
        require(_isOwnerOrGuardian(_msgSenderERC4973(), tokenId), "ERC4973SoulContainer: query from non-owner or guardian");
        return _getGuardianIndex(addr, tokenId);
    }

    /**
     * Returns guardian address by index
     */
    function getGuardianByIndex(uint256 index, uint256 tokenId) external view virtual returns (address) {
        require(_isOwnerOrGuardian(_msgSenderERC4973(), tokenId), "ERC4973SoulContainer: query from non-owner or guardian");
        return _guardians[tokenId][index];
    }

    /**
     * Returns guardian count
     */
    function getGuardianCount(uint256 tokenId) external view virtual returns (uint256) {
        require(_isOwnerOrGuardian(_msgSenderERC4973(), tokenId), "ERC4973SoulContainer: query from non-owner or guardian");
        return _guardians[tokenId].length;
    }

    // Returns whether an address is token guardian
    function _isGuardian(address addr, uint256 tokenId) internal view virtual returns (bool) {
        // we assumpt that each token ID should not contains too many guardians
        for (uint256 i = 0; i < _guardians[tokenId].length; i++) {
            if (addr == _guardians[tokenId][i]) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev See {IERC4973SoulId-isGuardian}.
     */
    function isGuardian(address addr, uint256 tokenId) external view virtual override returns (bool) {
        require(addr != address(0), "ERC4973SoulContainer: guardian is zero address");
        return _isGuardian(addr, tokenId);
    }

    /**
     * @dev See {IERC4973SoulId-setGuardian}.
     */
    function setGuardian(address to, bool approved, uint256 tokenId) external virtual override {
        // access controls
        require(ownerOf(tokenId) == _msgSenderERC4973(), "ERC4973SoulContainer: guardian setup query from non-owner");
        
        require(to != address(0), "ERC4973SoulContainer: guardian setup query for the zero address");
        require(_exists(tokenId), "ERC4973SoulContainer: guardian setup query for non-existent token");
        if (approved) {
            // adding guardian
            require(!_isGuardian(to, tokenId), "ERC4973SoulContainer: guardian already existed");
            _guardians[tokenId].push(to);

        } else {
            // remove guardian
            require(_isGuardian(to, tokenId), "ERC4973SoulContainer: removing non-existent guardian");

            uint256 total = _guardians[tokenId].length;
            if (_guardians[tokenId][total-1] != to) {
                uint256 index = _getGuardianIndex(to, tokenId);
                // replace current value from last array element
                _guardians[tokenId][index] = _guardians[tokenId][total-1];
                // remove last element and shorten the array length
                _guardians[tokenId].pop();
            } else {
                // remove last element and shorten the array length
                _guardians[tokenId].pop();
            }
        }

        emit SetGuardian(to, tokenId, approved);
    }

    /**
     * Returns approver index key for the current token renewal request
     */
    function _approverIndexKey(uint256 tokenId) internal view virtual returns (uint256) {
        uint256 createTime = _renewalRequest[tokenId].createTimestamp;
        return uint256(keccak256(abi.encodePacked(createTime, ":", tokenId)));
    }

    /**
     * Returns approval count for the renewal request
     * Approvers can be token owner or guardians
     */
    function getApprovalCount(uint256 tokenId) public view virtual returns (uint256) {
        uint256 indexKey = _approverIndexKey(tokenId);
        uint256 count = 0;

        // count if token owner approved
        if (_renewalApprovers[indexKey][ownerOf(tokenId)]) {
            count += 1;
        }

        for (uint256 i = 0; i < _guardians[tokenId].length; i++) {
            address guardian = _guardians[tokenId][i];
            if (_renewalApprovers[indexKey][guardian]) {
                count += 1;
            }
        }

        return count;
    }

    /**
     * Returns request approval quorum size (min number of approval needed)
     */
    function getApprovalQuorum(uint256 tokenId) public view virtual returns (uint256) {
        uint256 guardianCount = _guardians[tokenId].length;
        // mininum approvers are 2 (can be 1 token owner plus at least 1 guardian)
        require(guardianCount > 0, "ERC4973SoulContainer: approval quorum require at least 2 approvers");

        uint256 total = 1 + guardianCount;
        uint256 quorum = (total) / 2 + 1;
        return quorum;
    }

    /**
     * Returns whether renew request approved
     *
     * Valid approvers = N = 1 + guardians (1 from token owner)
     * Mininum one guardian is need to build the quorum system.
     *
     * Approval quorum = N / 2 + 1
     * For example: 3 approvers = 2 quorum needed
     *              4 approvers = 3 quorum needed
     *              5 approvers = 3 quorum needed
     *
     * Requirements:
     * - renewal request is not expired
     */
    function isRequestApproved(uint256 tokenId) public view virtual returns (bool) {
        if (getApprovalCount(tokenId) >= getApprovalQuorum(tokenId)) {
          return true;
        } else {
          return false;
        }
    }

    /**
     * Returns whether renew request is expired
     */
    function isRequestExpired(uint256 tokenId) public view virtual returns (bool) {
        uint256 expiry = uint256(_renewalRequest[tokenId].expireTimestamp);
        if (expiry > 0 && expiry <= block.timestamp) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev See {IERC4973SoulId-requestRenew}.
     */
    function requestRenew(uint256 expireTimestamp, uint256 tokenId) external virtual override {
        // access controls
        require(_isOwnerOrGuardian(_msgSenderERC4973(), tokenId), "ERC4973SoulContainer: query from non-owner or guardian");

        _renewalRequest[tokenId].requester = _msgSenderERC4973();
        _renewalRequest[tokenId].expireTimestamp = uint40(expireTimestamp);
        _renewalRequest[tokenId].createTimestamp = uint40(block.timestamp);

        emit RequestRenew(_msgSenderERC4973(), tokenId, expireTimestamp);
    }

    /**
     * @dev See {IERC4973SoulId-approveRenew}.
     */
    function approveRenew(bool approved, uint256 tokenId) external virtual override {
        // access controls
        require(_isOwnerOrGuardian(_msgSenderERC4973(), tokenId), "ERC4973SoulContainer: query from non-owner or guardian");

        // requirements
        require(_exists(tokenId), "ERC4973SoulContainer: approve for non-existent token");
        require(!isRequestExpired(tokenId), "ERC4973SoulContainer: request expired");

        // minimum 2 approvers: approver #1 is owner, approver #2, #3... are guardians
        require(_guardians[tokenId].length > 0, "ERC4973SoulContainer: approval quorum require at least 2 approvers");

        uint256 indexKey = _approverIndexKey(tokenId);
        _renewalApprovers[indexKey][_msgSenderERC4973()] = approved;
        
        emit ApproveRenew(tokenId, approved);
    }

    /**
     * @dev See {IERC4973SoulId-renew}.
     * Emits {Renew} event.
     * Emits {Transfer} event. (to support NFT platforms)
     */
    function renew(address to, uint256 tokenId) external virtual override {
        // access controls
        require(_isOwnerOrGuardian(_msgSenderERC4973(), tokenId), "ERC4973SoulContainer: renew with unauthorized access");
        require(_renewalRequest[tokenId].requester == _msgSenderERC4973(), "ERC4973SoulContainer: renew with invalid requester");

        // requirements
        require(_exists(tokenId), "ERC4973SoulContainer: renew with non-existent token");
        require(!isRequestExpired(tokenId), "ERC4973SoulContainer: renew with expired request");
        require(isRequestApproved(tokenId), "ERC4973SoulContainer: renew with unapproved request");
        require(balanceOf(to) == 0, "ERC4973SoulContainer: renew to existing token address");
        require(to != address(0), "ERC4973SoulContainer: renew to zero address");

        address oldAddr = _ownerOf(tokenId);

        unchecked {
            _burn(tokenId);

            // update new address data
            _addressData[to].tokenId = tokenId;
            _addressData[to].balance = 1;
            _addressData[to].numberRenewal += 1;
            _addressData[to].createTimestamp = uint40(block.timestamp);
            _owners[tokenId] = to;
        }

        emit Renew(to, tokenId);
        emit Transfer(oldAddr, to, tokenId);
    }

    /**
     * @dev Mints `tokenId` to `to` address.
     *
     * Requirements:
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     * - 1:1 mapping of token and address
     *
     * Emits {Attest} event.
     * Emits {Transfer} event. (to support NFT platforms)
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC4973SoulContainer: mint to the zero address");
        require(!_exists(tokenId), "ERC4973SoulContainer: token already minted");
        require(balanceOf(to) == 0, "ERC4973SoulContainer: one token per address");

        // Overflows are incredibly unrealistic.
        // max balance should be only 1
        unchecked {
            _addressData[to].tokenId = tokenId;
            _addressData[to].balance = 1;
            _addressData[to].numberMinted += 1;
            _addressData[to].createTimestamp = uint40(block.timestamp);
            _owners[tokenId] = to;
        }

        emit Attest(to, tokenId);
        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     *
     * Requirements:
     * - `tokenId` must exist.
     * 
     * Access:
     * - `tokenId` owner
     *
     * Emits {Revoke} event.
     * Emits {Transfer} event. (to support NFT platforms)
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = _ownerOf(tokenId);
        
        delete _addressData[owner].balance;
        _addressData[owner].numberBurned += 1;

        // delete will reset all struct variables to 0
        delete _owners[tokenId];
        delete _renewalRequest[tokenId];

        emit Revoke(owner, tokenId);
        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Burns `tokenId`. See {IERC4973-burn}.
     *
     * Access:
     * - `tokenId` owner
     */
    function burn(uint256 tokenId) public virtual override {
        require(ownerOf(tokenId) == _msgSenderERC4973(), "ERC4973SoulContainer: burn from non-owner");

        _burn(tokenId);
    }

    /**
     * @dev Returns the message sender (defaults to `msg.sender`).
     *
     * For GSN compatible contracts, you need to override this function.
     */
    function _msgSenderERC4973() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * Converts `uint256` to ASCII `string`
     */
    function _toString(uint256 value) internal pure returns (string memory ptr) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit),
            // but we allocate 128 bytes to keep the free memory pointer 32-byte word aliged.
            // We will need 1 32-byte word to store the length,
            // and 3 32-byte words to store a maximum of 78 digits. Total: 32 + 3 * 32 = 128.
            ptr := add(mload(0x40), 128)
            // Update the free memory pointer to allocate.
            mstore(0x40, ptr)

            // Cache the end of the memory to calculate the length later.
            let end := ptr

            // We write the string from the rightmost digit to the leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // Costs a bit more than early returning for the zero case,
            // but cheaper in terms of deployment and overall runtime costs.
            for {
                // Initialize and perform the first pass without check.
                let temp := value
                // Move the pointer 1 byte leftwards to point to an empty character slot.
                ptr := sub(ptr, 1)
                // Write the character to the pointer. 48 is the ASCII index of '0'.
                mstore8(ptr, add(48, mod(temp, 10)))
                temp := div(temp, 10)
            } temp {
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
            } {
                // Body of the for loop.
                ptr := sub(ptr, 1)
                mstore8(ptr, add(48, mod(temp, 10)))
            }

            let length := sub(end, ptr)
            // Move the pointer 32 bytes leftwards to make room for the length.
            ptr := sub(ptr, 32)
            // Store the length.
            mstore(ptr, length)
        }
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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

/**
 *******************************************************************************
 * IERC4973 Soul Container interface
 *******************************************************************************
 * Creator: Sharkz
 * Author: Jason Hoi
 * Date: 2022-07-26
 *
 */

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./IERC4973.sol";

/**
 * @dev See https://eips.ethereum.org/EIPS/eip-4973
 * This is additional interface on top of EIP-4973
 */
interface IERC4973SoulContainer is IERC165, IERC4973 {
  /**
   * @dev This emits when any guardian added or removed for a token.
   */
  event SetGuardian(address indexed to, uint256 indexed tokenId, bool approved);

  /**
   * @dev This emits when token owner or guardian request for token renewal.
   */
  event RequestRenew(address indexed from, uint256 indexed tokenId, uint256 expireTimestamp);

  /**
   * @dev This emits when renewal request approved by one address
   */
  event ApproveRenew(uint256 indexed tokenId, bool indexed approved);

  /**
   * @dev This emits when a token is renewed and bind to new address
   */
  event Renew(address indexed to, uint256 indexed tokenId);
  
  /**
   * @dev Returns token id for the address (since it is 1:1 mapping of token and address)
   */
  function tokenIdOf(address owner) external view returns (uint256);

  /**
   * @dev Returns whether an address is guardian of `tokenId`.
   */
  function isGuardian(address addr, uint256 tokenId) external view returns (bool);

  /**
   * @dev Set/remove guardian for `tokenId`.
   *
   * Requirements:
   * - `tokenId` exists
   * - (addition) guardian is not set before
   * - (removal) guardian should be existed
   *
   * Access:
   * - `tokenId` owner
   * 
   * Emits {SetGuardian} event.
   */
  function setGuardian(address to, bool approved, uint256 tokenId) external;

  /**
   * @dev Request for token renewal, to reassign token to new address.
   * It is recommanded to setup non-zero expiry timestamp, zero expiry means the 
   * request can last forever to receive approval.
   *
   * Requirements:
   * - `tokenId` exists
   *
   * Access:
   * - `tokenId` owner
   * - `tokenId` guardian
   *
   * Emits {RequestRenew} event.
   */
  function requestRenew(uint256 expireTimestamp, uint256 tokenId) external;

  /**
   * @dev Approve or cancel approval for a renewal request.
   * Owner or guardian can reset the renewal request by calling requestRenew() again to 
   * reset request approver index key to new value.
   *
   * Valid approvers = N = 1 + guardians (1 from token owner)
   * Mininum one guardian is need to build the quorum system.
   *
   * Approval quorum (> 50%) = N / 2 + 1
   * For example: 3 approvers = 2 quorum needed
   *              4 approvers = 3 quorum needed
   *              5 approvers = 3 quorum needed
   *
   * Requirements:
   * - `tokenId` exists
   * - request not expired
   *
   * Access:
   * - `tokenId` owner
   * - `tokenId` guardian
   *
   * Emits {ApproveRenew} event.
   */
  function approveRenew(bool approved, uint256 tokenId) external;

  /**
   * @dev Renew a token to new address.
   *
   * Renewal process (token can be renewed and bound to new address):
   * 1) Token owner or guardians (in case of the owner lost wallet) create/reset a renewal request
   * 2) Token owner and eacg guardian can approve the request until approval quorum (> 50%) reached
   * 3) Renewal action can be called by request originator to set the new binding address
   *
   * Requirements:
   * - `tokenId` exists
   * - request not expired
   * - request approved
   * - `to` address is not an owner of another token
   * - `to` cannot be the zero address.
   *
   * Access:
   * - `tokenId` owner
   * - `tokenId` guardian
   * - requester of the request
   *
   * Emits {Renew} event.
   */
  function renew(address to, uint256 tokenId) external;
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

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.6;

/// @title Account-bound tokens
/// @dev See https://eips.ethereum.org/EIPS/eip-4973
///  Note: the ERC-165 identifier for this interface is 0x5164cf47.
interface IERC4973 /* is ERC165, ERC721Metadata */ {
  /// @dev This emits when a new token is created and bound to an account by
  /// any mechanism.
  /// Note: For a reliable `from` parameter, retrieve the transaction's
  /// authenticated `from` field.
  event Attest(address indexed to, uint256 indexed tokenId);
  /// @dev This emits when an existing ABT is revoked from an account and
  /// destroyed by any mechanism.
  /// Note: For a reliable `from` parameter, retrieve the transaction's
  /// authenticated `from` field.
  event Revoke(address indexed to, uint256 indexed tokenId);
  /// @notice Count all ABTs assigned to an owner
  /// @dev ABTs assigned to the zero address are considered invalid, and this
  ///  function throws for queries about the zero address.
  /// @param owner An address for whom to query the balance
  /// @return The number of ABTs owned by `owner`, possibly zero
  function balanceOf(address owner) external view returns (uint256);
  /// @notice Find the address bound to an ERC4973 account-bound token
  /// @dev ABTs assigned to zero address are considered invalid, and queries
  ///  about them do throw.
  /// @param tokenId The identifier for an ABT
  /// @return The address of the owner bound to the ABT
  function ownerOf(uint256 tokenId) external view returns (address);
  /// @notice Destroys `tokenId`. At any time, an ABT receiver must be able to
  ///  disassociate themselves from an ABT publicly through calling this
  ///  function.
  /// @dev Must emit a `event Revoke` with the `address to` field pointing to
  ///  the zero address.
  /// @param tokenId The identifier for an ABT
  function burn(uint256 tokenId) external;
}