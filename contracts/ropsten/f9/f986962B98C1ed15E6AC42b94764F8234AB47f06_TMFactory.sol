// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.5.16;

import "./simpleproxy.sol";

contract MasterCopy  {
    address internal masterCopy;
    address internal _admin;
}

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface ITopMinterSetup {
    function setup_constructor(string calldata name,string calldata symbol,
        address _owner,
        address _coo,
        uint256 _value,
        bool _POWMint
    )  external ;
}

interface ITMFactory {
    function newTopMinter(string calldata name,string calldata symbol,
        uint256 _value,
        bool _POWMint
    )  external ;
    function setup_constructor(address _owner,address _auditor,address _am) external;
    function getOrigin()external view returns (address);
    function setOrigin(address b) external;
    function getAdmin()  external view returns (address);
      function setAdmin(address b) external;
}

contract TMFactory is MasterCopy,ITMFactory {
    event LOG_NEW_TM(
        address indexed caller,
        address indexed artist
    );

    mapping(address=>bool) private _isArtist;
    //please dont change memory map, ONLY add
    address private auditorAddress;  
    address private lastArtist;
    //====1.0 above=====
    address public artistMastercopy;

    function isArtist(address b)
        external view returns (bool)
    {
        return _isArtist[b];
    }

    //called by artist account
    function newTopMinter(string calldata _name,string calldata _symbol,
        uint256 _value,
        bool _POWMint
    )  external 
    {
        SimpleProxy proxy = new SimpleProxy(artistMastercopy);
        
        ITopMinterSetup iProxy=ITopMinterSetup(address(proxy));
        (bool success, ) = address(proxy).call(abi.encodeWithSelector(iProxy.setup_constructor.selector, 
        _name,_symbol,msg.sender,auditorAddress,
         _value,
         _POWMint));
        require(success, "CALL: topminter init fail");
        
        _isArtist[address(proxy)] = true;

        emit LOG_NEW_TM(msg.sender, address(proxy));

        lastArtist=address(proxy);
    }
    
    constructor() public {
        //no use
        _admin=address(1);
    }

    function setup_constructor(address _owner,address _auditor,address _am) external {
        require(address(0) == artistMastercopy, "already init!!!!");
        auditorAddress=_auditor;
        _admin = _owner;

        artistMastercopy=_am;
    }

    function getLastArtist()
        external view
        returns (address)
    {
        return lastArtist;
    }

    function getAdmin()
        external view
        returns (address)
    {
        return _admin;
    }

    function setAdmin(address b)
        external
    {
        require(msg.sender == _admin, "ERR_NOT_ADMIN");
        _admin = b;
    }
    function getOrigin()
        external view
        returns (address)
    {
        return masterCopy;
    }
    function setOrigin(address b)
        external
    {
        require(msg.sender == _admin, "ERR_NOT_ADMIN");
        masterCopy = b;
    }
    
    function setArtistMastercopy(address b)
        external
    {
        require(msg.sender == _admin, "ERR_NOT_ADMIN");
        artistMastercopy=b;
    }
    
    function setAuditor(address b)
        external
    {
        require(msg.sender == _admin, "ERR_NOT_ADMIN");
        
        auditorAddress = b;
    }
    



}

pragma solidity ^0.5.16;

contract SimpleProxy {

    address internal masterCopy;
    address internal owner;


    constructor(address _masterCopy)
        public
    {
        require(_masterCopy != address(0), "BID:Zero master is not permitted");
        masterCopy = _masterCopy;
        owner=msg.sender;
    }

    function setMaster(address _masterCopy) external{
        require(msg.sender==owner, "not controller");
        masterCopy = _masterCopy;
    }

    function ()
        external
        payable
    {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let masterCopy := and(sload(0), 0xffffffffffffffffffffffffffffffffffffffff)
            calldatacopy(0, 0, calldatasize())
            let success := delegatecall(gas, masterCopy, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            if eq(success, 0) { revert(0, returndatasize()) }
            return(0, returndatasize())
        }
    }
}