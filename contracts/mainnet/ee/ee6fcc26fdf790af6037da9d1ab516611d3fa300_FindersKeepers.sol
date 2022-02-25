/**
 *Submitted for verification at Etherscan.io on 2022-02-25
*/

// SPDX-License-Identifier: cc0
// by Dr. Slurp
//
/**
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0x;,dXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKo,..  .:ONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0l'.      .,o0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOc..         ..:xKWMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXk:.....''''...  ..,lkXWMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMWXx;..,:lddxkkkxl:'.  .':oONMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMWKd,.,:c:;;,'''',:oxl.   .';:d0WMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMW0l'.'cl;.';cll:...'ldc.    ..,:cxKWMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMNOc...,oc'.,odddo;...:oc'.     ..,;:lkXWMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMNk:..  .ld:..';:;,'';cll;..       ..,;::oONMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMWXx;.     .cdoc:;;:cllc::,..         ...,;::cdKWMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMWKd,.        .,:ldddol:,..           .......;:::lxKWMMMMMMMMMMMMMM
MMMMMMMMMMMMW0o,.            ......              .........';::::lkXWMMMMMMMMMMMM
MMMMMMMMMMNOl'...               .................,,,,'''''',;::::coONWMMMMMMMMMM
MMMMMMMMNk:...................'''''''''''''''''''',,,,'''''''',;;;:cdKNWMMMMMMMM
MMMMMMMW0dlc:;;;,'''''''''''''',,',,,,,,,,,,,,,,,,,;::;;,,''...'''',;lxKWMMMMMMM
MMMMMMMMMMWNXK0Okdolc;,,,,,,,,,,,,,,,,,,,,,,''''''',;:ccc:::;;'''''',,;lkXWMMMMM
MMMMMWNXXNWMMMMMMMWNOl;,,,,,,,,,,,,,,,;;;;;;;;;;;;;;;:clcccclodxkkOOOOOO0XWMMMMM
MMMMMXo:;cloxOXWMMWKxlccccccccccccccccccccccccccccclloooooollld0NMMMMMMMMMMMMMMM
MMMMMXxc;'....;o0WMWNKOdolllllllllllllllllllllllllllooooooooodk0NMMMMMMMMMMMMMMM
MMMMMMWNXOd:'...;xNMMMWN0kdllllllllllllllllllllllloooooooodk0XWMMMMMMMMMMMMMMMMM
MMMMMMMMMMMNOc''';xNMMMMMWXklcccllllllllllllllccclddoooodkXWMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMWKl,,,:kWMMMMMWOlcccllllllllllllllccccoddoollxXWMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMWO:,;;cOWMMMW0occcclxxllllllllllllcccldddocclxXMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMNx;;;;l0WMW0oc:cclxXOlcclllllllolccccodxxlcclkNMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMXo;;;:lxOxl:::ccdKXkccccodxxx0KkolcccldkxlcclkNMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMXd:;;:::::::clxKXklccclxOXWWMWKdllcccldkkolclkXWMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMXkl:;;::::ld00kocccccoOXNMMMMWOolllcccoxkxocldKWMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMWN0kxxxk0KKkocccccox0NWMMMMMMNOdllllccloxkxoloONMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMWWMMNxc:ccldOKNWMMMMMMMMMWXOdllllccldkkdllxXWMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMXdccclxXWMMMMMMMMMMMMMMWXOolllcccoxkocckNMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMNkcccoOWMMMMMMMMMMMMMMMMMWKxolllccokxlcl0WMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMWKdccldKWMMMMMMMMMMMMMMMMMWXklllcclxdlclOWMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMWKxlcld0WMMMMMMMMMMMMMMMMMNOlllccldocclOWMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWN0dccoONMMMMMMMMMMMMMMMMXxlllccodlccxXMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOxooONMMMMMMMMMMMMMMNkollccoOxclONMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWKxxXWMMMMMMMMMMMMW0ollclkKKxokXMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWMMMMMMMMMMMMMWKdllokKWWX0XWMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNklokKWMMMMWMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXkx0NMMMMMMMMMMMMMMMMMMMMMMMM
**/


pragma solidity >=0.7.0 <0.9.0;

contract FindersKeepers
{

    address creator;
    address public winnerAddress;
    string public winnerDiscord;  // data

    enum State {Init, Waiting, Done}
    State public state = State.Init;

        constructor() 
        {
            creator = msg.sender;
        }

        /// @notice Not the droids you are looking for.
        function startContest() public onlyOwner{
            state = State.Waiting;
        }

        /// @notice Greetings Meat-Bag, you made it to the final step.
        /// @dev Please write your full discord user name (ex:  jennyfer#0001)
        ///      We will be in touch to coordinate delivery of your prize. :p
        ///      WARNING: if this function asks for a ton of gas (more than 1 eth)
        ///      then do not call it, there is already a winner! 
        /// @param discord Your discord ID
        function enter_your_discord_user_name_to_win(string memory discord) public waitingState{
            winnerDiscord = discord;
            winnerAddress = msg.sender;
            state = State.Done;
        }

        modifier onlyOwner 
        {
            require(msg.sender == creator);
            _;
        }

        modifier waitingState
        {
            require(state == State.Waiting);
            _;
        }
}