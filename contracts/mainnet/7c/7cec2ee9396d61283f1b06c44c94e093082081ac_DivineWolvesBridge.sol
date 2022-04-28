/**
 *Submitted for verification at Etherscan.io on 2022-04-27
*/

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

// File: contracts/Bridge.sol

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/**
 * @title Divine Wolves Bridge
 */





interface IFang {
	function mintFromExtentionContract(address _to, uint256 _amount) external;
    function burnFromExtentionContract(address _to, uint256 _amount) external ;
}



contract DivineWolvesBridge is  Ownable{

    IFang fang;
    mapping(address => bool) _allowed;

    constructor() {
             fang = IFang(0x3D7462b447f5cf13B7A055A0F8Eaf7d231Da5CeF);
             _allowed[0xcf2EE98aB154316A041a252e8175e400dc0BA2E3] = true;
             _allowed[0x4aDC718394d6b58Ea183B38aaFa034399650EF58] = true;
             _allowed[0x1ca33E38Bea509C94eebd63636147425983d2c9E] = true;

    }

    function setFangaddress(address _val) public  onlyOwner{
        fang = IFang(_val);
    }

     modifier onlyExtensionContract() {
        require(_allowed[msg.sender], "Not Allowed");
        _;
    }

    function setAllowed(address _user, bool _state) public onlyOwner {
        _allowed[_user] = _state;
    }

     function mintFromExtentionContract(address _to, uint256 _amount) external onlyExtensionContract {
        fang.mintFromExtentionContract(_to, _amount);
    }

    function burnFromExtentionContract(address _to, uint256 _amount) external onlyExtensionContract {
        fang.burnFromExtentionContract(_to, _amount);
    }

}