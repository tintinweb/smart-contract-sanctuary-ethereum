/**
 *Submitted for verification at Etherscan.io on 2023-02-14
*/

// File: contracts/finalContract2.sol


pragma solidity 0.8.17;

contract finalContract2 {
    string public name2 = "finnal contract2";
    event KillFinal2();

    function kill2() public {
        emit KillFinal2();
        selfdestruct(payable(msg.sender));
    }
}

// File: contracts/finalContract1.sol


pragma solidity 0.8.17;

contract finalContract1 {
    string public name1 = "finnal contract1";
    event KillFinal1();

    function kill1() public {
        emit KillFinal1();
        selfdestruct(payable(msg.sender));
    }
}

// File: contracts/CreateFactory.sol


pragma solidity 0.8.17;



contract Create1Factory {
    string public name = "Create1Factory";
    event Create1(address create1contract);
    event KillCreate1();

    string public name1 = "Create1Factory";

    function create1(bytes memory code) public {
        address create1contract;
        assembly {
            create1contract := create(0, add(code, 0x20), mload(code))
        }
        emit Create1(create1contract);
    }

    function kill() public {
        emit KillCreate1();
        selfdestruct(payable(msg.sender));
    }
}

contract Create2Factory {
    event Create2(address create2contract);
    string public name = "Create2Factory";

    function code1() public pure returns (bytes memory) {
        return type(finalContract1).creationCode;
    }

    function code2() public pure returns (bytes memory) {
        return type(finalContract2).creationCode;
    }

    function create2(uint256 _salt) public {
        address create2contract;
        bytes32 salt = keccak256(abi.encode(_salt));
        bytes memory code = type(Create1Factory).creationCode;
        assembly {
            create2contract := create2(0, add(code, 0x20), mload(code), salt)
        }
        emit Create2(create2contract);
    }
}