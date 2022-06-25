// SPDX-License-Identifier: GLP-3.0

pragma solidity >=0.5.0 <0.9.0;

contract LGPD{

   event Solicitacao();

struct Controlador{
    string Empresa;
    uint CNPJ;
    address empresa;
}
mapping(address => Controlador) 
Controladores;

struct Operador {
    string nome;
    uint CPF;
    address endereco;
    bool autorizacao;
}

mapping(address => Operador) private
Operadores;
uint256 public numeroOperadores;

struct Titular{
        string nome;
        string sobrenome;
        uint CPF;
        address endereco;
    }
mapping (address => Titular) 
Titulares;
uint256 public numeroTitulares;


    Controlador public EmpresaControlador;
     address public immutable Controladorend;
    enum Dados {permitidos, solicitados, soliexclu, solicitaAltera}
    uint256 dadosExcluidos;

    Dados public ProtecaoDados = Dados.permitidos;

    modifier SomenteAutorizados{
        if(!Operadores[msg.sender].autorizacao) 
        revert("Operador nao autorizado");
        if(msg.sender != Operadores[msg.sender].endereco) 
        revert("Voce nao e Operador");
        _;
    }

    modifier SomenteTitular{
        if(msg.sender != Titulares[msg.sender].endereco) 
        revert("Voce nao e Titular");
        _;
    }
     modifier SomenteControlador{
        if(msg.sender != Controladorend) 
        revert("voce nao e o controlador");
        _;
    }
    
    event solicitante(address indexed endereco);
    
    constructor(string memory _Empresa, uint _CNPJ) {
        EmpresaControlador.Empresa = _Empresa;
        EmpresaControlador.CNPJ = _CNPJ;
        EmpresaControlador.empresa= msg.sender;
        Controladorend = EmpresaControlador.empresa; 
    }

    function cadastrarOperador(uint _CPF, string memory _nome, address endereco) 
    public SomenteControlador{
        Operadores[endereco].nome = _nome;
        Operadores[endereco].CPF = _CPF;
        Operadores[endereco].endereco = endereco;
        numeroOperadores++;
    }
    
    function inserirDados(string memory _nome, 
    string memory _sobrenome, uint _CPF, address endereco) 
    SomenteAutorizados public {
        Titulares[endereco] = Titular(
            _nome,
            _sobrenome,
            _CPF,
            endereco
        );
        numeroTitulares++;
        emit solicitante(msg.sender);
    }
    
    function permitirSolicitacao() public { 
        ProtecaoDados = Dados.solicitados;
        
    }

    function solicitarAltera() public SomenteControlador 
    SomenteTitular returns(string memory, address){
        ProtecaoDados = Dados.solicitaAltera;
        return ("o endereco solicitante e:", msg.sender);
    }

    function autorizarOperador(address _operador)public SomenteControlador{
        Operadores[_operador].autorizacao = true;
    }
    
    function Solcitardados(address _titular) view public 
    SomenteAutorizados returns(string memory, string memory, uint){
        require(ProtecaoDados == Dados.solicitados);
        return (Titulares[_titular].nome, 
        Titulares[_titular].sobrenome, 
        Titulares[_titular].CPF);
        }
        
    function ModificarDadosTitular(string memory _novonome, string memory _novosobrenome, uint _CPF, address _novoendereco)
    SomenteAutorizados public {
        require(ProtecaoDados == Dados.solicitaAltera);
        require(_CPF==Titulares[_novoendereco].CPF, "Nao pode alterar o CPF");
        Titulares[_novoendereco] = Titular(
            _novonome,
            _novosobrenome,
            _CPF,
            _novoendereco
        );
        emit solicitante(msg.sender);
    
    }
    
    function SolicitarExclusao(address enderecohash)  
    SomenteTitular public returns(bool, string memory, string memory){ //inserimos uma função booliana que solicita a exclusão dos dados
        if(msg.sender != enderecohash)
        revert("o endereco nao corresponde ao titular solicitante");
        ProtecaoDados = Dados.soliexclu;
        emit solicitante(msg.sender);
        return (true,"o endereco solicitado para excluir foi nome:",Titulares[enderecohash].nome); 
        }
        
    function ExcluirDados(address titular)public 
     SomenteControlador returns(string memory, address){
        require(ProtecaoDados == Dados.soliexclu);
        Titulares[titular].nome = "exluido";
        Titulares[titular].CPF = 0;
        Titulares[titular].sobrenome = "";
        dadosExcluidos++;
        emit solicitante(msg.sender);
        numeroTitulares--; 
        return("endereco que excluiu foi o", msg.sender);
    }
        
}