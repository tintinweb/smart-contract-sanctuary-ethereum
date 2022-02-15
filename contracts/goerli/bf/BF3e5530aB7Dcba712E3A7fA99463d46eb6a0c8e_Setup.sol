// Challenge name: Counterfactual
// Author: Throttle (@_no_handlebars)


pragma solidity 0.8.4;

import "./Factory.sol";
import "./Challenge.sol";

contract Setup {
    event Deployed(address);

    Factory public factory;
    Challenge public challenge;

    constructor() {
        factory = new Factory();
        challenge = new Challenge(address(factory));
        emit Deployed(address(challenge));
    }

    function isSolved() external view returns (bool) {
        return challenge.isSolved();
    }
}

pragma solidity 0.8.4;

contract Factory {
    function createContract(bytes memory bytecode, uint salt) public returns (bool) {
        address addr;
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        require(isForbidden(addr), "Only Forbidden Contracts");
        require(isFunded(addr), "Only Funded Contracts");
        return true;
    }

    function isForbidden(address _addr) internal view returns (bool) {
        bytes20 addr = bytes20(_addr);
        bytes20 id   = hex"00000000000000000000000000000000000f0b1d";
        bytes20 mask = hex"00000000000000000000000000000000000fffff";

        for (uint256 i; i != 30; ++i) {
            if (addr & mask == id) {
                return true;
            }
            mask <<= 4;
            id <<= 4;
        }

        return false;
    }

    function isFunded(address _addr) internal view returns (bool) {
        return _addr.balance >= 0.1 ether;
    }
}

pragma solidity 0.8.4;


interface IFactory {
    function createContract(bytes memory bytecode, uint salt) external returns (bool);
}

contract Challenge {
    bool public isSolved;
    IFactory factory;

    constructor(address _factory) {
        factory = IFactory(_factory);
    }

    function createContract(bytes memory bytecode, uint salt) public {
        isSolved = factory.createContract(bytecode, salt);
    }
}