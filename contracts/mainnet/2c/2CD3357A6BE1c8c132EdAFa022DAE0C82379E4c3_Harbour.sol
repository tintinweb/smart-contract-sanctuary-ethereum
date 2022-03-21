// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ICoin, IToken} from "../interfaces/Interfaces.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {RecoverableERC721Holder} from "../utils/RecoverableERC721Holder.sol";

interface ITunnel {
    function sendMessage(bytes calldata _message) external;
}

/// @dev A simple contract to orchestrate comings and going from the GHG Tunnel System
contract Harbour is Ownable, Pausable, RecoverableERC721Holder {

    address public tunnel;

    address public ggold;
    address public wood;

    address public goldhunters;
    address public ships;
    address public houses;

    mapping (address => address) public reflection;

    constructor(
        address _tunnel,
        address _ggold, 
        address _wood,
        address _goldhunters,
        address _ships, 
        address _houses
    ) {
        tunnel = _tunnel;
        ggold = _ggold;
        wood = _wood;
        goldhunters = _goldhunters;
        ships = _ships;
        houses = _houses;
        _pause();
    }

    //////////////   OWNER FUNCTIONS   //////////////

    // Travel is pausable
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // Creates a mapping between L1 <-> L2 Contract Equivalents
    function setReflection(address _key, address _reflection) external onlyOwner {
        reflection[_key] = _reflection;
        reflection[_reflection] = _key;
    }

    //////////////   USER FUNCTIONS   ///////////////

    function travel(
        uint256 _ggoldAmount, 
        uint256 _woodAmount,
        uint16[] calldata _goldhunterIds,
        uint16[] calldata _shipIds,
        uint16[] calldata _houseIds
    ) external whenNotPaused {
        uint256 callsIndex = 0;

        bytes[] memory calls = new bytes[](
            (_ggoldAmount > 0 ? 1 : 0) + 
            (_woodAmount > 0 ? 1 : 0) +
            (_goldhunterIds.length > 0 ? 1 : 0) +
            (_shipIds.length > 0 ? 1 : 0) +
            (_houseIds.length > 0 ? 1 : 0)
        );

        if (_ggoldAmount > 0) {
            ICoin(ggold).burn(msg.sender, _ggoldAmount);
            calls[callsIndex] = abi.encodeWithSelector(this.mintToken.selector, reflection[address(ggold)], msg.sender, _ggoldAmount);
            callsIndex++;
        }

        if (_woodAmount > 0) {
            ICoin(wood).burn(msg.sender, _woodAmount);
            calls[callsIndex] = abi.encodeWithSelector(this.mintToken.selector, reflection[address(wood)], msg.sender, _woodAmount);
            callsIndex++;
        }

        if (_goldhunterIds.length > 0) {
            _stakeMany(goldhunters, _goldhunterIds);
            calls[callsIndex] = abi.encodeWithSelector(this.unstakeMany.selector, reflection[address(goldhunters)], msg.sender, _goldhunterIds);
            callsIndex++;
        }

        if (_shipIds.length > 0) {
            _stakeMany(ships, _shipIds);
            calls[callsIndex] = abi.encodeWithSelector(this.unstakeMany.selector, reflection[address(ships)], msg.sender, _shipIds);
            callsIndex++;
        }

        if (_houseIds.length > 0) {
            _stakeMany(houses, _houseIds);
            calls[callsIndex] = abi.encodeWithSelector(this.unstakeMany.selector, reflection[address(houses)], msg.sender, _houseIds);
            // no need to increment callsIndex as this is last call
        }

        ITunnel(tunnel).sendMessage(abi.encode(reflection[address(this)], calls));
    }

    //////////////   INTERNAL FUNCTIONS   /////////////

    function _stakeMany(address nft, uint16[] calldata ids) internal {
        for(uint i = 0; i < ids.length; i++) {
            IToken(nft).safeTransferFrom(msg.sender, address(this), ids[i]);
        }
    }

    modifier onlyTunnel {
        require(msg.sender == tunnel, "ERROR: Msg.Sender is Not Tunnel");
        _;
    }

    function mintToken(address token, address to, uint256 amount) external onlyTunnel { 
        ICoin(token).mint(to, amount);
    }

    function unstakeMany(address nft, address harbourUser, uint16[] calldata ids) external onlyTunnel {
        for(uint i = 0; i < ids.length; i++) {
            IToken(nft).safeTransferFrom(address(this), harbourUser, ids[i]);
        }
    }
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.9;

interface ICoin {
    function mint(address account, uint amount) external;
    function burn(address _from, uint _amount) external;
    function balanceOf(address account) external returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IToken {
    function ownerOf(uint id) external view returns (address);
    function transferFrom(address from, address to, uint tokenId) external;
    function safeTransferFrom(address from, address to, uint tokenId) external; // ERC721
    function safeTransferFrom(address from, address to, uint tokenId, uint amount) external; // ERC1155
    function isApprovedForAll(address owner, address operator) external returns(bool);
    function setApprovalForAll(address operator, bool approved) external;
}

interface IGHGMetadata {
    ///// GENERIC GETTERS /////
    function getGoldhunterMetadata(uint16 _tokenId) external view returns (string memory);
    function getShipMetadata(uint16 _tokenId) external view returns (string memory);
    function getHouseMetadata(uint16 _tokenId) external view returns (string memory);

    ///// TRAIT GETTERS - SHIPS /////
    function shipIsPirate(uint16 _tokenId) external view returns (bool);
    function shipIsCrossedTheOcean(uint16 _tokenId) external view returns (bool);
    function getShipBackground(uint16 _tokenId) external view returns (string memory);
    function getShipShip(uint16 _tokenId) external view returns (string memory);
    function getShipFlag(uint16 _tokenId) external view returns (string memory);
    function getShipMast(uint16 _tokenId) external view returns (string memory);
    function getShipAnchor(uint16 _tokenId) external view returns (string memory);
    function getShipSail(uint16 _tokenId) external view returns (string memory);
    function getShipWaves(uint16 _tokenId) external view returns (string memory);

    ///// TRAIT GETTERS - HOUSES /////
    function getHouseBackground(uint16 _tokenId) external view returns (string memory);
    function getHouseType(uint16 _tokenId) external view returns (string memory);
    function getHouseWindow(uint16 _tokenId) external view returns (string memory);
    function getHouseDoor(uint16 _tokenId) external view returns (string memory);
    function getHouseRoof(uint16 _tokenId) external view returns (string memory);
    function getHouseForeground(uint16 _tokenId) external view returns (string memory);

    ///// TRAIT GETTERS - GOLDHUNTERS /////
    function goldhunterIsCrossedTheOcean(uint16 _tokenId) external view returns (bool);
    function goldhunterIsPirate(uint16 _tokenId) external view returns (bool);
    function getGoldhunterIsGen0(uint16 _tokenId) external pure returns (bool);
    function getGoldhunterSkin(uint16 _tokenId) external view returns (string memory);
    function getGoldhunterLegs(uint16 _tokenId) external view returns (string memory);
    function getGoldhunterFeet(uint16 _tokenId) external view returns (string memory);
    function getGoldhunterTshirt(uint16 _tokenId) external view returns (string memory);
    function getGoldhunterHeadwear(uint16 _tokenId) external view returns (string memory);
    function getGoldhunterMouth(uint16 _tokenId) external view returns (string memory);
    function getGoldhunterNeck(uint16 _tokenId) external view returns (string memory);
    function getGoldhunterSunglasses(uint16 _tokenId) external view returns (string memory);
    function getGoldhunterTool(uint16 _tokenId) external view returns (string memory);
    function getGoldhunterPegleg(uint16 _tokenId) external view returns (string memory);
    function getGoldhunterHook(uint16 _tokenId) external view returns (string memory);
    function getGoldhunterDress(uint16 _tokenId) external view returns (string memory);
    function getGoldhunterFace(uint16 _tokenId) external view returns (string memory);
    function getGoldhunterPatch(uint16 _tokenId) external view returns (string memory);
    function getGoldhunterEars(uint16 _tokenId) external view returns (string memory);
    function getGoldhunterHead(uint16 _tokenId) external view returns (string memory);
    function getGoldhunterArm(uint16 _tokenId) external view returns (string memory);
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)
pragma solidity ^0.8.0;

import {IToken} from "../interfaces/Interfaces.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract RecoverableERC721Holder is Ownable, IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @dev Allows for the safeTransfer of all ERC721 assets from this contract to a list of recipients
     */
    function emergencyTransferOut(address[] calldata _tokenAddressesToTransfer, address[] calldata _recipients, uint[] calldata _tokenIds) external onlyOwner {
        require((_tokenAddressesToTransfer.length == _tokenIds.length) && (_tokenIds.length == _recipients.length), "ERROR: INVALID INPUT DATA - MISMATCHED LENGTHS");

        for(uint i = 0; i < _recipients.length; i++) {
            IToken(_tokenAddressesToTransfer[i]).safeTransferFrom(address(this), _recipients[i], _tokenIds[i]);
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