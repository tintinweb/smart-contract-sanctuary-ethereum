//SPDX-License-Identifier: GPL-3.0

//''''''''''''''''''''''''''''''''''''''',;cxKWMMMMMMMMWKdc;,''''''''''''''''''''''''''''''''''''''',dNMWO:'''''''';lONWWKxlccccccccccldKWWNOl;'''''''';
//'''''''''''''''''''''''''''''''''''''''''',cxXWMMMMMXx:,'''''''''''''''''''''''''''''''''''''''''',dNMMNOl,'''''''';lx0XKko:,'''',:okKX0xl;'''''''',lk
//'''''''''''''''''''''''''''''''''''''''''''',lKMMMMXo,'''''''''''''''''''''''''''''''''''''''''''''dNMMMMN0o;''''''''',cdOXXOdccdOXXOdc,''''''''';o0NM
//''''''''';:cccccccccccccccccccccc:;'''''''''',xNMMWO;'''''''''',::ccccccccccccccccccccccc:,''''''',dNMMMMMMWKd:'''''''''',:dOKXNWXxc,'''''''''':dKWMMM
//'''''''',dXNNNNNNNNNNNNNNNNNNNNNNXKx:'''''''''oNMMWk;'''''''';o0XNNNNNNNNNNNNNNNNNNNNNNNNKl''''''',dNMMMMMMMMWXxc,'''''''''',:okKX0xl;'''''''cxKWMMMMM
//'''''''',xWMMMMMMMMMMMMMMMMMMMMMMMMW0:''''''''oNMMWk;''''''''oNMMMMMMMMMMMMMMMMMMMMMMMMMMNo''''''',dNMMMMMMMMMMWNkl,'''''''''''';lx0XKkxdolokXWMMMMMMM
//'''''''',xWMMMMMMMMMMMMMMMMMMMMMMMMMXl''''''''oNMMWk;''''''',dWMMMMMMMMMMMMMMMMMMMMMMMMMMNo''''''',dNMMMMMMMMMMMMMNOo;'''''''''''''c0WMMMWWWMMMMMMMMMM
//'''''''',xWMMMMMMMMMMMMMMMMMMMMMMMMMNo''''''''oNMMWk;''''''',dWMMMMMMMMMMMMMMMMMMMMMMMMMMNo''''''',dNMMMMMMMMMMMMMMMW0o,'''''''''',dNMMMMMMMMMMMMMMMMM
//'''''''',xWMMMMMMMMMMMMMMMMMMMMMMMMMNo''''''''oNMMWk;''''''',dWMMMMMMMMMMMMMMMMMMMMMMMMMMNo''''''',dNMMMMMMMMMMMMMMMW0o,'''''''''',dNMMMMMMMMMMMMMMMMM
//'''''''',xWMMMMMMMMMMMMMMMMMMMMMMMMMNo''''''''oNMMWk;''''''',dWMMMMMMMMMMMMMMMMMMMMMMMMMMNo''''''',dNMMMMMMMMMMMMMNOo;'''''''''''''c0WMMMWWWMMMMMMMMMM
//'''''''',xWMMMMMMMMMMMMMMMMMMMMMMMMMNo''''''''oNMMWk;''''''',dWMMMMMMMMMMMMMMMMMMMMMMMMMMKc''''''',dNMMMMMMMMMMWXkl,'''''''''''';lx0XKkddoclkXWMMMMMMM
//'''''''',xWMMMMMMMMMMMMMMMMMMMMMMMMMNo''''''''oNMMWk;''''''''dXNNNNNNNNNNNNNNNNNNNNWNNNKOl,''''''',dNMMMMMMMMWXxc,'''''''''',:okKX0xl;'''''',:xKWMMMMM
//'''''''',xWMMMMMMMMMMMMMMMMMMMMMMMMMNo''''''''oNMMWk;'''''''';cccccccccccccccccccccccc:;,''''''''',dNMMMMMMWKd:'''''''''',:dOXXNWXxc,'''''''''':d0NMMM
//'''''''',xWMMMMMMMMMMMMMMMMMMMMMMMMMNo''''''''oNMMWk;''''''''''''''''''''''''''''''''''''''''''''';OWMMMMN0o;''''''''',cd0XKOdccoOKX0dc;''''''''';oONW
//'''''''',xWMMMMMMMMMMMMMMMMMMMMMMMMMNo''''''''oNMMWk;''''''''''''''''''''''''''''''''''''''''''',lONMMMNOl,'''''''';lx0XKko:,'''',:okKX0xl;'''''''',lk
//,''''''',kWMMMMMMMMMMMMMMMMMMMMMMMMMNo,'''''',dNMMWk;'''''''''''''''''''''''''''''''''''''''',:lkXWMMMWO:''''''',;oONWWKxlcccccccccclxKWMNOo;'''''''';

// ██████   ██████  ██     ██ ███████ ██████  ███████ ██████      ██████  ██    ██                       
// ██   ██ ██    ██ ██     ██ ██      ██   ██ ██      ██   ██     ██   ██  ██  ██                        
// ██████  ██    ██ ██  █  ██ █████   ██████  █████   ██   ██     ██████    ████                         
// ██      ██    ██ ██ ███ ██ ██      ██   ██ ██      ██   ██     ██   ██    ██                          
// ██       ██████   ███ ███  ███████ ██   ██ ███████ ██████      ██████     ██                          
                                                                                                  
// ██    ██ ███    ██ ██ ██    ██ ███████ ██████  ███████ ███████ ██      ██      ███████    ██  ██████  
// ██    ██ ████   ██ ██ ██    ██ ██      ██   ██ ██      ██      ██      ██      ██         ██ ██    ██ 
// ██    ██ ██ ██  ██ ██ ██    ██ █████   ██████  ███████ █████   ██      ██      █████      ██ ██    ██ 
// ██    ██ ██  ██ ██ ██  ██  ██  ██      ██   ██      ██ ██      ██      ██      ██         ██ ██    ██ 
//  ██████  ██   ████ ██   ████   ███████ ██   ██ ███████ ███████ ███████ ███████ ███████ ██ ██  ██████  


pragma solidity 0.8.12;

contract Uniques_Proxy {

    event LogicContractChanged(address _newImplementation);

    event AdminChanged(address _newAdmin);

    //address where the proxy will make the delegatecall
    bytes32 private constant logic_contract = keccak256("proxy.logic");
    
    bytes32 private constant proxy_admin = keccak256("proxy.admin");
    

    constructor(address _logic_contract, string memory _metadata, string memory _contractURI) {
       bytes32 position = proxy_admin;
       address admin = msg.sender;
       assembly{
           sstore(position, admin)
       }
       position = logic_contract;
       assembly{
           sstore(position, _logic_contract)
       }
        (bool success, ) = _logic_contract.delegatecall(abi.encodeWithSignature("initialize(string,string)", _metadata, _contractURI));
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