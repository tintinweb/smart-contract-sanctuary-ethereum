// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/ISportManager.sol";
import "./library/String.sol";

contract SportManager is ISportManager, Ownable {
    using String for string;

    uint256 private _currentGameId = 0;
    uint256 private _currentAttributeId = 0;

    Game[] private games;
    Attribute[] private attributes;
    mapping(uint256 => mapping(uint256 => bool)) private supportedAttribute;

    function addNewGame(
        string memory name,
        bool active,
        ProviderGameData provider
    ) external override onlyOwner returns (uint256 gameId) {
        gameId = _currentGameId;
        _currentGameId++;
        games.push(Game(gameId, active, name, provider));
        emit AddNewGame(_currentGameId, name);
        if (active) {
            emit ActiveGame(_currentGameId);
        } else {
            emit DeactiveGame(_currentGameId);
        }
    }

    function updateGame(
        uint256 _gameId,
        string memory _newName,
        ProviderGameData _provider
    ) external onlyOwner {
        games[_gameId].name = _newName;
        games[_gameId].provider = _provider;
    }

    function getGameById(uint256 id)
        external
        view
        override
        returns (Game memory)
    {
        return games[id];
    }

    function deactiveGame(uint256 gameId) external override onlyOwner {
        Game storage game = games[gameId];
        require(game.active, "SM: deactived");
        game.active = false;
        emit DeactiveGame(gameId);
    }

    function activeGame(uint256 gameId) external override onlyOwner {
        Game storage game = games[gameId];
        require(!game.active, "SM: actived");
        game.active = true;
        emit ActiveGame(gameId);
    }

    function addNewAttribute(Attribute[] memory attribute)
        external
        override
        onlyOwner
    {
        uint256 attributeId = _currentAttributeId;
        for (uint256 i = 0; i < attribute.length; i++) {
            attributes.push(
                Attribute(
                    attributeId,
                    attribute[i].teamOption,
                    attribute[i].attributeSupportFor,
                    attribute[i].name
                )
            );
            attributeId++;
        }
        _currentAttributeId = attributeId;
    }

    function updateAttribute(
        uint256 _attributeId,
        string memory _name,
        bool _teamOption,
        AttributeSupportFor _attributeSupportFor
    ) external onlyOwner {
        if (!attributes[_attributeId].name.compare(_name)) {
            attributes[_attributeId].name = _name;
        }
        if (attributes[_attributeId].teamOption != _teamOption) {
            attributes[_attributeId].teamOption = _teamOption;
        }
        if (
            attributes[_attributeId].attributeSupportFor != _attributeSupportFor
        ) {
            attributes[_attributeId].attributeSupportFor = _attributeSupportFor;
        }
    }

    function setSupportedAttribute(
        uint256 gameId,
        uint256[] memory attributeIds,
        bool isSupported
    ) external override onlyOwner {
        require(gameId < _currentGameId);
        for (uint256 i = 0; i < attributeIds.length; i++) {
            uint256 attributeId = attributeIds[i];
            if (attributeId < _currentAttributeId) {
                supportedAttribute[gameId][attributeId] = isSupported;
            }
        }
    }

    function checkSupportedGame(uint256 gameId)
        external
        view
        override
        returns (bool)
    {
        if (gameId < _currentGameId) {
            Game memory game = games[gameId];
            return game.active;
        } else {
            return false;
        }
    }

    function checkSupportedAttribute(uint256 gameId, uint256 attributeId)
        external
        view
        override
        returns (bool)
    {
        return supportedAttribute[gameId][attributeId];
    }

    function getAllGame() external view returns (Game[] memory) {
        return games;
    }

    function getAllAttribute() external view returns (Attribute[] memory) {
        return attributes;
    }

    function getAttributesSupported(uint256 gameId)
        external
        view
        returns (Attribute[] memory result, uint256 size)
    {
        result = new Attribute[](attributes.length);
        size = 0;
        for (uint256 i = 0; i < attributes.length; i++) {
            Attribute memory attribute = attributes[i];
            if (supportedAttribute[gameId][attribute.id]) {
                result[size] = attribute;
                size++;
            }
        }
    }

    function getAttributeById(uint256 attributeId)
        external
        view
        override
        returns (Attribute memory)
    {
        return attributes[attributeId];
    }

    function checkTeamOption(uint256 attributeId)
        external
        view
        override
        returns (bool)
    {
        if (attributeId < _currentAttributeId) {
            Attribute memory attribute = attributes[attributeId];
            return attribute.teamOption;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

library String {
    function append(string memory a, string memory b)
        internal
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(a, b));
    }

    function toString(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function compare(string memory a, string memory b) internal pure returns(bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function toBytes32(string memory source)
        internal
        pure
        returns (bytes32 result)
    {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            // solhint-disable-line no-inline-assembly
            result := mload(add(source, 32))
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface ISportManager {
    struct Game {
        uint256 id;
        bool active;
        string name;
        ProviderGameData provider;
    }

    struct Attribute {
        uint256 id;
        bool teamOption;
        AttributeSupportFor attributeSupportFor;
        string name;
    }

    enum ProviderGameData {
        GameScoreKeeper,
        SportRadar
    }

    enum AttributeSupportFor {
        None,
        Team,
        Player,
        All
    }

    event AddNewGame(uint256 indexed gameId, string name);
    event DeactiveGame(uint256 indexed gameId);
    event ActiveGame(uint256 indexed gameId);
    event AddNewAttribute(uint256 indexed attributeId, string name);

    function getGameById(uint256 id) external view returns (Game memory);

    function addNewGame(
        string memory name,
        bool active,
        ProviderGameData provider
    ) external returns (uint256 gameId);

    function deactiveGame(uint256 gameId) external;

    function activeGame(uint256 gameId) external;

    function addNewAttribute(Attribute[] calldata attribute) external;

    function setSupportedAttribute(
        uint256 gameId,
        uint256[] memory attributeIds,
        bool isSupported
    ) external;

    function checkSupportedGame(uint256 gameId) external view returns (bool);

    function checkSupportedAttribute(uint256 gameId, uint256 attributeId)
        external
        view
        returns (bool);

    function checkTeamOption(uint256 attributeId) external view returns (bool);

    function getAttributeById(uint256 attributeId)
        external
        view
        returns (Attribute calldata);
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