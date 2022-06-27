// SPDX-License-Identifier: GLP-3.0
pragma solidity >=0.5.0 <0.9.0;
//Founder Omnes Blockchain e CTO Web3Club
//instagram @afonsodalvi
// LinkedIn: https://www.linkedin.com/in/afonso-dalvi-711635112/
contract LGPDAfonsoDalvi{
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
    bool acessardados; 
    
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
    function permitirAcessoDados()public SomenteControlador{
        acessardados = true;
    }
    function Solcitardados(address _titular) view public 
     returns(string memory, string memory, uint){ 
         if(!acessardados) 
         revert("nao esta liberado pelo controlador o acesso aos dados");
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
    SomenteTitular public returns(bool, string memory, string memory){ 
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