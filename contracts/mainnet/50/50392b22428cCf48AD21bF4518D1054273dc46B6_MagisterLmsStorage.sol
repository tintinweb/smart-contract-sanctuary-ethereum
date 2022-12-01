/**
 *Submitted for verification at Etherscan.io on 2022-12-01
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

contract MagisterLmsStorage {
    // definizione certificato
    struct Certificate {
        address platform;
        uint256 date;
    }

    // definizione certificato
    struct Badge {
        string url;
        uint256 date;
    }

    // proprietario contratto
    address _owner;
    //link dominio e platform's wallet
    mapping(string => address) public _platforms;
    //link platform's wallet e indirizzo dati badge
    mapping(address => mapping(uint256 => Badge)) public _badges;
    //link file hash e Certificate (platform's wallet + block timestamp)
    mapping(string => Certificate) public _certs;

    // crea il contratto e registra il proprietario
    // chi esegue questa operazione diventerà il proprietario dell'istanza pubblicata
    constructor() {
        _owner = msg.sender;
    }

    //imposta l'indirizzo del proprietario
    //solo il proprietario può eseguire questa operazione
    function setOwner(address _newOwner) public {
        require(msg.sender == _owner, "not owner");
        _owner = _newOwner;
    }

    //restituisce l'indirizzo del proprietario
    function getOwner() public view returns (address) {
        return _owner;
    }

    //registra una nuova piattaforma (address <-> dominio)
    //solo il proprietario può eseguire questa operazione
    //probabilmente dovra restare freeforall
    function registerUpdatePlatform(string calldata _domain) public {
        //require(msg.sender == _owner, "not owner");
        _platforms[_domain] = msg.sender;
    }

    //restituisce il domino legato all'indirizzo
    function getPlatformAddress(string calldata _domain)
        public
        view
        returns (address)
    {
        return _platforms[_domain];
    }

    //registra un certificato (file_hash, address piattaforma, timestamp del blocco)
    // solo le piattaforme (address) posso eseguire questa operazione
    function registerCertificate(string calldata _domain, string calldata _hash)
        public
    {
        require(_platforms[_domain] == msg.sender);
        _certs[_hash] = Certificate(msg.sender, block.timestamp);
    }

    //recupera i dati relativi ad un hash
    //input: file hash
    //output: indirizzo piattaforma, data registrazione certificato, dominio piattaforma
    function getCertificateByHash(string calldata _hash)
        public
        view
        returns (address, uint256)
    {
        return (_certs[_hash].platform, _certs[_hash].date);
    }

    //registra un badge (url data, address piattaforma, timestamp del blocco)
    // solo le piattaforme (address) posso eseguire questa operazione
    function registerBadge(
        uint256 _id,
        string calldata _url,
        string calldata _domain
    ) public {
        require(_platforms[_domain] == msg.sender);
        _badges[msg.sender][_id] = Badge(_url, block.timestamp);
    }

    //recupera i dati relativi ad un badge id di una specifica piattaforma (platform address)
    //input: file hash
    //output: indirizzo piattaforma, data registrazione certificato, dominio piattaforma
    function getBadgeById(address _platform, uint256 _badgeid)
        public
        view
        returns (string memory, uint256)
    {
        _badges[_platform][_badgeid];
        return (
            _badges[_platform][_badgeid].url,
            _badges[_platform][_badgeid].date
        );
    }
}