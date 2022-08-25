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
 * Sharkz Soul Badge
 *******************************************************************************
 * Creator: Sharkz Entertainment
 * Author: Jason Hoi
 *
 */

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../lib/sharkz/IScore.sol";
import "../lib/sharkz/Adminable.sol";
import "../lib/5114/ERC5114SoulBadge.sol";
import "../lib/712/EIP712Whitelist.sol";

interface IBalanceOf {
    function balanceOf(address owner) external view returns (uint256 balance);
}

interface IVoter {
    // Get voter vote value for a poll
    function getAddressVote(uint256 _pid, address _addr) external view returns (uint256);
}

contract SharkzSoulBadge is IScore, Adminable, ReentrancyGuard, EIP712Whitelist, ERC5114SoulBadge {
    // Keep track of total minted token count
    uint256 public tokenMinted;

    // Keep track of total destroyed token
    uint256 public tokenBurned;

    // Mint modes, 0: disable-minting, 1: free-mint, 2: restrict minting to target token owner, 3: restrict to voter
    uint256 public mintMode;

    // Max mint supply
    uint256 public mintSupply;
    
    // Target token contract for limited minting
    address public tokenContract;

    // Target voting contract for limited minting
    address public voteContract;

    // Target voting poll Id for limited minting
    uint256 public votePollId;

    // Minting by claim contract
    address internal _claimContract;

    // Token image (all token use same image)
    string public tokenImageUri;

    constructor(string memory _name, string memory _symbol, string memory _collectionUri, string memory _tokenImageUri) 
        ERC5114SoulBadge(_name, _symbol, _collectionUri, "") 
        EIP712Whitelist() 
    {
        tokenImageUri = _tokenImageUri;
        // default mint supply 10k
        mintSupply = 10000;
    }

    /**
     * @dev {IERC5114-tokenUri} alias to tokenURI(), so we just override tokenURI()
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Non-existent token");

        string memory output = string(abi.encodePacked(
          '{"name":"', name, ' #', _toString(tokenId), '","image":"', tokenImageUri, '"}'
        ));
        return string(abi.encodePacked("data:application/json;utf8,", output));
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) || 
               interfaceId == type(IScore).interfaceId;
    }

    /**
     * @dev See {IScore-baseScore}.
     */
    function baseScore() public pure virtual override returns (uint256) {
        return 1;
    }

    /**
     * @dev See {IScore-scoreByToken}.
     */
    function scoreByToken(uint256 _tokenId) external view virtual override returns (uint256) {
        if (_exists(_tokenId)) {
          return 1;
        } else {
          return 0;
        }
    }

    /**
     * @dev See {IScore-scoreByAddress}.
     */
    function scoreByAddress(address _addr) external view virtual override returns (uint256) {
        require(_addr != address(0), "Address is the zero address");
        revert("score by address not supported");
    }

    // Caller must not be an wallet account
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Caller should not be a contract");
        _;
    }

    // Caller must be `Soul` token owner
    modifier callerIsSoulOwner(address soulContract, uint256 soulTokenId) {
        require(soulContract != address(0), "Soul contract is the zero address");
        require(msg.sender == _getSoulOwnerAddress(soulContract, soulTokenId), "Caller is not Soul token owner");
        _;
    }

    // Change minting mode
    function setMintMode(uint256 _mode) external virtual onlyAdmin {
        mintMode = _mode;
    }

    // Change mint supply
    function setMintSupply(uint256 _max) external virtual onlyAdmin {
        mintSupply = _max;
    }

    // Update linking IBalanceOf contract address
    function setMintRestrictContract(address _addr) external onlyAdmin {
        tokenContract = _addr;
    }

    // Update linking vote contract and poll Id
    function setMintRestrictVote(address _addr, uint256 _pid) external onlyAdmin {
        voteContract = _addr;
        votePollId = _pid;
    }

    // Update linking claim contract
    function setClaimContract(address _addr) external onlyAdmin {
        _claimContract = _addr;
    }

    // Returns total valid token count
    function totalSupply() public view returns (uint256) {
        return tokenMinted - tokenBurned;
    }

    // Create a new token for Soul
    function _runMint(address soulContract, uint256 soulTokenId) private nonReentrant {
        require(mintMode > 0, 'Minting disabled');
        require(tokenMinted < mintSupply, 'Max minting supply reached');

        // mint to Soul contract and Soul tokenId
        _mint(tokenMinted, soulContract, soulTokenId);
        unchecked {
          tokenMinted += 1;
        }
    }

    // Minting by admin to any address
    function ownerMint(address soulContract, uint256 soulTokenId) 
        external 
        onlyAdmin 
    {
        _runMint(soulContract, soulTokenId);
    }

    // Minting from claim contract
    function claimMint(address soulContract, uint256 soulTokenId) external {
        require(_claimContract != address(0), "Linked claim contract is not set");
        require(_claimContract == msg.sender, "Caller is not claim contract");
        _runMint(soulContract, soulTokenId);
    }

    // Public minting, limited to Soul Token owner
    function publicMint(address soulContract, uint256 soulTokenId) 
        external 
        callerIsUser() 
        callerIsSoulOwner(soulContract, soulTokenId)
    {
        if (mintMode == 2) {
            // target token owner
            require(tokenContract != address(0), "Token contract is the zero address");
            require(_isExternalTokenOwner(tokenContract, msg.sender), "Caller is not target token owner");
        }
        if (mintMode == 3) {
            // target poll voter
            require(voteContract != address(0), "Vote contract is the zero address");
            require(isVoter(voteContract, votePollId, msg.sender), "Caller is not voter");
        }
        _runMint(soulContract, soulTokenId);
    }

    // Minting with signature from contract EIP712 signer, limited to Soul Token owner
    function whitelistMint(bytes calldata _signature, address soulContract, uint256 soulTokenId) 
        external 
        checkWhitelist(_signature) 
        callerIsUser 
        callerIsSoulOwner(soulContract, soulTokenId)
    {
        _runMint(soulContract, soulTokenId);
    }

    function burn(uint256 _tokenId) public override {
      super.burn(_tokenId);
      unchecked {
          tokenBurned += 1;
      }
    }

    /**
     * @dev Returns whether an address is NFT owner
     */
    function _isExternalTokenOwner(address _contract, address _ownerAddress) internal view returns (bool) {
        try IBalanceOf(_contract).balanceOf(_ownerAddress) returns (uint256 balance) {
            return balance > 0;
        } catch (bytes memory) {
          // when reverted, just returns...
          return false;
        }
    }

    /**
     * @dev Returns whether an address is a voter for a poll
     */
    function isVoter(address _contract, uint256 _pid, address _addr) public view returns (bool) {
        try IVoter(_contract).getAddressVote(_pid, _addr) returns (uint256 voteOption) {
            return voteOption > 0;
        } catch (bytes memory) {
          // when reverted, just returns...
          return false;
        }
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
 * IScore interface
 *******************************************************************************
 * Creator: Sharkz Entertainment
 * Author: Jason Hoi
 *
 */

pragma solidity ^0.8.7;

/**
 * @dev Interface of token score, external token contract may accumulate total 
 * score from multiple IScore tokens.
 */
interface IScore {
    /**
     * @dev Get base score for each token (this is the unit score for different
     *  `tokenId` or owner address)
     */
    function baseScore() external view returns (uint256);

    /**
     * @dev Get score for individual `tokenId`
     * This function is needed only when score varies between token ids.
     * In order to accumulate score, try to avoid any revert() if user submitted 
     * non-existent token id or owner address.
     *
     */
    function scoreByToken(uint256 tokenId) external view returns (uint256);

    /**
     * @dev Get score of an address
     * In order to accumulate score, try to avoid any revert() if user submitted 
     * non-existent token id or owner address.
     *
     */
    function scoreByAddress(address addr) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

/**
 *******************************************************************************
 * Adminable access control
 *******************************************************************************
 * Author: Jason Hoi
 *
 */
pragma solidity ^0.8.7;

/**
 * @dev Contract module which provides basic multi-admin access control mechanism,
 * admins are granted exclusive access to specific functions with the provided 
 * modifier.
 *
 * By default, the contract owner is the first admin.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyAdmin`, which can be applied to your functions to restrict access.
 * 
 */
contract Adminable {
    event AdminCreated(address indexed addr);
    event AdminRemoved(address indexed addr);

    // mapping for admin address
    mapping(address => uint256) _admins;

    // add the first admin with contract creator
    constructor() {
        _admins[_msgSenderAdminable()] = 1;
    }

    modifier onlyAdmin() {
        require(isAdmin(_msgSenderAdminable()), "Adminable: caller is not admin");
        _;
    }

    function isAdmin(address addr) public view virtual returns (bool) {
        return _admins[addr] == 1;
    }

    function setAdmin(address to, bool approved) public virtual onlyAdmin {
        require(to != address(0), "Adminable: cannot set admin for the zero address");

        if (approved) {
            require(!isAdmin(to), "Adminable: add existing admin");
            _admins[to] = 1;
            emit AdminCreated(to);
        } else {
            require(isAdmin(to), "Adminable: remove non-existent admin");
            delete _admins[to];
            emit AdminRemoved(to);
        }
    }

    /**
     * @dev Returns the message sender (defaults to `msg.sender`).
     *
     * For GSN compatible contracts, you need to override this function.
     */
    function _msgSenderAdminable() internal view virtual returns (address) {
        return msg.sender;
    }
}

// SPDX-License-Identifier: MIT

/**
 *******************************************************************************
 * ERC5114 Soul Badge
 *******************************************************************************
 * Creator: Sharkz Entertainment
 * Author: Jason Hoi
 *
 */

pragma solidity ^0.8.7;

import "./IERC5114SoulBadge.sol";

interface IOwnerOf {
  function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract ERC5114SoulBadge is IERC5114SoulBadge {
    // Structure to store each Soul token's badges data
    // Compiler will pack this into a single 256bit word.
    struct SoulTokenData {
        // 2**64-1 is more than enough
        // Keep track of final token balance
        uint64 balance;
        // Keep track of minted amount
        uint96 numberMinted;
        // Keeps track of burn count
        uint96 numberBurned;
    }

    // Mapping from `Soul contract, Soul tokenId` to token info
    mapping (address => mapping (uint256 => SoulTokenData)) internal _soulData;

    // Mapping from `badge tokenId` to `Soul contract`
    mapping (uint256 => address) public soulContracts;

    // Mapping from `badge tokenId` to `Soul tokenId`
    mapping (uint256 => uint256) public soulTokens;

    // How many badges can be attached to a `Soul`, zero means unlimited
    uint256 public maxTokenPerSoul;

    // How many badges can be minted from a `Soul`, zero means unlimited
    uint256 public maxMintPerSoul;

    // Token name {IERC5114SoulBadge-name}
    string public name;

    // Token symbol {IERC5114SoulBadge-symbol}
    string public symbol;

    // Immuntable collection uri
    string public collectionInfo;

    // Immuntable token base uri
    string public tokenBaseUri;

    constructor(string memory name_, string memory symbol_, string memory collectionUri_, string memory tokenBaseUri_) {
        name = name_;
        symbol = symbol_;
        collectionInfo = collectionUri_;
        tokenBaseUri = tokenBaseUri_;
        maxTokenPerSoul = 1;
        maxMintPerSoul = 0;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x5b5e139f || // ERC165 interface ID for ERC721Metadata.
            interfaceId == type(IERC5114).interfaceId ||
            interfaceId == type(IERC5114SoulBadge).interfaceId;
    }

    // Returns whether `tokenId` exists.
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return soulContracts[tokenId] != address(0);
    }

    // Returns Soul address and Soul token id
    function _getSoul(uint256 tokenId) internal view virtual returns (address, uint256) {
        address soulContract = soulContracts[tokenId];
        uint256 soulTokenId = soulTokens[tokenId];
        require(soulContract != address(0), "ERC5114SoulBadge: Soul token owner not found");
        return (soulContract, soulTokenId);
    }

    // Returns the current owner address of a `Soul`
    function _getSoulOwnerAddress(address soulContract, uint256 soulTokenId) internal view virtual returns (address) {
        try IOwnerOf(soulContract).ownerOf(soulTokenId) returns (address ownerAddress) {
            if (ownerAddress != address(0)) {
                return ownerAddress;
            } else {
                revert("ERC5114SoulBadge: Soul token owner not found");
            }
        } catch (bytes memory) {
            revert("ERC5114SoulBadge: Soul token owner not found");
        }
    }

    /**
     * @dev See {IERC5114SoulBadge-balanceOfSoul}.
     */
    function balanceOfSoul(address soulContract, uint256 soulTokenId) external view virtual override returns (uint256) {
        require(soulContract != address(0), "ERC5114SoulBadge: balance query for the zero address");
        return _soulData[soulContract][soulTokenId].balance;
    }

    /**
     * @dev See {IERC5114SoulBadge-soulOwnerOf}.
     */
    function soulOwnerOf(uint256 tokenId) public view virtual override returns (address) {
        (address soulContract, uint256 soulTokenId) = _getSoul(tokenId);
        return _getSoulOwnerAddress(soulContract, soulTokenId);
    }
    
    /**
     * @dev See {IERC5114-ownerOf}.
     */
    function ownerOf(uint256 tokenId) external view virtual override returns (address, uint256) {
        return _getSoul(tokenId);
    }

    // Returns the number of tokens minted by `Soul`
    function _numberMinted(address soulContract, uint256 soulTokenId) internal view returns (uint256) {
        return uint256(_soulData[soulContract][soulTokenId].numberMinted);
    }

    // Returns the number of tokens burned by `Soul`
    function _numberBurned(address soulContract, uint256 soulTokenId) internal view returns (uint256) {
        return uint256(_soulData[soulContract][soulTokenId].numberBurned);
    }

    /**
     * @dev Mints `tokenId` to a Soul (Soul contract, Soul token id)
     *
     * Requirements:
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     * - max token per `Soul` not reached
     * - max minting count per `Soul` not reached
     *
     * Emits {Mint} event.
     */
    function _mint(uint256 tokenId, address soulContract, uint256 soulTokenId) internal virtual {
        require(soulContract != address(0), "ERC5114SoulBadge: mint to the zero address");
        require(!_exists(tokenId), "ERC5114SoulBadge: token already minted");
        require(maxTokenPerSoul == 0 || _soulData[soulContract][soulTokenId].balance < maxTokenPerSoul, "ERC5114SoulBadge: max token per soul reached");
        require(maxMintPerSoul == 0 || _soulData[soulContract][soulTokenId].numberMinted < maxMintPerSoul, "ERC5114SoulBadge: max minting per soul reached");

        // Overflows are incredibly unrealistic.
        unchecked {
            soulContracts[tokenId] = soulContract;
            soulTokens[tokenId] = soulTokenId;
            _soulData[soulContract][soulTokenId].balance += 1;
            _soulData[soulContract][soulTokenId].numberMinted += 1;
        }

        emit Mint(tokenId, soulContract, soulTokenId);
    }

    /**
     * @dev See {IERC5114-collectionUri}.
     */
    function collectionUri() external view virtual override returns (string memory) {
        return collectionInfo;
    }

    /**
     * @dev See {IERC5114-tokenUri}. Alias to tokenURI()
     */
    function tokenUri(uint256 tokenId) external view virtual override returns (string memory) {
        return tokenURI(tokenId);
    }

    // Return tokenURI meta data for each `tokenId`
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC5114SoulBadge: URI query for non-existent token");
        return string(abi.encodePacked(tokenBaseUri, _toString(tokenId), ".json"));
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
     * Emits {Burn} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address soulContract = soulContracts[tokenId];
        uint256 soulTokenId = soulTokens[tokenId];
        delete soulContracts[tokenId];
        delete soulTokens[tokenId];
        
        _soulData[soulContract][soulTokenId].balance -= 1;
        _soulData[soulContract][soulTokenId].numberBurned += 1;

        emit Burn(tokenId, soulContract, soulTokenId);
    }

    /**
     * @dev Burns `tokenId`. See {IERC5114-burn}.
     *
     * Access:
     * - `tokenId` owner
     */
    function burn(uint256 tokenId) public virtual override {
        require(soulOwnerOf(tokenId) == _msgSenderERC5114(), "ERC5114SoulBadge: burn from non-owner"); 
        _burn(tokenId);
    }

    /**
     * @dev Returns the message sender (defaults to `msg.sender`).
     *
     * For GSN compatible contracts, you need to override this function.
     */
    function _msgSenderERC5114() internal view virtual returns (address) {
        return msg.sender;
    }

    // Converts `uint256` to ASCII `string`
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

/**                                                                 
 *******************************************************************************
 * EIP 721 whitelist
 *******************************************************************************
 * Author: Jason Hoi
 *
 */

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../sharkz/Adminable.sol";

contract EIP712Whitelist is Adminable, Context {
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
 * IERC5114 Soul Badge interface
 *******************************************************************************
 * Creator: Sharkz Entertainment
 * Author: Jason Hoi
 *
 */

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./IERC5114.sol";

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
 * @dev See https://eips.ethereum.org/EIPS/eip-5114
 * This is additional interface on top of EIP-5114
 *
 * (bytes4) 0xb9d11845 = type(IERC5114SoulBadge).interfaceId
 */
interface IERC5114SoulBadge is IERC165, IERC721Metadata, IERC5114 {
  // Emits when a token is burnt
  event Burn(uint256 indexed tokenId, address indexed soulContract, uint256 indexed soulTokenId);

  // Returns badge token balance for a `Soul`
  function balanceOfSoul(address soulContract, uint256 soulTokenId) external view returns (uint256);

  // Returns the `Soul` token owner address
  function soulOwnerOf(uint256 tokenId) external view returns (address);
  
  // Destroys token
  function burn(uint256 tokenId) external;
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
pragma solidity ^0.8.7;

/// @dev See https://eips.ethereum.org/EIPS/eip-5114
interface IERC5114 {
	// fired anytime a new instance of this token is minted
	// this event **MUST NOT** be fired twice for the same `tokenId`
	event Mint(uint256 indexed tokenId, address indexed nftAddress, uint256 indexed nftTokenId);

	// returns the NFT token that owns this token.
	// this function **MUST** throw if the token hasn't been minted yet
	// this function **MUST** always return the same result every time it is called after it has been minted
	// this function **MUST** return the same value as found in the original `Mint` event for the token
	function ownerOf(uint256 index) external view returns (address nftAddress, uint256 nftTokenId);
	
	// returns a censorship resistant URI with details about this token collection
	// the metadata returned by this is merged with the metadata return by `tokenUri(uint256)`
	// the collectionUri **MUST** be immutable and content addressable (e.g., ipfs://)
	// the collectionUri **MUST NOT** point at mutable/censorable content (e.g., https://)
	// data from `tokenUri` takes precedence over data returned by this method
	// any external links referenced by the content at `collectionUri` also **MUST** follow all of the above rules
	function collectionUri() external view returns (string calldata collectionUri);
	
	// returns a censorship resistant URI with details about this token instance
	// the tokenUri **MUST** be immutable and content addressable (e.g., ipfs://)
	// the tokenUri **MUST NOT** point at mutable/censorable content (e.g., https://)
	// data from this takes precedence over data returned by `collectionUri`
	// any external links referenced by the content at `tokenUri` also **MUST** follow all of the above rules
	function tokenUri(uint256 tokenId) external view returns (string calldata tokenUri);
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