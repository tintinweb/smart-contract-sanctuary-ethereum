/**
 *Submitted for verification at Etherscan.io on 2022-02-23
*/

// File: NameRegistry.sol


pragma solidity ^0.8.12;

contract NameRegistry {
    mapping(address => string) public names;

    function getName(address proxy) external view returns (string memory) {
        return names[proxy];
    }

    function setName(address proxy, string memory name) external {
        names[proxy] = name;
    }
}
// File: ProxyDelegate.sol


pragma solidity ^0.8.12;


contract Proxy {
    address public delegate;
    address public owner = msg.sender;

    NameRegistry public nameRegistry;

    error OnlyOwner();

    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwner();
        _;
    }

    constructor(string memory name, address delegate_, address nameRegistry_) {
        delegate = delegate_;
        nameRegistry = NameRegistry(nameRegistry_);
        nameRegistry.setName(address(this), name);
    }

    function upgradeDelegate(address newDelegateAddress) public onlyOwner {
        delegate = newDelegateAddress;
    }

    function name() external view returns (string memory) {
        return nameRegistry.getName(address(this));
    }

    fallback() external payable {
        assembly {
            let _target := sload(0)
            calldatacopy(0x0, 0x0, calldatasize())
            let result := delegatecall(gas(), _target, 0x0, calldatasize(), 0x0, 0)
            returndatacopy(0x0, 0x0, returndatasize())
            switch result
            case 0 {
                revert(0, 0)
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}