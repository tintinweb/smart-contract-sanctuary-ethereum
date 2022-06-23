/**
 *Submitted for verification at Etherscan.io on 2022-06-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
contract CadernoCampoCiag {


    modifier apenasDono {
        assert(msg.sender == dono);
        _;
        }

    modifier apenasCliente {
        assert(clientes[msg.sender].adr  !=  0x0000000000000000000000000000000000000000);
        _;
    }

    address dono;
    
    constructor() {
        dono = msg.sender;  
    }
    struct Cliente {
        address adr;
        string nome;
        string email;
    }

    struct Address_ {
        string street;
        string number;
        string complemento;
        string cep;
        string city;
        string state;
    }

    struct Technical {
        string name;
        string telephone;
        string cellphone;
        string email;
        string formation;
        string crea;
        string address_;
    }

    struct Property {
        string name;
        string areaCultivated;
        string areaTotal;
        string latitude;
        string longitude;
        string altitude;
        string address_;
        string producer;
    }

    struct SoilPrepOperation {
        string type_;
        string otherPractice;
    }

    struct SoilPrepPractice {
        string type_;
        string practiceOther;
    }

    struct SoilPreparation {
        bool adoptionPractices;
        string soilPrepPractices;
        string soilPrepOperations;
    }

    struct Seed {
        bool originOwn;
        string local;
        bool heatTreatment;
    }

    struct Irrigation {
        string system;
        string waterOrigin;
    }

    struct Fertilization {
        string date;
        string product;
        string dose;
        string applicationForm;
        string responsible;
        string note;
        
    }

    struct Harvest {
        string date;
        string amount;
        string destiny;
        string responsible;
    }

    struct Pesticide {
        string date;
        string harvestDate;
        string graceDate;
        string pest;
        string product;
        string dose;
        string volume;
        string operator;
    }

    struct Lote {
        string number;
        string vegetable;
        string variety;
        string areaCultivation;
        string previousCulture;
        string datePlanting;
        string dateHarvest;
    }

    event NovoCliente(address adr , string nome, string email);
    
    
    event CadernoCampoCreation(
        // Default values
        address adr,    
        string number
    );


    event LoteInfo(
        string vegetable,
        string variety,
        string areaCultivation,
        string previousCulture,
        string datePlanting,
        string dateHarvest
    );

    event TechnicalInfo(
                // Technical 
        string technical_name,
        string technical_telephone,
        string technical_cellphone,
        string technical_email,
        string technical_formation,
        string technical_crea,
        string technical_address // ENDEREÇO EM UMA STRING TUDO JUNTO
    );

    event PropertyInfo(
        // Property 
        string property_name,
        string property_area_Cultivated,
        string property_areaTotal,
        string property_latitude,
        string property_longitude,
        string property_altitude,
        string property_address,
        string producer // ENDEREÇO EM UMA STRING TUDO JUNTO
    );

    event SoilPreparationInfo(
        bool adoptionPractices,
        string soilPrepPractices,
        string soilPrepOperations
    );

    event SeedInfo(
                // Seed
        bool seed_originOwn,
        string seed_local,
        bool seed_heatTreatment
    );

    event IrrigationInfo(
        string system,
        string waterOrigin
    );

    event FerlizationsInfo(
        string ferlizations
    );

    event HarvestsInfo(
        string harvests
    );

    event PesticidesInfo(
        string pesticides
    );


    // DATA 
    mapping(address => Cliente) clientes;
    // METHODS

    function addCadernoCampo(
        Lote memory lote_,
        Property memory property_,
        Technical memory technical_,
        SoilPreparation memory soilPreparation_,
        Seed memory seed_,
        Irrigation memory irrigation_,

        string memory ferlizations,
        string memory harvests,
        string memory pesticides

    ) external {

        emit CadernoCampoCreation(
            msg.sender, lote_.number
         );

        emit LoteInfo(
            lote_.vegetable,lote_.variety, lote_.areaCultivation,lote_.previousCulture,
            lote_.datePlanting,lote_.dateHarvest
        );

        emit TechnicalInfo(
            technical_.name, technical_.telephone, technical_.cellphone, technical_.email,
            technical_.formation, technical_.crea, technical_.address_
        );

        emit PropertyInfo(
            property_.name,property_.areaCultivated, property_.areaTotal, property_.latitude, 
            property_.longitude, property_.altitude, property_.address_, property_.producer
        );

        emit SoilPreparationInfo(
            soilPreparation_.adoptionPractices, soilPreparation_.soilPrepPractices, soilPreparation_.soilPrepOperations
        );

        emit SeedInfo(
            seed_.originOwn, seed_.local, seed_.heatTreatment
        );

        emit IrrigationInfo(
            irrigation_.system, irrigation_.waterOrigin
        );

        emit FerlizationsInfo(
            ferlizations
        );

        emit HarvestsInfo(
            harvests
        );

        emit PesticidesInfo(
            pesticides
        );


    }


    function addCliente(address adr,
    string memory nome, string memory email) 
    external apenasDono() {
        Cliente storage to = clientes[adr];
        to.adr = adr;
        to.nome = nome;
        to.email = email;
        emit NovoCliente(adr,nome, email);
    }


    function getClienteByAddress(address adr) external apenasDono() view returns(Cliente memory) {
        return clientes[adr];
    }
}