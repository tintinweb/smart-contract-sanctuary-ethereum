// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC721.sol";
import "./ReentrancyGuard.sol";


contract Marketplace is ReentrancyGuard {

    // Variables
    address payable public immutable carteraStrambolics; // the account that receives fees
    uint public immutable tarifa; // the fee percentage on sales 
    uint public totalNft; 

    //Structs
    struct Producto {
        uint idProducto;
        IERC721 coleccion;
        uint idNft;
        uint precio;
        address payable vendedor;
        bool vendido;
    }

    event EnVenta(
        uint idProducto,
        address indexed coleccion,
        uint idNft,
        uint precio,
        address indexed vendedor
    );
    event Comprado(
        uint idProducto,
        address indexed coleccion,
        uint idNft,
        uint precio,
        address indexed vendedor,
        address indexed comprador
    );

    // idProducto -> Producto
    mapping(uint => Producto) public productos;

    //initiate constructor
    constructor(uint _tarifa) {
        carteraStrambolics = payable(msg.sender);
        tarifa = _tarifa;
    }

    //Obtains the total price of an Nft. It includes the listed price + the market comission
    function listarPrecio(uint _idProducto) view public returns(uint){
        return((productos[_idProducto].precio*(100 + tarifa))/100);
    }

    // Make item to offer on the marketplace
    function venderNFT(IERC721 _coleccion, uint _idNft, uint _precio) external nonReentrant {
        require(msg.sender == _coleccion.ownerOf(_idNft),"Only the NFT owner can sell it");
        require(_precio > 0, "The price has to be bigger than 0");
        // increment totalNft
        totalNft ++;
        // transfer NFT
        _coleccion.transferFrom(msg.sender, address(this), _idNft);
        // add new item to productos mapping
        productos[totalNft] = Producto (
            totalNft,
            _coleccion,
            _idNft,
            _precio,
            payable(msg.sender),
            false
        );
        // emit EnVenta event
        emit EnVenta(
            totalNft,
            address(_coleccion),
            _idNft,
            _precio,
            msg.sender
        );
    }

    function comprarNFT(uint _idProducto) external payable nonReentrant {
        uint _PrecioTotal = listarPrecio(_idProducto);
        Producto storage item = productos[_idProducto];
        require(_idProducto > 0 && _idProducto <= totalNft, "this NFT doesn't exist");
        require(msg.value >= _PrecioTotal, "not enough funds to purchase this item");
        require(!item.vendido, "this NFT has already been sold");
        // pay the price to seller 
        item.vendedor.transfer(item.precio);
        // pay the Market fee to carteraStrambolics
        carteraStrambolics.transfer(_PrecioTotal - item.precio);
        // update item to sold
        item.vendido = true;
        // transfer nft to buyer
        item.coleccion.transferFrom(address(this), msg.sender, item.idNft);
        // emit Bought event
        emit Comprado(
            _idProducto,
            address(item.coleccion),
            item.idNft,
            item.precio,
            item.vendedor,
            msg.sender
        );
    }

    /* Funciones ne Falta

    // Actualiza el precio de un Nft 
    function actualizarPrecio()  {
   
    }

    // Retirar fondos?
    function actualizarPrecio()  {
   
    }

    // Permite revender un Nft que se haya comprado
    // No estoy segurop si la funcion venderNft es suficiente
    function reVenderNft() {
      
    }
    */
}