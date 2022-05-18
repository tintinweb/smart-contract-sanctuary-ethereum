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
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash;
    }
}

pragma solidity ^0.8.0;

library AnonymiceLibrary {
    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
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

    function parseInt(string memory _a)
        internal
        pure
        returns (uint8 _parsedInt)
    {
        bytes memory bresult = bytes(_a);
        uint8 mint = 0;
        for (uint8 i = 0; i < bresult.length; i++) {
            if (
                (uint8(uint8(bresult[i])) >= 48) &&
                (uint8(uint8(bresult[i])) <= 57)
            ) {
                mint *= 10;
                mint += uint8(bresult[i]) - 48;
            }
        }
        return mint;
    }

    function substring(
        string memory str,
        uint256 startIndex,
        uint256 endIndex
    ) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

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
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed id
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 indexed id
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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

        require(
            msg.sender == owner || isApprovedForAll[owner][msg.sender],
            "NOT_AUTHORIZED"
        );

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
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from ||
                isApprovedForAll[from][msg.sender] ||
                msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

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

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(
                    msg.sender,
                    from,
                    id,
                    ""
                ) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(
                    msg.sender,
                    from,
                    id,
                    data
                ) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        returns (bool)
    {
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
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(
                    msg.sender,
                    address(0),
                    id,
                    ""
                ) ==
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
                ERC721TokenReceiver(to).onERC721Received(
                    msg.sender,
                    address(0),
                    id,
                    data
                ) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./AnonymiceLibrary.sol";
import "./ERC721sm.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract FoldedFacesV2 is ERC721, Ownable {
    /*
 __             __          __   __  __  __     
|__ | _| _ _|  |__  _ _ _    _) /  \  _)  _)    
|(_)|(_|(-(_|  |(_|(_(-_)   /__ \__/ /__ /__  , 
                                                
        __                                      
|_     / _  _ _ |  . _ |_ |_                    
|_)\/  \__)(-| )|__|(_)| )|_  .  
*/
    using AnonymiceLibrary for uint8;

    struct Trait {
        string traitName;
        string traitType;
    }

    //Mappings
    mapping(uint256 => Trait[]) public traitTypes;
    mapping(address => uint256) private lastWrite;

    //Mint Checks
    mapping(address => bool) addressWhitelistMinted;
    mapping(address => bool) contributorMints;
    uint256 contributorCount = 0;
    uint256 regularCount = 0;
    uint256 public totalSupply = 0;

    //uint256s
    uint256 public constant MAX_SUPPLY = 533;
    uint256 public constant WL_MINT_COST = 0.003 ether;
    uint256 public constant PUBLIC_MINT_COST = 0.005 ether;

    uint256 public constant PUBLIC_START_BLOCK = 0;

    mapping(uint256 => uint256) tokenIdToStartHash;
    mapping(uint256 => uint256) tokenIdToNonce;
    uint256 SEED_NONCE = 0;

    //minting flag
    bool ogMinted = false;
    bool public MINTING_LIVE = true;

    //uint arrays
    uint16[][8] TIERS;

    //p5js url
    string p5jsUrl;
    string p5jsIntegrity;
    string imageUrl;
    string animationUrl;

    //stillSnowCrash
    bytes32 constant whitelistRoot =
        0x2cd756bd043061e7f4cd5b02ccfbd86ac3965d315356463f26afa7c6915ab14f;

    constructor() payable ERC721("FoldedFaces", "FFACE") {
        //Declare all the rarity tiers

        //TwoFace
        TIERS[0] = [9000, 1000];
        //Color
        TIERS[1] = [1200, 880, 880, 880, 880, 880, 880, 880, 880, 880];
        //Border
        TIERS[2] = [1000, 9000];
        //Origin
        TIERS[3] = [9800, 200];
        //WarpSpeed
        TIERS[4] = [2250, 2250, 2250, 2250, 1000];
        //Folds
        TIERS[5] = [2500, 2500, 2500, 2500];
        //Universe
        TIERS[6] = [7000, 1000, 2000];
        //Water
        TIERS[7] = [1000, 9000];
    }

    //prevents someone calling read functions the same block they mint
    modifier disallowIfStateIsChanging() {
        require(
            owner() == msg.sender || lastWrite[msg.sender] < block.number,
            "not so fast!"
        );
        _;
    }

    /*
 __    __     __     __   __     ______   __     __   __     ______    
/\ "-./  \   /\ \   /\ "-.\ \   /\__  _\ /\ \   /\ "-.\ \   /\  ___\   
\ \ \-./\ \  \ \ \  \ \ \-.  \  \/_/\ \/ \ \ \  \ \ \-.  \  \ \ \__ \  
 \ \_\ \ \_\  \ \_\  \ \_\\"\_\    \ \_\  \ \_\  \ \_\\"\_\  \ \_____\ 
  \/_/  \/_/   \/_/   \/_/ \/_/     \/_/   \/_/   \/_/ \/_/   \/_____/ 
                                                                                                                                                                                                                                               
   */

    /**
     * @dev Converts a digit from 0 - 10000 into its corresponding rarity based on the given rarity tier.
     * @param _randinput The input from 0 - 10000 to use for rarity gen.
     * @param _rarityTier The tier to use.
     */
    function rarityGen(uint256 _randinput, uint8 _rarityTier)
        internal
        view
        returns (uint8)
    {
        uint16 currentLowerBound = 0;
        for (uint8 i = 0; i < TIERS[_rarityTier].length; i++) {
            uint16 thisPercentage = TIERS[_rarityTier][i];
            if (
                _randinput >= currentLowerBound &&
                _randinput < currentLowerBound + thisPercentage
            ) return i;
            currentLowerBound = currentLowerBound + thisPercentage;
        }

        revert();
    }

    /**
     * @param _t The token id to be used within the hash.
     * @param _a The address to be used within the hash.
     */
    function hash(uint256 _t, address _a) internal view returns (uint256) {
        uint256 _randinput = uint256(
            keccak256(
                abi.encodePacked(block.timestamp, block.difficulty, _t, _a)
            )
        );

        return _randinput;
    }

    /**
     * @dev Mint internal, this is to avoid code duplication.
     */
    function mintInternal() internal {
        require(
            MINTING_LIVE == true || msg.sender == owner(),
            "Minting not live"
        );
        uint256 _totalSupply = totalSupply;

        require(_totalSupply < MAX_SUPPLY, "Minted out");
        require(!AnonymiceLibrary.isContract(msg.sender), "No Contracts");
        require(regularCount < 241, "Minted Out Non Reserved Spots");

        uint256 thisTokenId = _totalSupply;

        tokenIdToStartHash[thisTokenId] = hash(thisTokenId, msg.sender);
        tokenIdToNonce[thisTokenId] = SEED_NONCE;
        lastWrite[msg.sender] = block.number;
        SEED_NONCE += 8;

        ++totalSupply;

        _mint(msg.sender, thisTokenId);
    }

    function mintOgBatch(address[] memory _addresses)
        external
        payable
        onlyOwner
    {
        require(ogMinted == false);
        require(_addresses.length == 10);

        uint256 _nonce = SEED_NONCE;
        for (uint256 i = 0; i < 10; i++) {
            uint256 thisTokenId = i;
            tokenIdToStartHash[thisTokenId] = hash(thisTokenId, _addresses[i]);
            tokenIdToNonce[thisTokenId] = _nonce;
            _mint(_addresses[i], thisTokenId);
            _nonce += 8;
        }
        totalSupply = 10;
        regularCount = 10;
        SEED_NONCE += 80;
        ogMinted = true;
    }

    /**
     * @dev Mints new tokens.
     */
    function mintWLFoldedFaces(address account, bytes32[] calldata merkleProof)
        external
        payable
    {
        bytes32 node = keccak256(abi.encodePacked(account));

        require(MerkleProof.verify(merkleProof, whitelistRoot, node));
        require(msg.value == WL_MINT_COST, "Insufficient ETH sent");
        require(
            addressWhitelistMinted[msg.sender] != true,
            "Address already minted WL"
        );

        addressWhitelistMinted[msg.sender] = true;
        ++regularCount;
        return mintInternal();
    }

    function mintPublicFoldedFaces() external payable {
        require(msg.value == PUBLIC_MINT_COST, "Insufficient ETH sent");
        require(block.number > PUBLIC_START_BLOCK, "Public mint not started");
        ++regularCount;
        return mintInternal();
    }

    function mintCircolorsContributor() external {
        require(contributorMints[msg.sender] == true);
        require(contributorCount < 16);

        contributorMints[msg.sender] = false;
        ++contributorCount;

        return mintInternal();
    }

    function mintTwenty() external {
        for (uint256 i = 0; i < 20; i++) {
            mintInternal();
        }
    }

    /*
 ______     ______     ______     _____     __     __   __     ______    
/\  == \   /\  ___\   /\  __ \   /\  __-.  /\ \   /\ "-.\ \   /\  ___\   
\ \  __<   \ \  __\   \ \  __ \  \ \ \/\ \ \ \ \  \ \ \-.  \  \ \ \__ \  
 \ \_\ \_\  \ \_____\  \ \_\ \_\  \ \____-  \ \_\  \ \_\\"\_\  \ \_____\ 
  \/_/ /_/   \/_____/   \/_/\/_/   \/____/   \/_/   \/_/ \/_/   \/_____/                                                                    
                                                                                           
*/
    function buildHash(uint256 _t) internal view returns (string memory) {
        // This will generate a 8 character string.
        string memory currentHash = "";
        uint256 rInput = tokenIdToStartHash[_t];
        uint256 _nonce = tokenIdToNonce[_t];

        for (uint8 i = 0; i < 8; i++) {
            ++_nonce;
            uint16 _randinput = uint16(
                uint256(keccak256(abi.encodePacked(rInput, _t, _nonce))) % 10000
            );
            currentHash = string(
                abi.encodePacked(
                    currentHash,
                    rarityGen(_randinput, i).toString()
                )
            );
        }
        return currentHash;
    }

    /**
     * @dev Hash to HTML function
     */
    function hashToHTML(string memory _hash, uint256 _tokenId)
        external
        view
        disallowIfStateIsChanging
        returns (string memory)
    {
        string memory htmlString = string(
            abi.encodePacked(
                "data:text/html,%3Chtml%3E%3Chead%3E%3Cscript%20src%3D%22",
                p5jsUrl,
                "%22%20integrity%3D%22",
                p5jsIntegrity,
                "%22%20crossorigin%3D%22anonymous%22%3E%3C%2Fscript%3E%3C%2Fhead%3E%3Cbody%3E%3Cscript%3Evar%20tokenId%3D",
                AnonymiceLibrary.toString(_tokenId),
                "%3Bvar%20hash%3D%22",
                _hash,
                "%22%3B"
            )
        );

        htmlString = string(
            abi.encodePacked(
                htmlString,
                "function%20setup%28%29%7Bs%3D%5B.5%2C1%5D%2Cc%3D%5B0%2C1%5D%2Cn%3D%5B0%2C1%5D%2Cnnw%3D0%2Cci%3D%5B0%2C1%5D%2Cnv%3D%5B%5B.001%2C.0025%5D%2C%5B.0025%2C.01%5D%2C%5B.01%2C.0025%5D%2C%5B.0025%2C.001%5D%2C%5B.001%2C.001%5D%5D%2Cov%3D%5B%5B4500%2C5500%2C6500%2C8e3%5D%2C%5B750%2C950%2C1150%2C1250%5D%2C%5B750%2C950%2C1150%2C1250%5D%2C%5B4500%2C5500%2C6500%2C8e3%5D%2C%5B4e3%2C5e3%2C6e3%2C15e3%5D%5D%2Cp%3D%5B%5B%22%2365010c%22%2C%22%23cb1b16%22%2C%22%23ef3c2d%22%2C%22%23f26a4f%22%2C%22%23f29479%22%2C%22%23fedfd4%22%2C%22%239dcee2%22%2C%22%234091c9%22%2C%22%231368aa%22%2C%22%23033270%22%2C%22%23000%22%2C%22%23faebd7%22%5D%2C%5B%22%230f3375%22%2C%22%2313459c%22%2C%22%231557c0%22%2C%22%23196bde%22%2C%22%232382f7%22%2C%22%234b9cf9%22%2C%22%2377b6fb%22%2C%22%23a4cefc%22%2C%22%23cce4fd%22%2C%22%23e8f3fe%22%2C%22%23000%22%2C%22%23faebd7%22%5D%2C%5B%22%230e0e0e%22%2C%22%23f3bc17%22%2C%22%23d54b0c%22%2C%22%23154255%22%2C%22%23dcdcdc%22%2C%22%23c0504f%22%2C%22%2368b9b0%22%2C%22%23ecbe2c%22%2C%22%232763ab%22%2C%22%23ce4241%22%2C%22%23faebd7%22%2C%22%23000%22%5D%2C%5B%22%23ff0000%22%2C%22%23fe1c00%22%2C%22%23fd3900%22%2C%22%23fc5500%22%2C%22%23fb7100%22%2C%22%23fb8e00%22%2C%22%23faaa00%22%2C%22%23f9c600%22%2C%22%23f8e300%22%2C%22%23f7ff00%22%2C%22%23000%22%2C%22%23faebd7%22%5D%2C%5B%22%23004733%22%2C%22%232b6a4d%22%2C%22%23568d66%22%2C%22%23a5c1ae%22%2C%22%23f3f4f6%22%2C%22%23dcdfe5%22%2C%22%23df8080%22%2C%22%23cb0b0a%22%2C%22%23ad080f%22%2C%22%238e0413%22%2C%22%23000%22%2C%22%23faebd7%22%5D%2C%5B%22%231e1619%22%2C%22%233c2831%22%2C%22%235d424e%22%2C%22%238c6677%22%2C%22%23ad7787%22%2C%22%23ac675b%22%2C%22%23c86166%22%2C%22%23f078b3%22%2C%22%23ec8782%22%2C%22%23dfde80%22%2C%22%23faebd7%22%2C%22%23000%22%5D%2C%5B%22%23008080%22%2C%22%23008080%22%2C%22%23178c8c%22%2C%22%23f7ff00%22%2C%22%2346a3a3%22%2C%22%235daeae%22%2C%22%2374baba%22%2C%22%238bc5c5%22%2C%22%23a2d1d1%22%2C%22%23b5dada%22%2C%22%23000%22%2C%22%23faebd7%22%5D%2C%5B%22%23669900%22%2C%22%2399cc33%22%2C%22%23ccee66%22%2C%22%23006699%22%2C%22%233399cc%22%2C%22%23990066%22%2C%22%23cc3399%22%2C%22%23ff6600%22%2C%22%23ff9900%22%2C%22%23ffcc00%22%2C%22%23000%22%2C%22%23faebd7%22%5D%2C%5B%22%23000%22%2C%22%23fff%22%2C%22%23000%22%2C%22%23fff%22%2C%22%23000%22%2C%22%23fff%22%2C%22%23000%22%2C%22%23fff%22%2C%22%23000%22%2C%22%23fff%22%2C%22%23000%22%2C%22%23fff%22%5D%2C%5B%22%232c6e49%22%2C%22%23618565%22%2C%22%23969c81%22%2C%22%23cbb39d%22%2C%22%23e5beab%22%2C%22%23ffc9b9%22%2C%22%23f5ba9c%22%2C%22%23ebab7f%22%2C%22%23e19c62%22%2C%22%23d68c45%22%2C%22%23000%22%2C%22%23faebd7%22%5D%2C%5B%22%2365010c%22%2C%22%23cb1b16%22%2C%22%23ef3c2d%22%2C%22%23f26a4f%22%2C%22%23f29479%22%2C%22%23fedfd4%22%2C%22%239dcee2%22%2C%22%234091c9%22%2C%22%231368aa%22%2C%22%23033270%22%2C%22%23faebd7%22%2C%22%23000%22%5D%5D%2CcreateCanvas%28700%2C950%29%2CnoiseSeed%28tokenId%29%2CnoLoop%28%29%2CnoStroke%28%29%2CrectMode%28CENTER%29%2CcolorMode%28HSL%29%2CpixelDensity%285%29%2Co%3Dnoise%2Cf%3Dfill%2Cq%3Dwidth%2Ca%3Dheight%2Cg%3DparseInt%28hash.substring%280%2C1%29%29%2B1%2Cz%3DparseInt%28hash.substring%281%2C2%29%29%2Cz2%3Dz%2B1%2Cci%3Dci%5BparseInt%28hash.substring%282%2C3%29%29%5D%2Cw%3Ds%5BparseInt%28hash.substring%283%2C4%29%29%5D%2Cx%3DparseInt%28hash.substring%284%2C5%29%29%2Cxx%3DparseInt%28hash.substring%284%2C5%29%29%2Czz%3DparseInt%28hash.substring%285%2C6%29%29%2Cyy%3DparseInt%28hash.substring%286%2C7%29%29%2Caa%3Dnv%5Bx%5D%5B0%5D%2Cvb%3Dnv%5Bx%5D%5B1%5D%2Cgb%3Dov%5Bxx%5D%5Bzz%5D%2Cff%3D%5B1e-5%2Caa%5D%2Cnnw%3Dff%5BparseInt%28hash.substring%287%2C8%29%29%5D%7Dfunction%20draw%28%29%7Bbackground%28p%5Bz%5D%5B10%5D%29%3B2%3D%3Dx%7C%7C3%3D%3Dx%3Fnn%3Dnnw%3Ann%3Daa%3Bfor%28let%20e%3D25%3Be%3C%3Dq-25%3Be%2B%3Dw%29for%28let%20c%3D25%3Bc%3C%3Da-25%3Bc%2B%3Dw%29n%3Do%28e%2Ann%2Cc%2Aaa%29%2Cn2%3Do%28e%2Avb%2Cc%2Avb%29%2Cn3%3Do%28%28e%2Bgb%2An%29%2Aaa%2C%28c%2Bgb%2An2%29%2Avb%29%2Cn4%3Do%28%28e%2Bgb%2An3%29%2Aaa%2C%28c%2Bgb%2An3%29%2Avb%29%2Cn5%3Do%28%28e%2Bgb%2An4%29%2Aaa%2C%28c%2Bgb%2An4%29%2Avb%29%2C0%3D%3Dyy%3Fe%3Cq%2Fg%3Fn5%3E.58%3FnoFill%28%29%3An5%3E.55%3Ff%28p%5Bz%5D%5B0%5D%29%3An5%3E.53%3Ff%28p%5Bz%5D%5B1%5D%29%3An5%3E.5%3Ff%28p%5Bz%5D%5B2%5D%29%3An5%3E.47%3Ff%28p%5Bz%5D%5B3%5D%29%3An5%3E.44%3FnoFill%28%29%3An5%3E.41%3Ff%28p%5Bz%5D%5B4%5D%29%3An5%3E.38%3Ff%28p%5Bz%5D%5B5%5D%29%3An5%3E.35%3Ff%28p%5Bz%5D%5B6%5D%29%3An5%3E.31%3Ff%28p%5Bz%5D%5B7%5D%29%3An5%3E.28%3Ff%28p%5Bz%5D%5B8%5D%29%3An5%3E.25%3Ff%28p%5Bz%5D%5B9%5D%29%3AnoFill%28%29%3An5%3E.58%3FnoFill%28%29%3An5%3E.55%3Ff%28p%5Bz2%5D%5B0%5D%29%3An5%3E.53%3Ff%28p%5Bz2%5D%5B1%5D%29%3An5%3E.5%3Ff%28p%5Bz2%5D%5B2%5D%29%3An5%3E.47%3Ff%28p%5Bz2%5D%5B3%5D%29%3An5%3E.44%3FnoFill%28%29%3An5%3E.41%3Ff%28p%5Bz2%5D%5B4%5D%29%3An5%3E.38%3Ff%28p%5Bz2%5D%5B5%5D%29%3An5%3E.35%3Ff%28p%5Bz2%5D%5B6%5D%29%3An5%3E.31%3Ff%28p%5Bz2%5D%5B7%5D%29%3An5%3E.28%3Ff%28p%5Bz2%5D%5B8%5D%29%3An5%3E.25%3Ff%28p%5Bz2%5D%5B9%5D%29%3AnoFill%28%29%3A1%3D%3Dyy%3Fn5%3E.6%3FnoFill%28%29%3An5%3E.4%3Ff%28p%5Bz%5D%5B3%5D%29%3AnoFill%28%29%3A2%3D%3Dyy%26%26f%281e3%2An2%2C100%2An5%2C100%2An5%29%2Crect%28e%2Cc%2Cw%29%3B0%3D%3Dci%26%26%28push%28%29%2CnoFill%28%29%2Cstroke%28p%5Bz%5D%5B10%5D%29%2CstrokeWeight%281570%29%2Ccircle%28q%2F2%2Ca%2F2%2C2e3%29%2Cpop%28%29%29%2Cpush%28%29%2CtextSize%283%29%2CtextAlign%28RIGHT%29%2Cf%28p%5Bz%5D%5B11%5D%29%2Ctext%28%22Folded%20Faces.%202022.%22%2Cq-25%2Ca-15%29%2Ctext%28hash%2Cq-25%2Ca-10%29%2Cpop%28%29%7D%3C%2Fscript%3E%3C%2Fbody%3E%3C%2Fhtml%3E"
            )
        );

        return htmlString;
    }

    /**
     * @dev Hash to metadata function
     */
    function hashToMetadata(string memory _hash)
        public
        view
        disallowIfStateIsChanging
        returns (string memory)
    {
        string memory metadataString;

        for (uint8 i = 0; i < 8; i++) {
            uint8 thisTraitIndex = AnonymiceLibrary.parseInt(
                AnonymiceLibrary.substring(_hash, i, i + 1)
            );

            metadataString = string(
                abi.encodePacked(
                    metadataString,
                    '{"trait_type":"',
                    traitTypes[i][thisTraitIndex].traitType,
                    '","value":"',
                    traitTypes[i][thisTraitIndex].traitName,
                    '"}'
                )
            );

            if (i != 7)
                metadataString = string(abi.encodePacked(metadataString, ","));
        }

        return string(abi.encodePacked("[", metadataString, "]"));
    }

    /**
     * @dev Returns the image and metadata for a token Id
     * @param _tokenId The tokenId to return the image and metadata for.
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_tokenId < totalSupply);

        string memory tokenHash = _tokenIdToHash(_tokenId);

        string
            memory description = '", "description": "533 FoldedFaces. Traits generated on chain & metadata, images mirrored on chain permanently.",';

        string memory encodedTokenId = AnonymiceLibrary.encode(
            bytes(string(abi.encodePacked(AnonymiceLibrary.toString(_tokenId))))
        );
        string memory encodedHash = AnonymiceLibrary.encode(
            bytes(string(abi.encodePacked(tokenHash)))
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    AnonymiceLibrary.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name": "FoldedFaces #',
                                    AnonymiceLibrary.toString(_tokenId),
                                    description,
                                    '"external_url":"',
                                    animationUrl,
                                    encodedTokenId,
                                    "&t=",
                                    encodedHash,
                                    '","image":"',
                                    imageUrl,
                                    AnonymiceLibrary.toString(_tokenId),
                                    "&t=",
                                    tokenHash,
                                    '","attributes":',
                                    hashToMetadata(tokenHash),
                                    "}"
                                )
                            )
                        )
                    )
                )
            );
    }

    /**
     * @dev Returns a hash for a given tokenId
     * @param _tokenId The tokenId to return the hash for.
     */
    function _tokenIdToHash(uint256 _tokenId)
        public
        view
        disallowIfStateIsChanging
        returns (string memory)
    {
        require(_tokenId < totalSupply);
        uint256 startHash = tokenIdToStartHash[_tokenId];
        string memory tokenHash = buildHash(startHash);

        return tokenHash;
    }

    /*
 ______     __     __     __   __     ______     ______    
/\  __ \   /\ \  _ \ \   /\ "-.\ \   /\  ___\   /\  == \   
\ \ \/\ \  \ \ \/ ".\ \  \ \ \-.  \  \ \  __\   \ \  __<   
 \ \_____\  \ \__/".~\_\  \ \_\\"\_\  \ \_____\  \ \_\ \_\ 
  \/_____/   \/_/   \/_/   \/_/ \/_/   \/_____/   \/_/ /_/ 
                                                           
    /**
     * @dev Add a trait type
     * @param _traitTypeIndex The trait type index
     * @param traits Array of traits to add
     */

    function addTraitType(uint256 _traitTypeIndex, Trait[] memory traits)
        external
        payable
        onlyOwner
    {
        for (uint256 i = 0; i < traits.length; i++) {
            traitTypes[_traitTypeIndex].push(
                Trait(traits[i].traitName, traits[i].traitType)
            );
        }

        return;
    }

    function addContributorMint(address _account) external payable onlyOwner {
        contributorMints[_account] = true;
    }

    function flipMintingSwitch() external payable onlyOwner {
        MINTING_LIVE = !MINTING_LIVE;
    }

    /**
     * @dev Sets the p5js url
     * @param _p5jsUrl The address of the p5js file hosted on CDN
     */

    function setJsAddress(string memory _p5jsUrl) external payable onlyOwner {
        p5jsUrl = _p5jsUrl;
    }

    /**
     * @dev Sets the p5js resource integrity
     * @param _p5jsIntegrity The hash of the p5js file (to protect w subresource integrity)
     */

    function setJsIntegrity(string memory _p5jsIntegrity)
        external
        payable
        onlyOwner
    {
        p5jsIntegrity = _p5jsIntegrity;
    }

    /**
     * @dev Sets the base image url
     * @param _imageUrl The base url for image field
     */

    function setImageUrl(string memory _imageUrl) external payable onlyOwner {
        imageUrl = _imageUrl;
    }

    function setAnimationUrl(string memory _animationUrl)
        external
        payable
        onlyOwner
    {
        animationUrl = _animationUrl;
    }

    function withdraw() external payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }
}