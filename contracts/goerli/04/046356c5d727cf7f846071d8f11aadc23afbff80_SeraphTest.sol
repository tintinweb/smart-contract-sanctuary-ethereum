// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <=0.9.0;

interface ISeraph {
    function checkEnter(address, bytes4, bytes calldata, uint256) external;
    function checkLeave(bytes4) external;
}

abstract contract SeraphProtected {

    ISeraph constant internal _seraph = ISeraph(0x5bAE40b37adA3385d4fF41Ec9973D7DF4Aa9B13C);

    modifier withSeraph() {
        _seraph.checkEnter(msg.sender, msg.sig, msg.data, 0);
        _;
        _seraph.checkLeave(msg.sig);
    }

    modifier withSeraphPayable() {
        _seraph.checkEnter(msg.sender, msg.sig, msg.data, msg.value);
        _;
        _seraph.checkLeave(msg.sig);
    }
}

contract SeraphTest is SeraphProtected{
 

    function setVars(address _contract) public withSeraph {
        (bool success, bytes memory data) = _contract.delegatecall(
            abi.encodeWithSignature("init()")
        );
    }
}