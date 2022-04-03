// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "ERC20.sol";
import "ERC20Burnable.sol";

/**

                ███████╗███████╗██████╗  ██████╗ ██████╗  █████╗ 
                ██╔════╝██╔════╝██╔══██╗██╔═══██╗██╔══██╗██╔══██╗
                █████╗  █████╗  ██║  ██║██║   ██║██████╔╝███████║
                ██╔══╝  ██╔══╝  ██║  ██║██║   ██║██╔══██╗██╔══██║
                ██║     ███████╗██████╔╝╚██████╔╝██║  ██║██║  ██║
                ╚═╝     ╚══════╝╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝

MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNXXXXXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMWNX0Oxdlc:,''...'',:oxKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMW0kxxddolllc;'..                .;dKWMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMNd.         ............            'oKWMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMk.  ..              ...................dNMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMX:                            ...        :KMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMO.                               .        ,0WMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMWo    ..                                    'OMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMN:     ..                                    ,0MMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMK,                                            ;KMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMWx.                           ...               cNMMMMMMMMMMMMMMMMM
MMMMMMMMMWKko:.                                              .dWMMMMMMMMMMMMMMMM
MMMMMMNOo;.                                                   :XWMMMMMMMMMMMMMMM
MMMWKo,     ,c;'.                                          ..;:ddld0NMMMMMMMMMMM
MMKl.      .c,.;ccc:,..                               ..',,,'. ;:  .,lkXWMMMMMMM
M0;        .c......,:::::;;,,'.................''',,',,'..    .:,      'lONMMMMM
Nc         .c'..        ...,,;;::;'','',,,''''''...          .:;.        .;xNMMM
X;          .,cc'.              ..                       ..,;,.             ;OWM
Wd.            .,,'''....       ..                ...',,,,'.                 .kW
MNo.               ....'''''''';:,,'','''''''''''',,'...                      :X
MMNk,                           ............                                  lN
MMMMXx,                                                                     .cKM
MMMMMMNOl'                                                                .:kNMM
MMMMMMMMWXOo;.                                                         .:dKWMMMM
MMMMMMMMMMMMWKkl;'.                                               .,coOXWMMMMMMM
MMMMMMMMMMMMMMMMWN0koc;'..                                ..';coxOXWMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMWNX0kxolc:;;,'''......''',,;:ccloxkOKXNWMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWNNXXXKKKKXXXNNWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                         


*/

contract FedoraToken is ERC20, ERC20Burnable {
    constructor(uint256 initialSupply, address owner) ERC20("Fedora", "FED") {
        _mint(owner, initialSupply);
    }
}