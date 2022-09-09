/**
 *Submitted for verification at Etherscan.io on 2022-09-09
*/

pragma solidity 0.8.16;

contract SolidlyContractAmendment {
    address public constant c30Address = 0xc301B6139055ae5b6704E3bbc5766ba59f1758C0;
    address public constant beepidibopAddress = 0xDa00C4Fec58DC0accE8FbDCd52428a7f66dcc433;
    address public constant rooshAddress = 0xdDf169Bf228e6D6e701180E2e6f290739663a784;
    address public constant lafaAddress = 0x8b9C5d6c73b4d11a362B62Bd4B4d3E52AF55C630;
    bool public c30Signed;
    bool public beepidibopSigned;
    bool public rooshSigned;
    bool public lafaSigned;
    bool public amendmentIsValid;
    uint256 public amendmentValidDate;

    string constant public amendment = "This is an amendment to the original Software Development Agreement saved on the Ethereum blockchain at contract address 0x7a0F4E2bAc82E49Cb4Fc87E40F6b280da5F40207, originally signed at timestamp 1661516734 (Friday, August 26, 2022 12:25:34 UTC). By the signature of this contract, both Parties hereby agree to an extension of the payment deadline as defined per Section 3.3, originally to be paid within 14 days of signing the original Agreement to the multi-signature wallet address 0xc7b4B9e9B62069b4c747ee63A88d6900839cA697, by an additional 7 days. All the original terms of the Software Development Agreement apply.";
    string constant declaration = "I hereby declare to have read and understood the text within the variable <amendment> and that by signing this amendment I agree to the terms in it.  I hereby declare to have the sole access, custody and ownership of the private key used to sign this message. I understand this entire statement can be used as evidence in a court of law.";

    function signAmendment(string memory _declaration) public {
        require (keccak256(bytes(_declaration)) == keccak256(bytes(declaration)));

        if (msg.sender == c30Address) {
            c30Signed = true;
        }
        if (msg.sender == beepidibopAddress) {
            beepidibopSigned = true;
        }
        if (msg.sender == rooshAddress) {
            rooshSigned = true;
        }
        if (msg.sender == lafaAddress) {
            lafaSigned = true;
        }
        if (c30Signed && beepidibopSigned && rooshSigned && lafaSigned) {
            if (!amendmentIsValid) {
                amendmentIsValid = true;
                amendmentValidDate = block.timestamp;
            }
        }
    }
}