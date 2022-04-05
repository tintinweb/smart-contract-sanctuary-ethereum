// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import the openzepplin contracts
import "./Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./FLTC.sol";
import "./IFLNFTC.sol";
import "./IFLTC.sol";

contract FLTPC is Ownable, Pausable{
    using Strings for string; 

    address payable public FLTCAddr;
    address payable public FLNFTCAddr;
    uint public FLNFTID=0;
    uint public GI = 0;
    string public tokenURI = "";
    string public GMipfsHash = "";
    bool public LMSAccepting=false;



    enum LMstatus {
        notexist,
        Submitted,
        Approved,
        Denied,
        Rewarded
    }

    struct LM {
        string LMipfsHash;
        string LMURI;
        LMstatus lmstatus;
    }

    mapping(uint => mapping (address => LM )) private LMSs; // GI -> address -> LocalModel
    mapping(uint => address[]) private LMsubmitters;
    mapping(string => bool) private LMipfsHashes;
    mapping(string => bool) private LMURIs;
    mapping (uint => bool) public GIC;
    mapping (uint => bool) public LMSC; // LMSs completed for this global iteration
    mapping (uint => bool) public LMSADRC; // LMSs Approval Disarroval completed for this global iteration
    event LMSstarted(uint GI); // Where GI is the global iteration for which local model submission has been started
    event LMSclosed(uint GI); // Where GI is the global iteration for which local model submission has been ended


    constructor (address payable _FLNFTCAddr) {
        FLNFTCAddr = _FLNFTCAddr;
        _pause();
        FLTC fLTC = new FLTC("FLToken","FLT"); 
        FLTCAddr = payable(address(fLTC));
    }

    modifier whenFLNFTminted() {
        require(FLNFTID!=0,"FLNFTX");  // FLNFTX="FLNFT not minted, ask owner to call createFLNFT"
        _;
    }

    modifier whenLMSAccepting() {

        require(FLNFTID!=0,"FLNFTX");
        require(!paused(), "Pausable: paused");
        require(LMSAccepting,"LMSsX"); // LMSsX="LMSubmissions not acceptable currently"
        _;
    }

    modifier whenLMSNotAccepting() {
        require(FLNFTID!=0,"FLNFTX");
        require(!paused(), "Pausable: paused");
        require(!LMSAccepting,"X: LMSs acceptable");
        _;
    }

    modifier onlyOwner() override{
        if(FLNFTID!=0 && owner()!=IFLNFTC(FLNFTCAddr).ownerOf(FLNFTID)){
            _transferOwnership(IFLNFTC(FLNFTCAddr).ownerOf(FLNFTID));
        }
        require(owner() == _msgSender(), "OWNX"); // OWNX: caller is not owner
        _;
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        require(FLNFTID==0,"FLNFTY :TRX"); //FLNFT is already minted, can't transfer ownership
        require(newOwner != address(0), "NOWN0"); //Ownable: new owner is the zero address
        _transferOwnership(newOwner);
    }


    function start_LMSs() public onlyOwner whenLMSNotAccepting{
        LMSAccepting = true;
        if(GI>0){
            require(GIC[GI],"Do GMUpdate"); //Please complete GMupdate first
        }
       
        emit LMSstarted(GI+1); // LocalModelSubmissionStarted
    }

    function close_LMSs() public onlyOwner whenLMSAccepting{ // closeLocalModelSubmission
        LMSAccepting = false;
        emit LMSclosed(GI+1); // LocalModelSubmissionClosed
        LMSC[GI+1]=true;
    }


    function createFLNFT(string memory _tokenURI, string memory _GMipfsHash) public onlyOwner whenPaused{
        require(FLNFTID==0,"FLNFTY"); //FLNFT already minted
        FLNFTID = IFLNFTC(FLNFTCAddr).mintFLNFT(owner(), address(this), _tokenURI, _GMipfsHash);
        tokenURI = _tokenURI;
        GMipfsHash = _GMipfsHash;
        _unpause();
    }

    function submitLocalModel(string memory _LMipfsHash, string memory _LMURI, uint _GI) public  whenLMSAccepting {
        
        if (Validate_LMS( _LMipfsHash,  _LMURI, _GI, msg.sender)){

            Add_LMS( _LMipfsHash,  _LMURI, msg.sender);
            LMipfsHashes[_LMipfsHash] = true;
            LMURIs[_LMipfsHash] = true;
        }
    }

    function Validate_LMS(string memory _LMipfsHash, string memory _LMURI, uint _gi, address _addroffltrainer) internal view returns (bool){

        require(LMSs[GI+1][_addroffltrainer].lmstatus==LMstatus.notexist,"LMY"); // You have already submmitted LM
        require(GI+1==_gi,"LMSs GI X");  // LMSs for this global iteration are not accepted
        require(LMipfsHashes[_LMipfsHash] != true, "_LMipfsHash Y"); // Provided _LMipfsHash already exist
        require(LMURIs[_LMURI] != true, "_LMURI Y"); // Provided _LMURI already exist
        require(LMsubmitters[_gi].length <= 10, "LMTR"); //Local model submission limit reached
        return true;
    }

    function Add_LMS(string memory _LMipfsHash, string memory _LMURI, address _addroffltrainer) internal returns (bool){
        LMsubmitters[GI+1].push(_addroffltrainer);
        LMSs[GI+1][_addroffltrainer]= LM(_LMipfsHash, _LMURI, LMstatus.Submitted);

        return true;
    }

    function Download_LMSx(uint _GI) public onlyOwner whenLMSNotAccepting returns(address[] memory){
        return LMsubmitters[_GI];
    }

    function Download_LMS(uint _GI, address LM_Submitter) public onlyOwner whenLMSNotAccepting returns(LM memory){
        require(LMSs[_GI][msg.sender].lmstatus!=LMstatus.notexist,'LMSX');
        return LMSs[_GI][LM_Submitter];
    }

    function ADRLMS( address _LMsubmitter, uint _GI, LMstatus _localModelStatus) public onlyOwner whenLMSNotAccepting returns(bool){
        require(_GI==GI+1,"LMADR X GI"); //LMS Approval/Disarroval for this global iteration not accepted
        require(LMSs[_GI][msg.sender].lmstatus==LMstatus.Submitted,'LMSX');
        require(_localModelStatus==LMstatus.Approved || _localModelStatus==LMstatus.Denied,'LMS Status IC'); //incorrect _localModelStatus provided
        LMSs[_GI][_LMsubmitter].lmstatus = _localModelStatus;
        if(_localModelStatus == LMstatus.Approved){
            bool statusminted = IFLTC(FLTCAddr).mintFLToken(_LMsubmitter);
            if(statusminted){
                LMSs[_GI][_LMsubmitter].lmstatus = LMstatus.Rewarded;
            }
        }

        return true;
    }

    function setLMSADRC(uint _GI) public onlyOwner whenLMSNotAccepting{
        require(_GI==GI+1,"GI IC"); // incorrect GI provided
        require(LMSC[_GI],"closeLMS X"); // LMSs not closed
        LMSADRC[_GI]=true;

    }

    event GMupdated(uint gi, string _GMipfsHash, string _tokenURI);

    function GMupdate( uint _GI, string memory _tokenURI, string memory _GMipfsHash) public onlyOwner  whenLMSNotAccepting returns(bool){
        require(!GIC[_GI],"GM GI Y"); // GM for this iteration already avaiable!
        require(_GI==GI+1,"GI IC"); // incorrect GI update!
        require(LMSADRC[_GI],"LMSADRC GI X"); //LMSADRC for _GI not completed!
        bool setTokenURIF = IFLNFTC(FLNFTCAddr).setTokenURI(FLNFTID, _tokenURI);
        bool setGMipfsHashF = IFLNFTC(FLNFTCAddr).setGMipfsHash(FLNFTID, _GMipfsHash);
        if(setTokenURIF && setGMipfsHashF){
            GI = GI+1;
            tokenURI = _tokenURI;
            GMipfsHash = _GMipfsHash;
            emit GMupdated( GI,  _GMipfsHash,  _tokenURI);
            GIC[GI]=true;
            return true;
        } 
        else{
            return false;
        }
    }

    function pause() public onlyOwner whenFLNFTminted{
        if(LMSAccepting){
            close_LMSs();
        }
        _pause();
    }

    function unpause() public onlyOwner whenFLNFTminted{
        _unpause();
    }



    receive() external payable {

    }

    fallback() external payable {

    }

    function withdraw() public onlyOwner  {
          (bool sent, ) =  owner().call{value: address(this).balance}("");
          require(sent, "ETH TR X");
    }

    function FLTCwithdraw() public onlyOwner  {
          IFLTC(FLTCAddr).withdraw();
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

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
    modifier onlyOwner() virtual{
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


// Import the openzepplin contracts
import "./Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";


contract FLTC is ERC20, Ownable, Pausable{

    // owner of FLTokenContract should be FLtaskPublisherContract
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        
    }


    function mintFLToken(address recipient)public whenNotPaused onlyOwner returns(bool){
        _mint(recipient, 1 * 10 ** 18); 
        return true;
    }

    function pause() public onlyOwner{
        _pause();
    }

    function unpause() public onlyOwner{
        _unpause();
    }

    function renounceOwnership() public view override onlyOwner {
        revert("can't renounceOwnership here"); //not possible with this smart contract
    }

    function transferOwnership() public view onlyOwner {
       revert("can't transferOwnership here"); //not possible with this smart contract
    }

    receive() external payable {

    }

    fallback() external payable {

    }

    function withdraw() public onlyOwner  {
          address _owner = owner();
          uint256 amount = address(this).balance;
          (bool sent, ) =  _owner.call{value: amount}("");
          require(sent, "Failed to send Ether");
    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IFLNFTC {
    function mintFLNFT(address minter, address _FLtaskPublisherContract, string memory _tokenURI, string memory _GMipfsHash) external  returns (uint256);
    function setTokenURI(uint256 _tokenId, string memory _tokenURI) external returns(bool);
    function setGMipfsHash(uint256 _tokenId, string memory _GMipfsHash) external returns(bool);
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IFLTC {
   function withdraw() external;
   function mintFLToken(address recipient) external  returns(bool);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}