/**
 *Submitted for verification at Etherscan.io on 2022-12-17
*/

// SPDX-License-Identifier: Apache 2.0

pragma solidity >0.8.14;

// Informacion del Smart Contract
// Nombre: Translado en Ambulancia
// Logica: Implementa el translado de ambulancia de un paciente desde un lugar al hospital
// Con varios parámetros cargados mediante IoT o GPS
// Pago por el servicio

// Declaracion del Smart Contract - AbulanceTransfer
contract AmbulanceTransfer {
    //Dirección de la ambulancia
    address payable public ambulance;
    //Dirección del hospital
    address public hospital;
    //Dirección del paciente
    address payable public user;
    
    //pago por el servicio
    uint256 public payment;

    //Pago mínimo de usuario por el servicio de ambulancia
    uint256 private _payment = 10000000 gwei; //0.01 ether

    //Parámetros del paciente
    //Está vivo?
    bool private alive;
    //Está consciente?
    bool private conscious;
    //Presión sanguínea del paciente IoT
    struct Pressure {
        uint8 high;
        uint8 low;
    }
    Pressure private pressure;
    //Ritmo cardiaco del paciente IoT
    uint8 private heartRate;
    //Distancia en metros desde la ambulacia hasta el hospital GPS
    uint32 private distanceM;

    //Iniciamos el sercicio
    bool public init;

    //Ha llegado al hospital?
    bool private arrival;

    //Estado del contrato
    bool public activeContract;

    // ----------- Eventos (pueden ser emitidos por el Smart Contract) -----------
    event Status(string message);
    event NewValue(string message, address hospital);

    // ----------- Constructor -----------
    // Uso: Inicializa el Smart Contract
    constructor() payable {
        //El propietario del smart contract es la ambulancia
        ambulance = payable(msg.sender);        
        //activamos el contrato
        activeContract = true;
        //El servicio está inactivo.
        init = false;
         
        // Se emite un evento
        emit Status("Init ambulance service. Payment MIN: 0.01 ether.");            
    }

    // Declaración de los modificadores

    // La autorización de la ambulancia
    modifier isAmbulance() {
        require(
            activeContract && msg.sender == ambulance,
            "You aren't authorised."
        );
        _;
    }

    //La autorización del hospital
    modifier isHospital() {
        require(
            activeContract && msg.sender == hospital,
            "You aren't authorised."
        );
        _;
    }

    // ------------ Funciones que modifican datos (set) ------------

    // Funcion
    // Nombre: initService
    // Uso:    Inicia el servicio de ambulancia el usuario hacia un hospital
    function initService(address _hospitalIni) public payable{
        require(activeContract, "Must be actived the smart contract.");        

        if (!init && msg.value >= _payment) {
            //iniciamos el servicio
            init = true;
            //Usuario del servicio
            user = payable(msg.sender);
            // Actualiza el payment
            payment = msg.value;
            //Hospital de destino
            hospital = _hospitalIni;              

            alive = true;
            conscious = true;
            distanceM = 0;
            arrival = false;
            pressure = Pressure(0, 0);

            // Se emite un evento
            emit Status("Payment made we perform ambulance service.");
            emit NewValue("The ambulance service has started.", hospital);
        } else {            
            //Se devuelve el dinero al usuario que ha intentado usar el servicio
            payable(msg.sender).transfer(msg.value);
            // Se emite un evento
            if(init) {
                emit Status("The ambulance service is used.");
            }else{
                emit Status("The payment is not enough to perform the service. MIN: 0.01 ether");
            }
        }       
    }

    // Funcion
    // Nombre: updateHeartRate
    // Uso:    Permite a la ambulancia actualizar el ritmo cardiaco del paciente
    function updateHeartRate(uint8 _heartRate) public isAmbulance {
        heartRate = _heartRate;
        emit NewValue("Update value Heart Rate.", hospital);
    }

    // Funcion
    // Nombre: updateDistance
    // Uso:    Permite a la ambulancia actualizar la distancia que queda hasta el hospital
    function updateDistance(uint32 _distanceM) public isAmbulance {       
        distanceM = _distanceM;
        emit NewValue("Update value Distance.", hospital);
    }    

    // Funcion
    // Nombre: updatePressure
    // Uso:    Permite a la ambulancia actualizar la presión arterial del paciente
    function updatePressure(uint8 _high, uint8 _low) public isAmbulance {
        pressure.high = _high;
        pressure.low = _low;
        emit NewValue("Update value Pressure.", hospital);
    }

    // Funcion
    // Nombre: updateAlive
    // Uso:    Permite a la ambulancia actualizar el estado del paciente, si está vivo o no
    function updateAlive(bool _alive) public isAmbulance {
        alive = _alive;
        emit NewValue("Update value Alive.", hospital);
    }

    // Funcion
    // Nombre: updateConscious
    // Uso:    Permite a la ambulancia actualizar el estado del paciente, si está consciente o no
    function updateConscious(bool _conscious) public isAmbulance {
        conscious = _conscious;
        emit NewValue("Update value Conscious.", hospital);
    }

    // Funcion
    // Nombre: setArrival
    // Uso:    Permite a la ambulancia actualizar el estado la llegada al hospital, finalizar el servicio
    //          y que se le efectúe el pago del servicio realizado.
    function setArrival() public payable isAmbulance {        
        distanceM = 0;
        arrival = true;   
        //La ambulancia recibe el pago del servicio    
        ambulance.transfer(payment);
        init = false;
        emit NewValue("Arrival of the ambulance.", hospital);
    }

    // ------------ Funciones de panico/emergencia ------------

    // Funcion
    // Nombre: stopAmbulanceTransfer
    // Uso:    Para el contrato.
    function stopAmbulanceTransfer() public payable {
        require(msg.sender == ambulance, "You must be the owner");
        activeContract = false;
        //Envia el dinero de vuelva a la ambulancia
        ambulance.transfer(payment);
        emit Status("Cancel transfer ambulance.");
    }

    // ------------ Funciones que consultan datos (get) ------------

    // Funcion
    // Nombre: getHeartRate
    // Logica: Consulta el ritmo cardiaco del paciente al hospital
    function getHeartRate() public view isHospital returns (uint8) {
        return heartRate;
    }

    // Funcion
    // Nombre: getDistance
    // Logica: Consulta la distancia hasta el hospital de la ambulancia y solo al hospital
    function getDistance() public view isHospital returns (uint32) {
        return distanceM;
    }

    // Funcion
    // Nombre: getPressure
    // Logica: Consulta el presión arterial del paciente al hospital
    function getPressure() public view isHospital returns (uint8, uint8) {
        return (pressure.high, pressure.low);
    }

    // Funcion
    // Nombre: getAlive
    // Logica: Consulta si está vivo el paciente al hospital
    function getAlive() public view isHospital returns (bool) {
        return alive;
    }

    // Funcion
    // Nombre: getConscious
    // Logica: Consulta si está consciente el paciente al hospital
    function getConscious() public view isHospital returns (bool) {
        return conscious;
    }

    // Funcion
    // Nombre: isArrival
    // Logica: Consulta si ha llegado la ambulancia al hospital
    function isArrival() public view isHospital returns (bool) {
        return arrival;
    }

}