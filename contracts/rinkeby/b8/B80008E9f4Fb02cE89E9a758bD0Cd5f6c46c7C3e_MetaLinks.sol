// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;



import "@openzeppelin/contracts/access/Ownable.sol";



/// @title MetaLinks
/// @author efenstakes
/// @notice Manages MetaLinks avatars & their links
/// @dev this contract has logic to store and retrieve metalink avatars and their links
contract MetaLinks is Ownable {

    // total number of avatars so far
    uint256 public totalAvatars;

    // total number of links so far
    uint256 public totalMetaLinks;

    // total addresses that have been added
    uint256 public totalAddresses;

    // map a metalink id to their addresses
    mapping( address => uint256 ) public addressesToMID;

    // map an id to avatar data
    mapping( uint256 => Avatar ) public midsToAvatars;
    
    // map an metalink id to links
    mapping( uint256 => MetaLink ) public midsToMetaLinks;


    // structs
    
    /// @notice Avatar struct
    /// @dev Avatar struct
    struct Avatar {
        string name;
        string aka;
        string bio;
        string avatar;
        string bg_avatar;
        uint256[] links;
    }

    
    /// @notice MetaLink struct
    /// @dev MetaLink struct
    struct MetaLink {
        string name;
        string aka;
        string universe;
        string link;
        string bio;
        string avatar;
        string bg_avatar;
        bool active;
    }

    

    // events

    /// @notice Event emitted when avatar is created
    /// @dev Event emitted when avatar is created
    /// @param avatarID the avatar id 
    /// @param name the avatar name 
    /// @param aka the avatar aka 
    /// @param bio the avatar bio 
    /// @param avatar the avatar avatar link
    /// @param bgAvatar the big image avatar link 
    event AvatarCreated(
        uint256 indexed avatarID,
        string name,
        string aka,
        string bio,
        string avatar,
        string bgAvatar
    );

    /// @notice Event emitted when avatar adds an address to their avatar
    /// @dev Event emitted when avatar adds an address to their avatar
    /// @param avatarID the avatar id 
    /// @param newAddresses the added addresses
    event AvatarAddressesAdded(
        uint256 indexed avatarID,
        address[] newAddresses
    );


    /// @notice Event emitted when an avatar adds a MetaLink
    /// @dev Event emitted when an avatar adds a MetaLink
    /// @param avatarID the avatar id 
    /// @param newMetaLinkID the MetaLink id 
    /// @param name the MetaLink name 
    /// @param aka the MetaLink aka 
    /// @param bio the MetaLink bio 
    /// @param avatar the MetaLink avatar link
    /// @param bgAvatar the big image MetaLink link 
    event MetaLinkAdded(
        uint256 indexed avatarID,
        uint256 indexed newMetaLinkID,
        string name,
        string aka,
        string bio,
        string universe,
        string link,
        string avatar,
        string bgAvatar,
        bool active
    );



    // constructor
    constructor() { }


    // modifiers

    /// @notice Ensure address has an avatar
    /// @dev Ensure address has an avatar
    modifier isMember() {
        require( addressesToMID[msg.sender] > 0 && addressesToMID[msg.sender] <= totalAvatars, "You have to be a member" );
        _;
    }

    /// @notice Ensure address has no avatar
    /// @dev Ensure address has no avatar
    modifier isNotMember() {
        require( addressesToMID[msg.sender] == 0, "You are already a member" );
        _;
    }



    /// @notice Create an avatar
    /// @dev Create an avatar
    /// @param _name the avatar name 
    /// @param _aka the avatar aka 
    /// @param _bio the avatar bio 
    /// @param _avatar the avatar avatar link
    /// @param _bg_avatar the big image avatar link 
    // generate new avatar id
    // associate address with generated avatar id
    // create avatar
    // add avatar to midsToAvatars
    // increase number of avatars by 1
    // emit event
    // return bool
    function createAvatar( string memory _name, string memory _aka, string memory _bio, string memory _avatar, string memory _bg_avatar ) external isNotMember returns (uint256) {
        // generate new avatar id
        uint256 id = totalAvatars + 1;

        // associate address with generated avatar id
        addressesToMID[msg.sender] = id;

        // create avatar
        Avatar memory newAvatar = Avatar({
            name: _name,
            aka: _aka,
            bio: _bio,
            avatar: _avatar,
            bg_avatar: _bg_avatar,
            links: new uint256[](0)
        });
        
        // add avatar to midsToAvatars
        midsToAvatars[id] = newAvatar;

        // increase number of avatars by 1
        totalAvatars++;

        // emit event
        emit AvatarCreated( id, _name, _aka, _bio, _avatar, _bg_avatar );

        return id;
    }


    /// @notice Add an avatars address
    /// @dev Add an avatars address. It skips any addresses that have already been added
    /// @param _addresses the new avatar _addresses
    // get address avatar id
    // for each address, add it to addressesToMID
    // emit event
    // return bool
    function addAvatarAddress(address[] memory _addresses) public isMember returns(bool) {
        // get address avatar id
        uint256 avatarID = addressesToMID[msg.sender];

        // ensure id is valid
        require( avatarID > 0 && avatarID <= totalAvatars, "Not a valid Avatar ID" );

        // keep a list of added addresses
        address[] memory _addedAddresses = new address[](_addresses.length);

        // for each address, add it to addressesToMID
        for( uint32 counter = 0; counter < _addresses.length; counter++ ) {
            bool alreadyExists = addressesToMID[_addresses[counter]] > 0;

            // if address is not added, add it
            if( !alreadyExists ) {
                addressesToMID[_addresses[counter]] = avatarID;
                _addedAddresses[ _addedAddresses.length ] = _addresses[counter];
                totalAddresses++;
            }
        }

        // emit event
        if( _addedAddresses.length > 0 ) {
            emit AvatarAddressesAdded( avatarID, _addedAddresses );
        }

        return true;
    }


    /// @notice Add an avatars MetaLink
    /// @dev Add an avatars MetaLink
    /// @param _name the metalink name 
    /// @param _aka the metalink aka 
    /// @param _bio the metalink bio 
    /// @param _universe the metalink universe 
    /// @param _avatar the metalink avatar link
    /// @param _bg_avatar the metalink big image avatar link 
    /// @param _link the metalink link
    /// @param _active the determinant for whether metalink is active or not
    // create link
    // generate a link id from totalMetaLinks
    // use the id to save link to midToMetaLinks mapping
    // add link to users avatar links array
    // increase total metalinks with 1
    // emit event
    // return bool
    function addAvatarMetalink( string memory _name, string memory _aka, string memory _bio, string memory _universe, string memory _avatar, string memory _bg_avatar, string memory _link, bool _active ) external isMember returns (bool) {
        // get the avatar id
        uint256 avatarID = addressesToMID[msg.sender];

        // get the avatar
        Avatar storage myAvatar = midsToAvatars[avatarID];

        // generate a link id from totalMetaLinks
        uint256 newMetaLinkID = totalMetaLinks + 1;

        // create link
        MetaLink memory newLink = MetaLink({
            name: _name,
            aka: _aka,
            bio: _bio,
            universe: _universe,
            link: _link,
            avatar: _avatar,
            bg_avatar: _bg_avatar,
            active: _active
        });

        // use the id to save link to midToMetaLinks mapping
        midsToMetaLinks[newMetaLinkID] = newLink;

        // add link to users avatar links array
        myAvatar.links.push(newMetaLinkID);

        // increase total metalinks with 1
        totalMetaLinks++;

        // emit event
        // resulted to using newLink.**PROPOERTY_NAME** because of a stack too deep error
        emit MetaLinkAdded(
            avatarID,
            newMetaLinkID,
            _name,
            _aka,
            _bio,
            _universe,
            _link,
            newLink.avatar,
            newLink.bg_avatar,
            newLink.active
        );

        return true;
    }



    /// @notice Check if given address is used
    /// @dev Check if given address is used
    /// @param _address the address
    function isAddressUsed(address _address) public view returns(bool) {
        return addressesToMID[_address] > 0;
    }


    /// @notice Get my id given address
    /// @dev Get my id given address
    function getMyAvatarID() public view returns(uint256) {
        return addressesToMID[msg.sender];
    }


    /// @notice Get avatar id given address
    /// @dev Get avatar id given address
    /// @param _address the avatar address
    function getAvatarID(address _address) public view returns(uint256) {
        return addressesToMID[_address];
    }

    
    /// @notice Get avatar given address
    /// @dev Get avatar given address
    /// @param _address the avatar address
    function getAvatarByAddress(address _address) public view returns(string memory, string memory, string memory, string memory, string memory, uint[] memory links) {
        uint256 id = addressesToMID[_address];
        
        // ensure the avatar exists
        require( id > 0 && id <= totalAvatars , "Avatar does not exist" );

        Avatar memory avatar = midsToAvatars[id];

        return ( avatar.name, avatar.aka, avatar.bio, avatar.avatar, avatar.bg_avatar, avatar.links );
    }
    
    
    /// @notice Get avatar given its id
    /// @dev Get avatar given its id
    /// @param _id the avatar id
    function getAvatarById(uint256 _id) public view returns(string memory, string memory, string memory, string memory, string memory, uint[] memory links) {      
        // ensure the avatar exists
        require( _id > 0 && _id <= totalAvatars , "Avatar does not exist" );

        Avatar memory avatar = midsToAvatars[_id];

        return ( avatar.name, avatar.aka, avatar.bio, avatar.avatar, avatar.bg_avatar, avatar.links );
    }


    /// @notice Get avatar metalink id list
    /// @dev Get avatar metalink id list
    /// @param _id the avatar id
    function getAvatarMetaLinkIDs(uint256 _id) public view returns(uint256[] memory links) {        
        Avatar memory avatar = midsToAvatars[_id];

        return avatar.links;
    }


    /// @notice Get metalink data
    /// @dev Get metalink data
    /// @param _id the metalink id
    function getMetaLink(uint256 _id) public view returns(string memory, string memory, string memory, string memory, string memory, string memory) {
        // ensure the metalink exists
        require( _id > 0 && _id <= totalMetaLinks , "MetaLink does not exist" );

        MetaLink memory metaLink = midsToMetaLinks[_id];

        return ( metaLink.name, metaLink.aka, metaLink.bio, metaLink.avatar, metaLink.bg_avatar, metaLink.link );
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