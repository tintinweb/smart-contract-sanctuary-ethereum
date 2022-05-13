pragma solidity ^0.5.1;

contract ecert
{
    address superadmin;
    address admin;
    address user;

    struct Diploma
    {
        uint256 hash1;
        uint256 hash2;
        mapping(uint => Entry) entries;
        uint numberEntries;
    }

    enum Status { Fail, Valid, RevokeError, RevokeReplace, RevokeFraud, RevokeNoReason}
    mapping(uint24 => string) statusString;
    
    

    struct Entry
    {
        uint256 date;
        address origin;
        Status status;
    }
    
    mapping(uint256=>uint24) hashes;
    Diploma[] diplomas;
    
    modifier onlySuper()
    {
        require(msg.sender==superadmin,'Function reserved to Superadmin');
        _;
    }
    
    modifier onlyAdmin()
    {
        require(admin!=address(0),'Function reserved to Admin but no Admin set');
        require(msg.sender==admin,'Function reserved to Admin');
        _;
    }
    
    modifier onlyUser()
    {
        require(admin!=address(0) || user!=address(0),'Function reserved to User or Admin but none is set');
        require(msg.sender==admin || msg.sender==user,'Function reserved to User or Admin');
        _;
    }
    
    constructor() public{
        superadmin=msg.sender;
        statusString[uint24(Status.Fail)]="Fail";
        statusString[uint24(Status.Valid)]="Valid";
        statusString[uint24(Status.RevokeError)]="RevokeError";
        statusString[uint24(Status.RevokeReplace)]="RevokeReplace";
        statusString[uint24(Status.RevokeFraud)]="RevokeFraud";
        statusString[uint24(Status.RevokeNoReason)]="RevokeNoReason";
    }
    
    function setAdmin(address _admin) onlySuper() external{
        admin=_admin;
    }
    
    function setUser(address _user) onlySuper() external {
        admin=_user;
    }

    event DiplomaAdded(
        address _sender,
        uint24 _diplomaNr,
        uint256 _hash1,
        uint256 _hash2,
        Status status
    );

    function addDiploma(uint256 _hash1,uint256 _hash2, Status _status) onlyUser() external
    {
        require(hashes[_hash1]==0,'hash1 already exists');
        require(hashes[_hash2]==0,'hash2 already exists');
        Diploma memory diploma = Diploma({hash1: _hash1, hash2: _hash2,numberEntries: 0});
        uint24 diplomaNr=uint24(diplomas.push(diploma));
        diplomas[diplomaNr-1].entries[0]=Entry(now,msg.sender,_status);
        diplomas[diplomaNr-1].numberEntries=1;
        hashes[_hash1]=diplomaNr;
        hashes[_hash2]=diplomaNr;
        emit DiplomaAdded(msg.sender, diplomaNr, diplomas[diplomaNr-1].hash1, diplomas[diplomaNr-1].hash2, diplomas[diplomaNr-1].entries[diplomas[diplomaNr-1].numberEntries-1].status);
    }

    event DiplomaChanged(
        address _sender,
        uint24 _diplomaNr,
        uint256 _hash1,
        uint256 _hash2,
        Status status
    );

    
    function changeDiploma(uint256 _hash, Status _status) onlyAdmin() external
    {
        require(hashes[_hash]!=0, 'hash does not exist');
        uint24 diplomaNr=hashes[_hash];
        diplomas[diplomaNr-1].entries[diplomas[diplomaNr-1].numberEntries]=Entry(now,msg.sender,_status);
        diplomas[diplomaNr-1].numberEntries++;
        emit DiplomaChanged(msg.sender, diplomaNr, diplomas[diplomaNr-1].hash1, diplomas[diplomaNr-1].hash2, diplomas[diplomaNr-1].entries[diplomas[diplomaNr-1].numberEntries-1].status);
    }
    
    function requestDiploma(uint256 _hash) external view returns (Status, string memory, string memory, uint)
    {
        if(hashes[_hash]==0) return(Status.Fail,statusString[uint24(Status.Fail)], 'No diploma registered with the hash given.',0);
        uint24 diplomaNr=hashes[_hash];
        Status status=diplomas[diplomaNr-1].entries[diplomas[diplomaNr-1].numberEntries-1].status;
        return (status, statusString[uint24(status)], string(abi.encodePacked('Diploma found with status ', statusString[uint24(status)])), diplomas[diplomaNr-1].numberEntries);
    }
 
    function requestDiplomaEntry(uint256 _hash, uint256 _entry) external view returns (Status, string memory, address, uint)
    {
        if(hashes[_hash]==0) return(Status.Fail, 'No diploma registered with the hash given.',address(0),0);
        uint24 diplomaNr=hashes[_hash];
        if(diplomas[diplomaNr-1].numberEntries<=_entry) return(Status.Fail, 'Entry number given too high.',address(0),0);
        return(diplomas[diplomaNr-1].entries[_entry].status,statusString[uint24(diplomas[diplomaNr-1].entries[_entry].status)], diplomas[diplomaNr-1].entries[_entry].origin,diplomas[diplomaNr-1].entries[_entry].date);
    }
}