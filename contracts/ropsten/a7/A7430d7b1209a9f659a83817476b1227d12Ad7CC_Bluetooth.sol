pragma solidity ^0.8.11;

import "./ERC721.sol";

contract Bluetooth is ERC721{

    event NewBluetooth(uint tokenId, string name, string mac);
    event Transfers(address from, address to, uint tokenId);
   
    struct Bluetooth{
        string name;
        string mac;
    }

    Bluetooth[] public bluetoothes;

    mapping (uint => address)  public bluetoothOwner;//tokenid => public address
    mapping (address => uint) ownerCount;//public address => count
    mapping (string => bool) checkMac;//mac address => tokenid

    function createBluetooth(string memory _name, string memory _mac) public {
        require(checkMac[_mac] == false);//return null

        bluetoothes.push(Bluetooth(_name, _mac ));
        uint tokenId = bluetoothes.length;
        bluetoothOwner[tokenId] = msg.sender;
        checkMac[_mac] = true;
        ownerCount[msg.sender]++;
        
       emit NewBluetooth(tokenId, _name, _mac );
    }

    //ERC721 overriding
    function balanceOf(address _owner) public view returns (uint256 _balance) {
        return ownerCount[_owner];
    }

    function ownerOf(uint256 _tokenId) public view returns (address _owner){
        return bluetoothOwner[_tokenId];
    }
    
    function _transfer(address _from,address _to, uint256 _tokenId) private {
        ownerCount[_to]++;
        ownerCount[_from]--;
        bluetoothOwner[_tokenId] = _to;
        emit Transfer(_from, _to, _tokenId);
    }
    
    function transfer(address _to, uint256 _tokenId) public {
        _transfer(msg.sender, _to, _tokenId);
    }

}