/**
 *Submitted for verification at Etherscan.io on 2022-08-26
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

pragma solidity ^0.8.0;

contract cre is Ownable {

    uint256 public cooldown;
    bool public live;

    struct Pixel {
        bytes32 color;
        address holder;
    }

    Pixel[2500] public pixels; 
    mapping(address => uint256) public walletCooldown;

    constructor() {
        live = true;
        cooldown = 60;
    }

    event PixelPlaced(uint256 location, bytes32 color, address holder);

    function setCooldown(uint256 newCooldown) public onlyOwner {
        cooldown = newCooldown;
    }

    function power() public onlyOwner {
        live ? live = false : live = true;
    }

    function playerCooldown(address wallet) public view returns(uint256) {
        if (block.timestamp - walletCooldown[wallet] >= cooldown) {
            return 0;
        } else {
            return cooldown - (block.timestamp - walletCooldown[wallet]);
        }
    }

    function placePixel(uint256 _location, bytes32 _color) public {
        require(acceptedColor(_color), "not accepted color");
        require(_location < 2500, "out of bounds");
        if (msg.sender != owner()) {
            require(block.timestamp - walletCooldown[msg.sender] >= cooldown, "cannot place pixel yet");
            walletCooldown[msg.sender] = block.timestamp;
        }
        pixels[_location] = Pixel({
            color: _color,
            holder: msg.sender
        });
        emit PixelPlaced(_location, _color, msg.sender);
    }

    function returnSinglePixel(uint256 _location) public view returns (bytes32 color_, address holder_) {
        Pixel memory pixel = pixels[_location];
        return (pixel.color, pixel.holder);
    }

    function fetchRow(uint256 multiplier) public view returns (bytes32[] memory) {
        bytes32[] memory boardRow = new bytes32[](50);
        for (uint256 i = 0; i < 50; i++) {
            Pixel memory pixel = pixels[i+(multiplier*50)];
            boardRow[i] = pixel.color;
        }
        return boardRow;
    }

    function acceptedColor(bytes32 color) public pure returns(bool) {
        if (
            color == 0x2366663030303000000000000000000000000000000000000000000000000000 || //red
            color == 0x2346464135303000000000000000000000000000000000000000000000000000 || //orange
            color == 0x2346464646303000000000000000000000000000000000000000000000000000 || //yellow
            color == 0x2330304646303000000000000000000000000000000000000000000000000000 || //green
            color == 0x2330303030464600000000000000000000000000000000000000000000000000 || //blue
            color == 0x2334423030383200000000000000000000000000000000000000000000000000 || //indigo
            color == 0x2337663030666600000000000000000000000000000000000000000000000000 || //violet
            color == 0x2346464646464600000000000000000000000000000000000000000000000000 || //white
            color == 0x2330303030303000000000000000000000000000000000000000000000000000 || //black
            color == 0x2338303830383000000000000000000000000000000000000000000000000000    //grey
        ) {
            return true;
        } else {
            return false;
        }
    }
}