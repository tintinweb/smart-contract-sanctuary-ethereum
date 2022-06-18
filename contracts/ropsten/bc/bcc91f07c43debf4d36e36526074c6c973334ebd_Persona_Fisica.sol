/**
 *Submitted for verification at Etherscan.io on 2022-06-18
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Persona_Fisica {
    
    struct P_Fisica_t {  // Aplica RGPD (informació que no hauria de ser visible)
        string dni;
        string nom;
        string adreca;
        string correu;
    }

    mapping (address => P_Fisica_t) public pfisiques;
    address[] public pfisiques_addr;

    event UserCreated (
        string dni,
        string nom,
        string adreca,
        string correu
    );

    function set_persona_fisica(address _address, string memory _dni, string memory _nom, string memory _adreca, string memory _correu) public {
        P_Fisica_t memory pfisica;

        pfisica.dni = _dni;
        pfisica.nom = _nom;
        pfisica.adreca = _adreca;
        pfisica.correu = _correu;

        pfisiques[_address] = pfisica;

        pfisiques_addr.push(_address);

        //emit UserCreated(_dni, _nom, _adreca, _correu);
    }

    function up_dni(address _address, string memory new_dni) public {
        pfisiques[_address].dni = new_dni;
    }

    function up_nom(address _address, string memory new_nom) public {
        pfisiques[_address].nom = new_nom;
    }

    function up_adreca(address _address, string memory new_adreca) public {
        pfisiques[_address].adreca = new_adreca;
    }

    function up_correu(address _address, string memory new_correu) public {
        pfisiques[_address].correu = new_correu;
    }

    function get_pfisica(address _address) view public returns(string memory, string memory, string memory, string memory) {  // X testeig es pública!!!!!!!!!!!!!
        return(pfisiques[_address].dni, pfisiques[_address].nom, pfisiques[_address].adreca, pfisiques[_address].correu);
    }

    function get_pfisiques() view public returns(address[] memory) {
        return pfisiques_addr;
    }
    
    function get_address(address _address) view internal returns(uint) {
        for (uint i = 0; i < pfisiques_addr.length; i++) {
            if (pfisiques_addr[i] == _address) {
                return(i);
            }
        }
        revert("No user with that address");
    }

    function get_quant_addresses() view public returns(uint) {
        return pfisiques_addr.length;
    }

    function is_user_added(address _address) view public returns(bool) {
        for (uint i = 0; i < pfisiques_addr.length; i++) {
            if (pfisiques_addr[i] == _address) {
                return(true);
            }
        }
        return(false);
    }

    function del_address(address _address) public {
        delete pfisiques[_address];
        uint i = get_address(_address);
        delete pfisiques_addr[i];        
    }
}