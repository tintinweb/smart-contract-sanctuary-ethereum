/**
 *Submitted for verification at Etherscan.io on 2022-08-22
*/

// SPDX-License-Identifier: GPL-3.0

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: contracts/qr.sol



pragma solidity ^0.8.0;


interface Collection{
    function ownerOf(uint256 _tokenId) external view returns (address);
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

contract QR is Ownable{

    uint256 displayCounter;

    constructor(){
        displayCounter = 0;
    }

    struct displayStruct{
        address displayOwner;
        uint256 tokenId;
        uint256 startTime;
        uint256 endTime;
        address collectionAddress;
        address nftOwnerAddress;
        uint256 rentPer10Mins;
    }

    struct displayNumber{
        uint256 dispNum;
    }

    uint256 displayOwnedArray;

    mapping (uint256 => displayStruct) public display;

    mapping (address => displayNumber[]) public displayOwnerMapping;

    mapping (address => bool) public whitelist;

    event Display(uint256 _displayId, displayStruct _displayDetails);

    function createDisplay(uint256 _rentPer10Mins) public isWhitelisted{
        display[displayCounter].displayOwner = msg.sender;
        display[displayCounter].rentPer10Mins = _rentPer10Mins;
        displayOwnerMapping[msg.sender].push(displayNumber(displayCounter));
        displayCounter++;
    }

    function setImage(address _NFTAddress, uint256 _tokenId, uint256 _displayId, uint256 _time) public payable{
        require(display[_displayId].endTime < block.timestamp, "The display is occupied");
        require(msg.value >= display[_displayId].rentPer10Mins * _time / 10, "Cost error");
        Collection thisCollection = Collection(_NFTAddress);
        require(thisCollection.ownerOf(_tokenId) == msg.sender, "Sender is not the owner of NFT");
        display[_displayId].tokenId = _tokenId;
        uint256 start = block.timestamp;
        display[_displayId].startTime = start;
        display[_displayId].endTime = start + _time;
        display[_displayId].collectionAddress = _NFTAddress;
        display[_displayId].nftOwnerAddress = msg.sender;
        uint256 displayOwnerShare = msg.value * 100 / 95;
        address displayOwner = display[_displayId].displayOwner;
        payable(displayOwner).transfer(displayOwnerShare);
        emit Display(_displayId, display[_displayId]);
        
    }

    modifier isWhitelisted(){
        require(whitelist[msg.sender] == true, "You are not the authorized to create a display");
        _;
    }

    function setRent(uint256 _displayId, uint256 _cost) public {
        require(display[_displayId].displayOwner == msg.sender,"Only display owners are authorized to set rent");
        display[_displayId].rentPer10Mins = _cost;
    }

    function getDisplaysOwned(address _address) public view virtual returns (uint256[] memory){
        uint256 len = displayOwnerMapping[_address].length;
        uint256[] memory displaysArray = new uint256[](len);
        for(uint256 i = 0; i < len; i++ ){
            displaysArray[i] = displayOwnerMapping[_address][i].dispNum;
        }
        return displaysArray;
    } 

    function addWhitelist(address _address) public onlyOwner{
        whitelist[_address] = true;
    }

    function removeWhitelist(address _address) public onlyOwner{
        whitelist[_address] = false;
    }

    function changeDisplayOwner(address _addressOld, address _addressNew) public onlyOwner{
        uint256[] memory displaysOwned = getDisplaysOwned(_addressOld);
        require(displaysOwned.length > 0, "Address owns no displays");
        delete displayOwnerMapping[_addressOld];
        for(uint256 i = 0; i < displaysOwned.length; i++){
            uint256 displayNumberTemp = displaysOwned[i];
            display[displayNumberTemp].displayOwner = _addressNew;
            displayOwnerMapping[_addressNew].push(displayNumber(displayNumberTemp));
        }
    }
}