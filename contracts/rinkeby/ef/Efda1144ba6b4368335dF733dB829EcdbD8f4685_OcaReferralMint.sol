/**
 *Submitted for verification at Etherscan.io on 2022-08-01
*/

pragma solidity =0.7.6;
// Developed by Orcania (https://orcania.io/)

interface IMINT {

    function price() external view returns (uint256);

}

interface IOCA{
         
    function mint(address user, uint256 amount) external;
  
}

contract OcaReferralMint {

    IMINT MINT = IMINT(0x4c4BAB8b80785272d0089D76E85828f9a70FdbC2);
    IOCA OCA = IOCA(0x8AeB42F7b4204C956c51907C89639E3446a787Ea);

    //User write functions=========================================================================================================================
    function mint(address referral) external payable {
        require(msg.sender != referral, "SELF_REFER");
        uint256 price = MINT.price();

        require(msg.value % price == 0);
        uint256 amount = msg.value / price * 1000000000000000000;

        OCA.mint(msg.sender, amount);
        OCA.mint(referral, amount * 5 / 100);
    }

}