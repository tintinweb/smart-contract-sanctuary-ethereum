// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./randomiser.sol";

contract testrand is randomiser {

    uint256[]  public arr;

    constructor() randomiser(1) {
        setNumTokensLeft(1, 15);
    }

    function getNumber() external{

        arr.push(randomTokenURI(1,uint256(keccak256(abi.encode(blockhash(block.number))))));

    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract randomiser {

    struct random_tool {
        bool        substituted;
        uint256     value;
    }

    mapping(uint => uint)                          num_tokens_left;
    mapping(uint => mapping (uint => random_tool)) random_eyes;
    uint256                                        startsWithZero;

    constructor(uint256 oneIfStartsWithZero) {
        startsWithZero = oneIfStartsWithZero;
    }

    function getTID(uint256 projectID, uint256 pos) internal view returns (uint){
        random_tool memory data = random_eyes[projectID][pos];
        if (data.substituted) return data.value;
        return pos;
    }

    function randomTokenURI(uint256 projectID, uint256 rand) internal returns (uint256) {
        require(num_tokens_left[projectID] > 0,"All tokens taken");
        uint256 ntl = num_tokens_left[projectID];
        uint256 nt = (rand % ntl);
        random_tool memory data = random_eyes[projectID][nt];

        uint endval = getTID(projectID,ntl-1);
        random_eyes[projectID][nt] = random_tool( true,endval);
        num_tokens_left[projectID] -= 1;

        if (data.substituted) return data.value+startsWithZero;
        return nt+startsWithZero;
    }

    function setNumTokensLeft(uint256 projectID, uint256 num) internal {
        num_tokens_left[projectID] = num;
    }

    function numLeft(uint projectID) external view returns (uint) {
        return num_tokens_left[projectID];
    }

}