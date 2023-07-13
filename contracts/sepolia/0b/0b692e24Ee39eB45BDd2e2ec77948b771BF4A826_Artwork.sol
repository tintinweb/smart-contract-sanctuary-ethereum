// SPDX-License-Identifier: UNLICENSED

contract Artwork{

    struct Art{
        address owner;
        string image; //path
        string description;
        uint256 price;
        string credentials;
        uint256 quantity;
        bool delivery_state;
    }

    uint256 art_count;

    mapping(uint256 => Art) public artworks;

    function createArt(address _owner, string memory _image_path, string memory _description, uint256 _price, string memory _credentials, uint256 _quantity) public {
        Art storage art = artworks[art_count];
        art.owner = _owner;
        art.image = _image_path;
        art.description = _description;
        art.price = _price;
        art.credentials = _credentials;
        art.quantity = _quantity;
        art.delivery_state = false;
        art_count++;
    }

    function updateQuantity(uint256 art_id, uint256 _new_quantity) public returns (uint256){
        Art storage art = artworks[art_id];
        art.quantity = _new_quantity;
        return art.quantity;
    }

    function startDelivery(uint256 art_id) public returns (bool){
        Art storage art = artworks[art_id];
        art.delivery_state = true;
        return art.delivery_state;
    }

    function getDeliveryStatus(uint256 art_id) public view returns (bool){
        Art storage art = artworks[art_id];
        return art.delivery_state;
    }

    function getArtQuantity(uint256 art_id) public view returns (uint256){
        Art storage art = artworks[art_id];
        return art.quantity;
    }

    function cancelDelivery(uint256 art_id) public returns (bool){
        Art storage art = artworks[art_id];
        art.delivery_state = false;
        return art.delivery_state;
    }

}