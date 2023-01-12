// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;   

contract HashFunction {
    function hash(
        string memory _text,
        uint _num,
        address _addr
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_text, _num, _addr));
    }

    // Example of hash collision
    // Hash collision can occur when you pass more than one dynamic data type
    // to abi.encodePacked. In such case, you should use abi.encode instead.
    function collision(
        string memory _text,
        string memory _anotherText
    ) public pure returns (bytes32) {
        // encodePacked(AAA, BBB) -> AAABBB
        // encodePacked(AA, ABBB) -> AAABBB
        return keccak256(abi.encodePacked(_text, _anotherText));
    }
}

contract GuessTheMagicWord {
    bytes32 public answer =
        0x60298f78cc0b47170ba79c10aa3851d7648bd96f2f8e46a19dbc777c36fb0c00;

    // Magic word is "Solidity"
    function guess(string memory _word) public view returns (bool) {
        return keccak256(abi.encodePacked(_word)) == answer;
    }
}


contract getfunctionHash {  
    // keccak256('transferFrom(address,address,uint256)') & 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000
    function getHash(string memory _word) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_word)) ;
    }

    function getFunction(string memory _word) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_word)) & 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000 ;
    }
}

interface IERC20 {
    function transferFrom( address sender,   address recipient,   uint256 amount    
    ) external returns (bool);    
}

contract TestAssemblyAndRevert {
    function test(address from, address to, uint256 value) public {
        // a standard erc20 token
        address token = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;// goerli chainlink

        // call transferFrom() of token using assembly
        assembly {
            let ptr := mload(0x40)

            // keccak256('transferFrom(address,address,uint256)') & 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000
            mstore(ptr, 0x23b872dd00000000000000000000000000000000000000000000000000000000)

            // calldatacopy(t, f, s) copy s bytes from calldata at position f to mem at position t
            // copy from, to, value from calldata to memory
            calldatacopy(add(ptr, 4), 4, 96)

            // call ERC20 Token contract transferFrom function
            let result := call(gas(), token, 0, ptr, 100, ptr, 32)

            if eq(result, 1) {
                return(0, 0)
            }
        }

        revert("TOKEN_TRANSFER_FROM_ERROR");
    }

    function test2(address from, address to, uint256 value) public {        
        address token = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB; // goerli chainlink
        IERC20(token).transferFrom(from, to, value);
    }
}
// https://goerli.etherscan.io/tx/0xe3874eab3982e83f938b6cb2b9d9025874c2421c8e58acb0ffb2aafa31c4d8e2