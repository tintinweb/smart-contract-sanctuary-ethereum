/**
 *Submitted for verification at Etherscan.io on 2022-08-25
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
    
    // mapping(address=>bool) public minters;
    
    constructor() {
    // constructor(uint256 initialSupply) ERC20("tntd", "atrh") {
        // _mint(msg.sender, 1000000000 * 10**18); // 1 bil
        // _mint(msg.sender, initialSupply);
    }
    
    // modifier onlyMinter() {
    //     require(minters[msg.sender]);
    //     _;
    // }
    
    // function changeMinter(address account, bool position) public onlyOwner {
    //     position ? minters[account] = true : minters[account] = false;
    // }
    
    // function burn(address account, uint256 amount) public onlyMinter {
    //     _burn(account, amount);
    // }
    
    // function mint(address account, uint256 amount) public onlyMinter {
    //     _mint(account, amount);
    // }

    struct Pixel {
        bytes32 color;
        address holder;
        uint256 cooldown;
    }

    Pixel[2500] public pixels; 

    // uint256 public maxSize = 100;
    uint256 public cooldown = 60;

    event PixelPlaced(uint256 location, bytes32 color, address holder);

    // function setMaxSize(uint256 newMaxSize) public onlyOwner {
    //     require(newMaxSize > maxSize);
    //     maxSize = newMaxSize;
    // }

    function setCooldown(uint256 newCooldown) public onlyOwner {
        cooldown = newCooldown;
    }

    function placePixel(uint256 _location, bytes32 _color) public {
        // require(balanceOf(msg.sender) >= 1000000000000000000, "error1");
        require(_location <= 2500, "error2");

        // Pixel memory pixel = pixels[_location];
        // require(pixel.holder != msg.sender, "error3");
        // require(block.timestamp - pixel.cooldown >= cooldown);

        // _burn(msg.sender, 1000000000000000000);

        pixels[_location] = Pixel({
            color: _color,
            holder: msg.sender,
            cooldown: block.timestamp
        });

        emit PixelPlaced(_location, _color, msg.sender);
        // return true;
    }

    function returnSinglePixel(uint256 _location) public view returns (bytes32 color_, address holder_, uint256 cooldown_) {
        Pixel memory pixel = pixels[_location];
        return (pixel.color, pixel.holder, pixel.cooldown);
    }

    function fetchRow(uint256 multiplier) public view returns (bytes32[] memory) {
        bytes32[] memory boardRow = new bytes32[](50);
        for (uint256 i = 0; i < 50; i++) {
            Pixel memory pixel = pixels[i+(multiplier*50)];
            boardRow[i] = pixel.color;
        }
        return boardRow;
    }

}