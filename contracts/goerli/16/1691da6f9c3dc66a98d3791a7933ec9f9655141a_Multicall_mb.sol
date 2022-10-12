/**
 *Submitted for verification at Etherscan.io on 2022-10-12
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

contract Multicall_mb {

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
    
    address private owner;
    uint total_value;
    
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    
    // Modificador verifica si el ejecutante es el propietario
    modifier isOwner() {
        require(msg.sender == owner, "No es owner");
        _;
    }
    
    constructor() payable{
        owner = msg.sender; 
        emit OwnerSet(address(0), owner);
        
        total_value = msg.value;  
    }
    
    // Retornar owner
    function getOwner() external view returns (address) {
        return owner;
    }
    
    // almacenar en el smart contract
    function charge() payable public isOwner {
        total_value += msg.value;
    }
    

    // ENVIAR MÚLTIPLES CALLDATA --------------------------------------------------------------------------------
    struct Call {
        address target;
        bytes callData;
    }
    function aggregate(Call[] memory calls) public payable returns (uint256 blockNumber, bytes[] memory returnData) {
        blockNumber = block.number;
        returnData = new bytes[](calls.length);
        for(uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory ret) = calls[i].target.call(calls[i].callData);
            require(success);
            returnData[i] = ret;
        }
    }
    
    // ENVIAR MÚLTIPLES ETHERS --------------------------------------------------------------------------------

    // Envío múltiple con .transfer
    function envioTransfer(address payable receiverAddr, uint receiverAmnt) private {
        receiverAddr.transfer(receiverAmnt);
    }
    // Envío múltiple con .call
    function envioCall(address payable _to, uint receiverAmnt) public payable{
        (bool sent, /*memory data*/) = _to.call{value: receiverAmnt}("");
        require(sent, "Error, Ether no enviado");
    }

    // sumar valores del array para transacción
    function sum(uint[] memory amounts) private returns (uint retVal) {
        uint totalAmnt = 0;
        
        for (uint i=0; i < amounts.length; i++) {
            totalAmnt += amounts[i];
        }
        return totalAmnt;
    }

    // ----- Función que invoca las 3 anteriores .call, .transfer y sum
    function enviarMultipless(address payable[] memory addrs, uint[] memory amnts) public payable {
    //function enviarMultipless(address payable[] memory addrs, uint[] memory amnts) payable public isOwner {
        total_value += msg.value;
        // validar que la cantidad de direcciones sea igual a cantidad de valores
        require(addrs.length == amnts.length, "The length the two arrays should be the same");
        
        uint totalAmnt = sum(amnts);
        
        require(total_value >= totalAmnt, "Validar que el total sea igual a la suma del array");

        for (uint i=0; i < addrs.length; i++) {
            total_value -= amnts[i];
            
            // envío de los valores
            envioCall(addrs[i], amnts[i]);
            //envioTransfer(addrs[i], amnts[i]);
        }
    }

    
    
}