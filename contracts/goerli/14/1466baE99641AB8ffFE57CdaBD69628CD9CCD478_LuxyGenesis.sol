// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

import "./tokens/ERC721/ERC721URIStorage.sol";
import "./safeguard/Pauser.sol";
//import "./RoyaltiesV1Luxy.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./interfaces/IPegasysPair.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

interface INFTBridge {
    function sendMsg(
        uint64 _dstChid,
        address _sender,
        address _receiver,
        uint256 _id,
        string calldata _uri
    ) external payable;

    function sendMsg(
        uint64 _dstChid,
        address _sender,
        bytes calldata _receiver,
        uint256 _id,
        string calldata _uri
    ) external payable;

    function totalFee(
        uint64 _dstChid,
        address _nft,
        uint256 _id
    ) external view returns (uint256);
}

// Multi-Chain Native NFT, same contract on all chains. User interacts with this directly.
contract LuxyGenesis is ERC721URIStorage, Pauser {
    using Strings for uint256;

    event NFTBridgeUpdated(address);
   
    address public nftBridge;
    address public artist;
    address public luxyLaunchpadFeeManager;
    uint256 public constant MAX_BATCH_MINT = 9;
    uint256 public constant MAX_SUPPLY_PER_CHAIN = 5;
    uint256 public constant DROP_START_TIME = 0;
    uint256 public constant WHITELIST_EXPIRE_TIME = 1 days;
    uint256 public requiredPriceInUsd = 1 * 1e16;
    uint256 public offset;
    uint256 public nativeGenesisSupply;
    uint256 public genesisSupply;
    uint256 public genesisCirculantSupply = nativeGenesisSupply + genesisSupply;
    uint256 public whitelistSize;
    string constant IPFS_HASH =
        "bafybeiaz5c3ukotvo6knkmp7tmascceuwnkeuordjp6sotukhj2m47nfi4";

    
    AggregatorV3Interface internal nativePriceFeed;
    IPegasysPair pegasysInterface = IPegasysPair(0x2CDF912CbeaF76d67feaDC994D889c2F4442b300);//Syscoin mainnet LP

    mapping(address => bool) private _whitelist;
    mapping(uint256 => uint256) private _assignOrders;

        enum Rarity {
        EGG,
        FORGOTTEN_ballon,
        LEAST_CONCERN,
        DOMESTICATED,
        NEAR_THREATENED
    }

      struct Metadata {
        uint32 ballonId;
        uint32 level;
        Rarity rarity;
    }

    struct Ballons {
        uint32 numberInGame;
        Rarity rarity;
        string name;
    }

    mapping(uint256 => Ballons) public ballons;
    /// @notice Mapping from token ID to NFT Metadata
    mapping(uint256 => Metadata) public metadata;

    error NotBridge();
    error InvalidAmountToMint();
    error TimeOut();
    error ExceedsMaxBatch();

    constructor(
      //  string memory _uri,
        address _nftBridge,
        address _luxyLaunchpadFeeManager
    ) ERC721("LuxyGenesis", "LuxyGenesis") {
        nftBridge = _nftBridge;
      //  baseURI = _uri;
        luxyLaunchpadFeeManager= _luxyLaunchpadFeeManager;
         if (block.chainid == 1) {
            nativePriceFeed  = AggregatorV3Interface(
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        );///eth/usd mainnet
        offset = 0; //TODO: validate minting on goerli fork from offset to offset + MAX_SUPPLY_PER_CHAIN
         }
         if (block.chainid == 137) {
            nativePriceFeed  = AggregatorV3Interface(
            0xAB594600376Ec9fD91F8e885dADF0CE036862dE0
        );  ///matic/usd
        offset = 2000; //TODO: validate minting on mumbai fork from offset to offset + MAX_SUPPLY_PER_CHAIN
         }
        if (block.chainid == 5) {
            nativePriceFeed  = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );  ///ETH/usd goerli
        offset = 0;  //TODO: validate minting on this fork from 0 to MAX_SUPPLY_PER_CHAIN
         }
         if (block.chainid == 80001) {
            nativePriceFeed  = AggregatorV3Interface(
            0x0715A7794a1dc8e42615F059dD6e406A6594651A
        );  ///matic/usd mumbai
         offset = 5;
         }
         if (block.chainid == 57 || block.chainid == 5700) {
              offset = 4000;
         }
        ballons[0] = Ballons(0, Rarity.DOMESTICATED, "Southern White ");
        ballons[1] = Ballons(1, Rarity.DOMESTICATED, "Hippopamus");
    }

    modifier onlyNftBridge() {
        if (msg.sender != nftBridge) revert NotOwner();
        _;
    }
    

    function getLatestPrice() public view returns (int) {
        // prettier-ignore
        (
            /* uint80 roundID */,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = nativePriceFeed.latestRoundData();
        return price;
    }

    function generateTokenId() public returns (uint256) {
        uint256 genesisRemainingToAssign = MAX_SUPPLY_PER_CHAIN - nativeGenesisSupply -1;
        if (genesisRemainingToAssign == 0) {
            genesisRemainingToAssign = 1;
        }
        
        uint256 randIndex = _random() % genesisRemainingToAssign;
        uint256 genesisIndex = _fillAssignOrder(
                genesisRemainingToAssign,
                randIndex
            );
        uint lastTokenId = genesisIndex + offset;
        return lastTokenId;
    }

    function getPriceToMint() public view returns (uint priceToMint) {
        int price = getLatestPrice();
        uint256 ethUsdPrice = uint256(price) * 1e10;
        priceToMint = (requiredPriceInUsd * 1e18) / ethUsdPrice;

    }
    function getPriceToMintSYS() view public returns (uint256) {
        (uint112 reserve0, uint112 reserve1, ) = pegasysInterface.getReserves(); 
        uint256 sysWeiPrice = reserve1/(reserve0);
        uint256 sysMintPriceWei = sysWeiPrice*10**6;
        return sysMintPriceWei*100;
    }

    function bridgeMint(
        address to,
        uint256 id
    ) external onlyNftBridge {
        _mint(to, id);
        uint ballonType = id%2;
        Ballons memory drawnGenesis = ballons[ballonType];

         metadata[id] = Metadata(
            uint32(id),
            1, // level
           // drawnGenesis.rank, // rank
            drawnGenesis.rarity // rarity
        );
        if(id > offset + MAX_SUPPLY_PER_CHAIN || id < offset){
            genesisSupply++; 
        } else {
            nativeGenesisSupply++;
        }
      
    }

    // calls nft bridge to get total fee for crossChain msg.Value
    function totalFee(uint64 _dstChid, uint256 _id) external view returns (uint256) {
        return INFTBridge(nftBridge).totalFee(_dstChid, address(this), _id);
    }

    // called by user, burn token on this chain and mint same id/uri on dest chain
    function crossChain(
        uint64 _dstChid,
        uint256 _id,
        address _receiver
    ) external payable whenNotPaused {
        if (msg.sender != ownerOf[_id]) revert NotOwner();
        string memory _uri = tokenURI(_id);
        _burn(_id);
        INFTBridge(nftBridge).sendMsg{value: msg.value}(_dstChid, msg.sender, _receiver, _id, _uri);
    }

    // support chains using bytes for address
    function crossChain(
        uint64 _dstChid,
        uint256 _id,
        bytes calldata _receiver
    ) external payable whenNotPaused {
        if (msg.sender != ownerOf[_id]) revert NotOwner();
        string memory _uri = tokenURI(_id);
        _burn(_id);
        INFTBridge(nftBridge).sendMsg{value: msg.value}(_dstChid, msg.sender, _receiver, _id, _uri);
    }

    function mint(
        address to,
        uint num
    ) external payable{
        if (genesisSupply > MAX_SUPPLY_PER_CHAIN ) revert MaxSupplyOut();
        if (_msgSender() != luxyLaunchpadFeeManager) revert InvalidOwner();
        if (block.timestamp < DROP_START_TIME) revert TimeOut();
        if (num > MAX_BATCH_MINT) revert ExceedsMaxBatch();

        for (uint256 i; i < num; i++) {
        uint256 randomId = generateTokenId(); //TODO: validate the generatedTokenId per chain considering the offsets - goerli should go from 0 to 9 / mumbai from 10 to 19
        _mint(to,  randomId);
        nativeGenesisSupply++;
        // string memory _uri = string(abi.encodePacked("/", randomId));
        // _setTokenURI(randomId, _uri);
        uint ballonType = randomId%2;
        Ballons memory drawnGenesis = ballons[ballonType];

         metadata[randomId] = Metadata(
            uint32(randomId),
            1, // level
           // drawnGenesis.rank, // rank
            drawnGenesis.rarity // rarity
        );
        }
    }

    function setNFTBridge(address _newBridge) public onlyOwner {
        nftBridge = _newBridge;
        emit NFTBridgeUpdated(_newBridge);
    }


    function _burn(uint256 id) internal virtual override {
        super._burn(id);
        if(id > offset + MAX_SUPPLY_PER_CHAIN || id < offset){
            genesisSupply--; 
        } else {
            nativeGenesisSupply--;
        }
        }
        /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 _interfaceId)
        public
        pure
        override(
            ERC721///,IERC165Upgradeable
        )
        returns (bool)
    {
        return
          //  _interfaceId == type(RoyaltiesV1Luxy).interfaceId ||
         //   _interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(_interfaceId);
    }
    function isWhitelisted(address addr) public view returns (bool) {
        return _whitelist[addr];
    }

    function addToWhitelist(address[] memory addresses) external onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            if (!isWhitelisted(addresses[i])) {
                _whitelist[addresses[i]] = true;
                whitelistSize++;
            }
        }
    }

    function removeFromWhitelist(address[] memory addresses)
        external
        onlyOwner
    {
        for (uint i = 0; i < addresses.length; i++) {
            if (isWhitelisted(addresses[i])) {
                _whitelist[addresses[i]] = false;
                whitelistSize--;
            }
        }
    }
    function _fillAssignOrder(uint256 orderA, uint256 orderB)
        internal
        returns (uint256)
    {
        uint256 temp = orderA;
        if (_assignOrders[orderA] > 0) temp = _assignOrders[orderA];
        _assignOrders[orderA] = orderB;
        if (_assignOrders[orderB] > 0)
            _assignOrders[orderA] = _assignOrders[orderB];
        _assignOrders[orderB] = temp;
        return _assignOrders[orderA];
    }

    // pseudo-random function that's pretty robust because of syscoin's pow chainlocks
    function _random() internal view returns (uint256) {
        uint256 genesisRemainingToAssign = MAX_SUPPLY_PER_CHAIN - nativeGenesisSupply;
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp +
                            block.difficulty +
                            ((
                                uint256(
                                    keccak256(abi.encodePacked(block.coinbase))
                                )
                            ) / block.timestamp) +
                            block.gaslimit +
                            ((
                                uint256(
                                    keccak256(abi.encodePacked(_msgSender()))
                                )
                            ) / block.timestamp) +
                            block.number
                    )
                )
            ) / genesisRemainingToAssign;
    
}
    /**
     * @notice Handler for matching Rarity element with corresponding string equivalent.
     * @dev Done in assembly because eternal if-elses are ugly.
     */
    function matchRarity(
        uint256 rarityNum
    ) public pure returns (string memory rarityName) {
        require(rarityNum != 0, "Eggs have no rarity");
        require(rarityNum < 9, "There are only 8 rarity cases");
        bytes memory result = new bytes(32);
        assembly {
            switch rarityNum
            case 1 {
                mstore(add(result, 32), "Forgotten Animal")
                mstore(result, 16)
            }
            case 2 {
                mstore(add(result, 32), "Least Concern")
                mstore(result, 13)
            }
            case 3 {
                mstore(add(result, 32), "Domesticated")
                mstore(result, 12)
            }
            case 4 {
                mstore(add(result, 32), "Near Threatened")
                mstore(result, 15)
            }
            case 5 {
                mstore(add(result, 32), "Vulnerable")
                mstore(result, 10)
            }
            case 6 {
                mstore(add(result, 32), "Endangered")
                mstore(result, 10)
            }
            case 7 {
                mstore(add(result, 32), "Critically Endangered")
                mstore(result, 21)
            }
            case 8 {
                mstore(add(result, 32), "Extinct")
                mstore(result, 7)
            }
        }
        return string(result);
    }
   /**
     * @notice Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     * @dev Returns an array of bytes representing the { Base64 } encoded version of the dataURI with the JSON data instructions.
     * Since abi.encodePacked() can only take a maximum of 12 parameters, metadata assembly is split into multiple phases.
     * @param tokenId uint256 ID of the token to query.
     */
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        _requireMinted(tokenId);
        // load both structs into memory for handling
        Metadata memory token = metadata[tokenId];
        Ballons memory ballon = ballons[uint(token.ballonId)];
   
        // traits formatting
        bytes memory traits;
        if (token.level > 0) {
            traits = abi.encodePacked(
                uint256(token.ballonId).toString(),
                "/",
                uint256(token.level).toString(),
                "-",
               // uint256(token.variant).toString(),
                '.png","attributes": [{"trait_type": "Rarity", "value": "',
                uint256(token.rarity).toString(),
                abi.encodePacked(
             //       '"}, {"trait_type": "Variant", "value": "',
              //      uint256(token.variant).toString(),
                    '"}, {"trait_type": "Level", "value": "',
                    uint256(token.level).toString()
                )
            );
        } else {
            traits = abi.encodePacked(
                'egg.png","attributes": [{"trait_type": "Level", "value": "',
                uint256(token.level).toString(),
                '"}, {"trait_type": "Rarity", "value": "',
                uint256(token.rarity).toString()
            );
        }
        // description formatting
        bytes memory description;
        if (token.level > 0) {
            description = abi.encodePacked(
                '"description": "Gensis #',
                tokenId.toString(),
                " is a level ",
                uint256(token.level).toString(),
                " ballon from the ",
                ballon.name,
                " species, which is currently under ",
                matchRarity(uint256(token.rarity)),
                " status. ",
                abi.encodePacked(
                    ". Out of the ",
                    uint256(ballon.numberInGame).toString(),
                    'Ballons of this species in the game, only "'
                )
            );
        } else {
            description = abi.encodePacked(
                '"description": "Genesis #',
                tokenId.toString()
            );
        }
        // assemble json
        bytes memory json = abi.encodePacked(
            '{"name": "Genesis #',
            tokenId.toString(),
            '", ',
            string(description),
            ', "image": "ipfs://',
            IPFS_HASH,
            "/",
            string(traits),
            '"}]}'
        );
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(json)
                )
            );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IPegasysPair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "@openzeppelin/contracts/security/Pausable.sol";
