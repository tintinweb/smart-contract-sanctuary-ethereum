/**
 *Submitted for verification at Etherscan.io on 2022-11-08
*/

/*            
                      
 __      __  __  __           ____     _____       __       ______  ____     ____       
/\ \  __/\ \/\ \/\ \  /'\_/`\/\  _`\  /\  __`\    /\ \     /\  _  \/\  _`\  /\  _`\     
\ \ \/\ \ \ \ \ \ \ \/\      \ \ \L\ \\ \ \/\ \   \ \ \    \ \ \L\ \ \ \L\ \\ \,\L\_\   
 \ \ \ \ \ \ \ \ \ \ \ \ \__\ \ \  _ <'\ \ \ \ \   \ \ \  __\ \  __ \ \  _ <'\/_\__ \   
  \ \ \_/ \_\ \ \ \_\ \ \ \_/\ \ \ \L\ \\ \ \_\ \   \ \ \L\ \\ \ \/\ \ \ \L\ \ /\ \L\ \ 
   \ `\___x___/\ \_____\ \_\\ \_\ \____/ \ \_____\   \ \____/ \ \_\ \_\ \____/ \ `\____\
    '\/__//__/  \/_____/\/_/ \/_/\/___/   \/_____/    \/___/   \/_/\/_/\/___/   \/_____/
                                                                                        
*/
                                         

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IERC721 {
    function transferFrom(address, address, uint256) external;
}

contract WumboSwap {
    IERC721 immutable WumboKey;
    IERC721 immutable WumboPass;
    address private constant treasury = 0x823D8C84126Da1756BE69421c78482d0D24d907e;

    constructor() {
        WumboKey = IERC721(0xE8E7E068868ab52e32Dfe899D6654ABB88642a00);
        WumboPass = IERC721(0xD0fF87cc052b35241D11127B8687d727B7444D3E);
    }

    function swapWumboKey(uint256 _keyTokenId) external {
        WumboKey.transferFrom(msg.sender, 0x000000000000000000000000000000000000dEaD, _keyTokenId);
        WumboPass.transferFrom(treasury, msg.sender, _keyTokenId+222);
    }
}