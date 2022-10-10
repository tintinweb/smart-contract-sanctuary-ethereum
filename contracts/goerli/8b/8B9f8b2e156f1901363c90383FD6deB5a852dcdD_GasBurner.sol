/**
 *Submitted for verification at Etherscan.io on 2022-10-10
*/

contract GasBurner {
    /// @notice Fully burns all available gas without reverting, for any gasLimit >= 22519.
    function burnGas() public {
        // All fixed code of this function (including the fixed 47 gas of the
        // loop, but excluding the extra gas consumed by address(this).call
        // below) consumes 1334 gas. We compute how much will be left for the
        // variable part of the loop.
        uint l = gasleft() - 1334;

        // Consume l % 179 more, so that the gas for the variable part of the loop is a multiple of 179.
        address(this).call{ gas: l % 179 }(abi.encodeWithSignature("burnGas()"));

        // Total gas consumed by the loop: 47 + r * 179
        uint r = l / 179;
        while(r > 0) {
            r--;
        }
    }
}