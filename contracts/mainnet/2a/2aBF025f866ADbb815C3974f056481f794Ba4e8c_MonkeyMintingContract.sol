/**
 *Submitted for verification at Etherscan.io on 2023-02-03
*/

// File: contracts/TnmtLibrary.sol



/// @title TNMT Structs

pragma solidity ^0.8.17;

library ITnmtLibrary {

    struct Tnmt {
        uint256 auctionId;
        uint256 monkeyId;
        uint8 noColors;
        mapping(uint8 => ColorStr) colors;
        uint8 rotations;
        bool hFlip;
        bool vFlip;
    }

    struct Attributes {
        uint256 auctionId;
        uint256 monkeyId;
        uint8 noColors;
        uint8 rotations;
        bool hFlip;
        bool vFlip;
    }

    struct Edit {
        uint256 auctionId;
        uint256 monkeyId;
        uint8 manyEdits;
        uint8 rotations;
        ColorDec[3] colors;
        address editor;
    }

    struct ColorDec {
        uint8 colorId;
        uint8 color_R;
        uint8 color_G;
        uint8 color_B;
        uint8 color_A;
    }

    struct ColorStr {
        uint8 colorId;
        bytes color;
    }


}
// File: contracts/ITnmtToken.sol



/// @title Interface for tnmt Auction House


pragma solidity ^0.8.17;

interface ITnmtToken {

    function exists(uint256 a) external returns (bool);

    function ownerOf(uint256 a) external returns (address);

    function mint(address _to,
        uint256 _auctionId,
        uint256 _monkeyId,
        uint8 _rotations,
        address _editor,
        uint8 _manyEdits,
        ITnmtLibrary.ColorDec[3] memory editColors) external returns (uint256);

}
// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/MonkeyMintingContract.sol






pragma solidity ^0.8.17;

