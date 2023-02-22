//SPDX-License-Identifier: GPL-3.0

/*_____________________________________________________________________________________________*/
//   ________  ________  _________  ________  ________  ________  ___  ________  _________     /
//  |\   __  \|\   __  \|\___   ___\\   ____\|\   ____\|\   __  \|\  \|\   __  \|\___   ___\   /
//  \ \  \|\  \ \  \|\  \|___ \  \_\ \  \___|\ \  \___|\ \  \|\  \ \  \ \  \|\  \|___ \  \_|   /
//   \ \   __  \ \   _  _\   \ \  \ \ \_____  \ \  \    \ \   _  _\ \  \ \   ____\   \ \  \    /
//    \ \  \ \  \ \  \\  \|   \ \  \ \|____|\  \ \  \____\ \  \\  \\ \  \ \  \___|    \ \  \   /
//     \ \__\ \__\ \__\\ _\    \ \__\  ____\_\  \ \_______\ \__\\ _\\ \__\ \__\        \ \__\  /
//      \|__|\|__|\|__|\|__|    \|__| |\_________\|_______|\|__|\|__|\|__|\|__|         \|__|  /
//                                    \|_________|                                             /
/*_____________________________________________________________________________________________*/

pragma solidity 0.8.16;

contract Proxy {

    //address where the proxy will make the delegatecall
    bytes32 private constant logic_contract = keccak256("artscript.proxy.logic");
    bytes32 private constant proxy_owner = keccak256("artscript.proxy.owner");

    event LogicContractChange(address _newImplementation);
    event OwnerChange(address _newOwner);

    modifier onlyProxyOwner {
        require(proxyOwner() == msg.sender, "you're not the proxy owner");
        _;
    }

    constructor(address _logic_contract, bytes32 _seed, address _metadataServer) {
        bytes32 position = proxy_owner;
        address admin = msg.sender;
        assembly{
            sstore(position, admin)
        }
        position = logic_contract;
        assembly{
            sstore(position, _logic_contract)
        }
       (bool success, ) = _logic_contract.delegatecall(abi.encodeWithSignature("initialize(address,bytes32)", _metadataServer, _seed));
       require(success, "initialize failed");
    }

    fallback () external payable {
        _fallback();
    }

    receive () external payable {
        _fallback();
    }

    /**
     * @notice Function to change the logic contract.
     * @param _logicAddress New logic contract address.
     */
    function setLogicContract(address _logicAddress) external onlyProxyOwner {   
        bytes32 position = logic_contract;   
        assembly {
            sstore(position, _logicAddress)
        } 
        emit LogicContractChange(_logicAddress);
    } 

    /**
     * @notice Function to set the admin of the contract.
     * @param _newOwner New admin of the contract.
     */
    function setProxyOwner(address _newOwner) external onlyProxyOwner  {
        bytes32 position = proxy_owner;   
        assembly {
            sstore(position, _newOwner)
        } 
        emit OwnerChange(_newOwner);
    }
    
    /**
     * @notice Getter for the logic contract address
     */
    function implementation() public view returns(address impl) {   
        bytes32 position = logic_contract;   
        assembly {
            impl := sload(position)
        } 
    } 
    
    /**
     * @notice Getter for the proxy admin address
     */
    function proxyOwner() public view returns(address admin) {   
        bytes32 position = proxy_owner;   
        assembly {
            admin := sload(position)
        } 
    }

    function _fallback() internal {
        bytes32 position = logic_contract;
        assembly {
          let _target := sload(position)
          calldatacopy(0x0, 0x0, calldatasize())
          let result := delegatecall(gas(), _target, 0x0, calldatasize(), 0x0, 0)
          returndatacopy(0x0, 0x0, returndatasize())
          switch result 
          case 0 {revert(0, returndatasize())} 
          default {return (0, returndatasize())}
        }
    }
    
}