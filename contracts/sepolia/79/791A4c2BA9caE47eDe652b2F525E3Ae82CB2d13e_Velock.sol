/**
 *Submitted for verification at Etherscan.io on 2023-05-23
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18 <0.9.0;

contract Velock {
    enum Role {
        Proprietaire,
        Constructeur,
        TiersDeConfiance,
        Administrateur
    }
    
    mapping(address => Role) public roles;
    mapping(address => Proprietaire) private proprietaires;
    mapping(uint256 => Car) public cars;
    mapping(uint256 => string[]) public carLogs;
    address private owner;

    constructor(){
        owner = msg.sender;
        roles[owner] = Role.Administrateur;
    }

    struct Car {
        string specs;
        uint256 mileage;
        string history;
    }

    struct Proprietaire {
        address addr;
        string nom;
        uint256[] vin;
    }

    struct Constructeur {
        address addr;
        string nom;
    }

    struct TiersDeConfiance {
        address addr;
        string nom;
    }

    uint256 private nextVIN;

    // Crée une nouvelle voiture avec les spécifications fournies et renvoie l'identifiant unique de la voiture (VIN)
    function createCar(string memory _specs) public returns (uint256) {
        uint256 vin = nextVIN;
        cars[vin].specs = _specs;
        nextVIN++;
        return vin;
    }

    // Récupère les spécifications de la voiture correspondant à l'identifiant unique (VIN) fourni
    function getCar(uint256 _vin) public view returns (string memory) {
        return cars[_vin].specs;
    }

    // Définit le kilométrage de la voiture correspondant à l'identifiant unique (VIN) fourni
    function setMileage(uint256 _vin, uint256 _mileage) public {
        cars[_vin].mileage = _mileage;
    }

    // Récupère le kilométrage de la voiture correspondant à l'identifiant unique (VIN) fourni
    function getMileage(uint256 _vin) public view returns (uint256) {
        return cars[_vin].mileage;
    }

    // Ajoute un journal (log) à l'historique de la voiture correspondant à l'identifiant unique (VIN) fourni
    function addLog(uint256 _vin, string memory _log) public {
        carLogs[_vin].push(_log);
        string memory history = cars[_vin].history;
        if (bytes(history).length > 0) {
            history = string(abi.encodePacked(history, ";", _log));
        } else {
            history = _log;
        }
        cars[_vin].history = history;
    }

    // Récupère tous les journaux (logs) de l'historique de la voiture correspondant à l'identifiant unique (VIN) fourni
    function getLogs(uint256 _vin) public view returns (string[] memory) {
        return carLogs[_vin];
    }

    // Ajoute une voiture à la liste des voitures du propriétaire correspondant à l'adresse fournie
    function ajouterVoiture(address _addr, uint256 _vin) public {
      Proprietaire storage proprietaire = proprietaires[_addr];
       proprietaire.vin.push(_vin);
    }
    // get les voitures d'un propriétaires
    function getVoituresDuProprietaire(address _addr) public view returns (uint256[] memory) {
        Proprietaire memory proprietaire = proprietaires[_addr];
        return proprietaire.vin;
    }



    //Ajouter un utilisateurs sans droit particulier
    function createProprietaireSansVoiture(address _addr, string memory _nom) public {
    proprietaires[_addr] = Proprietaire(_addr, _nom, new uint256[](0));
    roles[_addr] = Role.Proprietaire;
    }
    // Getters et setters pour la structure Constructeur
    mapping(address => Constructeur) public constructeurs;

    // Définit un constructeur avec l'adresse et le nom fournis
    function setConstructeur(address _addr, string memory _nom) public {
        constructeurs[_addr] = Constructeur(_addr, _nom);
        roles[_addr] = Role.Constructeur;
    }

    // Récupère les informations du constructeur correspondant à l'adresse fournie
    function getConstructeur(address _addr) public view returns (address, string memory) {
        Constructeur memory constructeur = constructeurs[_addr];
        return (constructeur.addr, constructeur.nom);
    }

    // Getters et setters pour la structure TiersDeConfiance
    mapping(address => TiersDeConfiance) public tiersDeConfiances;

    // Définit un tiers de confiance avec l'adresse et le nom fournis
    function setTiersDeConfiance(address _addr, string memory _nom) public {
        TiersDeConfiance memory tiers = TiersDeConfiance(_addr, _nom);
        tiersDeConfiances[_addr] = tiers;
        roles[_addr] = Role.TiersDeConfiance;
    }

    // Récupère les informations du tiers de confiance correspondant à l'adresse fournie
    function getTiersDeConfiance(address _addr) public view returns (address, string memory) {
        TiersDeConfiance memory tiers = tiersDeConfiances[_addr];
        return (tiers.addr, tiers.nom);
    }
    //Fonction retournant des entiers en fonction du rôle des utilisateurs 
function getRoleValue(address user) public view returns (Role) {
    return roles[user];
}

}