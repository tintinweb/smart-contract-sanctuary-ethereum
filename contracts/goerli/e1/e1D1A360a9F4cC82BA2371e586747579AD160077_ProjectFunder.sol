// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract ProjectFunder {

    //Estructura para un objeto
    struct Project {
        address owner; 
        string title;
        string description;
        uint target;
        uint deadline;
        uint amountCollected;
        string image;
        address[] contributors;
        uint[] contributions;
    }

    mapping(uint => Project) public projects;

    uint public numberOfProjects = 0;

    function createProject(address _owner, string memory _title, string memory _description, uint _target, uint _deadline, 
    string memory _image ) public returns (uint){

        Project storage project = projects[numberOfProjects]; //"storage" indica que la variable "project" se almacenará en la memoria de almacenamiento permanente en la blockchain.

        /*Comprobación de que la fecha limite elegid es posterior al momento actual.
        block.timestamp hace referencia al tiempo en ese momento, por lo tanto si el project.deadline 
        es anterior a esto enviaremos un mensaje de error*/
        require(project.deadline < block.timestamp, "The deadline should be a date in the future!!"); 

        project.owner = _owner;
        project.title = _title;
        project.target = _target;
        project.deadline = _deadline;
        project.amountCollected = 0;
        project.image = _image;

        numberOfProjects ++;

        return numberOfProjects -1; //Si todo funciona bien, devolvemos el número de proyectos -1 que serà el índice del projecto mas reciente
    }

    function contributeToProject(uint _id) public payable {
        uint amount = msg.value;
        
        Project storage project = projects[_id];

        project.contributors.push(msg.sender); //Insertamos en el Array la address del contribuyente
        project.contributions.push(amount); //Insertamos en el Array la cantidad
        
        (bool sent,) = payable(project.owner).call{value: amount}(""); //Transferimos la cantidad al contrato "project.owner" y verificamos si se ha realizado correctamente

        if(sent){
            project.amountCollected = project.amountCollected + amount;
        }
    }

    // Recogemos las address de los contribuyentes y la cantidad contribuida utilizando el mapping
    function getContributors(uint _id) view public returns(address[] memory, uint[] memory){
        return(projects[_id].contributors, projects[_id].contributions);
    }

    function getProjects() public view returns (Project[] memory) {
        Project[] memory allProjects = new Project[](numberOfProjects);
        /*Creamos una nueva variable llamada "allProjects" que es un tipo de Array de multiples "struct Project" pero no recogemos
         estos "struct project", sino que creamos un Array vació con tantos elementos vacíos como proyectos existen: ej. [{}, {}, {}]*/

        //Llenamos este Array creado con los proyectos
        for (uint i = 0; i < numberOfProjects; i++){
        Project storage item = projects[i];

        allProjects[i] = item;
        }

        return allProjects;
    }
}