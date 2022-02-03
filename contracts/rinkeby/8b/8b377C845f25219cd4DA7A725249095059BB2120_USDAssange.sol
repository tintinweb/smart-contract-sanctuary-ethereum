// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import "./Base64.sol";
import "./Ownable.sol";
import "./IERC1155Receiver.sol";

///                                                                                                     
///                                                                                                     
///                                   --::/:            -::/:--                                         
///                            -:/ossossssyso/---::///+osohyoshoo+//-                                   
///                         :++oooosyhdddhhdddhyoosyyyhhhhdhhshdsddss-                                  
///                       -/ooossssyyoydmdhddhddhhydyhdmmyysddsyhhhsoy+:-                               
///                      /+ooyyyhhhyhysdddddhhhhyddddhyhddyymdysdhsoyoyyoo/---                          
///                    -/soyyyyyysssdydhmmddhyhhyshdhdhhyhddhhysdssyyossoso++o:                         
///                   -+yhsss+++ooyoddhhyhdyhdhyhysshhhdhyyhhhysd+omoosoysooooo+/:-                     
///                   +yhossyysssoyydddhyoshyyhyshysssshmmhhddhyh+yyooooyhhdhhyooss+-                   
///                  -osossysyhysyymmdhydyyssyyhssssooysydmddhyhyosoooooyo/+ooo+sdhss+-                 
///                 -+soshhhhyysossmmhhyyyhssosyyyysooss+oyyyhhyoo++oo+h++oshyhohddhho/                 
///                -/oshdssdhso+ohhdmdyyhhsyyhsshssydhhyshdhddhhys++oso++odyyssosshdyy+/                
///               -/syyysohyoosshdddhssshdhhydhdmhdhmmhdhhsshyyhhhyyss+os+osyhyhyssoysy+:-              
///               /ohysyoho+ydshddhyysyysyyyhhdmmdddmdhyhhmmddyyhyyhoosyyhoosyyhhyo+ohhs+:              
///              -+yysssdosdyoymhsooyyyhhyydNsssdmymmmmdmmdyyhhyhhyhyssyyoo+osossssyosdhs/              
///              -ososyhsydsydmyoosyhhhddhdmNhyyddmmmmdhhdmhohyhshoosssshyooooyysoyss+hmyo-             
///             -/osoyssdmyyydyooooshdmdyddmdmdddddmmNdhsomdydhdhdsssssoysoo++oosssys+ymyso-            
///              :///syhhys+sosoooosshddsyhhhmdmddmdhmdmdhhsshdhyyhhyyysssyo++o+ssyysoomhoo/            
///               :/oyysys+/+oso++shhyhdydhhmmNhddddhddhmmdhhdhhyyysyhhyssysooo++osshsohmo+/            
///              -sossyyo+++o+so++ydyhhdddyyNNNdmmmhhhdhmdddddhdddddhyhsosyys+ssshy+sysymyo/            
///              /oosdhoo++oso+oo+yyyhmdhhydmhdmhdmdhyddhdmhhhdhhdddyyysosyyso+ysosysyyyyho/:           
///              :oodysyso+oooooooyddmmmddhhhdhmhdmmhddhhNmhyhhsoohdhhyoooo+os+ysyssyssooys+:           
///              :osysyooo+os+o+oyshhmhsydmhdddmymmmdmhhmddhmhhhyyhhyyyyo/osss+ssyssoos+ooy++-          
///              +oyysosssooooyhyydhddhssydhhmddhmmmdmddhhhhddyyhhdhhhhds+sssoo/+/++s++soh+s/:          
///              +oooso+sossssddyhhhyoydddhdddyhhddhdhhhhyys+o+++++oo+yyo+o++oo/://+o++ossyoo/-         
///              +yh++oos+syyyyysoo::/++oosoyhyyhyhydhyys++///:////+sysoso+/++++:/+/++oosssh/:          
///              +s+so/+soyy+ooooos++++/////+oysssssshs+/::/oosyhhhhdhhssso+//+o//::+/++y+ssy:          
///              /soo+++sosoydddhdddddhyhhoo//+oyhyhdho/:/oso+o+///+o+osyhs+++/oo++o/+//+s+ooy          
///              -sso+++ysssydddhyoo++++++syysoohmdddhy//+syy+oy+//:/+///oyoo++sys+o+/+/+oo+/ss         
///              +syy+++yhosyyss//+/://+yo+syhyohmhhmdh++oddhhddhhysyyoo+/+ossshh+++o:/++/+oo+o/        
///              -/+o++oyoos+++ooossssosssosshhsymmydhs/oohddyhhysohoooyso++sysyso+/so::/+//++++-       
///               //+ssossssyoyyhysssyssssoyhysshdmddh++oooyhdhydhhsssyhhyyydmddyo+o+s++oys//+/:-       
///               /+yssoosyhhyssysssyhysydhhdossdhdhhdyy/+oshhdhhhhdyssyhhdhhhydhyoooss++oo:-+:-        
///               :soso+ooymhhyyhhhyyhhyddmdyssyddmmdddy+ooyhhdmhyddhmdhddyshhddhooso++++oo:/+:-        
///               -osoyoyshdhysdmmhyhhddddhyoshdddmmdhdhs+oodmmNdmmmddssodddhyhho:/oss+///o:://         
///                syss++osdddydmmdddhyyddhsoydddmmdyhhdy+oodmmmdmddmmhsyddhyys+:://so+oo/+/:o:         
///                hddo+ososhdddddddhhhyyyssoyhhhddyhhsss+y+shhdhhhmdhhyhydhyo+/::/++o+/o//:+:          
///                odhh++++oshdhdhddhmdhososoo+++sosso+//so+ohyhdshdhhyhhhyoso/:/+os++++//:/:           
///                -syh++soooyhhhhmdddsssssso/:/+oo++::://+ohddyhyhdhdyyshssoo+:/++o+/++//--            
///                -hsy++yyosohysoddhdosyhmdyyooooo++os//+ssyhhhddhhyyysshhsoo//+oo+/+++/-              
///                -+yysosoo+shdhdddhhsyhddmhyo+ooyyo+os/oosyysyydhmhhy+yhhhs++/oss//++/:-              
///                 -/o++ooosyyyyyyyoyddyyssoo++++yys+ooosooosssssyddsoohyy+/+oooo+/::  /-              
///                    -/hosoooyyyhhhdossssoos+oosshoo+++o+++++sosssdho+ys+//o+o++/:/-  :               
///                    -:/sooo+soshddo/+++s+/////oo+/::::::://:+/+osyysosy++y++os::::                   
///                      -o++oosshhmh:/+/+oooyyyyysoosysssoso/os//+oshhoos+/s+/+/::///                  
///                       -+++ohosdmd/ohmdysyyysyhddyyysossssshhs/:+o+doosoo//://---:::-                
///                        ://soooyms+sdmdhsssoso+++++o+oooysoddds/++oyo+++oo/+:-                       
///                         -:/ooohs+yddhossyo+oooso+oyoo+osyshmdyo++ssso///o//:-                       
///                          -:s+oh+ohddhhdhdss++ssossoo++ssysssysyy+oooo+//+::::                       
///                           -o/+ssyysymmmddddsohyhddsysymhsosyosos+o+ss+//:-:::                       
///                            -:/+oshhohhyhdddsoshdhhsoyyhys+syo+ooooss+//:::/o/                       
///                             ///ohyooyssyhhyooooysysooossysyosoooo+so/:-::+oss:                      
///                             :+oyoooooyysss+syoos+osssy+oyooso+++o+//:::/+oosss+-                    
///                             -os++o+hsoyoosososysooosyyo+o+oss//::---::/ooooooooy:                   
///                              syo//++/++ssssoooyos/ososo++/++/----::::/+o+sosyssod:                  
///                              ohyyo//:/+os+s+++os+o+o//::::----:::::/+oso+oyshyhh:                   
///                              :hdsss+++/+//::://///:/:::::--:::::::/oosyoyhhhyyh-                    
///                               shssdso++oo+/::-:::::/::::::::::://+ooooyyddysyh-                     
///                              +osyddhoo+oo+++////////:::::/::://oossydddhssooh-                      
///                             /o+oommysyoooo+++oossoso++/+++oo+osyyhdmdhsoss+y:                       
///                            :ss+oshhhdo+ooooooooos+soooossyhhsydmmmhddsyyhhy/                        
///                            ssoooossydhsyhyssyyooyssssssyyyyyddmdhhhmmmss+s+                         
///                           /ssoshosooddmmhddhyhhhhyssoooo+sshdddhyymmmdo+s/                          
///                           yssoohsssyyhhyshdhssooyooooosyssshmmyhdhhys+os:                           
///                          +shdyoysssyyhhhhhdhmmyhdsssshhyhddyddhyyoos+os-                            
///                          syydhoyhsoyyhyyFREE ASSANGEhhssyhhyhyhhyoo+yo                              
///                          +yhhhhdmyssyydddssysyyyyssyyyydmdhsyhhhyyss/                               
///                          -syhysddhhdhdmmdddymmddddddhdossmhddhyssyo-                                

