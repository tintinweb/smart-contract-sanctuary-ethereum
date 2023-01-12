// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "AggregatorV3Interface.sol";
import "Ownable.sol";

contract Outlier is Ownable {

    // VARIABLES DEFINED AT THE DEPLOYMENT OF THE CONTRACT
    mapping(address => uint256) addressToChosenNumber;
    address[] private playerAddress;
    uint256[] private playerNumber;

    uint256 private constantUSD = 10 ** 26;
    uint256 private entryUSDFee = 10 * constantUSD;
    uint256 private entryETHFee = getEntryETHFee(entryUSDFee);
    uint256 private totalJackpot = 0;

    enum OUTLIER_STATE {
        OPEN,
        CLOSED
    }
    OUTLIER_STATE private outlier_state;

    constructor(){
        outlier_state = OUTLIER_STATE.OPEN;
    }

    // FUNCTIONS TO GET THE INPUTS FROM THE USERS
    function selectOutlierNumber(uint256 chosenNumber) payable public {
        require(outlier_state == OUTLIER_STATE.OPEN, "The Outlier Game is closed");
        require(addressToChosenNumber[msg.sender] == 0, "You have already played for today");
        require(msg.value >= ( entryETHFee - 10 ) && msg.value <= ( entryETHFee + 10 ), "You are not sending enough ETH");
        addressToChosenNumber[msg.sender] = chosenNumber;
        playerAddress.push(msg.sender);
        playerNumber.push(chosenNumber);
        totalJackpot += msg.value;
    }

    function endOutlierGame() onlyOwner public {
        require(outlier_state == OUTLIER_STATE.OPEN, "The Outlier Game is closed");
        outlier_state = OUTLIER_STATE.CLOSED;
    }

    function getPlayerNumber() onlyOwner public view returns(uint256[] memory){
        require(outlier_state == OUTLIER_STATE.CLOSED, "The Outlier Game is open");
        return playerNumber;
    }

    function getPlayerLength() onlyOwner public view returns(uint256){
        return playerNumber.length;
    }

    function getPlayerAddress() onlyOwner public view returns(address[] memory){
        require(outlier_state == OUTLIER_STATE.CLOSED, "The Outlier Game is open");
        return playerAddress;
    }

    function getTotalJackpot() onlyOwner public view returns(uint256){
        require(outlier_state == OUTLIER_STATE.CLOSED, "The Outlier Game is open");
        return totalJackpot;
    }

    function payOutlierWinners(uint256 jackpot, address winner) payable onlyOwner public {
        require(outlier_state == OUTLIER_STATE.CLOSED, "The Outlier Game is open");
        payable(winner).transfer(jackpot);
    }

    function startOutlierGame() onlyOwner public {
        require(outlier_state == OUTLIER_STATE.CLOSED, "The Outlier Game is open");
        for (uint256 i=0; i < playerNumber.length; i++) {
            addressToChosenNumber[ playerAddress[i] ] = 0;
        }
        playerNumber = new uint256[](0);
        playerAddress = new address[](0);
        totalJackpot = 0;
        entryETHFee = getEntryETHFee(entryUSDFee);
        outlier_state = OUTLIER_STATE.OPEN;
    }

    function checkBalance() onlyOwner public view returns(uint256) {
        return(address(this).balance);
    }

    function withdrawBalance() onlyOwner public {
        require(outlier_state == OUTLIER_STATE.CLOSED, "The Outlier Game is open");
        payable(owner()).transfer(address(this).balance);
    }
    
    function getEntryETHFee(uint256 entryUSDFee) private returns(uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
        (,int price,,,) = priceFeed.latestRoundData();
        uint256 newEntryETHFee = entryUSDFee / uint256(price);
        return newEntryETHFee;         
    }

    function checkEntryETHFee() public view returns(uint256){     
        return entryETHFee;
    }

    function checkEntryUSDFee() public view returns(uint256){     
        return entryUSDFee / constantUSD;
    }
    
    function checkOutlierGameState() public view returns(uint256) {
        return uint256(outlier_state);
    }

    function updateEntryUSDFee(uint256 newEntryUSDFee) onlyOwner public {
        require(outlier_state == OUTLIER_STATE.CLOSED, "The Outlier Game is open");
        entryUSDFee = newEntryUSDFee * constantUSD;
        entryETHFee = getEntryETHFee(entryUSDFee);
    }

    function fundMe() payable onlyOwner public{
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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