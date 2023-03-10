// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IKyudoNFT {
    function totalSupply() external view returns (uint);
}

interface IBowCoin {
    function totalSupply() external view returns (uint);
}

contract RandomNumGenerator is Ownable {
    IKyudoNFT private _kyudoNft;
    IBowCoin private _bowCoin;

    uint private _randomNumber;
    mapping(uint => address) private _seedAddresses;

    constructor() {
        // Fill random source addresses
        _seedAddresses[0] = 0x0000000000000000000000000000000000001000;
        _seedAddresses[1] = 0x0000000000000000000000000000000000001007;
        _seedAddresses[2] = 0x0000000000000000000000000000000000001002;
        _seedAddresses[3] = 0x0000000000000000000000000000000000001008;
        _seedAddresses[4] = 0x0000000000000000000000000000000000001005;
        _seedAddresses[5] = 0x11FcA460F2a4202b467aA6B00C9d3482d69D7C12;
        _seedAddresses[6] = 0x40375C92d9FAf44d2f9db9Bd9ba41a3317a2404f;
    }

    function setContracts(IKyudoNFT kyudoNft, IBowCoin bowCoin) external onlyOwner {
        _kyudoNft = IKyudoNFT(kyudoNft);
        _bowCoin = IBowCoin(bowCoin);
    }

    function getRandomNumber(uint _seed, uint _limit) public view returns (uint16) {
        uint extra = 0;
        for (uint16 i = 0; i < 7; i++) {
            extra += _seedAddresses[i].balance;
        }

        uint random = uint(
            keccak256(
                abi.encodePacked(
                    _kyudoNft.totalSupply(),
                    _seed,
                    blockhash(block.number - 1),
                    block.coinbase,
                    block.difficulty,
                    msg.sender,
                    extra,
                    _randomNumber,
                    _bowCoin.totalSupply()
                )
            )
        );

        return uint16(random % _limit);
    }

    function useNewAddr(uint _id, address _address) external onlyOwner {
        _seedAddresses[_id] = _address;
    }

    function useNewRandomNumber(uint _seed, uint _max) external onlyOwner {
        _randomNumber = getRandomNumber(_seed, _max);
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