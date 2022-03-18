// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "../game/interfaces/Interfaces.sol";

/**
 * @title Celestial Castle
 * @notice Edited from EtherOrcsOfficial/etherOrcs-contracts.
 */
contract CelestialCastle is Ownable, IERC721Receiver {
  bool public isTravelEnabled;
  /// @notice Celestial portal contract.
  PortalLike public portal;
  /// @notice Freaks N Guilds token contract.
  IFnG public freaksNGuilds;
  /// @notice Freaks bucks token contract.
  IFBX public freaksBucks;

  /// @notice Contract address to it's reflection.
  mapping(address => address) public reflection;
  /// @notice Original token id owner.
  mapping(uint256 => address) public ownerOf;

  /// @notice Require that the sender is the portal for bridging operations.
  modifier onlyPortal() {
    require(msg.sender == address(portal), "CelestialCastle: sender is not the portal");
    _;
  }

  /// @notice Initialize the contract.
  function initialize(
    address newPortal,
    address newFreaksNGuilds,
    address newFreaksBucks,
    bool newIsTravelEnabled
  ) external onlyOwner {
    portal = PortalLike(newPortal);
    freaksNGuilds = IFnG(newFreaksNGuilds);
    freaksBucks = IFBX(newFreaksBucks);
    isTravelEnabled = newIsTravelEnabled;
  }

  /// @notice Travel tokens to L2.
  function travel(
    uint256[] calldata freakIds,
    uint256[] calldata celestialIds,
    uint256 fbxAmount
  ) external {
    require(isTravelEnabled, "CelestialCastle: travel is disabled");
    bytes[] memory calls = new bytes[](
      (freakIds.length > 0 ? 1 : 0) + (celestialIds.length > 0 ? 1 : 0) + (fbxAmount > 0 ? 1 : 0)
    );
    uint256 callsIndex = 0;

    if (freakIds.length > 0) {
      Freak[] memory freaks = new Freak[](freakIds.length);
      for (uint256 i = 0; i < freakIds.length; i++) {
        require(ownerOf[freakIds[i]] == address(0), "CelestialCastle: token already staked");
        require(freaksNGuilds.isFreak(freakIds[i]), "CelestialCastle: not a freak");
        ownerOf[freakIds[i]] = msg.sender;
        freaks[i] = freaksNGuilds.getFreakAttributes(freakIds[i]);
        freaksNGuilds.transferFrom(msg.sender, address(this), freakIds[i]);
      }
      calls[callsIndex] = abi.encodeWithSelector(
        CelestialCastle.retrieveFreakIds.selector,
        reflection[address(freaksNGuilds)],
        msg.sender,
        freakIds,
        freaks
      );
      callsIndex++;
    }

    if (celestialIds.length > 0) {
      Celestial[] memory celestials = new Celestial[](celestialIds.length);
      for (uint256 i = 0; i < celestialIds.length; i++) {
        require(ownerOf[celestialIds[i]] == address(0), "CelestialCastle: token already staked");
        require(!freaksNGuilds.isFreak(celestialIds[i]), "CelestialCastle: not a celestial");
        ownerOf[celestialIds[i]] = msg.sender;
        celestials[i] = freaksNGuilds.getCelestialAttributes(celestialIds[i]);
        freaksNGuilds.transferFrom(msg.sender, address(this), celestialIds[i]);
      }
      calls[callsIndex] = abi.encodeWithSelector(
        CelestialCastle.retrieveCelestialIds.selector,
        reflection[address(freaksNGuilds)],
        msg.sender,
        celestialIds,
        celestials
      );
      callsIndex++;
    }

    if (fbxAmount > 0) {
      freaksBucks.burn(msg.sender, fbxAmount);
      calls[callsIndex] = abi.encodeWithSelector(
        CelestialCastle.retrieveBucks.selector,
        reflection[address(freaksBucks)],
        msg.sender,
        fbxAmount
      );
    }

    portal.sendMessage(abi.encode(reflection[address(this)], calls));
  }

  /// @notice Retrieve freaks from castle when bridging.
  function retrieveFreakIds(
    address fng,
    address owner,
    uint256[] calldata freakIds,
    Freak[] calldata freakAttributes
  ) external onlyPortal {
    for (uint256 i = 0; i < freakIds.length; i++) {
      delete ownerOf[freakIds[i]];
      IFnG(fng).transferFrom(address(this), owner, freakIds[i]);
      IFnG(fng).setFreakAttributes(freakIds[i], freakAttributes[i]);
    }
  }

  /// @notice Retrieve celestials from castle when bridging.
  function retrieveCelestialIds(
    address fng,
    address owner,
    uint256[] calldata celestialIds,
    Celestial[] calldata celestialAttributes
  ) external onlyPortal {
    for (uint256 i = 0; i < celestialIds.length; i++) {
      delete ownerOf[celestialIds[i]];
      IFnG(fng).transferFrom(address(this), owner, celestialIds[i]);
      IFnG(fng).setCelestialAttributes(celestialIds[i], celestialAttributes[i]);
    }
  }

  // function callFnG(bytes calldata data) external onlyPortal {
  //   (bool succ, ) = freaksNGuilds.call(data)
  // }

  /// @notice Retrive freaks bucks to `owner` when bridging.
  function retrieveBucks(
    address fbx,
    address owner,
    uint256 value
  ) external onlyPortal {
    IFBX(fbx).mint(owner, value);
  }

  /// @notice Set contract reflection address on L2.
  function setReflection(address key, address value) external onlyOwner {
    reflection[key] = value;
    reflection[value] = key;
  }

  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external pure override returns (bytes4) {
    return this.onERC721Received.selector;
  }

  function setIsTravelEnabled(bool newIsTravelEnabled) external onlyOwner {
    isTravelEnabled = newIsTravelEnabled;
  }
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

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.11;

import "./Structs.sol";

interface MetadataHandlerLike {
  function getCelestialTokenURI(uint256 id, Celestial memory character) external view returns (string memory);

  function getFreakTokenURI(uint256 id, Freak memory character) external view returns (string memory);
}

interface InventoryCelestialsLike {
  function getAttributes(Celestial memory character, uint256 id) external pure returns (bytes memory);

  function getImage(uint256 id) external view returns (bytes memory);
}

interface InventoryFreaksLike {
  function getAttributes(Freak memory character, uint256 id) external view returns (bytes memory);

  function getImage(Freak memory character) external view returns (bytes memory);
}

interface IFnG {
  function transferFrom(
    address from,
    address to,
    uint256 id
  ) external;

  function ownerOf(uint256 id) external returns (address owner);

  function isFreak(uint256 tokenId) external view returns (bool);

  function getSpecies(uint256 tokenId) external view returns (uint8);

  function getFreakAttributes(uint256 tokenId) external view returns (Freak memory);

  function setFreakAttributes(uint256 tokenId, Freak memory attributes) external;

  function getCelestialAttributes(uint256 tokenId) external view returns (Celestial memory);

  function setCelestialAttributes(uint256 tokenId, Celestial memory attributes) external;
}

interface IFBX {
  function mint(address to, uint256 amount) external;

  function burn(address from, uint256 amount) external;
}

interface ICKEY {
  function ownerOf(uint256 tokenId) external returns (address);
}

interface IVAULT {
  function depositsOf(address account) external view returns (uint256[] memory);
  function _depositedBlocks(address account, uint256 tokenId) external returns(uint256);
}

interface ERC20Like {
  function balanceOf(address from) external view returns (uint256 balance);

  function burn(address from, uint256 amount) external;

  function mint(address from, uint256 amount) external;

  function transfer(address to, uint256 amount) external;
}

interface ERC1155Like {
  function mint(
    address to,
    uint256 id,
    uint256 amount
  ) external;

  function burn(
    address from,
    uint256 id,
    uint256 amount
  ) external;
}

interface ERC721Like {
  function transferFrom(
    address from,
    address to,
    uint256 id
  ) external;

  function transfer(address to, uint256 id) external;

  function ownerOf(uint256 id) external returns (address owner);

  function mint(address to, uint256 tokenid) external;
}

interface PortalLike {
  function sendMessage(bytes calldata) external;
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
pragma solidity 0.8.11;

struct Freak {
  uint8 species;
  uint8 body;
  uint8 armor;
  uint8 mainHand;
  uint8 offHand;
  uint8 power;
  uint8 health;
  uint8 criticalStrikeMod;

}
struct Celestial {
  uint8 healthMod;
  uint8 powMod;
  uint8 cPP;
  uint8 cLevel;
}

struct Layer {
  string name;
  string data;
}

struct LayerInput {
  string name;
  string data;
  uint8 layerIndex;
  uint8 itemIndex;
}