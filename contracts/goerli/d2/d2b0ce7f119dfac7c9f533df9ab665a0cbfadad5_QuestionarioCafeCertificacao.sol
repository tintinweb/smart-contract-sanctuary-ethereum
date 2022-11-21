/**
 *Submitted for verification at Etherscan.io on 2022-11-21
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
    Benfeitoria[] benfeitorias;
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
    Pesticida[] pesticidas;
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

    event NovoQuestionario(
    uint256 data, address sender, string nome, string descricao
    // Cliente cliente, Auditor auditor, QuestionarioType questionario,
    // Fazenda fazenda, AnotacaoCampo anotacao_campo_
    );


    event ClienteInfo(
        string nome,
        string sobrenome,
        string email,
        uint64 celular,
        string idNacional
    );

    event AuditorInfo(
        string nome,
        string sobrenome,
        string email,
        uint64 celular,
        string idNacional
    );

    event FazendaInfo(
        string nome,
        string cidade,
        string idNacional,
        string endereco,
        string estado,
        string unidadeProdutora,
        string areaTotalHA,
        string geojsonTotal,
        string areaTotalCultivo,
        string geojsonCultivo,
        string areaPreservadaHA,
        string geojsonPreservada
    );

    event BenfeitoriasInfo(
        Benfeitoria[] benfeitorias
    );


    event AnotacaoCampoInfo(
        string variedade,
        string areaCultivo,
        string dataColheita,
        string dataPlantio,
        bool adocaoPratica,
        Fertilizacao[] fertizacoes,
        Pesticida[] pesticidas,
        Colheita[] colheitas,
        Colaborador[] colaboradores
    );

    function persistData(
        Cliente memory cliente_, 
        Auditor memory auditor_, 
        QuestionarioType memory questionario_, 
        Fazenda memory fazenda_, 
        AnotacaoCampo memory anotacao_campo_) external {
     
        emit NovoQuestionario(
            block.timestamp, msg.sender, questionario_.nome, questionario_.descricao
        );

        emit ClienteInfo(
            cliente_.nome, cliente_.sobrenome, cliente_.email, cliente_.celular, cliente_.idNacional
        );

        emit AuditorInfo(
            auditor_.nome, auditor_.sobrenome, auditor_.email, auditor_.celular, auditor_.idNacional
        );

        emit FazendaInfo(
            fazenda_.nome,fazenda_.cidade,fazenda_.idNacional,fazenda_.endereco,
            fazenda_.estado,fazenda_.unidadeProdutora,fazenda_.areaTotalHA,fazenda_.geojsonTotal,
            fazenda_.areaTotalCultivo,fazenda_.geojsonCultivo,fazenda_.areaPreservadaHA,fazenda_.geojsonPreservada
        );

        emit BenfeitoriasInfo(
            fazenda_.benfeitorias
        );


        emit AnotacaoCampoInfo(
            anotacao_campo_.variedade,anotacao_campo_.areaCultivo,anotacao_campo_.dataColheita,anotacao_campo_.dataPlantio,
            anotacao_campo_.adocaoPratica,anotacao_campo_.fertizacoes,anotacao_campo_.pesticidas,anotacao_campo_.colheitas,
            anotacao_campo_.colaboradores
        );
    }   

}