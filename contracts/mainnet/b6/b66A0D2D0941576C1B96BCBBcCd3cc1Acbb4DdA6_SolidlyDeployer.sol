// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;

interface IProxy {
    function initializeProxy(address) external;

    function updateImplementationAddress(address) external;

    function updateGovernanceAddress(address) external;

    function implementationAddress() external view returns (address);
}

/**
 * @title 0xDAO deployment bootstrapper
 * @author 0xDAO
 * @dev Rules:
 *      - Only owner 1 and owner 2 can deploy
 *      - New deployments are initialized with deployer contract being governance
 *      - Only owner 1 and 2 can set implementations and governance using deployer
 *      - Only owner 1 and owner 2 can update owner 1 and owner 2 addresses
 *      - Allows batch setting of governance on deployments
 */
contract SolidlyDeployer {
    address public owner1Address;
    address public owner2Address;
    address[] public deployedAddresses;

    constructor() {
        owner1Address = msg.sender;
        owner2Address = msg.sender;
    }

    modifier onlyOwners() {
        require(
            msg.sender == owner1Address || msg.sender == owner2Address,
            "Only owners"
        );
        _;
    }

    function setOwner1Address(address _owner1Address) external onlyOwners {
        owner1Address = _owner1Address;
    }

    function setOwner2Address(address _owner2Address) external onlyOwners {
        owner2Address = _owner2Address;
    }

    function deployedAddressesLength() external view returns (uint256) {
        return deployedAddresses.length;
    }

    function deployedAddressesList() external view returns (address[] memory) {
        return deployedAddresses;
    }

    function deploy(bytes memory code, uint256 salt) public onlyOwners {
        address addr;
        assembly {
            addr := create2(0, add(code, 0x20), mload(code), salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        IProxy(addr).initializeProxy(address(this));
        deployedAddresses.push(addr);
    }

    function deployMany(bytes memory code, uint256[] memory salts) public {
        for (uint256 saltIndex; saltIndex < salts.length; saltIndex++) {
            uint256 salt = salts[saltIndex];
            deploy(code, salt);
        }
    }

    function updateImplementationAddress(
        address _targetAddress,
        address _implementationAddress
    ) external onlyOwners {
        IProxy(_targetAddress).updateImplementationAddress(
            _implementationAddress
        );
    }

    function updateGovernanceAddress(
        address _targetAddress,
        address _governanceAddress
    ) public onlyOwners {
        IProxy(_targetAddress).updateGovernanceAddress(_governanceAddress);
    }

    function updateGovernanceAddressAll(address _governanceAddress)
        external
        onlyOwners
    {
        for (
            uint256 deployedIndex;
            deployedIndex < deployedAddresses.length;
            deployedIndex++
        ) {
            address targetAddress = deployedAddresses[deployedIndex];
            updateGovernanceAddress(targetAddress, _governanceAddress);
        }
    }

    function generateContractAddress(bytes memory bytecode, uint256 salt)
        public
        view
        returns (address)
    {
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(bytecode)
            )
        );
        return address(uint160(uint256(hash)));
    }

    enum Operation {
        Call,
        DelegateCall
    }

    function execute(
        address to,
        uint256 value,
        bytes calldata data,
        Operation operation
    ) external onlyOwners returns (bool success) {
        if (operation == Operation.Call) success = executeCall(to, value, data);
        else if (operation == Operation.DelegateCall)
            success = executeDelegateCall(to, data);
        require(success == true, "Transaction failed");
    }

    function executeCall(
        address to,
        uint256 value,
        bytes memory data
    ) internal returns (bool success) {
        assembly {
            success := call(
                gas(),
                to,
                value,
                add(data, 0x20),
                mload(data),
                0,
                0
            )
            let returnDataSize := returndatasize()
            returndatacopy(0, 0, returnDataSize)
            switch success
            case 0 {
                revert(0, returnDataSize)
            }
            default {
                return(0, returnDataSize)
            }
        }
    }

    function executeDelegateCall(address to, bytes memory data)
        internal
        returns (bool success)
    {
        assembly {
            success := delegatecall(
                gas(),
                to,
                add(data, 0x20),
                mload(data),
                0,
                0
            )
            let returnDataSize := returndatasize()
            returndatacopy(0, 0, returnDataSize)
            switch success
            case 0 {
                revert(0, returnDataSize)
            }
            default {
                return(0, returnDataSize)
            }
        }
    }
}