// SPDX-License-Identifier:MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

interface FULNFT_Interface {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function NFTStatus(uint256) external view returns (uint256, uint256);
}

contract FULGame is Ownable {
    /* 
    1656959400 (5 July)
    1657564200 (12 July)
    7 Days = 604800 In Epoch
    */

    struct GameWeek {
        uint startTime;
        uint endTime;
    }

    struct GameWeekSquad {
        uint[2] goalkeepers;
        uint[5] defenders;
        uint[5] midfielders;
        uint[3] attackers;
        uint totalLegendaryPlayers;
        uint totalRarePlayers;
        uint totalPoints;
        bool isCreated;
    }

    event SetGameWeak(uint at, uint startTime, uint endTime);
    event SquadCreated(address by, uint at);

    mapping(uint => GameWeek) public gameWeeks; // Insted Of Mapping Use Array And Take Game Week Data In Form Of Array
    mapping(address => mapping(uint => GameWeekSquad)) public userSquads;
    address public NFTContractAddress;
    uint public totalGameWeek;
    uint public curGameWeek;

    modifier isGameWeek(uint _gameWeek) {
        require(_gameWeek <= totalGameWeek, "Game Week Not Exists");
        _;
    }

    /*********** Below Given Methods Are Related To GameWeek And This Can Only Be Called By Contract Owner ***********/
    function isValidGameWeekTime(
        uint _gameWeek,
        uint _startTime,
        uint _endTime
    ) internal view returns (bool) {
        require(
            block.timestamp < _startTime,
            "Start Time Should Greater Than Current Time"
        );
        require(
            (_startTime + 604800) == _endTime,
            "There Should Be Fix Seven Days Gap Beteen Start And End Time"
        );
        if (_gameWeek > 1) {
            require(
                _startTime > gameWeeks[_gameWeek - 1].endTime,
                "Game Week's Start Time Should Greater Than End Time Of Previous Game Week"
            );
        }
        return true;
    }

    function setGameWeek(uint _startTime, uint _endTime) public onlyOwner {
        require(
            isValidGameWeekTime(totalGameWeek + 1, _startTime, _endTime) ==
                true,
            "Invalid Game Week Time"
        );
        totalGameWeek++;
        uint _curGameWeek = totalGameWeek;
        gameWeeks[_curGameWeek] = GameWeek(_startTime, _endTime);
        emit SetGameWeak(block.timestamp, _startTime, _endTime);
    }

    function changeGameWeek(
        uint _gameWeek,
        uint _startTime,
        uint _endTime
    ) public onlyOwner isGameWeek(_gameWeek) {
        require(
            isValidGameWeekTime(_gameWeek, _startTime, _endTime) == true,
            "Invalid Game Week Time"
        );
        gameWeeks[_gameWeek] = GameWeek(_startTime, _endTime);
        emit SetGameWeak(block.timestamp, _startTime, _endTime);
    }

    function setCurGameWeek(uint _curGameWeek)
        public
        onlyOwner
        isGameWeek(_curGameWeek)
    {
        curGameWeek = _curGameWeek;
    }

    function setNFTContractAddress(address _NFTContractAddress)
        public
        onlyOwner
    {
        NFTContractAddress = _NFTContractAddress;
    }

    /*********** Below Given Methods Are Related To GameWeek And This Can Only Be Called By Contract Owner ***********/

    modifier isSquadCreated() {
        require(
            userSquads[msg.sender][curGameWeek].isCreated == false,
            "You Has Already Created An Squad, You Can Only Modify Squad For Current Game Week"
        );
        _;
    }
    modifier isGameWeekSpecified() {
        require(curGameWeek > 0, "Game Week Is Not Specified By Admin");
        _;
    }
    modifier isGameStarted() {
        require(
            block.timestamp < gameWeeks[curGameWeek].startTime,
            "Game Is Started, Now You Cannot Create Or Update Your Game Week Squad"
        );
        _;
    }

    function validateSendedDeatils(
        uint[2] memory goalkeepers,
        uint[5] memory defenders,
        uint[5] memory midfielders,
        uint[3] memory attackers
    )
        internal
        view
        returns (
            uint,
            uint,
            bool
        )
    {
        address msgSender = msg.sender;
        uint _totalLegendry;
        uint _totalRare;

        FULNFT_Interface NFTContract = FULNFT_Interface(NFTContractAddress);
        for (uint i = 0; i < 2; ) {
            uint NFTId = goalkeepers[i];
            require(
                NFTContract.ownerOf(NFTId) == msgSender,
                "Given NFT Is Not Owned By You"
            );
            (uint NFTType, uint NFTPos) = NFTContract.NFTStatus(NFTId);
            require(NFTPos == 1, "NFT Position Is Not Goalkeepers");
            if (NFTType == 1) {
                _totalLegendry++;
            } else if (NFTType == 2) {
                _totalRare++;
            }
            unchecked {
                i++;
            }
        }

        for (uint i = 0; i < 5; ) {
            uint NFTId = defenders[i];
            require(
                NFTContract.ownerOf(NFTId) == msgSender,
                "Given NFT Is Not Owned By You"
            );
            (uint NFTType, uint NFTPos) = NFTContract.NFTStatus(NFTId);
            require(NFTPos == 2, "NFT Position Is Not Defenders");
            if (NFTType == 1) {
                _totalLegendry++;
            } else if (NFTType == 2) {
                _totalRare++;
            }
            if (_totalLegendry > 3 || _totalRare > 4) {
                return (0, 0, false);
            }
            unchecked {
                i++;
            }
        }

        for (uint i = 0; i < 5; ) {
            uint NFTId = midfielders[i];
            require(
                NFTContract.ownerOf(NFTId) == msgSender,
                "Given NFT Is Not Owned By You"
            );
            (uint NFTType, uint NFTPos) = NFTContract.NFTStatus(NFTId);
            require(NFTPos == 3, "NFT Position Is Not Midfielders");
            if (NFTType == 1) {
                _totalLegendry++;
            } else if (NFTType == 2) {
                _totalRare++;
            }
            if (_totalLegendry > 3 || _totalRare > 4) {
                return (0, 0, false);
            }
            unchecked {
                i++;
            }
        }

        for (uint i = 0; i < 3; ) {
            uint NFTId = attackers[i];
            require(
                NFTContract.ownerOf(NFTId) == msgSender,
                "Given NFT Is Not Owned By You"
            );
            (uint NFTType, uint NFTPos) = NFTContract.NFTStatus(NFTId);
            require(NFTPos == 4, "NFT Position Is Not Attackers");
            if (NFTType == 1) {
                _totalLegendry++;
            } else if (NFTType == 2) {
                _totalRare++;
            }
            if (_totalLegendry > 3 || _totalRare > 4) {
                return (0, 0, false);
            }
            unchecked {
                i++;
            }
        }
        return (_totalLegendry, _totalRare, true);
    }

    function setSquadData(
        uint _curGameWeek,
        uint[2] memory goalkeepers,
        uint[5] memory defenders,
        uint[5] memory midfielders,
        uint[3] memory attackers,
        uint _totalLegendry,
        uint _totalRare
    ) public {
        address msgSender = msg.sender;
        GameWeekSquad storage _userGameWeek = userSquads[msgSender][
            _curGameWeek
        ];
        _userGameWeek.totalLegendaryPlayers = _totalLegendry;
        _userGameWeek.totalRarePlayers = _totalRare;
        _userGameWeek.goalkeepers[0] = goalkeepers[0];
        _userGameWeek.goalkeepers[1] = goalkeepers[1];
        for (uint256 i = 0; i < 5; ) {
            _userGameWeek.defenders[i] = defenders[i];
            unchecked {
                i++;
            }
        }
        for (uint256 i = 0; i < 5; ) {
            _userGameWeek.midfielders[i] = midfielders[i];
            unchecked {
                i++;
            }
        }
        for (uint256 i = 0; i < 3; ) {
            _userGameWeek.attackers[i] = attackers[i];
            unchecked {
                i++;
            }
        }
        emit SquadCreated(msgSender, block.timestamp);
    }

    function createSquad(
        uint[2] memory goalkeepers,
        uint[5] memory defenders,
        uint[5] memory midfielders,
        uint[3] memory attackers
    ) public isGameWeekSpecified isGameStarted isSquadCreated {
        uint _curGameWeek = curGameWeek;
        address msgSender = msg.sender;
        (
            uint _totalLegendry,
            uint _totalRare,
            bool isValid
        ) = validateSendedDeatils(
                goalkeepers,
                defenders,
                midfielders,
                attackers
            );
        require(isValid == true, "Invalid Details");
        userSquads[msgSender][_curGameWeek].isCreated = true;
        setSquadData(
            _curGameWeek,
            goalkeepers,
            defenders,
            midfielders,
            attackers,
            _totalLegendry,
            _totalRare
        );
    }

    function updateSquad(
        uint[2] memory goalkeepers,
        uint[5] memory defenders,
        uint[5] memory midfielders,
        uint[3] memory attackers
    ) public isGameWeekSpecified isGameStarted {
        uint _curGameWeek = curGameWeek;
        address msgSender = msg.sender;
        require(
            userSquads[msgSender][_curGameWeek].isCreated == true,
            "You Has Not Created Any Squad"
        );
        (
            uint _totalLegendry,
            uint _totalRare,
            bool isValid
        ) = validateSendedDeatils(
                goalkeepers,
                defenders,
                midfielders,
                attackers
            );
        require(isValid == true, "Invalid Details");
        setSquadData(
            _curGameWeek,
            goalkeepers,
            defenders,
            midfielders,
            attackers,
            _totalLegendry,
            _totalRare
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}