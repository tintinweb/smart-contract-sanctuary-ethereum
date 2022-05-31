/**
 *Submitted for verification at Etherscan.io on 2022-05-31
*/

pragma solidity >=0.4.0  < 0.7.0;
pragma experimental ABIEncoderV2;

contract Notas {
    //Direccion del profesor que publicara las notas
    address public profesor;
    //Mapping para relacionar el hash de la identidad del alumno con su nota
    mapping(bytes32 => uint256) notas;
    //Array para almacenar las identidades de los alumnos que hacen reclamos
    string[] revisiones;

    //Eventos
    //Evento que se emite cuando se evalua un alumno
    event eventoAlumnoEvaluado(bytes32 id, uint256 nota);
    //Evento que se emite cuando se hace una revision de un alumno
    event eventoRevision(string);

    //Constructor
    constructor() public {
        profesor = msg.sender;
    }

    function evaluar(string memory idAlumno, uint256 notaAlumno)
        public
        unicamenteProfesor(msg.sender)
    {
        //Hash de la idenficacion del alumno
        bytes32 hashAlumno = keccak256(abi.encodePacked(idAlumno));
        //Relacion entre el hash y la nota
        notas[hashAlumno] = notaAlumno;
        //Emision de evento de evaluacion del alumno
        emit eventoAlumnoEvaluado(hashAlumno, notaAlumno);
    }

    modifier unicamenteProfesor(address _profesor) {
        require(_profesor == profesor);
        _;
    }

    function verNotas(string memory idAlumno) public view returns (uint256) {
        //Hash de la idenficacion del alumno
        bytes32 hashAlumno = keccak256(abi.encodePacked(idAlumno));
        //Si la nota existe, se muestra, si no, se muestra un mensaje de error
        require(notas[hashAlumno] != 0, "No se encuentra la nota del alumno");
        return notas[hashAlumno];
    }

    //Funcion para pedir revision del examen
    function Revision(string memory idAlumno) public {
        revisiones.push(idAlumno);
        emit eventoRevision(idAlumno);
    }

    function verRevisiones()
        public
        view
        unicamenteProfesor(msg.sender)
        returns (string[] memory)
    {
        return revisiones;
    }
}