contract MonkeyMintingContract is Ownable {
    
    struct minter {
        address minter;
        uint8   wave;
        bool minted;
    }

    struct addMinter {
        address minter;
        uint8   wave;
    }

    struct mintRecord {
        uint8   wave;
        uint256   monkeyId;
    }

    event minted(address who, uint8 wave, uint256 monkeyId, uint256 tokenId);

    // The tnmt ERC721 contract
    address private tnmt;

    // Monkey address
    address private Monkey;

    // Minting current wave
    uint8 public currentWave;

    // Minting current wave
    bool public paused;

    // Are we still in minting phase?
    bool public mintingPhase;

    //mapping address to whiteList
    mapping(address => minter) whiteList;

    //mapping wave to minted MonkeyId's
    mapping(uint8 => uint256[]) mintedByWave;

    //mapping tokenId to wave and MonkeyID
    mapping(uint256 => mintRecord) recordByTokenId;

    /**
     *   Require that contract is not paused
     */
    modifier notPaused() {
        require(!paused, "Minting contract is paused");
        _;
    }

    /**
     *   Require that minting phase is live
     */
    modifier mintingPhaseLive() {
        require(mintingPhase, "Minting phase ended");
        _;
    }

    constructor(address _monkey) {
        Monkey = _monkey;
        paused = true;
        mintingPhase = true;
    }

    /**
     * Updates the TNMT Token contract address
     */
    function updateTnmtContract(address _tnmt) public onlyOwner returns(bool)  {

        tnmt = _tnmt;

        return true;
    }

    /**
     * Updates the status of mintingPhase
     */
    function endminting() public onlyOwner returns(bool)  {

        mintingPhase = false;

        return mintingPhase;
    }

    /**
     * Pauses the contract
     */
    function pauseContract() public onlyOwner returns(bool)  {

        paused = true;

        return paused;
    }

    /**
     * Unpauses the contract
     */
    function unPauseContract() public onlyOwner returns(bool)  {

        paused = false;

        return paused;
    }

    /**
     * Increments the current wave and pauses contract
     */
    function nextWave() public onlyOwner returns(uint8)  {

        currentWave = currentWave + 1;
        pauseContract();

        return currentWave;
    }
    /**
     * Decrements the current wave and pauses contract
     */
    function prevWave() public onlyOwner returns(uint8)  {
        require(currentWave > 0,"currentWave can not go below 0");

        currentWave = currentWave - 1;
        pauseContract();
        return currentWave;
    }

    /**
     * Returns the address whiteListed wave
     */
    function checkIfWL(address _address) public view returns(uint8) {

        return whiteList[_address].wave;
    }

    /**
     * Returns the address minted status
     */
    function checkWave(uint8 _wave) public view onlyOwner returns(uint256[] memory) {
        return mintedByWave[_wave];
    }

    /**
     * Returns the address minted status
     */
    function tokenToWaveAndMonkeyId(uint256 _tokenId) public view onlyOwner returns(mintRecord memory) {
        return recordByTokenId[_tokenId];
    }

    /**
     * Mints by wave
     */
    function checkIfMinted() public view returns(bool) {
        return whiteList[msg.sender].minted;
    }

    /**
     * Adds a new address to a wave in white list
     */
    function addToWhiteList(address _newWhiteList, uint8 _wave) public onlyOwner mintingPhaseLive returns(bool) {
        require(whiteList[_newWhiteList].wave == 0, "New address already White Listed");
        require(_wave > 0, "Can not add to whitelist in wave 0");

        whiteList[_newWhiteList].wave = _wave;
        whiteList[_newWhiteList].minted = false;

        return true;
    }

    /**
     * Adds a new address to a wave in white list
     */
    function BatchAddToWhiteList(addMinter[] memory _newMinters) public onlyOwner mintingPhaseLive returns(bool) {

        for (uint256 i = 0; i < _newMinters.length; i++) {
            require(whiteList[_newMinters[i].minter].wave == 0, "New address already White Listed");
            require(_newMinters[i].wave > 0, "Can not add to whitelist in wave 0");
        }

        for (uint256 i = 0; i < _newMinters.length; i++) {
            whiteList[_newMinters[i].minter].wave = _newMinters[i].wave;
            whiteList[_newMinters[i].minter].minted = false;
        }

        return true;
    }

    /**
     * Removes an address from whiteList
     */
    function removeFromWhiteList(address _whiteListed) public onlyOwner  returns(bool)  {
        require(whiteList[_whiteListed].wave > currentWave || currentWave == 0, "Address minting already happened or is currently live");
        require(whiteList[_whiteListed].wave > 0 , "Address not white listed");
        require(whiteList[_whiteListed].minted == false, "That address already minted");

        delete whiteList[_whiteListed];

        return true;
    }

    /**
     * Changes an already White Listed address permitted minting wave
     */
    function changeWhiteListWave(address _whiteListed, uint8 _newWave) public onlyOwner mintingPhaseLive returns(bool)  {
        require(whiteList[_whiteListed].minted == false);
        require(whiteList[_whiteListed].wave >= currentWave);

        whiteList[_whiteListed].wave = _newWave;

        return true;
    }

    /**
     * Checkes if a certain monkeyId is already minted in the given wave
     */
    function isMintedInWave(uint256 _monkeyId, uint8 _wave) public view returns (bool) {
        require(_monkeyId < 2000, "Monkey Id must be less than 2000");

        for (uint256 i = 0; i < mintedByWave[_wave].length; i++) {
            if (mintedByWave[_wave][i] == _monkeyId) {
                return true;
            }

        }
        return false;
    }

    /**
     * Adds a monkeyId to the minted list if said monkeyId hasn't been added yet
     */
    function addMinted(uint256 _monkeyId, uint8 _wave) internal {
        require(!isMintedInWave(_monkeyId, _wave), "Monkey Id already minted in this wave.");
        mintedByWave[_wave].push(_monkeyId);
    }

    /**
     * Allows a white listed address to mint if its current wave is live
     */
    function mint(uint256 _monkeyId, uint8 _rots) external notPaused mintingPhaseLive returns(bool)  {
        require(_monkeyId < 2000, "Monkey Id must be less than 2000");
        require(_rots < 4, "Rots must be less than 4");

        if(currentWave == 0) {
            require(msg.sender == Monkey, "Minting has not yet started, hang tight");
        }

        require(whiteList[msg.sender].minted == false, "Minter already minted >.<");
        require(whiteList[msg.sender].wave == currentWave, "Address not White Listed for current wave");

        addMinted(_monkeyId, currentWave);
        whiteList[msg.sender].minted = true;

        ITnmtLibrary.ColorDec[3] memory emptyColors;

        uint256 token = ITnmtToken(tnmt).mint( msg.sender,
        currentWave,
        _monkeyId,
        _rots,
        address(0),
        0,
        emptyColors);

        recordByTokenId[token].wave = whiteList[msg.sender].wave;
        recordByTokenId[token].monkeyId = _monkeyId;

        emit minted(msg.sender, currentWave, _monkeyId, token);

        return true;
    }

}