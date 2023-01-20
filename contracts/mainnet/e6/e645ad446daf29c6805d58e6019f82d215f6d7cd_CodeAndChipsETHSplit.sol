pragma solidity ^0.8.17;

/**
 * @title       Code&Chips payment splitter
 *
 * @author      wwWw.exhausted-pigeon.xyz
 *
 * @notice      Splits every ETH payment received between 2 addresses, at a set ratio.
 *              For gas optimisation, this needs to be redeployed if the rate or addresses change
 *
 * @dev         There a 4 versions of this contract: in solidity, in inlined Yul (this version), 
 *              in Yul and in ETK-assembly. The ETK-assembly version is the most gas efficient, but
 *              cannot be verified on Etherscan (the gas difference being asm and this is 31 unit of gas).
 *              See the repo for more informations.
 *              This is not supposed to be used to transfer to a contract address, as 0 gas is passed (it
 *              will silently fail).
 * 
 * @custom:repo https://github.com/exhausted-pigeon-srl/exhausted-splitter
 */
contract CodeAndChipsETHSplit {
    fallback() external payable {
        assembly {
            // This is only a fallback, irregardless of calldata
            let exhaustedPigeonAddress := 0x6C4dc45b51bB46A60B99fB5395692ce11bBE49C5
            let codeAndChipsAddress := 0x97b3aE7e3e68F795f434cF3e9ec5e77550Bb201C

            // 4% cut
            let CCCut := div(mul(callvalue(), 400), 10000)

            // Send the cut, without any gas passed
            pop(call(0, codeAndChipsAddress, CCCut, 0, 0, 0, 0))

            // Send the remaining balance
            pop(call(0, exhaustedPigeonAddress, selfbalance(), 0, 0, 0, 0))
        }
    }
}