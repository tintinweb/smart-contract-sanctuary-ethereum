/**
 *Submitted for verification at Etherscan.io on 2022-03-12
*/

pragma solidity ^0.4.26;

    contract MusicSellingPlatform {
 
        struct Music {
            address owner;
            uint price;
        }

        address public manager;
        mapping (string => Music) music;
        string[] musicID;
        event CreateMusic(address creator, string id, uint price);
        event BuyMusic(address buyer, string id, uint price);

        constructor() public {
            manager = msg.sender;
        }
        
        modifier restricted() {
            require(msg.sender == manager);
            _;
        }
        
        function checkManager() public view returns (bool) {
            return msg.sender == manager;
        }
        
        function getMusicOwner(string id) public view returns (address) {
            return music[id].owner;
        }

        function sellMusic(string id) public payable {
            require(music[id].owner == manager);
            require(msg.value >= music[id].price);
            music[id].owner = msg.sender;
            emit BuyMusic(msg.sender, id, music[id].price);
        }

        function createMusic(string id, uint _price) public restricted returns (bool) {
            require(!musicExist(id));
            music[id].owner = manager;
            music[id].price = _price;
            musicID.push(id);
            emit CreateMusic(msg.sender, id, _price);
            return true;
        }

        function transferEther() public restricted {
            manager.transfer(address(this).balance);
        }

        function musicExist(string id) public restricted view returns (bool) {
            for (uint i = 0; i < musicID.length; i++) {
                if (keccak256(abi.encodePacked(musicID[i])) == keccak256(abi.encodePacked(id))) {
                    return true;
                }
            }
            return false;
        }

        function musicSold(string id) public view returns (bool) {
            if (music[id].owner == manager) 
                return false;
            else
                return true;
        }

        function getBalance() public restricted view returns (uint) {
            return address(this).balance;
        }

        function getManager() public view returns (address) {
            return manager;
        }

    }