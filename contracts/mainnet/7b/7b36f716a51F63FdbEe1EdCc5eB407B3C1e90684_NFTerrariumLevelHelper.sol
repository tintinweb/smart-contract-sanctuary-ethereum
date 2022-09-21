/**
 *Submitted for verification at Etherscan.io on 2022-09-21
*/

// SPDX-License-Identifier: GPL-3.0

/**

    ╔╗╔╔═╗╔╦╗┌─┐┬─┐┬─┐┌─┐┬─┐┬┬ ┬┌┬┐
    ║║║╠╣  ║ ├┤ ├┬┘├┬┘├─┤├┬┘││ ││││
    ╝╚╝╚   ╩ └─┘┴└─┴└─┴ ┴┴└─┴└─┘┴ ┴
    Contract by @texoid__

*/


/**
 * @title nonReentrant module to prevent recursive calling of functions
 * @dev See https://medium.com/coinmonks/protect-your-solidity-smart-contracts-from-reentrancy-attacks-9972c3af7c21
 */
 
abstract contract nonReentrant {
    bool private _reentryKey = false;
    modifier reentryLock {
        require(!_reentryKey, "cannot reenter a locked function");
        _reentryKey = true;
        _;
        _reentryKey = false;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol
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


//- NFTerrariumDust Contract
pragma solidity >=0.8.0 <0.9.0;
abstract contract NFTerrariumDust { 

    function burnDust(uint256 _type, uint256 _amount, address _address) external virtual;
    function balanceOf(address account, uint256 id) public view virtual returns (uint256);

}

//- NFTerrarium Level Helper
pragma solidity >=0.8.0 <0.9.0;

contract NFTerrariumLevelHelper is Ownable, nonReentrant {

    bool public levelActive;
    NFTerrariumDust private immutable dust;

    constructor( address dustAddress ) {
        dust = NFTerrariumDust(dustAddress);
    }

    //---------------[ Events ]---------------\\
    event LevelToken(address _from, uint256 _type, uint256 _amount, address _contract, uint256 _tokenID);
    event LevelTokenWithExperience(address _from, uint256[] _type, uint256[] _amount, address _contract, uint256 _tokenID);

    //---------------[ Modifiers ]---------------\\
    modifier levellingActive() {
        require( levelActive, "Token levelling is not enabled.");
        _;
    }

    //---------------[ public burn Functions ]---------------\\
    function levelToken(address _contract, uint256 _tokenID) external payable levellingActive reentryLock {

        require( dust.balanceOf(msg.sender, 2) > 0, "You must own at least 1x White Dust");
        dust.burnDust(2, 1, msg.sender);

        emit LevelToken(msg.sender, 2 , 1, _contract, _tokenID);

    }

    function addExperienceAndLevel(uint256[] memory _type, uint256[] memory _amount, address _contract, uint256 _tokenID) external payable levellingActive reentryLock {

        require(_type.length == _amount.length, "Invalid dust type and amount values entered. Must be the same length.");

        uint typeLength = _type.length;
        for(uint i = 0; i < typeLength; i++) {
            require( dust.balanceOf(msg.sender, _type[i]) >= _amount[i], string(abi.encodePacked("You must own", _amount[i], "x dust type ", _type[i])) );
        } 

        for(uint i = 0; i < typeLength; i++) {
            dust.burnDust(_type[i], _amount[i], msg.sender);
        } 

        emit LevelTokenWithExperience(msg.sender, _type , _amount, _contract, _tokenID);
    }

    //---------------[ onlyOwner Functions ]---------------\\
    function toggleLevellingActive() public onlyOwner {
        levelActive = !levelActive;
    }

}