/**
 *Submitted for verification at Etherscan.io on 2023-03-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Global Wallet Of Owner! (ERC1155 1/1 Version)
// For use with front-end views or
// To query wallet paramaters to pass to functions

// JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ
// JJJJJJJJJJJJJJJJJJJYYYYYYYYYYYYYYYYYYJJJJJJJJJJJJJJJJJJ
// JJJJJJJJJJJJJJJJJJ?~~~~~~~~~~~~~~~~~~!JJJJJJJJJJJJJJJJJ
// JJJJJJJJJJJJJJJJJY! ................ :JJJJJJJJJJJJJJJJJ
// JJJJJJJJJJJJJJJJJJ7::::::::::::::::::~JJJJJJJJJJJJJJJJJ
// JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ
// JJJJJJJJJJJJJJ?????????JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ
// JJJJJJJJJJJJJ?.........!YJJJJJJJ?^::::::::!JJJJJJJJJJJJ
// JJJJJJJJJJJJJ?.........!YJJJJJJJ?:::::::::!YJJJJJJJJJJJ
// JJJJJJJJJJJJJ?..........:::::::::.....::::!YJJJJJJJJJJJ
// JJJJJJJJJJJJJ?........................::::!YJJJJJJJJJJJ
// JJJJJJJJJJJJJ?~~~~^..................:!!!!?JJJJJJJJJJJJ
// JJJJJJJJJJJJJJYYYY7::::..............:YYYYJJJJJJJJJJJJJ
// JJJJJJJJJJJJJJJJJY!....^~~~~. . .^^^^!JJJJJJJJJJJJJJJJJ
// JJJJJJJJJJJJJJJJJY!    ?####.    5PPP5JJJJJJJJJJJJJJJJJ
// JJJJJJJJJJJJJJYYYY! .. 7GGGG.    YYYYYYYYYJJJJJJJJJJJJJ
// JJJJJJJJJJJJJYGGGGJ:::::....:::::....~GGGG5JJJJJJJJJJJJ
// JJJJJJJJJJJJJYGGGGJ::::.....:::::....^GGGG5JJJJJJJJJJJJ
// JJJJJJJJJJJJJYGGGGP5555~.............^YYYYYJJJJJJJJJJJJ
// JJJJJJJJJJJJJYGGGGGGGGB!.............:JJJJJJJJJJJJJJJJJ
// JJJJJJJJJ5PPPPGGGG57777^.........????J5555YJJJJJJJJJJJJ
// JJJJJJJJJGBGBGGGGGJ.:::.........:GBBBBGGGG5JJJJJJJJJJJJ
// JJJJJJJJJGGGGGPPPGY!!!!:........:PGGGP5PPPYJJJJJJJJJJJJ
// JJJJJJJJJGGGGG5555PPPPP~........:5P555JJJJJJJJJJJJJJJJJ
// JJJJJJJJJGGGGG55555555P!::::....:5P5P5YYYYJJJJJJJJJJJJJ
// JJJJJJJJJ5P5P5555555555PGGGG^...:5P555555PYJJJJJJJJJJJJ
// JJJJJJJJJ55555555555555GBGGG^...:5PPPP555PYJJJJJJJJJJJJ
// JJJJY555555555555555555GGGGG5YYYYGGGGG555555555YJJJJJJJ
// JJJJ5PPPP55555555555555GGGGGPPPPPGGGGG55555PPPPYJJJJJJJ

// Utility Brought to you by 0xInuarashi
// https://twitter.com/0xInuarashi || 0xInuarashi#1234 (Discord)

interface IERC1155 {
    function balanceOf(address address_, uint256 id_) external view returns (uint256);
}

interface IERC1155VerificationHelperGlobal {
    function getTotalERC1155Balances(address contract_, address owner_, uint256 start_,
    uint256 end_) external view returns (uint256);
}

contract globalWalletOfOwnerERC1155 {

    address public constant ERC1155VerificationHelperAddress =
        0x94C1702F522EE1235792a44cB8D50485ccb25863;

    function walletOfOwner(address contractAddress_, address wallet_, uint256 start_) 
    external view returns (uint256[] memory) {

        uint256[] memory _balance = new uint256[] (
            IERC1155VerificationHelperGlobal(ERC1155VerificationHelperAddress)
            .getTotalERC1155Balances(contractAddress_, wallet_, start_, 20000)
        );

        uint256 _index;

        if (_balance.length > 0) {
            for (uint256 i = 0; i < 20001;) {
                if (IERC1155(contractAddress_).balanceOf(wallet_, i) > 0) {
                    _balance[_index++] = i;
                }
            unchecked { ++i; }}
        }

        return _balance;
    }
}