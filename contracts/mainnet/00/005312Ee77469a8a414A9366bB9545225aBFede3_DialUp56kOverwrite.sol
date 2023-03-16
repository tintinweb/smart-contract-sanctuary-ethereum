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

// __/\\\\\\\\\\\\______/\\\\\\\\\\\\\\\_____________/\\\\\__/\\\________/\\\_
//  _\/\\\////////\\\___\/\\\///////////__________/\\\\////__\/\\\_____/\\\//__
//   _\/\\\______\//\\\__\/\\\__________________/\\\///_______\/\\\__/\\\//_____
//    _\/\\\_______\/\\\__\/\\\\\\\\\\\\_______/\\\\\\\\\\\____\/\\\\\\//\\\_____
//     _\/\\\_______\/\\\__\////////////\\\____/\\\\///////\\\__\/\\\//_\//\\\____
//      _\/\\\_______\/\\\_____________\//\\\__\/\\\______\//\\\_\/\\\____\//\\\___
//       _\/\\\_______/\\\___/\\\________\/\\\__\//\\\______/\\\__\/\\\_____\//\\\__
//        _\/\\\\\\\\\\\\/___\//\\\\\\\\\\\\\/____\///\\\\\\\\\/___\/\\\______\//\\\_
//         _\////////////______\/////////////________\/////////_____\///________\///__

// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "./OverwriteState.sol";
import { Ownable } from "openzeppelin-contracts/access/Ownable.sol";

interface IDisk {
    function burn(address _from, uint256[] memory _tokenIds, uint256[] memory _amounts) external;

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function mintBaseExisting(address[] calldata to, uint256[] calldata tokenIds, uint256[] calldata amounts) external;
}

interface IOS {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function ownerOf(uint256 tokenId) external view returns (address);
}

