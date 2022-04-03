/**
 *Submitted for verification at Etherscan.io on 2022-04-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ControlZ {

    address public owner;

    // Definir objetos NFT
    struct Drop {
        string imageUri;
        string NameProject;
        string WebSite;
        string MarketLink;
        string DiscordLink;
        string DescriptionProject;
        string NumberOfItems;
        string Price;
        uint256 Presale;
        uint256 Sale;
        uint8 Chain;
        bool Approved;
    }
  
    // Crie uma lista de algum tipo para Mostrar todos os objetos
    Drop[] public drops;
    mapping(uint256 => address) public users;

    constructor(){
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner, "voce nao tem acesso a esse contrato");
        _;
    }
    
    // Pegar a lista de NFTs
    function getDrops() public view returns(Drop[] memory) {
         return drops;
    } 
    // Adiciona a NFT na Lista 
    function addDrop(Drop memory _drop) public {
        _drop.Approved = false;
        drops.push(_drop);
        uint256 id = drops.length - 1;
        users[id] = msg.sender;
    }
    // Editar os objetos da de uma NFT
    function UpdateDrop(uint256 _id, Drop memory _drop ) public {
        require(msg.sender == users[_id], "Voce nao tem a Autorizacao necessaria");
        _drop.Approved = false;
        drops[_id] = _drop;
    }
    // Permitir que essa Nft seja visivel para todos 
    function ApproveDrop(uint256 _id) public onlyOwner {
        Drop storage drop = drops[_id];
        drop.Approved = true;
    }

    }