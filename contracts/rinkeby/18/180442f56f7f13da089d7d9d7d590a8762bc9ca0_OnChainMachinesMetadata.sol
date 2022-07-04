/**
 *Submitted for verification at Etherscan.io on 2022-07-03
*/

pragma solidity ^0.8.1;

// SPDX-License-Identifier: MIT

library Random {

    function byWeight(uint256 token, string memory name, address owner, uint256 timestamp, uint8[] memory values) internal pure returns(uint16 index){
        uint256 random = uint256(uint256(keccak256(abi.encodePacked(name, owner, timestamp, token)))) % values[values.length - 1];
        
        for (uint16 i = 0; i < values.length; i++) {
            if(values[i] > random){
                index = i;
                break;
            }
        }
    }

    function byBetween(uint8 vertical, uint8 horizontal, uint256 timestamp, uint8 section) internal pure returns (uint256) {
        return (100 * vertical) + (uint256(keccak256(abi.encodePacked(vertical, timestamp, horizontal))) % section);
    }

}

library Base64 {

    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        uint256 encodedLen = 4 * ((len + 2) / 3);

        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
    
}

library Convert {

	function toString(uint256 value) internal pure returns (string memory) {
        uint256 temp = value;
        uint256 digits;

        if (value == 0) return "0";

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

}

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
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

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)
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

contract Source is Ownable {

    // Struct for attribute ratio, "names of layers/colors", "weight of values"
    struct Ratio {
        string[] keys;
        uint8[] values;
    }

    // State of contract
    bool public tokenState;

    // Keys of attribute,  ["Background Color", "Fill Color", "Center", ...]
    string[] public traitAttributes;

    // Color of attributes, name => hexcode of color
    mapping (string => string) public traitColors;
    
    // Layer of attributes, name => svg graphic
    mapping (string => string) public traitLayers;

    // Weight ratio name of colors, trait => colors
    mapping (string => string[]) public ratioColorKeys;

    // Weight ratio name of layers, trait => layers
    mapping (string => string[]) public ratioLayerKeys;

    // Weight ratio value of colors, trait => ratios
    mapping (string => uint8[]) public ratioColorValues;

    // Weight ratio value of layers, trait => ratios
    mapping (string => uint8[]) public ratioLayerValues;

    /**
     * Set state of contract
     */   
    function setTokenState(bool state) external onlyOwner onlyDeactive {
        tokenState = state;
    }

    /**
     * Set key of attributes
     */   
    function setTraitAttributes(string[] memory values) external onlyOwner onlyDeactive {
        traitAttributes = values;
    }

    /**
     * Set color of attributes
     */   
    function setTraitColor(string memory key, string memory value) external onlyOwner onlyDeactive {
        traitColors[key] = value;
    }

    /**
     * Set layer of attributes
     */   
    function setTraitLayer(string memory key, string memory value) external onlyOwner onlyDeactive {
        traitLayers[key] = value;
    }

    /**
     * Set layers of ratio
     */   
    function setRatioLayers(string memory key, Ratio memory value) external onlyOwner onlyDeactive {
        ratioLayerKeys[key] = value.keys;
        ratioLayerValues[key] = value.values;
    }

    /**
     * Set colors of ratio
     */   
    function setRatioColors(string memory key, Ratio memory value) external onlyOwner onlyDeactive {
        ratioColorKeys[key] = value.keys;
        ratioColorValues[key] = value.values;
    }

    /**
     * Controller of contract state
     * With this modifier, admin can set attribute variables (colors, layers, ratios) just before minting.
     */   
    modifier onlyDeactive {
        require(tokenState == false, "token.state");
		_;
   }

}

