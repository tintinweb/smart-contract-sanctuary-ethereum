/**
 *Submitted for verification at Etherscan.io on 2023-01-20
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface NFT {
    function safeMint(address to, string memory metadataURI) external ;

    function balanceOf (address owner) external returns (uint256) ;

    function transferOwnership(address _newOwner) external ;

    function ownerOf (uint256 id) external returns (address);
}

interface ERC20 {
    function transfer(address to, uint256 amount) external returns ( bool);
}

contract  FundRaise{
    NFT immutable nftAdd ;
    ERC20 immutable token;
    address public owner;
    uint256 internal counter;
    uint256 internal shares;
    mapping(address => uint256) DonorsAmount;
    mapping (uint256 => string) nameOfDonor;
    mapping (uint256 => bool) claimed;

    event Donated (address _donor , uint amount);
    event withDrawn(address withdrawer , uint amount); 

    constructor (address _nftAdd, address _token  ,address _owner){
        nftAdd = NFT(_nftAdd);
        owner = _owner;
        token = ERC20(_token);
        shares = 100e18;
    }

    function Donate (string memory metadataURI,string memory name) public payable {
        require(msg.value > 1e8,"Too Little please add more");
        DonorsAmount[msg.sender] += msg.value;
        if(nftAdd.balanceOf(msg.sender) <3){
         nftAdd.safeMint(msg.sender,metadataURI);
        }
        nameOfDonor[counter] = name;
        counter++;
       
        (bool sent, ) = address(this).call{value: msg.value}("");
        require (sent,"failed to send amount");
        emit Donated(msg.sender,msg.value);
    }

    


    function withDraw() onlyOwner public payable {
        (bool sent, ) = owner.call{value: address(this).balance}("");
        require (sent,"failed to send amount");
        emit withDrawn(msg.sender,address(this).balance);
    }

    function withDrawToAnother (address _firm , uint _amount) public payable onlyOwner {
        (bool sent, ) = _firm.call{value: _amount}("");
        require (sent,"failed to send amount");
        emit withDrawn(_firm,_amount);

    }

    function claim (uint256 id) public {
        require (nftAdd.balanceOf(msg.sender) >= 1,'Not Allowed');
        require (msg.sender == nftAdd.ownerOf(id) && !claimed[id],'Not owner or Claimed');
        claimed[id] = true;
        token.transfer(msg.sender,shares);
    }

    function changeShares (uint256 amount) external onlyOwner{
        shares = amount;
    }

    function getDonorAmount(address donor) view  external returns(uint) {
        return DonorsAmount[donor];
    }

    function getBalance () view external returns(uint){
        return address(this).balance;
    }

    function getNameOfDonor (uint _count) view external returns(string memory){
       return nameOfDonor[_count];
    }

    function getCounter () view external returns (uint256){
        return counter;
    }


    function changeOwnership(address newOwner) onlyOwner public{
        owner = newOwner;
    }

    function changeNFTowership(address _newOwner) onlyOwner public {
        nftAdd.transferOwnership(_newOwner);
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "ONLY OWNER");
        _;
    }
    receive() external payable{

    }
}