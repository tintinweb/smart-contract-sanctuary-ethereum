//SPDX-License-Identifier: GPL-3.0

/********************************************************************/
/*        __             _,-"~^"-.                                  */
/*       _// )      _,-"~`         `.                               */
/*     ." ( /`"-,-"`                 ;                              */
/*    / 6                             ;                             */
/*   /           ,             ,-"     ;                            */
/*  (,__.--.      \           /        ;                            */
/*   //'   /`-.\   |          |        `._________                  */
/*     _.-'_/`  )  )--...,,,___\     \-----------,)                 */
/*   ((("~` _.-'.-'           __`-.   )         //                  */
/*         ((("`             (((---~"`         //                   */
/*                                            ((________________    */
/*                                            `----""""~~~~^^^```   */
/********************************************************************/

pragma solidity ^0.8.0;

contract Proxy {
    event LogicContractChanged(address _newImplementation);

    event AdminChanged(address _newAdmin);

    //address where the proxy will make the delegatecall
    bytes32 private constant logic_contract = keccak256("proxy.logic");

    bytes32 private constant proxy_admin = keccak256("proxy.admin");

    constructor(
        address _logic_contract,
        string memory _url,
        string memory _contractURI
    ) {
        bytes32 position = proxy_admin;
        address admin = msg.sender;
        assembly {
            sstore(position, admin)
        }
        position = logic_contract;
        assembly {
            sstore(position, _logic_contract)
        }
        (bool success, ) = _logic_contract.delegatecall(
            abi.encodeWithSignature(
                "initialize(string,string)",
                _url,
                _contractURI
            )
        );
        require(success, "Initialize failed");
    }

    /**
     * @dev Setters
     */
    function setLogicContract(address _logicAddress) public onlyProxyAdmin {
        bytes32 position = logic_contract;
        assembly {
            sstore(position, _logicAddress)
        }
        emit LogicContractChanged(_logicAddress);
    }

    function setProxyAdmin(address _newAdmin) public onlyProxyAdmin {
        bytes32 position = proxy_admin;
        assembly {
            sstore(position, _newAdmin)
        }
        emit AdminChanged(_newAdmin);
    }

    /**
     * @dev Getter for the logic contract address
     */
    function implementation() public view returns (address impl) {
        bytes32 position = logic_contract;
        assembly {
            impl := sload(position)
        }
    }

    /**
     * @dev Getter for the proxy admin address
     */
    function proxyAdmin() public view returns (address admin) {
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
            let result := delegatecall(
                gas(),
                _target,
                0x0,
                calldatasize(),
                0x0,
                0
            )
            returndatacopy(0x0, 0x0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev only the admin is allowed to call the functions that implement this modifier
     */
    modifier onlyProxyAdmin() {
        require(proxyAdmin() == msg.sender, "you're not the proxy admin");
        _;
    }
}