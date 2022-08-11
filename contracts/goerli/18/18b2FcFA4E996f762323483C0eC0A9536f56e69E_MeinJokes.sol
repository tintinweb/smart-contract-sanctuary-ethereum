// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// NOTE: I want to enhance the way colors are stored.
// Currently a HEX string is stored. Suggestions are welcomed :)
struct Jeshe {
    bytes6 bgColor;
    bytes6 textColor;
    address author;
    string content;
}

/// @title A Simple yet useful starter contract :)
/// @author Denny Portillo
/// @notice This implementation is used as a learning tool. Do not use in real-apps
contract MeinJokes {
    uint64 nextItemIdx;
    mapping(uint64 => Jeshe) itemsById;

    /// @notice Log items by listed by owner along with it's item_id
    /// @dev This indexed owner-item_id is usefull along with getItemsById fn
    event ListedItem(address indexed owner, uint64 indexed item_id);

    function totalItems() external view returns (uint64) {
        return nextItemIdx;
    }

    /// @notice Get information about an item by providing it's id
    function getItemById(uint64 _itemId) external view returns (Jeshe memory) {
        return itemsById[_itemId];
    }

    /// @notice List/Create a Jeshejojo
    /// @dev Emits #ListedItem
    /// @param _content The message you want to store
    /// @param _bgColor The background of your post. Just as facebook/instagram stories :p
    /// @param _textColor Set a custom font-color for your post
    function listItem(
        string calldata _content,
        bytes6 _bgColor,
        bytes6 _textColor
    ) external notEmptyOrGt200(_content) {
        itemsById[nextItemIdx] = Jeshe(
            _bgColor,
            _textColor,
            msg.sender,
            _content
        );
        emit ListedItem(msg.sender, nextItemIdx++);
    }

    // MODIFIERS
    modifier notEmptyOrGt200(string calldata _str) {
        bytes memory _rawBytes = bytes(_str);
        require(_rawBytes.length > 0, "String cannot be empty");
        require(_rawBytes.length < 222, "String.size cannot greater than 200");
        _;
    }
}