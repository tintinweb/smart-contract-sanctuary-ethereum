/**
 *Submitted for verification at Etherscan.io on 2022-11-11
*/

// Version de solidity del Smart Contract
// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.16;

// Informacion del Smart Contract
// Nombre: Subasta
// Logica: Implementa subasta de productos entre varios participantes

// Declaracion del Smart Contract - Auction
contract Auction {

    // ----------- Variables (datos) -----------
    // Información de la subasta
    string private description;
    uint private basePrice;
    uint256 private secondsToEnd;
    uint256 private createdTime;

    // Antiguo/nuevo dueño de subasta
    address payable public originalOwner;
    address public newOwner;

    // Puja mas alta
    address payable public highestBidder;
    uint public highestPrice;
    
    // Estado de la subasta
    bool private activeContract;
    
    // ----------- Eventos (pueden ser emitidos por el Smart Contract) -----------
    event Status(string _message);
    event Result(string _message, address winner);

    // ----------- Constructor -----------
    // Uso: Inicializa el Smart Contract - Auction con: description, precio y tiempo
    constructor() {
        
        // Inicializo el valor a las variables (datos)
        description = "En esta subasta se ofrece un coche. Se trata de un Ford Focus de ...";
        basePrice = 1 wei;   
        secondsToEnd = 60;   // 86400 = 24h | 3600 = 1h | 900 = 15 min | 600 = 10 min
        activeContract = true;
        createdTime = block.timestamp;
        originalOwner = payable(msg.sender);
        
        // Se emite un Evento
        emit Status("Subasta creada");
    }
    
    // ------------ Funciones que modifican datos (set) ------------

    // Funcion
    // Nombre: bid
    // Uso:    Permite a cualquier postor hacer una oferta de dinero para la subata
    //         El dinero es almacenado en el contrato, junto con el nombre del postor
    //         El postor cuya oferta ha sido superada recibe de vuelta el dinero pujado
    function bid() public payable {
        if(block.timestamp > (createdTime + secondsToEnd)  && activeContract == true){
            checkIfAuctionEnded();
        } else {
            if (msg.value > highestPrice && msg.value > basePrice){
                // Devuelve el dinero al ANTIGUO maximo postor
                highestBidder.transfer(highestPrice);
                
                // Actualiza el nombre y precio al NUEVO maximo postor
                highestBidder = payable(msg.sender);
                highestPrice = msg.value;
                
                // Se emite un evento
                emit Status("Nueva puja mas alta, el ultimo postor tiene su dinero de vuelta");
            } else {
                // Se emite un evento
                emit Status("La puja no es posible, no es lo suficientemente alta");
                revert("La puja no es posible, no es lo suficientemente alta");
            }
        }
    }

    // Funcion
    // Nombre: checkIfAuctionEnded
    // Uso:    Comprueba si la puja ha terminado, y en ese caso, 
    //         transfiere el balance del contrato al propietario de la subasta 
    function checkIfAuctionEnded() public{
        if (block.timestamp > (createdTime + secondsToEnd)){
            // Finaliza la subasta
            activeContract = false;
            
            // Transfiere el dinero (maxima puja) al propietario original de la subasta
            newOwner = highestBidder;
            originalOwner.transfer(highestPrice);
            
            // Se emiten varios eventos
            emit Status("La subasta ha finalizado");
            emit Result("El ganador de la subasta ha sido:", highestBidder);
        } else {
            revert("La subasta esta activa");
        }
    }
        
    // ------------ Funciones de panico/emergencia ------------

    // Funcion
    // Nombre: stopAuction
    // Uso:    Para la subasta y devuelve el dinero al maximo postor
    function stopAuction() public{
        require(msg.sender == originalOwner, "You must be the original OWNER");
        // Finaliza la subasta
        activeContract = false;
        // Devuelve el dinero al maximo postor
        if (highestBidder != address(0x0)){
            highestBidder.transfer(highestPrice);
        }
        
        // Se emite un evento
        emit Status("La subasta se ha parado");
    }
    
    // ------------ Funciones que consultan datos (get) ------------

    // Funcion
    // Nombre: getAuctionInfo
    // Logica: Consulta la description, la fecha de creacion y el tiempo de la subasta
    function getAuctionInfo() public view returns (string memory, uint, uint){
        return (description, createdTime, secondsToEnd);
    }
    
    // Funcion
    // Nombre: getHighestPrice
    // Logica: Consulta el precio de la maxima puja
    function getHighestPrice() public view returns (uint){
        return (highestPrice);
    }

    // Funcion
    // Nombre: getHighestBidder
    // Logica: Consulta el maximo pujador de la subasta
    function getHighestBidder() public view returns (address){
        return (highestBidder);
    }

    // Funcion
    // Nombre: getDescription
    // Logica: Consulta la descripcion de la subasta
    function getDescription() public view returns (string memory){
        return (description);
    }

    // Funcion
    // Nombre: getBasePrice
    // Logica: Consulta el precio inicial de la subasta
    function getBasePrice() public view returns (uint256){
        return (basePrice);
    }

    // Funcion
    // Nombre: getActiveContract
    // Logica: Consulta si la subasta esta activa o no
    function isActive() public view returns (bool){
        return (activeContract);
    }
    
}