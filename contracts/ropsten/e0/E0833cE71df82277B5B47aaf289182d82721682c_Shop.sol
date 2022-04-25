/**
 *Submitted for verification at Etherscan.io on 2022-04-22
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Shop {
    address private owner;
    struct picture {
        address addressWallet;
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
    string[] pictureName;
    uint256[] picID;
    uint256[] prices;

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
        // ดักคนdeploy ถึงทำได้
        require(msg.sender == owner, "You are not admin");
        pictures[countID].addressWallet = owner;
        pictures[countID].picName = picName;
        pictures[countID].name = "Admin";
        pictures[countID].price = price;
        pictures[countID].deliverAddress = "office";
        pictures[countID].tel = "02777777";
        pictures[countID].path = path;
        pictures[countID].status = 1;

        delete pathName;
        delete picID;
        for (uint256 i = 1; i <= countID; i++) {
            if (pictures[i].status == 1) {
                pathName.push(pictures[i].path);
                picID.push(i);
                pictureName.push(pictures[i].picName);
                prices.push(pictures[i].price);
            }
        }

        countID++;
    }

    function getPic()
        public
        view
        returns (
            string[] memory,
            string[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        return (pathName, pictureName, picID, prices);
    }

    function sendPicture(uint256 id, string memory tracking) public {
        // ดักคนdeploy ถึงทำได้
        require(msg.sender == owner, "You are not admin");
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

    function buyPicture(
        uint256 id,
        string memory name,
        string memory deliverAddress,
        string memory tel
    ) public payable {
        require(msg.value == pictures[id].price, "Not enough price");

        address payable oldOwner = payable(pictures[id].addressWallet);

        bool sent = oldOwner.send(msg.value);
        require(sent, "can not buy");

        pictures[id].addressWallet = msg.sender;
        pictures[id].name = name;
        pictures[id].deliverAddress = deliverAddress;
        pictures[id].tel = tel;
        pictures[id].status = 2;
    }
}