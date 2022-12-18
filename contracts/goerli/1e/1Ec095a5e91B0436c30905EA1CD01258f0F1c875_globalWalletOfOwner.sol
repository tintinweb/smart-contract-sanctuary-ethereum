// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Global Wallet Of Owner!
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

interface IERC721 {
    function balanceOf(address address_) external view returns (uint256);
    function ownerOf(uint256 tokenId_) external view returns (address);
}

contract globalWalletOfOwner {
    function walletOfOwner(address contractAddress_, address wallet_, uint256 start_) 
    external view returns (uint256[] memory) {
        uint256[] memory _balance = new uint256[] (
            IERC721(contractAddress_).balanceOf(wallet_));
        uint256 _index;
        uint256 _iterateId = start_;
        bool _isOwnerOfZeroAtLastIndex;

        if (_balance.length > 0) {
            while (_balance[_balance.length - 1] == 0 
                && !_isOwnerOfZeroAtLastIndex 
                && _iterateId < 65536 // A limit of iterations to prevent out of gas error
                ){
                if (wallet_ == IERC721(contractAddress_).ownerOf(_iterateId)) {
                    
                    // Check if 0 is owned and at last index
                    if (_iterateId == 0 && _index == _balance.length - 1) {
                        _isOwnerOfZeroAtLastIndex = true;
                    }

                    _balance[_index] = _iterateId;
                    _index++;
                }
                _iterateId++;
            }
        }
        return _balance;
    }
}