// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./tags/Tag.sol";

/*
 * This creates an example contract which can be queried to get "more info" about a tag.
 * Also called the "Tag Reference" this contract is a place to go to get more information.
 */
contract ExampleCC0Tag {
    address public license;
    address public owner;

    constructor() {
        owner = msg.sender;

        // create the tag reference
        Tag License = new Tag("license:cc0");
        license = address(License); // for testing

        // a readme provides a basic overview and should be included
        License.setReadme(
            "This tag refers to the Creative Commons CC0 License.\n"
            "CC0 (aka CC Zero) is a public dedication tool, which allows creators to give up their copyright and put their works into the worldwide public domain. CC0 allows reusers to distribute, remix, adapt, and build upon the material in any medium or format, with no conditions."
            "More information at https://creativecommons.org/share-your-work/public-domain/cc0/"
        );

        // these are optional, but could be useful to allow more granular querying
        License.set(
            "url",
            "https://creativecommons.org/share-your-work/public-domain/cc0/"
        );
        License.set("contact", '"Info" <[email protected]>'); // more info
        License.set("description", "creative commons v0 license");
        License.set("isa", "license");
        // ... and add more if needed...

        // Claims: Have your contract buy a license here by "buying a claim"

        // enable claims to allow contracts to "purchase" the thing.
        License.activateClaims(true);
        License.setClaimPrice(0.001 ether);

        // optional, setup a readme to show for people wanting info on claim purchase
        License.setClaimReadme(
            "Claims are available and entitle you to a license.\n"
            "Details may apply, please check our website for more information."
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Tag (Simple)
 * @dev Contract for defining Tags as part of the Tagged Contracts Protocol
 */

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Tag is Ownable {
    event TagClaimIsActive(bool claimsEnabled);
    event TagClaimPriced(uint256 claimsPrice);
    event TagSet(string name, string value);

    mapping(string => string) internal attributes; // just storing data: "foo" = "bar"
    string[] public keys; // TODO: refacfor this and ^^

    // optional list of claims
    mapping(address => bool) public claimList;
    uint256 public claimPrice = 0.005 ether; // set to 0 if you want free claims
    uint256 public createBlockTimestamp;
    bool public claimsEnabled = false;
    string public tag;
    string public readmeTxt = "";
    string public claimReadmeTxt = "";

    constructor(string memory _tag) {
        createBlockTimestamp = block.timestamp;
        tag = _toLower(_tag); // license:cc0
    }

    //
    // attribute getters/setters
    //
    function set(string memory name, string memory value) public onlyOwner {
        attributes[name] = value;
        keys.push(name);
        emit TagSet(name, value);
    }

    function get(string memory name) public view returns (string memory) {
        return attributes[name];
    }

    function attributesJson() public view returns (string memory) {
        string memory serialized = "[";

        for (uint256 i = 0; i < keys.length; i++) {
            serialized = string.concat(
                serialized, // ["thing:here","0x0",
                '"',
                keys[i],
                '","',
                attributes[keys[i]],
                '"'
            );
            if (i < keys.length) {
                serialized = string.concat(serialized, ",");
            }
        }
        serialized = string.concat(serialized, "]");
        return serialized; //string(abi.encodePacked(serialized));
    }

    // string to lowercaes
    function _toLower(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint256 i = 0; i < bStr.length; i++) {
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }

    //
    // readme functions
    //
    function setReadme(string memory _readme) public onlyOwner {
        readmeTxt = _readme;
    }

    function readme() public view returns (string memory) {
        return (readmeTxt);
    }

    //
    // claims functions: TODO allow purchase of claim by contract/user to prove ownership
    //
    function activateClaims(bool _claimsEnabled) public onlyOwner {
        claimsEnabled = _claimsEnabled;
        emit TagClaimIsActive(claimsEnabled);
    }

    function setClaimPrice(uint256 _claimPrice) public onlyOwner {
        require(_claimPrice >= 0, "INVALID CLAIM PRICE");
        claimPrice = _claimPrice;
        emit TagClaimPriced(claimPrice);
    }

    // TODO
    // function showProof(address) public {
    // }

    function setClaimReadme(string memory _claimReadme) public onlyOwner {
        claimReadmeTxt = _claimReadme;
    }

    function claimReadme() public view returns (string memory) {
        return (claimReadmeTxt);
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