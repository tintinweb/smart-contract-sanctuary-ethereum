/**
 *Submitted for verification at Etherscan.io on 2022-02-14
*/

pragma solidity ^0.8.11;

contract Bluetooth{

    event NewBluetooth(uint tokenId, string name, string mac);
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);

    struct Bluetooth{
        string name;
        string mac;
    }

    Bluetooth[] public bluetoothes;

    mapping (uint => address) bluetoothOwner;//tokenid => public address
    mapping (address => uint) ownerTokenId;//owner address => tokenId
    mapping (address => uint) ownerCount;//public address => count
    mapping (string => bool) checkMac;//mac address => tokenid
    mapping (string => bool) checkTransfer;//check transfer record
    mapping (address => string) private addresstoMac;
    mapping (address => string) private addresstoName;

    function createBluetooth(string memory _name, string memory _mac) public {
        require(checkMac[_mac] == false);//return null
        //not transfer history
        if(checkTransfer[_mac] == false){
            bluetoothes.push(Bluetooth(_name, _mac));
            uint tokenId = bluetoothes.length;
            bluetoothOwner[tokenId] = msg.sender;
            ownerTokenId[msg.sender] = tokenId;
            checkMac[_mac] = true;
            checkTransfer[_mac] == false;
            ownerCount[msg.sender]++;
            addresstoMac[msg.sender] = _mac;
            addresstoName[msg.sender] = _name;

            emit NewBluetooth(tokenId, _name, _mac);
        //having transfer history
        } else if(checkTransfer[_mac] == true){
            uint tokenId = ownerTokenId[msg.sender];
            checkTransfer[_mac] == false;
            emit NewBluetooth(tokenId, _name, _mac);
        }
    }

    //ERC721 interface
    function balanceOf(address _owner) public view returns (uint256 _balance) {
        return ownerCount[_owner];
    }

    function ownerOf(uint256 _tokenId) public view returns (address _owner) {
        return bluetoothOwner[_tokenId];
    }

    function addtoMac() public view returns (string memory _mac, string memory _name) {
        return (addresstoMac[msg.sender], addresstoName[msg.sender]);
    }
    
    function _transfer(address _from, address _to, uint tokenId, string memory _mac, string memory _name) private {
        require(tokenId <= bluetoothes.length && tokenId > 0);
        ownerCount[_to]++;
        ownerCount[_from]--;
        bluetoothOwner[tokenId] = _to;
        ownerTokenId[_to] = tokenId;
        checkMac[_mac] == false;
        checkTransfer[_mac] == true;
        addresstoMac[_from] = "";
        addresstoMac[_to] = _mac;
        addresstoName[_from]= "";
        addresstoName[_to] = _name;
        emit Transfer(_from, _to, tokenId);
    }

    function transfer(address _to, uint256 _tokenId, string memory _mac, string memory _name) public {
        require(msg.sender == bluetoothOwner[_tokenId]);
        _transfer(msg.sender, _to, _tokenId, _mac, _name);
    }

}