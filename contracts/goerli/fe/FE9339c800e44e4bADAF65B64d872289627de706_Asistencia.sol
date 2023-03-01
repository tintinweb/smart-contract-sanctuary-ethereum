/**
 *Submitted for verification at Etherscan.io on 2023-03-01
*/

// File: contracts/Asistencia.sol



pragma solidity ^0.8.0;

contract Asistencia {

    address public owner;
    uint256 public numClase = 0;
    uint256[] idClases;
 
    /*struct Clase {
        uint256[] idClases;
        address usuario;
    }
    Clase clase;*/

    modifier isOwner() {
        require(msg.sender == owner, "You are not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

   // mapping(address => bool) public assitedClass;

    mapping(address => mapping(uint => bool)) private assitedClass;

    function hasIdo (address alum, uint256 idClase) public view returns (bool){
        return assitedClass[alum][idClase];
    }


    function crearNuevaClase() public isOwner{
        contador();
        /*clase.*/idClases.push(numClase);
    }

    function marcar(address alumno, uint256 idClase) external {
        require(msg.sender == alumno, "You are not the alumno");
       // require(idClase <= /*clase.*/idClases.length, "La clase no existe");
        require(idClase == /*clase.*/idClases.length, "La clase ya ha pasado");
        
        assitedClass[alumno][idClase] = true;
    }

    function contador() private {
        numClase++;
    }

}