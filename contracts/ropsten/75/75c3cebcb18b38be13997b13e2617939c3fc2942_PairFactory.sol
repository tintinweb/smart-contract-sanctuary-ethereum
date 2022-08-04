/**
 *Submitted for verification at Etherscan.io on 2022-08-04
*/

// File: contracts/create2.sol

pragma solidity 0.8.9;

contract Pair{
    address public token1;
    address public token2;
    address public factory;
    constructor() {
        factory = msg.sender;
    }
    function initialize(address _t1, address _t2) external {
        require(msg.sender==factory, "Not Auth");
        token1 = _t1;
        token2 = _t2;
    }
}
contract PairFactory{
    address [] public pairs;
    mapping(address=> address) public pairRel;
    function createPair(address t1, address t2) external returns(address) {
        (address tokenA, address tokenB)=t1 > t2 ? (t2,t1) : (t1,t2);
        bytes32 salt = keccak256(abi.encodePacked(tokenA, tokenB));
        address calcAddr = address(uint160(uint(keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(type(Pair).creationCode)
            )
        ))));
        if(pairRel[calcAddr]!=address(0)) {
            revert (toString(calcAddr));
        }
        Pair pi = new Pair{salt:salt}();
        pi.initialize(tokenA, tokenB);
        address piAddr = address(pi);
        pairRel[piAddr] = calcAddr;
        pairs.push(piAddr);
        return calcAddr;
    }


function toString(address account) public pure returns(string memory) {
    return toString(abi.encodePacked(account));
}

function toString(uint256 value) public pure returns(string memory) {
    return toString(abi.encodePacked(value));
}

function toString(bytes32 value) public pure returns(string memory) {
    return toString(abi.encodePacked(value));
}

function toString(bytes memory data) public pure returns(string memory) {
    bytes memory alphabet = "0123456789abcdef";

    bytes memory str = new bytes(2 + data.length * 2);
    str[0] = "0";
    str[1] = "x";
    for (uint i = 0; i < data.length; i++) {
        str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
        str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
    }
    return string(str);
}
    function pairsCount() public view returns(uint256) {
        return pairs.length;
    }
}