contract DialUp56kOverwrite is OverwriteState, Ownable {
    // solhint-disable-next-line no-empty-blocks
    constructor() {}

    function getDisk(uint16 _diskId) public view returns (Disk memory) {
        return disks[_diskId];
    }

    function getOperatorWrites(address _operator) public view returns (
        uint16[] memory, uint16[] memory, uint16[] memory
    ) {
        require(operators[_operator].writes > 0, "operator not written");
        uint16[] memory diskIds = new uint16[](operators[_operator].writes);
        uint16[] memory traitIds = new uint16[](operators[_operator].writes);
        uint16[] memory osIds = new uint16[](operators[_operator].writes);

        for (uint8 i = 0; i < operators[_operator].writes; i++) {
            diskIds[i] = operators[_operator].overwrites[i].diskId;
            traitIds[i] = operators[_operator].overwrites[i].traitId;
            osIds[i] = operators[_operator].overwrites[i].osId;
        }

        return (diskIds, traitIds, osIds);
    }

    function getRelease(uint16 _osId) public view returns (
        uint16[] memory, uint16[] memory
    ) {
        require(operatingSystems[_osId].writes > 0, "os not released");
        uint16[] memory diskIds = new uint16[](operatingSystems[_osId].writes);
        uint16[] memory traitIds = new uint16[](operatingSystems[_osId].writes);

        for (uint8 i = 0; i < operatingSystems[_osId].writes; i++) {
            diskIds[i] = operatingSystems[_osId].overwrites[i].diskId;
            traitIds[i] = operatingSystems[_osId].overwrites[i].traitId;
        }

        return (diskIds, traitIds);
    }

    function getReleases(uint16 first, uint16 skip) public view returns (
        uint16[] memory
    ) {
        require(releaseCount > skip, "not enough releases");
        require(releaseCount >= first, "not enough releases");

        uint16[] memory osIds = new uint16[](first);

        for (uint8 i = 0; i < first; i++) {
            osIds[i] = releases[i + skip];
        }

        return osIds;
    }

    function recycleOS(uint256[] memory _tokenIds) external {
        uint256[] memory _diskIds = new uint256[](1);
        uint256[] memory _amounts = new uint256[](1);
        address[] memory _address = new address[](1);

        for (uint8 i = 0; i < _tokenIds.length; i++) {
            IOS(osAddress).safeTransferFrom(msg.sender, burnAddress, _tokenIds[i]);
        }

        _diskIds[0] = blankDiskId;
        _amounts[0] = _tokenIds.length * reclaims;
        _address[0] = msg.sender;

        IDisk(diskAddress).mintBaseExisting(_address, _diskIds, _amounts);
    }

    function recycleDisk(uint256[] memory _tokenIds, uint256[] memory _amounts) external {
        uint256[] memory _diskIds = new uint256[](1);
        uint256[] memory _mints = new uint256[](1);
        address[] memory _address = new address[](1);

        IDisk(diskAddress).burn(msg.sender, _tokenIds, _amounts);

        for (uint8 i = 0; i < _amounts.length; i++) {
            _mints[0] = _mints[0] + _amounts[i];
        }

        _diskIds[0] = blankDiskId;
        _address[0] = msg.sender;

        IDisk(diskAddress).mintBaseExisting(_address, _diskIds, _mints);
    }

    function upcycle(uint8 _diskId, uint256 _amount) external {
        require(disks[_diskId].loaded, "Disk not loaded");
        require(disks[_diskId].active, "Disk not active");

        uint256 _reclaims = disks[_diskId].reclaims * _amount;

        require(IDisk(diskAddress).balanceOf(msg.sender, blankDiskId) >= _reclaims, "Not enough disks");

        uint256[] memory _diskIds = new uint256[](1);
        uint256[] memory _burns = new uint256[](1);

        _diskIds[0] = blankDiskId;
        _burns[0] = _reclaims;

        IDisk(diskAddress).burn(msg.sender, _diskIds, _burns);

        uint256[] memory _tokenIds = new uint256[](1);
        uint256[] memory _amounts = new uint256[](1);
        address[] memory _address = new address[](1);

        _tokenIds[0] = _diskId;
        _amounts[0] = _amount;
        _address[0] = msg.sender;

        IDisk(diskAddress).mintBaseExisting(_address, _tokenIds, _amounts);
    }

    function overwrite(uint16[] memory _diskIds) external {
        uint256[] memory _amounts = new uint256[](_diskIds.length);
        uint256[] memory _tokenIds = new uint256[](_diskIds.length);

        for (uint8 i = 0; i < _diskIds.length; i++) {
            uint16 diskId = _diskIds[i];

            require(disks[diskId].loaded, "Disk not loaded");
            require(disks[diskId].active, "Disk not active");
            require(disks[diskId].overwrites > 0, "Disk not writeable");

            _tokenIds[i] = diskId;
            _amounts[i] = 1;

            uint randomNumber = uint(keccak256(
                abi.encodePacked(block.timestamp, msg.sender, diskId, i, operators[msg.sender].writes, block.difficulty)
            ));
            uint16 traitId = uint16(randomNumber % disks[diskId].overwrites);

            Overwrite memory newOverwrite;
            newOverwrite.diskId = diskId;
            newOverwrite.traitId = traitId;
            newOverwrite.write = operators[msg.sender].writes;
            newOverwrite.osId = 0;

            operators[msg.sender].overwrites[newOverwrite.write] = newOverwrite;
            operators[msg.sender].writes = newOverwrite.write + 1;
        }

        IDisk(diskAddress).burn(msg.sender, _tokenIds, _amounts);
    }

    function release(uint16 _osId, uint16[] memory _writes) external {
        require(IOS(osAddress).ownerOf(_osId) == msg.sender, "Access denied");
        require(operatingSystems[_osId].writes == 0, "OS already released");

        for (uint8 i = 0; i < _writes.length; i++) {
            Overwrite memory ow = operators[msg.sender].overwrites[_writes[i]];

            require(ow.diskId > 0, "Overwrite not found");
            require(ow.osId == 0, "Overwrite already used");

            ow.osId = _osId;

            operatingSystems[_osId].overwrites[i] = ow;
            operatingSystems[_osId].writes = i + 1;

            operators[msg.sender].overwrites[ow.write] = ow;
        }

        releases[releaseCount] = _osId;
        releaseCount++;
    }

    function loadDisk(uint16 _diskId, uint8 _reclaims, uint8 _overwrites) external onlyOwner {
        Disk memory newDisk;
        newDisk.reclaims = _reclaims;
        newDisk.overwrites = _overwrites;
        newDisk.active = false;
        newDisk.loaded = true;

        disks[_diskId] = newDisk;
    }

    function toggleDisk(uint16 _diskId) external onlyOwner {
        require(disks[_diskId].loaded, "Disk not loaded");
        disks[_diskId].active = !disks[_diskId].active;
    }

    function setAdminWallet(address _adminWallet) external onlyOwner {
        adminWallet = _adminWallet;
    }

    function setDiskAddress(address _diskAddress) external onlyOwner {
        diskAddress = _diskAddress;
    }

    function setOSAddress(address _osAddress) external onlyOwner {
        osAddress = _osAddress;
    }

    function setOSReclaims(uint8 _reclaims) external onlyOwner {
        reclaims = _reclaims;
    }

    function setBlankDisk(uint256 _tokenId) external onlyOwner {
        blankDiskId = _tokenId;
    }

    function withdrawFunds() external onlyOwner {
        // solhint-disable-next-line avoid-low-level-calls
        (bool teamSuccess, ) = adminWallet.call{ value: address(this).balance }("");
        require(teamSuccess, "Transfer failed.");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

abstract contract OverwriteState {
    address public diskAddress;
    address public osAddress;
    address public adminWallet;
    address public burnAddress = 0x000000000000000000000000000000000000dEaD;
    uint8 public reclaims;
    uint256 public blankDiskId;
    uint8 public releaseCount;

    struct Disk {
        uint8 reclaims;
        bool active;
        bool loaded;
        uint16 overwrites;
    }

    struct Overwrite {
        uint16 write;
        uint16 diskId;
        uint16 traitId;
        uint16 osId;
    }

    struct Operator {
        mapping(uint16 => Overwrite) overwrites;
        uint16 writes;
    }

    struct OS {
        mapping(uint16 => Overwrite) overwrites;
        uint16 writes;
    }

    mapping(uint16 => uint16) public releases;
    mapping(uint16 => Disk) public disks;
    mapping(uint16 => OS) public operatingSystems;
    mapping(address => Operator) public operators;
}