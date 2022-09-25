//SPDX-License-Identifier: GPL-3.0

/*MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM*/
/*MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM*/
/*MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNNXXXXKKKKKKKKKKKKXXXNNNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM*/
/*MMMMMMMMMMMMMMMMMMMMMMMMMMMMWNK0kdolc:;,,'''.............'''',;;:clodk0KNWMMMMMMMMMMMMMMMMMMMMMMMMMM*/
/*MMMMMMMMMMMMMMMMMMMMMMMWN0xo:,...                                    ...,:lx0XWMMMMMMMMMMMMMMMMMMMMM*/
/*MMMMMMMMMMMMMMMMMMMMWKxc,..                                                ..'cd0NMMMMMMMMMMMMMMMMMM*/
/*MMMMMMMMMMMMMMMMMWKx:..                                                        ..;o0NMMMMMMMMMMMMMMM*/
/*MMMMMMMMMMMMMMMW0l'.                                                              ..:kXMMMMMMMMMMMMM*/
/*MMMMMMMMMMMMMW0c..                                                                   .;xNMMMMMMMMMMM*/
/*MMMMMMMMMMMMXo.                                       ,:.                              .:OWMMMMMMMMM*/
/*MMMMMMMMMMWO;.                                      .,ONx'                               .oXMMMMMMMM*/
/*MMMMMMMMMNd.                                     ..'lKWMWOc.                              .cKMMMMMMM*/
/*MMMMMMMMNo.                                    .:dOKWMMMMMW0o;.                            .;0MMMMMM*/
/*MMMMMMMNo.                                     .ck0XMMMMMMWKx:.                             .;0MMMMM*/
/*MMMMMMWd.                                      . ..,dXMMMKo'.                                .cXMMMM*/
/*MMMMMWk'                                     .,l;.  .:KWO,.                                   .dNMMM*/
/*MMMMMX:.                                   .'oKWXdc,..;o'                                      ,OMMM*/
/*MMMMWx.                                    ..c0WKl;'. ..                                       .lNMM*/
/*MMMMX:.                                       'c,.                                              ,0MM*/
/*MMMMO'                                                                                          .xWM*/
/*MMMWd.                                                                                          .lNM*/
/*MMMNc.                       .:dddddddddddddddo:.            .cdddddl'.                          :XM*/
/*MMMK;                        .lXMMMMMMMMMMMMMMXc.            .:0MMMXl.                           ;KM*/
/*MMM0,                         .xWMMMMMMMMMMMMWx.              .;KMNl.                            ,0M*/
/*MMM0,                         .lNMMMMMMMMMMMMNl.               .oNk.                             'OM*/
/*MMMO'                         .cNMMMMMMMMMMMMXc.                cKo.                             'OM*/
/*MMMO'                         .cNMMMMMMMMMMMMXc.                :Ko.                             'kM*/
/*MMMO,                         .cNMMMMMMMMMMMMXc                 :Ko.                             .kM*/
/*MMM0,                         .cNMMMMMMMMMMMMXc.                :Ko.                             'kM*/
/*MMMK:                         .cNMMMMMMMMMMMMXc.                :Ko.                             'OM*/
/*MMMNl.                        .cNMMMMMMMMMMMMXc.                :Ko.                             ,0M*/
/*MMMWd.                        .cNMMMMMMMMMMMMXc.                :Ko.                             :XM*/
/*MMMM0,                        .cNMMMMMMMMMMMMXc.                :Ko.                            .lNM*/
/*MMMMNl.                       .cNMMMMMMMMMMMMXc                 :Ko.                            .xMM*/
/*MMMMMO,                       .cXMMMMMMMMMMMMNc.               .cKl.                            ;KMM*/
/*MMMMMNo.                       ;0MMMMMMMMMMMMWo.               .d0;                            .dWMM*/
/*MMMMMMXc.                      .dNMMMMMMMMMMMMO,               ;0x.                           .:KMMM*/
/*MMMMMMM0;.                      .xNMMMMMMMMMMMWx'            .;Ok,                            ,OWMMM*/
/*MMMMMMMM0:.                      .c0NMMMMMMMMMMW0l;,..   ...;dOd'                            'xWMMMM*/
/*MMMMMMMMMKc.                       .:dOKNWWMMMMMMWNX0kdddddxxl,.                            'xWMMMMM*/
/*MMMMMMMMMMNd'.                        ..,;:ccccccccccccc:;,..                             .;OWMMMMMM*/
/*MMMMMMMMMMMW0c.                                                                          .lKMMMMMMMM*/
/*MMMMMMMMMMMMMNk:.                                                                      .:ONMMMMMMMMM*/
/*MMMMMMMMMMMMMMMNOc'.                                                                 .:kNMMMMMMMMMMM*/
/*MMMMMMMMMMMMMMMMMWKx:'.                                                          ..;o0WMMMMMMMMMMMMM*/
/*MMMMMMMMMMMMMMMMMMMMWKko;'..                                                 ..':d0NMMMMMMMMMMMMMMMM*/
/*MMMMMMMMMMMMMMMMMMMMMMMMWXOxoc;'...                                   ...',:ox0XWMMMMMMMMMMMMMMMMMMM*/
/*MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXKOkxdollcc:::;;;;;;;;;;;;;;;;;::ccloodkO0XNWMMMMMMMMMMMMMMMMMMMMMMMM*/
/*MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWWWWNNNWWWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM*/
/*MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM*/

pragma solidity ^0.8.0;

contract Serials_Proxy {

    event LogicContractChanged(address _newImplementation);

    event AdminChanged(address _newAdmin);

    //address where the proxy will make the delegatecall
    bytes32 private constant logic_contract = keccak256("proxy.logic");
    
    bytes32 private constant proxy_admin = keccak256("proxy.admin");
    

    constructor(address _logic_contract, string memory _metadata, bytes32 _ATseed, bytes32 _MLseed, string memory _contractURI) {
       bytes32 position = proxy_admin;
       address admin = msg.sender;
       assembly{
           sstore(position, admin)
       }
       position = logic_contract;
       assembly{
           sstore(position, _logic_contract)
       }
       (bool success, ) = _logic_contract.delegatecall(abi.encodeWithSignature("initialize(string,bytes32,bytes32,string)", _metadata, _ATseed, _MLseed, _contractURI));
         require(success, "initialize failed");
    }

    /**
     * @notice Function to change the logic contract.
     * @param _logicAddress New logic contract address.
     */
    function setLogicContract(address _logicAddress) public onlyProxyAdmin {   
        bytes32 position = logic_contract;   
        assembly {
            sstore(position, _logicAddress)
        } 
        emit LogicContractChanged(_logicAddress);
    } 

    /**
     * @notice Function to set the admin of the contract.
     * @param _newAdmin New admin of the contract.
     */
    function setProxyAdmin(address _newAdmin) public onlyProxyAdmin  {
        bytes32 position = proxy_admin;   
        assembly {
            sstore(position, _newAdmin)
        } 
        emit AdminChanged(_newAdmin);
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
    function proxyAdmin() public view returns(address admin) {   
        bytes32 position = proxy_admin;   
        assembly {
            admin := sload(position)
        } 
    }

    fallback() external payable {
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
    
    /**
    * @dev only the admin is allowed to call the functions that implement this modifier
    */
    modifier onlyProxyAdmin {
        require(proxyAdmin() == msg.sender, "you're not the proxy admin");
        _;
    }
    
}