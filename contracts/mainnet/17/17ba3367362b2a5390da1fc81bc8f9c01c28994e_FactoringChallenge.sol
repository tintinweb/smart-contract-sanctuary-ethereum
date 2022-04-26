// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./BigNumber.sol";

contract FactoringChallenge {
    mapping(bytes32 => uint256) public claims;
    address payable public winner;
    BigNumber.instance public product;
    uint256 public withdrawlDelay;
    event ChallengeSolved();

    constructor(bytes memory _product, uint256 _withdrawlDelay) {
        product.val = _product;
        product.bitlen = BigNumber.get_bit_length(_product);
        product.neg = false;
        withdrawlDelay = _withdrawlDelay;
    }

    function isOne(bytes calldata value) internal pure returns (bool) {
        for (uint256 i = 0; i < value.length - 1; i++) {
            if (value[i] != 0x00) {
                return false;
            }
        }
        return value[value.length - 1] == 0x01;
    }

    function hasExcessPadding(bytes calldata value)
        internal
        pure
        returns (bool)
    {
        require(value.length >= 32, "Value has fewer than 32 bytes");
        for (uint256 i = 0; i < 32; i++) {
            if (value[i] != 0x00) {
                return false;
            }
        }
        return true;
    }

    function donate() external payable {
        require(winner == address(0), "Challenge has been solved");
    }

    function submitClaim(bytes32 _hash) external {
        require(winner == address(0), "Challenge has been solved");
        claims[_hash] = block.number;
    }

    function withdraw(bytes calldata _factor1, bytes calldata _factor2)
        external
    {
        require(winner == address(0), "Challenge has been solved");
        address payable claimant = payable(msg.sender);

        require(!hasExcessPadding(_factor1), "Excess padding");
        require(!hasExcessPadding(_factor2), "Excess padding");
        require(!isOne(_factor1), "Trivial factors");
        require(!isOne(_factor2), "Trivial factors");

        BigNumber.instance memory factor1 = BigNumber._new(
            _factor1,
            false,
            false
        );
        BigNumber.instance memory factor2 = BigNumber._new(
            _factor2,
            false,
            false
        );

        bytes32 hash = keccak256(abi.encode(msg.sender, _factor1, _factor2));
        uint256 claimBlockNumber = claims[hash];
        require(claimBlockNumber > 0, "Claim not found");
        require(
            block.number - claimBlockNumber > withdrawlDelay,
            "Not enough blocks mined since claim was submitted"
        );

        require(
            BigNumber.cmp(BigNumber.bn_mul(factor1, factor2), product, true) ==
                0,
            "Invalid factors"
        );

        winner = claimant;
        emit ChallengeSolved();

        (bool sent, ) = claimant.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }
}