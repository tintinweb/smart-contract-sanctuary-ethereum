/**
 *Submitted for verification at Etherscan.io on 2023-03-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Global Wallet Of Owner! (ERC1155 OpenSea Version)
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
    function balanceOf(address owner_, uint256 id_) external view returns (uint256);
}

contract GlobalWalletOfOwnerERC1155OS {

    // We store opensea's address and interface into contract storage
    address public constant OSAddress = 0x495f947276749Ce646f68AC8c248420045cb7b5e;
    IERC1155 public constant OS = IERC1155(OSAddress);

    // Encode creator address and tokenId to OS encoded ID
    function encodeTokenId(address creator_, uint256 tokenId_) 
    public pure returns (uint256) {

        uint256 _encodedTokenId = 
            (uint256(uint160(creator_)) << 96) + 
            (tokenId_ << 40) + 
            1;

        return _encodedTokenId;
    }

    // Create an array of the encoded tokenIds
    function createEncodedTokenIdArray(address creator_, uint256 start_, uint256 end_) 
    public pure returns (uint256[] memory) {
        uint256 l = (end_ - start_) + 1;
        uint256[] memory _a = new uint256[] (l);
        uint256 i; unchecked { do {
            _a[i] = encodeTokenId(creator_, start_++);
        } while (++i < l); }
        return _a;
    }

    // We get the unique token balances of the wallet
    function getUniqueBalances(address wallet_, address creator_,
    uint256 start_, uint256 end_) public view returns (uint256) {
        uint256[] memory _ids = createEncodedTokenIdArray(creator_, start_, end_);
        uint256 _balance;
        uint256 l = _ids.length;
        uint256 i; unchecked { do {
            if (OS.balanceOf(wallet_, _ids[i]) > 0) _balance++;
        } while (++i < l); }        
        return _balance;
    }

    // Finally, we return a uint256[] of the owned tokenIds
    function walletOfOwner(address wallet_, address creator_, 
    uint256 start_, uint256 end_) public view returns (uint256[] memory) {

        uint256 _balance = getUniqueBalances(wallet_, creator_, start_, end_);
        uint256[] memory _a = new uint256[] (_balance);
        uint256 l = _a.length;
        
        uint256 [] memory _ids = createEncodedTokenIdArray(creator_, start_, end_);
        uint256 _index;
        uint256 i; while (_a[l-1] == 0) {
            if (OS.balanceOf(wallet_, _ids[i]) > 0) _a[_index++] = _ids[i];
            unchecked { ++i; }
        }

        return _a;
    }
}