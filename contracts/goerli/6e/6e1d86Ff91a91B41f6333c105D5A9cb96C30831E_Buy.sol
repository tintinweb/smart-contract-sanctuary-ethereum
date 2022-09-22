/**
 *Submitted for verification at Etherscan.io on 2022-09-22
*/

/**
 *Submitted for verification at polygonscan.com on 2022-09-12
*/

/**
 *Submitted for verification at polygonscan.com on 2022-09-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "./Gravyard_0.sol";
// import "./Gravyard_1.sol";
// import "./Gravyard_2.sol";
// import "./Gravyard_3.sol";

interface IGravyard_0{
   function buyNFt(address _to, uint256 _tokenId) external payable returns(bool); 
}

interface IGravyard_1{
    function buyNFt(address _to, uint256 _tokenId) external payable returns(bool);
}

interface IGravyard_2{
    function buyNFt(address _to, uint256 _tokenId) external payable returns(bool);
}

interface IGravyard_3{
    function buyNFt(address _to, uint256 _tokenId) external payable returns(bool);
}

interface IGravyard_4{
    function customMint(uint256 lat, uint256 long, uint amount, address _to) external payable returns(bool);
    function totalSupply() external view returns (uint256);


}

contract Buy {
    IGravyard_0 public g0;
    IGravyard_1 public g1;
    IGravyard_2 public g2;
    IGravyard_3 public g3;
    IGravyard_4 public g4;

    mapping(address => mapping(uint256 => bool)) public saleRecord;


    event Bought(address indexed _grav, address indexed _to, uint256 indexed _tokenId, bool sold);
    event BoughtCustom(address _grav, address indexed _to,uint256 indexed _tokenId,uint256  lat,uint256  long);

    constructor(IGravyard_0 _g0, IGravyard_1 _g1, IGravyard_2 _g2, IGravyard_3 _g3, IGravyard_4 _g4){
        g0 = _g0;
        g1 = _g1;
        g2 = _g2;
        g3 = _g3;
        g4 = _g4;
    }

    function buyGrave(address _gravyard, address _to, uint256 _tokenId) external payable returns(bool){
        require(!saleRecord[_gravyard][_tokenId], "Token is already sold");
        if(_gravyard == address(g0))
        { 
            g0.buyNFt{value: msg.value}(_to, _tokenId);
            saleRecord[_gravyard][_tokenId] = true;
            emit Bought(_gravyard, _to, _tokenId, saleRecord[_gravyard][_tokenId]);
            return true;
        }
        else if(_gravyard == address(g1))
        {
            g1.buyNFt{value: msg.value}(_to, _tokenId);
            saleRecord[_gravyard][_tokenId] = true;
            emit Bought(_gravyard, _to, _tokenId, saleRecord[_gravyard][_tokenId]);
            return true;

        }
        else if(_gravyard == address(g2))
        {
            g2.buyNFt{value: msg.value}(_to, _tokenId);
            saleRecord[_gravyard][_tokenId] = true;
            emit Bought(_gravyard, _to, _tokenId, saleRecord[_gravyard][_tokenId]);
            return true;

        }
        else if(_gravyard == address(g3))
        {
            g3.buyNFt{value: msg.value}(_to, _tokenId);
            saleRecord[_gravyard][_tokenId] = true;
            emit Bought(_gravyard, _to, _tokenId, saleRecord[_gravyard][_tokenId]);
            return true;
        }
        else{
            return false;
        }
    }

    function buyCustomGrave(uint256 lat, uint256 long, uint256 _amount, address _to) payable external returns(bool){
            g4.customMint{value: msg.value}(lat, long, _amount, _to);
            emit BoughtCustom(address(g4), _to,g4.totalSupply(),lat,long);
            return true;
       
    }
}