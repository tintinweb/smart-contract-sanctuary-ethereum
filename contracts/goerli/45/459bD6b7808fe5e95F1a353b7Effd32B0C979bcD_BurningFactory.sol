// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;

/**
 * BurningFactory is the contract for management of ZUSD/GYEN.
 */
contract BurningFactory {
    address public manager;
    address public burner;
    address public logic;
    uint256 public icnt = 0;

    event BurnerChanged(address indexed oldBurner, address indexed newBurner, address indexed sender);
    event Deployed(address indexed burning, address indexed sender);
    event Deploysed(address[] burnings, address indexed sender);

    constructor(address _manager, address _burner, address _logic) public {
        require(_manager != address(0), "_manager is the zero address");
        require(_burner != address(0), "_burner is the zero address");
        manager = _manager;
        burner = _burner;
        logic = _logic;

        emit BurnerChanged(address(0), burner, msg.sender);
    }

    modifier onlyBurner() {
        require(msg.sender == burner, "the sender is not the burner");
        _;
    }

    modifier onlyManager() {
        require(msg.sender == manager, "the sender is not the manager");
        _;
    }

  function createClone() private returns (address result) {
        /*
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            result := create(0, clone, 0x37)
        }
        */
        address implementation = logic;
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            result := create(0, ptr, 0x37)
        }
    }

    function deployBatch(uint256 instanceAmount) public onlyBurner {
        address[] memory dsts  = new address[](instanceAmount);
        for(uint256 i=0; i< instanceAmount; i++) {
            address burning = createClone();
            dsts[i] = burning;
        }

        emit Deploysed(dsts, msg.sender);
    }

    function deploy() public onlyBurner {
        address burning = createClone();
        emit Deployed(address(burning), msg.sender);
    }

    function changeBurner(address _account) public onlyManager {
        require(_account != address(0), "this account is the zero address");

        address old = burner;
        burner = _account;
        emit BurnerChanged(old, burner, msg.sender);
    }
}