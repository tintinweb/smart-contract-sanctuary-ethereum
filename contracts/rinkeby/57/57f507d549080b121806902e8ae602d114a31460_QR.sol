/**
 *Submitted for verification at Etherscan.io on 2022-08-26
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
    uint256 minimumRent = 0.0001 ether;

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

    mapping (uint256 => displayStruct) public display;

    mapping (address => displayNumber[]) public displayOwnerMapping;

    mapping (address => bool) public whitelist;

    event Display(uint256 _displayId, displayStruct _displayDetails);

    /**
     * @dev Initializes the contract setting the displayCounter to 0.
     */
    constructor(){
        displayCounter = 0;
    }

    /*
    * @notice Whitelisted users create display with initial rent
    * Minimum rent criteria must be met
    *
    * @dev Function checks if the caller is whitelisted and the rent exceeds
    * the minimum criteria. If checks are passed, initializes the display 
    * mapping's "displayOwner" and "rentPer10Mins" properties.
    * Finally, the newly created display is pushed to the "displayOwnerMapping"
    * array which is mapped to the corresponding address.
    *
    * @param _rentPer10Mins rent to be set for the newly created display
    */
    function createDisplay(uint256 _rentPer10Mins) public{
        require(isWhitelisted(msg.sender),"The address is not whitelisted");
        require(_rentPer10Mins >= minimumRent,"Minimum rent criteria not met");
        display[displayCounter].displayOwner = msg.sender;
        display[displayCounter].rentPer10Mins = _rentPer10Mins;
        displayOwnerMapping[msg.sender].push(displayNumber(displayCounter));
        displayCounter++;
    }

    /*
    * @notice Any user who holds an ERC721 NFT can set image for particular display
    * Display must not be occupied. The function caller must own the NFT.
    * The NFT should be ERC721 standaard
    *
    * @dev Function checks if the display is occupied, validates the rent 
    * and checks for NFT ownership. Upon validation, the displayId, startTime,endTime, 
    * collectionAddress and nftOwnerAddress properties of the display will be changed
    * A fixed share of display will be sent to the display owner wallet, 
    * rest will stay in the contract
    * Finally the Display event is emitted which contains displayId and display struct
    *
    * @param _NFTAddress address of the NFT collection to be displayed
    * @param _tokenId token id of NFT collection to display
    * @param _displayId id of display to set the image on
    * @param _time time duration in seconds for the image display
    */

    function setImage(address _NFTAddress, uint256 _tokenId, uint256 _displayId, uint256 _time) public payable{
        // require(display[_displayId].endTime < block.timestamp, "The display is occupied");
        require(!isOccupied(_displayId),"Display is occupied");
        require(msg.value >= display[_displayId].rentPer10Mins * _time / 600, "Cost error");
        Collection thisCollection = Collection(_NFTAddress);
        require(thisCollection.ownerOf(_tokenId) == msg.sender, "Sender is not the owner of NFT");
        display[_displayId].tokenId = _tokenId;
        uint256 start = block.timestamp;
        display[_displayId].startTime = start;
        display[_displayId].endTime = start + _time;
        display[_displayId].collectionAddress = _NFTAddress;
        display[_displayId].nftOwnerAddress = msg.sender;
        uint256 displayOwnerShare = msg.value * 95 / 100;
        address displayOwner = display[_displayId].displayOwner;
        payable(displayOwner).transfer(displayOwnerShare);
        emit Display(_displayId, display[_displayId]);
        
    }

    /*
    * @notice Display owners can call this function to reset image on any of their owned display
    *
    * @dev Only owners of the display can utilize this function
    * collectionAddress and nftOwner address of display will be set to address(0)
    * endTime will bec set to startTime
    * Finally the Display event is emitted which contains displayId and display struct
    *
    * @param _displayId display id of display to reset
    */
    function resetDisplay(uint256 _displayId) public{
        require(display[_displayId].displayOwner == msg.sender,"Only display owners are authorized to reset display");
        display[_displayId].collectionAddress = address(0);
        display[_displayId].nftOwnerAddress = address(0);
        display[_displayId].endTime = display[_displayId].startTime;
        emit Display(_displayId, display[_displayId]);
    }

    /*
    * @notice Function to check whitelist status
    *
    * @param _address address to check in the whitelist
    *
    * @return bool returns status of whitelist
    */
    function isWhitelisted(address _address) public view virtual returns(bool){
        return whitelist[_address];
    }

    /*
    * @notice Display owners can call this function to change rent for any of their owned display
    *
    * @dev Only owners of the display can utilize this function
    * Minimum rent criteria must be met
    *
    * @param _rentPer10Mins new rent
    */
    function setRent(uint256 _displayId, uint256 _cost) public {
        require(display[_displayId].displayOwner == msg.sender,"Only display owners are authorized to set rent");
        require(_cost >= minimumRent,"Minimum rent criteria not met");
        display[_displayId].rentPer10Mins = _cost;
    }

    /*
    * @notice Function to get displays owned by particular address
    *
    * @param _address wallet address whose displays are to be fetched
    *
    * @return uint256[] returns array of display id's owned by the address
    */
    function getDisplaysOwned(address _address) public view virtual returns (uint256[] memory){
        uint256 len = displayOwnerMapping[_address].length;
        uint256[] memory displaysArray = new uint256[](len);
        for(uint256 counter = 0; counter < len; counter++ )
            displaysArray[counter] = displayOwnerMapping[_address][counter].dispNum;
        return displaysArray;
    } 

    /*
    * @notice Function to add addresses to the whitelist
    * Only contract owner can call
    *
    * @param _addressList list of wallet address to add in whitelist
    */
    function addWhitelist(address[] memory _addressList) public onlyOwner{
        uint256 len = _addressList.length;
        for(uint256 counter = 0; counter < len; counter++)
            whitelist[_addressList[counter]] = true;
    }

    /*
    * @notice Function to remove addresses from the whitelist
    * Only contract owner can call
    *
    * @param _addressList list of wallet address to remove from whitelist
    */
    function removeWhitelist(address[] memory _addressList) public onlyOwner{
        uint256 len = _addressList.length;
        for(uint256 counter = 0; counter < len; counter++)
            whitelist[_addressList[counter]] = true;
    }

    /*
    * @notice Function to withdraw all balance to contract owner's wallet
    * Only contract owner can call
    */
    function withdraw() public onlyOwner{
        payable(owner()).transfer(address(this).balance);
    }

    /*
    * @notice Function to check if a display is occupied
    *
    * @dev The display should be initialized
    * display not occupied if endTime of display is lesser tahn current block's timestamp 
    *
    * @param _displayId display id
    * @return bool returns true if occupied and false if not
    */
    function isOccupied(uint256 _displayId) public view virtual returns(bool){
        require(display[_displayId].displayOwner != address(0),"Display non-existant.");
        if(display[_displayId].endTime < block.timestamp){
            return false;
        }else{
            return true;
        }
    }

    /*
    * @notice Function to set minimum rent
    * Only contract owner can call
    *
    * @param _minRent minimum rent cost
    */
    function setMinimumRent(uint256 _minRent) public onlyOwner{
        minimumRent = _minRent;
    }

}