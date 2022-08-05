pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IOnlyUps.sol";


// █▀█ █▄░█ █░░ █▄█ █░█ █▀█ █▀ ░ ▀▄▀ █▄█ ▀█
// █▄█ █░▀█ █▄▄ ░█░ █▄█ █▀▀ ▄█ ▄ █░█ ░█░ █▄

// ╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋┏┓╋╋╋╋╋╋╋╋╋╋┏┓╋╋╋╋╋╋╋╋┏┓
// ╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋┃┃╋╋╋╋╋╋╋╋╋┏┛┗┓╋╋╋╋╋╋┏┛┗┓
// ┏━━┳━┳┳━━┳┳━┓┏━━┫┃╋┏━━┳━━┳━╋┓┏╋━┳━━┳━┻┓┏╋━━┓
// ┃┏┓┃┏╋┫┏┓┣┫┏┓┫┏┓┃┃╋┃┏━┫┏┓┃┏┓┫┃┃┏┫┏┓┃┏━┫┃┃━━┫
// ┃┗┛┃┃┃┃┗┛┃┃┃┃┃┏┓┃┗┓┃┗━┫┗┛┃┃┃┃┗┫┃┃┏┓┃┗━┫┗╋━━┃
// ┗━━┻┛┗┻━┓┣┻┛┗┻┛┗┻━┛┗━━┻━━┻┛┗┻━┻┛┗┛┗┻━━┻━┻━━┛
// ╋╋╋╋╋╋┏━┛┃
// ╋╋╋╋╋╋┗━━┛

// █▄░█ █▀▀ ▀█▀ █▀   █░░ █▀█ █▀▀ █▄▀ █▀▀ █▀▄   ▀█▀ █▀█   █▀▀ █▀█   █░█ █▀█
// █░▀█ █▀░ ░█░ ▄█   █▄▄ █▄█ █▄▄ █░█ ██▄ █▄▀   ░█░ █▄█   █▄█ █▄█   █▄█ █▀▀

// ONLYUPS.XYZ
// ORIGINAL CONTRACTS
// NFTS LOCKED TO GO UP

// BUILDING DEFI ON OPENSEA
// BUILDING DEFI ON OPENSEA
// BUILDING DEFI ON OPENSEA

contract FairMint is Ownable {

    IOnlyUps public onlyUpsNFT;

    mapping(address => bool) public wl;
    uint256 public wlCount;
    bool public isFM;

    uint256 public dropPrice = 9 ether / 100;

    // soft cap mint
    function mintWL() public payable
    {
        require(isFM, "fm");
        require(wl[msg.sender], "nowl");
        require(msg.value == dropPrice, "mprice");
        onlyUpsNFT.minter{value: (2 ether /10)}(msg.sender);
        onlyUpsNFT.distribute();
        //explicit sol8 style
        wlCount = wlCount - 1;
        wl[msg.sender] = false;
    }

    // soft cap mint
    function mintAll() public payable
    {
        require(isFM, "fm");
        require(msg.value == dropPrice, "mprice");
        uint256 id = onlyUpsNFT.minter{value: (2 ether /10)}(msg.sender);
        require(id < (9999 - wlCount), "wls");
        onlyUpsNFT.distribute();
    }

    function startFM(bool _is) public onlyOwner {
        isFM = _is;
    }


    function addToWl(address[] memory _wlUs) public onlyOwner {
        for (uint i=0; i<_wlUs.length; i++) {
            wl[_wlUs[i]] = true;
        }
        wlCount = wlCount + _wlUs.length;
    }

    function removeFromWl(address[] memory _wlUs) public onlyOwner {
        for (uint i=0; i<_wlUs.length; i++) {
            wl[_wlUs[i]] = false;
        }
        wlCount = wlCount - _wlUs.length;
    }

    function transferToChef(address _chef) public onlyOwner {
        onlyUpsNFT.transferOwnership(_chef);
    }

    function distributeChef() public onlyOwner {
        address payable _to = payable(msg.sender);
        _to.transfer(address(this).balance);
    }


    constructor(address _onlyups) {
        onlyUpsNFT = IOnlyUps(_onlyups);

    }

    receive() external payable {}

}

pragma solidity ^0.8.6;

// █▀█ █▄░█ █░░ █▄█ █░█ █▀█ █▀ ░ ▀▄▀ █▄█ ▀█
// █▄█ █░▀█ █▄▄ ░█░ █▄█ █▀▀ ▄█ ▄ █░█ ░█░ █▄

// ╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋┏┓╋╋╋╋╋╋╋╋╋╋┏┓╋╋╋╋╋╋╋╋┏┓
// ╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋╋┃┃╋╋╋╋╋╋╋╋╋┏┛┗┓╋╋╋╋╋╋┏┛┗┓
// ┏━━┳━┳┳━━┳┳━┓┏━━┫┃╋┏━━┳━━┳━╋┓┏╋━┳━━┳━┻┓┏╋━━┓
// ┃┏┓┃┏╋┫┏┓┣┫┏┓┫┏┓┃┃╋┃┏━┫┏┓┃┏┓┫┃┃┏┫┏┓┃┏━┫┃┃━━┫
// ┃┗┛┃┃┃┃┗┛┃┃┃┃┃┏┓┃┗┓┃┗━┫┗┛┃┃┃┃┗┫┃┃┏┓┃┗━┫┗╋━━┃
// ┗━━┻┛┗┻━┓┣┻┛┗┻┛┗┻━┛┗━━┻━━┻┛┗┻━┻┛┗┛┗┻━━┻━┻━━┛
// ╋╋╋╋╋╋┏━┛┃
// ╋╋╋╋╋╋┗━━┛

// █▄░█ █▀▀ ▀█▀ █▀   █░░ █▀█ █▀▀ █▄▀ █▀▀ █▀▄   ▀█▀ █▀█   █▀▀ █▀█   █░█ █▀█
// █░▀█ █▀░ ░█░ ▄█   █▄▄ █▄█ █▄▄ █░█ ██▄ █▄▀   ░█░ █▄█   █▄█ █▄█   █▄█ █▀▀

// ONLYUPS.XYZ
// ORIGINAL CONTRACTS
// NFTS LOCKED TO GO UP

// BUILDING DEFI ON OPENSEA
// BUILDING DEFI ON OPENSEA
// BUILDING DEFI ON OPENSEA


interface IOnlyUps{
    //721
    function minter(address _to) external payable returns (uint256);

    function distribute() external;
    function setMint(bool _isOpen) external;
    function transferOwnership(address newOwner) external;

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