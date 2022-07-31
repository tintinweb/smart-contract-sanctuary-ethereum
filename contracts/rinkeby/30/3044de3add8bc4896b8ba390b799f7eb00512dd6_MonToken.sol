/**
 *Submitted for verification at Etherscan.io on 2022-07-31
*/

//aller dans
// ethereum.org/en/developers/docs/standards/tokens/erc-20/
//il nous montre des fonctions a respecter

//SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

//0 creer un token   de type erc-20
contract MonToken {
   string public constant nom="Tarek";
   string public constant symbol="TRK";
   //ether = 10 exposant 18; deriere 1    10 zeros
   uint8 public decimals=18;
   //masse monetaire
   uint public totalSupply;

   //0 correspondre une adresse à sa balance donc creer un mapping
   mapping(address=>uint256) public balanceOf;

   //2 creer un double mapping, adresse autoriser a cette adresse de depenser ce montant
   mapping(address=>mapping(address=>uint256)) public allowance;

   //3  ajouter adresse owner
   address public owner;

   //1   ajouter l event transfer, indexed pour filtrer les evenements
   event Transfer(address indexed _from, address indexed _to, uint256 _value);
   //2 evenement approuver transaction
   event Approval(address indexed _owner, address indexed _spender, uint256 _value);
   //5 event ownership
   event Ownership(address indexed owner, address indexed neOwner);

   //0 constructor
   constructor(uint256 _totalSupply){
       //3  personne qui va deployer le smart contract
       owner=msg.sender;
      
       totalSupply=_totalSupply*10**decimals;
       //nb de tous les tokens deployés
       balanceOf[msg.sender]=totalSupply;
       //a ce stade on met la valeur des tokens et on peut deployer
       //on met 1000000
       //dans total supply on trouve la valeur
       //balanceOf aussi de l adresse deployeur aura la meme valeur
   }

   //4
   modifier onlyOwner(){
       require(msg.sender==owner, "tu n es pas le owner");
       _;
   }

   //apres premier deploiemment
   //1   on peut maintenant faire le transfert
   function transfer(address _to, uint256 _value) public returns (bool success)
   {   //il ne faut pas envoyer a une adresse 0
       require(_to!=address(0), "met adresse normale");
       //valeut est ok a transferer
       require(balanceOf[msg.sender]>=_value, "pas suffisant");
       balanceOf[msg.sender]-=_value;
       balanceOf[_to]+=_value;

       emit Transfer(msg.sender, _to, _value);

       return true;
       //a ce stade on peut deja transferer les tokens
       //on donnant l adresse au choix d envoi (transfert) et le montant 500
       //et verifier balanceof adresse
   }

   //2  fonction d'apres
   //pour que le token soit tradé par d autre personnes il faut les fonctions
   //approve, allowance et transfertfrom (autoriser : delegation)
   function approve(address _spender, uint256 _value) public returns (bool success){
    //fonction autoriser a depenser les tokens
    allowance[msg.sender][_spender]=_value;

    emit Approval(msg.sender, _spender, _value);

    return true;
   }

   //2.2 on finit par la fonction transfert from
   function transfertFrom(address _from, address _to, uint256 _value) public returns (bool success){
   //verfifier si ok pour la valeur
   require(balanceOf[_from]>=_value);
   //verifier que l autorisation de msg.sender est autorisée pour la valeur a transferer
   require(allowance[_from][msg.sender]>=_value);
   allowance[_from][msg.sender]-=_value;
   balanceOf[_from]-=_value;
   balanceOf[_to]+=_value;

   emit Transfer(msg.sender, _to, _value);

   return true;
   }
   //ici on a finit avec notre token créé
   //on peut tester transferFrom depuis la 2eme adresse a une 3 eme adresse
   //mais avant il faut faire approve




   //3   ajouter des fonctions hors standard

   //fonctions mint et burn
    //injecter des tokens
    function mint(address _to, uint256 _value) public onlyOwner() returns (bool success){
   //require(msg.sender==owner, "tu n es pas le owner");
   require(_to!=address(0));
  totalSupply += _value;
  balanceOf[_to] += _value;

   emit Transfer(msg.sender, _to, _value);

   return true;
   }


   //bruler des tokens
  function burn(uint256 _value) public onlyOwner() returns (bool success){
 //require(msg.sender==owner, "tu n es pas le owner");
  totalSupply -= _value;
  balanceOf[msg.sender] -= _value;

   emit Transfer(msg.sender, address(0), _value);

   return true;
   }

   //5  donner le pouvoir a une autre owner en cas ou
   function transferOwnership(address _newOwner) public onlyOwner()
   {
       owner = _newOwner;
       emit Ownership(msg.sender, _newOwner);
   }

}