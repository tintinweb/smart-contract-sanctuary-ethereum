/**
 *Submitted for verification at Etherscan.io on 2023-01-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract AustraCoin {
    
    string public constant Nombre = "AustraCoin";
    string public constant Simbolo = "ASC";
    uint8 public constant Decimales = 18;

    uint256 TotalSupply;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    event Transfer(address indexed Desde, address indexed Hacia, uint256 Cantidad);
    event Approval(
        address indexed Emisor,
        address indexed Receptor,
        uint256 Cantidad
    );

    constructor(uint256 total) {
        TotalSupply = total;
        balances[msg.sender] = total;
    }

    function Total_Minteado() public view returns (uint256) {
        return TotalSupply;
    }

    function Consulta_Balance(address Wallet) public view returns (uint256) {
        return balances[Wallet];
    }

    function Transferir(address Hacia, uint256 Cantidad)
        public
        returns (bool success)
    {
        require(
            Cantidad <= balances[msg.sender],
            "No hay fondos suficientes para hacer la transferencia"
        );
        balances[msg.sender] = balances[msg.sender] - Cantidad;
        balances[Hacia] = balances[Hacia] + Cantidad;
        emit Transfer(msg.sender, Hacia, Cantidad);
        success = true;
    }

    function Otorgar_Permiso(address Receptor, uint256 Cantidad)
        public
        returns (bool success)
    {
        allowed[msg.sender][Receptor] = Cantidad;
        emit Approval(msg.sender, Receptor, Cantidad);
        success = true;
    }

    function Consulta_Pemiso(address Emisor, address Receptor)
        public
        view
        returns (uint256 remaining)
    {
        remaining = allowed[Emisor][Receptor];
    }

    function Transferir_Desde(
        address Desde,
        address Hacia,
        uint256 Cantidad
    ) public returns (bool success) {
        require(
            Cantidad <= balances[Desde],
            "No hay fondos suficientes para hacer la transferencia"
        );
        require(Cantidad <= allowed[Desde][msg.sender], "Remitente no permitido");

        balances[Desde] = balances[Desde] - Cantidad;
        allowed[Desde][msg.sender] = allowed[Desde][msg.sender] - Cantidad;
        balances[Hacia] = balances[Hacia] + Cantidad;
        emit Transfer(Desde, Hacia, Cantidad);
        success = true;
    }
}