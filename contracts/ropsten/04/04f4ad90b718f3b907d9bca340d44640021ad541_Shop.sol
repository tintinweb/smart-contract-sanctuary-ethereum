/**
 *Submitted for verification at Etherscan.io on 2022-04-09
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Shop {
    address private owner;
    struct picture {
        address address_wallet;
        string picName;
        string name;
        uint256 price;
        string deliverAddress;
        string tel;
        string path;
        uint256 status;
        string trackingNumber;
    }
    uint256 countID;
    string[] pathName;
    uint256[] picID;

    mapping(uint256 => picture) public pictures;

    event OwnerSet(address indexed oldOwner, address indexed newOwner);

    constructor() {
        countID = 1;
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    function createSellPic(
        uint256 price,
        string memory path,
        string memory picName
    ) public {
        pictures[countID].address_wallet = owner;
        pictures[countID].picName = picName;
        pictures[countID].name = "Piya";
        pictures[countID].price = price;
        pictures[countID].deliverAddress = "at Me";
        pictures[countID].tel = "02777777";
        pictures[countID].path = path;
        pictures[countID].status = 1;

        delete pathName;
        delete picID;
        for (uint256 i = 1; i <= countID; i++) {
            if (pictures[i].status == 1) {
                pathName.push(pictures[i].picName);
                picID.push(i);
            }
        }

        // keccak256(abi.encodePacked(pictures[i].status)) != keccak256(abi.encodePacked("Send"))
        // pictures[countID] = picture(owner,picName,"Me",price,"at Me","027777",path,"Sell");
        // return (owner,price,path); view returns (address,uint,string memory)
        countID++;
    }

    function getPic() public view returns (string[] memory, uint256[] memory) {
        return (pathName, picID);
    }

    function sendPicture(uint256 id, string memory tracking) public {
        pictures[id].status = 3;
        pictures[id].trackingNumber = tracking;

        delete pathName;
        delete picID;
        for (uint256 i = 1; i <= countID; i++) {
            if (pictures[i].status == 1) {
                pathName.push(pictures[i].picName);
                picID.push(i);
            }
        }
    }

    // modifier costs(uint _amount) {
    //       require(
    //          msg.value >= _amount,
    //          "Not enough Ether provided."
    //       );
    //       _;
    //       if (msg.value > _amount)
    //          msg.sender.transfer(msg.value - _amount);
    //    }
    //    //msg ส่งมาตอนมีคนเรียก

    //  function forceOwnerChange(address _newOwner) public payable costs(200 ether) {
    //       owner = _newOwner;
    //       if (uint(owner) & 0 == 1) return;
    //    }

    function buyPicture(
        uint256 id,
        string memory name,
        string memory deliverAddress,
        string memory tel
    ) public payable {
        require(msg.value == pictures[id].price, "Not enough price");

        address payable oldOwner = payable(pictures[id].address_wallet);

        bool sent = oldOwner.send(msg.value);
        require(sent, "can not buy");

        pictures[id].address_wallet = msg.sender;
        pictures[id].name = name;
        pictures[id].deliverAddress = deliverAddress;
        pictures[id].tel = tel;
        pictures[id].status = 2;
    }
}