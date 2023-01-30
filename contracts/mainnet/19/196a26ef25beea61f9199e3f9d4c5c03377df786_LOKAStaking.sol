/**
 *Submitted for verification at Etherscan.io on 2023-01-30
*/

pragma solidity ^0.8.0;


// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
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

contract Membership is Context {
    address private owner;
    event MembershipChanged(address indexed owner, uint256 level);
    event OwnerTransferred(address indexed preOwner, address indexed newOwner);

    mapping(address => uint256) internal membership;

    constructor() {
        owner = _msgSender();
        setMembership(_msgSender(), 1);
    }

    function transferOwner(address newOwner) public onlyOwner {
        address preOwner = owner;
        setMembership(newOwner, 1);
        setMembership(preOwner, 0);
        owner = newOwner;
        emit OwnerTransferred(preOwner, newOwner);
    }

    function setMembership(address key, uint256 level) public onlyOwner {
        membership[key] = level;
        emit MembershipChanged(key, level);
    }

    modifier onlyOwner() {
        require(isOwner(), "Membership : caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return _msgSender() == owner;
    }


    modifier onlyAdmin() {
        require(isAdmin(), "Membership : caller is not a admin");
        _;
    }

    function isAdmin() public view returns (bool) {
        return membership[_msgSender()] == 1;
    }

    modifier onlyMinter() {
        require(isMinter(), "Memberhsip : caller is not a Minter");
        _;
    }

    function isMinter() public view returns (bool) {
        return isOwner() || membership[_msgSender()] == 11;
    }
    
    function getMembership(address account) public view returns (uint256){
        return membership[account];
    }
}

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)
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

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

contract Transmitter is Membership {
    function checkToken(address token, address payer, uint256 amount) public view {
        require(IERC20(token).balanceOf(payer)>=amount, "Insufficient balance");
        require(IERC20(token).allowance(payer, address(this))>=amount, "Not approved");
    }
    function checkNft(address nft, address owner, uint256 tokenId) public view {
        require(IERC721(nft).ownerOf(tokenId) == owner, "Not owner");
        require(IERC721(nft).isApprovedForAll(owner, address(this)), "Not approved");
    }
    function transferToken(address token, address payer, address receiver, uint256 amount) public onlyMinter{
        IERC20(token).transferFrom(payer, receiver, amount);
    }
    function transferNft(address nft, address owner, address proposer, uint256 tokenId) public onlyMinter{
        IERC721(nft).transferFrom(owner, proposer, tokenId);
    }
}

