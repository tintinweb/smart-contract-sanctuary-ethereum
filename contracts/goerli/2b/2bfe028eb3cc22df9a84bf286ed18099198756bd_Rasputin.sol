// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

import "./interfaces/IFrontlines.sol";
import "./interfaces/IQ00tantSquad.sol";
import "./StorageOracle/interfaces/IStorageOracle.sol";
import "./Q00nicornSquad.sol";

contract Rasputin {

    struct SquadInfo {
        address squadAddress;
        uint16 q00tBalance;
        uint16 squadPower;
        bool defeated;
        bool activeDefender;
    }

    IStorageOracle storageOracle = IStorageOracle(0xDEa25757FFd5eF1EBd949e58b533f8E97F14AE64);
    IFrontlines frontlines = IFrontlines(0x0F9B1418694ADAEe240Cb0d76B805d197da5ae8a);
    IERC721 q00tants = IERC721(0x9F7C5D43063e3ECEb6aE43A22b669BB01fD1039A);
    IERC721 q00nicorns = IERC721(0xc8Dc0f7B8Ca4c502756421C23425212CaA6f0f8A);
    bytes32 private constant q00tantSquadCodeHash = 0x7446750a89f01b0df07d957745cb5d1a49aa38c9a776062cde73245a098bb614;
    bytes32 private constant cornSquadCodeHash = 0x5987bb8bdd050e9b1b27079d47b3271c8fd4ac0f001772221bcded2ff238fba5;

    uint256 public q00tantSquadsTracked;
    uint256 public q00nicornSquadsTracked;

    mapping(uint256 => address) public q00tantSquads;
    mapping(uint256 => address) public q00nicornSquads;
    mapping(address => bool) public q00nicornSquadDefeated;
    mapping(address => bool) public squadsTracked;
    mapping(address => bool) public allowedOperator;

    address owner;
    uint256 maxImbueQ00tant = 350;

    uint256 q00tantSquadUndefeatedStart = 0;

    modifier onlyDeployer() {
        require(frontlines.deployers(msg.sender));
        _;
    }

    modifier onlyOperator() {
        require(allowedOperator[msg.sender]);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor(address[] memory operators, address[] memory defeatedCorns) {
        owner = msg.sender;
        for(uint256 i = 0;i < operators.length;i++) {
            allowedOperator[operators[i]] = true;
        }
        for(uint256 i = 0;i < defeatedCorns.length;i++) {
            q00nicornSquadDefeated[defeatedCorns[i]] = true;
        }
    }

    function setAllowedOperator(address operator, bool allowed) external onlyOwner {
        allowedOperator[operator] = allowed;
    }

    function setMaxImbueQ00tant(uint256 max) external onlyOwner {
        maxImbueQ00tant = max;
    }

    function nuclearAttack(address cornSquadAddress, address[] calldata q00tantSquadsToAttack, uint256 targetPower) external onlyDeployer onlyOperator {
        Q00nicornSquad cornSquad = Q00nicornSquad(cornSquadAddress);
        uint256 cornPower = cornSquad.squadPower();
        if(q00nicornPower(cornPower) > q00tantPower(cornSquadAddress, targetPower)) {
            address defendingSquad = frontlines.activeQ00tantSquad();

            for(uint256 i = 0;i < q00tantSquadsToAttack.length;i++) {
                address q00tantSquadAddress = q00tantSquadsToAttack[i];
                IQ00tantSquad qs = IQ00tantSquad(q00tantSquadAddress);
                if(qs.isDefeated()) { continue; }
                uint256 qsPower = qs.squadPower();
                if(qsPower > targetPower) { continue; }
                while(qsPower < targetPower) {
                    qs.imbueSquad();
                    qsPower += 50;
                }
                if(q00tantSquadAddress != defendingSquad) {
                    frontlines.setDefendingQ00tantSquad(q00tantSquadAddress);
                }
                frontlines.attack(cornSquadAddress);
            }   
        }
    }

    function q00tantPower(address cornSquadAddress, uint squadPower) public view returns (uint16) {
        return uint16(uint256(keccak256(abi.encodePacked(cornSquadAddress, block.timestamp, block.difficulty)))%squadPower);
    }

    function q00nicornPower(uint squadPower) public view returns (uint8) {
        return uint8(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)))%squadPower);
    }

    function stealthImbueCorn(address squadAddress) external onlyDeployer onlyOperator {
        Q00nicornSquad qs = Q00nicornSquad(squadAddress);
        require(q00nicorns.balanceOf(squadAddress) >= 5);
        require(!q00nicornSquadDefeated[squadAddress]);
        qs.imbueSquad();
    }

    function trackQ00tantSquad(address[] calldata squadAddresses) external onlyOperator {
        address squadAddress;
        for(uint256 i = 0;i < squadAddresses.length;i++) {
            squadAddress = squadAddresses[i];
            if(squadsTracked[squadAddress]) { continue; }
            bytes32 codeHash;
            assembly { codeHash := extcodehash(squadAddress) }
            require(codeHash == q00tantSquadCodeHash);

            squadsTracked[squadAddress] = true;
            q00tantSquads[q00tantSquadsTracked] = squadAddress;
            q00tantSquadsTracked++;
        }
    }

    function trackQ00nicornSquad(address[] calldata squadAddresses) external onlyOperator {
        address squadAddress;
        for(uint256 i = 0;i < squadAddresses.length;i++) {
            squadAddress = squadAddresses[i];
            if(squadsTracked[squadAddress]) { continue; }

            bytes32 codeHash;
            assembly { codeHash := extcodehash(squadAddress) }
            require(codeHash == cornSquadCodeHash);

            squadsTracked[squadAddress] = true;
            q00nicornSquads[q00nicornSquadsTracked] = squadAddress;
            q00nicornSquadsTracked++;
        }
    }

    function undefeatedQ00tantSquads() external view returns (SquadInfo[] memory) {
        uint256 undefeatedCount = 0;
        
        for(uint256 i = 0;i < q00tantSquadsTracked;i++) {
            IQ00tantSquad qs = IQ00tantSquad(q00tantSquads[i]);
            if(!qs.isDefeated()) { undefeatedCount++; }
        }

        uint256 index;
        SquadInfo[] memory si = new SquadInfo[](undefeatedCount);
        for(uint256 i = 0;i < q00tantSquadsTracked;i++) {
            SquadInfo memory csi;
            IQ00tantSquad qs = IQ00tantSquad(q00tantSquads[i]);
            if(!qs.isDefeated()) { 
                csi.squadAddress = address(qs);
                csi.q00tBalance = uint16(q00tants.balanceOf(address(qs)));
                csi.squadPower = uint16(qs.squadPower());
                csi.defeated = false;
                csi.activeDefender = (address(qs) == frontlines.activeQ00tantSquad());
                si[index] = csi;
                index++;
                if(index > undefeatedCount) { break; }
            }
        }
        return si;
    }

    function undefeatedQ00nicornSquads() external view returns (SquadInfo[] memory) {
        uint256 undefeatedCount = 0;
        
        for(uint256 i = 0;i < q00nicornSquadsTracked;i++) {
            if(!q00nicornSquadDefeated[q00nicornSquads[i]]) { undefeatedCount++; }
        }

        uint256 index;
        SquadInfo[] memory si = new SquadInfo[](undefeatedCount);
        for(uint256 i = 0;i < q00nicornSquadsTracked;i++) {
            SquadInfo memory csi;
            Q00nicornSquad qs = Q00nicornSquad(q00nicornSquads[i]);
            if(!q00nicornSquadDefeated[q00nicornSquads[i]]) {
                csi.squadAddress = address(qs);
                csi.q00tBalance = uint16(q00nicorns.balanceOf(address(qs)));
                csi.squadPower = uint16(qs.squadPower());
                csi.defeated = false;
                csi.activeDefender = false;
                si[index] = csi;
                index++;
                if(index > undefeatedCount) { break; }
            }
        }
        return si;
    }

    function setAsDefeated(address squadAddress, uint256 blockNumber, bytes memory storageProof) external {
        require(!q00nicornSquadDefeated[squadAddress]);
        bool defeated = (storageOracle.getStorage(squadAddress, blockNumber, 5, storageProof) > 0);
        q00nicornSquadDefeated[squadAddress] = defeated;
    }
}

