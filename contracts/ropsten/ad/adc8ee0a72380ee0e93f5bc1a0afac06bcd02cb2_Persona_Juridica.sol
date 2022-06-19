/**
 *Submitted for verification at Etherscan.io on 2022-06-19
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Persona_Juridica {
    
    // Tal i com està fet, només el mateix usuari podrà canviar-se dades

    struct P_Juridica_t { // No aplica RGPD
        string nif;
        string den_social; // denominacio social
        string adreca;
        string dades_constitucio;
        string apoderat;
    }

    mapping (address => P_Juridica_t) public pjuridiques;
    address[] public pjuridiques_addr;

    // event( );

    function set_persona_juridica(address _address, string memory _nif, string memory _den_social, string memory _adreca, string memory _dades_constitucio, string memory _apoderat) public {
        P_Juridica_t memory pjuridica;

        pjuridica.nif = _nif;
        pjuridica.den_social = _den_social;
        pjuridica.adreca = _adreca;
        pjuridica.dades_constitucio = _dades_constitucio;
        pjuridica.apoderat = _apoderat;

        pjuridiques[_address] = pjuridica;

        pjuridiques_addr.push(_address);
    }

    function up_nif(address _address, string memory new_nif) public {
        pjuridiques[_address].nif = new_nif;
    } 

    function up_den_social(address _address, string memory new_den_social) public {
        pjuridiques[_address].den_social = new_den_social;
    }
    
    function up_adreca(address _address, string memory new_adreca) public {
        pjuridiques[_address].adreca = new_adreca;
    }
    
    function up_dades_constitucio(address _address, string memory new_dc) public {
        pjuridiques[_address].dades_constitucio = new_dc; // Dades constitucio
    }
    
    function up_apoderat(address _address, string memory new_apoderat) public {
        pjuridiques[_address].apoderat = new_apoderat;
    }

    function get_pjuridica(address _address) view public returns(string memory, string memory, string memory, string memory, string memory) {  
        return(pjuridiques[_address].nif, pjuridiques[_address].den_social, pjuridiques[_address].adreca, pjuridiques[_address].dades_constitucio, pjuridiques[_address].apoderat);
    }

    function get_pjuridiques() view public returns(address[] memory) {
        return pjuridiques_addr;
    }

    function get_address(address _address) view internal returns(uint) {
        for (uint i = 0; i < pjuridiques_addr.length; i++) {
            if (pjuridiques_addr[i] == _address) {
                return(i);
            }
        }
        revert("No user with that address");
    }

    function get_quant_addresses() view public returns(uint) {
        return pjuridiques_addr.length;
    }

    function is_user_added(address _address) view public returns(bool) {
        for (uint i = 0; i < pjuridiques_addr.length; i++) {
            if (pjuridiques_addr[i] == _address) {
                return(true);
            }
        }
        return(false);
    }

    function del_address(address _address) public {
        delete pjuridiques[_address];
        uint i = get_address(_address);
        delete pjuridiques_addr[i]; 
    }
}