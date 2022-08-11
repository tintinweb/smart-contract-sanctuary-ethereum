// SPDX-License-Identifier: MIT
//  ___   _  __   __  ______   _______  _______  _______  ___      
// |   | | ||  | |  ||      | |   _   ||       ||   _   ||   |     
// |   |_| ||  | |  ||  _    ||  |_|  ||  _____||  |_|  ||   |     
// |      _||  |_|  || | |   ||       || |_____ |       ||   |     
// |     |_ |       || |_|   ||       ||_____  ||       ||   |     
// |    _  ||       ||       ||   _   | _____| ||   _   ||   |     
// |___| |_||_______||______| |__| |__||_______||__| |__||___|     
//  _______  _______  _______  ______    _______  _______  _______ 
// |       ||       ||       ||    _ |  |   _   ||       ||       |
// |  _____||_     _||   _   ||   | ||  |  |_|  ||    ___||    ___|
// | |_____   |   |  |  | |  ||   |_||_ |       ||   | __ |   |___ 
// |_____  |  |   |  |  |_|  ||    __  ||       ||   ||  ||    ___|
//  _____| |  |   |  |       ||   |  | ||   _   ||   |_| ||   |___ 
// |_______|  |___|  |_______||___|  |_||__| |__||_______||_______|

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";

contract KudasaiStorage is Ownable {
    enum Parts {
        back,
        body,
        hair,
        eyewear,
        face
    }
    mapping(Parts => uint256) public imageIdCounter;
    mapping(Parts => mapping(uint256 => string)) public images;
    mapping(Parts => mapping(uint256 => string)) public imageNames;
    mapping(Parts => mapping(uint256 => uint256)) public weights;
    mapping(Parts => uint256) public totalWeight;
    string public haka;

    function getKudasai(uint256 _back, uint256 _body, uint256 _hair, uint256 _eyewear, uint256 _face) external view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" buffered-rendering="static" width="1200px" height="1200px" viewBox="0,0,1200,1200"><defs>',
                    '<g id="bk">', images[Parts.back][_back], '</g>',
                    '<g id="bd">', images[Parts.body][_body], '</g>',
                    '<g id="h">', images[Parts.hair][_hair], '</g>',
                    '<g id="e">', images[Parts.eyewear][_eyewear], '</g>',
                    '<g id="f">', images[Parts.face][_face], '</g>',
                    '</defs><use href="#bk"/><use href="#bd"/><use href="#f"/><use href="#h"/><use href="#e"/></svg>'
                )
            );
    }

    function getHaka() external view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" buffered-rendering="static" width="1200px" height="1200px" viewBox="0,0,1200,1200"><defs>',
                    '<g id="hakc">', haka, '</g>',
                    '</defs><use href="#hakc"/></svg>'
                )
            );
    }

    function getWeight(uint256 _parts, uint256 _id) external view returns (uint256) {
        return weights[Parts(_parts)][_id];
    }

    function getTotalWeight(uint256 _parts) external view returns (uint256) {
        return totalWeight[Parts(_parts)];
    }

    function getImageName(uint256 _parts, uint256 _id) external view returns (string memory) {
        return imageNames[Parts(_parts)][_id];
    }

    function getImageIdCounter(uint256 _parts) external view returns (uint256) {
        return imageIdCounter[Parts(_parts)];
    }

    function importHaka(string memory _svg) external onlyOwner {
        haka = _svg;
    }

    function importImage(uint256 _parts, uint256 _weight, string memory _svg, string memory _name) external onlyOwner {
        images[Parts(_parts)][imageIdCounter[Parts(_parts)]] = _svg;
        imageNames[Parts(_parts)][imageIdCounter[Parts(_parts)]] = _name;
        weights[Parts(_parts)][imageIdCounter[Parts(_parts)]] = _weight;
        totalWeight[Parts(_parts)] += _weight;
        imageIdCounter[Parts(_parts)]++;
    }

    function changeImage(uint256 _parts, uint256 _id, uint256 _weight, string memory _svg, string memory _name) external onlyOwner {
        require(_id < imageIdCounter[Parts(_parts)], "None");
        images[Parts(_parts)][_id] = _svg;
        imageNames[Parts(_parts)][imageIdCounter[Parts(_parts)]] = _name;
        totalWeight[Parts(_parts)] -= weights[Parts(_parts)][_id];
        weights[Parts(_parts)][_id] = _weight;
        totalWeight[Parts(_parts)] += _weight;
    }
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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