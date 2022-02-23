// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;


import "../../utils/ERC721.sol";
import "../../utils/Strings.sol";
import "../../utils/Ownable.sol";


error NoTokensLeft();
error SoldOut();
error TooManyMintAtOnce();
error TooManyMintForTier();
error NotEnoughETH();
error NotOnWhitelist();
error DoesNotExist();
error OnlyTokenOwnerCanSwap();
error WhitelistMintNotStarted();
error MintNotStarted();
error EmptyBalance();


/*
          :::    ::::::::: ::::::::::            :::    ::: 
       :+: :+:  :+:    :+::+:                   :+:    :+:  
     +:+   +:+ +:+    +:++:+                    +:+  +:+    
   +#++:++#++:+#++:++#+ +#++:++#   +#++:++#+    +#++:+      
  +#+     +#++#+       +#+                    +#+  +#+      
 #+#     #+##+#       #+#                   #+#    #+#      
###     ######       ##########            ###    ###    

*/


/// @title  ApeX contract 
/// @author @CrossChainLabs (https://canthedevsdosomething.com) 
contract ApeX2 is ERC721, Ownable {
    using Strings for uint256;
    
     /*///////////////////////////////////////////////////////////////
                                   AUTH
    //////////////////////////////////////////////////////////////*/

    address constant gnosisSafeAddress = 0xBC3eD63c8DB00B47471CfBD747632E24be5Cb5cd;
    address constant devWallet = 0x26a9c1618eF16Ab862D1eE54C6AAf851711e39bF;

    /// Payout wallets 
    address[18] private _contributorWallets;

    /// Contributor share split
    mapping(address => uint256) private _contributorShares;

     modifier onlyOwnerOrDev {
        require(msg.sender == gnosisSafeAddress || msg.sender == devWallet || msg.sender == owner());
        _;
    }

     modifier onlyTokenOwner(uint256 _tokenId) {
        require(msg.sender == ownerOf[_tokenId], "Only token owner can swap");
        _;
    }

    /*///////////////////////////////////////////////////////////////
                               MERKLE INFO
    //////////////////////////////////////////////////////////////*/

    /// @notice Minting tiers
    uint256 public highOrderX = 0;
    uint256 public syndicateX = 1;
    uint256 public advocateX = 2;
    uint256 public citizenX = 3;
    uint256 public xList = 4;

    mapping(uint256 => bytes32) private merkleRoots;
    /// @notice test if a mapping is faster
    uint256[5] public maxMintsPerTier; 


    /*///////////////////////////////////////////////////////////////
                               MINT INFO
    //////////////////////////////////////////////////////////////*/

    uint256 constant public maxSupply = 6633 + 33;
    uint256 constant public mintPrice = 0.1 ether;
    uint256 public maxGeneralMintAmount = 15;
    bool public whitelistMintStarted = false;
    bool public mintStarted = false;
    string public threeDimensionalBaseURI;
    string public baseURI;

    /// @notice Maps tokenId to 2D (true) or 3D (false)
    mapping(uint256 => bool) public tokenIdToUpgraded;

    /// @notice Maps owner address to number of mints on a wallet- want to move this off chain since we only use on mint
    mapping(address => uint256) private numMintedPerWallet;


    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Mints 50 to the DAO Gnosis multisig wallet, sets the wallets, shares, and merkle roots for tiered mintlists
    constructor (
        string memory _baseURI, 
        uint256[18] memory shares, 
        address[18] memory wallets, 
        bytes32[5] memory _merkleRoots, 
        uint256[5] memory _maxMintsPerTier
        ) 
        ERC721("ApeX", "APEX") {
        
        baseURI = _baseURI;

        unchecked {
            balanceOf[gnosisSafeAddress] += 33;
            totalSupply += 33;
            for (uint256 i = 1; i <= 33; i++) {
                ownerOf[i] = gnosisSafeAddress;
            }
        }

        /// @notice Initializes the contributor wallets, 0.01 gas cheaper than hardcoding
        for (uint256 i = 0; i < wallets.length; i++) {
            /// set the wallets
            _contributorWallets[i] = wallets[i];

            /// set the shares
            _contributorShares[_contributorWallets[i]] = shares[i];
        }

        /// @notice Set the merkle roots
        for (uint256 i = 0; i < _merkleRoots.length; i++) {
            merkleRoots[i] = _merkleRoots[i];
        }

        /// @notice Set the max mints per whitelist tier
        for (uint256 i = 0; i < _maxMintsPerTier.length; i++) {
            maxMintsPerTier[i] = _maxMintsPerTier[i];
        }
    }


    /*///////////////////////////////////////////////////////////////
                            METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @dev Set the metadata URI for IPFS
    /// @param _baseURI The URI to set
    function setBaseURI(string memory _baseURI) public {
        baseURI = _baseURI;
    }


    /*///////////////////////////////////////////////////////////////
                            WHITELIST LOGIC
    //////////////////////////////////////////////////////////////*/

    function _leaf(address account) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    /// @notice Switch back to view if pure causes problems
    function verifyWhitelist(bytes32 leaf, bytes32[] memory proof, bytes32 merkleRoot)
        private
        pure 
        returns (bool)
    {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash < proofElement) {
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            } else {
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
            }
        }

        return computedHash == merkleRoot;
    }


    /*///////////////////////////////////////////////////////////////
                            MINTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function whitelistMint(uint16 amount, bytes32[] memory _proof, uint256 _tier) external payable {
        if (amount > maxMintsPerTier[_tier]) revert TooManyMintForTier();
        require(numMintedPerWallet[msg.sender] + amount < 16, "Only 15 ApeX allowed per wallet");
        if (!whitelistMintStarted) revert WhitelistMintNotStarted();
        if (msg.value < amount * mintPrice) revert NotEnoughETH();
        if (totalSupply + amount > maxSupply) revert NoTokensLeft();
        
        /// check if they're on the specific whitelist
        if (verifyWhitelist(_leaf(msg.sender), _proof, merkleRoots[_tier]) == false) revert NotOnWhitelist();
        
        /// @notice Set the minted NFT to true for future swapping between 2D and 3D avatars
        tokenIdToUpgraded[totalSupply] = false;

        unchecked {
            for (uint16 i = 0; i < amount; i++) {
                _mint(msg.sender, totalSupply + 1);
                numMintedPerWallet[msg.sender] += 1;
            }
        }
    }

    function generalMint(uint16 amount) external payable {
        /// @notice Will move this to the frontend to save on gas
        require(numMintedPerWallet[msg.sender] + amount < 16, "Only 15 ApeX allowed per wallet");
        if (amount > maxGeneralMintAmount) revert TooManyMintAtOnce();
        if (totalSupply + amount > maxSupply) revert NoTokensLeft();
        if (!mintStarted) revert MintNotStarted();
        if (msg.value < amount * mintPrice) revert NotEnoughETH();
        if (amount > maxGeneralMintAmount) revert TooManyMintAtOnce();

        unchecked {
            for (uint16 index = 0; index < amount; index++) {
                _mint(msg.sender, totalSupply + 1);
                numMintedPerWallet[msg.sender] += 1;
            }
        }
    }

    /// @notice Withdraw to Gnosis multisig and associated wallets
    function withdraw() external onlyOwnerOrDev {
        if (address(this).balance == 0) revert EmptyBalance();
        uint256 currentBalance = address(this).balance;
        for (uint256 i=0; i < _contributorWallets.length; i++) {
            (bool success, ) = _contributorWallets[i].call{value: (currentBalance / 10000 * _contributorShares[_contributorWallets[i]])}("");
            require(success);
        }
    }

    function toggleGeneralMint() public onlyOwnerOrDev {
        mintStarted = !mintStarted;
    }

    function toggleWhitelistMint() public onlyOwnerOrDev {
        whitelistMintStarted = !whitelistMintStarted;
    }

    /*///////////////////////////////////////////////////////////////
                        METADATA SWAPPING LOGIC
    //////////////////////////////////////////////////////////////*/

    function setThreeDimensionalBaseURI(string memory _threeDimensionalBaseURI) public onlyOwnerOrDev {
        threeDimensionalBaseURI = _threeDimensionalBaseURI;
    }

    function swap(uint256 tokenId) external onlyTokenOwner(tokenId) {
        tokenIdToUpgraded[tokenId] = !tokenIdToUpgraded[tokenId];
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (ownerOf[tokenId] == address(0)) revert DoesNotExist();

        if (tokenIdToUpgraded[tokenId] == true) {
            return string(abi.encodePacked(threeDimensionalBaseURI, tokenId.toString()));
        } else {
            return string(abi.encodePacked(baseURI, tokenId.toString()));
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/distractedm1nd/solmate/blob/main/src/tokens/ERC721.sol)
/// @dev Note that balanceOf does not revert if passed the zero address, in defiance of the ERC.
abstract contract ERC721 {
    /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*///////////////////////////////////////////////////////////////
                          METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*///////////////////////////////////////////////////////////////
                            ERC721 STORAGE                        
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(uint256 => address) public ownerOf;

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*///////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || msg.sender == getApproved[id] || isApprovedForAll[from][msg.sender],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            balanceOf[from]--;

            balanceOf[to]++;
        }

        ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            totalSupply++;

            balanceOf[to]++;
        }

        ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = ownerOf[id];

        require(ownerOf[id] != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            totalSupply--;

            balanceOf[owner]--;
        }

        delete ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
interface ERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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
pragma solidity ^0.8.0;

import "./Context.sol";

// File: lib/openzeppelin-contracts/contracts/access/Ownable.sol
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

pragma solidity ^0.8.0;
// File: lib/openzeppelin-contracts/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)


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