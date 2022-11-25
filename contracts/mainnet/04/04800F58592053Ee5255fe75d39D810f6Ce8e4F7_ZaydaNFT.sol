// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);
}

interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(address from, address to, uint256 id) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id], "NOT_AUTHORIZED");

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(address from, address to, uint256 id) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 || ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") == ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(address from, address to, uint256 id, bytes calldata data) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 || ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) == ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 || ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") == ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(address to, uint256 id, bytes memory data) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 || ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) == ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(address, address, uint256, bytes calldata) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/**

                                    artificial intelligence. non-
                                      fungible token. governance.
                                        decentralized finance.
                                  ,'
                  ,--.    ,--.
                 (( O))--(( O))
               ,'_`--'____`--'_`.
              _:  ____________  :_
             | | ||::::::::::|| | |
             | | ||::::::::::|| | |
             | | ||::::::::::|| | |
             |_| |/__________\| |_|
               |________________|
            __..-'            `-..__
         .-| : .---------------. : |-.
       ,\ || | |\____ZAYDA____/| | || /.
      /`.\:| | ||  __  __  __  || | |;/,'\
     :`-._\;.| || '--''--''--' || |,:/_.-':
     | -- :  | || .----------. || |  : -- |
     |    |  | || '----------' || |  |    |
     |    |  | ||   _   _   _  || |  |    |
     :,--.;  | ||  (_) (_) (_) || |  :,--.;
     (`-'|)  | ||______________|| |  (|`-')
      `--'   | |/______________\| |   `--'
             |____________________|
              `.________________,'

    web: zayda.io
*/

import {Owned} from "./solmate/src/auth/Owned.sol";
import {ERC721, ERC721TokenReceiver} from "./solmate/src/tokens/ERC721.sol";
import {ReentrancyGuard} from "./solmate/src/utils/ReentrancyGuard.sol";
import {Counters} from "./openzeppelin-contracts/contracts/utils/Counters.sol";
import {IERC20, IERC721} from "./Interfaces.sol";
import {ZaydaReserve} from "./ZaydaReserve.sol";

