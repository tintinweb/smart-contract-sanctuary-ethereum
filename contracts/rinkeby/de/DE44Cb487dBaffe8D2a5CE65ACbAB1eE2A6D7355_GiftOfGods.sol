// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Board {
    uint256 public creationDate;
    address public zeus;
    address[2] public semigod;
    address[4] public hero;
    address[8] public devoted;
    uint256 public amount;

    bool public open = true;
    uint256 public sponsorEndTime;

    constructor() {}

    function close() public {
        open = false;
    }

    function setCreationDate(uint256 _creationDate) public {
        creationDate = _creationDate;
    }

    function setAmount(uint256 _amount) public {
        amount = _amount;
    }

    function setZeus(address _zeus) public {
        zeus = _zeus;
    }

    function setSemigod(address[2] memory _semigod) public {
        semigod = _semigod;
    }

    function setHero(address[4] memory _hero) public {
        hero = _hero;
    }

    function setDevoted(address[8] memory _devoted) public {
        devoted = _devoted;
    }

    function getSemigod() public view returns (address[2] memory) {
        return semigod;
    }

    function getHero() public view returns (address[4] memory) {
        return hero;
    }

    function getDevoted() public view returns (address[8] memory) {
        return devoted;
    }

    function getSponsorEndTime() public view returns (uint256) {
        if (isSponsored()) return sponsorEndTime;
        return 0;
    }

    function joinNextFreeSpot(address _address) public returns (bool) {
        uint256 nextDevotedSpotIndex = nextDevotedSpot();
        if (nextDevotedSpotIndex != 69) {
            devoted[nextDevotedSpotIndex] = _address;

            if (nextDevotedSpotIndex == devoted.length - 1) return true; // needs to create a new board
            return false;
        }

        return true;
    }

    function nextDevotedSpot() private view returns (uint256) {
        for (uint256 i = 0; i < devoted.length; i++) {
            if (devoted[i] == address(0)) return i;
        }

        return 69;
    }

    function sponsor(uint256 _sponsorDuration) public {
        if (isSponsored()) {
            sponsorEndTime = sponsorEndTime + _sponsorDuration;
        } else {
            sponsorEndTime = block.timestamp + _sponsorDuration;
        }
    }

    function isSponsored() public view returns (bool) {
        if (sponsorEndTime == 0) return false;

        return sponsorEndTime > block.timestamp;
    }
}

