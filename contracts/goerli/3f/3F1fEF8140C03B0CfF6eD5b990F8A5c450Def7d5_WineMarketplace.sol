// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract WineMarketplace{
    struct Lot {
        address seller;
        uint256 price;
        string name;    
        uint256 stock;
        string origin;
        uint256 date;
        string description;
        string image;
        uint256 sold;
        uint256[] amount;
        uint256[] cost;
        address[] acquirers;
        }

    mapping(uint256 => Lot) public lots;

    uint256 public numberOfLots = 0;

    // function createLot(address _seller, string memory _name, uint256 _date,  string memory _origin, uint256 _price, string memory _color, string memory _perlage,  string memory _limpidity, string memory _texture, string memory _description, uint256 _stock, string memory _certificateImage, string memory _image) public returns (uint256) {
    //     Lot storage lot = lots[numberOfLots];

    //     require(lot.stock < 0 , "The amount of available pieces is insufficient.");

    //     lot.seller = _seller;
    //     lot.name = _name;
    //     lot.date = _date;
    //     lot.origin = _origin;
    //     lot.price = _price;
    //     lot.color = _color;
    //     lot.perlage = _perlage;
    //     lot.limpidity = _limpidity;
    //     lot.texture = _texture;
    //     lot.description = _description;
    //     lot.stock = _stock;
    //     lot.sold = 0;
    //     lot.certificateImage = _certificateImage;
    //     lot.image = _image;
    //     numberOfLots++;

    //     return numberOfLots - 1;
    // }
     function createLot(address _seller,uint256 _price, string memory _name, uint256 _stock, string memory _origin, uint256 _date, string memory _description, string memory _image) public returns (uint256) {
        Lot storage lot = lots[numberOfLots];

       

        lot.seller = _seller;
        lot.price = _price;
        lot.name = _name;
        lot.stock = _stock;
        lot.origin = _origin;
        lot.date = _date;
        lot.description = _description;
        lot.image = _image;
        lot.sold = 0;
        numberOfLots++;
       // require(lot.stock < 0 , "The amount of available pieces is insufficient.");
        return numberOfLots - 1;
    }
  function buyLot(uint256 _id) public payable {
    
        Lot storage lot = lots[_id];
        uint256 amount = msg.value;
        uint256 cost = msg.value*lot.price;

        lot.acquirers.push(msg.sender);
        lot.amount.push(amount);
        lot.cost.push(cost);

        (bool sent,) = payable(lot.seller).call{value: cost}("");

        if(sent) {
            lot.sold = lot.sold + amount ;
        }
    }

    function getBuyers(uint256 _id) view public returns (address[] memory, uint256[] memory) {
        return (lots[_id].acquirers,  lots[_id].cost);
    }

    function getLots() public view returns (Lot[] memory) {
        Lot[] memory allLots = new Lot[](numberOfLots);

        for(uint i = 0; i < numberOfLots; i++) {
            Lot storage item = lots[i];
            allLots[i] = item;
        }

        return allLots;
    }
}