contract ZaydaNFT is Owned, ERC721, ERC721TokenReceiver, ReentrancyGuard {
    using Counters for Counters.Counter;

    /** ****************************************************************
     * ADDRESSES
     * ****************************************************************/

    /// @notice The {ZaydaReserve} address that receives NFT reserved for the team.
    address public immutable teamReserve;

    /// @notice The {ZaydaReserve} address that receives NFT reserved for the community.
    address public immutable communityReserve;

    /** ****************************************************************
     * SUPPLY CONSTANTS
     * ****************************************************************/

    /// @notice The maximum number of mintable NFT.
    uint256 public constant maxSupply = 10000;

    /// @notice The maximum number of mintable NFT via mintlist.
    /// @dev 10% of {maxSupply} will be reserved for mintlist.
    uint256 public constant mintlistSupply = maxSupply / 10;

    /// @notice The maximum number of mintable NFT via reserves.
    /// @dev 5% of available supply will be reserved and split between reserves.
    uint256 public constant reservedSupply = (maxSupply - mintlistSupply) / 20;

    /// @notice The maximum number of mintable NFT via standard.
    uint256 public constant mintableSupply = maxSupply - mintlistSupply - reservedSupply;

    /** ****************************************************************
     * NFT STATE
     * ****************************************************************/

    /// @notice A boolean state of whether minting is possible.
    bool public mintIsActive;

    /// @notice The cost of minting an NFT via standard.
    uint256 public mintCost = 0.05 ether;

    /// @notice The total number of NFT minted.
    Counters.Counter public totalSupply;

    /// @notice The total number of NFT minted via mintlist.
    Counters.Counter public mintlistMinted;

    /// @notice The total number of NFT minted via reserves.
    Counters.Counter public reservesMinted;

    /** ****************************************************************
     * MINTLIST STATE
     * ****************************************************************/

    /// @notice A mapping to keep track of mintlisted addresses.
    mapping(address => bool) public isMintlisted;

    /// @notice A mapping to keep track of which addresses have claimed from mintlist.
    mapping(address => bool) public hasClaimedMintlist;

    /// @notice The total number of mintlisted addresses.
    Counters.Counter public totalMintlisted;

    /** ****************************************************************
     * METADATA CONSTANTS
     * ****************************************************************/

    /// @notice The base URI for minted NFT.
    string public baseURI;

    /// @notice The struct holding for minted NFT.
    struct NFTData {
        address creator;
        string ipfs;
    }

    /// @notice The mapping of NFT ids to their data.
    mapping(uint256 => NFTData) public getNFTData;

    /** ****************************************************************
     * EVENTS AND ERRORS
     * ****************************************************************/

    event MintStatusUpdated(bool _status);
    event MintCostUpdated(uint256 _cost);
    event AddedToMintlist(address indexed _mintlistee);
    event RemovedFromMintlist(address indexed _mintlistee);
    event BaseURIUpdated(string _uri);
    event WithdrawnEth(uint256 _timestamp, uint256 _amount);
    event WithdrawnERC20(uint256 _timestamp, uint256 _amount);
    event WithdrawnERC721(uint256 _timestamp, uint256 _id);
    event NewTokenCreated(uint256 _id, address indexed _creator, address indexed _owner);

    error TokenDoesNotExist();
    error MintlistOverflow();
    error MintlistAlreadyClaimed();
    error MintingIsNotActive();
    error MaxSupplyOverflow();
    error ReservedSupplyOverflow();
    error UserIsNotMintlisted();
    error InsufficientValue();
    error SoldOut();

    /** ****************************************************************
     * CONSTRUCTOR
     * ****************************************************************/

    /// @notice Initializes the contract and deploy and configure reserves.
    /// @param _owner The address of the owner for {ZaydaNFT} and reserves.
    /// @param _uri The Infura IPFS URI minted NFT will use.
    /// @dev The `_owner` param will be a Gnosis Safe Multisig contract.
    constructor(address _owner, string memory _uri) Owned(_owner) ERC721("Zayda NFT", "zNFT") {
        teamReserve = address(new ZaydaReserve(_owner));
        communityReserve = address(new ZaydaReserve(_owner));
        baseURI = _uri;
    }

    /// @notice Allows the contract to receive ethers.
    receive() external payable {}

    /** ****************************************************************
     * MINTING LOGIC
     * ****************************************************************/

    /// @notice Mints an NFT via mintlist.
    /// @param _ipfs The IPFS hash generated by ZAYDA API for the NFT.
    /// @dev The `msg.sender` must be truthy in the {isMintlisted} mapping.
    /// @dev The `msg.sender` must be falsey in the {hasClaimedMintlist} mapping.
    function claimNFT(string memory _ipfs) external nonReentrant {
        if (!isMintlisted[msg.sender]) revert UserIsNotMintlisted();
        if (hasClaimedMintlist[msg.sender]) revert MintlistAlreadyClaimed();

        hasClaimedMintlist[msg.sender] = true;
        mintlistMinted.increment();

        _mintNFT(msg.sender, _ipfs);
    }

    /// @notice Mints an NFT via reserves to {teamReserve}.
    /// @param _ipfs The IPFS hash generated by ZAYDA API for the NFT.
    function mintToTeam(string memory _ipfs) external onlyOwner {
        _mintNFT(teamReserve, _ipfs);
    }

    /// @notice Mints an NFT via reserves to {communityReserve}.
    /// @param _ipfs The IPFS hash generated by ZAYDA API for the NFT.
    function mintToCommunity(string memory _ipfs) external onlyOwner {
        _mintNFT(communityReserve, _ipfs);
    }

    /// @notice Mints an NFT via standard.
    /// @param _ipfs The IPFS hash generated by ZAYDA API for the NFT.
    /// @dev The `msg.value` must be greater than {mintCost}.
    /// @dev Reverts if {totalSupply}-{mintlistMinted}-{reservesMinted}, which
    /// is the total NFT minted via standard is more than or equal to {mintableSupply}.
    function mintNFT(string memory _ipfs) external payable nonReentrant {
        if (msg.value < mintCost) revert InsufficientValue();
        if (totalSupply.current() - mintlistMinted.current() - reservesMinted.current() >= mintableSupply) revert SoldOut();

        _mintNFT(msg.sender, _ipfs);
    }

    /** ****************************************************************
     * URI LOGIC
     * ****************************************************************/

    /// @notice Returns the token's full URI if it has been minted.
    /// @param _id The id of the token to get the URI for.
    /// @return The concat of {baseURI} and IPFS hash of the NFT
    function tokenURI(uint256 _id) public view virtual override returns (string memory) {
        NFTData memory nftData = getNFTData[_id];

        if (nftData.creator == address(0)) revert TokenDoesNotExist();

        return string.concat(baseURI, nftData.ipfs);
    }

    /** ****************************************************************
     * ZAYDA LOGIC
     * ****************************************************************/

    /// @notice Makes {mintIsActive} truthy if false, and falsey if true.
    function flipMintStatus() external onlyOwner {
        bool newStatus = !mintIsActive;

        mintIsActive = newStatus;
        emit MintStatusUpdated(newStatus);
    }

    /// @notice Updates the {mintCost} with the new provided amount.
    /// @param _cost The new cost in WEI for minting an NFT via standard.
    function updateMintCost(uint256 _cost) external onlyOwner {
        mintCost = _cost;
        emit MintCostUpdated(_cost);
    }

    /// @notice Adds an address to the mintlist.
    /// @param _mintlistees The addresses to be added to the mintlist.
    /// @dev The length of {totalMintlisted} after added the length of `_mintlistees`
    /// must be less than or equal to {mintlistSupply}.
    function addToMintlist(address[] memory _mintlistees) external onlyOwner {
        if (totalMintlisted.current() + _mintlistees.length > mintlistSupply) revert MintlistOverflow();

        for (uint256 i = 0; i < _mintlistees.length; i++) {
            address mintlistee = _mintlistees[i];

            if (!isMintlisted[mintlistee]) {
                _addToMintlist(mintlistee);
            }
        }
    }

    /// @notice Removes an address from the mintlist.
    /// @param _mintlistees The addresses to be removed form the mintlist.
    /// @dev The addresses in `_mintlistees` must not already claimed the mintlist.
    function removeFromMintlist(address[] memory _mintlistees) external onlyOwner {
        for (uint256 i = 0; i < _mintlistees.length; i++) {
            address mintlistee = _mintlistees[i];

            if (isMintlisted[mintlistee]) {
                if (hasClaimedMintlist[mintlistee]) revert MintlistAlreadyClaimed();

                _removeFromMintlist(mintlistee);
            }
        }
    }

    /// @notice Updates the {baseURI} with the newly provided.
    /// @param _uri The new URI to be used by the NFT.
    function updateBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
        emit BaseURIUpdated(_uri);
    }

    /// @notice Withdraws ethers in contract to owner.
    function withdrawEth() external onlyOwner {
        uint256 amount = address(this).balance;

        payable(owner).transfer(amount);
        emit WithdrawnEth(block.timestamp, amount);
    }

    /// @notice Withdraws ERC20 token balance in contract to owner.
    /// @param _address The address of the ERC20 token contract.
    function withdrawERC20(IERC20 _address) external onlyOwner {
        uint256 amount = _address.balanceOf(address(this));

        _address.transfer(owner, amount);
        emit WithdrawnERC20(block.timestamp, amount);
    }

    /// @notice Withdraws ERC721 token ids in contract to owner.
    /// @param _address The address of the ERC721 token contract.
    /// @param _ids The token ids owned by contract to send to owner.
    function withdrawERC721(IERC721 _address, uint256[] memory _ids) external onlyOwner {
        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 id = _ids[i];

            _address.transferFrom(address(this), owner, id);
            emit WithdrawnERC721(block.timestamp, id);
        }
    }

    /** ****************************************************************
     * INTERNAL LOGIC
     * ****************************************************************/

    /// @notice An internal method to add an address to the mintlist.
    /// @param _mintlistee The address to be added to the mintlist.
    function _addToMintlist(address _mintlistee) internal {
        totalMintlisted.increment();
        isMintlisted[_mintlistee] = true;
        emit AddedToMintlist(_mintlistee);
    }

    /// @notice An internal method to remove an address from the mintlist.
    /// @param _mintlistee The address to be removed from the mintlist.
    function _removeFromMintlist(address _mintlistee) internal {
        totalMintlisted.decrement();
        isMintlisted[_mintlistee] = false;
        emit RemovedFromMintlist(_mintlistee);
    }

    /// @notice An internal method to create a new token.
    /// @param _to The address that will receive the minted NFT.
    /// @param _ipfs The IPFS hash generated by ZAYDA API for the NFT.
    /// @dev The {mintIsActive} state must be truthy in order to mint, unless owner.
    /// @dev The new {totalSupply} must not exceed the {maxSupply} amount.
    /// @dev If minting to {teamReserve} or {communityReserve}, the {reservesMinted}
    /// must not exceed the {reservedSupply} amount.
    /// @dev The `creator` of `id` in {getNFTData} will be set to `msg.sender`, as
    /// it will be the one interacting with ZAYDA off-chain API.
    function _mintNFT(address _to, string memory _ipfs) internal {
        if (msg.sender != owner && !mintIsActive) revert MintingIsNotActive();

        totalSupply.increment();

        uint256 id = totalSupply.current();
        if (id > maxSupply) revert MaxSupplyOverflow();

        if (_to == teamReserve || _to == communityReserve) {
            reservesMinted.increment();
            if (reservesMinted.current() > reservedSupply) revert ReservedSupplyOverflow();
        }

        getNFTData[id] = NFTData({creator: msg.sender, ipfs: _ipfs});
        _mint(_to, id);

        emit NewTokenCreated(id, msg.sender, _to);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {Owned} from "./solmate/src/auth/Owned.sol";
import {IERC20, IERC721} from "./Interfaces.sol";

contract ZaydaReserve is Owned {
    /** ****************************************************************
     * EVENTS
     * ****************************************************************/

    event WithdrawnEth(uint256 _timestamp, uint256 _amount);
    event WithdrawnERC20(uint256 _timestamp, uint256 _amount);
    event WithdrawnERC721(uint256 _timestamp, uint256 _id);

    /** ****************************************************************
     * CONSTRUCTOR
     * ****************************************************************/

    /// @notice Initializes the reserve contract.
    /// @param _owner The address of the owner for the contract.
    constructor(address _owner) Owned(_owner) {}

    /// @notice Allows the contract to receive ethers.
    receive() external payable {}

    /** ****************************************************************
     * ZAYDA LOGIC
     * ****************************************************************/

    /// @notice Withdraws ethers in contract to owner.
    function withdrawEth() external onlyOwner {
        uint256 amount = address(this).balance;

        payable(owner).transfer(amount);
        emit WithdrawnEth(block.timestamp, amount);
    }

    /// @notice Withdraws ERC20 token balance in contract to owner.
    /// @param _address The address of the ERC20 token contract.
    function withdrawERC20(IERC20 _address) external onlyOwner {
        uint256 amount = _address.balanceOf(address(this));

        _address.transfer(owner, amount);
        emit WithdrawnERC20(block.timestamp, amount);
    }

    /// @notice Withdraws ERC721 token ids in contract to owner.
    /// @param _address The address of the ERC721 token contract.
    /// @param _ids The token ids owned by contract to send to owner.
    function withdrawERC721(IERC721 _address, uint256[] memory _ids) external onlyOwner {
        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 id = _ids[i];

            _address.transferFrom(address(this), owner, id);
            emit WithdrawnERC721(block.timestamp, id);
        }
    }
}