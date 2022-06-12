/**
 *Submitted for verification at Etherscan.io on 2022-06-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.14;

/*
    El contrato permitirá al adress del "merchant" crear infinitos (h/2^256) botonos de pago via UI
    Cada botón de pago generará un "payment" y tendrá asociado un "payer" que será el pagador del contrato
    Atributos del "payment" generado por el boton de pago:
        - merchant (el comercio que tiene capacidad de retiro)
        - payer (el comprador que debe cumplir los pagos)
        - monto (el total en wei)
        - cuotas (cantidad de pagos)
        - tiempo (plazo total en segundos)
        - strings descriptivos u otros attr para la UI.
    
    Importante:
        Para minimizar funciones de escritura, se deploya un contrato por merchant.

    Funciones De Movimientos de Dinero:
        - Pago de cuotas por parte del payer
        - Retiro de Saldos por parte del merchant
    
    Funciones de Escritura:
        - Constructor 
        - Creación de Botón de pago u "operacion"
        - Eliminacion de operación (softDelete o validacion para evitar borrado por error)
        - Registro de pago de cuota por el payer
        - Registro de retiro de dinero por el merchant


    Funciones de Lectura:
        - Despliegue de todas las operaciones por payer (ids)
        - Lectura de todos los pagos por Operacion (x id) y calculo de morosidad o no.
        - Reporting:
            - Resumen operativo por operacion (% pagado, % pagado en termino, etc)
            - Resumen por payer
            - Resumen por merchant


    Funcionalidades a agregar en otro SC que lo herede:
        Implementacion de modelos de cuotas crecientes/decrecientes custom etc..
        Generación de intereses por mora o descuentos por pago anticipado
        Posibilidad de generar refinanciación por parte del merchant
        Garantia "del payer" no liquidable ni total pero que cubra parte dle riesgo al merchant
        Garantía cruzada de garantes del payer
        Devolución al payer por incumplimiento via ganrantía del merchant c/Address de mediador firmante

*/

contract Cuotas {
    
    /* ------------------
        State Variables
    ---------------------*/ 

    address payable owner;
    address payable internal merchant;
    struct Payment {
        address payer;
        string product;
        uint value;
        uint paymentsNumber;
        uint periodSeconds;
        bool isDeleted;
        uint createdAt;
        uint [] values;
        uint [] expirations;
        bool [] states;
    }
    Payment [] public payments;  


    constructor(address payable _merchant) {
        owner = payable(msg.sender);
        merchant = _merchant;
    }

    /* --------------
        Modifiers    
    -----------------*/ 

    modifier onlyOwner() {
        require (msg.sender == owner, "Only owner can do this");
        _;
    }

    modifier onlyMerchant() {
        require (msg.sender == merchant, "Only merchant can do this");
        _;
    }

    modifier onlyPayer(address _payer) {
        require (msg.sender == _payer, "Only payer can do this");
        _;
    }



    /* ----------------------
        internal functions    
    -------------------------*/ 


    function createArrUint(uint _value, uint _q) internal pure returns (uint[] memory) {
        uint[] memory _arr = new uint[](_q);

        for (uint i=0; i < _q; i++) {
            _arr[i] = _value;
        }
        return(_arr);
    }

    function createExpirations(uint _secondsTotal, uint _q, uint _timestamp) internal pure returns (uint[] memory) {
        uint[] memory _arr = new uint[](_q);

        uint _interval = _secondsTotal / _q;

        for (uint i=0; i < _q; i++) {
            _arr[i] = _timestamp + (i+1) * _interval;
        }
        return(_arr);
    }

    function createArrBool(bool _value, uint _q) internal pure returns (bool[] memory) {
        bool[] memory _arr = new bool[](_q);

        for (uint i=0; i < _q; i++) {
            _arr[i] = _value;
        }
        return(_arr);
    }



    /* ----------------------
        Write functions    
    -------------------------*/ 

    function createOperation( address _payer, 
                                string memory _product, 
                                uint _value,
                                uint _paymentsNumber, 
                                uint _periodSeconds
                            ) public onlyMerchant 
    {
        uint _quota = _value /  _paymentsNumber;
        uint _timestamp = block.timestamp;
        payments.push ( Payment (
                {
                    payer: _payer,
                    product: _product,
                    value: _value,
                    paymentsNumber: _paymentsNumber,
                    periodSeconds: _periodSeconds,
                    isDeleted: false,
                    createdAt: _timestamp,
                    values: createArrUint(_quota, _paymentsNumber),
                    expirations:  createExpirations(_periodSeconds, _paymentsNumber, _timestamp),
                    states:  createArrBool(false, _paymentsNumber)
                }
            ));
    }


    // Le permite solo al merchant marcar una cuota como pagada
    function markAsPaid(uint _id, uint _PaymentNumber) public onlyMerchant {
        Payment storage p = payments[_id];
        p.states[_PaymentNumber] = true;
    }





    /* ----------------------
        Read Only functions    
    -------------------------*/ 

    function reportingMerchant() public view onlyMerchant returns(uint) {
        uint n_ops = payments.length;
        return(n_ops);
    }




    
    function getPaymentProfile(uint _id) public view onlyMerchant 
        returns(uint[] memory _payments, string[] memory _currStates, uint[] memory _secondsToExpirity) {
        
        uint _timestamp = block.timestamp;
        Payment memory p = payments[_id];

        uint _q = p.paymentsNumber;
        string[] memory _states = new string[](_q);
        uint[] memory _ste = new uint[](_q);

        for (uint i=0; i<_q; i++){
            
            if (p.expirations[i] > _timestamp) {
                _ste[i]= p.expirations[i] - _timestamp;   
            }else{
                _ste[i]= _timestamp - p.expirations[i];   
            }
 

            if (p.states[i]==true) {
                _states[i]= 'paid';
            }else if (p.expirations[i] > _timestamp) {
                _states[i]= 'waitingPayment';
            }else{
                _states[i]= 'expired';
            }

        }
        
        return(p.values, _states,_ste);
    }
    



    /* ----------------------
        Payable functions    
    -------------------------*/ 





}