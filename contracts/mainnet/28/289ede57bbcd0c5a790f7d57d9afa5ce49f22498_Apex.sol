/**
 *Submitted for verification at Etherscan.io on 2022-03-07
*/

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


// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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


// File contracts/utils/ERC721.sol

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


// File contracts/ApeX.sol

pragma solidity ^0.8.11;



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
error SwapNotOn();
error FreeMintNotStarted();
error NotOnFreeMintlist();
error CantMintMoreThanOnce();
error AlreadyMintedWhitelist();


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
contract Apex is ERC721, Ownable {
    using Strings for uint256;
    
     /*///////////////////////////////////////////////////////////////
                                   AUTH
    //////////////////////////////////////////////////////////////*/

    address constant gnosisSafeAddress = 0xBC3eD63c8DB00B47471CfBD747632E24be5Cb5cd;
    address constant devWallet = 0x26a9c1618eF16Ab862D1eE54C6AAf851711e39bF;
    address[15] private _freeMintWallets;
    
    /// Merkle roots
    bytes32 private mainMerkleRoot;

    /// Payout wallets 
    address[14] private _contributorWallets;

    /// Contributor share split
    mapping(address => uint256) private _contributorShares;


    /*///////////////////////////////////////////////////////////////
                               MINT INFO
    //////////////////////////////////////////////////////////////*/

    uint256 constant public maxSupply = 4400 + 44;
    uint256 constant public mintPrice = 0.1 ether;
    bool public whitelistMintStarted = false;
    bool public freeMintStarted = false;
    bool public mintStarted = false;
    string public twoDimensionalBaseURI;
    string public threeDimensionalBaseURI;
    bool public swapOn = false;

    /// @notice Maps tokenId to 2D (true) or 3D (false)
    mapping(uint256 => bool) public tokenIdToUpgraded;

    /// @notice Maps address to bool if they have minted or not
    mapping(address => bool) private hasMinted;
    mapping(address => bool) private hasWhitelistMinted;

    uint256[5] private _tierAllocations;
    mapping(address => uint256) private _freeMintersToAmount;
    mapping(address => uint256) private numMintedPerFreeMinter;


    /*///////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

     modifier onlyOwnerOrDev {
        require(msg.sender == gnosisSafeAddress || msg.sender == devWallet || msg.sender == owner());
        _;
    }

     modifier onlyTokenOwner(uint256 _tokenId) {
        require(msg.sender == ownerOf[_tokenId], "Only token owner can swap");
        _;
    }

    modifier amountLessThanTotalSupply (uint16 _amount) {
        if(totalSupply + _amount > maxSupply) revert NoTokensLeft();
        _;
    }

    modifier hasMintStarted {
        if(!mintStarted) revert MintNotStarted();
        _;
    }

    modifier isEnoughETH(uint16 amount) {
        if (msg.value < amount * mintPrice) revert NotEnoughETH();
        _;
    }

    modifier hasWalletMintedBefore() {
        if (hasMinted[msg.sender] == true) revert CantMintMoreThanOnce();
        _;
    }

    modifier hasWhitelistWalletMintedBefore() {
        if (hasWhitelistMinted[msg.sender] == true) revert AlreadyMintedWhitelist();
        _;
    }

    modifier isMintingLessThanMaxMint(uint16 _amount) {
        require(_amount < 4, "Max mints per mint is 3");
        _;
    }


    /*///////////////////////////////////////////////////////////////
                                INIT
    //////////////////////////////////////////////////////////////*/

    /// @notice Mints 44 to the DAO Gnosis multisig wallet, sets the wallets, shares, and merkle roots for tiered mintlists
    constructor (
        string memory _baseURI, 
        uint256[14] memory shares, 
        address[14] memory wallets,
        uint256[5] memory tierAllocations
        ) 
        ERC721("ApeX", "APEX") {
        
        twoDimensionalBaseURI = _baseURI;
        _contributorWallets = wallets;
        _tierAllocations = tierAllocations;

        unchecked {
            balanceOf[gnosisSafeAddress] += 44;
            totalSupply += 44;
            for (uint256 i = 1; i <= 44; i++) {
                ownerOf[i] = gnosisSafeAddress;
            }
        }

        /// @notice Initializes the contributor wallets
        for (uint256 i = 0; i < wallets.length; i++) {
            _contributorShares[_contributorWallets[i]] = shares[i];
        }
    }

    /// @notice Initializes the freemint wallets and their mint amount
    function setFreeMintAddresses(address[15] memory freeMintAddresses, uint256[15] memory freeMintAmounts) external onlyOwnerOrDev {
        for (uint256 i = 0; i < freeMintAddresses.length; i++) {
            _freeMintersToAmount[freeMintAddresses[i]] = freeMintAmounts[i];
        }
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwnerOrDev {
        mainMerkleRoot = _merkleRoot;
    }

    /*///////////////////////////////////////////////////////////////
                          MERKLE VALIDATION
    //////////////////////////////////////////////////////////////*/

    /// @dev    Add a hashed address to the merkle tree as a leaf
    /// @param  account Leaf address for MerkleTree
    /// @return bytes32 hashed version of the merkle leaf address
    function _leaf(address account) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    /// @dev    Verify the whitelist using the merkle tree
    /// @param  leaf Hashed address leaf from _leaf() to search for
    /// @param  proof Submitted root proof from MerkleTree
    /// @return bool True if address is allowed to mint
    function verifyMerkle(bytes32 leaf, bytes32[] memory proof, bytes32 merkleRoot) private pure returns (bool) {
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

    /// @dev   Whitelist mint
    /// @param amount Number of requested mints
    /// @param tier Whitelist tier of minter
    /// @param _proof Submitted root proof from MerkleTree for whitelist
    function whitelistMint(address account, uint16 amount, uint256 tier, bytes32[] memory _proof) external payable 
        amountLessThanTotalSupply(amount) 
        isEnoughETH(amount) 
        hasWhitelistWalletMintedBefore
    {
        if (amount > _tierAllocations[tier]) revert TooManyMintForTier();
        if (!whitelistMintStarted) revert WhitelistMintNotStarted();
        if (verifyMerkle(_leaf(account), _proof, mainMerkleRoot) == false) revert NotOnWhitelist();
        hasWhitelistMinted[msg.sender] = true;

        unchecked {
            for (uint16 i = 0; i < amount; i++) {
                _mint(msg.sender, totalSupply + 1);
            }
        }
    }

    function generalMint(uint16 amount) external payable 
        isMintingLessThanMaxMint(amount)
        amountLessThanTotalSupply(amount) 
        isEnoughETH(amount) 
        hasMintStarted 
        hasWalletMintedBefore
    {
        hasMinted[msg.sender] = true;

        unchecked {
            for (uint16 index = 0; index < amount; index++) {
                _mint(msg.sender, totalSupply + 1);
            }   
        }
    }

    /// @notice Mints a free token for a given address
    function freeMint(address account, uint16 amount, bytes32[] memory _proof) external payable 
        amountLessThanTotalSupply(amount)  
    {
        require(amount + numMintedPerFreeMinter[msg.sender] < _freeMintersToAmount[msg.sender] + 1, "Trying to mint more than your free mint allocation"); 
        require(_freeMintersToAmount[msg.sender] > 0, "Not on freemint list");

        if (!freeMintStarted) revert FreeMintNotStarted();
        if (verifyMerkle(_leaf(account), _proof, mainMerkleRoot) == false) revert NotOnFreeMintlist();
        numMintedPerFreeMinter[msg.sender] += amount;

        unchecked {
            for (uint16 i = 0; i < amount; i++) {
                _mint(msg.sender, totalSupply + 1);
            }
        }
    }

    function toggleWhitelistMint() public onlyOwnerOrDev {
        whitelistMintStarted = !whitelistMintStarted;
    }

    function toggleFreeMint() public onlyOwnerOrDev {
        freeMintStarted = !freeMintStarted;
    }

    function toggleGeneralMint() public onlyOwnerOrDev {
        mintStarted = !mintStarted;
    }

    /// @notice Withdraw to Gnosis multisig and associated wallets
    function withdraw() external onlyOwnerOrDev {
        if (address(this).balance == 0) revert EmptyBalance();
        uint256 currentBalance = address(this).balance;
        for (uint256 i=0; i < _contributorWallets.length; i++) {
            (bool success, ) = _contributorWallets[i].call{value: (currentBalance * _contributorShares[_contributorWallets[i]] / 10000)}("");
            require(success);
        }
    }

    /*///////////////////////////////////////////////////////////////
                        METADATA SWAPPING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @dev Set the metadata URI for IPFS
    /// @param _baseURI The URI to set
    function setTwoDimensionalBaseURI(string memory _baseURI) public {
        twoDimensionalBaseURI = _baseURI;
    }

    function setThreeDimensionalBaseURI(string memory _threeDimensionalBaseURI) public onlyOwnerOrDev {
        threeDimensionalBaseURI = _threeDimensionalBaseURI;
    }


    /// @notice Base assumption is that the mapping tokenId is false
    function swap(uint256 tokenId) external onlyTokenOwner(tokenId) {
        if (swapOn == false) revert SwapNotOn();
        /// if it is 3D
        if (tokenIdToUpgraded[tokenId] == true) {
            /// change tokenId URI to 2D
            tokenIdToUpgraded[tokenId] = !tokenIdToUpgraded[tokenId];
        } else {
            /// change tokenId URI to 3D
            tokenIdToUpgraded[tokenId] = true;
        }
    }


    function toggleSwap() public onlyOwner {
        swapOn = !swapOn;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (ownerOf[tokenId] == address(0)) revert DoesNotExist();

        if (tokenIdToUpgraded[tokenId] == true) {
            return string(abi.encodePacked(threeDimensionalBaseURI, tokenId.toString()));
        } else {
            return string(abi.encodePacked(twoDimensionalBaseURI, tokenId.toString()));
        }
    }
}