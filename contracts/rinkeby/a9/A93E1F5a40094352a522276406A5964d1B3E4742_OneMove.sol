// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "erc721a/contracts/IERC721A.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

interface IMT1 is IERC20{
    function mint(uint256 amount) external;
}

interface IUNQ is IERC721A{
    function mint(address account) external;
}

interface IARTIFACT is IERC1155{
    function mint(uint256 id, uint256 amount) external;
    function mintBatch(uint256[] memory ids, uint256[] memory amounts) external;
    // function mint(uint256 level, string memory gemType, uint256 amount) external;
    // function type_NumberReference(string memory account) external view returns (uint16);
}

interface ISHOEBOX is IERC1155{
    function mint(uint256 id, uint256 amount) external;
    function mintBatch(uint256[] memory ids, uint256[] memory amounts) external;
}

contract OneMove is Ownable, ERC1155Holder, ERC721Holder, ReentrancyGuard {

    IMT1 public tokenMT1;
    IERC20 public tokenRT1;
    IUNQ public nftUNQ;
    IARTIFACT public nftArtifact;
    ISHOEBOX public nftShoebox;

    // Developer address.
    address public devAddress;

    // Whitelist address.
    address public whitelist;

    // Contribute address.
    address[4] public contributeAddress;

    /* ========== MODIFIERS ========== */
    modifier onlyGovernance() {
        require(
            (msg.sender == devAddress || msg.sender == owner()),
            "OneMove::onlyGovernance: Not gov"
        );
        _;
    }

    modifier onlyOwnerWhitelist() {
        require(
            (msg.sender == whitelist || msg.sender == owner()),
            "OneMove::onlyOwnerWhitelist: Not Owner Whitelist"
        );
        _;
    }

    modifier onlyAdminWhitelist() {
        require(
            (msg.sender == whitelist || msg.sender == owner() || msg.sender == devAddress),
            "OneMove::onlyAdminWhitelist: Not Admin Whitelist"
        );
        _;
    }

    //Events
    event DepositBNB(uint256 uid, address account, uint256 amount);
    event WithdrawBNB(address account, uint256 amount);

    event DepositToken(uint256 uid, address account, uint256 amount, string token);
    event WithdrawToken(address account, uint256 amount, string token);
    event BurnToken(uint256 amount, string token);

    event DepositUNQ(uint256 uid, address account, uint256 tokenId);
    event WithdrawUNQ(address account, uint256 tokenId);

    event DepositArtifact(uint256 uid, address account, uint256 tokenId, uint256 amount);
    event DepositArtifactBatch(uint256 uid, address account, uint256[] tokenIds, uint256[] amounts);
    event WithdrawArtifact(address account, uint256 tokenId, uint256 amount);
    event WithdrawArtifactBatch(address account, uint256[] tokenIds, uint256[] amounts);
    event BurnArtifact(uint256 tokenId, uint256 amount);
    event BurnArtifactBatch(uint256[] tokenIds, uint256[] amounts);

    event DepositShoebox(uint256 uid, address account, uint256 tokenId, uint256 amount);
    event DepositShoeboxBatch(uint256 uid, address account, uint256[] tokenIds, uint256[] amounts);
    event WithdrawShoebox(address account, uint256 tokenId, uint256 amount);
    event WithdrawShoeboxBatch(address account, uint256[] tokenIds, uint256[] amounts);
    event BurnShoebox(uint256 tokenId, uint256 amount);
    event BurnShoeboxBatch(uint256[] tokenIds, uint256[] amounts);

    constructor(
        address _tokenMT1,
        address _tokenRT1,
        address _nftUNQ,
        address _nftArtifact,
        address _nftShoebox,
        address _devAddress,
        address _whitelist,
        address _conAddress1,
        address _conAddress2,
        address _conAddress3,
        address _conAddress4
    ) {
        tokenMT1 = IMT1(_tokenMT1);
        tokenRT1 = IERC20(_tokenRT1);
        nftUNQ = IUNQ(_nftUNQ);
        nftArtifact = IARTIFACT(_nftArtifact);
        nftShoebox = ISHOEBOX(_nftShoebox);
        devAddress = _devAddress;
        whitelist = _whitelist;
        contributeAddress[0] = _conAddress1;
        contributeAddress[1] = _conAddress2;
        contributeAddress[2] = _conAddress3;
        contributeAddress[3] = _conAddress4;
    }

    //BNB--------------------------
    function depositBNB(uint256 uid) external payable {
        emit DepositBNB(uid, msg.sender, msg.value);
    }
    
    function withdrawBNB(address account, uint256 amount) external onlyAdminWhitelist {
        payable(account).transfer(amount);
        emit WithdrawBNB(account, amount);
    }

    function withdrawWhitelist(uint256 _bnbAmount) external onlyOwnerWhitelist {
        require(address(this).balance >= _bnbAmount, "Contract Not enough BNB Balance");
        (bool success0, ) = payable(contributeAddress[0]).call{value: (_bnbAmount*50)/100}("");
        (bool success1, ) = payable(contributeAddress[1]).call{value: (_bnbAmount*20)/100}("");
        (bool success2, ) = payable(contributeAddress[2]).call{value: (_bnbAmount*15)/100}("");
        (bool success3, ) = payable(contributeAddress[3]).call{value: (_bnbAmount*15)/100}("");
        require(success0 , "Transfer failed conID 0.");
        require(success1 , "Transfer failed conID 1.");
        require(success2 , "Transfer failed conID 2.");
        require(success3 , "Transfer failed conID 3.");

        // require(address(this).balance >= 3e16, "Not enough BNB Balance (>0.03)");
        // payable(contributeAddress[0]).transfer((2e16*20)/100);
        // payable(contributeAddress[1]).transfer((2e16*15)/100);
        // payable(contributeAddress[2]).transfer((2e16*15)/100);
        // payable(contributeAddress[3]).transfer((2e16*50)/100);
    }

    function balanceBNB() external view returns(uint256) {
        return address(this).balance;
    }

    //Token MT1--------------------------
    function depositMT1(uint256 uid, uint256 amount) external {
        tokenMT1.transferFrom(msg.sender, address(this), amount);
        emit DepositToken(uid, msg.sender, amount, "1MT");
    }

    function withdrawMT1(address account, uint256 amount) external onlyAdminWhitelist {
        if(amount > tokenMT1.balanceOf(address(this))){
            tokenMT1.mint(amount- tokenMT1.balanceOf(address(this)));
        }
        tokenMT1.transfer(account, amount);

        emit WithdrawToken(account, amount, "1MT");
    }

    function balanceMT1() external view returns(uint256) {
        return tokenMT1.balanceOf(address(this));
    }

    function mintMT1(uint256 amount) external onlyAdminWhitelist {
        tokenMT1.mint(amount);
    }

    function burnMT1(uint256 amount) external onlyAdminWhitelist {
        tokenMT1.transfer(address(0x000000000000000000000000000000000000dEaD), amount);
        emit BurnToken(amount, "1MT");
    }

    //RT1--------------------------
    function depositRT1(uint256 uid, uint256 amount) external {
        tokenRT1.transferFrom(msg.sender, address(this), amount);
        emit DepositToken(uid, msg.sender, amount, "1RT");
    }

    function withdrawRT1(address account, uint256 amount) external onlyAdminWhitelist {
        tokenRT1.transfer(account, amount);
        emit WithdrawToken(account, amount, "1RT");
    }

    function balanceRT1() external view returns(uint256) {
        return tokenRT1.balanceOf(address(this));
    }

    function burnRT1(uint256 amount) external onlyAdminWhitelist {
        tokenRT1.transfer(address(0x000000000000000000000000000000000000dEaD), amount);
        emit BurnToken(amount, "1RT");
    }

    //UNQ-------------------------
    function depositUNQ(uint256 uid, uint256 _tokenId) external {
        nftUNQ.safeTransferFrom(msg.sender, address(this), _tokenId);
        emit DepositUNQ(uid, msg.sender, _tokenId);
    }

    function withdrawUNQ(uint256 _tokenId, address account) external onlyAdminWhitelist {
        nftUNQ.safeTransferFrom(address(this), account, _tokenId);
        emit WithdrawUNQ(account, _tokenId);
    }

    function mintUNQ(address account) external onlyAdminWhitelist {
        nftUNQ.mint(account);
    }

    function balanceUNQ() external view returns(uint256) {
        return nftUNQ.balanceOf(address(this));
    }
    //Artifact-------------------------
    function depositArtifact(uint256 uid, uint256 id, uint256 amount) external {
        nftArtifact.safeTransferFrom(msg.sender, address(this), id, amount, "");

        emit DepositArtifact(uid, msg.sender, id, amount);
    }

    function depositArtifactBatch(uint256 uid, uint256[] memory ids, uint256[] memory amounts) external{
        nftArtifact.safeBatchTransferFrom(msg.sender, address(this), ids, amounts, "");
        emit DepositArtifactBatch(uid, msg.sender, ids, amounts);
    }

    function withdrawArtifact(uint256 id, uint256 amount, address account) external onlyAdminWhitelist{
        if(nftArtifact.balanceOf(address(this), id) < amount){
            nftArtifact.mint(id, amount - nftArtifact.balanceOf(address(this), id));
        }
        
        nftArtifact.safeTransferFrom(address(this), account, id, amount, "");
        
        emit WithdrawArtifact(account, id, amount);
    }

    function withdrawArtifactBatch(uint256[] memory ids, uint256[] memory amounts, address account) external onlyAdminWhitelist {
        require(ids.length == amounts.length, "Tokens ID length should be same with Amounts length");
        for(uint256 i = 0; i < ids.length; i++){
            if(nftArtifact.balanceOf(address(this), ids[i]) < amounts[i]){
                nftArtifact.mint(ids[i], amounts[i] - nftArtifact.balanceOf(address(this), ids[i]));
            }
        }
        nftArtifact.safeBatchTransferFrom(address(this), account, ids, amounts, "");
        emit WithdrawArtifactBatch(account, ids, amounts);
    }

    function mintArtifact(uint256 id, uint256 amount) external onlyAdminWhitelist {
        nftArtifact.mint(id, amount);
    }

    function mintArtifactBatch(uint256[] memory ids, uint256[] memory amounts) external onlyAdminWhitelist {
        nftArtifact.mintBatch(ids, amounts);
    }

    function burnArtifact(uint256 id, uint256 amount) external onlyAdminWhitelist {
        nftArtifact.safeTransferFrom(address(this), address(0x000000000000000000000000000000000000dEaD), id, amount, "");
        emit BurnArtifact(id, amount);
    }

    function burnArtifactBatch(uint256[] memory ids, uint256[] memory amounts) external onlyAdminWhitelist {
        nftArtifact.safeBatchTransferFrom(address(this), address(0x000000000000000000000000000000000000dEaD), ids, amounts, "");
        emit BurnArtifactBatch(ids, amounts);
    }

    function balanceArtifact(uint256 id) external view returns(uint256) {
        return nftArtifact.balanceOf(address(this), id);
    }

    function balanceArtifactBatch(uint256[] memory ids) external view returns(uint256[] memory, uint256[] memory) {
        address[] memory addrs = new address[](ids.length);
        // address[] memory addr;
        for (uint i = 0; i < ids.length; i++)
            addrs[i] = address(this);
        
        return (ids, nftArtifact.balanceOfBatch(addrs, ids));
    }

    //Shoebox-------------------------
    function depositShoebox(uint256 uid, uint256 id, uint256 amount) external {
        nftShoebox.safeTransferFrom(msg.sender, address(this), id, amount, "");
        emit DepositShoebox(uid, msg.sender, id, amount);
    }

    function depositShoeboxBatch(uint256 uid, uint256[] memory ids, uint256[] memory amounts) external{
        nftShoebox.safeBatchTransferFrom(msg.sender, address(this), ids, amounts, "");
        emit DepositShoeboxBatch(uid, msg.sender, ids, amounts);
    }

    function withdrawShoebox(uint256 id, uint256 amount, address account) external onlyAdminWhitelist {
        if(nftShoebox.balanceOf(address(this), id) < amount){
            nftShoebox.mint(id, amount - nftShoebox.balanceOf(address(this), id));
        }
        nftShoebox.safeTransferFrom(address(this), account, id, amount, "");
                
        emit WithdrawShoebox(account, id, amount);
    }

    function withdrawShoeboxBatch(uint256[] memory ids, uint256[] memory amounts, address account) external onlyAdminWhitelist {
        require(ids.length == amounts.length, "Tokens ID length should be same with Amounts length");
        for(uint256 i = 0; i < ids.length; i++){
            if(nftShoebox.balanceOf(address(this), ids[i]) < amounts[i]){
                nftShoebox.mint(ids[i], amounts[i] - nftShoebox.balanceOf(address(this), ids[i]));
            }
        }
        nftShoebox.safeBatchTransferFrom(address(this), account, ids, amounts, "");
        emit WithdrawShoeboxBatch(account, ids, amounts);
    }

    function mintShoebox(uint256 id, uint256 amount) external onlyAdminWhitelist {
        nftShoebox.mint(id, amount);
    }

    function mintShoeboxBatch(uint256[] memory ids, uint256[] memory amounts) external onlyAdminWhitelist {
        nftShoebox.mintBatch(ids, amounts);
    }

    function burnShoebox(uint256 id, uint256 amount) external onlyAdminWhitelist {
        nftShoebox.safeTransferFrom(address(this), address(0x000000000000000000000000000000000000dEaD), id, amount, "");
        emit BurnShoebox(id, amount);
    }

    function burnShoeboxBatch(uint256[] memory ids, uint256[] memory amounts) external onlyAdminWhitelist {
        nftShoebox.safeBatchTransferFrom(address(this), address(0x000000000000000000000000000000000000dEaD), ids, amounts, "");
        emit BurnShoeboxBatch(ids, amounts);
    }

    function balanceShoebox(uint256 _tokenId) external view returns(uint256) {
        return nftShoebox.balanceOf(address(this), _tokenId);
    }

    function balanceShoeboxBatch(uint256[] memory ids) external view returns(uint256[] memory, uint256[] memory) {
        address[] memory addrs = new address[](ids.length);
        for (uint i = 0; i < ids.length; i++)
            addrs[i] = address(this);
        
        return (ids, nftShoebox.balanceOfBatch(addrs, ids));
    }

    function changeDev(address account) external onlyOwner {
        require(account != address(0), "Address 0");
        devAddress = account;
    }

    function changeWhitelist(address account) external onlyOwner {
        require(account != address(0), "Address 0");
        whitelist = account;
    }

    function setContribute(uint256 _contributeID, address _account) external onlyOwnerWhitelist {
        require(_contributeID >= 0 && _contributeID <= 3 , "Invalid Contribute ID (0 - 3)");
        require(_account != address(0), "Address 0");
        contributeAddress[_contributeID] = _account;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v3.3.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';

/**
 * @dev Interface of an ERC721A compliant contract.
 */
interface IERC721A is IERC721, IERC721Metadata {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

    /**
     * The caller cannot approve to the current owner.
     */
    error ApprovalToCurrentOwner();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    // Compiler will pack this into a single 256bit word.
    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
    }

    // Compiler will pack this into a single 256bit word.
    struct AddressData {
        // Realistically, 2**64-1 is more than enough.
        uint64 balance;
        // Keeps track of mint count with minimal overhead for tokenomics.
        uint64 numberMinted;
        // Keeps track of burn count with minimal overhead for tokenomics.
        uint64 numberBurned;
        // For miscellaneous variable(s) pertaining to the address
        // (e.g. number of whitelist mint slots used).
        // If there are multiple variables, please pack them into a uint64.
        uint64 aux;
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     * 
     * Burned tokens are calculated here, use `_totalMinted()` if you want to count just minted tokens.
     */
    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}