contract OnChainMachinesMetadata is Source {

    // Struct for attribute trait
    struct Object {
        string layer;
        string color;
    }

    /**
     * Returns metadata and vector value
     */
    function getMetadata(uint256 token, address minter, uint256 timestamp) external view returns (string memory) {
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(string(abi.encodePacked(
            '{"name": "OnChainMachines #',
            Convert.toString(token),
            '", "image": "data:image/svg+xml;base64,',
            Base64.encode(bytes(getVector(token, minter, timestamp))),
            '", "attributes": [',
            getAttributes(token, minter, timestamp),
            ']}'
        ))))));
    }

    /**
     * Layer & Color for each attribute
     * Select layer and layer color by weighted random.
     */   
    function getResource(string memory name, uint256 token, address minter, uint256 timestamp) internal view returns (Object memory) {
        string memory proxy = keccak256(abi.encodePacked(name)) == keccak256(abi.encodePacked("Jaw")) ? "Model" : name;

        string memory layer = ratioLayerKeys[name][Random.byWeight(token, proxy, minter, timestamp, ratioLayerValues[name])];
        string memory color = ratioColorKeys[layer][Random.byWeight(token, layer, minter, timestamp, ratioColorValues[layer])];

        return Object({ layer: layer, color: color });
    }

    /**
     * Name & color for attributes
     * Return json object with trait type and value
     */   
    function getAttributes(uint256 token, address minter, uint256 timestamp) internal view returns (string memory attribute) {
        for (uint8 i = 0; i < traitAttributes.length; i++) {
            string memory name = traitAttributes[i];
            Object memory object = getResource(name, token, minter, timestamp);
            string memory value = object.layer;

            if (keccak256(abi.encodePacked(name)) == keccak256(abi.encodePacked("Jaw"))) continue;
            if (keccak256(abi.encodePacked(object.color)) != keccak256(abi.encodePacked("None"))) value = string(abi.encodePacked(object.color, ' ', object.layer));
            if (i > 0) attribute = string(abi.encodePacked(attribute, ','));

            attribute = string(abi.encodePacked(attribute, '{"trait_type": "', traitAttributes[i], '", "value": "', value, '"}'));
        }
    }

    /**
     * Generate SVG string
     */       
	function getVector(uint256 token, address minter, uint256 timestamp) internal view returns (string memory) {
        return string(abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" width="600" height="600" viewBox="0 0 600 600" >',
            string(abi.encodePacked(
                '<style>.x{opacity:.25}.u{filter:drop-shadow(0 0 15px rgba(0,0,0,.2))}.s{fill:rgba(0,0,0,.1);stroke-width:0}.d{fill:rgba(0,0,0,.15)}.l{fill:rgba(250,250,250,.15)}.t{fill:none}.e{fill:#505050}.i{fill:#828282}.o{fill:#b4b4b4}.m{fill:',
                traitColors[getResource("Model", token, minter, timestamp).layer],
                '}.c{fill:',
                traitColors[string(abi.encodePacked(getResource("Model", token, minter, timestamp).layer, "C"))],
                '}</style>'
            )),
            string(abi.encodePacked(
                '<defs><pattern id="n" width="20" height="20" patternUnits="userSpaceOnUse" ><g stroke="#3c1e5a" opacity=".35" ><line x1="0" y1="0" x2="20" y2="20" /><line x1="20" y1="0" x2="0" y2="20" /></g></pattern><linearGradient id="d" x1="0" x2="0" y1="0" y2="100%"><stop offset="0%" stop-color="',
                traitColors[getResource("Background", token, minter, timestamp).color],
                '" /><stop offset="100%" stop-color="',
                traitColors[string(abi.encodePacked(getResource("Background", token, minter, timestamp).color, "D"))],
                '" /></linearGradient><linearGradient id="l" x1="0" x2="0" y1="0" y2="100%"><stop offset="0%" stop-color="',
                traitColors[string(abi.encodePacked(getResource("Background", token, minter, timestamp).color, "L"))],
                '" /><stop offset="100%" stop-color="',
                traitColors[string(abi.encodePacked(getResource("Background", token, minter, timestamp).color, "D"))],
                '" /></linearGradient></defs>'
            )),
            '<g stroke-width="7" stroke="#3c1e5a" >',
            getElements(token, minter, timestamp),
            '</g></svg>'
        ));
    }

    /**
     * Generate attributes layer graphic
     */   
    function getElements(uint256 token, address minter, uint256 timestamp) internal view returns (string memory element) {
        for (uint8 i = 0; i < traitAttributes.length; i++) {
            string memory name = traitAttributes[i];
            Object memory object = getResource(name, token, minter, timestamp);

            element = string(abi.encodePacked(
                element,
                '<g fill="',
                traitColors[object.color],
                '" >',
                traitLayers[object.layer],
                '</g>'
            ));
        }
    }

}