contract GiftOfGods is Ownable {
    Board[] private boards;

    uint256 public minPrice;

    uint256 public sponsorPricePerDay;

    event newBoardEvent(
        uint256 indexed _boardId,
        address indexed _zeus,
        address[2] _semigod,
        address[4] _hero,
        address[8] _devoted,
        uint256 _amount
    );

    event closeBoardEvent(
        uint256 indexed _boardId,
        address indexed _zeus,
        uint256 _amount
    );

    event joinBoardEvent(uint256 indexed _boardId, address indexed _address);

    event sponsorEvent(
        uint256 indexed _boardId,
        address indexed _address,
        uint256 _amount,
        uint256 _time
    );

    constructor() {}

    function newBoardAdmin(
        uint256 _amount,
        address _zeus,
        address[2] memory _semigod,
        address[4] memory _hero,
        address[8] memory _devoted
    ) external onlyOwner {
        uint256 boardId = _newboard(_zeus, _semigod, _hero, _devoted, _amount);

        emit joinBoardEvent(boardId, _zeus);

        for (uint256 i = 0; i < _semigod.length; i++) {
            emit joinBoardEvent(boardId, _semigod[i]);
        }
        for (uint256 i = 0; i < _hero.length; i++) {
            emit joinBoardEvent(boardId, _hero[i]);
        }
        for (uint256 i = 0; i < _devoted.length; i++) {
            emit joinBoardEvent(boardId, _devoted[i]);
        }
    }

    function newBoard(uint256 _amount) public payable {
        require(_amount >= minPrice, "Amount sent is not enough");
        require(msg.value >= _amount, "Amount sent is not consistent");

        uint256 boardId = _newboard(
            address(this),
            [address(this), address(this)],
            [address(this), address(this), address(this), address(this)],
            [
                msg.sender,
                address(0),
                address(0),
                address(0),
                address(0),
                address(0),
                address(0),
                address(0)
            ],
            _amount
        );

        emit joinBoardEvent(boardId, msg.sender);
    }

    function _newboard(
        address _zeus,
        address[2] memory _semigod,
        address[4] memory _hero,
        address[8] memory _devoted,
        uint256 _amount
    ) internal returns (uint256) {
        Board board = new Board();

        board.setCreationDate(block.timestamp);
        board.setZeus(_zeus);
        board.setAmount(_amount);

        board.setSemigod(_semigod);
        board.setHero(_hero);
        board.setDevoted(_devoted);

        boards.push(board);

        uint256 boardId = boards.length - 1;

        emit newBoardEvent(boardId, _zeus, _semigod, _hero, _devoted, _amount);

        return boardId;
    }

    function joinBoard(uint256 _boardId) external payable {
        Board board = boards[_boardId];

        require(board.open(), "Board is closed");
        require(msg.value >= board.amount(), "Amount is too little");

        if (board.zeus() != address(this))
            payable(board.zeus()).transfer(board.amount());

        bool isCreateNewBoardNeeded = board.joinNextFreeSpot(msg.sender);

        if (isCreateNewBoardNeeded) {
            uint256 newBoardId;

            newBoardId = _newboard(
                board.semigod(0),
                [board.hero(0), board.hero(1)],
                [
                    board.devoted(0),
                    board.devoted(1),
                    board.devoted(2),
                    board.devoted(3)
                ],
                [
                    address(0),
                    address(0),
                    address(0),
                    address(0),
                    address(0),
                    address(0),
                    address(0),
                    address(0)
                ],
                board.amount()
            );

            emit joinBoardEvent(newBoardId, board.semigod(0));
            emit joinBoardEvent(newBoardId, board.hero(0));
            emit joinBoardEvent(newBoardId, board.hero(1));
            emit joinBoardEvent(newBoardId, board.devoted(0));
            emit joinBoardEvent(newBoardId, board.devoted(1));
            emit joinBoardEvent(newBoardId, board.devoted(2));
            emit joinBoardEvent(newBoardId, board.devoted(3));

            newBoardId = _newboard(
                board.semigod(1),
                [board.hero(2), board.hero(3)],
                [
                    board.devoted(4),
                    board.devoted(5),
                    board.devoted(6),
                    board.devoted(7)
                ],
                [
                    address(0),
                    address(0),
                    address(0),
                    address(0),
                    address(0),
                    address(0),
                    address(0),
                    address(0)
                ],
                board.amount()
            );

            emit joinBoardEvent(newBoardId, board.semigod(1));
            emit joinBoardEvent(newBoardId, board.hero(2));
            emit joinBoardEvent(newBoardId, board.hero(3));
            emit joinBoardEvent(newBoardId, board.devoted(4));
            emit joinBoardEvent(newBoardId, board.devoted(5));
            emit joinBoardEvent(newBoardId, board.devoted(6));
            emit joinBoardEvent(newBoardId, board.devoted(7));

            board.close();
            emit closeBoardEvent(_boardId, board.zeus(), board.amount());
        } else {
            emit joinBoardEvent(_boardId, msg.sender);
        }
    }

    function sponsorAdmin(uint256 _boardId, uint256 _amount)
        external
        onlyOwner
    {
        _sponsor(_boardId, _amount);
    }

    function sponsor(uint256 _boardId) external payable {
        require(msg.value > sponsorPricePerDay, "Amount too little");

        _sponsor(_boardId, msg.value);
    }

    function _sponsor(uint256 _boardId, uint256 _amount) internal {
        Board board = boards[_boardId];

        uint256 sponsorTime = _amount / sponsorPricePerDay;

        board.sponsor(sponsorTime);

        emit sponsorEvent(_boardId, msg.sender, _amount, sponsorTime);
    }

    function getBoardData(uint256 _boardId)
        external
        view
        returns (
            uint256 creationDate,
            address zeus,
            address[2] memory semigod,
            address[4] memory hero,
            address[8] memory devoted,
            uint256 amount,
            bool open,
            uint256 sponsorEndTime
        )
    {
        Board board = boards[_boardId];

        return (
            board.creationDate(), // 0
            board.zeus(), // 1
            board.getSemigod(), // 2
            board.getHero(), // 3
            board.getDevoted(), // 4
            board.amount(), // 5
            board.open(), // 6
            board.getSponsorEndTime() // 7
        );
    }

    function setMinPrice(uint256 _amount) external onlyOwner {
        minPrice = _amount;
    }

    function setSponsorPricePerDay(uint256 _amount) external onlyOwner {
        sponsorPricePerDay = _amount;
    }

    function withdraw(uint256 _amount) external onlyOwner {
        payable(msg.sender).transfer(_amount);
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