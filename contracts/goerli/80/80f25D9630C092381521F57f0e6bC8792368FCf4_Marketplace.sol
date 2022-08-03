// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Marketplace is Ownable {
	/** @dev Struct that stores Art data 
	* @param id Art id 
	* @param name Art name 
	* @param description Art Description 
	* @param uri URI for the NFT
    * @param uri The initial price of the NFT
    * @param totalSupply Total amount of nft that can be minted using this art 
	* @param mintedCount Count for the nft minted using this art
	*/    
    struct Art {
        bytes32 id;
        bytes32 providerID;
        string name;
        string description;
        string uri;
        uint256 price;
        uint256 totalSupply;
        uint256 mintedCount;
    }

	/** @dev Struct that stores Provider data 
	* @param id Provider id 
	* @param name Provider name 
	* @param description Provider Description 
	* @param logo The provider's logo
    * @param addr The address for the provider
    * @param commission The commission for each sale
	*/    
    struct Provider {
        bytes32 id;
        string name;
        string description;
        string logo;
        address payable addr;
        uint commission;
        string banner;
    }

    //Events emited by the contract
    event ProviderCreated(bytes32 id, string name, string description, string picture, address addr, uint commission, string banner);
    event ProviderEdited(bytes32 id, string name, string description, string picture, address addr, uint commission, string banner);
    event ArtCreated(bytes32 id, bytes32 providerID, string name, string description, string uri, uint256 price, uint256 totalSupply);
    event ArtMinted(bytes32 id, bytes32 providerID, string name, string description, string uri, uint256 price, uint256 totalSupply, address owner);

    //List of all providers
    bytes32[] providers;   

    //Mapping between the address and the provider
    mapping (address => bytes32) providerByOwner;

    //Mapping between the id and the provider
    mapping (bytes32 => Provider) providerByID;

    //Mapping between the address of the owner and his arts
    mapping (bytes32 => bytes32[]) artsByProvider;

    //Mapping between the art id and the art
    mapping (bytes32 => Art) artByID;

    //////////////////////////  
    //  CONTRACT FUNCTIONS  //
    //////////////////////////  

    /** @dev Adds a new provider
    * @param name Provider name 
	* @param description Provider Description 
	* @param logo The provider's logo
    * @param addr The address for the provider
    * @param commission The marketplace commission for each sale
	*/
    function addProvider(string memory name, string memory description, string memory logo, address addr, uint commission, string memory banner) public onlyOwner {
        require(bytes(name).length > 0, "The name can't be empty");
        require(bytes(description).length > 0, "The description can't be empty");
        require(bytes(logo).length > 0, "The logo can't be empty");
        require(addr != owner(), "The owner can't be a provider");
        require(providerByOwner[addr] == 0, "The address is already a provider");
        require(commission >= 0 && commission <= 100, "The commission should be between 0 and 100");

        bytes32 id = keccak256(abi.encodePacked(msg.sender, name, block.timestamp));
        Provider memory p = Provider(id, name, description, logo, payable(addr), commission, banner);

        providers.push(id);
        providerByOwner[addr] = id;
        providerByID[id] = p;

        emit ProviderCreated(p.id, p.name, p.description, p.logo, p.addr, p.commission, banner);
    }

    function editProvider(bytes32 id, string memory name, string memory description, string memory logo, address addr, uint commission, string memory banner) public { 
        address owner = owner();
        Provider memory p = providerByID[id];

        require(p.id != 0, "The provider doesn't exist");

        if(msg.sender != owner) {
            require(p.addr == msg.sender, "Only the owner or the provider itself can edit this profile");
        }

        require(bytes(name).length > 0, "The name can't be empty");
        require(bytes(description).length > 0, "The description can't be empty");
        require(bytes(logo).length > 0, "The logo can't be empty");
        require(addr != owner, "The owner can't be a provider");
        require(providerByOwner[addr] == 0, "The address is already a provider");
        require(commission >= 0 && commission <= 100, "The commission should be between 0 and 100");

        p.name = name;
        p.description = description;
        p.logo = logo;
        p.addr = payable(addr);
        p.banner = banner;

        if(msg.sender == owner) {
            p.commission = commission;
        }

        providerByID[id] = p;

        emit ProviderEdited(p.id, p.name, p.description, p.logo, p.addr, p.commission, banner);
    }

    /** @dev Returns all the providers ids */
    function getProviders() view public returns(bytes32[] memory) {
        return providers;
    }

    /** @dev Returns the provider for the given id
    @param id The provider id
    */
    function getProviderByID(bytes32 id) view public returns(Provider memory) {
        return providerByID[id];
    }

    /** @dev Returns the provider for the given address
    @param addr The provider address
    */
    function getProviderByAddress(address addr) view public returns(bytes32) {
        bytes32 id = providerByOwner[addr];
        return id;
    }

    function addArtwork(string memory name, string memory description, string memory uri, uint256 price, uint256 totalSupply) public {
        require(bytes(name).length > 0, "The name can't be empty");
        require(bytes(description).length > 0, "The description can't be empty");
        require(bytes(uri).length > 0, "The uri can't be empty");
        require(price > 0, "The price should be greater than 0");
        require(totalSupply > 0, "The total supply should be greater than 0");

        bytes32 providerID = getProviderByAddress(msg.sender);
        require(providerID != 0, "The provider doesn't exist");

        bytes32 id = keccak256(abi.encodePacked(msg.sender, name, block.timestamp));
        Art memory art = Art(id, providerID, name, description, uri, price, totalSupply, 0);

        artsByProvider[providerID].push(id);
        artByID[id] = art;

        emit ArtCreated(art.id, art.providerID, art.name, art.description, art.uri, art.totalSupply, art.price);
    }

    function getArtworkForID(bytes32 id) view public returns(Art memory) {
        return artByID[id];
    }

    function getArtworksForProvider(bytes32 pID) view public returns(bytes32[] memory) {
        return artsByProvider[pID];
    }

    function buyArtwork(bytes32 aID) public payable {
        Art memory a = getArtworkForID(aID);
        require(a.id != 0, "The artwork doesn't exist");

        uint256 paidValue = msg.value;
        require(paidValue == a.price, "The price doesn't match");

        artByID[aID].mintedCount += 1;

        Provider memory p = providerByID[a.providerID];
        address payable providerAddress = p.addr;
        uint256 marketCommission = msg.value * p.commission / 100;
        providerAddress.transfer(msg.value - marketCommission);

        //Mint the art

        emit ArtMinted(a.id, a.providerID, a.name, a.description, a.uri, a.totalSupply, a.price, msg.sender);
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