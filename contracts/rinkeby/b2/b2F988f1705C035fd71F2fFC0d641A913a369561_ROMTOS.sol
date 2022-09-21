// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol";



//    ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⣫⣿⣿⣿⣿
//    ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢿⠛⣩⣾⣿⣿⣿⣿⣿
//    ⣿⣿⣿⣿⣿⣿⣿⣿⡛⠛⠛⠛⠛⠛⠛⢿⢻⣿⡿⠟⠋⣴⣾⣿⣿⣿⣿⣿⣿⣿
//    ⣿⣿⣿⣿⡿⢛⣋⠉⠁⠄⢀⠠⠄⠄⠄⠈⠄⠋⡂⠠⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
//    ⣿⣿⣿⣛⣛⣉⠄⢀⡤⠊⠁⠄⠄⠄⢀⠄⠄⠄⠄⠲⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿
//    ⣿⡿⠟⠋⠄⠄⡠⠊⠄⠄⠄⠄⠄⣀⣼⣤⣤⣤⣀⠄⠸⣿⣿⣿⣿⣿⣿⣿⣿⣿
//    ⣿⠛⣁⡀⠄⡠⠄⠄⠄⠄⠄⠄⢠⣿⣿⣿⣿⣿⣿⣷⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿
//    ⣿⠿⢟⡉⠰⠁⠄⠄⠄⠄⠄⠄⠄⠙⠿⠿⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
//    ⡇⠄⠄⠙⠃⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠈⠉⠉⠛⠛⠛⠻⢿⣿⣿⣿⣿
//    ⣇⠄⢰⣄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠉⠻⣿⣿
//    ⣿⠄⠈⠻⣦⣤⡀⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⣦⠙⣿
//    ⣿⣄⠄⠚⢿⣿⡟⠄⠄⠄⢀⡀⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⢀⣿⣧⠸
//    ⣿⣿⣆⠄⢸⡿⠄⠄⢀⣴⣿⣿⣿⣿⣷⣶⣶⣶⣶⠄⠄⠄⠄⠄⠄⢀⣾⣿⣿⠄
//    ⣿⣿⣿⣷⡞⠁⢀⣴⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⡀⠄⠄⣠⣾⣿⣿⣿⣿⢀
//    ⣿⣿⣿⡿⠁⢠⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠄⠄⠘⣿⣿⡿⠟⢃⣼
//    ⣿⣿⠏⠄⠠⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⠛⠉⢀⡠⢄⡠⡭⠄⣠⢠⣾⣿
//    ⠏⠄⠄⣸⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⠁⠄⢀⣦⣒⣁⣒⣩⣄⣃⢀⣮⣥⣼⣿
//    ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿



contract ROMTOS is ERC1155, Ownable {
    using Strings for uint256;

    uint256 public cost = 0.04 ether;
    string public baseURI;


    constructor(
        string memory initURI
    ) ERC1155("") {
        setURI(initURI);
    }

    function purchaseCity(uint256 tokenId) external payable {
        require( 1 <= tokenId && tokenId <= 5);
        require(msg.value >= cost, "Not enough ethers paid");
        _mint(msg.sender, tokenId, 1, "Invalid id");
    }

    function batchPurchase(uint256[] memory ids, uint256[] memory quantity) external onlyOwner {
        _mintBatch(msg.sender, ids, quantity, "");
    }

    function uri(uint256 tokenId) override public view returns (string memory) {
        return string(
            abi.encodePacked(baseURI, tokenId.toString(), ".json")
        );
    }

    function setURI(string memory _uri) public onlyOwner {
        baseURI = _uri;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function withdraw(address payable _to) external onlyOwner {
        _to.transfer(address(this).balance);
    }

    receive() external payable {

    }

}