/// @title  Dollars Assange by Pascal Boyart
/// @author jolan.eth
contract USDAssange is Ownable {
    string public symbol = "USDAssange";
    string public name = "Dollars Assange";
    string public description = ""; //to set

    string DollarsAssangeImageCID = "QmQGNnmoGuRGmCykTRQ44sZapoXWVuSUm1hWFEETcKRCf4";
    string DollarsAssangeAnimationCID = "QmQGNnmoGuRGmCykTRQ44sZapoXWVuSUm1hWFEETcKRCf4";

    uint256 public totalSupply = 0;

    address public ADDRESS_MINTER = 0x1Af70e564847bE46e4bA286c0b0066Da8372F902;
    address public ADDRESS_SIGN = 0x1Af70e564847bE46e4bA286c0b0066Da8372F902;

    address public ADDRESS_CHARITY; //to set
    address public ADDRESS_PBOY = 0x709e17B3Ec505F80eAb064d0F2A71c743cE225B3;
    address public ADDRESS_JOLAN = 0x51BdFa2Cbb25591AF58b202aCdcdB33325a325c2;

    uint256[2] public SHARE_CHARITY = [90, 30];
    uint256[2] public SHARE_PBOY = [8, 55];
    uint256[2] public SHARE_JOLAN = [2, 15];

    uint256 public SHARE_TYPE = 0;

    bool dropAllowed = true;
    bool mintAllowed = true;

    mapping(uint256 => mapping(address => uint256)) private balances;
    mapping(address => mapping(address => bool)) private operatorApprovals;

    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    constructor() {}

    // EIP165 functions ***************************************************

    function supportsInterface(bytes4 interfaceId)
    public pure returns (bool) {
        return interfaceId == 0xd9b67a26 || interfaceId == 0x0e89341c;
    }

    // Withdraw functions *************************************************

    function setShareType()
    public onlyOwner {
        SHARE_TYPE = SHARE_TYPE == 0 ? 1 : 0;
    }

    function setCharity(address CHARITY)
    public onlyOwner {
        ADDRESS_CHARITY = CHARITY;
    }

    function setPboy(address PBOY)
    public {
        require(msg.sender == ADDRESS_PBOY, "error msg.sender");
        ADDRESS_PBOY = PBOY;
    }

    function setJolan(address JOLAN)
    public {
        require(msg.sender == ADDRESS_JOLAN, "error msg.sender");
        ADDRESS_JOLAN = JOLAN;
    }

    function withdrawEquity()
    public onlyOwner {
        uint256 balance = address(this).balance;

        address[3] memory shareholders = [
            ADDRESS_CHARITY,
            ADDRESS_PBOY,
            ADDRESS_JOLAN
        ];

        uint256[3] memory _shares = [
            SHARE_CHARITY[SHARE_TYPE] * balance / 100,
            SHARE_PBOY[SHARE_TYPE] * balance / 100,
            SHARE_JOLAN[SHARE_TYPE] * balance / 100
        ];

        uint i = 0;
        while (i < 3) {
            require(payable(shareholders[i]).send(_shares[i]));
            i++;
        }
    }

    // Mint functions *****************************************************

    function freeAssange()
    public onlyOwner {
        mintAllowed = false;
    }

    function setMinter(address MINTER)
    public onlyOwner {
        ADDRESS_MINTER = MINTER;
    }

    function drop(address[] memory addresses, uint256[] memory quantity, uint256 total)
    public onlyOwner {
        require(dropAllowed, "error dropAllowed");
        uint256 i = 0;
        while (i < addresses.length)
            mintUSDAssange(addresses[i], quantity[i++]);
        totalSupply += total;
        dropAllowed = false;
    }

    function mint()
    public {
        require(mintAllowed, "error mintAllowed");
        require(msg.sender == ADDRESS_MINTER, "error msg.sender");
        mintUSDAssange(msg.sender, 1);
        totalSupply++;
    }
    
    function mintUSDAssange(address to, uint256 supply)
    private {
        _mint(to, 1, supply, '');
    }

    // Metadata functions *************************************************

    function setCIDs(string memory image, string memory animation)
    public onlyOwner {
        DollarsAssangeImageCID = image;
        DollarsAssangeAnimationCID = animation;
    }

    function setDescription(string memory _description)
    public onlyOwner {
        description = _description;
    }

    // ERC1155 functions **************************************************
    
    function uri(uint256)
    public view virtual returns (string memory) {
        return string(abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes (string(abi.encodePacked(
                        '{',
                        '"name":"',name,'",',
                        '"description":"',description,'",',
                        '"attributes":[',
                        '{"trait_type":"Character","value":"Julian Assange"},',
                        '{"trait_type":"Effect","value":"FREE ASSANGE"},',
                        '{"trait_type":"USD Portrait","value":"#2 - Free Assange"},',
                        '{"trait_type":"NFT Type","value":"Locked up days counter"},',
                        '{"trait_type":"Status","value":"',mintAllowed ? 'Locked up' : 'Free','"},',
                        '{"trait_type":"Medium","value":"Dollar bills glued on canvas"}',
                        '],',
                        '"image":"ipfs://',DollarsAssangeImageCID,'",',
                        '"animation_url":"ipfs://',DollarsAssangeAnimationCID,'"',
                        '}'
                    )))
                )
            )
        );
    }

    function balanceOf(address owner, uint256 id)
    public view virtual returns (uint256) {
        require(owner != address(0), "error owner");
        return balances[id][owner];
    }

    function balanceOfBatch(address[] memory owners, uint256[] memory ids)
    public view virtual returns (uint256[] memory) {
        require(owners.length == ids.length, "error length");
        uint256[] memory batchBalances = new uint256[](owners.length);

        uint256 i = 0;
        while (i < owners.length) 
            batchBalances[i] = balanceOf(owners[i], ids[i++]);

        return batchBalances;
    }

    function setApprovalForAll(address operator, bool approved)
    public virtual {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator)
    public view virtual returns (bool) {
        return operatorApprovals[owner][operator];
    }

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data)
    public virtual {
        require(from == msg.sender || isApprovedForAll(from, msg.sender), "error approved");
        require(to != address(0), "error to");

        address operator = msg.sender;

        uint256 fromBalance = balances[id][from];
        require(fromBalance >= amount, "error balance");
        unchecked {
            balances[id][from] = fromBalance - amount;
        }
        balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    function safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
    public virtual {
        require(from == msg.sender || isApprovedForAll(from, msg.sender), "error approved");
        require(ids.length == amounts.length, "error length");
        require(to != address(0), "error to");

        address operator = msg.sender;

        uint256 i = 0;
        while (i < ids.length) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = balances[id][from];
            require(fromBalance >= amount, "error balance");
            unchecked {
                balances[id][from] = fromBalance - amount;
            }
            balances[id][to] += amount;
            i++;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    function _mint(address to, uint256 id, uint256 amount, bytes memory data)
    private {
        require(to != address(0), "error to");

        address operator = msg.sender;

        balances[id][to] += amount;

        emit TransferSingle(operator, ADDRESS_SIGN, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    function _setApprovalForAll(address owner, address operator, bool approved)
    private {
        require(owner != operator, "error owner");
        operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _doSafeTransferAcceptanceCheck(address operator, address from, address to, uint256 id, uint256 amount, bytes memory data)
    private {
        uint256 size;
        assembly {
            size := extcodesize(to)
        }
        if (size > 0) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("error Receiver");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("error Receiver");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
    private {
        uint256 size;
        assembly {
            size := extcodesize(to)
        }
        if (size > 0) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("error Receiver");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("error Receiver");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;
        return array;
    }
}