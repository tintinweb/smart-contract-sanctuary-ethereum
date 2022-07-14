// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

/*
MNK0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000KNM
MO'..   ................................   .... ..... ..  ...  ................................. 'kM
Mk.                                           ......,;;,'.                                       .kM
Mk.                                     .;ldk0KXXXXNWMWWNKOdc,.                                  .kM
Mk.                                 .;oOXWMMMMMMMMMMMMMMMMMMMWKx:.                               .kM
Mk.                             .,lkKWMMMMMMMMMMMMMMMMMMMMMMMMMMWXx:.                            .kM
Mk.                          'lkKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKd'                          .kM
Mk.                        .oXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXd'                        .kM
Mk.                        lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0,                       .kM
Mk.                       ,0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO'                      .kM
Mk.                      .dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd.                     .kM
Mk.                      ;KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.                     .kM
Mk.                     .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.                     .kM
Mk.                     ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk.                     .kM
Mk.                     oWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMx.                     .kM
Mk.                    .dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk.                     .kM
Mk.                    .xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.                     .kM
Mk.                    .OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK,                     .kM
Mk.                    ,KMMMMMMMMMWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNc                     .kM
Mk.                    lNMMMMMMM0l:;;;:lx0XWMMMMMMMMMMMMWMMMUNLEARNkNMMMMMNl                     .kM
Mk.                   .xMMMMMMMWl        ..:d0NMMMMMMNOo:'.        ,KMMMMMNc                     .kM
Mk.                    oWMMMMMMMk.           .;0MMMMK:             :XMMMMMK,                     .kM
Mk.                    '0MMMMMMMWk:..     ..';oKMMMMNxc,...     ..:0WMMMMWx.                     .kM
Mk.                     cXMMMMMMMMWXK0OOO00KNWMMMMMMMMMWXK00OOOO0XWMMMMMMX:                      .kM
Mk.                     .oWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.                      .kM
Mk.                      .OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo                       .kM
Mk.                       :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX;                       .kM
Mk.                       .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMx.                       .kM
Mk.                        ;KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX:                        .kM
Mk.                         oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx.                        .kM
Mk.                         .kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK,                         .kM
Mk.                          '0MMMMMMMMMMMMMMWNK0000KKNWMMMMMMMMMMMMMXc                          .kM
Mk.                           lWMMMMMMMMMMW0l,...  ....;dXMMMMMMMMMMWd.                          .kM
Mk.                           ,KMMMMMMMMMMX;            .xMMMMMMMMMMNl                           .kM
Mk.                          .dNMMMMMMMMMMNl            ;0MMMMMMMMMMWo                           .kM
Mk.                         ;0WMMMMMMMMMMMMXd,.       'oKMMMMMMMMMMMWk.                          .kM
Mk.                       .lXMMMMMMMMMMMMMMMMN0xooooxOXWMMMMMMMMMMMMMW0l'                        .kM
Mk.                      ,kNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXx;                      .kM
Mk.                    .oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx.                    .kM
Mk.                    ,KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl                    .kM
Mk.                    .OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX:                    .kM
Mk.                     ;KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd.                    .kM
Mk.                      :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo.                     .kM
Mk.                       ;ONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO;                       .kM
Mk.                        .;dKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNk:.                        .kM
Mk.                           .:xKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWN0o,                           .kM
Mk.                              .;ok0NWMMMMMMMMMMMMMMMMMMMMMWXOxc'.                             .kM
Mk.                                  ..;cldxkO0KKKKKK00Okxol:,.                                  .kM
MKocccccccccccccccccccccccccccccccccccccccccloodddddddollccccccccccccccccccccccccccccccccccccccccoKM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
*/

// Everybody be cool! This is a robbery! https://twitter.com/BandOfCrazy

import "./ERC20.sol";

contract BOCXtoken is ERC20 {
    constructor() ERC20("BOCX Coin", "BOCX") {
        _mint(msg.sender, 10000000 * 1E18);
    }
}