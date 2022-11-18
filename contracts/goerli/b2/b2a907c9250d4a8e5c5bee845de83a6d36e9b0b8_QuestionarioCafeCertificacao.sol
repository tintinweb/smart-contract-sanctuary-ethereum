/**
 *Submitted for verification at Etherscan.io on 2022-11-18
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

    contract QuestionarioCafeCertificacao {

struct Cliente {
	string nome;
    string sobrenome;
    string email;
    uint64 celular;
    string idNacional;
}

struct Auditor {
	string nome;
    string sobrenome;
    string email;
    uint64 celular;
    string idNacional;
}

struct Colaborador {
    string nome;
    string sobrenome;
    string ocupacao;
    string dataInicial;
    uint64 telefone;
}

struct Fazenda {
    string nome;
    string cidade;
    string idNacional;
    string endereco;
    string estado;
    string unidadeProdutora;
    string areaTotalHA;
    string geojsonTotal;
    string areaTotalCultivo;
    string geojsonCultivo;
    string areaPreservadaHA;
    string geojsonPreservada;
}

struct Benfeitoria {
    string nome;
    string classificacao;
    string dataInicial;
    string latitude;
    string longitude;
}

struct DocumentoBenfeitoria {
	string filename;
	string originalFilename;
}

struct AnotacaoCampo {
	string variedade;
    string areaCultivo;
    string dataColheita;
    string dataPlantio;
    bool adocaoPratica;
    Fertilizacao[] fertizacoes;
    Pesticida[] pesticidades;
    Colheita[] colheitas;
    Colaborador[] colaboradores;
}

struct Preparacao {
	string data;
    string responsavel;
    PraticaAgricola[] praticas_agricolas;
}

struct PraticaAgricola {
	string TipoPraticaAgricola_;
    string outro;
}

struct Fertilizacao {
	string dataAplicacao;
    string produto;
    uint64 dose;
    string formaAplicacao;
    string responsavel;
}

struct Pesticida {
	string produto;
    string principioAtivo;
    string dataAplicacao;
    string peste;
    uint64 dose;
    uint64 volume;
    string responsavel;
}

struct Colheita {
	string data;
    uint64 quantidade;
    string destino;
    string responsavel;
}


struct QuestionarioType {
	string nome;
	string descricao;
}

struct StatusQuestionario {
	string statusProximo_;
    string statusAtual_;
    string data;
}

struct Topico {
    string descricao;
    string indice;
    string capitulo_;
}

struct Resposta {
	string descricao;
}

struct Requisito {
	string descricao;
    string indice;
}

struct Tarefa {
	string descricao;
}

struct StatusResposta {
	string statusProximo_;
    string statusAtual_;
    string data;
}

 struct Documento {
 	string filename;
 	string originalFilename;
 }

    event NovoQuestionarioEvent(
    uint256 data, address sender,
    Cliente cliente, Auditor auditor, QuestionarioType questionario,
    Fazenda fazenda, AnotacaoCampo anotacao_campo_
    );

    function addQuestionario(
        Cliente memory cliente_, 
        Auditor memory auditor_, 
        QuestionarioType memory questionario_, 
        Fazenda memory fazenda_, 
        AnotacaoCampo memory anotacao_campo_) external {
     
        emit NovoQuestionarioEvent(
            block.timestamp, msg.sender,
            cliente_, auditor_, questionario_, fazenda_, anotacao_campo_);    
    }   

}