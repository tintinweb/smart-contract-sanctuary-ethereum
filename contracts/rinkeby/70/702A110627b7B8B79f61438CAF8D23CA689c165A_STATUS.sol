//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface tokenInterface {
    function ownerOf(uint256 tokenId) external view returns (address);

    function checkMintType(uint256 _tokenId) external view returns (uint8);
}

contract STATUS is Ownable {
    address public tokenContractAddress;
    tokenInterface tokenContract;

    modifier checkTokenContract() {
        require(
            tokenContractAddress != address(0),
            "Please put the correct address"
        );
        tokenContract = tokenInterface(tokenContractAddress);
        _;
    }

    uint256 public maxLevel = 6;
    uint256 public statusRange;

    bool private _setStart;

    function setTokenContract(address _address) external onlyOwner {
        require(_address != address(0), "Please put the correct address");
        tokenContractAddress = _address;
    }

    // ChimeraStatus
    struct level {
        uint32 Head;
        uint32 SecondHead;
        uint32 Body;
        uint32 Leg;
        uint32 Tail;
        uint32 Wing;
        uint32 Effect;
    }

    struct characteristic {
        string Head;
        string SecondHead;
        string Body;
        string Leg;
        string Tail;
        string Wing;
        string Effect;
    }

    mapping(uint256 => level) private _chimeraLevels;
    mapping(uint256 => characteristic) private _chimeraCharacteristic;
    mapping(address => bool) private _levelControllableAddress;
    mapping(uint256 => bool) private _isLevelSet;
    mapping(uint256 => bool) private _isCharacteristicSet;

    function viewChimeraLevels(uint256 _tokenId)
        public
        view
        returns (uint32[] memory)
    {
        uint32[] memory arr = new uint32[](7);
        arr[0] = _chimeraLevels[_tokenId].Head;
        arr[1] = _chimeraLevels[_tokenId].SecondHead;
        arr[2] = _chimeraLevels[_tokenId].Body;
        arr[3] = _chimeraLevels[_tokenId].Leg;
        arr[4] = _chimeraLevels[_tokenId].Tail;
        arr[5] = _chimeraLevels[_tokenId].Wing;
        arr[6] = _chimeraLevels[_tokenId].Effect;

        return arr;
    }

    function viewChimeraCharacteristic(uint256 _tokenId)
        external
        view
        returns (string[] memory)
    {
        string[] memory arr = new string[](7);
        arr[0] = _chimeraCharacteristic[_tokenId].Head;
        arr[1] = _chimeraCharacteristic[_tokenId].SecondHead;
        arr[2] = _chimeraCharacteristic[_tokenId].Body;
        arr[3] = _chimeraCharacteristic[_tokenId].Leg;
        arr[4] = _chimeraCharacteristic[_tokenId].Tail;
        arr[5] = _chimeraCharacteristic[_tokenId].Wing;
        arr[6] = _chimeraCharacteristic[_tokenId].Effect;

        return arr;
    }

    function getStatusLevelSum(uint256 _tokenId)
        external
        view
        returns (uint256)
    {
        uint32[] memory levels = viewChimeraLevels(_tokenId);
        uint256 total;
        for (uint32 i = 0; i < levels.length; i++) {
            total += levels[i];
        }
        return total;
    }

    function _generateRandLevels(uint256 _tokenId)
        private
        view
        returns (uint256[] memory)
    {
        require(
            statusRange > 0 && maxLevel > 0,
            "Status settings need to be defined."
        );
        uint256 randNum = tokenContract.checkMintType(_tokenId) == 0
            ? statusRange
            : statusRange - 1;

        uint256[] memory arr = new uint256[](7);
        for (uint256 i = 0; i < 7; i++) {
            arr[i] = (
                ((uint256(
                    keccak256(abi.encodePacked(address(this), i, _tokenId))
                ) % randNum) + 1)
            );
        }

        return arr;
    }

    function _getStrLen(string memory _str) private pure returns (uint32) {
        uint256 len = bytes(_str).length;
        return uint32(len);
    }

    function setRandLevels(uint256 _tokenId) external checkTokenContract {
        require(_setStart, "Not start.");

        address owner = tokenContract.ownerOf(_tokenId);
        require(owner == msg.sender, "Chimera owners only.");
        require(_isCharacteristicSet[_tokenId], "Characteristics are not set.");
        require(!_isLevelSet[_tokenId], "Already setting level.");

        uint256[] memory arr = new uint256[](7);
        arr = _generateRandLevels(_tokenId);

        _chimeraLevels[_tokenId].Head = uint32(
            _getStrLen(_chimeraCharacteristic[_tokenId].Head)
        ) > 0
            ? uint32(arr[0])
            : 0;

        _chimeraLevels[_tokenId].SecondHead = uint32(
            _getStrLen(_chimeraCharacteristic[_tokenId].SecondHead)
        ) > 0
            ? uint32(arr[1])
            : 0;

        _chimeraLevels[_tokenId].Body = uint32(
            _getStrLen(_chimeraCharacteristic[_tokenId].Body)
        ) > 0
            ? uint32(arr[2])
            : 0;

        _chimeraLevels[_tokenId].Leg = uint32(
            _getStrLen(_chimeraCharacteristic[_tokenId].Leg)
        ) > 0
            ? uint32(arr[3])
            : 0;

        _chimeraLevels[_tokenId].Tail = uint32(
            _getStrLen(_chimeraCharacteristic[_tokenId].Tail)
        ) > 0
            ? uint32(arr[4])
            : 0;

        _chimeraLevels[_tokenId].Wing = uint32(
            _getStrLen(_chimeraCharacteristic[_tokenId].Wing)
        ) > 0
            ? uint32(arr[5])
            : 0;

        _chimeraLevels[_tokenId].Effect = uint32(
            _getStrLen(_chimeraCharacteristic[_tokenId].Effect)
        ) > 0
            ? uint32(arr[6])
            : 0;

        _isLevelSet[_tokenId] = true;
    }

    function setCharacteristic(uint256 _tokenId, string[] calldata parts)
        external
        onlyOwner
    {
        _chimeraCharacteristic[_tokenId].Head = parts[0];
        _chimeraCharacteristic[_tokenId].SecondHead = parts[1];
        _chimeraCharacteristic[_tokenId].Body = parts[2];
        _chimeraCharacteristic[_tokenId].Leg = parts[3];
        _chimeraCharacteristic[_tokenId].Tail = parts[4];
        _chimeraCharacteristic[_tokenId].Wing = parts[5];
        _chimeraCharacteristic[_tokenId].Effect = parts[6];

        _isCharacteristicSet[_tokenId] = true;
    }

    function setMaxLevel(uint256 _num) external onlyOwner {
        maxLevel = _num;
    }

    function setStatusRange(uint256 _range) external onlyOwner {
        statusRange = _range;
    }

    function setLevelControllableAddress(address _address, bool _state)
        external
        onlyOwner
    {
        _levelControllableAddress[_address] = _state;
    }

    function switchSetStart() external onlyOwner {
        _setStart = !_setStart;
    }

    function increaseLevel(
        uint256 _tokenId,
        uint32 _characteristicNum,
        uint32 _quantity
    ) external {
        require(_levelControllableAddress[msg.sender], "Not authorized");
        require(_quantity > 0, "Cannot be zero");

        if (_characteristicNum == 0) {
            require(
                _chimeraLevels[_tokenId].Head + _quantity <= maxLevel,
                "Beyond the maximum level"
            );
            _chimeraLevels[_tokenId].Head += _quantity;
        }

        if (_characteristicNum == 1) {
            require(
                _chimeraLevels[_tokenId].SecondHead + _quantity <= maxLevel,
                "Beyond the maximum level"
            );
            _chimeraLevels[_tokenId].SecondHead += _quantity;
        }

        if (_characteristicNum == 2) {
            require(
                _chimeraLevels[_tokenId].Body + _quantity <= maxLevel,
                "Beyond the maximum level"
            );
            _chimeraLevels[_tokenId].Body += _quantity;
        }

        if (_characteristicNum == 3) {
            require(
                _chimeraLevels[_tokenId].Leg + _quantity <= maxLevel,
                "Beyond the maximum level"
            );
            _chimeraLevels[_tokenId].Leg += _quantity;
        }

        if (_characteristicNum == 4) {
            require(
                _chimeraLevels[_tokenId].Tail + _quantity <= maxLevel,
                "Beyond the maximum level"
            );
            _chimeraLevels[_tokenId].Tail += _quantity;
        }

        if (_characteristicNum == 5) {
            require(
                _chimeraLevels[_tokenId].Wing + _quantity <= maxLevel,
                "Beyond the maximum level"
            );
            _chimeraLevels[_tokenId].Wing += _quantity;
        }

        if (_characteristicNum == 6) {
            require(
                _chimeraLevels[_tokenId].Effect + _quantity <= maxLevel,
                "Beyond the maximum level"
            );
            _chimeraLevels[_tokenId].Effect += _quantity;
        }
    }

    function decreaseLevel(
        uint256 _tokenId,
        uint32 _characteristicNum,
        uint32 _quantity
    ) external {
        require(_levelControllableAddress[msg.sender], "Not authorized");
        require(_quantity > 0, "Cannot be zero");

        if (_characteristicNum == 0) {
            require(
                _chimeraLevels[_tokenId].Head >= _quantity,
                "value is less than 0"
            );
            _chimeraLevels[_tokenId].Head -= _quantity;
        }

        if (_characteristicNum == 1) {
            require(
                _chimeraLevels[_tokenId].SecondHead >= _quantity,
                "value is less than 0"
            );
            _chimeraLevels[_tokenId].SecondHead -= _quantity;
        }

        if (_characteristicNum == 2) {
            require(
                _chimeraLevels[_tokenId].Body >= _quantity,
                "value is less than 0"
            );
            _chimeraLevels[_tokenId].Body -= _quantity;
        }

        if (_characteristicNum == 3) {
            require(
                _chimeraLevels[_tokenId].Leg >= _quantity,
                "value is less than 0"
            );
            _chimeraLevels[_tokenId].Leg -= _quantity;
        }

        if (_characteristicNum == 4) {
            require(
                _chimeraLevels[_tokenId].Tail >= _quantity,
                "value is less than 0"
            );
            _chimeraLevels[_tokenId].Tail -= _quantity;
        }

        if (_characteristicNum == 5) {
            require(
                _chimeraLevels[_tokenId].Wing >= _quantity,
                "value is less than 0"
            );
            _chimeraLevels[_tokenId].Wing -= _quantity;
        }

        if (_characteristicNum == 6) {
            require(
                _chimeraLevels[_tokenId].Effect >= _quantity,
                "value is less than 0"
            );
            _chimeraLevels[_tokenId].Effect -= _quantity;
        }
    }

    // ForceSetting
    function forceSetRandLevels(uint256 _tokenId, uint32[] calldata levels)
        external
        onlyOwner
    {
        _chimeraLevels[_tokenId].Head = levels[0];
        _chimeraLevels[_tokenId].SecondHead = levels[1];
        _chimeraLevels[_tokenId].Body = levels[2];
        _chimeraLevels[_tokenId].Leg = levels[3];
        _chimeraLevels[_tokenId].Tail = levels[4];
        _chimeraLevels[_tokenId].Wing = levels[5];
        _chimeraLevels[_tokenId].Effect = levels[6];

        if (!_isLevelSet[_tokenId]) {
            _isLevelSet[_tokenId] = true;
        }
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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