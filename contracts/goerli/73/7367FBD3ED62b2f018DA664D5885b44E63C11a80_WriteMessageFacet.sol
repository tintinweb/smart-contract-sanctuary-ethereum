// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.15;

import "./MessageLib.sol";

contract WriteMessageFacet {

    function setMessage(MessageLib.Circuit calldata _circuit) external {
        MessageLib.setMessage(_circuit);
    }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.15;

library MessageLib{

    bytes32 internal constant NAMESPACE = keccak256("wtf.lib.message");
    struct Circuit{
        uint256 id;
        string name;
    }

    function getStorage() internal pure returns (Circuit storage s){
        bytes32 position = NAMESPACE;
        assembly {
            s.slot := position
        }
    }

    function setMessage(Circuit calldata _circuit) internal{
        Circuit storage s = getStorage();
        s.id = _circuit.id;
        s.name = _circuit.name;
    }

    function getMessage() internal view returns (uint256 _id, string memory){
        return (getStorage().id, getStorage().name);
    }

}