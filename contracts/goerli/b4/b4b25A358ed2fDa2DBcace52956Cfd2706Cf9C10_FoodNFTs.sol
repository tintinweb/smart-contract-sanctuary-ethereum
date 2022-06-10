pragma solidity ^0.8.4;

contract FoodNFTs {

    uint256 private artworkCount = 0;
    uint256 private auctionsCount = 0;
    uint256 private providersCount = 0;

    struct Artwork {
        uint256 id;
        uint256 providerID;
        string title;
        string image;
        string description;
        string uri;
        uint256 amount;
        uint256 mintedCount;
        uint256 price;
    }

    struct Provider {
        uint256 id; 
        string name;
        string description;
        string logo;
        address payable addr;
        uint split;
        bool isEnabled;
    }

    address owner;

    Provider[] private allProviders;
    Artwork[] private allArtworks;

    mapping(address => Provider) private providerFor;
    mapping(uint256 => Provider) private providerForID;

    mapping(uint256 => Artwork) private artworkForID;
    mapping(address => Artwork[]) private artworksFor;

    constructor() { 
        owner = msg.sender;
    }

    // Helper functions
    function isStringEmpty(string memory _test) pure private returns(bool) {
        bytes memory checkString = bytes(_test);
        if (checkString.length > 0) {
            return false;
        } else {
            return true;
        }
    }

    function getRole(address _addr) public view returns (string memory) {
        if (owner == _addr) {
            return "owner";
        } else if (providerFor[_addr].id != 0) {
            return "provider";
        } else {
            return "user";
        }
    }

    // Platform Functions

    function addProvider(string calldata _name, string calldata _description, string calldata _logo, address payable _providerAddress, uint _split, bool _isEnabled) public {
        require(msg.sender == owner, "Only the owner can add providers");
        require(!isStringEmpty(_name), "The name can't be empty");
        require(!isStringEmpty(_description), "The description can't be empty");
        require(!isStringEmpty(_logo), "The logo url can't be empty");
        require(_providerAddress != owner, "The owner can't be a provider");
        require(providerFor[_providerAddress].id == 0, "A provider with that address already exists");
        require(_split <= 100, "The split must be less than or equal to 100");
        require(_split >= 0, "The split must be greater than or equal to 0");

        uint256 providerID = ++providersCount;

        Provider memory p = Provider({ id: providerID, name: _name, description: _description, logo: _logo, addr: _providerAddress, split: _split, isEnabled: _isEnabled });
        providerFor[_providerAddress] = p;
        providerForID[providerID] = p;

        allProviders.push(p);
    } 

    function getProviderByAddress(address _owner) public view returns (Provider memory) {
        Provider memory p = providerFor[_owner];
        return(p);
    }

    function getProviderByID(uint256 _id) public view returns (Provider memory) {
        require(_id <= providersCount, "The provider doesn't exists");
        Provider memory p = providerForID[_id];
        return(p);
    }

    function getAllProviders() public view returns (Provider[] memory) {
        return allProviders;
    }

    function getAllArtworks() public view returns (Artwork[] memory) {
        return allArtworks;
    }

    function addArtwork(string calldata _title, string calldata _image, string calldata _description, uint256 _amount, uint256 _price, string calldata _uri) public {
        Provider memory provider = providerFor[msg.sender];
        require(provider.id > 0, "You don't have a profile stored in the contract");
        require(!isStringEmpty(_title), "You must provide a title");
        require(_amount > 0, "The amount for the new artwork should be greater than 0");
        require(_price > 2600, "The price must be greater than 2600 wei");
        require(!isStringEmpty(_uri), "The artwork uri should not be empty");

        uint256 artworkId = ++artworkCount;

        Artwork memory a = Artwork({
            id: artworkId, 
            providerID: provider.id,
            title: _title, 
            image: _image, 
            description: _description, 
            amount: _amount, 
            mintedCount: 0, 
            price: _price, 
            uri: _uri});

        artworksFor[msg.sender].push(a);
        artworkForID[artworkId] = a;
        allArtworks.push(a);
    }

    function getAllArtworks(address _owner) public view returns (Artwork[] memory) {
        return artworksFor[_owner];
    } 

    function buyArtwork(uint256 _artworkID) public payable {
        Artwork memory artwork = artworkForID[_artworkID];
        uint256 amount = msg.value;
        
        require(artwork.id > 0, "The artwork doesn't exist");
        require(artwork.price > 0, "The artwork price is 0");
        require(amount >= artwork.price, "The amount provided is less than the lising price");
        require(artwork.mintedCount < artwork.amount, "The artwork reached the mint limit");

        artworkForID[_artworkID].mintedCount += 1;
        allArtworks[_artworkID - 1].mintedCount += 1;

        Provider memory provider = providerForID[artwork.providerID];
        provider.addr.transfer(msg.value * provider.split / 100);
    }
}