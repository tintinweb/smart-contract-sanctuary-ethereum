/**
 *Submitted for verification at Etherscan.io on 2022-03-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
* O projeto pode estar em um dos seguintes estados:
* - not_created, o projeto nunca foi criado;
* - created, o projeto foi criado mas ainda nao tem um executor;
* - in_execution; o projeto foi criado e tem um executor;
* - finished; o projeto foi concluido;
*/
enum Status {not_created, created, in_execution, finished}

struct Media{
  string ipfs_cid;
  string mime_type;
}

struct Project{
  uint256 ID;
  address proponent;
  address executor;
  address authority;
  string title;
  string description;
  uint256 amount;
  uint256 balance;
  string comment;
  uint8 percent_done;
  Media[] files;
  uint256 proposal_date;
  uint256 start_date;
  uint256 end_date;
  Status status;
}

contract BCoinProject {

  // Armazena o ID a ser utilizado na criacao do proximo projeto
  uint256 public _next_ID = 0;
  
  // Armazena a quantidade de projetos que estao no estado created
  uint32 public qdtProjectsInCreatedStatus = 0;

  // Mapping ID to projects
  mapping(uint256 => Project) projects;

  modifier onlyProjectAuthority(uint256 _project_ID){
    require(msg.sender == projects[_project_ID].authority, "NOTauthority");
    _;
  }

  // Gera um ID para novos projetos
  function getNewID() internal returns (uint256){
    return _next_ID++;
  }

  // Cadastra novos projetos
  function createProject(
    address _authority,
    string memory _title,
    string memory _description
  ) public payable{

    uint256 ID = getNewID();
  
    projects[ID].ID = ID;
    projects[ID].proponent = msg.sender;
    projects[ID].authority = _authority;
    projects[ID].title = _title;
    projects[ID].description = _description;
    projects[ID].amount = msg.value;
    projects[ID].balance = msg.value;
    projects[ID].proposal_date = block.timestamp;
    projects[ID].status = Status.created;
    qdtProjectsInCreatedStatus++;
  }

  /*
  * Funcao que deve ser executado pelo endereco que se propoe a ser o executor do projeto.
  *
  * Requirements:
  * - O projeto tem que estar no status created.
  */
  function toSign(uint256 _ID) public {
    require(projects[_ID].status == Status.created, "NOTcreated");

    projects[_ID].executor = msg.sender;
    projects[_ID].status = Status.in_execution;
    projects[_ID].start_date = block.timestamp;
    qdtProjectsInCreatedStatus--;
  }

  /*
  * Requirements:
  * - O projeto tem que estar no status in_execution.
  */
  function setPercentDone(uint256 _project_ID, uint8 _percentage) public onlyProjectAuthority(_project_ID){
    require(projects[_project_ID].status == Status.in_execution, "not_in_execution");

    if (_percentage < 100)
      projects[_project_ID].percent_done = _percentage;
    else
      _finish(_project_ID);
  }
  
  /*
  * Cadastra as IPFS CIDs dos arquivos de comprovacoes das atividades do  projeto.
  *
  * Requirements:
  * - O projeto tem que estar no status in_execution.
  * - Deve ser executada apenas pelo executor do projeto.
  */
  function addFiles(uint256 _project_ID, string[] memory _files_cids, string[] memory _files_mime_types) public{
    require(projects[_project_ID].status == Status.in_execution, "not_in_execution");
    require(projects[_project_ID].executor == msg.sender, "NOTexecutor");

    Media memory file;
    for (uint i=0; i < _files_cids.length; i++) {
      file.ipfs_cid = _files_cids[i];
      file.mime_type = _files_mime_types[i];
      projects[_project_ID].files.push(file);
    }
  }

  /*
  * Adiciona um comentario da autoridade do projeto informando a justificativa da nao finalizacao deste.
  *
  * Requirements:
  * - O projeto tem que estar no status in_execution.
  * - Deve ser executada apenas pela autoridade do projeto.
  */
  function addComment(uint256 _project_ID, string memory _comment) onlyProjectAuthority(_project_ID) public {
    require(projects[_project_ID].status == Status.in_execution, "not_in_execution");

    projects[_project_ID].comment = _comment;
  }

  /*
  * Finaliza o projeto.
  * Deve ser chamada quando o projeto estiver 100% concluido.
  *
  * Requirements:
  * - Os requerimento devem ser verificados pela funcao que esta chamando essa funcao.
  */
  function _finish(uint256 _ID) internal onlyProjectAuthority(_ID){
    projects[_ID].percent_done = 100;
    projects[_ID].status = Status.finished;
    projects[_ID].end_date = block.timestamp;
    _payExecutor(_ID);
  }

  /*
  * Realiza a transferencia da quantidade [project.balance] para o endereco [project.executor].
  *
  * Requirements:
  * - Os requerimento devem ser verificados pela funcao que esta chamando essa funcao.
  */
  function _payExecutor(uint256 _project_ID) internal onlyProjectAuthority(_project_ID){   
    uint256 balance = projects[_project_ID].balance;
    address  executor = projects[_project_ID].executor;

    projects[_project_ID].balance = 0;
    
    (bool success, ) = executor.call{value: balance}("");
    require(success, "");    
  }  

  /*
  * Retorna o projeto.
  *
  * Requirements:
  * - O projeto deve ter sido criado.
  */
  function getProject(uint256 _ID) public view returns(Project memory){
    require(projects[_ID].status != Status.not_created, "NOTexists");
    return projects[_ID];
  }
  
  function getAllProjectInCreatedStatus() public view returns(Project[] memory){
    uint qtdProjects = _next_ID;
    Project[] memory _projects = new Project[](qdtProjectsInCreatedStatus);
    
    uint j = 0;
    for(uint i=0; i < qtdProjects; i++)
      if(projects[i].status == Status.created){
        _projects[j] = projects[i];
        j++;
      }
    
    return _projects;
  }
  

  function getProjectsOfInExecution(address _addr) public view returns(Project[] memory){
    uint256 _qtdProjects = 0;

    for(uint256 ID=0; ID < _next_ID; ID++){
      if (projects[ID].status == Status.in_execution && (projects[ID].authority == _addr || projects[ID].proponent == _addr || projects[ID].executor == _addr)){
        _qtdProjects++;
      }
    }

    Project[] memory _projectsOf = new Project[](_qtdProjects);
    uint256 _projectsOfID = 0;

    for(uint256 ID=0; ID < _next_ID; ID++){
      if (projects[ID].status == Status.in_execution && (projects[ID].authority == _addr || projects[ID].proponent == _addr || projects[ID].executor == _addr)){
        _projectsOf[_projectsOfID] = projects[ID];
        _projectsOfID++;
      }
    }

    return _projectsOf;
  }

   function getProjectsOfFinished(address _addr) public view returns(Project[] memory){
    uint256 _qtdProjects = 0;

    for(uint256 ID=0; ID < _next_ID; ID++){
      if (projects[ID].status == Status.finished && (projects[ID].authority == _addr || projects[ID].proponent == _addr || projects[ID].executor == _addr)){
        _qtdProjects++;
      }
    }

    Project[] memory _projectsOf = new Project[](_qtdProjects);
    uint256 _projectsOfID = 0;

    for(uint256 ID=0; ID < _next_ID; ID++){
      if (projects[ID].status == Status.finished && (projects[ID].authority == _addr || projects[ID].proponent == _addr || projects[ID].executor == _addr)){
        _projectsOf[_projectsOfID] = projects[ID];
        _projectsOfID++;
      }
    }

    return _projectsOf;
  }
 
}