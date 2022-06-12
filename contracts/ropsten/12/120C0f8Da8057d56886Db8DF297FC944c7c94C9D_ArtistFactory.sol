// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.5.16;

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

interface IArtistSetup {
    function setup_constructor(string calldata name,string calldata symbol,address artistaddr,
    address auditor,address _bid,address _bonusPool,address _devPool,address _vbid)  external ;
    function name() external view returns (string memory);
     function tokenURI(uint256 tokenId) external view returns (string memory) ;
}

interface IArtistFactory {
    function newArtist(string calldata _name,string calldata _symbol)external;
    function setup_constructor(address _owner,address _bid,address _auditor,address _bonusPool,address _devPool,address _am,address _vbid) external;
    function getOrigin()external view returns (address);
    function setOrigin(address b) external;
    function getAdmin()  external view returns (address);
      function setAdmin(address b) external;
}

contract ArtistFactory is MasterCopy,IArtistFactory {
    event LOG_NEW_ARTIST(
        address indexed caller,
        address indexed artist
    );

    mapping(address=>bool) private _isArtist;
    //please dont change memory map, ONLY add
    IERC20 private bidtoken;
    address private auditorAddress;  
    address private bid;
    address private bonusPool;
    address private devPool;
    address private vbidpool;
    address private lastArtist;
    //====1.0 above=====
    address public artistMastercopy;

    function isArtist(address b)
        external view returns (bool)
    {
        return _isArtist[b];
    }

    //called by artist account
    function newArtist(string calldata _name,string calldata _symbol)
        external
    {
        SimpleProxy proxy = new SimpleProxy(artistMastercopy);
        
        IArtistSetup iProxy=IArtistSetup(address(proxy));
        (bool success, ) = address(proxy).call(abi.encodeWithSelector(iProxy.setup_constructor.selector, 
        _name,_symbol,msg.sender,auditorAddress,bid,bonusPool,devPool,vbidpool));
        require(success, "CALL: artist init fail");
        
        _isArtist[address(proxy)] = true;

        bidtoken.approve(address(proxy),1000000*1e18);

        emit LOG_NEW_ARTIST(msg.sender, address(proxy));

        lastArtist=address(proxy);
    }
    
    constructor() public {
        //no use
        _admin=address(1);
    }

    function setup_constructor(address _owner,address _bid,address _auditor,address _bonusPool,address _devPool,address _am,address _vbid) external {
        require(address(0) == vbidpool, "already init!!!!");
        bid=_bid;
        auditorAddress=_auditor;
        _admin = _owner;
        bidtoken=IERC20(bid);
        bonusPool=_bonusPool;
        devPool=_devPool;
        artistMastercopy=_am;
        vbidpool=_vbid;
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
    
    function rescueBid(address _moneyback) external {
        require(msg.sender == _admin, "ERR_NOT_ADMIN");
        bidtoken.transfer(_moneyback, bidtoken.balanceOf(address(this)));
   }



}

// contract Util{

//      address private constant _bonusPool=0x9B893781Ee099ea1d3831336cD38F91AF2c5f36c;
//      address private constant _devPool=0xd979F42b2FF6151aD32C8F96BBceE68D1F8Eef92;
//      address private constant _bid=0x00000000000045166C45aF0FC6E4Cf31D9E14B9A;
     
     
//     function createFactoryProxy(address _factoryMastercopy,address _artistMastercopy,address _auditor)
//         external
//     {
        
//         SimpleProxy proxy = new SimpleProxy(_factoryMastercopy);
        
//         IArtistFactory iProxy=IArtistFactory(address(proxy));
//         (bool success, ) = address(proxy).call(abi.encodeWithSelector(iProxy.setup_constructor.selector,
//         msg.sender,_bid,_auditor,_bonusPool,_devPool,_artistMastercopy));
//         require(success, "CALL: low-level factory init failed");
//     }
// }

pragma solidity ^0.5.16;

//EIP-1967 compatible
contract SimpleProxy {

    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    constructor(address _masterCopy)
        public
    {
        require(_masterCopy != address(0), "BID:Zero master is not permitted");
        address admin;
        admin = msg.sender;
        assembly {
            sstore(_IMPLEMENTATION_SLOT, _masterCopy)
            sstore(_ADMIN_SLOT, admin)
        }

    }

    

    function setMaster(address _masterCopy) external{
        address owner;
        assembly {
            owner := sload(_ADMIN_SLOT)
        }
        require(msg.sender==owner, "not controller");
        assembly {
            sstore(_IMPLEMENTATION_SLOT, _masterCopy)
        }
    }

    function ()
        external
        payable
    {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let masterCopy := and(sload(_IMPLEMENTATION_SLOT), 0xffffffffffffffffffffffffffffffffffffffff)
            calldatacopy(0, 0, calldatasize())
            let success := delegatecall(gas, masterCopy, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            if eq(success, 0) { revert(0, returndatasize()) }
            return(0, returndatasize())
        }
    }



}