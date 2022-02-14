/**
 *Submitted for verification at Etherscan.io on 2022-02-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view  returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract StickClub is IERC721Receiver, Ownable{

    //Stick properties 
    struct StickAttributes{
        address stickOwner;
        bool inLine;
        bool inFight;
        uint8 totalWins;
        uint8 totalLoses;
    }

    //User's stick 
    struct UserSticks{
        uint256 balance;
        uint8 [] stickIds;
        //Stick index;
        mapping(uint8 => uint) stickIndex;
    }

    //winner=0 unfinished game
    struct FightStats {
        uint256 prize;
        uint8 playerOne;
        uint8 playerTwo;
        uint8 winner;
    }

    mapping(uint8 => StickAttributes) private stick; 
    mapping(uint8 => FightStats) private fightLogs; 
    mapping(address=> UserSticks) private userSticks;

    address public STICK; 
    address public treasury;
    uint256 public fightFee=1 ether;
    uint256 public collectedFees;
    bool public fightPaused = false;
    uint8 public treasuryPercentage=10;
    uint8 public fightNumber = 0;

    event FightStarted(uint8 indexed fightId, uint8 indexed stickOne, uint8 indexed stickTwo);
    event FightEnded(uint8 indexed fightId, uint8 indexed winnerStick, uint256 indexed prize, uint256 treasuryFee);

    function setFightFee(uint256 _fee) public onlyOwner {
        fightFee = _fee;
    }

    //Sets the stick (NFT) contract.
    function setSTICKAddress(address _contract) public onlyOwner {
        STICK = _contract;
    }
    
    //Sets treasury address that where the fee will be withdrawn 
    function setTreasuryAddress(address _treasury) public onlyOwner {
        treasury = _treasury;
    }

    //Sets treasure fee in percentage that is the fee each fight
    function setTreasuryFeePercentage(uint8 _treasuryPercentage) public onlyOwner{
        require(_treasuryPercentage<=40, "Can't be more than 40%");
        treasuryPercentage=_treasuryPercentage;
    }
    //Checks the owner of the stick NFT using token ID
    function checkStickOwner(uint8 _stickId) internal view returns(address) {
        require (STICK!=address(0), "STICK NFT hasn't added yet");
        return IERC721(STICK).ownerOf(_stickId);
    }
    
    function pauseFight() public onlyOwner{
        fightPaused=true;
    }   

    function unPauseFight() public onlyOwner{
        fightPaused=false; 
    }

    //Register NFT to StickClub (queue) to fight (Stake)
    function getReadyToFight(uint8 _stickId) public{
        require(!fightPaused, "Fight is paused");
        require (msg.sender == checkStickOwner(_stickId), "Address is not owner of STICK");
        require(!stick[_stickId].inLine, "STICK already ready to fight");    
        IERC721(STICK).safeTransferFrom(msg.sender, address(this), _stickId);
        stick[_stickId].inLine=true;
        stick[_stickId].stickOwner=msg.sender;
        userSticks[msg.sender].stickIds.push(_stickId);
        uint arrayLength=(userSticks[msg.sender].stickIds).length;
        userSticks[msg.sender].stickIndex[_stickId]=arrayLength-1;
    }

    //Get NFT out from the queue (Don't want to fight anymore)
    function stayAwayFromFight(uint8 _stickId) public{
        require (stick[_stickId].stickOwner==msg.sender, "STICK does not belong to sender");
        require(stick[_stickId].inLine, "User's STICK is not ready to fight");
        require(!stick[_stickId].inFight, "User's STICK is in Fight");
        IERC721(STICK).safeTransferFrom(address(this), msg.sender, _stickId);   
        stick[_stickId].inLine=false;
        uint indexRemovedStick=userSticks[msg.sender].stickIndex[_stickId];
        uint lastIndex=(userSticks[msg.sender].stickIds).length-1;
        userSticks[msg.sender].stickIds[indexRemovedStick]=userSticks[msg.sender].stickIds[lastIndex];
        userSticks[msg.sender].stickIds.pop();
    }

    //Add FTM to user's balance
    function addBalance() public payable{
        require(!fightPaused, "Fight is paused");
        userSticks[msg.sender].balance+=msg.value;
    }

    //Show user's stick and balance
    function mySticks() public view returns (uint256 balance, uint8 [] memory sticks){
        return (userSticks[msg.sender].balance, userSticks[msg.sender].stickIds);
    }

    //Withdraw user's balance/contract fee out of the contract
    function withdrawBalance(uint256 _withdrawAmount) public {
        require (_withdrawAmount<=userSticks[msg.sender].balance,"Not enough FTM balance");
        require(payable(msg.sender).send(_withdrawAmount));
        userSticks[msg.sender].balance-=_withdrawAmount;
    }

    function withdrawToTreasury(uint256 _collectedFees) public{
        require (treasury!=address(0), "Treasury address hasn't been added yet");
        require (_collectedFees<=collectedFees,"Not enough collected FTM");
        require(payable(treasury).send(_collectedFees));
        collectedFees-=_collectedFees;
    }

    //Once the fight starts 
    function startFight(uint8 _stickOne, uint8 _stickTwo) public onlyOwner returns(uint8) {
        require (!fightPaused, "Fights are paused");
        require(stick[_stickOne].inLine && stick[_stickTwo].inLine, "Either one or both stick are not in lobby");
        require(!stick[_stickOne].inFight && !stick[_stickTwo].inFight, "Either one or both stick are in fight");
        require(userSticks[stick[_stickOne].stickOwner].balance >=fightFee && userSticks[stick[_stickTwo].stickOwner].balance >=fightFee, "Either one or both stick don't have enough fight fee");
        userSticks[stick[_stickOne].stickOwner].balance-=fightFee;
        userSticks[stick[_stickTwo].stickOwner].balance-=fightFee;
        stick[_stickOne].inFight=true;
        stick[_stickTwo].inFight=true;
        fightNumber++;
        //Keep record of figth
            fightLogs[fightNumber] = FightStats({
                playerOne:_stickOne,
                playerTwo:_stickTwo,
                winner:0,
                prize:0
            });
        emit FightStarted(fightNumber, _stickOne, _stickTwo);
        return fightNumber;
    }

    //Once fight is finished
    function endFight(uint8 _fightId, uint8 _winnerStick) public onlyOwner {
        require(_fightId<=fightNumber,"Fight ID does not exist");
        require (fightLogs[_fightId].winner==0, "Fight has been already finished");
        require(_winnerStick== fightLogs[_fightId].playerOne || _winnerStick== fightLogs[_fightId].playerTwo, "Winner was not in this fight ID");
        if(_winnerStick==fightLogs[_fightId].playerOne){
            fightLogs[_fightId].winner=1;
            stick[fightLogs[_fightId].playerOne].totalWins++;
            stick[fightLogs[_fightId].playerTwo].totalLoses++;
        }else{
            fightLogs[_fightId].winner=2;
            stick[fightLogs[_fightId].playerTwo].totalWins++;
            stick[fightLogs[_fightId].playerOne].totalLoses++;                        
        }
        userSticks[stick[_winnerStick].stickOwner].balance+=(2*fightFee*(100-treasuryPercentage))/100;
        fightLogs[_fightId].prize=(2*fightFee*(100-treasuryPercentage))/100;
        collectedFees+=(2*fightFee*treasuryPercentage)/100;
        stick[fightLogs[_fightId].playerOne].inFight=false;
        stick[fightLogs[_fightId].playerTwo].inFight=false;
        emit FightEnded(_fightId, _winnerStick, (2*fightFee*(100-treasuryPercentage))/100, (2*fightFee*treasuryPercentage)/100);
    }

    function fightLog(uint8 _fightId) public view returns(uint8 playerOne,uint8 playerTwo,uint8 winner,uint256 prize){
        require(fightLogs[_fightId].winner!=0 && _fightId<=fightNumber, "Game log is not ready yet");
        return (fightLogs[_fightId].playerOne, fightLogs[_fightId].playerTwo, fightLogs[_fightId].winner, fightLogs[_fightId].prize);
    }

    function stickStats(uint8 _stickId) public view returns(bool inFight, bool inLine, uint8 totalWins, uint8 totalLoses){
        return (stick[_stickId].inFight,stick[_stickId].inLine,stick[_stickId].totalWins, stick[_stickId].totalLoses);
    }

    function onERC721Received(address, address, uint256, bytes calldata ) public view override returns (bytes4) {        
        return IERC721Receiver(this).onERC721Received.selector;
    }
}