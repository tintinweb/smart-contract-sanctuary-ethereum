// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;



import "@openzeppelin/contracts/access/Ownable.sol";


contract MetaLinks is Ownable {

    // total number of avatars so far
    uint256 public totalAvatars;

    // total number of links so far
    uint256 public totalMetaLinks;

    // map a metalink id to their addresses
    mapping( address => uint256 ) public addressesToMID;

    // map an id to avatar data
    mapping( uint256 => Avatar ) public midsToAvatars;
    
    // map an metalink id to links
    mapping( uint256 => MetaLink ) public midsToMetaLinks;


    // structs
    
    // main avatar
    struct Avatar {
        string name;
        string aka;
        string bio;
        string avatar;
        uint256[] links;
    }

    // meta link struct
    struct MetaLink {
        string name;
        string aka;
        string universe;
        string link;
        string avatar;
        bool active;
    }

    

    // events

    // when avatar is created
    event AvatarCreated(
        uint256 indexed avatarID,
        string indexed name,
        string indexed aka,
        string bio,
        string avatar
    );
    
    // when an avatar adds an address to their avatar
    event AvatarAddressAdded(
        uint256 indexed id,
        address[] indexed newAddresses
    );

    // when link is added
    event MetaLinkAdded(
        uint256 indexed avatarID,
        uint256 indexed newMetaLinkID,
        string indexed name,
        string aka,
        string universe,
        string link,
        string avatar,
        bool active
    );



    // constructor
    constructor() {

    }


    // modifiers

    // ensure address has an avatar
    modifier isMember() {
        require( addressesToMID[msg.sender] > 0, "You have to be a member" );
        _;
    }

    // ensure address has no avatar
    modifier isNotMember() {
        require( addressesToMID[msg.sender] == 0, "You are already a member" );
        _;
    }



    // create an avatar
    // generate new avatar id
    // associate address with generated avatar id
    // create avatar
    // add avatar to midsToAvatars
    // increase number of avatars by 1
    // emit event
    // return bool
    function createAvatar( string memory name, string memory aka, string memory bio, string memory avatar ) external isNotMember returns (uint256) {
        // generate new avatar id
        uint256 id = totalAvatars + 1;

        // associate address with generated avatar id
        addressesToMID[msg.sender] = id;

        // create avatar
        Avatar memory newAvatar = Avatar({
            name: name,
            aka: aka,
            bio: bio,
            avatar: avatar,
            links: new uint256[](0)
        });
        
        // add avatar to midsToAvatars
        midsToAvatars[id] = newAvatar;

        // increase number of avatars by 1
        totalAvatars++;

        // emit event
        emit AvatarCreated( id, name, aka, bio, avatar );

        return id;
    }


    // add avatar address
    // get address avatar id
    // for each address, add it to addressesToMID
    // emit event
    // return bool
    function addAvatarAddress(address[] memory addresses) public isMember returns(bool) {
        // get address avatar id
        uint256 avatarID = addressesToMID[msg.sender];

        // for each address, add it to addressesToMID
        for( uint32 counter = 0; counter < addresses.length; counter++ ) {
            addressesToMID[addresses[counter]] = avatarID;
        }

        // emit event
        emit AvatarAddressAdded( avatarID, addresses );

        return true;
    }


    // add a link
    // create link
    // generate a link id from totalMetaLinks
    // use the id to save link to midToMetaLinks mapping
    // add link to users avatar links array
    // increase total metalinks with 1
    // emit event
    // return bool
    function addMetaLinkMetalink( string memory name, string memory aka, string memory universe, string memory avatar, string memory link, bool active ) external isMember returns (bool) {
        Avatar storage myAvatar = midsToAvatars[addressesToMID[msg.sender]];

        // generate a link id from totalMetaLinks
        uint256 newMetaLinkID = totalMetaLinks + 1;

        // create link
        MetaLink memory newLink = MetaLink({
            name: name,
            aka: aka,
            universe: universe,
            link: link,
            avatar: avatar,
            active: active
        });

        // use the id to save link to midToMetaLinks mapping
        midsToMetaLinks[newMetaLinkID] = newLink;

        // add link to users avatar links array
        myAvatar.links.push(newMetaLinkID);

        // increase total metalinks with 1
        totalMetaLinks++;

        // emit event
        emit MetaLinkAdded(
            newMetaLinkID,
            addressesToMID[msg.sender],
            name,
            aka,
            universe,
            link,
            avatar,
            active
        );

        return true;
    }



    // get my id given address
    function getMyAvatarID() public view returns(uint256) {
        return addressesToMID[msg.sender];
    }


    // get id given address
    function getAvatarID(address addrss) public view returns(uint256) {
        return addressesToMID[addrss];
    }

    
    // get an avatar given its id
    function getAvatar(uint256 id) public view returns(string memory, string memory, string memory, string memory, uint[] memory links) {
        Avatar memory avatar = midsToAvatars[id];

        return ( avatar.name, avatar.aka, avatar.bio, avatar.avatar, avatar.links );
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