// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./IERC20.sol";

contract KingsOfKings is ERC1155, Ownable {
    
    constructor(string memory _lightUri,string memory _darkUri){
        _setURI(lightID, _lightUri); //https://whenft.mypinata.cloud/ipfs/Qmev6ynextBQ2S3KuffXAJP9DKTuo7Y2dGW7naWKhatKCL/1.png
        _setURI(DarkID, _darkUri); //https://whenft.mypinata.cloud/ipfs/Qmev6ynextBQ2S3KuffXAJP9DKTuo7Y2dGW7naWKhatKCL/2.png
        royalityAddresss=payable(msg.sender);

    }

 
    uint256 public lightPrice=25000000000000000; //0.025 ether
    uint256 public darkPrice=25000000000000000; //0.025 ether
    uint256 public maxlightSupply=7777; 
    uint256 public maxdarkSupply=7777;
    uint256 public lightID=1;
    uint256 public DarkID=2;
    address public royalityAddresss;




    mapping(uint256 =>uint256) public supplytracker;



    function setURI(uint256 tokenID,string memory newuri) public onlyOwner {
        _setURI(tokenID,newuri);
    }


    function mintLight(address account, uint256 amount)
        public payable
        
    {   
        require(supplytracker[lightID]+amount<=maxlightSupply,"Max Supply Reached");
        if(msg.sender==owner()){
            
            _mint(account, lightID, amount, "");
            supplytracker[lightID]+=amount;
        }
        else{
            require(msg.value>=lightPrice,"insufficient Balance!");
            _mint(account, lightID, amount, "");
            supplytracker[lightID]+=amount;
        }
 
        
    }

      function mintDark(address account, uint256 amount) public payable
    {

        require(supplytracker[DarkID]+amount<=maxdarkSupply,"Max Supply Reached");
        if(msg.sender==owner())
            {
                    _mint(account, DarkID, amount, "");
                    supplytracker[DarkID]+=amount;
            }
        else
            {
                    require(msg.value>=darkPrice,"insufficient Balance!");
                    _mint(account, DarkID, amount, "");
                    supplytracker[DarkID]+=amount;
            }
    }


    function changeLightPrice(uint256 _price) public onlyOwner{
        lightPrice=_price;
    }

    function changeDarkPrice(uint256 _price) public onlyOwner{
        darkPrice=_price;
    }

    function changeLightURI(string memory _URI) public onlyOwner{
        _setURI(lightID, _URI);
    }

    function changeDarkURI(string memory _URI) public onlyOwner{
        _setURI(DarkID, _URI);
    }

    function changeroyalityAddresss(address _addr) public onlyOwner {
        royalityAddresss=payable(_addr);
    }

    function withdrawERC(IERC20 _addr, uint256 _amount) public  onlyOwner{
        IERC20(_addr).transfer(msg.sender,_amount);
    }
    function withdraw( uint256 _amount) public  onlyOwner{
        payable(msg.sender).transfer(_amount) ;
    }

    function setwhiteList(address _addr,bool _status) public  onlyOwner{
        whiteList[_addr]=_status;
    }


    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}