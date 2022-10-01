// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";

interface NFTcontract {
    function mint(address _to, uint256 _id) external;

    function getTotalMinted() external view returns (uint256);
}

contract launchpad is Ownable {
    NFTcontract public tokenContract;

    address payable public Treasury_wallet;

    uint16 public maxTotalSupply;
    uint256 public mintPrice;

    uint256 public startAt;
    uint256 public expiresAt;

    event LaunchpadStarting(
        uint256 expiresAt,
        uint16 maxTotalSupply,
        uint256 mintPrice
    );

    constructor(address payable _Treasury) {
        Treasury_wallet = _Treasury;
    }

    // external ----------------------------------------------------

    function privateMint(address to, uint16 count) external payable {
        require(block.timestamp < expiresAt, "Launchpad time has expired");
        require(
            msg.value == mintPrice * count,
            "Value is not equal to price * count"
        );

        _mintToken(to, count);
    }

    // internal ----------------------------------------------------

    function _mintToken(address _to, uint16 _count) internal {
        require(_count > 0, "Min amount is 1");
        require(
            maxTotalSupply - _count >= 0,
            "Limit: launchpad NFT has ended or too much count"
        );

        for (uint16 i = 0; i < _count; i++) {
            uint256 totalMinted = tokenContract.getTotalMinted();

            tokenContract.mint(_to, totalMinted + 1);
        }

        maxTotalSupply -= _count;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    // admin -------------------------------------------------------

    function setLaunchpadStart(
        uint16 _maxTotalSupply,
        uint256 _mintPrice,
        uint256 _duration,
        uint256 _startAfter
    ) external onlyOwner {
        require(block.timestamp + _duration > block.timestamp, "Invalid input");

        maxTotalSupply = _maxTotalSupply;
        mintPrice = _mintPrice;
        startAt = block.timestamp + _startAfter;
        expiresAt = startAt + _duration;

        emit LaunchpadStarting(expiresAt, maxTotalSupply, mintPrice);
    }

    // set ERC721 deployed contract address
    function setTokenContract(NFTcontract _tokenContract) external onlyOwner {
        tokenContract = _tokenContract;
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