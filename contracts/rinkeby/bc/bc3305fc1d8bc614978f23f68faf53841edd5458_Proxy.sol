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
        address _impl = delegate;
        require(_impl != address(0));

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 {
                revert(ptr, size)
            }
            default {
                return(ptr, size)
            }
        }
    }
}