// SPDX-License-Identifier: UNLICENSED

import "./interfaces/IGlitter.sol";
import "./interfaces/IQ00tantSquad.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "./OwnableEpochContract.sol";

pragma solidity ^0.8.17;

error NotAQ00tantSquad();
error SquadOverloaded();
error NotEnoughCorns();
error Q00nicornNotDeposited();
error Q00nicornSquadDefeated();
error OwnershipLocked();

contract Q00nicornSquad is OwnableEpochContract {
    IQ00tantSquad q00tantSquad;

    IGlitter glitter = IGlitter(0xB4849f82E4449f539314059842173db32509f022);
    IERC721 q00nicorns = IERC721(0xc8Dc0f7B8Ca4c502756421C23425212CaA6f0f8A);
    uint256 public squadPower = 50;
    bytes32 private constant q00tantSquadCodeHash = 0x7446750a89f01b0df07d957745cb5d1a49aa38c9a776062cde73245a098bb614;
    bool defeated;
    mapping(uint256 => address) ownerOf;

    constructor() {}

    function imbueSquad() external {
        uint256 newPower = squadPower + 50;
        if (newPower > 250) revert SquadOverloaded();

        glitter.burn(msg.sender, 100 * 1e18);
        squadPower = newPower;      
    }

    function depositCorns(uint256[] calldata tokenIds) external {
      for (uint256 i = 0; i < tokenIds.length;) {
        q00nicorns.transferFrom(msg.sender, address(this), tokenIds[i]);
        unchecked { ++i; }
      }
    }

    function attack(address _q00tantSquadAddress) external returns (bool) {
        if (q00nicorns.balanceOf(address(this)) < 5) revert NotEnoughCorns();
        if (defeated) revert Q00nicornSquadDefeated();
        bytes32 codeHash;
        assembly { codeHash := extcodehash(_q00tantSquadAddress) }
        if (codeHash != q00tantSquadCodeHash) revert NotAQ00tantSquad();
        q00tantSquad = IQ00tantSquad(_q00tantSquadAddress);
        uint8 attackValue = random();
        uint16 defendValue = q00tantSquad.defend();
        return attackValue > defendValue;
    }

    function random() private view returns (uint8) {
      return uint8(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)))%squadPower);
    }

    function transferOwnership(address) public pure override {
      revert OwnershipLocked();
    }

    // Owner management functions to be used by q00tiepie

    function transferFrom(address, address to, uint256 tokenId) external onlyEpoch {
      if (ownerOf[tokenId] == address(0)) revert Q00nicornNotDeposited();
      ownerOf[tokenId] = to;
    }

    function withdrawCorn(uint256 tokenId) external onlyEpoch {
      q00nicorns.transferFrom(address(this), ownerOf[tokenId], tokenId);
    }

    function setAsDefeated() external onlyEpoch {
      defeated = true;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IStorageOracle {
    function processStorageRoot(address account, uint256 blockNumber, bytes memory blockHeaderRLP, bytes memory accountStateProof) external;
    function getStorage(address account, uint256 blockNumber, uint256 slot, bytes memory storageProof) external view returns (uint256);
    function getStateRoot(bytes memory blockHeaderRLP, bytes32 blockHash) external pure returns (bytes32 stateRoot);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

interface IQ00tantSquad {
  function isDefeated() external view returns (bool);
  function setAsDefeated() external;
  function defend() external view returns (uint16);
  function squadPower() external view returns (uint256);
  function imbueSquad() external;
  function owner() external returns (address);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

interface IFrontlines {
  function q00tantSquads(address deployer) external view returns(bool);
  function cornSquads(address deployer) external view returns(bool);
  function deployers(address deployer) external view returns(bool);
  function miners(uint256 miner) external view returns(uint256);
  function cornMiners(uint256 miner) external view returns(uint256);

  function activeQ00tantSquad() external view returns(address);
  function unguardedAt() external view returns(uint256);
  function q00tantPoints() external view returns(uint256);
  function q00nicornPoints() external view returns(uint256);

  function registerQ00tantSquad(address _squadContract) external;
  function mine(uint256 _tokenId) external;
  function registerCornSquad(address _squadContract) external;
  function setDefendingQ00tantSquad(address _q00tantSquad) external;
  function conductHeist(uint256 _tokenId) external;
  function attack(address _cornSquad) external;
}

// SPDX-License-Identifier: UNLICENSED

import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

pragma solidity 0.8.17;

error OnlyEpoch();

interface IEpochRegistry {
  function isApprovedAddress(address _address) external view returns (bool);
  function setEpochContract(address _contract, bool _approved) external;
}

contract OwnableEpochContract is Ownable {
  IEpochRegistry internal immutable epochRegistry;

  constructor() {
    epochRegistry = IEpochRegistry(0x3b3E84457442c5c2C671d9528Ea730258c7ccfF7);
  }

  modifier onlyEpoch {
    if (!epochRegistry.isApprovedAddress(msg.sender)) revert OnlyEpoch();
    _;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

interface IGlitter {
  function burn(address from, uint256 amount) external;
  function transferFrom(address from, address to, uint256 amount) external returns (bool);
  function balanceOf(address account) external view returns (uint256);
  function mint(address to, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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