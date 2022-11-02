// SPDX-License-Identifier: dvdch.eth
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Whitelist is Ownable {
    struct asset {
        string name;
        address token;
        address aToken;
    }
    asset[] public Assets;

    constructor() {
        asset memory _asset;
        _asset.name = "USDC";
        _asset.token = 0xA2025B15a1757311bfD68cb14eaeFCc237AF5b43;
        _asset.aToken = 0x1Ee669290939f8a8864497Af3BC83728715265FF;
        Assets.push(_asset);
    }

    function declareAsset(
        string memory _name,
        address _token,
        address _aToken
    ) public onlyOwner {
        for (uint256 i = 0; i < Assets.length; i++) {
            if (Assets[i].token == _token) {
                revert("Asset already declared");
            }
        }
        asset memory _asset;
        _asset.name = _name;
        _asset.token = _token;
        _asset.aToken = _aToken;
        Assets.push(_asset);
    }

    function deleteAsset(address _token) public onlyOwner {
        for (uint256 i = 0; i < Assets.length; i++) {
            if (Assets[i].token == _token) {
                Assets[i] = Assets[Assets.length - 1];
                Assets.pop();
            }
        }
    }

    function getAssetListLength() public view returns (uint256) {
        return Assets.length;
    }

    function getAsset(uint256 _nb) public view returns (asset memory) {
        return Assets[_nb];
    }

    function getAssetAddress(uint256 _nb) public view returns (address) {
        return Assets[_nb].token;
    }

    function getAssetName(uint256 _nb) public view returns (string memory) {
        return Assets[_nb].name;
    }

    function getAaveAssetAddress(uint256 _nb) public view returns (address) {
        return Assets[_nb].aToken;
    }

    modifier isWhitelisted(address _token) {
        bool _whitelisted = false;
        for (uint256 i = 0 ; i < Assets.length; i++) {
            if (_token == Assets[i].token) {
                _whitelisted = true;
            }
        }
        require(_whitelisted);
        _;
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