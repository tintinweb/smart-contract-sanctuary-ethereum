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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import './interfaces/IERC20.sol';


contract IDO is Ownable {
    address public GameBoyAddr = 0x95697B2c78A32aE47cc172ccf91648ceE169Ef81;
    address public USDTAddr = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public eyewitness = 0x6f9990411b0c0596129784D8681f79272aC9D9a6;

    uint public lowerLimit = 200 * 10 ** 6;
    uint public upperLimit = 2000 * 10 ** 6;

    mapping (uint8 => mapping(address => uint)) public amountLimit;

    IERC20 public USDT;
    IERC20 public GameBoy;

    event IDOEvent(address indexed user, uint USDTAmount, uint GameBoyAmount);

    constructor() {
        USDT = IERC20(USDTAddr);
        GameBoy = IERC20(GameBoyAddr);
    }

    function ido(uint amount_, uint8 nonce_, uint8 v, bytes32 r, bytes32 s) public {
        require(amount_ >= lowerLimit, "Invalid amount");
        require(upperLimit-amountLimit[nonce_][msg.sender] >= amount_, "Insufficient quota");
        require(ecrecover(keccak256(abi.encodePacked(nonce_, amount_, msg.sender)), v, r, s) == eyewitness, 'INVALID_SIGNATURE');
        amountLimit[nonce_][msg.sender] += amount_;
        USDT.transferFrom(msg.sender, owner(), amount_);
        uint gameBoyAmount = amount_ * 100 * 10 / 4;
        GameBoy.transferFrom(owner(), msg.sender, gameBoyAmount);
        emit IDOEvent(msg.sender, amount_, gameBoyAmount);
    }

    function setEyewitness(address addr) public onlyOwner {
        require(addr != address(0), "addr is 0");
        eyewitness = addr;
    }

    function setLimit(uint lowerLimit_, uint upperLimit_) public onlyOwner {
        require(upperLimit_ >= lowerLimit_ && upperLimit_ > 0, "Invalid limit");
        lowerLimit = lowerLimit_;
        upperLimit = upperLimit_;
    }
}

pragma solidity ^0.8.9;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}