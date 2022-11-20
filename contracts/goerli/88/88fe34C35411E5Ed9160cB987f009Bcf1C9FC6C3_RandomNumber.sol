pragma solidity ^0.8.17;

contract RandomNumber{
    string private seed;
    uint256 private randNonce;

    modifier notContract() {
        require(msg.sender.code.length == 0, "Contract not allowed");
        _;
    }

    constructor(string memory _seed){
        seed = _seed;
        randNonce = 0;
    }


    function _getRandomNumberInRange(string memory _seed, uint _tokenFromUniswap, uint _from, uint _to) public view returns (uint) {
        require(_to > _from, "Range is not valid");
        uint randomNumber = uint(
            keccak256(
                abi.encodePacked(
                    keccak256(
                        abi.encodePacked(
                            block.number,
                            block.difficulty,
                            block.timestamp,
                            _seed,
                            randNonce,
                            _tokenFromUniswap
                        )
                    )
                )
            )
        ) % (_to - _from + 1);
        return randomNumber + _from;
    }
}