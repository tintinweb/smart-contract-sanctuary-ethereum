pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";

contract MyToken is ERC721Enumerable {
    
    uint256 cmcTokenid; 
    address _owner;

    mapping(address => uint) public whiteList;
    
    constructor() ERC721("joker token ", "JOKER") {
        cmcTokenid = 100000;
        _owner = msg.sender;
    }
    
    
    modifier Owner {   //管理员 判断
        require(_owner ==msg.sender);
        _;
    }
    
    function mint(address _to) public  {
        
        require(whiteList[msg.sender] ==1);
        cmcTokenid ++;
        _mint(_to,cmcTokenid);
    }       
    
    
    function setwhiteList(address _to) public Owner{
        
        whiteList[_to] = 1;
    }
    
    
    function burn(uint256 _tokenId) public{
        
         super._burn(_tokenId);
    }
}