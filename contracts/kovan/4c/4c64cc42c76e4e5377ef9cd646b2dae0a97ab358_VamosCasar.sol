/**
 *Submitted for verification at Etherscan.io on 2022-05-12
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract VamosCasar {

    address auth = 0x6EA4bF97ed7557F13cA5289Ff6d7af01f9EaBaFb;

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
        string dizNoivo;
        address Noiva;
        string dizNoiva;
        bool certificado;
    }
    
    Casamento oCasamento;

    constructor() {
        oNoivo.conta = 0xA79352975EA080aA52c4F8d221Cc6fB5c9bEf8cC;
        oNoivo.nome = "Rodrigo Silva";
        oNoivo.genero = "Masculino";

        aNoiva.conta = 0x7799e5710B5210A45CF5e87F405D644d2A2A46C1;
        aNoiva.nome = "Luis Melo";
        aNoiva.genero = "Feminino";
    }

    function Casar(uint32 data) public {
        require (
            msg.sender == oNoivo.conta ||
            msg.sender == aNoiva.conta,
            unicode"Apenas os noivos podem utilizar esta funcao."
        );
        require ( data > 0 && data < 99999999, unicode"Inserir em formato YYYYMMDD");
        oCasamento.data = data;
        if (msg.sender == oNoivo.conta) {
            oCasamento.Noivo = msg.sender;
            oCasamento.dizNoivo = string (
                abi.encodePacked(
                    "Eu ",
                    oNoivo.nome,
                    ", recebo-te minha esposa a ti, ",
                    aNoiva.nome,
                    ", e prometo ser-te fiel,",
                    " amar-te e respeitar-te,",
                    " na alegria e na tristeza,",
                    " na saude e na doenca,",
                    " todos os dias da nossa vida."
                    )
                );
        }
        else {
            oCasamento.Noiva = msg.sender;
            oCasamento.dizNoiva = string (
                abi.encodePacked(
                    "Eu ",
                    aNoiva.nome,
                    ", recebo-te meu marido a ti, ",
                    oNoivo.nome,
                    ", e prometo ser-te fiel,",
                    " amar-te e respeitar-te,",
                    " na alegria e na tristeza,",
                    " na saude e na doenca,",
                    " todos os dias da nossa vida."
                    )
                );                
        }
    }

    function Certificar(address noivo, address noiva) public returns (string memory verificacao) {
        require (msg.sender == auth);
        require (noivo == oCasamento.Noivo && noiva == oCasamento.Noiva);
            oCasamento.certificado = true;
            return "Casamento Certificado.";
    }
    function verVotos() public view returns(string memory votosNoivo, string memory votosNoiva) {
        require (
            oCasamento.Noivo != address(0) && oCasamento.Noiva != address(0),
            unicode"Ainda nao foram trocados votos."
        );
        return (oCasamento.dizNoivo, oCasamento.dizNoiva);
    }

    function Consultar(address conta) public view returns(string memory verificacao) {
        if (conta == oNoivo.conta) {
            return string(abi.encodePacked("Esta conta pertence ao noivo, ", oNoivo.nome,"."));
        }
        else if (conta == aNoiva.conta) {
            return string(abi.encodePacked("Esta conta pertence a noiva, ", aNoiva.nome,"."));
        }
        else {
            return verificacao = "Esta conta nao pertence a nenhum dos dois.";
        }
    }
}