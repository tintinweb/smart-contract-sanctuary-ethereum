// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.13;

import { IsController } from "../../registration/resolver/IsController.sol";
import { IRegistrar } from "../../registration/registrar/IRegistrar.sol";


error NotAuthorized(address sender, address authorized);

interface IResolverWithControl {

    function setInformation(bytes32 key, address votingContract, uint256 amount) external;

    function changeRegistrarControlledKeys(bytes32 key, bool onlyRegistrar) external;
}


contract ResolverWithControl is 
IResolverWithControl,
IsController
{

    mapping(bytes32=>mapping(address=>uint256)) internal _lookup;
    mapping(bytes32=>bool) internal _onlyRegistrar;
    // mapping(address=>mapping(bytes32=>uint256))) internal _reverseLookup;

    constructor() IsController(msg.sender){}

    function getInformation(string memory key, address votingContract) 
    public view 
    returns(uint256)
    {
        return getInformation(keccak256(abi.encode(key)), votingContract);
    }

    function getInformation(bytes32 key, address votingContract) 
    public view 
    returns(uint256)
    {
        return _lookup[key][votingContract];
    }

    function setInformation(bytes32 key, address votingContract, uint256 amount)
    external 
    override(IResolverWithControl)
    OnlyAuthorized(key, votingContract)
    {
        _lookup[key][votingContract] = amount;
    }

    function changeRegistrarControlledKeys(bytes32 key, bool onlyRegistrar) 
    external
    override(IResolverWithControl)
    OnlyRegistrar
    {
        _onlyRegistrar[key] = onlyRegistrar;
    }

    modifier OnlyAuthorized(bytes32 key, address votingContract) {
        address authorized = _onlyRegistrar[key] ? address(registrar) : registrar.getController(votingContract);
        if (msg.sender!=authorized){
            revert NotAuthorized(msg.sender, authorized);
        }
        _;
    }

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.13;

import {IRegistrar} from "../registrar/IRegistrar.sol";
    
error IsNotController(address sender, address votingContract);
error IsNotRegistrar(address sender, address registrar);


abstract contract IsController {
    IRegistrar internal registrar;

    constructor(address _registrar){
        registrar = IRegistrar(_registrar);
    }

    function setRegistrar(address _registrar)
    external
    OnlyRegistrar
    {
        registrar = IRegistrar(_registrar);
    }

    function _senderIsController(address votingContract) internal view returns (bool isRegistrarController){
        isRegistrarController = registrar.getController(votingContract)==msg.sender;
    } 

    modifier senderIsController(address votingContract) {
        if(!_senderIsController(votingContract)){
            revert IsNotController(msg.sender, votingContract);
        }
        _;
    }

    modifier OnlyRegistrar() {
        if(msg.sender!=address(registrar)){
            revert IsNotRegistrar(msg.sender, address(registrar));
        }
        _;
    }

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.13;

interface IRegistrarPrimitive {
    function register(address votingContract, address resolver, address controller) external;
    function getController(address votingContract) external view returns(address controller);
}

interface IRegistrar is IRegistrarPrimitive {
    function register(address votingContract, address resolver, address controller) external override(IRegistrarPrimitive);
    function getController(address votingContract) external view override(IRegistrarPrimitive) returns(address controller);
    function changeResolver(address votingContract, address newResolver) external;
}