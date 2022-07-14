// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

//Solo el usuario suscripto puede acceder a los datos de Block Insurance
//Solo el dueño

contract blockinsurance {
    address public owner;
    address public contractAddress;

    constructor() {
        owner = msg.sender;
        contractAddress = address(this);
    }

    struct beneficiario {
        string nombre;
        uint256 documento;
        // uint pais;
        // string apellido;
    }

    struct poliza {
        uint256 pais;
        uint256 poliza;
        uint256 compania;
        uint256 tiposeguro;
        uint256 prima;
        string caractesticas; // Esto debiera ser un array
    }

    mapping(address => beneficiario) direcciondatosbeneficiario; //genero una estructura de datos tipo BBDD
    mapping(address => bool) suscripcionactiva; //vamos a validar que genera datos mensualmente
    mapping(address => poliza) beneficiario_poliza; //relacion beneficiario poliza
    mapping(bytes32 => poliza) hashpoliza;

    event persona_activa(bool);
    event polizacargada(bool);

    modifier solopoliza(address _dir) {
        require(_dir == owner, "solo puede acceder el dueo del bloque");
        _;
    }

    modifier solousuariosuscripto(address _dir) {
        require(
            suscripcionactiva[_dir] == true,
            "No se encuentra el bloque activo"
        );
        _;
    }

    function suscribirpoliza(
        string memory _nombre,
        uint256 _id,
        uint256 _precio
    ) public {
        require(
            _precio >= 50,
            "No cumple el valor minimo de suscripcion a la cadena"
        );
        direcciondatosbeneficiario[msg.sender] = beneficiario(_nombre, _id);
        suscripcionactiva[msg.sender] = true;
        emit persona_activa(true);
    }

    function verdatos() public view returns (string memory) {
        return direcciondatosbeneficiario[msg.sender].nombre;
    }

    //revisar esta logica
    function suscribirpoliza(
        uint256 _nombre,
        uint256 _poliza,
        uint256 _compania,
        uint256 _tiposeguro,
        uint256 _prima,
        string memory _caractesticas
    ) public solousuariosuscripto(msg.sender) {
        bytes32 hash = keccak256(abi.encodePacked(_poliza));
        hashpoliza[hash] = poliza(
            _nombre,
            _poliza,
            _compania,
            _tiposeguro,
            _prima,
            _caractesticas
        );

        //beneficiario_poliza[msg.sender]=hash;  Ver el error de asignacion

        emit polizacargada(true);
    }
}