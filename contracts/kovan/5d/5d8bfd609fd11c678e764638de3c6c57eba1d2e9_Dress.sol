/**
 *Submitted for verification at Etherscan.io on 2022-06-17
*/

pragma solidity 0.8.7;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
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
contract Dress is Ownable {
    uint256 public totalGold;
    uint256 public totalBlue;
    mapping(address => uint256) public userGold;
    mapping(address => uint256) public userBlue;
    uint256 public constant PRICE = 1 ether / 100;
    uint256 public constant STEP = 5 minutes;
    uint256 public ownerShare;
    uint256 public winnerShare;
    uint256 public constant OWNER_PERCENTAGE = 40;
    uint256 private goldOrBlue = 2;
    uint256 private constant GOLD = 0;
    uint256 private constant BLUE = 1;

    //solhint-disable-next-line var-name-mixedcase
    uint256 public immutable start_time;

    error InsufficientFunds();
    error InvalidWinnerID();
    error TransferTxError();

    constructor() {
        //solhint-disable-next-line not-rely-on-time
        start_time = block.timestamp;
    }

    function calculatePrice() internal view returns (uint256) {
        //solhint-disable-next-line not-rely-on-time
        uint256 timeDif = block.timestamp - start_time;
        return PRICE + (timeDif / STEP) * 0.00001 ether;
    }

    function updateShares() private {
        ownerShare += (msg.value * OWNER_PERCENTAGE) / 100;
        winnerShare += (msg.value * (100 - OWNER_PERCENTAGE)) / 100;
    }

    function gold(uint256 quantity) external payable {
        uint256 enterPrice = calculatePrice();
        uint256 fullPrice = quantity * enterPrice;
        if (msg.value < fullPrice) revert InsufficientFunds();

        userGold[msg.sender] += quantity;
        totalGold += quantity;
        updateShares();
    }

    function blue(uint256 quantity) external payable {
        uint256 enterPrice = calculatePrice();
        uint256 fullPrice = quantity * enterPrice;
        if (msg.value < fullPrice) revert InsufficientFunds();

        userBlue[msg.sender] += quantity;
        totalBlue += quantity;
        updateShares();
    }

    function winner(uint256 winnerId) external onlyOwner {
        if (winnerId != GOLD && winnerId != BLUE) revert InvalidWinnerID();
        goldOrBlue = winnerId;
    }

    function ownerWithdraw() external onlyOwner {
        uint256 share = ownerShare;
        ownerShare = 0;

        //solhint-disable-next-line avoid-low-level-calls
        (bool isSuccess, ) = payable(owner()).call{ value: share }("");
        if (!isSuccess) revert TransferTxError();
    }

    function winnerWithdraw() external {
        uint256 withdrawAmount;
        if (goldOrBlue == GOLD) {
            withdrawAmount = (winnerShare * userGold[msg.sender]) / totalGold;

            userGold[msg.sender] = 0;
        } else {
            withdrawAmount = (winnerShare * userBlue[msg.sender]) / totalBlue;

            userBlue[msg.sender] = 0;
        }
        //solhint-disable-next-line avoid-low-level-calls
        (bool isSuccess, ) = payable(msg.sender).call{ value: withdrawAmount }(
            ""
        );
        if (!isSuccess) revert TransferTxError();
    }
}