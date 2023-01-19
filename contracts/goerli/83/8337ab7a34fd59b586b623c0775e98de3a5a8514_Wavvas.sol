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

interface IOschuns {
    event FailedRefund(address _to, uint256 _value);
    
    function endTime() external view returns(uint256);

    function bidder(address) external returns(bool);
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
^^^^^::::::::::::::.:..:::..::.......................:::..::
^^^~~:::::::::::::::::.::............................:::..::
^^^^~:::::::::::......^^::::::........................::..::
^~~^~^:::::::...:^:^~!!^^^^^^^::.................:::::::::::
~!~~~~^^^::..:^~!J5YJ5PJ~^^^^^::::.............::::::::::::^
~!~~~~^^:....~Y5PPPGPGGP5?~^^^:^^::...........::::::::::::::
!!!!~^:...:..:!7?YPPPPPP57^^^^^:^^::.............:......:.::
J?!~:::^^~^:::^^^7?JY5P5~..::::::^^:.......................:
^^~~~~??!~~~^~7!7!~~7YPY:......::::........................:
^!!7!!?Y57~~~^!!J5Y?YPPY^.............................:...:~
~777JY5P5??JYJ!7JP5J?JY5?^::::::::::::::::::::::^^^~~^:..^!J
~~~~~7?Y55555555YJ7:..:^JJ7!~~~~~~~~~~~~~~!!!!777??7^..^~7YP
~??77?7!!77JYJYJ!:..::. .!??7???????7~^7???JJ??77!^:^~7Y5Y?!
:7YY55J7!!~7!^.....^^:....:^^~7JJJJ77!~!7JJ77!~^^^~~!7777^::
::^~~^^^:::^^:.:^^^::::~!!::~!!!!??7777!!!~^^^:~!!!!?7!~^~7J
::^~^^^^^!^^^^::.:^::^:!J?77!!?JYYJ7^:::::^~~~!!?YJ7~:^7JYYY
^~??7JJJJJ!~~^^^^^^!!!^:?55Y?777?JJYYJ?7???JJYY??!~^!7?JJYYY
~5PY5PPPJJYY5J~^^~:!JJ?7~~?5PYJ7!!!~!!!77!77?77!!?YYYJJ??JYY
?PPPPPPGPPGPPP7~7?!7!7JY5?~~!?JJJ???77!~^:::~7???7!~^^^^^^^^
*/

pragma solidity 0.8.15;

import {IZooOfNeuralAutomata} from "../interfaces/IZooOfNeuralAutomata.sol";
import {IOschuns} from "../interfaces/IOschuns.sol";
import {Owned} from "../../lib/solmate/src/auth/Owned.sol";

contract Wavvas is Owned {
    uint256 constant id = 2;
    uint256 constant price = 0.01618 ether;

    address public immutable zona;
    address public immutable oschun;
    uint256 public immutable startTime;

    constructor(
        address _owner,
        address _zona,
        address _oschun, 
        uint256 _startTime
    ) Owned(_owner) {
        zona = _zona;
        oschun = _oschun;
        startTime = _startTime;
    }

    function mint(uint256 amount) external payable {
        require(startTime <= block.timestamp || msg.sender == owner);
        uint256 endTime = IOschuns(oschun).endTime();
        require(endTime > block.timestamp);
        require(msg.value >= price * amount);

        IZooOfNeuralAutomata(zona).mint(msg.sender, id, amount);
    }

    function withdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}