/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
contract Testes {

    struct Cliente {
        address adr;
        string nome;
        string email;
    }

    struct Address_ {
        string street;
        uint64 number;
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
        Address_ address_;
    }

    struct Property {
        string name;
        uint256 areaCultivated;
        uint256 areaTotal;
        string latitude;
        string longitude;
        string altitude;
        Address_ address_;
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
        SoilPrepPractice[] soilPrepPractices;
        SoilPrepOperation[] soilPrepOperations;
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
        uint256 dose;
        string applicationForm;
        string responsible;
        string note;
        
    }

    struct Harvest {
        string date;
        int256 amount;
        string destiny;
        string responsible;
    }

    struct Pesticide {
        string date;
        string harvestDate;
        string graceDate;
        string pest;
        string product;
        int256 dose;
        int256 volume;
        string operator;
    }

    struct CadernoCampo {
        string number;
        string vegetable;
        string variety;
        uint256 areaCultivation;
        string previousCulture;
        string datePlanting;
        string dateHarvest;
        Property property_;
        Technical technical_;
    }

    event NovoCliente(address adr , string nome, string email);
    
    
    event CadernoCampoCreation(
        // Default values
        address adr,    
        uint256 data,
        // From front-end
        CadernoCampo cadernoCampo_
        // SoilPreparation[] soilPreparation_,
        // Seed seed_,
        // Irrigation irrigation_,
        // Fertilization[] fertilizations,
        // Harvest[] harvests,
        // Pesticide pesticides
    );


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
    // DATA 
    mapping(address => Cliente) clientes;

    // METHODS

    function addCadernoCampo(
        string memory number,
        string memory vegetable,
        string memory variety,
        uint256 areaCultivation,
        string memory previousCulture,
        string memory datePlanting,
        string memory dateHarvest,

        // Parameters Property

        Property memory property_,
        Technical memory technical_

        // Parameters SoilPreparation 

    ) external {
        emit CadernoCampoCreation(
            msg.sender, block.timestamp, // DEFAULT VALUES
    CadernoCampo(
        number,vegetable,variety, areaCultivation,previousCulture,datePlanting,dateHarvest, // LOTE
        property_, technical_
        )
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