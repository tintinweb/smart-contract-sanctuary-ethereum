/**
 *Submitted for verification at Etherscan.io on 2023-03-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

abstract contract Governance {

    address _governance;

    constructor() {
        _governance = tx.origin;
    }

    event GovernanceTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyGovernance {
        require(msg.sender == _governance, "not governance");
        _;
    }

    function setGovernance(address governance)  public  onlyGovernance
    {
        require(governance != address(0), "new governance the zero address");
        emit GovernanceTransferred(_governance, governance);
        _governance = governance;
    }
}

interface ILand {
    function setGovernance(address governance) external;
}

contract GoverBlock is Governance{
   
    address public pfpkey_contract =  address(0x0);
    address public factory_contract = address(0x0);

    mapping(uint256 => address) public _minters;
    mapping(uint256 => address) public keyidmeta;
    mapping(address => uint256) public meta_id;

    event NewMetaRecord(
        address metaaddress,
        uint256 keyid
    );

    event setMetaAdmin(
        address landaddress,
        address adminaddr
    );

    function newmeta(address metaaddress, uint256 key_tokenid) external 
    {
          if( factory_contract == msg.sender)
          {
            keyidmeta[key_tokenid] =  metaaddress;
            meta_id[metaaddress] = key_tokenid;
            emit NewMetaRecord( metaaddress, key_tokenid );
          }
    }

    function postTransfer(uint256 tokenid, address owner) external 
    {
        if( pfpkey_contract == msg.sender)
        {
            address meta_addr = keyidmeta[tokenid];
            ILand _land = ILand( meta_addr);
            _land.setGovernance( owner );
            emit setMetaAdmin( meta_addr, owner);
        }
    }
    
    function setFactoryContract(address _factoryaddr) public onlyGovernance {
        factory_contract = _factoryaddr;
    }

    function setPFPContract(address _pfpaddr) public onlyGovernance {
        pfpkey_contract = _pfpaddr;
    }


}