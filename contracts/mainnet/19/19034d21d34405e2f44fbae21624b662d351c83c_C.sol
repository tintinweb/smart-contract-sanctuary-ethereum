/**
 *Submitted for verification at Etherscan.io on 2022-09-10
*/

pragma solidity ^0.8.0;


interface Target {
    function becomeTheOptimizor(address player) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract Deployer {
    constructor(bytes memory code) { assembly { return (add(code, 0x20), mload(code)) } }
}

contract C {

    Target target = Target(0x27761C482000F2fC91E74587576c2B267eEb4546);
    uint256 public constant BIT_MASK_LENGTH = 10;
    uint256 public constant BIT_MASK = 2**BIT_MASK_LENGTH - 1;

    address owner;

    constructor() {
        owner = msg.sender;
    }

    function constructIndexesFor3Sum(uint256 seed)
        public
        pure
        returns (uint256[3] memory arr)
    {
        unchecked {
            arr[0] = (seed & BIT_MASK) % 10;
            seed >>= BIT_MASK_LENGTH;

            // make sure indexes are unique
            // statistically, this loop shouldnt run much
            while (true) {
                arr[1] = (seed & BIT_MASK) % 10;
                seed >>= BIT_MASK_LENGTH;

                if (arr[1] != arr[0]) {
                    break;
                }
            }

            // make sure indexes are unique
            // statistically, this loop shouldnt run much
            while (true) {
                arr[2] = (seed & BIT_MASK) % 10;
                seed >>= BIT_MASK_LENGTH;

                if (arr[2] != arr[1] && arr[2] != arr[0]) {
                    break;
                }
            }
        }
    }

    function run() external {

        require(msg.sender == owner);

        uint256 size = 122;
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.coinbase,
                    block.number,
                    block.timestamp,
                    size
                )
            )
        );

        uint256[3] memory indexesFor3Sum = constructIndexesFor3Sum(
            seed >> (BIT_MASK_LENGTH * 10)
        );

        uint256[] memory indices = new uint256[](2);
        if (indexesFor3Sum[0] == 0) {
            indices[0] = indexesFor3Sum[1];
            indices[1] = indexesFor3Sum[2];
        } else if (indexesFor3Sum[1] == 0) {
            indices[0] = indexesFor3Sum[0];
            indices[1] = indexesFor3Sum[2];
        } else if (indexesFor3Sum[2] == 0) {
            indices[0] = indexesFor3Sum[0];
            indices[1] = indexesFor3Sum[1];
        } else {
            revert();
        }

        bytes memory bytecode = abi.encodePacked(
            hex"60043603602e577f",
            abi.encode(address(this)),
            hex"3452602034f35b7f",
            indices[0],
            hex"34527f",
            indices[1],
            hex"602052606034f3"
        );

        address player = address(new Deployer(bytecode));
        target.becomeTheOptimizor(player);
        target.transferFrom(address(this), owner, 1);
    }
}