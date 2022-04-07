/**
 *Submitted for verification at Etherscan.io on 2022-04-06
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

// File: contracts/KWWVault.sol


pragma solidity ^0.8.4;

contract KWWVaultEth is Ownable {
    //ETH Vault
    //boatId => amount
    mapping(uint16 => uint256) public boatsWithdrawAmount;
    //landId => ownerType (0-prince,1-princess, 2-landlord)
    mapping(uint16 => mapping(uint8 => uint256)) public landsWithdrawAmount;

    mapping(uint16 => uint256) public boatsMaxWithdraw;
    mapping(uint16 => uint256) public landsMaxWithdraw;

    uint256 teamWithdraw;
    uint256 teamMaxWithdraw;

    uint8 teamPercent = 10;

    address gameManager;

    //ETH Vault
    function depositBoatFees(uint16 totalSupply) public payable onlyGameManager{
        teamMaxWithdraw += msg.value / teamPercent;
        boatsMaxWithdraw[totalSupply] += (msg.value - msg.value / teamPercent ) / totalSupply;
    }

    function depositLandFees(uint16 landId) public payable onlyGameManager{
        teamMaxWithdraw += msg.value / teamPercent;
        landsMaxWithdraw[landId] += (msg.value - msg.value / teamPercent ) / 3;
    }

    function withdrawBoatFees(uint16 totalSupply, uint16 boatId, address addr) public onlyGameManager{
        uint256 availableToWithdraw = boatAvailableToWithdraw(totalSupply, boatId);
        (bool os, ) = payable(addr).call{value: availableToWithdraw}("");
        require(os);
        boatsWithdrawAmount[boatId] += availableToWithdraw;
    }

    function withdrawLandFees(uint16 landId, uint8 ownerTypeId, address addr) public onlyGameManager{
        uint256 availableToWithdraw = landAvailableToWithdraw(landId, ownerTypeId);
        (bool os, ) = payable(addr).call{value: availableToWithdraw}("");
        require(os);
        landsWithdrawAmount[landId][ownerTypeId] += availableToWithdraw;
    }

    /*
        GETTERS
    */

    function boatAvailableToWithdraw(uint16 totalSupply, uint16 boatId) public view returns(uint256) {
        uint16 maxState = (boatId / 100) * 100 + 100;
        uint256 withdrawMaxAmount= 0;
        for(uint16 i = boatId; i < totalSupply && i < maxState ; i++){
            withdrawMaxAmount += boatsMaxWithdraw[i];
        }
        return withdrawMaxAmount - boatsWithdrawAmount[boatId];
    }

    function landAvailableToWithdraw(uint16 landId, uint8 ownerTypeId) public view returns(uint256) {
        require(ownerTypeId < 3, "Owner type not valid");
        return landsMaxWithdraw[landId] - landsWithdrawAmount[landId][ownerTypeId];
    }

    function teamAvailableToWithdraw() public view returns(uint256) {
        return teamMaxWithdraw - teamWithdraw;
    }

    /*
        MODIFIERS
    */

    modifier onlyGameManager {
        require(gameManager != address(0), "Game manager not set");
        require(msg.sender == owner() || msg.sender == gameManager, "caller is not the Boats Contract");
        _;
    }

    /*
        ONLY OWNER
     */


    function withdrawFeesTeam(address teamWallet) public onlyOwner {
        uint256 availableToWithdraw = teamAvailableToWithdraw();
        (bool os, ) = payable(teamWallet).call{value: availableToWithdraw}("");
        require(os);
        teamWithdraw += availableToWithdraw;
    } 

    function withdrawAll(address teamWallet) public onlyOwner {
        (bool os, ) = payable(teamWallet).call{value: address(this).balance}("");
        require(os);
    }

    function setBoatsMaxWithdraw(uint16 totalSupplyIdx, uint256 maxWithdrawAmount) public onlyOwner{
        boatsMaxWithdraw[totalSupplyIdx] = maxWithdrawAmount;
    }

    function setLandsMaxWithdraw(uint16 landIdIdx, uint256 maxWithdrawAmount) public onlyOwner{
        landsMaxWithdraw[landIdIdx] = maxWithdrawAmount;
    }

    function setTeamMaxWithdraw(uint256 maxWithdrawAmount) public onlyOwner{
        teamMaxWithdraw = maxWithdrawAmount;
    }

    function setGameManager(address _addr) public onlyOwner{
        gameManager = _addr;
    }

    function setTeamPercent(uint8 _teamPercent) public onlyOwner{
        teamPercent = _teamPercent;
    }
}