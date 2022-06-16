// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC721} from 'solmate/tokens/ERC721.sol';
import {Base64} from 'base64/base64.sol';

import {Ownable} from './Ownable.sol';
import {VersionedInitializable} from './upgradeability/VersionedInitializable.sol';
import {IBoringCollection} from './interfaces/IBoringCollection.sol';
import {IBoredNFT} from './interfaces/IBoredNFT.sol';

contract BoredNFT is VersionedInitializable, Ownable, IBoredNFT, ERC721 {
  mapping(address => CollectionConfig) internal _collectionConfigs;
  mapping(uint256 => Outfit) internal _boringOutfits;
  uint256 public count;

  uint256 internal constant REVISION = 1;

  constructor(address[] memory collections)
    ERC721('BoredGhostsAlphaIMPL', 'BoredGhostsAlphaIMPL')
  {}

  function initialize(
    address masterOfGhosts,
    string calldata tokenName,
    string calldata tokenSymbol,
    address[] calldata collections
  ) external initializer {
    name = tokenName;
    symbol = tokenSymbol;

    _configureCollections(collections);

    _transferOwnership(masterOfGhosts);
  }

  function getRevision() internal pure override returns (uint256) {
    return REVISION;
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    return
      string(
        abi.encodePacked(
          'data:application/json;base64,',
          Base64.encode(
            bytes(string(abi.encodePacked('{"image_data": "', _getSvg(tokenId), '"', '}')))
          )
        )
      );
  }

  function configureCollection(address[] calldata collections) external onlyOwner {
    _configureCollections(collections);
  }

  function mint(address to) public override onlyOwner {
    _safeMint(to, count++);
  }

  function wear(uint256 tokenId, Outfit calldata newOutfit) external override {
    require(msg.sender == ownerOf(tokenId), 'Is it you on the photo? Let me talk with my manager');

    Outfit memory currentOutfit = _boringOutfits[tokenId];

    if (currentOutfit.location != address(0)) {
      _markOutfitAsAvailable(tokenId, currentOutfit.location, currentOutfit.id);
    }
    if (newOutfit.location != address(0)) {
      _markOutfitAsBorrowed(tokenId, newOutfit.location, newOutfit.id);
    } else {
      require(newOutfit.id == 0, 'Sorry, but we have only one casual outfit at the moment');
    }

    _boringOutfits[tokenId] = newOutfit;
  }

  function casualOutfit() public pure override returns (string memory) {
    return
      "<path class='st3' d='M564.3,380.3h0c0,13.8-14.3,13.8-14.3,27.7s14.3,13.9,14.3,27.8S550,449.8,550,463.6s14.3,13.9,14.3,27.8S550,505.3,550,519.2h0'/><path class='st3' d='M705.4,380.3h0c0,13.8-14.3,13.8-14.3,27.7s14.3,13.9,14.3,27.8-14.3,13.9-14.3,27.7,14.3,13.9,14.3,27.8-14.3,13.9-14.3,27.8h0'/><path class='st3' d='M667.1,311.3a242,242,0,0,0-166.7-27.9c-120.4,23-203.3,133.9-200,254.4,0,19.8,110.1,35.8,245.9,35.8s245.9-16,245.9-35.8c.3-16.9.4-155.1-131.5-230.120'/>";
  }

  function collectionConfigs(address collection) external view returns (CollectionConfig memory) {
    return _collectionConfigs[collection];
  }

  function boringOutfits(uint256 tokenId) external view returns (Outfit memory) {
    return _boringOutfits[tokenId];
  }

  function _configureCollections(address[] memory collections) internal {
    CollectionConfig memory collectionConfig;

    for (uint256 i = 0; i < collections.length; i++) {
      collectionConfig = _collectionConfigs[collections[i]];

      if (collectionConfig.outfitsCount == 0) {
        collectionConfig.outfitsCount = IBoringCollection(collections[i]).collectionSize();
        require(
          collectionConfig.outfitsCount != 0,
          'Not match to wear actually, not worth it to add'
        );
        _collectionConfigs[collections[i]] = collectionConfig;

        emit NewSeasonArrived(collections[i], collectionConfig.outfitsCount);
      }
    }
  }

  function _markOutfitAsAvailable(
    uint256 tokenId,
    address outfitLocation,
    uint8 outfitId
  ) internal {
    CollectionConfig memory collectionConfig = _collectionConfigs[outfitLocation];

    require(
      collectionConfig.outfitsCount > outfitId,
      'Never saw it before, not sure that we need it'
    );

    collectionConfig.woreMap ^= uint240(2**outfitId);
    _collectionConfigs[outfitLocation] = collectionConfig;

    emit OutfitReturned(tokenId, outfitLocation, outfitId);
  }

  function _markOutfitAsBorrowed(
    uint256 tokenId,
    address outfitLocation,
    uint8 outfitId
  ) internal {
    CollectionConfig memory collectionConfig = _collectionConfigs[outfitLocation];

    require(collectionConfig.outfitsCount > outfitId, "Well, we don't have that many");
    require(
      (collectionConfig.woreMap & (2**outfitId)) == 0,
      'Sorry, last week one ghost took it already, maybe he will return, come back later'
    );

    collectionConfig.woreMap |= uint240(2**outfitId);
    _collectionConfigs[outfitLocation] = collectionConfig;

    emit OutfitBorrowed(tokenId, outfitLocation, outfitId);
  }

  function _getSvg(uint256 tokenId) internal view returns (string memory) {
    Outfit memory outfit = _boringOutfits[tokenId];
    return
      string(
        abi.encodePacked(
          "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 1080 1080'><defs><style>.st0{fill:#fcf9f5}.st1{fill:#c4c2bf}.st2{fill:#c4bfb8}.st3{fill:none;stroke:#1d1d1b;stroke-width:13.8849;stroke-linecap:round;stroke-linejoin:round;stroke-miterlimit:10}.st4{fill:#1d1d1b}.st10,.st11,.st12,.st5,.st6,.st7,.st8,.st9{fill:#c4bfb8;stroke:#1d1d1b;stroke-width:13.8849;stroke-linecap:round;stroke-linejoin:round;stroke-miterlimit:10}.st10,.st11,.st12,.st6,.st7,.st8,.st9{fill:#fcf9f5}.st10,.st11,.st12,.st7,.st8,.st9{fill:#1d1d1b;stroke-width:13.8853}.st10,.st11,.st12,.st8,.st9{fill:none;stroke-width:15.2225}.st10,.st11,.st12,.st9{stroke-width:14.4199}.st10,.st11,.st12{fill:#1d1d1b;stroke:#fcfaf6;stroke-width:13.8849}.st11,.st12{fill:none;stroke:#1d1d1b;stroke-width:14.4136}.st12{fill:#fcf9f5;stroke-width:11.8913}.st13{fill-rule:evenodd;clip-rule:evenodd;fill:#1d1d1b}.st14{fill:#fff}</style></defs><path class='st0' d='M-2-2.3h1084v1084.54H-2z'/><g><animateTransform attributeName='transform' type='translate' keyTimes='0;0.5;1' values='0 20; 0 -20; 0 20' dur='6s' repeatCount='indefinite'/><g><path class='st2' d='M367.6 673.3c-7.5-12.7-58-10.9-58-10.9s5 38.3 35.9 83.4c-14.1 69.2-96.4 62.5-96.4 62.5s64.1 79.8 174.7 12.1c219.9 110.8 335-91.6 335-91.6-82.5 80.5-285.1 124.1-391.2-55.5Z'/><path class='st3' d='M304.3 651.5a246.1 246.1 0 0 0 38.4 92.8c-9.4 78.2-99.1 61.8-99.1 61.8 62.7 66.5 138 47.1 179.2 12.6h0a245.4 245.4 0 0 0 168.9 28.9c102.9-19.4 178.1-98.6 196-195.7'/><path class='st4' d='M794.6 650.9c0 31.1-111.3 47.2-248.6 47.2s-248.7-17.5-248.7-47.2 111.3-46 248.7-46 248.6 16.9 248.6 46Z'/></g><g>",
          outfit.location == address(0)
            ? casualOutfit()
            : IBoringCollection(outfit.location).getOutfit(outfit.id),
          "</g></g><g transform='translate(546 935)'><ellipse class='st2' rx='150.1' ry='29.5'><animateTransform attributeName='transform' type='scale' keyTimes='0;0.5;1' values='1;0.5;1' dur='6s' repeatCount='indefinite'/></ellipse></g></svg>"
        )
      );
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

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
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
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
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
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
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

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

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
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import './upgradeability/Context.sol';

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
contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
    address msgSender = _msgSender();
    _transferOwnership(msgSender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == _msgSender(), 'Ownable: caller is not the owner');
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
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal {
     _owner = newOwner;
     emit OwnershipTransferred(_owner, newOwner);
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

/**
 * @title VersionedInitializable
 * @author Aave, inspired by the OpenZeppelin Initializable contract
 * @notice Helper contract to implement initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * @dev WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
abstract contract VersionedInitializable {
  /**
   * @dev Indicates that the contract has been initialized.
   */
  uint256 private lastInitializedRevision = 0;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    uint256 revision = getRevision();
    require(
      initializing || isConstructor() || revision > lastInitializedRevision,
      'Contract instance has already been initialized'
    );

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      lastInitializedRevision = revision;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /**
   * @notice Returns the revision number of the contract
   * @dev Needs to be defined in the inherited class as a constant.
   * @return The revision number
   **/
  function getRevision() internal pure virtual returns (uint256);

  /**
   * @notice Returns true if and only if the function is running in the constructor
   * @return True if the function is running in the constructor
   **/
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    uint256 cs;
    //solium-disable-next-line
    assembly {
      cs := extcodesize(address())
    }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBoringCollection {
  function collectionSize() external view returns (uint8);

  function getOutfits(uint8 _from, uint8 _to) external view returns (string[] memory);

  function getOutfit(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBoredNFT {
  struct CollectionConfig {
    uint8 outfitsCount;
    uint240 woreMap;
  }

  struct Outfit {
    address location;
    uint8 id;
    //string name; //TODO: maybe return it back
  }
  event NewSeasonArrived(address outfitLocation, uint256 count);
  event OutfitBorrowed(uint256 tokenId, address outfitLocation, uint64 outfitId);
  event OutfitReturned(uint256 tokenId, address outfitLocation, uint64 outfitId);

  function count() external view returns (uint256);

  function collectionConfigs(address collection) external view returns (CollectionConfig memory);

  function boringOutfits(uint256 tokenId) external view returns (Outfit memory);

  function configureCollection(address[] calldata collections) external;

  function mint(address to) external;

  function wear(uint256 tokenId, Outfit calldata attributes) external;

  function casualOutfit() external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
  function _msgSender() internal view virtual returns (address payable) {
    return payable(msg.sender);
  }

  function _msgData() internal view virtual returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}