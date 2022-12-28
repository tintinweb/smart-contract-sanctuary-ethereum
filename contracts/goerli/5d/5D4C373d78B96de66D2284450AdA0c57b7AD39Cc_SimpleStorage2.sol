// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;    // version of solidity  
 // if we put a ^ before version, we are actually saying hey any version above and including the specified version are a par of contract

import "./SimpleStorage.sol";

contract SimpleStorage2 is SimpleStorage{
    // in order to make this function being overriden by its child contract, it is required
    // to make it as virtual
    function addEdge(uint256 src, uint256 dest) public override {
        edges.push(Edge(src, dest));
        edgeCt+=1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;    // version of solidity  
 // if we put a ^ before version, we are actually saying hey any version above and including the specified version are a par of contract

struct Edge {
    uint256 src;
    uint256 dest;
}

contract SimpleStorage {
    uint256 a = 69;  // unsigned int
    // if variabe is not initialized then it gets a default value which is a NULL value
    uint b;  // b will have NULL value
    string voice = "meow";
    address myAdress = 0xc15BB2baF07342aad4d311D0bBF2cEaf78ff2930;
    bytes32 myByte = "cat";

    uint256 private num;

    function setter(uint256 value) public {
        num = value;
    }

    function getter() public view returns(uint256) {
        return num;
    }

    struct Node {
        int nbr;
        int wt;
        string path;
    }
    

    uint256 internal edgeCt=0;
    Edge[] public edges;


    // in order to make this function being overriden by its child contract, it is required
    // to make it as virtual
    function addEdge(uint256 src, uint256 dest) public virtual {
        edges.push(Edge(src, dest));
        edges.push(Edge(dest, src));
        edgeCt+=1;
    }
    function TotalEdges() public view returns(uint256) {
        return edgeCt;
    }

    function readIthEdge(uint256 N) public view returns(Edge memory) {
        return edges[N];
    }


    //Node public node = Node ({wt:2, path:"123", nbr:3});
}

// contract myPractice {
//     mapping(int => int) public mp;

// }


// 0xd9145CCE52D386f254917e481eB44e9943F39138