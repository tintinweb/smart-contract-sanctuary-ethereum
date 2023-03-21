// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ShoeStore {
    struct Shoe {
        uint id;
        string name;
        string brand;
        uint size;
        address owner;
        uint price;
        string image;
        bool isListed;
    }
    Shoe[] public shoes;
    address public owner;
    uint128 public commissionRate;
    uint32 public listedShoesCount = 0;

    event ShoeCreated(
        uint id,
        string name,
        string brand,
        uint size,
        address owner,
        uint price,
        string _image
    );
    event ShoeListed(
        uint indexed shoeIndex,
        string name,
        string brand,
        uint size,
        address owner,
        uint price,
        string image
    );
    event ShoeDelisted(uint indexed shoeIndex);
    event ShoeBought(
        uint indexed shoeIndex,
        address indexed buyer,
        address indexed seller,
        uint price
    );

    constructor() {
        owner = msg.sender;
        commissionRate = 1;
    }

    function createShoe(
        string memory _name,
        string memory _brand,
        uint256 _size,
        uint256 _price,
        string memory _image
    ) public {
        require(_price > 0, "Price must be greater than 0");
        uint id = shoes.length;
        shoes.push(
            Shoe(id, _name, _brand, _size, msg.sender, _price, _image, false)
        );
        emit ShoeCreated(id, _name, _brand, _size, msg.sender, _price, _image);
    }

    function listShoe(uint256 _shoeId) public {
        require(_shoeId >= 0 && _shoeId < shoes.length, "Invalid shoe ID");
        require(shoes[_shoeId].owner == msg.sender, "You do not own this shoe");
        require(!shoes[_shoeId].isListed, "Shoe is already listed");
        shoes[_shoeId].isListed = true;
        listedShoesCount++;
        emit ShoeListed(
            _shoeId,
            shoes[_shoeId].name,
            shoes[_shoeId].brand,
            shoes[_shoeId].size,
            msg.sender,
            shoes[_shoeId].price,
            shoes[_shoeId].image
        );
    }

    function delistShoe(uint256 _shoeId) public {
        require(_shoeId >= 0 && _shoeId < shoes.length, "Invalid shoe ID");
        require(shoes[_shoeId].owner == msg.sender, "You do not own this shoe");
        require(shoes[_shoeId].isListed, "Shoe is not listed");
        shoes[_shoeId].isListed = false;
        listedShoesCount--;
        emit ShoeDelisted(_shoeId);
    }

    function buyShoe(uint256 _shoeId) public payable {
        require(shoes[_shoeId].isListed == true, "This shoe is not for sale");
        require(msg.value >= shoes[_shoeId].price, "Insufficient funds");
        address payable seller = payable(shoes[_shoeId].owner);
        seller.transfer((shoes[_shoeId].price * (100 - commissionRate)) / 100);
        shoes[_shoeId].owner = msg.sender;
        shoes[_shoeId].isListed = false;
        listedShoesCount--;
        emit ShoeBought(_shoeId, msg.sender, seller, shoes[_shoeId].price);
    }

    function getAllUserShoes(
        address _owner
    ) public view returns (Shoe[] memory) {
        Shoe[] memory shoesMem = shoes;
        uint32 count = 0;
        for (uint i = 0; i < shoes.length; i++) {
            if (shoes[i].owner == _owner) {
                count++;
            }
        }
        Shoe[] memory userShoes = new Shoe[](count);
        uint index = 0;
        for (uint i = 0; i < shoes.length; i++) {
            if (shoesMem[i].owner == _owner) {
                userShoes[index] = shoesMem[i];
                index++;
            }
        }
        return userShoes;
    }

    function changeShoePrice(uint _shoeId, uint _price) public {
        require(_shoeId >= 0 && _shoeId < shoes.length, "Invalid shoe ID");
        require(shoes[_shoeId].owner == msg.sender, "You do not own this shoe");
        shoes[_shoeId].price = _price;
    }

    function withdraw() external {
        require(msg.sender == owner);
        payable(address(owner)).transfer(address(this).balance);
    }

    function getAllListedShoes() public view returns (Shoe[] memory) {
        Shoe[] memory result = new Shoe[](listedShoesCount);
        uint256 idx = 0;
        for (uint256 i = 0; i < shoes.length; i++) {
            if (shoes[i].isListed == true) {
                result[idx] = shoes[i];
                idx++;
            }
        }
        return result;
    }

    receive() external payable {}

    fallback() external payable {}
}