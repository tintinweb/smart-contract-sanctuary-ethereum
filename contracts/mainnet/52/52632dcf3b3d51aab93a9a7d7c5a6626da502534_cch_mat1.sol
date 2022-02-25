/**
 *Submitted for verification at Etherscan.io on 2022-02-24
*/

pragma solidity ^0.4.21;							
    contract cch_mat1 {						
        address	owner;							

        function cch_mat10() public	{
            owner=msg.sender;
        }

        modifier onlyOwner() {
            require(msg.sender==owner);
            _;
        }									

        uint256 ID=8996959375953338495009171730492044151308761246817352843678377116;

        function setID(uint256 newID) public onlyOwner {
            ID=newID;
        }

        function getID() public constant returns(uint256) {
            return ID;
        }
}


// [email protected]:~/Рабочий стол/(16) MET AZOV (20220225)$ sha256sum met_kell_1.1plusBIN.sol
// 8996fea9593c0d86bdb4bc81c728d33b2e27ba4806236745e94ab17804f88a46  met_kell_1.1plusBIN.sol

// [email protected]:~/Рабочий стол/(16) MET AZOV (20220225)$ sha256sum met_kell_1.1bplusBIN.sol
// f75d9c5333f8434a37bb838d53bbea69f8cc442dd8ba9cadc176e88b4217d876  met_kell_1.1bplusBIN.sol

// [email protected]:~/Рабочий стол/(16) MET AZOV (20220225)$ sha256sum met_kell_1.1cplusBIN.sol
// 49bd5009b1cec74c1a48e00ac374f48d0afd43ee23104c38c69cefcdac9f91e7  met_kell_1.1cplusBIN.sol

// [email protected]:~/Рабочий стол/(16) MET AZOV (20220225)$ sha256sum met_kell_1.2plusBIN.sol
// 01ccc73d04920dbe56ea2f44a4bf358d14f9283fe95ccdf642564af7260aeff5  met_kell_1.2plusBIN.sol

// [email protected]:~/Рабочий стол/(16) MET AZOV (20220225)$ sha256sum met_kell_1.3plusBIN.sol
// a44ad15130800a3c8428dad543b4bccc89448bdcc6ba6138ed5fe63c7cb586fa  met_kell_1.3plusBIN.sol

// [email protected]:~/Рабочий стол/(16) MET AZOV (20220225)$ sha256sum met_kell_2.1plusBIN.sol
// 7ba61de2e46c819c31ab679791e17ea2e93fa18634513a05a28a4e6460022f86  met_kell_2.1plusBIN.sol

// [email protected]:~/Рабочий стол/(16) MET AZOV (20220225)$ sha256sum met_kell_2.2plusBIN.sol
// 7a352843fa69699cd82668a240c4183c6e79c666d0485b06db1091a3fbf176ae  met_kell_2.2plusBIN.sol

// [email protected]:~/Рабочий стол/(16) MET AZOV (20220225)$ sha256sum met_kell_2.3plusBIN.sol
// 783a7aba7b11d67c8b90789cce7bde2117bcc3022df2ba659c30101b3246ea2b  met_kell_2.3plusBIN.sol