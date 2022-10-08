/**
 *Submitted for verification at Etherscan.io on 2022-10-08
*/

//  SPDX-License-Identifier: MIT

pragma solidity > 0.8.0 < 0.9.0;
pragma experimental ABIEncoderV2;

contract ProductosChain
{
    modifier UnicamenteUsuarioDespliegaContrato(address _direccion)
    { 
        // Solo el usuario que despliega el contrato puede editar/eliminar sus productos
        require (_direccion == owner, 'No tienes permiso para ejecutar esta accion');
        _; 
    }

    modifier validarCrearProducto(string memory _nombre, string memory _descripcion)
    {
        require(bytes(_nombre).length > 0,'El nombre es requerido');
        require(bytes(_descripcion).length > 0,'La descripcion es requerida');
        _;
    }

    modifier validarCantidadLimite()
    {
        string memory max = toString(cantidadLimite);
        // string memory msj = string(abi.encodePacked('Limite alcanzado, no se puede crear mas de: ", max, " productos'));
        string memory msj = string(abi.encodePacked('Limite alcanzado, no se puede crear mas productos'));
        require((productos.length + 1) <= cantidadLimite, msj);
        _;
    }


    struct Producto{
        bytes32 id;
        string nombre;
        string descripcion;
        string imagen;
        bool destacado;
        address creadoPor;
        uint creadoEn;
    }

    // Identificador unico nonce
    uint256 nonce = 0;

    // Propietario del contrato
    address public owner;

    // Errores
    // error ErrorNoExisteProducto(string mensaje);

    Producto[] productos;

    // cantidad limite para crear productos
    uint256 cantidadLimite = 256;

    // eventos
    event EventoCrearProducto(bytes32 id, string nombre, string descripcion, string imagen, bool destacado, address creadoPor, uint creadoEn);
    event EventoActualizarProducto(bytes32 id, string nombre, string descripcion, string imagen, bool destacado, address creadoPor, uint creadoEn);
    event EventoEliminarProducto(bytes32 id, string nombre, string descripcion, string imagen, bool destacado, address creadoPor, uint creadoEn);

    event EventoModerarProducto(bytes32 id, string nombre, string descripcion, string imagen, bool destacado, address creadoPor, uint creadoEn);

    constructor()
    {
        owner = msg.sender;
    }

    function getCantidadLimite() public view returns(uint256)
    {
      return cantidadLimite;
    } 

    function setCantidadLimite(uint256 cantidad) public UnicamenteUsuarioDespliegaContrato(msg.sender)
    {
        string memory min = toString(productos.length);
        string memory msj = string(abi.encodePacked('La cantidad no puede ser menor a: ', min));
        require(cantidad > 0, 'La cantidad no puede ser cero');
        require(cantidad > productos.length, msj);
        
        cantidadLimite = cantidad;
    }
    
    function listarProductos() public view returns(Producto[] memory)
    {
        return productos;
    }

    function cantidadProductos() public view returns(uint256)
    {
        return productos.length;
    }

    // Crear producto
    function crearProducto(string memory _nombre, 
                  string memory _descripcion, 
                  string memory _imagen, 
                  bool _destacado) public 
                  validarCrearProducto(_nombre, _descripcion)
                  validarCantidadLimite()
                  returns (Producto memory)
    {
        nonce += 1;
        // bytes32 _id = keccak256(abi.encodePacked( nonce ));
        bytes32 _id = keccak256(abi.encodePacked( block.difficulty, block.timestamp, nonce ));
        address _creadoPor = msg.sender;
        uint _creadoEn = block.timestamp;

        // Creamos el producto
        Producto memory nuevoProducto = Producto(_id, _nombre, _descripcion, _imagen, _destacado, _creadoPor, _creadoEn);
        
        // Añadimos el producto al array de productos
        productos.push(nuevoProducto);

        emit EventoCrearProducto(nuevoProducto.id, nuevoProducto.nombre, nuevoProducto.descripcion, nuevoProducto.imagen, nuevoProducto.destacado, nuevoProducto.creadoPor, nuevoProducto.creadoEn);

        return nuevoProducto;
    }

    // editar producto
    function editarProducto(bytes32 _id) public view returns(Producto memory tmpProducto)
    {
        // Buscamos el producto
        for(uint256 i = 0; i< productos.length; i++)
        {
           if(productos[i].id == _id)
           {
              // Verificamos que la cuenta que edita el producto sea la misma que la creo 
              if(productos[i].creadoPor == msg.sender)
                return productos[i];
              else
                revert('No es propietario de este producto');
           }
       }

       // Si el producto no existe llamaos a revert y enviamos un corto mensaje
       revert('El producto no existe');
    }

    function eliminarProducto(bytes32 _id) public returns(Producto memory, bool success)
    {
        uint256 totalProductos = productos.length;

        for(uint256 i = 0; i< productos.length; i++)
        {
            // Buscamos el producto
           if(productos[i].id == _id)
           {
              // Verificamos que la cuenta que elimina el producto sea la misma que la creo 
              if(productos[i].creadoPor != msg.sender)
                revert('No es propietario de este producto');

              Producto memory tmpProducto = productos[i];
              
              // Intercambiamos valores del ultimo elemento del array con el valor buscado
              productos[i] = productos[totalProductos-1];

              // Borramos el ultimo indice
              delete productos[totalProductos-1]; 

              //Eliminamos el ultimo elemento del array
              productos.pop();

              emit EventoEliminarProducto(tmpProducto.id, tmpProducto.nombre, tmpProducto.descripcion, tmpProducto.imagen, tmpProducto.destacado, tmpProducto.creadoPor, tmpProducto.creadoEn);

              return (tmpProducto, true);
           }
       }

       // Si el producto no existe llamaos a revert y enviamos un corto mensaje
       revert('El producto no existe');
    }

    function actualizarProducto(string memory _nombre, 
                  string memory _descripcion, 
                  string memory _imagen, 
                  bool _destacado, 
                  bytes32 _id) public
                  validarCrearProducto(_nombre, _descripcion) 
                  returns(Producto memory tmpProducto, bool success)
    {
        for(uint256 i = 0; i< productos.length; i++)
        {
            // Buscamos el producto
           if(productos[i].id == _id)
           {
              // Verificamos que la cuenta que actualiza el producto sea la misma que la creo 
              if(productos[i].creadoPor != msg.sender)
                revert('No es propietario de este producto');

              productos[i].nombre = _nombre;
              productos[i].descripcion =  _descripcion;
              productos[i].imagen = _imagen;
              productos[i].destacado = _destacado;

              emit EventoActualizarProducto(productos[i].id, productos[i].nombre, productos[i].descripcion, productos[i].imagen, productos[i].destacado, productos[i].creadoPor, productos[i].creadoEn);

              return (productos[i], true);
           }
       }

       // revert ErrorNoExisteProducto('El producto no existe');
       revert('El producto no existe');
    }

    function moderarProductoEditar(string memory _nombre, 
                  string memory _descripcion, 
                  string memory _imagen, 
                  bytes32 _id) public
                  validarCrearProducto(_nombre, _descripcion)
                  UnicamenteUsuarioDespliegaContrato(msg.sender)
    {
        for(uint256 i = 0; i< productos.length; i++)
        {
           if(productos[i].id == _id)
           {
              productos[i].nombre = _nombre;
              productos[i].descripcion =  _descripcion;
              productos[i].imagen = _imagen;

              emit EventoModerarProducto(productos[i].id, productos[i].nombre, productos[i].descripcion, productos[i].imagen, productos[i].destacado, productos[i].creadoPor, productos[i].creadoEn);
           }
       }
    }

    function moderarProductoEliminar(bytes32 _id) public UnicamenteUsuarioDespliegaContrato(msg.sender)
    {
        uint256 totalProductos = productos.length;

        for(uint256 i = 0; i< productos.length; i++)
        {
           if(productos[i].id == _id)
           {
              Producto memory tmpProducto = productos[i];
              
              productos[i] = productos[totalProductos-1];

              delete productos[totalProductos-1]; 

              productos.pop();

              emit EventoEliminarProducto(tmpProducto.id, tmpProducto.nombre, tmpProducto.descripcion, tmpProducto.imagen, tmpProducto.destacado, tmpProducto.creadoPor, tmpProducto.creadoEn);
           }
       }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.1/contracts/utils/Strings.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }


}