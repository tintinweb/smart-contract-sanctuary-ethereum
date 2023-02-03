// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

struct NCAParams {
    string seed;
    string bg;
    string fg1;
    string fg2;
    string matrix;
    string activation;
    string rand;
    string mods;
}

interface INeuralAutomataEngine {
    function baseScript() external view returns(string memory);

    function parameters(NCAParams memory _params) external pure returns(string memory);

    function p5() external view returns(string memory);

    function script(NCAParams memory _params) external view returns(string memory);

    function page(NCAParams memory _params) external view returns(string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {NCAParams} from "./INeuralAutomataEngine.sol";

interface IZooOfNeuralAutomata {

    function updateEngine(address _engine) external;

    function updateContractURI(string memory _contractURI) external;

    function updateParams(uint256 _id, NCAParams memory _params) external;

    function updateMinter(uint256 _id, address _minter) external;

    function updateBurner(uint256 _id, address _burner) external;

    function updateBaseURI(uint256 _id, string memory _baseURI) external;

    function freeze(uint256 _id) external;

    function newToken(
        uint256 _id,
        NCAParams memory _params, 
        address _minter, 
        address _burner,
        string memory _baseURI
    ) external;

    function mint(
        address _to,
        uint256 _id,
        uint256 _amount
    ) external;

    function burn(
        address _from,
        uint256 _id,
        uint256 _amount
    ) external;
    
}

/* SPDX-License-Identifier: MIT
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNNNXXXXKKXWWWMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNNXXNNWWWMMMMMMMMMMMMMMWXKOkxdooollolloxkkOKNMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMWNK0kxddolodxxkO0XNWMWWWWWNKOxolccccccccccccccccllxXWWWWWWMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMWX0xolccccccccccccccldkOOOkxxolcccccccc:::::::::::::::oxddddxk0NWMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMWN0xocccccc::;;;;;;;;;;::::::::ccccc:::::;;;;;;;;;;;;,,,;:::::;,;:dOXNWMMMMMMM
MMMMMMMMMMMMMMMMMMMWX0xolcccc::;;;;;:::::::::::;;;;;;:::;;;;;:cccc:::;;;;;;;;;::::;;;,,,;:lx0NMMMMMM
MMMMMMMMMMMMMMMMMWXkoc::cc::;;;;::ccccccc::;;;;;;;;;;;;,,,;;;;:::;;,,,;:::;::;,''''',;ccc:;;lxKNWWMM
MMMMMMMMMMMMMMMWXOocccccc:;;;:ccccccc:::;;;,,,,;;;;;;;;;;,,,''',,,,;;:::::lc,...     .lOXX0kdokXWMMM
MMMMMMMMMMMMMWNOoccccccccc::cccccc::;;;;;;;;::::::::;;:coolc:;;,,;::::cok0k, .od, ... .:0WMMNK0XWMMM
MMMMMMMMMMMMMXxlcccccccccccccccc:;;;;;;;::::c;'.....  .'lkKXXX0kc,;cdOKNWO;  .''.'xKx'  cKMMMNKKWMMM
MMMMMMMMMMMWKdcccccccccccccc:::;;;;;;;::::lo;..co,.  ... .c0WMMNklxKWWMMNo.  .:;..;l;.  'kNX0O0NWMMM
MMMMMMMMWN0xc;:ccccccccccccc:;;;;;;::;;:oOKx' .,:.  .l0x'  ;0WMWXXWMMMMMNx.   ;o:.      'ldookXWMMMM
MMMMMMWNOdlc;;:cccccccccc:;;;;;;;:::cld0NWK:    .;,..;oc.  .lXN0xkKNNXXXXO:.  .',.   ..';:coOXWMMMMM
MMMMMWXxlcc:,,:cccccccccc:;;;;;;,;lkKNWMMMXc    ;xkc.      .,ll:,;coolllll:,''',,,,;;:::ldOXWMMMMMMM
MMMMWXklccc::;:cccccccccccc:::::;:cdxkO0XNNk'   .;ol'   ..',;;;;;::::::::::ccc:::ccccc:cd0NWMMMMMMMM
MMMMNOlcccccccccccccccccccccccccccccccc::ccc;'...',,,,,;::ccc:ccccccccccccccccccccccccco0NMWWWMMMMMM
MMMW0occccccccccccccccccccccccccccccc:;,',,,,,,;;;;:::ccccccccccccccccccccccccccccccc:;;lOWMMMMMMMMM
MMMXdcccccccccccccccccccccccccccccccc;',::;;;;;;,,,,,,,,,;;:::::cccccccccccccc::::;;,,,,;oXWMMMMMMMM
MMWOl:ccccccccccccccccccccccccccccccc;'';:'..'',,;;;;;;;,,,,,,,,;;;;;;;;;;;;;,,,,,,,,,:oOXWWMMMMMMMM
MMXd::cccccccccccccccccccccccccccccccc:,,,;,'...'''''',,,,;;;;;;;;,,,,,,,,,'','''''.;d0NWMMMMMMMMMMM
MWKo:cccccccccccccccccccccccccccccccccc:;,,;;,,''.'''.......''''''''''...':llooc;'',cxKWMMMMMMMMMMMM
MWKdccccccccccccccccccccccccccccccccccccc:;,,,;;;,'...';c:;,'..'''''''''..:k0000Odc',:lkNMMMMMMMMMMM
WWKdlcccccccccccccccccccccccccccccccccccccc::;,,;;;;;,;:cooool:'...'''''..:x00OOOko,';;:OWMMMMMMMMMM
WN0occcccccccccccccccccccccccccccccccccccc:::c::;,',,;;;;;;;:cc:,. .....'ldxdolc:;;;;;;oKWMMMMMMMMMM
WKo::cccccccccccccccccccccccccccccccccccccccccccc:::;,'',,;;;;;;;,,,,',,::::;;;;;;,.':xXWMMMMMMMMMMM
WKl,,;:cccccccccccccccccccccccccccccccccccccccccccccc::;;,,',,,,,,,,,,,,,,,'''''''..c0WMMMMMMMMMMMMM
Nk:'''',;::cccccccccccccccccccccccccccccccccccccccccc:ccccc:::;;,'''''''''''',;;::,,lOXXKXNMMMMMMMMM
Ko,''''''',,;;;;::::cccccccccccccccccccccccccccccccccccccccccccccc::::::::;;;;;;,,'',;:::lkXWMMMMMMM
0l''''''''''''''',,,,,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,,,,,'''''''''''''''''''';cxKWMMMMM
o,'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''',ckXWMMM
:''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''';dKWMM
,'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''',oKWM
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''';kNM
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''';kNM
*/

pragma solidity 0.8.15;

import {IZooOfNeuralAutomata} from "../interfaces/IZooOfNeuralAutomata.sol";
import {Owned} from "../../lib/solmate/src/auth/Owned.sol";

contract Spaces is Owned {

    address public immutable zona;
    uint256 public immutable startTime;
    uint256 public immutable endTime;

    mapping(address => bool) public claimed;

    constructor(
        address _owner, 
        address _zona, 
        uint256 _startTime
    ) Owned(_owner) {
        zona = _zona;
        startTime = _startTime;
        endTime = _startTime + 2 hours;
    }

    function mint() external {
        require(startTime <= block.timestamp || msg.sender == owner);
        require(endTime >= block.timestamp);
        require(!claimed[msg.sender]);
        claimed[msg.sender] = true;
        IZooOfNeuralAutomata(zona).mint(msg.sender, 4, 1);
    }
}