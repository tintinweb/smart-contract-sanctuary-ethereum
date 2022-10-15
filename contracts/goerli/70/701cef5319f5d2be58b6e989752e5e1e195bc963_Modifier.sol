/**
 *Submitted for verification at Etherscan.io on 2022-10-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Modifier {
    
    modifier verificarAdmin() {
        // msg.sender => no queremos que esta cuenta llame al metodo
        require(msg.sender == owner, "No es el owner.");
        _;
    }
  
    modifier whenNotPaused() {
      require(!paused,"El contrato ha sido pausado");
      _;
    }

    function pausarContrato() public verificarAdmin {
      paused = true;
    }

    function quitarPausaContrato() public verificarAdmin {
      paused = false;
    }

    uint256 totalSupply;
    address owner = 0xbC2568Ae7c08501B54D1f53b0A6FB149818feD9E;
    
    bool public paused; // false

    mapping(address => uint256) balances;
    event Transfer(address from, address to, uint256 value);   

    function _mint(address _account, uint256 _amount) internal {
        require(_account != address(0), "Mint to the zero address");

        totalSupply += _amount;
        balances[_account] += _amount;

        emit Transfer(address(0), _account, _amount);
    }

    function mintProtegido(address _account, uint256 _amount) public {
        require(msg.sender == owner, "No es el owner.");
        _mint(_account, _amount);
    }

    function mintProtegidoPorModifier(
        address _account, 
        uint256 _amount
    ) public verificarAdmin whenNotPaused{

        require(!blackList[_account],"Lista Negra");

        _mint(_account, _amount);

        // para atrapar o saber la cuenta de
        // la adrress que estan intentando 
        // hacer el ataque , deberia dejarse que se ejecute todo el metodo hast el final
        //attempts[msg.sender] += 1;
        //if(attempts[msg.sender] >= 3) {
        //    blackList[msg.sender] = true;
        //}

        segundaFunction();
    }


    function segundaFunction() internal pure {
       // mas operaciones 
       require(true); // tambien revierte todo lo anterior
    }

    mapping (address => bool) blackList;
    mapping (address => uint256) attempts;
    function addToBlackList(address _account) public verificarAdmin {
        blackList[_account] = true; 
    }

}