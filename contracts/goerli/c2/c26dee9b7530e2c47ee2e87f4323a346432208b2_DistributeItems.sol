/**
 *Submitted for verification at Etherscan.io on 2022-10-28
*/

/**
 *Submitted for verification at Etherscan.io on 2020-10-09
*/

pragma solidity ^0.5.10;

contract iInventory {
    
    function createFromTemplate(
        uint256 _templateId,
        uint8 _feature1,
        uint8 _feature2,
        uint8 _feature3,
        uint8 _feature4,
        uint8 _equipmentPosition
    )
        public
        returns(uint256);

}

contract DistributeItems is iInventory {
    
    modifier onlyAdmin() {
        require(admin == msg.sender, "DISTRIBUTE_ITEMS: Caller is not admin");
        _;
    }
    
    // Check if msg.sender is allowed to take _templateId
    modifier allowedItem(uint256 _templateId) {
        require(allowed[msg.sender][_templateId], "DISTRIBUTE_ITEMS: Caller is not allowed to claim item");
        _;
    }
    
    // Check if distribution has ended (default 0 = skip this check)
    modifier checkDistEndTime(uint256 _templateId) {
        // if distribution end time was set...
        if(distEndTime[_templateId] != 0) {
            require(distEndTime[_templateId] >= now, "DISTRIBUTE_ITEMS: Distribution for item has ended");
        }
        _;
    }
    
    // Check if hard cap reached (default 0 = skip this check)
    modifier checkHardCap(uint256 _templateId) {
        // If hard cap was set...
        if(hardCap[_templateId] != 0) {
            require(amtClaimed[_templateId] < hardCap[_templateId], "DISTRIBUTE_ITEMS: Hard cap for item reached");
        }
        _;
    }
    
    // Check whether the player has claimed _templateId
    modifier checkIfClaimed(uint256 _templateId) {
        require(!claimed[_templateId][msg.sender], "DISTRIBUTE_ITEMS: Player has already claimed item");
        _;
    }
    
    iInventory inv = iInventory(0xfbCc08d711664Fe9514404e4d9597774Ae3A0a63);
    
    address private admin;
    
    // Address => (_templateId => bool)
    mapping (address => mapping(uint256 => bool)) public allowed;
    
    // _templateId => timestamp when distribution ends (default 0 = no distribution end time)
    mapping (uint256 => uint256) public distEndTime;
    
    // _templateId => hard cap of _templateId (default 0 = no cap)
    mapping (uint256 => uint256) public hardCap;
    
    // _templateId => amount of times claimed 
    mapping (uint256 => uint256) public amtClaimed;
    
    // _templateId => player => has the player claimed?
    mapping (uint256 => mapping(address => bool)) public claimed;

    constructor() public {
        admin = msg.sender;
    }
    
    // Admin can add new item allowances
    function addItemAllowance(
        address _player,
        uint256 _templateId,
        bool _allowed
    )
        external
        onlyAdmin
    {
        allowed[_player][_templateId] = _allowed;
    }
    
    // Admin can add new item allowances in bulk 
    function addItemAllowanceForAll(
        address[] calldata _players,
        uint256 _templateId,
        bool _allowed
    )
        external
        onlyAdmin
    {
        for(uint i = 0; i < _players.length; i++) {
            allowed[_players[i]][_templateId] = _allowed;
        }
    }
    
    /*  Admin can add items with distribution time limits 
        and hard cap limits */
    function addTimedItem(
        uint256 _templateId,
        uint256 _distEndTime,
        uint256 _hardCap
    )
        external
        onlyAdmin
    {
        // Capped item?
        if(_hardCap > 0) {
            hardCap[_templateId] = _hardCap;
        }
        
        // Has dist end time?
        if(_distEndTime > now) {
            distEndTime[_templateId] = _distEndTime;
        }
        
    }
    
    /*  Player can claim 1x item of _templateId when 
        Admin has set the allowance beforehand */
    function claimItem(
        uint256 _templateId,
        uint8 _equipmentPosition
    )
        external
        allowedItem(_templateId)
    {
        // Reset allowance (only once per allowance)
        allowed[msg.sender][_templateId] = false;
        
        // Materialize
        inv.createFromTemplate(
            _templateId,
            0,
            0,
            0,
            0,
            _equipmentPosition
        );
    }
    
    /*  Player can claim item drops that have 
        distribution time limits or hard cap limits */
    function claimTimedItem(
        uint256 _templateId,
        uint8 _equipmentPosition
    )
        external
        checkDistEndTime(_templateId)
        checkHardCap(_templateId)
        checkIfClaimed(_templateId)
    {
        // increment the amount claimed if hard cap was set 
        if(hardCap[_templateId] != 0) {
            amtClaimed[_templateId]++;
        }
        
        // only once per address 
        claimed[_templateId][msg.sender] = true;
        
        // Materialize
        inv.createFromTemplate(
            _templateId,
            0,
            0,
            0,
            0,
            _equipmentPosition
        );
    }
    
    function createFromTemplate(
        uint256 _templateId,
        uint8 _feature1,
        uint8 _feature2,
        uint8 _feature3,
        uint8 _feature4,
        uint8 _equipmentPosition
    )
        public
        returns(uint256)
    {
        // (ง •̀_•́)ง
    }
    
}