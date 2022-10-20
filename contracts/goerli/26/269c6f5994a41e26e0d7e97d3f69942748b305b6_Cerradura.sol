/**
 *Submitted for verification at Etherscan.io on 2022-10-20
*/

pragma solidity >=0.8.9 <0.9.0;

contract Cerradura {

    struct Casa {
        uint256 id;
        string nombre;
        uint256 precio;
        bool pagado;
        address rentadoPor;
    }
    Casa[] public casas;
    
    constructor(){
    }

    function nuevaCasa(address _rentadoPor) public {
        uint256 id = casas.length + 1;
        casas.push(Casa(id, "NoNombre", 0.05 ether, false, _rentadoPor));
    }
    function pagarRenta( uint _index) public {
        Casa storage casa = casas[_index];
        casa.pagado = true;
    }
    function expirarRenta( uint _index) public {
        Casa storage casa = casas[_index];
        casa.pagado = false;
    }
    function updateNombre( uint _index, string calldata _nombre) public {
        //require(casas[_index].rentadoPor == _msgSender(), 'no eres el rendatario');
        Casa storage casa = casas[_index];
        casa.nombre = _nombre;
    }
    function updatePrecio( uint _index, uint256 _precio) public {
        Casa storage casa = casas[_index];
        casa.precio = _precio;
    }
    
}