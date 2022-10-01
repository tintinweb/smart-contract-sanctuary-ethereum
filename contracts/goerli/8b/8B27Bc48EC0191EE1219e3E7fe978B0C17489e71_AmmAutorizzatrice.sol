/**
 *Submitted for verification at Etherscan.io on 2022-10-01
*/

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title AmmAutorizzatrice
 * @author Giovanni Alessio Quintieri - <[email protected]>
 * @dev uno smart contract per automatizzare le fasi endoprocedimentali 
 */
contract AmmAutorizzatrice {

    address private _owner;
    mapping (string => bool) private beneficiario;

    constructor ()  
    {
        _owner = msg.sender;
    }

    function aggiungiBeneficiario(string memory _nomeBeneficiario, bool _autorizzazione) public
    returns (string memory){
        require(msg.sender == _owner, "Non sei autorizzato alla richiesta");
        beneficiario[_nomeBeneficiario] = _autorizzazione;
        if(_autorizzazione==true)
        {
            return "Beneficiario autorizzato aggiunto";
        }
        return "Beneficiario non autorizzato aggiunto";
    }
    
      
    /**
     * @dev Store value in variable
     * @param _nomeBeneficiario, _autor value to store
     */
    function modAutorizzazione(string memory _nomeBeneficiario, bool _autor) public returns (string memory) {
        require(msg.sender == _owner, "Non sei autorizzato alla richiesta");
        beneficiario[_nomeBeneficiario] = _autor;
        return string.concat("Autorizzazione modificata per il beneficiario",  _nomeBeneficiario);
    }

    /**
     * @dev Return value per chiamata da altri smart contract
     * @return value of 'autorizzato'
     */
    function richiediAutBenef(string memory _nomeBeneficiario) external view returns (bool){
        return beneficiario[_nomeBeneficiario];
    }

    /**
     * @dev Return value 
     * @return value of 'autorizzato'
     */
    function richiediStatoAut(string memory _nomeBeneficiario) public view returns (string memory){
        require(msg.sender == _owner, "Non sei autorizzato alla richiesta");
        if (beneficiario[_nomeBeneficiario]==true)
        {
            //se il beneficiario è autorizzato 
            return string.concat(_nomeBeneficiario, " risulta autorizzato");
        }
        //se il beneficiario non è autorizzato o non è presente sulla blockchain 
        return string.concat(_nomeBeneficiario, " non risulta autorizzato");
    }
}