contract LOKAStaking is Membership{
    event Stake(address indexed from, uint256 indexed continent, uint256 amount);
    event Unstake(address indexed from, uint256 indexed continent, uint256 amount);
    address payable private receiver;
    address LOKA;
    Transmitter transmitter;
    address[] internal stakers;
    mapping(uint256 => uint256) private continents;
    mapping(address => mapping (uint256 => uint256) ) public stakes;
    mapping(address => uint256) public indexes;

    constructor(address _loka, Transmitter _transmitter) {
        setLoka(_loka);
        setTransmitter(_transmitter);
        setReceiver(payable(_msgSender()));
    }
    function setTransmitter(Transmitter _transmitter) public onlyOwner {
        transmitter = _transmitter;
    }
    function setReceiver(address payable _receiver) public onlyOwner {
        receiver = _receiver;
    }
    function setLoka(address _loka) public onlyOwner {
        LOKA = _loka;
    }
    function getReceiver() public view returns(address) {
        return receiver;
    }
    function getTransmitter() public view returns(address) {
        return address(transmitter);
    }
    function getStakerCount() public view returns(uint256){
        return stakers.length;
    }
    function getStakers() public view returns(address[] memory){
        return stakers;
    }
    function getStakersRange(uint256 start, uint256 end) public view returns(address[] memory){
        address[] memory addresses = new address[](end-start);
         for(uint256 i=start; i<end; ++i){
            addresses[i-start] = stakers[i];
        }
        return addresses;
    }
    function getAmount() public view returns(uint256[] memory){
        uint256[] memory amounts = new uint256[](stakers.length);
        for(uint256 i=0; i<stakers.length; ++i){
            amounts[i] = stakes[stakers[i]][0];
        }
        return amounts;
    }
    function getAmountRange(uint256 start, uint256 end) public view returns(uint256[] memory){
        uint256[] memory amounts = new uint256[](end-start);
        for(uint256 i=start; i<end; ++i){
            amounts[i-start] = stakes[stakers[i]][0];
        }
        return amounts;
    }
    function getAmounts(uint256 size) public view returns(uint256[][] memory){
        uint256[][] memory amounts = new uint256[][](stakers.length);
        for(uint256 i=0; i<stakers.length; ++i){
            amounts[i] = new uint256[](size);
            for(uint256 j=0; j<size; ++j)
                amounts[i][j] = stakes[stakers[i]][j];
        }
        return amounts;
    }
    function getAmountsByAddress(uint256 size, address[] memory owners) public view returns(uint256[][] memory){
        uint256[][] memory amounts = new uint256[][](owners.length);
        for(uint256 i=0; i<owners.length; ++i){
            amounts[i] = new uint256[](size);
            for(uint256 j=0; j<size; ++j)
                amounts[i][j] = stakes[owners[i]][j];
        }
        return amounts;
    }
    function getAmountsRange(uint256 size, uint256 start, uint256 end) public view returns(uint256[][] memory){
        uint256[][] memory amounts = new uint256[][](end-start);
        for(uint256 i=start; i<end; ++i){
            amounts[i-start] = new uint256[](size);
            for(uint256 j=0; j<size; ++j)
                amounts[i-start][j] = stakes[stakers[i]][j];
        }
        return amounts;
    }
    function stake(uint256 continent, uint256 amount) public {
        require(continent>0, "Invalid index");
        require(amount>0, "Invalid amount");
        transmitter.transferToken(LOKA, _msgSender(), receiver, amount);
        continents[continent] += amount;
        continents[0] += amount;
        stakes[_msgSender()][continent] += amount;
        stakes[_msgSender()][0] += amount;
        if(indexes[_msgSender()]==0)
        {
            stakers.push(_msgSender());
            indexes[_msgSender()] = stakers.length;
        }
        emit Stake(_msgSender(), continent, amount);
    }
    function unstake(uint256 continent, uint256 amount) public {
        require(continent>0, "Invalid index");
        require(amount>0, "Invalid amount");
        require(stakes[_msgSender()][continent]>=amount, "Insufficient balance");
        transmitter.transferToken(LOKA, receiver, _msgSender(), amount);
        continents[continent] -= amount;
        continents[0] -= amount;
        stakes[_msgSender()][continent] -= amount;
        stakes[_msgSender()][0] -= amount;
        emit Unstake(_msgSender(), continent, amount);
    }
    
    function stakeOf(address owner, uint256 continent) public view returns(uint256) {
        return stakes[owner][continent];
    }
    function totalStakeOf(address owner) public view returns(uint256) {
        return stakes[owner][0];
    }
    function allStakeOf(address owner, uint256 size) public view returns(uint256[] memory) {
        uint256[] memory all = new uint256[](size);
        for(uint256 i=0; i<size; ++i)
            all[i] = stakes[owner][i];
        return all;
    }

    function stakeOfContinent(uint256 index) public view returns(uint256) {
        return continents[index];
    }
    function totalStakeOfContinent() public view returns(uint256) {
        return continents[0];
    }
    function allStakeOfContinent(uint256 size) public view returns(uint256[] memory) {
        uint256[] memory all = new uint256[](size);
        for(uint256 i=0; i<size; ++i)
            all[i] = continents[i];
        return all;
    }
}