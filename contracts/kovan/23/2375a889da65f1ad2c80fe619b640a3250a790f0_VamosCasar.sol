/**
 *Submitted for verification at Etherscan.io on 2022-05-13
*/

/**
 *Submitted for verification at Etherscan.io on 2022-05-12
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

contract VamosCasar {

    address oAutenticado = 0x11cf464aB69fF79f6cb1023604FD86dC652D2C78;

    struct Noivo {
        address conta;
        string nome;
        string genero;
    }

    Noivo oNoivo;

    struct Noiva {
        address conta;
        string nome;
        string genero;
    }

    Noiva aNoiva;

    struct Casamento {
        uint32 data;
        address Noivo;
        address Noiva;
        string dizNoivo;
        string dizNoiva;
        bool certificado;
    }
   
    Casamento oCasamento;

    constructor() {
        oNoivo.conta = 0x7799e5710B5210A45CF5e87F405D644d2A2A46C1;
        oNoivo.nome = "Luis Melo";
        oNoivo.genero = "Masculino";

        aNoiva.conta = 0xA79352975EA080aA52c4F8d221Cc6fB5c9bEf8cC;
        aNoiva.nome = "Rodrigo Silva";
        aNoiva.genero = "Feminino";
    }

    function Casar(uint32 data) public {
        require (msg.sender == oNoivo.conta || msg.sender == aNoiva.conta,unicode"Apenas os noivos podem utilizar esta funcao.");
        require ( data > 0 && data < 99999999, unicode"Inserir data:");
        oCasamento.data = data;
        if (msg.sender == oNoivo.conta) {
            oCasamento.Noivo = msg.sender;
            oCasamento.dizNoivo = string (abi.encodePacked("Eu ",oNoivo.nome,", recebo-te minha esposa a ti, ",aNoiva.nome,", e prometo ser-te fiel,amar-te e respeitar-te,na alegria e na tristeza, na saude e na doenca,todos os dias da nossa vida."));
        }
        else {
            oCasamento.Noiva = msg.sender;
            oCasamento.dizNoiva = string (abi.encodePacked("Eu ",aNoiva.nome,", recebo-te meu marido a ti, ",oNoivo.nome, ", e prometo ser-te fiel, amar-te e respeitar-te,na alegria e na tristeza, na saude e na doenca,todos os dias da nossa vida.")
            );                
        }
    }
    function ConsultarNoivo(address conta) public view returns(string memory verificacao) {
        if (conta == oNoivo.conta) {
            return string(abi.encodePacked("Conta de: ", oNoivo.nome,"."));
        }
        else {
             return verificacao = "Esta conta nao e a do noivo.";
        }
    }
    function ConsultarNoiva(address conta) public view returns(string memory verificacao) {
        if (conta == aNoiva.conta) {
            return string(abi.encodePacked("Conta de: ", aNoiva.nome,"."));
        }
        else{
           
             return verificacao = "Esta conta nao e a da noiva.";
        }
       
    }
        function Certificar(address noivo, address noiva) public returns (string memory verificacao) {
        require (msg.sender == oAutenticado);
        require (noivo == oCasamento.Noivo && noiva == oCasamento.Noiva);
            oCasamento.certificado = true;
            return "Casamento Certificado.";
        } 
}