/**
 *Submitted for verification at Etherscan.io on 2022-12-10
*/

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ICPO {
    function implementations(string memory) external view returns (address);
}

interface IDestroyable {
    function destroy() external;
}

/*

// https://forum.openzeppelin.com/t/a-more-gas-efficient-upgradeable-proxy-by-not-using-storage/4111/
// Not using SLOAD for implementation retrieval

This is an upgrade on the original implementation listed above. This helps shave off even more gas by
removing the need for a "Beacon" and extracing out the immutable address.

Upgradable control flow:
1. CPO --create2--> Proxy
2. On creation, Proxy gets the implementation from CPO and writes impl address into immutable variable
    - Immutable variable is stored at contract code offset 376
    - Compiled with solc 0.8.10, optimization runs: (?) depends on forge
3. To upgrade, destroy the proxy and recreate it with the same salt

*/

contract Proxy {
    address public immutable logic;
    address public immutable cpo;

    // If you ever change this file
    // Or recompile with a new compiler, this offset will probably be different
    // Run test_get_offset() with 3 verbosity to get the offset
    uint256 internal constant offset = 441;

    constructor(address _cpo, string memory _name) {
        cpo = _cpo;
        logic = ICPO(_cpo).implementations(_name);
    }

    function destroy() public {
        require(msg.sender == cpo, "shoo");

        address _addr = payable(cpo);
        assembly {
            selfdestruct(_addr)
        }
    }

    receive() external payable {}

    fallback() external payable {
        assembly {
            // Extract out immutable variable "logic"
            codecopy(0, offset, 20)
            let impl := mload(0)

            switch iszero(impl)
            case 1 {
                revert(0, 0)
            }
            default {

            }

            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(
                gas(),
                shr(96, impl),
                0,
                calldatasize(),
                0,
                0
            )
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}

contract CPO {
    // **** State variables ****

    address public owner;

    mapping(string => address) public implementations;
    mapping(string => address) public proxies;

    // **** Events ****

    event ProxyDeployed(address addr, bytes32 salt, address logic);

    // **** Constructor + Modifiers **** //

    receive() external payable {}

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    // **** Public functions ****

    function proxyCreationCode(string memory name)
        public
        view
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                // type(Proxy).creationCode,
                hex"60c060405234801561001057600080fd5b5060405161072a38038061072a833981810160405281019061003291906102f6565b8173ffffffffffffffffffffffffffffffffffffffff1660a08173ffffffffffffffffffffffffffffffffffffffff16815250508173ffffffffffffffffffffffffffffffffffffffff16630618f104826040518263ffffffff1660e01b815260040161009f91906103a7565b602060405180830381865afa1580156100bc573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906100e091906103c9565b73ffffffffffffffffffffffffffffffffffffffff1660808173ffffffffffffffffffffffffffffffffffffffff168152505050506103f6565b6000604051905090565b600080fd5b600080fd5b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b60006101598261012e565b9050919050565b6101698161014e565b811461017457600080fd5b50565b60008151905061018681610160565b92915050565b600080fd5b600080fd5b6000601f19601f8301169050919050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052604160045260246000fd5b6101df82610196565b810181811067ffffffffffffffff821117156101fe576101fd6101a7565b5b80604052505050565b600061021161011a565b905061021d82826101d6565b919050565b600067ffffffffffffffff82111561023d5761023c6101a7565b5b61024682610196565b9050602081019050919050565b60005b83811015610271578082015181840152602081019050610256565b83811115610280576000848401525b50505050565b600061029961029484610222565b610207565b9050828152602081018484840111156102b5576102b4610191565b5b6102c0848285610253565b509392505050565b600082601f8301126102dd576102dc61018c565b5b81516102ed848260208601610286565b91505092915050565b6000806040838503121561030d5761030c610124565b5b600061031b85828601610177565b925050602083015167ffffffffffffffff81111561033c5761033b610129565b5b610348858286016102c8565b9150509250929050565b600081519050919050565b600082825260208201905092915050565b600061037982610352565b610383818561035d565b9350610393818560208601610253565b61039c81610196565b840191505092915050565b600060208201905081810360008301526103c1818461036e565b905092915050565b6000602082840312156103df576103de610124565b5b60006103ed84828501610177565b91505092915050565b60805160a0516103026104286000396000818160f70152818161018701526101d1015260006101ad01526103026000f3fe6080604052600436106100385760003560e01c806383197ef014610088578063d7dfa0dd1461009f578063f3a50f89146100ca5761003f565b3661003f57005b60146101b96000396000518015600181146100595761005e565b600080fd5b5036600080376000803660008460601c5af43d6000803e8060008114610083573d6000f35b3d6000fd5b34801561009457600080fd5b5061009d6100f5565b005b3480156100ab57600080fd5b506100b46101ab565b6040516100c19190610234565b60405180910390f35b3480156100d657600080fd5b506100df6101cf565b6040516100ec9190610234565b60405180910390f35b7f000000000000000000000000000000000000000000000000000000000000000073ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff1614610183576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161017a906102ac565b60405180910390fd5b60007f0000000000000000000000000000000000000000000000000000000000000000905080ff5b7f000000000000000000000000000000000000000000000000000000000000000081565b7f000000000000000000000000000000000000000000000000000000000000000081565b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b600061021e826101f3565b9050919050565b61022e81610213565b82525050565b60006020820190506102496000830184610225565b92915050565b600082825260208201905092915050565b7f73686f6f00000000000000000000000000000000000000000000000000000000600082015250565b600061029660048361024f565b91506102a182610260565b602082019050919050565b600060208201905081810360008301526102c581610289565b905091905056fea2646970667358221220b4f3dfa57797c7ace04ab12b59deeef762aa067debba1b2ce7e71677c10ae92864736f6c634300080a0033",
                abi.encode(address(this), name)
            );
    }

    function proxyInitCodeHash(string memory name)
        public
        view
        returns (bytes32)
    {
        return keccak256(proxyCreationCode(name));
    }

    // **** Restricted functions ****

    function createProxy(
        string memory name,
        bytes32 salt,
        address impl
    ) public onlyOwner returns (address) {
        require(proxies[name] == address(0), "Proxy not destroyed yet");

        // Since proxy reads implementation address from this contract
        // we need to mutate the impl state first
        implementations[name] = impl;

        address deployed;
        bytes memory bytecode = proxyCreationCode(name);
        assembly {
            deployed := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(deployed != address(0), "create2 failed");
        proxies[name] = deployed;

        emit ProxyDeployed(deployed, salt, implementations[name]);
        return deployed;
    }

    function destroyProxy(string memory name) public onlyOwner {
        require(proxies[name] != address(0), "Proxy doesn't exist");

        IDestroyable(proxies[name]).destroy();
        proxies[name] = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        owner = newOwner;
    }
}