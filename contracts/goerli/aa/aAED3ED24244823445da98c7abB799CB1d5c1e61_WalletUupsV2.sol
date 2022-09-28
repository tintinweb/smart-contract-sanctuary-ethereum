// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import './Proxiable.sol';

contract WalletUupsV2 is Proxiable {
    address private owner;
    uint public cash;
    bool public initialized = false;

    modifier onlyOnwer() {
        require(msg.sender == owner, "Permission Denied");
        _;
    }

    modifier notInitialised(){
        require(!initialized, "Permission Denied");
        _;
    }

    function add(uint _cash) public {
        cash += _cash;
    }

    function sub(uint _cash) public {
        cash += _cash;
    }

    function upgrateTo(address _implementation) public onlyOnwer{
        _upgrateTo(_implementation);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

contract Proxiable {
    // Code position in storage is keccak256("PROXIABLE") = "0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7"
    
    function _upgrateTo(address _implementation) internal {
         require(
            bytes32(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7) == Proxiable(_implementation).proxiableUUID(),
            "Not compatible"
        );
        assembly {
            sstore(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7, _implementation)
        }
    }

    function proxiableUUID() public pure returns (bytes32) {
        return 0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7;
    }
}