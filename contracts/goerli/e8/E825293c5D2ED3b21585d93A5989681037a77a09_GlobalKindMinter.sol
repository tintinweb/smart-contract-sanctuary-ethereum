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
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../weth/IWeth9.sol";
import "../niftykit/INiftyKit.sol";
import "./IGlobalKindMinter.sol";

contract GlobalKindMinter is Ownable, IGlobalKindMinter {

    INiftyKit public niftykit;
    address payable public ethRecipient;
    address  public wethRecipient;
    IWETH9 public weth;


    constructor(address _niftykit, address payable _ethRecipient, address _wethRecipient, address payable _weth)  {
        niftykit = INiftyKit(_niftykit);
        ethRecipient = _ethRecipient;
        wethRecipient = _wethRecipient;
        weth = IWETH9(_weth);
    }

    function setNiftyKit(address _niftykit) external onlyOwner {
        niftykit = INiftyKit(_niftykit);
    }

    function setEthRecipient(address payable _ethRecipient) external onlyOwner {
        ethRecipient = _ethRecipient;
    }

    function setWethRecipient(address _wethRecipient) external onlyOwner {
        wethRecipient = _wethRecipient;
    }

    function transferOwnershipProxy(address newOwner) external onlyOwner {
        niftykit.transferOwnership(newOwner);
    }

    function startSaleProxy(
        uint256 newMaxAmount,
        uint256 newMaxPerMint,
        uint256 newMaxPerWallet,
        uint256 newPrice,
        bool presale
    ) external onlyOwner {
        niftykit.startSale(newMaxAmount, newMaxPerMint, newMaxPerWallet, newPrice, presale);
    }

    function mintTo(address to, uint64 quantity) public payable {
        _mint(to, quantity);
    }

    function mint(uint64 quantity) external payable {
        _mint(msg.sender, quantity);
    }

    function _mint(address to, uint64 quantity) internal {
        payoutEther(to, quantity);
        address[] memory toArray = new address[](1);
        toArray[0] = to;
        uint64[] memory quantityArray = new uint64[](1);
        quantityArray[0] = quantity;

        niftykit.batchAirdrop(quantityArray, toArray);
    }

    function payoutEther(address from, uint64 quantity) internal {
        uint256 price = niftykit.price();

        require(quantity > 0, "Quantity too low");
        require(msg.value >= price * quantity, "Not enough funds sent");
        uint256 half = msg.value / 2;
        uint256 otherHalf = msg.value - half;

        //send half of eth to treasury
        ethRecipient.transfer(half);

        // swap half of eth to weth, and send back to sender
        weth.deposit{value : otherHalf}();
        weth.transfer(from, otherHalf);

        // send weth from sender to recipient2
        weth.transferFrom(from, wethRecipient, otherHalf);
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

interface IGlobalKindMinter {
    function mintTo(address to, uint64 quantity) external payable;
    function mint(uint64 quantity) external payable;

    function transferOwnershipProxy(address newOwner) external;

    function startSaleProxy(
        uint256 newMaxAmount,
        uint256 newMaxPerMint,
        uint256 newMaxPerWallet,
        uint256 newPrice,
        bool presale
    ) external;

    function setNiftyKit(address _niftykit) external;
    function setWethRecipient(address _wethRecipient) external;
    function setEthRecipient(address payable _ethRecipient) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


interface INiftyKit  {
    function transferOwnership(address newOwner) external;
    function batchAirdrop(
        uint64[] calldata quantities,
        address[] calldata recipients
    ) external;
    function startSale(
        uint256 newMaxAmount,
        uint256 newMaxPerMint,
        uint256 newMaxPerWallet,
        uint256 newPrice,
        bool presale
    ) external;

    function price() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IWETH9 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function balanceOf(address) external view returns (uint);

    function allowance(address, address) external view returns (uint);

    receive() external payable;

    function deposit() external payable;

    function withdraw(uint wad) external;

    function totalSupply() external view returns (uint);

    function approve(address guy, uint wad) external returns (bool);

    function transfer(address dst, uint wad) external returns (bool);

    function transferFrom(address src, address dst, uint wad)
    external
    returns (bool);
}