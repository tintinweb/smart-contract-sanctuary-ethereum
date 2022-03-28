/**
 *Submitted for verification at Etherscan.io on 2022-03-28
*/

//SPDX-License-Identifier: MIT
/**** 
***** this code and any deployments of this code are strictly provided as-is; no guarantee, representation or warranty is being made, express or implied, as to the safety or correctness of the code 
***** or any smart contracts or other software deployed from these files, in accordance with the disclosures and licenses found here: https://github.com/V4R14/firm_utils/blob/main/LICENSE
***** this code is not audited, and users, developers, or adapters of these files should proceed with caution and use at their own risk.
****/

pragma solidity >=0.8.4;

/// @title Address Verifier
/// @notice on-chain address verification for client onboarding or third party request by requesting a specific amount of wei along with an on-chain reference or sig
/// @dev auto-transfers wei to firm (deployer) and returns provided amount of wei (msg.value), boolean signature confirmation and _sig hash

contract AddressVerifier {

    address payable firm;
    
    error SubmitWeiAmount(); 

    constructor() payable {
        firm = payable(msg.sender);
    }

    /// @param _sig client signature or instructed reference from firm
    /// @notice submit precise amount of wei to this contract address as directed by firm, along with name or other reference as _sig
    /// @return msg.value in wei as requested by firm, bool if verification submitted, and bytes4 hash of the sig
    function submitVerification(string calldata _sig) external payable returns (uint256, bool, bytes4) {
        if (msg.value == 0) revert SubmitWeiAmount(); // revert if zero wei sent - firm will request nonzero amount for verification
        (bool _signed, ) = firm.call{ value: address(this).balance }(""); // send dust to firm address instead of accumulating in this contract, also sending any ETH accumulated from receive()
        return(msg.value, _signed, bytes4(keccak256(bytes(_sig))));
    }

    receive() external payable {} // in case ETH is sent without data/without calling submitVerification
}