/**
 *Submitted for verification at Etherscan.io on 2022-02-22
*/

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.1;

contract Arras {
    
    enum Tipo {confirmatorias, penales, penitenciales}
    enum Firmado {noFirmado, firmadoVendedor, firmadoComprador}
    Tipo    public tipo;
    string  public referencia;  // Web con la venta, anuncio, etc
    uint    public importe = 0; // Del contrato de arras
    uint    public precio = 0;  // De la venta
    uint256 public vencimiento; // Del contrato de arras
    Firmado public firmado;

    function getArras() public view returns (Tipo, string memory, uint, uint, uint256, Firmado) {
        return (tipo, referencia, importe, precio, vencimiento, firmado);
    }

    function firmaVendedor(Tipo _tipo, string memory _referencia, uint _importe, uint _precio,uint256 _vencimiento) public {
        require(firmado == Firmado.noFirmado);
        tipo        = _tipo;
        referencia  = _referencia;
        importe     = _importe;
        precio      = _precio;
        vencimiento = _vencimiento;
        firmado     = Firmado.firmadoVendedor;
    }

    function firmaComprador() public payable {
        require(firmado == Firmado.firmadoVendedor);
        require(msg.value == importe); // Solo puede enviarse la cantidad exacta del contrato
        firmado = Firmado.firmadoComprador;
    }
}