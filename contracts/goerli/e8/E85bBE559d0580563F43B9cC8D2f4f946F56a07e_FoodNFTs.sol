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
        uint256 amount;
        uint256 mintedCount;
        uint256 price;
    }

    struct Provider {
        uint256 id; 
        string name;
        string logo;
        address addr;
        uint split;
    }

    address owner;

    Provider[] private allProviders;
    mapping(uint256 => Artwork) private allArtworks;
    mapping(address => Provider) private providerFor;
    mapping(address => Artwork[]) private artworksFor;

    constructor() { 
        owner = msg.sender;
    }

    function addProvider(string calldata _name, uint _split, string calldata _logo, address _owner) public {
        require(msg.sender == owner, "Only the owner can add providers");
        require(providerFor[_owner].id == 0, "A provider with that address already exists");
        require(_split < 100, "The split must be less than 100");

        Provider memory p = Provider({ id: ++providersCount, name: _name, logo: _logo, addr: _owner, split: _split });
        providerFor[_owner] = p;
        allProviders.push(p);
    } 

    function getProvider(address _owner) public view returns (Provider memory) {
        Provider memory p = providerFor[_owner];
        return(p);
    }

    function getAllProviders() public view returns (Provider[] memory) {
        return allProviders;
    }

    function getAllArtworks(address _owner) public view returns (Artwork[] memory) {
        return artworksFor[_owner];
    } 

    function addArtwork(string calldata _title, string calldata _image, string calldata _description, uint256 _amount, uint _price) public {
        Provider memory provider = providerFor[msg.sender];
        require(provider.id > 0, "You don't have a profile stored in the contract");
        
        uint256 artworkId = ++artworkCount;
        Artwork memory a = Artwork({id: artworkId, providerID: provider.id, title: _title, image: _image, description: _description, amount: _amount, mintedCount: 0, price: _price });
        artworksFor[msg.sender].push(a);
        allArtworks[artworkId] = a;
    }
}