import "./Ownable.sol";

abstract contract Pauser is Ownable, Pausable {
    mapping(address => bool) public pausers;

    event PauserAdded(address account);
    event PauserRemoved(address account);

    constructor() {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender), "Caller is not pauser");
        _;
    }

    function pause() public onlyPauser {
        _pause();
    }

    function unpause() public onlyPauser {
        _unpause();
    }

    function isPauser(address account) public view returns (bool) {
        return pausers[account];
    }

    function addPauser(address account) public onlyOwner {
        _addPauser(account);
    }

    function removePauser(address account) public onlyOwner {
        _removePauser(account);
    }

    function renouncePauser() public {
        _removePauser(msg.sender);
    }

    function _addPauser(address account) private {
        require(!isPauser(account), "Account is already pauser");
        pausers[account] = true;
        emit PauserAdded(account);
    }

    function _removePauser(address account) private {
        require(isPauser(account), "Account is not pauser");
        pausers[account] = false;
        emit PauserRemoved(account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.4;

import "./ERC721.sol";
import "../../utils/Strings.sol";


/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;



    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (ownerOf[tokenId] != address(0)) revert AlreadyMinted();

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
      if (ownerOf[tokenId] == address(0)) revert NotMinted();
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.4;

import "../../utils/Strings.sol";

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Modified from Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
/// License-Identifier: AGPL-3.0-only
interface ERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/// @notice Modern and gas efficient ERC-721 + ERC-20/EIP-2612-like implementation.
abstract contract ERC721 {
    using Strings for uint256;
    /*///////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed spender, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*///////////////////////////////////////////////////////////////
                            ERRORS
    //////////////////////////////////////////////////////////////*/

    error NotApproved();
    
    error NotOwner();

    error InvalidRecipient();

    error SignatureExpired();

    error InvalidSignature();

    error AlreadyMinted();

    error NotMinted();

    error MaxSupplyOut();

    /*///////////////////////////////////////////////////////////////
                            METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/
    
    string public name;

    string public symbol;

    string public baseURI = "";

    //function tokenURI(uint256 tokenId) public view virtual returns (string memory);
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        address owner = ownerOf[tokenId];
        if(owner != address(0)) return true ;
        if(owner == address(0)) return false;
    }
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    function _baseURI() internal view virtual returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory baseURI_) external {
           baseURI = baseURI_;
        }

    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        if (ownerOf[tokenId] == address(0)) revert NotMinted();

        string memory baseURI_ = _baseURI();
        return bytes(baseURI_).length > 0 ? string(abi.encodePacked(baseURI_, tokenId.toString())) : "";
    }
    /*///////////////////////////////////////////////////////////////
                            ERC-721 STORAGE
    //////////////////////////////////////////////////////////////*/
    
    uint256 public totalSupply;
    
    mapping(address => uint256) public balanceOf;

    mapping(uint256 => address) public ownerOf;

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                            EIP-2612-LIKE STORAGE
    //////////////////////////////////////////////////////////////*/
    
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256('Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)');

    bytes32 public constant PERMIT_ALL_TYPEHASH = 
        keccak256('Permit(address owner,address spender,uint256 nonce,uint256 deadline)');
    
    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(uint256 => uint256) public nonces;

    mapping(address => uint256) public noncesForAll;
    
    /*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    
    constructor(string memory name_, string memory symbol_) {
        name = name_;
        
        symbol = symbol_;
        
        INITIAL_CHAIN_ID = block.chainid;
        
        INITIAL_DOMAIN_SEPARATOR = _computeDomainSeparator();
    }



    /*///////////////////////////////////////////////////////////////
                            ERC-721 LOGIC
    //////////////////////////////////////////////////////////////*/
    
    function approve(address spender, uint256 tokenId) public virtual {
        address owner = ownerOf[tokenId];

        if (msg.sender != owner && !isApprovedForAll[owner][msg.sender]) revert NotApproved();
        
        getApproved[tokenId] = spender;
        
        emit Approval(owner, spender, tokenId); 
    }
    
    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;
        
        emit ApprovalForAll(msg.sender, operator, approved);
    }
    
    function transfer(address to, uint256 tokenId) public virtual returns (bool) {
        if (msg.sender != ownerOf[tokenId]) revert NotOwner();

        if (to == address(0)) revert InvalidRecipient();
        
        // underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow
        unchecked {
            balanceOf[msg.sender]--; 
        
            balanceOf[to]++;
        }
        
        delete getApproved[tokenId];
        
        ownerOf[tokenId] = to;
        
        emit Transfer(msg.sender, to, tokenId); 
        
        return true;
    }

    function transferFrom(
        address from, 
        address to, 
        uint256 tokenId
    ) public virtual {
        if (from != ownerOf[tokenId]) revert NotOwner();

        if (to == address(0)) revert InvalidRecipient();
        
        if (msg.sender != from 
            && msg.sender != getApproved[tokenId]
            && !isApprovedForAll[from][msg.sender]
        ) revert NotApproved();  
        
        // underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow
        unchecked { 
            balanceOf[from]--; 
        
            balanceOf[to]++;
        }
        
        delete getApproved[tokenId];
        
        ownerOf[tokenId] = to;
        
        emit Transfer(from, to, tokenId); 
    }
    
    function safeTransferFrom(
        address from, 
        address to, 
        uint256 tokenId
    ) public virtual {
        transferFrom(from, to, tokenId); 

        if (to.code.length != 0 
            && ERC721TokenReceiver(to).onERC721Received(msg.sender, from, tokenId, '') 
            != ERC721TokenReceiver.onERC721Received.selector
        ) revert InvalidRecipient();
    }
    
    function safeTransferFrom(
        address from, 
        address to, 
        uint256 tokenId, 
        bytes memory data
    ) public virtual {
        transferFrom(from, to, tokenId); 
        
        if (to.code.length != 0 
            && ERC721TokenReceiver(to).onERC721Received(msg.sender, from, tokenId, data) 
            != ERC721TokenReceiver.onERC721Received.selector
        ) revert InvalidRecipient();
    }

    /*///////////////////////////////////////////////////////////////
                            ERC-165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return
            interfaceId == 0x80ac58cd || // ERC-165 Interface ID for ERC-721
            interfaceId == 0x5b5e139f || // ERC-165 Interface ID for ERC-165
            interfaceId == 0x01ffc9a7; // ERC-165 Interface ID for ERC-721 Metadata
    }

    /*///////////////////////////////////////////////////////////////
                            EIP-2612-LIKE LOGIC
    //////////////////////////////////////////////////////////////*/
    
    function permit(
        address spender,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        if (block.timestamp > deadline) revert SignatureExpired();
        
        address owner = ownerOf[tokenId];
        
        // cannot realistically overflow on human timescales
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    '\x19\x01',
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, spender, tokenId, nonces[tokenId]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

            if (recoveredAddress == address(0)) revert InvalidSignature();

            if (recoveredAddress != owner && !isApprovedForAll[owner][recoveredAddress]) revert InvalidSignature(); 
        }
        
        getApproved[tokenId] = spender;

        emit Approval(owner, spender, tokenId);
    }
    
    function permitAll(
        address owner,
        address operator,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        if (block.timestamp > deadline) revert SignatureExpired();
        
        // cannot realistically overflow on human timescales
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    '\x19\x01',
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_ALL_TYPEHASH, owner, operator, noncesForAll[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

            if (recoveredAddress == address(0)) revert InvalidSignature();

            if (recoveredAddress != owner && !isApprovedForAll[owner][recoveredAddress]) revert InvalidSignature();
        }
        
        isApprovedForAll[owner][operator] = true;

        emit ApprovalForAll(owner, operator, true);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : _computeDomainSeparator();
    }

    function _computeDomainSeparator() internal view virtual returns (bytes32) {
        return 
            keccak256(
                abi.encode(
                    keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                    keccak256(bytes(name)),
                    keccak256(bytes('1')),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
                            MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/
    
    function _mint(address to, uint256 tokenId) internal virtual { 
        if (to == address(0)) revert InvalidRecipient();

        if (ownerOf[tokenId] != address(0)) revert AlreadyMinted();
  
        // cannot realistically overflow on human timescales
        unchecked {
            totalSupply++;
            
            balanceOf[to]++;
        }
        
        ownerOf[tokenId] = to;
        
        emit Transfer(address(0), to, tokenId); 
    }
    
    function _burn(uint256 tokenId) internal virtual { 
        address owner = ownerOf[tokenId];

        if (ownerOf[tokenId] == address(0)) revert NotMinted();
        
        // ownership check ensures no underflow
        unchecked {
            totalSupply--;
        
            balanceOf[owner]--;
        }
        
        delete ownerOf[tokenId];
        
        delete getApproved[tokenId];
        
        emit Transfer(owner, address(0), tokenId); 
    }
}

// SPDX-License-Identifier: GPL-3.0-only

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
 *
 * This adds a normal func that setOwner if _owner is address(0). So we can't allow
 * renounceOwnership. So we can support Proxy based upgradable contract
 */
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    error InvalidOwner();
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(msg.sender);
    }

    /**
     * @dev Only to be called by inherit contracts, in their init func called by Proxy
     * we require _owner == address(0), which is only possible when it's a delegateCall
     * because constructor sets _owner in contract state.
     */
    function initOwner() internal {
        require(_owner == address(0), "owner already set");
        _setOwner(msg.sender);
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
        if (owner() != msg.sender) revert InvalidOwner();
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
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
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
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