/**
 *Submitted for verification at Etherscan.io on 2022-12-14
*/

/** 
 *  SourceUnit: /Users/kuldeep/ETHEREUM/test/contracts/test.sol
*/

pragma solidity ^0.8.15;

struct Data {
    address owner;
    uint112 timestamp;
    bool v7;
    bool v8;
    address v4;
    address v3;
    uint256 v5;
    uint256 v6;
    string v1;
    string v2;
}

contract Gamma {
    Alpha public a;
    uint256 public value;

    Data public dataG;

    modifier checkB() {
        require(msg.sender == address(a.b()));
        _;
    }

    function setA(Alpha _a) public {
        a = _a;
    }

    function set(uint256 n) public checkB {
        value = n;
        a.set();
    }

    function setData(Data calldata _d) external {
        dataG = _d;
    }
}

contract Beta {
    Gamma public g;
    string public name;
    Data public dataB;

    modifier checkA() {
        require(msg.sender == address(g.a()));
        _;
    }

    function setG(Gamma _g) public {
        g = _g;
    }

    function set(string memory n) public checkA {
        name = n;
        g.set(100);
    }

    function setData(Data calldata _d) external {
        dataB = _d;
    }
}

contract Alpha {
    Beta public b;
    bool public flag;
    Data public dataA;

    modifier checkG() {
        require(msg.sender == address(b.g()));
        _;
    }

    function setB(Beta _b) public {
        b = _b;
    }

    function start() public {
        b.set("updated by Alpha");
    }

    function set() public checkG {
        flag = true;
    }

    function getter()
        public
        view
        returns (
            string memory,
            uint256,
            bool
        )
    {
        address g = address(b.g());
        return (b.name(), Gamma(g).value(), flag);
    }

    function setData(Data calldata _d) external {
        dataA = _d;
    }

    function transfer() public {
        b.setData(dataA);
        Gamma(b.g()).setData(dataA);
    }
}